#!/usr/bin/env bash
#
# Family OS — فحص الحلقة.
#
#   tools/harness/harness_check.sh
#
# يجيب على سؤالين في أمر واحد:
#   ١) هل حالة الحلقة (LOOP_STATE) متّسقة ولا تكذب؟
#   ٢) هل مساحة العمل آمنة (عبر tools/git/repo-health.sh)؟
#
# الحالة على GitHub هي ذاكرة الحلقة. وملف حالة متأخر أخطر من ملف غائب،
# لأنه يُضلّل الجلسة التالية فتكرّر عملاً منجزاً أو تخالف قراراً مقفولاً.
#
# Exit: 0 = الحلقة سليمة ومتّسقة، 1 = خلل يجب إصلاحه قبل الدفع.

set -uo pipefail

CYAN=$'\033[36m'; GREEN=$'\033[32m'; RED=$'\033[31m'; YELLOW=$'\033[33m'; BOLD=$'\033[1m'; OFF=$'\033[0m'
PROBLEMS=0
OK()   { printf "  ${GREEN}✔${OFF} %s\n" "$*"; }
WARN() { printf "  ${YELLOW}▲${OFF} %s\n" "$*"; }
BAD()  { printf "  ${RED}✖${OFF} %s\n" "$*"; PROBLEMS=$((PROBLEMS + 1)); }
NOTE() { printf "    %s\n" "$*"; }
HEAD() { printf "\n${BOLD}${CYAN}%s${OFF}\n" "$*"; }

cd "$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "not a git repository"; exit 1; }

STATE_FILE="docs/harness/LOOP_STATE.md"
HEALTH="tools/git/repo-health.sh"

# المراحل المسموحة ونقطة الإيقاف. أي قيمة خارجها = الحلقة خرجت عن تعريفها.
VALID_STATUSES='IDLE SELECTED COMPARE COVER COMPETE REAL_ENGINE LOCKED BLOCKED_ON_OWNER'

HEAD "١) حالة الحلقة"

if [ ! -f "$STATE_FILE" ]; then
  BAD "لا يوجد ملف حالة: $STATE_FILE — الحلقة بلا ذاكرة."
  printf "\n${BOLD}${RED}النتيجة: الحلقة معطّلة.${OFF}\n\n"
  exit 1
fi

# استخرج كتلة الحالة بين العلامتين.
BLOCK="$(awk '/<!-- HARNESS-STATE:BEGIN -->/{f=1;next} /<!-- HARNESS-STATE:END -->/{f=0} f' "$STATE_FILE")"
if [ -z "$BLOCK" ]; then
  BAD "كتلة الحالة مفقودة (علامتا HARNESS-STATE) — لا يمكن قراءة الحالة."
  printf "\n${BOLD}${RED}النتيجة: الحلقة معطّلة.${OFF}\n\n"
  exit 1
fi

field() { printf '%s\n' "$BLOCK" | sed -n "s/^[[:space:]]*$1:[[:space:]]*//p" | head -1 | sed 's/^["'"'"']//; s/["'"'"']$//'; }

STATUS="$(field status)"
SYSTEM="$(field active_system)"
STAGE="$(field stage)"
CARD="$(field card)"
QUESTION="$(field owner_question)"
BLOCKED="$(field blocked_by)"
TICK="$(field last_tick)"
EVIDENCE="$(field evidence)"

# ١) الحالة معروفة؟
if [ -z "$STATUS" ]; then
  BAD "حقل status فارغ."
elif ! printf '%s' " $VALID_STATUSES " | grep -q " $STATUS "; then
  BAD "status غير معروف: '$STATUS'"
  NOTE "المسموح: $VALID_STATUSES"
else
  OK "الحالة: $STATUS"
fi

# ٢) الحالة لا تكذب: متوقّف يعني سؤال، وغيره يعني لا سؤال معلّق.
if [ "$STATUS" = "BLOCKED_ON_OWNER" ]; then
  if [ -z "$QUESTION" ] || [ "$QUESTION" = "—" ] || [ "$QUESTION" = "-" ]; then
    BAD "الحالة متوقّفة بلا سؤال — الحلقة تشتكي بلا سبب، وهذا يُجمّد العمل."
    NOTE "اكتب owner_question بسؤال واحد محدّد وقابل للجواب."
  else
    OK "متوقّفة بسؤال معلن للمالك"
    NOTE "$QUESTION"
  fi
