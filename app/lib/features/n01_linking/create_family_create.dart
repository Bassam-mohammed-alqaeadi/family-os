import 'package:family_os/core/design/components/app_error_state.dart';

/// Injectable create-family seam — tests and previews only.
///
/// The production route uses the server-backed `FamilyCreationSource` from
/// AppScope (safety-phase Slice 0). The mocks live in test code only
/// (`app/test/features/n01_linking/create_family_mocks.dart`) and are never a
/// screen default.
typedef CreateFamilyFn = Future<void> Function(String name);

/// Mock create failure — maps to SHR-005 [AppErrorKind] variants.
class CreateFamilyException implements Exception {
  const CreateFamilyException(this.kind);

  final AppErrorKind kind;

  @override
  String toString() => 'CreateFamilyException($kind)';
}
