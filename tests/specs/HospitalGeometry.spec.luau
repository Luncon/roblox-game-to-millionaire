-- Native transformed geometry matrix; standalone logic doubles cannot prove this.
return function()
 local Game=game.ServerScriptService.Game
 local Shared=game.ReplicatedStorage.Shared
 local Map=require(Game.BattlefieldMap)
 local Sites=require(Shared.SettlementSites)
 local Layout=require(Shared.WorldConfig)
 local Topography=require(Game.Topography)
 local Data=require(Game.ProfileData)
 local container=Instance.new("Folder");container.Name="HospitalGeometryFixture";container.Parent=workspace
 local cases=0
 local ok,message=pcall(function()
  local world=Map.build(container)
  world.model:PivotTo(CFrame.new(3100,20,-3400)*CFrame.Angles(0,.43,0)*world.model:GetPivot())
  local parts=0;for _,p in world.model.Landscape:GetDescendants()do if p:IsA("BasePart")then parts+=1 end end
  assert(parts<=2000,"Hospital reservations exceeded landscape budget")
  for id=1,8 do
   local localFrame=Layout.plotFrame(id)
   for _,site in {Sites.hospital,Sites.hospitalPad,Sites.hospitalSpawn}do
    local p=localFrame:PointToWorldSpace(site)
    assert(Topography.isReserved(p,0,false),"Unreserved hospital/control/spawn")
    assert(math.abs(Topography.sampleHeight(p.X,p.Z)-.15)<.001,"Hospital site is not flat")
   end
   for _,civ in require(Shared.Civilizations)do
    for level=5,50 do
     world:setOwner(id,civ,9101,"HospitalGeometry",level)
     local s=Data.defaultState();s.level=level;s.trainingLevel=1
     s.hospitalLevel=if level>=10 then 1 else 0
     world:syncInfrastructure(id,s,civ)
     local plot=world.model.Plots["Plot"..id]
     local hospital=plot.Infrastructure:FindFirstChild("Hospital")
     if level<10 then assert(not hospital);continue end
     assert(hospital)
     local footprint=plot.Foundation.CFrame:PointToObjectSpace(hospital.FoundationFooting.Position)
     assert(footprint.Z-hospital.FoundationFooting.Size.Z/2>128,"Hospital enters final foundation")
     local total=0
     for _,p in plot:GetDescendants()do if p:IsA("BasePart")then total+=1 end end
     assert(total<=400,civ.id.." hospital settlement exceeded 400 parts: "..total)
     for _,p in hospital:GetDescendants()do if p:IsA("BasePart")then
      for _,x in {-1,1}do for _,z in {-1,1}do
       local point=p.CFrame:PointToWorldSpace(Vector3.new(x*p.Size.X/2,0,z*p.Size.Z/2))
       local localPoint=plot.Foundation.CFrame:PointToObjectSpace(point)
       assert(math.abs(localPoint.X-Sites.hospital.X)<=Sites.hospitalHalfSize.X+.01 and math.abs(localPoint.Z-Sites.hospital.Z)<=Sites.hospitalHalfSize.Z+.01,"Hospital escaped reserved footprint")
       local groundPoint=world.model.Ground.CFrame:PointToObjectSpace(point)
       assert(math.abs(groundPoint.X)<=800 and math.abs(groundPoint.Z)<=800,"Hospital escaped world")
      end end
     end end
     local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={plot.Settlement}
     params.RespectCanCollide=true
     local from=plot.Foundation.CFrame:PointToWorldSpace(Vector3.new(0,3,Sites.hospitalAccessStart))
     local to=plot.Foundation.CFrame:PointToWorldSpace(Sites.hospitalSpawn)
     local obstruction=workspace:Blockcast(CFrame.new(from),Vector3.new(3,4,3),to-from,params)
     assert(not obstruction,civ.id.." rear hospital corridor blocked at level "..level..": "..(if obstruction then obstruction.Instance.Name else ""))
    end
    cases+=1;task.wait()
   end
  end
  print("PASS: hospital native matrix: 8 plots, 13 civilizations, levels 5 through 50, rotated world")
 end)
 container:Destroy();assert(ok,message)
 return cases
end
