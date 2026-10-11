// Safety slice S0 (spine) — device capability ledger.
//
// Principle 2 ("capability is data"): every control in the UI is evaluated against a
// stored, current capability record. The HANDSET decides the facts (what permission was
// granted, what subsystem is actually running), the server stores them, and the UI
// reports them honestly through CapabilityHonestyBadge rather than guessing from a
// toggle.
//
// Two endpoints:
//   * POST /v1/devices/{deviceId}/capabilities        — device credential; upsert snapshot.
//   * GET  /v1/families/{familyId}/children/{childId}/device-capabilities — guardian read.
//
// The snapshot is an UPSERT keyed on (device_id, capability_key). A device may re-report
// the same state freely (idempotent); only real state changes produce events.
import { randomUUID } from 'node:crypto';
import { HttpError } from './http-error.js';

export const CAPABILITY_KEYS = Object.freeze(new Set([
  'usage_metering',
  'app_inventory',
  'app_block_overlay',
  'accessibility_enforcement',
  'instant_lock',
  'web_filter_vpn',
  'background_location',
  'boot_persistence',
  'push_delivery',
  'battery_reporting',
  'tamper_signals',
]));

export const CAPABILITY_STATES = Object.freeze(new Set([
  'confirmed',
  'awaiting_setup',
  'permission_needed',
  'unsupported',
  'revoked',
  'unknown',
]));

/**
 * Wire shape of one capability entry. Dates are ISO strings.
 */
export function capabilityView(row) {
  return {
    deviceId: row.device_id,
    capabilityKey: row.capability_key,
    state: row.state,
    evidence: row.evidence ?? null,
    appVersion: row.app_version ?? null,
    osVersion: row.os_version ?? null,
    confirmedAt: row.confirmed_at instanceof Date ? row.confirmed_at.toISOString() : null,
    reportedAt: row.reported_at instanceof Date ? row.reported_at.toISOString() : String(row.reported_at),
  };
}

function requireCapabilitySnapshotEntry(entry, index) {
  if (entry === null || typeof entry !== 'object') {
    throw new HttpError(400, 'invalid_request', `capabilities[${index}] must be an object.`);
  }
  const key = typeof entry.capabilityKey === 'string' ? entry.capabilityKey.trim() : '';
  if (!CAPABILITY_KEYS.has(key)) {
    throw new HttpError(400, 'invalid_request', `capabilities[${index}].capabilityKey is not known.`);
  }
  const state = typeof entry.state === 'string' ? entry.state.trim() : '';
  if (!CAPABILITY_STATES.has(state)) {
    throw new HttpError(400, 'invalid_request', `capabilities[${index}].state is not a known state.`);
  }
  let evidence = null;
  if (entry.evidence !== undefined && entry.evidence !== null) {
    if (typeof entry.evidence !== 'string') {
      throw new HttpError(400, 'invalid_request', `capabilities[${index}].evidence must be text.`);
    }
    const trimmed = entry.evidence.trim();
    if (trimmed.length < 1 || trimmed.length > 512) {
      throw new HttpError(400, 'invalid_request', `capabilities[${index}].evidence must be 1..512 chars.`);
    }
    evidence = trimmed;
  }
  let appVersion = null;
  if (entry.appVersion !== undefined && entry.appVersion !== null) {
    if (typeof entry.appVersion !== 'string') {
      throw new HttpError(400, 'invalid_request', `capabilities[${index}].appVersion must be text.`);
    }
    const trimmed = entry.appVersion.trim();
    if (trimmed.length < 1 || trimmed.length > 64) {
      throw new HttpError(400, 'invalid_request', `capabilities[${index}].appVersion must be 1..64 chars.`);
    }
    appVersion = trimmed;
  }
  let osVersion = null;
  if (entry.osVersion !== undefined && entry.osVersion !== null) {
    if (typeof entry.osVersion !== 'string') {
      throw new HttpError(400, 'invalid_request', `capabilities[${index}].osVersion must be text.`);
    }
    const trimmed = entry.osVersion.trim();
    if (trimmed.length < 1 || trimmed.length > 64) {
      throw new HttpError(400, 'invalid_request', `capabilities[${index}].osVersion must be 1..64 chars.`);
    }
    osVersion = trimmed;
  }
  // Pairing rule: confirmed ⇔ confirmedAt present; enforced by CHECK but validated early.
  let confirmedAt = null;
  if (entry.confirmedAt !== undefined && entry.confirmedAt !== null) {
    if (state !== 'confirmed') {
      throw new HttpError(400, 'invalid_request',
        `capabilities[${index}].confirmedAt must be omitted unless state is 'confirmed'.`);
    }
    const parsed = new Date(entry.confirmedAt);
    if (Number.isNaN(parsed.getTime())) {
      throw new HttpError(400, 'invalid_request', `capabilities[${index}].confirmedAt must be an ISO-8601 instant.`);
    }
    confirmedAt = parsed;
  } else if (state === 'confirmed') {
    confirmedAt = new Date();
  }
  return { capabilityKey: key, state, evidence, appVersion, osVersion, confirmedAt };
}

