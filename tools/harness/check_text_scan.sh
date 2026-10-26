#!/usr/bin/env bash
#
# حارسُ الشذوذج النصّي — لا حرفٌ أجنبيٌّ ينجو في وثائقِ العربية ولا في رسائلِ الإيداع.
#
# لماذا يوجد: كتبَ الوكيلُ العربيّةَ يدوياً في هذه الجلسة مرّاتٍ كثيرة، ودخلتْ رسالةَ إيداعٍ واحدة
# حرفٌ شرق‑آسيويٌّ سهواً («رمزٌ شارد» لا معنى له في السياق). لا يختبرُ `flutter analyze` ولا `npm test`
# النثرَ العربيّ، فلا شيءَ غير هذا الحارس يُمسِك هذا الصنف من العطب — وهو صنفٌ يتكاثر بالصمت: يبقى
# في الوثيقة، يقرأه إنسانٌ فيتوقّف عند الجملة ولا يعرف إن كانت ترجمةً أم خطلاً.
#
# الاستعمال:
#   tools/harness/check_text_scan.sh                 # وثائقُ البرنامج والعقود والحلقة
#   tools/harness/check_text_scan.sh --message F     # يفحص ملف رسالة الإيداع F أيضاً
#   tools/harness/check_text_scan.sh --staged        # يفحص ما هو مُعَدّ للإيداع + رسالة HEAD
#
# Exit: 0 = لا شذوذج؛ 1 = وُجد، ويُطبع الموضعُ والحرفُ رقميّاً ليعرف القارئُ ماذا يمسح.
set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "not a git repository" >&2; exit 1; }

EXTRA_MESSAGE=""
MODE="docs"
for a in "$@"; do
  case "$a" in
    --message) MODE="message-pair"; continue ;;
    --staged) MODE="staged" ;;
    *)
      if [ "$MODE" = "message-pair" ]; then EXTRA_MESSAGE="$a"; MODE="docs+message"; fi
      ;;
  esac
done

python3 - "$MODE" "${EXTRA_MESSAGE}" <<'PY'
import re, subprocess, sys, os

mode, message_file = sys.argv[1], sys.argv[2]

# الحروفُ الشرقي‑آسيوية بمساحاتها: الهانغول والكانا والرموز الصينية الموحَّدة والمتوافق عليها،
# وأشكالُ العرض الكامل التي تأتي مع اللوحات اليابانية — فالشاردُ قد يكون حرفَ ترقيمٍ لا حرفَ كلمة.
STRAY = re.compile(
    '['
    '\u1100-\u11ff'   # Hangul Jamo
    '\u3040-\u30ff'   # Hiragana + Katakana
    '\u3130-\u318f'   # Hangul Compatibility Jamo
    '\u31c0-\u31ef'   # CJK strokes
    '\u3200-\u33ff'   # enclosed / compatibility CJK
    '\u4e00-\u9fff'   # CJK unified
    '\uf900-\ufaff'   # CJK compatibility ideographs
    '\ufe30-\ufe4f'   # CJK compatibility forms
    '\uff00-\uffef'   # fullwidth forms — includes «！」全角
    '\uac00-\ud7af'   # Hangul syllables
    ']'
)

DOC_ROOTS = [
    'docs/real_platform',
    'docs/contracts',
    'docs/harness',
    'docs/safety_phase',
]

def files():
    for root in DOC_ROOTS:
        if not os.path.isdir(root):
            continue
        for base, _dirs, names in os.walk(root):
            for n in names:
                if n.endswith(('.md', '.json', '.txt')):
                    yield os.path.join(base, n)

def texts():
    for p in files():
        try:
            with open(p, encoding='utf-8') as fh:
                yield p, fh.read()
        except (OSError, UnicodeDecodeError):
            continue

problems = []

for path, body in texts():
    for line_no, line in enumerate(body.split('\n'), 1):
        hits = STRAY.findall(line)
        if hits:
            problems.append(
                f'{path}:{line_no} — {"".join(hits)} '
                f'(U+{" ".join(f"{ord(c):04X}" for c in hits)})'
            )

def check_message(label, body):
    for line_no, line in enumerate(body.split('\n'), 1):
        hits = STRAY.findall(line)
        if hits:
            problems.append(
                f'{label}:{line_no} — {"".join(hits)} '
                f'(U+{" ".join(f"{ord(c):04X}" for c in hits)})'
            )

if mode == 'message-pair':
    if os.path.exists(message_file):
        check_message(os.path.basename(message_file), open(message_file, encoding='utf-8').read())
elif mode == 'staged':
    out = subprocess.run(
        ['git', 'diff', '--cached', '--name-only', '-z', '--', *DOC_ROOTS],
        capture_output=True, text=True,
    ).stdout.split('\0')
    for p in [x for x in out if x]:
        body = subprocess.run(['git', 'show', f':{p}'], capture_output=True, text=True).stdout
        for line_no, line in enumerate(body.split('\n'), 1):
            hits = STRAY.findall(line)
            if hits:
                problems.append(f'{p}:{line_no} — {"".join(hits)}')
    head = subprocess.run(['git', 'log', '-1', '--format=%B'], capture_output=True, text=True).stdout
    check_message('HEAD message', head)
elif mode == 'docs+message':
    if os.path.exists(message_file):
        check_message(os.path.basename(message_file), open(message_file, encoding='utf-8').read())

if problems:
    print(f'  ✖ حرفٌ أجنبيٌّ شارد في نصٍّ عربيّ ({len(problems)}):')
    for p in problems[:20]:
        print(f'      {p}')
    if len(problems) > 20:
        print(f'      … و{len(problems) - 20} أخرى')
    print('    لا استثناء: الوثائقُ العربيةُ لا يُفترَض أن تحمل حرفاً من هذه المساحات أصلاً.')
    sys.exit(1)

print('  ✔ لا رمزَ شرق‑آسيويًّا شاردًا في وثائق البرنامج والعقود والحلقة.')
PY
