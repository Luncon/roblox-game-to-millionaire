--!strict

local variants = {
	sparta = {name="Spartan Warrior", weaponName="Dory Spear", weaponKind="spear"},
	britain = {name="Redcoat Warrior", weaponName="Officer Sword", weaponKind="sword"},
	seneca = {name="Seneca Warrior", weaponName="Woodland Axe", weaponKind="axe"},
	mongols = {name="Mongol Warrior", weaponName="Steppe Sabre", weaponKind="sabre"},
	vikings = {name="Norse Warrior", weaponName="Norse Axe", weaponKind="axe"},
	persia = {name="Persian Warrior", weaponName="Persian Spear", weaponKind="spear"},
	japan = {name="Sengoku Warrior", weaponName="Katana", weaponKind="katana"},
	maurya = {name="Mauryan Warrior", weaponName="Mauryan Spear", weaponKind="spear"},
	spain = {name="Spanish Warrior", weaponName="Spanish Rapier", weaponKind="rapier"},
	egypt = {name="Egyptian Warrior", weaponName="Khopesh", weaponKind="khopesh"},
	rome = {name="Roman Warrior", weaponName="Gladius", weaponKind="sword"},
	ottomans = {name="Ottoman Warrior", weaponName="Kilij", weaponKind="sabre"},
	ming = {name="Ming Warrior", weaponName="Dao", weaponKind="sabre"},
}
for _, variant in variants do table.freeze(variant) end
table.freeze(variants)
return table.freeze({
	unlockLevel=2, maxTroops=1, respawnDelay=15,
	maxHealth=100, damage=10, attackCooldown=1, attackRange=5,
	aggroRange=35, walkSpeed=12, thinkInterval=.2,
	arenaHeightTolerance=16, corpseLifetime=3, variants=variants,
})
