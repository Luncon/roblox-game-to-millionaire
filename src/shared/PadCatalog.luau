--!strict

local Camp = require(script.Parent.TrainingCampConfig)
local Sites = require(script.Parent.SettlementSites)
local definitions = {
	{action="shield",name="ShieldButton",track="shield",x=Sites.shieldPad.X,y=Sites.shieldPad.Y,z=Sites.shieldPad.Z,stage=15},
	{action="warCouncil",name="WarCouncilButton",track="warCouncil",x=Sites.warCouncilPad.X,y=Sites.warCouncilPad.Y,z=Sites.warCouncilPad.Z,stage=19},
	{action="formation",name="FormationButton",track="formation",x=Sites.formationPad.X,y=Sites.formationPad.Y,z=Sites.formationPad.Z,stage=20},
	{action="earn",name="CoinButton",track="earn",x=-12,z=14,stage=1},
	{action="testCoins",name="TestCoinButton",track="testCoins",x=-12,z=24,stage=1,studioOnly=true},
	{action="upgrade",name="UpgradeButton",track="settlement",x=12,z=14,stage=1},
	{action="weapon",name="WeaponButton",track="weapon",tier=2,x=18,z=23,stage=2},
	{action="armor",name="ArmorButton",track="armor",tier=2,x=28,z=23,stage=2},
	{action="weapon3",name="Weapon3Button",track="weapon",tier=3,x=18,z=23,stage=3},
	{action="armor3",name="Armor3Button",track="armor",tier=3,x=28,z=23,stage=3},
	{action="barracks2",name="Barracks2Button",track="barracks",tier=2,x=Sites.barracksPad.X,y=Sites.barracksPad.Y,z=Sites.barracksPad.Z,stage=2},
	{action="weapon4",name="Weapon4Button",track="weapon",tier=4,repeatFrom=3,x=18,z=23,stage=4},
	{action="armor4",name="Armor4Button",track="armor",tier=4,repeatFrom=3,x=28,z=23,stage=4},
	{action="barracks3",name="Barracks3Button",track="barracks",tier=3,x=Sites.barracksPad.X,y=Sites.barracksPad.Y,z=Sites.barracksPad.Z,stage=3},
	{action="barracks4",name="Barracks4Button",track="barracks",tier=4,x=Sites.barracksPad.X,y=Sites.barracksPad.Y,z=Sites.barracksPad.Z,stage=4},
	{action="barracks5",name="Barracks5Button",track="barracks",tier=5,x=Sites.barracksPad.X,y=Sites.barracksPad.Y,z=Sites.barracksPad.Z,stage=8},
	{action="barracks6",name="Barracks6Button",track="barracks",tier=6,x=Sites.barracksPad.X,y=Sites.barracksPad.Y,z=Sites.barracksPad.Z,stage=14},
	{action="hospital",name="HospitalButton",track="hospital",x=Sites.hospitalPad.X,y=Sites.hospitalPad.Y,z=Sites.hospitalPad.Z,stage=10},
	{action="training",name="TrainingButton",track="training",x=Camp.pad.X,y=Camp.pad.Y,z=Camp.pad.Z,stage=5},
	{action="skill",name="SkillButton",track="skill",x=Camp.pad.X+12,y=Camp.pad.Y,z=Camp.pad.Z,stage=10},
	{action="farm",name="FarmButton",track="farm",x=-48,y=-.3,z=-145,stage=7},
	{action="workers",name="WorkersButton",track="workers",x=60,y=-.3,z=-132,stage=7},
	{action="armyCamp",name="ArmyCampButton",track="armyCamp",x=Sites.capacityPad.X,y=Sites.capacityPad.Y,z=Sites.capacityPad.Z,stage=10},
	{action="collectFarm",name="FarmCollectButton",track="collectFarm",x=-24,y=-.3,z=-145,stage=7},
	{action="blacksmith",name="BlacksmithButton",track="blacksmith",x=-42,z=51,stage=13},
	{action="armorer",name="ArmorerButton",track="armorer",x=42,z=51,stage=13},
	{action="storehouse",name="StorehouseButton",track="storehouse",x=20,z=45,stage=16},
}
local fields = require(script.Parent.SettlementDevelopment).fields
local byAction = {}
for _, definition in definitions do table.freeze(definition); byAction[definition.action]=definition end
return table.freeze({definitions=table.freeze(definitions),byAction=table.freeze(byAction),fields=fields})
