import fs from 'node:fs';
import path from 'node:path';

if (process.argv.length > 2) throw new Error('Release target and storage cannot be overridden from the command line.');
const project = JSON.parse(fs.readFileSync('default.project.json', 'utf8'));
function relocate(node) {
  for (const [key, value] of Object.entries(node)) {
    if (key === '$path') node[key] = `../${value}`;
    else if (value && typeof value === 'object') relocate(value);
  }
}
relocate(project.tree);
project.name = 'ClashOfCivilizationsRelease';
project.servePort = 34878;
project.placeId = 73839918762778;
project.gameId = 10770758443;
project.servePlaceIds = [73839918762778];
const sandbox = { $className: 'Folder' };
for (const name of fs.readdirSync('prototypes/miniature/game/server').filter(name => name.endsWith('.luau')).sort()) {
  if (name === 'Bootstrap.server.luau') continue;
  if (name.endsWith('.server.luau') || name.endsWith('.client.luau')) throw new Error(`Unreviewed release entrypoint: ${name}`);
  sandbox[name.replace(/\.luau$/, '')] = { $path: `../prototypes/miniature/game/server/${name}` };
}
sandbox.Bootstrap = { $path: '../prototypes/miniature/release/Bootstrap.server.luau' };
project.tree.ServerScriptService = { $className: 'ServerScriptService', Sandbox: sandbox };
delete project.tree.ServerStorage.FakeProfileStore;
fs.mkdirSync('.cache', { recursive: true });
const target = path.join('.cache', 'miniature-release.project.json');
fs.writeFileSync(target, JSON.stringify(project, null, 2) + '\n');
console.log(`Created ${target}; this generates a target-bound production mapping and does not publish.`);
