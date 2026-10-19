--!strict
local Shared=game:GetService('ReplicatedStorage').Shared
local Sites=require(Shared.SettlementSites)
local Config=require(Shared.FormationConfig)
local Shield=require(script.Parent.ShieldCombat)
local Equipment=require(script.Parent.Equipment)
local Visuals=require(script.Parent.EquipmentVisuals)
local Rack={}
local pickups={warrior=-4,camp=0,reinforcement=4}

function Rack.unlocked(civ,state)
 return civ and Config.forCivilization(civ.id)~=nil and state and state.shieldLevel==1
end
function Rack.needs(rig,state)
 return rig:GetAttribute('WarriorClass')=='warrior' and state and state.shieldLevel==1
  and Config.forCivilization(rig:GetAttribute('CivilizationId'))~=nil
  and rig:GetAttribute('ShieldCharges')==0 and rig:GetAttribute('SpartanShieldRemaining')==0
end
function Rack.build(parent,frame,civ)
 local rack=Instance.new('Model');rack.Name='ShieldRack';rack:SetAttribute('CivilizationId',civ.id)
 local origin=frame*CFrame.new(Sites.shieldRack)
 local function part(name,size,offset,solid)
  local p=Instance.new('Part');p.Name,p.Size,p.CFrame=name,size,origin*CFrame.new(offset)
  p.Anchored,p.CanCollide,p.CanQuery,p.CanTouch=true,solid,solid,false
  p.Material,p.Color=Enum.Material.WoodPlanks,Color3.fromRGB(111,78,48);p.Parent=rack;return p
 end
 for _,x in {-6,6}do part('Upright',Vector3.new(.6,5,.6),Vector3.new(x,1.65,0),true)end
 part('Rail',Vector3.new(13,.5,.5),Vector3.new(0,3,0),true)
 for slot,x in pickups do
  local point=part('Pickup_'..slot,Vector3.new(1,1,1),Vector3.new(x,2.15,5),false);point.Transparency=1
  local visual=Visuals.clone('spartan-shield')
  if visual then
   visual.Name='StockShield_'..slot;visual:ScaleTo(.7)
   visual:PivotTo(origin*CFrame.new(x,2,0)*CFrame.Angles(0,math.pi,0))
   for _,item in visual:GetDescendants()do if item:IsA('BasePart')then item.Anchored=true end end
   visual.Parent=rack
  end
 end
 local sign=part('SupplySign',Vector3.new(12,1.5,.2),Vector3.new(0,4.5,0),false)
 local gui=Instance.new('SurfaceGui');gui.Face=Enum.NormalId.Back;gui.CanvasSize=Vector2.new(600,80);gui.Parent=sign
 local label=Instance.new('TextLabel');label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1
 label.Text,label.Font,label.TextScaled='SHIELD SUPPLIES',Enum.Font.GothamBold,true
 label.TextColor3=Color3.fromRGB(255,239,191);label.Parent=gui
 rack.Parent=parent;return rack
end
function Rack.goal(rack,slot)
 local point=rack and rack:FindFirstChild('Pickup_'..slot)
 -- The rear slot can also recruit a fourth melee in a custom composition.
 if not point and slot=='ranged' and rack then
  local center=rack:FindFirstChild('Pickup_camp')
  return if center then center.Position+center.CFrame.RightVector*8 else nil
 end
 return if point and point:IsA('BasePart')then point.Position else nil
end
function Rack.collect(rig,rack,slot,order,state,writable)
 local initial=rig:GetAttribute('AwaitingShieldSupply')==true and order=='advance'
 if (order~='regroup' and not initial) or writable~=true or not rack or not rack.Parent or not Rack.needs(rig,state) then return false end
 local plot=rack.Parent.Parent
 local owner=rig:GetAttribute('OwnerId');local civ=rig:GetAttribute('CivilizationId')
 if not plot or owner==nil or plot:GetAttribute('OwnerId')~=owner or plot:GetAttribute('CivilizationId')~=civ
  or rack:GetAttribute('CivilizationId')~=civ or rig:GetAttribute('ArmySlot')~=slot then return false end
 local hum=rig:FindFirstChildOfClass('Humanoid');local root=rig:FindFirstChild('HumanoidRootPart');local goal=Rack.goal(rack,slot)
 if not hum or hum.Health<=0 or not root or not goal or not rig:IsDescendantOf(workspace) or (root.Position-goal).Magnitude>2.5 then return false end
 if not Shield.restock(rig,civ,'warrior',state) then return false end
 if not Equipment.refreshShield(rig)then
  rig:SetAttribute('ShieldCharges',0);rig:SetAttribute('SpartanShieldRemaining',0);return false
 end
 rig:SetAttribute('ShieldRestockedAt',workspace:GetServerTimeNow())
 rig:SetAttribute('AwaitingShieldSupply',nil)
 return true
end
return Rack
