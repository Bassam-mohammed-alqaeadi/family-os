/// The family this device last selected, kept across a cold start.
///
/// Without it, a guardian who restarts the app offline has no family to match the kept minutes
/// reading against, and the reading is hidden. It holds only the family id, which the server
/// already told this device. It is cleared at sign-in and sign-out, so a different account never
/// inherits it.
abstract interface class SelectedFamilyStore {
  Future<String?> read();

  Future<void> write(String familyId);

  Future<void> clear();
}

/// Opens the durable store on first use. Every read and write fails soft: a broken store means
/// "no remembered family", never an exception in the sign-in flow.
final class DeferredSelectedFamilyStore implements SelectedFamilyStore {
  DeferredSelectedFamilyStore(this._open);

  final Future<SelectedFamilyStore?> Function() _open;
  Future<SelectedFamilyStore?>? _opened;

  Future<SelectedFamilyStore?> get _store => _opened ??= _open();

  @override
  Future<String?> read() async {
    try {
      return await (await _store)?.read();
    } on Object {
      return null;
    }
  }

  @override
  Future<void> write(String familyId) async {
    try {
      await (await _store)?.write(familyId);
    } on Object {
      return;
    }
  }

  @override
  Future<void> clear() async {
    try {
      await (await _store)?.clear();
    } on Object {
      return;
    }
  }
}
