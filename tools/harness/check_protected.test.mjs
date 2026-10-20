import assert from 'node:assert/strict';
import test from 'node:test';
import { runCheckProtected } from './check_protected.mjs';

test('check_protected function is exported and returns verification object', () => {
  const result = runCheckProtected({ baseRef: 'HEAD' });
  assert.equal(typeof result, 'object');
  assert.equal(typeof result.success, 'boolean');
  assert.ok(Array.isArray(result.unrecordedSystems));
  assert.ok(Array.isArray(result.testsToRun));
});
