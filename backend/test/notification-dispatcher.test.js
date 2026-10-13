import assert from 'node:assert/strict';
import test from 'node:test';
import {
  ALERT_COPY,
  classifyNotificationEvent,
  formatNotificationTime,
  renderAlertCopy,
  resolveNotificationSubject,
} from '../src/notification-dispatcher.js';

const FAMILY = 'aaaaaaaa-1111-4111-8111-111111111111';
const CHILD = 'bbbbbbbb-2222-4222-8222-222222222222';
const DEVICE = 'cccccccc-3333-4333-8333-333333333333';
const ALERT = 'dddddddd-4444-4444-8444-444444444444';
const ZONE = 'eeeeeeee-5555-4555-8555-555555555555';

function fakeClient(rowsOrResolver) {
  const calls = [];
  return {
    calls,
    async query(sql, params) {
      calls.push({ sql, params });
      const rows = typeof rowsOrResolver === 'function' ? rowsOrResolver(sql, params) : rowsOrResolver;
      return { rows };
    },
  };
}

function event(eventType, payload = {}) {
  return { event_type: eventType, aggregate_id: FAMILY, payload };
}

test('SOS is classified as an urgent notify event with its reviewed copy key', () => {
  const result = classifyNotificationEvent('family.sos_alert_raised');
  assert.equal(result.kind, 'notify');
  assert.deepEqual(result.type, {
    copyKey: 'sos.raised', subject: 'child', channelId: 'familyos_sos_alerts', ttlSeconds: 3600, urgency: 'alert',
  });
});

test('geofence entry uses the entry copy and high-priority family zone channel', () => {
  const result = classifyNotificationEvent('family.geofence_entered');
  assert.equal(result.type.copyKey, 'geofence.entered');
  assert.equal(result.type.subject, 'child');
  assert.equal(result.type.channelId, 'familyos_geofence_alerts');
  assert.equal(result.type.ttlSeconds, 1800);
  assert.equal(result.type.urgency, 'alert');
});

test('geofence exit remains a distinct, classified event', () => {
  assert.equal(classifyNotificationEvent('family.geofence_exited').type.copyKey, 'geofence.exited');
});

test('protection reports are high priority without claiming an SOS alert', () => {
  const result = classifyNotificationEvent('family.device_protection_reported');
  assert.equal(result.type.copyKey, 'protection.reported');
  assert.equal(result.type.subject, 'device');
  assert.equal(result.type.channelId, 'familyos_protection_alerts');
  assert.equal(result.type.urgency, 'high');
  assert.deepEqual(renderAlertCopy('protection.reported', {
    locale: 'en', child: 'Maya', time: '2026-05-10T07:05:00Z',
  }), {
    title: 'Maya’s protection needs attention',
    body: 'The device reported a protection concern at 7:05 AM UTC',
  });
});

test('chat message stays with the existing nudger', () => {
  assert.deepEqual(classifyNotificationEvent('family.chat_message_sent'), {
    kind: 'skip', reason: 'chat_nudge_existing_nudger',
  });
});

test('known non-notification audit events are explicitly skipped', () => {
  assert.deepEqual(classifyNotificationEvent('family.child_archived'), {
    kind: 'skip', reason: 'audit_only',
  });
});

test('an event outside both closed vocabularies fails closed', () => {
  assert.throws(() => classifyNotificationEvent('family.future_event'), /unclassified_outbox_event_type/);
});

test('Arabic time is 12-hour and uses Arabic-Indic digits', () => {
  assert.equal(formatNotificationTime('2026-05-10T15:45:00.000Z', 'ar'), '٣:٤٥ م بتوقيت UTC');
});

test('Arabic morning time keeps a leading-zero minute and Arabic AM marker', () => {
  assert.equal(formatNotificationTime('2026-05-10T03:07:00.000Z', 'ar'), '٣:٠٧ ص بتوقيت UTC');
});

test('Arabic noon is rendered as twelve with the PM marker', () => {
  assert.equal(formatNotificationTime('2026-05-10T12:00:00.000Z', 'ar'), '١٢:٠٠ م بتوقيت UTC');
});

test('English time remains readable in 12-hour form', () => {
  assert.equal(formatNotificationTime('2026-05-10T15:45:00.000Z', 'en'), '3:45 PM UTC');
});

