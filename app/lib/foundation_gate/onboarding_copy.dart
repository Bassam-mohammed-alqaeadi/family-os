import 'package:flutter/widgets.dart';

import 'package:family_os/foundation_gate/foundation_gate_models.dart';

/// Presentation copy for the real onboarding core (sign-in, sign-up, family
/// creation, first child). Arabic first; English mirrors it.
///
/// Every string here describes something the screen really does. There is no
/// copy for demo, trial, biometric or invite paths because those features are
/// not part of the admitted product yet.
class OnboardingCopy {
  const OnboardingCopy._(this.isArabic);

  factory OnboardingCopy.of(BuildContext context) => OnboardingCopy._(
    Localizations.localeOf(context).languageCode.toLowerCase() == 'ar',
  );

  final bool isArabic;

  // ── Shared form validation ──
  String get emailRequired =>
      isArabic ? 'أدخل بريدك الإلكتروني.' : 'Enter your e-mail address.';
  String get emailInvalid => isArabic
      ? 'صيغة البريد غير صحيحة — مثال: name@example.com'
      : 'That does not look like an e-mail — e.g. name@example.com';
  String get passwordRequired =>
      isArabic ? 'أدخل كلمة المرور.' : 'Enter your password.';
  String get passwordTooShort => isArabic
      ? 'كلمة المرور يجب أن تكون 8 أحرف على الأقل.'
      : 'The password must be at least 8 characters.';
  String get passwordNeedsLetterAndDigit => isArabic
      ? 'استخدم حرفًا ورقمًا واحدًا على الأقل.'
      : 'Use at least one letter and one digit.';
  String get confirmRequired =>
      isArabic ? 'أعد كتابة كلمة المرور.' : 'Re-enter the password.';
  String get confirmMismatch =>
      isArabic ? 'كلمتا المرور غير متطابقتين.' : 'The passwords do not match.';
  String get termsRequired => isArabic
      ? 'يلزم الموافقة على الشروط للمتابعة.'
      : 'You need to accept the terms to continue.';
  String get fixErrorsAbove => isArabic
      ? 'راجع الحقول المحددة بالأحمر.'
      : 'Check the fields marked in red.';
  String get hidePassword => isArabic ? 'إخفاء كلمة المرور' : 'Hide password';
  String get showPassword => isArabic ? 'إظهار كلمة المرور' : 'Show password';
  String get pleaseWait => isArabic ? 'لحظة من فضلك…' : 'One moment…';
  String get notConfiguredTitle =>
      isArabic ? 'هذا البناء غير متصل بالخادم' : 'This build has no server';
  String get notConfiguredMessage => isArabic
      ? 'شغّل التطبيق مع FAMILY_OS_API_ORIGIN وإعدادات Firebase حتى يعمل تسجيل الدخول الحقيقي.'
      : 'Run the app with FAMILY_OS_API_ORIGIN and Firebase options to enable real sign-in.';

  // ── Sign-in (SCR-SHR-003) ──
  String get signInTitle => isArabic ? 'مرحبًا بعودتك' : 'Welcome back';
  String get signInSubtitle => isArabic
      ? 'سجّل الدخول لمتابعة عائلتك.'
      : 'Sign in to continue to your family.';
  String get signInEmailLabel => isArabic ? 'البريد الإلكتروني' : 'E-mail';
  String get signInPasswordLabel => isArabic ? 'كلمة المرور' : 'Password';
  String get signInSubmit => isArabic ? 'تسجيل الدخول' : 'Sign in';
  String get signingIn => isArabic ? 'جارٍ تسجيل الدخول…' : 'Signing in…';
  String get forgotPassword =>
      isArabic ? 'نسيت كلمة المرور؟' : 'Forgot your password?';
  String get noAccountPrompt =>
      isArabic ? 'ليس لديك حساب؟' : 'New to Family OS?';
  String get createAccountLink =>
      isArabic ? 'إنشاء حساب جديد' : 'Create an account';
  String get signedInNoFamilyHint => isArabic
      ? 'تم تسجيل الدخول. لنُنشئ عائلتك الآن.'
      : 'Signed in. Let us set up your family.';
  String get signedInDiscoveryFailedTitle => isArabic
      ? 'تم تسجيل الدخول، لكن تعذر الوصول إلى خادم العائلة'
      : 'Signed in, but the family server is unreachable';
  String get signedInDiscoveryFailedMessage => isArabic
      ? 'تحقق من الاتصال ثم اضغط «إعادة المحاولة».'
      : 'Check your connection, then tap “Try again”.';
  String get tryAgain => isArabic ? 'إعادة المحاولة' : 'Try again';

