#!/usr/bin/env python3
"""VX-B3 — rewrite user-facing ARB honesty strings to glossary v1 (D2)."""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(r"D:/special projects/family/app/lib/core/i18n")

# Order matters — longer / more specific first.
AR_REPLACEMENTS: list[tuple[str, str]] = [
    ("MOCK-REMOTE", "على هذا الجهاز"),
    ("NOT IMPLEMENTED", "قريبًا"),
    ("IMPLEMENTED", "يعمل"),
    ("UNSUPPORTED", "غير مدعوم"),
    ("DEGRADED", "يعمل جزئيًا"),
    ("REMOTE CLOSED", "سيصل إلى الأجهزة الأخرى في تحديث قادم"),
    ("مغلقان Remote", "سيصلان إلى الأجهزة الأخرى في تحديث قادم"),
    ("مغلقتان Remote", "ستصلان إلى الأجهزة الأخرى في تحديث قادم"),
    ("مغلق Remote", "سيصل إلى الأجهزة الأخرى في تحديث قادم"),
    ("بوابة المستشار مغلق Remote", "مساعد العائلة الذكي يتوفر في تحديث قادم"),
    ("بوابة المعلّم مغلق Remote", "المعلّم الذكي يتوفر في تحديث قادم"),
    ("و بوابة المستشار مغلقان Remote", "ومساعد العائلة الذكي يتوفران في تحديث قادم"),
    ("و بوابة المستشار مغلقان", "ومساعد العائلة الذكي"),
    ("MediaProjection", "صلاحية الجهاز"),
    ("غير متاح حتى Native", "يتوفر في تحديث قادم"),
    ("حتى Native", "في تحديث قادم"),
    ("Native مغلقة", "تتوفر في تحديث قادم"),
    ("Native مغلق", "يتوفر في تحديث قادم"),
    ("Native CLOSED", "يتوفر في تحديث قادم"),
    ("جاهزية Native", "جاهزية الجهاز"),
    ("تحقق من جاهزية Native", "تحقق من جاهزية الجهاز"),
    ("Backend/FCM", "تحديث قادم للأجهزة الأخرى"),
    ("يتطلّبان Backend", "يتوفران في تحديث قادم"),
    ("يتطلّب Backend", "يتوفر في تحديث قادم"),
    ("Backend —", "تحديث قادم —"),
    ("يحتاج FCM", "سيصل للأجهزة الأخرى لاحقاً"),
    ("FCM", "إشعار الأجهزة الأخرى"),
    ("LiveKit الأصلي مغلق", "الاتصال الصوتي يتوفر في تحديث قادم"),
    ("عبر LiveKit", "صوت وفيديو"),
    ("LiveKit", "الاتصال الصوتي/المرئي"),
    ("Advisor Gateway", "مساعد العائلة"),
    ("Tutor AI Gateway", "المعلّم الذكي"),
    ("Gateway", "المساعد"),
    ("Native/Remote", "تحديث قادم"),
    ("Native", "الجهاز"),
    ("Remote", "الأجهزة الأخرى"),
]

EN_REPLACEMENTS: list[tuple[str, str]] = [
    ("MOCK-REMOTE", "On this device"),
    ("NOT IMPLEMENTED", "Coming soon"),
    ("IMPLEMENTED", "Works"),
    ("UNSUPPORTED", "Not supported"),
    ("DEGRADED", "Partly working"),
    ("Advisor Gateway REMOTE CLOSED", "The family assistant arrives in an upcoming update"),
    ("Tutor AI Gateway REMOTE CLOSED", "The tutor arrives in an upcoming update"),
    ("Advisor Gateway + family chat share REMOTE CLOSED", "Sharing and the family assistant arrive in an upcoming update"),
    ("Licensed audio + Advisor Gateway REMOTE CLOSED", "Licensed audio and the family assistant arrive in an upcoming update"),
    ("REMOTE CLOSED", "Will reach other devices in an upcoming update"),
    ("NAT CLOSED", "Needs a device permission — coming later"),
    ("Native CLOSED", "Needs a device permission — coming later"),
    ("unavailable until Native", "arrives in an upcoming update"),
    ("until Native", "in an upcoming update"),
    ("requires Backend/FCM", "reaches other devices in an upcoming update"),
    ("requires Backend", "arrives in an upcoming update"),
    ("Backend/FCM", "an upcoming update for other devices"),
    ("Backend —", "an upcoming update —"),
    ("needs FCM later", "will notify other devices later"),
    ("FCM", "device notification"),
    ("MediaProjection", "device permission"),
    ("via LiveKit", "audio and video"),
    ("LiveKit native CLOSED", "Calls arrive in an upcoming update"),
    ("LiveKit", "audio/video call"),
    ("Advisor Gateway", "family assistant"),
    ("Check Native readiness", "Check device readiness"),
    ("Native DNS", "device DNS"),
    ("Native/Remote", "an upcoming update"),
    ("needs Native", "needs an upcoming update"),
    ("requires Native", "arrives in an upcoming update"),
    ("Native", "device"),
    ("Remote", "other devices"),
    ("Gateway", "assistant"),
    ("relay", "delivery"),
]

