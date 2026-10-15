--!strict

local definitions = {
	{action="earn",name="CoinButton",track="earn",x=-12,z=14,stage=1},
	{action="upgrade",name="UpgradeButton",track="settlement",x=12,z=14,stage=1},
	{action="weapon",name="WeaponButton",track="weapon",tier=2,x=-12,z=24,stage=2},
	{action="armor",name="ArmorButton",track="armor",tier=2,x=12,z=24,stage=2},
	{action="weapon3",name="Weapon3Button",track="weapon",tier=3,x=-12,z=31,stage=3},
	{action="armor3",name="Armor3Button",track="armor",tier=3,x=12,z=31,stage=3},
	{action="barracks2",name="Barracks2Button",track="barracks",tier=2,x=0,z=24,stage=2},
	{action="weapon4",name="Weapon4Button",track="weapon",tier=4,repeatFrom=3,x=-24,z=24,stage=4},
	{action="armor4",name="Armor4Button",track="armor",tier=4,repeatFrom=3,x=24,z=24,stage=4},
	{action="barracks3",name="Barracks3Button",track="barracks",tier=3,x=0,z=31,stage=3},
	{action="barracks4",name="Barracks4Button",track="barracks",tier=4,x=24,z=31,stage=4},
}
local fields = {settlement="level",weapon="weaponLevel",armor="armorLevel",barracks="barracksLevel"}
local byAction = {}
for _, definition in definitions do table.freeze(definition); byAction[definition.action]=definition end
return table.freeze({definitions=table.freeze(definitions),byAction=table.freeze(byAction),fields=table.freeze(fields)})
