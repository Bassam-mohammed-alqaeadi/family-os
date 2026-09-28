import json
import re
from pathlib import Path

p = Path(r"D:/special projects/family/app/lib/core/i18n/app_en.arb")
data = json.loads(p.read_text(encoding="utf-8"))
fixes = {
    "permissionsExplainerVideoToast": "Video comes later — preview only for now",
    "addFromSourceTopicToast": "Topic-only create is ready — type a concept next",
    "addFromSourceVoiceToast": "Voice explanation capture is coming — noted for now",
    "addFromSourcePdfSelectedToast": "Science notes selected",
    "studioCameraFrameSemantics": "Camera viewfinder aimed at a textbook page",
    "generationOutputsGeneratingToast": (
        "Local queue — The family assistant arrives in an upcoming update. "
        "Preview opens after generate."
    ),
    "webFilterDeliveryHonesty": (
        "Policy delivery is tracked locally (Configured→Verified). "
        "Device block arrives in an upcoming update."
    ),
    "brainStageAnalyzeSubtitle": "Patterns and anomalies — server assistance when enabled",
    "childModeLockSecretOpened": "Secret entry opened",
    "addEventCalendarHijriToast": "Hijri calendar selected",
    "addEventCalendarGregorianToast": "Gregorian calendar selected",
    "individualTimelineDiscussToast": "Suggestion queued for your family advisor.",
    "knowledgeMapsDinnerSendToast": "Sent to family chat — tonight's discussion is ready",
    "childLearnHomeMaterialSoonToast": "Coming soon on this path",
    "childTutorPhotoToast": "Photo a problem — I'll explain step by step",
    "smartAlertsDetectBody": (
        "1. Block / snapshot / report planes are designed here\n"
        "2. Capture & device permission: Needs a device permission — coming later\n"
        "3. You decide the next step when device delivery ships"
    ),
    "childFriendsChatToast": (
        "Safe chat opens locally — delivery to other devices arrives later"
    ),
    "peerComparePrivacyBanner": (
        "Fully anonymous comparison with general age averages — no names, "
        "no families, no shaming. Local cohort only — Email/PDF sharing comes later."
    ),
    "sosAlertDeliveryDelivered": (
        "{channel} → {recipient}: LOCAL only (other-device delivery closed)"
    ),
}
for k, v in fixes.items():
    if k in data:
        data[k] = v

# Topic label for praise placeholder
data["childResultPraiseTopicFractions"] = "adding fractions"
data["@childResultPraiseTopicFractions"] = {
    "description": "VX-B3 · CHD-016 praise topic label (Rule 23)"
}

ar = Path(r"D:/special projects/family/app/lib/core/i18n/app_ar.arb")
ar_data = json.loads(ar.read_text(encoding="utf-8"))
ar_data["childResultPraiseTopicFractions"] = "جمع الكسور"
ar_data["@childResultPraiseTopicFractions"] = {
    "description": "VX-B3 · CHD-016 praise topic label (Rule 23)"
}
ar.write_text(
    json.dumps(ar_data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
)

banned = re.compile(
    r"\b(Native|Remote|MOCK|FCM|MediaProjection|LiveKit|relay|backend|gateway)\b",
    re.I,
)
left = []
for k, v in data.items():
    if k.startswith("@") or not isinstance(v, str):
        continue
    if banned.search(v):
        left.append((k, v))

p.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print("EN remaining", len(left))
for k, v in left:
    print(k, ":", v[:120])
