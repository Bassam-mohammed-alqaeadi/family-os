// Family customization profile v1 — programme `08_FAMILY_CUSTOMIZATION_PROGRAMME.md`, slice 1.
//
// The owner's standing instruction is that each family bends this app to its own culture and vision,
// and meets those choices on the screens it actually uses. Three facts stood in code instead of in
// the family: which day a week grid opens with, which days this family rests, and what the app calls
// the people in it. This module makes all three data, and holds the line where flexibility ends:
// a family may rest every day of its week except one, but never none — "school days" is then
// undefined and every weekday rule silently flips.
//
// Scope is deliberate. Screen-time budgets, filter categories, task decisions and chat policy keep
// their own tables and their own endpoints, and this profile does not copy them: one capability, one
// truth (AGENTS.md §5). A missing row is not an error and not an empty week — it is the default view,
// so a family that never opened the screen sees exactly what it has always seen.
//
// Writes are family-wide and belong to the primary guardian, the same boundary the collaboration
// policy (110) holds. Any active guardian may read. Optimistic versioning means two guardians who
// read the same profile cannot lose one another's change in silence; the loser is refused and told
// to re-read.

import { HttpError } from './http-error.js';

/** Canonical day order. The wire and the view always list rest days in this order. */
export const CUSTOMIZATION_DAYS = Object.freeze(['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat']);

/** The two numeral systems a family may choose; the app renders every number through one reader. */
export const NUMERAL_SYSTEMS = Object.freeze(['western', 'eastern']);

/** The four addressing words this product speaks with. Migration 135 allows no other key. */
export const CUSTOMIZATION_LABEL_KEYS = Object.freeze(['father', 'mother', 'guardian', 'child']);

const REST_COLUMN_BY_DAY = Object.freeze({
  sun: 'rest_sunday',
  mon: 'rest_monday',
  tue: 'rest_tuesday',
  wed: 'rest_wednesday',
  thu: 'rest_thursday',
  fri: 'rest_friday',
  sat: 'rest_saturday',
});

export const FAMILY_CUSTOMIZATION_DEFAULTS = Object.freeze({
  version: 0,
  weekStartDay: 'mon',
  restDays: Object.freeze(['fri', 'sat']),
  numerals: 'western',
  guardianLabels: Object.freeze({}),
  updatedAt: null,
  updatedByMembershipId: null,
  source: 'default',
});

export class FamilyCustomizationError extends HttpError {
  constructor(status, code, message) {
    super(status, code, message);
    this.name = 'FamilyCustomizationError';
  }
}

/**
 * The four words as the app consumes them: a plain object, known keys only, and no inherited
 * prototype — this object is spread into widget copy, and a `constructor` key arriving from the
 * database must not become a word on a child's screen.
 */
function labelView(value) {
  if (value == null || typeof value !== 'object' || Array.isArray(value)) return {};
  const out = {};
  for (const key of CUSTOMIZATION_LABEL_KEYS) {
    const raw = value[key];
    if (typeof raw === 'string' && raw.trim() !== '') out[key] = raw;
  }
  return out;
}

function restDaysView(row) {
  return CUSTOMIZATION_DAYS.filter((day) => row[REST_COLUMN_BY_DAY[day]] === true);
}

export function familyCustomizationView(row) {
  if (row == null) {
    return {
      ...FAMILY_CUSTOMIZATION_DEFAULTS,
      restDays: [...FAMILY_CUSTOMIZATION_DEFAULTS.restDays],
      guardianLabels: {},
    };
  }
  return {
    version: Number(row.version),
    weekStartDay: row.week_start_day,
    // A row written before this column existed, or any value that is not the one legal word,
    // reads as the default rather than as a third numeral system.
    numerals: row.numerals === 'eastern' ? 'eastern' : 'western',
    restDays: restDaysView(row),
    guardianLabels: labelView(row.guardian_labels),
    updatedAt: row.updated_at == null ? null : new Date(row.updated_at).toISOString(),
    updatedByMembershipId: row.updated_by_membership_id ?? null,
    source: 'family',
  };
}

/** ISO weekday (Mon = 1 … Sun = 7) for a day key, so a client can rotate a grid without parsing names. */
export function customizationIsoWeekday(day) {
  const index = CUSTOMIZATION_DAYS.indexOf(day);
  if (index < 0) return null;
  return index === 0 ? 7 : index;
}

const PROFILE_COLUMNS = `family_id, week_start_day, numerals,
       rest_sunday, rest_monday, rest_tuesday, rest_wednesday, rest_thursday, rest_friday, rest_saturday,
       guardian_labels, version, updated_by_membership_id, updated_at`;

