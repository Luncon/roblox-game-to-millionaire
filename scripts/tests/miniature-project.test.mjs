import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { test } from 'node:test';
import { execFileSync } from 'node:child_process';

test('main project launches ordinary miniature gameplay and preserves full-size tooling', () => {
  const main = JSON.parse(fs.readFileSync('default.project.json', 'utf8'));
  const miniature = JSON.parse(fs.readFileSync('miniature-playtest.project.json', 'utf8'));
  const legacy = JSON.parse(fs.readFileSync('legacy-fullscale.project.json', 'utf8'));
  assert.equal(main.name, 'ClashOfCivilizations');
  assert.equal(main.servePort, 34872);
  assert.deepEqual(main.tree, miniature.tree);
  assert.equal(main.tree.ServerScriptService.Sandbox.$path, 'prototypes/miniature/game/server');
  assert.equal(main.tree.ServerScriptService.Game, undefined);
  assert.equal(legacy.tree.ServerScriptService.Game.$path, 'src/server');
  assert.equal(legacy.tree.StarterPlayer.StarterPlayerScripts.Game.$path, 'src/client');
  assert.equal(legacy.tree.ReplicatedStorage.Shared.$path, 'src/shared');
  execFileSync(process.execPath, ['scripts/create-test-project.mjs', '--local-playtest']);
  const generated = JSON.parse(fs.readFileSync('.cache/local-playtest.project.json', 'utf8'));
  assert.equal(generated.tree.ServerScriptService.Sandbox, undefined);
  assert.equal(generated.tree.ServerScriptService.Game.Bootstrap.$path, '../tests/LocalPlaytest.server.luau');
});

test('playable miniature mapping isolates production services and the scale preview', () => {
  const project = JSON.parse(fs.readFileSync('miniature-playtest.project.json', 'utf8'));
  const mapped = [];
  function visit(node) {
    for (const [key, value] of Object.entries(node)) {
      if (key === '$path') mapped.push(value);
      else if (value && typeof value === 'object') visit(value);
    }
  }
  visit(project.tree);
  const allowed = new Set([
    'prototypes/miniature/game/server', 'prototypes/miniature/game/client',
    'prototypes/miniature/game/shared', 'tests/runtime/FakeProfileStore.luau',
    'src/shared/Civilizations.luau',
    'src/server/ClaimRegistry.luau', 'assets/mount-templates',
    'src/shared/SettlementSites.luau', 'src/shared/TrainingCampConfig.luau',
    'src/server/FarmTenders.luau', 'assets/farm-templates', 'src/client/PanelVisibility.luau',
    ...['WarriorConfig', 'RangedConfig', 'UpgradeTracks', 'ProgressionConfig',
      'SettlementProgression', 'WeaponSkillPose', 'WeaponSkillConfig', 'FormationConfig',
      'TacticalCombatConfig', 'MedicalConfig', 'WorldConfig'].map(name => `src/shared/${name}.luau`),
    ...['WarriorRig', 'Equipment', 'NPCModelTemplates', 'TroopAppearance', 'EquipmentVisuals',
      'OutfitTemplates', 'ShieldCombat', 'CombatEncounter', 'CombatTactics', 'CombatRules',
      'Topography', 'TroopFootwork', 'CrowdMovement', 'MedicPlanner', 'MedicalRetreat',
      'MedicalRules', 'MedicalService', 'YardRecovery'].map(name => `src/server/${name}.luau`),
    'assets/npc-templates', 'assets/equipment-templates', 'assets/outfit-templates',
    'prototypes/miniature/game/shared/OriginalRangedConfig.luau',
    'prototypes/miniature/game/shared/OriginalMedicalConfig.luau',
  ]);
  assert(mapped.length > 0);
  for (const file of mapped) {
    assert(allowed.has(file), `Unreviewed sandbox dependency: ${file}`);
    assert(fs.existsSync(path.resolve(file)), `Missing mapping: ${file}`);
  }
  assert.equal(project.tree.ServerScriptService.Sandbox.$path, 'prototypes/miniature/game/server');
  assert.equal(project.tree.ServerStorage.FakeProfileStore.$path, 'tests/runtime/FakeProfileStore.luau');
  assert.equal(project.tree.ServerScriptService.Game, undefined);
  assert.equal(project.tree.ServerStorage.OriginalArmy.$path, undefined, 'Original helpers must use explicit module mappings');
  assert.equal(project.tree.ServerStorage.OriginalArmy.WarriorRig.$path, 'src/server/WarriorRig.luau');
  assert.equal(project.tree.ServerStorage.OriginalArmy.CombatEncounter.$path, 'src/server/CombatEncounter.luau');
  assert.equal(project.tree.ReplicatedStorage.Shared.RangedConfig.$path, 'prototypes/miniature/game/shared/OriginalRangedConfig.luau');
  assert.equal(project.tree.ReplicatedStorage.Shared.MedicalConfig.$path, 'prototypes/miniature/game/shared/OriginalMedicalConfig.luau');
  assert.equal(project.tree.ReplicatedStorage.OriginalArmyConfig.RangedConfig.$path, 'src/shared/RangedConfig.luau');
  assert.equal(project.tree.ReplicatedStorage.OriginalArmyConfig.MedicalConfig.$path, 'src/shared/MedicalConfig.luau');
  for (const forbidden of ['Bootstrap', 'ProfileService', 'ProfileData', 'Economy', 'WarriorService', 'NeutralOpponentService']) {
    assert.equal(project.tree.ServerStorage.OriginalArmy[forbidden], undefined, `Original service must not bootstrap: ${forbidden}`);
  }
  const preview = JSON.parse(fs.readFileSync('miniature.project.json', 'utf8'));
  assert.equal(preview.tree.ServerScriptService.Miniature.$path, 'prototypes/miniature/server');
});

