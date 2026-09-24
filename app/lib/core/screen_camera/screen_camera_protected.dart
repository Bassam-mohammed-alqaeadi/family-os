/// Explicit Family OS camera exceptions (SC-OD-07) — never silent bypass.
enum ScreenCameraExceptionClass {
  /// SOS Final owns emergency; FS-004 must not block reachability.
  sos,

  /// QR / enrollment camera when flow requires it.
  qrEnrollment,

  /// Approved Family OS camera workflows (e.g. Studio) — role-gated.
  familyOsWorkflow,

  /// Family call camera only when feature explicitly requires it.
  familyCallCamera,
}

/// Protected matrix — ordinary Quran/Chat paths are not FS-004-controlled.
abstract final class ScreenCameraProtectedMatrix {
  static const Set<ScreenCameraExceptionClass> alwaysExplicit = {
    ScreenCameraExceptionClass.sos,
    ScreenCameraExceptionClass.qrEnrollment,
    ScreenCameraExceptionClass.familyOsWorkflow,
    ScreenCameraExceptionClass.familyCallCamera,
  };

  /// Microphone / SOS audio are OUT of FS-004 (SC-OD-05 / SC-OD-08).
  static const bool microphoneInScope = false;
  static const bool sosAudioInScope = false;
}
