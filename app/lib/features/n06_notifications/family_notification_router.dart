import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

const _notificationUuid =
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89a-fA-F][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$';
final _notificationUuidPattern = RegExp(_notificationUuid);

/// A strictly validated, in-app destination for one of the reviewed family alerts.
///
/// FCM text is never used to make a route. The only routing inputs are the closed event/copy-key
/// pairs and the opaque UUIDs the backend resolved for that event. No coordinates or names are
/// accepted from notification data.
///
/// A child's pending task claim lands on the family's task screen, which is the one screen that can
/// answer it. It carries no identifiers in its route: the screen reads the family's own queue, so
/// there is nothing for a forged payload to point at.
final class PendingAlert {
  const PendingAlert._({
    required this.eventType,
    required this.copyKey,
    required this.channelId,
    required this.route,
    this.alertId,
    this.childId,
    this.deviceId,
    this.zoneId,
    this.occurredAt,
  });

  final String eventType;
  final String copyKey;
  final String channelId;
  final String route;
  final String? alertId;
  final String? childId;
  final String? deviceId;
  final String? zoneId;
  final DateTime? occurredAt;

  static PendingAlert? fromRemoteMessage(RemoteMessage message) =>
      fromData(message.data);

  static PendingAlert? fromData(Map<String, dynamic> data) {
    final type = data['type'];
    final copyKey = data['copyKey'];
    final alertId = data['alertId'];
    final childId = data['childId'];
    final deviceId = data['deviceId'];
    final zoneId = data['zoneId'];
    final occurredAtRaw = data['occurredAt'];
    if (type is! String || copyKey is! String) return null;
    final occurredAt = occurredAtRaw is String
        ? DateTime.tryParse(occurredAtRaw)?.toUtc()
        : null;

    if (type == 'family.sos_alert_raised' && copyKey == 'sos.raised' &&
        _isUuid(alertId) && _isUuid(childId)) {
      final route = Uri(
        path: '/scr-fat-018',
        queryParameters: <String, String>{'alertId': alertId as String, 'childId': childId as String},
      ).toString();
      return PendingAlert._(
        eventType: type,
        copyKey: copyKey,
        channelId: 'familyos_sos_alerts',
        route: route,
        alertId: alertId,
        childId: childId,
        occurredAt: occurredAt,
      );
    }

    if ((type == 'family.geofence_entered' && copyKey == 'geofence.entered') ||
        (type == 'family.geofence_exited' && copyKey == 'geofence.exited')) {
      if (!_isUuid(childId) || !_isUuid(zoneId)) return null;
      final route = Uri(
        path: '/scr-fat-014',
        queryParameters: <String, String>{'childId': childId as String},
      ).toString();
      return PendingAlert._(
        eventType: type,
        copyKey: copyKey,
        channelId: 'familyos_geofence_alerts',
        route: route,
        childId: childId,
        zoneId: zoneId,
        occurredAt: occurredAt,
      );
    }

    if (type == 'family.device_protection_reported' &&
        copyKey == 'protection.reported' && _isUuid(deviceId)) {
      final route = Uri(
        path: '/scr-fat-026',
        queryParameters: <String, String>{'deviceId': deviceId as String},
      ).toString();
      return PendingAlert._(
        eventType: type,
        copyKey: copyKey,
        channelId: 'familyos_protection_alerts',
        route: route,
        deviceId: deviceId,
        childId: _isUuid(childId) ? childId : null,
        occurredAt: occurredAt,
      );
    }
    if (type == 'family.task_claimed' && copyKey == 'task.claimed') {
      return PendingAlert._(
        eventType: type,
        copyKey: copyKey,
        channelId: 'familyos_family_alerts',
        route: '/scr-fat-054',
        childId: _isUuid(childId) ? childId : null,
        occurredAt: occurredAt,
      );
    }
    return null;
  }

  /// Used by the native foreground-notification tap bridge as a second route allow-list.
  static String? validateRoute(Object? raw) {
    if (raw is! String || raw.isEmpty || raw.length > 512) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.hasScheme || uri.hasAuthority || uri.hasFragment || uri.path.isEmpty) {
      return null;
    }
    final parameters = uri.queryParametersAll;
    final keys = parameters.keys.toSet();
    bool exactlyOne(String key) => parameters[key]?.length == 1;
    switch (uri.path) {
      case '/scr-fat-018':
        if (keys.length != 2 || !keys.containsAll(const <String>{'alertId', 'childId'}) ||
            !exactlyOne('alertId') || !exactlyOne('childId') ||
            !_isUuid(uri.queryParameters['alertId']) || !_isUuid(uri.queryParameters['childId'])) {
          return null;
        }
        break;
      case '/scr-fat-014':
        if (keys.length != 1 || !keys.contains('childId') || !exactlyOne('childId') ||
            !_isUuid(uri.queryParameters['childId'])) {
          return null;
        }
        break;
      case '/scr-fat-026':
        if (keys.length != 1 || !keys.contains('deviceId') || !exactlyOne('deviceId') ||
            !_isUuid(uri.queryParameters['deviceId'])) {
          return null;
        }
        break;
      case '/scr-fat-054':
        // The task board takes no parameters, so any parameter at all is a reason to refuse it.
        if (keys.isNotEmpty) return null;
        break;
      default:
        return null;
    }
    return uri.toString();
  }

  static bool _isUuid(Object? value) =>
      value is String && _notificationUuidPattern.hasMatch(value);
}

