-- Two genuine clients, production army/medical services and fake profiles only.
local testing=game:GetService("StudioTestService")
local args=testing:GetTestArgs()
if type(args)~="table" or args.suite~="medical-support"then return end
local Players,Replicated=game:GetService("Players"),game:GetService("ReplicatedStorage")
local context=require(game.ServerStorage.RuntimeTests.ProfileTestContext)
assert(context.store.isFakeProfileStore)
local control=Instance.new("Folder");control.Name="PrototypeTestControl"
local commands,reports=Instance.new("RemoteEvent"),Instance.new("RemoteEvent")
commands.Name,commands.Parent="Command",control;reports.Name,reports.Parent="Report",control
local responses={}
local connection=reports.OnServerEvent:Connect(function(player,id,response)
 responses[id]=responses[id]or {};responses[id][player.UserId]=response
end)
control.Parent=Replicated
local service,sequence=nil,0
local function waitFor(predicate,label,seconds)
 local untilTime=os.clock()+(seconds or 15)
 repeat if predicate()then return end;task.wait(.02)until os.clock()>untilTime
 error("Timed out: "..label)
end
local function round(action,options,target,count)
 sequence+=1;local id="medical-multi-"..sequence
 commands:FireAllClients({round=id,action=action,options=options,target=target})
 waitFor(function()local n=0;for _ in responses[id]or {}do n+=1 end;return n==count end,id,30)
 for _,response in responses[id]do assert(response.executed,tostring(response.result));assert(response.result.ok)end
 return responses[id]
