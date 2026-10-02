/// Origin of data rendered by a family-facing screen.
///
/// A source must never report [remoteAuthoritative] unless it is backed by a
/// server-authorized read. Cached data remains distinct so stale state cannot
/// impersonate current family truth.
enum RuntimeDataOrigin { unavailable, localOnly, cached, remoteAuthoritative }