# Word-boundary banned tokens for the guard (after rewrite).
BANNED = re.compile(
    r"\b(Native|Remote|MOCK|FCM|MediaProjection|LiveKit|relay|backend|gateway|Backend|Gateway)\b",
    re.I,
)


def scrub(value: str, reps: list[tuple[str, str]]) -> str:
    out = value
    for old, new in reps:
        out = out.replace(old, new)
    return out


def process(path: Path, reps: list[tuple[str, str]], *, is_ar: bool) -> int:
    data = json.loads(path.read_text(encoding="utf-8"))
    changed = 0
    remaining = []
    for key, val in list(data.items()):
        if key.startswith("@") or not isinstance(val, str):
            continue
        # Keep technical descriptions alone — only scrub values.
        new = scrub(val, reps)
        # Extra badge-specific
        if key == "capabilityStatusImplemented":
            new = "يعمل" if is_ar else "Works"
        elif key == "capabilityStatusMockRemote":
            new = "على هذا الجهاز" if is_ar else "On this device"
        elif key == "capabilityStatusDegraded":
            new = "يعمل جزئيًا" if is_ar else "Partly working"
        elif key == "capabilityStatusUnsupported":
            new = "غير مدعوم" if is_ar else "Not supported"
        elif key == "capabilityStatusNotImplemented":
            new = "قريبًا" if is_ar else "Coming soon"
        elif key == "languageHelpLocaleToast":
            new = "تم تغيير لغة الواجهة" if is_ar else "Interface language updated"
        elif key == "childResultPraiseMasteredAdd":
            # Will be replaced with placeholder form below
            new = "أتقنت {topic}!" if is_ar else "You mastered {topic}!"
        if new != val:
            data[key] = new
            changed += 1
        if BANNED.search(data[key]) and key not in {
            # keys that legitimately mention ending a session "remotely" as English
        }:
            # Allow "remotely" adverb in EN end-session copy by checking token list
            hits = BANNED.findall(data[key])
            # filter soft words
            hits = [h for h in hits if h.lower() not in {"remotely"}]
            if hits:
                remaining.append((key, data[key], hits))

    # Ensure praise placeholder metadata
    if "childResultPraiseMasteredAdd" in data:
        data["@childResultPraiseMasteredAdd"] = {
            "description": "VX-B3 · CHD-016 praise with dynamic topic (Rule 23)",
            "placeholders": {
                "topic": {"type": "String", "example": "fractions"}
            },
        }

    # Child gentle honesty line (new key)
    if is_ar:
        data["honestyChildGentleLine"] = (
            "بعض الأشياء هنا تعمل على هذا الجهاز فقط الآن 🌱"
        )
    else:
        data["honestyChildGentleLine"] = (
            "Some things here work on this device only for now 🌱"
        )
    data["@honestyChildGentleLine"] = {
        "description": "VX-B3 glossary v1 · child screens one gentle line (D2)"
    }

    path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"{path.name}: changed {changed} values; remaining banned hits: {len(remaining)}")
    for key, val, hits in remaining[:40]:
        print(f"  ! {key}: {hits} → {val[:120]}")
    return len(remaining)


def main() -> None:
    left = 0
    left += process(ROOT / "app_ar.arb", AR_REPLACEMENTS, is_ar=True)
    left += process(ROOT / "app_en.arb", EN_REPLACEMENTS, is_ar=False)
    print("TOTAL remaining", left)


if __name__ == "__main__":
    main()
