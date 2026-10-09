// The membership roster read, against a port that supplies rows.
//
// The visibility rule - who may read a family's roster - belongs to the Foundation store
// and is exercised where the real store runs, in postgres-integration.test.js. What is
// tested here is what this module itself decides: which rows a caller sees as their own,
// how the roster is ordered, and what it refuses to pass through. A fake port is the
// right instrument for that because the port is data access by contract.
import assert from 'node:assert/strict';
import test from 'node:test';
import { createMembershipRoster } from '../src/membership-roster.js';
import { HttpError } from '../src/http-error.js';

const PRIMARY = 'roster-primary';
const OTHER = 'roster-other';
const FAMILY = '11111111-1111-4111-8111-111111111111';

function row(overrides = {}) {
  return {
    id: '22222222-2222-4222-8222-222222222222',
    role: 'co_guardian',
    status: 'active',
    status_reason_code: null,
    version: 2,
    joined_at: new Date('2026-10-01T10:00:00.000Z'),
    status_changed_at: new Date('2026-10-01T10:00:00.000Z'),
    created_at: new Date('2026-10-01T09:00:00.000Z'),
    target_subject: OTHER,
    ...overrides,
  };
}

function rosterOver(rows, { authorize = async () => ({ id: 'actor' }) } = {}) {
  return createMembershipRoster({
    port: {
      async withTransaction(run) {
        return run(null);
      },
      authorize,
      async readMemberships() {
        return rows;
      },
    },
  });
}

test('isSelf is decided against the caller, not guessed from an identifier', async () => {
  const list = rosterOver([
    row({ id: 'a', status: 'active', target_subject: PRIMARY, created_at: new Date('2026-10-01T08:00:00Z') }),
    row({ id: 'b', status: 'active', target_subject: OTHER, created_at: new Date('2026-10-01T09:00:00Z') }),
  ]);

  const { memberships } = await list({ principal: { subject: PRIMARY }, familyId: FAMILY });
  assert.deepEqual(
    memberships.map((membership) => [membership.id, membership.isSelf]),
    [
      ['a', true],
      ['b', false],
    ],
  );
});

test('an invitation addressed to the caller is recognisable while it is still pending', async () => {
  // The one row a person must be able to identify before they are a member: the offer
  // waiting for them. It is not active membership, and it is still theirs.
  const list = rosterOver([row({ status: 'invited', target_subject: PRIMARY })]);

  const { memberships } = await list({ principal: { subject: PRIMARY }, familyId: FAMILY });
  assert.equal(memberships[0].status, 'invited');
  assert.equal(memberships[0].isSelf, true);
});

test('the roster carries no subject and no name the server cannot prove', async () => {
  const list = rosterOver([row({ target_subject: 'sensitive-subject-claim' })]);

  const { memberships } = await list({ principal: { subject: PRIMARY }, familyId: FAMILY });
  const serialized = JSON.stringify(memberships);
  assert.equal(
    serialized.includes('sensitive-subject-claim'),
    false,
    'an invitee identifier leaked into the roster response',
  );
  assert.deepEqual(Object.keys(memberships[0]).sort(), [
    'createdAt',
    'id',
    'isSelf',
    'joinedAt',
    'role',
    'status',
    'statusChangedAt',
    'statusReasonCode',
    'version',
  ]);
});

test('active members lead, then what is waiting, then what was cut off', async () => {
  const list = rosterOver([
    row({ id: 'removed', status: 'removed', created_at: new Date('2026-10-01T07:00:00Z') }),
    row({ id: 'invited', status: 'invited', created_at: new Date('2026-10-01T11:00:00Z') }),
    row({ id: 'active-old', status: 'active', created_at: new Date('2026-10-01T08:00:00Z') }),
    row({ id: 'revoked', status: 'revoked', created_at: new Date('2026-10-01T06:00:00Z') }),
    row({ id: 'active-new', status: 'active', created_at: new Date('2026-10-01T09:00:00Z') }),
  ]);

  const { memberships } = await list({ principal: { subject: PRIMARY }, familyId: FAMILY });
  assert.deepEqual(
    memberships.map((membership) => membership.id),
    ['active-old', 'active-new', 'invited', 'revoked', 'removed'],
  );
});

test('an unknown status refuses to be rendered rather than being guessed', async () => {
  const list = rosterOver([row({ status: 'suspended_in_anger' })]);

  await assert.rejects(
    () => list({ principal: { subject: PRIMARY }, familyId: FAMILY }),
    (error) => error instanceof HttpError && error.code === 'membership_status_unknown',
  );
});

test('the store decides visibility, and its refusal is what the caller gets', async () => {
  const list = rosterOver([row()], {
    authorize: async () => {
      throw new HttpError(403, 'family_access_denied', 'No permitted family membership.');
    },
  });

  await assert.rejects(
    () => list({ principal: { subject: 'stranger' }, familyId: FAMILY }),
    (error) => error.status === 403,
  );
});
