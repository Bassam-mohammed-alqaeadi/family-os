import 'package:flutter/widgets.dart';

/// Copy for the isolated, synthetic Foundation Gate.
///
/// This keeps the same words and state grammar across its sign-in, family
/// selection and Children Control Centre surfaces without importing the legacy
/// mock-first application localization composition root.
class FoundationGateCopy {
  const FoundationGateCopy._(this.isArabic);

  factory FoundationGateCopy.of(BuildContext context) {
    return FoundationGateCopy._(Localizations.localeOf(context).languageCode.toLowerCase() == 'ar');
  }

  final bool isArabic;

  String get appTitle => isArabic ? 'بوابة العائلة' : 'Family Gate';
  String get unconfigured => isArabic ? 'بوابة الأساس غير مهيأة.' : 'Foundation Gate is not configured.';
  String get signingIn => isArabic ? 'جارٍ التحقق من الوصول…' : 'Checking access…';
  String get loadingRoster => isArabic ? 'جارٍ تحميل سجل الأطفال من الخادم…' : 'Loading the server roster…';
  String get signInTitle => isArabic ? 'تسجيل دخول تجريبي' : 'Synthetic sign-in';
  String get syntheticOnly => isArabic
      ? 'هذا المسار مخصص لبيئة الاختبار الاصطناعية فقط.'
      : 'This flow is available only in the synthetic staging environment.';
  String get syntheticEmail => isArabic ? 'البريد التجريبي' : 'Synthetic email';
  String get syntheticPassword => isArabic ? 'كلمة المرور التجريبية' : 'Synthetic password';
  String get signInFailure => isArabic ? 'تعذر تسجيل الدخول.' : 'Sign-in is unavailable.';
  String get signIn => isArabic ? 'تسجيل الدخول' : 'Sign in';
  String get signOut => isArabic ? 'تسجيل الخروج' : 'Sign out';
  String get chooseFamily => isArabic ? 'اختر العائلة' : 'Choose a family';
  String get chooseFamilyHint => isArabic
      ? 'يتم التحقق من الوصول من الخادم قبل عرض سجل الأطفال.'
      : 'The server verifies access before any children roster is shown.';
  String get childrenTitle => isArabic ? 'مركز الأطفال' : 'Children control centre';
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
  String get noActiveFamily => isArabic ? 'لا توجد عائلة نشطة متاحة.' : 'No active family is available.';
  String get signInAgain => isArabic ? 'يرجى تسجيل الدخول مرة أخرى.' : 'Please sign in again.';
  String get accessDenied => isArabic ? 'الوصول غير متاح.' : 'Access is not available.';
  String get rosterAccessDenied => isArabic
      ? 'مركز تحكم الأطفال غير متاح لهذا الحساب.'
      : 'The children control centre is not available for this account.';
  String get serviceUnavailable => isArabic ? 'الخدمة غير متاحة مؤقتًا.' : 'Service is temporarily unavailable.';
  String get networkUnavailable => isArabic ? 'الاتصال غير متاح.' : 'Connection is unavailable.';
  String get retry => isArabic ? 'إعادة المحاولة' : 'Retry';
  String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  String get chooseAnotherFamily => isArabic ? 'اختيار عائلة أخرى' : 'Choose another family';
  String get emptyRosterTitle => isArabic ? 'لم تُضف ملفات أطفال بعد' : 'No child profiles are set up yet';
  String get emptyRosterBody => isArabic
      ? 'إذا أكد الخادم أن هذا الحساب وصي أساسي، يمكنك إنشاء ملف طفل بالاسم والعمر.'
      : 'If the server confirms this account is a primary guardian, you can create a child profile with a name and age.';
  String get setupStatus => isArabic ? 'حالة الإعداد' : 'Setup status';
  String get sourceLabel => isArabic ? 'المصدر' : 'Source';
  String get familyContext => isArabic ? 'سياق العائلة' : 'Family context';
  String get rosterUnavailableTitle => isArabic ? 'لا يمكن عرض السجل الآن' : 'The roster is unavailable right now';
  String get rosterUnavailableBody => isArabic
      ? 'لم نحتفظ بنسخة قديمة كأنها حقيقة حالية. أعد المحاولة أو اختر عائلة أخرى.'
      : 'No older roster is shown as current truth. Retry or choose another family.';
  String get accessDeniedBody => isArabic
      ? 'تم التحقق من الوصول من الخادم، ولا توجد تفاصيل أسرية معروضة هنا.'
      : 'Access is verified by the server, and no family detail is shown here.';
  String get noDevicePolicyTitle => isArabic ? 'حدود هذه الخطوة' : 'What this step includes';
  String get childCountOne => isArabic ? 'ملف طفل واحد' : '1 child profile';
  String childCount(int count) => isArabic ? '$count ملفات أطفال' : '$count child profiles';
  String age(int ageYears) => isArabic ? 'العمر: $ageYears' : 'Age: $ageYears';

  String get addChildProfile => isArabic ? 'إضافة ملف طفل' : 'Add child profile';
  String get addChildProfileHint => isArabic
      ? 'أدخل الاسم والعمر فقط. تُرسل هذه المحاولة إلى الخادم، ثم يُعاد تحميل سجل الأطفال المؤكد.'
      : 'Enter only a name and age. This attempt is sent to the server, then the confirmed children roster is reloaded.';
  String get childDisplayName => isArabic ? 'اسم الطفل' : 'Child name';
  String get childAgeYears => isArabic ? 'العمر بالسنوات' : 'Age in years';
  String get createChildProfile => isArabic ? 'إنشاء ملف الطفل' : 'Create child profile';
  String get creatingChildProfile => isArabic ? 'جارٍ إنشاء ملف الطفل…' : 'Creating child profile…';
  String get childProfileCreated => isArabic ? 'تم إنشاء ملف الطفل وتحديث السجل.' : 'Child profile created and roster refreshed.';
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

  String displayRole(String role) {
    return switch (role) {
      'primary_guardian' => isArabic ? 'الوصي الأساسي' : 'Primary guardian',
      'co_guardian' => isArabic ? 'وصي مشارك' : 'Co-guardian',
      'child' => isArabic ? 'طفل' : 'Child',
      _ => isArabic ? 'دور غير متاح' : 'Role unavailable',
    };
  }
}
