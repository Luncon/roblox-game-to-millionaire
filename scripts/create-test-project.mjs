import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const outputDirectory = path.join(root, '.cache');
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
project.name += 'Tests';
project.tree.ReplicatedStorage.ClientTests = { $path: '../tests/client-runtime' };
project.tree.ServerStorage = {
  ...project.tree.ServerStorage,
  $className: 'ServerStorage',
  Tests: { $path: '../tests/specs' },
  RuntimeTests: { $path: '../tests/runtime' },
};
project.tree.ServerScriptService.Game.Bootstrap = { $path: '../tests/TestBootstrap.server.luau' };
project.tree.ServerScriptService.MultiplayerTests = { $path: '../tests/multiplayer/Server.server.luau' };
project.tree.ServerScriptService.ArmyMultiplayerTests = { $path: '../tests/multiplayer/Army.server.luau' };
project.tree.ServerScriptService.ProgressionTests = { $path: '../tests/multiplayer/Progression.server.luau' };
project.tree.ServerScriptService.PersistenceTests = { $path: '../tests/multiplayer/Persistence.server.luau' };
project.tree.ServerScriptService.FullServerTests = { $path: '../tests/multiplayer/FullServer.server.luau' };
project.tree.StarterPlayer.StarterPlayerScripts.MultiplayerTests = { $path: '../tests/multiplayer/Client.client.luau' };
fs.mkdirSync(outputDirectory, { recursive: true });
fs.mkdirSync(path.join(root, 'build'), { recursive: true });
fs.writeFileSync(path.join(outputDirectory, 'test.project.json'), JSON.stringify(project, null, 2) + '\n');
console.log('Created .cache/test.project.json; build it with Rojo to run the Studio tests.');