end
local ok,result=pcall(function()
 waitFor(function()
  if #Players:GetPlayers()~=2 or not context.service then return false end
  for _,p in Players:GetPlayers()do if not responses.ready or not responses.ready[p.UserId]
   or not p.Character or not context.service.profiles:isWritable(p.UserId)then return false end end
  return true
 end,"two ready clients and writable fake profiles",60)
 service=context.service;service.neutralOpponents:destroy()
 local players=Players:GetPlayers();table.sort(players,function(a,b)return a.UserId<b.UserId end)
 local Data=require(game.ServerScriptService.Game.ProfileData)
 for i,p in players do
  local id=if i==1 then "sparta"else "britain"
  local state=Data.defaultState();state.coins,state.level,state.barracksLevel,state.trainingLevel,state.armyCampLevel,state.hospitalLevel=1000,10,4,1,1,1
  assert(service.profiles:set(p.UserId,id,state))
  round("civilizationInput",{action="choose",civilization=id},p.UserId,1)
  round("developmentInput",{kind="command",button="Hold"},p.UserId,1)
  p.Character.HumanoidRootPart.Anchored=true
 end
 local function point(x,z)
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include
  params.FilterDescendantsInstances={service.world.model.Ground,service.world.model.Landscape.TerrainSurface}
  local hit=assert(workspace:Raycast(Vector3.new(x,100,z),Vector3.new(0,-200,0),params))
  return Vector3.new(x,hit.Position.Y+3,z)
 end
 local function freeze(rig,p)rig.HumanoidRootPart.Anchored=true;rig:PivotTo(CFrame.new(p))end
 local held={}
 local armies={service.army:get(players[1].UserId),service.army:get(players[2].UserId)}
 for i,army in armies do
  for id,slot in army.slots do freeze(slot.rig,point(if id=="medic" then 300 elseif id=="warrior"then 312 elseif id=="camp"then 330 else 340,if i==1 then -8 else 8))end
  local medic=army.slots.medic.rig;medic.HumanoidRootPart.Anchored=false;medic.HumanoidRootPart:SetNetworkOwner(nil)
  task.wait(.35);assert(service.command(players[i],"order","regroup").ok)
  task.wait(.35);assert(service.command(players[i],"order","hold").ok)
  task.wait(.5);held[i]=medic.HumanoidRootPart.Position
 end
 armies[1].slots.warrior.rig.Humanoid.Health=50;armies[2].slots.warrior.rig.Humanoid.Health=20
 -- Outside the hostile arena, both medics can see the more wounded foreign patient.
 -- They must heal only their own patient. These are actual registered NPCs.
 waitFor(function()return armies[1].slots.warrior.rig.Humanoid.Health>50 and armies[2].slots.warrior.rig.Humanoid.Health>20 end,"isolated first heals",4)
 assert(armies[1].slots.warrior.rig.Humanoid.Health==62 and armies[2].slots.warrior.rig.Humanoid.Health==32)
 local observed=round("medicalObserve",{focus=point(310,0)},nil,2)
 for i,p in players do assert(service.economy:get(p.UserId).coins==1000)
  local delta=armies[i].slots.medic.rig.HumanoidRootPart.Position-held[i]
  assert(delta.Magnitude<.05,"Unanchored Hold medic moved: "..tostring(delta))
 end
 for _,p in players do task.wait(.35);assert(service.command(p,"order","regroup").ok)end
 local patient=armies[1].slots.warrior.rig;patient.Humanoid.Health=50
 local Camp=require(game.ReplicatedStorage.Shared.TrainingCampConfig)
 local own=service.registry:get(players[1].UserId);local foreign=service.registry:get(players[2].UserId)
 local foreignFrame=service.world.model.Plots["Plot"..foreign.plotId].Foundation.CFrame
 freeze(patient,foreignFrame:PointToWorldSpace(Camp.point(1)))
 task.wait(3.2);assert(patient.Humanoid.Health==50,"Foreign yard healed another owner's troop")
 local frame=service.world.model.Plots["Plot"..own.plotId].Foundation.CFrame
 freeze(patient,frame:PointToWorldSpace(Camp.point(1)))
 waitFor(function()return patient.Humanoid.Health==55 end,"own yard recovery",4)
 freeze(armies[1].slots.medic.rig,point(300,-8));freeze(patient,point(312,-8));patient.Humanoid.Health=40
 task.wait(.35);assert(service.command(players[1],"order","hold").ok)
 waitFor(function()return #service.world.model.MedicalBandages:GetChildren()>0 end,"pending switch flight",5)
 local oldMedic=armies[1].slots.medic.rig
 assert(service.select(players[1],"maurya",true).ok)
 assert(not oldMedic.Parent and #service.world.model.MedicalBandages:GetChildren()==0)
 assert(service.army:get(players[2].UserId).slots.medic.rig==armies[2].slots.medic.rig)
 freeze(armies[2].slots.medic.rig,point(300,8))
 local victim=armies[2].slots.warrior.rig;victim.Humanoid.Health=40
 task.wait(.35);assert(service.command(players[2],"order","hold").ok)
 waitFor(function()return #service.world.model.MedicalBandages:GetChildren()>0 end,"pending lease-loss flight",5)
 local key="User_"..players[2].UserId
 local stored=assert(context.store:read(key));stored.session.token="medical-foreign-lease"
 context.store:seed(key,stored)
 assert(not service.profiles:save(players[2].UserId).ok and not service.profiles:isWritable(players[2].UserId))
 task.wait(.4);assert(victim.Humanoid.Health==40 and #service.world.model.MedicalBandages:GetChildren()==0)
 local evidence={}
 for id,response in observed do evidence[tostring(id)]=response.result end
 return {ok=true,cases=5,clients=2,evidence=evidence,foreignHealingRejected=true,foreignYardRejected=true,switchCancelled=true,leaseLossCancelled=true}
end)
if service then
 for _,p in Players:GetPlayers()do
  if p.Character then p.Character.HumanoidRootPart.Anchored=false end
  local army=service.army:get(p.UserId)
  if army then for _,slot in army.slots do if slot.rig then slot.rig.HumanoidRootPart.Anchored=false end end end
 end
end
connection:Disconnect();control:Destroy()
testing:EndTest(if ok then result else {ok=false,message=tostring(result)})
