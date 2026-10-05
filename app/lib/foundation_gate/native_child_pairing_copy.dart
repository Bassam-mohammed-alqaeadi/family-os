import 'package:flutter/widgets.dart';

/// Localized user-facing copy for the real native child-device hand-off.
///
/// This is deliberately presentation-only: it carries no pairing state,
/// credential, persistence, or mock device behavior.
class NativeChildPairingCopy {
  const NativeChildPairingCopy._(this.isArabic);

  factory NativeChildPairingCopy.of(BuildContext context) =>
      NativeChildPairingCopy._(
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar',
      );

  final bool isArabic;

  String get parentTitle => isArabic ? 'ربط جهاز الابن' : 'Pair child device';
  String get parentIntro => isArabic
      ? 'أنشئ رمز ربط لمرة واحدة على جهاز الوالد. شاركه مع جهاز الابن فقط أثناء وجودك معه.'
      : 'Create a one-time pairing code on the parent device. Give it to the child device only while you are present.';
  String get deviceNameLabel =>
      isArabic ? 'اسم جهاز الابن' : 'Child device name';
  String get deviceNameHint => isArabic
      ? 'مثال: هاتف أندرويد للابن'
      : 'For example: Child Android phone';
  String get parentAccessRequired => isArabic
      ? 'الربط متاح فقط للوصي الأساسي المصادق عليه.'
      : 'Pairing is available only to the authenticated primary guardian.';
  String get deviceNameRequired => isArabic
      ? 'أدخل اسم جهاز الابن أولاً.'
      : 'Enter this child device name first.';
  String get creatingPairing =>
      isArabic ? 'جارٍ إنشاء رمز ربط آمن…' : 'Creating secure pairing code…';
  String get createPairing =>
      isArabic ? 'إنشاء رمز الربط' : 'Create pairing code';
  String get pairingUnavailable => isArabic
      ? 'تعذر على الخادم إنشاء رمز ربط.'
      : 'The server could not create a pairing code.';
  String get oneTimePairingCode =>
      isArabic ? 'رمز ربط الابن لمرة واحدة' : 'One-time child pairing code';
  String pairingExpiresAt(DateTime value) => isArabic
      ? 'ينتهي في ${value.toLocal()}. لا يمكن استخدامه مرة أخرى بعد نجاح ربط جهاز الابن.'
      : 'Expires at ${value.toLocal()}. It cannot be used again after a successful child-device claim.';
  String get copyCode => isArabic ? 'نسخ الرمز' : 'Copy code';

  String get childTitle =>
      isArabic ? 'الدخول إلى وضع الابن' : 'Enter Child Mode';
  String get childIntro => isArabic
      ? 'اطلب من الوالد إنشاء رمز ربط لمرة واحدة. لإرسال الموقع الحقيقي للجهاز عندما لا يكون التطبيق مفتوحًا، سيطلب Android إذن الموقع الدقيق وإذن الموقع في الخلفية. بعد القبول، يبدأ وضع الابن خدمة أمامية مرئية دائمًا ويمكن إيقافها على هذا الجهاز.'
      : 'Ask the parent to create a one-time pairing code. To send the device’s real location while this app is not open, Android will ask for precise and background location access. After acceptance, Child Mode starts an always-visible foreground service that you can stop on this device.';
  String get pairingCodeLabel =>
      isArabic ? 'رمز الربط لمرة واحدة' : 'One-time pairing code';
  String get pairingCodeHint =>
      isArabic ? 'مثال: ABC DEF' : 'For example: ABC DEF';
  String get secureOriginAndCodeRequired => isArabic
      ? 'يلزم عنوان API آمن ورمز ربط.'
      : 'A secure API origin and pairing code are required.';
  String get locationPermissionNotGranted => isArabic
      ? 'لم يُمنح إذن الموقع. يظل رمز الربط غير مستخدم.'
      : 'Location access was not granted. The pairing code remains unused.';
  String get childModeActive => isArabic
      ? 'وضع الابن نشط. يرسل هذا الجهاز الآن قياسات البطارية والموقع الحقيقية.'
      : 'Child Mode is active. This device now sends real battery and location telemetry.';
  String childModeStartFailed(String reason) => isArabic
      ? 'تعذر بدء وضع الابن: $reason'
      : 'Child Mode could not start: $reason';
  String get pairingClaimFailed => isArabic
      ? 'رمز الربط غير صالح أو منتهٍ أو مستخدم سابقًا، أو أن الخادم غير متاح.'
      : 'The pairing code is invalid, expired, already used, or the server is unavailable.';
  String get settingUpChildMode =>
      isArabic ? 'جارٍ إعداد وضع الابن…' : 'Setting up Child Mode…';
  String get enterChildMode =>
      isArabic ? 'الدخول إلى وضع الابن' : 'Enter Child Mode';
  String get childModeStopped => isArabic
      ? 'تم إيقاف خدمة وضع الابن الأمامية على هذا الجهاز.'
      : 'Child Mode foreground service stopped on this device.';
  String get childModeStopFailed => isArabic
      ? 'تعذر إيقاف خدمة وضع الابن.'
      : 'Child Mode service could not be stopped.';
  String get stopChildMode => isArabic
      ? 'إيقاف وضع الابن على هذا الجهاز'
      : 'Stop Child Mode on this device';

