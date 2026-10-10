// W6 — the laws of web filtering and tamper resistance, as pure functions.
//
// No database and no server, on purpose: a rule that can only be checked through a socket
// is a rule nobody checks. These are the functions the routes call - nothing here
// re-implements a decision.
//
// What is being defended, in one line each:
//
//   * a device that has not reported lately is NOT protected, and the only thing that can
//     produce "protected" is a recent report that said so;
//   * a report is judged fresh by when the SERVER heard it, not by the handset's own clock;
//   * a temporary allow closes by itself, and an approval cannot outlive what was asked;
//   * the decision order is identical to the client engine's, so the phone in a child's
//     hand and the screen in a parent's hand can never disagree about the same page.
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';
import {
  DEFAULT_WEB_FILTER_POLICY,
  LEVEL_PRESETS,
  PROTECTION_FRESHNESS_MINUTES,
  TEMP_ALLOW_MINUTES_CEILING,
  WEB_FILTER_CATEGORIES,
  activeTempAllowHosts,
  classifyHost,
  computeProtectionHealth,
  evaluateWebRequest,
  hostInList,
  mergePolicy,
  normalizeCategories,
  normalizeHost,
  normalizeHostList,
  tempAllowState,
} from '../src/web-filter.js';

const at = (iso) => new Date(iso);
const minutesAgo = (now, minutes) => new Date(now.getTime() - minutes * 60000);

// ── the honest host ────────────────────────────────────────────────────────────────────

test('a host is read the same way twice, whatever shape it arrives in', () => {
  // The reason this matters: a family that blocks example.com and finds www.example.com
  // open has been handed a switch that lies.
  assert.equal(normalizeHost('HTTPS://WWW.Example.COM:443/path?q=1'), 'example.com');
  assert.equal(normalizeHost('  example.com.  '), 'example.com');
  assert.equal(normalizeHost('http://sub.example.com/x'), 'sub.example.com');
  assert.equal(normalizeHost(''), '');
  assert.equal(normalizeHost('not a host'), 'not a host');

  assert.deepEqual(normalizeHostList(['WWW.B.com', 'a.com', 'b.com', 'a.com', '']), ['a.com', 'b.com']);
  // Subdomains inherit a family's decision, in both directions.
  assert.equal(hostInList('game.example.com', ['example.com']), true);
  assert.equal(hostInList('example.com', ['example.com']), true);
  assert.equal(hostInList('notexample.com', ['example.com']), false);
});

test('the decision order is the client engine’s order, step for step', () => {
  const policy = {
    blockHosts: ['blocked.example.com'],
    allowHosts: ['allowed.example.com'],
    dictionaryKeywords: ['casino'],
    enabledCategories: ['games'],
    version: 7,
  };
  const decide = (host) => evaluateWebRequest(policy, { host });

  // 1. The block list is first: it outranks an allow entry and a temporary allow.
  assert.deepEqual(decide('blocked.example.com'), {
    allowed: false, denySource: 'blocklist', categoryKey: null, policyVersion: 7,
  });
  // 2. A temporary allow outranks the allow list, the dictionary and the category.
  assert.equal(evaluateWebRequest({ ...policy, activeTempAllows: ['steam.example.com'] }, { host: 'steam.example.com' }).allowed, true);
  // 3. The allow list comes next, and beats the dictionary and the category.
  assert.equal(decide('allowed.example.com').allowed, true);
  // 4. Then the dictionary.
  assert.equal(decide('my-casino.example.com').denySource, 'dictionary');
  // 5. Then the category.
  assert.deepEqual(decide('games.example.com'), {
    allowed: false, denySource: 'category', categoryKey: 'games', policyVersion: 7,
  });
  // 6. Otherwise it is allowed, and the answer says so rather than staying silent.
  assert.equal(decide('school.example.com').allowed, true);
  // An unreadable host is not a denial: refusing "" would block a child's whole internet
  // because a URL failed to parse.
  assert.equal(decide('').allowed, true);
});

test('the category classifier answers with a category or with nothing', () => {
  assert.equal(classifyHost('games.example.com'), 'games');
  assert.equal(classifyHost('www.netflix.com'), 'streaming');
  assert.equal(classifyHost('tiktok.com'), 'social');
  assert.equal(classifyHost('wikipedia.org'), null);
  assert.equal(classifyHost(''), null);
});

