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

function fakeClient(rows) {
  const calls = [];
  return {
    calls,
    async query(sql, params) {
      calls.push({ sql, params });
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
  assert.equal(formatNotificationTime('2026-05-10T15:45:00.000Z', 'ar'), '٣:٤٥ م');
});

test('Arabic morning time keeps a leading-zero minute and Arabic AM marker', () => {
  assert.equal(formatNotificationTime('2026-05-10T03:07:00.000Z', 'ar'), '٣:٠٧ ص');
});

test('Arabic noon is rendered as twelve with the PM marker', () => {
  assert.equal(formatNotificationTime('2026-05-10T12:00:00.000Z', 'ar'), '١٢:٠٠ م');
});

test('English time remains readable in 12-hour form', () => {
  assert.equal(formatNotificationTime('2026-05-10T15:45:00.000Z', 'en'), '3:45 PM');
});

test('SOS Arabic copy includes the send-time child name and localized time', () => {
  assert.deepEqual(renderAlertCopy('sos.raised', {
    locale: 'ar', child: 'ليان', time: '2026-05-10T15:45:00Z',
  }), {
    title: 'استغاثة من ليان', body: 'ضغط زر الاستغاثة الساعة ٣:٤٥ م',
  });
  assert.equal(ALERT_COPY['sos.raised'].ar.title, 'استغاثة من {child}');
});

test('geofence English copy resolves both the child and zone placeholders', () => {
  assert.deepEqual(renderAlertCopy('geofence.entered', {
    locale: 'en', child: 'Maya', zone: 'School', time: '2026-05-10T07:05:00Z',
  }), {
    title: 'Maya arrived at School', body: 'Entered the safe zone at 7:05 AM',
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

test('geofence name is resolved at send time while the zone comes from the event payload', async () => {
  const client = fakeClient([{ id: CHILD, display_name: 'عمر' }]);
  const result = await resolveNotificationSubject(client, event('family.geofence_entered', {
    childId: CHILD, zoneId: ZONE, zoneName: 'المدرسة', occurredAt: '2026-05-10T06:20:00Z',
  }));
  assert.equal(result.child, 'عمر');
  assert.equal(result.zone, 'المدرسة');
  assert.equal(result.zoneId, ZONE);
  assert.deepEqual(client.calls[0].params, [FAMILY, CHILD]);
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
      childId: CHILD, zoneId: ZONE, zoneName: 'Home', occurredAt: '2026-05-10T06:20:00Z',
    })),
    /notification_subject_unavailable/,
  );
});
