import { randomUUID } from 'node:crypto';
import { HttpError } from './http-error.js';

/**
 * Web filtering and tamper resistance - the wave the master plan calls the hardest, and
 * hardest because of one trap: a product can look like it protects while protecting
 * nothing. A shield icon, a "protection is on" line, a green dot beside a child's name:
 * all of them can be drawn by a screen that has heard nothing at all.
 *
 * So the laws of this surface are stated once, here, and each one is checkable from the
 * outside:
 *
 *   1. HEALTH IS COMPUTED, NEVER STORED. A device's protection state is derived from its
 *      newest report and the clock. There is no `protected` column to go stale, and no
 *      code path that can set one - so "the app says protected" always means "a handset
 *      said something recent", or it is not said.
 *
 *   2. SILENCE IS NOT HEALTH. A device that has never reported, or has not reported
 *      within the freshness window, is `unverified`. Not `protected`, because nothing
 *      said so; and not `broken`, because a phone in a drawer is not a crisis. The one
 *      thing a family can never be shown here is a green light produced by absence.
 *
 *   3. FRESHNESS IS MEASURED ON THE SERVER'S CLOCK. A report's `observed_at` is kept as
 *      the handset's testimony, but how old a report is is measured from the moment the
 *      server heard it. A device clock is the first thing someone with something to hide
 *      moves; the receipt time is out of that reach. (Policy windows are the opposite
 *      case - migration 105 measures those in the family's own offset - because there the
 *      question is what time it is for this family, not how long since a device spoke.)
 *
 *   4. EVIDENCE IS APPEND-ONLY. Every protection report is kept forever. A report is
 *      never edited and never deleted, so a family asking "when did this start?" gets an
 *      answer instead of the newest row, and nobody can make the past read as protected.
 *
 *   5. A TEMPORARY ALLOW HAS AN END, AND THE END IS THE SERVER'S. An approval stores the
 *      minute it closes and how many minutes it was for, and it closes by itself - no
 *      cleanup job, no second request, no stored `expired` status to forget to write.
 *      `expired` is a computed answer about the clock, exactly like `blocked` is in
 *      screen time.
 *
 *   6. THE DECISION ORDER IS ONE ORDER, THE SAME ONE THE HANDSET USES. Blocklist, then an
 *      active temporary allow, then the allow list, then the keyword dictionary, then the
 *      category, then allow. The client's engine states the same precedence and a test
 *      compares the two, because a server that resolves an allowed host differently from
 *      the app is a family being told two things about the same page.
 *
 *   7. NO BROWSING LOG. This module stores decisions a family made and evidence a handset
 *      reported. It does not store which URLs a child tried to open. A filter that keeps
 *      that log is a surveillance product wearing a filter's clothes.
 *
 * Authorization, precisely:
 *
 *   read / write the family's filter policy      guardians. The child's own handset reads
 *                                                its policy through the device
 *                                                credential, which proves which child
 *                                                it is.
 *   ask for a temporary allow                    the child's device (device credential),
 *                                                or a guardian on a child's behalf.
 *   decide a temporary allow                     guardians. A child cannot open its own
 *                                                door.
 *   report protection state                      the child's own device credential - a
 *                                                report is testimony, and testimony has
 *                                                an owner. Nobody may report on a
 *                                                handset they are not.
 *   read the family's protection state           guardians.
 */

export const WEB_FILTER_LEVELS = Object.freeze(['strict', 'balanced', 'open']);

/**
 * The six categories a family can switch on, in the child's words and in the father's.
 * This list is the server's declaration; `web-filter.test.js` compares it, key by key,
 * with `WebFilterCategories.known` in the Flutter client, because a switch the server does
 * not accept is a switch that does nothing while looking like it does something.
 */
export const WEB_FILTER_CATEGORIES = Object.freeze([
  'adults',
  'gambling',
  'violence',
  'social',
  'games',
  'streaming',
]);

/** The level presets, identical to the client's `WebFilterPolicy.categoriesForLevel`. */
export const LEVEL_PRESETS = Object.freeze({
  strict: Object.freeze([...WEB_FILTER_CATEGORIES]),
  balanced: Object.freeze(['adults', 'gambling', 'violence']),
  open: Object.freeze([]),
});

export const PROTECTION_OBSERVED_STATES = Object.freeze([
  'healthy',
  'vpn_active',
  'profile_removed',
  'permission_revoked',
  'dns_bypassed',
  'device_admin_removed',
  'unsupported',
]);

/**
 * The states that mean somebody or something got between the family and the filter. Kept
 * as a list of tokens rather than a boolean so a family can be told WHAT was seen -
 * "a VPN is running" and "the filter profile was removed" are different conversations.
 */
export const TAMPER_OBSERVED_STATES = Object.freeze([
  'vpn_active',
  'profile_removed',
  'permission_revoked',
  'dns_bypassed',
  'device_admin_removed',
]);

/** Computed health values a family reads. `unverified` is a first-class answer, not an error. */
export const PROTECTION_HEALTH_STATES = Object.freeze([
  'protected',
  'at_risk',
  'unverified',
  'unsupported',
]);

/**
 * How long a report speaks for. Ninety minutes: long enough that a handset which is asleep,
 * offline or between wake-ups is not treated as abandoned, short enough that a device whose
 * reporting was silently disabled stops reading as protected inside the same morning.
 */