test('the former *.example fixture hosts classify the same through label tokens alone (S1)', () => {
  // These hosts used to be an exact-match table inside production code. The table was
  // removed; this pins that nothing about their classification changed.
  const expected = {
    'adult.example': 'adults',
    'gambling.example': 'gambling',
    'casino.example': 'gambling',
    'violence.example': 'violence',
    'social.example': 'social',
    'games.example': 'games',
    'streaming.example': 'streaming',
  };
  for (const [host, category] of Object.entries(expected)) {
    assert.equal(classifyHost(host), category, host);
  }
});

// ── the honest shield ──────────────────────────────────────────────────────────────────

test('silence is not health: a device that never reported is unverified', () => {
  const now = at('2026-10-08T09:00:00.000Z');
  const health = computeProtectionHealth({ latestReport: null, now });
  assert.equal(health.state, 'unverified');
  assert.equal(health.reason, 'never_reported');
  assert.equal(health.ageMinutes, null);
});

test('a report older than the window stops speaking for the device', () => {
  const now = at('2026-10-08T09:00:00.000Z');
  const fresh = computeProtectionHealth({
    latestReport: { observedState: 'healthy', reportedAt: minutesAgo(now, 10), signals: [] },
    now,
  });
  assert.equal(fresh.state, 'protected');
  assert.equal(fresh.ageMinutes, 10);

  // Exactly at the edge it still speaks; one minute past it, it does not.
  const edge = computeProtectionHealth({
    latestReport: { observedState: 'healthy', reportedAt: minutesAgo(now, PROTECTION_FRESHNESS_MINUTES), signals: [] },
    now,
  });
  assert.equal(edge.state, 'protected');

  const stale = computeProtectionHealth({
    latestReport: { observedState: 'healthy', reportedAt: minutesAgo(now, PROTECTION_FRESHNESS_MINUTES + 1), signals: [] },
    now,
  });
  assert.equal(stale.state, 'unverified');
  assert.equal(stale.reason, 'stale_report');
});

test('freshness is measured on the server’s clock, not the handset’s claim', () => {
  const now = at('2026-10-08T09:00:00.000Z');
  // A handset whose clock is a day ahead says it looked "tomorrow" and that it is healthy.
  // The claim is kept as testimony, but the device is judged by when the server heard it -
  // which, in this case, is a day ago.
  const health = computeProtectionHealth({
    latestReport: {
      observedState: 'healthy',
      observedAt: at('2026-10-09T09:00:00.000Z'),
      reportedAt: minutesAgo(now, 24 * 60),
      signals: [],
    },
    now,
  });
  assert.equal(health.state, 'unverified');
  assert.equal(health.reason, 'stale_report');
});

test('what the handset saw is reported as what it saw', () => {
  const now = at('2026-10-08T09:00:00.000Z');
  const report = (observedState, signals = []) => computeProtectionHealth({
    latestReport: { observedState, signals, detail: '', reportedAt: minutesAgo(now, 1) },
    now,
  });
  assert.equal(report('vpn_active').state, 'at_risk');
  assert.equal(report('vpn_active').reason, 'vpn_active');
  assert.equal(report('profile_removed').state, 'at_risk');
  assert.equal(report('permission_revoked').state, 'at_risk');
  assert.equal(report('dns_bypassed').state, 'at_risk');
  assert.equal(report('device_admin_removed').state, 'at_risk');
  // A platform that cannot hold the plane is a fact about the phone, not a failure of the
  // child: calling it "at risk" would blame the wrong party.
  assert.equal(report('unsupported').state, 'unsupported');
  // An observation this server has never heard of is reported as unknown, never as safe.
  assert.equal(report('something_new').state, 'unverified');
  assert.equal(report('something_new').reason, 'unrecognised_observation');
  // The signals ride along, so a family can be told what was seen rather than only that
  // something was.
  assert.deepEqual(report('vpn_active', ['vpn_active', 'proxy_detected']).signals, ['vpn_active', 'proxy_detected']);
});

// ── the door with an end ───────────────────────────────────────────────────────────────

test('an approval closes by itself and never outlives the request', () => {
  const now = at('2026-10-08T09:00:00.000Z');
  const open = { status: 'approved', expiresAt: new Date(now.getTime() + 5 * 60000), host: 'school.example.com' };
  const closed = { status: 'approved', expiresAt: new Date(now.getTime() - 1), host: 'games.example.com' };
  const pending = { status: 'pending', expiresAt: null, host: 'youtube.com' };
  const denied = { status: 'denied', expiresAt: null, host: 'casino.example.com' };

  assert.equal(tempAllowState(open, now), 'active');
  // One millisecond past the end, the door is shut - and nobody had to close it.
  assert.equal(tempAllowState(closed, now), 'expired');
  assert.equal(tempAllowState(pending, now), 'pending');
  assert.equal(tempAllowState(denied, now), 'denied');

  assert.deepEqual(activeTempAllowHosts([open, closed, pending, denied], now), ['school.example.com']);
  assert.ok(TEMP_ALLOW_MINUTES_CEILING <= 240, 'the ceiling stays inside what the request may ask for');
});

