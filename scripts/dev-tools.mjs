import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

export const root = fileURLToPath(new URL('../', import.meta.url));
export const platform = `${process.platform}-${process.arch}`;
export const tools = JSON.parse(fs.readFileSync(new URL('../dev-tools.lock.json', import.meta.url), 'utf8'));

export function toolPath(name) {
  return path.join(root, '.cache', 'dev-tools', platform, name, tools[name].version,
    name + (process.platform === 'win32' ? '.exe' : ''));
}

export function runTool(name, args, options = {}) {
  const executable = toolPath(name);
  if (!fs.existsSync(executable)) {
    throw new Error(`${name} ${tools[name].version} is missing. Run npm run setup:tools first.`);
  }
  const result = spawnSync(executable, args, { cwd: root, stdio: 'inherit', ...options });
  if (result.error) throw result.error;
  return result;
}
