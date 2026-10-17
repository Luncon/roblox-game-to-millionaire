--!strict
local Formation={
 id='spartan-shieldwall',name='Spartan Shieldwall',civilization='sparta',
 shieldUnlock=15,shieldCost=150,campUnlock=18,campCost=250,
 councilUnlock=19,councilCost=200,unlock=20,cost=250,
 shieldHits=2,shieldFrontDot=.5,
 pace=6,arrivalTolerance=2.5,cohesionTolerance=4.5,
 -- Negative Z is forward. The center leads the two outer shieldmen.
 offsets={warrior=Vector3.new(0,0,-2),camp=Vector3.new(-5,0,0),reinforcement=Vector3.new(5,0,0),
  ranged=Vector3.new(-3,0,9),medic=Vector3.new(3,0,9)},
 roles={warrior='warrior',camp='warrior',reinforcement='warrior',ranged='ranged',medic='medic'},
}
table.freeze(Formation.offsets);table.freeze(Formation.roles)
return table.freeze(Formation)