  // ── QR Code pairing strings ──────────────────────────────────────────────

  String get scanQrCode => isArabic ? 'مسح رمز QR' : 'Scan QR code';

  String get enterCodeManually =>
      isArabic ? 'إدخال الرمز يدوياً' : 'Enter code manually';

  String get orEnterManually =>
      isArabic ? 'أو أدخل الرمز يدوياً' : 'or enter manually';

  String get scanQrInstruction => isArabic
      ? 'وجّه الكاميرا نحو رمز QR الظاهر في هاتف الوالد'
      : 'Point the camera at the QR code shown on the parent device';

  // ── B5 parent pairing polish ──────────────────────────────────────────
  String get emailVerificationRequiredTitle =>
      isArabic ? 'أكّد بريدك الإلكتروني أولًا' : 'Verify your e-mail first';
  String get emailVerificationRequiredBody => isArabic
      ? 'ربط جهاز الابن يمنح هذا الحساب تحكمًا بجهازه. لحماية عائلتك، يجب تأكيد بريدك الإلكتروني (وسيلة استعادة الحساب) قبل إصدار رمز الربط. يمكنك متابعة بقية الإعداد الآن.'
      : 'Pairing gives this account control over your child’s device. To protect your family, verify your e-mail (your recovery channel) before a pairing code can be issued. You can continue the rest of setup now.';
  String get sendVerificationEmail =>
      isArabic ? 'إرسال رسالة التأكيد' : 'Send verification e-mail';
  String get verificationEmailSent => isArabic
      ? 'أُرسلت رسالة التأكيد. افتح الرابط في بريدك ثم اضغط «تحققت».'
      : 'Verification e-mail sent. Open the link in your inbox, then tap “I verified”.';
  String get verificationEmailSendFailed => isArabic
      ? 'تعذر إرسال رسالة التأكيد الآن. حاول بعد قليل.'
      : 'The verification e-mail could not be sent right now. Try again shortly.';
  String get iVerified => isArabic ? 'تحققت' : 'I verified';
  String get stillNotVerified => isArabic
      ? 'لم يُؤكَّد البريد بعد. تأكد من فتح الرابط في نفس البريد المسجّل.'
      : 'The e-mail is not verified yet. Make sure you opened the link sent to the registered address.';
  String get emailVerified =>
      isArabic ? 'تم تأكيد البريد الإلكتروني' : 'E-mail verified';
  String get checkingVerification => isArabic ? 'جارٍ التحقق…' : 'Checking…';
  String expiresIn(Duration remaining) {
    final m = remaining.inMinutes;
    final sec = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return isArabic ? 'ينتهي الرمز خلال $m:$sec' : 'Code expires in $m:$sec';
  }

