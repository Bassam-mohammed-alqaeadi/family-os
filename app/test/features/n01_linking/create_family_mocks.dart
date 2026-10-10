import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/features/n01_linking/create_family_create.dart';

/// Test-only create-family mocks — never imported from `lib/`.
///
/// The production route creates the family on the server through the
/// Foundation Gate [FamilyCreationSource] (safety-phase Slice 0). These mocks
/// are injected explicitly by tests that need instant seams.

/// Mock create: succeeds immediately (no persistence — tests only).
Future<void> mockCreateFamilySuccess(String name) async {
  assert(name.trim().isNotEmpty, 'family name required');
}

/// Test helper — always throws [CreateFamilyException] of the given kind.
CreateFamilyFn mockCreateFamilyFail(AppErrorKind kind) {
  return (String name) async {
    assert(name.trim().isNotEmpty, 'family name required');
    throw CreateFamilyException(kind);
  };
}
