import 'dart:convert';

import 'package:flutter/services.dart';

/// Android boundary for the real child-device telemetry engine.
///
/// This has no mock implementation. On unsupported platforms it reports that
/// native telemetry is unavailable; it never manufactures sensor readings or a
/// successful pairing state.
class NativeChildTelemetryBridge {
  NativeChildTelemetryBridge._();

  static const MethodChannel _channel = MethodChannel(
    'com.familyos.family_os/native_child_telemetry',
  );

  static final List<VoidCallback> _revocationListeners = [];

  static void addRevocationListener(VoidCallback listener) {
    _ensureInitialized();
    _revocationListeners.add(listener);
  }

  static void removeRevocationListener(VoidCallback listener) {
    _revocationListeners.remove(listener);
  }

  static bool _initialized = false;
  static void _ensureInitialized() {
    if (_initialized) return;
    try {
      // Guard against headless test environments where ServicesBinding is uninitialized.
      ServicesBinding.instance.defaultBinaryMessenger;
    } catch (_) {
      return;
    }
    _initialized = true;
    try {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onDeviceRevoked') {
          for (final listener in List<VoidCallback>.from(_revocationListeners)) {
            try {
              listener();
            } catch (_) {}
          }
        }
      });
    } catch (_) {
      _initialized = false;
    }
  }

  /// Triggers an immediate heartbeat on the native child service.
  static Future<bool> heartbeat() async {
    try {
      final result = await _channel.invokeMethod<bool>('heartbeat');
      return result == true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<NativeTelemetryPermissionState>
  requestLocationPermissions() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'requestLocationPermissions',
      );
      return NativeTelemetryPermissionState.fromMap(result);
    } on MissingPluginException {
      return const NativeTelemetryPermissionState.unavailable();
    } on PlatformException {
      return const NativeTelemetryPermissionState.unavailable();
    }
  }

  static Future<NativeTelemetryStatus> status() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('status');
      return NativeTelemetryStatus.fromMap(result);
    } on MissingPluginException {
      return const NativeTelemetryStatus.unavailable();
    } on PlatformException {
      return const NativeTelemetryStatus.unavailable();
    }
  }

  static Future<bool> stop() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('stop');
      return result?['stopped'] == true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// S2 resilience: the protection verdict computed where the facts live.
  ///
  /// The verdict's state word comes from a closed vocabulary; anything outside
  /// it (or any platform failure) yields [NativeProtectionState.unavailable].
  /// See [NativeProtectionState.effectiveState] for the one rule Dart applies.
  static Future<NativeProtectionState> protectionState() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'protectionState',
      );
      return NativeProtectionState.fromMap(result);
    } on MissingPluginException {
      return const NativeProtectionState.unavailable();
    } on PlatformException {
      return const NativeProtectionState.unavailable();
    }
  }

  /// S2 resilience: which settings door opens this vendor's battery exemption.
  static Future<NativeBatteryGuidance> batteryGuidance() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'batteryGuidance',
      );
      return NativeBatteryGuidance.fromMap(result);
    } on MissingPluginException {
      return const NativeBatteryGuidance.unavailable();
    } on PlatformException {
      return const NativeBatteryGuidance.unavailable();
    }
  }

  /// S2 resilience: opens the vendor's battery settings (resolve-checked natively;
  /// falls back to the app-details screen). True only when a vendor door opened.
  static Future<bool> openBatterySettings() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'openBatterySettings',
      );
      return result?['opened'] == true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Moves the one-time device credential directly into Android Keystore-backed
  /// storage, then starts the foreground service only if real location access
  /// has been granted by the device owner/guardian.
  static Future<NativeTelemetryStartResult> configureAndStart({
    required String apiOrigin,
    required String deviceId,
    required String deviceCredential,
  }) async {
    try {
      final result = await _channel
          .invokeMapMethod<String, dynamic>('configureAndStart', {
            'apiOrigin': apiOrigin,
            'deviceId': deviceId,
            'deviceCredential': deviceCredential,
          });
      return NativeTelemetryStartResult.fromMap(result);
    } on MissingPluginException {
      return const NativeTelemetryStartResult.unavailable();
    } on PlatformException {
      return const NativeTelemetryStartResult.unavailable();
    }
  }

  /// Starts the foreground service from the pairing the native layer already holds.
  ///
  /// The pairing screen configures; the transparency screen starts — after the
  /// disclosure has been made and the permissions asked. No credential crosses
  /// this boundary in either direction.
  static Future<NativeTelemetryStartResult> startConfigured() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'startConfigured',
      );
      return NativeTelemetryStartResult.fromMap(result);
    } on MissingPluginException {
      return const NativeTelemetryStartResult.unavailable();
    } on PlatformException {
      return const NativeTelemetryStartResult.unavailable();
    }
  }

  /// Records the disclosure-consent act on the server, with the paired-device
  /// credential the native layer holds. The credential never reaches Dart.
  static Future<NativeConsentAnswer> recordConsent({
    required String capability,
    required String textVersion,
    required String idempotencyKey,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'consentRequest',
        <String, Object?>{
          'operation': 'recordConsent',
          'body': jsonEncode({
            'capability': capability,
            'textVersion': textVersion,
          }),
          'idempotencyKey': idempotencyKey,
        },
      );
      return NativeConsentAnswer.fromMap(result);
    } on MissingPluginException {
      return const NativeConsentAnswer.unavailable();
    } on PlatformException {
      return const NativeConsentAnswer.unavailable();
    }
  }

  /// What this handset is sharing right now, as the server's consent ledger
  /// holds it — never an inference.
  static Future<NativeConsentAnswer> readLocationSharing() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'consentRequest',
        <String, Object?>{'operation': 'readLocationSharing'},
      );
      return NativeConsentAnswer.fromMap(result);
    } on MissingPluginException {
      return const NativeConsentAnswer.unavailable();
    } on PlatformException {
      return const NativeConsentAnswer.unavailable();
    }
  }
}

