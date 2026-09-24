import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';

import 'web_filter_document.dart';

/// Rule 25 seam — authoritative Web Filter documents (SQLite / memory).
abstract class WebFilterDomainRepository {
  Future<WebFilterDocument?> loadFamilyBaseline(FamilyId familyId);

  Future<WebFilterDocument?> loadChildOverride(
    FamilyId familyId,
    ChildId childId,
  );

  /// Effective policy for [childId] (override wins · Q-WF-01).
  Future<WebFilterDocument> loadEffective(FamilyId familyId, ChildId childId);

  Future<void> save(WebFilterDocument document);

  Future<void> removeChildOverride(FamilyId familyId, ChildId childId);
}
