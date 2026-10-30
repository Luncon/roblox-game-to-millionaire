import fs from 'node:fs';
import path from 'node:path';

const args = process.argv.slice(2);
if (args.length > 1 || args.some(arg => arg !== '--visible')) throw new Error('Only --visible is supported; no funding or storage modes.');
const visible = args.includes('--visible');
const project = JSON.parse(fs.readFileSync('miniature-playtest.project.json', 'utf8'));
function relocate(node) {
  for (const [key, value] of Object.entries(node)) {
    if (key === '$path') node[key] = `../${value}`;
    else if (value && typeof value === 'object') relocate(value);
  }
}
relocate(project.tree);
project.name = visible ? 'ClashOfCivilizationsThreePlayerVisibleTest' : 'ClashOfCivilizationsThreePlayerTest';
project.servePort = visible ? 34877 : 34876;
// Directory overlays are additive in Rojo. Enumerate modules so the ordinary
// Bootstrap is replaced, rather than retained beside the funded test entrypoint.
const sandbox = { $className: 'Folder' };
for (const name of fs.readdirSync('prototypes/miniature/game/server').filter(name => name.endsWith('.luau')).sort()) {
  const instanceName = name.replace(/(?:\.server|\.client)?\.luau$/, '');
  sandbox[instanceName] = { $path: `../prototypes/miniature/game/server/${name}` };
}
sandbox.Bootstrap = { $path: '../tests/miniature-multiplayer/Bootstrap.server.luau' };
project.tree.ServerScriptService = {
  $className: 'ServerScriptService',
  Sandbox: sandbox,
  ThreePlayerCoordinator: { $path: '../tests/miniature-multiplayer/Coordinator.server.luau' },
};
if (visible) project.tree.ServerScriptService.ThreePlayerCoordinator.$attributes = { VisibleRun: true };
project.tree.ServerStorage.ThreePlayerContext = { $path: '../tests/miniature-multiplayer/Context.luau' };
project.tree.StarterPlayer.StarterPlayerScripts.ThreePlayerBot = { $path: '../tests/miniature-multiplayer/Client.client.luau' };
fs.mkdirSync('.cache', { recursive: true });
const target = path.join('.cache', visible ? 'miniature-three-player-visible.project.json' : 'miniature-three-player.project.json');
fs.writeFileSync(target, JSON.stringify(project, null, 2) + '\n');
console.log(`Created ${target}; build a dedicated place and run the isolated three-client Studio test.`);
