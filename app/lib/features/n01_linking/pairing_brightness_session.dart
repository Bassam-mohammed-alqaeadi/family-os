import 'package:flutter/services.dart';

/// Owns the temporary Android window-brightness override used while a guardian
/// pairing QR is visible. Unsupported platforms fail silently.
///
/// The previous value is restored exactly once. The race where a route is
/// disposed before the native maximize call returns is also handled: the late
/// result is immediately restored.
class PairingBrightnessSession {
  PairingBrightnessSession({
    MethodChannel channel = const MethodChannel(
      'com.familyos.family_os/pairing_brightness',
    ),
  }) : _channel = channel;

  final MethodChannel _channel;
  double? _previousBrightness;
  bool _maximizeResolved = false;
  bool _restoreRequested = false;

  Future<void> maximize() async {
    if (_maximizeResolved) return;
    try {
      _previousBrightness = await _channel.invokeMethod<double>('maximize');
      _maximizeResolved = true;
      if (_restoreRequested) await _restoreNative();
    } on PlatformException {
      _maximizeResolved = true;
    } on MissingPluginException {
      _maximizeResolved = true;
    }
  }

  Future<void> restore() async {
    if (_restoreRequested) return;
    _restoreRequested = true;
    if (_maximizeResolved) await _restoreNative();
  }

  Future<void> _restoreNative() async {
    try {
      await _channel.invokeMethod<void>('restore', <String, Object?>{
        'brightness': _previousBrightness,
      });
    } on PlatformException {
      // Brightness is a visual enhancement, never a launch/pairing blocker.
    } on MissingPluginException {
      // Expected on iOS, web, desktop, and host-side widget tests.
    }
  }
}