export function familyCustomizationFor(store) {
  return {
    async read({ principal, familyId }) {
      return store.withTransaction(async (client) => {
        await store.activeActorMembership(client, familyId, principal.subject);
        const { rows } = await client.query(
          `SELECT ${PROFILE_COLUMNS}
             FROM family_customization_profiles
            WHERE family_id = $1`,
          [familyId],
        );
        return { profile: familyCustomizationView(rows[0] ?? null) };
      });
    },

    async update({ principal, familyId, change, expectedVersion, correlationId }) {
      return store.withTransaction(async (client) => {
        const actor = await store.activeActorMembership(client, familyId, principal.subject);
        if (actor.role !== 'primary_guardian') {
          throw new FamilyCustomizationError(
            403,
            'customization_primary_guardian_required',
            'Only the primary guardian may change this family\'s character profile.',
          );
        }

        const { rows: currentRows } = await client.query(
          `SELECT ${PROFILE_COLUMNS}
             FROM family_customization_profiles
            WHERE family_id = $1
              FOR UPDATE`,
          [familyId],
        );
        const current = familyCustomizationView(currentRows[0] ?? null);
        if (current.version !== expectedVersion) {
          throw new FamilyCustomizationError(
            409,
            'customization_stale_version',
            'The family profile changed since it was read.',
          );
        }

        const weekStartDay = change.weekStartDay ?? current.weekStartDay;
        const numerals = change.numerals ?? current.numerals;
        const restDays = change.restDays ?? current.restDays;
        // The floor, stated here so the refusal names the field, and enforced again by
        // `family_customization_rest_day_exists` where an invented request cannot walk around it.
        if (restDays.length === 0) {
          throw new FamilyCustomizationError(
            400,
            'customization_rest_day_required',
            'A family must keep at least one rest day.',
          );
        }
        const resting = new Set(restDays);
        const labels = change.labels ?? null;
        const nextLabels = { ...current.guardianLabels };
        if (labels != null) {
          for (const [key, value] of Object.entries(labels)) {
            if (value == null) delete nextLabels[key];
            else nextLabels[key] = value;
          }
        }

        const nextVersion = current.version + 1;
        const { rows } = await client.query(
          `INSERT INTO family_customization_profiles
             (family_id, week_start_day, numerals,
              rest_sunday, rest_monday, rest_tuesday, rest_wednesday, rest_thursday, rest_friday, rest_saturday,
              guardian_labels, version, updated_by_membership_id, updated_at)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11::jsonb, $12, $13, NOW())
           ON CONFLICT (family_id) DO UPDATE SET
             week_start_day = EXCLUDED.week_start_day,
             numerals = EXCLUDED.numerals,
             rest_sunday = EXCLUDED.rest_sunday,
             rest_monday = EXCLUDED.rest_monday,
             rest_tuesday = EXCLUDED.rest_tuesday,
             rest_wednesday = EXCLUDED.rest_wednesday,
             rest_thursday = EXCLUDED.rest_thursday,
             rest_friday = EXCLUDED.rest_friday,
             rest_saturday = EXCLUDED.rest_saturday,
             guardian_labels = EXCLUDED.guardian_labels,
             version = EXCLUDED.version,
             updated_by_membership_id = EXCLUDED.updated_by_membership_id,
             updated_at = NOW()
           WHERE family_customization_profiles.version = $14
           RETURNING ${PROFILE_COLUMNS}`,
          [
            familyId,
            weekStartDay,
            numerals,
            resting.has('sun'),
            resting.has('mon'),
            resting.has('tue'),
            resting.has('wed'),
            resting.has('thu'),
            resting.has('fri'),
            resting.has('sat'),
            JSON.stringify(nextLabels),
            nextVersion,
            actor.id,
            expectedVersion,
          ],
        );
        if (rows[0] == null) {
          // The row moved between the locked read and this statement: a first write on a family
          // with no row yet cannot collide, but a versioned update can, and the answer is the same
          // refusal the read gave rather than a silently overwritten profile.
          throw new FamilyCustomizationError(
            409,
            'customization_stale_version',
            'The family profile changed since it was read.',
          );
        }
        await store.appendAuditAndOutbox(client, {
          familyId,
          actorMembershipId: actor.id,
          correlationId,
          subjectId: familyId,
          subjectType: 'family_customization_profile',
          eventType: 'family.customization_updated',
        });
        return { profile: familyCustomizationView(rows[0]) };
      });
    },
  };
}
