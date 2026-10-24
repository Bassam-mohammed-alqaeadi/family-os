# One-shot ARB + generated-l10n writer for the screen-time polish wave.
#
# Why this file exists: `flutter gen-l10n` is the only writer of
# `lib/core/i18n/app_localizations*.dart`, and this sandbox has no Flutter SDK.
# `test/tool/l10n_generated_shape_test.dart` states the generator's rules
# literally (a plain message is one line when `  String get key => 'value';` is at
# most 80 UTF-16 units wide and is split after `=>` when wider; every ARB message is
# declared in the abstract class and implemented in both language files; the two ARB
# files carry the same key set), so this script writes exactly those shapes instead of
# guessing, and the owner's `flutter gen-l10n` gate stays a no-op diff.
#
# Copy rules this list keeps, because they are tested rather than tasteful:
#   * Arabic-first — the ARB template is `app_ar.arb`, English is the fallback;
#   * Western digits only (the numeral controller owns any conversion);
#   * no engineering jargon (`test/core/i18n/vx_b3_arb_human_language_test.dart`);
#   * no string duplicates the panel's pinned sentences, and nothing that contains
#     `متبقي` outside the remaining-time line — the child board counts those substrings.
#
# Run from `app/`:  python3 tool/_polish_add_arb.py
import json
import os
import sys

ARB_DIR = os.path.join("lib", "core", "i18n")

