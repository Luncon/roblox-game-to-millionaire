--!strict
local Shared=game:GetService("ReplicatedStorage").Shared
local Config=require(Shared.MedicalConfig)
local Rules=require(script.Parent.MedicalRules)
local Recovery=require(script.Parent.YardRecovery)
local Medical={}

-- Physics/visual injection is for fake fixtures only; production uses native sweeps.
function Medical.new(world,combat,economy,isActive,clock,physics,visual)
 local now=clock or os.clock
 local space=physics or workspace
 local shots,deadlines,recoveries={}, {},setmetatable({}, {__mode="k"})
 local folder
 local alive=true
 if not visual then
  folder=Instance.new("Folder");folder.Name="MedicalBandages";folder.Parent=world.model
 end
 local function make(origin)
  if visual then return visual(origin) end
  local part=Instance.new("Part")
  part.Name,part.Size,part.Position="Bandage",Vector3.new(.7,.45,.45),origin
  part.Anchored,part.CanCollide,part.CanTouch,part.CanQuery=true,false,false,false
  part.Color,part.Material=Color3.fromRGB(246,238,212),Enum.Material.Fabric
  part.Shape=Enum.PartType.Cylinder
  part.Parent=folder
  return part
 end
 local controller={}
 local function patient(ownerId,rig)
  local a=combat:actor(rig)
  local state=economy:get(ownerId)
  if not alive or not economy:canMutate(ownerId) or not combat:canAct(rig)
   or not Rules.patient(a,ownerId,state) then return nil end
  return a,state
 end
 local function source(rig)
  local a=combat:actor(rig)
  if not alive or not a or a.kind~="medic" or not combat:canAct(rig)
   or not economy:canMutate(a.ownerId) or not isActive(rig) then return nil end
  local state=economy:get(a.ownerId)
  return if state and state.hospitalLevel==1 then a else nil
 end
 local function heal(ownerId,rig,life,amount)
  local a=patient(ownerId,rig)
  if not a or a.humanoid~=life then return 0 end
  local applied=Rules.apply(a,life,amount)
  if applied>0 then
   rig:SetAttribute("LastHealAt",workspace:GetServerTimeNow())
   rig:SetAttribute("LastHealAmount",applied)
  end
  return applied
 end
 function controller:cancel(rig)
  local shot=shots[rig]
  if shot then shots[rig]=nil;shot.part:Destroy() end
 end
 function controller:forget(rig)
  self:cancel(rig)
  local record=recoveries[rig]
  if record and record.connection then record.connection:Disconnect() end
  recoveries[rig]=nil
  rig:SetAttribute("Recovering",nil)
 end
 function controller:count(): number local n=0;for _ in shots do n+=1 end;return n end
 function controller:readyAt(ownerId): number return deadlines[ownerId] or 0 end
 function controller:throw(rig,actors): boolean
  local a=source(rig)
  local time=now()
  if not a or shots[rig] or time<(deadlines[a.ownerId] or 0) then return false end
  local state=economy:get(a.ownerId)
  -- Rank only patients we can actually help; a blocked critical patient must
  -- not prevent a visible wounded fighter from receiving bandages.
  local target=Rules.choose(a,actors,state,Config.range,function(candidate)
   local current=patient(a.ownerId,candidate.rig)
   return current~=nil and current.humanoid==candidate.humanoid and combat:visible(a,current)
  end)
  if not target or not combat:visible(a,target) then return false end
  -- Fresh registration/life checks immediately before launch.
  local current=patient(a.ownerId,target.rig)
  if not current or current.humanoid~=target.humanoid then return false end
  local origin=a.position+Vector3.new(0,1,0)
  local destination=current.position+Vector3.new(0,1,0)
  local duration=math.clamp((destination-origin).Magnitude/Config.speed,.12,.9)
  local velocity=current.root and current.root.AssemblyLinearVelocity or Vector3.zero
  local lead=Vector3.new(velocity.X,0,velocity.Z)*duration
  if lead.Magnitude>12 then lead=lead.Unit*12 end
  destination+=lead
  local filter=RaycastParams.new();filter.FilterType=Enum.RaycastFilterType.Exclude
  filter.FilterDescendantsInstances=if folder then {rig,folder} else {rig}
  local part=make(origin)
  local lives={}
  for _,actor in actors do
   if actor.rig~=rig and actor.alive and actor.claimed and actor.ownerId==a.ownerId
    and actor.civilizationId==a.civilizationId and actor.plotId==a.plotId then lives[actor.rig]=actor.humanoid end
  end
  shots[rig]={part=part,sourceLife=a.humanoid,ownerId=a.ownerId,civilizationId=a.civilizationId,plotId=a.plotId,
   origin=origin,destination=destination,duration=duration,
   began=time,elapsed=0,position=origin,filter=filter,lives=lives}
  deadlines[a.ownerId]=time+Config.cooldown
  rig:SetAttribute("BandageTargetPosition",target.position)
  rig:SetAttribute("BandageThrownAt",workspace:GetServerTimeNow())
  rig:SetAttribute("BandageReadyAt",workspace:GetServerTimeNow()+Config.cooldown)
  return true
 end
 function controller:step()
  local time=now()
  local actors
  for rig,shot in shots do
   local a=source(rig)
   local elapsed=time-shot.began
   if not a or a.humanoid~=shot.sourceLife or a.civilizationId~=shot.civilizationId or a.plotId~=shot.plotId
    or elapsed>Config.lifetime or elapsed-shot.elapsed>.25 then self:cancel(rig);continue end
   -- Subdivide the arc to prevent a chord cutting through an obstacle.
   local untilTime=math.min(elapsed,shot.duration)
   while shot.elapsed<untilTime and shots[rig]==shot do
    local nextTime=math.min(untilTime,shot.elapsed+1/60)
    local t=nextTime/shot.duration
    local point=shot.origin:Lerp(shot.destination,t)+Vector3.new(0,math.sin(t*math.pi)*Config.arc,0)
    local delta=point-shot.position
    local hit=if delta.Magnitude>.001 then space:Spherecast(shot.position,.25,delta,shot.filter) else nil
    local endPoint=if hit then shot.position+delta.Unit*math.max(0,(hit.Distance or delta.Magnitude)-.01) else point
    actors=actors or combat:actors()
    local recipient=Rules.nearest(a,actors,economy:get(a.ownerId),shot.position,endPoint,Config.contactRadius,function(candidate,contact)
     local current=patient(shot.ownerId,candidate.rig)
     if not current or shot.lives[candidate.rig]~=current.humanoid or current.humanoid~=candidate.humanoid
      or (current.position-a.position).Magnitude>Config.range or not combat:visible(a,current) then return false end
     local ray=current.position+Vector3.new(0,1,0)-contact
     local wall=if ray.Magnitude>.001 then space:Raycast(contact,ray,shot.filter) else nil
     return not wall or wall.Instance:IsDescendantOf(current.rig)
    end)
    if recipient then
     self:cancel(rig) -- Consume once before any health mutation.
     heal(shot.ownerId,recipient.rig,shot.lives[recipient.rig],Config.heal)
     break
    end
    if hit then self:cancel(rig);break end
    shot.elapsed,shot.position=nextTime,point
    shot.part.Position=point
   end
   if shots[rig]==shot and elapsed>=shot.duration then self:cancel(rig) end
  end
 end
 function controller:recover(rig,frame)
  local a=combat:actor(rig)
  local state=if a then economy:get(a.ownerId) else nil
  local eligible=a~=nil and economy:canMutate(a.ownerId) and Rules.patient(a,a.ownerId,state)
   and state.trainingLevel==1 and Recovery.contains(frame:PointToObjectSpace(a.position))
  local record=recoveries[rig] or {};recoveries[rig]=record
  if not a then self:forget(rig);return end
  if record.watched~=a.humanoid then
   if record.connection then record.connection:Disconnect() end
   local life=a.humanoid
   record.watched,record.observed=life,life.Health
   if life.HealthChanged then record.connection=life.HealthChanged:Connect(function(health)
    if health<record.observed then record.entered,record.nextAt=nil,nil end
    record.observed=health
   end) end
  end
  local tick=Recovery.step(record,a.humanoid,eligible,now(),rig:GetAttribute("LastHitAt"))
  if tick then heal(a.ownerId,rig,a.humanoid,Config.yardHeal) end
  rig:SetAttribute("Recovering",eligible and record.entered~=nil and now()-record.entered>=2 and a.humanoid.Health<a.humanoid.MaxHealth)
 end
 function controller:destroy()
  alive=false
  for rig in shots do self:cancel(rig) end
  for rig in recoveries do self:forget(rig) end
  table.clear(recoveries);table.clear(deadlines)
  if folder then folder:Destroy() end
 end
 return controller
end
return Medical
