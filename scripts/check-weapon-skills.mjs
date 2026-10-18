// Run real Luau modules with explicit engine doubles. This does not run Roblox physics.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { spawnSync } from 'node:child_process';
const installed=path.join(os.homedir(),'.local/bin/luau');
const luau = process.env.LUAU_CLI || (fs.existsSync(installed) ? installed : 'luau');
const modules = [
  'src/shared/ProgressionConfig.luau', 'src/shared/SettlementProgression.luau',
  'src/shared/UpgradeTracks.luau', 'src/shared/Civilizations.luau',
  'src/shared/WarriorConfig.luau', 'src/shared/RangedConfig.luau',
  'src/shared/WeaponSkillConfig.luau', 'src/shared/WeaponSkillPose.luau', 'src/shared/WeaponSkillAnimation.luau', 'src/shared/SpearDashTrail.luau', 'src/shared/WeaponSkillPlayback.luau',
  'src/shared/FormationConfig.luau', 'src/shared/SettlementDevelopment.luau', 'src/server/ProfileData.luau',
  'src/shared/TrainingCampConfig.luau', 'src/shared/TacticalCombatConfig.luau', 'src/server/CombatTactics.luau', 'src/shared/MedicalConfig.luau', 'src/server/MedicalService.luau', 'src/server/MedicalRules.luau', 'src/server/YardRecovery.luau', 'src/server/MedicPlanner.luau', 'src/server/MedicalRetreat.luau',
  'src/server/Economy.luau', 'src/server/CombatRules.luau', 'src/server/ShieldCombat.luau', 'src/server/WeaponSkillService.luau', 'src/server/CrowdMovement.luau', 'src/server/TroopFootwork.luau', 'src/server/ArmyRest.luau', 'src/server/ArmyFormation.luau',
  'src/server/ProfileService.luau', 'src/server/CombatService.luau', 'tests/runtime/FakeProfileStore.luau',
  'tests/specs/WeaponSkillProgression.spec.luau', 'tests/specs/WeaponSkillActions.spec.luau', 'tests/specs/WeaponSkillAnimation.spec.luau', 'tests/specs/WeaponSkillPlayback.spec.luau',
  'tests/specs/Economy.spec.luau', 'tests/specs/EconomyPersistence.spec.luau',
  'tests/specs/EconomyProgression.spec.luau', 'tests/specs/ProfileData.spec.luau',
  'tests/specs/ProfileGrowth.spec.luau', 'tests/specs/EconomyExpansion.spec.luau',
  'tests/specs/SettlementDevelopment.spec.luau', 'tests/specs/HospitalProgression.spec.luau', 'tests/specs/MedicalLogic.spec.luau', 'tests/specs/MedicalFlights.spec.luau', 'tests/specs/MedicalRetreat.spec.luau', 'tests/specs/CrowdMovement.spec.luau', 'tests/specs/TroopFootwork.spec.luau', 'tests/specs/ArmyRest.spec.luau', 'tests/specs/FormationProgression.spec.luau', 'tests/specs/ShieldCombat.spec.luau', 'tests/specs/ArmyFormation.spec.luau',
  'tests/specs/TargetAcquisition.spec.luau',
  'tests/specs/TestCurrency.spec.luau',
];
const identifiers = new Map(modules.map(file => [file, file.replace(/\.luau$/, '').replaceAll('/', '.') ]));
let source = `local primitives=(function()\n${fs.readFileSync('tests/cli/Primitives.luau', 'utf8')}\nend)()\n`;
source += `local Vector3,CFrame,Enum,Color3,RaycastParams=primitives.Vector3,primitives.CFrame,primitives.Enum,primitives.Color3,primitives.RaycastParams
local Instance=primitives.Instance
local task={wait=function()error("Waiting requires Studio")end}
local function typeof(value)return if type(value)=="table" and value._type then value._type else type(value)end
local workspace={GetServerTimeNow=os.clock}
local nodes,loaders,cache={},{},{}
local function node(id)
  if nodes[id] then return nodes[id]end
  local n={_id=id};nodes[id]=n
  function n:FindFirstChild(name)return self[name]end
  local parent,name=string.match(id,"^(.*)%.([^%.]+)$")
  if parent then n.Parent=node(parent);n.Parent[name]=n end
  return n
end
local game={ReplicatedStorage={Shared=node("src.shared")},ServerScriptService={Game=node("src.server")},ServerStorage={RuntimeTests=node("tests.runtime")},HttpService={GenerateGUID=function()return tostring(os.clock())end},Players={}}
function game:GetService(name)return self[name]end
local function require(module)
  assert(module and loaders[module._id],"Unmapped test module")
  if cache[module._id]==nil then cache[module._id]=loaders[module._id]()end
  return cache[module._id]
end
`;
for (const [file, id] of identifiers) {
  source += `node(${JSON.stringify(id)})\n`;
}
for (const [file, id] of identifiers) {
  source += `loaders[${JSON.stringify(id)}]=function()\nlocal script=node(${JSON.stringify(id)})\n${fs.readFileSync(file,'utf8')}\nend\n`;
}
source += 'local total=0\n';
for (const file of modules.filter(file => file.startsWith('tests/specs/'))) {
  source += `total+=require(node(${JSON.stringify(identifiers.get(file))}))()\n`;
}
source += 'print("Standalone logic cases passed: "..total.." (explicit engine doubles; Studio checks still required)")\n';
fs.mkdirSync('.cache', { recursive:true });
const output=path.resolve('.cache/weapon-skills-logic.luau');
fs.writeFileSync(output, source);
const result=spawnSync(luau,[output],{stdio:'inherit'});
if(result.error) { console.error(`Cannot run Luau CLI: ${result.error.message}. Set LUAU_CLI to its installed path.`);process.exit(1); }
process.exit(result.status ?? 1);