# (key, ar, en, description, placeholders) — placeholders: [(name, dartType)]
MESSAGES = [
    # ---------------------------------------------------------------- CHD-004 · hero ring
    ("childDayBoardTimeHeroTitle", "وقتك اليوم", "Your time today",
     "SCR-CHD-004 daily time hero ring title", []),
    ("childDayBoardTimeHeroBase", "الحد الأساسي", "Daily base limit",
     "SCR-CHD-004 hero ring legend for the guardian-set daily cap", []),
    ("childDayBoardTimeHeroEarned", "دقائق كسبتها", "Minutes you earned",
     "SCR-CHD-004 hero ring legend for minutes earned by tasks and activities", []),
    ("childDayBoardTimeHeroGrant", "منحة من أهلي", "Gift from family",
     "SCR-CHD-004 hero ring legend for guardian-granted temporary minutes", []),
    ("childDayBoardTimeHeroNoLimit", "وقتك مفتوح اليوم", "Your day is open",
     "SCR-CHD-004 hero ring when the server reports no daily limit", []),
    ("childDayBoardTimeHeroLoading", "نقرأ وقتك من الخادم…",
     "Reading your time from the server…",
     "SCR-CHD-004 hero ring loading state", []),
    ("childDayBoardTimeHeroAbundant", "أمامك وقت مريح — استمتع بذكاء",
     "Plenty of time left — enjoy it wisely",
     "SCR-CHD-004 hero ring calm tone when minutes are plentiful", []),
    ("childDayBoardTimeHeroNearEnd", "بقي القليل — أنهِ لعبتك بهدوء",
     "A little left — finish your game calmly",
     "SCR-CHD-004 hero ring warm tone when the day is nearly spent", []),
    ("childDayBoardTimeHeroDepleted", "انتهى وقت اليوم — غداً وقت جديد",
     "Today's time is done — tomorrow brings a fresh one",
     "SCR-CHD-004 hero ring when the day's minutes are spent", []),
    ("childDayBoardTimeHeroWindDown", "اقترب وقت النوم — خفف الشاشة",
     "Bedtime is near — let the screen wind down",
     "SCR-CHD-004 hero ring bedtime tone", []),
    ("childDayBoardTimeHeroRingSemantics", "حلبة وقت الشاشة: {percent}% مستهلك",
     "Screen time ring: {percent}% used",
     "SCR-CHD-004 hero ring accessibility sentence", [("percent", "int")]),
    # ---------------------------------------------------------------- CHD-004 · routine
    ("childDayBoardRoutineTitle", "روتين اليوم", "Today's routine",
     "SCR-CHD-004 routine card title", []),
    ("childDayBoardRoutineSleep", "وقت النوم 🌙", "Bedtime 🌙",
     "SCR-CHD-004 routine badge for the sleep window", []),
    ("childDayBoardRoutineSchool", "وقت الدوام 🎒", "School hours 🎒",
     "SCR-CHD-004 routine badge for the school window", []),
    ("childDayBoardRoutineFree", "وقت اللعب 🎮", "Play time 🎮",
     "SCR-CHD-004 routine badge when the child's own time is open", []),
    ("childDayBoardRoutineWindDown", "تهدئة قبل النوم",
     "Winding down before sleep",
     "SCR-CHD-004 routine badge in the minutes before bedtime", []),
    ("childDayBoardRoutineHint",
     "النوم والدوام واللعب حسب جدول عائلتك",
     "Sleep, school and play follow your family's schedule",
     "SCR-CHD-004 routine card hint line", []),
    # ---------------------------------------------------------------- CHD-004 · minute economy
    ("childDayBoardTasksTitle", "مهامي ومكافآتي", "My tasks and rewards",
     "SCR-CHD-004 tasks and rewards card title", []),
    ("childDayBoardTasksSubtitle", "أنهِ مهمتك لتربح دقائق",
     "Finish a task to earn minutes",
     "SCR-CHD-004 tasks card subtitle", []),
    ("childDayBoardTasksPoints", "{points} نقطة", "{points} points",
     "SCR-CHD-004 reward shown on one task card", [("points", "int")]),
    ("childDayBoardTasksStatusPending", "لم تبدأ بعد", "Not started yet",
     "SCR-CHD-004 status of a task nobody has sent", []),
    ("childDayBoardTasksStatusClaimed", "أرسلتها — بانتظار أهل",
     "Sent — waiting for a guardian",
     "SCR-CHD-004 status of a task awaiting a guardian's answer", []),
    ("childDayBoardTasksStatusConfirmed", "موافق عليها", "Approved",
     "SCR-CHD-004 status of an approved task", []),
    ("childDayBoardTasksStatusDeclined", "ردّها أهل هذه المرة",
     "Declined this time",
     "SCR-CHD-004 status of a declined task", []),
    ("childDayBoardTasksStatusArchived", "مؤرشفة", "Archived",
     "SCR-CHD-004 status of a task closed for the day", []),
    ("childDayBoardTasksOpenAll", "كل المهام", "All tasks",
     "SCR-CHD-004 link from the tasks card to the tasks list", []),
    ("childDayBoardTasksEmpty", "لا مهام اليوم", "No tasks today",
     "SCR-CHD-004 empty state of the tasks card", []),
    ("childDayBoardTasksLoading", "نقرأ مهامك…", "Reading your tasks…",
     "SCR-CHD-004 loading state of the tasks card", []),
    ("childDayBoardTasksUnavailable", "لم يُربط خادم المهام بعد",
     "The tasks server is not connected yet",
     "SCR-CHD-004 state of the tasks card with no server bound", []),
    ("childDayBoardTasksRefused", "لم أستطع قراءة مهامك الآن",
     "I could not read your tasks right now",
     "SCR-CHD-004 error state of the tasks card", []),
    # ---------------------------------------------------------------- CHD-004 · safety hold
    ("childDayBoardSafetyTitle", "زر الأمان", "Safety button",
     "SCR-CHD-004 safety card title", []),
    ("childDayBoardSafetyReady", "جاهز — اضغط مطولاً للنجدة",
     "Ready — press and hold for help",
     "SCR-CHD-004 safety button when it is armed", []),
    ("childDayBoardSafetyHold", "اضغط مطولاً 3 ثوانٍ", "Press and hold for 3 seconds",
     "SCR-CHD-004 instruction under the safety button", []),
    ("childDayBoardSafetyProgress", "استمر بالضغط — {seconds}",
     "Keep holding — {seconds}",
     "SCR-CHD-004 countdown inside the safety hold", [("seconds", "int")]),
    ("childDayBoardSafetyReleased", "أُرسل طلب النجدة", "The help request was sent",
     "SCR-CHD-004 message once the hold completed", []),
    ("childDayBoardSafetySemantics", "زر النجدة — اضغط مطولاً لثلاث ثوانٍ",
     "Help button — press and hold for three seconds",
     "SCR-CHD-004 accessibility label of the safety button", []),
    # ---------------------------------------------------------------- CHD-004 · touchpoints
    ("childDayBoardTouchpointsTitle", "عائلتي", "My family",
     "SCR-CHD-004 family touchpoints card title", []),
    ("childDayBoardTouchpointsSubtitle", "اتصال أو رسالة بضغطة واحدة",
     "A call or a message with one tap",
     "SCR-CHD-004 family touchpoints card subtitle", []),
    ("childDayBoardTouchpointsFamilyThread", "محادثة العائلة", "Family thread",
     "SCR-CHD-004 one-tap touchpoint to the shared family thread", []),
    ("childDayBoardTouchpointsAllChats", "كل المحادثات", "All chats",
     "SCR-CHD-004 one-tap touchpoint to the child's conversation list", []),
    ("childDayBoardTouchpointsAskTime", "أطلب دقائق إضافية",
     "Ask for extra minutes",
     "SCR-CHD-004 one-tap touchpoint to the time-request screen", []),
    ("childDayBoardTouchpointsQuran", "وردي من القرآن", "My Qur'an page",
     "SCR-CHD-004 one-tap touchpoint to the child's Qur'an page", []),
    ("childDayBoardTouchpointsWallet", "دفتر دقائق", "My minutes ledger",
     "SCR-CHD-004 one-tap touchpoint to the child's minutes wallet", []),
    # ---------------------------------------------------------------- FAT-032 · extra time
    ("screenTimeServerExtensionTitle", "تمديد الوقت", "Extra time",
     "SCR-FAT-032 server panel — quick and custom extension card title", []),
    ("screenTimeServerExtensionHint",
     "تُضاف الدقائق بقرار من الخادم وتصل للطفل عند مزامنته",
     "Minutes are added by the server and reach the child on their next sync",
     "SCR-FAT-032 server panel — extension card honesty hint", []),
    ("screenTimeServerExtensionCustom", "دقائق مخصصة", "Custom minutes",
     "SCR-FAT-032 server panel — open the custom extension sheet", []),
    ("screenTimeServerExtensionCustomTitle", "كم دقيقة تمنح الآن؟",
     "How many minutes now?",
     "SCR-FAT-032 server panel — custom extension sheet title", []),
    ("screenTimeServerExtensionCustomHelper", "من 1 إلى 240 دقيقة",
     "Between 1 and 240 minutes",
     "SCR-FAT-032 server panel — custom extension helper text", []),
    ("screenTimeServerExtensionCustomConfirm", "امنح على الخادم",
     "Grant on the server",
     "SCR-FAT-032 server panel — custom extension confirm button", []),
    ("screenTimeServerExtensionCustomInvalid", "أدخل عدد دقائق بين 1 و 240",
     "Enter minutes between 1 and 240",
     "SCR-FAT-032 server panel — custom extension validation error", []),
    ("screenTimeServerExtensionPending", "الخادم ينفذ التمديد…",
     "The server is applying the extension…",
     "SCR-FAT-032 server panel — extension write in flight", []),
    # ---------------------------------------------------------------- FAT-032 · instant lock
    ("screenTimeServerLockStateLocked", "الهاتف موقوف الآن بقرارك",
     "The phone is stopped now, by your decision",
     "SCR-FAT-032 server panel — lock card when a lock is live", []),
    ("screenTimeServerLockStateUnlocked", "الهاتف يعمل ضمن حد اليوم",
     "The phone works within today's cap",
     "SCR-FAT-032 server panel — lock card when nothing is stopping the phone", []),
    ("screenTimeServerLockSince", "أوقف عند {time}", "Stopped at {time}",
     "SCR-FAT-032 server panel — when the live lock began", [("time", "String")]),
    ("screenTimeServerLockBusy", "الخادم ينفذ…", "The server is applying it…",
     "SCR-FAT-032 server panel — lock write in flight", []),
    ("screenTimeServerLockConfirmed", "تم التأكيد من الخادم",
     "Confirmed by the server",
     "SCR-FAT-032 server panel — confirmed-lock chip", []),
    ("screenTimeServerLockReleaseNote", "الإعادة لا تلغي حد اليوم",
     "Releasing does not erase today's cap",
     "SCR-FAT-032 server panel — release lock note", []),
    # ---------------------------------------------------------------- FAT-032 · apps sheet
    ("screenTimeServerAppsTitle", "التطبيقات والفئات", "Apps and categories",
     "SCR-FAT-032 server panel — app rules card title", []),
    ("screenTimeServerAppsSubtitle", "قرارك لكل تطبيق يُحفظ على الخادم",
     "Your decision for each app is saved on the server",
     "SCR-FAT-032 server panel — app rules card subtitle", []),
    ("screenTimeServerAppsOpen", "أدر التطبيقات", "Manage apps",
     "SCR-FAT-032 server panel — open the app rules sheet", []),
    ("screenTimeServerAppsRules", "قواعد التطبيقات", "App rules",
     "SCR-FAT-032 server panel — link from the insights card to app rules", []),
    ("screenTimeServerAppsClose", "تم", "Done",
     "SCR-FAT-032 app rules sheet — dismiss control", []),
    ("screenTimeServerAppsLoading", "نقرأ تطبيقات الهاتف…",
     "Reading the phone's apps…",
     "SCR-FAT-032 app rules sheet — loading state", []),
    ("screenTimeServerAppsEmpty", "لم يبلّغ الهاتف عن تطبيقات بعد",
     "The phone has not reported any apps yet",
     "SCR-FAT-032 app rules sheet — empty state", []),
    ("screenTimeServerAppsDenied", "لا يملك هذا الحساب إدارة تطبيقات هذا الابن",
     "This account may not manage this child's apps",
     "SCR-FAT-032 app rules sheet — refused read", []),
    ("screenTimeServerAppsStale", "لم يستجب الخادم — هذه آخر قائمة وصلت",
     "The server did not answer — this is the last list that arrived",
     "SCR-FAT-032 app rules sheet — unreachable state", []),
    ("screenTimeServerAppsNoSession", "لا توجد جلسة خادم — لا نغير شيئاً",
     "There is no server session — nothing is changed",
     "SCR-FAT-032 app rules sheet — no session bound", []),
    ("screenTimeServerAppAllow", "اسمح", "Allow",
     "SCR-FAT-032 app rules sheet — allow one app", []),
    ("screenTimeServerAppBlock", "احجب", "Block",
     "SCR-FAT-032 app rules sheet — block one app", []),
    ("screenTimeServerAppStateAllowed", "مسموح", "Allowed",
     "SCR-FAT-032 app rules sheet — the rule the server stores for one app", []),
    ("screenTimeServerAppStateBlocked", "محجوب", "Blocked",
     "SCR-FAT-032 app rules sheet — a blocked app, stated as the stored rule", []),
    ("screenTimeServerAppPending", "بانتظار القرار", "Awaiting a decision",
     "SCR-FAT-032 app rules sheet — a rule nobody has written yet", []),
    ("screenTimeServerAppFree", "مسموح دائماً", "Always allowed",
     "SCR-FAT-032 app rules sheet — an app with no limit on it", []),
    ("screenTimeServerAppLimitSet", "حد يومي للتطبيق", "A daily limit for this app",
     "SCR-FAT-032 app rules sheet — per-app limit field label", []),
    ("screenTimeServerAppLimitValue", "حد {minutes} دقيقة", "{minutes}-minute limit",
     "SCR-FAT-032 app rules sheet — the stored per-app limit",
     [("minutes", "int")]),
    ("screenTimeServerAppUnlimited", "بلا حد لهذا التطبيق", "No limit for this app",
     "SCR-FAT-032 app rules sheet — helper under the limit field", []),
    ("screenTimeServerAppUsed", "استهلك {minutes} دقيقة", "Used {minutes} minutes",
     "SCR-FAT-032 app rules sheet — today's minutes for one app",
     [("minutes", "int")]),
    ("screenTimeServerAppUnknown", "التطبيق غير معروف على هذا الهاتف بعد",
     "This app is not known on this phone yet",
     "SCR-FAT-032 app rules sheet — a rule for an app no handset reported", []),
    ("screenTimeServerAppSaveError", "رفض الخادم القرار — لم يتغير شيء",
     "The server refused the decision — nothing changed",
     "SCR-FAT-032 app rules sheet — a write that did not land", []),
    # ---------------------------------------------------------------- FAT-032 · categories
    ("screenTimeServerCategoryGames", "ألعاب", "Games",
     "SCR-FAT-032 app rules sheet — the games category", []),
    ("screenTimeServerCategorySocial", "تواصل", "Social",
     "SCR-FAT-032 app rules sheet — the social category", []),
    ("screenTimeServerCategoryVideo", "فيديو ويوتيوب", "Video and YouTube",
     "SCR-FAT-032 app rules sheet — the video category", []),
    ("screenTimeServerCategoryEducation", "تعليم", "Learning",
     "SCR-FAT-032 app rules sheet — the learning category", []),
    ("screenTimeServerCategoryOther", "أخرى", "Other",
     "SCR-FAT-032 app rules sheet — anything the phone reported without a category", []),
    ("screenTimeServerCategoryBlockAll", "احجب الفئة", "Block category",
     "SCR-FAT-032 app rules sheet — block every app in one category", []),
    ("screenTimeServerCategoryAllowAll", "اسمح للفئة", "Allow category",
     "SCR-FAT-032 app rules sheet — allow every app in one category", []),
    ("screenTimeServerCategoryApplied", "طبق على {count} تطبيق",
     "Applied to {count} apps",
     "SCR-FAT-032 app rules sheet — how many rules one category action wrote",
     [("count", "int")]),
    ("screenTimeServerCategoryBudget", "ميزانية الفئة اليومية",
     "Daily category budget",
     "SCR-FAT-032 app rules sheet — per-category minute budget field", []),
    ("screenTimeServerCategoryBudgetPending",
     "ميزانية الفئة تحتاج مساراً جديداً على الخادم",
     "A category budget needs a new route on the server",
     "SCR-FAT-032 app rules sheet — the contract a category budget waits on", []),
    # ---------------------------------------------------------------- FAT-032 · insights
    ("screenTimeServerInsightsTitle", "تحليل استهلاك اليوم", "Today's usage",
     "SCR-FAT-032 server panel — usage insights card title", []),
    ("screenTimeServerInsightsUsed", "المستهلك", "Used",
     "SCR-FAT-032 server panel — minutes used today", []),
    ("screenTimeServerInsightsCap", "حد اليوم", "Daily cap",
     "SCR-FAT-032 server panel — the cap today's minutes are read against", []),
    ("screenTimeServerInsightsGranted", "منح إضافية", "Extra granted",
     "SCR-FAT-032 server panel — minutes a guardian added to the cap", []),
    ("screenTimeServerInsightsTop", "أكثر التطبيقات استهلاكاً", "Most-used apps",
     "SCR-FAT-032 server panel — heading over the per-app bars", []),
    ("screenTimeServerInsightsNoUsage", "لا استهلاك مسجلاً اليوم",
     "No usage recorded today",
     "SCR-FAT-032 server panel — insights when the day is untouched", []),
    ("screenTimeServerInsightsOverCap", "تجاوز الاستهلاك حد اليوم",
     "Usage went past today's cap",
     "SCR-FAT-032 server panel — insights when used minutes exceed what was allowed", []),
    ("screenTimeServerInsightsShare", "{percent}% من وقت اليوم",
     "{percent}% of today's time",
     "SCR-FAT-032 server panel — one app's share of the day", [("percent", "int")]),
    ("screenTimeServerInsightsHint",
     "الأرقام كما حسابها الخادم اليوم، على ساعة الجهاز",
     "The numbers as the server counted them today, on the device clock",
     "SCR-FAT-032 server panel — insights footnote", []),
    # ---------------------------------------------------------------- FAT-032 · week schedule
    ("screenTimeServerWeekTitle", "جدول الأسبوع", "Week schedule",
     "SCR-FAT-032 server panel — week schedule card title", []),
    ("screenTimeServerWeekSchoolDays", "أيام وضع المدرسة", "School mode days",
     "SCR-FAT-032 server panel — heading over the school-day chips", []),
    ("screenTimeServerWeekWeekend", "عطلة الأسبوع", "Weekend",
     "SCR-FAT-032 server panel — the weekend group of days", []),
    ("screenTimeServerWeekWeekdays", "أيام الدراسة", "School days",
     "SCR-FAT-032 server panel — the weekday group of days", []),
    ("screenTimeServerWeekBedtimeHint",
     "الخادم يخزن نافذة نوم واحدة لكل الأيام حتى تُبنى نافذة للعطلة",
     "The server stores one bedtime window for every day until a weekend window is built",
     "SCR-FAT-032 server panel — bedtime window explanation", []),
    ("screenTimeServerWeekWeekendNote",
     "نافذة نوم منفصلة للعطلة تحتاج امتداداً في عقد الخادم",
     "A separate weekend bedtime window needs an extension of the server contract",
     "SCR-FAT-032 server panel — what the weekend bedtime waits on", []),
    ("screenTimeServerWeekSave", "احفظ أيام الأسبوع", "Save week days",
     "SCR-FAT-032 server panel — write the school-day set", []),
    ("screenTimeServerWeekBedtimeStart", "بداية النوم", "Bedtime starts",
     "SCR-FAT-032 server panel — pick the bedtime start", []),
    ("screenTimeServerWeekBedtimeEnd", "نهاية النوم", "Bedtime ends",
     "SCR-FAT-032 server panel — pick the bedtime end", []),
    ("screenTimeServerWeekWeekendBedtimeStart", "بداية نوم العطلة",
     "Weekend bedtime starts",
     "SCR-FAT-032 server panel — pick the weekend bedtime start", []),
    ("screenTimeServerWeekWeekendBedtimeEnd", "نهاية نوم العطلة",
     "Weekend bedtime ends",
     "SCR-FAT-032 server panel — pick the weekend bedtime end", []),
    ("screenTimeServerDaySat", "السبت", "Sat",
     "SCR-FAT-032 server panel — Saturday in the week editor", []),
    ("screenTimeServerDaySun", "الأحد", "Sun",
     "SCR-FAT-032 server panel — Sunday in the week editor", []),
    ("screenTimeServerDayMon", "الاثنين", "Mon",
     "SCR-FAT-032 server panel — Monday in the week editor", []),
    ("screenTimeServerDayTue", "الثلاثاء", "Tue",
     "SCR-FAT-032 server panel — Tuesday in the week editor", []),
    ("screenTimeServerDayWed", "الأربعاء", "Wed",
     "SCR-FAT-032 server panel — Wednesday in the week editor", []),
    ("screenTimeServerDayThu", "الخميس", "Thu",
     "SCR-FAT-032 server panel — Thursday in the week editor", []),
    ("screenTimeServerDayFri", "الجمعة", "Fri",
     "SCR-FAT-032 server panel — Friday in the week editor", []),
    # ---------------------------------------------------------------- FAT-032 · cap + earned merge
    ("screenTimeServerEarnedMinutesOnHint",
     "دقائق مهامك تُضاف إلى حد اليوم مباشرة",
     "Your task minutes go straight into today's cap",
     "SCR-FAT-032 server panel — earned-minutes switch on", []),
    ("screenTimeServerEarnedMinutesOffHint",
     "دقائق مهامك محفوظة لك ولا تُطيل حد اليوم",
     "Your task minutes are saved for you and do not extend today's cap",
     "SCR-FAT-032 server panel — earned-minutes switch off", []),
    ("screenTimeServerCapPresets", "اقتراحات سريعة", "Quick picks",
     "SCR-FAT-032 server panel — heading over the daily-cap quick picks", []),
    ("screenTimeServerCapUnlimited", "بلا حد", "No limit",
     "SCR-FAT-032 server panel — the zero-minute cap pick", []),
    ("screenTimeServerCapPresetValue", "{minutes} دقيقة", "{minutes} min",
     "SCR-FAT-032 server panel — one daily-cap quick pick", [("minutes", "int")]),
]


