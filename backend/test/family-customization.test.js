// Programme «family character», slice 1 — the profile laws, in unit form.
//
// The reading that matters: a family that never opened this screen must see exactly what it sees
// today, so the default is not an empty week but the app's own behaviour; and because every other
// system reads these values, a write must be refused rather than guessed at — a stale version, an
// empty rest list, a non-primary guardian, or a word that is not one of the four the app speaks with.
import assert from 'node:assert/strict';
import test from 'node:test';

import {
  CUSTOMIZATION_DAYS,
  FAMILY_CUSTOMIZATION_DEFAULTS,
  FamilyCustomizationError,
  customizationIsoWeekday,
  familyCustomizationFor,
  familyCustomizationView,
} from '../src/family-customization.js';

const FAMILY = '11111111-1111-4111-8111-111111111111';
const PRIMARY = '22222222-2222-4222-8222-222222222222';
const CO_GUARDIAN = '33333333-3333-4333-8333-333333333333';

function storedRow(overrides = {}) {
  const rest = new Set(overrides.restDays ?? ['fri', 'sat']);
  return {
    family_id: FAMILY,
    week_start_day: overrides.weekStartDay ?? 'mon',
    numerals: overrides.numerals ?? 'western',
    rest_sunday: rest.has('sun'),
    rest_monday: rest.has('mon'),
    rest_tuesday: rest.has('tue'),
    rest_wednesday: rest.has('wed'),
    rest_thursday: rest.has('thu'),
    rest_friday: rest.has('fri'),
    rest_saturday: rest.has('sat'),
    guardian_labels: overrides.guardianLabels ?? {},
    version: overrides.version ?? 1,
    updated_by_membership_id: overrides.updatedBy ?? PRIMARY,
    updated_at: overrides.updatedAt == null ? null : new Date(overrides.updatedAt),
  };
}

function profileHarness(initialRow = null) {
  const state = {
    row: initialRow,
    audit: [],
    raceAfterRead: null,
    subjects: new Map([
      ['primary', { id: PRIMARY, role: 'primary_guardian' }],
      ['co-guardian', { id: CO_GUARDIAN, role: 'co_guardian' }],
    ]),
  };

  const client = {
    async query(sql, values = []) {
      if (sql.includes('FROM family_customization_profiles')) {
        if (state.raceAfterRead != null) {
          const race = state.raceAfterRead;
          state.raceAfterRead = null;
          race(state);
        }
        return { rows: state.row == null ? [] : [{ ...state.row }] };
      }
      if (sql.includes('INSERT INTO family_customization_profiles')) {
        const expectedVersion = values[13];
        const currentVersion = state.row?.version ?? 0;
        // `WHERE family_customization_profiles.version = $13` — the same refusal the read gives,
        // for a row that moved between the lock and this statement.
        if (currentVersion !== expectedVersion) return { rows: [] };
        state.row = {
          family_id: values[0],
          week_start_day: values[1],
          numerals: values[2],
          rest_sunday: values[3],
          rest_monday: values[4],
          rest_tuesday: values[5],
          rest_wednesday: values[6],
          rest_thursday: values[7],
          rest_friday: values[8],
          rest_saturday: values[9],
          guardian_labels: JSON.parse(values[10]),
          version: values[11],
          updated_by_membership_id: values[12],
          updated_at: new Date('2026-10-26T00:00:00.000Z'),
        };
        return { rows: [{ ...state.row }] };
      }
      throw new Error(`Unexpected customization SQL: ${sql}`);
    },
  };

  const store = {
    async withTransaction(work) {
      return work(client);
    },
    async activeActorMembership(_client, familyId, subject) {
      if (familyId !== FAMILY || !state.subjects.has(subject)) {
        throw new Error('No active membership');
      }
      return { ...state.subjects.get(subject) };
    },
    async appendAuditAndOutbox(_client, record) {
      state.audit.push(record);
    },
  };

  return { state, profiles: familyCustomizationFor(store) };
}

test('a family that never wrote a profile is reported as the default view, not as an empty week', async () => {
  const { profiles } = profileHarness(null);
  const { profile } = await profiles.read({ principal: { subject: 'primary' }, familyId: FAMILY });

  assert.deepEqual(profile, {
    version: 0,
    weekStartDay: 'mon',
    numerals: 'western',
    restDays: ['fri', 'sat'],
    guardianLabels: {},
    updatedAt: null,
    updatedByMembershipId: null,
    updatedAt: null,
    updatedByMembershipId: null,
    source: 'default',
  });
  assert.equal(profile.version, FAMILY_CUSTOMIZATION_DEFAULTS.version);
});

test('rest days are listed in canonical day order, whatever order the row was written in', () => {
  const view = familyCustomizationView(storedRow({ restDays: ['sat', 'fri', 'sun'] }));
  assert.deepEqual(view.restDays, ['sun', 'fri', 'sat']);
  assert.deepEqual(CUSTOMIZATION_DAYS.map(customizationIsoWeekday), [7, 1, 2, 3, 4, 5, 6]);
});

test('a stored word that is not a word, or not one of the four, never reaches the app', () => {
  // `constructor` is the shape of the risk: this object is spread into copy, so an inherited key
  // arriving from jsonb must not become a name on a child's screen.
  const row = storedRow({ guardianLabels: JSON.parse('{"father":"بابا","constructor":"x","mother":"","child":7}') });
  assert.deepEqual(familyCustomizationView(row).guardianLabels, { father: 'بابا' });
});

