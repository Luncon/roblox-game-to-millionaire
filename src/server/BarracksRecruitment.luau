--!strict
local Players=game:GetService('Players')
local Service={}

function Service.new(world,registry,economy,event,publish)
 local bindings,traffic={},{}
 local controller={}
 local function nearby(player)
  if player.Parent~=Players or not economy:canMutate(player.UserId)then return nil,'profile_unavailable'end
  local claim,state=registry:get(player.UserId),economy:get(player.UserId)
  if not claim or not state or state.level<2 then return nil,'barracks_locked'end
  local character=player.Character;local root=character and character:FindFirstChild('HumanoidRootPart')
  local hum=character and character:FindFirstChildOfClass('Humanoid')
  if not root or not hum or hum.Health<=0 or not character:IsDescendantOf(workspace)then return nil,'not_alive'end
  local plot=world.model.Plots:FindFirstChild('Plot'..claim.plotId)
  local barracks=plot and plot.Settlement:FindFirstChild('Barracks')
  local board=barracks and barracks:FindFirstChild('RecruitmentBoard')
  if not board or plot:GetAttribute('OwnerId')~=player.UserId or plot:GetAttribute('CivilizationId')~=claim.civilizationId
   or (root.Position-board.Position).Magnitude>14 then return nil,'barracks_too_far'end
  return {board=board,claim=claim,state=state}
 end
 function controller:open(player)
  local data,reason=nearby(player);if not data then return {ok=false,reason=reason}end
  local time=os.clock()
  if traffic[player.UserId] and time-traffic[player.UserId]<.3 then return {ok=false,reason='rate_limited'}end
  traffic[player.UserId]=time
  event:FireClient(player,{board=data.board,civilizationId=data.claim.civilizationId})
  return {ok=true}
 end
 function controller:select(player,value)
  local data,reason=nearby(player);if not data then return {ok=false,reason=reason}end
  local result=economy:selectComposition(player.UserId,value)
  publish(player,result,'composition');return result
 end
 function controller:sync()
  for board,connections in bindings do if not board:IsDescendantOf(world.model)then
   for _,c in connections do c:Disconnect()end;bindings[board]=nil
  end end
  for _,plot in world.model.Plots:GetChildren()do
   local barracks=plot.Settlement:FindFirstChild('Barracks')
   local board=barracks and barracks:FindFirstChild('RecruitmentBoard')
   if board and not bindings[board]then bindings[board]={
    board:FindFirstChildOfClass('ProximityPrompt').Triggered:Connect(function(player)self:open(player)end),
    board:FindFirstChildOfClass('ClickDetector').MouseClick:Connect(function(player)self:open(player)end)}end
  end
 end
 function controller:release(id)traffic[id]=nil end
 function controller:destroy()
  for _,connections in bindings do for _,c in connections do c:Disconnect()end end
  table.clear(bindings);table.clear(traffic)
 end
 return controller
end
return Service
