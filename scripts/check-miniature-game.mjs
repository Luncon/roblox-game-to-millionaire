import fs from 'node:fs';
import path from 'node:path';
import { runTool } from './dev-tools.mjs';

const roots = ['prototypes/miniature/game/shared', 'prototypes/miniature/game/server', 'tests/miniature-game'];
const files = roots.flatMap(directory => fs.readdirSync(directory)
  .filter(name => name.endsWith('.luau') && !name.endsWith('.server.luau') && !name.endsWith('.client.luau'))
  .map(name => `${directory}/${name}`));
files.push('tests/runtime/FakeProfileStore.luau', 'src/server/ClaimRegistry.luau', 'src/shared/Civilizations.luau');
// Actual original combat planners run against explicit engine doubles here.
// Rendering, joints, clothing and ground contacts still require native Studio.
files.push(...['CombatEncounter', 'CombatTactics', 'CombatRules', 'Topography', 'TroopFootwork',
  'CrowdMovement', 'MedicPlanner', 'MedicalRetreat', 'MedicalRules', 'MedicalService', 'YardRecovery'].map(name => `src/server/${name}.luau`));
files.push(...['TacticalCombatConfig', 'WarriorConfig', 'RangedConfig', 'MedicalConfig',
  'WorldConfig', 'SettlementSites', 'TrainingCampConfig', 'SettlementProgression',
  'ProgressionConfig'].map(name => `src/shared/${name}.luau`));
const id = file => file.replace(/\.luau$/, '').replaceAll('/', '.');
let source = `local mathTypes=require("@lune/roblox")
local primitives=(function()\n${fs.readFileSync('tests/cli/Primitives.luau', 'utf8')}\nend)()
local Vector3,CFrame,Color3=mathTypes.Vector3,mathTypes.CFrame,mathTypes.Color3
local Enum,RaycastParams,Instance=primitives.Enum,primitives.RaycastParams,primitives.Instance
Enum.Material={Grass="Grass",LeafyGrass="LeafyGrass",Sand="Sand",Snow="Snow",Mud="Mud"}
local engineTypeof=typeof
local function typeof(value)return if type(value)=="table" and value._type then value._type else engineTypeof(value)end
local workspace={GetServerTimeNow=os.clock,Raycast=function()return nil end}
local nodes,loaders,cache={},{},{}
local function node(id)
 if nodes[id] then return nodes[id] end
 local value={_id=id};nodes[id]=value
 local parent,name=string.match(id,"^(.*)%.([^%.]+)$")
 if parent then value.Parent=node(parent);value.Parent[name]=value end
 return value
end
local game={ReplicatedStorage={MiniatureGame=node("prototypes.miniature.game.shared")},
 ServerScriptService={Sandbox=node("prototypes.miniature.game.server")},ServerStorage={},Workspace=workspace}
function game:GetService(name)return self[name]end
local function require(module)
 assert(module and loaders[module._id],"Unmapped miniature test dependency")
 if cache[module._id]==nil then cache[module._id]=loaders[module._id]()end
 return cache[module._id]
end
`;
for (const file of files) source += `node(${JSON.stringify(id(file))})\n`;
source += `game.ServerStorage.FakeProfileStore=node("tests.runtime.FakeProfileStore")
game.ServerStorage.ClaimRegistry=node("src.server.ClaimRegistry")
game.ServerStorage.OriginalArmy=node("src.server")
game.ReplicatedStorage.Shared=node("src.shared")
game.ReplicatedStorage.OriginalArmyConfig={RangedConfig=node("src.shared.RangedConfig"),MedicalConfig=node("src.shared.MedicalConfig")}
game.ReplicatedStorage.Shared={}
for name,module in node("src.shared") do game.ReplicatedStorage.Shared[name]=module end
game.ReplicatedStorage.Shared.RangedConfig=node("prototypes.miniature.game.shared.OriginalRangedConfig")
game.ReplicatedStorage.Shared.MedicalConfig=node("prototypes.miniature.game.shared.OriginalMedicalConfig")
game.ReplicatedStorage.MiniatureGame.Civilizations=node("src.shared.Civilizations")\n`;
for (const file of files) {
  source += `loaders[${JSON.stringify(id(file))}]=function()\nlocal script=node(${JSON.stringify(id(file))})\n${fs.readFileSync(file, 'utf8')}\nend\n`;
}
source += 'local count=0\n';
for (const file of files.filter(file => file.endsWith('.spec.luau'))) {
  source += `count+=require(node(${JSON.stringify(id(file))}))()\n`;
}
source += 'assert(count>0,"No miniature logic tests ran")\nprint(`Miniature logic cases passed: {count} (fake store; Studio checks separate)`)\n';
fs.mkdirSync('.cache', { recursive: true });
const output = path.resolve('.cache/miniature-game-logic.luau');
fs.writeFileSync(output, source);
const logicStatus = runTool('lune', ['run', output]).status ?? 1;
if (logicStatus !== 0) process.exit(logicStatus);
process.exit(runTool('lune', ['run', '.lune/mount-assets.luau']).status ?? 1);
