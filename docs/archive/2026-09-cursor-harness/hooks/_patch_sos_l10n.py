#!/usr/bin/env python3
"""Append SOS Flutter UI slice ARB keys and patch generated localizations."""
from __future__ import annotations

import json
import pathlib
import re

ROOT = pathlib.Path(r"D:\special projects\family\app\lib\core\i18n")
en_path = ROOT / "app_en.arb"
ar_path = ROOT / "app_ar.arb"

new_en = {
  "sosAlertAcknowledgeCta": "Acknowledge — I saw this alert",
  "@sosAlertAcknowledgeCta": {"description": "SCR-FAT-018 acknowledge CTA"},
  "sosAlertAcknowledgeSemantics": "Acknowledge the SOS alert without closing it",
  "@sosAlertAcknowledgeSemantics": {"description": "SCR-FAT-018 acknowledge Semantics"},
  "sosAlertAcknowledgedToast": "Acknowledged — alert remains open until resolved",
  "@sosAlertAcknowledgedToast": {"description": "SCR-FAT-018 ack toast"},
  "sosAlertCallUnavailableToast": "Calling is not configured on this device yet — alert stays active",
  "@sosAlertCallUnavailableToast": {"description": "SCR-FAT-018 honest call unavailable"},
  "sosAlertStatusActive": "Incident: ACTIVE",
  "@sosAlertStatusActive": {"description": "SOS incident status"},
  "sosAlertStatusAcknowledged": "Incident: ACKNOWLEDGED",
  "@sosAlertStatusAcknowledged": {"description": "SOS incident status"},
  "sosAlertStatusEscalating": "Incident: ESCALATING",
  "@sosAlertStatusEscalating": {"description": "SOS incident status"},
  "sosAlertLocationAcquiring": "Location: ACQUIRING",
  "@sosAlertLocationAcquiring": {"description": "SOS location class"},
  "sosAlertLocationReady": "Location: READY",
  "@sosAlertLocationReady": {"description": "SOS location class"},
  "sosAlertLocationStale": "Location: STALE",
  "@sosAlertLocationStale": {"description": "SOS location class"},
  "sosAlertLocationUnavailable": "Location: UNAVAILABLE",
  "@sosAlertLocationUnavailable": {"description": "SOS location class"},
  "sosAlertDeliveryPending": "{channel} → {recipient}: PENDING",
  "@sosAlertDeliveryPending": {
    "description": "SOS delivery row",
    "placeholders": {"channel": {"type": "String"}, "recipient": {"type": "String"}},
  },
  "sosAlertDeliveryFailed": "{channel} → {recipient}: FAILED",
  "@sosAlertDeliveryFailed": {
    "description": "SOS delivery row",
    "placeholders": {"channel": {"type": "String"}, "recipient": {"type": "String"}},
  },
  "sosAlertDeliveryUnavailable": "{channel} → {recipient}: UNAVAILABLE",
  "@sosAlertDeliveryUnavailable": {
    "description": "SOS delivery row",
    "placeholders": {"channel": {"type": "String"}, "recipient": {"type": "String"}},
  },
  "sosAlertDeliveryNotConfigured": "{channel} → {recipient}: NOT_CONFIGURED",
  "@sosAlertDeliveryNotConfigured": {
    "description": "SOS delivery row",
    "placeholders": {"channel": {"type": "String"}, "recipient": {"type": "String"}},
  },
  "sosAlertDeliveryDelivered": "{channel} → {recipient}: DELIVERED",
  "@sosAlertDeliveryDelivered": {
    "description": "SOS delivery row",
    "placeholders": {"channel": {"type": "String"}, "recipient": {"type": "String"}},
  },
  "sosAlertBreakGlassCta": "Temporary break-glass override…",
  "@sosAlertBreakGlassCta": {"description": "SCR-FAT-018 break-glass CTA"},
  "sosAlertBreakGlassSemantics": "Open temporary break-glass override sheet",
  "@sosAlertBreakGlassSemantics": {"description": "SCR-FAT-018 break-glass Semantics"},
  "sosBreakGlassTitle": "Temporary break-glass",
  "@sosBreakGlassTitle": {"description": "Break-glass sheet title"},
  "sosBreakGlassBody": "This temporarily unlocks SOS response tools for {minutes} minutes. It does not change permanent SOS policy and is audited.",
  "@sosBreakGlassBody": {
    "description": "Break-glass body",
    "placeholders": {"minutes": {"type": "int"}},
  },
  "sosBreakGlassReasonLabel": "Reason / context",
  "@sosBreakGlassReasonLabel": {"description": "Break-glass reason field"},
  "sosBreakGlassContinueCta": "Continue",
  "@sosBreakGlassContinueCta": {"description": "Break-glass continue"},
  "sosBreakGlassConfirmCta": "Confirm temporary override",
  "@sosBreakGlassConfirmCta": {"description": "Break-glass confirm"},
  "sosBreakGlassCancelCta": "Cancel",
  "@sosBreakGlassCancelCta": {"description": "Break-glass cancel"},
  "sosAlertObserverViewOnlyNote": "Observer: view and acknowledge only — resolve, escalate, and setup are not available",
  "@sosAlertObserverViewOnlyNote": {"description": "FAT-018 observer note"},
  "sosAlertHonestyBanner": "SOS is always available — delivery channels show honest status only",
  "@sosAlertHonestyBanner": {"description": "FAT-018 honesty banner"},
  "sosAlertIncidentNote": "Emergency incident is open — location and delivery status below are honest",
  "@sosAlertIncidentNote": {"description": "FAT-018 incident note"},
  "childSosInProgressLocationPending": "Location status shown honestly — GPS provider not active in this build",
  "@childSosInProgressLocationPending": {"description": "CHD-006 location honesty"},
  "childSosInProgressDeliveryHonesty": "Parent notification status is shown per channel — no silent success",
  "@childSosInProgressDeliveryHonesty": {"description": "CHD-006 delivery honesty"},
  "childSosInProgressCallUnavailableToast": "Calling is not available in this build — SOS stays active",
  "@childSosInProgressCallUnavailableToast": {"description": "CHD-006 call honesty"},
  "sosLadderMaxBackupsError": "Maximum 5 backup contacts",
  "@sosLadderMaxBackupsError": {"description": "FAT-028 max backups"},
  "sosLadderVerificationUnverified": "UNVERIFIED",
  "@sosLadderVerificationUnverified": {"description": "FAT-028 verification"},
  "sosLadderVerificationPending": "PENDING",
  "@sosLadderVerificationPending": {"description": "FAT-028 verification"},
  "sosLadderVerificationVerified": "VERIFIED",
  "@sosLadderVerificationVerified": {"description": "FAT-028 verification"},
  "sosLadderVerificationRevoked": "REVOKED",
  "@sosLadderVerificationRevoked": {"description": "FAT-028 verification"},
  "sosLadderVerificationFailed": "FAILED",
  "@sosLadderVerificationFailed": {"description": "FAT-028 verification"},
  "sosLadderPriorityLabel": "P{priority}",
  "@sosLadderPriorityLabel": {
    "description": "FAT-028 priority",
    "placeholders": {"priority": {"type": "int"}},
  },
  "sosLadderReadOnlyTitle": "View only",
  "@sosLadderReadOnlyTitle": {"description": "FAT-028 read-only title"},
  "sosLadderReadOnlyMessage": "Only the primary parent or mother with Full access can edit emergency contacts",
  "@sosLadderReadOnlyMessage": {"description": "FAT-028 read-only message"},
  "sosPanicQuietTitle": "Panic Quiet Mode (child)",
  "@sosPanicQuietTitle": {"description": "FAT-028 panic quiet"},
  "sosPanicQuietSubtitle": "When preferred, the child SOS active screen shows critical status only",
  "@sosPanicQuietSubtitle": {"description": "FAT-028 panic quiet subtitle"},
  "sosReadinessTitle": "Capability readiness",
  "@sosReadinessTitle": {"description": "FAT-028 readiness"},
  "sosReadinessBody": "Push, SMS, and calling are NOT_CONFIGURED in this UI slice. SOS still fires in-app.",
  "@sosReadinessBody": {"description": "FAT-028 readiness body"},
  "sosAlertConnectionOnline": "Connection: ONLINE",
  "@sosAlertConnectionOnline": {"description": "SOS connection"},
  "sosAlertConnectionDegraded": "Connection: DEGRADED",
  "@sosAlertConnectionDegraded": {"description": "SOS connection"},
  "sosAlertConnectionOffline": "Connection: OFFLINE",
  "@sosAlertConnectionOffline": {"description": "SOS connection"},
  "sosBreakGlassCapabilityDefault": "SOS response tools",
  "@sosBreakGlassCapabilityDefault": {"description": "Default break-glass capability label"},
}

