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
  Object.freeze({
    name: '106_web_filter.sql',
    sha256: '7e5ddc587f8b2f34bbf6594e67e9440550d34c388f0ff8ec338d0646494573eb',
  }),
  Object.freeze({
    name: '107_family_tasks.sql',
    sha256: 'e9e0f81c3aae3e761511724f6a4fd90b344d35af8cf9e6c7b84132e6476eafb9',
  }),
  Object.freeze({
    name: '108_family_calendar.sql',
    sha256: '875fb31c1886c39c73d9d6d28a8c0dd7747e306fe07d179d8f4aae5941e7aa8a',
  }),
  Object.freeze({
    name: '109_family_chat.sql',
    sha256: 'e08b2672b3b9bb98849c93662d68fb05d65dc03000acdac476ba2e0aaf1a1c2e',
  }),
  Object.freeze({
    name: '110_collaboration_flexibility.sql',
    sha256: '9ee7e4a5023703a6acb35b48771d97693766b8de96b776fdf5bff748cecd6c2b',
  }),
  Object.freeze({
    name: '111_collaboration_audiences.sql',
    sha256: '0a75b5153954bd6523c544bb3f0df0bd3e51041afaa263b93b90bfcc60dfa88d',
  }),
  Object.freeze({
    name: '112_family_chat_realtime_media.sql',
    sha256: '93a85730a6504143abbc08085f87c7ea61572508fc6281468f8b93d6d4cd5036',
  }),
  Object.freeze({
    name: '113_family_push_registrations.sql',
    sha256: 'b89330a5ae113a85d6fbb4830878d87200a2563c55ef8519963bed9c8c2f5f5b',
  }),
  Object.freeze({
    name: '114_child_consents.sql',
    sha256: '14607d83a8537c0ebb39d09cb0b15acf27294ae7fa4e1ff3470b971547f0be31',
  }),
  Object.freeze({
    name: '115_family_invite_codes.sql',
    sha256: '08a971388e6e66d359424500ac69e3ea375963c309532af87b77b53815196006',
  }),
  Object.freeze({
    name: '116_location_retention_erasure.sql',
    sha256: 'c244cb7bb986f6e16f27606f7b984cd27361dd43b23fafb001a8cf95654dcfaa',
  }),
  Object.freeze({
    name: '117_device_capabilities.sql',
    sha256: 'ac2fb338f0b35fb68ce1cfafd526b91ca1b58102abf60d51a95931b08cafc5ac',
  }),
  Object.freeze({
    name: '118_command_lifecycle.sql',
    sha256: '79cbe3a16da8cb423ff1b0ba84b83a84c752bce66b6b182a9e20700ec10bf34e',
  }),
  Object.freeze({
    name: '119_ai_events_security_envelope.sql',
    sha256: 'c323657db99429062c5816bfcbc1caf11129141515b85c51cdd1a198e67fe6a7',
  }),
  Object.freeze({
    name: '120_device_push_registrations.sql',
    sha256: '88490bc254a7d99d721c7161c9eb19b0ba61966f33e09e9b7b102be281e3b9ec',
  }),
  Object.freeze({
    name: '121_delivery_states.sql',
    sha256: '8c837d61fbf7293b2ec7e7fb1fadb3343d8dbc1d03e3c043581d93312d63dc7c',
  }),
  Object.freeze({
    name: '122_family_notification_preferences.sql',
    sha256: '860c3244e753d31b640a14b99d234de6b429b52587c5b1ee49cd205a4d502789',
  }),
  Object.freeze({
    name: '123_notification_retries.sql',
    sha256: 'ccd21d6ae27b8c3d3c81a8fc57070171d5419bbe9024e9e6fe4a8b475bdaea48',
  }),
  Object.freeze({
    name: '124_geofence_notification_payload_minimization.sql',
    sha256: '44929dc7031ad3bc7614b6613f41c3e0cf331cebcb0e745eb507ed1e44e6c114',
  }),
  Object.freeze({
    name: '130_family_minutes_ledger.sql',
    sha256: '65d4f3b7e1b3633bc253bc297bea4ad5beb5b3c18fa638483358417886c08111',
  }),
  Object.freeze({
    name: '131_family_app_wallets.sql',
    sha256: 'fa8ac4b4f885cd8ab12a0221e0817c9a742dc9643fe64845a845a580ad1de01e',
  }),
  Object.freeze({
    name: '132_point_ledger_to_minutes.sql',
    sha256: '21d9c7efdd1ee192a80646d5d243752be8adc486fd1581d1c8ffcfee0b7ee77b',
  }),
  Object.freeze({
    name: '133_screen_time_earned_minutes_switch.sql',
    sha256: '6ee81d4dd4bde665267c707991f7f3148744541b770b51cd1ca0adf419d2b830',
  }),
  Object.freeze({
    name: '134_usage_consumption_ledger_shape.sql',
    sha256: '8b39d4cb82b16b0e91ecad0096fcc7866d8570d6a7d9270de3ede4f783b259d5',
  }),
  Object.freeze({
    name: '135_family_customization_profile.sql',
    sha256: 'd8ac5120899c4885c491c325ad0221d6c460baf18920b5f8f3164c1fac7c5f0f',
  }),
  Object.freeze({
    name: '136_notification_delivery_gating.sql',
    sha256: '3d92908dec6d937fcad8f69395924fb104a26d8b2e6e8a903fab53d85aeca889',
  }),
]);
