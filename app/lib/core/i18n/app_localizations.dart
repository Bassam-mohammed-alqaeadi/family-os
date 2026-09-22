import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'i18n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// Application display name
  ///
  /// In ar, this message translates to:
  /// **'عائلتي'**
  String get appTitle;

  /// Component gallery screen title
  ///
  /// In ar, this message translates to:
  /// **'معرض المكونات'**
  String get galleryTitle;

  /// Gallery intro under the app title
  ///
  /// In ar, this message translates to:
  /// **'رموز التصميم والمكوّنات الأساسية — وضع الأب / وضع الابن'**
  String get galleryHint;

  /// Gallery section: color swatches
  ///
  /// In ar, this message translates to:
  /// **'الألوان'**
  String get galleryColors;

  /// Gallery section: shadow samples
  ///
  /// In ar, this message translates to:
  /// **'الظلال'**
  String get galleryShadows;

  /// Gallery section: gradient strips
  ///
  /// In ar, this message translates to:
  /// **'التدرجات'**
  String get galleryGradients;

  /// Gallery section: corner radius chips
  ///
  /// In ar, this message translates to:
  /// **'الزوايا'**
  String get galleryRadii;

  /// Gallery section: font weight samples
  ///
  /// In ar, this message translates to:
  /// **'الخطوط'**
  String get galleryTypography;

  /// Gallery section: parent/child mode toggle
  ///
  /// In ar, this message translates to:
  /// **'وضع الواجهة'**
  String get galleryUiMode;

  /// Parent UI mode label
  ///
  /// In ar, this message translates to:
  /// **'أب'**
  String get galleryModeParent;

  /// Child UI mode label
  ///
  /// In ar, this message translates to:
  /// **'ابن'**
  String get galleryModeChild;

  /// Gallery section: PrimaryBtn variants
  ///
  /// In ar, this message translates to:
  /// **'الأزرار'**
  String get galleryButtons;

  /// Gallery section: AppCard
  ///
  /// In ar, this message translates to:
  /// **'البطاقات'**
  String get galleryCards;

  /// Gallery section: RowTile
  ///
  /// In ar, this message translates to:
  /// **'الصفوف'**
  String get galleryRows;

  /// Gallery section: Tag variants
  ///
  /// In ar, this message translates to:
  /// **'الوسوم'**
  String get galleryTags;

  /// Gallery section: BannerNote variants
  ///
  /// In ar, this message translates to:
  /// **'اللافتات'**
  String get galleryBanners;

  /// Gallery section: ProgressBar
  ///
  /// In ar, this message translates to:
  /// **'التقدّم'**
  String get galleryProgress;

  /// Gallery section: BottomSheetHost
  ///
  /// In ar, this message translates to:
  /// **'الورقة السفلية'**
  String get gallerySheet;

  /// Gallery section: AppToast
  ///
  /// In ar, this message translates to:
  /// **'الإشعار'**
  String get galleryToast;

  /// UI-008 SettingsPersistToggle failure inline copy (Rule 24)
  ///
  /// In ar, this message translates to:
  /// **'تعذر الحفظ — حاول مرة أخرى'**
  String get settingsPersistError;

  /// Gallery section: TabsBar
  ///
  /// In ar, this message translates to:
  /// **'التبويبات'**
  String get galleryTabs;

  /// Gallery section: HubGrid
  ///
  /// In ar, this message translates to:
  /// **'شبكة المحور'**
  String get galleryHub;

  /// No description provided for @galleryBtnPrimary.
  ///
  /// In ar, this message translates to:
  /// **'إجراء أساسي'**
  String get galleryBtnPrimary;

  /// No description provided for @galleryBtnTeal.
  ///
  /// In ar, this message translates to:
  /// **'إجراء تركواز'**
  String get galleryBtnTeal;

  /// No description provided for @galleryBtnSec.
  ///
  /// In ar, this message translates to:
  /// **'ثانوي'**
  String get galleryBtnSec;

  /// No description provided for @galleryBtnGhost.
  ///
  /// In ar, this message translates to:
  /// **'شفاف'**
  String get galleryBtnGhost;

  /// No description provided for @galleryBtnCoral.
  ///
  /// In ar, this message translates to:
  /// **'خطر'**
  String get galleryBtnCoral;

  /// No description provided for @galleryBtnDisabled.
  ///
  /// In ar, this message translates to:
  /// **'معطّل'**
  String get galleryBtnDisabled;

  /// No description provided for @galleryCardTitle.
  ///
  /// In ar, this message translates to:
  /// **'بطاقة تجريبية'**
  String get galleryCardTitle;

  /// No description provided for @galleryCardBody.
  ///
  /// In ar, this message translates to:
  /// **'نص البطاقة يطابق السطح والظل ونصف القطر في النموذج.'**
  String get galleryCardBody;

  /// No description provided for @galleryCardLink.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل'**
  String get galleryCardLink;

  /// No description provided for @galleryRowTitle1.
  ///
  /// In ar, this message translates to:
  /// **'تفقّد الصباح'**
  String get galleryRowTitle1;

  /// No description provided for @galleryRowSub1.
  ///
  /// In ar, this message translates to:
  /// **'اكتمل الساعة ٧:٣٠'**
  String get galleryRowSub1;

  /// No description provided for @galleryRowTitle2.
  ///
  /// In ar, this message translates to:
  /// **'دردشة العائلة'**
  String get galleryRowTitle2;

  /// No description provided for @galleryRowSub2.
  ///
  /// In ar, this message translates to:
  /// **'رسالتان جديدتان'**
  String get galleryRowSub2;

  /// No description provided for @galleryRowTitle3.
  ///
  /// In ar, this message translates to:
  /// **'وقت الدراسة'**
  String get galleryRowTitle3;

  /// No description provided for @galleryRowSub3.
  ///
  /// In ar, this message translates to:
  /// **'بقي ٤٥ دقيقة'**
  String get galleryRowSub3;

  /// No description provided for @galleryTagG.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get galleryTagG;

  /// No description provided for @galleryTagT.
  ///
  /// In ar, this message translates to:
  /// **'تركواز'**
  String get galleryTagT;

  /// No description provided for @galleryTagP.
  ///
  /// In ar, this message translates to:
  /// **'هوية'**
  String get galleryTagP;

  /// No description provided for @galleryTagA.
  ///
  /// In ar, this message translates to:
  /// **'انتباه'**
  String get galleryTagA;

  /// No description provided for @galleryBannerT.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة تركواز — إرشاد هادئ للعائلة.'**
  String get galleryBannerT;

  /// No description provided for @galleryBannerP.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة هوية — معلومات بخلفية بنفسجية.'**
  String get galleryBannerP;

  /// No description provided for @galleryBannerA.
  ///
  /// In ar, this message translates to:
  /// **'انتباه دافئ — لا تستخدم المرجان للتحذيرات.'**
  String get galleryBannerA;

  /// No description provided for @galleryOpenSheet.
  ///
  /// In ar, this message translates to:
  /// **'افتح الورقة'**
  String get galleryOpenSheet;

  /// No description provided for @gallerySheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'ورقة تجريبية'**
  String get gallerySheetTitle;

  /// No description provided for @gallerySheetClose.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get gallerySheetClose;

  /// No description provided for @galleryShowToast.
  ///
  /// In ar, this message translates to:
  /// **'أظهر إشعارًا'**
  String get galleryShowToast;

  /// No description provided for @galleryToastMessage.
  ///
  /// In ar, this message translates to:
  /// **'تم تنفيذ الإجراء بنجاح'**
  String get galleryToastMessage;

  /// No description provided for @galleryToastAction.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get galleryToastAction;

  /// No description provided for @galleryToastUndone.
  ///
  /// In ar, this message translates to:
  /// **'تم التراجع'**
  String get galleryToastUndone;

  /// No description provided for @tabParentToday.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get tabParentToday;

  /// No description provided for @tabParentKids.
  ///
  /// In ar, this message translates to:
  /// **'أبنائي'**
  String get tabParentKids;

  /// No description provided for @tabParentFamily.
  ///
  /// In ar, this message translates to:
  /// **'العائلة'**
  String get tabParentFamily;

  /// No description provided for @tabParentStudio.
  ///
  /// In ar, this message translates to:
  /// **'التعليم'**
  String get tabParentStudio;

  /// No description provided for @tabParentSettings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get tabParentSettings;

  /// No description provided for @tabChildMyDay.
  ///
  /// In ar, this message translates to:
  /// **'يومي'**
  String get tabChildMyDay;

  /// No description provided for @tabChildLearn.
  ///
  /// In ar, this message translates to:
  /// **'تعلّمي'**
  String get tabChildLearn;

  /// No description provided for @tabChildFamily.
  ///
  /// In ar, this message translates to:
  /// **'عائلتي'**
  String get tabChildFamily;

  /// No description provided for @tabChildMe.
  ///
  /// In ar, this message translates to:
  /// **'أنا'**
  String get tabChildMe;

  /// No description provided for @galleryHubItem1.
  ///
  /// In ar, this message translates to:
  /// **'المهام'**
  String get galleryHubItem1;

  /// No description provided for @galleryHubItem2.
  ///
  /// In ar, this message translates to:
  /// **'المحفظة'**
  String get galleryHubItem2;

  /// No description provided for @galleryHubItem3.
  ///
  /// In ar, this message translates to:
  /// **'الأوضاع'**
  String get galleryHubItem3;

  /// No description provided for @galleryHubItem4.
  ///
  /// In ar, this message translates to:
  /// **'التقارير'**
  String get galleryHubItem4;

  /// No description provided for @galleryHubItem5.
  ///
  /// In ar, this message translates to:
  /// **'الأجهزة'**
  String get galleryHubItem5;

  /// No description provided for @galleryHubItem6.
  ///
  /// In ar, this message translates to:
  /// **'المستشار'**
  String get galleryHubItem6;

  /// SCR-SHR-001 slide 0 emoji
  ///
  /// In ar, this message translates to:
  /// **'🦁'**
  String get welcomeSlide0Emoji;

  /// SCR-SHR-001 slide 0 title
  ///
  /// In ar, this message translates to:
  /// **'عائلتي'**
  String get welcomeSlide0Title;

  /// SCR-SHR-001 slide 0 body
  ///
  /// In ar, this message translates to:
  /// **'تطبيق واحد يجمع عائلتك: طمأنينة الوالد · تواصل دافئ · تعلّم ممتع'**
  String get welcomeSlide0Body;

  /// SCR-SHR-001 slide 1 emoji
  ///
  /// In ar, this message translates to:
  /// **'🗺️'**
  String get welcomeSlide1Emoji;

  /// SCR-SHR-001 slide 1 title
  ///
  /// In ar, this message translates to:
  /// **'اطمئن بلمحة'**
  String get welcomeSlide1Title;

  /// SCR-SHR-001 slide 1 body
  ///
  /// In ar, this message translates to:
  /// **'أين أبناؤك الآن؟ وصلوا بسلام؟ كل الطمأنينة في ٨ ثوانٍ صباحًا'**
  String get welcomeSlide1Body;

  /// SCR-SHR-001 slide 2 emoji
  ///
  /// In ar, this message translates to:
  /// **'📚'**
  String get welcomeSlide2Emoji;

  /// SCR-SHR-001 slide 2 title
  ///
  /// In ar, this message translates to:
  /// **'يتعلمون ويحبونه'**
  String get welcomeSlide2Title;

  /// SCR-SHR-001 slide 2 body
  ///
  /// In ar, this message translates to:
  /// **'وقت التعلم لا يُحسب من وقت اللعب — فيتحول الجهاز من خصم إلى معلّم'**
  String get welcomeSlide2Body;

  /// SCR-SHR-001 hint under dots when not on last slide
  ///
  /// In ar, this message translates to:
  /// **'انقر الدوائر للتالي'**
  String get welcomeDotsHint;

  /// SCR-SHR-001 hint under dots on last slide
  ///
  /// In ar, this message translates to:
  /// **'👍'**
  String get welcomeDotsDone;

  /// SCR-SHR-001 primary CTA → create account
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الآن'**
  String get welcomeStartCta;

  /// SCR-SHR-001 ghost CTA → login
  ///
  /// In ar, this message translates to:
  /// **'لديّ حساب — تسجيل الدخول'**
  String get welcomeLoginCta;

  /// SCR-SHR-001 legal footer — no data collection before choice
  ///
  /// In ar, this message translates to:
  /// **'بالمتابعة توافق على الشروط وسياسة الخصوصية'**
  String get welcomeLegal;

  /// SCR-SHR-001 accessible label for slide dots
  ///
  /// In ar, this message translates to:
  /// **'نقاط الشرائح — انقر للتالي'**
  String get welcomeDotsSemantics;

  /// SCR-SHR-001 live region for current slide
  ///
  /// In ar, this message translates to:
  /// **'شريحة {index} من {total}'**
  String welcomeSlideSemantics(int index, int total);

  /// SCR-SHR-002 AppBar title
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get createAccountTitle;

  /// SCR-SHR-002 step chip / subtitle
  ///
  /// In ar, this message translates to:
  /// **'خطوة ١ من ٢'**
  String get createAccountStep;

  /// SCR-SHR-002 email field label
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get createAccountEmailLabel;

  /// SCR-SHR-002 email placeholder
  ///
  /// In ar, this message translates to:
  /// **'abdullah@example.com'**
  String get createAccountEmailHint;

  /// SCR-SHR-002 password field label
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get createAccountPasswordLabel;

  /// SCR-SHR-002 password placeholder
  ///
  /// In ar, this message translates to:
  /// **'٨ أحرف على الأقل'**
  String get createAccountPasswordHint;

  /// SCR-SHR-002 confirm password label
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور'**
  String get createAccountConfirmLabel;

  /// SCR-SHR-002 confirm password placeholder
  ///
  /// In ar, this message translates to:
  /// **'أعد كتابتها'**
  String get createAccountConfirmHint;

  /// SCR-SHR-002 password strength <6 chars
  ///
  /// In ar, this message translates to:
  /// **'قصيرة — زدها'**
  String get createAccountStrengthWeak;

  /// SCR-SHR-002 password strength 6–9 chars
  ///
  /// In ar, this message translates to:
  /// **'جيدة'**
  String get createAccountStrengthGood;

  /// SCR-SHR-002 password strength ≥10 chars
  ///
  /// In ar, this message translates to:
  /// **'قوية ممتازة 💪'**
  String get createAccountStrengthStrong;

  /// SCR-SHR-002 terms checkbox label
  ///
  /// In ar, this message translates to:
  /// **'أوافق على الشروط وسياسة الخصوصية — لا إعلانات ولا بيع بيانات إطلاقًا.'**
  String get createAccountTerms;

  /// SCR-SHR-002 primary CTA
  ///
  /// In ar, this message translates to:
  /// **'إنشاء الحساب'**
  String get createAccountSubmit;

  /// SCR-SHR-002 footer ADR-003 note
  ///
  /// In ar, this message translates to:
  /// **'لا نطلب رقم هاتف — البريد يكفي (قرار ADR-003)'**
  String get createAccountNoPhoneNote;

  /// SCR-SHR-003 AppBar title
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get loginTitle;

  /// SCR-SHR-003 AppBar subtitle
  ///
  /// In ar, this message translates to:
  /// **'مرحبًا بعودتك'**
  String get loginSubtitle;

  /// SCR-SHR-003 email field label
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get loginEmailLabel;

  /// SCR-SHR-003 email placeholder
  ///
  /// In ar, this message translates to:
  /// **'abdullah@example.com'**
  String get loginEmailHint;

  /// SCR-SHR-003 password field label
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get loginPasswordLabel;

  /// SCR-SHR-003 password placeholder
  ///
  /// In ar, this message translates to:
  /// **'••••••••'**
  String get loginPasswordHint;

  /// SCR-SHR-003 forgot password link
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة المرور؟'**
  String get loginForgotLink;

  /// SCR-SHR-003 anti-enumeration forgot toast — always same
  ///
  /// In ar, this message translates to:
  /// **'أرسلنا رابط الاستعادة إن كان البريد مسجّلًا لدينا'**
  String get loginForgotToast;

  /// SCR-SHR-003 primary CTA
  ///
  /// In ar, this message translates to:
  /// **'دخول'**
  String get loginSubmit;

  /// SCR-SHR-003 biometric mock CTA — no Face ID APIs
  ///
  /// In ar, this message translates to:
  /// **'🔒 الدخول بالبصمة'**
  String get loginBiometric;

  /// SCR-SHR-003 biometric mock success toast
  ///
  /// In ar, this message translates to:
  /// **'تم الدخول بالبصمة'**
  String get loginBiometricToast;

  /// SCR-SHR-003 invite footer prompt
  ///
  /// In ar, this message translates to:
  /// **'وصلتك دعوة من عائلتك؟'**
  String get loginInvitePrompt;

  /// SCR-SHR-003 invite footer link → FAT-009
  ///
  /// In ar, this message translates to:
  /// **'ادخلي من رابط الدعوة ‹'**
  String get loginInviteLink;

  /// SCR-SHR-007 AppBar title
  ///
  /// In ar, this message translates to:
  /// **'من سيستخدم هذا الجهاز؟'**
  String get deviceModeTitle;

  /// SCR-SHR-007 AppBar subtitle — age-neutral
  ///
  /// In ar, this message translates to:
  /// **'شاشة محايدة'**
  String get deviceModeSubtitle;

  /// SCR-SHR-007 muted intro under header
  ///
  /// In ar, this message translates to:
  /// **'اختر بدقّة — هذا يحدد وضع التطبيق على هذا الجهاز.'**
  String get deviceModeIntro;

  /// SCR-SHR-007 guardian card emoji
  ///
  /// In ar, this message translates to:
  /// **'👑'**
  String get deviceModeGuardianEmoji;

  /// SCR-SHR-007 guardian card title
  ///
  /// In ar, this message translates to:
  /// **'أنا — وليّ الأمر'**
  String get deviceModeGuardianTitle;

  /// SCR-SHR-007 guardian card body
  ///
  /// In ar, this message translates to:
  /// **'أتابع أبنائي من هنا وأدير العائلة'**
  String get deviceModeGuardianBody;

  /// SCR-SHR-007 guardian card Semantics label
  ///
  /// In ar, this message translates to:
  /// **'أنا — وليّ الأمر. أتابع أبنائي من هنا وأدير العائلة'**
  String get deviceModeGuardianSemantics;

  /// SCR-SHR-007 child card emoji
  ///
  /// In ar, this message translates to:
  /// **'🧒'**
  String get deviceModeChildEmoji;

  /// SCR-SHR-007 child card title
  ///
  /// In ar, this message translates to:
  /// **'ابني'**
  String get deviceModeChildTitle;

  /// SCR-SHR-007 child card body
  ///
  /// In ar, this message translates to:
  /// **'هذا جهازه، وسيُربط بحساب وليّ أمره'**
  String get deviceModeChildBody;

  /// SCR-SHR-007 child card Semantics label
  ///
  /// In ar, this message translates to:
  /// **'ابني. هذا جهازه، وسيُربط بحساب وليّ أمره'**
  String get deviceModeChildSemantics;

  /// SCR-SHR-007 BannerNote.p leading glyph
  ///
  /// In ar, this message translates to:
  /// **'ℹ️'**
  String get deviceModeBannerLeading;

  /// SCR-SHR-007 BannerNote.p — no mother option (security)
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد خيار «أم» هنا — الأم تنضم بدعوة من لوحة الأب بمستوى صلاحية يحدده هو. ومن يضغط «وليّ الأمر» بلا دعوة ينشئ عائلة جديدة.'**
  String get deviceModeNoMotherBanner;

  /// SCR-FAT-001 AppBar title
  ///
  /// In ar, this message translates to:
  /// **'إنشاء العائلة'**
  String get createFamilyTitle;

  /// SCR-FAT-001 AppBar subtitle — creator is OWNER
  ///
  /// In ar, this message translates to:
  /// **'أنت المالك'**
  String get createFamilySubtitle;

  /// SCR-FAT-001 family name field label
  ///
  /// In ar, this message translates to:
  /// **'اسم العائلة'**
  String get createFamilyNameLabel;

  /// SCR-FAT-001 placeholder only — field starts empty (Rule 23)
  ///
  /// In ar, this message translates to:
  /// **'مثال: عائلة أحمد'**
  String get createFamilyNameHint;

  /// SCR-FAT-001 children count dropdown label
  ///
  /// In ar, this message translates to:
  /// **'كم ابنًا ستتابع؟'**
  String get createFamilyChildCountLabel;

  /// SCR-FAT-001 child count option: one
  ///
  /// In ar, this message translates to:
  /// **'ابن واحد'**
  String get createFamilyChildCountOne;

  /// SCR-FAT-001 child count option: two
  ///
  /// In ar, this message translates to:
  /// **'ابنان'**
  String get createFamilyChildCountTwo;

  /// SCR-FAT-001 child count option: three
  ///
  /// In ar, this message translates to:
  /// **'٣ أبناء'**
  String get createFamilyChildCountThree;

  /// SCR-FAT-001 child count option: four or more
  ///
  /// In ar, this message translates to:
  /// **'٤ فأكثر'**
  String get createFamilyChildCountFourPlus;

  /// SCR-FAT-001 BannerNote.g leading glyph
  ///
  /// In ar, this message translates to:
  /// **'🎁'**
  String get createFamilyBannerLeading;

  /// SCR-FAT-001 BannerNote.g free trial + SOS never gated
  ///
  /// In ar, this message translates to:
  /// **'تبدأ تجربتك المجانية الكاملة الآن — والاستغاثة والسلامة لا تُحجب أبدًا في أي باقة.'**
  String get createFamilyTrialBanner;

  /// SCR-FAT-001 primary CTA
  ///
  /// In ar, this message translates to:
  /// **'إنشاء العائلة'**
  String get createFamilySubmit;

  /// SCR-SHR-005 / AppErrorState network title (amber)
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الاتصال'**
  String get errorNetworkTitle;

  /// SCR-SHR-005 network body — prototype amber template
  ///
  /// In ar, this message translates to:
  /// **'لم نستطع الوصول للخادم. بياناتك المحفوظة ما زالت أمامك — أعد المحاولة عندما يكون الاتصال جاهزًا.'**
  String get errorNetworkMessage;

  /// SCR-SHR-005 timeout title — distinct from network
  ///
  /// In ar, this message translates to:
  /// **'انتهت مهلة الاتصال'**
  String get errorTimeoutTitle;

  /// SCR-SHR-005 timeout body — create-family edge
  ///
  /// In ar, this message translates to:
  /// **'استغرق الخادم وقتًا أطول من المتوقع. حاول إنشاء العائلة مرة أخرى.'**
  String get errorTimeoutMessage;

  /// SCR-SHR-005 4xx validation title — distinct copy
  ///
  /// In ar, this message translates to:
  /// **'تعذّر إنشاء العائلة'**
  String get errorValidationTitle;

  /// SCR-SHR-005 validation body — create-family 4xx
  ///
  /// In ar, this message translates to:
  /// **'تحقق من اسم العائلة وحاول مرة أخرى. إن استمر الخطأ، جرّب اسمًا مختلفًا.'**
  String get errorValidationMessage;

  /// SCR-SHR-005 offline / needs-network title
  ///
  /// In ar, this message translates to:
  /// **'يلزم اتصال بالإنترنت'**
  String get errorOfflineTitle;

  /// SCR-SHR-005 offline honesty — no fake queue (UI-001)
  ///
  /// In ar, this message translates to:
  /// **'إنشاء العائلة يحتاج اتصالًا نشطًا — لا يمكن حفظ الطلب دون اتصال.'**
  String get errorOfflineMessage;

  /// SCR-SHR-005 Retry CTA — Semantics label source
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get errorRetryCta;

  /// SCR-FAT-002 AppBar title
  ///
  /// In ar, this message translates to:
  /// **'إعداد عائلتك'**
  String get setupWizardTitle;

  /// SCR-FAT-002 AppBar subtitle — estimated time
  ///
  /// In ar, this message translates to:
  /// **'٤ دقائق'**
  String get setupWizardSubtitle;

  /// SCR-FAT-002 hero percent — mirrors mock UI progress const
  ///
  /// In ar, this message translates to:
  /// **'{percent}٪'**
  String setupWizardProgressHero(int percent);

  /// SCR-FAT-002 progress caption — suggestions not gates (UI-002)
  ///
  /// In ar, this message translates to:
  /// **'من الإعداد المقترح'**
  String get setupWizardProgressCaption;

  /// SCR-FAT-002 accessible label for cached suggestion progress
  ///
  /// In ar, this message translates to:
  /// **'التقدّم المقترح {percent} بالمئة من الإعداد'**
  String setupWizardProgressSemantics(int percent);

  /// SCR-FAT-002 checklist row 1 title — done
  ///
  /// In ar, this message translates to:
  /// **'إنشاء الحساب والعائلة'**
  String get setupWizardStepAccountTitle;

  /// SCR-FAT-002 checklist row 1 subtitle — completed
  ///
  /// In ar, this message translates to:
  /// **'تمّ'**
  String get setupWizardStepAccountSubtitle;

  /// SCR-FAT-002 pending suggestion row subtitle (UI-002)
  ///
  /// In ar, this message translates to:
  /// **'مقترح عندما تكون جاهزًا'**
  String get setupWizardStepSuggestedPending;

  /// SCR-FAT-002 checklist row 2 title
  ///
  /// In ar, this message translates to:
  /// **'إضافة أول ابن وربط جهازه'**
  String get setupWizardStepAddChildTitle;

  /// SCR-FAT-002 add-child — suggestion tone (UI-002)
  ///
  /// In ar, this message translates to:
  /// **'مقترح · ~ دقيقتان'**
  String get setupWizardStepAddChildSubtitle;

  /// SCR-FAT-002 Tag.a on add-child row — suggestion not gate
  ///
  /// In ar, this message translates to:
  /// **'الأهم الآن'**
  String get setupWizardStepAddChildTag;

  /// SCR-FAT-002 checklist row 3 title
  ///
  /// In ar, this message translates to:
  /// **'دعوة الأم'**
  String get setupWizardStepInviteTitle;

  /// SCR-FAT-002 invite mother — optional suggestion (doc 20 / UI-002)
  ///
  /// In ar, this message translates to:
  /// **'مقترح لتطمئن معك — اختياري'**
  String get setupWizardStepInviteSubtitle;

  /// SCR-FAT-002 checklist row 4 title
  ///
  /// In ar, this message translates to:
  /// **'إعداد جهات الطوارئ'**
  String get setupWizardStepSosTitle;

  /// SCR-FAT-002 SOS row — suggestion tone (UI-002)
  ///
  /// In ar, this message translates to:
  /// **'مقترح · دقيقة واحدة'**
  String get setupWizardStepSosSubtitle;

  /// SCR-FAT-002 ghost CTA — always available; never gated
  ///
  /// In ar, this message translates to:
  /// **'أكمل لاحقًا — إلى لوحة اليوم'**
  String get setupWizardSkipLater;

  /// SCR-FAT-003 AppBar title
  ///
  /// In ar, this message translates to:
  /// **'إضافة ابن'**
  String get addChildTitle;

  /// SCR-FAT-003 AppBar subtitle — step 1 of 3
  ///
  /// In ar, this message translates to:
  /// **'١ من ٣'**
  String get addChildStep;

  /// SCR-FAT-003 name field label
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get addChildNameLabel;

  /// SCR-FAT-003 placeholder only — field starts empty (Rule 23 / G8)
  ///
  /// In ar, this message translates to:
  /// **'الاسم الأول'**
  String get addChildNameHint;

  /// SCR-FAT-003 age dropdown label
  ///
  /// In ar, this message translates to:
  /// **'العمر'**
  String get addChildAgeLabel;

  /// SCR-FAT-003 age option label — years already localized digits
  ///
  /// In ar, this message translates to:
  /// **'{years} سنة'**
  String addChildAgeYears(String years);

  /// SCR-FAT-003 character emoji picker label
  ///
  /// In ar, this message translates to:
  /// **'شخصيته المفضلة'**
  String get addChildCharacterLabel;

  /// SCR-FAT-003 kid color picker label
  ///
  /// In ar, this message translates to:
  /// **'لونه في التطبيق'**
  String get addChildColorLabel;

  /// SCR-FAT-003 accessible name for a color swatch
  ///
  /// In ar, this message translates to:
  /// **'لون الفرد {index}'**
  String addChildColorSwatchSemantics(int index);

  /// SCR-FAT-003 primary CTA → FAT-004
  ///
  /// In ar, this message translates to:
  /// **'متابعة — رمز الربط'**
  String get addChildContinue;

  /// SCR-FAT-003 footer before LTR mock alias
  ///
  /// In ar, this message translates to:
  /// **'هويته في التحليلات: '**
  String get addChildAliasPrefix;

  /// SCR-FAT-003 footer after LTR mock alias
  ///
  /// In ar, this message translates to:
  /// **' — اسمه لا يغادر العائلة'**
  String get addChildAliasSuffix;

  /// SCR-FAT-003 accessible full alias footer
  ///
  /// In ar, this message translates to:
  /// **'هويته في التحليلات {alias} — اسمه لا يغادر العائلة'**
  String addChildAliasSemantics(String alias);

  /// SCR-FAT-004 header title (parametric — no child name)
  ///
  /// In ar, this message translates to:
  /// **'اربط جهازه'**
  String get linkQrTitle;

  /// SCR-FAT-004 step indicator
  ///
  /// In ar, this message translates to:
  /// **'٢ من ٣'**
  String get linkQrStep;

  /// SCR-FAT-004 muted instruction lead
  ///
  /// In ar, this message translates to:
  /// **'على جهازه: '**
  String get linkQrInstructionPrefix;

  /// SCR-FAT-004 mandatory bold instruction (wave-1 / parametric)
  ///
  /// In ar, this message translates to:
  /// **'حمّل نفس التطبيق «عائلتي»، واختر «ابني»، وامسح هذا الرمز.'**
  String get linkQrInstructionBold;

  /// SCR-FAT-004 QR area semantics label
  ///
  /// In ar, this message translates to:
  /// **'رمز الربط QR'**
  String get linkQrSemantics;

  /// SCR-FAT-004 timer line before mm:ss
  ///
  /// In ar, this message translates to:
  /// **'⏱ الرمز صالح '**
  String get linkQrTimerLead;

  /// SCR-FAT-004 timer line after mm:ss (single-use)
  ///
  /// In ar, this message translates to:
  /// **' · استخدام واحد فقط'**
  String get linkQrTimerTrail;

  /// SCR-FAT-004 expired pairing token (UF-01 rotate)
  ///
  /// In ar, this message translates to:
  /// **'⛔ انتهت صلاحية الرمز — جدّده'**
  String get linkQrExpired;

  /// SCR-FAT-004 primary CTA → FAT-005
  ///
  /// In ar, this message translates to:
  /// **'تمّ المسح على جهازه ← متابعة'**
  String get linkQrContinue;

  /// SCR-FAT-004 renew pairing token
  ///
  /// In ar, this message translates to:
  /// **'تجديد الرمز'**
  String get linkQrRenew;

  /// SCR-FAT-004 toast after renew
  ///
  /// In ar, this message translates to:
  /// **'✓ وُلّد رمز جديد — القديم أُبطل والعداد بدأ من جديد'**
  String get linkQrRenewToast;

  /// SCR-FAT-004 ghost CTA → trial FAT-007
  ///
  /// In ar, this message translates to:
  /// **'جهازه ليس معي الآن — جرّب التطبيق أولًا'**
  String get linkQrTrial;

  /// SCR-FAT-005 header title
  ///
  /// In ar, this message translates to:
  /// **'لماذا هذه الأذونات؟'**
  String get permissionsExplainerTitle;

  /// SCR-FAT-005 step indicator
  ///
  /// In ar, this message translates to:
  /// **'٣ من ٣'**
  String get permissionsExplainerStep;

  /// SCR-FAT-005 mock video card title (Rule 23 — جهازه)
  ///
  /// In ar, this message translates to:
  /// **'فيديو: ماذا سيطلب جهازه؟ (٩٠ ثانية)'**
  String get permissionsExplainerVideoTitle;

  /// SCR-FAT-005 video card semantics button label
  ///
  /// In ar, this message translates to:
  /// **'تشغيل فيديو شرح الأذونات'**
  String get permissionsExplainerVideoSemantics;

  /// SCR-FAT-005 mock video tap toast
  ///
  /// In ar, this message translates to:
  /// **'الفيديو قريبًا — هذا عرض تجريبي'**
  String get permissionsExplainerVideoToast;

  /// SCR-FAT-005 location permission title
  ///
  /// In ar, this message translates to:
  /// **'الموقع «طوال الوقت»'**
  String get permissionsExplainerLocationTitle;

  /// SCR-FAT-005 location WHY (G-3)
  ///
  /// In ar, this message translates to:
  /// **'ليصلك مكانه وتنبيهات المناطق الآمنة — نطلبه بعد أول قيمة، لا فورًا'**
  String get permissionsExplainerLocationWhy;

  /// SCR-FAT-005 accessibility permission title
  ///
  /// In ar, this message translates to:
  /// **'خدمة إمكانية الوصول'**
  String get permissionsExplainerA11yTitle;

  /// SCR-FAT-005 accessibility WHY (G-3)
  ///
  /// In ar, this message translates to:
  /// **'للحجب الفوري فقط — وقياس الوقت لا يحتاجها أصلًا'**
  String get permissionsExplainerA11yWhy;

  /// SCR-FAT-005 battery exemption title
  ///
  /// In ar, this message translates to:
  /// **'استثناء البطارية'**
  String get permissionsExplainerBatteryTitle;

  /// SCR-FAT-005 battery WHY (Rule 23 — جهازه)
  ///
  /// In ar, this message translates to:
  /// **'حتى لا يقتل نظام التوفير اتصالنا بجهازه'**
  String get permissionsExplainerBatteryWhy;

  /// SCR-FAT-005 rule-3 amber banner (refusal never locks)
  ///
  /// In ar, this message translates to:
  /// **'✋ إن رُفض أي إذن لن تُقفل أي شاشة — سيعمل البديل ونعرض بطاقة استعادة. (القاعدة ٣)'**
  String get permissionsExplainerBanner;

  /// SCR-FAT-005 primary CTA → FAT-006
  ///
  /// In ar, this message translates to:
  /// **'فهمت — أكمل الربط'**
  String get permissionsExplainerContinue;

  /// SCR-FAT-006 AppBar title
  ///
  /// In ar, this message translates to:
  /// **'تمّ الربط!'**
  String get linkSuccessTitle;

  /// SCR-FAT-006 AppBar subtitle — mock counts (Eastern digits)
  ///
  /// In ar, this message translates to:
  /// **'١ من ٣ أبناء'**
  String get linkSuccessStep;

  /// SCR-FAT-006 celebration title — Rule 23 generic ابنك
  ///
  /// In ar, this message translates to:
  /// **'جهاز ابنك متصل الآن'**
  String get linkSuccessHeroTitle;

  /// SCR-FAT-006 celebration when display name injected
  ///
  /// In ar, this message translates to:
  /// **'جهاز {name} متصل الآن'**
  String linkSuccessHeroTitleNamed(String name);

  /// SCR-FAT-006 muted lead into mini map
  ///
  /// In ar, this message translates to:
  /// **'وهذه أول ثمرة — موقعه الآن:'**
  String get linkSuccessFirstFruit;

  /// SCR-FAT-006 mini map Semantics label
  ///
  /// In ar, this message translates to:
  /// **'معاينة الموقع الحالي'**
  String get linkSuccessMapSemantics;

  /// SCR-FAT-006 location card title (mock)
  ///
  /// In ar, this message translates to:
  /// **'📍 ثانوية النور — حي النرجس'**
  String get linkSuccessLocationTitle;

  /// SCR-FAT-006 location meta (mock Eastern digits)
  ///
  /// In ar, this message translates to:
  /// **'آخر تحديث: الآن · البطارية ٨٤٪'**
  String get linkSuccessLocationMeta;

  /// SCR-FAT-006 age template card title
  ///
  /// In ar, this message translates to:
  /// **'⚡ اختصر الطريق — قالب عمره جاهز'**
  String get linkSuccessTemplateTitle;

  /// SCR-FAT-006 age template body — Rule 23 no child name
  ///
  /// In ar, this message translates to:
  /// **'قالب «١٤–١٧» يضبط: ٤ ساعات، فلترة مناسبة، نوم ١٠:٣٠. وتصقله متى شئت.'**
  String get linkSuccessTemplateBody;

  /// SCR-FAT-006 apply age template CTA
  ///
  /// In ar, this message translates to:
  /// **'طبّق القالب (موصى به)'**
  String get linkSuccessApplyTemplate;

  /// SCR-FAT-006 manual adjust ghost CTA
  ///
  /// In ar, this message translates to:
  /// **'أضبط كل شيء يدويًا'**
  String get linkSuccessManual;

  /// SCR-FAT-006 toast after applying template
  ///
  /// In ar, this message translates to:
  /// **'✓ ضُبط على قالب ١٤–١٧'**
  String get linkSuccessApplyToast;

  /// SCR-FAT-006 toast for manual path (جهازه / ملفه)
  ///
  /// In ar, this message translates to:
  /// **'تمام — تضبط كل أداة بنفسك من ملفه'**
  String get linkSuccessManualToast;

  /// SCR-FAT-006 applied BannerNote.g — no child name
  ///
  /// In ar, this message translates to:
  /// **'✓ قالب «١٤–١٧» مطبق: ٤ ساعات · فلترة متوازنة · نوم ١٠:٣٠'**
  String get linkSuccessTemplateApplied;

  /// SCR-FAT-006 undo applied template
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get linkSuccessTemplateUndo;

  /// SCR-FAT-006 next-child card title
  ///
  /// In ar, this message translates to:
  /// **'👦 بقي اثنان من أبنائك'**
  String get linkSuccessNextChildTitle;

  /// SCR-FAT-006 next-child body — جهازه wording
  ///
  /// In ar, this message translates to:
  /// **'قلتَ إنك ستتابع ٣ أبناء — أضف التالي وجهازه أمامك، أو أجّل من دون قلق.'**
  String get linkSuccessNextChildBody;

  /// SCR-FAT-006 add next child CTA → FAT-003
  ///
  /// In ar, this message translates to:
  /// **'+ أضف الابن التالي (٢ من ٣)'**
  String get linkSuccessAddNext;

  /// SCR-FAT-006 toast before navigating to FAT-003
  ///
  /// In ar, this message translates to:
  /// **'نبدأ بابنك التالي 👦'**
  String get linkSuccessAddNextToast;

  /// SCR-FAT-006 mint CTA → FAT-010
  ///
  /// In ar, this message translates to:
  /// **'إلى لوحة اليوم — أكمل البقية لاحقًا'**
  String get linkSuccessDayBoard;

  /// SCR-FAT-007 AppBar title
  ///
  /// In ar, this message translates to:
  /// **'وضع التجربة'**
  String get trialModeTitle;

  /// SCR-FAT-007 AppBar subtitle — permanent trial strip label
  ///
  /// In ar, this message translates to:
  /// **'بيانات تجريبية'**
  String get trialModeSubtitle;

  /// SCR-FAT-007 BannerNote.a — intentional demo child «تجريبي»
  ///
  /// In ar, this message translates to:
  /// **'🧪 هذه بيانات تجريبية لابن افتراضي اسمه «تجريبي» — كل شيء يعمل، ولا شيء حقيقي. اربط جهازًا حقيقيًا متى شئت.'**
  String get trialModeBanner;

  /// SCR-FAT-007 demo avatar initial
  ///
  /// In ar, this message translates to:
  /// **'ت'**
  String get trialModeAvatarLetter;

  /// SCR-FAT-007 demo child name + age (Eastern digits)
  ///
  /// In ar, this message translates to:
  /// **'تجريبي — ١٢ سنة'**
  String get trialModeChildTitle;

  /// SCR-FAT-007 demo location + battery (Eastern digits)
  ///
  /// In ar, this message translates to:
  /// **'📍 المدرسة الافتراضية · 🔋 ٧٧٪'**
  String get trialModeChildMeta;

  /// SCR-FAT-007 demo time remaining (Eastern digits)
  ///
  /// In ar, this message translates to:
  /// **'⏱ المتبقي: ٢ س ١٥ د'**
  String get trialModeRemaining;

  /// SCR-FAT-007 demo minutes budget (Eastern digits)
  ///
  /// In ar, this message translates to:
  /// **'⏱ ١٨٠ دقيقة'**
  String get trialModeMinutes;

  /// SCR-FAT-007 try-these AppCard title
  ///
  /// In ar, this message translates to:
  /// **'ماذا تستطيع أن تجرّب؟'**
  String get trialModeTryTitle;

  /// SCR-FAT-007 map RowTile → FAT-014
  ///
  /// In ar, this message translates to:
  /// **'الخريطة والمناطق الآمنة'**
  String get trialModeMapRow;

  /// SCR-FAT-007 advisor RowTile → FAT-011
  ///
  /// In ar, this message translates to:
  /// **'اقتراحات مستشار العائلة'**
  String get trialModeAdvisorRow;

  /// SCR-FAT-007 PrimaryBtn → FAT-004
  ///
  /// In ar, this message translates to:
  /// **'اربط جهازًا حقيقيًا الآن'**
  String get trialModeLinkCta;

  /// SCR-FAT-008 AppBar title
  ///
  /// In ar, this message translates to:
  /// **'🤍 ادعُ الأم'**
  String get inviteMotherTitle;

  /// SCR-FAT-008 muted intro
  ///
  /// In ar, this message translates to:
  /// **'تطمئن معك على الأبناء — وأنت تحدد مستواها وتغيّره متى شئت.'**
  String get inviteMotherIntro;

  /// SCR-FAT-008 email field label
  ///
  /// In ar, this message translates to:
  /// **'بريدها الإلكتروني'**
  String get inviteMotherEmailLabel;

  /// SCR-FAT-008 email placeholder — no person name (Rule 23)
  ///
  /// In ar, this message translates to:
  /// **'email@example.com'**
  String get inviteMotherEmailHint;

  /// SCR-FAT-008 level مطّلعة title
  ///
  /// In ar, this message translates to:
  /// **'مطّلعة'**
  String get inviteMotherLevelObserverTitle;

  /// SCR-FAT-008 level مطّلعة description
  ///
  /// In ar, this message translates to:
  /// **'ترى كل شيء وتطمئن وتُخطرك'**
  String get inviteMotherLevelObserverDesc;

  /// SCR-FAT-008 level مشاركة title (default)
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get inviteMotherLevelPartnerTitle;

  /// SCR-FAT-008 level مشاركة description
  ///
  /// In ar, this message translates to:
  /// **'وتوافق على طلبات الأبناء وتمنح وقتًا إضافيًا أيضًا'**
  String get inviteMotherLevelPartnerDesc;

  /// SCR-FAT-008 level كاملة title
  ///
  /// In ar, this message translates to:
  /// **'كاملة'**
  String get inviteMotherLevelFullTitle;

  /// SCR-FAT-008 level كاملة description
  ///
  /// In ar, this message translates to:
  /// **'وتعدّل القواعد والحدود معك'**
  String get inviteMotherLevelFullDesc;

  /// SCR-FAT-008 Tag.g on default مشاركة level
  ///
  /// In ar, this message translates to:
  /// **'موصى به'**
  String get inviteMotherRecommendedTag;

  /// SCR-FAT-008 BannerNote.p leading glyph
  ///
  /// In ar, this message translates to:
  /// **'🔴'**
  String get inviteMotherBannerLeading;

  /// SCR-FAT-008 BannerNote.p fixed SOS rights
  ///
  /// In ar, this message translates to:
  /// **'بأي مستوى: تستقبل الاستغاثة وتتصل بالأبناء وترى مواقعهم — هذه حقوق لا تخضع للتدرّج.'**
  String get inviteMotherBanner;

  /// SCR-FAT-008 PrimaryBtn send invite
  ///
  /// In ar, this message translates to:
  /// **'أرسل الدعوة'**
  String get inviteMotherSubmit;

  /// SCR-FAT-008 success toast — email local-part only (Rule 23)
  ///
  /// In ar, this message translates to:
  /// **'أُرسلت الدعوة إلى {localPart} بمستوى «{level}» ✓'**
  String inviteMotherToast(String localPart, String level);

  /// SCR-FAT-009 AppBar title
  ///
  /// In ar, this message translates to:
  /// **'دعوة انضمام'**
  String get acceptMotherInviteTitle;

  /// SCR-FAT-009 AppBar subtitle
  ///
  /// In ar, this message translates to:
  /// **'ما تراه الأم'**
  String get acceptMotherInviteSubtitle;

  /// SCR-FAT-009 big heart glyph
  ///
  /// In ar, this message translates to:
  /// **'🤍'**
  String get acceptMotherInviteHeart;

  /// SCR-FAT-009 heart Semantics label
  ///
  /// In ar, this message translates to:
  /// **'دعوة انضمام للعائلة'**
  String get acceptMotherInviteHeartSemantics;

  /// SCR-FAT-009 centered invite headline (Rule 23 placeholders)
  ///
  /// In ar, this message translates to:
  /// **'{inviter} يدعوك للانضمام إلى «{family}»'**
  String acceptMotherInviteHeadline(String inviter, String family);

  /// SCR-FAT-009 generic inviter when constructor empty (Rule 23)
  ///
  /// In ar, this message translates to:
  /// **'ولي الأمر'**
  String get acceptMotherInviteInviterFallback;

  /// SCR-FAT-009 generic family when constructor empty (Rule 23)
  ///
  /// In ar, this message translates to:
  /// **'العائلة'**
  String get acceptMotherInviteFamilyFallback;

  /// SCR-FAT-009 granted-level RowTile leading
  ///
  /// In ar, this message translates to:
  /// **'🎚️'**
  String get acceptMotherInviteLevelEmoji;

  /// SCR-FAT-009 granted level title — display only
  ///
  /// In ar, this message translates to:
  /// **'مستواك: {level}'**
  String acceptMotherInviteLevelTitle(String level);

  /// SCR-FAT-009 mother-facing مطّلعة meaning
  ///
  /// In ar, this message translates to:
  /// **'ترين كل شيء · تطمئنين · تُخطَرين'**
  String get acceptMotherInviteLevelObserverMeaning;

  /// SCR-FAT-009 mother-facing مشاركة meaning (default)
  ///
  /// In ar, this message translates to:
  /// **'ترين كل شيء · توافقين على الطلبات · تمنحين وقتًا إضافيًا'**
  String get acceptMotherInviteLevelPartnerMeaning;

  /// SCR-FAT-009 mother-facing كاملة meaning
  ///
  /// In ar, this message translates to:
  /// **'ترين كل شيء · توافقين · تعدّلين القواعد مع الأب'**
  String get acceptMotherInviteLevelFullMeaning;

  /// SCR-FAT-009 fixed-rights RowTile leading
  ///
  /// In ar, this message translates to:
  /// **'🔴'**
  String get acceptMotherInviteRightsEmoji;

  /// SCR-FAT-009 fixed rights title
  ///
  /// In ar, this message translates to:
  /// **'حقوقك الثابتة'**
  String get acceptMotherInviteRightsTitle;

  /// SCR-FAT-009 fixed SOS/call/location rights
  ///
  /// In ar, this message translates to:
  /// **'الاستغاثة تصلك · تتصلين بالأبناء · ترين مواقعهم — دائمًا'**
  String get acceptMotherInviteRightsSubtitle;

  /// SCR-FAT-009 PrimaryBtn accept → mother role + FAT-028
  ///
  /// In ar, this message translates to:
  /// **'قبول والانضمام'**
  String get acceptMotherInviteAccept;

  /// SCR-FAT-009 PrimaryBtn.ghost decline → SHR-001
  ///
  /// In ar, this message translates to:
  /// **'ليس الآن'**
  String get acceptMotherInviteDecline;

  /// SCR-FAT-009 welcome toast with invitee first name
  ///
  /// In ar, this message translates to:
  /// **'🌸 أهلًا {invitee} — أنتِ الآن شريكة التوجيه بمستوى «{level}»'**
  String acceptMotherInviteWelcomeToast(String invitee, String level);

  /// SCR-FAT-009 welcome toast without invitee name
  ///
  /// In ar, this message translates to:
  /// **'🌸 أهلًا — أنتِ الآن شريكة التوجيه بمستوى «{level}»'**
  String acceptMotherInviteWelcomeToastGeneric(String level);

  /// SCR-FAT-009 decline toast — invite valid a week
  ///
  /// In ar, this message translates to:
  /// **'لا بأس — تبقى الدعوة صالحة أسبوعًا، و{inviter} يستطيع تذكيرك'**
  String acceptMotherInviteDeclineToast(String inviter);

  /// Gallery sample for BannerNote.g (mint)
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة نعناع — تجربة مجانية وسلامة لا تُحجب.'**
  String get galleryBannerG;

  /// SCR-FAT-010 AppBar title
  ///
  /// In ar, this message translates to:
  /// **'لوحة اليوم'**
  String get dayBoardTitle;

  /// SCR-FAT-010 bare shell note (no bottom tabs OK)
  ///
  /// In ar, this message translates to:
  /// **'هيكل بدون تبويبات — مرحلة ١'**
  String get dayBoardShellNote;

  /// SCR-FAT-010 mock sync line
  ///
  /// In ar, this message translates to:
  /// **'☁️ آخر مزامنة: {time} — يعمل دون إنترنت ويُحدّث عند الاتصال'**
  String dayBoardSyncLine(String time);

  /// SCR-FAT-010 default mock sync age
  ///
  /// In ar, this message translates to:
  /// **'منذ دقيقة'**
  String get dayBoardSyncMockTime;

  /// SCR-FAT-010 greeting — parametric name (Rule 23)
  ///
  /// In ar, this message translates to:
  /// **'صباح الخير {name} 👋'**
  String dayBoardGreeting(String name);

  /// SCR-FAT-010 generic guardian when constructor empty (Rule 23)
  ///
  /// In ar, this message translates to:
  /// **'ولي الأمر'**
  String get dayBoardGuardianFallback;

  /// SCR-FAT-010 muted greeting subtitle
  ///
  /// In ar, this message translates to:
  /// **'أبناؤك بخير وبأمان تام اليوم'**
  String get dayBoardGreetingSub;

  /// SCR-FAT-010 family pulse avatar row label
  ///
  /// In ar, this message translates to:
  /// **'نبض العائلة'**
  String get dayBoardPulseLabel;

  /// SCR-FAT-010 active child card title
  ///
  /// In ar, this message translates to:
  /// **'{name} ({age} سنة)'**
  String dayBoardChildTitle(String name, int age);

  /// SCR-FAT-010 active child location·battery line
  ///
  /// In ar, this message translates to:
  /// **'📍 {location} · 🔋 {battery} متصل'**
  String dayBoardLocationBattery(String location, String battery);

  /// SCR-FAT-010 Tag.g active now
  ///
  /// In ar, this message translates to:
  /// **'نشط الآن'**
  String get dayBoardActiveTag;

  /// SCR-FAT-010 active child time-left stat
  ///
  /// In ar, this message translates to:
  /// **'⏱️ المتبقي: {value}'**
  String dayBoardStatTimeLeft(String value);

  /// SCR-FAT-010 active child quran stat
  ///
  /// In ar, this message translates to:
  /// **'📖 ورد القرآن: {value}'**
  String dayBoardStatQuran(String value);

  /// SCR-FAT-010 active child wallet stat
  ///
  /// In ar, this message translates to:
  /// **'⏱ محفظته: {value}'**
  String dayBoardStatWallet(String value);

  /// SCR-FAT-010 quick follow services card title
  ///
  /// In ar, this message translates to:
  /// **'خدمات المتابعة السريعة'**
  String get dayBoardQuickTitle;

  /// SCR-FAT-010 link to children list FAT-012
  ///
  /// In ar, this message translates to:
  /// **'كل الأبناء ←'**
  String get dayBoardAllChildren;

  /// SCR-FAT-010 quick grid Quran → FAT-072
  ///
  /// In ar, this message translates to:
  /// **'القرآن'**
  String get dayBoardQuickQuran;

  /// SCR-FAT-010 quick grid tasks → FAT-054
  ///
  /// In ar, this message translates to:
  /// **'المهام'**
  String get dayBoardQuickTasks;

  /// SCR-FAT-010 quick grid lock → FAT-037
  ///
  /// In ar, this message translates to:
  /// **'القفل'**
  String get dayBoardQuickLock;

  /// SCR-FAT-010 quick grid map → FAT-014
  ///
  /// In ar, this message translates to:
  /// **'الخريطة'**
  String get dayBoardQuickMap;

  /// SCR-FAT-010 importance ladder section heading
  ///
  /// In ar, this message translates to:
  /// **'الأهم الآن'**
  String get dayBoardPrioritySection;

  /// SCR-FAT-010 fallback priority title — prefer projection copy (UI-004)
  ///
  /// In ar, this message translates to:
  /// **'طلب معلّق'**
  String get dayBoardPriorityTitle;

  /// SCR-FAT-010 fallback priority subtitle (UI-004)
  ///
  /// In ar, this message translates to:
  /// **'افتح صندوق الطلبات لتقرر'**
  String get dayBoardPrioritySubtitle;

  /// SCR-FAT-010 Tag.a on priority card
  ///
  /// In ar, this message translates to:
  /// **'قرار الوالد ←'**
  String get dayBoardPriorityTag;

  /// SCR-FAT-010 advisor BannerNote.p (AI Serves, Not Decides)
  ///
  /// In ar, this message translates to:
  /// **'مستشار العائلة يقترح — وأنت تقرر. لا شيء يُطبَّق من تلقاء نفسه.'**
  String get dayBoardAdvisorBanner;

  /// SCR-FAT-010 PrimaryBtn.ghost → FAT-011 suggest-only (UI-004)
  ///
  /// In ar, this message translates to:
  /// **'عرض الاقتراحات'**
  String get dayBoardAdvisorCta;

  /// SCR-FAT-032 app bar title
  ///
  /// In ar, this message translates to:
  /// **'وقت الشاشة'**
  String get childScreenTimeTitle;

  /// SCR-FAT-032 ControlFit subtitle
  ///
  /// In ar, this message translates to:
  /// **'نوافذ زمنية للنوم والصلاة والمذاكرة — ليست مفاتيح شكلية فقط'**
  String get childScreenTimeSubtitle;

  /// SCR-FAT-032 sleep schedule row
  ///
  /// In ar, this message translates to:
  /// **'نوم'**
  String get childScreenTimeSleep;

  /// SCR-FAT-032 prayer schedule row
  ///
  /// In ar, this message translates to:
  /// **'صلاة'**
  String get childScreenTimePrayer;

  /// SCR-FAT-032 study schedule row
  ///
  /// In ar, this message translates to:
  /// **'مذاكرة'**
  String get childScreenTimeStudy;

  /// SCR-FAT-032 start time chip
  ///
  /// In ar, this message translates to:
  /// **'البداية'**
  String get childScreenTimeStart;

  /// SCR-FAT-032 end time chip
  ///
  /// In ar, this message translates to:
  /// **'النهاية'**
  String get childScreenTimeEnd;

  /// SCR-FAT-032 save CTA
  ///
  /// In ar, this message translates to:
  /// **'حفظ الجداول'**
  String get childScreenTimeSave;

  /// SCR-FAT-032 end > start validation
  ///
  /// In ar, this message translates to:
  /// **'يجب أن تكون النهاية بعد البداية في نفس اليوم'**
  String get childScreenTimeValidation;

  /// SCR-FAT-032 read-only when not father
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — التعديل لولي الأمر'**
  String get childScreenTimeReadOnly;

  /// SCR-FAT-032 SET-002 section title
  ///
  /// In ar, this message translates to:
  /// **'الحد اليومي والمحافظ'**
  String get childScreenTimeCapsSection;

  /// SCR-FAT-032 daily entertainment cap field
  ///
  /// In ar, this message translates to:
  /// **'الحد اليومي (دقائق)'**
  String get childScreenTimeDailyCap;

  /// SCR-FAT-032 allowWalletOverflow switch
  ///
  /// In ar, this message translates to:
  /// **'السماح بالمحفظة بعد نفاد الحد'**
  String get childScreenTimeAllowOverflow;

  /// SCR-FAT-032 Ruling B helper under overflow switch
  ///
  /// In ar, this message translates to:
  /// **'معطّل افتراضياً (حكم B): الدقائق المكتسبة تبقى داخل الحد اليومي إلا إذا سمحت بالتجاوز'**
  String get childScreenTimeAllowOverflowHelp;

  /// SCR-FAT-032 wallets list heading
  ///
  /// In ar, this message translates to:
  /// **'محافظ التطبيقات'**
  String get childScreenTimeWalletsHeading;

  /// SCR-FAT-032 wallet balance line
  ///
  /// In ar, this message translates to:
  /// **'{minutes} دقيقة مكتسبة'**
  String childScreenTimeWalletMinutes(int minutes);

  /// SCR-FAT-032 mock wallet app label
  ///
  /// In ar, this message translates to:
  /// **'ألعاب'**
  String get childScreenTimeWalletGames;

  /// SCR-FAT-032 mock wallet app label
  ///
  /// In ar, this message translates to:
  /// **'يوتيوب'**
  String get childScreenTimeWalletYoutube;

  /// SCR-FAT-032 education wallet — non-countable
  ///
  /// In ar, this message translates to:
  /// **'قرآن (تعليمي)'**
  String get childScreenTimeWalletQuran;

  /// SCR-FAT-032 save acknowledgement toast (schedules + SET-002)
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الجداول والحدود'**
  String get childScreenTimeSaveToast;

  /// SET-003 parent sync status — child offline or awaiting ack
  ///
  /// In ar, this message translates to:
  /// **'بانتظار مزامنة الجهاز'**
  String get childScreenTimeSyncPending;

  /// SET-003 parent sync status — child applied snapshot
  ///
  /// In ar, this message translates to:
  /// **'وُصل للابن'**
  String get childScreenTimeSyncDelivered;

  /// SET-003 child mirror stub title (P12 proof)
  ///
  /// In ar, this message translates to:
  /// **'وقت الشاشة لي'**
  String get childTimeMirrorTitle;

  /// SET-003 child remaining-minutes label
  ///
  /// In ar, this message translates to:
  /// **'الدقائق المتبقية اليوم'**
  String get childTimeMirrorRemainingLabel;

  /// SET-003 remaining minutes value
  ///
  /// In ar, this message translates to:
  /// **'متبقي {minutes} دقيقة'**
  String childTimeMirrorRemainingMinutes(int minutes);

  /// SET-003 soft notice when sleep schedule becomes active
  ///
  /// In ar, this message translates to:
  /// **'وقت الهدوء مفعّل — نم بهدوء'**
  String get childTimeMirrorSleepNotice;

  /// SET-003 exempt note — chat/Quran/SOS on expiry (banner copy)
  ///
  /// In ar, this message translates to:
  /// **'المحادثة والقرآن ونداء الطوارئ تبقى متاحة عند نفاد الوقت'**
  String get childTimeMirrorExemptBanner;

  /// SCR-FAT-034 app bar title
  ///
  /// In ar, this message translates to:
  /// **'تطبيقات الابن'**
  String get childAppsTitle;

  /// SCR-FAT-034 tip banner (Family Link / Qustodio honesty)
  ///
  /// In ar, this message translates to:
  /// **'اضغط على أي تطبيق للسماح أو الحظر أو مراجعة الحد — ينعكس على جهاز الابن.'**
  String get childAppsTipBanner;

  /// SCR-FAT-034 mother observer read-only hint
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — مستوى مشاركة أو كاملة يمكنه السماح أو الحظر'**
  String get childAppsObserverHint;

  /// SCR-FAT-034 CTA to FAT-035 when pending installs exist
  ///
  /// In ar, this message translates to:
  /// **'راجع {count} طلب تطبيق جديد'**
  String childAppsPendingCta(int count);

  /// SCR-FAT-034 shared-control footer note
  ///
  /// In ar, this message translates to:
  /// **'صلاحيات السماح والحظر مشتركة بين الأب والأم لضمان توافق الرعاية.'**
  String get childAppsSharedNote;

  /// SCR-FAT-034 empty inventory title
  ///
  /// In ar, this message translates to:
  /// **'لا تطبيقات متزامنة بعد'**
  String get childAppsEmptyTitle;

  /// SCR-FAT-034 empty inventory message
  ///
  /// In ar, this message translates to:
  /// **'عند إبلاغ جهاز هذا الابن عن التطبيقات المثبتة، ستظهر هنا حسب الفئة.'**
  String get childAppsEmptyMessage;

  /// SCR-FAT-034 child RoleGuard lean title
  ///
  /// In ar, this message translates to:
  /// **'أدوات الوالدين'**
  String get childAppsChildLeanTitle;

  /// SCR-FAT-034 child RoleGuard lean message
  ///
  /// In ar, this message translates to:
  /// **'السماح والحظر للتطبيقات للوالدين فقط.'**
  String get childAppsChildLeanMessage;

  /// SCR-FAT-034 P-4 SOS CTA
  ///
  /// In ar, this message translates to:
  /// **'استغاثة'**
  String get childAppsSosCta;

  /// SCR-FAT-034 category games
  ///
  /// In ar, this message translates to:
  /// **'الألعاب والترفيه'**
  String get childAppsCatGames;

  /// SCR-FAT-034 games category rule
  ///
  /// In ar, this message translates to:
  /// **'مسموحة ضمن وقت الشاشة اليومي'**
  String get childAppsCatGamesRule;

  /// SCR-FAT-034 category social
  ///
  /// In ar, this message translates to:
  /// **'التواصل الاجتماعي'**
  String get childAppsCatSocial;

  /// SCR-FAT-034 social category rule
  ///
  /// In ar, this message translates to:
  /// **'تحتاج موافقة مسبقة لكل تطبيق'**
  String get childAppsCatSocialRule;

  /// SCR-FAT-034 category edu
  ///
  /// In ar, this message translates to:
  /// **'التعليم والقرآن'**
  String get childAppsCatEdu;

  /// SCR-FAT-034 edu category rule
  ///
  /// In ar, this message translates to:
  /// **'مفتوحة دائمًا — لا تُحسب من وقت اللعب'**
  String get childAppsCatEduRule;

  /// SCR-FAT-034 category tools
  ///
  /// In ar, this message translates to:
  /// **'أدوات النظام'**
  String get childAppsCatTools;

  /// SCR-FAT-034 tools category rule
  ///
  /// In ar, this message translates to:
  /// **'متاحة دائمًا للمساعدة والمهام'**
  String get childAppsCatToolsRule;

  /// SCR-FAT-034 category app count tag
  ///
  /// In ar, this message translates to:
  /// **'{count} تطبيقات'**
  String childAppsCount(int count);

  /// SCR-FAT-034 allowed status remaining vs limit
  ///
  /// In ar, this message translates to:
  /// **'باقٍ {remaining} من {limit} د'**
  String childAppsRemaining(int remaining, int limit);

  /// SCR-FAT-034 free/edu status label
  ///
  /// In ar, this message translates to:
  /// **'حر ومفتوح'**
  String get childAppsStatusFree;

  /// SCR-FAT-034 blocked status label
  ///
  /// In ar, this message translates to:
  /// **'محظور'**
  String get childAppsStatusBlocked;

  /// SCR-FAT-034 pending install status
  ///
  /// In ar, this message translates to:
  /// **'بانتظار قرار'**
  String get childAppsStatusPending;

  /// SCR-FAT-034 wallet minutes under app
  ///
  /// In ar, this message translates to:
  /// **'محفظة {minutes} د'**
  String childAppsWallet(int minutes);

  /// SCR-FAT-034 instant-lock badge on app row
  ///
  /// In ar, this message translates to:
  /// **'موقوف فورًا'**
  String get childAppsInstantLocked;

  /// SCR-FAT-034 control sheet allow
  ///
  /// In ar, this message translates to:
  /// **'سماح بالاستخدام'**
  String get childAppsAllow;

  /// SCR-FAT-034 control sheet block
  ///
  /// In ar, this message translates to:
  /// **'حظر وإغلاق'**
  String get childAppsBlock;

  /// SCR-FAT-034 control sheet honesty hint
  ///
  /// In ar, this message translates to:
  /// **'هذا الضبط ينعكس فورًا على جهاز الابن.'**
  String get childAppsSheetHint;

  /// SCR-FAT-034 toast after allow/block
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث «{name}»'**
  String childAppsStatusUpdated(String name);

  /// SCR-FAT-035 app bar title
  ///
  /// In ar, this message translates to:
  /// **'موافقة تطبيق جديد'**
  String get newAppApprovalTitle;

  /// SCR-FAT-035 hero subtitle (no planted child name)
  ///
  /// In ar, this message translates to:
  /// **'طلب تثبيت معلّق حتى قرارك — ينعكس على جهاز الابن فور الموافقة أو الرفض.'**
  String get newAppApprovalRequestHint;

  /// SCR-FAT-035 risk/info card heading
  ///
  /// In ar, this message translates to:
  /// **'بطاقة المعلومات والتقييم'**
  String get newAppApprovalInfoHeading;

  /// SCR-FAT-035 age rating row label
  ///
  /// In ar, this message translates to:
  /// **'التقييم العمري'**
  String get newAppApprovalAgeLabel;

  /// SCR-FAT-035 social risk row — strangers
  ///
  /// In ar, this message translates to:
  /// **'محادثة مع غرباء'**
  String get newAppApprovalStrangersLabel;

  /// SCR-FAT-035 social risk value — strangers
  ///
  /// In ar, this message translates to:
  /// **'ممكنة إذا لم تُضبط'**
  String get newAppApprovalStrangersValue;

  /// SCR-FAT-035 social risk row — disappearing messages
  ///
  /// In ar, this message translates to:
  /// **'رسائل تختفي'**
  String get newAppApprovalVanishLabel;

  /// SCR-FAT-035 social risk value — disappearing
  ///
  /// In ar, this message translates to:
  /// **'نعم'**
  String get newAppApprovalVanishValue;

  /// SCR-FAT-035 advisor tip (Rule 23 — no planted name/age)
  ///
  /// In ar, this message translates to:
  /// **'توصية مستشار العائلة: التطبيق مقبول عمريًا مع حد لا يتجاوز {minutes} دقيقة يوميًا وتفعيل أمان الدائرة الخاصة.'**
  String newAppApprovalAdvisorTip(int minutes);

  /// SCR-FAT-035 allow-with-limit CTA
  ///
  /// In ar, this message translates to:
  /// **'سماح بحد {minutes} د'**
  String newAppApprovalApprove(int minutes);

  /// SCR-FAT-035 deny-with-alternative CTA
  ///
  /// In ar, this message translates to:
  /// **'حظر مع بديل'**
  String get newAppApprovalDeny;

  /// SCR-FAT-035 pedagogical tone footer
  ///
  /// In ar, this message translates to:
  /// **'النبرة التربوية للابن: توجيه للأفضل دائمًا — حوار ووئام لا صدام.'**
  String get newAppApprovalToneNote;

  /// SCR-FAT-035 mother observer read-only
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — القرار يتطلب مستوى مشاركة فما فوق'**
  String get newAppApprovalObserverHint;

  /// SCR-FAT-035 empty state title
  ///
  /// In ar, this message translates to:
  /// **'لا طلبات تثبيت معلّقة'**
  String get newAppApprovalEmptyTitle;

  /// SCR-FAT-035 empty state message
  ///
  /// In ar, this message translates to:
  /// **'عندما يطلب الابن تثبيت تطبيق جديد، يظهر هنا للموافقة أو الرفض.'**
  String get newAppApprovalEmptyMessage;

  /// SCR-FAT-035 child RoleGuard lean title
  ///
  /// In ar, this message translates to:
  /// **'أدوات الوالدين'**
  String get newAppApprovalChildLeanTitle;

  /// SCR-FAT-035 child RoleGuard lean message
  ///
  /// In ar, this message translates to:
  /// **'موافقة التطبيقات الجديدة للوالدين فقط.'**
  String get newAppApprovalChildLeanMessage;

  /// SCR-FAT-035 P-4 SOS CTA
  ///
  /// In ar, this message translates to:
  /// **'استغاثة'**
  String get newAppApprovalSosCta;

  /// SCR-FAT-035 toast after approve
  ///
  /// In ar, this message translates to:
  /// **'سُمح بـ «{name}» بحد {minutes} د/يوم — انعكس على جهاز الابن'**
  String newAppApprovalApprovedToast(String name, int minutes);

  /// SCR-FAT-035 toast after deny
  ///
  /// In ar, this message translates to:
  /// **'حُظر «{name}» بلطف — ووصل الابن: لم يُوافق هذه المرة'**
  String newAppApprovalDeniedToast(String name);

  /// SCR-FAT-035 done banner after allow
  ///
  /// In ar, this message translates to:
  /// **'تم السماح بـ «{name}» بحد {minutes} دقيقة يوميًا — وصل الابن الإشعار السار'**
  String newAppApprovalDoneAllowed(String name, int minutes);

  /// SCR-FAT-035 done banner after deny
  ///
  /// In ar, this message translates to:
  /// **'تم حظر «{name}» — وأُخطر الابن بلطف مع اقتراح بديل مفيد'**
  String newAppApprovalDoneBlocked(String name);

  /// SCR-FAT-035 CTA back to FAT-034
  ///
  /// In ar, this message translates to:
  /// **'العودة لتطبيقات الابن'**
  String get newAppApprovalBackToApps;

  /// SCR-FAT-038 app bar title
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات التحايل'**
  String get tamperAlertsTitle;

  /// SCR-FAT-038 pedagogy banner (dialogue not judgment)
  ///
  /// In ar, this message translates to:
  /// **'المحاولة ليست جريمة — إنها معلومة تربوية. الهدف حوار لا عقاب.'**
  String get tamperAlertsPedagogyBanner;

  /// SCR-FAT-038 Bark alert-first honesty
  ///
  /// In ar, this message translates to:
  /// **'نُعلِم بمحاولات الالتفاف كإشارات حوار — لا كمحضر اتهام (Bark).'**
  String get tamperAlertsHonestyBanner;

  /// SCR-FAT-038 active section heading
  ///
  /// In ar, this message translates to:
  /// **'تنبيه نشط'**
  String get tamperAlertsActiveHeading;

  /// SCR-FAT-038 handled history heading
  ///
  /// In ar, this message translates to:
  /// **'السجل'**
  String get tamperAlertsHistoryHeading;

  /// SCR-FAT-038 active tag
  ///
  /// In ar, this message translates to:
  /// **'نشط'**
  String get tamperAlertsStatusActive;

  /// SCR-FAT-038 handled tag
  ///
  /// In ar, this message translates to:
  /// **'عولج'**
  String get tamperAlertsStatusHandled;

  /// SCR-FAT-038 kind — VPN (Rule 23, no planted name)
  ///
  /// In ar, this message translates to:
  /// **'تطبيق VPN على جهاز الابن'**
  String get tamperAlertsKindVpn;

  /// SCR-FAT-038 VPN detail line
  ///
  /// In ar, this message translates to:
  /// **'اكتُشف وعُطّل تلقائيًا'**
  String get tamperAlertsKindVpnDetail;

  /// SCR-FAT-038 kind — permission disable
  ///
  /// In ar, this message translates to:
  /// **'إيقاف إذن الحماية'**
  String get tamperAlertsKindPermission;

  /// SCR-FAT-038 permission detail
  ///
  /// In ar, this message translates to:
  /// **'أُلغي إذن حماية مطلوب'**
  String get tamperAlertsKindPermissionDetail;

  /// SCR-FAT-038 kind — clock change
  ///
  /// In ar, this message translates to:
  /// **'تغيير وقت الجهاز'**
  String get tamperAlertsKindClock;

  /// SCR-FAT-038 clock detail
  ///
  /// In ar, this message translates to:
  /// **'أُعيد الوقت تلقائيًا وسُجّل'**
  String get tamperAlertsKindClockDetail;

  /// SCR-FAT-038 kind — safe mode
  ///
  /// In ar, this message translates to:
  /// **'وضع آمن أو إقلاع تجاوز'**
  String get tamperAlertsKindSafeMode;

  /// SCR-FAT-038 safe mode detail
  ///
  /// In ar, this message translates to:
  /// **'اكتُشف مسار إقلاع يتجاوز الحماية على جهاز الابن'**
  String get tamperAlertsKindSafeModeDetail;

  /// SCR-FAT-038 kind — generic bypass
  ///
  /// In ar, this message translates to:
  /// **'محاولة تجاوز'**
  String get tamperAlertsKindBypass;

  /// SCR-FAT-038 bypass detail
  ///
  /// In ar, this message translates to:
  /// **'أُبلغ عن محاولة التفاف تقنية'**
  String get tamperAlertsKindBypassDetail;

  /// SCR-FAT-038 kind — SIM change
  ///
  /// In ar, this message translates to:
  /// **'إخراج أو تبديل الشريحة'**
  String get tamperAlertsKindSim;

  /// SCR-FAT-038 SIM detail
  ///
  /// In ar, this message translates to:
  /// **'سُجّل تغيير الشريحة على جهاز الابن'**
  String get tamperAlertsKindSimDetail;

  /// SCR-FAT-038 dialogue tip — VPN
  ///
  /// In ar, this message translates to:
  /// **'اقتراح: الفضول حول الشبكات شائع. افتح حوارًا هادئًا: ماذا كنت تحاول الوصول إليه؟'**
  String get tamperAlertsTipVpn;

  /// SCR-FAT-038 dialogue tip — permission
  ///
  /// In ar, this message translates to:
  /// **'اقتراح: اسأل معًا لماذا أُوقف إذن الحماية — استمع أولًا ثم أعد الإعدادات.'**
  String get tamperAlertsTipPermission;

  /// SCR-FAT-038 dialogue tip — clock
  ///
  /// In ar, this message translates to:
  /// **'اقتراح: تلاعب الساعة غالبًا يعني رغبة بمزيد من الوقت — ناقش الحدود قبل إعادة القواعد.'**
  String get tamperAlertsTipClock;

  /// SCR-FAT-038 dialogue tip — safe mode
  ///
  /// In ar, this message translates to:
  /// **'اقتراح: تعامل مع إقلاع الوضع الآمن كإشارة لمراجعة الحماية معًا، لا كحكم.'**
  String get tamperAlertsTipSafeMode;

  /// SCR-FAT-038 dialogue tip — bypass
  ///
  /// In ar, this message translates to:
  /// **'اقتراح: محاولة التجاوز معلومة للحوار — ابقَ فضوليًا لا متهمًا.'**
  String get tamperAlertsTipBypass;

  /// SCR-FAT-038 dialogue tip — SIM
  ///
  /// In ar, this message translates to:
  /// **'اقتراح: تأكد أن الجهاز مع الابن، ثم راجع دفاعات إنذار الشريحة إن لزم.'**
  String get tamperAlertsTipSim;

  /// SCR-FAT-038 link to FAT-037 anti-tamper settings
  ///
  /// In ar, this message translates to:
  /// **'فتح دفاعات مقاومة التحايل'**
  String get tamperAlertsSettingsCta;

  /// SCR-FAT-038 empty title
  ///
  /// In ar, this message translates to:
  /// **'لا تنبيهات تحايل'**
  String get tamperAlertsEmptyTitle;

  /// SCR-FAT-038 empty message
  ///
  /// In ar, this message translates to:
  /// **'عند رصد محاولة التفاف تظهر هنا كإشارة حوار — لا كمحاكمة.'**
  String get tamperAlertsEmptyMessage;

  /// SCR-FAT-038 child RoleGuard lean title
  ///
  /// In ar, this message translates to:
  /// **'واجهة الوالدين'**
  String get tamperAlertsChildLeanTitle;

  /// SCR-FAT-038 child RoleGuard lean message
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات التحايل للوالدين. زر الطوارئ يبقى متاحًا.'**
  String get tamperAlertsChildLeanMessage;

  /// SCR-FAT-038 mother observer hint
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — دفاعات مقاومة التحايل يضبطها الأب.'**
  String get tamperAlertsObserverHint;

  /// SCR-FAT-038 P-4 SOS CTA
  ///
  /// In ar, this message translates to:
  /// **'طوارئ'**
  String get tamperAlertsSosCta;

  /// SCR-FAT-038 loading semantics
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل تنبيهات التحايل'**
  String get tamperAlertsLoadingSemantics;

  /// SCR-FAT-040 app bar title
  ///
  /// In ar, this message translates to:
  /// **'الاستوديو'**
  String get studioBoardTitle;

  /// SCR-FAT-040 create hero title → FAT-041
  ///
  /// In ar, this message translates to:
  /// **'+ أنشئ محتوى الآن'**
  String get studioBoardCreateTitle;

  /// SCR-FAT-040 create hero subtitle (90s rule)
  ///
  /// In ar, this message translates to:
  /// **'صوّر صفحة كتاب — ومستشار العائلة يجهز درسًا واختبارًا في ٩٠ ثانية'**
  String get studioBoardCreateSubtitle;

  /// SCR-FAT-040 S-EDU-064 suggestions section
  ///
  /// In ar, this message translates to:
  /// **'اقتراحات مستشار العائلة اليوم'**
  String get studioBoardSuggestionsHeading;

  /// SCR-FAT-040 suggestion — fractions (no planted name)
  ///
  /// In ar, this message translates to:
  /// **'الابن يتعثر في الكسور'**
  String get studioBoardSugFractionsTitle;

  /// SCR-FAT-040 suggestion CTA — fractions
  ///
  /// In ar, this message translates to:
  /// **'أنشئ تمارين مركزة؟'**
  String get studioBoardSugFractionsSub;

  /// SCR-FAT-040 suggestion — Quran wird
  ///
  /// In ar, this message translates to:
  /// **'ورد الحفظ وصل «الملك»'**
  String get studioBoardSugWirdTitle;

  /// SCR-FAT-040 suggestion CTA — wird
  ///
  /// In ar, this message translates to:
  /// **'جهّز ورد الأسبوع؟'**
  String get studioBoardSugWirdSub;

  /// SCR-FAT-040 recent content heading
  ///
  /// In ar, this message translates to:
  /// **'محتواي الأخير'**
  String get studioBoardRecentHeading;

  /// SCR-FAT-040 link to FAT-048 materials
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get studioBoardRecentAll;

  /// SCR-FAT-040 recent quiz title
  ///
  /// In ar, this message translates to:
  /// **'اختبار الكسور — رياضيات'**
  String get studioBoardContentQuizTitle;

  /// SCR-FAT-040 recent quiz subtitle
  ///
  /// In ar, this message translates to:
  /// **'أُسند · بانتظار الحل'**
  String get studioBoardContentQuizSub;

  /// SCR-FAT-040 recent flashcards title
  ///
  /// In ar, this message translates to:
  /// **'بطاقات الإنجليزية'**
  String get studioBoardContentCardsTitle;

  /// SCR-FAT-040 recent flashcards subtitle
  ///
  /// In ar, this message translates to:
  /// **'أُتقن ١٨ من ٢٤'**
  String get studioBoardContentCardsSub;

  /// SCR-FAT-040 recent wird title
  ///
  /// In ar, this message translates to:
  /// **'ورد سورة الملك ١–١٠'**
  String get studioBoardContentWirdTitle;

  /// SCR-FAT-040 recent wird subtitle
  ///
  /// In ar, this message translates to:
  /// **'٣ أيام متتالية'**
  String get studioBoardContentWirdSub;

  /// SCR-FAT-040 content status — active
  ///
  /// In ar, this message translates to:
  /// **'نشط'**
  String get studioBoardStatusActive;

  /// SCR-FAT-040 content status — progress
  ///
  /// In ar, this message translates to:
  /// **'٧٥٪'**
  String get studioBoardStatusProgress;

  /// SCR-FAT-040 content status — excellent
  ///
  /// In ar, this message translates to:
  /// **'ممتاز'**
  String get studioBoardStatusExcellent;

  /// SCR-FAT-040 quick action → FAT-042
  ///
  /// In ar, this message translates to:
  /// **'صوّر كتابًا'**
  String get studioBoardQuickCamera;

  /// SCR-FAT-040 quick action → FAT-046
  ///
  /// In ar, this message translates to:
  /// **'المكتبة'**
  String get studioBoardQuickLibrary;

  /// SCR-FAT-040 quick action → FAT-050
  ///
  /// In ar, this message translates to:
  /// **'النتائج'**
  String get studioBoardQuickResults;

  /// SCR-FAT-040 empty title
  ///
  /// In ar, this message translates to:
  /// **'لا محتوى بعد'**
  String get studioBoardEmptyTitle;

  /// SCR-FAT-040 empty message
  ///
  /// In ar, this message translates to:
  /// **'ابدأ بإنشاء درس أو اختبار من أي مصدر — الكاميرا أقصر طريق.'**
  String get studioBoardEmptyMessage;

  /// SCR-FAT-040 child RoleGuard lean title
  ///
  /// In ar, this message translates to:
  /// **'الاستوديو للوالدين'**
  String get studioBoardChildLeanTitle;

  /// SCR-FAT-040 child RoleGuard lean message
  ///
  /// In ar, this message translates to:
  /// **'صناعة المحتوى التعليمي للوالدين. زر الطوارئ يبقى متاحًا.'**
  String get studioBoardChildLeanMessage;

  /// SCR-FAT-040 mother observer hint
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — إنشاء المحتوى متاح للأب أو الأم بمستوى شريك/كامل.'**
  String get studioBoardObserverHint;

  /// SCR-FAT-040 P-4 SOS CTA
  ///
  /// In ar, this message translates to:
  /// **'طوارئ'**
  String get studioBoardSosCta;

  /// SCR-FAT-040 loading semantics
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل لوحة الاستوديو'**
  String get studioBoardLoadingSemantics;

  /// SCR-FAT-041 app bar title (F-13)
  ///
  /// In ar, this message translates to:
  /// **'أضف من أي مصدر'**
  String get addFromSourceTitle;

  /// SCR-FAT-041 tip banner (Rule 23 — no planted name)
  ///
  /// In ar, this message translates to:
  /// **'ارفع أي كتاب أو مذكرة، أو اختر التكليف المناسب لابنك من المسارات الميسّرة.'**
  String get addFromSourceTip;

  /// SCR-FAT-041 PDF hero title · S-EDU-050
  ///
  /// In ar, this message translates to:
  /// **'رفع ملف PDF (كتاب المدرسة / ملخص)'**
  String get addFromSourcePdfTitle;

  /// SCR-FAT-041 PDF hero subtitle
  ///
  /// In ar, this message translates to:
  /// **'يحلل مستشار العائلة الملف ويولد بطاقات تفاعلية واختبارًا متدرجًا بضغطة زر'**
  String get addFromSourcePdfSubtitle;

  /// SCR-FAT-041 PDF smart-generate tag
  ///
  /// In ar, this message translates to:
  /// **'توليد ذكي'**
  String get addFromSourcePdfTag;

  /// SCR-FAT-041 secondary sources section
  ///
  /// In ar, this message translates to:
  /// **'خيارات التكليف والواجبات المباشرة'**
  String get addFromSourceOptionsHeading;

  /// SCR-FAT-041 → FAT-049
  ///
  /// In ar, this message translates to:
  /// **'تكليف بواجب أو تحدي مهارات'**
  String get addFromSourceAssignmentTitle;

  /// SCR-FAT-041 assignment subtitle
  ///
  /// In ar, this message translates to:
  /// **'واجب مدرسي بالدفتر · تثبيت فجوة مهارة · سؤال عائلي خاص'**
  String get addFromSourceAssignmentSub;

  /// SCR-FAT-041 → FAT-042 · S-EDU-048
  ///
  /// In ar, this message translates to:
  /// **'تصوير صفحة من الكتاب بالكاميرا'**
  String get addFromSourceCameraTitle;

  /// SCR-FAT-041 camera subtitle
  ///
  /// In ar, this message translates to:
  /// **'التقاط سريع وتحليل'**
  String get addFromSourceCameraSub;

  /// SCR-FAT-041 · S-EDU-049
  ///
  /// In ar, this message translates to:
  /// **'رابط فيديو تعليمي'**
  String get addFromSourceLinkTitle;

  /// SCR-FAT-041 link subtitle
  ///
  /// In ar, this message translates to:
  /// **'يوتيوب · منصات تعليمية'**
  String get addFromSourceLinkSub;

  /// SCR-FAT-041 link mock toast
  ///
  /// In ar, this message translates to:
  /// **'الصق رابط فيديو تعليمي — ومستشار العائلة يستخرج منه ملخصًا وتمارين'**
  String get addFromSourceLinkToast;

  /// SCR-FAT-041 · S-EDU-051
  ///
  /// In ar, this message translates to:
  /// **'إنشاء من موضوع فقط'**
  String get addFromSourceTopicTitle;

  /// SCR-FAT-041 topic subtitle
  ///
  /// In ar, this message translates to:
  /// **'سمِّ المفهوم — والمستشار يجهّز حزمة درس'**
  String get addFromSourceTopicSub;

  /// SCR-FAT-041 topic mock toast
  ///
  /// In ar, this message translates to:
  /// **'الإنشاء من موضوع جاهز في الوضع التجريبي — اكتب المفهوم لاحقًا'**
  String get addFromSourceTopicToast;

  /// SCR-FAT-041 · S-EDU-052 P1
  ///
  /// In ar, this message translates to:
  /// **'شرح صوتي'**
  String get addFromSourceVoiceTitle;

  /// SCR-FAT-041 voice subtitle
  ///
  /// In ar, this message translates to:
  /// **'سجّل شرحًا قصيرًا بصوت الوالد'**
  String get addFromSourceVoiceSub;

  /// SCR-FAT-041 voice mock toast
  ///
  /// In ar, this message translates to:
  /// **'التقاط الشرح الصوتي قادم (P1) — تم التسجيل التجريبي'**
  String get addFromSourceVoiceToast;

  /// SCR-FAT-041 → FAT-046 · S-EDU-053
  ///
  /// In ar, this message translates to:
  /// **'استيراد من مكتبة المجتمع'**
  String get addFromSourceLibraryTitle;

  /// SCR-FAT-041 library subtitle
  ///
  /// In ar, this message translates to:
  /// **'حزم موثوقة مشاركة من عائلات أخرى'**
  String get addFromSourceLibrarySub;

  /// SCR-FAT-041 PDF sheet title
  ///
  /// In ar, this message translates to:
  /// **'رفع مصدر تعليمي (PDF) وتوليد المحتوى'**
  String get addFromSourcePdfSheetTitle;

  /// SCR-FAT-041 PDF sheet body (Rule 23)
  ///
  /// In ar, this message translates to:
  /// **'اختر كتاب المدرسة أو مذكرة الدرس — ومستشار العائلة يحلّلها ويولّد بطاقات واختبارًا متدرجًا لابنك.'**
  String get addFromSourcePdfSheetBody;

  /// SCR-FAT-041 mock PDF option — math
  ///
  /// In ar, this message translates to:
  /// **'كتاب الرياضيات — الفصل الثاني (الكسور والعمليات)'**
  String get addFromSourcePdfMathTitle;

  /// SCR-FAT-041 mock PDF math meta
  ///
  /// In ar, this message translates to:
  /// **'PDF رسمي · ١٤.٢ ميجابايت · متوسط'**
  String get addFromSourcePdfMathSub;

  /// SCR-FAT-041 mock PDF option — science
  ///
  /// In ar, this message translates to:
  /// **'مذكرة العلوم — الوحدة الثالثة (المادة والطاقة)'**
  String get addFromSourcePdfScienceTitle;

  /// SCR-FAT-041 mock PDF science meta
  ///
  /// In ar, this message translates to:
  /// **'PDF مدرسي · ٨.٥ ميجابايت · ملخص وأسئلة'**
  String get addFromSourcePdfScienceSub;

  /// SCR-FAT-041 pick-from-device row
  ///
  /// In ar, this message translates to:
  /// **'+ اختيار ملف PDF آخر من جهازك…'**
  String get addFromSourcePdfDeviceTitle;

  /// SCR-FAT-041 device picker mock toast
  ///
  /// In ar, this message translates to:
  /// **'يمكنك اختيار أي ملف PDF من جوالك أو حاسوبك'**
  String get addFromSourcePdfDeviceToast;

  /// SCR-FAT-041 alternate PDF select toast
  ///
  /// In ar, this message translates to:
  /// **'تم اختيار مذكرة العلوم (تجريبي)'**
  String get addFromSourcePdfSelectedToast;

  /// SCR-FAT-041 PDF sheet primary CTA → FAT-043
  ///
  /// In ar, this message translates to:
  /// **'حلّل وولّد'**
  String get addFromSourcePdfGenerateCta;

  /// SCR-FAT-041 PDF processing toast
  ///
  /// In ar, this message translates to:
  /// **'مستشار العائلة يحلل ملف الـ PDF الآن…'**
  String get addFromSourcePdfProcessingToast;

  /// SCR-FAT-041 child RoleGuard lean title
  ///
  /// In ar, this message translates to:
  /// **'إضافة المصادر للوالدين'**
  String get addFromSourceChildLeanTitle;

  /// SCR-FAT-041 child RoleGuard lean message
  ///
  /// In ar, this message translates to:
  /// **'بوابات إنشاء المحتوى للوالدين. الاستغاثة تبقى متاحة.'**
  String get addFromSourceChildLeanMessage;

  /// SCR-FAT-041 mother observer hint
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — الإنشاء من المصادر للأب أو الأم الشريكة/الكاملة.'**
  String get addFromSourceObserverHint;

  /// SCR-FAT-041 observer tap blocked toast
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — اطلب من الأب أو أم شريكة الإنشاء'**
  String get addFromSourceObserverBlocked;

  /// SCR-FAT-041 P-4 SOS CTA
  ///
  /// In ar, this message translates to:
  /// **'طوارئ'**
  String get addFromSourceSosCta;

  /// SCR-FAT-042 app bar title · S-EDU-048
  ///
  /// In ar, this message translates to:
  /// **'التقاط من الكاميرا'**
  String get studioCameraTitle;

  /// SCR-FAT-042 viewfinder instruction (Rule 23 — no planted name)
  ///
  /// In ar, this message translates to:
  /// **'وجّه الكاميرا لصفحة الكتاب — درس الكسور مثلًا'**
  String get studioCameraInstruction;

  /// SCR-FAT-042 mock viewfinder page label
  ///
  /// In ar, this message translates to:
  /// **'صفحة ٤٧ — الكسور'**
  String get studioCameraFrameLabel;

  /// SCR-FAT-042 mock viewfinder subject/grade
  ///
  /// In ar, this message translates to:
  /// **'رياضيات · ثالث متوسط'**
  String get studioCameraFrameMeta;

  /// SCR-FAT-042 viewfinder Semantics label
  ///
  /// In ar, this message translates to:
  /// **'إطار كاميرا تجريبي موجّه لصفحة كتاب'**
  String get studioCameraFrameSemantics;

  /// SCR-FAT-042 primary CTA → FAT-043
  ///
  /// In ar, this message translates to:
  /// **'التقاط وتحليل'**
  String get studioCameraCaptureCta;

  /// SCR-FAT-042 mock analysis toast before FAT-043
  ///
  /// In ar, this message translates to:
  /// **'حُللت الصفحة: «جمع الكسور المتشابهة» — ٣ أمثلة و٦ تمارين'**
  String get studioCameraAnalyzedToast;

  /// SCR-FAT-042 camera denied repair title
  ///
  /// In ar, this message translates to:
  /// **'يلزم إذن الكاميرا'**
  String get studioCameraRepairTitle;

  /// SCR-FAT-042 camera denied repair body
  ///
  /// In ar, this message translates to:
  /// **'تصوير صفحة الكتاب يحتاج الكاميرا مرة واحدة. افتح إعدادات النظام وفعّل الكاميرا لهذا التطبيق — لست عالقًا.'**
  String get studioCameraRepairBody;

  /// SCR-FAT-042 repair CTA ≥48dp — deep-link OS settings
  ///
  /// In ar, this message translates to:
  /// **'فتح إعدادات الكاميرا'**
  String get studioCameraOpenSettings;

  /// SCR-FAT-042 mock settings deep-link toast
  ///
  /// In ar, this message translates to:
  /// **'فتح إعدادات النظام (تجريبي) — فعّل الكاميرا ثم عد.'**
  String get studioCameraOpenSettingsToast;

  /// SCR-FAT-042 soft re-request permission
  ///
  /// In ar, this message translates to:
  /// **'حاول طلب الإذن مرة أخرى'**
  String get studioCameraRetryPermission;

  /// SCR-FAT-042 permanently denied title
  ///
  /// In ar, this message translates to:
  /// **'الكاميرا محظورة لهذا التطبيق'**
  String get studioCameraPermanentTitle;

  /// SCR-FAT-042 permanently denied instructions
  ///
  /// In ar, this message translates to:
  /// **'فعّل الكاميرا من إعدادات النظام لهذا التطبيق، ثم عد لتصوير صفحة الكتاب.'**
  String get studioCameraPermanentBody;

  /// SCR-FAT-042 child RoleGuard lean title
  ///
  /// In ar, this message translates to:
  /// **'التقاط الكاميرا للوالدين'**
  String get studioCameraChildLeanTitle;

  /// SCR-FAT-042 child RoleGuard lean message
  ///
  /// In ar, this message translates to:
  /// **'تصوير صفحة الكتاب أداة استوديو للوالدين. الاستغاثة تبقى متاحة.'**
  String get studioCameraChildLeanMessage;

  /// SCR-FAT-042 mother observer hint
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — التقاط الصفحات للأب أو الأم الشريكة/الكاملة.'**
  String get studioCameraObserverHint;

  /// SCR-FAT-042 observer capture blocked toast
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — اطلب من الأب أو أم شريكة الالتقاط'**
  String get studioCameraObserverBlocked;

  /// SCR-FAT-042 P-4 SOS CTA
  ///
  /// In ar, this message translates to:
  /// **'طوارئ'**
  String get studioCameraSosCta;

  /// SCR-FAT-042 permission-check loading Semantics
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحقق من إذن الكاميرا'**
  String get studioCameraLoadingSemantics;

  /// SCR-FAT-043 app bar title · S-EDU-054…060
  ///
  /// In ar, this message translates to:
  /// **'مخرجات التوليد'**
  String get generationOutputsTitle;

  /// SCR-FAT-043 list card heading — 9 forms from one source
  ///
  /// In ar, this message translates to:
  /// **'ماذا نولّد؟'**
  String get generationOutputsHeading;

  /// SCR-FAT-043 mock source banner (Rule 23 — discrete label from repo)
  ///
  /// In ar, this message translates to:
  /// **'المصدر: «جمع الكسور المتشابهة» — ص٤٧ رياضيات'**
  String get generationOutputsSourceFractions;

  /// SCR-FAT-043 output — lesson
  ///
  /// In ar, this message translates to:
  /// **'درس مبسط'**
  String get generationOutputsLessonTitle;

  /// SCR-FAT-043 lesson subtitle (Rule 23 — no planted name)
  ///
  /// In ar, this message translates to:
  /// **'شرح تفاعلي بلغة ابنك'**
  String get generationOutputsLessonSub;

  /// SCR-FAT-043 output — homework
  ///
  /// In ar, this message translates to:
  /// **'واجب'**
  String get generationOutputsHomeworkTitle;

  /// SCR-FAT-043 homework subtitle
  ///
  /// In ar, this message translates to:
  /// **'٦ تمارين متدرجة'**
  String get generationOutputsHomeworkSub;

  /// SCR-FAT-043 output — quiz
  ///
  /// In ar, this message translates to:
  /// **'اختبار قصير'**
  String get generationOutputsQuizTitle;

  /// SCR-FAT-043 quiz subtitle
  ///
  /// In ar, this message translates to:
  /// **'١٠ أسئلة مصححة آليًا'**
  String get generationOutputsQuizSub;

  /// SCR-FAT-043 output — flashcards
  ///
  /// In ar, this message translates to:
  /// **'بطاقات حفظ'**
  String get generationOutputsFlashcardsTitle;

  /// SCR-FAT-043 flashcards subtitle
  ///
  /// In ar, this message translates to:
  /// **'قواعد الكسور'**
  String get generationOutputsFlashcardsSub;

  /// SCR-FAT-043 output — challenge
  ///
  /// In ar, this message translates to:
  /// **'تحدٍّ بمكافأة'**
  String get generationOutputsChallengeTitle;

  /// SCR-FAT-043 challenge subtitle
  ///
  /// In ar, this message translates to:
  /// **'حل ٥ بلا خطأ = ٢٠ دقيقة'**
  String get generationOutputsChallengeSub;

  /// SCR-FAT-043 output — review game (P1)
  ///
  /// In ar, this message translates to:
  /// **'لعبة مراجعة'**
  String get generationOutputsReviewGameTitle;

  /// SCR-FAT-043 review game subtitle
  ///
  /// In ar, this message translates to:
  /// **'مطابقة · ترتيب · صح-خطأ'**
  String get generationOutputsReviewGameSub;

  /// SCR-FAT-043 phase-locked tag on review game
  ///
  /// In ar, this message translates to:
  /// **'P1'**
  String get generationOutputsPhaseTag;

  /// SCR-FAT-043 toast when P1 switch tapped
  ///
  /// In ar, this message translates to:
  /// **'لعبة المراجعة في مرحلة لاحقة — غير قابلة للتحديد الآن'**
  String get generationOutputsPhaseLockedToast;

  /// SCR-FAT-043 hard lock banner — auto religious generation forbidden
  ///
  /// In ar, this message translates to:
  /// **'⛔ المحتوى الديني (قرآن · حديث · فقه) لا يُولَّد آليًا أبدًا — يُنقل من مصادر معتمدة فقط، والأب يراجع. قرار مالك لا استثناء فيه.'**
  String get generationOutputsReligiousLock;

  /// SCR-FAT-043 primary CTA → FAT-044
  ///
  /// In ar, this message translates to:
  /// **'ولّد المحدد ({count})'**
  String generationOutputsGenerateCta(int count);

  /// SCR-FAT-043 mock generate toast before FAT-044
  ///
  /// In ar, this message translates to:
  /// **'🧠 يولّد مستشار العائلة الآن…'**
  String get generationOutputsGeneratingToast;

  /// SCR-FAT-043 toast when generate with zero selected
  ///
  /// In ar, this message translates to:
  /// **'اختر مخرجًا واحدًا على الأقل للتوليد'**
  String get generationOutputsNoneSelectedToast;

  /// SCR-FAT-043 empty state title
  ///
  /// In ar, this message translates to:
  /// **'لا مخرجات بعد'**
  String get generationOutputsEmptyTitle;

  /// SCR-FAT-043 empty state message
  ///
  /// In ar, this message translates to:
  /// **'التقط أو ارفع مصدرًا أولًا — ثم اختر الأشكال التي تريد توليدها.'**
  String get generationOutputsEmptyMessage;

  /// SCR-FAT-043 loading Semantics
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحميل مخرجات التوليد'**
  String get generationOutputsLoadingSemantics;

  /// SCR-FAT-043 child RoleGuard lean title
  ///
  /// In ar, this message translates to:
  /// **'مخرجات التوليد للوالدين'**
  String get generationOutputsChildLeanTitle;

  /// SCR-FAT-043 child RoleGuard lean message
  ///
  /// In ar, this message translates to:
  /// **'اختيار مخرجات الاستوديو أداة للوالدين. الاستغاثة تبقى متاحة.'**
  String get generationOutputsChildLeanMessage;

  /// SCR-FAT-043 mother observer hint
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — التحديد والتوليد للأب أو الأم الشريكة/الكاملة.'**
  String get generationOutputsObserverHint;

  /// SCR-FAT-043 observer blocked toast
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — اطلب من الأب أو أم شريكة التوليد'**
  String get generationOutputsObserverBlocked;

  /// SCR-FAT-043 P-4 SOS CTA
  ///
  /// In ar, this message translates to:
  /// **'طوارئ'**
  String get generationOutputsSosCta;

  /// SCR-FAT-044 app bar title
  ///
  /// In ar, this message translates to:
  /// **'معاينة واعتماد'**
  String get previewApproveTitle;

  /// SCR-FAT-044 90-second rule banner
  ///
  /// In ar, this message translates to:
  /// **'⚡ قاعدة ٩٠ ثانية — الأب يعتمد ولا يؤلّف · تحرير خفيف فقط'**
  String get previewApproveRuleBanner;

  /// SCR-FAT-044 quiz card title
  ///
  /// In ar, this message translates to:
  /// **'الاختبار'**
  String get previewApproveQuizTitle;

  /// SCR-FAT-044 lesson card title
  ///
  /// In ar, this message translates to:
  /// **'الدرس'**
  String get previewApproveLessonTitle;

  /// SCR-FAT-044 ready tag
  ///
  /// In ar, this message translates to:
  /// **'جاهز'**
  String get previewApproveReadyTag;

  /// SCR-FAT-044 quiz Q1 prompt
  ///
  /// In ar, this message translates to:
  /// **'س١: ٢/٧ + ٣/٧ = ؟'**
  String get previewApproveQ1Prompt;

  /// SCR-FAT-044 quiz Q1 option A
  ///
  /// In ar, this message translates to:
  /// **'أ) ٥/٧ ✓'**
  String get previewApproveQ1OptA;

  /// SCR-FAT-044 quiz Q1 option B
  ///
  /// In ar, this message translates to:
  /// **'ب) ٥/١٤'**
  String get previewApproveQ1OptB;

  /// SCR-FAT-044 quiz Q1 option C
  ///
  /// In ar, this message translates to:
  /// **'ج) ٦/٧'**
  String get previewApproveQ1OptC;

  /// SCR-FAT-044 quiz Q2 prompt
  ///
  /// In ar, this message translates to:
  /// **'س٢: ١/٥ + ٢/٥ = ؟'**
  String get previewApproveQ2Prompt;

  /// SCR-FAT-044 quiz Q2 option A
  ///
  /// In ar, this message translates to:
  /// **'أ) ٣/٥ ✓'**
  String get previewApproveQ2OptA;

  /// SCR-FAT-044 quiz Q2 option B
  ///
  /// In ar, this message translates to:
  /// **'ب) ٣/١٠'**
  String get previewApproveQ2OptB;

  /// SCR-FAT-044 quiz Q2 option C
  ///
  /// In ar, this message translates to:
  /// **'ج) ٢/٥'**
  String get previewApproveQ2OptC;

  /// SCR-FAT-044 swapped quiz Q3 prompt
  ///
  /// In ar, this message translates to:
  /// **'س٣: ٤/٩ + ٢/٩ = ؟'**
  String get previewApproveQ3Prompt;

  /// SCR-FAT-044 quiz Q3 option A
  ///
  /// In ar, this message translates to:
  /// **'أ) ٦/٩ ✓'**
  String get previewApproveQ3OptA;

  /// SCR-FAT-044 quiz Q3 option B
  ///
  /// In ar, this message translates to:
  /// **'ب) ٦/١٨'**
  String get previewApproveQ3OptB;

  /// SCR-FAT-044 quiz Q3 option C
  ///
  /// In ar, this message translates to:
  /// **'ج) ٨/٩'**
  String get previewApproveQ3OptC;

  /// SCR-FAT-044 lesson preview summary
  ///
  /// In ar, this message translates to:
  /// **'«تخيل بيتزا مقسومة ٧ قطع…» — شرح بالأمثلة البصرية'**
  String get previewApproveLessonSummary;

  /// SCR-FAT-044 swap question CTA
  ///
  /// In ar, this message translates to:
  /// **'بدّل سؤالًا'**
  String get previewApproveSwapCta;

  /// SCR-FAT-044 edit question CTA
  ///
  /// In ar, this message translates to:
  /// **'عدّل سؤالًا'**
  String get previewApproveEditCta;

  /// SCR-FAT-044 delete question CTA
  ///
  /// In ar, this message translates to:
  /// **'احذف'**
  String get previewApproveDeleteCta;

  /// SCR-FAT-044 difficulty CTA
  ///
  /// In ar, this message translates to:
  /// **'أسهل/أصعب'**
  String get previewApproveDifficultyCta;

  /// SCR-FAT-044 swap toast
  ///
  /// In ar, this message translates to:
  /// **'س٣ استُبدل بسؤال أسهل'**
  String get previewApproveSwapToast;

  /// SCR-FAT-044 edit toast (mock)
  ///
  /// In ar, this message translates to:
  /// **'افتح أي سؤال وعدّل نصه وخياراته قبل الإرسال'**
  String get previewApproveEditToast;

  /// SCR-FAT-044 delete toast
  ///
  /// In ar, this message translates to:
  /// **'حُذف السؤال — لن يصل الابن إلا ما اعتمدتَه'**
  String get previewApproveDeleteToast;

  /// SCR-FAT-044 difficulty toast
  ///
  /// In ar, this message translates to:
  /// **'عُدّل مستوى الصعوبة'**
  String get previewApproveDifficultyToast;

  /// SCR-FAT-044 primary approve → FAT-045
  ///
  /// In ar, this message translates to:
  /// **'اعتمد الكل — أسنده الآن'**
  String get previewApproveApproveCta;

  /// SCR-FAT-044 reject all CTA
  ///
  /// In ar, this message translates to:
  /// **'ارفض المحتوى'**
  String get previewApproveRejectCta;

  /// SCR-FAT-044 reject toast
  ///
  /// In ar, this message translates to:
  /// **'رُفض المحتوى — لن يُسند للابن'**
  String get previewApproveRejectToast;

  /// SCR-FAT-044 approve blocked toast
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد محتوى معتمد للإسناد'**
  String get previewApproveCannotApproveToast;

  /// SCR-FAT-044 90-second timing note
  ///
  /// In ar, this message translates to:
  /// **'من الالتقاط لهنا: ~{seconds} ثانية — ضمن قاعدة الـ٩٠ ✓'**
  String previewApproveTimingNote(int seconds);

  /// SCR-FAT-044 empty title
  ///
  /// In ar, this message translates to:
  /// **'لا معاينة بعد'**
  String get previewApproveEmptyTitle;

  /// SCR-FAT-044 empty message
  ///
  /// In ar, this message translates to:
  /// **'ولّد مخرجات من الاستوديو أولًا — ثم راجع واعتمد هنا.'**
  String get previewApproveEmptyMessage;

  /// SCR-FAT-044 loading semantics
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحميل المعاينة'**
  String get previewApproveLoadingSemantics;

  /// SCR-FAT-044 child lean title
  ///
  /// In ar, this message translates to:
  /// **'المعاينة والاعتماد للوالدين'**
  String get previewApproveChildLeanTitle;

  /// SCR-FAT-044 child lean message
  ///
  /// In ar, this message translates to:
  /// **'اعتماد مخرجات الاستوديو أداة للوالدين. الاستغاثة تبقى متاحة.'**
  String get previewApproveChildLeanMessage;

  /// SCR-FAT-044 mother observer hint
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — الاعتماد والرفض للأب أو الأم الشريكة/الكاملة.'**
  String get previewApproveObserverHint;

  /// SCR-FAT-044 observer blocked toast
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — اطلب من الأب أو أم شريكة الاعتماد'**
  String get previewApproveObserverBlocked;

  /// SCR-FAT-044 P-4 SOS CTA
  ///
  /// In ar, this message translates to:
  /// **'طوارئ'**
  String get previewApproveSosCta;

  /// SCR-FAT-045 app bar title
  ///
  /// In ar, this message translates to:
  /// **'الإسناد والمكافأة'**
  String get attributionRewardTitle;

  /// SCR-FAT-045 mastery banner · minutes-only ع-١
  ///
  /// In ar, this message translates to:
  /// **'مكافأة دقائق شاشة عند الإتقان (≥{percent}٪) — الأب يحدد الدقائق فقط'**
  String attributionRewardMasteryBanner(int percent);

  /// SCR-FAT-045 child picker heading
  ///
  /// In ar, this message translates to:
  /// **'لمن؟'**
  String get attributionRewardWhoHeading;

  /// SCR-FAT-045 generic child label 1 · Rule 23
  ///
  /// In ar, this message translates to:
  /// **'ابن ١'**
  String get attributionRewardChildOne;

  /// SCR-FAT-045 generic child label 2 · Rule 23
  ///
  /// In ar, this message translates to:
  /// **'ابن ٢'**
  String get attributionRewardChildTwo;

  /// SCR-FAT-045 generic child label 3 · Rule 23
  ///
  /// In ar, this message translates to:
  /// **'ابن ٣'**
  String get attributionRewardChildThree;

  /// SCR-FAT-045 schedule field label
  ///
  /// In ar, this message translates to:
  /// **'الموعد'**
  String get attributionRewardScheduleLabel;

  /// SCR-FAT-045 schedule option — tomorrow
  ///
  /// In ar, this message translates to:
  /// **'غدًا — بعد المدرسة'**
  String get attributionRewardScheduleTomorrow;

  /// SCR-FAT-045 schedule option — today
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get attributionRewardScheduleToday;

  /// SCR-FAT-045 schedule option — weekend
  ///
  /// In ar, this message translates to:
  /// **'نهاية الأسبوع'**
  String get attributionRewardScheduleWeekend;

  /// SCR-FAT-045 rewards card heading
  ///
  /// In ar, this message translates to:
  /// **'المكافأة عند الإتقان (≥{percent}٪)'**
  String attributionRewardRewardsHeading(int percent);

  /// SCR-FAT-045 wallet minutes reward
  ///
  /// In ar, this message translates to:
  /// **'{minutes} دقيقة لمحفظته'**
  String attributionRewardWalletMinutes(int minutes);

  /// SCR-FAT-045 play minutes reward
  ///
  /// In ar, this message translates to:
  /// **'+{minutes} دقيقة لعب'**
  String attributionRewardPlayMinutes(int minutes);

  /// SCR-FAT-045 play reward auto-add note
  ///
  /// In ar, this message translates to:
  /// **'تُضاف تلقائيًا'**
  String get attributionRewardAutoAdded;

  /// SCR-FAT-045 primary assign CTA
  ///
  /// In ar, this message translates to:
  /// **'إسناد ✓'**
  String get attributionRewardAssignCta;

  /// SCR-FAT-045 secondary CTA → FAT-046
  ///
  /// In ar, this message translates to:
  /// **'مكتبة المجتمع'**
  String get attributionRewardLibraryCta;

  /// SCR-FAT-045 assign success toast
  ///
  /// In ar, this message translates to:
  /// **'أُسند لـ{name} — وصله: «والدك جهّز لك تحديًا — {minutes} دقيقة تنتظرك!»'**
  String attributionRewardAssignedToast(String name, int minutes);

  /// SCR-FAT-045 cannot assign toast
  ///
  /// In ar, this message translates to:
  /// **'اختر ابنًا وفعّل مكافأة دقائق واحدة على الأقل'**
  String get attributionRewardCannotAssignToast;

  /// SCR-FAT-045 empty state title
  ///
  /// In ar, this message translates to:
  /// **'لا أبناء للإسناد'**
  String get attributionRewardEmptyTitle;

  /// SCR-FAT-045 empty state message
  ///
  /// In ar, this message translates to:
  /// **'اربط جهاز ابن أولًا — ثم أسند المحتوى بمكافأة دقائق.'**
  String get attributionRewardEmptyMessage;

  /// SCR-FAT-045 loading semantics
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحميل الإسناد'**
  String get attributionRewardLoadingSemantics;

  /// SCR-FAT-045 child lean title
  ///
  /// In ar, this message translates to:
  /// **'الإسناد والمكافأة للوالدين'**
  String get attributionRewardChildLeanTitle;

  /// SCR-FAT-045 child lean message
  ///
  /// In ar, this message translates to:
  /// **'إسناد المحتوى التعليمي أداة للوالدين. الاستغاثة تبقى متاحة.'**
  String get attributionRewardChildLeanMessage;

  /// SCR-FAT-045 observer mother hint
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — الإسناد للوالد أو الأم الشريكة/الكاملة.'**
  String get attributionRewardObserverHint;

  /// SCR-FAT-045 observer blocked toast
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — اطلب من الأب أو أم شريكة الإسناد'**
  String get attributionRewardObserverBlocked;

  /// SCR-FAT-045 P-4 SOS CTA
  ///
  /// In ar, this message translates to:
  /// **'طوارئ'**
  String get attributionRewardSosCta;

  /// SCR-FAT-046 app bar title
  ///
  /// In ar, this message translates to:
  /// **'مكتبة المجتمع'**
  String get communityLibraryTitle;

  /// SCR-FAT-046 search placeholder
  ///
  /// In ar, this message translates to:
  /// **'ابحث: كسور · تجويد · إنجليزية…'**
  String get communityLibrarySearchHint;

  /// SCR-FAT-046 filtered empty
  ///
  /// In ar, this message translates to:
  /// **'لا حزم تطابق هذا البحث'**
  String get communityLibrarySearchNoResults;

  /// SCR-FAT-046 top-rated card heading
  ///
  /// In ar, this message translates to:
  /// **'الأعلى تقييمًا هذا الأسبوع'**
  String get communityLibraryTopRatedHeading;

  /// SCR-FAT-046 pack title — fractions
  ///
  /// In ar, this message translates to:
  /// **'سلسلة الكسور كاملة'**
  String get communityLibraryPackFractions;

  /// SCR-FAT-046 pack title — Quran
  ///
  /// In ar, this message translates to:
  /// **'مراجعة جزء عمّ'**
  String get communityLibraryPackJuzAmma;

  /// SCR-FAT-046 pack title — English
  ///
  /// In ar, this message translates to:
  /// **'بطاقات إنجليزي أول متوسط'**
  String get communityLibraryPackEnglish;

  /// SCR-FAT-046 anonymous author — Rule 23
  ///
  /// In ar, this message translates to:
  /// **'أب من الرياض'**
  String get communityLibraryAuthorFatherRiyadh;

  /// SCR-FAT-046 anonymous author — Rule 23
  ///
  /// In ar, this message translates to:
  /// **'أم من جدة'**
  String get communityLibraryAuthorMotherJeddah;

  /// SCR-FAT-046 anonymous author — Rule 23
  ///
  /// In ar, this message translates to:
  /// **'أب من الدمام'**
  String get communityLibraryAuthorFatherDammam;

  /// SCR-FAT-046 pack subtitle meta
  ///
  /// In ar, this message translates to:
  /// **'{author} · ⭐ {rating} ({count})'**
  String communityLibraryPackMeta(String author, String rating, int count);

  /// SCR-FAT-046 import sheet detail
  ///
  /// In ar, this message translates to:
  /// **'{lessons} دروس + {quizzes} اختبارات · نشرها {author} · اجتازت مراجعة المجتمع ✓'**
  String communityLibraryPackDetail(int lessons, int quizzes, String author);

  /// SCR-FAT-046 trusted pack tag
  ///
  /// In ar, this message translates to:
  /// **'موثوق ✓'**
  String get communityLibraryTrustedTag;

  /// SCR-FAT-046 import CTA → FAT-047
  ///
  /// In ar, this message translates to:
  /// **'استيراد مجاني'**
  String get communityLibraryImportCta;

  /// SCR-FAT-046 import success toast
  ///
  /// In ar, this message translates to:
  /// **'استُوردت لاستوديوك — عدّلها بحرية'**
  String get communityLibraryImportedToast;

  /// SCR-FAT-046 publish card heading
  ///
  /// In ar, this message translates to:
  /// **'شارك أنت أيضًا'**
  String get communityLibraryPublishHeading;

  /// SCR-FAT-046 publish card body
  ///
  /// In ar, this message translates to:
  /// **'اختبار الكسور الذي صنعته نال إعجاب أبنائك — انشره ليستفيد غيرك.'**
  String get communityLibraryPublishMessage;

  /// SCR-FAT-046 local pack name for publish CTA
  ///
  /// In ar, this message translates to:
  /// **'اختبار الكسور'**
  String get communityLibraryPublishPackFractionsQuiz;

  /// SCR-FAT-046 publish CTA
  ///
  /// In ar, this message translates to:
  /// **'انشر «{name}»'**
  String communityLibraryPublishCta(String name);

  /// SCR-FAT-046 father publish toast
  ///
  /// In ar, this message translates to:
  /// **'أُرسل للمراجعة — يُنشر باسمك بعد اجتياز الضوابط الستة'**
  String get communityLibraryPublishSubmittedToast;

  /// SCR-FAT-046 mother publish needs father
  ///
  /// In ar, this message translates to:
  /// **'أُرسل لموافقة الأب — ثم الضوابط الستة للمجتمع'**
  String get communityLibraryPublishPendingFatherToast;

  /// SCR-FAT-046 six controls footer
  ///
  /// In ar, this message translates to:
  /// **'كل محتوى منشور يمر بالضوابط الستة: مراجعة · تصنيف عمري · بلا بيانات شخصية · تقييم · بلاغات · إزالة فورية'**
  String get communityLibrarySixControlsNote;

  /// SCR-FAT-046 secondary CTA → FAT-047
  ///
  /// In ar, this message translates to:
  /// **'افتح المسار التعليمي'**
  String get communityLibraryPathCta;

  /// SCR-FAT-046 empty title
  ///
  /// In ar, this message translates to:
  /// **'مكتبة المجتمع هادئة'**
  String get communityLibraryEmptyTitle;

  /// SCR-FAT-046 empty message
  ///
  /// In ar, this message translates to:
  /// **'أنشئ حزمة في الاستوديو أولًا — ثم تصفّح وشارك مع العائلات الأخرى.'**
  String get communityLibraryEmptyMessage;

  /// SCR-FAT-046 empty CTA → FAT-041
  ///
  /// In ar, this message translates to:
  /// **'أضف من أي مصدر'**
  String get communityLibraryEmptyCta;

  /// SCR-FAT-046 loading semantics
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحميل مكتبة المجتمع'**
  String get communityLibraryLoadingSemantics;

  /// SCR-FAT-046 child lean title
  ///
  /// In ar, this message translates to:
  /// **'مكتبة المجتمع للوالدين'**
  String get communityLibraryChildLeanTitle;

  /// SCR-FAT-046 child lean message
  ///
  /// In ar, this message translates to:
  /// **'استيراد ونشر حزم المجتمع أداة للوالدين. الاستغاثة تبقى متاحة.'**
  String get communityLibraryChildLeanMessage;

  /// SCR-FAT-046 observer banner
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — الاستيراد والنشر للوالد أو الأم الشريكة/الكاملة.'**
  String get communityLibraryObserverHint;

  /// SCR-FAT-046 observer blocked toast
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — اطلب من الأب أو أم شريكة الاستيراد'**
  String get communityLibraryObserverBlocked;

  /// SCR-FAT-046 P-4 SOS CTA
  ///
  /// In ar, this message translates to:
  /// **'طوارئ'**
  String get communityLibrarySosCta;

  /// SCR-FAT-047 app bar title
  ///
  /// In ar, this message translates to:
  /// **'المسار التعليمي'**
  String get learningPathTitle;

  /// SCR-FAT-047 path heading (Rule 23 generic child)
  ///
  /// In ar, this message translates to:
  /// **'مسار {child} — {subject}'**
  String learningPathHeading(String child, String subject);

  /// SCR-FAT-047 generic child label 1 — Rule 23
  ///
  /// In ar, this message translates to:
  /// **'ابن ١'**
  String get learningPathChildOne;

  /// SCR-FAT-047 generic child label 2 — Rule 23
  ///
  /// In ar, this message translates to:
  /// **'ابن ٢'**
  String get learningPathChildTwo;

  /// SCR-FAT-047 generic child label 3 — Rule 23
  ///
  /// In ar, this message translates to:
  /// **'ابن ٣'**
  String get learningPathChildThree;

  /// SCR-FAT-047 subject — fractions
  ///
  /// In ar, this message translates to:
  /// **'الكسور'**
  String get learningPathSubjectFractions;

  /// SCR-FAT-047 progress caption
  ///
  /// In ar, this message translates to:
  /// **'{percent}٪ — {done} من {total} دروس'**
  String learningPathProgressLabel(int percent, int done, int total);

  /// SCR-FAT-047 stop — concept
  ///
  /// In ar, this message translates to:
  /// **'مفهوم الكسر'**
  String get learningPathStopConcept;

  /// SCR-FAT-047 stop — similar fractions
  ///
  /// In ar, this message translates to:
  /// **'الكسور المتشابهة'**
  String get learningPathStopSimilar;

  /// SCR-FAT-047 stop — adding
  ///
  /// In ar, this message translates to:
  /// **'جمع الكسور'**
  String get learningPathStopAdding;

  /// SCR-FAT-047 stop — subtract
  ///
  /// In ar, this message translates to:
  /// **'طرح الكسور'**
  String get learningPathStopSubtract;

  /// SCR-FAT-047 stop — final quiz
  ///
  /// In ar, this message translates to:
  /// **'الاختبار الشامل'**
  String get learningPathStopFinalQuiz;

  /// SCR-FAT-047 mastered subtitle
  ///
  /// In ar, this message translates to:
  /// **'أتقنه {percent}٪'**
  String learningPathStopMastered(int percent);

  /// SCR-FAT-047 current stop subtitle
  ///
  /// In ar, this message translates to:
  /// **'الاختبار معلق — أُسند اليوم'**
  String get learningPathStopQuizPending;

  /// SCR-FAT-047 locked stop subtitle
  ///
  /// In ar, this message translates to:
  /// **'يُفتح بعد الإتقان'**
  String get learningPathStopLocked;

  /// SCR-FAT-047 capstone reward subtitle
  ///
  /// In ar, this message translates to:
  /// **'مكافأة كبرى: {minutes} دقيقة'**
  String learningPathStopReward(int minutes);

  /// SCR-FAT-047 advisor banner
  ///
  /// In ar, this message translates to:
  /// **'مستشار العائلة يقترح الخطوة التالية تلقائيًا بناء على الإتقان — لا تقدم بلا فهم.'**
  String get learningPathAdvisorBanner;

  /// SCR-FAT-047 CTA → FAT-048
  ///
  /// In ar, this message translates to:
  /// **'المواد والدروس'**
  String get learningPathMaterialsCta;

  /// SCR-FAT-047 locked stop toast
  ///
  /// In ar, this message translates to:
  /// **'هذه الخطوة تُفتح بعد الإتقان'**
  String get learningPathLockedToast;

  /// SCR-FAT-047 mastered stop toast
  ///
  /// In ar, this message translates to:
  /// **'مُتقَن بالفعل — تابع المسار'**
  String get learningPathMasteredToast;

  /// SCR-FAT-047 empty state title
  ///
  /// In ar, this message translates to:
  /// **'لا مسار تعليمي بعد'**
  String get learningPathEmptyTitle;

  /// SCR-FAT-047 empty state message
  ///
  /// In ar, this message translates to:
  /// **'أنشئ محتوى في الاستوديو أولًا — ثم تابع الإتقان على مسار.'**
  String get learningPathEmptyMessage;

  /// SCR-FAT-047 empty CTA → FAT-041
  ///
  /// In ar, this message translates to:
  /// **'أضف من أي مصدر'**
  String get learningPathEmptyCta;

  /// SCR-FAT-047 loading semantics
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل المسار التعليمي'**
  String get learningPathLoadingSemantics;

  /// SCR-FAT-047 child lean title
  ///
  /// In ar, this message translates to:
  /// **'المسار التعليمي للوالدين'**
  String get learningPathChildLeanTitle;

  /// SCR-FAT-047 child lean message
  ///
  /// In ar, this message translates to:
  /// **'متابعة مسار الإتقان أداة والدية. زر الطوارئ يبقى متاحًا.'**
  String get learningPathChildLeanMessage;

  /// SCR-FAT-047 observer mother hint
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — فتح المواد للأب أو أم شريكة/كاملة.'**
  String get learningPathObserverHint;

  /// SCR-FAT-047 observer blocked toast
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — اطلب من الأب أو أم شريكة فتح المواد'**
  String get learningPathObserverBlocked;

  /// SCR-FAT-047 P-4 SOS CTA
  ///
  /// In ar, this message translates to:
  /// **'طوارئ'**
  String get learningPathSosCta;

  /// SCR-FAT-048 app bar title
  ///
  /// In ar, this message translates to:
  /// **'المواد والدروس'**
  String get materialsLessonsTitle;

  /// SCR-FAT-048 subject — math
  ///
  /// In ar, this message translates to:
  /// **'رياضيات'**
  String get materialsLessonsSubjectMath;

  /// SCR-FAT-048 subject — quran
  ///
  /// In ar, this message translates to:
  /// **'قرآن وتجويد'**
  String get materialsLessonsSubjectQuran;

  /// SCR-FAT-048 subject — english
  ///
  /// In ar, this message translates to:
  /// **'إنجليزية'**
  String get materialsLessonsSubjectEnglish;

  /// SCR-FAT-048 subject — science
  ///
  /// In ar, this message translates to:
  /// **'علوم'**
  String get materialsLessonsSubjectScience;

  /// SCR-FAT-048 math row subtitle with active path
  ///
  /// In ar, this message translates to:
  /// **'{lessons} دروس · {quizzes} اختبارات · مسار نشط'**
  String materialsLessonsMetaMathActive(int lessons, int quizzes);

  /// SCR-FAT-048 quran row subtitle
  ///
  /// In ar, this message translates to:
  /// **'ورد أسبوعي · من مصادر معتمدة'**
  String get materialsLessonsMetaQuranWeekly;

  /// SCR-FAT-048 english row subtitle
  ///
  /// In ar, this message translates to:
  /// **'{count} بطاقة حفظ'**
  String materialsLessonsMetaEnglishCards(int count);

  /// SCR-FAT-048 science row subtitle
  ///
  /// In ar, this message translates to:
  /// **'درس مستورد من المكتبة'**
  String get materialsLessonsMetaScienceImported;

  /// SCR-FAT-048 add subject button
  ///
  /// In ar, this message translates to:
  /// **'+ مادة'**
  String get materialsLessonsAddSubjectCta;

  /// SCR-FAT-048 add lesson button → FAT-041
  ///
  /// In ar, this message translates to:
  /// **'+ درس'**
  String get materialsLessonsAddLessonCta;

  /// SCR-FAT-048 CTA → FAT-049
  ///
  /// In ar, this message translates to:
  /// **'إنشاء واجب'**
  String get materialsLessonsAssignmentCta;

  /// SCR-FAT-048 add subject toast (prototype)
  ///
  /// In ar, this message translates to:
  /// **'مادة جديدة بلونها'**
  String get materialsLessonsAddSubjectToast;

  /// SCR-FAT-048 non-path subject tap toast
  ///
  /// In ar, this message translates to:
  /// **'دروس هذه المادة قريبًا'**
  String get materialsLessonsSubjectToast;

  /// SCR-FAT-048 empty state title
  ///
  /// In ar, this message translates to:
  /// **'لا مواد بعد'**
  String get materialsLessonsEmptyTitle;

  /// SCR-FAT-048 empty state message
  ///
  /// In ar, this message translates to:
  /// **'أضف مادة أو استورد درسًا — ثم نظّم المقررات والواجبات.'**
  String get materialsLessonsEmptyMessage;

  /// SCR-FAT-048 empty CTA → FAT-041
  ///
  /// In ar, this message translates to:
  /// **'أضف من أي مصدر'**
  String get materialsLessonsEmptyCta;

  /// SCR-FAT-048 loading semantics
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل المواد والدروس'**
  String get materialsLessonsLoadingSemantics;

  /// SCR-FAT-048 child lean title
  ///
  /// In ar, this message translates to:
  /// **'المواد والدروس للوالدين'**
  String get materialsLessonsChildLeanTitle;

  /// SCR-FAT-048 child lean message
  ///
  /// In ar, this message translates to:
  /// **'إدارة المواد والدروس أداة والدية. زر الطوارئ يبقى متاحًا.'**
  String get materialsLessonsChildLeanMessage;

  /// SCR-FAT-048 observer mother hint
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — إضافة المواد والدروس والواجبات للأب أو أم شريكة/كاملة.'**
  String get materialsLessonsObserverHint;

  /// SCR-FAT-048 observer blocked toast
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — اطلب من الأب أو أم شريكة إدارة المواد'**
  String get materialsLessonsObserverBlocked;

  /// SCR-FAT-048 P-4 SOS CTA
  ///
  /// In ar, this message translates to:
  /// **'طوارئ'**
  String get materialsLessonsSosCta;

  /// SCR-FAT-049 app bar title
  ///
  /// In ar, this message translates to:
  /// **'إنشاء واجب واختبار'**
  String get createAssignmentTitle;

  /// SCR-FAT-049 body heading with parametric child
  ///
  /// In ar, this message translates to:
  /// **'ماذا تريد أن تسند لـ {name}؟'**
  String createAssignmentHeading(String name);

  /// SCR-FAT-049 intro banner
  ///
  /// In ar, this message translates to:
  /// **'اختر نوع التكليف الذي يناسب يوم {name}، وسيتولى النظام توجيهه بدقة للشاشة المخصصة له.'**
  String createAssignmentIntroBanner(String name);

  /// SCR-FAT-049 Rule 23 child label one
  ///
  /// In ar, this message translates to:
  /// **'الابن الأول'**
  String get createAssignmentChildOne;

  /// SCR-FAT-049 Rule 23 child label two
  ///
  /// In ar, this message translates to:
  /// **'الابن الثاني'**
  String get createAssignmentChildTwo;

  /// SCR-FAT-049 Rule 23 child label three
  ///
  /// In ar, this message translates to:
  /// **'الابن الثالث'**
  String get createAssignmentChildThree;

  /// SCR-FAT-049 path 1 title
  ///
  /// In ar, this message translates to:
  /// **'١. واجب المدرسة البيتي (دفتر / منصة)'**
  String get createAssignmentHomeworkTitle;

  /// SCR-FAT-049 path 1 subtitle
  ///
  /// In ar, this message translates to:
  /// **'يحل في الدفتر المدرسي ويرفع صورة الحل'**
  String get createAssignmentHomeworkSubtitle;

  /// SCR-FAT-049 homework field hint
  ///
  /// In ar, this message translates to:
  /// **'مثال: حل صفحة ٤٥ في الرياضيات'**
  String get createAssignmentHomeworkHint;

  /// SCR-FAT-049 homework minutes reward (ع-١)
  ///
  /// In ar, this message translates to:
  /// **'المكافأة: +{minutes} دقيقة لعب لمحفظته'**
  String createAssignmentHomeworkReward(int minutes);

  /// SCR-FAT-049 homework proof tag
  ///
  /// In ar, this message translates to:
  /// **'صورة إثبات'**
  String get createAssignmentHomeworkProofTag;

  /// SCR-FAT-049 homework assign CTA
  ///
  /// In ar, this message translates to:
  /// **'إسناد الواجب المدرسي ←'**
  String get createAssignmentHomeworkCta;

  /// SCR-FAT-049 empty homework toast
  ///
  /// In ar, this message translates to:
  /// **'أدخل عنوان الواجب أولًا'**
  String get createAssignmentHomeworkEmptyToast;

  /// SCR-FAT-049 homework success toast
  ///
  /// In ar, this message translates to:
  /// **'أُسند الواجب المدرسي لـ {name}'**
  String createAssignmentHomeworkAssignedToast(String name);

  /// SCR-FAT-049 path 2 title
  ///
  /// In ar, this message translates to:
  /// **'٢. تثبيت فجوة مهارة (علاج التعثر)'**
  String get createAssignmentSkillTitle;

  /// SCR-FAT-049 path 2 subtitle
  ///
  /// In ar, this message translates to:
  /// **'مستخرجة مباشرة من تقرير النتائج'**
  String get createAssignmentSkillSubtitle;

  /// SCR-FAT-049 skill recommended tag
  ///
  /// In ar, this message translates to:
  /// **'موصى به'**
  String get createAssignmentSkillRecommendedTag;

  /// SCR-FAT-049 skill gap label
  ///
  /// In ar, this message translates to:
  /// **'فجوة المهارة المكتشفة في التقرير:'**
  String get createAssignmentSkillGapLabel;

  /// SCR-FAT-049 skill gap title key
  ///
  /// In ar, this message translates to:
  /// **'قسمة الكسور الاعتيادية'**
  String get createAssignmentSkillFractionDivision;

  /// SCR-FAT-049 skill gap display line
  ///
  /// In ar, this message translates to:
  /// **'➗ {title} ({detail})'**
  String createAssignmentSkillGapLine(String title, String detail);

  /// SCR-FAT-049 skill miss detail
  ///
  /// In ar, this message translates to:
  /// **'تعثر في {missed} من {total}'**
  String createAssignmentSkillMissed(int missed, int total);

  /// SCR-FAT-049 skill quiz ready line
  ///
  /// In ar, this message translates to:
  /// **'جاهز كويز تفاعلي فوري من {count} أسئلة متدرجة'**
  String createAssignmentSkillQuizReady(int count);

  /// SCR-FAT-049 skill assign CTA
  ///
  /// In ar, this message translates to:
  /// **'إسناد تحدي المهارة لـ {name} ككويز (+{minutes} دقيقة) ←'**
  String createAssignmentSkillCta(String name, int minutes);

  /// SCR-FAT-049 no skill gap message
  ///
  /// In ar, this message translates to:
  /// **'لا فجوة مهارة مفتوحة بعد — راجع متابعة النتائج بعد اختبار.'**
  String get createAssignmentSkillEmptyMessage;

  /// SCR-FAT-049 skill success toast
  ///
  /// In ar, this message translates to:
  /// **'أُسند تحدي المهارة لـ {name} (+{minutes} دقيقة)'**
  String createAssignmentSkillAssignedToast(String name, int minutes);

  /// SCR-FAT-049 path 3 title
  ///
  /// In ar, this message translates to:
  /// **'٣. سؤال تحدي عائلي خاص من الأب'**
  String get createAssignmentFamilyTitle;

  /// SCR-FAT-049 path 3 subtitle
  ///
  /// In ar, this message translates to:
  /// **'لغز، سؤال ذكاء، أو معلومة تثقيفية بود'**
  String get createAssignmentFamilySubtitle;

  /// SCR-FAT-049 family challenge field hint
  ///
  /// In ar, this message translates to:
  /// **'اكتب سؤالك هنا…'**
  String get createAssignmentFamilyHint;

  /// SCR-FAT-049 family challenge minutes (ع-١)
  ///
  /// In ar, this message translates to:
  /// **'المكافأة: +{minutes} دقيقة شجاعة'**
  String createAssignmentFamilyReward(int minutes);

  /// SCR-FAT-049 family gold-card tag
  ///
  /// In ar, this message translates to:
  /// **'بطاقة ذهبية'**
  String get createAssignmentFamilyGoldTag;

  /// SCR-FAT-049 family assign CTA
  ///
  /// In ar, this message translates to:
  /// **'إرسال التحدي كبطاقة فخمة ←'**
  String get createAssignmentFamilyCta;

  /// SCR-FAT-049 empty family question toast
  ///
  /// In ar, this message translates to:
  /// **'اكتب سؤال التحدي أولًا'**
  String get createAssignmentFamilyEmptyToast;

  /// SCR-FAT-049 family success toast
  ///
  /// In ar, this message translates to:
  /// **'أُرسل التحدي العائلي لـ {name}'**
  String createAssignmentFamilyAssignedToast(String name);

  /// SCR-FAT-049 CTA → FAT-050
  ///
  /// In ar, this message translates to:
  /// **'متابعة النتائج'**
  String get createAssignmentResultsCta;

  /// SCR-FAT-049 empty state title
  ///
  /// In ar, this message translates to:
  /// **'لا ابن لإسناده'**
  String get createAssignmentEmptyTitle;

  /// SCR-FAT-049 empty state message
  ///
  /// In ar, this message translates to:
  /// **'اربط ابنًا أولًا — ثم أسند واجبًا أو كويز مهارة أو تحديًا عائليًا.'**
  String get createAssignmentEmptyMessage;

  /// SCR-FAT-049 empty CTA → FAT-003
  ///
  /// In ar, this message translates to:
  /// **'إضافة ابن'**
  String get createAssignmentEmptyCta;

  /// SCR-FAT-049 loading semantics
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل إنشاء الواجب'**
  String get createAssignmentLoadingSemantics;

  /// SCR-FAT-049 child lean title
  ///
  /// In ar, this message translates to:
  /// **'الواجبات للوالدين'**
  String get createAssignmentChildLeanTitle;

  /// SCR-FAT-049 child lean message
  ///
  /// In ar, this message translates to:
  /// **'إنشاء الواجبات والاختبارات أداة والدية. زر الطوارئ يبقى متاحًا.'**
  String get createAssignmentChildLeanMessage;

  /// SCR-FAT-049 observer mother hint
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — إسناد الواجبات وكويز المهارة والتحدي العائلي للأب أو أم شريكة/كاملة.'**
  String get createAssignmentObserverHint;

  /// SCR-FAT-049 observer blocked toast
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — اطلب من الأب أو أم شريكة الإسناد'**
  String get createAssignmentObserverBlocked;

  /// SCR-FAT-049 P-4 SOS CTA
  ///
  /// In ar, this message translates to:
  /// **'طوارئ'**
  String get createAssignmentSosCta;

  /// SCR-FAT-050 app bar title
  ///
  /// In ar, this message translates to:
  /// **'نتائج وتفوق'**
  String get resultsFollowupTitle;

  /// SCR-FAT-050 body heading — Rule 23 generic child
  ///
  /// In ar, this message translates to:
  /// **'نتائج وتفوق {name}'**
  String resultsFollowupHeading(String name);

  /// SCR-FAT-050 generic child label (nameKey one)
  ///
  /// In ar, this message translates to:
  /// **'الابن الأول'**
  String get resultsFollowupChildOne;

  /// SCR-FAT-050 generic child label (nameKey two)
  ///
  /// In ar, this message translates to:
  /// **'الابن الثاني'**
  String get resultsFollowupChildTwo;

  /// SCR-FAT-050 generic child label (nameKey three)
  ///
  /// In ar, this message translates to:
  /// **'الابن الثالث'**
  String get resultsFollowupChildThree;

  /// SCR-FAT-050 mastery card caption
  ///
  /// In ar, this message translates to:
  /// **'مستوى إتقان {subject}'**
  String resultsFollowupMasteryCaption(String subject);

  /// SCR-FAT-050 mastery subject — math
  ///
  /// In ar, this message translates to:
  /// **'الرياضيات'**
  String get resultsFollowupMasterySubjectMath;

  /// SCR-FAT-050 mastery tag — steady average
  ///
  /// In ar, this message translates to:
  /// **'{percent}٪ متوسط'**
  String resultsFollowupMasteryAverageTag(int percent);

  /// SCR-FAT-050 mastery tag — improved after remediation
  ///
  /// In ar, this message translates to:
  /// **'ارتفع لـ {percent}٪ ↗'**
  String resultsFollowupMasteryImprovedTag(int percent);

  /// SCR-FAT-050 mastery hero percent
  ///
  /// In ar, this message translates to:
  /// **'{percent}٪'**
  String resultsFollowupMasteryHero(int percent);

  /// SCR-FAT-050 skill gap section title
  ///
  /// In ar, this message translates to:
  /// **'🧠 فجوات المهارات وعلاجها'**
  String get resultsFollowupGapSectionTitle;

  /// SCR-FAT-050 gap section tag — pending
  ///
  /// In ar, this message translates to:
  /// **'تحتاج تثبيتاً'**
  String get resultsFollowupGapNeedsFixTag;

  /// SCR-FAT-050 gap section tag — mastered
  ///
  /// In ar, this message translates to:
  /// **'تم التثبيت ✓'**
  String get resultsFollowupGapMasteredTag;

  /// SCR-FAT-050 skill gap title — fraction division
  ///
  /// In ar, this message translates to:
  /// **'قسمة الكسور الاعتيادية'**
  String get resultsFollowupSkillFractionDivision;

  /// SCR-FAT-050 pending gap detail line
  ///
  /// In ar, this message translates to:
  /// **'أخطأ في {missed} من {total} — تحتاج تمريناً علاجياً'**
  String resultsFollowupGapPendingDetail(int missed, int total);

  /// SCR-FAT-050 mastered gap detail line
  ///
  /// In ar, this message translates to:
  /// **'أنجز الكويز بنجاح وثبت المهارة بنسبة {percent}٪'**
  String resultsFollowupGapMasteredDetail(int percent);

  /// SCR-FAT-050 gap CTA → FAT-049
  ///
  /// In ar, this message translates to:
  /// **'علاج الفجوة ⚡'**
  String get resultsFollowupGapCta;

  /// SCR-FAT-050 mastered gap row tag
  ///
  /// In ar, this message translates to:
  /// **'متقن ⭐'**
  String get resultsFollowupGapMasteredLabel;

  /// SCR-FAT-050 activity log section title
  ///
  /// In ar, this message translates to:
  /// **'سجل الواجبات والأنشطة'**
  String get resultsFollowupActivitySectionTitle;

  /// SCR-FAT-050 activity row — homework title
  ///
  /// In ar, this message translates to:
  /// **'واجب الكسور المدرسي'**
  String get resultsFollowupActivitySchoolFractionsTitle;

  /// SCR-FAT-050 activity row — family challenge title
  ///
  /// In ar, this message translates to:
  /// **'تحدي اليوم من الأب'**
  String get resultsFollowupActivityDailyChallengeTitle;

  /// SCR-FAT-050 activity row — homework subtitle
  ///
  /// In ar, this message translates to:
  /// **'سلّمه في موعده · مصحح بالصورة 📸'**
  String get resultsFollowupActivityOnTimePhoto;

  /// SCR-FAT-050 activity row — family challenge subtitle (minutes only)
  ///
  /// In ar, this message translates to:
  /// **'أجاب بدقة وكسب +{minutes} دقيقة'**
  String resultsFollowupActivityEarnedMinutes(int minutes);

  /// SCR-FAT-050 activity status — homework complete
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get resultsFollowupActivityStatusComplete;

  /// SCR-FAT-050 activity status — family challenge approved
  ///
  /// In ar, this message translates to:
  /// **'معتمد'**
  String get resultsFollowupActivityStatusApproved;

  /// SCR-FAT-050 optional CTA → FAT-051
  ///
  /// In ar, this message translates to:
  /// **'تقرير جلسات التركيز'**
  String get resultsFollowupFocusCta;

  /// SCR-FAT-050 empty state title
  ///
  /// In ar, this message translates to:
  /// **'لا طفل للمتابعة'**
  String get resultsFollowupEmptyTitle;

  /// SCR-FAT-050 empty state message
  ///
  /// In ar, this message translates to:
  /// **'اربط طفلاً أولاً — ثم تابع الإتقان وفجوات المهارات ونتائج الواجبات.'**
  String get resultsFollowupEmptyMessage;

  /// SCR-FAT-050 empty CTA → FAT-003
  ///
  /// In ar, this message translates to:
  /// **'أضف طفلاً'**
  String get resultsFollowupEmptyCta;

  /// SCR-FAT-050 loading semantics
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل متابعة النتائج'**
  String get resultsFollowupLoadingSemantics;

  /// SCR-FAT-050 child lean title
  ///
  /// In ar, this message translates to:
  /// **'النتائج للوالدين'**
  String get resultsFollowupChildLeanTitle;

  /// SCR-FAT-050 child lean message
  ///
  /// In ar, this message translates to:
  /// **'متابعة النتائج والإتقان أداة والدية. زر الطوارئ يبقى متاحًا.'**
  String get resultsFollowupChildLeanMessage;

  /// SCR-FAT-050 observer mother hint
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — علاج فجوات المهارات للأب أو أم شريكة/كاملة.'**
  String get resultsFollowupObserverHint;

  /// SCR-FAT-050 observer blocked toast
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — اطلب من الأب أو أم شريكة علاج الفجوات'**
  String get resultsFollowupObserverBlocked;

  /// SCR-FAT-050 P-4 SOS CTA
  ///
  /// In ar, this message translates to:
  /// **'طوارئ'**
  String get resultsFollowupSosCta;

  /// SCR-FAT-036 app bar title
  ///
  /// In ar, this message translates to:
  /// **'فلترة الإنترنت'**
  String get webFilterTitle;

  /// SCR-FAT-036 ControlFit subtitle
  ///
  /// In ar, this message translates to:
  /// **'فئات الحظر تُحفظ وتُطبَّق على التصفح — ليست مفاتيح شكلية'**
  String get webFilterSubtitle;

  /// SCR-FAT-036 level section heading
  ///
  /// In ar, this message translates to:
  /// **'مستوى التصفية'**
  String get webFilterLevelHeading;

  /// SCR-FAT-036 level chip — strict
  ///
  /// In ar, this message translates to:
  /// **'صارم'**
  String get webFilterLevelStrict;

  /// SCR-FAT-036 level chip — balanced
  ///
  /// In ar, this message translates to:
  /// **'متوازن'**
  String get webFilterLevelBalanced;

  /// SCR-FAT-036 level chip — open
  ///
  /// In ar, this message translates to:
  /// **'مفتوح'**
  String get webFilterLevelOpen;

  /// SCR-FAT-036 categories list heading
  ///
  /// In ar, this message translates to:
  /// **'فئات الحظر'**
  String get webFilterCategoriesHeading;

  /// SCR-FAT-036 category — adults
  ///
  /// In ar, this message translates to:
  /// **'محتوى للبالغين'**
  String get webFilterCategoryAdults;

  /// SCR-FAT-036 category — gambling
  ///
  /// In ar, this message translates to:
  /// **'مقامرة'**
  String get webFilterCategoryGambling;

  /// SCR-FAT-036 category — violence
  ///
  /// In ar, this message translates to:
  /// **'عنف'**
  String get webFilterCategoryViolence;

  /// SCR-FAT-036 category — social
  ///
  /// In ar, this message translates to:
  /// **'تواصل اجتماعي'**
  String get webFilterCategorySocial;

  /// SCR-FAT-036 category — games
  ///
  /// In ar, this message translates to:
  /// **'ألعاب'**
  String get webFilterCategoryGames;

  /// SCR-FAT-036 category — streaming
  ///
  /// In ar, this message translates to:
  /// **'بث وترفيه'**
  String get webFilterCategoryStreaming;

  /// SCR-FAT-036 save CTA
  ///
  /// In ar, this message translates to:
  /// **'حفظ التصفية'**
  String get webFilterSave;

  /// SCR-FAT-036 save acknowledgement toast
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ فلترة الإنترنت'**
  String get webFilterSaveToast;

  /// SCR-FAT-036 read-only when not father
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — الأب يمكنه التعديل'**
  String get webFilterReadOnly;

  /// SET-005 father preview section heading (Qustodio/Net Nanny)
  ///
  /// In ar, this message translates to:
  /// **'معاينة ما يراه الابن'**
  String get webFilterPreviewHeading;

  /// SET-005 preview refresh-on-reopen note
  ///
  /// In ar, this message translates to:
  /// **'نفس قرار الحجب الذي يظهر للابن — أعد فتح المعاينة بعد تغيير السياسة'**
  String get webFilterPreviewHint;

  /// SET-005 preview URL field hint
  ///
  /// In ar, this message translates to:
  /// **'https://adult.example/…'**
  String get webFilterPreviewUrlHint;

  /// SET-005 preset fixture URL button
  ///
  /// In ar, this message translates to:
  /// **'استخدم مثال المحتوى للبالغين'**
  String get webFilterPreviewUseFixture;

  /// SET-005 open preview CTA
  ///
  /// In ar, this message translates to:
  /// **'معاينة ما يراه الابن'**
  String get webFilterPreviewButton;

  /// SET-005 preview sheet caption
  ///
  /// In ar, this message translates to:
  /// **'كيف يراه الابن'**
  String get webFilterPreviewSheetTitle;

  /// SET-005 child polite block title
  ///
  /// In ar, this message translates to:
  /// **'هذا الموقع محجوب الآن'**
  String get webBlockTitle;

  /// SET-005 allow state title (preview)
  ///
  /// In ar, this message translates to:
  /// **'هذا الموقع مسموح'**
  String get webBlockAllowedTitle;

  /// SET-005 allow state body
  ///
  /// In ar, this message translates to:
  /// **'لن تظهر صفحة حجب لهذا الرابط مع السياسة الحالية.'**
  String get webBlockAllowedBody;

  /// SET-005 unlock CTA seam (SET-006 wires loop)
  ///
  /// In ar, this message translates to:
  /// **'اطلب فتح الموقع من أبيك'**
  String get webBlockUnlockCta;

  /// SET-005 G-3 human reason — adults
  ///
  /// In ar, this message translates to:
  /// **'هذا المحتوى للبالغين ولا يناسبك الآن. إن كان مهمًا لدراستك يمكنك طلب فتحه بلطف.'**
  String get webBlockReasonAdults;

  /// SET-005 G-3 human reason — gambling
  ///
  /// In ar, this message translates to:
  /// **'هذا الموقع مرتبط بالمقامرة ولا يناسبك الآن.'**
  String get webBlockReasonGambling;

  /// SET-005 G-3 human reason — violence
  ///
  /// In ar, this message translates to:
  /// **'هذا المحتوى يتضمن عنفًا ولا يناسبك الآن.'**
  String get webBlockReasonViolence;

  /// SET-005 G-3 human reason — social
  ///
  /// In ar, this message translates to:
  /// **'مواقع التواصل محجوبة مؤقتًا حسب سياسة عائلتك.'**
  String get webBlockReasonSocial;

  /// SET-005 G-3 human reason — games
  ///
  /// In ar, this message translates to:
  /// **'ألعاب الإنترنت محجوبة مؤقتًا حسب سياسة عائلتك.'**
  String get webBlockReasonGames;

  /// SET-005 G-3 human reason — streaming
  ///
  /// In ar, this message translates to:
  /// **'مواقع البث والترفيه محجوبة مؤقتًا حسب سياسة عائلتك.'**
  String get webBlockReasonStreaming;

  /// SET-005 G-3 soft fallback reason
  ///
  /// In ar, this message translates to:
  /// **'هذا المحتوى لا يناسبك الآن. إن كنت تراه مهمًا لدراستك، اطلب فتحه من أبيك.'**
  String get webBlockReasonGeneric;

  /// SET-006 parent inbox heading on FAT-036
  ///
  /// In ar, this message translates to:
  /// **'طلبات فتح المواقع'**
  String get webUnlockInboxTitle;

  /// SET-006 parent inbox subtitle
  ///
  /// In ar, this message translates to:
  /// **'وافق أو ارفض المواقع التي طلب ابنك فتحها — مثل موافقة التطبيقات في Family Link'**
  String get webUnlockInboxSubtitle;

  /// SET-006 empty inbox
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات فتح معلّقة'**
  String get webUnlockInboxEmpty;

  /// SET-006 approve unlock
  ///
  /// In ar, this message translates to:
  /// **'موافقة'**
  String get webUnlockApprove;

  /// SET-006 deny unlock
  ///
  /// In ar, this message translates to:
  /// **'رفض'**
  String get webUnlockDeny;

  /// SET-006 mother observer cannot approve
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — الموافقة للأب أو مستوى مشاركة'**
  String get webUnlockObserverHint;

  /// SET-006 child toast after request
  ///
  /// In ar, this message translates to:
  /// **'أُرسل طلب الفتح إلى والديك'**
  String get webUnlockRequestedToast;

  /// SET-006 throttle toast
  ///
  /// In ar, this message translates to:
  /// **'طلبت فتح هذا الموقع من قبل'**
  String get webUnlockDuplicateToast;

  /// SET-006 child notified on approve
  ///
  /// In ar, this message translates to:
  /// **'وافق والداك على فتح هذا الموقع'**
  String get webUnlockApprovedToast;

  /// SET-006 child notified on deny
  ///
  /// In ar, this message translates to:
  /// **'أبقا والداك هذا الموقع محظورًا'**
  String get webUnlockDeniedToast;

  /// SCR-FAT-037 screen title
  ///
  /// In ar, this message translates to:
  /// **'القفل الفوري'**
  String get instantLockTitle;

  /// SCR-FAT-037 instant lock MVP switch
  ///
  /// In ar, this message translates to:
  /// **'قفل الجهاز الآن'**
  String get instantLockToggle;

  /// SCR-FAT-037 instant lock helper
  ///
  /// In ar, this message translates to:
  /// **'يقفل جهاز الابن فورًا مع بقاء الطوارئ والدردشة والقرآن متاحة'**
  String get instantLockSubtitle;

  /// SET-009 locked status label
  ///
  /// In ar, this message translates to:
  /// **'الجهاز مقفل'**
  String get instantLockStatusLocked;

  /// SET-009 unlocked status label
  ///
  /// In ar, this message translates to:
  /// **'الجهاز غير مقفل'**
  String get instantLockStatusUnlocked;

  /// SET-009 lockedBy father
  ///
  /// In ar, this message translates to:
  /// **'مقفل بواسطة الأب'**
  String get instantLockLockedByFather;

  /// SET-009 lockedBy mother
  ///
  /// In ar, this message translates to:
  /// **'مقفل بواسطة الأم'**
  String get instantLockLockedByMother;

  /// SET-009 Lock button
  ///
  /// In ar, this message translates to:
  /// **'قفل'**
  String get instantLockAction;

  /// SET-009 Unlock button
  ///
  /// In ar, this message translates to:
  /// **'فتح القفل'**
  String get instantLockUnlockAction;

  /// SET-009 lock/unlock denied toast
  ///
  /// In ar, this message translates to:
  /// **'غير مسموح بتغيير قفل الجهاز'**
  String get instantLockDeniedToast;

  /// SET-009 mother supersession banner
  ///
  /// In ar, this message translates to:
  /// **'الأب فتح القفل (تم تجاوز قفلك)'**
  String get instantLockSupersessionBanner;

  /// SET-007 father-only anti-tamper section
  ///
  /// In ar, this message translates to:
  /// **'الحماية من التلاعب'**
  String get antiTamperSectionTitle;

  /// SET-007 deep-link deny panel for mother/child
  ///
  /// In ar, this message translates to:
  /// **'غير متاح'**
  String get antiTamperUnavailable;

  /// SET-007 father save CTA
  ///
  /// In ar, this message translates to:
  /// **'حفظ الحماية'**
  String get antiTamperSave;

  /// SET-007 save acknowledgement
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ حماية التلاعب'**
  String get antiTamperSaveToast;

  /// SET-007 403 write denied toast
  ///
  /// In ar, this message translates to:
  /// **'غير مسموح بتعديل الحماية من التلاعب'**
  String get antiTamperDeniedToast;

  /// SET-007/008 stub label noDelete
  ///
  /// In ar, this message translates to:
  /// **'منع حذف التطبيق'**
  String get antiTamperNoDelete;

  /// SET-007/008 stub label noClockChange
  ///
  /// In ar, this message translates to:
  /// **'منع تغيير الساعة'**
  String get antiTamperNoClockChange;

  /// SET-007/008 stub label noVpn
  ///
  /// In ar, this message translates to:
  /// **'منع VPN'**
  String get antiTamperNoVpn;

  /// SET-007/008 stub label simAlert
  ///
  /// In ar, this message translates to:
  /// **'تنبيه تبديل الشريحة'**
  String get antiTamperSimAlert;

  /// SET-007/008 stub label settingsPin
  ///
  /// In ar, this message translates to:
  /// **'رمز إعدادات الجهاز'**
  String get antiTamperSettingsPin;

  /// SET-007/008 stub label bypassAlert
  ///
  /// In ar, this message translates to:
  /// **'تنبيه محاولة التحايل'**
  String get antiTamperBypassAlert;

  /// SET-008 whenEnabled noDelete (P-6 / frozen prototype)
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن إلغاء تثبيت عائلتي من جهاز الابن'**
  String get antiTamperNoDeleteWhenEnabled;

  /// SET-008 whenEnabled noClockChange
  ///
  /// In ar, this message translates to:
  /// **'أي تلاعب بالساعة يُعاد تلقائيًا ويُسجل'**
  String get antiTamperNoClockChangeWhenEnabled;

  /// SET-008 whenEnabled noVpn
  ///
  /// In ar, this message translates to:
  /// **'تُعطل فور تثبيتها ويصلك تنبيه'**
  String get antiTamperNoVpnWhenEnabled;

  /// SET-008 whenEnabled simAlert
  ///
  /// In ar, this message translates to:
  /// **'إشعار فوري إن أُخرجت شريحة الاتصال'**
  String get antiTamperSimAlertWhenEnabled;

  /// SET-008 whenEnabled settingsPin
  ///
  /// In ar, this message translates to:
  /// **'إعدادات الجهاز الحساسة تطلب رمز الأب'**
  String get antiTamperSettingsPinWhenEnabled;

  /// SET-008 whenEnabled bypassAlert
  ///
  /// In ar, this message translates to:
  /// **'أي محاولة التفاف تصلك لحظيًا كمعلومة تربوية'**
  String get antiTamperBypassAlertWhenEnabled;

  /// SET-008 honesty when Device Admin / OS grant missing (mock)
  ///
  /// In ar, this message translates to:
  /// **'يحتاج صلاحية الجهاز'**
  String get antiTamperNeedsDevicePermission;

  /// SCR-FAT-058 screen title
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notificationPrefsTitle;

  /// SCR-FAT-058 ControlFit subtitle
  ///
  /// In ar, this message translates to:
  /// **'ساعات الهدوء لكتم التنبيهات غير الحرجة فقط'**
  String get notificationPrefsSubtitle;

  /// SET-010 quiet hours switch
  ///
  /// In ar, this message translates to:
  /// **'ساعات الهدوء'**
  String get notificationPrefsQuietHours;

  /// SET-010 quiet start
  ///
  /// In ar, this message translates to:
  /// **'البداية'**
  String get notificationPrefsStart;

  /// SET-010 quiet end
  ///
  /// In ar, this message translates to:
  /// **'النهاية'**
  String get notificationPrefsEnd;

  /// SET-010 invalid quiet window
  ///
  /// In ar, this message translates to:
  /// **'حدّد وقت بداية ونهاية مختلفين'**
  String get notificationPrefsValidation;

  /// SET-010 save CTA
  ///
  /// In ar, this message translates to:
  /// **'حفظ الإشعارات'**
  String get notificationPrefsSave;

  /// SET-010 save acknowledgement
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ إعدادات الإشعارات'**
  String get notificationPrefsSaveToast;

  /// SET-010 / P-4 SOS always pierces quiet hours
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات الطوارئ (SOS) والتنبيهات الحرجة تصل دائماً — حتى أثناء ساعات الهدوء'**
  String get notificationPrefsSosPierceBanner;

  /// SET-011 which member row is loaded
  ///
  /// In ar, this message translates to:
  /// **'إعدادات {member}'**
  String notificationPrefsMemberHeading(String member);

  /// SET-011 father member label
  ///
  /// In ar, this message translates to:
  /// **'الأب'**
  String get notificationPrefsMemberFather;

  /// SET-011 mother member label
  ///
  /// In ar, this message translates to:
  /// **'الأم'**
  String get notificationPrefsMemberMother;

  /// SET-011 child member label
  ///
  /// In ar, this message translates to:
  /// **'الابن'**
  String get notificationPrefsMemberChild;

  /// SET-011 R-3 / S-AIC-029 mother analysis notices
  ///
  /// In ar, this message translates to:
  /// **'إشعارات التحليلات'**
  String get notificationPrefsAnalysisNotices;

  /// SET-011 analysis notices helper
  ///
  /// In ar, this message translates to:
  /// **'تحديثات اختيارية غير حرجة عند تحليلات المستشار'**
  String get notificationPrefsAnalysisNoticesHint;

  /// SCR-FAT-059 app bar title
  ///
  /// In ar, this message translates to:
  /// **'الخصوصية والبيانات'**
  String get privacyDataTitle;

  /// SCR-FAT-059 ControlFit subtitle (P-7 / Bark honesty)
  ///
  /// In ar, this message translates to:
  /// **'ما يُجمع عن الابن يظهر له بصدق — تبديل الأب يحدّث شاشة الشفافية'**
  String get privacyDataSubtitle;

  /// SCR-FAT-059 scopes section heading
  ///
  /// In ar, this message translates to:
  /// **'نطاقات الجمع'**
  String get privacyDataScopesHeading;

  /// SET-012 retention vs live collection honesty (no invent wipe)
  ///
  /// In ar, this message translates to:
  /// **'إيقاف الجمع الحي لا يمسح السجل التاريخي تلقائياً — الاحتفاظ ≠ الجمع الحالي'**
  String get privacyDataRetentionNote;

  /// SET-012 mother/non-owner read-only banner
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — تعديل الخصوصية للأب المالك'**
  String get privacyDataReadOnlyNote;

  /// SCR-FAT-059 save CTA
  ///
  /// In ar, this message translates to:
  /// **'حفظ نطاقات الجمع'**
  String get privacyDataSave;

  /// SCR-FAT-059 save acknowledgement
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ نطاقات الجمع'**
  String get privacyDataSaveToast;

  /// SET-012 father-only write denied toast
  ///
  /// In ar, this message translates to:
  /// **'غير مسموح — خصوصية المالك فقط'**
  String get privacyDataWriteDenied;

  /// SET-012 collection scope — location
  ///
  /// In ar, this message translates to:
  /// **'الموقع'**
  String get privacyScopeLocation;

  /// SET-012 collection scope — screen time
  ///
  /// In ar, this message translates to:
  /// **'وقت الشاشة'**
  String get privacyScopeScreenTime;

  /// SET-012 collection scope — web activity
  ///
  /// In ar, this message translates to:
  /// **'نشاط الويب'**
  String get privacyScopeWebActivity;

  /// SET-012 collection scope — communications
  ///
  /// In ar, this message translates to:
  /// **'التواصل'**
  String get privacyScopeCommunications;

  /// SCR-CHD-010 app bar title (S-ADM-035)
  ///
  /// In ar, this message translates to:
  /// **'ماذا يُجمع عني'**
  String get whatIsCollectedTitle;

  /// SCR-CHD-010 ControlFit subtitle
  ///
  /// In ar, this message translates to:
  /// **'هذه القائمة تعكس ما وافق ولي الأمر على جمعه عنك الآن'**
  String get whatIsCollectedSubtitle;

  /// SET-012 child cannot edit scopes
  ///
  /// In ar, this message translates to:
  /// **'شفافية بدون خداع — لا يمكنك تعديل هذه النطاقات'**
  String get whatIsCollectedHonestyNote;

  /// SET-012 empty enabled-scopes list
  ///
  /// In ar, this message translates to:
  /// **'لا يُجمع شيء عنك حالياً وفق إعدادات ولي الأمر'**
  String get whatIsCollectedEmpty;

  /// SET-012 offline/last-synced honesty
  ///
  /// In ar, this message translates to:
  /// **'آخر تحديث: {when}'**
  String whatIsCollectedLastUpdated(String when);

  /// SET-013 section heading — forget vs wipe
  ///
  /// In ar, this message translates to:
  /// **'الذاكرة وبيانات العائلة'**
  String get privacyLifecycleHeading;

  /// SET-013 forget CTA — advisor memory only
  ///
  /// In ar, this message translates to:
  /// **'نسيان ذاكرة المستشار'**
  String get privacyForgetButton;

  /// SET-013 single-confirm dialog title
  ///
  /// In ar, this message translates to:
  /// **'نسيان ذاكرة المستشار؟'**
  String get privacyForgetConfirmTitle;

  /// SET-013 forget explain — R10 honesty
  ///
  /// In ar, this message translates to:
  /// **'هذا يمسح ملاحظات ذاكرة المستشار فقط. المحادثات وسجل التدقيق يبقيان كما هما.'**
  String get privacyForgetConfirmBody;

  /// SET-013 forget dialog confirm
  ///
  /// In ar, this message translates to:
  /// **'نسيان الذاكرة'**
  String get privacyForgetConfirmAction;

  /// SET-013 forget success toast
  ///
  /// In ar, this message translates to:
  /// **'تم مسح ذاكرة المستشار'**
  String get privacyForgetToast;

  /// SET-013 wipe CTA — family lifecycle
  ///
  /// In ar, this message translates to:
  /// **'مسح بيانات العائلة'**
  String get privacyWipeButton;

  /// SET-013 wipe step-1 title
  ///
  /// In ar, this message translates to:
  /// **'مسح بيانات العائلة؟'**
  String get privacyWipeStep1Title;

  /// SET-013 wipe step-1 explain
  ///
  /// In ar, this message translates to:
  /// **'هذا يجدول مسحاً دائماً لبيانات العائلة. إدخالات سجل التدقيق لا تُحذف أبداً. لديك مهلة ندم ٧ أيام للإلغاء.'**
  String get privacyWipeStep1Body;

  /// SET-013 wipe step-1 continue
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get privacyWipeStep1Continue;

  /// SET-013 wipe step-2 title
  ///
  /// In ar, this message translates to:
  /// **'تأكيد جدولة المسح'**
  String get privacyWipeStep2Title;

  /// SET-013 wipe step-2 type-confirm
  ///
  /// In ar, this message translates to:
  /// **'اكتب {phrase} لجدولة المسح. التنفيذ ينتظر ٧ أيام — يمكنك الإلغاء في أي وقت خلال هذه المهلة.'**
  String privacyWipeStep2Body(String phrase);

  /// SET-013 type-to-confirm phrase (AR)
  ///
  /// In ar, this message translates to:
  /// **'مسح'**
  String get privacyWipeConfirmPhrase;

  /// SET-013 wipe step-2 confirm
  ///
  /// In ar, this message translates to:
  /// **'جدولة المسح'**
  String get privacyWipeStep2Action;

  /// SET-013 wipe scheduled toast
  ///
  /// In ar, this message translates to:
  /// **'تمت جدولة المسح — بدأت مهلة الندم ٧ أيام'**
  String get privacyWipeScheduledToast;

  /// SET-013 pending wipe banner
  ///
  /// In ar, this message translates to:
  /// **'مسح معلّق حتى {when} — ألغِ خلال ٧ أيام'**
  String privacyWipePendingBanner(String when);

  /// SET-013 cancel wipe within regret window
  ///
  /// In ar, this message translates to:
  /// **'إلغاء المسح المجدول'**
  String get privacyWipeCancelButton;

  /// SET-013 wipe cancel toast
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء المسح المجدول'**
  String get privacyWipeCancelledToast;

  /// SET-013 mother/child denied
  ///
  /// In ar, this message translates to:
  /// **'غير مسموح — النسيان/المسح للمالك فقط'**
  String get privacyLifecycleDeniedToast;

  /// SET-013 shared dialog dismiss
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get privacyDialogCancel;

  /// SET-013 mock audit panel — no forget
  ///
  /// In ar, this message translates to:
  /// **'سجل التدقيق (إضافة فقط)'**
  String get privacyAuditPanelTitle;

  /// SET-013 R10 honesty on audit panel
  ///
  /// In ar, this message translates to:
  /// **'زر النسيان لا يظهر هنا — سجل التدقيق لا يُمسح أبداً (R10)'**
  String get privacyAuditPanelHint;

  /// SET-013 empty audit panel
  ///
  /// In ar, this message translates to:
  /// **'لا إدخالات تدقيق بعد'**
  String get privacyAuditPanelEmpty;

  /// SCR-FAT-029 app bar title
  ///
  /// In ar, this message translates to:
  /// **'لوحة تحكم العقل'**
  String get brainControlTitle;

  /// SET-014 Rule 26 / Bark honesty banner
  ///
  /// In ar, this message translates to:
  /// **'الذكاء الاصطناعي يخدم — ولا يقرّر. يقترح فقط؛ القرار لك دائمًا (Bark).'**
  String get brainServesNotDecidesBanner;

  /// SET-014 stages section — server flags
  ///
  /// In ar, this message translates to:
  /// **'مراحل الذكاء (من الخادم)'**
  String get brainStagesHeading;

  /// SET-014 AiStageId.analyze
  ///
  /// In ar, this message translates to:
  /// **'المحلل'**
  String get brainStageAnalyzeTitle;

  /// SET-014 analyze subtitle
  ///
  /// In ar, this message translates to:
  /// **'أنماط وشذوذ — بوابة خادم عند التفعيل'**
  String get brainStageAnalyzeSubtitle;

  /// SET-014 AiStageId.suggest
  ///
  /// In ar, this message translates to:
  /// **'المستشار'**
  String get brainStageSuggestTitle;

  /// SET-014 suggest subtitle
  ///
  /// In ar, this message translates to:
  /// **'اقتراحات عملية — أنت توافق أو ترفض'**
  String get brainStageSuggestSubtitle;

  /// SET-014 AiStageId.coach
  ///
  /// In ar, this message translates to:
  /// **'المساعد'**
  String get brainStageCoachTitle;

  /// SET-014 coach subtitle
  ///
  /// In ar, this message translates to:
  /// **'أسئلة وإجابات من معرفة العائلة — بلا تنفيذ تلقائي'**
  String get brainStageCoachSubtitle;

  /// SET-014 flag-on tag
  ///
  /// In ar, this message translates to:
  /// **'نشطة'**
  String get brainStageActive;

  /// SET-014 flag-off coming-soon / disabled CTA
  ///
  /// In ar, this message translates to:
  /// **'قريبًا'**
  String get brainStageComingSoon;

  /// SET-014 flag-on CTA — opens mock AdvisorRepository
  ///
  /// In ar, this message translates to:
  /// **'عرض الاقتراحات'**
  String get brainStageViewSuggestions;

  /// SET-014 suggestions list heading
  ///
  /// In ar, this message translates to:
  /// **'اقتراحات المستشار (نموذج)'**
  String get brainSuggestionsHeading;

  /// SET-014 empty suggestions
  ///
  /// In ar, this message translates to:
  /// **'لا اقتراحات لهذه المرحلة الآن'**
  String get brainSuggestionsEmpty;

  /// SET-014 suggest-only hint under list
  ///
  /// In ar, this message translates to:
  /// **'لا شيء يُطبَّق تلقائيًا — راجع وقرّر.'**
  String get brainSuggestionsDecideHint;

  /// SET-015 mother/child deny panel for SCR-FAT-029
  ///
  /// In ar, this message translates to:
  /// **'غير متاح'**
  String get brainControlUnavailable;

  /// SCR-FAT-067 app bar title
  ///
  /// In ar, this message translates to:
  /// **'إعدادات الرقابة الذكية'**
  String get smartSupervisionTitle;

  /// SET-016 ControlFit subtitle — G1 platform honesty
  ///
  /// In ar, this message translates to:
  /// **'كل مفتاح يقرأ قدرة المنصة — لا ندّعي ما لا يعمل (صدق Screen Time).'**
  String get smartSupervisionSubtitle;

  /// SET-016 Screen Time honesty banner
  ///
  /// In ar, this message translates to:
  /// **'التبديل يعكس القدرة الفعلية للمنصة. غير المتاح يظهر معطّلًا — لا يبدو كمفعّل.'**
  String get smartSupervisionHonestyBanner;

  /// SET-016 platform label Android
  ///
  /// In ar, this message translates to:
  /// **'المنصة: أندرويد'**
  String get smartSupervisionPlatformAndroid;

  /// SET-016 platform label iOS
  ///
  /// In ar, this message translates to:
  /// **'المنصة: iOS'**
  String get smartSupervisionPlatformIos;

  /// SET-016 feature webFilter
  ///
  /// In ar, this message translates to:
  /// **'تصفية الويب'**
  String get smartSupervisionWebFilter;

  /// SET-016 feature appLimits
  ///
  /// In ar, this message translates to:
  /// **'حدود التطبيقات'**
  String get smartSupervisionAppLimits;

  /// SET-016 feature notificationListen
  ///
  /// In ar, this message translates to:
  /// **'مراقبة الإشعارات'**
  String get smartSupervisionNotificationListen;

  /// SET-016 feature locationAlways
  ///
  /// In ar, this message translates to:
  /// **'الموقع دائمًا'**
  String get smartSupervisionLocationAlways;

  /// SET-016 honesty badge for unavailable capability
  ///
  /// In ar, this message translates to:
  /// **'غير متاح على هذه المنصة'**
  String get smartSupervisionUnavailableBadge;

  /// SET-016 limited badge for reportsOnly
  ///
  /// In ar, this message translates to:
  /// **'تقارير فقط — محدود'**
  String get smartSupervisionLimitedBadge;

  /// SCR-FAT-068 app bar title
  ///
  /// In ar, this message translates to:
  /// **'مراقبة المنصات'**
  String get platformMonitoringTitle;

  /// SET-017 ControlFit subtitle
  ///
  /// In ar, this message translates to:
  /// **'كل منصة × ميزة تعرض القدرة الفعلية. غير المتاح لا يبدو كمفعّل بالكامل (صدق Screen Time).'**
  String get platformMonitoringSubtitle;

  /// SET-017 Rule 16 honesty banner
  ///
  /// In ar, this message translates to:
  /// **'الادعاءات المعطّلة تبقى باهتة ومطفأة — اللون المينت للمفعّل محجوز للقدرة الكاملة فقط.'**
  String get platformMonitoringHonestyBanner;

  /// SET-017 reportsOnly limited-state copy
  ///
  /// In ar, this message translates to:
  /// **'تقارير محدودة فقط — ليست إنفاذًا كاملًا.'**
  String get platformMonitoringLimitedHint;

  /// UI-018 offline last-capability honesty
  ///
  /// In ar, this message translates to:
  /// **'بدون اتصال — تُعرض آخر مصفوفة قدرات معروفة (ليست ادعاءات نظام حية).'**
  String get platformMonitoringOfflineBanner;

  /// UI-018 child effective monitoring section title
  ///
  /// In ar, this message translates to:
  /// **'الرقابة التي تنطبق عليّ'**
  String get effectiveMonitoringSectionTitle;

  /// UI-018 P-7 effective ≠ desired honesty
  ///
  /// In ar, this message translates to:
  /// **'تعكس ما يستطيع جهازك إنفاذه فعلًا — لا ما تمنّاه وليّ الأمر.'**
  String get effectiveMonitoringChildSubtitle;

  /// UI-018 empty effective monitoring list
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ميزات رقابة فعّالة على جهازك الآن'**
  String get effectiveMonitoringEmpty;

  /// UI-018 full effective monitoring badge
  ///
  /// In ar, this message translates to:
  /// **'نشط'**
  String get effectiveMonitoringFullBadge;

  /// SCR-FAT-085 app bar title
  ///
  /// In ar, this message translates to:
  /// **'الأوضاع الذكية'**
  String get smartModesTitle;

  /// SET-018 ControlFit subtitle — school on FAT-085 only
  ///
  /// In ar, this message translates to:
  /// **'فعّل وضعًا جاهزًا أو عدّل ساعات المدرسة هنا. المدرسة لا تفتح الشاشة المحذوفة FAT-039.'**
  String get smartModesSubtitle;

  /// SET-018 T-1 host map banner for S-SEC-058/059 → FAT-085
  ///
  /// In ar, this message translates to:
  /// **'جدول وضع المدرسة (S-SEC-058) والتفعيل (S-SEC-059) على هذه الشاشة — لا على شاهدة القبر FAT-039.'**
  String get smartModesHostBanner;

  /// SET-018 modes list heading
  ///
  /// In ar, this message translates to:
  /// **'الأوضاع الجاهزة'**
  String get smartModesListHeading;

  /// BuiltInModeId.sleep label
  ///
  /// In ar, this message translates to:
  /// **'النوم'**
  String get smartModeSleep;

  /// BuiltInModeId.school label
  ///
  /// In ar, this message translates to:
  /// **'المدرسة'**
  String get smartModeSchool;

  /// BuiltInModeId.study label
  ///
  /// In ar, this message translates to:
  /// **'الدراسة'**
  String get smartModeStudy;

  /// BuiltInModeId.ramadan label
  ///
  /// In ar, this message translates to:
  /// **'رمضان'**
  String get smartModeRamadan;

  /// BuiltInModeId.exams label
  ///
  /// In ar, this message translates to:
  /// **'الاختبارات'**
  String get smartModeExams;

  /// BuiltInModeId.vacation label
  ///
  /// In ar, this message translates to:
  /// **'الإجازة'**
  String get smartModeVacation;

  /// BuiltInModeId.custom label
  ///
  /// In ar, this message translates to:
  /// **'مخصص'**
  String get smartModeCustom;

  /// SET-018 school schedule start field
  ///
  /// In ar, this message translates to:
  /// **'بداية المدرسة'**
  String get smartModeSchoolStart;

  /// SET-018 school schedule end field
  ///
  /// In ar, this message translates to:
  /// **'نهاية المدرسة'**
  String get smartModeSchoolEnd;

  /// SCR-CHD-004 app bar title
  ///
  /// In ar, this message translates to:
  /// **'لوحة يومي'**
  String get childDayBoardTitle;

  /// SET-019 CHD-004 subtitle — live mode stream
  ///
  /// In ar, this message translates to:
  /// **'حالة يومك الآن — تتحدث عندما يفعّل ولي الأمر وضعًا ذكيًا'**
  String get childDayBoardSubtitle;

  /// SET-019 status card when no smart mode is active
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد وضع نشط الآن'**
  String get childDayBoardIdleStatus;

  /// SET-019 status card active mode label
  ///
  /// In ar, this message translates to:
  /// **'الوضع النشط: {modeName}'**
  String childDayBoardActiveStatus(String modeName);

  /// SET-019 soft enter notice toast
  ///
  /// In ar, this message translates to:
  /// **'دخل وضع {modeName}'**
  String childDayBoardModeEnter(String modeName);

  /// SET-019 soft exit notice toast
  ///
  /// In ar, this message translates to:
  /// **'انتهى وضع {modeName}'**
  String childDayBoardModeExit(String modeName);

  /// UI-005 mode + expiry together on CHD-004 status card
  ///
  /// In ar, this message translates to:
  /// **'ينتهي حوالي {time}'**
  String childDayBoardModeExpiry(String time);

  /// UI-005 last-synced honesty line on CHD-004
  ///
  /// In ar, this message translates to:
  /// **'آخر مزامنة: {time}'**
  String childDayBoardLastSynced(String time);

  /// UI-005 offline + last-synced banner on CHD-004
  ///
  /// In ar, this message translates to:
  /// **'دون اتصال — تُعرض آخر لوحة مزامَنة ({time}). تُحدَّث عند عودة الشبكة.'**
  String childDayBoardOfflineBanner(String time);

  /// SCR-FAT-033 / UI-006 app bar title
  ///
  /// In ar, this message translates to:
  /// **'طلبات الوقت الإضافي'**
  String get requestInboxTitle;

  /// UI-006 SHR-006 context name for empty inbox
  ///
  /// In ar, this message translates to:
  /// **'طلبات الوقت الإضافي'**
  String get requestInboxEmptyContext;

  /// UI-006 pending row title
  ///
  /// In ar, this message translates to:
  /// **'طلب +{minutes} دقيقة'**
  String requestInboxRequestedMinutes(int minutes);

  /// UI-006 grant chip section label
  ///
  /// In ar, this message translates to:
  /// **'دقائق المنحة'**
  String get requestInboxGrantLabel;

  /// UI-006 grant chip label
  ///
  /// In ar, this message translates to:
  /// **'{minutes} د'**
  String requestInboxGrantMinutes(int minutes);

  /// UI-006 mother ceiling honesty line
  ///
  /// In ar, this message translates to:
  /// **'سقف منحتك {minutes} دقيقة (ADR-039)'**
  String requestInboxCeilingHint(int minutes);

  /// UI-006 approve CTA
  ///
  /// In ar, this message translates to:
  /// **'موافقة'**
  String get requestInboxApprove;

  /// UI-006 reject CTA
  ///
  /// In ar, this message translates to:
  /// **'رفض'**
  String get requestInboxReject;

  /// UI-006 reject reason field label
  ///
  /// In ar, this message translates to:
  /// **'السبب لابنك'**
  String get requestInboxRejectReasonLabel;

  /// UI-006 reject reason field hint
  ///
  /// In ar, this message translates to:
  /// **'سيظهر له هذا السبب'**
  String get requestInboxRejectReasonHint;

  /// UI-006 reject without reason snackbar
  ///
  /// In ar, this message translates to:
  /// **'أضف سببًا ليفهم ابنك القرار'**
  String get requestInboxReasonRequired;

  /// UI-006 mother observer cannot decide
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — الشريكة أو الكاملة أو الأب يقررون'**
  String get requestInboxObserverHint;

  /// UI-006 offline honesty banner
  ///
  /// In ar, this message translates to:
  /// **'دون اتصال — تُحفظ قراراتك حتى تعود الشبكة.'**
  String get requestInboxOfflineBanner;

  /// UI-006 offline queue ack
  ///
  /// In ar, this message translates to:
  /// **'القرار في قائمة الانتظار'**
  String get requestInboxOfflineQueued;

  /// UI-006 AC3 child-visible reject reason
  ///
  /// In ar, this message translates to:
  /// **'رُفض طلبك: {reason}'**
  String requestInboxChildRejectedReason(String reason);

  /// UI-006 child approve toast/seam
  ///
  /// In ar, this message translates to:
  /// **'حصلت على +{minutes} دقيقة إضافية'**
  String requestInboxChildApproved(int minutes);

  /// SCR-SHR-006 / AppEmptyState title (mint)
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد شيء هنا بعد'**
  String get emptyStateTitle;

  /// SCR-SHR-006 empty body — prototype bigstate template
  ///
  /// In ar, this message translates to:
  /// **'عندما يحدث جديد في «{contextName}» ستجده هنا أولًا.'**
  String emptyStateMessage(String contextName);

  /// SCR-SHR-006 fallback context name when host omits one
  ///
  /// In ar, this message translates to:
  /// **'هذه الشاشة'**
  String get emptyStateDefaultContext;

  /// SCR-SHR-006 suggested action CTA
  ///
  /// In ar, this message translates to:
  /// **'حسنًا'**
  String get emptyStateActionCta;

  /// SCR-FAT-028 app bar title
  ///
  /// In ar, this message translates to:
  /// **'إعداد الطوارئ'**
  String get emergencySetupTitle;

  /// SET-020 SOS protocol banner on FAT-028
  ///
  /// In ar, this message translates to:
  /// **'عند طلب أي ابن للاستغاثة، يُخطر الأب والأم فوراً. إذا تعذّر الرد، يتصاعد البلاغ حسب هذا السلّم'**
  String get sosLadderProtocolBanner;

  /// SET-021 / P-4 SOS receipt ungradeable banner on FAT-028
  ///
  /// In ar, this message translates to:
  /// **'استلام تنبيهات الاستغاثة (SOS) لا يمكن إيقافه للأولياء — يصل للأم في كل المستويات بما فيها المطّلعة'**
  String get sosReceiptCannotDisableBanner;

  /// SET-020 subtitle — parents immovable on rung 1
  ///
  /// In ar, this message translates to:
  /// **'الوالدان مثبتان في الدرجة ١ — لا يمكن إزالتهما أو إيقاف تنبيه الطوارئ عنهما'**
  String get sosLadderSubtitle;

  /// SET-020 ladder section heading
  ///
  /// In ar, this message translates to:
  /// **'سلّم التصعيد المعتمد'**
  String get sosLadderHeading;

  /// SET-020 rung-1 father label
  ///
  /// In ar, this message translates to:
  /// **'الأب'**
  String get sosLadderFatherLabel;

  /// SET-020 rung-1 mother label
  ///
  /// In ar, this message translates to:
  /// **'الأم'**
  String get sosLadderMotherLabel;

  /// SET-020 locked rung-1 hint
  ///
  /// In ar, this message translates to:
  /// **'فوري ومباشر بلا أي تأخير · إشعار مسموع'**
  String get sosLadderRung1LockedHint;

  /// SET-020 mandatory lock tag for parents
  ///
  /// In ar, this message translates to:
  /// **'إلزامي'**
  String get sosLadderMandatoryTag;

  /// SET-020 inline validation error — parents immovable
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن إزالة الوالدين من الدرجة الأولى في سلّم الطوارئ'**
  String get sosLadderParentImmovableError;

  /// SET-020 add backup contact CTA
  ///
  /// In ar, this message translates to:
  /// **'إضافة جهة موثوقة خارج العائلة'**
  String get sosLadderAddBackup;

  /// SET-020 default name for new backup contact
  ///
  /// In ar, this message translates to:
  /// **'جهة احتياطية'**
  String get sosLadderBackupDefaultName;

  /// SET-020 default relation for new backup
  ///
  /// In ar, this message translates to:
  /// **'موثوق'**
  String get sosLadderBackupDefaultRelation;

  /// SET-020 backup delay subtitle
  ///
  /// In ar, this message translates to:
  /// **'بعد {seconds} ثانية بلا استجابة'**
  String sosLadderBackupDelay(int seconds);

  /// SCR-FAT-079 app bar title
  ///
  /// In ar, this message translates to:
  /// **'مساعدي الذكي — ماذا يفعل عني'**
  String get myAdvisorTitle;

  /// SET-022 ADR-038 / Bark honesty banner
  ///
  /// In ar, this message translates to:
  /// **'الذكاء الاصطناعي يخدم — ولا يقرّر. يقترح فقط؛ القرار لك دائمًا (Bark).'**
  String get myAdvisorServesBanner;

  /// SET-022 AI suggestions section label
  ///
  /// In ar, this message translates to:
  /// **'اقتراحات المستشار'**
  String get myAdvisorSuggestionsHeading;

  /// SET-022 suggest-only approve hint
  ///
  /// In ar, this message translates to:
  /// **'وافق لإنشاء قاعدة في محرك القواعد — الاقتراح نفسه لا يُنفَّذ.'**
  String get myAdvisorSuggestionsHint;

  /// SET-022 empty pending suggestions
  ///
  /// In ar, this message translates to:
  /// **'لا اقتراحات معلّقة الآن'**
  String get myAdvisorSuggestionsEmpty;

  /// SET-022 My rules section label
  ///
  /// In ar, this message translates to:
  /// **'قواعطي'**
  String get myAdvisorMyRulesHeading;

  /// SET-022 My rules section hint ADR-038
  ///
  /// In ar, this message translates to:
  /// **'قواعد حتمية ألّفها الأب أو وافق عليها — ليست اقتراحات ذكاء اصطناعي.'**
  String get myAdvisorMyRulesHint;

  /// SET-022 empty enabled rules
  ///
  /// In ar, this message translates to:
  /// **'لا قواعد مفعّلة بعد'**
  String get myAdvisorMyRulesEmpty;

  /// SET-022 approve suggestion CTA
  ///
  /// In ar, this message translates to:
  /// **'موافقة'**
  String get myAdvisorApprove;

  /// SET-022 reject suggestion CTA
  ///
  /// In ar, this message translates to:
  /// **'رفض'**
  String get myAdvisorReject;

  /// SET-022 mother/child read-only lean
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — موافقة القواعد للأب وحده (A-5).'**
  String get myAdvisorReadOnlyHint;

  /// SET-023 rule consequent picker heading
  ///
  /// In ar, this message translates to:
  /// **'محرّر القواعد — النتائج'**
  String get ruleEditorHeading;

  /// SET-023 allow-list picker hint
  ///
  /// In ar, this message translates to:
  /// **'اختر الأتمتة المسموحة فقط. أفعال المالك الحصرية لا تكون نتائج قواعد (Bark / ADR-038).'**
  String get ruleEditorHint;

  /// SET-023 save drafted rule CTA
  ///
  /// In ar, this message translates to:
  /// **'حفظ القاعدة'**
  String get ruleEditorSave;

  /// SET-023 ADR-038(d) forbidden consequent blocked
  ///
  /// In ar, this message translates to:
  /// **'مرفوض — مكافحة العبث، فتح التطبيقات المحظورة، وتعديل التفويض لا تكون نتائج قواعد.'**
  String get ruleEditorForbiddenBlocked;

  /// SET-023 allowed consequent label
  ///
  /// In ar, this message translates to:
  /// **'إشعار الأب'**
  String get ruleConsequentNotifyFather;

  /// SET-023 allowed consequent label
  ///
  /// In ar, this message translates to:
  /// **'منح دقائق'**
  String get ruleConsequentGrantMinutes;

  /// SET-023 allowed consequent label
  ///
  /// In ar, this message translates to:
  /// **'قفل مرن'**
  String get ruleConsequentSoftLock;

  /// SCR-CHD-001 AppBar title
  ///
  /// In ar, this message translates to:
  /// **'ترحيب الابن'**
  String get childWelcomeTitle;

  /// SCR-CHD-001 AppBar subtitle
  ///
  /// In ar, this message translates to:
  /// **'بداية لطيفة'**
  String get childWelcomeSubtitle;

  /// SCR-CHD-001 cartoon hero glyph
  ///
  /// In ar, this message translates to:
  /// **'🦁'**
  String get childWelcomeHeroEmoji;

  /// SCR-CHD-001 hero Semantics label
  ///
  /// In ar, this message translates to:
  /// **'شخصية ترحيب كرتونية'**
  String get childWelcomeHeroSemantics;

  /// SCR-CHD-001 headline — Rule 23 generic بطل
  ///
  /// In ar, this message translates to:
  /// **'أهلًا بك يا بطل!'**
  String get childWelcomeHeadline;

  /// SCR-CHD-001 body — no surveillance language
  ///
  /// In ar, this message translates to:
  /// **'هذا الجهاز سيرتبط بعائلتك — عشان يطمئنون عليك، وتلعب وتتعلم وتكسب دقائق لعب ⏱'**
  String get childWelcomeBody;

  /// SCR-CHD-001 CTA → CHD-002
  ///
  /// In ar, this message translates to:
  /// **'يلّا نبدأ 🚀'**
  String get childWelcomeContinue;

  /// SCR-CHD-001 CTA Semantics
  ///
  /// In ar, this message translates to:
  /// **'يلّا نبدأ — متابعة لمسح رمز الربط'**
  String get childWelcomeContinueSemantics;

  /// SCR-CHD-001 RoleGuard parent lean title
  ///
  /// In ar, this message translates to:
  /// **'لجهاز الابن'**
  String get childWelcomeParentLeanTitle;

  /// SCR-CHD-001 RoleGuard parent lean message
  ///
  /// In ar, this message translates to:
  /// **'ترحيب الابن مساحة لجهاز الابن بعد اختيار الوضع — ليست جزءًا من تجربة الوالدين.'**
  String get childWelcomeParentLeanMessage;

  /// SCR-CHD-002 app bar title
  ///
  /// In ar, this message translates to:
  /// **'امسح الرمز'**
  String get childQrTitle;

  /// SCR-CHD-002 app bar subtitle
  ///
  /// In ar, this message translates to:
  /// **'من جهاز والدك'**
  String get childQrSubtitle;

  /// SCR-CHD-002 scan instruction
  ///
  /// In ar, this message translates to:
  /// **'وجّه الكاميرا إلى الرمز الظاهر على جهاز والدك'**
  String get childQrInstruction;

  /// SCR-CHD-002 scan frame semantics
  ///
  /// In ar, this message translates to:
  /// **'إطار مسح رمز الربط'**
  String get childQrScanSemantics;

  /// UI-003 cross-role note — FAT-004 TTL untouched
  ///
  /// In ar, this message translates to:
  /// **'رمز والدك يبقى صالحًا حتى انتهاء مدته — المسح لا يُبطله (UF-01).'**
  String get childQrFatherTokenNote;

  /// SCR-CHD-002 mock scan CTA
  ///
  /// In ar, this message translates to:
  /// **'تمّ المسح ✓ (محاكاة)'**
  String get childQrSimulateScan;

  /// SCR-CHD-002 manual entry link
  ///
  /// In ar, this message translates to:
  /// **'تعذّر المسح؟ أدخله يدويًا'**
  String get childQrManualLink;

  /// SCR-CHD-002 lean manual hint toast
  ///
  /// In ar, this message translates to:
  /// **'افتح إعدادات الكاميرا أو أدخل الرمز يدويًا إن رُفضت الكاميرا دائمًا.'**
  String get childQrManualHintToast;

  /// UI-003 camera denied repair title
  ///
  /// In ar, this message translates to:
  /// **'نحتاج إذن الكاميرا'**
  String get childQrRepairTitle;

  /// UI-003 camera denied explain copy
  ///
  /// In ar, this message translates to:
  /// **'المسح يحتاج الكاميرا مرة واحدة لربط جهازك. افتح إعدادات النظام وفعّل الكاميرا لهذا التطبيق — لستَ في طريق مسدود.'**
  String get childQrRepairBody;

  /// UI-003 repair CTA ≥48dp — deep-link OS settings
  ///
  /// In ar, this message translates to:
  /// **'فتح إعدادات الكاميرا'**
  String get childQrOpenSettings;

  /// UI-003 mock settings deep-link toast
  ///
  /// In ar, this message translates to:
  /// **'فتح إعدادات النظام (محاكاة) — فعّل الكاميرا ثم عد.'**
  String get childQrOpenSettingsToast;

  /// UI-003 soft re-request permission
  ///
  /// In ar, this message translates to:
  /// **'حاول طلب الإذن مجددًا'**
  String get childQrRetryPermission;

  /// UI-003 permanently denied title
  ///
  /// In ar, this message translates to:
  /// **'الكاميرا غير متاحة — أدخل الرمز يدويًا'**
  String get childQrPermanentTitle;

  /// UI-003 permanently denied manual instructions
  ///
  /// In ar, this message translates to:
  /// **'على بعض الأجهزة يُرفض الإذن نهائيًا. افتح إعدادات النظام يدويًا وفعّل الكاميرا، أو اكتب الرمز المكوّن من ٨ أحرف الظاهر أسفل شاشة والدك.'**
  String get childQrPermanentBody;

  /// SCR-CHD-002 manual token placeholder
  ///
  /// In ar, this message translates to:
  /// **'A1B2-C3D4'**
  String get childQrManualPlaceholder;

  /// SCR-CHD-002 manual claim CTA
  ///
  /// In ar, this message translates to:
  /// **'ربط الجهاز ✓'**
  String get childQrManualSubmit;

  /// UI-003 UF-01 token validation error
  ///
  /// In ar, this message translates to:
  /// **'الرمز غير صالح — ٨ أحرف كما يظهر عند والدك (UF-01).'**
  String get childQrTokenInvalid;

  /// SCR-CHD-003 AppBar title — honesty charter
  ///
  /// In ar, this message translates to:
  /// **'بصراحة معك'**
  String get transparencyConsentTitle;

  /// SCR-CHD-003 AppBar subtitle
  ///
  /// In ar, this message translates to:
  /// **'قبل أن نبدأ'**
  String get transparencyConsentSubtitle;

  /// SCR-CHD-003 teal honesty banner — care not spy
  ///
  /// In ar, this message translates to:
  /// **'نحن لا نتجسس — نطمئن. وهذا بالضبط ما سيعرفه والداك عنك:'**
  String get transparencyConsentHonestyBanner;

  /// SCR-CHD-003 shared scopes card title
  ///
  /// In ar, this message translates to:
  /// **'✅ ما يُشارك مع عائلتك'**
  String get transparencyConsentSharedTitle;

  /// SCR-CHD-003 shared — location title
  ///
  /// In ar, this message translates to:
  /// **'موقعك'**
  String get transparencyConsentSharedLocationTitle;

  /// SCR-CHD-003 shared — location why
  ///
  /// In ar, this message translates to:
  /// **'عشان يطمئنون إنك بخير'**
  String get transparencyConsentSharedLocationBody;

  /// SCR-CHD-003 shared — screen time title
  ///
  /// In ar, this message translates to:
  /// **'وقت استخدامك للجوال'**
  String get transparencyConsentSharedScreenTimeTitle;

  /// SCR-CHD-003 shared — screen time why
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي وأسماء التطبيقات'**
  String get transparencyConsentSharedScreenTimeBody;

  /// SCR-CHD-003 shared — battery title
  ///
  /// In ar, this message translates to:
  /// **'بطارية جهازك'**
  String get transparencyConsentSharedBatteryTitle;

  /// SCR-CHD-003 shared — battery why
  ///
  /// In ar, this message translates to:
  /// **'عشان ما ينقطع التواصل'**
  String get transparencyConsentSharedBatteryBody;

  /// SCR-CHD-003 never-read card title
  ///
  /// In ar, this message translates to:
  /// **'⛔ ما لن يُقرأ أبدًا'**
  String get transparencyConsentNeverTitle;

  /// SCR-CHD-003 never — private message text
  ///
  /// In ar, this message translates to:
  /// **'نصوص رسائلك الخاصة'**
  String get transparencyConsentNeverMessagesTitle;

  /// SCR-CHD-003 never — category alert only
  ///
  /// In ar, this message translates to:
  /// **'يصلهم التنبيه بفئته فقط — لا كلامك'**
  String get transparencyConsentNeverMessagesBody;

  /// SCR-CHD-003 never — photos and files title
  ///
  /// In ar, this message translates to:
  /// **'صورك وملفاتك'**
  String get transparencyConsentNeverPhotosTitle;

  /// SCR-CHD-003 never — photos honesty line
  ///
  /// In ar, this message translates to:
  /// **'محتواها يبقى لك — لا يُفتح ولا يُقرأ'**
  String get transparencyConsentNeverPhotosBody;

  /// SCR-CHD-003 advisor notice card title
  ///
  /// In ar, this message translates to:
  /// **'🧠 وشيء أخير'**
  String get transparencyConsentAdvisorTitle;

  /// SCR-CHD-003 general advisor notice (charter)
  ///
  /// In ar, this message translates to:
  /// **'في التطبيق مساعد ذكي يساعد عائلتك على فهم يومك بشكل عام — وجوده معلن لك دائمًا هنا وفي تبويب «أنا».'**
  String get transparencyConsentAdvisorBody;

  /// SCR-CHD-003 CTA → CHD-004
  ///
  /// In ar, this message translates to:
  /// **'فهمت وأوافق ✓'**
  String get transparencyConsentAccept;

  /// SCR-CHD-003 CTA Semantics
  ///
  /// In ar, this message translates to:
  /// **'فهمت وأوافق — المتابعة إلى لوحة يومي'**
  String get transparencyConsentAcceptSemantics;

  /// SCR-CHD-003 RoleGuard parent lean title
  ///
  /// In ar, this message translates to:
  /// **'لجهاز الابن'**
  String get transparencyConsentParentLeanTitle;

  /// SCR-CHD-003 RoleGuard parent lean message
  ///
  /// In ar, this message translates to:
  /// **'إقرار الشفافية مساحة لجهاز الابن بعد الربط — ليست جزءًا من تجربة الوالدين.'**
  String get transparencyConsentParentLeanMessage;

  /// UI-004 empty-family greeting subtitle (Rule 23)
  ///
  /// In ar, this message translates to:
  /// **'لا أبناء مربوطون بعد — أضِف ابنًا عندما تكون مستعدًا'**
  String get dayBoardGreetingSubEmpty;

  /// UI-004 empty children card — never plant Khaled
  ///
  /// In ar, this message translates to:
  /// **'لا أبناء على اللوحة بعد'**
  String get dayBoardEmptyChildrenTitle;

  /// UI-004 empty children honesty (Rule 23)
  ///
  /// In ar, this message translates to:
  /// **'اربط جهاز ابن لترى حالته الحية هنا. بلا أسماء أو دقائق مزروعة.'**
  String get dayBoardEmptyChildrenSubtitle;

  /// UI-004 empty pending inbox card
  ///
  /// In ar, this message translates to:
  /// **'لا طلبات معلّقة'**
  String get dayBoardEmptyPendingTitle;

  /// UI-004 empty pending honesty
  ///
  /// In ar, this message translates to:
  /// **'عندما يطلب ابن وقتًا إضافيًا يظهر هنا — لا نصوص عيّنة مزروعة.'**
  String get dayBoardEmptyPendingSubtitle;

  /// UI-004 honest offline + last-synced banner
  ///
  /// In ar, this message translates to:
  /// **'دون اتصال — تُعرض آخر لوحة مزامَنة ({time}). تُحدَّث عند عودة الشبكة.'**
  String dayBoardOfflineBanner(String time);

  /// UI-004 fallback when last-synced time is unknown
  ///
  /// In ar, this message translates to:
  /// **'غير معروف'**
  String get dayBoardSyncUnknown;

  /// SCR-FAT-056 app bar title
  ///
  /// In ar, this message translates to:
  /// **'الباقات والاشتراك'**
  String get plansTitle;

  /// SCR-FAT-057 app bar title
  ///
  /// In ar, this message translates to:
  /// **'إدارة الاشتراك'**
  String get manageSubscriptionTitle;

  /// UI-007 mother/child deny banner on billing
  ///
  /// In ar, this message translates to:
  /// **'إدارة الاشتراك للمالك وحده — مع الحفاظ التام على أمان جميع أفراد العائلة.'**
  String get billingOwnerOnlyDeny;

  /// UI-007 / P-4 honesty banner — safety never paywalled
  ///
  /// In ar, this message translates to:
  /// **'مبدأ الأمان الدائم: حتى لو انتهت التجربة أو أُوقف التجديد، لن يتوقف تتبع الموقع أو نداء الاستغاثة أو محادثة العائلة أبدًا.'**
  String get billingSafetyNeverGated;

  /// UI-007 entitlement active tag
  ///
  /// In ar, this message translates to:
  /// **'نشطة'**
  String get billingStatusActive;

  /// UI-007 entitlement trial tag
  ///
  /// In ar, this message translates to:
  /// **'تجربة — باقٍ {days} أيام'**
  String billingStatusTrial(int days);

  /// UI-007 entitlement expired tag with safety honesty
  ///
  /// In ar, this message translates to:
  /// **'منتهية — الأمان مستمر'**
  String get billingStatusExpired;

  /// UI-007 cancel renewal toast
  ///
  /// In ar, this message translates to:
  /// **'تم إيقاف التجديد — الأمان الأساسي مستمر مجانًا'**
  String get billingCancelAck;

  /// UI-007 recommended paid plan title (provisional)
  ///
  /// In ar, this message translates to:
  /// **'باقة العائلة الذكية المتكاملة'**
  String get plansFamilySmartTitle;

  /// UI-007 recommended plan subtitle
  ///
  /// In ar, this message translates to:
  /// **'ذكاء العائلة الاصطناعي الكامل + الاستوديو التعليمي غير المحدود + ورد القرآن الصوتي بدون إنترنت لكافة الأبناء.'**
  String get plansFamilySmartSubtitle;

  /// UI-007 provisional price copy
  ///
  /// In ar, this message translates to:
  /// **'٢٩ ر.س / شهريًا لكل العائلة'**
  String get plansFamilySmartPrice;

  /// UI-007 free forever safety tier
  ///
  /// In ar, this message translates to:
  /// **'باقة الأمان الأساسي المستمر'**
  String get plansBasicSafetyTitle;

  /// UI-007 free tier subtitle
  ///
  /// In ar, this message translates to:
  /// **'مجانية تمامًا ومدى الحياة لكل عائلة.'**
  String get plansBasicSafetySubtitle;

  /// UI-007 free tier price
  ///
  /// In ar, this message translates to:
  /// **'مجانية مدى الحياة'**
  String get plansBasicSafetyPrice;

  /// UI-007 free tier SOS bullet
  ///
  /// In ar, this message translates to:
  /// **'تتبع الموقع المباشر وزر الاستغاثة SOS'**
  String get plansBasicBulletSos;

  /// UI-007 free tier chat bullet
  ///
  /// In ar, this message translates to:
  /// **'المحادثات والمكالمات الأسرية المشفّرة'**
  String get plansBasicBulletChat;

  /// UI-007 free tier screen-time bullet
  ///
  /// In ar, this message translates to:
  /// **'إدارة وقت الشاشة الأساسية والقفل الفوري'**
  String get plansBasicBulletScreenTime;

  /// UI-007 recommended plan tag
  ///
  /// In ar, this message translates to:
  /// **'الخيار الموصى به'**
  String get plansRecommended;

  /// UI-007 CTA to FAT-057
  ///
  /// In ar, this message translates to:
  /// **'إدارة الاشتراك'**
  String get plansOpenManage;

  /// UI-007 current plan heading
  ///
  /// In ar, this message translates to:
  /// **'الباقة الحالية: {name}'**
  String manageCurrentPlan(String name);

  /// UI-007 auto-renew on
  ///
  /// In ar, this message translates to:
  /// **'التجديد التلقائي: مفعّل'**
  String get manageAutoRenewOn;

  /// UI-007 auto-renew off honesty
  ///
  /// In ar, this message translates to:
  /// **'التجديد التلقائي: غير مفعّل (لن نخصم منك)'**
  String get manageAutoRenewOff;

  /// UI-007 CTA back to FAT-056
  ///
  /// In ar, this message translates to:
  /// **'ترقية الباقة أو تغييرها'**
  String get manageChangePlan;

  /// UI-007 cancel renewal CTA
  ///
  /// In ar, this message translates to:
  /// **'إيقاف التجديد'**
  String get manageCancelRenewal;

  /// UI-007 cancel path safety honesty
  ///
  /// In ar, this message translates to:
  /// **'إيقاف التجديد لا يوقف الاستغاثة أو الموقع أو محادثة العائلة أبدًا.'**
  String get manageCancelSafetyNote;

  /// SCR-CHD-021 / UI-011 app bar title
  ///
  /// In ar, this message translates to:
  /// **'انتهى الوقت — بلطف'**
  String get timeExpiryTitle;

  /// SCR-CHD-021 calm headline (not punitive)
  ///
  /// In ar, this message translates to:
  /// **'انتهى وقت اللعب اليوم'**
  String get timeExpiryHeadline;

  /// SCR-CHD-021 supportive body copy
  ///
  /// In ar, this message translates to:
  /// **'أحسنت اليوم! إنجازاتك ودقائقك محفوظة، ونلقاك غداً بنشاط.'**
  String get timeExpiryBody;

  /// UI-011 sealed banner — Rules 9/11 / C-1 exempts
  ///
  /// In ar, this message translates to:
  /// **'محادثة العائلة والقرآن يبقيان متاحين. نداء الطوارئ (SOS) يصل دائماً.'**
  String get timeExpiryExemptBanner;

  /// SCR-CHD-021 section heading for exempt CTAs
  ///
  /// In ar, this message translates to:
  /// **'ما زال متاحاً لك الآن:'**
  String get timeExpiryStillAvailable;

  /// UI-011 AC1 chat CTA title
  ///
  /// In ar, this message translates to:
  /// **'محادثة العائلة'**
  String get timeExpiryChatCta;

  /// UI-011 AC1 chat CTA subtitle (C-1)
  ///
  /// In ar, this message translates to:
  /// **'التواصل مع أبيك وأمك متاح دائماً'**
  String get timeExpiryChatSubtitle;

  /// UI-011 AC1 Quran CTA title
  ///
  /// In ar, this message translates to:
  /// **'ورْد القرآن والتعلّم'**
  String get timeExpiryQuranCta;

  /// UI-011 AC1 Quran CTA subtitle
  ///
  /// In ar, this message translates to:
  /// **'لا يُحسب من وقت اللعب ومتاح دائماً'**
  String get timeExpiryQuranSubtitle;

  /// UI-011 AC2 locked entertainment row title
  ///
  /// In ar, this message translates to:
  /// **'الألعاب والترفيه'**
  String get timeExpiryEntertainmentLocked;

  /// UI-011 AC2 locked entertainment subtitle
  ///
  /// In ar, this message translates to:
  /// **'مقفلة حتى الغد أو موافقة وقت إضافي'**
  String get timeExpiryEntertainmentSubtitle;

  /// UI-011 SOS CTA on expiry screen (P-4)
  ///
  /// In ar, this message translates to:
  /// **'نداء الطوارئ — متاح دائماً'**
  String get timeExpirySosCta;

  /// SCR-FAT-025 / UI-012 app bar — settings hub
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get deviceHealthSettingsTitle;

  /// UI-012 devices section heading on FAT-025
  ///
  /// In ar, this message translates to:
  /// **'الأجهزة'**
  String get deviceHealthDevicesHeading;

  /// UI-012 devices section subtitle
  ///
  /// In ar, this message translates to:
  /// **'الصحة والنبض والأذونات'**
  String get deviceHealthDevicesSubtitle;

  /// UI-012 amber hint when any device at risk
  ///
  /// In ar, this message translates to:
  /// **'جهاز قد ينقطع'**
  String get deviceHealthSectionAtRiskHint;

  /// UI-012 green health tag
  ///
  /// In ar, this message translates to:
  /// **'سليم'**
  String get deviceHealthStatusHealthy;

  /// UI-012 amber at-risk tag
  ///
  /// In ar, this message translates to:
  /// **'قد ينقطع الاتصال'**
  String get deviceHealthStatusAtRisk;

  /// UI-012 offline health tag
  ///
  /// In ar, this message translates to:
  /// **'غير متصل'**
  String get deviceHealthStatusOffline;

  /// UI-012 last heartbeat label
  ///
  /// In ar, this message translates to:
  /// **'آخر نبضة قبل {ago}'**
  String deviceHealthLastBeat(String ago);

  /// UI-012 battery percent
  ///
  /// In ar, this message translates to:
  /// **'البطارية {percent}٪'**
  String deviceHealthBattery(int percent);

  /// UI-012 offline last-health honesty
  ///
  /// In ar, this message translates to:
  /// **'عرض آخر صحة معروفة — الجهاز غير متصل الآن'**
  String get deviceHealthOfflineLastKnown;

  /// SCR-FAT-026 / UI-012 fallback app bar
  ///
  /// In ar, this message translates to:
  /// **'تفصيل الجهاز'**
  String get deviceHealthDetailTitle;

  /// UI-012 missing deviceId
  ///
  /// In ar, this message translates to:
  /// **'الجهاز غير موجود'**
  String get deviceHealthDeviceMissing;

  /// UI-012 permissions section
  ///
  /// In ar, this message translates to:
  /// **'حالة الأذونات'**
  String get deviceHealthPermissionsHeading;

  /// UI-012 location permission row
  ///
  /// In ar, this message translates to:
  /// **'الموقع طوال الوقت'**
  String get deviceHealthPermLocation;

  /// UI-012 accessibility permission row
  ///
  /// In ar, this message translates to:
  /// **'إمكانية الوصول'**
  String get deviceHealthPermAccessibility;

  /// UI-012 battery exemption row
  ///
  /// In ar, this message translates to:
  /// **'استثناء البطارية'**
  String get deviceHealthPermBattery;

  /// UI-012 auto-start permission row
  ///
  /// In ar, this message translates to:
  /// **'التشغيل التلقائي'**
  String get deviceHealthPermAutoStart;

  /// UI-012 granted tag
  ///
  /// In ar, this message translates to:
  /// **'ممنوح'**
  String get deviceHealthPermGranted;

  /// UI-012 denied tag — repairable
  ///
  /// In ar, this message translates to:
  /// **'مرفوض'**
  String get deviceHealthPermDenied;

  /// UI-012 permanently denied / RESTRICTED_BY_OS
  ///
  /// In ar, this message translates to:
  /// **'منعه النظام'**
  String get deviceHealthPermOsBlocked;

  /// UI-012 permanent-deny honesty under row
  ///
  /// In ar, this message translates to:
  /// **'منعه نظام الجهاز — ليس رفضًا منكم'**
  String get deviceHealthOsBlockedHint;

  /// UI-012 permanently denied edge banner
  ///
  /// In ar, this message translates to:
  /// **'بعض الأذونات يمنعها نظام الجهاز نفسه. افتح الإعدادات وأصلحها يدويًا ثم ارجع — سنعيد الفحص دون إعادة تثبيت التطبيق.'**
  String get deviceHealthPermanentExplain;

  /// UI-012 repair CTA — open OS settings
  ///
  /// In ar, this message translates to:
  /// **'أصلح المعطّل'**
  String get deviceHealthRepairCta;

  /// UI-012 mock settings deep-link toast
  ///
  /// In ar, this message translates to:
  /// **'فُتحت إعدادات النظام على الجهاز (محاكاة)'**
  String get deviceHealthOpenSettingsToast;

  /// SCR-FAT-026 بوابة ٤ OEM warning — {oem} brand only
  ///
  /// In ar, this message translates to:
  /// **'أجهزة {oem} تحتاج خطوة خاصة — نظام توفير الطاقة يوقف الحماية بعد دقائق من إطفاء الشاشة.'**
  String deviceHealthOemBanner(String oem);

  /// SCR-FAT-026 manufacturer guide heading — no person names
  ///
  /// In ar, this message translates to:
  /// **'لكي لا ينقطع الجهاز عنك'**
  String get deviceHealthGuideHeading;

  /// SCR-FAT-026 OEM guide step 1
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات ← التطبيقات ← عائلتي'**
  String get deviceHealthGuideStep1;

  /// SCR-FAT-026 OEM guide step 2
  ///
  /// In ar, this message translates to:
  /// **'فعّل «التشغيل التلقائي»'**
  String get deviceHealthGuideStep2;

  /// SCR-FAT-026 OEM guide step 3
  ///
  /// In ar, this message translates to:
  /// **'البطارية ← بلا قيود'**
  String get deviceHealthGuideStep3;

  /// SCR-FAT-026 primary deep-link CTA in OEM guide
  ///
  /// In ar, this message translates to:
  /// **'افتح الإعداد الآن'**
  String get deviceHealthOpenSettingsNowCta;

  /// SCR-FAT-026 open-settings-now honesty toast
  ///
  /// In ar, this message translates to:
  /// **'فُتحت شاشة الإعداد الصحيحة على الجهاز (محاكاة Intent)'**
  String get deviceHealthOpenSettingsNowToast;

  /// SCR-FAT-026 repair CTA honesty toast
  ///
  /// In ar, this message translates to:
  /// **'أُرسل طلب إصلاح للجهاز مع الدليل (محاكاة)'**
  String get deviceHealthRepairRequestToast;

  /// SCR-FAT-026 child-role lean title
  ///
  /// In ar, this message translates to:
  /// **'لأولياء الأمور'**
  String get deviceHealthChildLeanTitle;

  /// SCR-FAT-026 child-role lean message
  ///
  /// In ar, this message translates to:
  /// **'تفصيل صحة الجهاز للوالدين — إعداداتك تظهر في تبويب «أنا».'**
  String get deviceHealthChildLeanMessage;

  /// SCR-FAT-075 / UI-013 app bar
  ///
  /// In ar, this message translates to:
  /// **'ميزات قادمة'**
  String get comingSoonTitle;

  /// UI-013 AC1 honesty — no fake dates (Rule 23)
  ///
  /// In ar, this message translates to:
  /// **'خارطة ما بعد الإطلاق — نبنيها بإتقان، دون وعود بتواريخ.'**
  String get comingSoonHonestyBanner;

  /// UI-013 feature catalog heading
  ///
  /// In ar, this message translates to:
  /// **'ما نجهّزه لكم'**
  String get comingSoonSectionHeading;

  /// UI-013 must not look like working settings
  ///
  /// In ar, this message translates to:
  /// **'أسماء فقط — ليست إعدادات جاهزة للعمل.'**
  String get comingSoonSectionHint;

  /// UI-013 non-interactive status tag
  ///
  /// In ar, this message translates to:
  /// **'قريبًا'**
  String get comingSoonTag;

  /// UI-013 AC2 — no pretend toggles (G-3)
  ///
  /// In ar, this message translates to:
  /// **'هذه ليست عناصر تحكم جاهزة. لا يمكن تشغيل أو إيقاف أي شيء هنا.'**
  String get comingSoonNotSettingsBanner;

  /// UI-013 Wave-3B catalog row
  ///
  /// In ar, this message translates to:
  /// **'فلترة الراوتر المنزلي'**
  String get comingSoonFeatureRouterFilter;

  /// UI-013 Wave-3B catalog subtitle
  ///
  /// In ar, this message translates to:
  /// **'فلترة على مستوى الشبكة عندما تصبح جاهزة'**
  String get comingSoonFeatureRouterFilterSub;

  /// UI-013 Wave-3B catalog row
  ///
  /// In ar, this message translates to:
  /// **'السلامة على الطريق'**
  String get comingSoonFeatureRoadSafety;

  /// UI-013 Wave-3B catalog subtitle
  ///
  /// In ar, this message translates to:
  /// **'حوادث · قيادة · تنبيه الجوال أثناء القيادة'**
  String get comingSoonFeatureRoadSafetySub;

  /// UI-013 Wave-3B catalog row
  ///
  /// In ar, this message translates to:
  /// **'مقارنة الأقران'**
  String get comingSoonFeaturePeerCompare;

  /// UI-013 Wave-3B catalog subtitle
  ///
  /// In ar, this message translates to:
  /// **'مقارنة مجهولة ومطمئنة'**
  String get comingSoonFeaturePeerCompareSub;

  /// UI-013 Wave-3B catalog row
  ///
  /// In ar, this message translates to:
  /// **'موزع المهام الذكي'**
  String get comingSoonFeatureChoreAi;

  /// UI-013 Wave-3B catalog subtitle
  ///
  /// In ar, this message translates to:
  /// **'توزيع عادل للمهام بين أفراد الأسرة'**
  String get comingSoonFeatureChoreAiSub;

  /// UI-013 Wave-3B catalog row
  ///
  /// In ar, this message translates to:
  /// **'المحادثة الصوتية مع مستشار العائلة'**
  String get comingSoonFeatureVoiceAdvisor;

  /// UI-013 Wave-3B catalog subtitle
  ///
  /// In ar, this message translates to:
  /// **'محادثة صوتية مع المستشار عند جاهزيتها'**
  String get comingSoonFeatureVoiceAdvisorSub;

  /// UI-013 Wave-3B catalog row
  ///
  /// In ar, this message translates to:
  /// **'مشروع بمراحل'**
  String get comingSoonFeaturePhasedProject;

  /// UI-013 Wave-3B catalog subtitle
  ///
  /// In ar, this message translates to:
  /// **'مشاريع الاستوديو على مراحل'**
  String get comingSoonFeaturePhasedProjectSub;

  /// UI-013 Wave-3B catalog row
  ///
  /// In ar, this message translates to:
  /// **'تلاوة الابن الذكية'**
  String get comingSoonFeatureSmartRecitation;

  /// UI-013 Wave-3B catalog subtitle
  ///
  /// In ar, this message translates to:
  /// **'دعم التلاوة بعين الابن'**
  String get comingSoonFeatureSmartRecitationSub;

  /// UI-013 Wave-3B catalog row
  ///
  /// In ar, this message translates to:
  /// **'الوكيل المفوَّض'**
  String get comingSoonFeatureDelegatedAgent;

  /// UI-013 Wave-3B catalog subtitle
  ///
  /// In ar, this message translates to:
  /// **'أتمتة محدودة مع تدقيق وتراجع'**
  String get comingSoonFeatureDelegatedAgentSub;

  /// UI-014 screen-reader label for SOS fire/entry CTA
  ///
  /// In ar, this message translates to:
  /// **'إرسال نداء الطوارئ SOS'**
  String get spineCtaSosSemantics;

  /// UI-014 screen-reader label for instant lock CTA
  ///
  /// In ar, this message translates to:
  /// **'قفل جهاز الابن فوراً'**
  String get spineCtaLockSemantics;

  /// UI-014 screen-reader label for instant unlock CTA
  ///
  /// In ar, this message translates to:
  /// **'فتح قفل جهاز الابن'**
  String get spineCtaUnlockSemantics;

  /// UI-014 screen-reader label for request-inbox approve CTA
  ///
  /// In ar, this message translates to:
  /// **'الموافقة على طلب الوقت الإضافي'**
  String get spineCtaApproveSemantics;

  /// UI-014 screen-reader label for request-inbox reject CTA
  ///
  /// In ar, this message translates to:
  /// **'رفض طلب الوقت الإضافي'**
  String get spineCtaRejectSemantics;

  /// UI-014 screen-reader label for grant chip
  ///
  /// In ar, this message translates to:
  /// **'منح {minutes} دقيقة'**
  String spineCtaGrantMinutesSemantics(int minutes);

  /// UI-014 icon-only back CTA on request inbox
  ///
  /// In ar, this message translates to:
  /// **'رجوع من صندوق الطلبات'**
  String get requestInboxBackSemantics;

  /// UI-014 icon-only remove on SOS ladder backup row
  ///
  /// In ar, this message translates to:
  /// **'إزالة جهة احتياطية من سلم الطوارئ'**
  String get sosLadderBackupRemoveSemantics;

  /// SCR-FAT-011 app bar — اقتراحات العقل
  ///
  /// In ar, this message translates to:
  /// **'اقتراحات مستشار العائلة'**
  String get advisorSuggestionsTitle;

  /// SCR-FAT-011 Bark suggest-only honesty banner
  ///
  /// In ar, this message translates to:
  /// **'مستشار العائلة يقترح — وأنت تقرر. لا شيء يُطبَّق من تلقاء نفسه. (AI Serves, Not Decides)'**
  String get advisorSuggestionsServesBanner;

  /// SCR-FAT-011 suggestion card seal chip
  ///
  /// In ar, this message translates to:
  /// **'ختم مستشار العائلة'**
  String get advisorSuggestionsSeal;

  /// SCR-FAT-011 approve CTA — opens confirm
  ///
  /// In ar, this message translates to:
  /// **'موافقة'**
  String get advisorSuggestionsApprove;

  /// SCR-FAT-011 reject CTA
  ///
  /// In ar, this message translates to:
  /// **'رفض'**
  String get advisorSuggestionsReject;

  /// SCR-FAT-011 explicit approve confirm title
  ///
  /// In ar, this message translates to:
  /// **'إضافة إلى قواعطي؟'**
  String get advisorSuggestionsApproveConfirmTitle;

  /// SCR-FAT-011 explicit approve confirm body (ADR-038)
  ///
  /// In ar, this message translates to:
  /// **'الموافقة تنشئ قاعدة في محرك القواعد. الاقتراح نفسه لا يُنفَّذ تلقائيًا — القرار لك.'**
  String get advisorSuggestionsApproveConfirmBody;

  /// SCR-FAT-011 confirm dialog primary action
  ///
  /// In ar, this message translates to:
  /// **'نعم، أضف للقواعد'**
  String get advisorSuggestionsApproveConfirmAction;

  /// SCR-FAT-011 confirm dialog cancel
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get advisorSuggestionsApproveCancel;

  /// SCR-FAT-011 mother/child read-only lean
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — موافقة الاقتراحات للأب وحده (A-5).'**
  String get advisorSuggestionsReadOnlyHint;

  /// SCR-FAT-011 AppEmptyState title
  ///
  /// In ar, this message translates to:
  /// **'لا اقتراحات الآن'**
  String get advisorSuggestionsEmptyTitle;

  /// SCR-FAT-011 AppEmptyState message
  ///
  /// In ar, this message translates to:
  /// **'عندما يقترح مستشار العائلة شيئًا، يظهر هنا — وأنت تقرر الموافقة أو الرفض.'**
  String get advisorSuggestionsEmptyMessage;

  /// SCR-FAT-011 stage 1–2 on-device privacy footer
  ///
  /// In ar, this message translates to:
  /// **'المرحلتان ١–٢ تعملان على الجهاز — خصوصية كاملة ومجانية'**
  String get advisorSuggestionsPrivacyFooter;

  /// SCR-FAT-011 suggestions list Semantics label
  ///
  /// In ar, this message translates to:
  /// **'قائمة اقتراحات مستشار العائلة'**
  String get advisorSuggestionsListSemantics;

  /// SCR-FAT-012 app bar — قائمة الأبناء
  ///
  /// In ar, this message translates to:
  /// **'أبنائي'**
  String get childrenListTitle;

  /// SCR-FAT-012 add-child CTA → FAT-003
  ///
  /// In ar, this message translates to:
  /// **'+ إضافة ابن'**
  String get childrenListAddChild;

  /// SCR-FAT-012 remaining screen-time label
  ///
  /// In ar, this message translates to:
  /// **'متبقٍ {time}'**
  String childrenListTimeLeft(String time);

  /// SCR-FAT-012 health tag excellent
  ///
  /// In ar, this message translates to:
  /// **'ممتاز'**
  String get childrenListHealthExcellent;

  /// SCR-FAT-012 health tag at-risk connection
  ///
  /// In ar, this message translates to:
  /// **'قد ينقطع'**
  String get childrenListHealthAtRisk;

  /// SCR-FAT-012 shared policies card title
  ///
  /// In ar, this message translates to:
  /// **'إعدادات مشتركة لكل الأبناء'**
  String get childrenListSharedPoliciesTitle;

  /// SCR-FAT-012 shared policies card subtitle — override honesty
  ///
  /// In ar, this message translates to:
  /// **'قاعدة واحدة تعمّ الجميع — والاستثناء الفردي يغلب (دستورك)'**
  String get childrenListSharedPoliciesSubtitle;

  /// SCR-FAT-012 shared policies sheet title
  ///
  /// In ar, this message translates to:
  /// **'إعدادات مشتركة'**
  String get childrenListSharedSheetTitle;

  /// SCR-FAT-012 Family Link/Qustodio shared-rules honesty
  ///
  /// In ar, this message translates to:
  /// **'تُطبق على من تختار — وأي إعداد فردي لاحق يغلبها ويظهر كاستثناء.'**
  String get childrenListSharedHonesty;

  /// SCR-FAT-012 shared scope label
  ///
  /// In ar, this message translates to:
  /// **'تشمل:'**
  String get childrenListSharedScopeLabel;

  /// SCR-FAT-012 apply shared rules to all children
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get childrenListSharedScopeAll;

  /// SCR-FAT-012 apply shared rules to selected children
  ///
  /// In ar, this message translates to:
  /// **'أبناء محددون'**
  String get childrenListSharedScopeSome;

  /// SCR-FAT-012 unified daily cap row
  ///
  /// In ar, this message translates to:
  /// **'الحد اليومي الموحد'**
  String get childrenListSharedDailyCap;

  /// SCR-FAT-012 daily cap hours value
  ///
  /// In ar, this message translates to:
  /// **'{hours} ساعات'**
  String childrenListSharedDailyCapValue(int hours);

  /// SCR-FAT-012 unified bedtime row
  ///
  /// In ar, this message translates to:
  /// **'وقت النوم الموحد'**
  String get childrenListSharedBedtime;

  /// SCR-FAT-012 shared web filter row
  ///
  /// In ar, this message translates to:
  /// **'فلترة الويب'**
  String get childrenListSharedWebFilter;

  /// SCR-FAT-012 shared web filter hint
  ///
  /// In ar, this message translates to:
  /// **'مستوى واحد للجميع'**
  String get childrenListSharedWebFilterHint;

  /// SCR-FAT-012 individual override honesty title
  ///
  /// In ar, this message translates to:
  /// **'استثناءات فردية نشطة (تغلب المشترك)'**
  String get childrenListSharedExceptionsTitle;

  /// SCR-FAT-012 individual override honesty body (no planted names)
  ///
  /// In ar, this message translates to:
  /// **'أي حد فردي في ملف الابن يغلب القاعدة المشتركة — لا تُمحى الاستثناءات عند التطبيق على الجميع.'**
  String get childrenListSharedExceptionsBody;

  /// SCR-FAT-012 apply shared policies CTA (father)
  ///
  /// In ar, this message translates to:
  /// **'تطبيق على الجميع ✓'**
  String get childrenListSharedApply;

  /// SCR-FAT-012 AppEmptyState title
  ///
  /// In ar, this message translates to:
  /// **'لا أبناء بعد'**
  String get childrenListEmptyTitle;

  /// SCR-FAT-012 AppEmptyState message
  ///
  /// In ar, this message translates to:
  /// **'أضف ابنًا لترى حالته وموقعه ووقت الشاشة هنا — القائمة فارغة حتى تربط جهازًا.'**
  String get childrenListEmptyMessage;

  /// SCR-FAT-012 child-role lean title
  ///
  /// In ar, this message translates to:
  /// **'لأولياء الأمور'**
  String get childrenListChildLeanTitle;

  /// SCR-FAT-012 child-role lean message
  ///
  /// In ar, this message translates to:
  /// **'قائمة الأبناء مساحة للوالدين لمتابعة العائلة — ليست جزءًا من تجربة الابن.'**
  String get childrenListChildLeanMessage;

  /// SCR-FAT-012 loading Semantics
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل قائمة الأبناء'**
  String get childrenListLoadingSemantics;

  /// SCR-FAT-012 roster list Semantics
  ///
  /// In ar, this message translates to:
  /// **'قائمة الأبناء'**
  String get childrenListListSemantics;

  /// SCR-FAT-012 child row Semantics
  ///
  /// In ar, this message translates to:
  /// **'{name}، {age}، {location}، البطارية {battery}، الصحة {health}'**
  String childrenListRowSemantics(
    String name,
    String age,
    String location,
    String battery,
    String health,
  );

  /// SCR-FAT-013 app bar fallback when name unknown
  ///
  /// In ar, this message translates to:
  /// **'ملف الابن'**
  String get childProfileTitle;

  /// SCR-FAT-013 identity title name — age
  ///
  /// In ar, this message translates to:
  /// **'{name} — {age}'**
  String childProfileNameAge(String name, String age);

  /// SCR-FAT-013 status line when health excellent
  ///
  /// In ar, this message translates to:
  /// **'كل شيء على ما يرام'**
  String get childProfileStatusOk;

  /// SCR-FAT-013 status line when connection at risk
  ///
  /// In ar, this message translates to:
  /// **'قد ينقطع الاتصال'**
  String get childProfileStatusAtRisk;

  /// SCR-FAT-013 metric tile battery
  ///
  /// In ar, this message translates to:
  /// **'البطارية'**
  String get childProfileMetricBattery;

  /// SCR-FAT-013 metric tile connection
  ///
  /// In ar, this message translates to:
  /// **'الاتصال'**
  String get childProfileMetricConnection;

  /// SCR-FAT-013 metric tile location
  ///
  /// In ar, this message translates to:
  /// **'الموقع'**
  String get childProfileMetricLocation;

  /// SCR-FAT-013 metric tile wallet
  ///
  /// In ar, this message translates to:
  /// **'محفظته'**
  String get childProfileMetricWallet;

  /// SCR-FAT-013 today screen-time usage row
  ///
  /// In ar, this message translates to:
  /// **'اليوم: {used} من {cap}'**
  String childProfileTodayUsage(String used, String cap);

  /// SCR-FAT-013 per-child tools section title
  ///
  /// In ar, this message translates to:
  /// **'أدوات الابن'**
  String get childProfileToolsTitle;

  /// SCR-FAT-013 tools badge — individual scope
  ///
  /// In ar, this message translates to:
  /// **'تخصه وحده'**
  String get childProfileToolsBadge;

  /// SCR-FAT-013 tools honesty hint
  ///
  /// In ar, this message translates to:
  /// **'كل ما تضبطه هنا يسري على هذا الابن فقط — لكل ابن إعداداته المستقلة'**
  String get childProfileToolsHint;

  /// SCR-FAT-013 tool → FAT-032
  ///
  /// In ar, this message translates to:
  /// **'وقت الشاشة'**
  String get childProfileToolScreenTime;

  /// SCR-FAT-013 tool → FAT-033
  ///
  /// In ar, this message translates to:
  /// **'طلبات الوقت'**
  String get childProfileToolTimeRequests;

  /// SCR-FAT-013 tool → FAT-036
  ///
  /// In ar, this message translates to:
  /// **'فلترة الإنترنت'**
  String get childProfileToolWebFilter;

  /// SCR-FAT-013 tool → FAT-037
  ///
  /// In ar, this message translates to:
  /// **'القفل الفوري'**
  String get childProfileToolInstantLock;

  /// SCR-FAT-013 tool → FAT-067
  ///
  /// In ar, this message translates to:
  /// **'ضبط الرقابة'**
  String get childProfileToolSmartSupervision;

  /// SCR-FAT-013 tool → FAT-026
  ///
  /// In ar, this message translates to:
  /// **'صحة الجهاز'**
  String get childProfileToolDeviceHealth;

  /// SCR-FAT-013 live location card title
  ///
  /// In ar, this message translates to:
  /// **'الموقع المباشر'**
  String get childProfileLocationTitle;

  /// SCR-FAT-013 location summary line
  ///
  /// In ar, this message translates to:
  /// **'📍 {location} · {seen} · 🔋 {battery}'**
  String childProfileLocationSummary(
    String location,
    String seen,
    String battery,
  );

  /// SCR-FAT-013 details link → FAT-014
  ///
  /// In ar, this message translates to:
  /// **'التفاصيل ‹'**
  String get childProfileDetailsLink;

  /// SCR-FAT-013 connection health card
  ///
  /// In ar, this message translates to:
  /// **'صحة الاتصال'**
  String get childProfileConnectionTitle;

  /// SCR-FAT-013 connection health body
  ///
  /// In ar, this message translates to:
  /// **'آخر نبضة: {heartbeat} · كل الأذونات ممنوحة.'**
  String childProfileConnectionBody(String heartbeat);

  /// SCR-FAT-013 device details link → FAT-026
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الجهاز ‹'**
  String get childProfileDeviceDetailsLink;

  /// SCR-FAT-013 empty when childId missing
  ///
  /// In ar, this message translates to:
  /// **'اختر ابنًا أولًا'**
  String get childProfileMissingIdTitle;

  /// SCR-FAT-013 missing childId message
  ///
  /// In ar, this message translates to:
  /// **'افتح ملف الابن من قائمة الأبناء — لا يُعرض ملف بدون معرّف ابن.'**
  String get childProfileMissingIdMessage;

  /// SCR-FAT-013 unknown childId
  ///
  /// In ar, this message translates to:
  /// **'الابن غير موجود'**
  String get childProfileNotFoundTitle;

  /// SCR-FAT-013 not-found message
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد ابن بهذا المعرّف في العائلة — عد إلى قائمة الأبناء واختر ابنًا مربوطًا.'**
  String get childProfileNotFoundMessage;

  /// SCR-FAT-013 child-role lean title
  ///
  /// In ar, this message translates to:
  /// **'لأولياء الأمور'**
  String get childProfileChildLeanTitle;

  /// SCR-FAT-013 child-role lean message
  ///
  /// In ar, this message translates to:
  /// **'ملف الابن مساحة للوالدين لمتابعة الابن وضبط إعداداته — ليست جزءًا من تجربة الابن.'**
  String get childProfileChildLeanMessage;

  /// SCR-FAT-013 loading Semantics
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل ملف الابن'**
  String get childProfileLoadingSemantics;

  /// SCR-FAT-013 tools grid Semantics
  ///
  /// In ar, this message translates to:
  /// **'أدوات إعدادات الابن'**
  String get childProfileToolsSemantics;

  /// SCR-FAT-013 identity card Semantics
  ///
  /// In ar, this message translates to:
  /// **'{name}، {age}، الحالة {status}'**
  String childProfileIdentitySemantics(String name, String age, String status);

  /// SCR-FAT-014 app bar title
  ///
  /// In ar, this message translates to:
  /// **'أين أبنائي؟'**
  String get locationMapTitle;

  /// SCR-FAT-014 Life360 competitive honesty — location ≠ full parental control
  ///
  /// In ar, this message translates to:
  /// **'الموقع والمناطق الآمنة اطمئنان جغرافي (نمط Life360) — وليست بديلًا لوقت الشاشة أو فلترة المحتوى.'**
  String get locationMapHonestyBanner;

  /// SCR-FAT-014 empty when no children linked
  ///
  /// In ar, this message translates to:
  /// **'لا مواقع بعد'**
  String get locationMapEmptyTitle;

  /// SCR-FAT-014 empty message Rule 23
  ///
  /// In ar, this message translates to:
  /// **'اربط جهاز ابن لترى موقعه الحي والمناطق الآمنة هنا — بلا أسماء أو إحداثيات مزروعة.'**
  String get locationMapEmptyMessage;

  /// SCR-FAT-014 unknown childId
  ///
  /// In ar, this message translates to:
  /// **'الابن غير موجود'**
  String get locationMapNotFoundTitle;

  /// SCR-FAT-014 not-found message
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد ابن بهذا المعرّف على الخريطة — عد إلى قائمة الأبناء واختر ابنًا مربوطًا.'**
  String get locationMapNotFoundMessage;

  /// SCR-FAT-014 child-role lean title
  ///
  /// In ar, this message translates to:
  /// **'لأولياء الأمور'**
  String get locationMapChildLeanTitle;

  /// SCR-FAT-014 child-role lean message
  ///
  /// In ar, this message translates to:
  /// **'خريطة الموقع مساحة للوالدين لمتابعة الأبناء — ليست جزءًا من تجربة الابن.'**
  String get locationMapChildLeanMessage;

  /// SCR-FAT-014 loading Semantics
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل خريطة الموقع'**
  String get locationMapLoadingSemantics;

  /// SCR-FAT-014 map canvas Semantics
  ///
  /// In ar, this message translates to:
  /// **'خريطة حية لمواقع الأبناء والمناطق الآمنة'**
  String get locationMapCanvasSemantics;

  /// SCR-FAT-014 floating pin row title
  ///
  /// In ar, this message translates to:
  /// **'{name} — {place}'**
  String locationMapPinTitle(String name, String place);

  /// SCR-FAT-014 pin row subtitle without zone
  ///
  /// In ar, this message translates to:
  /// **'{seen} · 🔋 {battery}'**
  String locationMapPinSubtitle(String seen, String battery);

  /// SCR-FAT-014 pin row subtitle inside safe zone
  ///
  /// In ar, this message translates to:
  /// **'داخل «{zone}» · {seen} · 🔋 {battery}'**
  String locationMapPinSubtitleInZone(String zone, String seen, String battery);

  /// SCR-FAT-014 pin row → FAT-015
  ///
  /// In ar, this message translates to:
  /// **'السجل ←'**
  String get locationMapHistoryLink;

  /// SCR-FAT-014 embedded day-thread heading
  ///
  /// In ar, this message translates to:
  /// **'🧵 خيط يوم {name}'**
  String locationMapThreadTitle(String name);

  /// SCR-FAT-014 day-thread → FAT-015 full history
  ///
  /// In ar, this message translates to:
  /// **'السجل الكامل ‹'**
  String get locationMapFullHistoryLink;

  /// SCR-FAT-014 CTA → FAT-016
  ///
  /// In ar, this message translates to:
  /// **'🛡️ المناطق الآمنة'**
  String get locationMapSafeZonesCta;

  /// SCR-FAT-014 safe zones button Semantics
  ///
  /// In ar, this message translates to:
  /// **'فتح قائمة المناطق الآمنة'**
  String get locationMapSafeZonesSemantics;

  /// SCR-FAT-014 decorative map landmark
  ///
  /// In ar, this message translates to:
  /// **'منزلنا'**
  String get locationMapLandmarkHome;

  /// SCR-FAT-014 decorative map landmark
  ///
  /// In ar, this message translates to:
  /// **'المدرسة'**
  String get locationMapLandmarkSchool;

  /// SCR-FAT-014 decorative map landmark
  ///
  /// In ar, this message translates to:
  /// **'حديقة الحي'**
  String get locationMapLandmarkPark;

  /// SCR-FAT-014 decorative map landmark
  ///
  /// In ar, this message translates to:
  /// **'نادي الحي'**
  String get locationMapLandmarkClub;

  /// SCR-FAT-014 decorative map landmark
  ///
  /// In ar, this message translates to:
  /// **'مسجد الحي'**
  String get locationMapLandmarkMosque;

  /// SCR-FAT-014 decorative map street label
  ///
  /// In ar, this message translates to:
  /// **'شارع الحي'**
  String get locationMapLandmarkStreet;

  /// SCR-FAT-015 app bar fallback title
  ///
  /// In ar, this message translates to:
  /// **'سجل المواقع'**
  String get locationHistoryTitle;

  /// SCR-FAT-015 app bar with child display name
  ///
  /// In ar, this message translates to:
  /// **'خيط يوم {name}'**
  String locationHistoryThreadTitle(String name);

  /// SCR-FAT-015 Life360 competitive honesty
  ///
  /// In ar, this message translates to:
  /// **'سجل المواقع اطمئنان جغرافي (نمط Life360) — وليس بديلًا لوقت الشاشة أو فلترة المحتوى.'**
  String get locationHistoryHonestyBanner;

  /// SCR-FAT-015 missing childId
  ///
  /// In ar, this message translates to:
  /// **'اختر ابنًا أولًا'**
  String get locationHistoryMissingIdTitle;

  /// SCR-FAT-015 missing childId message Rule 23
  ///
  /// In ar, this message translates to:
  /// **'افتح السجل من خريطة الموقع أو ملف الابن — بلا أسماء مزروعة على هذه الشاشة.'**
  String get locationHistoryMissingIdMessage;

  /// SCR-FAT-015 known child with empty trail
  ///
  /// In ar, this message translates to:
  /// **'لا سجل بعد'**
  String get locationHistoryEmptyTitle;

  /// SCR-FAT-015 empty trail Rule 23
  ///
  /// In ar, this message translates to:
  /// **'عندما يتحرك الجهاز ستظهر أماكن اليوم هنا — بلا خط زمني مزروع.'**
  String get locationHistoryEmptyMessage;

  /// SCR-FAT-015 unknown childId
  ///
  /// In ar, this message translates to:
  /// **'الابن غير موجود'**
  String get locationHistoryNotFoundTitle;

  /// SCR-FAT-015 not-found message
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد ابن بهذا المعرّف في السجل — عد إلى الخريطة واختر ابنًا مربوطًا.'**
  String get locationHistoryNotFoundMessage;

  /// SCR-FAT-015 child-role lean title
  ///
  /// In ar, this message translates to:
  /// **'لأولياء الأمور'**
  String get locationHistoryChildLeanTitle;

  /// SCR-FAT-015 child-role lean message
  ///
  /// In ar, this message translates to:
  /// **'سجل المواقع مساحة للوالدين لمتابعة تحركات الأبناء — ليست جزءًا من تجربة الابن.'**
  String get locationHistoryChildLeanMessage;

  /// SCR-FAT-015 loading Semantics
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل سجل المواقع'**
  String get locationHistoryLoadingSemantics;

  /// SCR-FAT-015 empty/missing CTA → FAT-014
  ///
  /// In ar, this message translates to:
  /// **'فتح خريطة الموقع'**
  String get locationHistoryOpenMapCta;

  /// SCR-FAT-015 S-SEC-023 frequent places heading
  ///
  /// In ar, this message translates to:
  /// **'📍 أماكن {name} المتكررة'**
  String locationHistoryFrequentTitle(String name);

  /// SCR-FAT-015 frequent places section badge
  ///
  /// In ar, this message translates to:
  /// **'جديد'**
  String get locationHistoryFrequentNewBadge;

  /// SCR-FAT-015 frequent place Tag.g
  ///
  /// In ar, this message translates to:
  /// **'منتظم'**
  String get locationHistoryPlaceRegular;

  /// SCR-FAT-015 frequent place Tag.a
  ///
  /// In ar, this message translates to:
  /// **'جديد'**
  String get locationHistoryPlaceNovel;

  /// SCR-FAT-015 S-SEC-023 dialogue-not-accusation hint
  ///
  /// In ar, this message translates to:
  /// **'يتعلّمها النظام تلقائيًا — والمكان الجديد إشارة حوار لا اتهام.'**
  String get locationHistoryFrequentHint;

  /// SCR-FAT-015 90-day retention honesty
  ///
  /// In ar, this message translates to:
  /// **'يُحتفظ بالسجل ٩٠ يومًا ثم يُحذف تلقائيًا — سياسة تقليم ملزمة.'**
  String get locationHistoryRetentionNote;

  /// SCR-FAT-016 app bar title
  ///
  /// In ar, this message translates to:
  /// **'المناطق الآمنة'**
  String get safeZonesTitle;

  /// SCR-FAT-016 Life360 competitive honesty
  ///
  /// In ar, this message translates to:
  /// **'المناطق الآمنة اطمئنان جغرافي (نمط Life360) — وليست بديلًا لوقت الشاشة أو فلترة المحتوى.'**
  String get safeZonesHonestyBanner;

  /// SCR-FAT-016 mother below full — view-only
  ///
  /// In ar, this message translates to:
  /// **'🔒 عرض فقط — تعديل المناطق يتطلب مستوى «كاملة». يمكنك دائمًا رؤية مواقع الأبناء.'**
  String get safeZonesReadOnlyBanner;

  /// SCR-FAT-016 list card heading
  ///
  /// In ar, this message translates to:
  /// **'المناطق المعتمدة للعائلة'**
  String get safeZonesSectionTitle;

  /// SCR-FAT-016 compact add in card header
  ///
  /// In ar, this message translates to:
  /// **'+ إضافة منطقة'**
  String get safeZonesAddHeaderCta;

  /// SCR-FAT-016 header add Semantics
  ///
  /// In ar, this message translates to:
  /// **'إضافة منطقة آمنة جديدة'**
  String get safeZonesAddHeaderSemantics;

  /// SCR-FAT-016 primary create CTA → FAT-017
  ///
  /// In ar, this message translates to:
  /// **'+ رسم منطقة آمنة جديدة على الخريطة'**
  String get safeZonesDrawCta;

  /// SCR-FAT-016 draw CTA Semantics
  ///
  /// In ar, this message translates to:
  /// **'رسم منطقة آمنة جديدة على الخريطة'**
  String get safeZonesDrawSemantics;

  /// SCR-FAT-016 empty list title
  ///
  /// In ar, this message translates to:
  /// **'لا مناطق آمنة بعد'**
  String get safeZonesEmptyTitle;

  /// SCR-FAT-016 empty Rule 23
  ///
  /// In ar, this message translates to:
  /// **'ارسم أول منطقة على الخريطة ليصلك تنبيه وصول ومغادرة — بلا مناطق مزروعة.'**
  String get safeZonesEmptyMessage;

  /// SCR-FAT-016 empty → FAT-017
  ///
  /// In ar, this message translates to:
  /// **'رسم منطقة آمنة'**
  String get safeZonesEmptyCta;

  /// SCR-FAT-016 child-role lean title
  ///
  /// In ar, this message translates to:
  /// **'لأولياء الأمور'**
  String get safeZonesChildLeanTitle;

  /// SCR-FAT-016 child-role lean message
  ///
  /// In ar, this message translates to:
  /// **'المناطق الآمنة مساحة للوالدين لضبط حدود الاطمئنان — ليست جزءًا من تجربة الابن.'**
  String get safeZonesChildLeanMessage;

  /// SCR-FAT-016 loading Semantics
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل المناطق الآمنة'**
  String get safeZonesLoadingSemantics;

  /// SCR-FAT-016 zone row subtitle
  ///
  /// In ar, this message translates to:
  /// **'{desc} · تنبيه وصول ومغادرة'**
  String safeZonesAlertSubtitle(String desc);

  /// SCR-FAT-016 alert Switch Semantics
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات الوصول والمغادرة لمنطقة {name}'**
  String safeZonesSwitchSemantics(String name);

  /// SCR-FAT-016 family-wide applies honesty
  ///
  /// In ar, this message translates to:
  /// **'تسري على كل الأبناء — وتنبيهات كل ابن تُضبط من ملفه.'**
  String get safeZonesAppliesNote;

  /// SCR-FAT-017 app bar title
  ///
  /// In ar, this message translates to:
  /// **'إنشاء منطقة آمنة'**
  String get createSafeZoneTitle;

  /// SCR-FAT-017 draw instruction banner
  ///
  /// In ar, this message translates to:
  /// **'✍️ ارسمها بيدك: اضغط على الخريطة حيث مركز المنطقة، اسحب لتحريكه، ثم اضبط الحجم بالشريط.'**
  String get createSafeZoneDrawBanner;

  /// SCR-FAT-017 Life360 competitive honesty
  ///
  /// In ar, this message translates to:
  /// **'المناطق الآمنة اطمئنان جغرافي (نمط Life360) — وليست بديلًا لوقت الشاشة أو فلترة المحتوى.'**
  String get createSafeZoneHonestyBanner;

  /// SCR-FAT-017 mother below full — view-only
  ///
  /// In ar, this message translates to:
  /// **'🔒 عرض فقط — رسم المناطق يتطلب مستوى «كاملة». يمكنك دائمًا رؤية مواقع الأبناء.'**
  String get createSafeZoneReadOnlyBanner;

  /// SCR-FAT-017 map overlay before first tap
  ///
  /// In ar, this message translates to:
  /// **'👆 اضغط هنا لوضع مركز المنطقة'**
  String get createSafeZoneTapHint;

  /// SCR-FAT-017 after center placed
  ///
  /// In ar, this message translates to:
  /// **'✓ المركز موضوع — اسحبه على الخريطة إن أردت تعديله'**
  String get createSafeZoneCenterPlaced;

  /// SCR-FAT-017 map canvas Semantics
  ///
  /// In ar, this message translates to:
  /// **'خريطة لرسم المنطقة الآمنة — اضغط لوضع المركز واسحب لتحريكه'**
  String get createSafeZoneMapSemantics;

  /// SCR-FAT-017 radius slider label
  ///
  /// In ar, this message translates to:
  /// **'نصف القطر — {meters} متر (يتغيّر أمامك على الخريطة)'**
  String createSafeZoneRadiusLabel(String meters);

  /// SCR-FAT-017 radius slider Semantics
  ///
  /// In ar, this message translates to:
  /// **'نصف قطر المنطقة الآمنة'**
  String get createSafeZoneRadiusSemantics;

  /// SCR-FAT-017 name field label
  ///
  /// In ar, this message translates to:
  /// **'اسم المنطقة'**
  String get createSafeZoneNameLabel;

  /// SCR-FAT-017 default name hint (prototype zname)
  ///
  /// In ar, this message translates to:
  /// **'نادي الحي'**
  String get createSafeZoneNameHint;

  /// SCR-FAT-017 alert toggles card heading
  ///
  /// In ar, this message translates to:
  /// **'نبّهني عند'**
  String get createSafeZoneAlertsHeading;

  /// SCR-FAT-017 arrival alert
  ///
  /// In ar, this message translates to:
  /// **'الوصول'**
  String get createSafeZoneAlertArrival;

  /// SCR-FAT-017 departure alert
  ///
  /// In ar, this message translates to:
  /// **'المغادرة'**
  String get createSafeZoneAlertDeparture;

  /// SCR-FAT-017 no-show alert title
  ///
  /// In ar, this message translates to:
  /// **'عدم الوصول في الموعد'**
  String get createSafeZoneAlertNoShow;

  /// SCR-FAT-017 no-show alert subtitle
  ///
  /// In ar, this message translates to:
  /// **'مثال: لم يصل المدرسة ٧:٣٠ ص'**
  String get createSafeZoneAlertNoShowHint;

  /// SCR-FAT-017 primary save CTA
  ///
  /// In ar, this message translates to:
  /// **'حفظ المنطقة الآمنة ←'**
  String get createSafeZoneSaveCta;

  /// SCR-FAT-017 save Semantics
  ///
  /// In ar, this message translates to:
  /// **'حفظ المنطقة الآمنة والعودة للقائمة'**
  String get createSafeZoneSaveSemantics;

  /// SCR-FAT-017 family-wide applies note
  ///
  /// In ar, this message translates to:
  /// **'ستسري على كل الأبناء — وتنبيهات كل ابن تُضبط من ملفه'**
  String get createSafeZoneAppliesNote;

  /// SCR-FAT-017 save blocked without center
  ///
  /// In ar, this message translates to:
  /// **'👆 ضع مركز المنطقة على الخريطة أولًا'**
  String get createSafeZoneNeedCenter;

  /// SCR-FAT-017 save success toast
  ///
  /// In ar, this message translates to:
  /// **'حُفظت منطقة «{name}» بنجاح ✓'**
  String createSafeZoneSavedToast(String name);

  /// SCR-FAT-017 saved zone description
  ///
  /// In ar, this message translates to:
  /// **'نصف قطر {meters} م'**
  String createSafeZoneRadiusDesc(String meters);

  /// SCR-FAT-017 child-role lean title
  ///
  /// In ar, this message translates to:
  /// **'لأولياء الأمور'**
  String get createSafeZoneChildLeanTitle;

  /// SCR-FAT-017 child-role lean message
  ///
  /// In ar, this message translates to:
  /// **'رسم المناطق الآمنة مساحة للوالدين — ليست جزءًا من تجربة الابن.'**
  String get createSafeZoneChildLeanMessage;

  /// SCR-FAT-017 center pin Semantics
  ///
  /// In ar, this message translates to:
  /// **'مركز المنطقة الآمنة'**
  String get createSafeZonePinSemantics;

  /// SCR-FAT-018 app bar / empty title
  ///
  /// In ar, this message translates to:
  /// **'بلاغ استغاثة'**
  String get sosAlertTitle;

  /// SCR-FAT-018 active board headline
  ///
  /// In ar, this message translates to:
  /// **'{name} يطلب النجدة'**
  String sosAlertHeadline(String name);

  /// SCR-FAT-018 piercing siren honesty (P-4)
  ///
  /// In ar, this message translates to:
  /// **'🔊 أطلقنا صفارة الإنذار في جوالك وجوال الأم — تخترق الوضع الصامت'**
  String get sosAlertSirenBanner;

  /// SCR-FAT-018 live broadcast note S-SEC-027
  ///
  /// In ar, this message translates to:
  /// **'اليوم · البث الحي والموقع مستمران الآن'**
  String get sosAlertLiveBroadcastNote;

  /// SCR-FAT-018 S-SEC-028 auto-call pending
  ///
  /// In ar, this message translates to:
  /// **'📞 اتصال تلقائي خلال ثوانٍ…'**
  String get sosAlertAutoCallPending;

  /// SCR-FAT-018 location/battery/movement meta
  ///
  /// In ar, this message translates to:
  /// **'📍 {location}\n🔋 {battery}٪ · {movement} · دقة ± {accuracy} م'**
  String sosAlertMetaLine(
    String location,
    String battery,
    String movement,
    String accuracy,
  );

  /// SCR-FAT-018 call-now CTA
  ///
  /// In ar, this message translates to:
  /// **'📞 اتصل بـ {name} الآن (مكالمة طارئة فورية)'**
  String sosAlertCallNowCta(String name);

  /// SCR-FAT-018 call-now Semantics
  ///
  /// In ar, this message translates to:
  /// **'اتصال طارئ فوري بالابن'**
  String get sosAlertCallNowSemantics;

  /// SCR-FAT-018 open FAT-014 CTA
  ///
  /// In ar, this message translates to:
  /// **'🗺️ عرض الموقع الحي بدقة على الخريطة'**
  String get sosAlertLiveMapCta;

  /// SCR-FAT-018 live map Semantics
  ///
  /// In ar, this message translates to:
  /// **'فتح خريطة الموقع الحي'**
  String get sosAlertLiveMapSemantics;

  /// SCR-FAT-018 resolve / ack CTA
  ///
  /// In ar, this message translates to:
  /// **'✓ وصلتُ إليه — تم الاطمئنان وإلغاء البلاغ'**
  String get sosAlertResolveCta;

  /// SCR-FAT-018 resolve Semantics
  ///
  /// In ar, this message translates to:
  /// **'إغلاق بلاغ الاستغاثة بعد الاطمئنان'**
  String get sosAlertResolveSemantics;

  /// SCR-FAT-018 S-SEC-030 escalate CTA
  ///
  /// In ar, this message translates to:
  /// **'🚨 تنبيه جهات الطوارئ'**
  String get sosAlertEscalateCta;

  /// SCR-FAT-018 escalate Semantics
  ///
  /// In ar, this message translates to:
  /// **'تصعيد البلاغ لجهات الطوارئ'**
  String get sosAlertEscalateSemantics;

  /// SCR-FAT-018 recipients footer SET-020/021
  ///
  /// In ar, this message translates to:
  /// **'وصل البلاغ: {names} — الاستغاثة لا تخضع لأي تدرّج'**
  String sosAlertRecipientsFooter(String names);

  /// SCR-FAT-018 P-4 never muted/paywalled banner
  ///
  /// In ar, this message translates to:
  /// **'الاستغاثة لا تُكتم ولا تُقيَّد بالاشتراك — تصل دائمًا لكل الأوصياء'**
  String get sosAlertP4NeverGated;

  /// SCR-FAT-018 live map Semantics
  ///
  /// In ar, this message translates to:
  /// **'خريطة بث الموقع الحي أثناء بلاغ الاستغاثة'**
  String get sosAlertMapSemantics;

  /// SCR-FAT-018 child pin Semantics
  ///
  /// In ar, this message translates to:
  /// **'موقع {name} الحي'**
  String sosAlertPinSemantics(String name);

  /// SCR-FAT-018 empty state title
  ///
  /// In ar, this message translates to:
  /// **'لا بلاغ استغاثة نشط'**
  String get sosAlertEmptyTitle;

  /// SCR-FAT-018 empty state message
  ///
  /// In ar, this message translates to:
  /// **'عند ضغط الابن زر الاستغاثة يظهر البلاغ هنا فورًا — مع صفارة تخترق الصامت وخريطة حية.'**
  String get sosAlertEmptyMessage;

  /// SCR-FAT-018 error title
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل البلاغ'**
  String get sosAlertErrorTitle;

  /// SCR-FAT-018 error message
  ///
  /// In ar, this message translates to:
  /// **'حاول مجددًا — الاستغاثة لا تعتمد على هذه الشاشة وحدها.'**
  String get sosAlertErrorMessage;

  /// SCR-FAT-018 child-role lean title
  ///
  /// In ar, this message translates to:
  /// **'لأولياء الأمور'**
  String get sosAlertChildLeanTitle;

  /// SCR-FAT-018 child-role lean message
  ///
  /// In ar, this message translates to:
  /// **'لوحة بلاغ الاستغاثة للوالدين — زر الاستغاثة عندك في تطبيق الابن.'**
  String get sosAlertChildLeanMessage;

  /// SCR-FAT-018 empty → FAT-028 CTA
  ///
  /// In ar, this message translates to:
  /// **'إعداد سلسلة الطوارئ ←'**
  String get sosAlertSetupCta;

  /// SCR-FAT-018 setup CTA Semantics
  ///
  /// In ar, this message translates to:
  /// **'فتح إعداد الطوارئ'**
  String get sosAlertSetupSemantics;

  /// SCR-FAT-018 resolve snackbar
  ///
  /// In ar, this message translates to:
  /// **'✓ الحمد لله — أُغلق البلاغ وتم الاطمئنان وسُجّل في سجل الأمان'**
  String get sosAlertResolvedToast;

  /// SCR-FAT-018 escalate snackbar
  ///
  /// In ar, this message translates to:
  /// **'أُرسل التنبيه لجهات الطوارئ على السلّم'**
  String get sosAlertEscalatedToast;

  /// SCR-FAT-018 call-now snackbar Stage-1
  ///
  /// In ar, this message translates to:
  /// **'بدء مكالمة طارئة (محاكاة مرحلة ١)'**
  String get sosAlertCallStartedToast;

  /// SCR-FAT-019 app bar title
  ///
  /// In ar, this message translates to:
  /// **'التنبيهات'**
  String get alertsHubTitle;

  /// SCR-FAT-019 S-ADM-028 three-tier honesty
  ///
  /// In ar, this message translates to:
  /// **'درجات الإلحاح الثلاث — الحماية من الكتم · 🔴 تدخّل الآن · 🟡 انتبه · 🟢 اطمئنان'**
  String get alertsHubHonestyBanner;

  /// SCR-FAT-019 P-4 / quiet-hours bypass honesty
  ///
  /// In ar, this message translates to:
  /// **'التنبيهات الحرجة والاستغاثة لا تُكتم بساعات الهدوء — تصل دائمًا'**
  String get alertsHubP4Banner;

  /// SCR-FAT-019 critical urgency section header
  ///
  /// In ar, this message translates to:
  /// **'🔴 يحتاجك الآن'**
  String get alertsHubSectionCritical;

  /// SCR-FAT-019 attention urgency section header
  ///
  /// In ar, this message translates to:
  /// **'🟡 يستحق نظرة'**
  String get alertsHubSectionAttention;

  /// SCR-FAT-019 reassurance urgency section header
  ///
  /// In ar, this message translates to:
  /// **'🟢 للاطمئنان'**
  String get alertsHubSectionReassurance;

  /// SCR-FAT-019 section counter
  ///
  /// In ar, this message translates to:
  /// **'{count}'**
  String alertsHubCount(int count);

  /// SCR-FAT-019 empty state title
  ///
  /// In ar, this message translates to:
  /// **'لا تنبيهات الآن'**
  String get alertsHubEmptyTitle;

  /// SCR-FAT-019 empty state message S-AIC-006
  ///
  /// In ar, this message translates to:
  /// **'عند وصول تنبيه من الرصد يظهر هنا حسب درجة الإلحاح — مقتطف فقط لا أرشيف.'**
  String get alertsHubEmptyMessage;

  /// SCR-FAT-019 loading Semantics
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحميل مركز التنبيهات'**
  String get alertsHubLoadingSemantics;

  /// SCR-FAT-019 child-role lean title
  ///
  /// In ar, this message translates to:
  /// **'لأولياء الأمور'**
  String get alertsHubChildLeanTitle;

  /// SCR-FAT-019 child-role lean message
  ///
  /// In ar, this message translates to:
  /// **'مركز التنبيهات للوالدين — اطمئنانك يظهر عندهم بدرجات الإلحاح.'**
  String get alertsHubChildLeanMessage;

  /// SCR-FAT-020 app bar title
  ///
  /// In ar, this message translates to:
  /// **'تفصيل التنبيه'**
  String get alertDetailTitle;

  /// SCR-FAT-020 Bark-style honesty: category+severity+advice only
  ///
  /// In ar, this message translates to:
  /// **'الفئة + الخطورة + التوصية — لا النص الخام (صدق تنبيه Bark)'**
  String get alertDetailHonestyBanner;

  /// SCR-FAT-020 P-4 SOS / critical pierce honesty
  ///
  /// In ar, this message translates to:
  /// **'الاستغاثة والتنبيهات الحرجة لا تُكتم بساعات الهدوء — تصل دائمًا'**
  String get alertDetailP4Banner;

  /// SCR-FAT-020 critical urgency tag
  ///
  /// In ar, this message translates to:
  /// **'🔴 عالية'**
  String get alertDetailUrgencyCritical;

  /// SCR-FAT-020 attention urgency tag
  ///
  /// In ar, this message translates to:
  /// **'🟡 انتبه'**
  String get alertDetailUrgencyAttention;

  /// SCR-FAT-020 reassurance urgency tag
  ///
  /// In ar, this message translates to:
  /// **'🟢 اطمئنان'**
  String get alertDetailUrgencyReassurance;

  /// SCR-FAT-020 stranger category
  ///
  /// In ar, this message translates to:
  /// **'فئة: تواصل من غريب'**
  String get alertDetailCategoryStranger;

  /// SCR-FAT-020 device/battery category
  ///
  /// In ar, this message translates to:
  /// **'فئة: حالة الجهاز'**
  String get alertDetailCategoryDevice;

  /// SCR-FAT-020 screen-time category
  ///
  /// In ar, this message translates to:
  /// **'فئة: وقت الشاشة'**
  String get alertDetailCategoryScreenTime;

  /// SCR-FAT-020 safe-arrival category
  ///
  /// In ar, this message translates to:
  /// **'فئة: وصول آمن'**
  String get alertDetailCategorySafeArrival;

  /// SCR-FAT-020 advisor advice label
  ///
  /// In ar, this message translates to:
  /// **'🧠 توصية مستشار العائلة:'**
  String get alertDetailAdvicePrefix;

  /// SCR-FAT-020 tone-bridge section title
  ///
  /// In ar, this message translates to:
  /// **'ردود تحفظ النبرة'**
  String get alertDetailToneSectionTitle;

  /// SCR-FAT-020 stranger block CTA (rules)
  ///
  /// In ar, this message translates to:
  /// **'حظر هذا الرقم'**
  String get alertDetailBlockCta;

  /// SCR-FAT-020 mother without rules — request block
  ///
  /// In ar, this message translates to:
  /// **'اطلب الحظر من صاحب الصلاحية'**
  String get alertDetailRequestBlockCta;

  /// SCR-FAT-020 request-block snackbar
  ///
  /// In ar, this message translates to:
  /// **'أُخطر صاحب الصلاحية بطلب الحظر'**
  String get alertDetailRequestBlockToast;

  /// SCR-FAT-020 block completed
  ///
  /// In ar, this message translates to:
  /// **'✓ حُظر الرقم عن جهاز الابن — وصلك تأكيد، وللابن لم يظهر شيء مزعج'**
  String get alertDetailBlockDoneBanner;

  /// SCR-FAT-020 battery reminder CTA
  ///
  /// In ar, this message translates to:
  /// **'أرسل تذكيرًا لطيفًا'**
  String get alertDetailSendReminderCta;

  /// SCR-FAT-020 battery reminder done
  ///
  /// In ar, this message translates to:
  /// **'✓ أُرسل التذكير اللطيف للابن'**
  String get alertDetailReminderDoneBanner;

  /// SCR-FAT-020 open chat CTA
  ///
  /// In ar, this message translates to:
  /// **'افتح المحادثة'**
  String get alertDetailOpenChatCta;

  /// SCR-FAT-020 games → FAT-032
  ///
  /// In ar, this message translates to:
  /// **'راجع وقت الشاشة'**
  String get alertDetailReviewScreenTimeCta;

  /// SCR-FAT-020 games dismiss CTA
  ///
  /// In ar, this message translates to:
  /// **'تجاهل هذه المرة'**
  String get alertDetailDismissCta;

  /// SCR-FAT-020 games dismiss done
  ///
  /// In ar, this message translates to:
  /// **'✓ تجاوزت عنها هذه المرة — لم يُخصم شيء'**
  String get alertDetailDismissDoneBanner;

  /// SCR-FAT-020 arrive heart CTA
  ///
  /// In ar, this message translates to:
  /// **'أرسل ❤️'**
  String get alertDetailSendHeartCta;

  /// SCR-FAT-020 arrive heart done
  ///
  /// In ar, this message translates to:
  /// **'✓ وصل قلبك للابن — فرحته وصلتنا'**
  String get alertDetailHeartDoneBanner;

  /// SCR-FAT-020 arrive → FAT-014
  ///
  /// In ar, this message translates to:
  /// **'اعرض على الخريطة'**
  String get alertDetailShowOnMapCta;

  /// SCR-FAT-020 missing alertId/kind
  ///
  /// In ar, this message translates to:
  /// **'لا تنبيه محدد'**
  String get alertDetailEmptyTitle;

  /// SCR-FAT-020 empty / noHub honesty
  ///
  /// In ar, this message translates to:
  /// **'يُفتح تفصيل التنبيه من مركز التنبيهات فقط — اختر تنبيهًا لعرض فئته وخطورته.'**
  String get alertDetailEmptyMessage;

  /// SCR-FAT-020 unknown id/kind
  ///
  /// In ar, this message translates to:
  /// **'التنبيه غير موجود'**
  String get alertDetailNotFoundTitle;

  /// SCR-FAT-020 not-found message
  ///
  /// In ar, this message translates to:
  /// **'لم نعثر على هذا التنبيه — قد يكون أُغلق أو انتهت صلاحيته.'**
  String get alertDetailNotFoundMessage;

  /// SCR-FAT-020 loading Semantics
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحميل تفصيل التنبيه'**
  String get alertDetailLoadingSemantics;

  /// SCR-FAT-020 child-role lean title
  ///
  /// In ar, this message translates to:
  /// **'لأولياء الأمور'**
  String get alertDetailChildLeanTitle;

  /// SCR-FAT-020 child-role lean message
  ///
  /// In ar, this message translates to:
  /// **'تفصيل التنبيه للوالدين — اطمئنانك يصلهم بفئة وخطورة دون نص خام.'**
  String get alertDetailChildLeanMessage;

  /// SCR-FAT-021 app bar title (family tab)
  ///
  /// In ar, this message translates to:
  /// **'العائلة'**
  String get conversationsListTitle;

  /// SCR-FAT-021 UI-007 chat never paywalled honesty
  ///
  /// In ar, this message translates to:
  /// **'حق ثابت: المحادثة العائلية لا تُقيَّد بأي مستوى اشتراك — مشفّرة ومتاحة دائمًا'**
  String get conversationsListHonestyBanner;

  /// SCR-FAT-021 conversations section header
  ///
  /// In ar, this message translates to:
  /// **'المحادثات'**
  String get conversationsListSectionTitle;

  /// SCR-FAT-021 new conversation CTA
  ///
  /// In ar, this message translates to:
  /// **'+ محادثة جديدة'**
  String get conversationsListNewChatCta;

  /// SCR-FAT-021 Stage-1 new-chat snackbar
  ///
  /// In ar, this message translates to:
  /// **'محادثة جديدة — قريبًا (مرحلة ١)'**
  String get conversationsListNewChatToast;

  /// SCR-FAT-021 empty state title
  ///
  /// In ar, this message translates to:
  /// **'لا محادثات بعد'**
  String get conversationsListEmptyTitle;

  /// SCR-FAT-021 empty state message
  ///
  /// In ar, this message translates to:
  /// **'عند بدء محادثة عائلية تظهر هنا — العائلية مثبتة أعلى دائمًا وحق ثابت لا يُقيَّد.'**
  String get conversationsListEmptyMessage;

  /// SCR-FAT-021 loading Semantics
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحميل قائمة المحادثات'**
  String get conversationsListLoadingSemantics;

  /// SCR-FAT-021 child-role lean title
  ///
  /// In ar, this message translates to:
  /// **'لأولياء الأمور'**
  String get conversationsListChildLeanTitle;

  /// SCR-FAT-021 child-role lean message
  ///
  /// In ar, this message translates to:
  /// **'قائمة محادثات الوالدين — محادثاتك العائلية تظهر في تبويب عائلتك.'**
  String get conversationsListChildLeanMessage;

  /// SCR-FAT-022 default app bar title
  ///
  /// In ar, this message translates to:
  /// **'المحادثة'**
  String get conversationTitle;

  /// SCR-FAT-022 E2E encryption honesty tag
  ///
  /// In ar, this message translates to:
  /// **'🔒 مشفّرة طرفيًا'**
  String get conversationEncryptedTag;

  /// SCR-FAT-022 per-thread settings CTA
  ///
  /// In ar, this message translates to:
  /// **'⚙️ إعدادات المحادثة'**
  String get conversationSettingsTag;

  /// SCR-FAT-022 Stage-1 settings snackbar
  ///
  /// In ar, this message translates to:
  /// **'إعدادات المحادثة — قريبًا (مرحلة ١)'**
  String get conversationSettingsToast;

  /// SCR-FAT-022 family thread pin + UI-007 honesty
  ///
  /// In ar, this message translates to:
  /// **'📌 المحادثة العائلية مثبتة دائمًا — وحق ثابت لا يُقيَّد بأي مستوى'**
  String get conversationFamilyPinNote;

  /// SCR-FAT-022 tone-bridge helper under chips
  ///
  /// In ar, this message translates to:
  /// **'💜 جسر النبرة — ردود تحفظ الودّ حاضرة دائمًا'**
  String get conversationToneBridgeNote;

  /// SCR-FAT-022 composer hint
  ///
  /// In ar, this message translates to:
  /// **'اكتب رسالة…'**
  String get conversationInputHint;

  /// SCR-FAT-022 send button Semantics
  ///
  /// In ar, this message translates to:
  /// **'إرسال الرسالة'**
  String get conversationSendSemantics;

  /// SCR-FAT-022 outbound message time label
  ///
  /// In ar, this message translates to:
  /// **'الآن'**
  String get conversationSentNow;

  /// SCR-FAT-022 attach button Semantics
  ///
  /// In ar, this message translates to:
  /// **'إرفاق صورة أو صوت أو ملف'**
  String get conversationAttachSemantics;

  /// SCR-FAT-022 Stage-1 attach snackbar
  ///
  /// In ar, this message translates to:
  /// **'📎 شارك صورة أو تسجيلًا أو ملفًا — داخل دائرة العائلة فقط'**
  String get conversationAttachToast;

  /// SCR-FAT-022 empty thread title
  ///
  /// In ar, this message translates to:
  /// **'ابدأ المحادثة'**
  String get conversationEmptyTitle;

  /// SCR-FAT-022 empty thread message
  ///
  /// In ar, this message translates to:
  /// **'لا رسائل بعد — اكتب أول رسالة أدناه. المحادثة حق ثابت لا يُقيَّد بأي مستوى.'**
  String get conversationEmptyMessage;

  /// SCR-FAT-022 missing chatWith title
  ///
  /// In ar, this message translates to:
  /// **'اختر محادثة'**
  String get conversationMissingPeerTitle;

  /// SCR-FAT-022 missing chatWith message
  ///
  /// In ar, this message translates to:
  /// **'افتح محادثة من قائمة العائلة لعرض الرسائل.'**
  String get conversationMissingPeerMessage;

  /// SCR-FAT-022 unknown peer title
  ///
  /// In ar, this message translates to:
  /// **'المحادثة غير موجودة'**
  String get conversationNotFoundTitle;

  /// SCR-FAT-022 unknown peer message
  ///
  /// In ar, this message translates to:
  /// **'هذا الطرف غير معروف في محادثات العائلة بعد.'**
  String get conversationNotFoundMessage;

  /// SCR-FAT-022 loading Semantics
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحميل المحادثة'**
  String get conversationLoadingSemantics;

  /// SCR-FAT-022 child-role lean title
  ///
  /// In ar, this message translates to:
  /// **'لأولياء الأمور'**
  String get conversationChildLeanTitle;

  /// SCR-FAT-022 child-role lean message
  ///
  /// In ar, this message translates to:
  /// **'محادثة الوالدين — محادثاتك العائلية تظهر في تبويب عائلتك.'**
  String get conversationChildLeanMessage;

  /// SCR-FAT-023 app bar title
  ///
  /// In ar, this message translates to:
  /// **'مكالمة جارية'**
  String get activeCallTitle;

  /// SCR-FAT-023 live status + timer
  ///
  /// In ar, this message translates to:
  /// **'جارية · {elapsed}'**
  String activeCallStatusActive(String elapsed);

  /// SCR-FAT-023 mute button Semantics
  ///
  /// In ar, this message translates to:
  /// **'كتم الصوت'**
  String get activeCallMuteSemantics;

  /// SCR-FAT-023 unmute button Semantics
  ///
  /// In ar, this message translates to:
  /// **'إعادة الصوت'**
  String get activeCallUnmuteSemantics;

  /// SCR-FAT-023 speaker button Semantics
  ///
  /// In ar, this message translates to:
  /// **'مكبر الصوت'**
  String get activeCallSpeakerSemantics;

  /// SCR-FAT-023 video button Semantics
  ///
  /// In ar, this message translates to:
  /// **'الكاميرا'**
  String get activeCallVideoSemantics;

  /// SCR-FAT-023 end-call button Semantics
  ///
  /// In ar, this message translates to:
  /// **'إنهاء المكالمة'**
  String get activeCallEndSemantics;

  /// SCR-FAT-023 mute-on snackbar
  ///
  /// In ar, this message translates to:
  /// **'🔇 كتمت صوتك مؤقتًا — اضغط مجددًا لإعادته'**
  String get activeCallMuteOnToast;

  /// SCR-FAT-023 mute-off snackbar
  ///
  /// In ar, this message translates to:
  /// **'🎙 عاد صوتك'**
  String get activeCallMuteOffToast;

  /// SCR-FAT-023 speaker-on snackbar
  ///
  /// In ar, this message translates to:
  /// **'🔊 مكبر الصوت يعمل'**
  String get activeCallSpeakerOnToast;

  /// SCR-FAT-023 speaker-off snackbar
  ///
  /// In ar, this message translates to:
  /// **'🔈 مكبر الصوت متوقف'**
  String get activeCallSpeakerOffToast;

  /// SCR-FAT-023 camera-on snackbar
  ///
  /// In ar, this message translates to:
  /// **'📹 الكاميرا تعمل — {name} يراك الآن'**
  String activeCallCameraOnToast(String name);

  /// SCR-FAT-023 camera-off snackbar
  ///
  /// In ar, this message translates to:
  /// **'📷 الكاميرا متوقفة'**
  String get activeCallCameraOffToast;

  /// SCR-FAT-023 LiveKit + silent-breakthrough honesty
  ///
  /// In ar, this message translates to:
  /// **'صوت وفيديو عبر LiveKit — بيانات وصفية فقط، لا تسجيل · 🔔 مكالمات الاطمئنان ترنّ عند الابن حتى لو كان جهازه صامتًا'**
  String get activeCallHonestyNote;

  /// SCR-FAT-023 play-together card title
  ///
  /// In ar, this message translates to:
  /// **'🎮 العبا معًا أثناء المكالمة'**
  String get activeCallPlayTogetherTitle;

  /// SCR-FAT-023 shared draw title
  ///
  /// In ar, this message translates to:
  /// **'لوحة رسم مشتركة'**
  String get activeCallDrawTitle;

  /// SCR-FAT-023 shared draw subtitle
  ///
  /// In ar, this message translates to:
  /// **'ترسمان معًا في اللحظة نفسها — تقريب المسافات'**
  String get activeCallDrawSubtitle;

  /// SCR-FAT-023 shared draw CTA
  ///
  /// In ar, this message translates to:
  /// **'افتح'**
  String get activeCallDrawCta;

  /// SCR-FAT-023 shared draw Stage-1 toast
  ///
  /// In ar, this message translates to:
  /// **'🎨 فُتحت اللوحة المشتركة — خطوطك لحظية'**
  String get activeCallDrawToast;

  /// SCR-FAT-023 tic-tac-toe title
  ///
  /// In ar, this message translates to:
  /// **'إكس-أو سريعة'**
  String get activeCallXoTitle;

  /// SCR-FAT-023 tic-tac-toe subtitle
  ///
  /// In ar, this message translates to:
  /// **'جولة خفيفة وأنتما تتكلمان'**
  String get activeCallXoSubtitle;

  /// SCR-FAT-023 tic-tac-toe CTA
  ///
  /// In ar, this message translates to:
  /// **'العب'**
  String get activeCallXoCta;

  /// SCR-FAT-023 tic-tac-toe Stage-1 toast
  ///
  /// In ar, this message translates to:
  /// **'❌⭕ بدأت الجولة — دور الطرف الآخر أولًا'**
  String get activeCallXoToast;

  /// SCR-FAT-023 missing callId title
  ///
  /// In ar, this message translates to:
  /// **'لا مكالمة نشطة'**
  String get activeCallMissingIdTitle;

  /// SCR-FAT-023 missing callId message
  ///
  /// In ar, this message translates to:
  /// **'افتح مكالمة من سجل المكالمات أو من محادثة عائلية.'**
  String get activeCallMissingIdMessage;

  /// SCR-FAT-023 unknown callId title
  ///
  /// In ar, this message translates to:
  /// **'المكالمة غير موجودة'**
  String get activeCallNotFoundTitle;

  /// SCR-FAT-023 unknown callId message
  ///
  /// In ar, this message translates to:
  /// **'هذا المعرّف غير معروف في مكالمات العائلة بعد.'**
  String get activeCallNotFoundMessage;

  /// SCR-FAT-023 loading Semantics
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحميل المكالمة'**
  String get activeCallLoadingSemantics;

  /// SCR-FAT-023 child-role lean title
  ///
  /// In ar, this message translates to:
  /// **'لأولياء الأمور'**
  String get activeCallChildLeanTitle;

  /// SCR-FAT-023 child-role lean message
  ///
  /// In ar, this message translates to:
  /// **'مكالمة الوالدين — مكالماتك العائلية تظهر في تبويب عائلتك.'**
  String get activeCallChildLeanMessage;

  /// SCR-FAT-024 app bar title
  ///
  /// In ar, this message translates to:
  /// **'المكالمات'**
  String get callHistoryTitle;

  /// SCR-FAT-024 metadata-only + quick reply honesty
  ///
  /// In ar, this message translates to:
  /// **'بيانات وصفية فقط — لا تسجيل صوت ولا فيديو · رد سريع أو رسالة حب من السجل'**
  String get callHistoryHonestyBanner;

  /// SCR-FAT-024 outgoing direction label
  ///
  /// In ar, this message translates to:
  /// **'↗ صادرة'**
  String get callHistoryDirectionOutgoing;

  /// SCR-FAT-024 incoming direction label
  ///
  /// In ar, this message translates to:
  /// **'↙ واردة'**
  String get callHistoryDirectionIncoming;

  /// SCR-FAT-024 missed direction label
  ///
  /// In ar, this message translates to:
  /// **'↙ فائتة'**
  String get callHistoryDirectionMissed;

  /// SCR-FAT-024 outgoing video direction label
  ///
  /// In ar, this message translates to:
  /// **'↗ صادرة فيديو'**
  String get callHistoryDirectionOutgoingVideo;

  /// SCR-FAT-024 redial button Semantics
  ///
  /// In ar, this message translates to:
  /// **'إعادة الاتصال'**
  String get callHistoryRedialSemantics;

  /// SCR-FAT-024 dial seam Stage-1 snackbar
  ///
  /// In ar, this message translates to:
  /// **'اتصال جديد — قريبًا (مرحلة ١)'**
  String get callHistoryDialToast;

  /// SCR-FAT-024 empty state title
  ///
  /// In ar, this message translates to:
  /// **'لا مكالمات بعد'**
  String get callHistoryEmptyTitle;

  /// SCR-FAT-024 empty state message
  ///
  /// In ar, this message translates to:
  /// **'عند إجراء مكالمة عائلية تظهر هنا — واردة وصادرة وفائتة مع رد سريع.'**
  String get callHistoryEmptyMessage;

  /// SCR-FAT-024 loading Semantics
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحميل سجل المكالمات'**
  String get callHistoryLoadingSemantics;

  /// SCR-FAT-024 child-role lean title
  ///
  /// In ar, this message translates to:
  /// **'لأولياء الأمور'**
  String get callHistoryChildLeanTitle;

  /// SCR-FAT-024 child-role lean message
  ///
  /// In ar, this message translates to:
  /// **'سجل مكالمات الوالدين — مكالماتك العائلية تظهر في تبويب عائلتك.'**
  String get callHistoryChildLeanMessage;

  /// SCR-FAT-025 settings hub app bar (F-08)
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settingsHubTitle;

  /// SCR-FAT-025 child-role lean title
  ///
  /// In ar, this message translates to:
  /// **'لأولياء الأمور'**
  String get settingsHubChildLeanTitle;

  /// SCR-FAT-025 child-role lean message
  ///
  /// In ar, this message translates to:
  /// **'إعدادات العائلة للوالدين — إعداداتك تظهر في تبويب «أنا».'**
  String get settingsHubChildLeanMessage;

  /// SCR-FAT-025 family section heading
  ///
  /// In ar, this message translates to:
  /// **'العائلة'**
  String get settingsHubSectionFamily;

  /// SCR-FAT-025 emergency section heading
  ///
  /// In ar, this message translates to:
  /// **'الطوارئ'**
  String get settingsHubSectionEmergency;

  /// SCR-FAT-025 AI & privacy section heading
  ///
  /// In ar, this message translates to:
  /// **'الذكاء والخصوصية'**
  String get settingsHubSectionPrivacy;

  /// SCR-FAT-025 general section heading
  ///
  /// In ar, this message translates to:
  /// **'عام'**
  String get settingsHubSectionGeneral;

  /// SCR-FAT-025 coming-soon section heading
  ///
  /// In ar, this message translates to:
  /// **'ميزات قادمة'**
  String get settingsHubSectionComingSoon;

  /// SCR-FAT-025 → FAT-027
  ///
  /// In ar, this message translates to:
  /// **'أعضاء العائلة'**
  String get settingsHubRowFamilyMembers;

  /// SCR-FAT-025 → FAT-027 subtitle
  ///
  /// In ar, this message translates to:
  /// **'الأدوار والدعوات'**
  String get settingsHubRowFamilyMembersSub;

  /// SCR-FAT-025 → FAT-031 father-only (Rule 23 — no planted names)
  ///
  /// In ar, this message translates to:
  /// **'صلاحية الأم'**
  String get settingsHubRowMotherShare;

  /// SCR-FAT-025 → FAT-031 subtitle
  ///
  /// In ar, this message translates to:
  /// **'مستوى مشاركة الأم'**
  String get settingsHubRowMotherShareSub;

  /// SCR-FAT-025 → FAT-030
  ///
  /// In ar, this message translates to:
  /// **'طلبات فتح وضع الوالد'**
  String get settingsHubRowParentModeRequests;

  /// SCR-FAT-025 → FAT-004
  ///
  /// In ar, this message translates to:
  /// **'ربط جهاز جديد'**
  String get settingsHubRowLinkDevice;

  /// SCR-FAT-025 → FAT-004 subtitle
  ///
  /// In ar, this message translates to:
  /// **'رمز QR — جهاز واحد لكل ابن'**
  String get settingsHubRowLinkDeviceSub;

  /// SCR-FAT-025 → FAT-028
  ///
  /// In ar, this message translates to:
  /// **'إعداد الطوارئ'**
  String get settingsHubRowEmergency;

  /// SCR-FAT-025 → FAT-028 subtitle
  ///
  /// In ar, this message translates to:
  /// **'جهات النجدة وزر الاستغاثة'**
  String get settingsHubRowEmergencySub;

  /// SCR-FAT-025 → FAT-029 father-only
  ///
  /// In ar, this message translates to:
  /// **'حدود مستشار العائلة وصلاحياته'**
  String get settingsHubRowBrain;

  /// SCR-FAT-025 → FAT-029 subtitle
  ///
  /// In ar, this message translates to:
  /// **'ماذا يرى وماذا لا يرى'**
  String get settingsHubRowBrainSub;

  /// SCR-FAT-025 → FAT-079
  ///
  /// In ar, this message translates to:
  /// **'مساعدي الذكي — ماذا يفعل عني'**
  String get settingsHubRowAdvisor;

  /// SCR-FAT-025 → FAT-079 subtitle
  ///
  /// In ar, this message translates to:
  /// **'قواعد التفويض'**
  String get settingsHubRowAdvisorSub;

  /// SCR-FAT-025 → FAT-059
  ///
  /// In ar, this message translates to:
  /// **'الخصوصية والبيانات'**
  String get settingsHubRowPrivacy;

  /// SCR-FAT-025 → FAT-060
  ///
  /// In ar, this message translates to:
  /// **'سجل التدقيق'**
  String get settingsHubRowAudit;

  /// SCR-FAT-025 → FAT-060 subtitle
  ///
  /// In ar, this message translates to:
  /// **'من فعل ماذا ومتى'**
  String get settingsHubRowAuditSub;

  /// SCR-FAT-025 → FAT-058
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get settingsHubRowNotifications;

  /// SCR-FAT-025 → FAT-056 father-only
  ///
  /// In ar, this message translates to:
  /// **'الباقات والاشتراك'**
  String get settingsHubRowBilling;

  /// SCR-FAT-025 → FAT-061
  ///
  /// In ar, this message translates to:
  /// **'اللغة والمساعدة'**
  String get settingsHubRowLanguage;

  /// SCR-FAT-025 → FAT-075
  ///
  /// In ar, this message translates to:
  /// **'ما نجهزه لكم بإتقان'**
  String get settingsHubRowComingSoon;

  /// SCR-FAT-025 → FAT-075 subtitle
  ///
  /// In ar, this message translates to:
  /// **'بلا وعود بتواريخ'**
  String get settingsHubRowComingSoonSub;

  /// SCR-FAT-027 screen title
  ///
  /// In ar, this message translates to:
  /// **'أعضاء العائلة'**
  String get familyMembersTitle;

  /// SCR-FAT-027 owner self marker — parametric name
  ///
  /// In ar, this message translates to:
  /// **'{name} (أنت)'**
  String familyMembersSelfName(String name);

  /// SCR-FAT-027 owner subtitle · one_owner_per_family
  ///
  /// In ar, this message translates to:
  /// **'المالك — كل الصلاحيات'**
  String get familyMembersRoleOwner;

  /// SCR-FAT-027 mother subtitle
  ///
  /// In ar, this message translates to:
  /// **'وليّة أمر'**
  String get familyMembersRoleMother;

  /// SCR-FAT-027 locked guardian subtitle (S-ADM-013)
  ///
  /// In ar, this message translates to:
  /// **'وصيّ إضافي — لا يُرقّى'**
  String get familyMembersRoleGuardian;

  /// SCR-FAT-027 child subtitle
  ///
  /// In ar, this message translates to:
  /// **'ابن — وضع مقفول ثلاثيًا'**
  String get familyMembersRoleChild;

  /// SCR-FAT-027 owner Tag.p
  ///
  /// In ar, this message translates to:
  /// **'مالك'**
  String get familyMembersTagOwner;

  /// SCR-FAT-027 owner-only mother level change hint → FAT-031
  ///
  /// In ar, this message translates to:
  /// **'{level} · تغيير ←'**
  String familyMembersTagMotherChange(String level);

  /// SCR-FAT-027 guardian locked observer tag
  ///
  /// In ar, this message translates to:
  /// **'مطّلع 🔒'**
  String get familyMembersTagGuardianLocked;

  /// SCR-FAT-027 child lock tag
  ///
  /// In ar, this message translates to:
  /// **'🔒 ابن'**
  String get familyMembersTagChild;

  /// SCR-FAT-027 owner invite → FAT-008
  ///
  /// In ar, this message translates to:
  /// **'+ دعوة وليّ أمر'**
  String get familyMembersInviteCta;

  /// SCR-FAT-027 disabled invite for non-owner
  ///
  /// In ar, this message translates to:
  /// **'+ دعوة (للمالك وحده)'**
  String get familyMembersInviteOwnerOnly;

  /// SCR-FAT-027 invite-only footer · one_owner_per_family
  ///
  /// In ar, this message translates to:
  /// **'لا أحد يدخل العائلة إلا بدعوة من مالكها'**
  String get familyMembersInviteOnlyNote;

  /// SCR-FAT-027 empty roster (Rule 23)
  ///
  /// In ar, this message translates to:
  /// **'لا أعضاء بعد'**
  String get familyMembersEmptyTitle;

  /// SCR-FAT-027 empty roster body
  ///
  /// In ar, this message translates to:
  /// **'ادعُ وليّ أمر أو اربط ابنًا لترى الأدوار والمستويات هنا.'**
  String get familyMembersEmptyMessage;

  /// SCR-FAT-027 child lean title
  ///
  /// In ar, this message translates to:
  /// **'لأولياء الأمور'**
  String get familyMembersChildLeanTitle;

  /// SCR-FAT-027 child lean message
  ///
  /// In ar, this message translates to:
  /// **'أعضاء العائلة والأدوار مساحة للوالدين — ليست جزءًا من تجربة الابن.'**
  String get familyMembersChildLeanMessage;

  /// SCR-CHD-005 app bar title
  ///
  /// In ar, this message translates to:
  /// **'طلب النجدة'**
  String get childSosTitle;

  /// SCR-CHD-005 app bar chip
  ///
  /// In ar, this message translates to:
  /// **'زر الاستغاثة'**
  String get childSosSubtitle;

  /// SCR-CHD-005 hold instruction
  ///
  /// In ar, this message translates to:
  /// **'إذا حسّيت بخطر — اضغط مطوّلًا ٣ ثوانٍ'**
  String get childSosHint;

  /// SCR-CHD-005 big hold button label
  ///
  /// In ar, this message translates to:
  /// **'نجدة\n🚨'**
  String get childSosHoldLabel;

  /// SCR-CHD-005 Semantics for hold button
  ///
  /// In ar, this message translates to:
  /// **'زر الاستغاثة — اضغط باستمرار ثلاث ثوانٍ لطلب النجدة'**
  String get childSosHoldSemantics;

  /// SCR-CHD-005 idle status
  ///
  /// In ar, this message translates to:
  /// **'اضغط باستمرار…'**
  String get childSosStatusIdle;

  /// SCR-CHD-005 countdown while holding
  ///
  /// In ar, this message translates to:
  /// **'استمر بالضغط… {seconds}'**
  String childSosStatusHolding(int seconds);

  /// SCR-CHD-005 early release protection message
  ///
  /// In ar, this message translates to:
  /// **'توقفت قبل ٣ ثوانٍ — لم ينطلق البلاغ (حماية من اللمس غير المقصود)'**
  String get childSosStatusCancelled;

  /// SCR-CHD-005 after hold completes
  ///
  /// In ar, this message translates to:
  /// **'جاري إرسال البلاغ…'**
  String get childSosStatusFiring;

  /// SCR-CHD-005 P-4 always-on honesty banner
  ///
  /// In ar, this message translates to:
  /// **'🛡 يعمل هذا الزر دائمًا — حتى لو خلص وقتك، أو انقطع النت، أو انتهى اشتراك العائلة. موقعك يوصل لأهلك فورًا.'**
  String get childSosAlwaysOnBanner;

  /// SCR-CHD-005 parent lean title
  ///
  /// In ar, this message translates to:
  /// **'لجهاز الابن'**
  String get childSosParentLeanTitle;

  /// SCR-CHD-005 parent lean message
  ///
  /// In ar, this message translates to:
  /// **'زر الاستغاثة مساحة لجهاز الابن — أولياء الأمور يستقبلون البلاغ من شاشة بلاغ الاستغاثة.'**
  String get childSosParentLeanMessage;

  /// SCR-CHD-006 headline after SOS fire
  ///
  /// In ar, this message translates to:
  /// **'وصل بلاغك لعائلتك'**
  String get childSosInProgressHeadline;

  /// SCR-CHD-006 live location broadcast note
  ///
  /// In ar, this message translates to:
  /// **'موقعك يُبث لوالديك مباشرة الآن'**
  String get childSosInProgressBroadcast;

  /// SCR-CHD-006 father saw alert status (role noun, Rule 23)
  ///
  /// In ar, this message translates to:
  /// **'✓ أبوك شاهد البلاغ — وهو يتصل بك وفي الطريق إليك'**
  String get childSosInProgressFatherSeen;

  /// SCR-CHD-006 mother saw alert status (role noun, Rule 23)
  ///
  /// In ar, this message translates to:
  /// **'✓ أمك شاهدت البلاغ'**
  String get childSosInProgressMotherSeen;

  /// SCR-CHD-006 backup contacts standby
  ///
  /// In ar, this message translates to:
  /// **'⏳ جهات الطوارئ الاحتياطية متأهبة'**
  String get childSosInProgressBackupStandby;

  /// SCR-CHD-006 call father CTA
  ///
  /// In ar, this message translates to:
  /// **'📞 كلّم أبوك الآن'**
  String get childSosInProgressCallFatherCta;

  /// SCR-CHD-006 call father semantics
  ///
  /// In ar, this message translates to:
  /// **'اتصال فوري بالأب أثناء الاستغاثة'**
  String get childSosInProgressCallFatherSemantics;

  /// SCR-CHD-006 safe cancel CTA
  ///
  /// In ar, this message translates to:
  /// **'أنا بخير — إلغاء البلاغ 💚'**
  String get childSosInProgressCancelCta;

  /// SCR-CHD-006 cancel CTA semantics
  ///
  /// In ar, this message translates to:
  /// **'فتح تأكيد إلغاء بلاغ الاستغاثة'**
  String get childSosInProgressCancelSemantics;

  /// SCR-CHD-006 cancel confirmation title
  ///
  /// In ar, this message translates to:
  /// **'إلغاء البلاغ؟'**
  String get childSosInProgressCancelSheetTitle;

  /// SCR-CHD-006 cancel confirmation body
  ///
  /// In ar, this message translates to:
  /// **'أكيد إنك بخير؟ عائلتك ستعرف أنك بخير وألغيته بنفسك.'**
  String get childSosInProgressCancelSheetBody;

  /// SCR-CHD-006 confirm I am safe
  ///
  /// In ar, this message translates to:
  /// **'نعم أنا بأمان والحمد لله ✓'**
  String get childSosInProgressConfirmSafeCta;

  /// SCR-CHD-006 confirm safe semantics
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الأمان وإلغاء بلاغ الاستغاثة'**
  String get childSosInProgressConfirmSafeSemantics;

  /// SCR-CHD-006 dismiss cancel sheet
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get childSosInProgressCancelBackCta;

  /// SCR-CHD-006 after child resolves SOS
  ///
  /// In ar, this message translates to:
  /// **'الحمد لله على سلامتك يا بطل 💚 أُخطر أهلك أنك بأمان'**
  String get childSosInProgressResolvedToast;

  /// SCR-CHD-006 P-4 never muted/gated banner
  ///
  /// In ar, this message translates to:
  /// **'🛡 الاستغاثة الجارية لا تُكتم ولا تُقيَّد بالاشتراك — بث موقعك يصل دائمًا لعائلتك'**
  String get childSosInProgressP4Banner;

  /// SCR-CHD-006 empty title
  ///
  /// In ar, this message translates to:
  /// **'لا بلاغ استغاثة جارٍ'**
  String get childSosInProgressEmptyTitle;

  /// SCR-CHD-006 empty message
  ///
  /// In ar, this message translates to:
  /// **'عند إطلاق الاستغاثة تظهر هنا حالة البث الحي ومن شاهد البلاغ.'**
  String get childSosInProgressEmptyMessage;

  /// SCR-CHD-006 empty CTA to CHD-005
  ///
  /// In ar, this message translates to:
  /// **'زر الاستغاثة ←'**
  String get childSosInProgressOpenButtonCta;

  /// SCR-CHD-006 empty CTA semantics
  ///
  /// In ar, this message translates to:
  /// **'فتح زر الاستغاثة'**
  String get childSosInProgressOpenButtonSemantics;

  /// SCR-CHD-006 error title
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل البلاغ'**
  String get childSosInProgressErrorTitle;

  /// SCR-CHD-006 error message
  ///
  /// In ar, this message translates to:
  /// **'حاول مجددًا — الاستغاثة لا تعتمد على هذه الشاشة وحدها.'**
  String get childSosInProgressErrorMessage;

  /// SCR-CHD-006 parent lean title
  ///
  /// In ar, this message translates to:
  /// **'لجهاز الابن'**
  String get childSosInProgressParentLeanTitle;

  /// SCR-CHD-006 parent lean message
  ///
  /// In ar, this message translates to:
  /// **'شاشة الاستغاثة الجارية لجهاز الابن — أولياء الأمور يتابعون من لوحة بلاغ الاستغاثة.'**
  String get childSosInProgressParentLeanMessage;

  /// SCR-CHD-006 status card semantics
  ///
  /// In ar, this message translates to:
  /// **'بث الموقع الحي أثناء الاستغاثة'**
  String get childSosInProgressBroadcastSemantics;

  /// SCR-CHD-007 app bar title (family tab)
  ///
  /// In ar, this message translates to:
  /// **'محادثاتي'**
  String get childChatsTitle;

  /// SCR-CHD-007 UI-007 encryption + never-lock honesty
  ///
  /// In ar, this message translates to:
  /// **'🔒 كل محادثاتكم مشفّرة طرفيًا — ولا تُقفل أبدًا حتى بانتهاء وقتك'**
  String get childChatsHonestyBanner;

  /// SCR-CHD-007 closed-circle honesty
  ///
  /// In ar, this message translates to:
  /// **'🛡 دائرتك الآمنة: تتواصل مع من اعتمدهم والدك فقط — ولا يوصلك أي غريب.'**
  String get childChatsSafeCircleBanner;

  /// SCR-CHD-007 phone contacts CTA (عل-٤)
  ///
  /// In ar, this message translates to:
  /// **'📞 اتصال — جهات اتصال هاتفك'**
  String get childChatsCallContactsCta;

  /// SCR-CHD-007 phone contacts CTA semantics
  ///
  /// In ar, this message translates to:
  /// **'فتح جهات اتصال الهاتف — العائلة المعتمدة أولًا'**
  String get childChatsCallContactsSemantics;

  /// SCR-CHD-007 Stage-1 phone contacts snackbar
  ///
  /// In ar, this message translates to:
  /// **'جهات اتصال الهاتف — قريبًا (مرحلة ١)'**
  String get childChatsCallContactsToast;

  /// SCR-CHD-007 empty state title
  ///
  /// In ar, this message translates to:
  /// **'لا محادثات بعد'**
  String get childChatsEmptyTitle;

  /// SCR-CHD-007 empty state message
  ///
  /// In ar, this message translates to:
  /// **'عند بدء محادثة مع عائلتك تظهر هنا — مشفّرة ولا تُقفل أبدًا حتى بانتهاء وقتك.'**
  String get childChatsEmptyMessage;

  /// SCR-CHD-007 loading Semantics
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحميل محادثاتك'**
  String get childChatsLoadingSemantics;

  /// SCR-CHD-007 parent-role lean title
  ///
  /// In ar, this message translates to:
  /// **'لجهاز الابن'**
  String get childChatsParentLeanTitle;

  /// SCR-CHD-007 parent-role lean message
  ///
  /// In ar, this message translates to:
  /// **'محادثات الابن لجهازه — أولياء الأمور يفتحون قائمة العائلة من تبويب العائلة.'**
  String get childChatsParentLeanMessage;

  /// SCR-CHD-008 fallback title
  ///
  /// In ar, this message translates to:
  /// **'المحادثة'**
  String get childConversationTitle;

  /// SCR-CHD-008 send time label
  ///
  /// In ar, this message translates to:
  /// **'الآن'**
  String get childConversationNowLabel;

  /// SCR-CHD-008 incoming call card
  ///
  /// In ar, this message translates to:
  /// **'أحد والديك يتصل بك الآن'**
  String get childConversationIncomingTitle;

  /// SCR-CHD-008 incoming subtitle
  ///
  /// In ar, this message translates to:
  /// **'مكالمة اطمئنان — ترنّ حتى بالصامت'**
  String get childConversationIncomingSubtitle;

  /// SCR-CHD-008 answer CTA
  ///
  /// In ar, this message translates to:
  /// **'رد ✓'**
  String get childConversationAnswerCta;

  /// SCR-CHD-008 answer toast
  ///
  /// In ar, this message translates to:
  /// **'📞 رددت بلمسة واحدة — يسمعك الآن'**
  String get childConversationAnswerToast;

  /// SCR-CHD-008 never-lock UI-007
  ///
  /// In ar, this message translates to:
  /// **'💬 هذي المحادثة ما تقفل أبدًا — حتى لو خلص وقت اللعب. أهلك دايمًا موجودين.'**
  String get childConversationNeverLockBanner;

  /// SCR-CHD-008 composer hint
  ///
  /// In ar, this message translates to:
  /// **'اكتب رسالة…'**
  String get childConversationInputHint;

  /// SCR-CHD-008 send semantics
  ///
  /// In ar, this message translates to:
  /// **'إرسال الرسالة'**
  String get childConversationSendSemantics;

  /// SCR-CHD-008 loading
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحميل المحادثة'**
  String get childConversationLoadingSemantics;

  /// SCR-CHD-008 empty thread
  ///
  /// In ar, this message translates to:
  /// **'ابدأ المحادثة'**
  String get childConversationEmptyTitle;

  /// SCR-CHD-008 empty body
  ///
  /// In ar, this message translates to:
  /// **'اكتب لأول مرة — الرسالة تصل فورًا لعائلتك.'**
  String get childConversationEmptyMessage;

  /// SCR-CHD-008 missing chatWith
  ///
  /// In ar, this message translates to:
  /// **'اختر محادثة'**
  String get childConversationMissingPeerTitle;

  /// SCR-CHD-008 missing peer body
  ///
  /// In ar, this message translates to:
  /// **'افتح محادثة من قائمة عائلتي أولًا.'**
  String get childConversationMissingPeerMessage;

  /// SCR-CHD-008 not found
  ///
  /// In ar, this message translates to:
  /// **'المحادثة غير موجودة'**
  String get childConversationNotFoundTitle;

  /// SCR-CHD-008 not found body
  ///
  /// In ar, this message translates to:
  /// **'قد تكون خارج دائرتك الآمنة — ارجع لقائمة المحادثات.'**
  String get childConversationNotFoundMessage;

  /// SCR-CHD-008 parent lean
  ///
  /// In ar, this message translates to:
  /// **'لجهاز الابن'**
  String get childConversationParentLeanTitle;

  /// SCR-CHD-008 parent lean body
  ///
  /// In ar, this message translates to:
  /// **'محادثة الابن لجهازه — استخدم قائمة المحادثات من حساب الوالد.'**
  String get childConversationParentLeanMessage;

  /// SCR-CHD-009 title
  ///
  /// In ar, this message translates to:
  /// **'مكالمة'**
  String get childActiveCallTitle;

  /// SCR-CHD-009 status line
  ///
  /// In ar, this message translates to:
  /// **'جارية · {elapsed}'**
  String childActiveCallStatus(String elapsed);

  /// SCR-CHD-009 mute
  ///
  /// In ar, this message translates to:
  /// **'كتم الميكروفون'**
  String get childActiveCallMuteSemantics;

  /// SCR-CHD-009 speaker
  ///
  /// In ar, this message translates to:
  /// **'مكبر الصوت'**
  String get childActiveCallSpeakerSemantics;

  /// SCR-CHD-009 end
  ///
  /// In ar, this message translates to:
  /// **'إنهاء المكالمة'**
  String get childActiveCallEndSemantics;

  /// SCR-CHD-009 mute on
  ///
  /// In ar, this message translates to:
  /// **'الميكروفون مكتوم'**
  String get childActiveCallMuteOnToast;

  /// SCR-CHD-009 mute off
  ///
  /// In ar, this message translates to:
  /// **'الميكروفون مفتوح'**
  String get childActiveCallMuteOffToast;

  /// SCR-CHD-009 speaker on
  ///
  /// In ar, this message translates to:
  /// **'مكبر الصوت يعمل'**
  String get childActiveCallSpeakerOnToast;

  /// SCR-CHD-009 speaker off
  ///
  /// In ar, this message translates to:
  /// **'مكبر الصوت مغلق'**
  String get childActiveCallSpeakerOffToast;

  /// SCR-CHD-009 loading
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تجهيز المكالمة'**
  String get childActiveCallLoadingSemantics;

  /// SCR-CHD-009 missing callId
  ///
  /// In ar, this message translates to:
  /// **'لا مكالمة محددة'**
  String get childActiveCallMissingIdTitle;

  /// SCR-CHD-009 missing body
  ///
  /// In ar, this message translates to:
  /// **'ابدأ مكالمة من جهات اتصال عائلتك.'**
  String get childActiveCallMissingIdMessage;

  /// SCR-CHD-009 not found
  ///
  /// In ar, this message translates to:
  /// **'المكالمة انتهت'**
  String get childActiveCallNotFoundTitle;

  /// SCR-CHD-009 not found body
  ///
  /// In ar, this message translates to:
  /// **'ارجع لمحادثاتك وحاول مرة أخرى.'**
  String get childActiveCallNotFoundMessage;

  /// SCR-CHD-009 parent lean
  ///
  /// In ar, this message translates to:
  /// **'لجهاز الابن'**
  String get childActiveCallParentLeanTitle;

  /// SCR-CHD-009 parent lean body
  ///
  /// In ar, this message translates to:
  /// **'مكالمة الابن لجهازه — أولياء الأمور يستخدمون شاشة المكالمة الجارية.'**
  String get childActiveCallParentLeanMessage;

  /// SCR-SHR-008 AppBar title
  ///
  /// In ar, this message translates to:
  /// **'تبديل المستخدم'**
  String get deviceUserSwitchTitle;

  /// SCR-SHR-008 active profile self marker
  ///
  /// In ar, this message translates to:
  /// **'{name} (أنت)'**
  String deviceUserSwitchSelfName(String name);

  /// SCR-SHR-008 father subtitle
  ///
  /// In ar, this message translates to:
  /// **'مالك العائلة'**
  String get deviceUserSwitchRoleOwner;

  /// SCR-SHR-008 mother subtitle base
  ///
  /// In ar, this message translates to:
  /// **'وليّة أمر'**
  String get deviceUserSwitchRoleMother;

  /// SCR-SHR-008 mother subtitle with permission level
  ///
  /// In ar, this message translates to:
  /// **'وليّة أمر — {level}'**
  String deviceUserSwitchRoleMotherWithLevel(String level);

  /// SCR-SHR-008 child profile subtitle
  ///
  /// In ar, this message translates to:
  /// **'ابن'**
  String get deviceUserSwitchRoleChild;

  /// SCR-SHR-008 active profile tag
  ///
  /// In ar, this message translates to:
  /// **'نشط'**
  String get deviceUserSwitchActiveTag;

  /// SCR-SHR-008 inactive profile trailing
  ///
  /// In ar, this message translates to:
  /// **'دخول ←'**
  String get deviceUserSwitchEnterHint;

  /// SCR-SHR-008 add local account CTA
  ///
  /// In ar, this message translates to:
  /// **'+ إضافة حساب على هذا الجهاز'**
  String get deviceUserSwitchAddAccountCta;

  /// SCR-SHR-008 add account honesty toast
  ///
  /// In ar, this message translates to:
  /// **'كل حساب بكلمة مروره — لا جلسات مفتوحة'**
  String get deviceUserSwitchAddAccountToast;

  /// SCR-SHR-008 empty title Rule 23
  ///
  /// In ar, this message translates to:
  /// **'لا حسابات على هذا الجهاز بعد'**
  String get deviceUserSwitchEmptyTitle;

  /// SCR-SHR-008 empty body
  ///
  /// In ar, this message translates to:
  /// **'أضف حساب الأب أو الأم هنا للتبديل بلا إعادة تثبيت.'**
  String get deviceUserSwitchEmptyMessage;

  /// SCR-SHR-008 child RoleGuard lean
  ///
  /// In ar, this message translates to:
  /// **'لأولياء الأمور'**
  String get deviceUserSwitchChildLeanTitle;

  /// SCR-SHR-008 child lean body
  ///
  /// In ar, this message translates to:
  /// **'تبديل المستخدم بين الأب والأم على جهاز مشترك — جهاز الابن يبقى في وضع الابن.'**
  String get deviceUserSwitchChildLeanMessage;

  /// SCR-SHR-008 password confirm dialog title
  ///
  /// In ar, this message translates to:
  /// **'تأكيد التبديل'**
  String get deviceUserSwitchConfirmTitle;

  /// SCR-SHR-008 password confirm body
  ///
  /// In ar, this message translates to:
  /// **'أدخل كلمة مرور حساب «{name}» للتبديل على هذا الجهاز.'**
  String deviceUserSwitchConfirmBody(String name);

  /// SCR-SHR-008 mock password field
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get deviceUserSwitchPasswordLabel;

  /// SCR-SHR-008 confirm switch
  ///
  /// In ar, this message translates to:
  /// **'دخول'**
  String get deviceUserSwitchConfirmSubmit;

  /// SCR-SHR-008 cancel switch
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get deviceUserSwitchConfirmCancel;

  /// SCR-CHD-011 AppBar title
  ///
  /// In ar, this message translates to:
  /// **'فتح وضع الوالد'**
  String get childModeLockTitle;

  /// SCR-CHD-011 AppBar chip
  ///
  /// In ar, this message translates to:
  /// **'قفل ثلاثي 🔐'**
  String get childModeLockSubtitle;

  /// SCR-CHD-011 dual-key honesty banner
  ///
  /// In ar, this message translates to:
  /// **'🔒 هذا الجهاز في وضع الابن المقفول. الفتح يحتاج مفتاحين: كلمة مرور وليّ الأمر + موافقة من جهازه.'**
  String get childModeLockDualKeyBanner;

  /// SCR-CHD-011 secret entry step title
  ///
  /// In ar, this message translates to:
  /// **'الخطوة ١ — المدخل السري'**
  String get childModeLockSecretStepTitle;

  /// SCR-CHD-011 secret hold instruction
  ///
  /// In ar, this message translates to:
  /// **'اضغط مطوّلًا ١٠ ثوانٍ على الشعار:'**
  String get childModeLockSecretStepHint;

  /// SCR-CHD-011 logo hold semantics
  ///
  /// In ar, this message translates to:
  /// **'اضغط مطوّلًا عشر ثوانٍ على شعار العائلة لفتح المدخل السري'**
  String get childModeLockLogoHoldSemantics;

  /// SCR-CHD-011 secret entry opened
  ///
  /// In ar, this message translates to:
  /// **'✓ فُتح المدخل (محاكاة)'**
  String get childModeLockSecretOpened;

  /// SCR-CHD-011 password step title
  ///
  /// In ar, this message translates to:
  /// **'الخطوة ٢ — كلمة مرور الحساب'**
  String get childModeLockPasswordStepTitle;

  /// SCR-CHD-011 no-PIN honesty
  ///
  /// In ar, this message translates to:
  /// **'كلمة مرور وليّ الأمر — ليست رقم PIN للجهاز.'**
  String get childModeLockPasswordStepHint;

  /// SCR-CHD-011 password field label
  ///
  /// In ar, this message translates to:
  /// **'كلمة مرور الحساب'**
  String get childModeLockPasswordLabel;

  /// SCR-CHD-011 password field hint
  ///
  /// In ar, this message translates to:
  /// **'كلمة مرور وليّ الأمر — لا PIN'**
  String get childModeLockPasswordHint;

  /// SCR-CHD-011 verify password CTA
  ///
  /// In ar, this message translates to:
  /// **'تحقّق'**
  String get childModeLockVerifyCta;

  /// SCR-CHD-011 verifying label
  ///
  /// In ar, this message translates to:
  /// **'جاري التحقّق…'**
  String get childModeLockVerifying;

  /// SCR-CHD-011 verify CTA semantics
  ///
  /// In ar, this message translates to:
  /// **'التحقّق من كلمة مرور وليّ الأمر لطلب المفتاح الثاني'**
  String get childModeLockVerifySemantics;

  /// SCR-CHD-011 failed password status
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور غير صحيحة ({current}/{max}) — أُخطر الأب فورًا'**
  String childModeLockPasswordFailed(int current, int max);

  /// SCR-CHD-011 request sent toast
  ///
  /// In ar, this message translates to:
  /// **'أُرسل طلب الموافقة إلى جهاز الأب…'**
  String get childModeLockRequestSentToast;

  /// SCR-CHD-011 awaiting second key
  ///
  /// In ar, this message translates to:
  /// **'⏳ الخطوة ٣ — بانتظار المفتاح الثاني من جهاز والدك. كلمة المرور وحدها لا تكفي.'**
  String get childModeLockAwaitingBanner;

  /// SCR-CHD-011 CTA to FAT-030
  ///
  /// In ar, this message translates to:
  /// **'شاهد ما يصل الأب ←'**
  String get childModeLockViewFatherCta;

  /// SCR-CHD-011 FAT-030 CTA semantics
  ///
  /// In ar, this message translates to:
  /// **'الانتقال لشاشة طلب فتح وضع الوالد على جهاز الأب'**
  String get childModeLockViewFatherSemantics;

  /// SCR-CHD-011 attempts warning banner
  ///
  /// In ar, this message translates to:
  /// **'⚠️ كل محاولة خاطئة تصل والدك فورًا. وبعد ٣ محاولات: قفل ٢٤ ساعة + إخطار والدتك.'**
  String get childModeLockAttemptsWarning;

  /// SCR-CHD-011 24h lockout banner
  ///
  /// In ar, this message translates to:
  /// **'🔒 قُفل المدخل ٢٤ ساعة بعد ثلاث محاولات فاشلة — وأُخطرت والدتك.'**
  String get childModeLockLockoutBanner;

  /// SCR-CHD-011 entertainment locked row
  ///
  /// In ar, this message translates to:
  /// **'الترفيه مقفل في وضع الابن — لا يخرج إلا بمفتاحين.'**
  String get childModeLockEntertainmentLocked;

  /// SCR-CHD-011 P-4 SOS CTA
  ///
  /// In ar, this message translates to:
  /// **'🛡 استغاثة — دائمًا متاحة'**
  String get childModeLockSosCta;

  /// SCR-CHD-011 parent RoleGuard lean
  ///
  /// In ar, this message translates to:
  /// **'لجهاز الابن'**
  String get childModeLockParentLeanTitle;

  /// SCR-CHD-011 parent lean body
  ///
  /// In ar, this message translates to:
  /// **'قفل وضع الابن والمدخل السري على جهاز الابن — المفتاح الثاني يصل الأب في طلب فتح وضع الوالد.'**
  String get childModeLockParentLeanMessage;

  /// SCR-FAT-030 AppBar title
  ///
  /// In ar, this message translates to:
  /// **'طلبات فتح وضع الوالد'**
  String get parentSecondKeyTitle;

  /// SCR-FAT-030 empty inbox title
  ///
  /// In ar, this message translates to:
  /// **'لا طلبات فتح الآن'**
  String get parentSecondKeyEmptyTitle;

  /// SCR-FAT-030 empty inbox body
  ///
  /// In ar, this message translates to:
  /// **'عندما يتحقّق جهاز ابن من كلمة مرور الحساب، يصل طلب المفتاح الثاني هنا لتسمح أو ترفض.'**
  String get parentSecondKeyEmptyMessage;

  /// SCR-FAT-030 pending card heading
  ///
  /// In ar, this message translates to:
  /// **'🔓 طلب الآن'**
  String get parentSecondKeyPendingHeading;

  /// SCR-FAT-030 pending request title
  ///
  /// In ar, this message translates to:
  /// **'طلب فتح وضع الوالد على جهاز الابن'**
  String get parentSecondKeyPendingBody;

  /// SCR-FAT-030 pending meta line
  ///
  /// In ar, this message translates to:
  /// **'أُدخلت كلمة المرور الصحيحة · بانتظار موافقتك'**
  String get parentSecondKeyPendingMeta;

  /// SCR-FAT-030 approve CTA
  ///
  /// In ar, this message translates to:
  /// **'سماح ١٠ دقائق'**
  String get parentSecondKeyApprove;

  /// SCR-FAT-030 deny CTA
  ///
  /// In ar, this message translates to:
  /// **'رفض'**
  String get parentSecondKeyDeny;

  /// SCR-FAT-030 approve semantics
  ///
  /// In ar, this message translates to:
  /// **'السماح بفتح وضع الوالد عشر دقائق على جهاز الابن'**
  String get parentSecondKeyApproveSemantics;

  /// SCR-FAT-030 deny semantics
  ///
  /// In ar, this message translates to:
  /// **'رفض طلب فتح وضع الوالد'**
  String get parentSecondKeyDenySemantics;

  /// SCR-FAT-030 approve toast
  ///
  /// In ar, this message translates to:
  /// **'سُمح بفتح وضع الوالد ١٠ دقائق على جهاز الابن'**
  String get parentSecondKeyApprovedToast;

  /// SCR-FAT-030 deny toast
  ///
  /// In ar, this message translates to:
  /// **'رُفض الطلب — بقي جهاز الابن مقفولًا'**
  String get parentSecondKeyDeniedToast;

  /// SCR-FAT-030 failed attempts section
  ///
  /// In ar, this message translates to:
  /// **'سجل المحاولات'**
  String get parentSecondKeyAttemptsTitle;

  /// SCR-FAT-030 empty attempt log
  ///
  /// In ar, this message translates to:
  /// **'لا محاولات فاشلة بعد.'**
  String get parentSecondKeyAttemptsEmpty;

  /// SCR-FAT-030 failed attempt row
  ///
  /// In ar, this message translates to:
  /// **'محاولة بكلمة مرور خاطئة ({current}/{max})'**
  String parentSecondKeyAttemptFailed(int current, int max);

  /// SCR-FAT-030 lockout attempt row
  ///
  /// In ar, this message translates to:
  /// **'قفل بعد المحاولة {current} — أُخطرت الأم'**
  String parentSecondKeyAttemptLockout(int current);

  /// SCR-FAT-030 attempt device subtitle
  ///
  /// In ar, this message translates to:
  /// **'جهاز الابن'**
  String get parentSecondKeyAttemptDevice;

  /// SCR-FAT-030 lockout honesty banner
  ///
  /// In ar, this message translates to:
  /// **'💡 بعد ٣ محاولات فاشلة: قفل ٢٤ ساعة + إخطار الأم. الثغرة صارت جرس إنذار مبكرًا للتحايل.'**
  String get parentSecondKeyLockoutHint;

  /// SCR-FAT-030 mother view-only hint
  ///
  /// In ar, this message translates to:
  /// **'🔒 المفتاح الثاني في جيب الأب — ترين الطلبات والمحاولات الفاشلة؛ السماح/الرفض على جهازه.'**
  String get parentSecondKeyMotherHint;

  /// SCR-FAT-030 P-4 SOS CTA
  ///
  /// In ar, this message translates to:
  /// **'🛡 الاستغاثة — متاحة دائمًا'**
  String get parentSecondKeySosCta;

  /// SCR-FAT-030 child RoleGuard lean
  ///
  /// In ar, this message translates to:
  /// **'لجهاز الوالد'**
  String get parentSecondKeyChildLeanTitle;

  /// SCR-FAT-030 child lean body
  ///
  /// In ar, this message translates to:
  /// **'سماح ورفض المفتاح الثاني على جهاز الأب بعد أن يتحقّق الابن من كلمة مرور الحساب.'**
  String get parentSecondKeyChildLeanMessage;

  /// SCR-FAT-031 AppBar title
  ///
  /// In ar, this message translates to:
  /// **'مستوى صلاحية الأم'**
  String get motherPermissionLevelTitle;

  /// SCR-FAT-031 selected level title with current marker
  ///
  /// In ar, this message translates to:
  /// **'{level} — الحالية'**
  String motherPermissionLevelCurrentTitle(String level);

  /// SCR-FAT-031 مطّلعة description
  ///
  /// In ar, this message translates to:
  /// **'ترى وتطمئن وتُخطرك'**
  String get motherPermissionLevelObserverDesc;

  /// SCR-FAT-031 مشاركة description
  ///
  /// In ar, this message translates to:
  /// **'+ توافق على الطلبات وتمنح وقتًا (≤٣٠ د) وتدير المهام'**
  String get motherPermissionLevelPartnerDesc;

  /// SCR-FAT-031 كاملة description
  ///
  /// In ar, this message translates to:
  /// **'+ تعديل القواعد والحدود والمناطق الآمنة'**
  String get motherPermissionLevelFullDesc;

  /// SCR-FAT-031 P-4 fixed rights + owner-reserved banner
  ///
  /// In ar, this message translates to:
  /// **'بأي مستوى: الاستغاثة تصلها · تتصل بالأبناء · ترى مواقعهم. ومستشار العائلة والاشتراك والدعوات لك وحدك.'**
  String get motherPermissionLevelFixedRightsBanner;

  /// SCR-FAT-031 non-owner lean banner
  ///
  /// In ar, this message translates to:
  /// **'هذه الشاشة للمالك وحده — تغيير مستوى صلاحية الأم على جهاز الأب.'**
  String get motherPermissionLevelOwnerOnlyBanner;

  /// SCR-FAT-031 immutable audit heading
  ///
  /// In ar, this message translates to:
  /// **'سجل التغييرات — لا يُحذف'**
  String get motherPermissionLevelAuditTitle;

  /// SCR-FAT-031 empty audit honesty
  ///
  /// In ar, this message translates to:
  /// **'لا تغييرات بعد — كل رفع أو خفض يُسجَّل هنا ولا يُحذف.'**
  String get motherPermissionLevelAuditEmpty;

  /// SCR-FAT-031 audit row from→to (RTL arrow)
  ///
  /// In ar, this message translates to:
  /// **'{from} ← {to}'**
  String motherPermissionLevelAuditTransition(String from, String to);

  /// SCR-FAT-031 audit meta — no planted names (Rule 23)
  ///
  /// In ar, this message translates to:
  /// **'{when} · بواسطتك · أُخطرت الأم'**
  String motherPermissionLevelAuditMeta(String when);

  /// SCR-FAT-031 downgrade double-confirm title
  ///
  /// In ar, this message translates to:
  /// **'⚠️ تأكيد الخفض'**
  String get motherPermissionLevelDowngradeTitle;

  /// SCR-FAT-031 downgrade confirm body — parametric level, no planted names
  ///
  /// In ar, this message translates to:
  /// **'ستفقد القدرة على الموافقة على طلبات الأبناء ومنح الوقت الإضافي عند الخفض إلى «{level}» — متأكد؟'**
  String motherPermissionLevelDowngradeBody(String level);

  /// SCR-FAT-031 downgrade confirm CTA
  ///
  /// In ar, this message translates to:
  /// **'نعم — خفّض إلى {level}'**
  String motherPermissionLevelDowngradeConfirm(String level);

  /// SCR-FAT-031 upgrade trust title
  ///
  /// In ar, this message translates to:
  /// **'🤍 ترقية إلى «{level}»'**
  String motherPermissionLevelUpgradeTitle(String level);

  /// SCR-FAT-031 upgrade trust body — no planted father/mother names
  ///
  /// In ar, this message translates to:
  /// **'ستصلها رسالة ثقة: يمكنك الآن المزيد ضمن مستوى «{level}» — دون منح صلاحيات المالك (مستشار العائلة · الاشتراك · الدعوات).'**
  String motherPermissionLevelUpgradeBody(String level);

  /// SCR-FAT-031 upgrade confirm CTA
  ///
  /// In ar, this message translates to:
  /// **'رقِّ إلى {level}'**
  String motherPermissionLevelUpgradeConfirm(String level);

  /// SCR-FAT-031 dialog cancel
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get motherPermissionLevelDialogCancel;

  /// SCR-FAT-031 downgrade toast
  ///
  /// In ar, this message translates to:
  /// **'خُفض المستوى إلى «{level}» — وأُخطرت الأم بالتغيير'**
  String motherPermissionLevelDowngradedToast(String level);

  /// SCR-FAT-031 upgrade toast
  ///
  /// In ar, this message translates to:
  /// **'رُقيت إلى «{level}» 🤍 — سُجّل في سجل لا يُحذف'**
  String motherPermissionLevelUpgradedToast(String level);

  /// SCR-FAT-031 P-4 SOS CTA
  ///
  /// In ar, this message translates to:
  /// **'🛡 الاستغاثة — متاحة دائمًا'**
  String get motherPermissionLevelSosCta;

  /// SCR-FAT-031 child RoleGuard lean title
  ///
  /// In ar, this message translates to:
  /// **'لجهاز الوالد'**
  String get motherPermissionLevelChildLeanTitle;

  /// SCR-FAT-031 child lean body
  ///
  /// In ar, this message translates to:
  /// **'مستوى صلاحية الأم يحدّده المالك فقط — لا يظهر على جهاز الابن.'**
  String get motherPermissionLevelChildLeanMessage;

  /// SCR-FAT-051 screen title
  ///
  /// In ar, this message translates to:
  /// **'تقرير وجلسات التركيز'**
  String get focusReportTitle;

  /// SCR-FAT-051 child heading
  ///
  /// In ar, this message translates to:
  /// **'جلسات تركيز {name}'**
  String focusReportHeading(String name);

  /// SCR-FAT-051 weekly summary label
  ///
  /// In ar, this message translates to:
  /// **'هذا الأسبوع'**
  String get focusReportWeeklyLabel;

  /// SCR-FAT-051 goal tag complete
  ///
  /// In ar, this message translates to:
  /// **'🎯 الهدف الأسبوعي: مكتمل ١٠٠٪'**
  String get focusReportGoalComplete;

  /// SCR-FAT-051 goal tag in progress
  ///
  /// In ar, this message translates to:
  /// **'🎯 الهدف الأسبوعي: قيد التقدم'**
  String get focusReportGoalInProgress;

  /// SCR-FAT-051 sessions count label
  ///
  /// In ar, this message translates to:
  /// **'جلسات تركيز'**
  String get focusReportSessionsLabel;

  /// SCR-FAT-051 weekly duration line
  ///
  /// In ar, this message translates to:
  /// **'{hours} س {minutes} د تركيز صافٍ · أطولها {longest} د'**
  String focusReportWeeklyMeta(int hours, int minutes, int longest);

  /// SCR-FAT-051 advisor headline
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة ذكية: انضباط ذاتي يستحق التقدير'**
  String get focusReportAdvisorTitleSelfDiscipline;

  /// SCR-FAT-051 advisor body — Rule 23 generic child
  ///
  /// In ar, this message translates to:
  /// **'أثناء مذاكرة العلوم يوم الاثنين، حاول {name} فتح تطبيقًا مشتتًا مرتين لكنه تراجع بنفسه فورًا وعاد لمواصلة دراسته.'**
  String focusReportAdvisorBodyScienceResist(String name);

  /// SCR-FAT-051 praise status new
  ///
  /// In ar, this message translates to:
  /// **'جديد'**
  String get focusReportPraiseNewTag;

  /// SCR-FAT-051 praise status sent
  ///
  /// In ar, this message translates to:
  /// **'تم الثناء ✓'**
  String get focusReportPraiseSentTag;

  /// SCR-FAT-051 send praise CTA
  ///
  /// In ar, this message translates to:
  /// **'أرسل ثناءً وتشجيعاً'**
  String get focusReportPraiseCta;

  /// SCR-FAT-051 self-discipline reward CTA — minutes only
  ///
  /// In ar, this message translates to:
  /// **'مكافأة (+{minutes} د)'**
  String focusReportRewardCta(int minutes);

  /// SCR-FAT-051 praise delivered label
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال تشجيعك لشاشة {name}:'**
  String focusReportPraiseDeliveredLabel(String name);

  /// SCR-FAT-051 sent praise quote
  ///
  /// In ar, this message translates to:
  /// **'فخور بك! لاحظت مقاومتك للتشتيت ورجوعك للمذاكرة 👏'**
  String get focusReportPraiseQuoteResistDistraction;

  /// SCR-FAT-051 praise toast
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال التشجيع إلى شاشة {name}'**
  String focusReportPraiseSentToast(String name);

  /// SCR-FAT-051 reward toast — minutes only
  ///
  /// In ar, this message translates to:
  /// **'كافأت {name} بـ +{minutes} دقيقة وقت لعب لانضباطه الذاتي الرائع'**
  String focusReportRewardToast(String name, int minutes);

  /// SCR-FAT-051 schedule card title
  ///
  /// In ar, this message translates to:
  /// **'جلساتك المجدولة'**
  String get focusReportScheduleHeading;

  /// SCR-FAT-051 schedule owner tag
  ///
  /// In ar, this message translates to:
  /// **'أنت تنشئها'**
  String get focusReportScheduleOwnerTag;

  /// SCR-FAT-051 schedule name
  ///
  /// In ar, this message translates to:
  /// **'مذاكرة العصر'**
  String get focusReportScheduleAfternoonStudy;

  /// SCR-FAT-051 schedule time
  ///
  /// In ar, this message translates to:
  /// **'٤:٣٠ – ٥:٣٠ م'**
  String get focusReportScheduleAfternoonSlot;

  /// SCR-FAT-051 schedule days
  ///
  /// In ar, this message translates to:
  /// **'أيام الدراسة'**
  String get focusReportScheduleSchoolDays;

  /// SCR-FAT-051 blocked app label
  ///
  /// In ar, this message translates to:
  /// **'تطبيقات الفيديو'**
  String get focusReportBlockedYoutube;

  /// SCR-FAT-051 blocked app label
  ///
  /// In ar, this message translates to:
  /// **'الألعاب'**
  String get focusReportBlockedGames;

  /// SCR-FAT-051 blocked apps joiner
  ///
  /// In ar, this message translates to:
  /// **'، '**
  String get focusReportBlockedJoiner;

  /// SCR-FAT-051 schedule row subtitle
  ///
  /// In ar, this message translates to:
  /// **'{time} · {days} · يُغلق: {blocked}'**
  String focusReportScheduleMeta(String time, String days, String blocked);

  /// SCR-FAT-051 add schedule CTA
  ///
  /// In ar, this message translates to:
  /// **'+ جلسة مجدولة جديدة'**
  String get focusReportAddScheduleCta;

  /// SCR-FAT-051 Stage-1 add schedule toast
  ///
  /// In ar, this message translates to:
  /// **'الجلسات المجدولة — المحرر الكامل في مرحلة لاحقة'**
  String get focusReportAddScheduleToast;

  /// SCR-FAT-051 schedule footnote
  ///
  /// In ar, this message translates to:
  /// **'أثناء الجلسة تُغلق التطبيقات المحددة فقط — والقرآن والتعليمي يبقيان مفتوحين. جلسات {name} الطوعية تبقى تكسبه دقائق انضباط كما هي.'**
  String focusReportScheduleFootnote(String name);

  /// SCR-FAT-051 generic child label
  ///
  /// In ar, this message translates to:
  /// **'الابن الأول'**
  String get focusReportChildOne;

  /// SCR-FAT-051 generic child label
  ///
  /// In ar, this message translates to:
  /// **'الابن الثاني'**
  String get focusReportChildTwo;

  /// SCR-FAT-051 generic child label
  ///
  /// In ar, this message translates to:
  /// **'الابن الثالث'**
  String get focusReportChildThree;

  /// SCR-FAT-051 empty title
  ///
  /// In ar, this message translates to:
  /// **'لا بيانات تركيز بعد'**
  String get focusReportEmptyTitle;

  /// SCR-FAT-051 empty message
  ///
  /// In ar, this message translates to:
  /// **'أضف ابنًا أولًا — ثم تظهر جلسات التركيز الأسبوعية وجداول الوالد هنا.'**
  String get focusReportEmptyMessage;

  /// SCR-FAT-051 empty CTA → FAT-003
  ///
  /// In ar, this message translates to:
  /// **'أضف ابنًا'**
  String get focusReportEmptyCta;

  /// SCR-FAT-051 loading semantics
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل تقرير التركيز'**
  String get focusReportLoadingSemantics;

  /// SCR-FAT-051 child lean title
  ///
  /// In ar, this message translates to:
  /// **'تقرير التركيز للوالدين'**
  String get focusReportChildLeanTitle;

  /// SCR-FAT-051 child lean message
  ///
  /// In ar, this message translates to:
  /// **'التقارير الأسبوعية وجداول الوالد تُدار على جهاز الوالد. زر الطوارئ يبقى متاحًا.'**
  String get focusReportChildLeanMessage;

  /// SCR-FAT-051 observer banner
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — الثناء والمكافآت وتبديل الجداول للأب أو أم شريكة/كاملة.'**
  String get focusReportObserverHint;

  /// SCR-FAT-051 observer blocked toast
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — اطلب من الأب أو أم شريكة إدارة التركيز'**
  String get focusReportObserverBlocked;

  /// SCR-FAT-051 child lean SOS CTA
  ///
  /// In ar, this message translates to:
  /// **'طوارئ'**
  String get focusReportSosCta;

  /// SCR-FAT-052 app bar title
  ///
  /// In ar, this message translates to:
  /// **'تقويم العائلة'**
  String get familyCalendarTitle;

  /// SCR-FAT-052 header hijri line (mock)
  ///
  /// In ar, this message translates to:
  /// **'الأحد ٢٢ ربيع الأول ١٤٤٨'**
  String get familyCalendarHijriDate;

  /// SCR-FAT-052 header gregorian line (mock)
  ///
  /// In ar, this message translates to:
  /// **'١٤ سبتمبر ٢٠٢٦'**
  String get familyCalendarGregorianDate;

  /// SCR-FAT-052 prayer time mock
  ///
  /// In ar, this message translates to:
  /// **'🕌 فجر ٤:٣٨'**
  String get familyCalendarPrayerFajr;

  /// SCR-FAT-052 prayer time mock
  ///
  /// In ar, this message translates to:
  /// **'🕌 ظهر ١١:٥٤'**
  String get familyCalendarPrayerDhuhr;

  /// SCR-FAT-052 prayer time mock
  ///
  /// In ar, this message translates to:
  /// **'🕌 عصر ٣:١٨'**
  String get familyCalendarPrayerAsr;

  /// SCR-FAT-052 prayer time mock
  ///
  /// In ar, this message translates to:
  /// **'🕌 مغرب ٥:٥٦'**
  String get familyCalendarPrayerMaghrib;

  /// SCR-FAT-052 prayer time mock
  ///
  /// In ar, this message translates to:
  /// **'🕌 عشاء ٧:٢٦'**
  String get familyCalendarPrayerIsha;

  /// SCR-FAT-052 month grid heading
  ///
  /// In ar, this message translates to:
  /// **'سبتمبر ٢٠٢٦ · ربيع الأول'**
  String get familyCalendarMonthSep2026;

  /// SCR-FAT-052 weekday header
  ///
  /// In ar, this message translates to:
  /// **'أحد'**
  String get familyCalendarWeekdaySun;

  /// SCR-FAT-052 weekday header
  ///
  /// In ar, this message translates to:
  /// **'اثن'**
  String get familyCalendarWeekdayMon;

  /// SCR-FAT-052 weekday header
  ///
  /// In ar, this message translates to:
  /// **'ثلا'**
  String get familyCalendarWeekdayTue;

  /// SCR-FAT-052 weekday header
  ///
  /// In ar, this message translates to:
  /// **'أرب'**
  String get familyCalendarWeekdayWed;

  /// SCR-FAT-052 weekday header
  ///
  /// In ar, this message translates to:
  /// **'خمي'**
  String get familyCalendarWeekdayThu;

  /// SCR-FAT-052 weekday header
  ///
  /// In ar, this message translates to:
  /// **'جمع'**
  String get familyCalendarWeekdayFri;

  /// SCR-FAT-052 weekday header
  ///
  /// In ar, this message translates to:
  /// **'سبت'**
  String get familyCalendarWeekdaySat;

  /// SCR-FAT-052 filter chip — all
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get familyCalendarFilterAll;

  /// SCR-FAT-052 filter chip — religious
  ///
  /// In ar, this message translates to:
  /// **'🕌 دينية'**
  String get familyCalendarFilterDin;

  /// SCR-FAT-052 filter chip — occasions
  ///
  /// In ar, this message translates to:
  /// **'🎂 مناسبات'**
  String get familyCalendarFilterOcc;

  /// SCR-FAT-052 filter chip — school
  ///
  /// In ar, this message translates to:
  /// **'🏫 دراسة'**
  String get familyCalendarFilterSch;

  /// SCR-FAT-052 filter chip — activity
  ///
  /// In ar, this message translates to:
  /// **'⚽ نشاط'**
  String get familyCalendarFilterAct;

  /// SCR-FAT-052 events list heading — all
  ///
  /// In ar, this message translates to:
  /// **'الأحداث القادمة'**
  String get familyCalendarEventsHeadingAll;

  /// SCR-FAT-052 events list heading — religious
  ///
  /// In ar, this message translates to:
  /// **'🕌 دينية'**
  String get familyCalendarEventsHeadingDin;

  /// SCR-FAT-052 events list heading — occasions
  ///
  /// In ar, this message translates to:
  /// **'🎂 مناسبات'**
  String get familyCalendarEventsHeadingOcc;

  /// SCR-FAT-052 events list heading — school
  ///
  /// In ar, this message translates to:
  /// **'🏫 دراسة'**
  String get familyCalendarEventsHeadingSch;

  /// SCR-FAT-052 events list heading — activity
  ///
  /// In ar, this message translates to:
  /// **'⚽ نشاط'**
  String get familyCalendarEventsHeadingAct;

  /// SCR-FAT-052 empty filtered list
  ///
  /// In ar, this message translates to:
  /// **'لا أحداث في هذه الفئة'**
  String get familyCalendarFilterEmpty;

  /// SCR-FAT-052 CTA → FAT-053
  ///
  /// In ar, this message translates to:
  /// **'+ حدث جديد'**
  String get familyCalendarAddEventCta;

  /// SCR-FAT-052 event title (Rule 23)
  ///
  /// In ar, this message translates to:
  /// **'مراجعة حفظ — ورد يومي'**
  String get familyCalendarEventMemorizationReview;

  /// SCR-FAT-052 event title (Rule 23)
  ///
  /// In ar, this message translates to:
  /// **'تمرين سباحة — النادي'**
  String get familyCalendarEventSwimPractice;

  /// SCR-FAT-052 event title (Rule 23)
  ///
  /// In ar, this message translates to:
  /// **'عشاء بيت الجد'**
  String get familyCalendarEventGrandpaDinner;

  /// SCR-FAT-052 event title (Rule 23)
  ///
  /// In ar, this message translates to:
  /// **'اختبار قرآن'**
  String get familyCalendarEventQuranTest;

  /// SCR-FAT-052 event title (Rule 23)
  ///
  /// In ar, this message translates to:
  /// **'ذكرى زواجكما'**
  String get familyCalendarEventAnniversary;

  /// SCR-FAT-052 event title (Rule 23)
  ///
  /// In ar, this message translates to:
  /// **'موعد أسنان'**
  String get familyCalendarEventDentalAppointment;

  /// SCR-FAT-052 event when line
  ///
  /// In ar, this message translates to:
  /// **'اليوم · بعد المغرب'**
  String get familyCalendarWhenTodayAfterMaghrib;

  /// SCR-FAT-052 event when line
  ///
  /// In ar, this message translates to:
  /// **'اليوم · ٤:٣٠ م'**
  String get familyCalendarWhenToday430pm;

  /// SCR-FAT-052 event when line
  ///
  /// In ar, this message translates to:
  /// **'اليوم · ٧:٣٠ م'**
  String get familyCalendarWhenToday730pm;

  /// SCR-FAT-052 event when line
  ///
  /// In ar, this message translates to:
  /// **'الثلاثاء'**
  String get familyCalendarWhenTuesday;

  /// SCR-FAT-052 event when line
  ///
  /// In ar, this message translates to:
  /// **'الخميس ٢٦ ربيع الأول'**
  String get familyCalendarWhenThursday26;

  /// SCR-FAT-052 event when line
  ///
  /// In ar, this message translates to:
  /// **'الخميس · ١٠ ص'**
  String get familyCalendarWhenThursday10am;

  /// SCR-FAT-052 Rule 23 who label
  ///
  /// In ar, this message translates to:
  /// **'الابن الأول'**
  String get familyCalendarWhoOne;

  /// SCR-FAT-052 Rule 23 who label
  ///
  /// In ar, this message translates to:
  /// **'الابن الثاني'**
  String get familyCalendarWhoTwo;

  /// SCR-FAT-052 Rule 23 who label
  ///
  /// In ar, this message translates to:
  /// **'الابن الثالث'**
  String get familyCalendarWhoThree;

  /// SCR-FAT-052 Rule 23 who label
  ///
  /// In ar, this message translates to:
  /// **'الأبوان'**
  String get familyCalendarWhoParents;

  /// SCR-FAT-052 Rule 23 who label
  ///
  /// In ar, this message translates to:
  /// **'الجميع'**
  String get familyCalendarWhoEveryone;

  /// SCR-FAT-052 empty title
  ///
  /// In ar, this message translates to:
  /// **'لا أحداث في التقويم بعد'**
  String get familyCalendarEmptyTitle;

  /// SCR-FAT-052 empty message
  ///
  /// In ar, this message translates to:
  /// **'أضف ابنًا أولًا — ثم تظهر الأحداث العائلية ومواقيت الصلاة وشبكة الشهر هنا.'**
  String get familyCalendarEmptyMessage;

  /// SCR-FAT-052 empty CTA → FAT-003
  ///
  /// In ar, this message translates to:
  /// **'أضف ابنًا'**
  String get familyCalendarEmptyCta;

  /// SCR-FAT-052 loading semantics
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل التقويم العائلي'**
  String get familyCalendarLoadingSemantics;

  /// SCR-FAT-052 child lean title
  ///
  /// In ar, this message translates to:
  /// **'التقويم للوالدين'**
  String get familyCalendarChildLeanTitle;

  /// SCR-FAT-052 child lean message
  ///
  /// In ar, this message translates to:
  /// **'إدارة التقويم والأحداث من جهاز الوالدين. زر SOS متاح دائمًا.'**
  String get familyCalendarChildLeanMessage;

  /// SCR-FAT-052 observer banner
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — إضافة الأحداث للأب أو الأم الشريكة/الكاملة.'**
  String get familyCalendarObserverHint;

  /// SCR-FAT-052 observer blocked toast
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — اطلب من الأب أو الأم الشريكة إدارة التقويم'**
  String get familyCalendarObserverBlocked;

  /// SCR-FAT-052 child lean SOS CTA
  ///
  /// In ar, this message translates to:
  /// **'SOS'**
  String get familyCalendarSosCta;

  /// SCR-FAT-053 app bar title
  ///
  /// In ar, this message translates to:
  /// **'حدث جديد'**
  String get addEventTitle;

  /// SCR-FAT-053 title field label
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get addEventTitleLabel;

  /// SCR-FAT-053 title field hint
  ///
  /// In ar, this message translates to:
  /// **'ما موضوع هذا الحدث؟'**
  String get addEventTitleHint;

  /// SCR-FAT-053 prototype default title (Rule 23 — no planted names)
  ///
  /// In ar, this message translates to:
  /// **'جلسة مراجعة الحفظ'**
  String get addEventDefaultTitleSample;

  /// SCR-FAT-053 category section
  ///
  /// In ar, this message translates to:
  /// **'الفئة'**
  String get addEventCategoryHeading;

  /// SCR-FAT-053 category din
  ///
  /// In ar, this message translates to:
  /// **'دينية'**
  String get addEventCategoryDin;

  /// SCR-FAT-053 category occ
  ///
  /// In ar, this message translates to:
  /// **'مناسبة'**
  String get addEventCategoryOcc;

  /// SCR-FAT-053 category sch
  ///
  /// In ar, this message translates to:
  /// **'دراسة'**
  String get addEventCategorySch;

  /// SCR-FAT-053 category act
  ///
  /// In ar, this message translates to:
  /// **'نشاط'**
  String get addEventCategoryAct;

  /// SCR-FAT-053 date section
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get addEventDateHeading;

  /// SCR-FAT-053 hijri toggle
  ///
  /// In ar, this message translates to:
  /// **'🌙 هجري'**
  String get addEventCalendarHijri;

  /// SCR-FAT-053 gregorian toggle
  ///
  /// In ar, this message translates to:
  /// **'ميلادي'**
  String get addEventCalendarGregorian;

  /// SCR-FAT-053 hijri toast
  ///
  /// In ar, this message translates to:
  /// **'🌙 التقويم الهجري معتمد (مرحلة ١)'**
  String get addEventCalendarHijriToast;

  /// SCR-FAT-053 gregorian toast
  ///
  /// In ar, this message translates to:
  /// **'📅 التقويم الميلادي معتمد (مرحلة ١)'**
  String get addEventCalendarGregorianToast;

  /// SCR-FAT-053 mock hijri date
  ///
  /// In ar, this message translates to:
  /// **'٢٣ ربيع الأول ١٤٤٨'**
  String get addEventDateHijriSample;

  /// SCR-FAT-053 mock gregorian date
  ///
  /// In ar, this message translates to:
  /// **'الاثنين ١٥ سبتمبر ٢٠٢٦'**
  String get addEventDateGregorianSample;

  /// SCR-FAT-053 date conversion note
  ///
  /// In ar, this message translates to:
  /// **'= الاثنين ١٥ سبتمبر — التحويل تلقائي'**
  String get addEventDateConversionSample;

  /// SCR-FAT-053 time label
  ///
  /// In ar, this message translates to:
  /// **'الوقت'**
  String get addEventTimeLabel;

  /// SCR-FAT-053 time after maghrib
  ///
  /// In ar, this message translates to:
  /// **'🕌 بعد المغرب مباشرة'**
  String get addEventTimeAfterMaghrib;

  /// SCR-FAT-053 time after isha
  ///
  /// In ar, this message translates to:
  /// **'🕌 بعد العشاء'**
  String get addEventTimeAfterIsha;

  /// SCR-FAT-053 specific time
  ///
  /// In ar, this message translates to:
  /// **'⏰ ساعة محددة'**
  String get addEventTimeSpecific;

  /// SCR-FAT-053 place label
  ///
  /// In ar, this message translates to:
  /// **'المكان (اختياري) 📍'**
  String get addEventPlaceLabel;

  /// SCR-FAT-053 place hint
  ///
  /// In ar, this message translates to:
  /// **'المنزل، المسجد، النادي…'**
  String get addEventPlaceHint;

  /// SCR-FAT-053 reminder label
  ///
  /// In ar, this message translates to:
  /// **'تذكير قبل'**
  String get addEventReminderLabel;

  /// SCR-FAT-053 reminder at time
  ///
  /// In ar, this message translates to:
  /// **'وقته'**
  String get addEventReminderAtTime;

  /// SCR-FAT-053 reminder 15 min
  ///
  /// In ar, this message translates to:
  /// **'١٥ دقيقة'**
  String get addEventReminderFifteenMin;

  /// SCR-FAT-053 reminder 1 hour
  ///
  /// In ar, this message translates to:
  /// **'ساعة'**
  String get addEventReminderOneHour;

  /// SCR-FAT-053 reminder 1 day
  ///
  /// In ar, this message translates to:
  /// **'يوم كامل'**
  String get addEventReminderOneDay;

  /// SCR-FAT-053 who label
  ///
  /// In ar, this message translates to:
  /// **'يخص'**
  String get addEventWhoLabel;

  /// SCR-FAT-053 who child one
  ///
  /// In ar, this message translates to:
  /// **'الابن الأول 🦁'**
  String get addEventWhoChildOne;

  /// SCR-FAT-053 who child two
  ///
  /// In ar, this message translates to:
  /// **'الابن الثاني 🐱'**
  String get addEventWhoChildTwo;

  /// SCR-FAT-053 who child three
  ///
  /// In ar, this message translates to:
  /// **'الابن الثالث 🐼'**
  String get addEventWhoChildThree;

  /// SCR-FAT-053 who mother
  ///
  /// In ar, this message translates to:
  /// **'الأم 🌸'**
  String get addEventWhoMother;

  /// SCR-FAT-053 who everyone
  ///
  /// In ar, this message translates to:
  /// **'الجميع 👨‍👩‍👧‍👦'**
  String get addEventWhoEveryone;

  /// SCR-FAT-053 weekly switch
  ///
  /// In ar, this message translates to:
  /// **'تكرار أسبوعي'**
  String get addEventWeeklyRepeat;

  /// SCR-FAT-053 save CTA
  ///
  /// In ar, this message translates to:
  /// **'حفظ الحدث ✓'**
  String get addEventSaveCta;

  /// SCR-FAT-053 empty title toast
  ///
  /// In ar, this message translates to:
  /// **'أدخل عنوان الحدث أولاً'**
  String get addEventTitleEmptyToast;

  /// SCR-FAT-053 save success toast
  ///
  /// In ar, this message translates to:
  /// **'✓ حُفظ «{title}» — ظهر في التقويم وسيُذكَّر {who}'**
  String addEventSavedToast(String title, String who);

  /// SCR-FAT-053 empty title
  ///
  /// In ar, this message translates to:
  /// **'لا أفراد في العائلة بعد'**
  String get addEventEmptyTitle;

  /// SCR-FAT-053 empty message
  ///
  /// In ar, this message translates to:
  /// **'أضف ابناً أولاً — ثم يمكن جدولة أحداث التقويم العائلي هنا.'**
  String get addEventEmptyMessage;

  /// SCR-FAT-053 empty CTA → FAT-003
  ///
  /// In ar, this message translates to:
  /// **'إضافة ابن'**
  String get addEventEmptyCta;

  /// SCR-FAT-053 loading semantics
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل نموذج إضافة حدث'**
  String get addEventLoadingSemantics;

  /// SCR-FAT-053 child lean title
  ///
  /// In ar, this message translates to:
  /// **'أحداث التقويم للوالدين'**
  String get addEventChildLeanTitle;

  /// SCR-FAT-053 child lean message
  ///
  /// In ar, this message translates to:
  /// **'إضافة أحداث التقويم العائلي تتم من جهاز الوالد. زر SOS متاح دائماً.'**
  String get addEventChildLeanMessage;

  /// SCR-FAT-053 child lean SOS CTA
  ///
  /// In ar, this message translates to:
  /// **'SOS'**
  String get addEventSosCta;

  /// SCR-FAT-053 observer banner
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — حفظ الأحداث للأب أو الأم الشريكة/الكاملة.'**
  String get addEventObserverHint;

  /// SCR-FAT-053 observer blocked toast
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — اطلب من الأب أو الأم الشريكة حفظ الأحداث'**
  String get addEventObserverBlocked;

  /// SCR-FAT-054 app bar title
  ///
  /// In ar, this message translates to:
  /// **'مهام العائلة'**
  String get familyTasksTitle;

  /// SCR-FAT-054 header subtitle
  ///
  /// In ar, this message translates to:
  /// **'المهام اليومية والحوافز المشجعة'**
  String get familyTasksSubtitle;

  /// SCR-FAT-054 CTA → FAT-055
  ///
  /// In ar, this message translates to:
  /// **'+ مهمة جديدة'**
  String get familyTasksNewTaskCta;

  /// SCR-FAT-054 pending card heading
  ///
  /// In ar, this message translates to:
  /// **'⏳ بانتظار اعتمادك الآن'**
  String get familyTasksPendingHeading;

  /// SCR-FAT-054 empty pending list
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مهام معلقة الآن — أحسنتم 👏'**
  String get familyTasksPendingEmpty;

  /// SCR-FAT-054 approve button
  ///
  /// In ar, this message translates to:
  /// **'✓ اعتماد (+{minutes} د)'**
  String familyTasksApproveCta(int minutes);

  /// SCR-FAT-054 approve success toast
  ///
  /// In ar, this message translates to:
  /// **'⏱ تم اعتماد مهمة {child} وأودعت +{minutes} دقيقة في محفظته!'**
  String familyTasksApproveToast(String child, int minutes);

  /// SCR-FAT-054 pending row title
  ///
  /// In ar, this message translates to:
  /// **'{child}: «{title}»'**
  String familyTasksPendingLine(String child, String title);

  /// SCR-FAT-054 mother help card (Rule 23 generic)
  ///
  /// In ar, this message translates to:
  /// **'🤝 طلبات مساعدة الأم'**
  String get familyTasksMotherHelpHeading;

  /// SCR-FAT-054 mother help row meta
  ///
  /// In ar, this message translates to:
  /// **'بلا دقائق — شراكة بيت 💗 · {time}'**
  String familyTasksMotherHelpMeta(String time);

  /// SCR-FAT-054 mother help open tag
  ///
  /// In ar, this message translates to:
  /// **'مفتوحة'**
  String get familyTasksMotherStatusOpen;

  /// SCR-FAT-054 mother help done tag
  ///
  /// In ar, this message translates to:
  /// **'أُنجزت 🌟'**
  String get familyTasksMotherStatusDone;

  /// SCR-FAT-054 active tasks card heading
  ///
  /// In ar, this message translates to:
  /// **'المهام الجارية للأبناء'**
  String get familyTasksActiveHeading;

  /// SCR-FAT-054 active row title
  ///
  /// In ar, this message translates to:
  /// **'{title} ({child})'**
  String familyTasksActiveLine(String title, String child);

  /// SCR-FAT-054 active row reward line (minutes only)
  ///
  /// In ar, this message translates to:
  /// **'المكافأة: +{minutes} دقيقة لمحفظته — بقرارك'**
  String familyTasksRewardMeta(int minutes);

  /// SCR-FAT-054 status tag — completed
  ///
  /// In ar, this message translates to:
  /// **'مكتملة'**
  String get familyTasksStatusCompleted;

  /// SCR-FAT-054 status tag — pending
  ///
  /// In ar, this message translates to:
  /// **'قيد المراجعة'**
  String get familyTasksStatusPendingApproval;

  /// SCR-FAT-054 status tag — assigned
  ///
  /// In ar, this message translates to:
  /// **'جارية'**
  String get familyTasksStatusAssigned;

  /// SCR-FAT-054 Rule 23 child label
  ///
  /// In ar, this message translates to:
  /// **'الابن الأول'**
  String get familyTasksChildOne;

  /// SCR-FAT-054 Rule 23 child label
  ///
  /// In ar, this message translates to:
  /// **'الابن الثاني'**
  String get familyTasksChildTwo;

  /// SCR-FAT-054 Rule 23 child label
  ///
  /// In ar, this message translates to:
  /// **'الابن الثالث'**
  String get familyTasksChildThree;

  /// SCR-FAT-054 task title (Rule 23)
  ///
  /// In ar, this message translates to:
  /// **'ترتيب الغرفة والسرير'**
  String get familyTasksTaskTidyRoom;

  /// SCR-FAT-054 task title (Rule 23)
  ///
  /// In ar, this message translates to:
  /// **'غسيل الصحون بعد العشاء'**
  String get familyTasksTaskWashDishes;

  /// SCR-FAT-054 task title (Rule 23)
  ///
  /// In ar, this message translates to:
  /// **'مذاكرة الرياضيات وحل التمرين'**
  String get familyTasksTaskMathStudy;

  /// SCR-FAT-054 mother help title (Rule 23)
  ///
  /// In ar, this message translates to:
  /// **'مراجعة قائمة العودة للمدارس'**
  String get familyTasksTaskSchoolReturnList;

  /// SCR-FAT-054 proof line
  ///
  /// In ar, this message translates to:
  /// **'📸 تم إرفاق صورة للغرفة مرتبة'**
  String get familyTasksProofPhotoAttached;

  /// SCR-FAT-054 time line
  ///
  /// In ar, this message translates to:
  /// **'قبل ١٠ دقائق'**
  String get familyTasksTimeTenMinAgo;

  /// SCR-FAT-054 time line
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get familyTasksTimeToday;

  /// SCR-FAT-054 time line
  ///
  /// In ar, this message translates to:
  /// **'أمس'**
  String get familyTasksTimeYesterday;

  /// SCR-FAT-054 empty title
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد أفراد عائلة بعد'**
  String get familyTasksEmptyTitle;

  /// SCR-FAT-054 empty message
  ///
  /// In ar, this message translates to:
  /// **'أضف ابناً أولاً — ثم يمكن إدارة مهام العائلة والمكافآت هنا.'**
  String get familyTasksEmptyMessage;

  /// SCR-FAT-054 empty CTA → FAT-003
  ///
  /// In ar, this message translates to:
  /// **'إضافة ابن'**
  String get familyTasksEmptyCta;

  /// SCR-FAT-054 loading semantics
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل مهام العائلة'**
  String get familyTasksLoadingSemantics;

  /// SCR-FAT-054 child lean title
  ///
  /// In ar, this message translates to:
  /// **'مهام العائلة للوالدين'**
  String get familyTasksChildLeanTitle;

  /// SCR-FAT-054 child lean message
  ///
  /// In ar, this message translates to:
  /// **'إدارة مهام العائلة والمكافآت تتم من جهاز الوالد. زر SOS متاح دائماً.'**
  String get familyTasksChildLeanMessage;

  /// SCR-FAT-054 child lean SOS CTA
  ///
  /// In ar, this message translates to:
  /// **'SOS'**
  String get familyTasksSosCta;

  /// SCR-FAT-054 observer banner
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — اعتماد المهام وإنشاء مهام جديدة للأب أو الأم الشريكة/الكاملة.'**
  String get familyTasksObserverHint;

  /// SCR-FAT-054 observer blocked toast
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — اطلب من الأب أو الأم الشريكة إدارة المهام'**
  String get familyTasksObserverBlocked;

  /// SCR-FAT-055 screen title
  ///
  /// In ar, this message translates to:
  /// **'مهمة جديدة'**
  String get createTaskTitle;

  /// SCR-FAT-055 task title label
  ///
  /// In ar, this message translates to:
  /// **'عنوان المهمة'**
  String get createTaskTaskTitleLabel;

  /// SCR-FAT-055 task title hint
  ///
  /// In ar, this message translates to:
  /// **'مثال: رتّب غرفتك قبل المغرب'**
  String get createTaskTaskTitleHint;

  /// SCR-FAT-055 assignee label
  ///
  /// In ar, this message translates to:
  /// **'تُسند إلى'**
  String get createTaskAssigneeLabel;

  /// SCR-FAT-055 assignee child one
  ///
  /// In ar, this message translates to:
  /// **'الابن الأول 🦁'**
  String get createTaskAssigneeChildOne;

  /// SCR-FAT-055 assignee child two
  ///
  /// In ar, this message translates to:
  /// **'الابن الثاني 🐱'**
  String get createTaskAssigneeChildTwo;

  /// SCR-FAT-055 assignee child three
  ///
  /// In ar, this message translates to:
  /// **'الابن الثالث 🐼'**
  String get createTaskAssigneeChildThree;

  /// SCR-FAT-055 assignee mother
  ///
  /// In ar, this message translates to:
  /// **'الأم 🌸'**
  String get createTaskAssigneeMother;

  /// SCR-FAT-055 mother help banner (no minutes)
  ///
  /// In ar, this message translates to:
  /// **'تتحول إلى طلب مساعدة للأم — بدون مكافأة دقائق لعب.'**
  String get createTaskMotherHelpBanner;

  /// SCR-FAT-055 reward card title
  ///
  /// In ar, this message translates to:
  /// **'المكافأة (دقائق فقط)'**
  String get createTaskRewardTitle;

  /// SCR-FAT-055 courage minutes label
  ///
  /// In ar, this message translates to:
  /// **'دقائق الشجاعة'**
  String get createTaskCourageLabel;

  /// SCR-FAT-055 playtime label
  ///
  /// In ar, this message translates to:
  /// **'وقت لعب إضافي'**
  String get createTaskPlaytimeLabel;

  /// SCR-FAT-055 minute chip label
  ///
  /// In ar, this message translates to:
  /// **'{minutes} دقيقة'**
  String createTaskMinutesLabel(int minutes);

  /// SCR-FAT-055 submit CTA → FAT-054
  ///
  /// In ar, this message translates to:
  /// **'إنشاء المهمة →'**
  String get createTaskSubmitCta;

  /// SCR-FAT-055 empty title toast
  ///
  /// In ar, this message translates to:
  /// **'أدخل عنوان المهمة أولاً'**
  String get createTaskTitleEmptyToast;

  /// SCR-FAT-055 submit success toast
  ///
  /// In ar, this message translates to:
  /// **'✓ أُسندت «{title}» إلى {who}'**
  String createTaskSubmittedToast(String title, String who);

  /// SCR-FAT-055 empty title
  ///
  /// In ar, this message translates to:
  /// **'لا أفراد في العائلة بعد'**
  String get createTaskEmptyTitle;

  /// SCR-FAT-055 empty message
  ///
  /// In ar, this message translates to:
  /// **'أضف ابناً أولاً — ثم يمكن إنشاء مهام عائلية بمكافآت هنا.'**
  String get createTaskEmptyMessage;

  /// SCR-FAT-055 empty CTA → FAT-003
  ///
  /// In ar, this message translates to:
  /// **'إضافة ابن'**
  String get createTaskEmptyCta;

  /// SCR-FAT-055 loading semantics
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل نموذج إنشاء مهمة'**
  String get createTaskLoadingSemantics;

  /// SCR-FAT-055 child lean title
  ///
  /// In ar, this message translates to:
  /// **'المهام العائلية للوالدين'**
  String get createTaskChildLeanTitle;

  /// SCR-FAT-055 child lean message
  ///
  /// In ar, this message translates to:
  /// **'إنشاء المهام العائلية يتم من جهاز الوالد. زر SOS متاح دائماً.'**
  String get createTaskChildLeanMessage;

  /// SCR-FAT-055 child lean SOS CTA
  ///
  /// In ar, this message translates to:
  /// **'SOS'**
  String get createTaskSosCta;

  /// SCR-FAT-055 observer banner
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — إنشاء المهام للأب أو الأم الشريكة/الكاملة.'**
  String get createTaskObserverHint;

  /// SCR-FAT-055 observer blocked toast
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — اطلب من الأب أو الأم الشريكة إنشاء المهام'**
  String get createTaskObserverBlocked;

  /// SCR-FAT-060 screen title
  ///
  /// In ar, this message translates to:
  /// **'سجل التدقيق'**
  String get auditLogTitle;

  /// SCR-FAT-060 R10 append-only banner
  ///
  /// In ar, this message translates to:
  /// **'📜 يُضاف ولا يُعدل ولا يُحذف — أبدًا. حياديته حمايتك.'**
  String get auditLogAppendBanner;

  /// SCR-FAT-060 empty title
  ///
  /// In ar, this message translates to:
  /// **'لا إدخالات تدقيق بعد'**
  String get auditLogEmptyTitle;

  /// SCR-FAT-060 empty message
  ///
  /// In ar, this message translates to:
  /// **'ستظهر هنا الأفعال العائلية المهمة كسجل إضافة فقط. لا يمكن حذف شيء من هذه الشاشة.'**
  String get auditLogEmptyMessage;

  /// SCR-FAT-060 loading semantics
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل سجل التدقيق'**
  String get auditLogLoadingSemantics;

  /// SCR-FAT-060 child lean title
  ///
  /// In ar, this message translates to:
  /// **'سجل التدقيق للوالدين'**
  String get auditLogChildLeanTitle;

  /// SCR-FAT-060 child lean message
  ///
  /// In ar, this message translates to:
  /// **'سجل التدقيق الأمني يُدار من جهاز الوالد. زر SOS متاح دائماً.'**
  String get auditLogChildLeanMessage;

  /// SCR-FAT-060 child lean SOS CTA
  ///
  /// In ar, this message translates to:
  /// **'SOS'**
  String get auditLogSosCta;

  /// SCR-FAT-060 observer banner
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — سجل التدقيق لا يُغيَّر في أي مستوى صلاحية.'**
  String get auditLogObserverHint;

  /// SCR-FAT-060 Rule 23 subject
  ///
  /// In ar, this message translates to:
  /// **'الابن الأول'**
  String get auditLogSubjectChildOne;

  /// SCR-FAT-060 Rule 23 subject
  ///
  /// In ar, this message translates to:
  /// **'الابن الثاني'**
  String get auditLogSubjectChildTwo;

  /// SCR-FAT-060 Rule 23 subject
  ///
  /// In ar, this message translates to:
  /// **'الابن الثالث'**
  String get auditLogSubjectChildThree;

  /// SCR-FAT-060 Rule 23 subject
  ///
  /// In ar, this message translates to:
  /// **'الأم'**
  String get auditLogSubjectMother;

  /// SCR-FAT-060 actor identity
  ///
  /// In ar, this message translates to:
  /// **'بواسطة الأب'**
  String get auditLogActorFather;

  /// SCR-FAT-060 actor identity
  ///
  /// In ar, this message translates to:
  /// **'بواسطة الأم'**
  String get auditLogActorMother;

  /// SCR-FAT-060 actor identity
  ///
  /// In ar, this message translates to:
  /// **'النظام'**
  String get auditLogActorSystem;

  /// SCR-FAT-060 actor identity
  ///
  /// In ar, this message translates to:
  /// **'جهاز {who}'**
  String auditLogActorChildDevice(String who);

  /// SCR-FAT-060 when stamp
  ///
  /// In ar, this message translates to:
  /// **'{date} · {time}'**
  String auditLogWhenStamp(String date, String time);

  /// SCR-FAT-060 SOS row title
  ///
  /// In ar, this message translates to:
  /// **'بلاغ استغاثة — {who}'**
  String auditLogEntrySosTitle(String who);

  /// SCR-FAT-060 level change title
  ///
  /// In ar, this message translates to:
  /// **'ترقية الأم: مطلعة ← مشاركة'**
  String get auditLogEntryMotherLevelTitle;

  /// SCR-FAT-060 unlock attempt title
  ///
  /// In ar, this message translates to:
  /// **'محاولة فتح وضع الوالد ×٢'**
  String get auditLogEntryUnlockTitle;

  /// SCR-FAT-060 forget title
  ///
  /// In ar, this message translates to:
  /// **'استخدام زر النسيان'**
  String get auditLogEntryForgetTitle;

  /// SCR-FAT-060 consent title
  ///
  /// In ar, this message translates to:
  /// **'موافقة ولي الأمر — ربط جهاز {who}'**
  String auditLogEntryConsentTitle(String who);

  /// SCR-FAT-060 detail
  ///
  /// In ar, this message translates to:
  /// **'أُغلق يدويًا بعد ٦ د'**
  String get auditLogDetailClosedAfter6m;

  /// SCR-FAT-060 detail
  ///
  /// In ar, this message translates to:
  /// **'أُخطرت'**
  String get auditLogDetailObserverToPartner;

  /// SCR-FAT-060 detail
  ///
  /// In ar, this message translates to:
  /// **'رُفضت'**
  String get auditLogDetailRejectedX2;

  /// SCR-FAT-060 detail
  ///
  /// In ar, this message translates to:
  /// **'الجمعة'**
  String get auditLogDetailFriday;

  /// SCR-FAT-060 detail
  ///
  /// In ar, this message translates to:
  /// **'بطابع زمني'**
  String get auditLogDetailTimestamped;

  /// SCR-FAT-060 detail
  ///
  /// In ar, this message translates to:
  /// **'أُخطرت'**
  String get auditLogDetailNotified;

  /// SCR-FAT-061 screen title
  ///
  /// In ar, this message translates to:
  /// **'اللغة والمساعدة'**
  String get languageHelpTitle;

  /// SCR-FAT-061 language card heading
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get languageHelpLanguageSection;

  /// SCR-FAT-061 Arabic row title
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get languageHelpArabic;

  /// SCR-FAT-061 Arabic row subtitle
  ///
  /// In ar, this message translates to:
  /// **'RTL أصيل'**
  String get languageHelpArabicSubtitle;

  /// SCR-FAT-061 current locale tag
  ///
  /// In ar, this message translates to:
  /// **'الحالية'**
  String get languageHelpCurrentTag;

  /// SCR-FAT-061 English row title
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get languageHelpEnglish;

  /// SCR-FAT-061 English choose action
  ///
  /// In ar, this message translates to:
  /// **'اختيار'**
  String get languageHelpChooseAction;

  /// SCR-FAT-061 Stage-1 locale switch toast
  ///
  /// In ar, this message translates to:
  /// **'واجهة English — قريبًا في تحديث لاحق'**
  String get languageHelpLocaleToast;

  /// SCR-FAT-061 help center card heading
  ///
  /// In ar, this message translates to:
  /// **'مركز المساعدة'**
  String get languageHelpHelpCenterSection;

  /// SCR-FAT-061 help row → FAT-026
  ///
  /// In ar, this message translates to:
  /// **'جهاز ابني ينقطع؟'**
  String get languageHelpDeviceDisconnectTitle;

  /// SCR-FAT-061 device help subtitle
  ///
  /// In ar, this message translates to:
  /// **'الأشهر — دليل لكل جهاز'**
  String get languageHelpDeviceDisconnectSubtitle;

  /// SCR-FAT-061 help row → FAT-030
  ///
  /// In ar, this message translates to:
  /// **'كيف أفتح وضع الوالد؟'**
  String get languageHelpParentModeTitle;

  /// SCR-FAT-061 support CTA
  ///
  /// In ar, this message translates to:
  /// **'تواصل مع الدعم'**
  String get languageHelpSupportCta;

  /// SCR-FAT-061 Stage-1 support toast
  ///
  /// In ar, this message translates to:
  /// **'محادثة الدعم بالعربية — الرد خلال ساعات العمل'**
  String get languageHelpSupportToast;

  /// SCR-FAT-061 empty title
  ///
  /// In ar, this message translates to:
  /// **'أكمل إعداد العائلة أولًا'**
  String get languageHelpEmptyTitle;

  /// SCR-FAT-061 empty message
  ///
  /// In ar, this message translates to:
  /// **'أضف ابنًا لتفعيل إعدادات اللغة ومركز المساعدة.'**
  String get languageHelpEmptyMessage;

  /// SCR-FAT-061 empty CTA → FAT-003
  ///
  /// In ar, this message translates to:
  /// **'أضف ابنًا'**
  String get languageHelpEmptyCta;

  /// SCR-FAT-061 loading semantics
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل اللغة والمساعدة'**
  String get languageHelpLoadingSemantics;

  /// SCR-FAT-061 child lean title
  ///
  /// In ar, this message translates to:
  /// **'اللغة والمساعدة للوالدين'**
  String get languageHelpChildLeanTitle;

  /// SCR-FAT-061 child lean message
  ///
  /// In ar, this message translates to:
  /// **'إعدادات اللغة والمساعدة تُدار من جهاز الوالد. زر الطوارئ يبقى متاحًا.'**
  String get languageHelpChildLeanMessage;

  /// SCR-FAT-061 observer banner
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — تغيير اللغة والتواصل مع الدعم للأب أو أم شريكة/كاملة.'**
  String get languageHelpObserverHint;

  /// SCR-FAT-061 observer blocked toast
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — اطلب من الأب أو أم شريكة تغيير اللغة أو التواصل مع الدعم'**
  String get languageHelpObserverBlocked;

  /// SCR-FAT-061 child lean SOS CTA
  ///
  /// In ar, this message translates to:
  /// **'طوارئ'**
  String get languageHelpSosCta;

  /// SCR-FAT-063 screen title via nameKey
  ///
  /// In ar, this message translates to:
  /// **'خط {name} الزمني'**
  String individualTimelineTitle(String name);

  /// SCR-FAT-063 Rule 23 child label
  ///
  /// In ar, this message translates to:
  /// **'الابن الأول'**
  String get individualTimelineChildOne;

  /// SCR-FAT-063 Rule 23 child label
  ///
  /// In ar, this message translates to:
  /// **'الابن الثاني'**
  String get individualTimelineChildTwo;

  /// SCR-FAT-063 Rule 23 child label
  ///
  /// In ar, this message translates to:
  /// **'الابن الثالث'**
  String get individualTimelineChildThree;

  /// SCR-FAT-063 empty title
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد خط زمني بعد'**
  String get individualTimelineEmptyTitle;

  /// SCR-FAT-063 empty message
  ///
  /// In ar, this message translates to:
  /// **'أضف ابنًا لرؤية خطه الزمني الموحّد عبر الأمان والتعلّم والتواصل.'**
  String get individualTimelineEmptyMessage;

  /// SCR-FAT-063 empty CTA → FAT-003
  ///
  /// In ar, this message translates to:
  /// **'إضافة ابن'**
  String get individualTimelineEmptyCta;

  /// SCR-FAT-063 loading semantics
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل الخط الزمني'**
  String get individualTimelineLoadingSemantics;

  /// SCR-FAT-063 child lean title
  ///
  /// In ar, this message translates to:
  /// **'الخط الزمني للوالدين'**
  String get individualTimelineChildLeanTitle;

  /// SCR-FAT-063 child lean message
  ///
  /// In ar, this message translates to:
  /// **'يُعرض الخط الزمني على جهاز الوالد. زر SOS متاح دائمًا.'**
  String get individualTimelineChildLeanMessage;

  /// SCR-FAT-063 child lean SOS CTA
  ///
  /// In ar, this message translates to:
  /// **'SOS'**
  String get individualTimelineSosCta;

  /// SCR-FAT-063 observer banner
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — يمكنك قراءة الرؤى وخيط اليوم دون تنفيذ الاقتراحات.'**
  String get individualTimelineObserverHint;

  /// SCR-FAT-063 observer blocked toast
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — تنفيذ اقتراحات المستشار يتطلب مستوى شريك أو كاملة.'**
  String get individualTimelineObserverBlocked;

  /// SCR-FAT-063 insight badge
  ///
  /// In ar, this message translates to:
  /// **'الربط عبر المجالات'**
  String get individualTimelineInsightBadgeCrossDomain;

  /// SCR-FAT-063 pattern prefix
  ///
  /// In ar, this message translates to:
  /// **'نمط مكتشف: '**
  String get individualTimelinePatternLabel;

  /// SCR-FAT-063 prototype pattern
  ///
  /// In ar, this message translates to:
  /// **'أيام تمرين كرة القدم ← ينام أبكر ~٢٥ د ← نتائجه التعليمية صباح اليوم التالي أعلى ~١٥٪.'**
  String get individualTimelinePatternFootballSleepStudy;

  /// SCR-FAT-063 suggestion prefix
  ///
  /// In ar, this message translates to:
  /// **'اقتراح: '**
  String get individualTimelineSuggestionLabel;

  /// SCR-FAT-063 prototype suggestion
  ///
  /// In ar, this message translates to:
  /// **'اجعل الاختبارات المهمة صباح ما بعد التمرين.'**
  String get individualTimelineSuggestionTestsAfterPractice;

  /// SCR-FAT-063 privacy note
  ///
  /// In ar, this message translates to:
  /// **'لا منافس يرى الصورة الثلاثية: أمن + تعليم + تواصل معًا.'**
  String get individualTimelinePrivacyTriDomainUnique;

  /// SCR-FAT-063 insight CTA
  ///
  /// In ar, this message translates to:
  /// **'ناقش مع المستشار'**
  String get individualTimelineDiscussCta;

  /// SCR-FAT-063 discuss toast
  ///
  /// In ar, this message translates to:
  /// **'تمت إضافة الاقتراح لمساعد العائلة (محاكاة المرحلة ١).'**
  String get individualTimelineDiscussToast;

  /// SCR-FAT-063 today section
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get individualTimelineTodayHeading;

  /// SCR-FAT-063 timeline stop
  ///
  /// In ar, this message translates to:
  /// **'وضع المدرسة نشط'**
  String get individualTimelineStopSchoolModeActive;

  /// SCR-FAT-063 timeline stop
  ///
  /// In ar, this message translates to:
  /// **'أنهى مراجعة الكسور'**
  String get individualTimelineStopFinishedFractionsReview;

  /// SCR-FAT-063 timeline stop
  ///
  /// In ar, this message translates to:
  /// **'«أبي وصلت المدرسة»'**
  String get individualTimelineStopArrivedSchoolMessage;

  /// SCR-FAT-063 timeline stop
  ///
  /// In ar, this message translates to:
  /// **'نام ١١:١٠ م أمس'**
  String get individualTimelineStopLateSleep;

  /// SCR-FAT-063 time stamp
  ///
  /// In ar, this message translates to:
  /// **'منذ ٧:٠٠ ص'**
  String get individualTimelineTimeSince7am;

  /// SCR-FAT-063 time stamp
  ///
  /// In ar, this message translates to:
  /// **'٨:٤٠ ص'**
  String get individualTimelineTimeAt840am;

  /// SCR-FAT-063 time stamp
  ///
  /// In ar, this message translates to:
  /// **'٧:١٤ ص'**
  String get individualTimelineTimeAt714am;

  /// SCR-FAT-063 time stamp
  ///
  /// In ar, this message translates to:
  /// **'١١:١٠ م أمس'**
  String get individualTimelineTimeAt1110pmYesterday;

  /// SCR-FAT-063 stop detail
  ///
  /// In ar, this message translates to:
  /// **'٩٠٪'**
  String get individualTimelineDetailScore90;

  /// SCR-FAT-063 stop detail
  ///
  /// In ar, this message translates to:
  /// **'متأخر ٤٠ د عن أساسه'**
  String get individualTimelineDetailLate40minBaseline;

  /// SCR-FAT-062 app bar title
  ///
  /// In ar, this message translates to:
  /// **'أنماط العائلة'**
  String get familyPatternsTitle;

  /// SCR-FAT-062 advisor banner with always-visible confidence
  ///
  /// In ar, this message translates to:
  /// **'🧠 مستشار العائلة يتعلم إيقاع عائلتك ليكشف الخارج عنه — مؤشر ثقة معلن دائمًا: {percent}٪.'**
  String familyPatternsAdvisorBanner(int percent);

  /// SCR-FAT-062 Rule 23 nameKey childOne
  ///
  /// In ar, this message translates to:
  /// **'الابن الأول'**
  String get familyPatternsChildOne;

  /// SCR-FAT-062 Rule 23 nameKey childTwo
  ///
  /// In ar, this message translates to:
  /// **'الابن الثاني'**
  String get familyPatternsChildTwo;

  /// SCR-FAT-062 per-child confidence seal
  ///
  /// In ar, this message translates to:
  /// **'ثقة {percent}٪'**
  String familyPatternsConfidenceSeal(int percent);

  /// SCR-FAT-062 sleep anomaly row
  ///
  /// In ar, this message translates to:
  /// **'النوم تأخر ٤٠ د هذا الأسبوع'**
  String get familyPatternsSleepDelayTitle;

  /// SCR-FAT-062 sleep baseline subtitle
  ///
  /// In ar, this message translates to:
  /// **'عن خط أساسه ١٠:٣٠ م'**
  String get familyPatternsSleepBaselineSubtitle;

  /// SCR-FAT-062 communication ok row
  ///
  /// In ar, this message translates to:
  /// **'التواصل طبيعي ومستقر'**
  String get familyPatternsCommunicationStableTitle;

  /// SCR-FAT-062 education improve row
  ///
  /// In ar, this message translates to:
  /// **'تحسن تعليمي +١٢٪'**
  String get familyPatternsEducationImproveTitle;

  /// SCR-FAT-062 morning watch row
  ///
  /// In ar, this message translates to:
  /// **'نشاطها الصباحي انخفض ٣ أيام'**
  String get familyPatternsMorningActivityDropTitle;

  /// SCR-FAT-062 morning watch hint
  ///
  /// In ar, this message translates to:
  /// **'مبدئي — قد يكون إرهاقًا'**
  String get familyPatternsMorningActivityHint;

  /// SCR-FAT-062 anomaly tag
  ///
  /// In ar, this message translates to:
  /// **'شذوذ'**
  String get familyPatternsTagAnomaly;

  /// SCR-FAT-062 ok tag
  ///
  /// In ar, this message translates to:
  /// **'✓'**
  String get familyPatternsTagOk;

  /// SCR-FAT-062 watch tag
  ///
  /// In ar, this message translates to:
  /// **'راقب'**
  String get familyPatternsTagWatch;

  /// SCR-FAT-062 improve tag
  ///
  /// In ar, this message translates to:
  /// **'📈'**
  String get familyPatternsTagImprove;

  /// SCR-FAT-062 link → FAT-063
  ///
  /// In ar, this message translates to:
  /// **'الخط الزمني ‹'**
  String get familyPatternsTimelineLink;

  /// SCR-FAT-062 footer note
  ///
  /// In ar, this message translates to:
  /// **'خط الأساس يُبنى من ١٤ يومًا — ومستشار العائلة يقترح ولا يحكم'**
  String get familyPatternsFooterNote;

  /// SCR-FAT-062 empty title
  ///
  /// In ar, this message translates to:
  /// **'لا أنماط عائلية بعد'**
  String get familyPatternsEmptyTitle;

  /// SCR-FAT-062 empty message
  ///
  /// In ar, this message translates to:
  /// **'أضف ابنًا أولًا — ثم تظهر أنماط النوم والتواصل والتعليم هنا بعد نافذة خط الأساس.'**
  String get familyPatternsEmptyMessage;

  /// SCR-FAT-062 empty CTA → FAT-003
  ///
  /// In ar, this message translates to:
  /// **'إضافة ابن'**
  String get familyPatternsEmptyCta;

  /// SCR-FAT-062 loading semantics
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل أنماط العائلة'**
  String get familyPatternsLoadingSemantics;

  /// SCR-FAT-062 child lean title
  ///
  /// In ar, this message translates to:
  /// **'أنماط العائلة للوالدين'**
  String get familyPatternsChildLeanTitle;

  /// SCR-FAT-062 child lean message
  ///
  /// In ar, this message translates to:
  /// **'رؤى الأنماط تُدار من جهاز الوالد. زر SOS متاح دائمًا.'**
  String get familyPatternsChildLeanMessage;

  /// SCR-FAT-062 observer banner
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — الخط الزمني للفرد يفتح للأب أو للأم بمستوى مشاركة/كامل.'**
  String get familyPatternsObserverHint;

  /// SCR-FAT-062 observer timeline blocked toast
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط — اطلب من الأب أو الأم بمستوى مشاركة فتح الخط الزمني'**
  String get familyPatternsObserverBlocked;

  /// SCR-FAT-062 child lean SOS CTA
  ///
  /// In ar, this message translates to:
  /// **'SOS'**
  String get familyPatternsSosCta;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
