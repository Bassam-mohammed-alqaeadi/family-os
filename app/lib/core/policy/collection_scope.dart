/// Lean collection scopes for SET-012 / P-7 child transparency.
///
/// Storage key: PRIV `privacy_collection_scopes` per child.
enum CollectionScope {
  location,
  screenTime,
  webActivity,
  communications;

  /// Stable JSON / prefs key.
  String get key => switch (this) {
        CollectionScope.location => 'location',
        CollectionScope.screenTime => 'screenTime',
        CollectionScope.webActivity => 'webActivity',
        CollectionScope.communications => 'communications',
      };

  static CollectionScope? tryParse(String raw) {
    switch (raw.trim()) {
      case 'location':
        return CollectionScope.location;
      case 'screenTime':
      case 'screen_time':
        return CollectionScope.screenTime;
      case 'webActivity':
      case 'web_activity':
        return CollectionScope.webActivity;
      case 'communications':
        return CollectionScope.communications;
      default:
        return null;
    }
  }
}

/// Ordered lean set used by father toggles + child honesty list.
const List<CollectionScope> kLeanCollectionScopes = CollectionScope.values;
