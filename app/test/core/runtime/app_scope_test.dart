import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/runtime/app_runtime.dart';
import 'package:family_os/core/runtime/app_scope.dart';
import 'package:family_os/core/runtime/identity_source.dart';

void main() {
  testWidgets(
    'AppScope exposes injected identity state and rebuilds dependents',
    (tester) async {
      final source = _FakeIdentitySource(const IdentitySnapshot.unavailable());
      final runtime = AppRuntime(identity: source);
      addTearDown(runtime.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: AppScope(
            runtime: runtime,
            child: Builder(
              builder: (context) {
                final snapshot = AppScope.of(context).identity.value;
                return Text(snapshot.familyId?.value ?? 'unavailable');
              },
            ),
          ),
        ),
      );

      expect(find.text('unavailable'), findsOneWidget);

      source.emit(_remoteFamilySnapshot());
      await tester.pump();

      expect(find.text('fam_real'), findsOneWidget);
    },
  );

  testWidgets(
    'AppScope has no implicit fallback outside explicit composition',
    (tester) async {
      AppRuntime? resolved;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            resolved = AppScope.maybeOf(context);
            return const SizedBox();
          },
        ),
      );

      expect(resolved, isNull);
    },
  );

  test('runtime refresh delegates to its typed identity port', () async {
    final source = _FakeIdentitySource(const IdentitySnapshot.unavailable());
    final runtime = AppRuntime(identity: source);
    addTearDown(runtime.dispose);

    source.emit(_remoteFamilySnapshot());
    final refreshed = await runtime.refreshIdentity();

    expect(refreshed.familyId, FamilyId('fam_real'));
    expect(refreshed.isRemoteAuthoritative, isTrue);
  });
}

IdentitySnapshot _remoteFamilySnapshot() {
  return IdentitySnapshot(
    authority: IdentityAuthority.remoteAuthoritative,
    accountId: AccountId('acc_real'),
    familyId: FamilyId('fam_real'),
    activeChildId: ChildId('child_real'),
    role: AppRole.father,
    motherLevel: MotherLevel.full,
    isPrimaryOwner: true,
  );
}

final class _FakeIdentitySource extends ChangeNotifier
    implements IdentitySource {
  _FakeIdentitySource(this._value);

  IdentitySnapshot _value;

  @override
  IdentitySnapshot get value => _value;

  void emit(IdentitySnapshot next) {
    _value = next;
    notifyListeners();
  }

  @override
  Future<IdentitySnapshot> refresh() async => _value;
}
