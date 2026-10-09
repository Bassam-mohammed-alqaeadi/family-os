import pg from 'pg';

const { Pool } = pg;
const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function requiredUuid(value, label) {
  if (typeof value !== 'string' || !UUID_PATTERN.test(value.trim())) {
    throw new Error(`${label} must be a UUID.`);
  }
  return value.trim();
}

export async function verifyAuditOutboxCorrelation({
  connectionString,
  familyId,
  correlationId,
  poolFactory = (options) => new Pool(options),
}) {
  if (typeof connectionString !== 'string' || !connectionString.trim()) {
    throw new Error('A database connection string is required.');
  }
  const verifiedFamilyId = requiredUuid(familyId, 'Family ID');
  const verifiedCorrelationId = requiredUuid(correlationId, 'Correlation ID');
  const pool = poolFactory({ connectionString: connectionString.trim(), max: 1 });
  const client = await pool.connect();
  let transactionOpen = false;

  try {
    await client.query('BEGIN READ ONLY ISOLATION LEVEL REPEATABLE READ');
    transactionOpen = true;
    const audit = await client.query(
      `SELECT id::text AS id
       FROM family_audit_events
       WHERE family_id = $1 AND correlation_id = $2
       ORDER BY id ASC`,
      [verifiedFamilyId, verifiedCorrelationId],
    );
    const outbox = await client.query(
      `SELECT payload->>'auditEventId' AS audit_event_id, status
       FROM outbox_events
       WHERE aggregate_id = $1 AND correlation_id = $2
       ORDER BY id ASC`,
      [verifiedFamilyId, verifiedCorrelationId],
    );
    await client.query('COMMIT');
    transactionOpen = false;

    if (audit.rowCount === 0) {
      throw new Error('No audit event exists for the supplied family/correlation evidence.');
    }
    if (outbox.rowCount === 0) {
      throw new Error('No outbox event exists for the supplied family/correlation evidence.');
    }

    const auditIds = new Set(audit.rows.map((row) => row.id));
    const linkedAuditIds = outbox.rows.map((row) => row.audit_event_id);
    if (linkedAuditIds.some((auditId) => !auditIds.has(auditId))) {
      throw new Error('An outbox event did not link to an audit event from the same correlation evidence.');
    }
    if (auditIds.size !== linkedAuditIds.length || new Set(linkedAuditIds).size !== auditIds.size) {
      throw new Error('Audit/outbox evidence is not one-to-one for the supplied correlation evidence.');
    }
    if (outbox.rows.some((row) => row.status !== 'pending')) {
      throw new Error('Outbox state is not pending while no consumer is authorized in this Foundation staging scope.');
    }

    return {
      checks: [
        'durable_audit_event_present',
        'durable_outbox_event_present',
        'audit_outbox_one_to_one_linked',
        'server_correlation_preserved',
        'outbox_pending_without_consumer',
      ],
      counts: { auditEvents: audit.rowCount, outboxEvents: outbox.rowCount },
    };
  } catch (error) {
    if (transactionOpen) {
      await client.query('ROLLBACK');
    }
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}