  // ── Password reset sheet ──
  String get resetTitle =>
      isArabic ? 'إعادة تعيين كلمة المرور' : 'Reset your password';
  String get resetMessage => isArabic
      ? 'سنرسل رابط إعادة التعيين إلى بريدك. افتح الرابط ثم عد وسجّل الدخول بكلمة المرور الجديدة.'
      : 'We will e-mail you a reset link. Open it, choose a new password, then come back and sign in.';
  String get resetSend => isArabic ? 'إرسال الرابط' : 'Send link';
  String get resetSending => isArabic ? 'جارٍ الإرسال…' : 'Sending…';
  String get resetSentTitle => isArabic ? 'تحقق من بريدك' : 'Check your inbox';
  String resetSentMessage(String email) => isArabic
      ? 'إن كان هناك حساب مرتبط بـ $email فستصلك رسالة خلال دقائق. لا تنسَ مجلد الرسائل غير المرغوبة.'
      : 'If an account exists for $email, a message is on its way. Check your spam folder too.';
  String get resetDone => isArabic ? 'حسنًا' : 'Done';
  String get cancel => isArabic ? 'إلغاء' : 'Cancel';

  // ── Sign-up (SCR-SHR-002) ──
  String get signUpTitle => isArabic ? 'إنشاء حساب' : 'Create your account';
  String get signUpSubtitle => isArabic
      ? 'حساب واحد لولي الأمر — البريد وكلمة المرور يكفيان.'
      : 'One guardian account — e-mail and password are all you need.';
  String get signUpConfirmLabel =>
      isArabic ? 'تأكيد كلمة المرور' : 'Confirm password';
  String get signUpSubmit => isArabic ? 'إنشاء الحساب' : 'Create account';
  String get creatingAccount =>
      isArabic ? 'جارٍ إنشاء الحساب…' : 'Creating your account…';
  String get termsLabel => isArabic
      ? 'أوافق على شروط الاستخدام وسياسة الخصوصية. لا إعلانات ولا بيع بيانات.'
      : 'I agree to the Terms of Use and Privacy Policy. No ads, no data sale.';
  String get haveAccountPrompt =>
      isArabic ? 'لديك حساب بالفعل؟' : 'Already have an account?';
  String get signInLink => isArabic ? 'تسجيل الدخول' : 'Sign in';
  String get emailInUseTitle => isArabic
      ? 'هذا البريد مسجّل مسبقًا'
      : 'This e-mail already has an account';
  String get emailInUseMessage => isArabic
      ? 'يبدو أنك أنشأت حسابًا من قبل. سجّل الدخول بنفس البريد، أو استخدم «نسيت كلمة المرور» إن لم تتذكرها.'
      : 'Looks like you signed up before. Sign in with the same e-mail, or use “Forgot your password” if you cannot remember it.';
  String get emailInUseAction =>
      isArabic ? 'تسجيل الدخول بهذا البريد' : 'Sign in with this e-mail';
  String get strengthWeak => isArabic ? 'ضعيفة' : 'Weak';
  String get strengthFair => isArabic ? 'مقبولة' : 'Fair';
  String get strengthGood => isArabic ? 'جيدة' : 'Good';
  String get strengthStrong => isArabic ? 'قوية' : 'Strong';
  String get strengthHint => isArabic
      ? '8 أحرف على الأقل، ويفضَّل خلط الحروف والأرقام والرموز.'
      : 'At least 8 characters; mixing letters, digits and symbols helps.';