class NativeTelemetryPermissionState {
  const NativeTelemetryPermissionState({
    required this.fineLocationGranted,
    required this.backgroundLocationGranted,
    required this.available,
  });

  const NativeTelemetryPermissionState.unavailable()
    : fineLocationGranted = false,
      backgroundLocationGranted = false,
      available = false;

  final bool fineLocationGranted;
  final bool backgroundLocationGranted;
  final bool available;

  factory NativeTelemetryPermissionState.fromMap(Map<String, dynamic>? value) =>
      NativeTelemetryPermissionState(
        fineLocationGranted: value?['fineLocationGranted'] == true,
        backgroundLocationGranted: value?['backgroundLocationGranted'] == true,
        available: value?['available'] == true,
      );
}

class NativeTelemetryStartResult {
  const NativeTelemetryStartResult({
    required this.started,
    required this.reason,
  });

  const NativeTelemetryStartResult.unavailable()
    : started = false,
      reason = 'native_telemetry_unavailable';

  final bool started;
  final String reason;

  factory NativeTelemetryStartResult.fromMap(Map<String, dynamic>? value) =>
      NativeTelemetryStartResult(
        started: value?['started'] == true,
        reason: value?['reason'] as String? ?? 'native_telemetry_unavailable',
      );
}

class NativeTelemetryStatus {
  const NativeTelemetryStatus({
    required this.available,
    required this.running,
    required this.configured,
    required this.fineLocationGranted,
    required this.backgroundLocationGranted,
    this.credentialRevoked = false,
    this.lastReportOutcome,
  });

  const NativeTelemetryStatus.unavailable()
    : available = false,
      running = false,
      configured = false,
      fineLocationGranted = false,
      backgroundLocationGranted = false,
      credentialRevoked = false,
      lastReportOutcome = null;

  final bool available;
  final bool running;
  final bool configured;
  final bool fineLocationGranted;
  final bool backgroundLocationGranted;
  final bool credentialRevoked;
  final String? lastReportOutcome;

  factory NativeTelemetryStatus.fromMap(Map<String, dynamic>? value) =>
      NativeTelemetryStatus(
        available: value?['available'] == true,
        running: value?['running'] == true,
        configured: value?['configured'] == true,
        fineLocationGranted: value?['fineLocationGranted'] == true,
        backgroundLocationGranted: value?['backgroundLocationGranted'] == true,
        credentialRevoked: value?['credentialRevoked'] == true,
        lastReportOutcome: value?['lastReportOutcome'] as String?,
      );
}

/// S2 resilience: the protection verdict, mirrored - never re-derived - from native.
///
/// The native layer computes the verdict; Dart applies exactly one rule on top
/// ([effectiveState]): when the live grant overlay explicitly says background
/// location is *not* granted, a healthy-looking verdict is distrusted into
/// `stopped/permission_revoked`, because the overlay is fresher than any verdict
/// the service computed before the grant was pulled. Missing overlay fields mean
/// "not re-read", never a flip: doubt about the overlay does not rewrite the
/// verdict, it just renders it.
class NativeProtectionState {
  const NativeProtectionState({
    required this.state,
    required this.reasons,
    required this.reason,
    required this.queueDepth,
    required this.live,
    required this.backgroundLocationGranted,
    required this.notificationsGranted,
    required this.available,
  });

