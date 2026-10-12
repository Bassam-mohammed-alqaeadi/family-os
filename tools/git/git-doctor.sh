#!/usr/bin/env bash
#
# Family OS — طبيب Git: يمنع تكرار فشل الدفع إلى GitHub.
#
#   tools/git/git-doctor.sh check     [repo]   فحص: شبكة + مصادقة + إعدادات + تزامن + خطافات
#   tools/git/git-doctor.sh repair    [repo]   إصلاح تلقائي غير مُدمِّر + تثبيت الخطافات (آمن للتكرار)
#   tools/git/git-doctor.sh push      [repo]   دفعة آمنة ثم تحقّق فعلي أن SHA وصل إلى GitHub
#   tools/git/git-doctor.sh self-test [repo]   اختبار ذاتي بلا شبكة (يعمل في CI)
#   tools/git/git-doctor.sh report    [repo]   تقرير تصعيد إلى دعم Arena.ai
#
# لماذا هذا الملف داخل المستودع؟
#   لأن مساحة العمل مؤقتة، وأي إصلاح خارج Git يُمسح. هذا الملف + .githooks + سطر في
#   أمر التأسيس يجعلان الإصلاح قابلاً للاستعادة بأمر واحد في أي جلسة جديدة، في أي مسار،
#   وبأي HOME فارغ — بلا اعتماد على /tmp أو على إعدادات سبق أن ضُبطت.
#
#   أوامر البدء في كل جلسة:
#       tools/git/git-doctor.sh repair      # مرة واحدة في بداية الجلسة
#       tools/git/git-doctor.sh push        # عند كل دفعة (يتحقّق أن الريموت استلم فعلاً)
#
# مبادئ السلامة (غير قابلة للتفاوض):
#   • لا force-push، ولا حذف فرع أو وسم، ولا إعادة كتابة تاريخ.
#   • لا تعديل لأي ملف متتبَّع (كل الإصلاحات في .git/config أو ~/.gitconfig أو .git/hooks).
#   • لا أسرار في المخرجات، ولا قراءة رمز من البيئة.
#
# Exit: 0 = سليم/نجح، 1 = خلل حقيقي، 2 = خطأ استخدام.
set -uo pipefail

CYAN=$'\033[36m'; GREEN=$'\033[32m'; RED=$'\033[31m'; YELLOW=$'\033[33m'; BOLD=$'\033[1m'; OFF=$'\033[0m'
PASS=0; FAIL=0
ok()      { printf "  ${GREEN}✔${OFF} %s\n" "$*"; PASS=$((PASS+1)); }
bad()     { printf "  ${RED}✖${OFF} %s\n" "$*"; FAIL=$((FAIL+1)); }
warn()    { printf "  ${YELLOW}▲${OFF} %s\n" "$*"; }
section() { printf "\n${BOLD}${CYAN}%s${OFF}\n" "$*"; }
note()    { printf "    %s\n" "$*"; }

MODE="${1:-check}"
# المسار الافتراضي: المستودع الذي يحتوي هذا الملف — فيعمل في أي استنساخ وأي مسار.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO="$(cd "$SCRIPT_DIR/../.." 2>/dev/null && pwd || echo "$PWD")"
REPO="${2:-$DEFAULT_REPO}"
# هوية الإيداع الافتراضية لهذا المستودع (يمكن تجاوزها بمتغيّر بيئة).
# تُضبط محلياً فقط — لا نلمس إعداداً عاماً للهوية.
IDENTITY_NAME="${GIT_IDENTITY_NAME:-Bassam-mohammed-alqaeadi}"
IDENTITY_EMAIL="${GIT_IDENTITY_EMAIL:-312219484+Bassam-mohammed-alqaeadi@users.noreply.github.com}"