new_ar = {
  "sosAlertAcknowledgeCta": "إقرار — رأيت هذا البلاغ",
  "@sosAlertAcknowledgeCta": {"description": "SCR-FAT-018 acknowledge CTA"},
  "sosAlertAcknowledgeSemantics": "إقرار بلاغ الاستغاثة دون إغلاقه",
  "@sosAlertAcknowledgeSemantics": {"description": "SCR-FAT-018 acknowledge Semantics"},
  "sosAlertAcknowledgedToast": "تم الإقرار — البلاغ يبقى مفتوحًا حتى يُغلق",
  "@sosAlertAcknowledgedToast": {"description": "SCR-FAT-018 ack toast"},
  "sosAlertCallUnavailableToast": "الاتصال غير مُعدّ على هذا الجهاز بعد — البلاغ يبقى نشطًا",
  "@sosAlertCallUnavailableToast": {"description": "SCR-FAT-018 honest call unavailable"},
  "sosAlertStatusActive": "الحادثة: نشطة",
  "@sosAlertStatusActive": {"description": "SOS incident status"},
  "sosAlertStatusAcknowledged": "الحادثة: مُقرّ بها",
  "@sosAlertStatusAcknowledged": {"description": "SOS incident status"},
  "sosAlertStatusEscalating": "الحادثة: تصعيد",
  "@sosAlertStatusEscalating": {"description": "SOS incident status"},
  "sosAlertLocationAcquiring": "الموقع: جاري التحديد",
  "@sosAlertLocationAcquiring": {"description": "SOS location class"},
  "sosAlertLocationReady": "الموقع: جاهز",
  "@sosAlertLocationReady": {"description": "SOS location class"},
  "sosAlertLocationStale": "الموقع: قديم",
  "@sosAlertLocationStale": {"description": "SOS location class"},
  "sosAlertLocationUnavailable": "الموقع: غير متاح",
  "@sosAlertLocationUnavailable": {"description": "SOS location class"},
  "sosAlertDeliveryPending": "{channel} → {recipient}: قيد الانتظار",
  "@sosAlertDeliveryPending": {
    "description": "SOS delivery row",
    "placeholders": {"channel": {"type": "String"}, "recipient": {"type": "String"}},
  },
  "sosAlertDeliveryFailed": "{channel} → {recipient}: فشل",
  "@sosAlertDeliveryFailed": {
    "description": "SOS delivery row",
    "placeholders": {"channel": {"type": "String"}, "recipient": {"type": "String"}},
  },
  "sosAlertDeliveryUnavailable": "{channel} → {recipient}: غير متاح",
  "@sosAlertDeliveryUnavailable": {
    "description": "SOS delivery row",
    "placeholders": {"channel": {"type": "String"}, "recipient": {"type": "String"}},
  },
  "sosAlertDeliveryNotConfigured": "{channel} → {recipient}: غير مُعدّ",
  "@sosAlertDeliveryNotConfigured": {
    "description": "SOS delivery row",
    "placeholders": {"channel": {"type": "String"}, "recipient": {"type": "String"}},
  },
  "sosAlertDeliveryDelivered": "{channel} → {recipient}: وصل",
  "@sosAlertDeliveryDelivered": {
    "description": "SOS delivery row",
    "placeholders": {"channel": {"type": "String"}, "recipient": {"type": "String"}},
  },
  "sosAlertBreakGlassCta": "تجاوز مؤقت (كسر الزجاج)…",
  "@sosAlertBreakGlassCta": {"description": "SCR-FAT-018 break-glass CTA"},
  "sosAlertBreakGlassSemantics": "فتح ورقة التجاوز المؤقت",
  "@sosAlertBreakGlassSemantics": {"description": "SCR-FAT-018 break-glass Semantics"},
  "sosBreakGlassTitle": "تجاوز مؤقت",
  "@sosBreakGlassTitle": {"description": "Break-glass sheet title"},
  "sosBreakGlassBody": "يفتح مؤقتًا أدوات الاستجابة لمدة {minutes} دقيقة. لا يغيّر سياسة الاستغاثة الدائمة ويُسجَّل في السجل.",
  "@sosBreakGlassBody": {
    "description": "Break-glass body",
    "placeholders": {"minutes": {"type": "int"}},
  },
  "sosBreakGlassReasonLabel": "السبب / السياق",
  "@sosBreakGlassReasonLabel": {"description": "Break-glass reason field"},
  "sosBreakGlassContinueCta": "متابعة",
  "@sosBreakGlassContinueCta": {"description": "Break-glass continue"},
  "sosBreakGlassConfirmCta": "تأكيد التجاوز المؤقت",
  "@sosBreakGlassConfirmCta": {"description": "Break-glass confirm"},
  "sosBreakGlassCancelCta": "إلغاء",
  "@sosBreakGlassCancelCta": {"description": "Break-glass cancel"},
  "sosAlertObserverViewOnlyNote": "مراقبة: عرض وإقرار فقط — الإغلاق والتصعيد والإعداد غير متاحة",
  "@sosAlertObserverViewOnlyNote": {"description": "FAT-018 observer note"},
  "sosAlertHonestyBanner": "الاستغاثة متاحة دائمًا — تظهر حالات التسليم بصدق فقط",
  "@sosAlertHonestyBanner": {"description": "FAT-018 honesty banner"},
  "sosAlertIncidentNote": "حادثة طوارئ مفتوحة — حالة الموقع والتسليم أدناه صادقة",
  "@sosAlertIncidentNote": {"description": "FAT-018 incident note"},
  "childSosInProgressLocationPending": "حالة الموقع صادقة — مزوّد GPS غير نشط في هذا البناء",
  "@childSosInProgressLocationPending": {"description": "CHD-006 location honesty"},
  "childSosInProgressDeliveryHonesty": "حالة إبلاغ الوالدين لكل قناة — بلا نجاح صامت",
  "@childSosInProgressDeliveryHonesty": {"description": "CHD-006 delivery honesty"},
  "childSosInProgressCallUnavailableToast": "الاتصال غير متاح في هذا البناء — الاستغاثة تبقى نشطة",
  "@childSosInProgressCallUnavailableToast": {"description": "CHD-006 call honesty"},
  "sosLadderMaxBackupsError": "الحد الأقصى ٥ جهات احتياط",
  "@sosLadderMaxBackupsError": {"description": "FAT-028 max backups"},
  "sosLadderVerificationUnverified": "غير موثّق",
  "@sosLadderVerificationUnverified": {"description": "FAT-028 verification"},
  "sosLadderVerificationPending": "قيد التحقق",
  "@sosLadderVerificationPending": {"description": "FAT-028 verification"},
  "sosLadderVerificationVerified": "موثّق",
  "@sosLadderVerificationVerified": {"description": "FAT-028 verification"},
  "sosLadderVerificationRevoked": "ملغى",
  "@sosLadderVerificationRevoked": {"description": "FAT-028 verification"},
  "sosLadderVerificationFailed": "فشل",
  "@sosLadderVerificationFailed": {"description": "FAT-028 verification"},
  "sosLadderPriorityLabel": "أ{priority}",
  "@sosLadderPriorityLabel": {
    "description": "FAT-028 priority",
    "placeholders": {"priority": {"type": "int"}},
  },
  "sosLadderReadOnlyTitle": "عرض فقط",
  "@sosLadderReadOnlyTitle": {"description": "FAT-028 read-only title"},
  "sosLadderReadOnlyMessage": "ولي الأمر الأساسي أو الأم بصلاحية كاملة فقط يعدّلون جهات الطوارئ",
  "@sosLadderReadOnlyMessage": {"description": "FAT-028 read-only message"},
  "sosPanicQuietTitle": "وضع الهدوء أثناء الاستغاثة (طفل)",
  "@sosPanicQuietTitle": {"description": "FAT-028 panic quiet"},
  "sosPanicQuietSubtitle": "عند التفعيل، شاشة الاستغاثة النشطة للطفل تعرض الحالة الحرجة فقط",
  "@sosPanicQuietSubtitle": {"description": "FAT-028 panic quiet subtitle"},
  "sosReadinessTitle": "جاهزية القدرات",
  "@sosReadinessTitle": {"description": "FAT-028 readiness"},
  "sosReadinessBody": "الدفع والرسائل والاتصال غير مُعدّة في هذه الشريحة. الاستغاثة تعمل داخل التطبيق.",
  "@sosReadinessBody": {"description": "FAT-028 readiness body"},
  "sosAlertConnectionOnline": "الاتصال: متصل",
  "@sosAlertConnectionOnline": {"description": "SOS connection"},
  "sosAlertConnectionDegraded": "الاتصال: متدهور",
  "@sosAlertConnectionDegraded": {"description": "SOS connection"},
  "sosAlertConnectionOffline": "الاتصال: غير متصل",
  "@sosAlertConnectionOffline": {"description": "SOS connection"},
  "sosBreakGlassCapabilityDefault": "أدوات الاستجابة للاستغاثة",
  "@sosBreakGlassCapabilityDefault": {"description": "Default break-glass capability label"},
}

