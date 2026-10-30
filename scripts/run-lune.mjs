import { runTool } from './dev-tools.mjs';

const result = runTool('lune', ['run', ...process.argv.slice(2)]);
process.exit(result.status ?? 1);
