import 'package:family_os/core/design/components/app_error_state.dart';

/// Injectable create-family seam (Rule 23/25).
///
/// The production default resolves the real [FamilyCreationSource] from the
/// app scope; it never falls back to a mock success. Tests inject explicit
/// implementations.
typedef CreateFamilyFn = Future<void> Function(String name);

/// Create-family failure — maps to SHR-005 [AppErrorKind] variants.
///
/// [title] and [message] override the kind's default copy when a failure needs
/// server-contract-specific wording (session, conflict, …). They are resolved
/// from localized copy classes by the caller, never hardcoded in widgets.
class CreateFamilyException implements Exception {
  const CreateFamilyException(this.kind, {this.title, this.message});

  final AppErrorKind kind;
  final String? title;
  final String? message;

  @override
  String toString() => 'CreateFamilyException($kind)';
}

/// Test helper — always throws [kind].
CreateFamilyFn mockCreateFamilyFail(AppErrorKind kind) {
  return (String name) async {
    assert(name.trim().isNotEmpty, 'family name required');
    throw CreateFamilyException(kind);
  };
}
