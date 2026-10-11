// Safety slice S0 (spine) — command lifecycle and receipts.
//
// Principle 3 (asynchronous commands): every intent is a row with an id, an idempotency
// key, an expiry, and a lifecycle:
//     accepted -> dispatched -> received -> applied | limited | rejected | expired | failed
//
// A late handset never applies an expired command without re-evaluation. A retry with the
// same idempotency key replays the first answer. Cancelling is a NEW command (not a row
// delete) — added in its own slice.
//
// S0 ships only three command types: lock_now, release_lock, refresh_policy.
// Dispatch (marking a row 'dispatched' when the device pulls it) happens at poll time
// handled by the next-wave notification/dispatch worker; the first POST creates the
// command in 'accepted', the receipt endpoint advances it to terminal state.
import { randomUUID } from 'node:crypto';
import { HttpError } from './http-error.js';

export const COMMAND_TYPES = Object.freeze(new Set([
  'lock_now',
  'release_lock',
  'refresh_policy',
]));

export const COMMAND_STATES = Object.freeze(new Set([
  'accepted',
  'dispatched',
  'received',
  'applied',
  'limited',
  'rejected',
  'expired',
  'failed',
]));

export const RECEIPT_KINDS = Object.freeze(new Set(['applied', 'limited', 'failed']));

/** Terminal states — no further transitions. */
export const TERMINAL_STATES = Object.freeze(new Set([
  'applied', 'limited', 'rejected', 'expired', 'failed',
]));

/** Map receipt_kind -> terminal state. */
const RECEIPT_TO_STATE = Object.freeze({
  applied: 'applied',
  limited: 'limited',
  failed: 'failed',
});

export function commandView(row) {
  const toIso = (value) => (value instanceof Date ? value.toISOString() : value ?? null);
  return {
    id: row.id,
    familyId: row.family_id,
    childId: row.child_id,
    deviceId: row.device_id,
    commandType: row.command_type,
    policyId: row.policy_id ?? null,
    policyVersion: row.policy_version ?? null,
    payload: row.payload ?? {},
    actorMembershipId: row.actor_membership_id ?? null,
    idempotencyKey: row.idempotency_key,
    priority: row.priority,
    expiresAt: toIso(row.expires_at),
    state: row.state,
    createdAt: toIso(row.created_at),
    dispatchedAt: toIso(row.dispatched_at),
    receivedAt: toIso(row.received_at),
    appliedAt: toIso(row.applied_at),
    failureReason: row.failure_reason ?? null,
  };
}

export function receiptView(row) {
  return {
    commandId: row.command_id,
    receiptKind: row.receipt_kind,
    effectiveState: row.effective_state ?? {},
    observedAtDevice: row.observed_at_device instanceof Date
      ? row.observed_at_device.toISOString() : String(row.observed_at_device),
    receivedAtServer: row.received_at_server instanceof Date
      ? row.received_at_server.toISOString() : String(row.received_at_server),
    failureReason: row.failure_reason ?? null,
  };
}

