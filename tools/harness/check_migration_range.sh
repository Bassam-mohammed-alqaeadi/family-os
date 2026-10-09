#!/usr/bin/env bash
#
# Family OS — حارس نطاق ترقيم الهجرات.
#
#   tools/harness/check_migration_range.sh
#
# يمنع أخطر تعارض صامت: هجرتان بنفس الرقم، أو هجرة جديدة خارج تسلسل main.
#
# لماذا هذا خطر حقيقي: الأسماء تختلف فيمرّ الدمج في Git بلا تعارض ظاهر،
# بينما `schema-manifest.js` يحمل الرقم مرتين بترتيب غير معرّف — فينشأ عطل
# في قاعدة البيانات لا يظهر في المراجعة إطلاقاً.
#
# منذ توحيد التطوير على `main` (أكتوبر ٢٠٢٦) لا توجد فروع متوازية طويلة العمر.
# الترقيم متسلسل على main وحده:
#
#   001–008 → التاريخ المشترك الموروث (مستثنى صراحةً)
#   100–113 → عمل arena/6233 الذي دُمج في main (محفوظ في الوسم archive/arena-6233f1a1)
#   114+    → كل هجرة جديدة، بالتسلسل، على main
#
# أي عمل يُنقل من فرع مؤرشف (مثل 009_pairing_code_short_numeric.sql في
# archive/arena-e8dd180c) يجب أن يُعاد ترقيمه إلى الرقم التالي على main.
#
# Exit: 0 = الترقيم داخل النطاق، 1 = خارج النطاق.

set -uo pipefail

GREEN=$'\033[32m'; RED=$'\033[31m'; YELLOW=$'\033[33m'; BOLD=$'\033[1m'; OFF=$'\033[0m'
PROBLEMS=0
OK()   { printf "  ${GREEN}✔${OFF} %s\n" "$*"; }
BAD()  { printf "  ${RED}✖${OFF} %s\n" "$*"; PROBLEMS=$((PROBLEMS + 1)); announce "Migration range" "$*"; }
WARN() { printf "  ${YELLOW}▲${OFF} %s\n" "$*"; }

cd "$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "not a git repository"; exit 1; }

# في CI لا تصل سجلات المهمة إلى هنا، لكن واجهة الإعلانات تعمل. فالأداة تُعلن سبب
# فشلها بنفسها بدل أن تترك قارئاً أعمى يخمّن.
announce() {
  [ -n "${GITHUB_ACTIONS:-}" ] || return 0
  printf '::error title=%s::%s\n' "$1" "$2"
}

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
MIGRATIONS_DIR="backend/db/migrations"
MANIFEST="backend/src/schema-manifest.js"

# النطاق المسموح على main: ١٠٠ فما فوق، بالتسلسل.
RANGE_MIN=100
RANGE_MAX=999

printf "\n${BOLD}نطاق ترقيم الهجرات${OFF}\n"
printf "  الفرع: %s\n" "$BRANCH"

[ -d "$MIGRATIONS_DIR" ] || { BAD "لا يوجد مجلد هجرات: $MIGRATIONS_DIR"; exit 1; }

# ١) هل الهجرات الموجودة داخل نطاق main (100+) أو من التاريخ المشترك المعلن؟
#    الممنوع هو **إضافة** رقم جديد خارج تسلسل main (مثل 009 من فرع مؤرشف).
VIOLATIONS=0

# الموروث مُعلَن صراحةً، لا مُستنتَج من آثار Git.
#
# ولماذا: جُرِّب الاستنتاج مرتين وفشل في إحداهما. أولاً بمقارنة الفروع على الريموت،
# فلم تكن الفروع الأخرى مجلوبة. ثم بجذر التاريخ، فاختلف الجذر بين نسخة محلية
# ونسخة CI (التي تجلب التاريخ كاملاً) — فنجح الحارس محلياً وفشل في CI.
# والاستدلال الذي يعتمد على شكل النسخة المستنسخة ليس استدلالاً.
#
# فالقائمة المعلنة: الهجرات 001–008 تاريخ مشترك مشترك، ولا نملك ترقيمها.
# وكل ما عداها يجب أن يقع في نطاق main (100 فما فوق). والنتيجة واحدة في أي نسخة وفي أي فرع.
INHERITED_NUMBERS='001 002 003 004 005 006 007 008'