// ── the policy a family states ─────────────────────────────────────────────────────────

test('a change touches what was sent and leaves the rest as the family left it', () => {
  const existing = {
    level: 'balanced',
    enabledCategories: ['adults'],
    allowHosts: ['school.example.com'],
    blockHosts: [],
    dictionaryKeywords: [],
  };
  // One switch flipped: everything else keeps its stored value, rather than being reset to
  // a default nobody chose.
  const afterOneSwitch = mergePolicy(existing, { categories: ['adults', 'games'] });
  assert.deepEqual(afterOneSwitch.enabledCategories, ['adults', 'games']);
  assert.deepEqual(afterOneSwitch.allowHosts, ['school.example.com']);
  assert.equal(afterOneSwitch.level, 'balanced');

  // A list sent as a list replaces the stored one - removing a host has to be possible,
  // and a merge would silently refuse the removal.
  const afterRemoval = mergePolicy(existing, { allowHosts: [] });
  assert.deepEqual(afterRemoval.allowHosts, []);
});

test('a category the server does not know is refused where it is named', () => {
  assert.deepEqual(normalizeCategories(['games', 'ADULTS', 'games']), ['adults', 'games']);
  assert.throws(() => normalizeCategories(['crypto']), /Unknown category/);
});

test('the level presets match what the client seeds when a level is chosen', () => {
  assert.deepEqual(LEVEL_PRESETS.strict, [...WEB_FILTER_CATEGORIES]);
  assert.deepEqual(LEVEL_PRESETS.balanced, ['adults', 'gambling', 'violence']);
  assert.deepEqual(LEVEL_PRESETS.open, []);
  assert.deepEqual(DEFAULT_WEB_FILTER_POLICY.enabledCategories, LEVEL_PRESETS.balanced);
});

// ── the two sides must not drift ───────────────────────────────────────────────────────

const repositoryRoot = join(dirname(fileURLToPath(import.meta.url)), '..', '..');

test('the six categories are the same six the Flutter client switches on', async () => {
  const source = await readFile(
    join(repositoryRoot, 'app', 'lib', 'core', 'policy', 'web_filter_policy.dart'),
    'utf8',
  );
  const block = source.slice(
    source.indexOf('abstract final class WebFilterCategories'),
    source.indexOf('static bool isKnown'),
  );
  const clientKeys = [...block.matchAll(/static const (\w+) = '([a-z]+)';/g)].map((match) => match[2]);
  assert.deepEqual(
    clientKeys,
    [...WEB_FILTER_CATEGORIES],
    'a category the client offers and the server does not accept is a switch that does nothing',
  );
});

test('the client engine resolves a decision in the same order as this server', async () => {
  const source = await readFile(
    join(repositoryRoot, 'app', 'lib', 'core', 'web_filter', 'web_filter_engine.dart'),
    'utf8',
  );
  // The client numbers its precedence in comments - `// 1. Blocklist → DENY (highest)`,
  // `// 2. Active timed temporary allow → ALLOW`, and so on. Those numbers ARE the
  // declaration, so this reads them in order and names the step each one describes.
  const steps = [...source.matchAll(/\/\/\s*(\d)\.\s*([^\n]*)/g)]
    .map((match) => ({ index: Number(match[1]), text: match[2].toLowerCase() }))
    .filter((step) => step.index >= 1 && step.index <= 6)
    .sort((left, right) => left.index - right.index);
  const named = steps.map((step) => {
    if (step.text.includes('blocklist')) return 'blocklist';
    if (step.text.includes('temporary allow')) return 'temporary allow';
    if (step.text.includes('allowlist')) return 'allowlist';
    if (step.text.includes('dictionary')) return 'dictionary';
    if (step.text.includes('category')) return 'category';
    return 'allow';
  });
  assert.deepEqual(
    named,
    ['blocklist', 'temporary allow', 'allowlist', 'dictionary', 'category'],
    'the phone in a child’s hand and the screen in a parent’s hand must not be able to disagree',
  );
  // The sixth step is the fallback, and the client writes it unnumbered (`// 6/7. Safe
  // Search TBD / else ALLOW`) because safe search is not built yet. It is checked by name
  // here so the day safe search lands, this test is where the two sides meet.
  assert.ok(
    /else ALLOW/.test(source),
    'the client engine must still end in a fallback allow rather than an implicit denial',
  );
});
