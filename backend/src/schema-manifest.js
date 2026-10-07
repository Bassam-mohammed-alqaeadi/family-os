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
  Object.freeze({
    name: '004_audit_correlation.sql',
    sha256: '310e1262ce68d241be13bee1f2e0242864260e9eb22ebebaa81a8c5b4aa31032',
  }),
  Object.freeze({
    name: '005_family_children_roster.sql',
    sha256: '0da71c0880da2e10ae306888902e933b10b7090a54cf428af9ceae395bf4503e',
  }),
  Object.freeze({
    name: '006_family_child_presentation.sql',
    sha256: 'd90e02313090e70002a5fccb07521adc789841a0ddc428541469245f5990af4c',
  }),
  Object.freeze({
    name: '007_device_telemetry.sql',
    sha256: '0b6aa7c741ba6b8abf00ad1a3d81edd34615486b1687e8e662867d5b48df798e',
  }),
  Object.freeze({
    name: '008_native_device_pairing.sql',
    sha256: '7685932c64f70e7f5e4e9bf63c728cbb36d56bfc8c3568e00c61283a5d75edb1',
  }),
  Object.freeze({
    name: '100_ai_events.sql',
    sha256: '3ce4d797a6903fc4fc565953e37abc667fc31ce6b812cf7dd1bf2f2a39409d81',
  }),
  Object.freeze({
    name: '101_device_lifecycle.sql',
    sha256: '8fcc436a1aa7d9c49bc22bce43b1a9d60dc6c37484a5a03ce9cd665581f7cab2',
  }),
  Object.freeze({
    name: '102_safe_zones.sql',
    sha256: '1c82191b42cb954b7f79044247e4646d8d3551ebcc116adaaf4a9cfe56d9fef3',
  }),
  Object.freeze({
    name: '103_location_stream.sql',
    sha256: 'fe479db93338016b3dc247de083999cd84bf663d88bd845364a05273bd541419',
  }),
  Object.freeze({
    name: '104_sos_emergency.sql',
    sha256: 'b1fd0da1d511fadcde2c2449129633a6fd6ded0421deef3ae4b7c8abc2112e9a',
  }),
  Object.freeze({
    name: '105_screen_time.sql',
    sha256: 'dc09b4b20804f3d5af37aa9c9742467a607e54c9729834071af74b0f4f72b625',
  }),
]);
