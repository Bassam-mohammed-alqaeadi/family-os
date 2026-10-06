import 'device_lifecycle.dart';

/// Guardian-facing sentences for the device lifecycle.
///
/// The server ships machine reason codes and nothing else, so this is the only
/// place a device state becomes words. Arabic is written first and English
/// beside it, matching the rest of this client, and no sentence states a cause it
/// was not given: the text for `stopped_reporting` says the device stopped
/// reporting rather than guessing that it was switched off.
class DeviceLifecycleCopy {
  const DeviceLifecycleCopy({required this.isArabic});

  final bool isArabic;

  /// The one-line summary shown on a child's card when a device needs the
  /// guardian's hand. Deliberately a single sentence: a healthy family day should
  /// not read like a diagnostics console.
  String attentionLine(FoundationGateGuardianDevice device) {
    // The shape is the same in both languages: the device's own label, then the
    // named cause. Only the cause is translated.
    return '${device.deviceLabel}: ${reason(device.health.reasonCode)}';
  }

  /// The action the guardian can take next, or null when there is nothing useful
  /// to suggest. A suggestion that cannot be acted on is noise.
  String? nextStep(FoundationGateGuardianDevice device) {
    return switch (device.health.state) {
      FoundationGateDeviceHealthState.revoked => isArabic
          ? 'أعد الربط ليعود الجهاز يرسل حالته.'
          : 'Pair it again so it can report once more.',
      FoundationGateDeviceHealthState.neverReported => isArabic
          ? 'افتح التطبيق على جهاز الطفل لإكمال الربط.'
          : 'Open the app on the child device to finish pairing.',
      FoundationGateDeviceHealthState.offline => isArabic
          ? 'تأكد أن الجهاز يعمل ومتصل بالإنترنت.'
          : 'Check that the device is on and connected.',
      FoundationGateDeviceHealthState.stale => isArabic
          ? 'آخر تحديث متأخر. تحقق من الاتصال.'
          : 'The last update is late. Check the connection.',
      FoundationGateDeviceHealthState.awaitingPairing ||
      FoundationGateDeviceHealthState.active => null,
    };
  }

  /// The named cause. Every state the server can report has a sentence, so a
  /// guardian never sees a raw code.
  String reason(String reasonCode) {
    return switch (reasonCode) {
      'device_revoked' => isArabic
          ? 'تم قطع الجهاز ولم يعد يرسل شيئاً.'
          : 'This device was cut off and no longer reports.',
      'awaiting_pairing' => isArabic
          ? 'بانتظار إكمال الربط.'
          : 'Waiting for pairing to finish.',
      'never_reported' => isArabic
          ? 'لم يرسل أي تحديث بعد.'
          : 'It has not sent an update yet.',
      'reporting_now' => isArabic ? 'يرسل حالته الآن.' : 'Reporting now.',
      'reporting_late' => isArabic
          ? 'آخر تحديث متأخر عن المعتاد.'
          : 'The last update is later than usual.',
      'stopped_reporting' => isArabic
          ? 'توقف عن إرسال حالته.'
          : 'It stopped reporting its state.',
      'location_reported' => isArabic
          ? 'يرسل موقعه.'
          : 'It reports its location.',
      'location_missing' => isArabic
          ? 'لا يرسل موقعه.'
          : 'It is not sending its location.',
      _ => isArabic ? 'حالة غير معروفة.' : 'Unknown state.',
    };
  }

  /// The gentle, non-alarming label for a device that is simply fine.
  String get healthy => isArabic ? 'يعمل' : 'Working';

  /// The single action a guardian can take on a device that needs a hand.
  String get repairAction => isArabic ? 'إصلاح' : 'Fix';

  /// Names the condition in one word, for places that cannot fit a sentence.
  String stateName(FoundationGateDeviceHealthState state) {
    return switch (state) {
      FoundationGateDeviceHealthState.revoked =>
        isArabic ? 'مقطوع' : 'Cut off',
      FoundationGateDeviceHealthState.awaitingPairing =>
        isArabic ? 'بانتظار الربط' : 'Awaiting pairing',
      FoundationGateDeviceHealthState.neverReported =>
        isArabic ? 'لم يبدأ' : 'Never started',
      FoundationGateDeviceHealthState.active => isArabic ? 'يعمل' : 'Active',
      FoundationGateDeviceHealthState.stale => isArabic ? 'متأخر' : 'Late',
      FoundationGateDeviceHealthState.offline => isArabic ? 'غير متصل' : 'Offline',
    };
  }
}
