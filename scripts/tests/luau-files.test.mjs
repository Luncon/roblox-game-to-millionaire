import assert from 'node:assert/strict';
import { test } from 'node:test';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { selectLuauFiles } from '../luau-files.mjs';

test('checks staged, unstaged and untracked Luau while excluding deleted, ignored and vendor files', t => {
  const cwd = fs.mkdtempSync(path.join(os.tmpdir(), 'luau-gate-'));
  t.after(() => fs.rmSync(cwd, { recursive: true, force: true }));
  const git = (...args) => execFileSync('git', args, { cwd, stdio: 'pipe' }).toString().trim();
  const write = (file, source = 'return true\n') => {
    fs.mkdirSync(path.dirname(path.join(cwd, file)), { recursive: true });
    fs.writeFileSync(path.join(cwd, file), source);
  };
  git('init');
  write('.gitignore', 'tests/ignored.luau\n');
  for (const file of ['src/clean.luau', 'src/edited.luau', 'tests/deleted.luau',
    'prototypes/miniature/spaced name.luau', 'assets/vendor.luau']) write(file);
  git('add', '.');
  git('-c', 'user.name=Tooling Test', '-c', 'user.email=test@example.invalid', 'commit', '-m', 'Fixture');
  const base = git('rev-parse', 'HEAD');
  write('src/edited.luau', 'return false\n');
  write('tests/staged.luau');
  git('add', 'tests/staged.luau');
  write('prototypes/miniature/spaced name.luau', 'return false\n');
  write('.lune/new.luau');
  write('tests/ignored.luau');
  write('assets/new-vendor.luau');
  write('src/readme.md');
  fs.unlinkSync(path.join(cwd, 'tests/deleted.luau'));
  const expected = ['.lune/new.luau', 'prototypes/miniature/spaced name.luau', 'src/edited.luau', 'tests/staged.luau'];
  assert.deepEqual(selectLuauFiles({ cwd }).sort(), expected);
  assert(!selectLuauFiles({ cwd, all: true }).includes('tests/deleted.luau'));
  git('add', '-A');
  git('-c', 'user.name=Tooling Test', '-c', 'user.email=test@example.invalid', 'commit', '-m', 'Changes');
  assert.deepEqual(selectLuauFiles({ cwd, base }).sort(), expected);
  assert.deepEqual(selectLuauFiles({ cwd }), []);
  assert(selectLuauFiles({ cwd, all: true }).includes('src/clean.luau'));
  assert(!selectLuauFiles({ cwd, all: true }).includes('tests/deleted.luau'));
  assert.throws(() => selectLuauFiles({ cwd, base: 'missing-ref' }));
});