def dart_escape(value: str) -> str:
    """How gen-l10n escapes a message into a single-quoted Dart literal."""
    return value.replace("\\", "\\\\").replace("'", "\\'").replace('"', '\\"')


def dart_width(line: str) -> int:
    """Dart's own measure: UTF-16 code units."""
    return len(line.encode("utf-16-le")) // 2


def arb_entry(key: str, value: str, description: str, placeholders) -> str:
    lines = [f'  "{key}": {json.dumps(value, ensure_ascii=False)},']
    lines.append(f'  "@{key}": {{')
    described = f'    "description": {json.dumps(description, ensure_ascii=False)}'
    if placeholders:
        lines.append(described + ',')
        lines.append('    "placeholders": {')
        for index, (name, ptype) in enumerate(placeholders):
            lines.append(f'      "{name}": {{')
            lines.append(f'        "type": "{ptype}"')
            lines.append('      }'
                         + (',' if index < len(placeholders) - 1 else ''))
        lines.append('    }')
    else:
        lines.append(described)
    lines.append('  }')
    return "\n".join(lines)


def patch_arb(path: str, lang_index: int) -> None:
    source = open(path, encoding="utf-8").read()
    stripped = source.rstrip()
    assert stripped.endswith("}"), path
    body = stripped[:-1].rstrip()
    if body.endswith(","):
        body = body[:-1]
    entries = []
    for key, ar, en, description, placeholders in MESSAGES:
        value = ar if lang_index == 0 else en
        entries.append(arb_entry(key, value, description, placeholders))
    updated = body + ",\n" + ",\n".join(entries) + "\n}\n"
    open(path, "w", encoding="utf-8").write(updated)
    json.loads(open(path, encoding="utf-8").read())  # must stay valid JSON


