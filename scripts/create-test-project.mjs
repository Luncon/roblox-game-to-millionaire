import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const outputDirectory = path.join(root, '.cache');
const solo = process.argv.includes('--solo');
const development = process.argv.includes('--development');
const expansion = process.argv.includes('--expansion');
const neutral = process.argv.includes('--neutral');
if (development && !solo) throw new Error('--development requires --solo');
if (expansion && !solo) throw new Error('--expansion requires --solo');
if (neutral && !solo) throw new Error('--neutral requires --solo');
if ([development, expansion, neutral].filter(Boolean).length > 1) throw new Error('Choose --development, --expansion or --neutral');
const project = JSON.parse(fs.readFileSync('default.project.json', 'utf8'));

function relocatePaths(instance) {
  for (const [key, value] of Object.entries(instance)) {
    if (key === '$path') {
      instance[key] = path.relative(outputDirectory, path.resolve(root, value)).replaceAll('\\', '/');
    } else if (value && typeof value === 'object') {
      relocatePaths(value);
    }
  }
}

relocatePaths(project.tree);
project.name += solo ? 'SoloTests' : 'Tests';
project.tree.ReplicatedStorage.ClientTests = { $path: '../tests/client-runtime' };
project.tree.ServerStorage = {
  ...project.tree.ServerStorage,
  $className: 'ServerStorage',
  Tests: { $path: '../tests/specs' },
  RuntimeTests: { $path: '../tests/runtime' },
};
// Explicit children avoid Rojo keeping the folder-discovered production bootstrap
// alongside the test override as a second Script with the same name.
const serverDirectory = path.join(root, 'src/server');
project.tree.ServerScriptService.Game = { $className: 'Folder' };
for (const name of fs.readdirSync(serverDirectory)) {
  if (!name.endsWith('.luau') || name === 'Bootstrap.server.luau') continue;
  const instanceName = name.replace(/(?:\.server|\.client)?\.luau$/, '');
  project.tree.ServerScriptService.Game[instanceName] = { $path: `../src/server/${name}` };
}
project.tree.ServerScriptService.Game.Bootstrap = { $path: solo ? '../tests/SoloBootstrap.server.luau' : '../tests/TestBootstrap.server.luau' };
if (solo) {
  const runner = neutral ? 'SoloNeutralOpponents' : expansion ? 'SoloEconomyExpansion' : development ? 'SoloSettlementDevelopment' : 'SoloWorldGrowth';
  project.tree.ServerScriptService[`${runner}Tests`] = { $path: `../tests/${runner}.server.luau` };
} else {
project.tree.ServerScriptService.MultiplayerTests = { $path: '../tests/multiplayer/Server.server.luau' };
project.tree.ServerScriptService.ArmyMultiplayerTests = { $path: '../tests/multiplayer/Army.server.luau' };
project.tree.ServerScriptService.ProgressionTests = { $path: '../tests/multiplayer/Progression.server.luau' };
project.tree.ServerScriptService.PersistenceTests = { $path: '../tests/multiplayer/Persistence.server.luau' };
project.tree.ServerScriptService.WorldGrowthTests = { $path: '../tests/multiplayer/WorldGrowth.server.luau' };
project.tree.ServerScriptService.FullServerTests = { $path: '../tests/multiplayer/FullServer.server.luau' };
}
project.tree.StarterPlayer.StarterPlayerScripts.MultiplayerTests = { $path: '../tests/multiplayer/Client.client.luau' };
fs.mkdirSync(outputDirectory, { recursive: true });
fs.mkdirSync(path.join(root, 'build'), { recursive: true });
const outputName = solo ? 'solo-test.project.json' : 'test.project.json';
fs.writeFileSync(path.join(outputDirectory, outputName), JSON.stringify(project, null, 2) + '\n');
console.log(`Created .cache/${outputName}; build it with Rojo to run the Studio tests.`);
