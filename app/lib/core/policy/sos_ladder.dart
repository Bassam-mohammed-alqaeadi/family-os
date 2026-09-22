import 'package:flutter/foundation.dart';

/// Fixed member ids that always occupy SOS ladder rung 1 (P-5 / SET-020).
///
/// Competitive: Life360 / panic — parents are always on the emergency chain.
const Set<String> kSosLadderFixedParentIds = {'father', 'mother'};

/// Validation codes for illegal SOS ladder edits (SET-020).
abstract final class SosLadderValidationCode {
  static const rung1ParentImmovable = 'rung1_parent_immovable';
  static const rung1ParentDisableForbidden = 'rung1_parent_disable_forbidden';
}

/// Thrown when API/UI attempts to remove or disable rung-1 parents.
final class SosLadderValidationException implements Exception {
  SosLadderValidationException(this.code, {this.memberId});

  final String code;
  final String? memberId;

  @override
  String toString() =>
      'SosLadderValidationException($code${memberId != null ? ', member=$memberId' : ''})';
}

/// Editable backup contact on rung 2+ (outside-family escalation).
@immutable
final class SosBackupContact {
  const SosBackupContact({
    required this.id,
    required this.name,
    this.relation = '',
    this.delaySeconds = 60,
    this.enabled = true,
  });

  final String id;
  final String name;
  final String relation;
  final int delaySeconds;
  final bool enabled;

  SosBackupContact copyWith({
    String? id,
    String? name,
    String? relation,
    int? delaySeconds,
    bool? enabled,
  }) {
    return SosBackupContact(
      id: id ?? this.id,
      name: name ?? this.name,
      relation: relation ?? this.relation,
      delaySeconds: delaySeconds ?? this.delaySeconds,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'relation': relation,
        'delaySeconds': delaySeconds,
        'enabled': enabled,
      };

  factory SosBackupContact.fromJson(Map<String, dynamic> json) {
    return SosBackupContact(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      relation: json['relation']?.toString() ?? '',
      delaySeconds: (json['delaySeconds'] as num?)?.toInt() ?? 60,
      enabled: json['enabled'] != false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SosBackupContact &&
          id == other.id &&
          name == other.name &&
          relation == other.relation &&
          delaySeconds == other.delaySeconds &&
          enabled == other.enabled;

  @override
  int get hashCode => Object.hash(id, name, relation, delaySeconds, enabled);
}

/// SOS escalation ladder — rung 1 parents fixed; backups editable below (P-5).
@immutable
final class SosLadder {
  const SosLadder({
    required this.familyId,
    this.presentParentIds = const {'father', 'mother'},
    this.backups = const [],
  });

  static const String defaultFamilyId = 'default';

  /// Defaults: both parents present on rung 1; no backups.
  factory SosLadder.defaults({String familyId = defaultFamilyId}) => SosLadder(
        familyId: familyId,
        presentParentIds: Set<String>.from(kSosLadderFixedParentIds),
        backups: const [],
      );

  final String familyId;

  /// Parent member ids present in the family (subset of [kSosLadderFixedParentIds]).
  final Set<String> presentParentIds;

  /// Rung 2+ backup contacts (editable / removable / toggleable).
  final List<SosBackupContact> backups;

  /// Ordered rung-1 member ids (father, mother when present).
  List<String> get rung1MemberIds {
    final ids = kSosLadderFixedParentIds
        .where(presentParentIds.contains)
        .toList();
    ids.sort();
    return ids;
  }

  /// True when [memberId] is a fixed parent currently on rung 1.
  bool isRung1Parent(String memberId) =>
      kSosLadderFixedParentIds.contains(memberId) &&
      presentParentIds.contains(memberId);

  static bool isFixedParentId(String memberId) =>
      kSosLadderFixedParentIds.contains(memberId);

  SosLadder copyWith({
    String? familyId,
    Set<String>? presentParentIds,
    List<SosBackupContact>? backups,
  }) {
    return SosLadder(
      familyId: familyId ?? this.familyId,
      presentParentIds: presentParentIds ?? this.presentParentIds,
      backups: backups ?? this.backups,
    );
  }

  /// Ensures rung-1 parents stay present and backups never reuse parent ids.
  SosLadder normalized() {
    final parents = presentParentIds
        .where(kSosLadderFixedParentIds.contains)
        .toSet();
    final safeBackups = backups
        .where((b) => b.id.isNotEmpty && !kSosLadderFixedParentIds.contains(b.id))
        .toList();
    return SosLadder(
      familyId: familyId,
      presentParentIds: parents.isEmpty
          ? Set<String>.from(kSosLadderFixedParentIds)
          : parents,
      backups: safeBackups,
    );
  }

  Map<String, dynamic> toJson() => {
        'familyId': familyId,
        'presentParentIds': presentParentIds.toList()..sort(),
        'backups': backups.map((b) => b.toJson()).toList(),
      };

  factory SosLadder.fromJson(Map<String, dynamic> json) {
    final parentsRaw = json['presentParentIds'];
    final parents = <String>{};
    if (parentsRaw is List) {
      for (final p in parentsRaw) {
        final id = p.toString();
        if (kSosLadderFixedParentIds.contains(id)) parents.add(id);
      }
    }
    final backupsRaw = json['backups'];
    final backups = <SosBackupContact>[];
    if (backupsRaw is List) {
      for (final item in backupsRaw) {
        if (item is Map) {
          backups.add(
            SosBackupContact.fromJson(
              item.map((k, v) => MapEntry(k.toString(), v)),
            ),
          );
        }
      }
    }
    return SosLadder(
      familyId: json['familyId']?.toString() ?? defaultFamilyId,
      presentParentIds: parents.isEmpty
          ? Set<String>.from(kSosLadderFixedParentIds)
          : parents,
      backups: backups,
    ).normalized();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SosLadder &&
          familyId == other.familyId &&
          setEquals(presentParentIds, other.presentParentIds) &&
          listEquals(backups, other.backups);

  @override
  int get hashCode => Object.hash(
        familyId,
        Object.hashAll(presentParentIds.toList()..sort()),
        Object.hashAll(backups),
      );
}
