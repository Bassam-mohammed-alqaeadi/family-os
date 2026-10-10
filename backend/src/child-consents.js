// Safety slice 2 — the child-consent surface.
//
// Play's User Data and Background Location rules make a recorded consent a condition of
// collection: a prominent disclosure, an explicit act, and a durable record of who agreed
// to which text and when. This surface keeps that record and answers honestly about it.
//
// Two actors may record a grant: the child's own handset at setup (device credential, the
// act the disclosure screen performed) or a primary guardian (bearer). Withdrawal is a
// guardian act only — a handset that could withdraw its own consent could silence a
// guardian's decision as easily as it recorded one.
//
// Nothing here grants collection by itself. `location-telemetry` consults `readActiveConsent`
// before storing a fix, and refuses with `consent_required` while no active consent exists.
import { HttpError } from './http-error.js';

export const CONSENT_CAPABILITIES = Object.freeze(new Set(['location', 'usage_stats', 'web_filtering']));

/**
 * One consent row as the wire reports it. `state` distinguishes never-granted from
 * withdrawn, because "no" and "not yet" are different answers to a child's question.
 */
export function consentView(row) {
  if (row === null) {
    return {
      capability: null,
      state: 'none',
      textVersion: null,
      grantedAt: null,
      withdrawnAt: null,
      grantedByMembershipId: null,
      grantedByDeviceId: null,
      withdrawnByMembershipId: null,
    };
  }
  return {
    capability: row.capability,
    state: row.withdrawn_at === null ? 'granted' : 'withdrawn',
    textVersion: row.text_version,
    grantedAt: row.granted_at instanceof Date ? row.granted_at.toISOString() : String(row.granted_at),
    withdrawnAt:
      row.withdrawn_at === null
        ? null
        : row.withdrawn_at instanceof Date
          ? row.withdrawn_at.toISOString()
          : String(row.withdrawn_at),
    grantedByMembershipId: row.granted_by_membership_id ?? null,
    grantedByDeviceId: row.granted_by_device_id ?? null,
    withdrawnByMembershipId: row.withdrawn_by_membership_id ?? null,
  };
}

export function createChildConsentSurface({ port, now = () => new Date() }) {
  /**
   * The device this consent names, with the same standing rules as every device route:
   * a credential speaks only for its own handset, a guardian only for a device in the
   * family they own.
   */
  async function readDeviceAuthorizing(tx, { principal, deviceCredential, deviceId }) {
    const device = await port.readConsentDevice(tx, { deviceId });
    if (device === null) {
      throw new HttpError(404, 'device_not_found', 'Linked device was not found.');
    }
    if (deviceCredential != null) {
      if (
        device.credential_revoked_at != null ||
        !port.credentialMatches(device.credential_hash, deviceCredential)
      ) {
        throw new HttpError(
          401,
          'invalid_device_credential',
          'The device credential is invalid or revoked.',
        );
      }
      return device;
    }
    if (!principal) {
      throw new HttpError(
        401,
        'authentication_required',
        'A device credential or bearer token is required.',
      );
    }
    await port.authorize(tx, {
      familyId: device.family_id,
      subject: principal.subject,
      primaryGuardianOnly: true,
    });
    return device;
  }

  /**
   * Records one grant: who consented, when, and the disclosure text version they saw.
   *
   * Replaying the same Idempotency-Key returns the first answer. Granting while an active
   * consent already exists is refused (`consent_already_granted`) rather than stacked: one
   * act, one row, and the history of withdrawals is never overwritten.
   */
  async function recordConsent({
    principal,
    deviceCredential,
    deviceId,
    capability,
    textVersion,
    idempotencyKey,
    requestHash,
  }) {
    return port.idempotent(
      `consent:grant:${deviceId}:${capability}`,
      idempotencyKey,
      requestHash,
      async (tx) => {
        const device = await readDeviceAuthorizing(tx, { principal, deviceCredential, deviceId });
        const active = await port.readActiveConsent(tx, {
          childId: device.child_id,
          capability,
        });
        if (active !== null) {
          throw new HttpError(
            409,
            'consent_already_granted',
            'An active consent already exists for this capability.',
          );
        }
        const membershipId = deviceCredential != null ? null : (await port.activeActorMembershipId(tx, {
          familyId: device.family_id,
          subject: principal.subject,
        }));
        const row = await port.insertConsent(tx, {
          familyId: device.family_id,
          childId: device.child_id,
          capability,
          textVersion,
          grantedByMembershipId: membershipId,
          grantedByDeviceId: deviceCredential != null ? deviceId : null,
          grantedAt: now(),
        });
        return { consent: consentView(row) };
      },
    );
  }

  /**
   * Withdraws the active consent and freezes it with the guardian's moment of refusal.
   *
   * Repeat-safe: withdrawing an already-withdrawn (or never-granted) capability returns
   * the current honest state instead of manufacturing an error for a second "no".
   */
  async function withdrawConsent({ principal, deviceId, capability, correlationId }) {
    return port.withTransaction(async (tx) => {
      const device = await readDeviceAuthorizing(tx, { principal, deviceCredential: null, deviceId });
      const membershipId = await port.activeActorMembershipId(tx, {
        familyId: device.family_id,
        subject: principal.subject,
      });
      const active = await port.readActiveConsent(tx, { childId: device.child_id, capability });
      if (active === null) {
        const latest = await port.readLatestConsent(tx, { childId: device.child_id, capability });
        return { consent: consentView(latest) };
      }
      const row = await port.withdrawActiveConsent(tx, {
        childId: device.child_id,
        capability,
        withdrawnByMembershipId: membershipId,
        withdrawnAt: now(),
      });
      return { consent: consentView(row) };
    });
  }

  /**
   * What this handset is sharing right now — the child phone's honest answer about
   * itself, readable by the handset and by a primary guardian. Never a guess: the state
   * is the ledger's state.
   */
  async function locationSharing({ principal, deviceCredential, deviceId }) {
    return port.withTransaction(async (tx) => {
      const device = await readDeviceAuthorizing(tx, { principal, deviceCredential, deviceId });
      const rows = await port.readConsentStates(tx, { childId: device.child_id });
      return {
        deviceId,
        childId: device.child_id,
        capabilities: Object.fromEntries(
          [...CONSENT_CAPABILITIES].map((capability) => [
            capability,
            consentView(rows.get(capability) ?? null),
          ]),
        ),
      };
    });
  }

  return { recordConsent, withdrawConsent, locationSharing };
}

