--!strict

local definitions = {
	{action="earn",name="CoinButton",track="earn",x=-12,z=14,stage=1},
	{action="upgrade",name="UpgradeButton",track="settlement",x=12,z=14,stage=1},
	{action="weapon",name="WeaponButton",track="weapon",tier=2,x=18,z=23,stage=2},
	{action="armor",name="ArmorButton",track="armor",tier=2,x=28,z=23,stage=2},
	{action="weapon3",name="Weapon3Button",track="weapon",tier=3,x=18,z=23,stage=3},
	{action="armor3",name="Armor3Button",track="armor",tier=3,x=28,z=23,stage=3},
	{action="barracks2",name="Barracks2Button",track="barracks",tier=2,x=-24,z=-16,stage=2},
	{action="weapon4",name="Weapon4Button",track="weapon",tier=4,repeatFrom=3,x=18,z=23,stage=4},
	{action="armor4",name="Armor4Button",track="armor",tier=4,repeatFrom=3,x=28,z=23,stage=4},
	{action="barracks3",name="Barracks3Button",track="barracks",tier=3,x=-24,z=-16,stage=3},
	{action="barracks4",name="Barracks4Button",track="barracks",tier=4,x=-24,z=-16,stage=4},
	{action="barracks5",name="Barracks5Button",track="barracks",tier=5,x=-24,z=-16,stage=8},
	{action="barracks6",name="Barracks6Button",track="barracks",tier=6,x=-24,z=-16,stage=14},
	{action="training",name="TrainingButton",track="training",x=0,z=34,stage=5},
	{action="farm",name="FarmButton",track="farm",x=-48,y=-.3,z=-145,stage=7},
	{action="workers",name="WorkersButton",track="workers",x=60,y=-.3,z=-132,stage=7},
	{action="armyCamp",name="ArmyCampButton",track="armyCamp",x=-24,z=36,stage=10},
	{action="collectFarm",name="FarmCollectButton",track="collectFarm",x=-24,y=-.3,z=-145,stage=7},
	{action="blacksmith",name="BlacksmithButton",track="blacksmith",x=-42,z=51,stage=13},
	{action="armorer",name="ArmorerButton",track="armorer",x=42,z=51,stage=13},
	{action="storehouse",name="StorehouseButton",track="storehouse",x=20,z=45,stage=16},
}
local fields = require(script.Parent.SettlementDevelopment).fields
local byAction = {}
for _, definition in definitions do table.freeze(definition); byAction[definition.action]=definition end
return table.freeze({definitions=table.freeze(definitions),byAction=table.freeze(byAction),fields=fields})
