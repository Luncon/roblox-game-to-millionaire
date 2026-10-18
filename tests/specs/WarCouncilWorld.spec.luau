return function()
 local Game=game.ServerScriptService.Game
 local Map=require(Game.BattlefieldMap)
 local Sites=require(game.ReplicatedStorage.Shared.SettlementSites)
 local Topography=require(Game.Topography)
 assert(Sites.warCouncil,'Council site is missing')
 local box=Instance.new('Folder');box.Parent=workspace
 local world=Map.build(box);local n=0
 local function test(name,fn)fn();n+=1;print('PASS: '..name)end
 local ok,result=pcall(function()
  test('all factions have an accessible map room beside camp on every rotated plot',function()
   for id=1,8 do for _,civ in require(game.ReplicatedStorage.Shared.Civilizations)do
    world:setOwner(id,civ,100+id,'CouncilTester',20)
    world:syncControls(id,{level=20,weaponLevel=10,armorLevel=15,barracksLevel=6,trainingLevel=1,
     armyCampLevel=2,hospitalLevel=1,armorerLevel=1,warCouncilLevel=1,shieldLevel=0,formationLevel=0})
    local plot=world.model.Plots['Plot'..id];local room=assert(plot.Infrastructure:FindFirstChild('WarCouncil'))
    local map=assert(room:FindFirstChild('MapTable'))
    assert(map:FindFirstChildOfClass('ProximityPrompt') and map:FindFirstChildOfClass('ClickDetector'))
    assert(not plot.Controls:FindFirstChild('WarCouncilButton'))
    assert((plot.Controls:FindFirstChild('ShieldButton')~=nil)==(require(game.ReplicatedStorage.Shared.FormationConfig).forCivilization(civ.id)~=nil))
    local shield=plot.Controls:FindFirstChild('ShieldButton')
    if shield then assert(shield.Position.Y-shield.Size.Y/2>=plot.Foundation.Position.Y+plot.Foundation.Size.Y/2,'Shield pad is buried in the foundation')end
    local filter=OverlapParams.new();filter.FilterType=Enum.RaycastFilterType.Include
    filter.FilterDescendantsInstances={plot.Infrastructure,plot.Settlement};filter.RespectCanCollide=true
    for z=22,36,2 do
     local frame=plot.Foundation.CFrame*CFrame.new(Sites.warCouncil.X,3,z)
     assert(#workspace:GetPartBoundsInBox(frame,Vector3.new(4,5,2),filter)==0,'Council entrance is blocked')
    end
    local center=plot.Foundation.CFrame:PointToWorldSpace(Sites.warCouncil)
    assert(Topography.isReserved(center,0,true) and math.abs(Topography.sampleHeight(center.X,center.Z)-.15)<.001)
   end end
  end)
  test('council and formation pads are physical eligible purchases beside the room',function()
   local civ=require(game.ReplicatedStorage.Shared.Civilizations)[1]
   world:setOwner(1,civ,101,'CouncilTester',20)
   local s={level=20,weaponLevel=10,armorLevel=15,barracksLevel=6,trainingLevel=1,armyCampLevel=2,
    hospitalLevel=1,armorerLevel=1,warCouncilLevel=0,shieldLevel=1,formationLevel=0}
   world:syncControls(1,s);local plot=world.model.Plots.Plot1
   assert(plot.Controls:FindFirstChild('WarCouncilButton') and not plot.Infrastructure:FindFirstChild('WarCouncil'))
   s.warCouncilLevel=1;world:syncControls(1,s)
   assert(plot.Controls:FindFirstChild('FormationButton') and not plot.Controls:FindFirstChild('ShieldButton'))
   s.formationLevel=1;world:syncControls(1,s);assert(not plot.Controls:FindFirstChild('FormationButton'))
   local parts=0;for _,p in world.model.Landscape:GetDescendants()do if p:IsA('BasePart')then parts+=1 end end
   assert(parts<=2000,'Landscape exceeded its static part budget: '..parts)
  end)
  return n
 end)
 box:Destroy();assert(ok,result);return result
end