/**
 * The PostgreSQL port. Consent reads and writes are plain statements on the ledger table
 * from migration 114; nothing here infers consent from other rows.
 */
export function postgresChildConsentPort(store, { credentialMatches }) {
  return {
    credentialMatches,

    async withTransaction(run) {
      return store.withTransaction(run);
    },

    async idempotent(scope, key, requestHash, work) {
      return store.withTransaction(async (client) => {
        const replay = await store.acquireIdempotencySlot(client, scope, key, requestHash);
        if (replay) return replay;
        const result = await work(client);
        await store.completeIdempotencySlot(client, scope, key, result);
        return result;
      });
    },

    async authorize(client, { familyId, subject, primaryGuardianOnly = false }) {
      return store.activeActorMembership(client, familyId, subject, { primaryGuardianOnly });
    },

    async activeActorMembershipId(client, { familyId, subject }) {
      const membership = await store.activeActorMembership(client, familyId, subject, {
        primaryGuardianOnly: true,
      });
      return membership.id;
    },

    async readConsentDevice(client, { deviceId }) {
      const { rows } = await client.query(
        `SELECT id, family_id, child_id, credential_hash, credential_revoked_at
           FROM family_child_devices
          WHERE id = $1
          FOR UPDATE`,
        [deviceId],
      );
      return rows[0] ?? null;
    },

    async readActiveConsent(client, { childId, capability }) {
      const { rows } = await client.query(
        `SELECT * FROM family_child_consents
          WHERE child_id = $1 AND capability = $2 AND withdrawn_at IS NULL`,
        [childId, capability],
      );
      return rows[0] ?? null;
    },

    async readLatestConsent(client, { childId, capability }) {
      const { rows } = await client.query(
        `SELECT * FROM family_child_consents
          WHERE child_id = $1 AND capability = $2
          ORDER BY granted_at DESC, id DESC
          LIMIT 1`,
        [childId, capability],
      );
      return rows[0] ?? null;
    },

    async readConsentStates(client, { childId }) {
      const { rows } = await client.query(
        `SELECT DISTINCT ON (capability) *
           FROM family_child_consents
          WHERE child_id = $1
          ORDER BY capability, granted_at DESC, id DESC`,
        [childId],
      );
      return new Map(rows.map((row) => [row.capability, row]));
    },

    async insertConsent(
      client,
      {
        familyId,
        childId,
        capability,
        textVersion,
        grantedByMembershipId,
        grantedByDeviceId,
        grantedAt,
      },
    ) {
      const { rows } = await client.query(
        `INSERT INTO family_child_consents
           (family_id, child_id, capability, text_version,
            granted_by_membership_id, granted_by_device_id, granted_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         RETURNING *`,
        [
          familyId,
          childId,
          capability,
          textVersion.trim(),
          grantedByMembershipId,
          grantedByDeviceId,
          grantedAt,
        ],
      );
      return rows[0];
    },

    async withdrawActiveConsent(client, { childId, capability, withdrawnByMembershipId, withdrawnAt }) {
      const { rows } = await client.query(
        `UPDATE family_child_consents
            SET withdrawn_at = $3, withdrawn_by_membership_id = $4
          WHERE child_id = $1 AND capability = $2 AND withdrawn_at IS NULL
          RETURNING *`,
        [childId, capability, withdrawnAt, withdrawnByMembershipId],
      );
      return rows[0] ?? null;
    },
  };
}

export function childConsentsFor(store, { credentialMatches }) {
  return createChildConsentSurface({
    port: postgresChildConsentPort(store, { credentialMatches }),
  });
}
