#!/usr/bin/env bash
#
# Family OS — حارس نطاق ترقيم الهجرات.
#
#   tools/harness/check_migration_range.sh
#
# يمنع أخطر تعارض صامت في العمل المتوازي: فرعان يختاران نفس رقم الهجرة.
#
# لماذا هذا خطر حقيقي: الأسماء تختلف فيمرّ الدمج في Git بلا تعارض ظاهر،
# بينما `schema-manifest.js` يحمل الرقم مرتين بترتيب غير معرّف — فينشأ عطل
# في قاعدة البيانات لا يظهر في المراجعة إطلاقاً.
#
# الحل: نطاق محجوز لكل فرع. فيصبح التصادم **مستحيلاً بنيوياً**،
# ولا يحتاج أحد إلى إعادة ترقيم عند الدمج.
#
#   main                     → 001–099  (التاريخ المشترك)
#   arena/01a10887-family-os → 010–099  (الفرع المتوازي، النطاق الطبيعي)
#   arena/6233f1a1-family-os → 100–199  ← هذه الجلسة
#
# Exit: 0 = الترقيم داخل النطاق، 1 = خارج النطاق.

set -uo pipefail

GREEN=$'\033[32m'; RED=$'\033[31m'; YELLOW=$'\033[33m'; BOLD=$'\033[1m'; OFF=$'\033[0m'
PROBLEMS=0
OK()   { printf "  ${GREEN}✔${OFF} %s\n" "$*"; }
BAD()  { printf "  ${RED}✖${OFF} %s\n" "$*"; PROBLEMS=$((PROBLEMS + 1)); }
WARN() { printf "  ${YELLOW}▲${OFF} %s\n" "$*"; }

cd "$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "not a git repository"; exit 1; }

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
MIGRATIONS_DIR="backend/db/migrations"
MANIFEST="backend/src/schema-manifest.js"

# النطاق المحجوز لهذا الفرع.
RANGE_MIN=100
RANGE_MAX=199
OWNED_BRANCHES='arena/6233f1a1-family-os'

printf "\n${BOLD}نطاق ترقيم الهجرات${OFF}\n"
printf "  الفرع: %s\n" "$BRANCH"

[ -d "$MIGRATIONS_DIR" ] || { BAD "لا يوجد مجلد هجرات: $MIGRATIONS_DIR"; exit 1; }

# ١) هل الهجرات الموجودة داخل النطاق المحجوز أو أقدم من الحجز؟
#    الهجرات الموروثة (001–009 وما يأتي من main) مسموحة — لها تاريخ مشترك.
#    الممنوع هو **إضافة** رقم جديد داخل نطاق فرع آخر.
VIOLATIONS=0

# الأساس = الجذر الفعلي لتاريخ هذا الفرع. ما هو موجود فيه «موروث» ولا نحاسبه على الترقيم؛
# وما أضفناه بعده هو **لنا** ويجب أن يقع في نطاقنا المحجوز.
#
# لا نستخدم merge-base مع main: تاريخا المستودع متباعدان بلا سلف مشترك، فيرجع فارغاً.
# والجذر يعمل في أي نسخة مستنسخة وبلا شبكة.
BASE="$(git rev-list --max-parents=0 HEAD 2>/dev/null | head -1)"

while IFS= read -r file; do
  [ -n "$file" ] || continue
  base="$(basename "$file")"
  num="${base%%_*}"
  case "$num" in
    ''|*[!0-9]*) BAD "رقم هجرة غير صالح في: $base"; VIOLATIONS=$((VIOLATIONS + 1)); continue ;;
  esac
  n=$((10#$num))

  # موروثة إن كانت موجودة في جذر الفرع ⇒ لها تاريخ مشترك، وليست مسؤوليتنا.
  if [ -n "$BASE" ] && git cat-file -e "$BASE:$file" 2>/dev/null; then
    continue
  fi

  if [ "$n" -ge "$RANGE_MIN" ] && [ "$n" -le "$RANGE_MAX" ]; then
    OK "$base — داخل النطاق المحجوز ($RANGE_MIN–$RANGE_MAX)"
  else
    BAD "$base — خارج النطاق المحجوز. فرعنا يحجز $RANGE_MIN–$RANGE_MAX لمنع تصادم صامت مع الفروع المتوازية"
    VIOLATIONS=$((VIOLATIONS + 1))
  fi
done < <(find "$MIGRATIONS_DIR" -maxdepth 1 -name '*.sql' | sort)

INHERITED_COUNT=0
while IFS= read -r file; do
  [ -n "$file" ] || continue
  [ -n "$BASE" ] && git cat-file -e "$BASE:$file" 2>/dev/null && INHERITED_COUNT=$((INHERITED_COUNT + 1))
done < <(find "$MIGRATIONS_DIR" -maxdepth 1 -name '*.sql' | sort)
if [ "$INHERITED_COUNT" -gt 0 ]; then
  OK "الهجرات الموروثة من الأساس مستثناة: $INHERITED_COUNT"
fi

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

printf "\n${BOLD}────────────────────────────────────────────────${OFF}\n"
if [ "$PROBLEMS" -eq 0 ]; then
  printf "${BOLD}${GREEN}النتيجة: الترقيم آمن — لا تصادم ممكن مع أي فرع متوازٍ.${OFF}\n"
  printf "نطاقنا المحجوز: %s–%s · والفرع المتوازي في نطاقه الطبيعي 010–099\n" "$RANGE_MIN" "$RANGE_MAX"
else
  printf "${BOLD}${RED}النتيجة: %d خلل في الترقيم.${OFF}\n" "$PROBLEMS"
fi
printf "${BOLD}────────────────────────────────────────────────${OFF}\n\n"

exit $([ "$PROBLEMS" -eq 0 ] && echo 0 || echo 1)
