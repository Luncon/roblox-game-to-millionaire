import assert from 'node:assert/strict';
import test from 'node:test';
import { runTool } from '../dev-tools.mjs';

test('source fingerprint canonicalizes only zero-valued CFrame tokens', () => {
  const result = runTool('lune', ['run', '.lune/template-fingerprint.luau']);
  assert.equal(result.status, 0);
});
