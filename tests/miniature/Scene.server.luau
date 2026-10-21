-- Native checks for the isolated place. Never opens any profile store.
local Replicated=game:GetService('ReplicatedStorage')
local control=Instance.new('RemoteEvent');control.Name='MiniatureTestControl';control.Parent=Replicated
control.OnServerEvent:Connect(function(player,action)
 if action=='respawn'and game.RunService:IsStudio()and player.Character then player.Character.Humanoid.Health=0 end
end)
local ok,result=pcall(function()
 local scene=workspace:WaitForChild('MiniaturePreview',10)
 assert(scene,'Miniature scene is missing')
 assert(not game.ServerScriptService.Game:FindFirstChild('ProfileService'))
 assert(not Replicated:FindFirstChild('CombatRemotes')and not Replicated:FindFirstChild('EconomyRemotes'))
 assert(#scene.Buildings:GetChildren()==3 and #scene.Actors:GetChildren()==6)
 for _,building in scene.Buildings:GetChildren()do
  assert(math.abs(building:GetScale()-.25)<.001,'Wrong building scale')
  assert(building:GetAttribute('Description')and building.SelectTarget.ClickDetector and building.SelectTarget.ProximityPrompt)
  for _,part in building:GetDescendants()do if part:IsA('BasePart')then assert(not part.CanCollide)end end
 end
 local original={}
 for _,actor in scene.Actors:GetChildren()do
  assert(math.abs(actor:GetScale()-.25)<.001,'Wrong actor scale')
  original[actor]=actor:GetPivot().Position
  for _,part in actor:GetDescendants()do if part:IsA('BasePart')then
   assert(not game.PhysicsService:CollisionGroupsAreCollidable(part.CollisionGroup,'Default'),'Actor blocks the commander')
  end end
 end
 local player=game.Players:GetPlayers()[1]or game.Players.PlayerAdded:Wait()
 local deadline=os.clock()+15
 repeat task.wait(.1)until player.Character and player.Character:FindFirstChild('HumanoidRootPart')or os.clock()>deadline
 assert(player.Character and player.Character:GetScale()==1,'Avatar was miniaturized')
 assert(not player.Backpack:FindFirstChildOfClass('Tool')and not player.Character:FindFirstChildOfClass('Tool'))
 local moved={}
 for _=1,220 do
  task.wait(.1)
  for actor,start in original do
   local p=actor:GetPivot().Position
   if (p-start).Magnitude>.6 then moved[actor]=true end
   assert(math.abs(p.X)<20 and math.abs(p.Z)<16,'Actor left the miniature plot')
   assert(p.Y>0 and p.Y<4,'Actor left the ground band')
  end
 end
 local soldiers,workers=0,0
 for actor in original do
  assert(moved[actor],'Actor never moved: '..actor.Name)
  if actor:GetAttribute('PreviewRole')=='soldier'then
   soldiers+=1;assert(actor:FindFirstChildOfClass('Tool'),'Lost miniature weapon')
   assert(math.abs(actor.Torso.Size.Y-.5)<.1,'Body scale drifted')
   assert((actor.Head.Position-actor.Torso.Position).Magnitude<1,'Body joints separated')
  else workers+=1 end
 end
 assert(soldiers==4 and workers==2)
 assert(require(game.ServerStorage.TemplateFingerprint)()==Replicated:GetAttribute('OriginalTemplates'),'Source templates changed')
 return {ok=true,actors=6,buildings=3,seconds=22}
end)
Replicated:SetAttribute('MiniatureSceneResult',game.HttpService:JSONEncode({ok=ok,result=result}))
if not ok then warn(result)end
