import 'package:flutter/widgets.dart';

import 'foundation_gate_models.dart';

/// Copy for the isolated, synthetic Foundation Gate.
///
/// This keeps the same words and state grammar across its sign-in, family
/// selection and Children Control Centre surfaces without importing the legacy
/// mock-first application localization composition root.
class FoundationGateCopy {
  const FoundationGateCopy._(this.isArabic);

  factory FoundationGateCopy.of(BuildContext context) {
    return FoundationGateCopy._(
      Localizations.localeOf(context).languageCode.toLowerCase() == 'ar',
    );
  }

  final bool isArabic;

  String get appTitle => isArabic ? 'بوابة العائلة' : 'Family Gate';
  String get unconfigured => isArabic
      ? 'بوابة الأساس غير مهيأة.'
      : 'Foundation Gate is not configured.';
  String get signingIn =>
      isArabic ? 'جارٍ التحقق من الوصول…' : 'Checking access…';
  String get loadingRoster => isArabic
      ? 'جارٍ تحميل سجل الأطفال من الخادم…'
      : 'Loading the server roster…';
  String get signInTitle =>
      isArabic ? 'تسجيل دخول تجريبي' : 'Synthetic sign-in';
  String get syntheticOnly => isArabic
      ? 'هذا المسار مخصص لبيئة الاختبار الاصطناعية فقط.'
      : 'This flow is available only in the synthetic staging environment.';
  String get syntheticEmail => isArabic ? 'البريد التجريبي' : 'Synthetic email';
  String get syntheticPassword =>
      isArabic ? 'كلمة المرور التجريبية' : 'Synthetic password';
  String get signInFailure =>
      isArabic ? 'تعذر تسجيل الدخول.' : 'Sign-in is unavailable.';
  String get createAccountFailed => isArabic
      ? 'حدث خطأ أثناء إنشاء الحساب. تأكد من صحة البيانات أو حاول مرة أخرى.'
      : 'Account creation failed. Check the details or try again.';
  String get alreadyHaveAccountSignIn => isArabic
      ? 'لديك حساب بالفعل؟ تسجيل الدخول'
      : 'Already have an account? Sign in';

  // ── Identity-provider outcomes (presentation-safe; never provider text) ──
  String get identityInvalidCredentials => isArabic
      ? 'البريد الإلكتروني أو كلمة المرور غير صحيحة.'
      : 'The e-mail or password is incorrect.';
  String get identityEmailAlreadyInUse => isArabic
      ? 'هذا البريد مسجّل مسبقًا. سجّل الدخول بدلًا من ذلك.'
      : 'This e-mail already has an account. Sign in instead.';
  String get identityWeakPassword => isArabic
      ? 'كلمة المرور ضعيفة. استخدم 8 أحرف على الأقل مع أرقام وحروف.'
      : 'The password is too weak. Use at least 8 characters with letters and numbers.';
  String get identityInvalidEmail => isArabic
      ? 'صيغة البريد الإلكتروني غير صحيحة.'
      : 'The e-mail address format is not valid.';
  String get identityNetworkUnavailable => isArabic
      ? 'تعذر الوصول إلى خدمة الحساب. تحقق من الاتصال ثم أعد المحاولة.'
      : 'The account service could not be reached. Check your connection and try again.';
  String get identityTooManyAttempts => isArabic
      ? 'محاولات كثيرة. انتظر قليلًا ثم أعد المحاولة.'
      : 'Too many attempts. Wait a moment and try again.';
  String get identityAccountDisabled => isArabic
      ? 'هذا الحساب معطّل. تواصل مع الدعم.'
      : 'This account is disabled. Contact support.';

  /// Message for a failed sign-in attempt. Unknown reasons fall back to the
  /// generic [signInFailure] text on purpose.
  String signInFailureFor(FoundationGateIdentityFailure? failure) {
    return switch (failure) {
      FoundationGateIdentityFailure.invalidCredentials =>
        identityInvalidCredentials,
      FoundationGateIdentityFailure.invalidEmail => identityInvalidEmail,
      FoundationGateIdentityFailure.networkUnavailable =>
        identityNetworkUnavailable,
      FoundationGateIdentityFailure.tooManyAttempts => identityTooManyAttempts,
      FoundationGateIdentityFailure.accountDisabled => identityAccountDisabled,
      _ => signInFailure,
    };
  }

  /// Message for a failed sign-up attempt.
  String createAccountFailureFor(FoundationGateIdentityFailure? failure) {
    return switch (failure) {
      FoundationGateIdentityFailure.emailAlreadyInUse =>
        identityEmailAlreadyInUse,
      FoundationGateIdentityFailure.weakPassword => identityWeakPassword,
      FoundationGateIdentityFailure.invalidEmail => identityInvalidEmail,
      FoundationGateIdentityFailure.networkUnavailable =>
        identityNetworkUnavailable,
      FoundationGateIdentityFailure.tooManyAttempts => identityTooManyAttempts,
      _ => createAccountFailed,
    };
  }

