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
  String get pairingCodeHint => isArabic
      ? 'ستة أحرف، مثال: ABC DEF'
      : 'Six characters, for example ABC DEF';

  String get copyCode => isArabic ? 'نسخ الرمز' : 'Copy code';

  String get childTitle =>
      isArabic ? 'الدخول إلى وضع الابن' : 'Enter Child Mode';
  String get childIntro => isArabic
      ? 'اطلب من الوالد إنشاء رمز ربط لمرة واحدة. لإرسال الموقع الحقيقي للجهاز عندما لا يكون التطبيق مفتوحًا، سيطلب Android إذن الموقع الدقيق وإذن الموقع في الخلفية. بعد القبول، يبدأ وضع الابن خدمة أمامية مرئية دائمًا ويمكن إيقافها على هذا الجهاز.'
      : 'Ask the parent to create a one-time pairing code. To send the device’s real location while this app is not open, Android will ask for precise and background location access. After acceptance, Child Mode starts an always-visible foreground service that you can stop on this device.';
  String get pairingCodeLabel =>
      isArabic ? 'رمز الربط لمرة واحدة' : 'One-time pairing code';
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

  String get scanQrCode =>
      isArabic ? 'مسح رمز QR' : 'Scan QR code';

  String get enterCodeManually =>
      isArabic ? 'إدخال الرمز يدوياً' : 'Enter code manually';

  String get orEnterManually =>
      isArabic ? 'أو أدخل الرمز يدوياً' : 'or enter manually';

  String get scanQrInstruction => isArabic
      ? 'وجّه الكاميرا نحو رمز QR الظاهر في هاتف الوالد'
      : 'Point the camera at the QR code shown on the parent device';
}
