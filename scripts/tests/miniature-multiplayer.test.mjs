import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { test } from 'node:test';

test('three-player mapping replaces the bootstrap and retains exactly one main client plus one test bot', () => {
  const baseText = fs.readFileSync('miniature-playtest.project.json', 'utf8');
  const mainText = fs.readFileSync('default.project.json', 'utf8');
  execFileSync(process.execPath, ['scripts/create-miniature-multiplayer-tests.mjs']);
  const target = '.cache/miniature-three-player.project.json';
  const project = JSON.parse(fs.readFileSync(target, 'utf8'));
  const base = JSON.parse(baseText);
  const mappings = [];
  function visit(node) {
    for (const [key, value] of Object.entries(node)) {
      if (key === '$path') mappings.push(value);
      else if (value && typeof value === 'object') visit(value);
    }
  }
  visit(project.tree);
  assert.equal(project.name, 'ClashOfCivilizationsThreePlayerTest');
  assert.equal(project.servePort, 34876);
  assert.notEqual(project.tree.ServerScriptService.ThreePlayerCoordinator.$attributes?.VisibleRun, true);
  for (const file of mappings) {
    assert(file.startsWith('../'), `Generated path must resolve from .cache: ${file}`);
    assert(fs.existsSync(path.resolve(path.dirname(target), file)), `Missing three-player dependency: ${file}`);
    assert(!/mount-source-backups|legacy-fullscale|tests\/miniature-game|ProfileService/.test(file), `Unexpected test/live dependency: ${file}`);
  }
  const server = project.tree.ServerScriptService;
  assert.deepEqual(Object.keys(server).sort(), ['$className', 'Sandbox', 'ThreePlayerCoordinator']);
  assert.equal(server.Sandbox.$path, undefined, 'A server directory overlay would keep the ordinary Bootstrap');
  assert.equal(server.Sandbox.Bootstrap.$path, '../tests/miniature-multiplayer/Bootstrap.server.luau');
  assert.equal(server.ThreePlayerCoordinator.$path, '../tests/miniature-multiplayer/Coordinator.server.luau');
  assert.deepEqual(Object.entries(server.Sandbox)
    .filter(([, value]) => value?.$path?.endsWith('.server.luau'))
    .map(([name]) => name), ['Bootstrap']);
  const scripts = project.tree.StarterPlayer.StarterPlayerScripts;
  assert.deepEqual(Object.keys(scripts).sort(), ['$className', 'MiniatureGame', 'ThreePlayerBot']);
  assert.equal(scripts.MiniatureGame.$path, '../prototypes/miniature/game/client');
  assert.equal(scripts.MiniatureGame.Main, undefined, 'Do not overlay a second Main on the client directory');
  assert.equal(scripts.ThreePlayerBot.$path, '../tests/miniature-multiplayer/Client.client.luau');
  const clients = fs.readdirSync('prototypes/miniature/game/client').filter(name => name.endsWith('.client.luau'));
  assert.deepEqual(clients, ['Main.client.luau'], 'The directory must have exactly one automatic game client');
  assert.equal(project.tree.ServerStorage.ThreePlayerContext.$path, '../tests/miniature-multiplayer/Context.luau');
  assert.equal(project.tree.ServerStorage.FakeProfileStore.$path, '../tests/runtime/FakeProfileStore.luau');
  for (const name of ['MountTemplates', 'NPCTemplates', 'EquipmentTemplates', 'OutfitTemplates', 'FarmTemplates']) {
    assert.equal(project.tree.ServerStorage[name].$path, `../${base.tree.ServerStorage[name].$path}`);
  }
  for (const [name, node] of Object.entries(base.tree.ServerStorage.OriginalArmy)) {
    if (node?.$path) assert.equal(project.tree.ServerStorage.OriginalArmy[name].$path, `../${node.$path}`);
  }
  assert.equal(project.tree.ServerStorage.OriginalArmy.ProfileService, undefined);
  assert.equal(project.tree.ServerScriptService.Game, undefined);
  assert.equal(project.tree.ReplicatedStorage.MiniatureGame.$path, '../prototypes/miniature/game/shared');
  assert.equal(fs.readFileSync('miniature-playtest.project.json', 'utf8'), baseText, 'Generator changed ordinary sandbox mapping');
  assert.equal(fs.readFileSync('default.project.json', 'utf8'), mainText, 'Generator changed main mapping');
});

test('visible three-player mapping persists the opt-in flag in a separate on-disk place', () => {
  execFileSync(process.execPath, ['scripts/create-miniature-multiplayer-tests.mjs']);
  const normal = JSON.parse(fs.readFileSync('.cache/miniature-three-player.project.json', 'utf8'));
  execFileSync(process.execPath, ['scripts/create-miniature-multiplayer-tests.mjs', '--visible']);
  const visible = JSON.parse(fs.readFileSync('.cache/miniature-three-player-visible.project.json', 'utf8'));
  assert.equal(visible.name, 'ClashOfCivilizationsThreePlayerVisibleTest');
  assert.equal(visible.servePort, 34877);
  assert.equal(visible.tree.ServerScriptService.ThreePlayerCoordinator.$attributes.VisibleRun, true);
  delete visible.tree.ServerScriptService.ThreePlayerCoordinator.$attributes;
  assert.deepEqual(visible.tree, normal.tree, 'Visible mode must retain the same fake-store fixture and assets');
  assert.deepEqual(JSON.parse(fs.readFileSync('.cache/miniature-three-player.project.json', 'utf8')), normal, 'Visible generation overwrote the ordinary test project');
  assert.equal(JSON.parse(fs.readFileSync('default.project.json', 'utf8')).tree.ServerScriptService.ThreePlayerCoordinator, undefined);
});

test('three-player test entrypoints retain Studio, fake-store and fixture boundaries', () => {
  const executable = file => fs.readFileSync(file, 'utf8')
    .replace(/--\[(=*)\[[\s\S]*?\]\1\]/g, '')
    .replace(/--[^\r\n]*/g, '');
  const bootstrap = executable('tests/miniature-multiplayer/Bootstrap.server.luau');
  const bot = executable('tests/miniature-multiplayer/Client.client.luau');
  assert.match(bootstrap, /:IsStudio\(\)/);
  assert.match(bootstrap, /FakeProfileStore/);
  assert.match(bootstrap, /MiniatureThreePlayerFixture/);
  assert.match(bot, /:IsStudio\(\)/);
  assert.match(bot, /MiniatureThreePlayerFixture/);
  assert.doesNotMatch(`${bootstrap}\n${bot}`, /DataStoreService|CivilizationProfilesV1/);
  assert.doesNotMatch(bot, /\b(?:PlayerModule|GetControls|InputReadiness)\b/, 'The bot must leave the actual game input controller alone');
  assert.throws(() => execFileSync(process.execPath, ['scripts/create-miniature-multiplayer-tests.mjs', '--live'], { stdio: 'pipe' }));
});
