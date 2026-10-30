import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

export function selectLuauFiles({ cwd = process.cwd(), base = 'HEAD', all = false } = {}) {
  const roots = ['src', 'tests', 'prototypes/miniature', '.lune'];
  const git = (...args) => execFileSync('git', args, { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] })
    .split('\0').filter(Boolean);
  const tracked = all
    ? git('ls-files', '-z', '--', ...roots)
    : git('diff', '--name-only', '--diff-filter=ACMR', '-z', base, '--', ...roots);
  const untracked = git('ls-files', '--others', '--exclude-standard', '-z', '--', ...roots);
  return [...new Set([...tracked, ...untracked])]
    .filter(file => /\.(lua|luau)$/.test(file) && fs.existsSync(path.join(cwd, file)));
}
