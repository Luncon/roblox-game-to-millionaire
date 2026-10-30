import assert from 'node:assert/strict';
import fs from 'node:fs';
import { test } from 'node:test';

// ExecuteLuau's Client context has a different require cache from game
// LocalScripts. Requiring PlayerModule there creates a second ControlModule
// singleton, which overwrites the game's named ControlScriptRenderstep binding.
// Fixtures must observe Humanoid movement and use native input instead.
const fixtures = [
  ...fs.readdirSync('tests/miniature-game')
    .filter(name => name.endsWith('.luau') && !name.endsWith('.spec.luau'))
    .map(name => `tests/miniature-game/${name}`),
  'tests/miniature/Input.luau',
];

function executableSource(source) {
  return source
    .replace(/--\[(=*)\[[\s\S]*?\]\1\]/g, '')
    .replace(/--[^\r\n]*/g, '');
}

test('native miniature fixtures leave the game-owned default controller in its LocalScript VM', () => {
  const controllerAccess = /\b(?:PlayerModule|GetControls)\b/;
  const fixtureControllerAccess = /\b(?:PlayerModule|GetControls|InputReadiness)\b/;
  // Check the boundary against both the original bug and an aliased variant,
  // without modifying a frozen native fixture or requiring Roblox at test time.
  for (const regression of [
    'require(player.PlayerScripts:WaitForChild("PlayerModule")):GetControls()',
    'local module = player.PlayerScripts.PlayerModule\nlocal controls = require(module)',
    'require(module):GetControls()',
    'require(player.PlayerScripts.MiniatureGame.InputReadiness).start(screen)',
  ]) {
    assert.match(executableSource(regression), fixtureControllerAccess);
  }
  for (const file of fixtures) {
    const source = executableSource(fs.readFileSync(file, 'utf8'));
    assert.doesNotMatch(
      source,
      fixtureControllerAccess,
      `${file}: tool-context fixtures must not access PlayerModule/GetControls or invoke InputReadiness; a second singleton replaces the game's movement render binding`,
    );
  }
  const main = executableSource(fs.readFileSync('prototypes/miniature/game/client/Main.client.luau', 'utf8'));
  assert.doesNotMatch(main, /\bMovement\b/, 'Main must not bootstrap the unsupported movement-controller workaround');
  assert.doesNotMatch(main, controllerAccess, 'Main must use the actual-game-context input-readiness boundary');
  const readiness = executableSource(fs.readFileSync('prototypes/miniature/game/client/InputReadiness.luau', 'utf8'));
  assert.doesNotMatch(
    `${main}\n${readiness}`,
    /(?:\b(?:Disable|Enable)\s*\(|\bBindContextActions\b|\bBindAction(?:AtPriority)?\s*\()/,
    'Input readiness must reselect the default mode without forcing controls or replacing keyboard bindings',
  );
});