else
  if [ -n "$QUESTION" ] && [ "$QUESTION" != "—" ] && [ "$QUESTION" != "-" ]; then
    BAD "سؤال معلّق والحالة ليست BLOCKED_ON_OWNER — إمّا يُجاب أو تُوقف الحلقة."
  fi
fi

# ٣) المرحلة النشطة تحتاج بطاقة موجودة فعلاً.
case "$STATUS" in
  IDLE|LOCKED|BLOCKED_ON_OWNER) ;;
  *)
    if [ -z "$CARD" ] || [ "$CARD" = "—" ]; then
      BAD "الحالة '$STATUS' بلا بطاقة — لا عمل بلا بطاقة."
    elif [ ! -f "$CARD" ]; then
      BAD "البطاقة المعلنة غير موجودة: $CARD"
    else
      OK "البطاقة: $CARD"
    fi
    ;;
esac

# ٤) اكتمال حقول المتابعة.
for pair in "active_system:$SYSTEM" "last_tick:$TICK"; do
  name="${pair%%:*}"; value="${pair#*:}"
  if [ -z "$value" ] || [ "$value" = "—" ] || [ "$value" = "-" ]; then
    BAD "حقل $name فارغ."
  fi
done
[ -n "$EVIDENCE" ] && [ "$EVIDENCE" != "—" ] && OK "الدليل مُعلن: ${EVIDENCE:0:90}" || WARN "لا دليل مُعلن (evidence) — الإقفال بلا رقم لا يُقبل."

# ٥) الحالة يجب أن تكون داخل موجة مصرَّح بها.
case "$SYSTEM" in
  *M1*) NOTE "الموجة النشطة M1 — مصرَّح بها بقفل M0. تأكّد أنها الوحيدة المفتوحة." ;;
esac
if [ "$STATUS" != "IDLE" ] && [ "$STATUS" != "BLOCKED_ON_OWNER" ] && [ -n "$BLOCKED" ] && [ "$BLOCKED" != "—" ] && [ "$BLOCKED" != "-" ]; then
  WARN "حقل blocked_by غير فارغ والحالة تتقدّم: $BLOCKED"
fi

# ٦) مراجع البطاقة/الحالة موجودة لمن يشير إليها.
if [ -f "$STATE_FILE" ]; then
  REFS="$(grep -oE 'docs/harness/[A-Za-z0-9._/-]+\.(md|sh)' "$STATE_FILE" | sort -u)"
  for r in $REFS; do
    [ -f "$r" ] || BAD "مرجع مكسور في ملف الحالة: $r"
  done
fi

HEAD "٢) صحة المستودع"
if [ -x "$HEALTH" ] || [ -f "$HEALTH" ]; then
  if bash "$HEALTH" >/tmp/.harness-health.out 2>&1; then
    OK "مساحة العمل آمنة (exit 0)"
  else
    BAD "فحص المستودع رفض — التفصيل:"
    grep -E '✖|▲' /tmp/.harness-health.out | head -8 | sed 's/^/    /'
  fi
else
  WARN "لا توجد أداة الفحص $HEALTH — لا يمكن تأكيد سلامة مساحة العمل."
fi

printf "\n${BOLD}${CYAN}────────────────────────────────────────────────${OFF}\n"
if [ "$PROBLEMS" -eq 0 ]; then
  printf "${BOLD}${GREEN}النتيجة: الحلقة سليمة ومتّسقة.${OFF}\n"
  printf "الحالة: %s · النظام: %s · البطاقة: %s\n" "$STATUS" "$SYSTEM" "$CARD"
else
  printf "${BOLD}${RED}النتيجة: %d خلل في الحلقة.${OFF}\n" "$PROBLEMS"
fi
printf "${BOLD}${CYAN}────────────────────────────────────────────────${OFF}\n\n"

exit $([ "$PROBLEMS" -eq 0 ] && echo 0 || echo 1)
