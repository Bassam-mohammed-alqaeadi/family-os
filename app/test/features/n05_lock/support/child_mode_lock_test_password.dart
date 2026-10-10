/// Test-only parent-account password for [ChildModeLockService].
///
/// Safety phase S1 moved this out of production code (`lib/`), where it used to be a
/// fixed password anyone reading the repository knew. Production has no verifier until
/// slice S12 and answers `ChildModeUnlockOutcome.unavailable`.
const kChildModeLockTestPassword = 'parent-account';