export function createCommandSurface({ port, now = () => new Date() }) {
  /** Guardian must be primary guardian in the family and the device must belong to the
   *  child + family named on the command. */
  async function authorizeGuardianForDevice(tx, { principal, familyId, childId, deviceId }) {
    await port.authorize(tx, { familyId, subject: principal.subject, primaryGuardianOnly: true });
    const device = await port.readDeviceForChild(tx, { familyId, childId, deviceId });
    if (device === null) {
      throw new HttpError(404, 'device_not_found',
        'The device was not found for this child in this family.');
    }
    return device;
  }

  async function authorizeDevice(tx, { deviceCredential, deviceId }) {
    const device = await port.readDeviceIdentity(tx, { deviceId });
    if (device === null) {
      throw new HttpError(404, 'device_not_found', 'Linked device was not found.');
    }
    if (device.credential_revoked_at != null
        || !port.credentialMatches(device.credential_hash, deviceCredential)) {
      throw new HttpError(401, 'invalid_device_credential',
        'The device credential is invalid or revoked.');
    }
    return device;
  }

  /**
   * Create a command from a guardian action. Returns the existing row if idempotency
   * replays (same family/device/idempotency_key).
   *
   * Validation: commandType must be in the S0 allow-list, expires_at must be in the
   * future, and the device must honestly report the supporting capability (checked
   * against the stored capability ledger, not guessed).
   */
  async function createCommand({
    principal, familyId, childId, deviceId, commandType,
    payload = {}, idempotencyKey, priority = 100, ttlSeconds = 120,
    policyId = null, policyVersion = null,
  }) {
    if (!COMMAND_TYPES.has(commandType)) {
      throw new HttpError(400, 'invalid_request', `commandType '${commandType}' is not enabled in this slice.`);
    }
    if (!Number.isInteger(priority) || priority < 0 || priority > 1000) {
      throw new HttpError(400, 'invalid_request', 'priority must be an integer in 0..1000.');
    }
    if (!Number.isInteger(ttlSeconds) || ttlSeconds < 5 || ttlSeconds > 3600) {
      throw new HttpError(400, 'invalid_request', 'ttlSeconds must be an integer in 5..3600.');
    }
    return port.idempotent(
      `command:create:${familyId}:${deviceId}:${commandType}`,
      idempotencyKey,
      { commandType, payload, ttlSeconds, priority },
      async (tx) => {
        await authorizeGuardianForDevice(tx, { principal, familyId, childId, deviceId });
        // Capability gating: lock_now / release_lock require instant_lock;
        // refresh_policy has no capability precondition (it is a soft pull).
        if (commandType === 'lock_now' || commandType === 'release_lock') {
          const cap = await port.readCapability(tx, { deviceId, capabilityKey: 'instant_lock' });
          if (cap === null || cap.state !== 'confirmed') {
            throw new HttpError(409, 'capability_not_confirmed',
              'The instant_lock capability is not confirmed on this device.');
          }
        }
        const createdAt = now();
        const expiresAt = new Date(createdAt.getTime() + ttlSeconds * 1000);
        const membershipId = await port.activeActorMembershipId(tx, { familyId, subject: principal.subject });
        const row = await port.insertCommand(tx, {
          familyId, childId, deviceId, commandType,
          policyId, policyVersion, payload,
          actorMembershipId: membershipId,
          idempotencyKey, priority,
          expiresAt, createdAt,
        });
        await port.appendCommandEvent(tx, {
          familyId, childId, deviceId,
          commandId: row.id, commandType,
          eventType: 'command.dispatched',
          severity: commandType === 'lock_now' ? 'warning' : 'notice',
        });
        return { command: commandView(row) };
      },
    );
  }

  /**
   * Record a receipt from the device. The command must exist, must belong to this
   * device, and must not already be terminal. An expired command is refused (the device
   * must ask for a fresh policy rather than act on a stale intent).
   */
  async function recordReceipt({
    deviceCredential, deviceId, commandId, receiptKind,
    effectiveState = {}, observedAtDevice, failureReason = null,
    idempotencyKey, requestHash,
  }) {
    if (!RECEIPT_KINDS.has(receiptKind)) {
      throw new HttpError(400, 'invalid_request', 'receiptKind must be applied, limited, or failed.');
    }
    if (receiptKind === 'failed' && (!failureReason || failureReason.trim().length === 0)) {
      throw new HttpError(400, 'invalid_request', 'failed receipts must carry a failureReason.');
    }
    const observedAt = new Date(observedAtDevice);
    if (Number.isNaN(observedAt.getTime())) {
      throw new HttpError(400, 'invalid_request', 'observedAtDevice must be an ISO-8601 instant.');
    }
    return port.idempotent(
      `command:receipt:${deviceId}:${commandId}`,
      idempotencyKey,
      requestHash,
      async (tx) => {
      const device = await authorizeDevice(tx, { deviceCredential, deviceId });
      const command = await port.readCommandForDevice(tx, { commandId, deviceId });
      if (command === null) {
        throw new HttpError(404, 'command_not_found', 'The command was not found for this device.');
      }
      if (TERMINAL_STATES.has(command.state)) {
        // Idempotent reply: replaying the same receipt returns existing state.
        const existing = await port.readReceipt(tx, { commandId });
        return {
          command: commandView(command),
          receipt: existing ? receiptView(existing) : null,
          note: 'command already terminal',
        };
      }
      const now_ = now();
      if (command.expires_at.getTime() <= now_.getTime()) {
        // Mark expired and refuse to apply (stale command safety).
        await port.transitionCommand(tx, {
          commandId, state: 'expired', at: now_, failureReason: 'command expired before delivery',
        });
        await port.appendCommandEvent(tx, {
          familyId: device.family_id, childId: command.child_id, deviceId,
          commandId, commandType: command.command_type,
          eventType: 'command.expired', severity: 'notice',
        });
        throw new HttpError(410, 'command_expired',
          'The command expired before it could be applied. Request a fresh policy.');
      }
      const receivedAt = now_;
      const targetState = RECEIPT_TO_STATE[receiptKind];
      const appliedAt = receiptKind === 'applied' ? receivedAt : null;
      const row = await port.transitionCommand(tx, {
        commandId, state: targetState, at: receivedAt, appliedAt,
        failureReason: receiptKind === 'failed' ? failureReason.trim().slice(0, 256) : null,
        setReceivedAt: true,
      });
      const receipt = await port.upsertReceipt(tx, {
        commandId, receiptKind, effectiveState, observedAtDevice: observedAt,
        receivedAtServer: receivedAt,
        failureReason: receiptKind === 'failed' ? failureReason.trim().slice(0, 256) : null,
      });
      await port.appendCommandEvent(tx, {
        familyId: device.family_id, childId: command.child_id, deviceId,
        commandId, commandType: command.command_type,
        eventType: receiptKind === 'applied' ? 'command.applied' : 'command.failed',
        severity: receiptKind === 'failed' ? 'warning' : 'notice',
      });
      return { command: commandView(row), receipt: receiptView(receipt) };
    });
  }

  /** Pull commands for a device in 'accepted' state (called on wake/poll). */
  async function pullPending({ deviceCredential, deviceId, limit = 20 }) {
    if (!Number.isInteger(limit) || limit < 1 || limit > 100) {
      throw new HttpError(400, 'invalid_request', 'limit must be 1..100.');
    }
    return port.withTransaction(async (tx) => {
      const device = await authorizeDevice(tx, { deviceCredential, deviceId });
      const now_ = now();
      // First, expire anything past expiry we haven't marked yet.
      await port.expireStaleCommands(tx, { deviceId, now: now_ });
      const rows = await port.pullPendingCommands(tx, { deviceId, limit, now: now_ });
      // Mark pulled rows 'dispatched' on the way out. This is the server-side moment of dispatch.
      const ids = rows.map((r) => r.id);
      if (ids.length > 0) {
        await port.markDispatched(tx, { ids, dispatchedAt: now_ });
      }
      return {
        deviceId,
        pulledAt: now_.toISOString(),
        commands: rows.map(commandView),
      };
    });
  }

  /** List commands for a family (guardian view). */
  async function listForFamily({ principal, familyId, limit = 50, state = null, childId = null, deviceId = null }) {
    if (!Number.isInteger(limit) || limit < 1 || limit > 200) {
      throw new HttpError(400, 'invalid_request', 'limit must be 1..200.');
    }
    if (state !== null && !COMMAND_STATES.has(state)) {
      throw new HttpError(400, 'invalid_request', 'state is not a known command state.');
    }
    if (childId !== null && !/^[0-9a-f-]{36}$/i.test(childId)) {
      throw new HttpError(400, 'invalid_request', 'childId must be a UUID.');
    }
    if (deviceId !== null && !/^[0-9a-f-]{36}$/i.test(deviceId)) {
      throw new HttpError(400, 'invalid_request', 'deviceId must be a UUID.');
    }
    return port.withTransaction(async (tx) => {
      await port.authorize(tx, { familyId, subject: principal.subject, primaryGuardianOnly: false });
      const rows = await port.listFamilyCommands(tx, { familyId, limit, state, childId, deviceId });
      // Attach receipts where present.
      const receipts = new Map();
      for (const cmd of rows) {
        const r = await port.readReceipt(tx, { commandId: cmd.id });
        if (r) receipts.set(cmd.id, receiptView(r));
      }
      return {
        familyId,
        commands: rows.map((row) => ({
          ...commandView(row),
          receipt: receipts.get(row.id) ?? null,
        })),
      };
    });
  }

  return { createCommand, recordReceipt, pullPending, listForFamily };
}

