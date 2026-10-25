#!/usr/bin/env python3
"""ARB + generated-l10n writer for Family OS, driven by a JSON message table.

Why this file exists: `flutter gen-l10n` is the only sanctioned writer of
`lib/core/i18n/app_localizations*.dart`, and the agent workspace has no Flutter SDK.
`test/tool/l10n_generated_shape_test.dart` states the generator's rules literally (a plain
message is one line when `  String get key => 'value';` is at most 80 UTF-16 units wide and is
split after `=>` when wider; every ARB message is declared in the abstract class and implemented
in both language files; the two ARB files carry the same key set), so this tool writes exactly
those shapes instead of guessing, and the owner's `flutter gen-l10n` gate stays a no-op diff.

Usage, from `app/`:
    python3 tool/arb_messages.py tool/messages/<slice>.json

The JSON is a list of messages, each an object:
    {"key": "...", "ar": "...", "en": "...", "desc": "...",
     "placeholders": [["minutes", "int"]]}

Copy rules this tool enforces or assumes, because they are tested rather than tasteful:
  * Arabic-first — the ARB template is `app_ar.arb`, English is the fallback;
  * Western digits only (`test/core/i18n/vx_b3_numeral_format_test.dart`);
  * no engineering jargon (`test/core/i18n/vx_b3_arb_human_language_test.dart` bans
    Native / Remote / Backend / relay / FCM / Gateway / MOCK / MediaProjection as words);
  * a key may be added exactly once — an existing key aborts the run rather than duplicating an
    entry, because a second `app_ar.arb` key with the same name is silent data loss.

Rewriting an ARB by hand with chained regexes has already cost this repo ~105 entries once; that
is why the whole file is re-emitted here from parsed JSON and re-parsed before it is kept.
"""

import json
import os
import re
import sys

ARB_DIR = os.path.join("lib", "core", "i18n")

JARGON = re.compile(
    r"\b(?:Native|Remote|REMOTE|FCM|Backend|MediaProjection|MOCK|Gateway|LiveKit|relay)\b",
    re.IGNORECASE,
)
EASTERN_DIGITS = re.compile(r"[٠-٩۰-۹]")
PLACEHOLDER = re.compile(r"\{([A-Za-z_][A-Za-z0-9_]*)\}")


def load(path):
    raw = json.load(open(path, encoding="utf-8"))
    if isinstance(raw, dict):
        raw = raw["messages"]
    messages = []
    for item in raw:
        messages.append(
            (
                item["key"],
                item["ar"],
                item["en"],
                item["desc"],
                [tuple(p) for p in item.get("placeholders", [])],
            )
        )
    return messages


def check(messages):
    """Refuse a table that would fail a CI gate after it has been written."""
    problems = []
    seen = set()
    for key, ar, en, desc, placeholders in messages:
        if key in seen:
            problems.append(f"{key}: repeated inside the table")
        seen.add(key)
        if not desc.endswith((".", "؟", "…")) and len(desc) < 12:
            problems.append(f"{key}: description too thin to review")
        for lang, value in (("ar", ar), ("en", en)):
            if JARGON.search(value):
                problems.append(f"{key}.{lang}: engineering jargon in user copy")
            if EASTERN_DIGITS.search(value):
                problems.append(f"{key}.{lang}: non-Western digits in user copy")
            named = set(PLACEHOLDER.findall(value))
            declared = {name for name, _ in placeholders}
            if named != declared:
                problems.append(
                    f"{key}.{lang}: placeholders {sorted(named)} vs {sorted(declared)}"
                )
    return problems


def dart_escape(value):
    """How gen-l10n escapes a message into a single-quoted Dart literal."""
    return value.replace("\\", "\\\\").replace("'", "\\'").replace('"', '\\"')


def dart_width(line):
    """Dart's own measure: UTF-16 code units."""
    return len(line.encode("utf-16-le")) // 2


def arb_entry(key, value, description, placeholders):
    lines = [f'  "{key}": {json.dumps(value, ensure_ascii=False)},']
    lines.append(f'  "@{key}": {{')
    described = f'    "description": {json.dumps(description, ensure_ascii=False)}'
    if placeholders:
        lines.append(described + ",")
        lines.append('    "placeholders": {')
        for index, (name, ptype) in enumerate(placeholders):
            lines.append(f'      "{name}": {{')
            lines.append(f'        "type": "{ptype}"')
            lines.append(
                "      }" + ("," if index < len(placeholders) - 1 else "")
            )
        lines.append("    }")
    else:
        lines.append(described)
    lines.append("  }")
    return "\n".join(lines)


