import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { test } from 'node:test';

test('release closure has one target-bound live bootstrap, one Main, retained assets and no fixture startup', () => {
  const original = fs.readFileSync('default.project.json', 'utf8');
  execFileSync(process.execPath, ['scripts/create-miniature-release.mjs']);
  const target = '.cache/miniature-release.project.json';
  const release = JSON.parse(fs.readFileSync(target, 'utf8'));
  assert.equal(release.name, 'ClashOfCivilizationsRelease');
  assert.equal(release.placeId, 73839918762778);
  assert.equal(release.gameId, 10770758443);
  assert.deepEqual(release.servePlaceIds, [73839918762778]);
  assert.equal(release.servePort, 34878);
  const files = [];
  function visit(node) {
    for (const [name, value] of Object.entries(node)) {
      assert(!/^(?:Native|ThreePlayer|FakeProfileStore)/.test(name), `Development instance in release: ${name}`);
      if (name === '$attributes') {
        assert(!Object.keys(value).some(key => /Verification|VisibleRun|Fixture/.test(key)), 'Development attribute in release');
      } else if (name === '$path') {
        assert(value.startsWith('../'), `Release path does not resolve from .cache: ${value}`);
        assert(!/tests\/|\.cache\/|mount-source-backups|legacy-fullscale|game\/server\/Bootstrap\.server/.test(value), `Development path in release: ${value}`);
        const resolved = path.resolve(path.dirname(target), value);
        assert(fs.existsSync(resolved), `Missing release dependency: ${value}`);
        if (fs.statSync(resolved).isDirectory()) {
          for (const file of fs.readdirSync(resolved, { recursive: true })) {
            if (/\.(?:server|client)\.luau$/.test(file)) files.push(path.join(resolved, file));
          }
        } else files.push(resolved);
      } else if (value && typeof value === 'object') visit(value);
    }
  }
  visit(release.tree);
  assert.deepEqual(files.filter(file => file.endsWith('.server.luau')).map(file => path.relative(process.cwd(), file)), ['prototypes/miniature/release/Bootstrap.server.luau']);
  assert.deepEqual(files.filter(file => file.endsWith('.client.luau')).map(file => path.relative(process.cwd(), file)), ['prototypes/miniature/game/client/Main.client.luau']);
  const sandbox = release.tree.ServerScriptService.Sandbox;
  assert.equal(sandbox.$path, undefined, 'Directory overlays can duplicate Bootstrap');
  for (const name of ['LiveStartup', 'ReleaseConfig', 'PersistentProfileStore', 'Runtime', 'Sessions']) {
    assert.equal(sandbox[name].$path, `../prototypes/miniature/game/server/${name}.luau`);
  }
  assert.deepEqual(Object.keys(release.tree.ServerScriptService).sort(), ['$className', 'Sandbox']);
  assert.deepEqual(Object.keys(release.tree.StarterPlayer.StarterPlayerScripts).sort(), ['$className', 'MiniatureGame']);
  const base = JSON.parse(original);
  for (const name of ['MountTemplates', 'NPCTemplates', 'EquipmentTemplates', 'OutfitTemplates', 'FarmTemplates']) {
    assert.equal(release.tree.ServerStorage[name].$path, `../${base.tree.ServerStorage[name].$path}`);
  }
  const config = fs.readFileSync('prototypes/miniature/game/server/ReleaseConfig.luau', 'utf8');
  for (const [key, value] of [['placeId', 73839918762778], ['universeId', 10770758443], ['ownerId', 68716649]]) {
    assert.match(config, new RegExp(`\\b${key}\\s*=\\s*${value}\\b`));
  }
  const bootstrap = fs.readFileSync('prototypes/miniature/release/Bootstrap.server.luau', 'utf8');
  assert.match(bootstrap, /LiveStartup/);
  assert.doesNotMatch(bootstrap, /FakeProfileStore|20000|100000|ThreePlayer/);
  assert.equal(fs.readFileSync('default.project.json', 'utf8'), original, 'Release generation mutated ordinary Studio startup');
  assert.equal(base.tree.ServerStorage.FakeProfileStore.$path, 'tests/runtime/FakeProfileStore.luau');
  assert.throws(() => execFileSync(process.execPath, ['scripts/create-miniature-release.mjs', '--verification'], { stdio: 'pipe' }));
});
