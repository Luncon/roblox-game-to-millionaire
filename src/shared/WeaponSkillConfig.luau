--!strict

local Skills = {}
local aliases = {spear="spear",javelin="spear",pilum="spear",axe="axe",sword="sword",sabre="sword",
	katana="sword",rapier="sword",khopesh="sword",gladius="sword",kilij="sword",dao="sword"}
Skills.families = table.freeze({
	spear=table.freeze({name="Dash Thrust",cooldown=8,windup=0,duration=.2,range=12,targets=1}),
	axe=table.freeze({name="Whirlwind",cooldown=12,windup=0,duration=.35,range=6,targets=3}),
	sword=table.freeze({name="Double Slash",cooldown=9,windup=0,duration=.24,range=5,targets=1}),
})
Skills.tiers = table.freeze({
	table.freeze({name="I",unlock=10,cost=100,spear=1.3,axe=.8,sword=.65,second=.75}),
	table.freeze({name="II",unlock=20,cost=200,spear=1.4,axe=.9,sword=.70,second=.80}),
	table.freeze({name="III",unlock=30,cost=350,spear=1.5,axe=1,sword=.75,second=.85}),
	table.freeze({name="IV",unlock=40,cost=550,spear=1.6,axe=1.1,sword=.80,second=.90}),
	table.freeze({name="V",unlock=50,cost=800,spear=1.7,axe=1.2,sword=.85,second=.95}),
})
function Skills.family(kind: string?): string?
	return if kind then aliases[kind] else nil
end
function Skills.description(family: string,level: number): string
	local tier = Skills.tiers[level]
	if not tier then return "" end
	local multiplier = if family=="sword" then tier.sword+tier.second else tier[family]
	return string.format("%g%% DMG · %gs",multiplier*100,Skills.families[family].cooldown)
end
return table.freeze(Skills)