def abstract_entry(key, ar, description, placeholders):
    if placeholders:
        args = ", ".join(f"{ptype} {name}" for name, ptype in placeholders)
        signature = f"  String {key}({args});"
    else:
        signature = f"  String get {key};"
    return "\n".join([
        f"  /// {description}",
        "  ///",
        "  /// In ar, this message translates to:",
        f"  /// **'{ar}'**",
        signature,
    ])


def language_entry(key, value, placeholders):
    if placeholders:
        body = value
        for name, _ in placeholders:
            body = body.replace("{" + name + "}", "$" + name)
        args = ", ".join(f"{ptype} {name}" for name, ptype in placeholders)
        return "\n".join([
            "  @override",
            f"  String {key}({args}) {{",
            f"    return '{dart_escape(body)}';",
            "  }",
        ])
    single = f"  String get {key} => '{dart_escape(value)}';"
    if dart_width(single) <= 80:
        return f"  @override\n{single}"
    return (f"  @override\n  String get {key} =>\n"
            f"      '{dart_escape(value)}';")


def patch_generated(path: str, block: str, marker: str) -> None:
    source = open(path, encoding="utf-8").read()
    if not source.endswith("\n"):
        source += "\n"
    idx = source.rindex(marker)
    updated = source[:idx].rstrip("\n") + "\n\n" + block.rstrip("\n") + "\n" \
        + source[idx:]
    open(path, "w", encoding="utf-8").write(updated)


def main() -> int:
    os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    patch_arb(os.path.join(ARB_DIR, "app_ar.arb"), 0)
    patch_arb(os.path.join(ARB_DIR, "app_en.arb"), 1)

    patch_generated(
        os.path.join(ARB_DIR, "app_localizations.dart"),
        "\n\n".join(abstract_entry(key, ar, description, placeholders)
                    for key, ar, _en, description, placeholders in MESSAGES),
        "}\n\nclass _AppLocalizationsDelegate",
    )
    patch_generated(
        os.path.join(ARB_DIR, "app_localizations_ar.dart"),
        "\n\n".join(language_entry(key, ar, placeholders)
                    for key, ar, _en, _d, placeholders in MESSAGES),
        "}\n",
    )
    patch_generated(
        os.path.join(ARB_DIR, "app_localizations_en.dart"),
        "\n\n".join(language_entry(key, en, placeholders)
                    for key, _ar, en, _d, placeholders in MESSAGES),
        "}\n",
    )
    print(f"added {len(MESSAGES)} messages to ARB + generated l10n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