honesty_en = {
  "sosAlertSirenBanner": "SOS alert is open — channels below show honest delivery status",
  "sosAlertLiveBroadcastNote": "Incident open — location and delivery are reported honestly (no silent success)",
  "sosAlertAutoCallPending": "Call capability: NOT_CONFIGURED in this build",
  "sosAlertCallStartedToast": "Calling is not configured yet — alert stays active",
  "sosAlertEscalatedToast": "Escalation requested — delivery status stays honest per channel",
  "sosAlertRecipientsFooter": "Recipients: {names} — SOS is never paywalled",
  "childSosInProgressBroadcast": "Help request is active — status below is honest",
  "childSosInProgressFatherSeen": "Father channel: see delivery status",
  "childSosInProgressMotherSeen": "Mother channel: see delivery status",
  "childSosInProgressBackupStandby": "Backup escalation: verified contacts only when configured",
}

honesty_ar = {
  "sosAlertSirenBanner": "بلاغ الاستغاثة مفتوح — القنوات أدناه تعرض حالة التسليم بصدق",
  "sosAlertLiveBroadcastNote": "الحادثة مفتوحة — الموقع والتسليم يُعرضان بصدق (بلا نجاح صامت)",
  "sosAlertAutoCallPending": "الاتصال: غير مُعدّ في هذا البناء",
  "sosAlertCallStartedToast": "الاتصال غير مُعدّ بعد — البلاغ يبقى نشطًا",
  "sosAlertEscalatedToast": "طُلب التصعيد — حالة التسليم تبقى صادقة لكل قناة",
  "sosAlertRecipientsFooter": "المستلمون: {names} — الاستغاثة بلا اشتراك",
  "childSosInProgressBroadcast": "طلب النجدة نشط — الحالة أدناه صادقة",
  "childSosInProgressFatherSeen": "قناة الأب: راجع حالة التسليم",
  "childSosInProgressMotherSeen": "قناة الأم: راجع حالة التسليم",
  "childSosInProgressBackupStandby": "تصعيد الاحتياط: جهات موثّقة فقط عند الإعداد",
}


