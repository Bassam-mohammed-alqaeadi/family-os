#!/usr/bin/env bash
#
# Family OS — فحص صحة المستودع.
#
#   tools/git/repo-health.sh
#
# يجيب على سؤال واحد فقط: «لو انتهت مساحة العمل هذه الآن، هل سأفقد أي شيء؟»
# إن كان الجواب «لا»، فأنت آمن. وإن كان «نعم»، فالبرنامج يسمّي ما هو غير مدفوع.
#
# مبدأ التشغيل: مساحة العمل مؤقتة، والمستودع على GitHub هو المصدر الوحيد للحقيقة.
# لذلك كل شيء مهم يجب أن يكون: مُودَعاً (committed) ومدفوعاً (pushed).
#
# Exit code: 0 = آمن، 1 = يوجد ما يستحق التوقف عنده.

set -uo pipefail

CYAN=$'\033[36m'; GREEN=$'\033[32m'; RED=$'\033[31m'; YELLOW=$'\033[33m'; BOLD=$'\033[1m'; OFF=$'\033[0m'
PROBLEMS=0
NOTE()  { printf '  %s\n' "$*"; }
OK()    { printf "  ${GREEN}✔${OFF} %s\n" "$*"; }
WARN()  { printf "  ${YELLOW}▲${OFF} %s\n" "$*"; }
BAD()   { printf "  ${RED}✖${OFF} %s\n" "$*"; PROBLEMS=$((PROBLEMS + 1)); }
HEAD()  { printf "\n${BOLD}${CYAN}%s${OFF}\n" "$*"; }

cd "$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "not a git repository"; exit 1; }

# بوابة الملفات الثقيلة: كل ما هو مُشتق أو مُنزَّل لا يدخل المستودع أبداً.
FORBIDDEN_RE='(^|/)(node_modules|\.dart_tool|\.venv|venv|__pycache__|\.next|\.nuxt|dist|build|out|target|coverage|\.pytest_cache|\.ruff_cache|\.turbo)(/|$)'
FORBIDDEN_EXT_RE='\.(zip|tar|tgz|tar\.gz|jar|apk|aab|ipa|so|dll|dylib|o|a|class|pyc)$'
SIZE_LIMIT_KB=2048   # 2 MiB — أي ملف متتبَّع أكبر من هذا يحتاج تبريراً صريحاً.

HEAD "١) الهوية والتزامن"
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
UPSTREAM="origin/$BRANCH"
NOTE "الفرع الحالي: $BRANCH"
if [ "$BRANCH" = "HEAD" ]; then
  BAD "أنت في detached HEAD — أي عمل جديد سيضيع. شغّل: git switch <branch>"
else
  OK "على فرع، ليس detached"
fi

if ! git rev-parse --verify --quiet "$UPSTREAM" >/dev/null; then
  WARN "لا يوجد فرع مقابل على origin باسم $BRANCH — سيُنشأ عند أول دفعة."
else
  read -r BEHIND AHEAD < <(git rev-list --left-right --count "$UPSTREAM...HEAD" 2>/dev/null || echo "0 0")
  if [ "${AHEAD:-0}" -gt 0 ]; then
    BAD "$AHEAD إيداع/إيداعات محلية لم تُدفع — هذا بالضبط ما يضيع عند إعادة بناء مساحة العمل."
    git --no-pager log --oneline "$UPSTREAM..HEAD" | sed 's/^/      /'
    NOTE "الحل: git push origin $BRANCH"
  else
    OK "لا إيداعات غير مدفوعة"
  fi
  if [ "${BEHIND:-0}" -gt 0 ]; then
    WARN "$BEHIND إيداع على الريموت ليس عندك محلياً. شغّل: git fetch origin && git reset --soft $UPSTREAM"
  fi
fi

HEAD "٢) الملفات غير المُودَعة (الخطر الأكبر)"
CHANGES="$(git status --porcelain)"
if [ -z "$CHANGES" ]; then
  OK "شجرة العمل نظيفة تماماً — صفر تغييرات غير محفوظة"
else
  MODIFIED="$(printf '%s\n' "$CHANGES" | grep -c '^ M\|^M')"
  DELETED="$(printf '%s\n' "$CHANGES" | grep -c '^ D\|^D')"
  UNTRACKED="$(printf '%s\n' "$CHANGES" | grep -c '^??')"
  [ "$MODIFIED" -gt 0 ] && WARN "$MODIFIED ملف معدّل وغير مُودَع" || true
  [ "$DELETED" -gt 0 ] && WARN "$DELETED ملف محذوف" || true
  if [ "$UNTRACKED" -gt 0 ]; then
    WARN "$UNTRACKED ملف غير متتبَّع:"
    printf '%s\n' "$CHANGES" | grep '^??' | sed 's/^?? /      /'
  fi

  # لكل ملف موجود على القرص، هل محتواه موجود في تاريخ المستودع؟
  # إن كان نعم، فالمحتوى محفوظ حتى لو لم يُودَع. وإن كان لا، فهو عمل وحيد غير محفوظ.
  UNIQUE=0
  while IFS= read -r entry; do
    path="${entry:3}"
    [ -f "$path" ] || continue
    blob="$(git hash-object "$path" 2>/dev/null)" || continue
    hit=""
    while IFS= read -r commit; do
      [ "$(git rev-parse "$commit:$path" 2>/dev/null)" = "$blob" ] && { hit=1; break; }
    done < <(git log --all --format=%H -- "$path" 2>/dev/null)
    if [ -z "$hit" ]; then
      UNIQUE=$((UNIQUE + 1))
      BAD "عمل وحيد غير محفوظ في التاريخ: $path"
    fi
  done <<< "$CHANGES"

  if [ "$UNIQUE" -eq 0 ]; then
    OK "كل ملف غير مُودَع محتواه موجود أصلاً في تاريخ المستودع — لا شيء سيضيع"
  fi
  NOTE "الحل الدائم: git add -A && git commit -m '...' && git push origin $BRANCH"