test('only the primary guardian may change what the whole family reads', async () => {
  const { state, profiles } = profileHarness(null);
  await assert.rejects(
    profiles.update({
      principal: { subject: 'co-guardian' },
      familyId: FAMILY,
      change: { weekStartDay: 'sat' },
      expectedVersion: 0,
      correlationId: 'correlation-co',
    }),
    (error) => error instanceof FamilyCustomizationError
      && error.status === 403
      && error.code === 'customization_primary_guardian_required',
  );
  assert.equal(state.row, null, 'a refused write stores nothing');
  assert.equal(state.audit.length, 0, 'a refused write leaves no trace claiming otherwise');
});

test('a write stores the family’s own week, rest days and words, and records who did it', async () => {
  const { state, profiles } = profileHarness(null);
  const { profile } = await profiles.update({
    principal: { subject: 'primary' },
    familyId: FAMILY,
    change: {
      weekStartDay: 'sat',
      restDays: ['thu', 'fri'],
      numerals: 'eastern',
      labels: { father: 'بابا', mother: 'حبيبتي' },
    },
    expectedVersion: 0,
    correlationId: 'correlation-primary',
  });

  assert.equal(profile.version, 1);
  assert.equal(profile.weekStartDay, 'sat');
  assert.equal(profile.numerals, 'eastern', 'a family that chose its digits gets them stored');
  assert.deepEqual(profile.restDays, ['thu', 'fri']);
  assert.deepEqual(profile.guardianLabels, { father: 'بابا', mother: 'حبيبتي' });
  assert.equal(profile.source, 'family');
  assert.equal(profile.updatedByMembershipId, PRIMARY);

  // One boolean per day, so a rest day cannot be typed twice or spelled differently.
  assert.equal(state.row.numerals, 'eastern');
  assert.equal(state.row.rest_thursday, true);
  assert.equal(state.row.rest_friday, true);
  assert.equal(state.row.rest_saturday, false, 'a rest list replaces the week, it does not grow one');
  assert.equal(state.row.rest_monday, false);

  assert.equal(state.audit.length, 1);
  assert.equal(state.audit[0].eventType, 'family.customization_updated');
  assert.equal(state.audit[0].subjectType, 'family_customization_profile');
  assert.equal(state.audit[0].actorMembershipId, PRIMARY);
});

test('an omitted word survives and a null word is dropped', async () => {
  const { profiles } = profileHarness(storedRow({
    version: 3,
    guardianLabels: { father: 'بابا', mother: 'ماما', child: 'يا صغيري' },
  }));
  const { profile } = await profiles.update({
    principal: { subject: 'primary' },
    familyId: FAMILY,
    change: { labels: { mother: 'حبيبتي', father: null } },
    expectedVersion: 3,
    correlationId: 'correlation-labels',
  });

  assert.deepEqual(profile.guardianLabels, { child: 'يا صغيري', mother: 'حبيبتي' });
  assert.equal(profile.version, 4);
});

test('a week with no rest day is refused by name, because every weekday rule is measured against it', async () => {
  const { state, profiles } = profileHarness(storedRow({ version: 2, restDays: ['fri', 'sat'] }));
  await assert.rejects(
    profiles.update({
      principal: { subject: 'primary' },
      familyId: FAMILY,
      change: { restDays: [] },
      expectedVersion: 2,
      correlationId: 'correlation-norestdays',
    }),
    (error) => error instanceof FamilyCustomizationError
      && error.status === 400
      && error.code === 'customization_rest_day_required',
  );
  assert.deepEqual(state.row.restDays ?? ['fri', 'sat'], ['fri', 'sat'], 'the stored week is untouched');
  assert.equal(state.audit.length, 0);
});

test('a stale version is refused rather than silently winning over the other guardian’s change', async () => {
  const { profiles } = profileHarness(storedRow({ version: 5 }));
  await assert.rejects(
    profiles.update({
      principal: { subject: 'primary' },
      familyId: FAMILY,
      change: { weekStartDay: 'thu' },
      expectedVersion: 4,
      correlationId: 'correlation-stale',
    }),
    (error) => error instanceof FamilyCustomizationError
      && error.status === 409
      && error.code === 'customization_stale_version',
  );
});

test('a row that moves between the locked read and the write is refused the same way', async () => {
  const { state, profiles } = profileHarness(storedRow({ version: 5 }));
  // The race the version column exists for: the locked read saw version 5, and by the time the
  // statement ran the other guardian had already written. `WHERE … version = $13` returns no row.
  state.raceAfterRead = (inner) => {
    inner.row = { ...inner.row, version: 6 };
  };

  await assert.rejects(
    profiles.update({
      principal: { subject: 'primary' },
      familyId: FAMILY,
      change: { weekStartDay: 'thu' },
      expectedVersion: 5,
      correlationId: 'correlation-race',
    }),
    (error) => error instanceof FamilyCustomizationError
      && error.status === 409
      && error.code === 'customization_stale_version',
  );
  assert.equal(state.audit.length, 0, 'the loser does not audit a change it did not make');
});

test('reading is open to any active guardian of this family and to nobody else', async () => {
  const { profiles } = profileHarness(storedRow({ version: 1 }));
  const { profile } = await profiles.read({ principal: { subject: 'co-guardian' }, familyId: FAMILY });
  assert.equal(profile.source, 'family');

  await assert.rejects(
    profiles.read({ principal: { subject: 'stranger' }, familyId: FAMILY }),
    /No active membership/,
  );
});