def load(path: pathlib.Path) -> dict:
  return json.loads(path.read_text(encoding="utf-8"))


def save(path: pathlib.Path, data: dict) -> None:
  path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


en = load(en_path)
ar = load(ar_path)
en.update(new_en)
en.update(honesty_en)
ar.update(new_ar)
ar.update(honesty_ar)
save(en_path, en)
save(ar_path, ar)
print("ARB keys written:", len(new_en))

# Patch generated Dart localizations manually (repo keeps checked-in gen files).
abstract_path = ROOT / "app_localizations.dart"
en_dart = ROOT / "app_localizations_en.dart"
ar_dart = ROOT / "app_localizations_ar.dart"

GETTERS = [
  ("sosAlertAcknowledgeCta", "String get", None),
  ("sosAlertAcknowledgeSemantics", "String get", None),
  ("sosAlertAcknowledgedToast", "String get", None),
  ("sosAlertCallUnavailableToast", "String get", None),
  ("sosAlertStatusActive", "String get", None),
  ("sosAlertStatusAcknowledged", "String get", None),
  ("sosAlertStatusEscalating", "String get", None),
  ("sosAlertLocationAcquiring", "String get", None),
  ("sosAlertLocationReady", "String get", None),
  ("sosAlertLocationStale", "String get", None),
  ("sosAlertLocationUnavailable", "String get", None),
  ("sosAlertDeliveryPending", "String", "String channel, String recipient"),
  ("sosAlertDeliveryFailed", "String", "String channel, String recipient"),
  ("sosAlertDeliveryUnavailable", "String", "String channel, String recipient"),
  ("sosAlertDeliveryNotConfigured", "String", "String channel, String recipient"),
  ("sosAlertDeliveryDelivered", "String", "String channel, String recipient"),
  ("sosAlertBreakGlassCta", "String get", None),
  ("sosAlertBreakGlassSemantics", "String get", None),
  ("sosBreakGlassTitle", "String get", None),
  ("sosBreakGlassBody", "String", "int minutes"),
  ("sosBreakGlassReasonLabel", "String get", None),
  ("sosBreakGlassContinueCta", "String get", None),
  ("sosBreakGlassConfirmCta", "String get", None),
  ("sosBreakGlassCancelCta", "String get", None),
  ("sosAlertObserverViewOnlyNote", "String get", None),
  ("sosAlertHonestyBanner", "String get", None),
  ("sosAlertIncidentNote", "String get", None),
  ("childSosInProgressLocationPending", "String get", None),
  ("childSosInProgressDeliveryHonesty", "String get", None),
  ("childSosInProgressCallUnavailableToast", "String get", None),
  ("sosLadderMaxBackupsError", "String get", None),
  ("sosLadderVerificationUnverified", "String get", None),
  ("sosLadderVerificationPending", "String get", None),
  ("sosLadderVerificationVerified", "String get", None),
  ("sosLadderVerificationRevoked", "String get", None),
  ("sosLadderVerificationFailed", "String get", None),
  ("sosLadderPriorityLabel", "String", "int priority"),
  ("sosLadderReadOnlyTitle", "String get", None),
  ("sosLadderReadOnlyMessage", "String get", None),
  ("sosPanicQuietTitle", "String get", None),
  ("sosPanicQuietSubtitle", "String get", None),
  ("sosReadinessTitle", "String get", None),
  ("sosReadinessBody", "String get", None),
  ("sosAlertConnectionOnline", "String get", None),
  ("sosAlertConnectionDegraded", "String get", None),
  ("sosAlertConnectionOffline", "String get", None),
  ("sosBreakGlassCapabilityDefault", "String get", None),
]