case "$MODE" in
  check|repair|push|self-test|report) ;;
  /*|./*|../*) REPO="$MODE"; MODE="check" ;;
  *) echo "usage: $0 [check|repair|push|self-test|report] [repo_path]"; exit 2 ;;
esac

# ---------------------------------------------------------------------------
# سياق
# ---------------------------------------------------------------------------
ctx() {
  cd "$REPO" 2>/dev/null || { echo "المسار ليس مستودعاً: $REPO" >&2; exit 2; }
  git rev-parse --git-dir >/dev/null 2>&1 || { echo "لا يوجد مستودع Git في $REPO" >&2; exit 2; }
  # العنوان المتوقّع: من الإعداد إن وُجد، وإلا قيمة ثابتة تُنقذ مستودعاً فقد إعداده.
  ORIGIN_URL="$(git config --get remote.origin.url || true)"
  [ -n "$ORIGIN_URL" ] || ORIGIN_URL="${GIT_EXPECTED_ORIGIN:-https://github.com/Bassam-mohammed-alqaeadi/family-os.git}"
  case "$ORIGIN_URL" in
    git@github.com:*) SLUG="${ORIGIN_URL#git@github.com:}" ;;
    https://github.com/*) SLUG="${ORIGIN_URL#https://github.com/}" ;;
    ssh://git@github.com/*) SLUG="${ORIGIN_URL#ssh://git@github.com/}" ;;
    *) SLUG="" ;;
  esac
  SLUG="${SLUG%.git}"
  BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo HEAD)"
  IN_GIT=1; [ "$BRANCH" = "HEAD" ] && IN_GIT=0
  GITHUB_DIR="$(git rev-parse --git-path hooks)"
  EXPECTED_ORIGIN="${GIT_EXPECTED_ORIGIN:-https://github.com/${SLUG:-Bassam-mohammed-alqaeadi/family-os}.git}"
}

# ---------------------------------------------------------------------------
# ١) الشبكة — هل HTTPS إلى GitHub مسموح فعلاً؟
# ---------------------------------------------------------------------------
net_check() {
  section "١) الشبكة — HTTPS إلى GitHub"
  local ip; ip="$(getent hosts github.com 2>/dev/null | awk '{print $1}' | command head -1)"
  [ -n "$ip" ] && ok "DNS يحلّ github.com ($ip)" || bad "DNS لا يحلّ github.com — لا خروج"

  local code
  code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 20 https://github.com/ 2>/dev/null || echo 000)"
  case "$code" in
    200|301|302) ok "HTTPS github.com:443 → HTTP $code" ;;
    000)         bad "github.com:443 غير قابل للوصول (محجوب؟)" ;;
    *)           warn "github.com:443 → HTTP $code" ;;
  esac
  for h in api.github.com codeload.github.com; do
    code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 15 "https://$h/" 2>/dev/null || echo 000)"
    [ "$code" != "000" ] && ok "$h متاح (HTTP $code)" || warn "$h غير متاح (HTTP $code)"
  done
  local issuer
  issuer="$(echo | timeout 15 openssl s_client -connect github.com:443 -servername github.com 2>/dev/null | openssl x509 -noout -issuer 2>/dev/null | command head -1)"
  case "$issuer" in
    *"E2B Proxy CA"*) ok "وسيط Egress في المنصة يحقن المصادقة (E2B Proxy CA)" ;;
    "")               warn "تعذّرت قراءة شهادة TLS" ;;
    *)                warn "شهادة TLS: ${issuer#issuer=}" ;;
  esac
}

# ---------------------------------------------------------------------------
# ٢) المصادقة — بلا طبع أي سرّ
# ---------------------------------------------------------------------------
auth_check() {
  section "٢) المصادقة على GitHub"
  local login limit
  login="$(curl -sS --max-time 20 https://api.github.com/user 2>/dev/null | grep -o '"login": *"[^"]*"' | command head -1 | cut -d'"' -f4)"
  limit="$(curl -sS --max-time 20 https://api.github.com/rate_limit 2>/dev/null | tr -d ' \n' | grep -o '"core":{"limit":[0-9]*' | grep -o '[0-9]*$')"
  if [ -n "$login" ]; then ok "API يعرف الهوية: $login"
  else bad "API لا يعرف الهوية — المصادقة غير محقونة (سيفشل الدفع بـ 401)"; fi
  if [ "${limit:-0}" -ge 1000 ] 2>/dev/null; then ok "سقف الطلبات $limit/ساعة → الطلبات مُصادَقة كمستخدم"
  else warn "سقف الطلبات ${limit:-غير معروف} → غير مُصادَقة (توقّع رفض الدفع)"; fi
  if git config --get-all credential.helper >/dev/null 2>&1; then
    warn "يوجد credential.helper — إن استخدم توكن البيئة الوهمي (arena-egress-dummy-token) فالدفع سيتحوّل إلى 401"
  else
    ok "لا credential.helper (صحيح: المصادقة من وسيط المنصة)"
  fi
  command -v gh >/dev/null 2>&1 && ok "بديل متاح إن تعذّر الاتصال المباشر: gh" || warn "gh غير متاح (بديل احتياطي مفقود)"
}

# ---------------------------------------------------------------------------
# ٣) الإعدادات — الأنماط الثلاثة التي تُفشل الدفع المتكرر
# ---------------------------------------------------------------------------
config_check() {
  section "٣) إعدادات الدفع (الأنماط الثلاثة للفشل المتكرر)"
  if [ -z "$(git config --get remote.origin.url || true)" ]; then
    bad "remote origin مفقود → 'fatal: No configured push destination' — الإصلاح: $0 repair"
  elif [ "$(git config --get remote.origin.url)" = "$EXPECTED_ORIGIN" ]; then
    ok "remote origin سليم"
  else
    warn "remote origin مختلف عن المتوقّع: $(git config --get remote.origin.url)"
  fi

  if [ "$IN_GIT" = "1" ] && [ "$BRANCH" != "main" ]; then
    local up merge
    up="$(git config --get "branch.$BRANCH.remote" || true)"
    merge="$(git config --get "branch.$BRANCH.merge" || true)"
    if [ -z "$up" ] || [ -z "$merge" ]; then
      # فرع لا يوجد له مقابل على الريموت بعد ليس خللاً: أول دفعة تنشئه و autoSetupRemote يربطه.
      if git rev-parse --verify --quiet "refs/remotes/origin/$BRANCH" >/dev/null 2>&1; then
        bad "الفرع $BRANCH موجود على origin لكن بلا upstream → 'fatal: The current branch has no upstream branch' — الإصلاح: $0 repair"
      else
        warn "لا upstream بعد للفرع $BRANCH (غير موجود على origin) — أول دفعة ستنشئه وتربطه تلقائياً"
      fi
    elif [ "$merge" != "refs/heads/$BRANCH" ]; then
      bad "upstream باسم مختلف ($merge) → 'fatal: The upstream branch … does not match' — الإصلاح: $0 repair"
    else
      ok "upstream مطابق لاسم الفرع: $up → $merge"
    fi
  fi

  if [ -z "$(git config --get user.name || true)" ] || [ -z "$(git config --get user.email || true)" ]; then
    bad "هوية الإيداع ناقصة → 'Author identity unknown' يمنع أي إيداع — الإصلاح: $0 repair"
  else
    ok "هوية الإيداع مضبوطة"
  fi
  [ "$(git config push.default || true)" = "current" ] \
    && ok "push.default=current" \
    || bad "push.default غير مضبوط → 'git push' قد تفشل بلا سبب — الإصلاح: $0 repair"
  [ "$(git config push.autoSetupRemote || true)" = "true" ] \
    && ok "push.autoSetupRemote=true" \
    || bad "push.autoSetupRemote غير مضبوط — الإصلاح: $0 repair"

  if [ "$(git rev-parse --is-shallow-repository 2>/dev/null)" = "true" ]; then
    bad "المستودع shallow ($(git rev-list --count HEAD 2>/dev/null) إيداع فقط) → تاريخ مقطوع يُضعف الاستعادة — الإصلاح: $0 repair"
  else
    ok "تاريخ كامل غير مقطوع ($(git rev-list --count HEAD 2>/dev/null) إيداع)"
  fi
}

# ---------------------------------------------------------------------------
# ٤) الخطافات — هل الحارس مثبّت ويعمل؟
# ---------------------------------------------------------------------------
hooks_check() {
  section "٤) خطافات الحماية (منع force-push والحذف)"
  local name src="$REPO/.githooks"
  if [ ! -d "$src" ]; then warn "لا يوجد مجلد .githooks في المستودع"; return; fi
  for f in "$src"/*; do
    [ -f "$f" ] || continue
    name="$(basename "$f")"
    if [ -f "$GITHUB_DIR/$name" ]; then
      if grep -q 'FAMILY-OS-MANAGED' "$GITHUB_DIR/$name" 2>/dev/null; then ok "الخطاف مثبّت وفعّال: $name"
      elif [ -f "$GITHUB_DIR/$name.local" ]; then ok "الخطاف مثبّت (وخطاف خارجي محفوظ بجانبه): $name"
      else warn "خطاف باسم $name موجود لكنه ليس مُداراً من هذا المستودع — لن نلمسه"; fi
    else
      bad "الخطاف غير مثبّت: $name → الإصلاح: $0 repair"
    fi
  done
  [ -x "$GITHUB_DIR/commit-msg" ] && ok "خطاف commit-msg الخارجي سليم (لم يُمسّ)" || note "لا خطاف commit-msg في هذه المساحة (طبيعي في استنساخ جديد)"
}

# ---------------------------------------------------------------------------
# ٥) التزامن — هل يوجد عمل غير مدفوع؟
# ---------------------------------------------------------------------------
sync_check() {
  section "٥) التزامن مع الريموت"
  if [ "$IN_GIT" != "1" ]; then bad "detached HEAD — أي إيداع جديد سيتوه"; return; fi
  git fetch -q origin 2>/dev/null || warn "تعذّر fetch (شبكة؟)"
  if ! git rev-parse --verify --quiet "refs/remotes/origin/$BRANCH" >/dev/null 2>&1; then
    warn "لا مرجع مقابل على origin بعد (سيُنشأ مع أول دفعة)"; return
  fi
  local counts ahead behind
  counts="$(git rev-list --left-right --count "origin/$BRANCH...HEAD" 2>/dev/null || echo '0 0')"
  behind="${counts%%[[:space:]]*}"; ahead="${counts##*[[:space:]]}"
  [ "${ahead:-0}" -eq 0 ] && ok "صفر إيداع محلي غير مدفوع" \
    || bad "$ahead إيداع غير مدفوع — ادفع الآن: tools/git/git-doctor.sh push"
  [ "${behind:-0}" -eq 0 ] && ok "لا تخلّف عن الريموت" \
    || warn "$behind إيداع على الريموت ليس عندك — git fetch && git merge origin/$BRANCH (لا rebase، لا force)"
  [ -z "$(git status --porcelain)" ] && ok "شجرة العمل نظيفة" \
    || warn "تغييرات غير مُودَعة: $(git status --porcelain | wc -l | tr -d ' ') ملف (لن أمسّها)"
}

# ---------------------------------------------------------------------------
# الإصلاح — آمن للتكرار، وغير مُدمِّر
# ---------------------------------------------------------------------------
install_hooks() {
  local src="$REPO/.githooks" dst="$GITHUB_DIR" name
  [ -d "$src" ] || return 0
  mkdir -p "$dst"
  for f in "$src"/*; do
    [ -f "$f" ] || continue
    name="$(basename "$f")"
    case "$name" in *.sample) continue;; esac
    chmod +x "$f" 2>/dev/null || true
    if [ -f "$dst/$name" ] && ! grep -q 'FAMILY-OS-MANAGED' "$dst/$name" 2>/dev/null; then
      mv "$dst/$name" "$dst/$name.local" && ok "خطاف خارجي ($name) حُفظ جانباً باسم $name.local ولن يُفقد"
    fi
    cp -f "$f" "$dst/$name" && chmod +x "$dst/$name" && ok "ثُبِّت الخطاف: $name"
  done
}

do_repair() {
  section "إصلاح كامل غير مُدمِّر (لا يمسّ أي ملف متتبَّع)"
  do_local_repair
  # ٥) التاريخ الكامل — يحتاج شبكة، ولهذا هو خارج الإصلاح المحلي
  if [ "$(git rev-parse --is-shallow-repository 2>/dev/null)" = "true" ]; then
    if GIT_TERMINAL_PROMPT=0 git fetch --unshallow origin >/dev/null 2>&1; then
      ok "اكتمل التاريخ: $(git rev-list --count HEAD) إيداع"
    else
      warn "تعذّر إكمال التاريخ الآن (شبكة؟) — أعد المحاولة عند توفر الشبكة"
    fi
  fi
  # ٦) upstream مطابق للاسم — بعد التأكد من وجود الفرع على الريموت
  if [ "$IN_GIT" = "1" ] && [ "$BRANCH" != "main" ]; then
    if git rev-parse --verify --quiet "refs/remotes/origin/$BRANCH" >/dev/null 2>&1; then
      git branch --set-upstream-to="origin/$BRANCH" "$BRANCH" >/dev/null 2>&1 \
        && ok "upstream = origin/$BRANCH (اسم مطابق، لا main)"
    else
      GIT_TERMINAL_PROMPT=0 git fetch -q origin "$BRANCH" 2>/dev/null || true
      if git rev-parse --verify --quiet "refs/remotes/origin/$BRANCH" >/dev/null 2>&1; then
        git branch --set-upstream-to="origin/$BRANCH" "$BRANCH" >/dev/null 2>&1 && ok "upstream = origin/$BRANCH (بعد الجلب)"
      else
        warn "الفرع ليس على origin بعد — أول دفعة ستنشئه (push.autoSetupRemote يتولّى الربط)"
      fi
    fi
  fi
}

# الإصلاح المحلي: فوري، بلا شبكة، غير مُدمِّر، وآمن للتكرار.
# يُستدعى تلقائياً في وضع `push` — لأن الأشياء الثلاثة التي تُفشل الدفع تُصلَح هنا قبل الدفع.
do_local_repair() {
  section "إصلاح محلي فوري (بلا شبكة)"
  # ١) الوجهة
  if [ -z "$(git config --get remote.origin.url || true)" ]; then
    git remote add origin "$EXPECTED_ORIGIN" && ok "أُعيد remote origin: $EXPECTED_ORIGIN"
  else
    ok "remote origin قائم"
  fi
  # ٢) refspec: أضِف الناقص فقط (بلا تكرار)
  local specs; specs="$(git config --get-all remote.origin.fetch || true)"
  if [ "$IN_GIT" = "1" ] && [ "$BRANCH" != "main" ]; then
    if printf '%s\n' "$specs" | grep -qF "refs/remotes/origin/$BRANCH"; then
      ok "refspec يغطّي الفرع $BRANCH"
    else
      git config --add remote.origin.fetch "+refs/heads/$BRANCH:refs/remotes/origin/$BRANCH" && ok "أُضيف refspec للفرع $BRANCH"
    fi
  fi
  printf '%s\n' "$specs" | grep -qF "refs/remotes/origin/main" || {
    git config --add remote.origin.fetch "+refs/heads/main:refs/remotes/origin/main" && ok "أُضيف refspec لـ main"; }
  # ٣) إعدادات الدفع — محلياً، وعالمياً إن أمكن كتابة HOME
  git config push.default current && ok "push.default=current (محلي)"
  git config push.autoSetupRemote true && ok "push.autoSetupRemote=true (محلي)"
  git config fetch.prune true
  git config gc.reflogExpire never
  git config gc.reflogExpireUnreachable never
  ok "reflog محفوظ للأبد (استعادة أي إيداع ضائع)"
  if [ -w "${HOME:-/nonexistent}" ] 2>/dev/null; then
    git config --global push.default current 2>/dev/null || true
    git config --global push.autoSetupRemote true 2>/dev/null || true
    git config --global gc.reflogExpire never 2>/dev/null || true
    git config --global gc.reflogExpireUnreachable never 2>/dev/null || true
    git config --global fetch.prune true 2>/dev/null || true
    git config --global --get-all url.https://github.com/.insteadOf 2>/dev/null | grep -q 'git@github.com:' || \
      git config --global --add url.https://github.com/.insteadOf git@github.com: 2>/dev/null || true
    ok "نُسخت الإعدادات عالمياً إلى ~/.gitconfig (تنفع حتى في استنساخ جديد)"
  else
    warn "HOME غير قابل للكتابة — الإعداد محلي فقط"
  fi
  # ٤) الخطافات
  install_hooks
  # ٥) هوية الإيداع: الاستنساخ لا ينقل user.name/user.email، فجلسة باردة تفشل بـ
  #    "Author identity unknown" قبل أن تصل إلى الدفع أصلاً.
  [ -n "$(git config --get user.name || true)" ]  || { git config user.name "$IDENTITY_NAME" && ok "ضُبطت هوية الإيداع (name)"; }
  [ -n "$(git config --get user.email || true)" ] || { git config user.email "$IDENTITY_EMAIL" && ok "ضُبطت هوية الإيداع (email)"; }
  [ -n "$(git config --get user.name || true)" ] && [ -n "$(git config --get user.email || true)" ] && ok "هوية الإيداع جاهزة"
  # ٦) upstream مطابق للاسم، محلياً بلا شبكة (إن كان الفرع معروفاً)
  if [ "$IN_GIT" = "1" ] && [ "$BRANCH" != "main" ]; then
    local _merge
    _merge="$(git config --get "branch.$BRANCH.merge" || true)"
    if [ "$_merge" = "refs/heads/$BRANCH" ]; then
      ok "upstream مطابق لاسم الفرع أصلاً"
    elif git rev-parse --verify --quiet "refs/remotes/origin/$BRANCH" >/dev/null 2>&1; then
      git branch --set-upstream-to="origin/$BRANCH" "$BRANCH" >/dev/null 2>&1 \
        && ok "upstream = origin/$BRANCH (اسم مطابق، لا main)"
    fi
  fi
}

# ---------------------------------------------------------------------------
# الدفع الآمن + التحقّق من الاستلام
# ---------------------------------------------------------------------------
do_push() {
  [ "$IN_GIT" = "1" ] || { bad "لا يمكن الدفع من detached HEAD"; exit 1; }
  section "دفعة آمنة + تحقّق أن GitHub استلم فعلاً"
  # «الإصلاح قبل الدفع»: كل ما يُصلَح هنا محلي وفوري وبلا شبكة، وآمن للتكرار.
  do_local_repair
  local local_sha remote_sha
  local_sha="$(git rev-parse HEAD)"
  if ! git push origin "HEAD:refs/heads/$BRANCH" 2>&1 | sed 's/^/      /'; then
    bad "فشل الدفع — شغّل: $0 report لعرض خطوات التصعيد"; exit 1
  fi
  remote_sha="$(git ls-remote origin "refs/heads/$BRANCH" 2>/dev/null | awk '{print $1}')"
  if [ "$local_sha" != "$remote_sha" ]; then
    bad "الدفع قال إنه نجح لكن الريموت يحمل ${remote_sha:-لا شيء} ≠ $local_sha — العمل غير محفوظ"; exit 1
  fi
  ok "GitHub يحمل فعلاً: $local_sha"
  if [ -n "$SLUG" ]; then
    local api_sha
    api_sha="$(curl -sS --max-time 20 "https://api.github.com/repos/$SLUG/commits/$BRANCH" 2>/dev/null \
      | grep -o '"sha": *"[0-9a-f]\{40\}"' | command head -1 | cut -d'"' -f4)"
    [ "$api_sha" = "$local_sha" ] && ok "وتأكيد ثانٍ من واجهة GitHub بنفس الـSHA" \
      || warn "الواجهة أعادت ${api_sha:-لا شيء} — تحقّق يدوي مستحسن"
  fi
}

# ---------------------------------------------------------------------------
# الاختبار الذاتي — بلا شبكة (يُشغَّل في CI)
# ---------------------------------------------------------------------------
do_self_test() {
  section "اختبار ذاتي (بلا شبكة)"
  local tmp rc failures=0
  tmp="$(mktemp -d)"
  # أ) سلامة الصياغة والأذونات
  if bash -n "$SCRIPT_DIR/git-doctor.sh"; then ok "صياغة git-doctor.sh سليمة"; else bad "خطأ صياغة في git-doctor.sh"; failures=$((failures+1)); fi
  if [ -f "$REPO/.githooks/pre-push" ] && bash -n "$REPO/.githooks/pre-push"; then ok "صياغة .githooks/pre-push سليمة"
  else bad ".githooks/pre-push مفقود أو فيه خطأ صياغة"; failures=$((failures+1)); fi
  local mode; mode="$(git ls-files -s .githooks/pre-push 2>/dev/null | awk '{print $1}')"
  [ "$mode" = "100755" ] && ok "الخطاف قابل للتنفيذ في الفهرس (100755)" \
    || { bad "وضع الخطاف في الفهرس = ${mode:-غير متتبَّع} (يجب 100755)"; failures=$((failures+1)); }

  # ب) سلوك الخطاف في مستودع مؤقت
  (
    cd "$tmp" || exit 1
    git init -q .
    git -c user.email=t@t -c user.name=t commit -q --allow-empty -m a
    A="$(git rev-parse HEAD)"
    git -c user.email=t@t -c user.name=t commit -q --allow-empty -m b
    B="$(git rev-parse HEAD)"
    cp "$REPO/.githooks/pre-push" .git/pre-push; chmod +x .git/pre-push
    REF='refs/heads/test'

    printf '%s %s %s %s\n' "$REF" "$B" "$REF" "$A" | GIT_DIR=.git .git/pre-push origin x
    echo "FF=$?"
    printf '%s %s %s %s\n' "$REF" "$A" "$REF" "$B" | GIT_DIR=.git .git/pre-push origin x
    echo "NONFF=$?"
    printf '%s %s %s %s\n' "$REF" '0000000000000000000000000000000000000000' "$REF" "$B" | GIT_DIR=.git .git/pre-push origin x
    echo "DELETE=$?"

    # غياب كائن الطرف الآخر: sha صحيح الشكل لكنه غير موجود محلياً ⇒ تعذّر التحقق ⇒ رفض
    UNKNOWN='1111111111111111111111111111111111111111'
    printf '%s %s %s %s\n' "$REF" "$B" "$REF" "$UNKNOWN" | GIT_DIR=.git .git/pre-push origin x
    echo "UNKNOWN_SHA=$?"
    # main: حتى مع تجاوز صريح يبقى مرفوضاً
    printf '%s %s %s %s\n' 'refs/heads/main' "$B" 'refs/heads/main' "$UNKNOWN" | FAMILY_OS_ALLOW_FORCE_PUSH=1 GIT_DIR=.git .git/pre-push origin x
    echo "MAIN_UNVERIFIED_OVERRIDE=$?"
    # فرع غير main مع تجاوز صريح: مسموح (المخرج الوحيد المقصود)
    printf '%s %s %s %s\n' "$REF" "$B" "$REF" "$UNKNOWN" | FAMILY_OS_ALLOW_FORCE_PUSH=1 GIT_DIR=.git .git/pre-push origin x
    echo "UNVERIFIED_OVERRIDE=$?"
    # سجل الحارس: يجب أن يحمل المرفوض ولا يحمل المسموح-بتحذير القديم
    echo "LOG_BLOCKED=$(grep -c 'BLOCKED-UNVERIFIED' .git/family-os-push-guard.log 2>/dev/null || echo 0)"
    echo "LOG_OLD_ALLOW=$(grep -c 'UNVERIFIED-ALLOWED' .git/family-os-push-guard.log 2>/dev/null || echo 0)"
  ) > "$tmp/out" 2>"$tmp/err"
  local ff nonff del
  ff="$(grep '^FF=' "$tmp/out" | cut -d= -f2)"
  nonff="$(grep '^NONFF=' "$tmp/out" | cut -d= -f2)"
  del="$(grep '^DELETE=' "$tmp/out" | cut -d= -f2)"
  [ "$ff" = "0" ] && ok "الخطاف يسمح بدمج fast-forward" || { bad "الخطاف رفض fast-forward (يجب أن يسمح)"; failures=$((failures+1)); }
  [ "$nonff" != "0" ] && ok "الخطاف يمنع force-push (خروج $nonff)" || { bad "الخطاف سمح بـ force-push"; failures=$((failures+1)); }
  [ "$del" != "0" ] && ok "الخطاف يمنع حذف الفرع (خروج $del)" || { bad "الخطاف سمح بحذف فرع"; failures=$((failures+1)); }

  # حالات «تعذّر التحقق»: كانت تُسمح بعد تحذير، ويجب الآن أن تُرفض
  local unk mainunk over logblk logold
  unk="$(grep '^UNKNOWN_SHA=' "$tmp/out" | cut -d= -f2)"
  mainunk="$(grep '^MAIN_UNVERIFIED_OVERRIDE=' "$tmp/out" | cut -d= -f2)"
  over="$(grep '^UNVERIFIED_OVERRIDE=' "$tmp/out" | cut -d= -f2)"
  logblk="$(grep '^LOG_BLOCKED=' "$tmp/out" | cut -d= -f2)"
  logold="$(grep '^LOG_OLD_ALLOW=' "$tmp/out" | cut -d= -f2)"
  [ "$unk" != "0" ] && ok "غياب remote SHA: مرفوض لا مسموح (خروج $unk)" || { bad "الخطاف سمح بدفع تعذّر التحقق فيه"; failures=$((failures+1)); }
  [ "$mainunk" != "0" ] && ok "main بلا تجاوز: مرفوض حتى مع FAMILY_OS_ALLOW_FORCE_PUSH=1" || { bad "main قَبِل دفعاً تعذّر التحقق فيه رغم التجاوز"; failures=$((failures+1)); }
  [ "$over" = "0" ] && ok "فرع غير main مع تجاوز صريح: مسموح (المخرج المقصود وحده)" || { bad "التجاوز الصريح لم يعمل على فرع غير main"; failures=$((failures+1)); }
  [ "${logblk:-0}" != "0" ] && ok "سجل الحارس يوثّق الرفض (BLOCKED-UNVERIFIED)" || { bad "لم يُسجَّل الرفض في سجل الحارس"; failures=$((failures+1)); }
  [ "${logold:-0}" = "0" ] && ok "لا أثر للسلوك القديم (UNVERIFIED-ALLOWED)" || { bad "ما زال السلوك القديم يسجّل سماحاً"; failures=$((failures+1)); }

  # ج) الإصلاح آمن للتكرار في مستودع بلا إعداد
  (
    cd "$tmp" || exit 1
    rm -f .git/config
    bash "$SCRIPT_DIR/git-doctor.sh" repair "$tmp" >/dev/null 2>&1
    echo "R1=$?"
    bash "$SCRIPT_DIR/git-doctor.sh" repair "$tmp" >/dev/null 2>&1
    echo "R2=$?"
    echo "REMOTE=$(git config --get remote.origin.url || echo MISSING)"
    echo "DUPES=$(git config --get-all remote.origin.fetch 2>/dev/null | sort | uniq -d | wc -l | tr -d ' ')"
    echo "IDENT=$(git config --get user.email || echo MISSING)"
    echo "PUSHDEF=$(git config --get push.default || echo MISSING)"
  ) > "$tmp/out2" 2>&1
  [ "$(grep '^R1=' "$tmp/out2" | cut -d= -f2)" = "0" ] && ok "repair ينجح على مستودع فقد إعداده" || { bad "repair فشل على مستودع بلا config"; failures=$((failures+1)); }
  [ "$(grep '^R2=' "$tmp/out2" | cut -d= -f2)" = "0" ] && ok "repair آمن للتكرار (تشغيل ثانٍ)" || { bad "repair غير آمن للتكرار"; failures=$((failures+1)); }
  [ "$(grep '^REMOTE=' "$tmp/out2" | cut -d= -f2-)" != "MISSING" ] && ok "repair أعاد remote origin" || { bad "repair لم يُعِد origin"; failures=$((failures+1)); }
  [ "$(grep '^DUPES=' "$tmp/out2" | cut -d= -f2)" = "0" ] && ok "لا refspec مكرر بعد تشغيلين" || { bad "تكرّر refspec بعد تشغيلين"; failures=$((failures+1)); }
  [ "$(grep '^IDENT=' "$tmp/out2" | cut -d= -f2-)" != "MISSING" ] && ok "repair يضبط هوية الإيداع (بلاها لا إيداع أصلاً)" || { bad "repair لم يضبط هوية الإيداع"; failures=$((failures+1)); }
  [ "$(grep '^PUSHDEF=' "$tmp/out2" | cut -d= -f2)" = "current" ] && ok "repair يضبط push.default=current" || { bad "push.default لم يُضبط"; failures=$((failures+1)); }

  # د) اختبار شامل على ريموت محلي حقيقي (بلا شبكة): هل يمنع الخطاف force-push فعلاً؟
  (
    cd "$tmp" || exit 1
    git init -q --bare origin.git
    if git remote get-url origin >/dev/null 2>&1; then
      git remote set-url origin "$tmp/origin.git"
    else
      git remote add origin "$tmp/origin.git"
    fi
    git config push.default current
    git push -q origin HEAD:refs/heads/e2e 2>/dev/null; echo "FF_PUSH=$?"
    echo "R1=$(git ls-remote "$tmp/origin.git" refs/heads/e2e | awk '{print $1}')"
    # أعِد كتابة التاريخ محلياً ثم ادفعه بالقوة بلا حارس — لإثبات أن الخطر حقيقي
    git reset -q --hard HEAD~1 2>/dev/null || true
    git -c user.email=t@t -c user.name=t commit -q --allow-empty -m rewritten
    git push -q --force origin HEAD:refs/heads/e2e >/dev/null 2>&1; echo "FORCE_NO_HOOK=$?"
    echo "R2=$(git ls-remote "$tmp/origin.git" refs/heads/e2e | awk '{print $1}')"
  ) > "$tmp/out3" 2>&1
  # الآن ثبّت الحارس، وأعد المحاولة نفسها: يجب أن تُرفض ويبقى الريموت كما هو
  cp "$REPO/.githooks/pre-push" "$tmp/.git/hooks/pre-push"; chmod +x "$tmp/.git/hooks/pre-push"
  (
    cd "$tmp" || exit 1
    git reset -q --hard HEAD~1 2>/dev/null || true
    git -c user.email=t@t -c user.name=t commit -q --allow-empty -m rewritten-again
    git push --force origin HEAD:refs/heads/e2e >/dev/null 2>&1; echo "FORCE_WITH_HOOK=$?"
    echo "R3=$(git ls-remote "$tmp/origin.git" refs/heads/e2e | awk '{print $1}')"
    git push -q origin HEAD:refs/heads/e2e-new >/dev/null 2>&1; echo "NEW_BRANCH=$?"
  ) > "$tmp/out4" 2>&1
  local ffpush fhook r1 r2 r3 newbranch
  ffpush="$(grep '^FF_PUSH=' "$tmp/out3" | cut -d= -f2)"
  r1="$(grep '^R1=' "$tmp/out3" | cut -d= -f2)"
  r2="$(grep '^R2=' "$tmp/out3" | cut -d= -f2)"
  fhook="$(grep '^FORCE_WITH_HOOK=' "$tmp/out4" | cut -d= -f2)"
  r3="$(grep '^R3=' "$tmp/out4" | cut -d= -f2)"
  newbranch="$(grep '^NEW_BRANCH=' "$tmp/out4" | cut -d= -f2)"

  [ "$ffpush" = "0" ] && ok "دفع fast-forward حقيقي نجح على ريموت محلي" \
    || { bad "دفع fast-forward فشل (خروج $ffpush)"; failures=$((failures+1)); }
  [ "$r1" != "$r2" ] && ok "بلا حارس: force-push فعلاً أعاد كتابة ريموت الاختبار (الخطر مثبَت)" \
    || warn "لم يتغيّر الريموت عند محاولة القوة بلا حارس (بيئة git مختلفة؟)"
  [ "$fhook" != "0" ] && ok "بالحارس مثبّتاً: force-push مرفوض عبر git push حقيقي (خروج $fhook)" \
    || { bad "الحارس لم يمنع force-push"; failures=$((failures+1)); }
  [ "$r3" = "$r2" ] && ok "ريموت الاختبار سليم بعد المحاولة المرفوضة (التاريخ لم يُمحَ)" \
    || { bad "الريموت تغيّر رغم الحارس — خطر فقدان تاريخ"; failures=$((failures+1)); }
  [ "$newbranch" = "0" ] && ok "إنشاء فرع جديد (بلا تاريخ يُكتب فوقه) مسموح" \
    || warn "دفع فرع جديد رُفض (خروج $newbranch)"

  # هـ) استنساخ shallow حقيقي: التحقق من ancestry مستحيل ⇒ يجب الرفض، والدفع العادي يجب أن يمرّ
  (
    cd "$tmp" || exit 1
    rm -rf shallow-src shallow-origin.git shallow-clone
    git init -q shallow-src
    (
      cd shallow-src
      git config user.email t@t; git config user.name t
      echo one > f; git add f; git commit -q -m c1
      git branch -M main
      echo two >> f; git commit -qam c2
      git checkout -q -b other; echo side > s; git add s; git commit -q -m c3
      git checkout -q main
    )
    git init -q --bare shallow-origin.git
    git -C shallow-src push -q "$tmp/shallow-origin.git" --all
    git clone -q --depth=1 --branch main "file://$tmp/shallow-origin.git" shallow-clone 2>/dev/null
    (
      cd shallow-clone
      echo "IS_SHALLOW=$(git rev-parse --is-shallow-repository)"
      echo "COMMITS=$(git rev-list --count HEAD)"
      cp "$REPO/.githooks/pre-push" .git/hooks/pre-push; chmod +x .git/hooks/pre-push
      # (١) دفع fast-forward عادي من استنساخ shallow: يجب أن يُسمح
      echo three >> f
      git -c user.email=t@t -c user.name=t commit -qam c4
      git push -q origin HEAD:refs/heads/main >/dev/null 2>&1; echo "SHALLOW_FF=$?"
      # (٢) دفع إلى فرع لا نملك تاريخه (other): الطرف الآخر غير موجود محلياً ⇒ التحقق مستحيل ⇒ رفض
      echo "OTHER_BEFORE=$(git ls-remote origin refs/heads/other | awk '{print $1}')"
      git push --force origin HEAD:refs/heads/other >/dev/null 2>&1; echo "SHALLOW_UNVERIFIED=$?"
      echo "OTHER_AFTER=$(git ls-remote origin refs/heads/other | awk '{print $1}')"
      echo "GUARD_LOGGED=$(grep -c 'BLOCKED-UNVERIFIED' .git/family-os-push-guard.log 2>/dev/null || echo 0)"
      # (٣) main من استنساخ shallow: تجاوز صريح لا يجوز أن يفتحه
      git -c user.email=t@t -c user.name=t commit -q --amend -m rewritten
      FAMILY_OS_ALLOW_FORCE_PUSH=1 git push --force origin HEAD:refs/heads/main >/dev/null 2>&1; echo "SHALLOW_MAIN_OVERRIDE=$?"
      echo "MAIN_REMOTE=$(git ls-remote origin refs/heads/main | awk '{print $1}')"
    )
  ) > "$tmp/out5" 2>&1
  local s_ff s_unv s_ok s_log s_main s_mainremote other_before other_after
  s_ff="$(grep '^SHALLOW_FF=' "$tmp/out5" | cut -d= -f2)"
  s_unv="$(grep '^SHALLOW_UNVERIFIED=' "$tmp/out5" | cut -d= -f2)"
  s_log="$(grep '^GUARD_LOGGED=' "$tmp/out5" | cut -d= -f2)"
  s_main="$(grep '^SHALLOW_MAIN_OVERRIDE=' "$tmp/out5" | cut -d= -f2)"
  other_before="$(grep '^OTHER_BEFORE=' "$tmp/out5" | cut -d= -f2)"
  other_after="$(grep '^OTHER_AFTER=' "$tmp/out5" | cut -d= -f2)"
  [ "$(grep '^IS_SHALLOW=' "$tmp/out5" | cut -d= -f2)" = "true" ] \
    && ok "اختبار shallow حقيقي: الاستنساخ فعلاً shallow (depth=1)" \
    || warn "لم يكن الاستنساخ shallow — الاختبار أقل قوة"
  [ "$s_ff" = "0" ] && ok "shallow: دفع fast-forward عادي مسموح (لا منع كاذب)" || { bad "shallow: مُنع دفع fast-forward مشروع (منع كاذب)"; failures=$((failures+1)); }
  [ "$s_unv" != "0" ] && ok "shallow + غياب كائن الطرف الآخر: مرفوض (لم يُسمح بعد تحذير)" || { bad "shallow: سُمح بدفع تعذّر التحقق من ancestry فيه"; failures=$((failures+1)); }
  [ "${s_log:-0}" != "0" ] && ok "shallow: الرفض موثّق في سجل الحارس" || { bad "shallow: لم يُسجَّل الرفض"; failures=$((failures+1)); }
  [ "$other_before" = "$other_after" ] && ok "shallow: ريموت الفرع الآخر سليم بعد الرفض" || { bad "shallow: تغيّر ريموت فرع لم نتحقق منه"; failures=$((failures+1)); }
  [ "$s_main" != "0" ] && ok "shallow: main مرفوض رغم التجاوز الصريح" || { bad "shallow: main قَبِل فرض تاريخ"; failures=$((failures+1)); }

  rm -rf "$tmp"
  printf "\n"
  [ "$failures" -eq 0 ] && { printf "${GREEN}${BOLD}الاختبار الذاتي: ناجح${OFF}\n"; return 0; }
  printf "${RED}${BOLD}الاختبار الذاتي: %d فشل${OFF}\n" "$failures"; return 1
}

# ---------------------------------------------------------------------------
# تقرير التصعيد
# ---------------------------------------------------------------------------
do_report() {
  section "تقرير تصعيد إلى دعم Arena.ai (انسخه كما هو)"
  cat <<EOF
────────────────────────────────────────────────────────────────
الموضوع: استمرارية إعداد Git بين الجلسات — إسقاط .git/config واستنساخ depth=1

المستودع         : ${SLUG:-Bassam-mohammed-alqaeadi/family-os}
الفرع            : $BRANCH
E2B_SANDBOX_ID   : ${E2B_SANDBOX_ID:-غير متاح}
E2B_TEMPLATE_ID  : ${E2B_TEMPLATE_ID:-غير متاح}
الوقت            : $(date -u '+%Y-%m-%d %H:%M UTC')

الأعراض الحرفية المتكررة:
  fatal: No configured push destination.
  fatal: The current branch <b> has no upstream branch.
  fatal: The upstream branch of your current branch does not match the name of your current branch.
  واختفاء إيداعات محلية وُجدت قبل إعادة بناء مساحة العمل.

السبب الجذري:
  1) .git/config مُدرَج في استثناءات اللقطات، وهو المكان الوحيد الذي يُعرَّف فيه remote origin
     (لا gitconfig عام ولا credential.helper). بعد أي استعادة يفقد المستودع وجهة الدفع،
     و git init الشائع لا يُصلحه، وإعادة الاستنساخ تمسح الإيداعات المحلية.
  2) الاستنساخ عند تهيئة المساحة depth=1 (.git/shallow موجود): التاريخ المحلي إيداع واحد،
     فأي إيداع محلي يزول مع إعادة بناء المساحة.
  3) الفرع المُنشأ للجلسة بلا upstream، وبعض الأدوات تضبطه على main فيتكرر خطأ عدم التطابق.

ما هو موجود الآن داخل المستودع (لا يعتمد على /home/user ولا على /tmp):
  • tools/git/git-doctor.sh  — فحص + إصلاح + دفع آمن مُتحقَّق + اختبار ذاتي + تقرير.
  • .githooks/pre-push        — يمنع force-push وحذف الفروع محلياً.
  • أمر التأسيس (docs/AGENT_BOOTSTRAP_PROMPT.md) يطلب تشغيل repair في بداية كل جلسة.

الإعداد المطلوب تغييره على مستوى المنصة (لا يملكه وكيل داخل الجلسة):
  أ) تشغيل أمر بدء جلسة تلقائي عند تهيئة مساحة العمل:
       tools/git/git-doctor.sh repair     (بعد الاستنساخ وقبل أي عمل)
     هذا يجعل الإصلاح فعلياً "تلقائياً" بلا اعتماد على انتباه الوكيل.
  ب) لا تُسقط .git/config من اللقطات (أو انقل رمز الدفع إلى ملف مستقل فلا يحتاج config للحماية).
  ج) لا تُعِد إنشاء/استنساخ مساحة العمل أثناء الجلسة؛ وإن لزم فليكن استنساخاً كاملاً لا depth=1.
  د) اضبط في صورة الـsandbox: push.default=current و push.autoSetupRemote=true.
  هـ) أكّد استمرار حقن مصادقة GitHub في وسيط Egress لـ github.com و api.github.com و codeload.github.com.

طريقة التصعيد: من داخل المحادثة عبر زر المساعدة/الإبلاغ أو قنوات دعم Arena.ai،
مع لصق هذا التقرير كاملاً ووقت آخر فشل ورسالة الخطأ الحرفية.
────────────────────────────────────────────────────────────────
EOF
}

# ---------------------------------------------------------------------------
ctx
case "$MODE" in
  check)
    net_check; auth_check; config_check; hooks_check; sync_check
    if [ -x "$REPO/tools/git/repo-health.sh" ] || [ -f "$REPO/tools/git/repo-health.sh" ]; then
      section "٦) فحص المستودع نفسه"
      if bash "$REPO/tools/git/repo-health.sh" >/dev/null 2>&1; then ok "tools/git/repo-health.sh → exit 0"
      else warn "tools/git/repo-health.sh أعاد exit 1 (راجع تقريره)"; fi
    fi
    ;;
  repair)
    do_repair
    config_check; hooks_check
    ;;
  push)
    net_check; auth_check; do_push
    ;;
  self-test)
    do_self_test || exit 1
    exit 0
    ;;
  report)
    do_report; exit 0
    ;;
esac

printf "\n${BOLD}الخلاصة:${OFF} ناجح=%d فاشل=%d\n" "$PASS" "$FAIL"
if [ "$FAIL" -eq 0 ]; then exit 0; fi
printf "${YELLOW}الإصلاح المقترح: %s repair${OFF}\n" "${BASH_SOURCE[0]}"
exit 1
