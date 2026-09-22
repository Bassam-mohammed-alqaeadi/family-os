import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/policy/web_filter_evaluator.dart';
import 'package:family_os/core/policy/web_filter_policy.dart';
import 'package:family_os/core/policy/web_filter_policy_repository.dart';

void main() {
  group('WebFilterEvaluator', () {
    test('adults enabled blocks adult.example fixture', () {
      final policy = WebFilterPolicy(
        level: WebFilterLevel.open,
        categories: {
          for (final k in WebFilterCategories.known) k: false,
          WebFilterCategories.adults: true,
        },
      );

      final decision = WebFilterEvaluator.decide(
        Uri.parse('https://adult.example/x'),
        policy,
      );

      expect(decision, isA<WebFilterDeny>());
      expect((decision as WebFilterDeny).category, WebFilterCategories.adults);
      expect(decision.policyVersion, policy.policyVersion);
    });

    test('allow-list host overrides category deny', () {
      final policy = WebFilterPolicy(
        level: WebFilterLevel.strict,
        categories: {
          for (final k in WebFilterCategories.known) k: true,
        },
        allowList: {'adult.example'},
      );

      final decision = WebFilterEvaluator.decide(
        Uri.parse('https://adult.example/x'),
        policy,
      );

      expect(decision, isA<WebFilterAllow>());
    });

    test('open level still respects explicit category blocks', () {
      final policy = WebFilterPolicy(
        level: WebFilterLevel.open,
        categories: {
          for (final k in WebFilterCategories.known) k: false,
          WebFilterCategories.gambling: true,
        },
      );

      final deny = WebFilterEvaluator.decide(
        Uri.parse('https://gambling.example/bet'),
        policy,
      );
      expect(deny, isA<WebFilterDeny>());
      expect((deny as WebFilterDeny).category, WebFilterCategories.gambling);

      final allow = WebFilterEvaluator.decide(
        Uri.parse('https://news.example/'),
        policy,
      );
      expect(allow, isA<WebFilterAllow>());
    });

    test('safe host is allowed when categories off', () {
      final policy = WebFilterPolicy(
        level: WebFilterLevel.open,
        categories: {
          for (final k in WebFilterCategories.known) k: false,
        },
        policyVersion: 7,
      );
      final decision = WebFilterEvaluator.decide(
        Uri.parse('https://school.example/lesson'),
        policy,
      );
      expect(decision, isA<WebFilterAllow>());
      expect(decision.policyVersion, 7);
    });

    test('decision snapshot matches evaluate for same URL+policy', () {
      final policy = WebFilterPolicy(
        level: WebFilterLevel.balanced,
        policyVersion: 3,
      );
      final url = Uri.parse('https://adult.example/x');
      final a = WebFilterDecisionSnapshot.evaluate(url, policy);
      final b = WebFilterDecisionSnapshot.evaluate(url, policy);
      expect(a, b);
      expect(a.isDenied, isTrue);
      expect(a.categoryKey, WebFilterCategories.adults);
      expect(a.policyVersion, 3);
      expect(a.host, 'adult.example');
    });
  });

  group('PrefsWebFilterPolicyRepository', () {
    test('adults toggle persists across reopen', () async {
      final shared = <String, String>{};
      final child = ChildId('wf-child');
      final repo1 = PrefsWebFilterPolicyRepository(
        MemoryWebFilterPrefsStore(shared),
      );

      final base = await repo1.load(child);
      expect(base.isCategoryEnabled(WebFilterCategories.adults), isTrue);

      await repo1.save(
        child,
        base.withCategory(WebFilterCategories.adults, true).copyWith(
              policyVersion: base.policyVersion + 1,
              updatedAt: DateTime.utc(2026, 9, 20),
            ),
      );

      // Flip adults off then on to prove persistence of true.
      await repo1.save(
        child,
        (await repo1.load(child))
            .withCategory(WebFilterCategories.adults, false),
      );
      await repo1.save(
        child,
        (await repo1.load(child)).withCategory(WebFilterCategories.adults, true),
      );

      final repo2 = PrefsWebFilterPolicyRepository(
        MemoryWebFilterPrefsStore(shared),
      );
      final reloaded = await repo2.load(child);
      expect(reloaded.isCategoryEnabled(WebFilterCategories.adults), isTrue);
    });
  });
}
