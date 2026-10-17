import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const outputDirectory = path.join(root, '.cache');
const solo = process.argv.includes('--solo');
const localPlaytest = process.argv.includes('--local-playtest');
const development = process.argv.includes('--development');
const expansion = process.argv.includes('--expansion');
const neutral = process.argv.includes('--neutral');
const training = process.argv.includes('--training');
const farmers = process.argv.includes('--farmers');
const combat = process.argv.includes('--combat');
const geometry = process.argv.includes('--geometry');
const medical = process.argv.includes('--medical');
const skills = process.argv.includes('--skills');
if (localPlaytest && [solo, development, expansion, neutral, training, farmers, combat, geometry, skills, medical].some(Boolean)) throw new Error('--local-playtest must run by itself');
if (development && !solo) throw new Error('--development requires --solo');
if (expansion && !solo) throw new Error('--expansion requires --solo');
if (neutral && !solo) throw new Error('--neutral requires --solo');
if (training && !solo) throw new Error('--training requires --solo');
if (farmers && !solo) throw new Error('--farmers requires --solo');
if (combat && !solo) throw new Error('--combat requires --solo');
if (geometry && !solo) throw new Error('--geometry requires --solo');
if (medical && !solo) throw new Error('--medical requires --solo');
if (skills && !solo) throw new Error('--skills requires --solo');
if ([development, expansion, neutral, training, farmers, combat, geometry, skills, medical].filter(Boolean).length > 1) throw new Error('Choose --development, --expansion, --neutral, --training, --farmers, --combat, --geometry, --skills or --medical');
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
project.name += localPlaytest ? 'LocalPlaytest' : solo ? 'SoloTests' : 'Tests';
if (!localPlaytest) {
project.tree.ReplicatedStorage.ClientTests = { $path: '../tests/client-runtime' };
project.tree.ServerStorage = {
  ...project.tree.ServerStorage,
  $className: 'ServerStorage',
  Tests: { $path: '../tests/specs' },
  RuntimeTests: { $path: '../tests/runtime' },
};
}
// Explicit children avoid Rojo keeping the folder-discovered production bootstrap
// alongside the test override as a second Script with the same name.
const serverDirectory = path.join(root, 'src/server');
project.tree.ServerScriptService.Game = { $className: 'Folder' };
for (const name of fs.readdirSync(serverDirectory)) {
  if (!name.endsWith('.luau') || name === 'Bootstrap.server.luau') continue;
  const instanceName = name.replace(/(?:\.server|\.client)?\.luau$/, '');
  project.tree.ServerScriptService.Game[instanceName] = { $path: `../src/server/${name}` };
}
project.tree.ServerScriptService.Game.Bootstrap = { $path: localPlaytest ? '../tests/LocalPlaytest.server.luau' : solo ? '../tests/SoloBootstrap.server.luau' : '../tests/TestBootstrap.server.luau' };
if (localPlaytest) {
  project.tree.ServerScriptService.Game.FakeProfileStore = { $path: '../tests/runtime/FakeProfileStore.luau' };
} else if (solo) {
  const runner = medical ? 'SoloMedicalSupport' : geometry ? 'SoloSettlementGeometry' : skills ? 'SoloWeaponSkills' : combat ? 'SoloTacticalCombat' : farmers ? 'SoloFarmTenders' : training ? 'SoloTrainingCamp' : neutral ? 'SoloNeutralOpponents' : expansion ? 'SoloEconomyExpansion' : development ? 'SoloSettlementDevelopment' : 'SoloWorldGrowth';
  project.tree.ServerScriptService[`${runner}Tests`] = { $path: `../tests/${runner}.server.luau` };
} else {
project.tree.ServerScriptService.MedicalMultiplayerTests = { $path: '../tests/multiplayer/MedicalSupport.server.luau' };
project.tree.ServerScriptService.TacticalCombatMultiplayerTests = { $path: '../tests/multiplayer/TacticalCombat.server.luau' };
project.tree.ServerScriptService.MultiplayerTests = { $path: '../tests/multiplayer/Server.server.luau' };
project.tree.ServerScriptService.ArmyMultiplayerTests = { $path: '../tests/multiplayer/Army.server.luau' };
project.tree.ServerScriptService.ProgressionTests = { $path: '../tests/multiplayer/Progression.server.luau' };
project.tree.ServerScriptService.PersistenceTests = { $path: '../tests/multiplayer/Persistence.server.luau' };
project.tree.ServerScriptService.WorldGrowthTests = { $path: '../tests/multiplayer/WorldGrowth.server.luau' };
project.tree.ServerScriptService.FullServerTests = { $path: '../tests/multiplayer/FullServer.server.luau' };
}
if (!localPlaytest) project.tree.StarterPlayer.StarterPlayerScripts.MultiplayerTests = { $path: '../tests/multiplayer/Client.client.luau' };
fs.mkdirSync(outputDirectory, { recursive: true });
fs.mkdirSync(path.join(root, 'build'), { recursive: true });
const outputName = localPlaytest ? 'local-playtest.project.json' : solo ? 'solo-test.project.json' : 'test.project.json';
fs.writeFileSync(path.join(outputDirectory, outputName), JSON.stringify(project, null, 2) + '\n');
console.log(`Created .cache/${outputName}; build it with Rojo to run the Studio tests.`);