export function parseCapabilitySnapshotPayload(body) {
  if (!Array.isArray(body?.capabilities)) {
    throw new HttpError(400, 'invalid_request', 'capabilities must be a list.');
  }
  if (body.capabilities.length > 32) {
    throw new HttpError(400, 'invalid_request', 'capabilities must hold at most 32 entries per snapshot.');
  }
  const seen = new Set();
  const entries = body.capabilities.map((entry, index) => {
    const parsed = requireCapabilitySnapshotEntry(entry, index);
    if (seen.has(parsed.capabilityKey)) {
      throw new HttpError(400, 'invalid_request',
        `capabilities[${index}] duplicates key '${parsed.capabilityKey}'.`);
    }
    seen.add(parsed.capabilityKey);
    return parsed;
  });
  return entries;
}

export function createDeviceCapabilitySurface({ port, now = () => new Date() }) {
  async function authorizeDevice(tx, { principal, deviceCredential, deviceId }) {
    const device = await port.readDeviceIdentity(tx, { deviceId });
    if (device === null) {
      throw new HttpError(404, 'device_not_found', 'Linked device was not found.');
    }
    if (deviceCredential != null) {
      if (device.credential_revoked_at != null
          || !port.credentialMatches(device.credential_hash, deviceCredential)) {
        throw new HttpError(401, 'invalid_device_credential',
          'The device credential is invalid or revoked.');
      }
      return device;
    }
    if (!principal) {
      throw new HttpError(401, 'authentication_required',
        'A device credential or bearer token is required.');
    }
    await port.authorize(tx, {
      familyId: device.family_id,
      subject: principal.subject,
      primaryGuardianOnly: true,
    });
    return device;
  }

  async function reportSnapshot({
    principal, deviceCredential, deviceId, entries, requestHash, idempotencyKey,
  }) {
    // Surface-level invariant (mirrors SQL CHECK): confirmed ⇔ confirmedAt present.
    for (const entry of entries) {
      if (entry.state === 'confirmed' && entry.confirmedAt == null) {
        throw new HttpError(400, 'invalid_request',
          'A confirmed capability must carry confirmedAt.');
      }
      if (entry.state !== 'confirmed' && entry.confirmedAt != null) {
        throw new HttpError(400, 'invalid_request',
          'confirmedAt must be omitted unless state is confirmed.');
      }
    }
    return port.idempotent(
      `capabilities:snapshot:${deviceId}`,
      idempotencyKey,
      requestHash,
      async (tx) => {
        const device = await authorizeDevice(tx, { principal, deviceCredential, deviceId });
        const reportedAt = now();
        const changed = [];
        for (const entry of entries) {
          const prior = await port.readCapability(tx, {
            deviceId, capabilityKey: entry.capabilityKey,
          });
          const row = await port.upsertCapability(tx, {
            deviceId,
            familyId: device.family_id,
            capabilityKey: entry.capabilityKey,
            state: entry.state,
            evidence: entry.evidence,
            appVersion: entry.appVersion,
            osVersion: entry.osVersion,
            confirmedAt: entry.confirmedAt,
            reportedAt,
          });
          if (prior === null || prior.state !== row.state) {
            changed.push(capabilityView(row));
            await port.appendCapabilityChangedEvent(tx, {
              familyId: device.family_id,
              childId: device.child_id,
              deviceId,
              capabilityKey: entry.capabilityKey,
              state: entry.state,
              priorState: prior?.state ?? null,
            });
          }
        }
        return {
          deviceId,
          reportedAt: reportedAt.toISOString(),
          capabilities: changed,
        };
      },
    );
  }

  async function readForChild({ principal, familyId, childId }) {
    return port.withTransaction(async (tx) => {
      await port.authorize(tx, { familyId, subject: principal.subject, primaryGuardianOnly: true });
      await port.verifyChildInFamily(tx, { familyId, childId });
      const rows = await port.readCapabilitiesForChild(tx, { familyId, childId });
      const byDevice = new Map();
      for (const row of rows) {
        if (!byDevice.has(row.device_id)) {
          byDevice.set(row.device_id, { deviceId: row.device_id, capabilities: {} });
        }
        byDevice.get(row.device_id).capabilities[row.capability_key] = capabilityView(row);
      }
      return {
        familyId,
        childId,
        devices: [...byDevice.values()],
      };
    });
  }

  return { reportSnapshot, readForChild };
}