  const NativeProtectionState.unavailable()
    : state = NativeProtectionVerdict.unavailable,
      reasons = const [],
      reason = null,
      queueDepth = 0,
      live = false,
      backgroundLocationGranted = null,
      notificationsGranted = null,
      available = false;

  /// Closed vocabulary from the native contract (`not_configured` included).
  /// Anything outside it parses as [NativeProtectionVerdict.unavailable].
  final NativeProtectionVerdict state;

  /// Degraded reason wires (`battery_restricted`, `offline`, ...), possibly empty.
  final List<String> reasons;

  /// Stopped reason wire (`service_down`, `permission_revoked`, ...), if stopped.
  final String? reason;

  final int queueDepth;

  /// False when the service never reported in this process (verdict derived locally).
  final bool live;

  /// Live grant overlay, re-read by the activity. Null = not re-read.
  final bool? backgroundLocationGranted;
  final bool? notificationsGranted;

  final bool available;

  /// The verdict to render after the single overlay-distrust rule.
  NativeProtectionState get effective {
    if ((state == NativeProtectionVerdict.fullyProtected ||
            state == NativeProtectionVerdict.degraded) &&
        backgroundLocationGranted == false) {
      return NativeProtectionState(
        state: NativeProtectionVerdict.stopped,
        reasons: const [],
        reason: 'permission_revoked',
        queueDepth: queueDepth,
        live: live,
        backgroundLocationGranted: backgroundLocationGranted,
        notificationsGranted: notificationsGranted,
        available: available,
      );
    }
    return this;
  }

  factory NativeProtectionState.fromMap(Map<String, dynamic>? value) {
    if (value == null || value['available'] != true) {
      return const NativeProtectionState.unavailable();
    }
    final parsed = NativeProtectionVerdict.parse(value['state']);
    if (parsed == null) return const NativeProtectionState.unavailable();
    final rawReasons = value['reasons'];
    return NativeProtectionState(
      state: parsed,
      reasons: rawReasons is List
          ? rawReasons.whereType<String>().toList(growable: false)
          : const [],
      reason: value['reason'] as String?,
      queueDepth: (value['queueDepth'] as num?)?.toInt() ?? 0,
      live: value['live'] != false,
      backgroundLocationGranted: value['backgroundLocationGranted'] as bool?,
      notificationsGranted: value['notificationsGranted'] as bool?,
      available: true,
    );
  }
}

enum NativeProtectionVerdict {
  fullyProtected('fully_protected'),
  degraded('degraded'),
  stopped('stopped'),
  notConfigured('not_configured'),
  unavailable('unavailable');

  const NativeProtectionVerdict(this.wire);

  final String wire;

  static NativeProtectionVerdict? parse(Object? wire) {
    for (final verdict in NativeProtectionVerdict.values) {
      if (verdict.wire == wire) return verdict;
    }
    return null;
  }
}

/// S2 resilience: the vendor's battery-settings door (guidance only).
class NativeBatteryGuidance {
  const NativeBatteryGuidance({
    required this.vendor,
    required this.action,
    required this.packageName,
    required this.activity,
    required this.stepsKey,
    required this.available,
  });

  const NativeBatteryGuidance.unavailable()
    : vendor = 'stock',
      action = '',
      packageName = '',
      activity = '',
      stepsKey = 'oem_stock',
      available = false;

  final String vendor;
  final String action;
  final String packageName;
  final String activity;

  /// Copy key the guidance screen maps to localized steps (closed switch).
  final String stepsKey;
  final bool available;

  factory NativeBatteryGuidance.fromMap(Map<String, dynamic>? value) {
    if (value == null || value['available'] != true) {
      return const NativeBatteryGuidance.unavailable();
    }
    return NativeBatteryGuidance(
      vendor: value['vendor'] as String? ?? 'stock',
      action: value['action'] as String? ?? '',
      packageName: value['package'] as String? ?? '',
      activity: value['activity'] as String? ?? '',
      stepsKey: value['stepsKey'] as String? ?? 'oem_stock',
      available: true,
    );
  }
}

/// One consent answer from the server, carried across the native boundary as the
/// raw status and body. Nothing here interprets consent: the caller reads the
/// ledger's own words.
class NativeConsentAnswer {
  const NativeConsentAnswer({required this.statusCode, required this.body});

  const NativeConsentAnswer.unavailable()
    : statusCode = null,
      body = null;

  final int? statusCode;
  final String? body;

  bool get available => statusCode != null;

  factory NativeConsentAnswer.fromMap(Map<String, dynamic>? value) {
    final status = value?['statusCode'];
    final body = value?['body'];
    if (status is! int || body is! String) {
      return const NativeConsentAnswer.unavailable();
    }
    return NativeConsentAnswer(statusCode: status, body: body);
  }
}
