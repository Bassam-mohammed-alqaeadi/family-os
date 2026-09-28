import 'package:flutter/foundation.dart';

import 'package:family_os/core/app_control/app_control_runtime.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/modes/modes_runtime.dart';
import 'package:family_os/core/offline_ai_safety/offline_ai_safety_runtime.dart';
import 'package:family_os/core/screen_camera/screen_camera_runtime.dart';
import 'package:family_os/core/sos_final/sos_final_runtime.dart';
import 'package:family_os/features/n02_day/location_ux_bridge.dart';
import 'package:family_os/features/n04_web_filter/web_filter_runtime.dart';

/// HOST-ROUTER-C — boot-once FS Domain runtimes (soft-fail, no Memory claim).
///
/// Screens may still call [ensureOpen] (idempotent). Composition root warms
/// the same singletons so first navigation is not a cold Domain open.
abstract final class FsCompositionRuntime {
  FsCompositionRuntime._();

  static var _opened = false;
  static var _partial = false;

  static bool get isOpen => _opened;
  static bool get partialUnavailable => _partial;

  /// Soft bind from [main] — never throws.
  static Future<void> tryBind() async {
    if (_opened) return;
    try {
      await FsSessionKernel.ensureOpen();
      if (FsSessionKernel.sqliteFallbackToMemory) {
        debugPrint(
          'HOST-ROUTER-C: SQLite→Memory — FS Domain boot skipped '
          '(not restart-safe)',
        );
        _partial = true;
        _opened = true;
        return;
      }
      await Stage1SosFinalRuntime.ensureOpen();
      await Stage1AppControlRuntime.ensureOpen();
      await Stage1LocationRuntime.ensureOpen();
      await Stage1ModesRuntime.ensureOpen();
      await Stage1WebFilterRuntime.ensureOpen();
      await Stage1ScreenCameraRuntime.ensureOpen();
      await Stage1OfflineAiSafetyRuntime.ensureOpen();
      _partial = false;
      _opened = true;
    } catch (e, st) {
      debugPrint('HOST-ROUTER-C FsCompositionRuntime.tryBind soft-fail: $e\n$st');
      _partial = true;
      _opened = true;
    }
  }

  static void resetForTest() {
    _opened = false;
    _partial = false;
    Stage1SosFinalRuntime.resetForTest();
    Stage1AppControlRuntime.resetForTest();
    Stage1LocationRuntime.resetForTest();
    Stage1ModesRuntime.resetForTest();
    Stage1WebFilterRuntime.resetForTest();
    Stage1ScreenCameraRuntime.resetForTest();
    Stage1OfflineAiSafetyRuntime.resetForTest();
  }
}