  /// Account was created with the provider, but family discovery failed. The
  /// account exists; the user should sign in and will land on family setup.
  String get accountCreatedDiscoveryUnavailable => isArabic
      ? 'تم إنشاء حسابك. تعذر الوصول إلى خادم العائلة الآن — تابع الإعداد وسنعيد المحاولة.'
      : 'Your account was created. The family server is unreachable right now — continue setup and we will retry.';

  // ── SCR-FAT-001 real family-creation failure copy (title + message) ──
  String get familyCreationUnavailableTitle =>
      isArabic ? 'إنشاء العائلة غير مهيأ' : 'Family creation is not configured';
  String get familyCreationUnavailableMessage => isArabic
      ? 'هذا البناء لا يتصل بخادم حقيقي لإنشاء العائلة، ولا ننشئ عائلة وهمية.'
      : 'This build has no real family-creation server, and no mock family is created.';
  String get familyCreationSessionExpiredTitle =>
      isArabic ? 'انتهت الجلسة' : 'Session expired';
  String get familyCreationSessionExpiredMessage => isArabic
      ? 'سجّل الدخول مرة أخرى، ثم أعد إنشاء العائلة.'
      : 'Sign in again, then create the family.';
  String get familyCreationDeniedTitle =>
      isArabic ? 'الوصول غير متاح' : 'Access is not available';
  String get familyCreationDeniedMessage => isArabic
      ? 'لا يسمح هذا الحساب بإنشاء عائلة.'
      : 'This account may not create a family.';
  String get familyCreationConflictTitle =>
      isArabic ? 'تعذّر تأكيد المحاولة' : 'Attempt could not be confirmed';
  String get familyCreationConflictMessage => isArabic
      ? 'راجع اسم العائلة وأعد المحاولة.'
      : 'Review the family name and try again.';
  String get familyCreationServiceUnavailableTitle =>
      isArabic ? 'الخدمة غير متاحة مؤقتًا' : 'Service temporarily unavailable';
  String get familyCreationServiceUnavailableMessage => isArabic
      ? 'تعذّر إنشاء العائلة على الخادم الآن. أعد المحاولة بعد قليل.'
      : 'The server could not create the family right now. Try again shortly.';
  String get familyCreationUnexpectedTitle =>
      isArabic ? 'استجابة غير متوقعة' : 'Unexpected response';
  String get familyCreationUnexpectedMessage => isArabic
      ? 'لم يفهم التطبيق رد الخادم. أعد المحاولة.'
      : 'The app could not understand the server response. Retry.';
  String get signIn => isArabic ? 'تسجيل الدخول' : 'Sign in';
  String get signOut => isArabic ? 'تسجيل الخروج' : 'Sign out';
  String get chooseFamily => isArabic ? 'اختر العائلة' : 'Choose a family';
  String get chooseFamilyHint => isArabic
      ? 'يتم التحقق من الوصول من الخادم قبل عرض سجل الأطفال.'
      : 'The server verifies access before any children roster is shown.';
  String get childrenTitle =>
      isArabic ? 'مركز الأطفال' : 'Children control centre';
  String get childrenSubtitle => isArabic
      ? 'ملفات الأطفال المرتبطة بالعائلة المختارة'
      : 'Child profiles for the selected family';
  String get serverRosterCurrentSession => isArabic
      ? 'سجل الخادم · الجلسة الحالية'
      : 'Server roster · current session';
  String get profileRosterOnly => isArabic
      ? 'يعرض هذا المسار ملفات الأطفال فقط.'
      : 'This flow shows child profiles only.';
  String get rosterBoundary => isArabic
      ? 'حالة الأجهزة والسياسات غير متصلة في هذه الخطوة؛ لن نعرضها كتوقع أو حقيقة.'
      : 'Device and policy states are not connected in this slice, so they are not shown as estimates or facts.';
  String get primaryGuardianCanCreate => isArabic
      ? 'يمكن للوصي الأساسي إنشاء ملف طفل بالاسم والعمر. الخادم هو صاحب قرار الصلاحية.'
      : 'A primary guardian can create a name-and-age child profile. The server makes the authorization decision.';
  String get coGuardianReadOnly => isArabic
      ? 'عرض وصفي للوصي المشارك؛ لا يمنح هذا العرض صلاحية تعديل.'
      : 'Co-guardian read-only view; viewing does not grant edit authority.';
  String get noActiveFamily =>
      isArabic ? 'لا توجد عائلة نشطة متاحة.' : 'No active family is available.';
  String get signInAgain =>
      isArabic ? 'يرجى تسجيل الدخول مرة أخرى.' : 'Please sign in again.';
  String get accessDenied =>
      isArabic ? 'الوصول غير متاح.' : 'Access is not available.';
  String get rosterAccessDenied => isArabic
      ? 'مركز تحكم الأطفال غير متاح لهذا الحساب.'
      : 'The children control centre is not available for this account.';
  String get serviceUnavailable => isArabic
      ? 'الخدمة غير متاحة مؤقتًا.'
      : 'Service is temporarily unavailable.';
  String get networkUnavailable =>
      isArabic ? 'الاتصال غير متاح.' : 'Connection is unavailable.';
  String get retry => isArabic ? 'إعادة المحاولة' : 'Retry';
  String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  String get chooseAnotherFamily =>
      isArabic ? 'اختيار عائلة أخرى' : 'Choose another family';
  String get emptyRosterTitle =>
      isArabic ? 'لم تُضف ملفات أطفال بعد' : 'No child profiles are set up yet';
  String get emptyRosterBody => isArabic
      ? 'إذا أكد الخادم أن هذا الحساب وصي أساسي، يمكنك إنشاء ملف طفل بالاسم والعمر.'
      : 'If the server confirms this account is a primary guardian, you can create a child profile with a name and age.';
  String get setupStatus => isArabic ? 'حالة الإعداد' : 'Setup status';
  String get sourceLabel => isArabic ? 'المصدر' : 'Source';
  String get familyContext => isArabic ? 'سياق العائلة' : 'Family context';
  String get rosterUnavailableTitle => isArabic
      ? 'لا يمكن عرض السجل الآن'
      : 'The roster is unavailable right now';
  String get rosterUnavailableBody => isArabic
      ? 'لم نحتفظ بنسخة قديمة كأنها حقيقة حالية. أعد المحاولة أو اختر عائلة أخرى.'
      : 'No older roster is shown as current truth. Retry or choose another family.';
  String get accessDeniedBody => isArabic
      ? 'تم التحقق من الوصول من الخادم، ولا توجد تفاصيل أسرية معروضة هنا.'
      : 'Access is verified by the server, and no family detail is shown here.';
  String get noDevicePolicyTitle =>
      isArabic ? 'حدود هذه الخطوة' : 'What this step includes';
  String get childCountOne => isArabic ? 'ملف طفل واحد' : '1 child profile';
  String childCount(int count) =>
      isArabic ? '$count ملفات أطفال' : '$count child profiles';
  String age(int ageYears) => isArabic ? 'العمر: $ageYears' : 'Age: $ageYears';