/**
 * PostgreSQL port. Statements against the table created in migration 117.
 */
export function postgresDeviceCapabilityPort(store, { credentialMatches }) {
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

    async readDeviceIdentity(client, { deviceId }) {
      const { rows } = await client.query(
        `SELECT id, family_id, child_id, credential_hash, credential_revoked_at
           FROM family_child_devices
          WHERE id = $1`,
        [deviceId],
      );
      return rows[0] ?? null;
    },

    async verifyChildInFamily(client, { familyId, childId }) {
      const { rows } = await client.query(
        `SELECT id FROM family_children
          WHERE family_id = $1 AND id = $2 AND archived_at IS NULL`,
        [familyId, childId],
      );
      if (rows.length === 0) {
        throw new HttpError(404, 'child_not_found', 'The child was not found in this family.');
      }
    },

    async readCapability(client, { deviceId, capabilityKey }) {
      const { rows } = await client.query(
        `SELECT * FROM family_device_capabilities
          WHERE device_id = $1 AND capability_key = $2`,
        [deviceId, capabilityKey],
      );
      return rows[0] ?? null;
    },

    async readCapabilitiesForChild(client, { familyId, childId }) {
      const { rows } = await client.query(
        `SELECT dc.*
           FROM family_device_capabilities dc
           JOIN family_child_devices d ON d.id = dc.device_id
          WHERE d.family_id = $1 AND d.child_id = $2
          ORDER BY d.id, dc.capability_key`,
        [familyId, childId],
      );
      return rows;
    },

    async upsertCapability(client, {
      deviceId, familyId, capabilityKey, state, evidence,
      appVersion, osVersion, confirmedAt, reportedAt,
    }) {
      const { rows } = await client.query(
        `INSERT INTO family_device_capabilities
           (device_id, family_id, capability_key, state, evidence,
            app_version, os_version, confirmed_at, reported_at)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
         ON CONFLICT (device_id, capability_key) DO UPDATE SET
           state = EXCLUDED.state,
           evidence = EXCLUDED.evidence,
           app_version = EXCLUDED.app_version,
           os_version = EXCLUDED.os_version,
           confirmed_at = EXCLUDED.confirmed_at,
           reported_at = EXCLUDED.reported_at
         RETURNING *`,
        [deviceId, familyId, capabilityKey, state, evidence,
         appVersion, osVersion, confirmedAt, reportedAt],
      );
      return rows[0];
    },

    /**
     * Append an outbox row + ai_event for a capability state change (R6: same tx).
     * Uses a direct INSERT with the new envelope columns because `appendAiEvent`
     * registry currently only knows v1 types; S0 adds a `device.capability.changed`
     * fact directly.
     */
    async appendCapabilityChangedEvent(client, {
      familyId, childId, deviceId, capabilityKey, state, priorState,
    }) {
      const correlationId = randomUUID();
      await store.appendAuditAndOutbox(client, {
        familyId,
        actorMembershipId: null,
        correlationId,
        eventType: `device.capability.changed`,
        subjectType: 'child_device',
        subjectId: deviceId,
        payload: { childId, capabilityKey, state, priorState },
      });
      // Source_trust = 'reported' (the device itself told us); data_quality = 'fresh'.
      await client.query(
        `INSERT INTO ai_events
           (id, schema_version, event_type, family_id, child_id, device_id,
            policy_version, source, confidence, explanation, reject_path, correlation_id,
            source_trust, data_quality, visibility_class, retention_class,
            capability_key, causality_id, severity)
         VALUES ($1,'ai-event.v1','device.capability.changed',$2,$3,$4,
                 'permission-policy.v1','server',1,
                 'Device capability state changed.',NULL,$5,
                 'reported','fresh','guardian','realtime',
                 $6,NULL,'notice')`,
        [randomUUID(), familyId, childId, deviceId, correlationId, capabilityKey],
      );
    },
  };
}

export function deviceCapabilitiesFor(store, { credentialMatches }) {
  return createDeviceCapabilitySurface({
    port: postgresDeviceCapabilityPort(store, { credentialMatches }),
  });
}
