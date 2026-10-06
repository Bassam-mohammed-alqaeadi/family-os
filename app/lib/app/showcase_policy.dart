/// Which routes belong to the family's product, and which belong to the design showcase.
///
/// Added 2026-10-06 under the Phase Zero mandate: the showcase must be structurally
/// quarantined from the live production path, not merely avoided by convention.
///
/// **How this list was derived, and why it is only two entries.**
///
/// The first attempt at this list quarantined sixty-three `/scr-*` routes on the evidence
/// that no literal path string for them appeared outside the router and the galleries.
/// That evidence was wrong, and checking it before committing is the only reason this file
/// is useful rather than harmful: `shell_config.dart` renders every one of those screens
/// through its hub and tab entries, addressing them by screen id and building the path at
/// runtime. Sixty-three product screens would have vanished from the shell in a release
/// build - a silent feature regression, in a change whose entire purpose was to protect the
/// product's integrity.
///
/// The corrected analysis walks the real navigation graph instead of matching strings:
///
///   * roots are the product entry, every tab root screen id and every hub entry screen id
///     in `shell_config.dart`, and every explicit `go`/`push` target in the shell and role
///     guard;
///   * edges are the explicit navigation calls inside each screen class named by the router.
///
/// Its result: all one hundred and twenty-nine `/scr-*` routes are reachable product
/// surface. Not one is a preview. The showcase is exactly two routes - `/gallery`, the
/// design-token gallery, and `/dev-screens`, the QA catalogue - and neither is linked from
/// any tab, any hub entry or any family journey. They exist to browse the design system.
///
/// What the quarantine guarantees in a build that did not ask for the showcase:
///   1. The showcase routes are not registered at all, so there is no route object to
///      navigate to.
///   2. A deep link to a quarantined path redirects to the product entry, so an old link or
///      a hand-typed URL cannot open one.
///   3. Release mode refuses the showcase whatever any build flag says, and it is decided at
///      startup rather than by a caller remembering to pass a parameter.
library;

/// The compile-time request. A build that wants the showcase passes
/// `--dart-define=FAMILY_OS_SHOWCASE=true`. The default requests it, and release mode then
/// refuses it regardless - the quarantine must not be defeatable by a flag.
const bool kShowcaseRequested = bool.fromEnvironment(
  'FAMILY_OS_SHOWCASE',
  defaultValue: true,
);

/// Whether the design showcase may be registered for this build.
///
/// Pure, so both directions are testable without building two binaries.
bool showcaseEnabledFor({
  bool? requested,
  bool? isReleaseMode,
}) {
  final wants = requested ?? kShowcaseRequested;
  final release = isReleaseMode ?? _isReleaseMode;
  return wants && !release;
}

/// Set once at startup so this library does not import the widgets layer for one boolean.
bool _isReleaseMode = false;

/// Records the build mode. Called from `main` before the router is built.
void bindReleaseMode(bool isRelease) {
  _isReleaseMode = isRelease;
}

/// The path a quarantined deep link is sent to: the product entry, never a catalogue page.
const String showcaseFallbackPath = '/scr-shr-001';

/// Routes that exist only to browse the design system.
///
/// Every `/scr-*` screen is deliberately absent from this set. They are the family's
/// product surface, addressed by the shell's tabs and hubs, and removing them would be the
/// regression this policy exists to prevent.
const Set<String> quarantinedShowcasePaths = <String>{
  '/gallery',
  '/dev-screens',
};

/// Whether `path` may only be served by a build that opted into the showcase.
bool isQuarantinedShowcasePath(String path) => quarantinedShowcasePaths.contains(path);
