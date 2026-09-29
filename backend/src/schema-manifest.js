// Migration names and immutable SHA-256 content digests expected by this API release.
// Update this manifest only when adding a reviewed new migration; never rewrite an applied migration.
export const FOUNDATION_SCHEMA_MIGRATIONS = Object.freeze([
  Object.freeze({
    name: '001_foundation.sql',
    sha256: '18614988686dda9fbf71d79d9a75fe8da513e1e1c8f2763169ae20cc306d14e9',
  }),
  Object.freeze({
    name: '002_membership_lifecycle.sql',
    sha256: 'f1d2b34780fd043e5b5de412c53692cce1b337c2ed601e17e6b7c64e3a75b193',
  }),
  Object.freeze({
    name: '003_guardian_continuity.sql',
    sha256: 'e740a795dad432a6f3770a79ff62f559f91b3c49cebeb449c45fa70926a59c35',
  }),
]);