/// Receives push taps and routes only validated S1 notifications to existing screens.
///
/// Firebase automatically displays notification payloads while the app is backgrounded. While
/// foregrounded, the Android bridge uses the same four channels and carries only a validated
/// internal route. Missing Firebase configuration and platform-channel errors remain optional.
final class FamilyNotificationRouter {
  FamilyNotificationRouter({required GoRouter router}) : _router = router;

  static const MethodChannel _native =
      MethodChannel('com.familyos.family_os/family_notifications');

  final GoRouter _router;
  final List<StreamSubscription<RemoteMessage>> _subscriptions =
      <StreamSubscription<RemoteMessage>>[];
  PendingAlert? _pending;
  var _attached = false;

  static void registerBackgroundHandler() {
    try {
      FirebaseMessaging.onBackgroundMessage(familyOsPushBackgroundHandler);
    } on Object {
      // Push is optional on builds without the Firebase platform plugin.
    }
  }

  Future<void> attach() async {
    if (_attached) return;
    _attached = true;
    _native.setMethodCallHandler(_handleNativeCall);
    try {
      final initialRoute = await _native.invokeMethod<String>('consumeNotificationRoute');
      final safeRoute = PendingAlert.validateRoute(initialRoute);
      if (safeRoute != null) _router.go(safeRoute);
    } on Object {
      // Native routing is absent on iOS and must not prevent push subscription elsewhere.
    }
    try {
      if (Firebase.apps.isEmpty) return;
      final messaging = FirebaseMessaging.instance;
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: false,
        sound: true,
      );
      _subscriptions.add(FirebaseMessaging.onMessage.listen(
        (message) => unawaited(_showForeground(message)),
        onError: (Object _) {},
      ));
      _subscriptions.add(FirebaseMessaging.onMessageOpenedApp.listen(
        _acceptMessage,
        onError: (Object _) {},
      ));
      final initial = await messaging.getInitialMessage();
      if (initial != null) _acceptMessage(initial);
    } on Object {
      // Push setup must not prevent the family app from opening.
    }
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final alert = PendingAlert.fromRemoteMessage(message);
    final title = message.notification?.title?.trim();
    final body = message.notification?.body?.trim();
    if (alert == null || title == null || title.isEmpty || body == null || body.isEmpty) return;
    try {
      await _native.invokeMethod<bool>('showForegroundNotification', <String, Object?>{
        'id': message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
        'title': title,
        'body': body,
        'channelId': alert.channelId,
        'route': alert.route,
      });
    } on Object {
      // iOS and platforms without the Android notification bridge stay non-fatal.
    }
  }

  void _acceptMessage(RemoteMessage message) {
    final alert = PendingAlert.fromRemoteMessage(message);
    if (alert == null) return;
    _pending = alert;
    WidgetsBinding.instance.addPostFrameCallback((_) => flushPending());
  }

  Future<Object?> _handleNativeCall(MethodCall call) async {
    if (call.method == 'openRoute') {
      final safeRoute = PendingAlert.validateRoute(call.arguments);
      if (safeRoute != null) _router.go(safeRoute);
    }
    return null;
  }

  /// Flushes a cold-start or early-arriving alert once the root router is mounted.
  void flushPending() {
    final alert = _pending;
    if (alert == null) return;
    _pending = null;
    final safeRoute = PendingAlert.validateRoute(alert.route);
    if (safeRoute != null) _router.go(safeRoute);
  }

  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    _native.setMethodCallHandler(null);
    _attached = false;
  }
}

@pragma('vm:entry-point')
Future<void> familyOsPushBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) await Firebase.initializeApp();
    // Validate the closed contract in the background isolate. Android displays the
    // notification payload through Firebase; routing occurs only after a user tap.
    PendingAlert.fromRemoteMessage(message);
  } on Object {
    // A malformed or unavailable optional push must not crash the background isolate.
  }
}
