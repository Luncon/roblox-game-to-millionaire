import assert from 'node:assert/strict';
import { test } from 'node:test';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { runTool } from '../dev-tools.mjs';

test('native tools reject lint, formatting, syntax and runtime failures', t => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'luau-tools-'));
  t.after(() => fs.rmSync(directory, { recursive: true, force: true }));
  const file = path.join(directory, 'failure.luau');
  const run = (tool, args) => runTool(tool, args, { stdio: 'pipe', encoding: 'utf8' });

  fs.writeFileSync(file, 'return missing_global\n');
  assert.notEqual(run('selene', [file]).status, 0, 'lint errors must fail');
  fs.writeFileSync(file, 'local value={answer=42};return value\n');
  assert.notEqual(run('stylua', ['--check', file]).status, 0, 'format drift must fail');
  assert.equal(run('stylua', ['--verify', file]).status, 0);
  assert.equal(run('stylua', ['--check', file]).status, 0);
  fs.writeFileSync(file, 'local =\n');
  assert.notEqual(run('lune', ['run', file]).status, 0, 'syntax errors must fail');
  fs.writeFileSync(file, 'error("intentional fixture failure")\n');
  const failure = run('lune', ['run', file]);
  assert.notEqual(failure.status, 0, 'failed assertions must fail the test process');
  assert.match(failure.stdout + failure.stderr, /intentional fixture failure/);
});