is_inherited() {
  case " $INHERITED_NUMBERS " in *" $1 "*) return 0 ;; *) return 1 ;; esac
}

while IFS= read -r file; do
  [ -n "$file" ] || continue
  base="$(basename "$file")"
  num="${base%%_*}"
  case "$num" in
    ''|*[!0-9]*) BAD "رقم هجرة غير صالح في: $base"; VIOLATIONS=$((VIOLATIONS + 1)); continue ;;
  esac
  n=$((10#$num))

  if is_inherited "$num"; then
    continue
  fi

  if [ "$n" -ge "$RANGE_MIN" ] && [ "$n" -le "$RANGE_MAX" ]; then
    OK "$base — داخل نطاق main ($RANGE_MIN+)"
  else
    BAD "$base — خارج نطاق main. كل هجرة جديدة تأخذ الرقم التالي على main ($RANGE_MIN فما فوق)؛ أعد ترقيم أي هجرة منقولة من فرع مؤرشف"
    VIOLATIONS=$((VIOLATIONS + 1))
  fi
done < <(find "$MIGRATIONS_DIR" -maxdepth 1 -name '*.sql' | sort)

OK "تاريخ مشترك مُعلَن ومستثنى: $INHERITED_NUMBERS"

# ٣) لا تكرار في الترقيم داخل الفرع نفسه.
DUPLICATES="$(find "$MIGRATIONS_DIR" -maxdepth 1 -name '*.sql' -printf '%f\n' 2>/dev/null | sed 's/_.*//' | sort | uniq -d)"
if [ -n "$DUPLICATES" ]; then
  BAD "أرقام هجرة مكرّرة داخل الفرع: $DUPLICATES"
else
  OK "لا تكرار في أرقام الهجرات"
fi

# ٤) الـmanifest يجب أن يذكر كل ملف موجود، ولا يذكر ملفاً مفقوداً.
#    هذا هو المكان الذي يسقط فيه التعارض الصامت عادةً.
if [ -f "$MANIFEST" ]; then
  MANIFEST_MISSING=0
  while IFS= read -r file; do
    base="$(basename "$file")"
    if ! grep -q "'$base'" "$MANIFEST"; then
      BAD "هجرة موجودة وغير مسجَّلة في $MANIFEST: $base"
      MANIFEST_MISSING=$((MANIFEST_MISSING + 1))
    fi
  done < <(find "$MIGRATIONS_DIR" -maxdepth 1 -name '*.sql' | sort)

  while IFS= read -r name; do
    [ -n "$name" ] || continue
    if [ ! -f "$MIGRATIONS_DIR/$name" ]; then
      BAD "الـmanifest يذكر هجرة غير موجودة: $name"
    fi
  done < <(grep -oE "name: '[^']+\.sql'" "$MANIFEST" | sed "s/name: '//; s/'//")

  [ "$MANIFEST_MISSING" -eq 0 ] && OK "الـmanifest مطابق لمجلد الهجرات"
fi

LAST_MIGRATION="$(find "$MIGRATIONS_DIR" -maxdepth 1 -name '*.sql' -printf '%f\n' 2>/dev/null | sed 's/_.*//' | sort | tail -1)"
NEXT_MIGRATION=$(( 10#${LAST_MIGRATION:-099} + 1 ))
[ "$NEXT_MIGRATION" -lt "$RANGE_MIN" ] && NEXT_MIGRATION=$RANGE_MIN

printf "\n${BOLD}────────────────────────────────────────────────${OFF}\n"
if [ "$PROBLEMS" -eq 0 ]; then
  printf "${BOLD}${GREEN}النتيجة: الترقيم آمن ومتسلسل على main.${OFF}\n"
  printf "الهجرة التالية على main: %03d\n" "$NEXT_MIGRATION"
else
  printf "${BOLD}${RED}النتيجة: %d خلل في الترقيم.${OFF}\n" "$PROBLEMS"
fi
printf "${BOLD}────────────────────────────────────────────────${OFF}\n\n"

exit $([ "$PROBLEMS" -eq 0 ] && echo 0 || echo 1)