  // ── Create family (SCR-FAT-001) ──
  String get familyTitle => isArabic ? 'أنشئ عائلتك' : 'Create your family';
  String get familySubtitle => isArabic
      ? 'العائلة هي المساحة التي تجمع أطفالك وأجهزتهم. أنت مالكها وتتحكم بمن ينضم إليها.'
      : 'A family is the space that holds your children and their devices. You own it and decide who joins.';
  String get familyNameLabel => isArabic ? 'اسم العائلة' : 'Family name';
  String get familyNameHint =>
      isArabic ? 'مثال: عائلة أحمد' : 'e.g. The Ahmed family';
  String get familyNameRequired =>
      isArabic ? 'أدخل اسمًا للعائلة.' : 'Enter a family name.';
  String get familyNameTooLong => isArabic
      ? 'الاسم طويل جدًا (الحد 120 حرفًا).'
      : 'The name is too long (120 characters max).';
  String get familySubmit => isArabic ? 'إنشاء العائلة' : 'Create family';
  String get creatingFamily =>
      isArabic ? 'جارٍ إنشاء العائلة…' : 'Creating the family…';
  String get familyWhatNextTitle =>
      isArabic ? 'ماذا بعد الإنشاء؟' : 'What happens next?';
  String get familyWhatNext1 => isArabic
      ? 'تضيف أول طفل (اسم وعمر فقط).'
      : 'You add your first child (name and age only).';
  String get familyWhatNext2 => isArabic
      ? 'تربط جهاز الطفل عبر رمز QR يُصدره الخادم.'
      : 'You pair the child’s phone with a server-issued QR code.';
  String get familyWhatNext3 => isArabic
      ? 'يمكنك تغيير الاسم لاحقًا من الإعدادات.'
      : 'You can rename the family later in Settings.';

  // ── Add child (SCR-FAT-003) ──
  String get childTitle => isArabic ? 'أضف طفلك' : 'Add your child';
  String get childSubtitle => isArabic
      ? 'نحتاج الاسم والعمر فقط. الشخصية واللون لتمييز الطفل داخل التطبيق.'
      : 'Only the name and age are required. The character and colour tell children apart in the app.';
  String get childNameLabel => isArabic ? 'اسم الطفل' : 'Child’s name';
  String get childNameHint => isArabic ? 'الاسم الأول' : 'First name';
  String get childNameRequired =>
      isArabic ? 'أدخل اسم الطفل.' : 'Enter the child’s name.';
  String get childNameTooLong => isArabic
      ? 'الاسم طويل جدًا (الحد 120 حرفًا).'
      : 'The name is too long (120 characters max).';
  String get childAgeLabel => isArabic ? 'العمر' : 'Age';
  String get childCharacterLabel => isArabic ? 'الشخصية' : 'Character';
  String get childColorLabel => isArabic ? 'اللون' : 'Colour';
  String get childSubmit =>
      isArabic ? 'حفظ والمتابعة إلى الربط' : 'Save and continue to pairing';
  String get savingChild => isArabic ? 'جارٍ الحفظ…' : 'Saving…';
  String get childSavedToServer => isArabic
      ? 'يُحفظ الملف على خادم العائلة ويحصل على معرّف ثابت.'
      : 'The profile is stored on the family server and receives a permanent ID.';
  String get childNoFamilyTitle =>
      isArabic ? 'لا توجد عائلة نشطة' : 'No active family';
  String get childNoFamilyMessage => isArabic
      ? 'أنشئ العائلة أولًا ثم أضف الطفل.'
      : 'Create the family first, then add the child.';
  String get childGoCreateFamily =>
      isArabic ? 'إنشاء العائلة' : 'Create the family';

  String childCreateFailureTitle(
    FamilyChildProfileCreateFailurePresentation f,
  ) => switch (f) {
    FamilyChildProfileCreateFailurePresentation.invalidInput =>
      isArabic ? 'بيانات غير مقبولة' : 'The details were rejected',
    FamilyChildProfileCreateFailurePresentation.conflict =>
      isArabic ? 'يوجد طفل بهذه البيانات' : 'This child already exists',
    FamilyChildProfileCreateFailurePresentation.accessDenied =>
      isArabic ? 'غير مسموح' : 'Not allowed',
    FamilyChildProfileCreateFailurePresentation.sessionInvalid =>
      isArabic ? 'انتهت الجلسة' : 'Session expired',
    FamilyChildProfileCreateFailurePresentation.network =>
      isArabic ? 'تعذر الاتصال بالخادم' : 'Could not reach the server',
    FamilyChildProfileCreateFailurePresentation.unavailable =>
      isArabic ? 'الخدمة غير متاحة الآن' : 'Service unavailable',
  };

