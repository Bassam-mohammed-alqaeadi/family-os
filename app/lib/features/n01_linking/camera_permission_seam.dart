/// OS camera permission for SCR-CHD-002 (device_permission — local only).
///
/// Mock-first Rule 23/25: no real camera / permission_handler package.
/// Injectable so widget tests drive granted / denied / permanentlyDenied.
enum CameraPermissionStatus {
  /// Scan UI may show the camera frame.
  granted,

  /// Soft deny — repair UI with deep-link to OS settings.
  denied,

  /// Hard deny (typical iOS) — manual instructions, no settings CTA alone.
  permanentlyDenied,
}

/// Seam for check / request / open OS settings (mock deep-link).
abstract class CameraPermissionSeam {
  Future<CameraPermissionStatus> check();

  /// Soft request; may return [CameraPermissionStatus.denied] or granted.
  Future<CameraPermissionStatus> request();

  /// Deep-link OS app settings. Returns whether the call was accepted.
  Future<bool> openSettings();
}

/// Controllable fake for Stage-1 / widget tests.
class FakeCameraPermissionSeam implements CameraPermissionSeam {
  FakeCameraPermissionSeam({
    this.status = CameraPermissionStatus.granted,
    this.grantOnOpenSettings = false,
    this.grantOnRequest = false,
  });

  CameraPermissionStatus status;

  /// When true, [openSettings] flips [status] to [CameraPermissionStatus.granted].
  bool grantOnOpenSettings;

  /// When true, [request] flips [status] to [CameraPermissionStatus.granted].
  bool grantOnRequest;

  int checkCount = 0;
  int requestCount = 0;
  int openSettingsCount = 0;

  @override
  Future<CameraPermissionStatus> check() async {
    checkCount++;
    return status;
  }

  @override
  Future<CameraPermissionStatus> request() async {
    requestCount++;
    if (grantOnRequest) {
      status = CameraPermissionStatus.granted;
    }
    return status;
  }

  @override
  Future<bool> openSettings() async {
    openSettingsCount++;
    if (grantOnOpenSettings) {
      status = CameraPermissionStatus.granted;
    }
    return true;
  }
}