fi

HEAD "٣) لا شيء ثقيل داخل المستودع"
HEAVY="$(git ls-files | grep -E "$FORBIDDEN_RE" | head -20 || true)"
if [ -z "$HEAVY" ]; then
  OK "لا مجلدات مُشتقّة أو مُنزَّلة متتبَّعة (node_modules، build، dist، caches)"
else
  BAD "مجلدات مُشتقّة متتبَّعة — يجب أن تكون في .gitignore:"
  printf '%s\n' "$HEAVY" | head -10 | sed 's/^/      /'
fi

BIG="$(git ls-files -z | xargs -0 -I{} du -k "{}" 2>/dev/null | awk -v L="$SIZE_LIMIT_KB" '$1 > L {print $1" "$2}' | sort -rn | head -10 || true)"
if [ -z "$BIG" ]; then
  OK "لا ملف متتبَّع أكبر من $((SIZE_LIMIT_KB / 1024)) MiB"
else
  WARN "ملفات كبيرة متتبَّعة — تحتاج تبريراً أو نقلاً إلى مساحة خارجية (Release assets):"
  printf '%s\n' "$BIG" | awk '{printf "      %8.1f MiB  %s\n", $1/1024, $2}'
  NOTE "القاعدة: المستودع للمصدر فقط. الأصول الكبيرة تُرفع كـ Release asset لا كملف في التاريخ."
fi

BINARY="$(git ls-files | grep -E "$FORBIDDEN_EXT_RE" | head -10 || true)"
if [ -z "$BINARY" ]; then
  OK "لا ملفات تنفيذية أو مضغوطة متتبَّعة (zip، apk، so، dll، pyc)"
else
  WARN "ملفات تنفيذية/مضغوطة متتبَّعة:"
  printf '%s\n' "$BINARY" | sed 's/^/      /'
fi

SIZE="$(du -sh .git 2>/dev/null | cut -f1)"
NOTE "حجم تاريخ المستودع (.git): ${SIZE:-unknown}  — الميزانية: ابقَ تحت ~100 MiB"

HEAD "٤) لا أسرار ولا مفاتيح"
# الفحص على المحتوى لا على الاسم: ملف اسمه بلا ضرر لا يُلوَّم، وملف باسم بريء
# يحمل مفتاحاً لا يُعفى. هذا نفس منطق scripts/verify-no-service-account-keys.mjs.
SECRET_HITS=0
for path in $(git ls-files); do
  case "$path" in
    *.env.example|scripts/verify-no-service-account-keys.mjs|.gitignore|tools/git/*) continue ;;
  esac
  # الأسماء الممنوعة صراحةً (تُطابق قواعد .gitignore نفسها).
  if printf '%s' "$path" | grep -Eqi '(^|/)(firebase-adminsdk|credentials\.json|foundation_gate_local_configuration\.dart|GoogleService-Info\.plist|google-services\.json)|service[-_]?account.*\.json$'; then
    BAD "اسم ملف ممنوع على المستودع: $path"
    SECRET_HITS=$((SECRET_HITS + 1))
    continue
  fi
  [ -f "$path" ] || continue
  size=$(wc -c < "$path" 2>/dev/null || echo 0)
  [ "$size" -gt 5242880 ] && continue            # تجاهل الأصول الكبيرة
  if grep -EIq -- '-----BEGIN (RSA |EC )?PRIVATE KEY-----|"type"[[:space:]]*:[[:space:]]*"service_account"|"private_key"[[:space:]]*:' "$path" 2>/dev/null; then
    BAD "محتوى $path يحتوي بصمة مفتاح خاص — أوقف الدفع وافحص فوراً"
    SECRET_HITS=$((SECRET_HITS + 1))
  fi
done
if [ "$SECRET_HITS" -eq 0 ]; then
  OK "لا مفاتيح ولا أسرار في أي ملف متتبَّع (فحص المحتوى لا الاسم)"
fi
if [ -f scripts/verify-no-service-account-keys.mjs ] && command -v node >/dev/null 2>&1; then
  if node scripts/verify-no-service-account-keys.mjs >/dev/null 2>&1; then
    OK "الحارس الرسمي للمستودع يوافق: صفر مفاتيح"
  else
    BAD "الحارس الرسمي scripts/verify-no-service-account-keys.mjs رفض المستودع"
  fi
fi

HEAD "٥) .gitignore يحمي المُشتقّات"
for pattern in 'node_modules' 'build/' '.dart_tool' '.env' 'coverage/' 'dist/' '*.zip'; do
  if grep -qF "$pattern" .gitignore 2>/dev/null; then
    OK ".gitignore يغطّي $pattern"
  else
    WARN ".gitignore لا يغطّي $pattern"
  fi
done

printf "\n${BOLD}${CYAN}────────────────────────────────────────────────${OFF}\n"
if [ "$PROBLEMS" -eq 0 ]; then
  printf "${BOLD}${GREEN}النتيجة: مساحة العمل آمنة للتخلّي عنها.${OFF}\n"
  printf "كل شيء مهم محفوظ على GitHub. الاستعادة = clone + install.\n"
else
  printf "${BOLD}${RED}النتيجة: $PROBLEMS مشكلة يجب حلّها قبل إغلاق الجلسة.${OFF}\n"
fi
printf "${BOLD}${CYAN}────────────────────────────────────────────────${OFF}\n\n"

exit $([ "$PROBLEMS" -eq 0 ] && echo 0 || echo 1)
