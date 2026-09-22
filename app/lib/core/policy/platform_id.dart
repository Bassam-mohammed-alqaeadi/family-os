/// Target OS for capability honesty (SET-016 / G1).
enum PlatformId {
  android,
  ios,
}

extension PlatformIdX on PlatformId {
  String get storageKey => name;
}