def patch_arb(path, lang_index, messages):
    source = open(path, encoding="utf-8").read()
    for key, *_ in messages:
        if f'"{key}":' in source:
            raise SystemExit(f"{os.path.basename(path)} already carries {key} — add it once")
    stripped = source.rstrip()
    assert stripped.endswith("}"), path
    body = stripped[:-1].rstrip()
    if body.endswith(","):
        body = body[:-1]
    entries = []
    for key, ar, en, description, placeholders in messages:
        value = ar if lang_index == 0 else en
        entries.append(arb_entry(key, value, description, placeholders))
    updated = body + ",\n" + ",\n".join(entries) + "\n}\n"
    open(path, "w", encoding="utf-8").write(updated)
    json.loads(open(path, encoding="utf-8").read())  # must stay valid JSON
    return len(entries)


def abstract_entry(key, ar, description, placeholders):
    if placeholders:
        args = ", ".join(f"{ptype} {name}" for name, ptype in placeholders)
        signature = f"  String {key}({args});"
    else:
        signature = f"  String get {key};"
    return "\n".join(
        [
            f"  /// {description}",
            "  ///",
            "  /// In ar, this message translates to:",
            f"  /// **'{ar}'**",
            signature,
        ]
    )


def language_entry(key, value, placeholders):
    if placeholders:
        body = value
        for name, _ in placeholders:
            body = body.replace("{" + name + "}", "$" + name)
        args = ", ".join(f"{ptype} {name}" for name, ptype in placeholders)
        return "\n".join(
            [
                "  @override",
                f"  String {key}({args}) {{",
                f"    return '{dart_escape(body)}';",
                "  }",
            ]
        )
    single = f"  String get {key} => '{dart_escape(value)}';"
    if dart_width(single) <= 80:
        return f"  @override\n{single}"
    return f"  @override\n  String get {key} =>\n      '{dart_escape(value)}';"


def patch_generated(path, block, marker):
    source = open(path, encoding="utf-8").read()
    if not source.endswith("\n"):
        source += "\n"
    idx = source.rindex(marker)
    updated = (
        source[:idx].rstrip("\n") + "\n\n" + block.rstrip("\n") + "\n" + source[idx:]
    )
    open(path, "w", encoding="utf-8").write(updated)


def main(argv):
    if len(argv) < 2:
        raise SystemExit(__doc__)
    os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    messages = load(argv[1])
    problems = check(messages)
    if problems:
        for line in problems:
            print("BLOCKED:", line)
        return 1

    patch_arb(os.path.join(ARB_DIR, "app_ar.arb"), 0, messages)
    patch_arb(os.path.join(ARB_DIR, "app_en.arb"), 1, messages)
    patch_generated(
        os.path.join(ARB_DIR, "app_localizations.dart"),
        "\n\n".join(
            abstract_entry(key, ar, description, placeholders)
            for key, ar, _en, description, placeholders in messages
        ),
        "}\n\nclass _AppLocalizationsDelegate",
    )
    patch_generated(
        os.path.join(ARB_DIR, "app_localizations_ar.dart"),
        "\n\n".join(
            language_entry(key, ar, placeholders)
            for key, ar, _en, _d, placeholders in messages
        ),
        "}\n",
    )
    patch_generated(
        os.path.join(ARB_DIR, "app_localizations_en.dart"),
        "\n\n".join(
            language_entry(key, en, placeholders)
            for key, _ar, en, _d, placeholders in messages
        ),
        "}\n",
    )

    ar = json.load(open(os.path.join(ARB_DIR, "app_ar.arb"), encoding="utf-8"))
    en = json.load(open(os.path.join(ARB_DIR, "app_en.arb"), encoding="utf-8"))
    ar_keys = {k for k in ar if not k.startswith("@")}
    en_keys = {k for k in en if not k.startswith("@")}
    if ar_keys != en_keys:
        raise SystemExit("ARB key parity broken — refusing to leave that behind")
    print(
        f"added {len(messages)} messages · ar={len(ar_keys)} en={len(en_keys)} keys · parity ok"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