  String childCreateFailureMessage(
    FamilyChildProfileCreateFailurePresentation f,
  ) => switch (f) {
    FamilyChildProfileCreateFailurePresentation.invalidInput =>
      isArabic
          ? 'راجع الاسم والعمر ثم حاول مرة أخرى.'
          : 'Check the name and age, then try again.',
    FamilyChildProfileCreateFailurePresentation.conflict =>
      isArabic
          ? 'ربما أُضيف الطفل بالفعل. ارجع إلى قائمة الأطفال للتأكد.'
          : 'The child may already have been added. Check the children list.',
    FamilyChildProfileCreateFailurePresentation.accessDenied =>
      isArabic
          ? 'هذا الحساب لا يملك صلاحية إضافة أطفال لهذه العائلة.'
          : 'This account may not add children to this family.',
    FamilyChildProfileCreateFailurePresentation.sessionInvalid =>
      isArabic
          ? 'سجّل الدخول مرة أخرى ثم أعد المحاولة.'
          : 'Sign in again, then retry.',
    FamilyChildProfileCreateFailurePresentation.network =>
      isArabic
          ? 'تحقق من الاتصال ثم اضغط «إعادة المحاولة». لن يُنشأ الطفل مرتين.'
          : 'Check your connection and tap “Try again”. The child will not be created twice.',
    FamilyChildProfileCreateFailurePresentation.unavailable =>
      isArabic
          ? 'الخادم مشغول أو غير مهيأ. حاول بعد قليل.'
          : 'The server is busy or not configured. Try again shortly.',
  };

  String ageYears(int age) => isArabic ? '$age سنة' : '$age years';
  String colorSwatch(int index) =>
      isArabic ? 'اللون رقم $index' : 'Colour $index';

  // ── Identity failures (shared with foundation copy; kept here so the
  //    onboarding screens have one import) ──
  String identityFailure(
    FoundationGateIdentityFailure? failure,
  ) => switch (failure) {
    FoundationGateIdentityFailure.invalidCredentials =>
      isArabic
          ? 'البريد الإلكتروني أو كلمة المرور غير صحيحة.'
          : 'The e-mail or password is incorrect.',
    FoundationGateIdentityFailure.emailAlreadyInUse => emailInUseMessage,
    FoundationGateIdentityFailure.weakPassword =>
      isArabic
          ? 'كلمة المرور ضعيفة. استخدم 8 أحرف على الأقل مع حروف وأرقام.'
          : 'The password is too weak. Use at least 8 characters with letters and digits.',
    FoundationGateIdentityFailure.invalidEmail => emailInvalid,
    FoundationGateIdentityFailure.networkUnavailable =>
      isArabic
          ? 'تعذر الوصول إلى خدمة الحساب. تحقق من الاتصال ثم أعد المحاولة.'
          : 'The account service could not be reached. Check your connection and try again.',
    FoundationGateIdentityFailure.tooManyAttempts =>
      isArabic
          ? 'محاولات كثيرة. انتظر قليلًا ثم أعد المحاولة.'
          : 'Too many attempts. Wait a moment and try again.',
    FoundationGateIdentityFailure.accountDisabled =>
      isArabic
          ? 'هذا الحساب معطّل. تواصل مع الدعم.'
          : 'This account is disabled. Contact support.',
    FoundationGateIdentityFailure.noSession =>
      isArabic
          ? 'انتهت الجلسة. سجّل الدخول مرة أخرى.'
          : 'Your session ended. Sign in again.',
    FoundationGateIdentityFailure.unknown || null =>
      isArabic
          ? 'حدث خطأ غير متوقع. حاول مرة أخرى.'
          : 'Something went wrong. Please try again.',
  };
}

/// Presentation buckets for child-profile creation failures.
enum FamilyChildProfileCreateFailurePresentation {
  invalidInput,
  conflict,
  accessDenied,
  sessionInvalid,
  network,
  unavailable,
}
