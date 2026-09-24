import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/capability_registry.dart';
import 'package:family_os/core/fs_foundation/capability_status.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/core/policy/web_filter_evaluator.dart';
import 'package:family_os/core/policy/web_filter_policy.dart';
import 'package:family_os/core/web_filter/domain_web_filter_policy_repository.dart';
import 'package:family_os/core/web_filter/web_filter_document.dart';
import 'package:family_os/core/web_filter/web_filter_engine.dart';
import 'package:family_os/core/web_filter/web_filter_store.dart';
import 'package:family_os/core/web_filter/web_filter_verdict.dart';

void main() {
  late MemoryLocalDatabase db;
  late LocalWebFilterStore store;
  final family = FamilyId('fam_wf');
  final child = ChildId('child_a');
  final now = DateTime.utc(2026, 9, 24, 16);

  setUp(() async {
    db = MemoryLocalDatabase();
    await db.open();
    expect(await db.schemaVersion(), FamilyLocalSchema.currentVersion);
    store = LocalWebFilterStore(db, clock: () => now);
  });

  tearDown(() async {
    await db.close();
  });

  test('schema v4 exposes wf_document', () async {
    expect(FamilyLocalSchema.currentVersion, 10);
    await db.insert('wf_document', {
      'scope_key': 'family',
      'family_id': family.value,
      'child_id': null,
      'level': 'balanced',
      'categories_json': '{}',
      'allow_json': '[]',
      'block_json': '[]',
      'dict_json': '[]',
      'policy_version': 1,
      'updated_at': 1,
    });
    expect((await db.query('wf_document')).length, 1);
  });

  test('Q-WF-01 child override wins over family baseline', () async {
    await store.save(
      WebFilterDocument(
        familyId: family,
        scopeKind: WebFilterScopeKind.familyBaseline,
        level: WebFilterLevel.strict,
        allowList: {'school.edu'},
      ),
    );
    await store.save(
      WebFilterDocument(
        familyId: family,
        scopeKind: WebFilterScopeKind.childOverride,
        childId: child,
        level: WebFilterLevel.open,
        blockList: {'bad.example'},
      ),
    );

    final effective = await store.loadEffective(family, child);
    expect(effective.scopeKind, WebFilterScopeKind.childOverride);
    expect(effective.level, WebFilterLevel.open);
    expect(effective.blockList, contains('bad.example'));
    expect(effective.allowList, isEmpty);
  });

  test('effective falls back to family when no override', () async {
    await store.save(
      WebFilterDocument(
        familyId: family,
        scopeKind: WebFilterScopeKind.familyBaseline,
        allowList: {'ok.example'},
      ),
    );
    final effective = await store.loadEffective(family, child);
    expect(effective.scopeKind, WebFilterScopeKind.familyBaseline);
    expect(effective.allowList, contains('ok.example'));
  });

  group('WF-OD-08 precedence', () {
    test('blocklist beats allowlist', () {
      final doc = WebFilterDocument(
        familyId: family,
        scopeKind: WebFilterScopeKind.familyBaseline,
        allowList: {'twin.example'},
        blockList: {'twin.example'},
      );
      final v = WebFilterEngine.decide(
        Uri.parse('https://twin.example/x'),
        doc,
      );
      expect(v.denied, isTrue);
      expect(v.denySource, WebFilterDenySource.blocklist);
    });

    test('temp allow beats allowlist path but not blocklist', () {
      final doc = WebFilterDocument(
        familyId: family,
        scopeKind: WebFilterScopeKind.familyBaseline,
        blockList: {'blocked.example'},
      );
      final stillDenied = WebFilterEngine.decide(
        Uri.parse('https://blocked.example'),
        doc,
        activeTemporaryAllows: {'blocked.example'},
      );
      expect(stillDenied.denied, isTrue);

      final allowed = WebFilterEngine.decide(
        Uri.parse('https://temp.example'),
        doc,
        activeTemporaryAllows: {'temp.example'},
      );
      expect(allowed.denied, isFalse);
      expect(allowed.allowSource, WebFilterAllowSource.temporaryAllow);
    });

    test('dictionary denies before category', () {
      final doc = WebFilterDocument(
        familyId: family,
        scopeKind: WebFilterScopeKind.familyBaseline,
        dictionaryKeywords: {'casino'},
        categories: {WebFilterCategories.gambling: false},
      );
      final v = WebFilterEngine.decide(
        Uri.parse('https://news.example/casino-tips'),
        doc,
      );
      expect(v.denied, isTrue);
      expect(v.denySource, WebFilterDenySource.dictionary);
    });

    test('category deny still works', () {
      final doc = WebFilterDocument(
        familyId: family,
        scopeKind: WebFilterScopeKind.familyBaseline,
        categories: {WebFilterCategories.adults: true},
      );
      final v = WebFilterEngine.decide(
        Uri.parse('https://adult.example/page'),
        doc,
      );
      expect(v.denied, isTrue);
      expect(v.denySource, WebFilterDenySource.category);
      expect(v.categoryKey, WebFilterCategories.adults);
    });
  });

  test('Stage-1 evaluator bridges to domain precedence', () {
    final policy = WebFilterPolicy(
      allowList: {'evil.example'},
      blockList: {'evil.example'},
    );
    final d = WebFilterEvaluator.decide(
      Uri.parse('https://evil.example'),
      policy,
    );
    expect(d.isDenied, isTrue);
    expect(d.denySource, WebFilterDenySource.blocklist);
  });

  test('DomainWebFilterPolicyRepository save is child override', () async {
    final adapter = DomainWebFilterPolicyRepository(store, familyId: family);
    await adapter.save(
      child,
      WebFilterPolicy(blockList: {'x.example'}, policyVersion: 3),
    );
    final override = await store.loadChildOverride(family, child);
    expect(override, isNotNull);
    expect(override!.blockList, contains('x.example'));
    expect(override.policyVersion, 3);

    final loaded = await adapter.load(child);
    expect(loaded.blockList, contains('x.example'));
  });

  test('applyFs002OwnCapabilities upgrades list honesty', () async {
    final registry = CapabilityRegistry(db, clock: () => now);
    await registry.ensureSeeded();
    await registry.setStatus('fs002.web_lists', CapabilityStatus.degraded);
    await registry.applyFs002OwnCapabilities();
    expect(
      (await registry.get('fs002.web_lists'))!.status,
      CapabilityStatus.implemented,
    );
    expect(
      (await registry.get('fs002.native_block'))!.status,
      CapabilityStatus.mockRemote,
    );
    expect(
      (await registry.get('fs002.taxonomy'))!.status,
      CapabilityStatus.degraded,
    );
  });
}