  String get pairingExpired => isArabic
      ? 'انتهت صلاحية الرمز ولم يُستخدم. أصدر رمزًا جديدًا.'
      : 'The code expired unused. Issue a new one.';
  String get regenerateCode => isArabic ? 'إصدار رمز جديد' : 'Issue a new code';
  String get waitingForChildDevice => isArabic
      ? 'بانتظار جهاز الابن… امسح الرمز من هاتف الابن.'
      : 'Waiting for the child device… scan the code from the child’s phone.';
  String get childDeviceConnected =>
      isArabic ? 'تم ربط جهاز الابن بنجاح' : 'Child device connected';
  String get backToChildren =>
      isArabic ? 'العودة إلى الأبناء' : 'Back to children';
  String get codeCopied => isArabic ? 'تم نسخ الرمز' : 'Code copied';
  String get keepScreenOpen => isArabic
      ? 'أبقِ هذه الشاشة مفتوحة حتى يكتمل الربط.'
      : 'Keep this screen open until pairing completes.';

  // ── B6 child pairing polish ───────────────────────────────────────────
  String get stepPermissions => isArabic ? 'الأذونات' : 'Permissions';
  String get stepScan => isArabic ? 'الرمز' : 'Code';
  String get stepActivate => isArabic ? 'التفعيل' : 'Activate';
  String get permissionsIntro => isArabic
      ? 'قبل إدخال الرمز، يحتاج التطبيق إذن الموقع «طوال الوقت» حتى يرى الوالد مكان الجهاز وبطاريته. لن يُستهلك الرمز قبل منح الأذونات.'
      : 'Before entering the code, the app needs location access “all the time” so the parent can see the device’s location and battery. The code is not consumed until permissions are granted.';
  String get permissionLocation =>
      isArabic ? 'الموقع الدقيق' : 'Precise location';
  String get permissionBackground => isArabic
      ? 'الموقع في الخلفية (طوال الوقت)'
      : 'Background location (all the time)';
  String get granted => isArabic ? 'ممنوح' : 'Granted';
  String get notGranted => isArabic ? 'غير ممنوح' : 'Not granted';
  String get grantPermissions =>
      isArabic ? 'منح الأذونات' : 'Grant permissions';
  String get permissionsHelp => isArabic
      ? 'إذا لم يظهر خيار «طوال الوقت»، افتح إعدادات التطبيق ← الأذونات ← الموقع واختر «السماح طوال الوقت».'
      : 'If “All the time” does not appear, open App settings → Permissions → Location and choose “Allow all the time”.';
  String get nativeUnavailable => isArabic
      ? 'وضع الابن متاح على أجهزة أندرويد فقط.'
      : 'Child Mode is available on Android devices only.';
  String get secureOriginRequired => isArabic
      ? 'يتطلب وضع الابن خادمًا عبر HTTPS. عنوان الخادم الحالي غير آمن، لذلك لن يُستهلك أي رمز.'
      : 'Child Mode requires an HTTPS server. The current server address is not secure, so no code will be consumed.';
  String get verifyingCode =>
      isArabic ? 'جارٍ التحقق من الرمز…' : 'Verifying the code…';
  String get activatingProtection =>
      isArabic ? 'جارٍ تفعيل الحماية…' : 'Activating protection…';
  String get codeConsumedStartFailed => isArabic
      ? 'تم قبول الرمز لكن تعذر تشغيل الحماية على هذا الجهاز. اطلب من الوالد إصدار رمز جديد ثم أعد المحاولة.'
      : 'The code was accepted but protection could not start on this device. Ask the parent to issue a new code and try again.';
  String startFailureReason(String reason) => switch (reason) {
    'location_permission_required' =>
      isArabic ? 'إذن الموقع مطلوب.' : 'Location permission is required.',
    'invalid_native_telemetry_configuration' =>
      isArabic
          ? 'إعدادات الخادم غير صالحة لهذا الجهاز.'
          : 'Server configuration is not valid for this device.',
    'native_telemetry_start_failed' =>
      isArabic
          ? 'تعذر تشغيل خدمة الحماية.'
          : 'The protection service could not start.',
    'native_telemetry_unavailable' => nativeUnavailable,
    _ => isArabic ? 'سبب غير متوقع.' : 'Unexpected reason.',
  };
  String get codeFormatHint => isArabic
      ? 'الرمز طويل؛ المسح بالكاميرا أسهل وأدق.'
      : 'The code is long; scanning with the camera is easier and more accurate.';
}
