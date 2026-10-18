return function()
 local module=game.ServerScriptService.Game:FindFirstChild('ShieldCombat')
 assert(module,'Two-hit combat shields are not implemented')
 local Shield=require(module)
 local n=0
 local function test(name,fn)fn();n+=1;print('PASS: '..name)end
 local function rig()
  local values={}
  return {GetAttribute=function(_,k)return values[k]end,SetAttribute=function(_,k,v)values[k]=v end,GetDescendants=function()return {}end}
 end
 local function target(kind,civ,state)
  local r=rig();Shield.refresh(r,civ or 'sparta',kind or 'warrior',state or {shieldLevel=1,armorLevel=15,armorerLevel=1})
  return {rig=r,position=Vector3.zero,root={CFrame={LookVector=Vector3.new(0,0,-1)}}}
 end
 test('only trained Spartan players and melee receive two charges',function()
  for _,kind in {'player','warrior'}do assert(target(kind).rig:GetAttribute('ShieldCharges')==2)end
  for _,kind in {'ranged','medic'}do assert(target(kind).rig:GetAttribute('ShieldCharges')==0)end
  assert(target('warrior','britain').rig:GetAttribute('ShieldCharges')==0)
  assert(target('warrior','sparta',{shieldLevel=0,armorLevel=15}).rig:GetAttribute('ShieldCharges')==0)
 end)
 test('two frontal validated contacts exhaust protection and the third deals ordinary damage',function()
  local t=target()
  assert(Shield.block(t,Vector3.new(0,0,-4)) and t.rig:GetAttribute('ShieldCharges')==1)
  assert(Shield.block(t,Vector3.new(0,0,-4)) and t.rig:GetAttribute('ShieldCharges')==0)
  assert(not Shield.block(t,Vector3.new(0,0,-4)))
 end)
 test('side rear and coincident sources do not consume a charge',function()
  local t=target()
  for _,p in {Vector3.new(4,0,0),Vector3.new(0,0,4),Vector3.zero}do assert(not Shield.block(t,p))end
  assert(t.rig:GetAttribute('ShieldCharges')==2)
 end)
 test('equipment refreshes and armor upgrades cannot refill a damaged life',function()
  local t=target();assert(Shield.block(t,Vector3.new(0,0,-4)))
  Shield.refresh(t.rig,'sparta','warrior',{shieldLevel=1,armorLevel=50,armorerLevel=1})
  assert(t.rig:GetAttribute('ShieldCharges')==1)
  assert(Shield.block(t,Vector3.new(0,0,-4)))
  Shield.refresh(t.rig,'sparta','warrior',{shieldLevel=1,armorLevel=50,armorerLevel=1})
  assert(t.rig:GetAttribute('ShieldCharges')==0 and target().rig:GetAttribute('ShieldCharges')==2)
 end)
 test('a newly bought training unlock grants once and identity switches discard stale shields',function()
  local t=target('player','sparta',{shieldLevel=0})
  Shield.refresh(t.rig,'sparta','player',{shieldLevel=1});assert(t.rig:GetAttribute('ShieldCharges')==2)
  Shield.refresh(t.rig,'britain','player',{shieldLevel=0});assert(t.rig:GetAttribute('ShieldCharges')==0)
 end)
 test('switching civilizations on the same player life cannot refill shields',function()
  local t=target('player');assert(Shield.block(t,Vector3.new(0,0,-4)))
  Shield.refresh(t.rig,'britain','player',{shieldLevel=0})
  Shield.refresh(t.rig,'sparta','player',{shieldLevel=1})
  assert(t.rig:GetAttribute('ShieldCharges')==1)
 end)
 return n
end
