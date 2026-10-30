// Explicit opt-in download; npm installation hooks remain disabled.
import fs from 'node:fs';
import path from 'node:path';
import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { tools, platform, toolPath, runTool } from './dev-tools.mjs';

for (const [name, tool] of Object.entries(tools)) {
  const asset = tool.assets[platform];
  if (!asset) throw new Error(`No reviewed ${name} binary for ${platform}. See docs/SETUP.md.`);
  const executable = toolPath(name);
  if (!fs.existsSync(executable)) {
    console.log(`Downloading ${name} ${tool.version} for ${platform}`);
    const response = await fetch(asset.url, { signal: AbortSignal.timeout(120_000) });
    if (!response.ok) throw new Error(`${asset.url}: HTTP ${response.status}`);
    const archive = Buffer.from(await response.arrayBuffer());
    if (createHash('sha256').update(archive).digest('hex') !== asset.sha256) {
      throw new Error(`${name}: release archive SHA-256 mismatch`);
    }
    const directory = path.dirname(executable);
    fs.mkdirSync(directory, { recursive: true });
    const zip = path.join(directory, 'release.zip');
    fs.writeFileSync(zip, archive);
    const result = process.platform === 'win32'
      ? spawnSync('powershell.exe', ['-NoProfile', '-NonInteractive', '-Command',
        'Expand-Archive -LiteralPath $env:DEV_TOOL_ARCHIVE -DestinationPath $env:DEV_TOOL_DESTINATION -Force'],
      { stdio: 'inherit', env: { ...process.env, DEV_TOOL_ARCHIVE: zip, DEV_TOOL_DESTINATION: directory } })
      : spawnSync('unzip', ['-o', zip, name, '-d', directory], { stdio: 'inherit' });
    if (result.error) throw result.error;
    if (result.status !== 0) throw new Error(`${name}: extraction failed (install unzip on WSL/Linux)`);
    fs.chmodSync(executable, 0o755);
    fs.unlinkSync(zip);
  }
  const result = runTool(name, ['--version'], { encoding: 'utf8', stdio: 'pipe' });
  if (result.status !== 0 || result.stdout.trim() !== `${name} ${tool.version}`) {
    throw new Error(`${name}: installed binary does not match pinned version ${tool.version}`);
  }
  console.log(result.stdout.trim());
}
