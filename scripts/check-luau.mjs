import { root, runTool } from './dev-tools.mjs';
import { selectLuauFiles } from './luau-files.mjs';

const [mode, ...args] = process.argv.slice(2);
if (!['lint', 'format:check', 'format'].includes(mode)) {
  throw new Error('Expected lint, format:check or format');
}
if (args.some(arg => arg !== '--all')) throw new Error('Only --all is supported');

const files = selectLuauFiles({ cwd: root, base: process.env.LUAU_CHECK_BASE || 'HEAD', all: args.includes('--all') });
if (files.length === 0) {
  console.log(`No changed Luau files for ${mode}. Use --all for a full scan.`);
} else {
  console.log(`${mode}: ${files.length} Luau files${args.includes('--all') ? '' : ' changed or untracked'}`);
  const tool = mode === 'lint' ? 'selene' : 'stylua';
  const options = mode === 'lint' ? [] : mode === 'format' ? ['--verify'] : ['--check'];
  let status = 0;
  // Bound command length on Windows while retaining each tool's failure status.
  for (let start = 0; start < files.length; start += 40) {
    const result = runTool(tool, [...options, '--', ...files.slice(start, start + 40)]);
    if (result.status !== 0) status = result.status ?? 1;
  }
  process.exitCode = status;
}
