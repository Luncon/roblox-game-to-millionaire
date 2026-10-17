-- Sustained native encounter measurements. Called only by the fake-store medical suite.
return function(context,player,helpers)
 assert(game:GetService("RunService"):IsStudio() and context.store.isFakeProfileStore)
 local service=context.service
 local Opponents=require(game.ServerScriptService.Game.NeutralOpponentService)
 local results,connections={},{}
 local opponents
 local function army()return assert(service.army:get(player.UserId))end
 local function reset()
  if opponents then opponents:destroy();opponents=nil end
  for _,connection in connections do connection:Disconnect()end;table.clear(connections)
  helpers.choose("britain");helpers.choose("sparta");helpers.order("hold")
 end
 local function spawn(count)
  local definitions={}
  for index=1,count do
   local p=service.world.model.Ground.CFrame:PointToObjectSpace(helpers.floorPoint((index-1)*4,-4))
   table.insert(definitions,{id=tostring(index),kind="warrior",offset=Vector3.new(p.X,0,p.Z)})
  end
  opponents=Opponents.start(service.world,service.combat,{enabled=true,respawnDelay=60,slots=definitions},service.encounters)
  for _,slot in opponents:get()do slot.rig.Humanoid.MaxHealth=1000;slot.rig.Humanoid.Health=1000 end
 end
 local ok,result=pcall(function()
  local folder=service.world.model:FindFirstChild("NeutralOpponents");if folder then folder:Destroy()end
  for _,count in {1,3}do for _,withMedic in {false,true}do
   game:SetAttribute("MedicalSupportVerificationPhase",string.format("Combat: %d enemies, medic %s",count,tostring(withMedic)))
   reset()
   local slots=army().slots
   helpers.freeze(slots.warrior.rig,helpers.floorPoint(0,0))
   helpers.freeze(slots.ranged.rig,helpers.floorPoint(-70,70))
   helpers.freeze(slots.camp.rig,helpers.floorPoint(70,70))
   helpers.freeze(slots.medic.rig,helpers.floorPoint(if withMedic then 0 else -70,if withMedic then 20 else -70))
   local fighter=slots.warrior.rig.Humanoid
   local previous=fighter.Health
   local measurement={opponents=count,medicInRange=withMedic,damage=0,healing=0,healEvents=0,damageEvents=0,peakBandages=0}
   table.insert(connections,fighter.HealthChanged:Connect(function(health)
    local change=health-previous;previous=health
    if change>0 then measurement.healing+=change;measurement.healEvents+=1
    elseif change<0 then measurement.damage-=change;measurement.damageEvents+=1 end
   end))
   spawn(count)
   local began=os.clock()
   while os.clock()-began<12 do
    local flights=#service.world.model.MedicalBandages:GetChildren()
    measurement.peakBandages=math.max(measurement.peakBandages,flights)
    assert(flights<=1,"A medic launched concurrent bandages")
    local identities={}
    for _,rig in service.world.model.Troops:GetChildren()do
     local h=rig:FindFirstChildOfClass("Humanoid")
     if h and h.Health>0 then
      local id=rig:GetAttribute("ArmySlot");assert(not identities[id],"Duplicate living army slot")
      identities[id]=true;assert(h.Health<=h.MaxHealth)
     end
    end
    task.wait(.05)
   end
   measurement.seconds=os.clock()-began;measurement.finalHealth=fighter.Health
   assert(measurement.damageEvents>0,"Native enemy encounters never dealt damage")
   if withMedic then assert(measurement.healEvents>0,"No actual bandage contact during combat")
   else assert(measurement.healing==0,"Out-of-range healer affected the baseline")end
   table.insert(results,measurement)
  end end
  reset()
  local slots=army().slots
  for id,slot in slots do helpers.freeze(slot.rig,helpers.floorPoint(if id=="medic" then 0 else 100,if id=="medic" then 0 else 100))end
  local medic=slots.medic.rig
  spawn(3)
  local deadline=os.clock()+20
  repeat task.wait(.05)until medic.Humanoid.Health<=0 or os.clock()>deadline
  assert(medic.Humanoid.Health<=0,"Native enemies could not kill the non-retaliating medic")
  helpers.waitFor(function()return army().slots.medic.rig==nil end,"natural medic death")
  local replacementAt=army().slots.medic.respawnAt
  assert(replacementAt-workspace:GetServerTimeNow()>14.5)
  local waitingHUD=helpers.inspectHUD()
  opponents:destroy();opponents=nil
  helpers.waitFor(function()return army().slots.medic.rig~=nil end,"natural combat medic replacement",17)
  assert(workspace:GetServerTimeNow()>=replacementAt and army().slots.medic.rig~=medic and army().order=="hold")
  for id,slot in slots do if id~="medic" then assert(army().slots[id].rig==slot.rig,"Medic death replaced a fighter")end end
  return {ok=true,fights=results,naturalMedicDeath=true,replacementAt=replacementAt,waitingHUD=waitingHUD}
 end)
 if opponents then opponents:destroy()end
 for _,connection in connections do connection:Disconnect()end
 assert(ok,result);return result
end
