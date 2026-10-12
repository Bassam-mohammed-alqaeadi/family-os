// The outbox event vocabulary is closed: adding a server event without deciding whether it may
// notify a family is a build failure, not a silent push leak.
import assert from 'node:assert/strict';
import { readdirSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';
import {
  ALERT_COPY,
  AUDIT_ONLY_REASONS,
  NOTIFY_TYPES,
} from '../src/notification-dispatcher.js';

const here = dirname(fileURLToPath(import.meta.url));
const sourceRoot = join(here, '..', 'src');
const EVENT_TYPE = /^(?:family|device|command|guardian_transfer)\.[A-Za-z0-9_.-]+$/;

function javascriptFiles(directory) {
  const files = [];
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) files.push(...javascriptFiles(path));
    else if (entry.isFile() && entry.name.endsWith('.js') && entry.name !== 'notification-dispatcher.js') files.push(path);
  }
  return files;
}

function quotedEventTypes(expression) {
  const events = new Set();
  const quoted = /'([^'\\]*(?:\\.[^'\\]*)*)'|"([^"\\]*(?:\\.[^"\\]*)*)"|`([^`\\]*(?:\\.[^`\\]*)*)`/g;
  for (const match of expression.matchAll(quoted)) {
    const value = match[1] ?? match[2] ?? match[3];
    if (EVENT_TYPE.test(value)) events.add(value);
  }
  return events;
}

function sourceEventTypes() {
  const events = new Set();
  for (const path of javascriptFiles(sourceRoot)) {
    const source = readFileSync(path, 'utf8');
    // Object-literal eventType arguments, including the two arms of ternary event choices.
    const eventProperty = /\beventType\s*:\s*([\s\S]{0,260}?)(?=,\s*[A-Za-z_$][\w$]*\s*:|,\s*\n\s*[})])/g;
    for (const match of source.matchAll(eventProperty)) {
      for (const event of quotedEventTypes(match[1])) events.add(event);
    }
    // Some operations select one of two event literals into a local `eventType` first.
    const eventAssignment = /\b(?:const|let|var)\s+eventType\s*=\s*([\s\S]{0,360}?);/g;
    for (const match of source.matchAll(eventAssignment)) {
      for (const event of quotedEventTypes(match[1])) events.add(event);
    }
    // A few audit-only rows are written as SQL literals, not JS object properties.
    const eventInSql = /\bevent_type\b[\s\S]{0,240}?['\"]((?:family|device|command|guardian_transfer)\.[A-Za-z0-9_.-]+)['\"]/gi;
    for (const match of source.matchAll(eventInSql)) events.add(match[1]);
  }
  return events;
}

const sourceEvents = sourceEventTypes();

test('every server eventType literal is classified exactly once', () => {
  const classified = new Set([...Object.keys(NOTIFY_TYPES), ...Object.keys(AUDIT_ONLY_REASONS)]);
  const unclassified = [...sourceEvents].filter((event) => !classified.has(event)).sort();
  const stale = [...classified].filter((event) => !sourceEvents.has(event)).sort();
  assert.deepEqual(unclassified, [], `unclassified server eventType literals: ${unclassified.join(', ')}`);
  assert.deepEqual(stale, [], `classification keys with no server eventType source: ${stale.join(', ')}`);
});

test('every NOTIFY_TYPES key occurs as an actual server eventType literal', () => {
  assert.deepEqual(Object.keys(NOTIFY_TYPES).sort(), [...sourceEvents]
    .filter((event) => Object.hasOwn(NOTIFY_TYPES, event)).sort());
  for (const [eventType, definition] of Object.entries(NOTIFY_TYPES)) {
    assert.ok(sourceEvents.has(eventType), `${eventType} must be emitted by server code`);
    assert.ok(Object.hasOwn(ALERT_COPY, definition.copyKey), `${eventType} copy key must exist`);
  }
});

test('every AUDIT_ONLY_REASONS key occurs in server code and has an explicit reason', () => {
  for (const [eventType, reason] of Object.entries(AUDIT_ONLY_REASONS)) {
    assert.ok(sourceEvents.has(eventType), `${eventType} must be emitted by server code`);
    assert.ok(typeof reason === 'string' && reason.length > 0, `${eventType} needs a skip reason`);
  }
});

test('notification and audit-only classifications are disjoint and only four types notify', () => {
  assert.equal(Object.keys(NOTIFY_TYPES).length, 4);
  assert.deepEqual(
    Object.keys(NOTIFY_TYPES).filter((event) => Object.hasOwn(AUDIT_ONLY_REASONS, event)),
    [],
  );
  assert.deepEqual([...Object.keys(NOTIFY_TYPES)].map((event) => NOTIFY_TYPES[event].copyKey).sort(),
    ['geofence.entered', 'geofence.exited', 'protection.reported', 'sos.raised'].sort());
});