export const PROTECTION_FRESHNESS_MINUTES = 90;

export const TEMP_ALLOW_MINUTES_CEILING = 120;
export const TEMP_ALLOW_MAX_OPEN_QUESTIONS_PER_CHILD = 20;

const MAX_LIST_ENTRIES = 200;
const MAX_HOST_LENGTH = 253;
const MAX_KEYWORD_LENGTH = 64;
const HOST_PATTERN = /^[a-z0-9.-]+$/;

export class WebFilterError extends HttpError {
  constructor(status, code, message) {
    super(status, code, message);
    this.name = 'WebFilterError';
  }
}

/**
 * Normalizes a host the way both sides must agree to: lower case, no scheme, no port, no
 * trailing dot, no leading `www.` - because a family that blocks `example.com` and then
 * finds `www.example.com` open has been handed a switch that lies.
 */
export function normalizeHost(raw) {
  if (typeof raw !== 'string') return '';
  let host = raw.trim().toLowerCase();
  if (host === '') return '';
  host = host.replace(/^[a-z][a-z0-9+.-]*:\/\//, '');
  host = host.split('/')[0].split('?')[0].split('#')[0];
  host = host.replace(/:\d+$/, '');
  host = host.replace(/\.$/, '');
  host = host.replace(/^www\./, '');
  return host;
}

/** Every host a family stated, normalized and de-duplicated, in a stable order. */
export function normalizeHostList(values) {
  const seen = new Set();
  const out = [];
  for (const value of values ?? []) {
    const host = normalizeHost(value);
    if (host === '' || seen.has(host)) continue;
    seen.add(host);
    out.push(host);
  }
  return out.sort();
}

function hostMatches(host, listed) {
  return host === listed || host.endsWith(`.${listed}`);
}

export function hostInList(host, list) {
  const normalized = normalizeHost(host);
  if (normalized === '') return false;
  return list.some((entry) => hostMatches(normalized, entry));
}

/**
 * The one decision order. Identical to `WebFilterEngine.decide` in the client, and the
 * reason it is a function here rather than inline in a route: a rule that can be called
 * twice can be compared, and the test that compares it to the client's order is the only
 * thing standing between two implementations and two answers.
 */
export function evaluateWebRequest(policy, { host }) {
  const normalized = normalizeHost(host);
  if (normalized === '') {
    return { allowed: true, denySource: null, categoryKey: null, policyVersion: policy.version };
  }
  if (hostInList(normalized, policy.blockHosts)) {
    return { allowed: false, denySource: 'blocklist', categoryKey: null, policyVersion: policy.version };
  }
  if (hostInList(normalized, policy.activeTempAllows ?? [])) {
    return { allowed: true, denySource: null, categoryKey: null, policyVersion: policy.version };
  }
  if (hostInList(normalized, policy.allowHosts)) {
    return { allowed: true, denySource: null, categoryKey: null, policyVersion: policy.version };
  }
  const keyword = keywordHit(normalized, policy.dictionaryKeywords);
  if (keyword != null) {
    return { allowed: false, denySource: 'dictionary', categoryKey: null, policyVersion: policy.version };
  }
  const category = classifyHost(normalized);
  if (category != null && policy.enabledCategories.includes(category)) {
    return { allowed: false, denySource: 'category', categoryKey: category, policyVersion: policy.version };
  }
  return { allowed: true, denySource: null, categoryKey: null, policyVersion: policy.version };
}

function keywordHit(host, keywords) {
  for (const keyword of keywords ?? []) {
    const token = String(keyword).trim().toLowerCase();
    if (token !== '' && host.includes(token)) return token;
  }
  return null;
}

/**
 * The server's classifier for the six categories. It reads a host's labels rather than
 * fetching the page: this is the same declaration the client's engine makes, and neither
 * one claims to be a content classifier. A wrong guess here costs a family a blocked page
 * they can open with a temporary allow - which is why the allow path exists.
 */
export function classifyHost(rawHost) {
  const host = normalizeHost(rawHost);
  if (host === '') return null;
  const fixtures = {
    'adult.example': 'adults',
    'gambling.example': 'gambling',
    'casino.example': 'gambling',
    'violence.example': 'violence',
    'social.example': 'social',
    'games.example': 'games',
    'streaming.example': 'streaming',
  };
  if (fixtures[host] != null) return fixtures[host];
  const tokens = [
    ['adults', ['adult', 'porn', 'xxx']],
    ['gambling', ['gambling', 'casino', 'betting']],
    ['violence', ['violence', 'gore']],
    ['social', ['social', 'facebook', 'instagram', 'tiktok']],
    ['games', ['games', 'steam', 'roblox']],
    ['streaming', ['streaming', 'netflix', 'youtube', 'twitch']],
  ];
  for (const [category, needles] of tokens) {
    if (needles.some((needle) => host.includes(needle))) return category;
  }
  return null;
}

/**
 * The health a family is shown. Three inputs, no state: the newest report (or null), the
 * clock, and the freshness window. Every branch that could have returned `protected`
 * without evidence returns something else instead.
 */
export function computeProtectionHealth({ latestReport, now = new Date(), freshnessMinutes = PROTECTION_FRESHNESS_MINUTES }) {
  if (latestReport == null) {
    return {
      state: 'unverified',
      reason: 'never_reported',
      since: null,
      ageMinutes: null,
      detail: '',
      signals: [],
    };
  }
  const receivedAt = latestReport.reportedAt instanceof Date
    ? latestReport.reportedAt
    : new Date(latestReport.reportedAt);
  const ageMinutes = Math.max(0, Math.floor((now.getTime() - receivedAt.getTime()) / 60000));
  const base = {
    since: receivedAt,
    ageMinutes,
    detail: latestReport.detail ?? '',
    signals: [...(latestReport.signals ?? [])],
  };
  if (latestReport.observedState === 'unsupported') {
    // The platform cannot hold the plane. That is a fact about the phone, not a failure of
    // the child, and calling it "at risk" would blame the wrong party.
    return { ...base, state: 'unsupported', reason: 'platform_unsupported' };
  }
  if (ageMinutes > freshnessMinutes) {
    // Silence. Not protected - nothing recently said so - and not at risk, because nothing
    // said that either.
    return { ...base, state: 'unverified', reason: 'stale_report' };
  }
  if (TAMPER_OBSERVED_STATES.includes(latestReport.observedState)) {
    return { ...base, state: 'at_risk', reason: latestReport.observedState };
  }
  if (latestReport.observedState === 'healthy') {
    return { ...base, state: 'protected', reason: 'reported_healthy' };
  }
  // An observed state this server does not know: the handset said something specific and
  // we cannot classify it. Unknown is reported as unknown.
  return { ...base, state: 'unverified', reason: 'unrecognised_observation' };
}

/**
 * A temporary allow's own answer about the clock. `approved` and its end are stored; what
 * a family or a handset reads is this - so an approval that has run out never needs anyone
 * to remember to close it.
 */
export function tempAllowState(row, now = new Date()) {
  if (row.status === 'approved') {
    const expiresAt = row.expiresAt instanceof Date ? row.expiresAt : new Date(row.expiresAt);
    if (expiresAt.getTime() <= now.getTime()) return 'expired';
    return 'active';
  }
  return row.status;
}

/** The hosts a handset may open right now: approvals whose minute has not passed. */
export function activeTempAllowHosts(rows, now = new Date()) {
  const hosts = new Set();
  for (const row of rows) {
    if (tempAllowState(row, now) === 'active') hosts.add(row.host);
  }
  return [...hosts].sort();
}

const GUARDIAN_ROLES = new Set(['primary_guardian', 'co_guardian']);

function requireGuardian(actor, code, message) {
  if (actor == null || !GUARDIAN_ROLES.has(actor.role)) {
    throw new WebFilterError(403, code, message);
  }
}

function policyFromRow(row) {
  return {
    level: row.level,
    enabledCategories: [...row.enabled_categories],
    allowHosts: [...row.allow_hosts],
    blockHosts: [...row.block_hosts],
    dictionaryKeywords: [...row.dictionary_keywords],
    version: row.version,
    updatedAt: row.updated_at,
  };
}

function policyView(policy, now, rows) {
  return {
    ...policy,
    activeTempAllows: activeTempAllowHosts(rows, now),
  };
}

export const DEFAULT_WEB_FILTER_POLICY = Object.freeze({
  level: 'balanced',
  enabledCategories: Object.freeze([...LEVEL_PRESETS.balanced]),
  allowHosts: Object.freeze([]),
  blockHosts: Object.freeze([]),
  dictionaryKeywords: Object.freeze([]),
  version: 1,
});

/**
 * Merges a partial statement over what exists. A client sending one switch sends one
 * switch; a client that omits the lists leaves them as the family left them. Lists are
 * replaced, never merged, because removing a host from a list has to be possible, and a
 * merge is a rule that silently refuses the removal.
 */
export function mergePolicy(existing, change) {
  const level = change.level ?? existing.level;
  const categories = change.categories == null
    ? existing.enabledCategories
    : normalizeCategories(change.categories);
  const allowHosts = change.allowHosts == null ? existing.allowHosts : normalizeHostList(change.allowHosts);
  const blockHosts = change.blockHosts == null ? existing.blockHosts : normalizeHostList(change.blockHosts);
  const keywords = change.dictionaryKeywords == null
    ? existing.dictionaryKeywords
    : normalizeKeywords(change.dictionaryKeywords);
  return { level, enabledCategories: categories, allowHosts, blockHosts, dictionaryKeywords: keywords };
}

export function normalizeCategories(values) {
  const seen = new Set();
  for (const value of values ?? []) {
    const key = String(value).trim().toLowerCase();
    if (key === '') continue;
    if (!WEB_FILTER_CATEGORIES.includes(key)) {
      throw new WebFilterError(422, 'web_filter_unknown_category', `Unknown category: ${value}`);
    }
    seen.add(key);
  }
  return WEB_FILTER_CATEGORIES.filter((key) => seen.has(key));
}

export function normalizeKeywords(values) {
  const seen = new Set();
  for (const value of values ?? []) {
    const keyword = String(value).trim().toLowerCase();
    if (keyword === '') continue;
    if (keyword.length > MAX_KEYWORD_LENGTH) {
      throw new WebFilterError(422, 'web_filter_keyword_too_long', 'A dictionary keyword is too long.');
    }
    seen.add(keyword);
  }
  return [...seen].sort();
}

function requireCoherentPolicy(policy) {
  if (!WEB_FILTER_LEVELS.includes(policy.level)) {
    throw new WebFilterError(422, 'web_filter_unknown_level', 'Unknown filter level.');
  }
  if (policy.allowHosts.length > MAX_LIST_ENTRIES || policy.blockHosts.length > MAX_LIST_ENTRIES) {
    throw new WebFilterError(422, 'web_filter_list_too_long', 'A host list is too long.');
  }
  for (const host of [...policy.allowHosts, ...policy.blockHosts]) {
    if (host.length > MAX_HOST_LENGTH || !HOST_PATTERN.test(host)) {
      throw new WebFilterError(422, 'web_filter_host_invalid', `Not a hostname: ${host}`);
    }
  }
  const both = policy.allowHosts.filter((host) => policy.blockHosts.includes(host));
  if (both.length > 0) {
    // Blocklist wins in the engine, so an allow entry that is also blocked is a line on a
    // screen that does nothing. The family is told which host rather than handed a policy
    // that quietly disagrees with itself.
    throw new WebFilterError(409, 'web_filter_host_both_lists', `A host cannot be both allowed and blocked: ${both[0]}`);
  }
}

export function protectionView(device, latestReport, now) {
  const health = computeProtectionHealth({ latestReport, now });
  return {
    deviceId: device.id,
    deviceLabel: device.device_label,
    childId: device.child_id,
    state: health.state,
    reason: health.reason,
    since: health.since,
    ageMinutes: health.ageMinutes,
    detail: health.detail,
    signals: health.signals,
  };
}

/**
 * The one place the database's spelling becomes this module's spelling. The laws above read
 * `expiresAt`; PostgreSQL returns `expires_at`, and the gap between the two is where an
 * expired door silently reads as open. Found by the real-PostgreSQL journey, which is the
 * only test that ever sees a row the database shaped.
 */
function tempAllowFromRow(row) {
  return {
    id: row.id,
    familyId: row.family_id,
    childId: row.child_id,
    host: row.host,
    status: row.status,
    requestedMinutes: row.requested_minutes,
    grantedMinutes: row.granted_minutes,
    reason: row.reason,
    requestedByMembershipId: row.requested_by_membership_id,
    requestedByDeviceId: row.requested_by_device_id,
    decidedByMembershipId: row.decided_by_membership_id,
    decidedAt: row.decided_at,
    expiresAt: row.expires_at,
    createdAt: row.created_at,
  };
}

function deviceRowToReport(row) {
  return {
    id: row.id,
    observedState: row.observed_state,
    signals: [...row.signals],
    detail: row.detail,
    observedAt: row.observed_at,
    reportedAt: row.reported_at,
  };
}

// ---------------------------------------------------------------------------------------
// Operations. Each one is a factory over a port, so the SQL lives in one place (the port)
// and the law lives here - the shape migration 105's screen-time module established.
// ---------------------------------------------------------------------------------------

export function createWebFilterPolicyRead({ port }) {
  return async function readWebFilterPolicy({ principal, familyId, childId }) {
    return port.read(async (tx) => {
      const actor = await port.authorize(tx, { familyId, subject: principal.subject });
      requireGuardian(actor, 'web_filter_forbidden', 'Only a guardian may read this policy.');
      const row = await port.readPolicy(tx, { familyId, childId });
      const rows = await port.readTempAllows(tx, { familyId, childId });
      const now = new Date();
      if (row == null) return policyView({ ...DEFAULT_WEB_FILTER_POLICY }, now, rows);
      return policyView(policyFromRow(row), now, rows);
    });
  };
}

export function createWebFilterPolicyUpdate({ port }) {
  return async function updateWebFilterPolicy({
    principal,
    familyId,
    childId,
    change,
    expectedVersion = null,
    idempotencyKey,
    requestHash,
    correlationId,
  }) {
    return port.idempotent(
      `web-filter:policy:${familyId}:${childId}`,
      idempotencyKey,
      requestHash,
      async (tx) => {
        const actor = await port.authorize(tx, { familyId, subject: principal.subject });
        requireGuardian(actor, 'web_filter_forbidden', 'Only a guardian may change this policy.');
        const existing = await port.readPolicy(tx, { familyId, childId }, { forUpdate: true });
        if (existing == null) {
          const child = await port.readChild(tx, { familyId, childId });
          if (child == null) {
            throw new WebFilterError(404, 'child_not_found', 'This child is not part of the family.');
          }
        }
        if (expectedVersion != null) {
          const current = existing?.version ?? 0;
          if (current !== expectedVersion) {
            // Two guardians on two phones: the second save is refused rather than silently
            // overwriting the first, exactly as screen time refuses it.
            throw new WebFilterError(409, 'web_filter_stale_version', 'The policy changed since this screen read it.');
          }
        }
        const base = existing == null
          ? {
              level: DEFAULT_WEB_FILTER_POLICY.level,
              enabledCategories: [...DEFAULT_WEB_FILTER_POLICY.enabledCategories],
              allowHosts: [],
              blockHosts: [],
              dictionaryKeywords: [],
            }
          : policyFromRow(existing);
        const merged = mergePolicy(base, change);
        requireCoherentPolicy(merged);
        const row = await port.upsertPolicy(tx, {
          familyId,
          childId,
          policy: merged,
          actorMembershipId: actor.id,
        });
        await port.audit(tx, {
          familyId,
          actorMembershipId: actor.id,
          correlationId,
          subjectId: childId,
          subjectType: 'web_filter_policy',
          eventType: 'family.web_filter_policy_updated',
        });
        const rows = await port.readTempAllows(tx, { familyId, childId });
        return { policy: policyView(policyFromRow(row), new Date(), rows) };
      },
    );
  };
}

export function createEvaluateWebRequest({ port }) {
  return async function evaluateFamilyWebRequest({ principal, familyId, childId, host }) {
    return port.read(async (tx) => {
      const actor = await port.authorize(tx, { familyId, subject: principal.subject });
      requireGuardian(actor, 'web_filter_forbidden', 'Only a guardian may evaluate a request here.');
      const row = await port.readPolicy(tx, { familyId, childId });
      const rows = await port.readTempAllows(tx, { familyId, childId });
      const now = new Date();
      const policy = row == null
        ? { ...DEFAULT_WEB_FILTER_POLICY, allowHosts: [], blockHosts: [], dictionaryKeywords: [] }
        : policyFromRow(row);
      return {
        ...evaluateWebRequest({ ...policy, activeTempAllows: activeTempAllowHosts(rows, now) }, { host }),
        normalizedHost: normalizeHost(host),
      };
    });
  };
}

export function createTempAllowList({ port }) {
  return async function listTempAllows({ principal, familyId, childId }) {
    return port.read(async (tx) => {
      const actor = await port.authorize(tx, { familyId, subject: principal.subject });
      requireGuardian(actor, 'web_filter_forbidden', 'Only a guardian may read these requests.');
      const rows = await port.readTempAllows(tx, { familyId, childId });
      const now = new Date();
      return {
        requests: rows.map((row) => tempAllowView(row, now)),
        activeHosts: activeTempAllowHosts(rows, now),
      };
    });
  };
}

function tempAllowView(row, now) {
  return {
    id: row.id,
    host: row.host,
    status: row.status,
    state: tempAllowState(row, now),
    requestedMinutes: row.requestedMinutes,
    grantedMinutes: row.grantedMinutes,
    reason: row.reason,
    requestedByMembershipId: row.requestedByMembershipId,
    requestedByDeviceId: row.requestedByDeviceId,
    decidedByMembershipId: row.decidedByMembershipId,
    decidedAt: row.decidedAt,
    expiresAt: row.expiresAt,
    createdAt: row.createdAt,
  };
}

export function createTempAllowRequest({ port }) {
  return async function requestTempAllow({
    principal,
    deviceId,
    deviceCredential,
    familyId,
    childId,
    host,
    minutes,
    reason = '',
    idempotencyKey,
    requestHash,
    correlationId,
  }) {
    return port.idempotent(
      `web-filter:temp-allow:${familyId ?? deviceId}:${childId ?? 'self'}`,
      idempotencyKey,
      requestHash,
      async (tx) => {
        let effectiveFamilyId = familyId;
        let effectiveChildId = childId;
        let requesterMembershipId = null;
        let requesterDeviceId = null;
        if (deviceId != null) {
          const device = await port.readDevice(tx, { deviceId });
          if (device == null || device.credential_revoked_at != null || !port.credentialMatches(device.credential_hash, deviceCredential)) {
            throw new WebFilterError(403, 'device_credential_rejected', 'The device credential is not accepted.');
          }
          // The handset is the proof of which child is asking; a body cannot claim another.
          effectiveFamilyId = device.family_id;
          effectiveChildId = device.child_id;
          requesterDeviceId = device.id;
        } else {
          const actor = await port.authorize(tx, { familyId, subject: principal.subject });
          requireGuardian(actor, 'web_filter_forbidden', "Only a guardian may ask on a child's behalf.");
          requesterMembershipId = actor.id;
        }
        const normalizedHost = normalizeHost(host);
        if (normalizedHost === '' || normalizedHost.length > MAX_HOST_LENGTH || !HOST_PATTERN.test(normalizedHost)) {
          throw new WebFilterError(422, 'web_filter_host_invalid', 'A hostname is required.');
        }
        await port.lockOpenQuestion(tx, { childId: effectiveChildId, host: normalizedHost });
        const existingOpen = await port.readOpenQuestion(tx, { childId: effectiveChildId, host: normalizedHost });
        if (existingOpen != null) {
          // A question already waiting is not asked twice. The child sees the question it
          // asked; the guardians see one card, not a stack.
          throw new WebFilterError(409, 'web_filter_request_pending', 'This host is already waiting for an answer.');
        }
        const row = await port.insertTempAllow(tx, {
          familyId: effectiveFamilyId,
          childId: effectiveChildId,
          host: normalizedHost,
          requestedMinutes: minutes,
          reason: typeof reason === 'string' ? reason.slice(0, 300) : '',
          requestedByMembershipId: requesterMembershipId,
          requestedByDeviceId: requesterDeviceId,
        });
        await port.audit(tx, {
          familyId: effectiveFamilyId,
          actorMembershipId: requesterMembershipId,
          correlationId,
          subjectId: effectiveChildId,
          subjectType: 'web_filter_temp_allow',
          eventType: 'family.web_filter_temp_allow_requested',
        });
        return { request: tempAllowView(row, new Date()) };
      },
    );
  };
}

export function createTempAllowDecision({ port }) {
  return async function decideTempAllow({
    principal,
    familyId,
    childId,
    requestId,
    decision,
    grantedMinutes = null,
    idempotencyKey,
    requestHash,
    correlationId,
  }) {
    return port.idempotent(
      `web-filter:temp-allow-decision:${familyId}:${requestId}`,
      idempotencyKey,
      requestHash,
      async (tx) => {
        const actor = await port.authorize(tx, { familyId, subject: principal.subject });
        requireGuardian(actor, 'web_filter_forbidden', 'Only a guardian may answer this request.');
        const existing = await port.readTempAllow(tx, { familyId, childId, requestId }, { forUpdate: true });
        if (existing == null) {
          throw new WebFilterError(404, 'web_filter_request_not_found', 'This request is not part of the family.');
        }
        const now = new Date();
        if (tempAllowState(existing, now) !== 'pending') {
          // Answered once is answered. A second answer would either extend a door nobody
          // re-asked for or deny something already open.
          throw new WebFilterError(409, 'web_filter_request_decided', 'This request has already been answered.');
        }
        if (decision === 'deny') {
          const row = await port.decideTempAllow(tx, {
            requestId,
            status: 'denied',
            grantedMinutes: null,
            expiresAt: null,
            decidedByMembershipId: actor.id,
          });
          await port.audit(tx, {
            familyId,
            actorMembershipId: actor.id,
            correlationId,
            subjectId: existing.childId,
            subjectType: 'web_filter_temp_allow',
            eventType: 'family.web_filter_temp_allow_denied',
          });
          return { request: tempAllowView(row, now) };
        }
        // Approve. The granted minutes are the guardian's, never the child's ask widened,
        // and they can never run past the ceiling or past what was requested.
        const wanted = grantedMinutes == null ? existing.requestedMinutes : grantedMinutes;
        if (!Number.isInteger(wanted) || wanted < 1 || wanted > TEMP_ALLOW_MINUTES_CEILING) {
          throw new WebFilterError(422, 'web_filter_grant_out_of_range', `Granted minutes must be between 1 and ${TEMP_ALLOW_MINUTES_CEILING}.`);
        }
        if (wanted > existing.requestedMinutes) {
          throw new WebFilterError(409, 'web_filter_grant_exceeds_request', 'The grant cannot exceed what was asked for.');
        }
        const expiresAt = new Date(now.getTime() + wanted * 60000);
        const row = await port.decideTempAllow(tx, {
          requestId,
          status: 'approved',
          grantedMinutes: wanted,
          expiresAt,
          decidedByMembershipId: actor.id,
        });
        await port.audit(tx, {
          familyId,
          actorMembershipId: actor.id,
          correlationId,
          subjectId: existing.childId,
          subjectType: 'web_filter_temp_allow',
          eventType: 'family.web_filter_temp_allow_approved',
        });
        return { request: tempAllowView(row, now) };
      },
    );
  };
}

export function createProtectionReportSubmit({ port }) {
  return async function reportDeviceProtection({
    deviceId,
    deviceCredential,
    observedState,
    signals = [],
    detail = '',
    observedAt = null,
    correlationId,
  }) {
    return port.withTransaction(async (tx) => {
      const device = await port.readDevice(tx, { deviceId });
      if (device == null || device.credential_revoked_at != null || !port.credentialMatches(device.credential_hash, deviceCredential)) {
        throw new WebFilterError(403, 'device_credential_rejected', 'The device credential is not accepted.');
      }
      if (!PROTECTION_OBSERVED_STATES.includes(observedState)) {
        throw new WebFilterError(422, 'web_filter_observation_unknown', 'Unknown protection observation.');
      }
      const row = await port.insertProtectionReport(tx, {
        familyId: device.family_id,
        childId: device.child_id,
        deviceId: device.id,
        observedState,
        signals: [...signals].map((signal) => String(signal).slice(0, 64)).slice(0, 32),
        detail: typeof detail === 'string' ? detail.slice(0, 500) : '',
        observedAt: observedAt ?? new Date(),
      });
      // The device also keeps its own `last_seen_at` true, because a handset that is
      // talking about its protection is a handset that is talking.
      await port.touchDeviceSeen(tx, { deviceId: device.id });
      await port.audit(tx, {
        familyId: device.family_id,
        actorMembershipId: null,
        correlationId,
        subjectId: device.id,
        subjectType: 'device_protection',
        eventType: 'family.device_protection_reported',
      });
      const latest = await port.readLatestProtectionReport(tx, { deviceId: device.id });
      return { report: deviceRowToReport(row), health: protectionView(device, latest, new Date()) };
    });
  };
}

export function createProtectionRead({ port }) {
  return async function readFamilyProtection({ principal, familyId }) {
    return port.read(async (tx) => {
      const actor = await port.authorize(tx, { familyId, subject: principal.subject });
      requireGuardian(actor, 'web_filter_forbidden', 'Only a guardian may read the family protection state.');
      const devices = await port.readFamilyDevices(tx, { familyId });
      const now = new Date();
      const items = [];
      for (const device of devices) {
        const latest = await port.readLatestProtectionReport(tx, { deviceId: device.id });
        items.push(protectionView(device, latest, now));
      }
      const counts = { protected: 0, at_risk: 0, unverified: 0, unsupported: 0 };
      for (const item of items) counts[item.state] += 1;
      return { devices: items, counts, freshnessMinutes: PROTECTION_FRESHNESS_MINUTES };
    });
  };
}

export function createDevicePolicyRead({ port }) {
  return async function readPolicyForDevice({ deviceId, deviceCredential }) {
    return port.read(async (tx) => {
      const device = await port.readDevice(tx, { deviceId });
      if (device == null || device.credential_revoked_at != null || !port.credentialMatches(device.credential_hash, deviceCredential)) {
        throw new WebFilterError(403, 'device_credential_rejected', 'The device credential is not accepted.');
      }
      const row = await port.readPolicy(tx, { familyId: device.family_id, childId: device.child_id });
      const rows = await port.readTempAllows(tx, { familyId: device.family_id, childId: device.child_id });
      const now = new Date();
      const policy = row == null
        ? { ...DEFAULT_WEB_FILTER_POLICY, allowHosts: [], blockHosts: [], dictionaryKeywords: [] }
        : policyFromRow(row);
      return { policy: policyView(policy, now, rows) };
    });
  };
}

export function webFilterFor(store, { credentialMatches }) {
  const port = postgresWebFilterPort(store, { credentialMatches });
  return {
    readPolicy: createWebFilterPolicyRead({ port }),
    updatePolicy: createWebFilterPolicyUpdate({ port }),
    evaluate: createEvaluateWebRequest({ port }),
    listTempAllows: createTempAllowList({ port }),
    requestTempAllow: createTempAllowRequest({ port }),
    decideTempAllow: createTempAllowDecision({ port }),
    reportProtection: createProtectionReportSubmit({ port }),
    readProtection: createProtectionRead({ port }),
    readPolicyForDevice: createDevicePolicyRead({ port }),
  };
}

const POLICY_COLUMNS = `child_id, family_id, level, enabled_categories, allow_hosts, block_hosts,
                        dictionary_keywords, version, updated_by_membership_id, updated_at`;

const TEMP_ALLOW_COLUMNS = `id, family_id, child_id, host, status, requested_minutes, granted_minutes,
                            reason, requested_by_membership_id, requested_by_device_id,
                            decided_by_membership_id, decided_at, expires_at, created_at`;

const REPORT_COLUMNS = `id, family_id, child_id, device_id, observed_state, signals, detail,
                        observed_at, reported_at`;

export function postgresWebFilterPort(store, { credentialMatches }) {
  return {
    credentialMatches,

    async withTransaction(run) {
      return store.withTransaction(run);
    },

    async read(run) {
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

    async authorize(client, { familyId, subject }) {
      return store.activeActorMembership(client, familyId, subject);
    },

    async readChild(client, { familyId, childId }) {
      const { rows } = await client.query(
        `SELECT id FROM family_children WHERE family_id = $1 AND id = $2`,
        [familyId, childId],
      );
      return rows[0] ?? null;
    },

    async readDevice(client, { deviceId }) {
      const { rows } = await client.query(
        `SELECT id, family_id, child_id, device_label, credential_hash, credential_revoked_at
           FROM family_child_devices WHERE id = $1`,
        [deviceId],
      );
      return rows[0] ?? null;
    },

    async readFamilyDevices(client, { familyId }) {
      const { rows } = await client.query(
        `SELECT id, family_id, child_id, device_label, credential_revoked_at
           FROM family_child_devices
          WHERE family_id = $1 AND credential_revoked_at IS NULL
          ORDER BY device_label ASC, id ASC`,
        [familyId],
      );
      return rows;
    },

    async touchDeviceSeen(client, { deviceId }) {
      await client.query(
        `UPDATE family_child_devices SET last_seen_at = NOW() WHERE id = $1 AND last_seen_at IS NOT NULL`,
        [deviceId],
      );
    },

    async readPolicy(client, { familyId, childId }, { forUpdate = false } = {}) {
      const { rows } = await client.query(
        `SELECT ${POLICY_COLUMNS}
           FROM family_web_filter_policies
          WHERE child_id = $1 AND family_id = $2
          ${forUpdate ? 'FOR UPDATE' : ''}`,
        [childId, familyId],
      );
      return rows[0] ?? null;
    },

    async upsertPolicy(client, { familyId, childId, policy, actorMembershipId }) {
      const { rows } = await client.query(
        `INSERT INTO family_web_filter_policies
           (child_id, family_id, level, enabled_categories, allow_hosts, block_hosts,
            dictionary_keywords, updated_by_membership_id)
         VALUES ($1, $2, $3, $4::text[], $5::text[], $6::text[], $7::text[], $8)
         ON CONFLICT (child_id) DO UPDATE
            SET level = EXCLUDED.level,
                enabled_categories = EXCLUDED.enabled_categories,
                allow_hosts = EXCLUDED.allow_hosts,
                block_hosts = EXCLUDED.block_hosts,
                dictionary_keywords = EXCLUDED.dictionary_keywords,
                updated_by_membership_id = EXCLUDED.updated_by_membership_id,
                version = family_web_filter_policies.version + 1,
                updated_at = NOW()
         RETURNING ${POLICY_COLUMNS}`,
        [
          childId,
          familyId,
          policy.level,
          policy.enabledCategories,
          policy.allowHosts,
          policy.blockHosts,
          policy.dictionaryKeywords,
          actorMembershipId,
        ],
      );
      return rows[0];
    },

    async readTempAllows(client, { familyId, childId }) {
      const { rows } = await client.query(
        `SELECT ${TEMP_ALLOW_COLUMNS}
           FROM family_web_filter_temp_allows
          WHERE family_id = $1 AND child_id = $2
          ORDER BY created_at DESC, id DESC`,
        [familyId, childId],
      );
      return rows.map(tempAllowFromRow);
    },

    async readTempAllow(client, { familyId, childId, requestId }, { forUpdate = false } = {}) {
      const { rows } = await client.query(
        `SELECT ${TEMP_ALLOW_COLUMNS}
           FROM family_web_filter_temp_allows
          WHERE id = $1 AND family_id = $2 AND child_id = $3
          ${forUpdate ? 'FOR UPDATE' : ''}`,
        [requestId, familyId, childId],
      );
      return rows[0] == null ? null : tempAllowFromRow(rows[0]);
    },

    /**
     * Serializes questions about the same child and host. The unique index refuses the
     * second open question; this lock is what turns "two phones pressed at once" into one
     * clean refusal instead of a constraint error reaching the family.
     */
    async lockOpenQuestion(client, { childId, host }) {
      await client.query(`SELECT pg_advisory_xact_lock(hashtext($1))`, [`web-filter:${childId}:${host}`]);
    },

    async readOpenQuestion(client, { childId, host }) {
      const { rows } = await client.query(
        `SELECT ${TEMP_ALLOW_COLUMNS}
           FROM family_web_filter_temp_allows
          WHERE child_id = $1 AND host = $2 AND status = 'pending'`,
        [childId, host],
      );
      return rows[0] ?? null;
    },

    async countOpenQuestions(client, { childId }) {
      const { rows } = await client.query(
        `SELECT COUNT(*)::int AS open FROM family_web_filter_temp_allows
          WHERE child_id = $1 AND status = 'pending'`,
        [childId],
      );
      return rows[0]?.open ?? 0;
    },

    async insertTempAllow(client, {
      familyId,
      childId,
      host,
      requestedMinutes,
      reason,
      requestedByMembershipId,
      requestedByDeviceId,
    }) {
      const { rows } = await client.query(
        `INSERT INTO family_web_filter_temp_allows
           (id, family_id, child_id, host, status, requested_minutes, reason,
            requested_by_membership_id, requested_by_device_id)
         VALUES ($1, $2, $3, $4, 'pending', $5, $6, $7, $8)
         RETURNING ${TEMP_ALLOW_COLUMNS}`,
        [
          randomUUID(),
          familyId,
          childId,
          host,
          requestedMinutes,
          reason,
          requestedByMembershipId,
          requestedByDeviceId,
        ],
      );
      return tempAllowFromRow(rows[0]);
    },

    async decideTempAllow(client, { requestId, status, grantedMinutes, expiresAt, decidedByMembershipId }) {
      const { rows } = await client.query(
        `UPDATE family_web_filter_temp_allows
            SET status = $2,
                granted_minutes = $3,
                expires_at = $4,
                decided_by_membership_id = $5,
                decided_at = NOW()
          WHERE id = $1 AND status = 'pending'
          RETURNING ${TEMP_ALLOW_COLUMNS}`,
        [requestId, status, grantedMinutes, expiresAt, decidedByMembershipId],
      );
      if (rows[0] == null) {
        throw new WebFilterError(409, 'web_filter_request_decided', 'This request has already been answered.');
      }
      return tempAllowFromRow(rows[0]);
    },

    async insertProtectionReport(client, {
      familyId,
      childId,
      deviceId,
      observedState,
      signals,
      detail,
      observedAt,
    }) {
      const { rows } = await client.query(
        `INSERT INTO family_device_protection_reports
           (id, family_id, child_id, device_id, observed_state, signals, detail, observed_at)
         VALUES ($1, $2, $3, $4, $5, $6::text[], $7, $8)
         RETURNING ${REPORT_COLUMNS}`,
        [randomUUID(), familyId, childId, deviceId, observedState, signals, detail, observedAt],
      );
      return rows[0];
    },

    async readLatestProtectionReport(client, { deviceId }) {
      const { rows } = await client.query(
        `SELECT ${REPORT_COLUMNS}
           FROM family_device_protection_reports
          WHERE device_id = $1
          ORDER BY reported_at DESC, id DESC
          LIMIT 1`,
        [deviceId],
      );
      const row = rows[0];
      if (row == null) return null;
      return {
        id: row.id,
        observedState: row.observed_state,
        signals: [...row.signals],
        detail: row.detail,
        observedAt: row.observed_at,
        reportedAt: row.reported_at,
      };
    },

    async audit(client, {
      familyId,
      actorMembershipId,
      correlationId,
      subjectId,
      subjectType,
      eventType,
    }) {
      await store.appendAuditAndOutbox(client, {
        familyId,
        actorMembershipId,
        correlationId,
        subjectId,
        subjectType,
        eventType,
      });
    },
  };
}
