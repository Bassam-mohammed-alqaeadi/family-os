import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/policy/collection_scope.dart';
import 'package:family_os/core/policy/privacy_collection_policy.dart';
import 'package:family_os/core/policy/privacy_collection_repository.dart';
import 'package:family_os/core/policy/web_unlock_service.dart' show AuditAppend;

void main() {
  group('canEditPrivacyCollection', () {
    test('father only', () {
      expect(canEditPrivacyCollection(AppRole.father), isTrue);
      expect(canEditPrivacyCollection(AppRole.mother), isFalse);
      expect(canEditPrivacyCollection(AppRole.child), isFalse);
    });
  });

  group('PrivacyCollectionPolicy', () {
    test('defaults enable all lean scopes', () {
      final p = PrivacyCollectionPolicy.defaults(childId: 'c1');
      expect(p.enabledScopes, kLeanCollectionScopes);
      expect(p.isEnabled(CollectionScope.location), isTrue);
    });

    test('withScope off removes from enabledScopes', () {
      final p = PrivacyCollectionPolicy.defaults(childId: 'c1')
          .withScope(CollectionScope.location, false);
      expect(p.enabledScopes, isNot(contains(CollectionScope.location)));
      expect(p.enabledScopes, contains(CollectionScope.screenTime));
    });

    test('json round-trip', () {
      final original = PrivacyCollectionPolicy.defaults(childId: 'c1')
          .withScope(CollectionScope.webActivity, false)
          .copyWith(updatedAt: DateTime.utc(2026, 9, 20, 12));
      final round = PrivacyCollectionPolicy.fromJson(original.toJson());
      expect(round.childId, 'c1');
      expect(round.isEnabled(CollectionScope.webActivity), isFalse);
      expect(round.isEnabled(CollectionScope.location), isTrue);
      expect(round.updatedAt, DateTime.utc(2026, 9, 20, 12));
    });
  });

  group('PrefsPrivacyCollectionRepository', () {
    test('father save persists across reopen', () async {
      final store = MemoryPrivacyCollectionPrefsStore();
      final repo = PrefsPrivacyCollectionRepository(store);
      final saved = PrivacyCollectionPolicy.defaults(childId: 'demo-child')
          .withScope(CollectionScope.location, false);

      final result = await repo.save(saved, actor: AppRole.father);
      expect(result, isA<PrivacyCollectionWriteOk>());

      final reopened = PrefsPrivacyCollectionRepository(store);
      final loaded = await reopened.load('demo-child');
      expect(loaded.isEnabled(CollectionScope.location), isFalse);
      expect(loaded.isEnabled(CollectionScope.screenTime), isTrue);
    });

    test('mother write denied + audit', () async {
      final audit = AuditAppend();
      final repo = PrefsPrivacyCollectionRepository(
        MemoryPrivacyCollectionPrefsStore(),
        audit: audit,
      );
      final result = await repo.save(
        PrivacyCollectionPolicy.defaults(childId: 'c1')
            .withScope(CollectionScope.location, false),
        actor: AppRole.mother,
      );
      expect(result, isA<PrivacyCollectionWriteDenied>());
      expect(
        audit.entries.any((e) => e.contains('403 PRIVACY_COLLECTION')),
        isTrue,
      );
      final loaded = await repo.load('c1');
      expect(loaded.isEnabled(CollectionScope.location), isTrue);
    });

    test('child write denied', () async {
      final repo = InMemoryPrivacyCollectionRepository();
      final result = await repo.save(
        PrivacyCollectionPolicy.defaults(childId: 'c1'),
        actor: AppRole.child,
      );
      expect(result, isA<PrivacyCollectionWriteDenied>());
    });
  });
}