def abstract_decls() -> str:
  lines = []
  for name, kind, params in GETTERS:
    if params is None:
      lines.append(f"  {kind} {name};")
    else:
      lines.append(f"  {kind} {name}({params});")
  return "\n".join(lines) + "\n"


def en_impl(name: str, kind: str, params: str | None) -> str:
  val = new_en[name]
  if params is None:
    return f"  @override\n  String get {name} => {json.dumps(val, ensure_ascii=False)};\n"
  if name.startswith("sosAlertDelivery"):
    # '{channel} → {recipient}: PENDING'
    template = val.replace("{channel}", "$channel").replace("{recipient}", "$recipient")
    return (
      f"  @override\n"
      f"  String {name}(String channel, String recipient) =>\n"
      f"      '{template}';\n"
    )
  if name == "sosBreakGlassBody":
    template = val.replace("{minutes}", "$minutes")
    return (
      f"  @override\n"
      f"  String {name}(int minutes) =>\n"
      f"      '{template}';\n"
    )
  if name == "sosLadderPriorityLabel":
    template = val.replace("{priority}", "$priority")
    return (
      f"  @override\n"
      f"  String {name}(int priority) => '{template}';\n"
    )
  raise AssertionError(name)


def ar_impl(name: str, kind: str, params: str | None) -> str:
  val = new_ar[name]
  if params is None:
    return f"  @override\n  String get {name} => {json.dumps(val, ensure_ascii=False)};\n"
  if name.startswith("sosAlertDelivery"):
    template = val.replace("{channel}", "$channel").replace("{recipient}", "$recipient")
    return (
      f"  @override\n"
      f"  String {name}(String channel, String recipient) =>\n"
      f"      '{template}';\n"
    )
  if name == "sosBreakGlassBody":
    template = val.replace("{minutes}", "$minutes")
    return (
      f"  @override\n"
      f"  String {name}(int minutes) =>\n"
      f"      '{template}';\n"
    )
  if name == "sosLadderPriorityLabel":
    template = val.replace("{priority}", "$priority")
    return (
      f"  @override\n"
      f"  String {name}(int priority) => '{template}';\n"
    )
  raise AssertionError(name)


