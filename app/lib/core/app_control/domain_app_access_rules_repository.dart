import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/policy/app_access_rules.dart';
import 'package:family_os/core/policy/app_access_rules_repository.dart';

import 'app_control_disposition.dart';
import 'app_control_document.dart';
import 'app_control_repository.dart';

/// Adapts App Control domain → Stage-1 [AppAccessRulesRepository].
///
/// **Ownership split (APP-OD-12):**
/// - FS-003 owns [AppAccessRule.blocked] (Permanent Block disposition)
/// - Screen Time owns limit / countable / unlimited (persisted via [stAxes])
final class DomainAppAccessRulesRepository implements AppAccessRulesRepository {
  DomainAppAccessRulesRepository(
    this._domain, {
    required this.familyId,
    AppAccessRulesRepository? stAxes,
  }) : _stAxes = stAxes ?? InMemoryAppAccessRulesRepository();

  final AppControlDomainRepository _domain;
  final FamilyId familyId;
  final AppAccessRulesRepository _stAxes;

  @override
  Future<AppAccessRuleSet> load(ChildId childId) async {
    final st = await _stAxes.load(childId);
    final ac = await _domain.loadEffective(familyId, childId);
    final byId = <String, AppAccessRule>{for (final r in st.rules) r.appId: r};

    for (final e in ac.dispositions.entries) {
      final existing = byId[e.key];
      final blocked = e.value == AppPackageDisposition.block;
      if (existing == null) {
        byId[e.key] = AppAccessRule(appId: e.key, blocked: blocked);
      } else {
        byId[e.key] = existing.copyWith(blocked: blocked);
      }
    }

    // Ensure AC block wins even if ST prefs still say allowed.
    for (final e in ac.dispositions.entries) {
      if (e.value == AppPackageDisposition.block) {
        final r = byId[e.key];
        if (r != null && !r.blocked) {
          byId[e.key] = r.copyWith(blocked: true);
        }
      }
    }

    return AppAccessRuleSet(childId: childId, rules: byId.values.toList());
  }

  @override
  Future<void> save(ChildId childId, AppAccessRuleSet set) async {
    // Persist ST axes without treating blocked as ST-owned authority.
    final stOnly = AppAccessRuleSet(
      childId: childId,
      rules: [
        for (final r in set.rules)
          AppAccessRule(
            appId: r.appId,
            blocked: false, // AC owns block; strip before ST prefs write
            limitMinutes: r.limitMinutes,
            countable: r.countable,
            unlimited: r.unlimited,
          ),
      ],
    );
    await _stAxes.save(childId, stOnly);

    final dispositions = <String, AppPackageDisposition>{};
    for (final r in set.rules) {
      dispositions[r.appId] = r.blocked
          ? AppPackageDisposition.block
          : AppPackageDisposition.allow;
    }
    final existing = await _domain.loadChildOverride(familyId, childId);
    final doc = AppControlDocument(
      familyId: familyId,
      scopeKind: AppControlScopeKind.childOverride,
      childId: childId,
      dispositions: dispositions,
      policyVersion: (existing?.policyVersion ?? 0) + 1,
    );
    await _domain.save(doc);
  }
}
