import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const advanced = process.argv.includes('--advanced');
const services = process.argv.includes('--services');
const shop = process.argv.includes('--shop');
const mounts = process.argv.includes('--mounts');
const review = process.argv.includes('--review');
const research = process.argv.includes('--research');
if (research && [advanced, services, shop, mounts, review].some(Boolean)) throw new Error('--research must run by itself');
if (review && !mounts) throw new Error('--review requires --mounts');
const project = JSON.parse(fs.readFileSync(path.join(root, 'miniature-playtest.project.json'), 'utf8'));
function relocate(node) {
  for (const [key, value] of Object.entries(node)) {
    if (key === '$path') node[key] = `../${value}`;
    else if (value && typeof value === 'object') relocate(value);
  }
}
relocate(project.tree);
project.name += research ? 'ResearchTests' : mounts ? 'MountedTests' : shop ? 'ShopTests' : services ? 'ServicesTests' : advanced ? 'AdvancedTests' : 'Tests';
// A child next to a directory $path is additive in Rojo, even with the same
// name. Enumerate server sources so funded modes replace, rather than duplicate,
// the normal Bootstrap script.
project.tree.ServerScriptService.Sandbox = { $className: 'Folder' };
for (const name of fs.readdirSync('prototypes/miniature/game/server').filter(name => name.endsWith('.luau')).sort()) {
  const instanceName = name.replace(/(?:\.server|\.client)?\.luau$/, '');
  project.tree.ServerScriptService.Sandbox[instanceName] = { $path: `../prototypes/miniature/game/server/${name}` };
}
project.tree.ServerScriptService.IsolationChecks = { $path: '../tests/miniature-game/Isolation.server.luau' };
project.tree.ServerStorage.TemplateFingerprint = { $path: '../tests/miniature/Templates.luau' };
project.tree.ServerStorage.NativeStressChecks = { $path: '../tests/miniature-game/Stress.luau' };
project.tree.ServerStorage.NativeOwnershipChecks = { $path: '../tests/miniature-game/Ownership.luau' };
project.tree.ServerStorage.NativeOutpostScene = { $path: '../tests/miniature-game/OutpostScene.luau' };
project.tree.ServerStorage.NativeOutpostScenery = { $path: '../tests/miniature-game/OutpostScenery.luau' };
project.tree.ServerStorage.NativeMountStructures = { $path: '../tests/miniature-game/MountStructures.luau' };
project.tree.ServerStorage.NativeMountedScene = { $path: '../tests/miniature-game/MountedScene.luau' };
project.tree.ServerStorage.NativeMountedGallery = { $path: '../tests/miniature-game/MountedGallery.luau' };
project.tree.ServerStorage.NativeSupportCollision = { $path: '../tests/miniature-game/SupportCollision.luau' };
project.tree.ServerStorage.NativeRagdollSources = { $path: '../tests/miniature-game/RagdollSources.luau' };
project.tree.ServerStorage.NativeOriginalArmyScene = { $path: '../tests/miniature-game/OriginalArmyScene.luau' };
project.tree.ServerStorage.NativeKitGallery = { $path: '../tests/miniature-game/KitGallery.luau' };
if (!advanced && !services) project.tree.ServerScriptService.SceneChecks = { $path: '../tests/miniature-game/Scene.server.luau' };
if (advanced) project.tree.ServerScriptService.Sandbox.Bootstrap = { $path: '../tests/miniature-game/AdvancedBootstrap.server.luau' };
if (shop) project.tree.ServerScriptService.Sandbox.Bootstrap = { $path: '../tests/miniature-game/ShopBootstrap.server.luau' };
if (mounts) project.tree.ServerScriptService.Sandbox.Bootstrap = { $path: '../tests/miniature-game/MountedBootstrap.server.luau' };
if (research) project.tree.ServerScriptService.Sandbox.Bootstrap = { $path: '../tests/miniature-game/ResearchBootstrap.server.luau' };
if (services) project.tree.ServerScriptService.Sandbox.Bootstrap = { $path: '../tests/miniature-game/ServicesBootstrap.server.luau' };
for (const name of fs.readdirSync('tests/miniature-game')) {
  if (name !== 'Scene.server.luau' && name.endsWith('Scene.server.luau')) {
    project.tree.ServerScriptService[name.replace('.server.luau', 'Checks')] = { $path: `../tests/miniature-game/${name}` };
  }
}
project.tree.ReplicatedStorage.NativeInputChecks = { $path: '../tests/miniature-game/Input.luau' };
project.tree.ReplicatedStorage.NativeManagementChecks = { $path: '../tests/miniature-game/Management.luau' };
project.tree.ReplicatedStorage.NativeKitTour = { $path: '../tests/miniature-game/KitTour.luau' };
project.tree.ReplicatedStorage.NativeInventoryGuards = { $path: '../tests/miniature-game/InventoryGuards.luau' };
project.tree.ReplicatedStorage.NativeInventoryFlow = { $path: '../tests/miniature-game/InventoryFlow.luau' };
project.tree.ReplicatedStorage.NativeMilitaryBaselineFlow = { $path: '../tests/miniature-game/MilitaryBaselineFlow.luau' };
project.tree.ReplicatedStorage.NativeSimpleShopGuards = { $path: '../tests/miniature-game/SimpleShopGuards.luau' };
project.tree.ReplicatedStorage.NativeSimpleShopFlow = { $path: '../tests/miniature-game/SimpleShopFlow.luau' };
project.tree.ReplicatedStorage.NativeOutpostFlow = { $path: '../tests/miniature-game/OutpostFlow.luau' };
project.tree.ReplicatedStorage.NativeMountedFlow = { $path: '../tests/miniature-game/MountedFlow.luau' };
project.tree.ReplicatedStorage.NativeMountedDeathFlow = { $path: '../tests/miniature-game/MountedDeathFlow.luau' };
project.tree.ReplicatedStorage.NativeMountedRemoval = { $path: '../tests/miniature-game/MountedRemoval.luau' };
project.tree.ReplicatedStorage.NativeStructureFlow = { $path: '../tests/miniature-game/StructureFlow.luau' };
project.tree.ReplicatedStorage.NativeRagdollClient = { $path: '../tests/miniature-game/RagdollClient.luau' };
project.tree.ReplicatedStorage.NativeArmySmoothing = { $path: '../tests/miniature-game/ArmySmoothing.luau' };
project.tree.StarterPlayer.StarterPlayerScripts.NativeArmySmoothingRunner = { $path: '../tests/miniature-game/ArmySmoothingRunner.client.luau' };
project.tree.ReplicatedStorage.NativeServicesChecks = { $path: '../tests/miniature-game/Services.luau' };
project.tree.ReplicatedStorage.NativeLifecycleChecks = { $path: '../tests/miniature-game/Lifecycle.luau' };
project.tree.ReplicatedStorage.NativeResearchSwitch = { $path: '../tests/miniature-game/ResearchSwitch.luau' };
if (research) {
  project.tree.ServerScriptService = { Sandbox: project.tree.ServerScriptService.Sandbox, IsolationChecks: project.tree.ServerScriptService.IsolationChecks };
  project.tree.ReplicatedStorage.NativeMilitaryFlow = { $path: '../tests/miniature-game/MilitaryFlow.luau' };
  project.tree.ReplicatedStorage.NativeMilitaryLayouts = { $path: '../tests/miniature-game/MilitaryLayouts.luau' };
  project.tree.ReplicatedStorage.NativeArmyControlFlow = { $path: '../tests/miniature-game/ArmyControlFlow.luau' };
  project.tree.ReplicatedStorage.NativeMilitaryLifecycle = { $path: '../tests/miniature-game/MilitaryLifecycle.luau' };
  project.tree.ReplicatedStorage.NativeMilitaryUIGuards = { $path: '../tests/miniature-game/MilitaryUIGuards.luau' };
  project.tree.ReplicatedStorage.NativeMilitaryRemoteGuards = { $path: '../tests/miniature-game/MilitaryRemoteGuards.luau' };
  project.tree.ServerStorage.NativeMilitaryMatrix = { $path: '../tests/miniature-game/MilitaryNativeMatrix.luau' };
  delete project.tree.StarterPlayer.StarterPlayerScripts.NativeArmySmoothingRunner;
}
if (review) {
  // Player review retains the Coin-only seed without autorunning diagnostic
  // scenes that require a particular civilization or a timed test sequence.
  project.name = 'MiniatureMountsFundedReview';
  project.tree.ServerScriptService = { Sandbox: project.tree.ServerScriptService.Sandbox };
  for (const service of [project.tree.ServerStorage, project.tree.ReplicatedStorage]) {
    for (const name of Object.keys(service)) {
      if (name.startsWith('Native') || name === 'TemplateFingerprint') delete service[name];
    }
  }
  delete project.tree.StarterPlayer.StarterPlayerScripts.NativeArmySmoothingRunner;
}
fs.mkdirSync('.cache', { recursive: true });
fs.mkdirSync('build', { recursive: true });
const target = research ? '.cache/miniature-game-research-test.project.json' : review ? '.cache/miniature-game-mounted-review.project.json' : mounts ? '.cache/miniature-game-mounted-test.project.json' : shop ? '.cache/miniature-game-shop-test.project.json' : services ? '.cache/miniature-game-services-test.project.json' : advanced ? '.cache/miniature-game-advanced-test.project.json' : '.cache/miniature-game-test.project.json';
fs.writeFileSync(target, JSON.stringify(project, null, 2) + '\n');
console.log(`Created ${target}; build with Rojo and run one isolated Studio Play.`);