def ensure_abstract(text: str) -> str:
  if "sosAlertAcknowledgeCta" in text:
    return text
  # Insert before closing brace of abstract class — find last getter before final }
  # Safer: insert after sosAlertCallStartedToast declaration
  needle = "  String get sosAlertCallStartedToast;"
  if needle not in text:
    raise SystemExit("abstract needle missing")
  return text.replace(needle, needle + "\n" + abstract_decls().rstrip("\n"))


def ensure_impl(path: pathlib.Path, builder) -> None:
  text = path.read_text(encoding="utf-8")
  if "sosAlertAcknowledgeCta" in text:
    print(path.name, "already patched")
    return
  # Insert before class closing — after last method of AppLocalizationsEn/Ar
  # Find sosAlertCallStartedToast implementation and append after it
  pattern = re.compile(
    r"  @override\n  String get sosAlertCallStartedToast =>\n      '[^']*';\n",
    re.M,
  )
  m = pattern.search(text)
  if not m:
    # single-line form
    pattern2 = re.compile(
      r"  @override\n  String get sosAlertCallStartedToast => '[^']*';\n"
    )
    m = pattern2.search(text)
  if not m:
    raise SystemExit(f"impl needle missing in {path}")
  block = "".join(builder(n, k, p) + "\n" for n, k, p in GETTERS)
  text = text[: m.end()] + "\n" + block + text[m.end() :]
  # Also update honesty string literals for known keys if present
  path.write_text(text, encoding="utf-8")
  print("patched", path.name)


abstract = abstract_path.read_text(encoding="utf-8")
abstract_path.write_text(ensure_abstract(abstract), encoding="utf-8")
print("abstract patched")

ensure_impl(en_dart, en_impl)
ensure_impl(ar_dart, ar_impl)

# Patch honesty strings in EN/AR dart for existing getters
for path, mapping in ((en_dart, honesty_en), (ar_dart, honesty_ar)):
  text = path.read_text(encoding="utf-8")
  for key, val in mapping.items():
    # Replace getter body for simple getters; skip parameterized
    if "{" in val and key == "sosAlertRecipientsFooter":
      # keep placeholder form in dart
      continue
    pat = re.compile(
      rf"(  @override\n  String get {key} =>)([\s\S]*?;)\n",
      re.M,
    )
    if not pat.search(text):
      continue
    text = pat.sub(
      rf"\1 {json.dumps(val, ensure_ascii=False)};\n",
      text,
      count=1,
    )
  path.write_text(text, encoding="utf-8")

print("done")
