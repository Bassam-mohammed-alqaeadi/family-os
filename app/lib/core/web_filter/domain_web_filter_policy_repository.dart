import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/policy/web_filter_policy.dart';
import 'package:family_os/core/policy/web_filter_policy_repository.dart';
import 'package:family_os/core/web_filter/web_filter_document.dart';
import 'package:family_os/core/web_filter/web_filter_repository.dart';

/// Adapts [WebFilterDomainRepository] → Stage-1 [WebFilterPolicyRepository].
///
/// Saves as **child override** (Q-WF-01). Loads via effective resolution.
final class DomainWebFilterPolicyRepository
    implements WebFilterPolicyRepository {
  DomainWebFilterPolicyRepository(this._domain, {required this.familyId});

  final WebFilterDomainRepository _domain;
  final FamilyId familyId;

  @override
  Future<WebFilterPolicy> load(ChildId childId) async {
    final doc = await _domain.loadEffective(familyId, childId);
    return doc.toStage1Policy();
  }

  @override
  Future<void> save(ChildId childId, WebFilterPolicy policy) async {
    final doc = WebFilterDocument.fromStage1Policy(
      familyId: familyId,
      scopeKind: WebFilterScopeKind.childOverride,
      childId: childId,
      policy: policy,
    );
    await _domain.save(doc);
  }
}
