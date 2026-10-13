-- Geofence notifications need the child, zone and crossing time. Keep labels and all
-- coordinates out of durable push payloads, including rows written by older releases.
UPDATE outbox_events
   SET payload = jsonb_strip_nulls(jsonb_build_object(
     'childId', payload -> 'childId',
     'zoneId', payload -> 'zoneId',
     'occurredAt', payload -> 'occurredAt'
   ))
 WHERE event_type IN ('family.geofence_entered', 'family.geofence_exited')
   AND jsonb_typeof(payload) = 'object';
