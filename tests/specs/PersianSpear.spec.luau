return function()
 local G=game.ServerScriptService.Game
 local Equipment=require(G.Equipment);local Rig=require(G.WarriorRig)
 local civs={};for _,c in require(game.ReplicatedStorage.Shared.Civilizations)do civs[c.id]=c end
 local container=Instance.new('Folder');container.Parent=workspace
 local original=game.ServerStorage.EquipmentTemplates.spear
 local sourcePivot=original:GetPivot();local sourceHandle=original.Handle.CFrame
 local function check(rig,player)
  local tool=rig:FindFirstChildOfClass('Tool');assert(tool)
  local handle=tool:FindFirstChild(if player then 'Handle' else 'WarriorHandle');assert(handle)
  local visual=tool:FindFirstChild('spear');assert(visual)
  local frame=handle.CFrame:ToObjectSpace(visual.VisualHandle.CFrame)
  local direction=frame.RightVector:Dot(Vector3.xAxis)
  assert(if rig:GetAttribute('CivilizationId')=='persia' then direction<-.999 else direction>.999)
 end
 local ok,result=pcall(function()
  for _,id in {'persia','maurya'}do
   local state={weaponLevel=20,armorLevel=15}
   local rig=Rig.create(civs[id],CFrame.new(9000,9000,9000),101,1,state,'warrior');rig.Parent=container
   check(rig,false)
   local fake={Character=rig,FindFirstChildOfClass=function()return nil end}
   assert(Equipment.apply(fake,civs[id],state,true));check(rig,true)
  end
  assert(original:GetPivot()==sourcePivot and original.Handle.CFrame==sourceHandle)
  return 1
 end)
 container:Destroy();assert(ok,result);return result
end
