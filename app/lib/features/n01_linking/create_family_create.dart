import 'package:family_os/core/design/components/app_error_state.dart';

/// Injectable create-family seam (mock-first Rule 23/25 — no Firebase).
typedef CreateFamilyFn = Future<void> Function(String name);

/// Mock create failure — maps to SHR-005 [AppErrorKind] variants.
class CreateFamilyException implements Exception {
  const CreateFamilyException(this.kind);

  final AppErrorKind kind;

  @override
  String toString() => 'CreateFamilyException($kind)';
}

/// Default mock create: succeeds immediately (OWNER created — no persistence).
Future<void> mockCreateFamilySuccess(String name) async {
  assert(name.trim().isNotEmpty, 'family name required');
}

/// Test helper — always throws [kind].
CreateFamilyFn mockCreateFamilyFail(AppErrorKind kind) {
  return (String name) async {
    assert(name.trim().isNotEmpty, 'family name required');
    throw CreateFamilyException(kind);
  };
}