test('native test modes select one bootstrap without a directory overlay', () => {
  for (const [flag, filename, bootstrap] of [
    [undefined, 'miniature-game-test', '../prototypes/miniature/game/server/Bootstrap.server.luau'],
    ['--advanced', 'miniature-game-advanced-test', '../tests/miniature-game/AdvancedBootstrap.server.luau'],
    ['--services', 'miniature-game-services-test', '../tests/miniature-game/ServicesBootstrap.server.luau'],
    ['--shop', 'miniature-game-shop-test', '../tests/miniature-game/ShopBootstrap.server.luau'],
    ['--mounts', 'miniature-game-mounted-test', '../tests/miniature-game/MountedBootstrap.server.luau'],
  ]) {
    execFileSync(process.execPath, ['scripts/create-miniature-game-tests.mjs', ...(flag ? [flag] : [])]);
    const project = JSON.parse(fs.readFileSync(`.cache/${filename}.project.json`, 'utf8'));
    const sandbox = project.tree.ServerScriptService.Sandbox;
    assert.equal(sandbox.$path, undefined, 'Rojo directory overlays add a duplicate Bootstrap');
    assert.equal(sandbox.Bootstrap.$path, bootstrap);
    const scripts = Object.entries(sandbox).filter(([, node]) => typeof node === 'object' && node.$path?.endsWith('.server.luau'));
    assert.deepEqual(scripts.map(([name]) => name), ['Bootstrap']);
    for (const name of ['Runtime', 'State', 'Economy', 'World', 'SpartanKit']) {
      assert.equal(sandbox[name].$path, `../prototypes/miniature/game/server/${name}.luau`);
    }
  }
});

test('funded player review preserves the seed without autorunning native diagnostics', () => {
  execFileSync(process.execPath, ['scripts/create-miniature-game-tests.mjs', '--mounts', '--review']);
  const project = JSON.parse(fs.readFileSync('.cache/miniature-game-mounted-review.project.json', 'utf8'));
  assert.deepEqual(Object.keys(project.tree.ServerScriptService), ['Sandbox']);
  assert.equal(project.tree.ServerScriptService.Sandbox.Bootstrap.$path, '../tests/miniature-game/MountedBootstrap.server.luau');
  assert.equal(project.tree.ServerScriptService.Sandbox.$path, undefined);
  assert.equal(project.tree.ServerStorage.FakeProfileStore.$path, '../tests/runtime/FakeProfileStore.luau');
  for (const service of [project.tree.ServerStorage, project.tree.ReplicatedStorage]) {
    assert(!Object.keys(service).some(name => name.startsWith('Native') || name === 'TemplateFingerprint'));
  }
  assert.equal(project.tree.StarterPlayer.StarterPlayerScripts.NativeArmySmoothingRunner, undefined);
  assert.equal(project.tree.ServerStorage.MountTemplates.$path, '../assets/mount-templates');
});

test('military research fixture declares separate funding and one bootstrap', () => {
  execFileSync(process.execPath, ['scripts/create-miniature-game-tests.mjs', '--research']);
  const project = JSON.parse(fs.readFileSync('.cache/miniature-game-research-test.project.json', 'utf8'));
  assert.equal(project.tree.ServerScriptService.Sandbox.$path, undefined);
  assert.equal(project.tree.ServerScriptService.Sandbox.Bootstrap.$path, '../tests/miniature-game/ResearchBootstrap.server.luau');
  assert.deepEqual(Object.keys(project.tree.ServerScriptService).sort(), ['IsolationChecks', 'Sandbox']);
  assert.equal(project.tree.ReplicatedStorage.NativeMilitaryFlow.$path, '../tests/miniature-game/MilitaryFlow.luau');
  assert.equal(project.tree.StarterPlayer.StarterPlayerScripts.NativeArmySmoothingRunner, undefined);
  assert.throws(() => execFileSync(process.execPath, ['scripts/create-miniature-game-tests.mjs', '--research', '--mounts'], { stdio: 'pipe' }));
});
