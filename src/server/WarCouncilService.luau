--!strict
local Players=game:GetService('Players')
local Config=require(game.ReplicatedStorage.Shared.FormationConfig)
local Council={}
function Council.new(world,registry,economy,event,publish,onSelect)
 local controller={};local bindings={};local traffic={}
 local function nearby(player)
  if player.Parent~=Players or not economy:canMutate(player.UserId)then return nil,'profile_unavailable' end
  local claim=registry:get(player.UserId);local state=economy:get(player.UserId)
  if not claim or not state or state.warCouncilLevel~=1 then return nil,'council_locked' end
  local char=player.Character;local root=char and char:FindFirstChild('HumanoidRootPart')
  local hum=char and char:FindFirstChildOfClass('Humanoid')
  if not root or not hum or hum.Health<=0 or not char:IsDescendantOf(workspace)then return nil,'not_alive' end
  local infrastructure=world.model.Plots['Plot'..claim.plotId]:FindFirstChild('Infrastructure')
  local room=infrastructure and infrastructure:FindFirstChild('WarCouncil')
  local map=room and room:FindFirstChild('MapTable')
  if not map or (root.Position-map.Position).Magnitude>14 then return nil,'council_too_far' end
  return {state=state,claim=claim,map=map}
 end
 function controller:open(player)
  local data,reason=nearby(player);if not data then return {ok=false,reason=reason}end
  local now=os.clock();if traffic[player.UserId] and now-traffic[player.UserId]<.3 then return {ok=false,reason='rate_limited'}end
  traffic[player.UserId]=now
  event:FireClient(player,{map=data.map,civilizationId=data.claim.civilizationId,
   unlocked=data.state.formationLevel==1,selected=data.state.selectedFormation})
  return {ok=true}
 end
 function controller:select(player,value)
  local data,reason=nearby(player);if not data then return {ok=false,reason=reason}end
  if value~=Config.id and value~='none' then return {ok=false,reason='invalid'}end
  local result=economy:selectFormation(player.UserId,value)
  if result.ok then onSelect(player)end
  publish(player,result,'formationSelection');return result
 end
 function controller:sync()
  for map,connections in bindings do if not map:IsDescendantOf(world.model)then
   for _,c in connections do c:Disconnect()end;bindings[map]=nil
  end end
  for _,plot in world.model.Plots:GetChildren()do
   local infrastructure=plot:FindFirstChild('Infrastructure');local room=infrastructure and infrastructure:FindFirstChild('WarCouncil')
   local map=room and room:FindFirstChild('MapTable')
   if map and not bindings[map]then bindings[map]={
    map:FindFirstChildOfClass('ProximityPrompt').Triggered:Connect(function(p)self:open(p)end),
    map:FindFirstChildOfClass('ClickDetector').MouseClick:Connect(function(p)self:open(p)end)}end
  end
 end
 function controller:release(id)traffic[id]=nil end
 function controller:destroy()
  for _,connections in bindings do for _,c in connections do c:Disconnect()end end
  table.clear(bindings);table.clear(traffic)
 end
 return controller
end
return Council
