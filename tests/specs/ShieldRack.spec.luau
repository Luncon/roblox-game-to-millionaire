return function()
 local G=game.ServerScriptService.Game;local S=game.ReplicatedStorage.Shared
 local Rack=require(G.ShieldRack);local Shield=require(G.ShieldCombat);local Sites=require(S.SettlementSites)
 local n=0;local function test(name,fn)fn();n+=1;print('PASS: '..name)end
 local container=Instance.new('Folder');container.Parent=workspace
 local function fixture(id,slot,kind)
  local civ;for _,candidate in require(S.Civilizations)do if candidate.id==id then civ=candidate end end
  local plot=Instance.new('Model');plot:SetAttribute('OwnerId',101);plot:SetAttribute('CivilizationId',id);plot.Parent=container
  local infrastructure=Instance.new('Folder');infrastructure.Parent=plot
  local rack=Rack.build(infrastructure,CFrame.new(0,10000,0),civ)
  local state={weaponLevel=20,armorLevel=15,shieldLevel=1}
  local rig=require(G.WarriorRig).create(civ,CFrame.new(Rack.goal(rack,slot)),101,1,state,kind or 'warrior')
  rig:SetAttribute('ArmySlot',slot);rig.HumanoidRootPart.Anchored=true;rig.Parent=container
  return rack,rig,state,plot
 end
 local function spend(rig)
  rig:SetAttribute('ShieldCharges',0);rig:SetAttribute('SpartanShieldRemaining',0)
  for _,item in rig:GetDescendants()do if item:GetAttribute('CombatShield')==true then item:Destroy()end end
 end
 local ok,result=pcall(function()
  test('unlocked shield racks display immutable inert shield clones and separated assigned pickup points',function()
   local source=game.ServerStorage.EquipmentTemplates['spartan-shield'];local before=source:GetDescendants();local pivot=source:GetPivot()
   for _,id in {'sparta','rome','persia'}do
    local rack=fixture(id,'warrior');local displays=0
    for _,item in rack:GetDescendants()do
     assert(not item:IsA('BaseScript') and not item:IsA('Humanoid'))
     if item:IsA('BasePart')then assert(item.Anchored and not item.CanTouch)end
     if item:GetAttribute('TemplateId')=='spartan-shield'then displays+=1 end
    end
    assert(displays==3 and Rack.unlocked({id=id},{shieldLevel=1}))
    assert((Rack.goal(rack,'warrior')-Rack.goal(rack,'camp')).Magnitude>=4)
    assert((Sites.shieldRack-require(S.TrainingCampConfig).center).Magnitude<=30)
   end
   assert(source:GetPivot()==pivot and #source:GetDescendants()==#before)
   assert(not Rack.unlocked({id='britain'},{shieldLevel=1}) and not Rack.unlocked({id='rome'},{shieldLevel=0}))
  end)
  test('rack restores only a spent recalled current owned living melee within its assigned pickup',function()
   for _,id in {'sparta','rome','persia'}do
    local rack,rig,state=fixture(id,'warrior');spend(rig)
    local tool=rig:FindFirstChildOfClass('Tool');local torso=rig.Torso;local joint=torso['Right Shoulder'];local base=joint.C0
    rig.Humanoid.Health=57;rig:SetAttribute('WeaponSkillReadyAt',12345)
    local point=Rack.goal(rack,'warrior');rig:PivotTo(CFrame.new(point+Vector3.new(10,0,0)))
    assert(not Rack.collect(rig,rack,'warrior','regroup',state,true))
    rig:PivotTo(CFrame.new(point));assert(not Rack.collect(rig,rack,'warrior','hold',state,true))
    assert(not Rack.collect(rig,rack,'warrior','regroup',state,false))
    assert(not Rack.collect(rig,rack,'camp','regroup',state,true))
    assert(Rack.collect(rig,rack,'warrior','regroup',state,true))
    assert(rig:GetAttribute('ShieldCharges')==2 and rig.Humanoid.Health==57 and rig:GetAttribute('WeaponSkillReadyAt')==12345)
    assert(rig:FindFirstChildOfClass('Tool')==tool and torso['Right Shoulder']==joint and joint.C0==base)
    local count=0;for _,item in rig:GetDescendants()do if item:GetAttribute('CombatShield')==true then count+=1 end end
    assert(count==1 and not Rack.collect(rig,rack,'warrior','regroup',state,true))
    assert(Shield.block({rig=rig,root=rig.HumanoidRootPart,position=point},point+Vector3.new(0,0,-4)))
    assert(not Rack.collect(rig,rack,'warrior','regroup',state,true) and rig:GetAttribute('ShieldCharges')==1)
   end
  end)
  test('rack rejects foreign claims factions dead troops and unsupported roles',function()
   local rack,rig,state,plot=fixture('sparta','warrior');spend(rig)
   plot:SetAttribute('OwnerId',102);assert(not Rack.collect(rig,rack,'warrior','regroup',state,true))
   plot:SetAttribute('OwnerId',101);rig:SetAttribute('CivilizationId','rome');assert(not Rack.collect(rig,rack,'warrior','regroup',state,true))
   rig:SetAttribute('CivilizationId','sparta');rig.Humanoid.Health=0;assert(not Rack.collect(rig,rack,'warrior','regroup',state,true))
   for _,kind in {'ranged','medic'}do local r,t,s=fixture('sparta','camp',kind);spend(t);assert(not Rack.collect(t,r,'camp','regroup',s,true))end
  end)
  return n
 end)
 container:Destroy();assert(ok,result);return result
end
