// AiEvent v1 — the bounded, append-only fact envelope that every system emits
// from the first day so the intelligence systems (M9) can consume real history
// instead of inventing it later.
//
// The envelope separates two things that must never be confused:
//   * facts observed by the server  -> confidence 1, rejectPath null;
//   * suggestions derived by AI      -> confidence < 1, rejectPath required.
// A suggestion the guardian cannot reject is not admitted anywhere. A fact has
// nothing to reject.
//
// v1 deliberately carries identifiers, a type and an explanation only. It never
// carries free text a child or guardian typed, a token, a payload body or any
// provider response.

export const AI_EVENT_SCHEMA_VERSION = 'ai-event.v1';

// The registered v1 event types. Unknown types are refused rather than stored,
// so the fact store cannot silently accumulate unreviewed claims.
const AI_EVENT_REGISTRY = Object.freeze({
  'family.child.created': Object.freeze({
    source: 'server',
    confidence: 1,
    explanation: 'A primary guardian created a child profile for this family.',
    rejectPath: null,
  }),
  'device.registered': Object.freeze({
    source: 'server',
    confidence: 1,
    explanation: 'A guardian added a device record for a child in this family.',
    rejectPath: null,
  }),
  'device.paired': Object.freeze({
    source: 'server',
    confidence: 1,
    explanation:
      'A handset claimed a one-time pairing code, so the device can now report its state.',
    rejectPath: null,
  }),
  'device.revoked': Object.freeze({
    source: 'server',
    confidence: 1,
    explanation:
      'A guardian cut this device off, and its credential can no longer be used.',
    rejectPath: null,
  }),
  // Telemetry heartbeats are deliberately NOT events. A device reporting every
  // few minutes would bury the facts that matter under its own pulse, and the
  // latest reading already lives on the device row. What belongs on a timeline is
  // a change in condition, which is why pairing and revocation are here and a
  // heartbeat is not.
});

export const AI_EVENT_TYPES = Object.freeze(
  Object.keys(AI_EVENT_REGISTRY),
);

export function isKnownAiEventType(eventType) {
  return (
    typeof eventType === 'string' &&
    Object.prototype.hasOwnProperty.call(AI_EVENT_REGISTRY, eventType)
  );
}

export function aiEventDefinition(eventType) {
  if (!isKnownAiEventType(eventType)) {
    throw new TypeError(`Unregistered AiEvent type: ${String(eventType)}`);
  }
  return AI_EVENT_REGISTRY[eventType];
}

/**
 * Builds the durable envelope stored for one observed fact.
 *
 * `occurredAt` is assigned by the database when it is omitted, so a caller can
 * never backdate or fabricate observation time.
 */
export function buildAiEvent({
  eventType,
  familyId,
  childId = null,
  deviceId = null,
  policyVersion,
  correlationId,
}) {
  const definition = aiEventDefinition(eventType);
  return Object.freeze({
    schemaVersion: AI_EVENT_SCHEMA_VERSION,
    eventType,
    familyId,
    childId,
    deviceId,
    policyVersion,
    source: definition.source,
    confidence: definition.confidence,
    explanation: definition.explanation,
    rejectPath: definition.rejectPath,
    correlationId,
  });
}

export function aiEventView(row) {
  return {
    id: row.id,
    schemaVersion: row.schema_version,
    eventType: row.event_type,
    familyId: row.family_id,
    childId: row.child_id,
    deviceId: row.device_id,
    policyVersion: row.policy_version,
    source: row.source,
    confidence: Number(row.confidence),
    explanation: row.explanation,
    rejectPath: row.reject_path,
    occurredAt: row.occurred_at,
  };
}