  String get addChildProfile =>
      isArabic ? 'إضافة ملف طفل' : 'Add child profile';
  String get addChildProfileHint => isArabic
      ? 'أدخل الاسم والعمر فقط. تُرسل هذه المحاولة إلى الخادم، ثم يُعاد تحميل سجل الأطفال المؤكد.'
      : 'Enter only a name and age. This attempt is sent to the server, then the confirmed children roster is reloaded.';
  String get childDisplayName => isArabic ? 'اسم الطفل' : 'Child name';
  String get childAgeYears => isArabic ? 'العمر بالسنوات' : 'Age in years';
  String get createChildProfile =>
      isArabic ? 'إنشاء ملف الطفل' : 'Create child profile';
  String get creatingChildProfile =>
      isArabic ? 'جارٍ إنشاء ملف الطفل…' : 'Creating child profile…';
  String get childProfileCreated => isArabic
      ? 'تم إنشاء ملف الطفل وتحديث السجل.'
      : 'Child profile created and roster refreshed.';
  String get childProfileSavedRefreshUnavailable => isArabic
      ? 'تم حفظ ملف الطفل، لكن تعذر تحديث السجل الآن. أعد المحاولة لعرض السجل المؤكد.'
      : 'The child profile was saved, but the roster could not refresh. Retry to view the confirmed roster.';
  String get childProfileInvalid => isArabic
      ? 'راجع الاسم والعمر ثم أعد المحاولة.'
      : 'Check the name and age, then try again.';
  String get childProfileConflict => isArabic
      ? 'تعذر تأكيد هذه المحاولة. راجع البيانات وأعد المحاولة.'
      : 'This attempt could not be confirmed. Review the details and try again.';
  String get childProfileUnavailable => isArabic
      ? 'خدمة إنشاء الملف غير متاحة مؤقتًا. أعد المحاولة بنفس البيانات.'
      : 'Profile creation is temporarily unavailable. Retry with the same details.';
  String get childProfileNetworkUnavailable => isArabic
      ? 'تعذر الاتصال لإنشاء الملف. أعد المحاولة بنفس البيانات.'
      : 'Could not connect to create the profile. Retry with the same details.';

  String get serverAssignedProfileIdentifier => isArabic
      ? 'يعيّن الخادم معرّف الملف بعد الإنشاء.'
      : 'The server assigns the profile identifier after creation.';

  String displayRole(String role) {
    return switch (role) {
      'primary_guardian' => isArabic ? 'الوصي الأساسي' : 'Primary guardian',
      'co_guardian' => isArabic ? 'وصي مشارك' : 'Co-guardian',
      'child' => isArabic ? 'طفل' : 'Child',
      _ => isArabic ? 'دور غير متاح' : 'Role unavailable',
    };
  }
}