// ── PostgreSQL port ──────────────────────────────────────────────────────────────

export function postgresCommandPort(store, { credentialMatches }) {
  return {
    credentialMatches,

    async withTransaction(run) { return store.withTransaction(run); },

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
      const m = await store.activeActorMembership(client, familyId, subject, { primaryGuardianOnly: false });
      return m.id;
    },

    async readDeviceIdentity(client, { deviceId }) {
      const { rows } = await client.query(
        `SELECT id, family_id, child_id, credential_hash, credential_revoked_at
           FROM family_child_devices WHERE id = $1`,
        [deviceId],
      );
      return rows[0] ?? null;
    },

    async readDeviceForChild(client, { familyId, childId, deviceId }) {
      const { rows } = await client.query(
        `SELECT id, family_id, child_id
           FROM family_child_devices
          WHERE family_id = $1 AND child_id = $2 AND id = $3`,
        [familyId, childId, deviceId],
      );
      return rows[0] ?? null;
    },

    async readCapability(client, { deviceId, capabilityKey }) {
      const { rows } = await client.query(
        `SELECT * FROM family_device_capabilities
          WHERE device_id = $1 AND capability_key = $2`,
        [deviceId, capabilityKey],
      );
      return rows[0] ?? null;
    },

    async readCommandForDevice(client, { commandId, deviceId }) {
      const { rows } = await client.query(
        `SELECT * FROM family_commands WHERE id = $1 AND device_id = $2`,
        [commandId, deviceId],
      );
      return rows[0] ?? null;
    },

    async readReceipt(client, { commandId }) {
      const { rows } = await client.query(
        `SELECT * FROM family_command_receipts WHERE command_id = $1`,
        [commandId],
      );
      return rows[0] ?? null;
    },

    async insertCommand(client, {
      familyId, childId, deviceId, commandType, policyId, policyVersion, payload,
      actorMembershipId, idempotencyKey, priority, expiresAt, createdAt,
    }) {
      const { rows } = await client.query(
        `INSERT INTO family_commands
           (id, family_id, child_id, device_id, command_type,
            policy_id, policy_version, payload, actor_membership_id,
            idempotency_key, priority, expires_at, state, created_at)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8::jsonb,$9,$10,$11,$12,'accepted',$13)
         RETURNING *`,
        [randomUUID(), familyId, childId, deviceId, commandType,
         policyId, policyVersion, JSON.stringify(payload ?? {}), actorMembershipId,
         idempotencyKey, priority, expiresAt, createdAt],
      );
      return rows[0];
    },

    async transitionCommand(client, { commandId, state, at, appliedAt = null, failureReason = null, setReceivedAt = false }) {
      const sets = ['state = $2'];
      const params = [commandId, state];
      if (appliedAt) { params.push(appliedAt); sets.push(`applied_at = $${params.length}`); }
      if (failureReason !== null) { params.push(failureReason); sets.push(`failure_reason = $${params.length}`); }
      if (setReceivedAt) { sets.push('received_at = NOW()'); }
      const { rows } = await client.query(
        `UPDATE family_commands SET ${sets.join(', ')} WHERE id = $1 RETURNING *`,
        params,
      );
      return rows[0] ?? null;
    },

    async upsertReceipt(client, {
      commandId, receiptKind, effectiveState, observedAtDevice, receivedAtServer, failureReason,
    }) {
      const { rows } = await client.query(
        `INSERT INTO family_command_receipts
           (command_id, receipt_kind, effective_state, observed_at_device,
            received_at_server, failure_reason)
         VALUES ($1,$2,$3::jsonb,$4,$5,$6)
         ON CONFLICT (command_id) DO UPDATE SET
           receipt_kind = EXCLUDED.receipt_kind,
           effective_state = EXCLUDED.effective_state,
           observed_at_device = EXCLUDED.observed_at_device,
           received_at_server = EXCLUDED.received_at_server,
           failure_reason = EXCLUDED.failure_reason
         RETURNING *`,
        [commandId, receiptKind, JSON.stringify(effectiveState ?? {}),
         observedAtDevice, receivedAtServer, failureReason],
      );
      return rows[0];
    },

    async expireStaleCommands(client, { deviceId, now }) {
      await client.query(
        `UPDATE family_commands
            SET state = 'expired', failure_reason = 'command expired before delivery'
          WHERE device_id = $1
            AND state IN ('accepted','dispatched','received')
            AND expires_at <= $2`,
        [deviceId, now],
      );
    },

    async pullPendingCommands(client, { deviceId, limit, now }) {
      const { rows } = await client.query(
        `SELECT * FROM family_commands
          WHERE device_id = $1
            AND state = 'accepted'
            AND expires_at > $2
          ORDER BY priority DESC, created_at ASC, id ASC
          LIMIT $3`,
        [deviceId, now, limit],
      );
      return rows;
    },

    async markDispatched(client, { ids, dispatchedAt }) {
      await client.query(
        `UPDATE family_commands
            SET state = 'dispatched', dispatched_at = $2
          WHERE id = ANY($1::uuid[]) AND state = 'accepted'`,
        [ids, dispatchedAt],
      );
    },

    async listFamilyCommands(client, { familyId, limit, state, childId, deviceId }) {
      const conds = ['family_id = $1'];
      const params = [familyId];
      if (state) { params.push(state); conds.push(`state = $${params.length}`); }
      if (childId) { params.push(childId); conds.push(`child_id = $${params.length}`); }
      if (deviceId) { params.push(deviceId); conds.push(`device_id = $${params.length}`); }
      params.push(limit);
      const { rows } = await client.query(
        `SELECT * FROM family_commands
          WHERE ${conds.join(' AND ')}
          ORDER BY created_at DESC, id DESC
          LIMIT $${params.length}`,
        params,
      );
      return rows;
    },

    async appendCommandEvent(client, {
      familyId, childId, deviceId, commandId, commandType, eventType, severity,
    }) {
      const correlationId = randomUUID();
      await store.appendAuditAndOutbox(client, {
        familyId,
        actorMembershipId: null,
        correlationId,
        eventType,
        subjectType: 'family_command',
        subjectId: commandId,
        payload: { childId, deviceId, commandType },
      });
      await client.query(
        `INSERT INTO ai_events
           (id, schema_version, event_type, family_id, child_id, device_id,
            policy_version, source, confidence, explanation, reject_path, correlation_id,
            source_trust, data_quality, visibility_class, retention_class,
            capability_key, command_id, severity)
         VALUES ($1,'ai-event.v1',$2,$3,$4,$5,
                 'permission-policy.v1','server',1,
                 'Command lifecycle event.',NULL,$6,
                 'verified','fresh','guardian','realtime',
                 NULL,$7,$8)`,
        [randomUUID(), eventType, familyId, childId, deviceId,
         correlationId, commandId, severity],
      );
    },
  };
}

export function commandLifecycleFor(store, { credentialMatches }) {
  return createCommandSurface({
    port: postgresCommandPort(store, { credentialMatches }),
  });
}