test('SOS Arabic copy includes the send-time child name and localized time', () => {
  assert.deepEqual(renderAlertCopy('sos.raised', {
    locale: 'ar', child: 'ليان', time: '2026-05-10T15:45:00Z',
  }), {
    title: 'استغاثة من ليان', body: 'ضغط زر الاستغاثة الساعة ٣:٤٥ م بتوقيت UTC',
  });
  assert.equal(ALERT_COPY['sos.raised'].ar.title, 'استغاثة من {child}');
});

test('geofence English copy resolves both the child and zone placeholders', () => {
  assert.deepEqual(renderAlertCopy('geofence.entered', {
    locale: 'en', child: 'Maya', zone: 'School', time: '2026-05-10T07:05:00Z',
  }), {
    title: 'Maya arrived at School', body: 'Entered the safe zone at 7:05 AM UTC',
  });
});

test('SOS resolves child name and pressed time from the SOS and child tables, not payload', async () => {
  const client = fakeClient([{ alert_id: ALERT, child_id: CHILD, occurred_at: '2026-05-10T15:45:00Z', display_name: 'ليان' }]);
  const result = await resolveNotificationSubject(client, event('family.sos_alert_raised', {
    subjectId: ALERT,
  }));
  assert.equal(result.child, 'ليان');
  assert.equal(result.childId, CHILD);
  assert.equal(result.alertId, ALERT);
  assert.equal(result.occurredAt, '2026-05-10T15:45:00Z');
  assert.deepEqual(client.calls[0].params, [FAMILY, ALERT]);
  assert.match(client.calls[0].sql, /FROM family_sos_alerts/);
  assert.match(client.calls[0].sql, /family_children/);
});

test('geofence child and zone labels are resolved from current family rows at dispatch', async () => {
  const client = fakeClient((sql) => (sql.includes('family_safe_zones')
    ? [{ name: 'المدرسة' }]
    : [{ id: CHILD, display_name: 'عمر' }]));
  const result = await resolveNotificationSubject(client, event('family.geofence_entered', {
    childId: CHILD, zoneId: ZONE, occurredAt: '2026-05-10T06:20:00Z',
  }));
  assert.equal(result.child, 'عمر');
  assert.equal(result.zone, 'المدرسة');
  assert.equal(result.zoneId, ZONE);
  assert.deepEqual(client.calls[0].params, [FAMILY, CHILD]);
  assert.deepEqual(client.calls[1].params, [FAMILY, ZONE]);
  assert.match(client.calls[1].sql, /family_safe_zones/);
  assert.match(client.calls[1].sql, /archived_at IS NULL/);
});

test('a missing or archived safe zone falls back to a generic localized label', async () => {
  const client = fakeClient((sql) => (sql.includes('family_safe_zones')
    ? []
    : [{ id: CHILD, display_name: 'Maya' }]));
  const subject = await resolveNotificationSubject(client, event('family.geofence_exited', {
    childId: CHILD, zoneId: ZONE, occurredAt: '2026-05-10T06:20:00Z',
  }));
  assert.equal(subject.zone, null);
  assert.deepEqual(renderAlertCopy('geofence.exited', {
    locale: 'en', child: subject.child, zone: subject.zone, time: subject.occurredAt,
  }), {
    title: 'Maya left a safe zone',
    body: 'Left the safe zone at 6:20 AM UTC',
  });
});

test('protection resolves device to the current child name from family_child_devices', async () => {
  const client = fakeClient([{ child_id: CHILD, display_name: 'سامي' }]);
  const result = await resolveNotificationSubject(client, event('family.device_protection_reported', {
    deviceId: DEVICE, occurredAt: '2026-05-10T11:00:00Z',
  }));
  assert.equal(result.child, 'سامي');
  assert.equal(result.childId, CHILD);
  assert.equal(result.deviceId, DEVICE);
  assert.match(client.calls[0].sql, /FROM family_child_devices device/);
  assert.deepEqual(client.calls[0].params, [FAMILY, DEVICE]);
});

test('a missing or archived subject fails closed rather than sending a nameless alert', async () => {
  const client = fakeClient([]);
  await assert.rejects(
    resolveNotificationSubject(client, event('family.geofence_exited', {
      childId: CHILD, zoneId: ZONE, occurredAt: '2026-05-10T06:20:00Z',
    })),
    /notification_subject_unavailable/,
  );
});
