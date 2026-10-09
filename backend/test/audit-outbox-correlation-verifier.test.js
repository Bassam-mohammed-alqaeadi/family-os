import assert from 'node:assert/strict';
import test from 'node:test';
import { verifyAuditOutboxCorrelation } from '../src/audit-outbox-correlation-verifier.js';

const FAMILY_ID = '11111111-1111-4111-8111-111111111111';
const CORRELATION_ID = '22222222-2222-4222-8222-222222222222';

test('audit/outbox verifier uses a read-only transaction and proves one-to-one correlation evidence', async () => {
  const statements = [];
  let released = false;
  let ended = false;
  const client = {
    async query(sql, values) {
      statements.push({ sql, values });
      if (sql.startsWith('SELECT id::text')) {
        return { rowCount: 2, rows: [{ id: 'audit-1' }, { id: 'audit-2' }] };
      }
      if (sql.startsWith("SELECT payload->>'auditEventId'")) {
        return {
          rowCount: 2,
          rows: [
            { audit_event_id: 'audit-1', status: 'pending' },
            { audit_event_id: 'audit-2', status: 'pending' },
          ],
        };
      }
      return { rowCount: 0, rows: [] };
    },
    release() { released = true; },
  };

  const result = await verifyAuditOutboxCorrelation({
    connectionString: 'postgresql://unused-in-test',
    familyId: FAMILY_ID,
    correlationId: CORRELATION_ID,
    poolFactory: (options) => {
      assert.equal(options.max, 1);
      return {
        async connect() { return client; },
        async end() { ended = true; },
      };
    },
  });

  assert.deepEqual(result, {
    checks: [
      'durable_audit_event_present',
      'durable_outbox_event_present',
      'audit_outbox_one_to_one_linked',
      'server_correlation_preserved',
      'outbox_pending_without_consumer',
    ],
    counts: { auditEvents: 2, outboxEvents: 2 },
  });
  assert.equal(statements[0].sql, 'BEGIN READ ONLY ISOLATION LEVEL REPEATABLE READ');
  assert.equal(statements.at(-1).sql, 'COMMIT');
  assert.deepEqual(statements[1].values, [FAMILY_ID, CORRELATION_ID]);
  assert.deepEqual(statements[2].values, [FAMILY_ID, CORRELATION_ID]);
  assert.equal(released, true);
  assert.equal(ended, true);
});

test('audit/outbox verifier rolls back a failed read-only transaction without accepting mismatched evidence', async () => {
  const statements = [];
  const client = {
    async query(sql) {
      statements.push(sql);
      if (sql.startsWith("SELECT payload->>'auditEventId'")) {
        throw new Error('read failed');
      }
      if (sql.startsWith('SELECT id::text')) {
        return { rowCount: 1, rows: [{ id: 'audit-1' }] };
      }
      return { rowCount: 0, rows: [] };
    },
    release() {},
  };

  await assert.rejects(
    verifyAuditOutboxCorrelation({
      connectionString: 'postgresql://unused-in-test',
      familyId: FAMILY_ID,
      correlationId: CORRELATION_ID,
      poolFactory: () => ({ async connect() { return client; }, async end() {} }),
    }),
    /read failed/,
  );
  assert.ok(statements.includes('ROLLBACK'));
});
