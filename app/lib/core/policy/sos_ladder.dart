import 'package:flutter/foundation.dart';

/// Fixed member ids that always occupy SOS ladder rung 1 (P-5 / SET-020).
///
/// Competitive: Life360 / panic — parents are always on the emergency chain.
const Set<String> kSosLadderFixedParentIds = {'father', 'mother'};

/// Max editable backup contacts (FAT-028 / OD-04).
const int kSosMaxBackupContacts = 5;

/// Backup phone verification lifecycle (FAT-028).
enum SosVerificationStatus {
  unverified,
  pending,
  verified,
  revoked,
  failed,
}

/// Validation codes for illegal SOS ladder edits (SET-020).
abstract final class SosLadderValidationCode {
  static const rung1ParentImmovable = 'rung1_parent_immovable';
  static const rung1ParentDisableForbidden = 'rung1_parent_disable_forbidden';
  static const backupLimitExceeded = 'backup_limit_exceeded';
  static const priorityOutOfRange = 'priority_out_of_range';
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
    this.priority = 1,
    this.phoneE164 = '',
    this.verification = SosVerificationStatus.unverified,
  });

  final String id;
  final String name;
  final String relation;
  final int delaySeconds;
  final bool enabled;

  /// Escalation order among backups — must be 1..[kSosMaxBackupContacts].
  final int priority;

  /// Display/storage phone (E.164 preferred). Empty = not set.
  final String phoneE164;

  final SosVerificationStatus verification;

  /// Only [SosVerificationStatus.verified] backups participate in escalation.
  bool get isEscalationEligible =>
      enabled && verification == SosVerificationStatus.verified;

  SosBackupContact copyWith({
    String? id,
    String? name,
    String? relation,
    int? delaySeconds,
    bool? enabled,
    int? priority,
    String? phoneE164,
    SosVerificationStatus? verification,
  }) {
    return SosBackupContact(
      id: id ?? this.id,
      name: name ?? this.name,
      relation: relation ?? this.relation,
      delaySeconds: delaySeconds ?? this.delaySeconds,
      enabled: enabled ?? this.enabled,
      priority: priority ?? this.priority,
      phoneE164: phoneE164 ?? this.phoneE164,
      verification: verification ?? this.verification,
    );
  }

  /// Changing phone forces re-verification (UNVERIFIED).
  SosBackupContact withPhoneChanged(String nextPhone) {
    final trimmed = nextPhone.trim();
    if (trimmed == phoneE164) return this;
    return copyWith(
      phoneE164: trimmed,
      verification: SosVerificationStatus.unverified,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'relation': relation,
        'delaySeconds': delaySeconds,
        'enabled': enabled,
        'priority': priority,
        'phoneE164': phoneE164,
        'verification': verification.name,
      };

  factory SosBackupContact.fromJson(Map<String, dynamic> json) {
    final vRaw = json['verification']?.toString();
    final verification = SosVerificationStatus.values.firstWhere(
      (e) => e.name == vRaw,
      orElse: () => SosVerificationStatus.unverified,
    );
    final priority = (json['priority'] as num?)?.toInt() ?? 1;
    return SosBackupContact(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      relation: json['relation']?.toString() ?? '',
      delaySeconds: (json['delaySeconds'] as num?)?.toInt() ?? 60,
      enabled: json['enabled'] != false,
      priority: priority.clamp(1, kSosMaxBackupContacts),
      phoneE164: json['phoneE164']?.toString() ?? '',
      verification: verification,
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
          enabled == other.enabled &&
          priority == other.priority &&
          phoneE164 == other.phoneE164 &&
          verification == other.verification;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        relation,
        delaySeconds,
        enabled,
        priority,
        phoneE164,
        verification,
      );
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

  /// Backups sorted by [SosBackupContact.priority] ascending.
  List<SosBackupContact> get backupsByPriority {
    final list = List<SosBackupContact>.from(backups);
    list.sort((a, b) => a.priority.compareTo(b.priority));
    return list;
  }

  /// Verified + enabled backups only (escalation eligibility).
  List<SosBackupContact> get verifiedEscalationBackups =>
      backupsByPriority.where((b) => b.isEscalationEligible).toList();

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
