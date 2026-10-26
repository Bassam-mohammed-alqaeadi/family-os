import 'package:flutter/services.dart';

/// What the phone's own system allows this app to display.
///
/// This is not a Family OS setting and no screen may treat it as one: a family can
/// turn quiet hours off, unmute every alert, and still receive nothing, because the
/// operating system was never told to let this app show anything. [unknownAnswer]
/// exists so that case is reported instead of guessed — a promise of delivery needs
/// an answer, not an absence of evidence to the contrary.
enum DeviceNotificationPermission { granted, denied, unknownAnswer }

/// The seam the notification card reads. A fake implements it in tests, and the
/// native one below is the only production implementation.
abstract class DeviceNotificationPermissionBridge {
  const DeviceNotificationPermissionBridge();

  /// The current answer, without prompting the parent.
  Future<DeviceNotificationPermission> status();

  /// Asks the system — which may show its own dialog, or answer immediately if the
  /// parent has already refused once and the system will not ask twice.
  Future<DeviceNotificationPermission> request();
}

/// The Android answer, over the same notification bridge that already carries push
/// taps. Everything that is not an answer stays [DeviceNotificationPermission.unknownAnswer]:
/// a missing plugin (a build without the platform channel) and a failed call are both
/// cases where the app genuinely does not know, and the card has to say so.
final class NativeNotificationPermissionBridge extends DeviceNotificationPermissionBridge {
  const NativeNotificationPermissionBridge();

  static const MethodChannel _native =
      MethodChannel('com.familyos.family_os/family_notifications');

  static Future<DeviceNotificationPermission> _read(String method) async {
    try {
      return switch (await _native.invokeMethod<String>(method)) {
        'granted' => DeviceNotificationPermission.granted,
        'denied' => DeviceNotificationPermission.denied,
        _ => DeviceNotificationPermission.unknownAnswer,
      };
    } on MissingPluginException {
      return DeviceNotificationPermission.unknownAnswer;
    } on PlatformException {
      return DeviceNotificationPermission.unknownAnswer;
    }
  }

  @override
  Future<DeviceNotificationPermission> status() =>
      _read('notificationPermissionStatus');

  @override
  Future<DeviceNotificationPermission> request() =>
      _read('requestNotificationPermission');
}
