import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/ux_local_seed.dart';
import 'package:family_os/core/app_control/app_control_runtime.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/prefs_misc/prefs_misc_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Stage1AppControlRuntime.resetForTest();
    PrefsMiscRuntime.resetForTest();
    await FsSessionKernel.ensureOpen(preferSqlite: true);
  });

  test('applyUxLocalSeed is idempotent for app-install tickets', () async {
    await PrefsMiscRuntime.tryBind();
    await Stage1AppControlRuntime.ensureOpen();

    final first = await applyUxLocalSeed();
    expect(first, greaterThanOrEqualTo(0));

    final pending = await Stage1AppControlRuntime.service.listPendingInstalls(
      ChildId('demo-child'),
    );
    // When SQLite honest, seed creates one pending install.
    if (FsSessionKernel.sqliteFallbackToMemory) {
      return;
    }
    expect(pending, isNotEmpty);

    await applyUxLocalSeed();
    final again = await Stage1AppControlRuntime.service.listPendingInstalls(
      ChildId('demo-child'),
    );
    expect(again.length, pending.length);
  });
}
