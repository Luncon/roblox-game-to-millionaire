--!strict
local Formation={
 shieldUnlock=15,shieldCost=150,campUnlock=18,campCost=250,
 councilUnlock=19,councilCost=200,unlock=20,cost=250,
 shieldHits=2,shieldFrontDot=.5,
 pace=6,arrivalTolerance=2.5,cohesionTolerance=4.5,
 roles={warrior='warrior',camp='warrior',reinforcement='warrior',ranged='ranged',medic='medic'},
}
-- Negative Z is forward. Each definition owns its geometry and guard headings.
local definitions={
 ['seneca-focused-volley']={
  id='seneca-focused-volley',name='Seneca Focused Volley',civilization='seneca',requiresShields=false,
  description='1 guard, 3 archers, 1 medic\nConcentrated fire from a loose crescent',
  composition='1 melee, 3 ranged, 1 medic',volley=true,screenRange=40,guardRadius=14,archerRadius=8,shotSpacing=.45,
  roles={warrior='warrior',camp='ranged',reinforcement='ranged',ranged='ranged',medic='medic'},
  offsets={warrior=Vector3.new(0,0,-6),camp=Vector3.new(-10,0,2),reinforcement=Vector3.new(10,0,2),
   ranged=Vector3.new(0,0,5),medic=Vector3.new(5,0,11)},
  facingAngles={},
 },
 ['viking-shield-wedge']={
  id='viking-shield-wedge',name='Viking Shield Wedge',civilization='vikings',
  description='3 shieldmen in a pointed wedge\nBreaks into combat at melee contact',
  breakOnMeleeContact=true,
  frontLeadMinimum=4,supportDepthMinimum=10,supportSpacingMinimum=3,
  offsets={warrior=Vector3.new(0,0,-6),camp=Vector3.new(-5,0,0),reinforcement=Vector3.new(5,0,0),
   ranged=Vector3.new(-3,0,8),medic=Vector3.new(3,0,8)},
  facingAngles={},
 },
 ['spartan-shieldwall']={
  id='spartan-shieldwall',name='Spartan Shieldwall',civilization='sparta',skillFamily='spear',
  description='3 shieldmen in a shallow arc\nRanged + medic side by side behind',
  frontLeadMinimum=.5,supportDepthMinimum=7,supportSpacingMinimum=3,
  offsets={warrior=Vector3.new(0,0,-2),camp=Vector3.new(-5,0,0),reinforcement=Vector3.new(5,0,0),
   ranged=Vector3.new(-3,0,9),medic=Vector3.new(3,0,9)},
  facingAngles={},
 },
 ['persian-archer-screen']={
  id='persian-archer-screen',name='Persian Archer Screen',civilization='persia',skillFamily='spear',
  description='3 shieldmen in a straight line\nStops for bow fire; guards stay nearby',
  screenRange=30,approachRange=45,approachSpeedMultiplier=.5,guardRadius=6,
  frontLeadMinimum=-1,frontLeadMaximum=1,supportDepthMinimum=7,supportSpacingMinimum=3,
  offsets={warrior=Vector3.new(0,0,0),camp=Vector3.new(-6,0,0),reinforcement=Vector3.new(6,0,0),
   ranged=Vector3.new(-3,0,9),medic=Vector3.new(3,0,9)},
  facingAngles={},
 },
 ['roman-shield-guard']={
  id='roman-shield-guard',name='Roman Shield Guard',civilization='rome',skillFamily='sword',
  description='3 shieldmen guard a compact group\nJavelin + medic protected between flank guards',
  frontLeadMinimum=2,supportDepthMinimum=4,supportSpacingMinimum=2.5,
  offsets={warrior=Vector3.new(0,0,-5),camp=Vector3.new(-5.5,0,0),reinforcement=Vector3.new(5.5,0,0),
   ranged=Vector3.new(-1.75,0,1.5),medic=Vector3.new(1.75,0,1.5)},
  facingAngles={camp=-math.pi/4,reinforcement=math.pi/4},
 },
}
local byCivilization={}
for _,definition in definitions do
 if definition.roles then table.freeze(definition.roles)end
 table.freeze(definition.offsets);table.freeze(definition.facingAngles);table.freeze(definition)
 byCivilization[definition.civilization]=definition
end
Formation.byId=table.freeze(definitions)
function Formation.forCivilization(id: string?)return if id then byCivilization[id] else nil end
function Formation.rolesFor(definition)return definition.roles or Formation.roles end
function Formation.usesShields(id: string?)
 local definition=Formation.forCivilization(id)
 return definition~=nil and definition.requiresShields~=false
end
table.freeze(Formation.roles)
return table.freeze(Formation)
