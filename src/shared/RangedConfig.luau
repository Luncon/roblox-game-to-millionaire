--!strict

local variants = {
	sparta={name="Spartan Javelinman",weaponName="Spartan Javelin",weaponKind="spear",projectileKind="spear"},
	britain={name="Redcoat Musketeer",weaponName="Redcoat Musket",weaponKind="musket",projectileKind="bullet"},
	seneca={name="Seneca Archer",weaponName="Woodland Bow",weaponKind="bow",projectileKind="arrow"},
	mongols={name="Mongol Archer",weaponName="Steppe Bow",weaponKind="bow",projectileKind="arrow"},
	vikings={name="Norse Axe Thrower",weaponName="Throwing Axe",weaponKind="axe",projectileKind="axe"},
	persia={name="Persian Archer",weaponName="Persian Bow",weaponKind="bow",projectileKind="arrow"},
	japan={name="Sengoku Archer",weaponName="Yumi Bow",weaponKind="bow",projectileKind="arrow"},
	maurya={name="Mauryan Archer",weaponName="Mauryan Bow",weaponKind="bow",projectileKind="arrow"},
	spain={name="Spanish Crossbowman",weaponName="Spanish Crossbow",weaponKind="crossbow",projectileKind="bolt"},
	egypt={name="Egyptian Slinger",weaponName="Egyptian Sling",weaponKind="sling",projectileKind="stone"},
	rome={name="Roman Javelinman",weaponName="Pilum",weaponKind="spear",projectileKind="spear"},
	ottomans={name="Ottoman Musketeer",weaponName="Ottoman Musket",weaponKind="musket",projectileKind="bullet"},
	ming={name="Ming Crossbowman",weaponName="Ming Crossbow",weaponKind="crossbow",projectileKind="bolt"},
}
for _, variant in variants do table.freeze(variant) end
return table.freeze({range=45,attackCooldown=2,aggroRange=60,speed=90,
	maxProjectiles=32,damageMultiplier=.8,variants=table.freeze(variants)})
