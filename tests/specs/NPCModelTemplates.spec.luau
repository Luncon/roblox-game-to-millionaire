return function()
	local Tracks=require(game.ReplicatedStorage.Shared.UpgradeTracks)
	local function near(actual,expected) assert(math.abs(actual-expected)<.002,tostring(actual).." ~= "..expected) end
	local module=game.ServerScriptService.Game:FindFirstChild("NPCModelTemplates")
	assert(module,"NPCModelTemplates is not implemented yet")
	local Templates=require(module)
	local Rig=require(game.ServerScriptService.Game.WarriorRig)
	local catalog=require(game.ReplicatedStorage.Shared.Civilizations)
	local rome=nil
	for _,civ in catalog do if civ.id=="rome" then rome=civ end end
	local original=Rig.create(rome,CFrame.new(20,100,30),101,1)
	local outside=Instance.new("Part")
	local prepared=nil
	local count=0
	local function test(name,callback) callback(); count+=1; print("PASS: "..name) end
	local ok,result=pcall(function()
		local script=Instance.new("Script")
		script.Name="UnsafeTemplateScript"; script.Disabled=true; script.Parent=original
		local moduleScript=Instance.new("ModuleScript")
		moduleScript.Parent=original
		local force=Instance.new("ForceField"); force.Parent=original
		local body=Instance.new("BodyVelocity"); body.Parent=original.Torso
		local external=Instance.new("Weld")
		external.Name="ExternalUnsafeJoint"; external.Part0=original.Torso; external.Part1=outside; external.Parent=original.Torso
		local competing=Instance.new("Weld")
		competing.Name="CompetingBodyJoint"; competing.Part0=original.HumanoidRootPart; competing.Part1=original["Right Arm"]; competing.Parent=original.HumanoidRootPart
		local hat=Instance.new("Part")
		hat.Name="LooseTemplateHat"; hat.Size=Vector3.new(2,.4,2); hat.CFrame=original.Head.CFrame*CFrame.new(0,.7,0)
		hat.Anchored=true; hat.Parent=original
		-- Rig.create now supplies a civilization shirt; keep one identifiable
		-- source garment rather than relying on ordering between duplicate Shirts.
		local shirt=original:FindFirstChildOfClass("Shirt") or Instance.new("Shirt")
		shirt.Name="FixtureShirt"; shirt.ShirtTemplate="rbxassetid://123"; shirt.Parent=original
		local beforeCount=#original:GetDescendants()
		local originalHatFrame=hat.CFrame
		test("template preparation clones and sanitizes scripts tools forces and external links",function()
			prepared=Templates.prepare(original)
			assert(prepared and prepared~=original and prepared.Parent==nil)
			assert(prepared.PrimaryPart==prepared:FindFirstChild("HumanoidRootPart"))
			assert(prepared:FindFirstChild("CompetingBodyJoint",true)==nil)
			local motors=0
			for _,item in prepared:GetDescendants() do
				assert(not item:IsA("LuaSourceContainer") and not item:IsA("Tool") and not item:IsA("ForceField") and not item:IsA("BodyMover"))
				if item:IsA("BasePart") then assert(not item.Anchored) end
				if item:IsA("Motor6D") or item:IsA("Weld") or item:IsA("WeldConstraint") then
					assert(item.Part0 and item.Part1 and item.Part0:IsDescendantOf(prepared) and item.Part1:IsDescendantOf(prepared))
					if item:IsA("Motor6D") then motors+=1 end
				end
			end
			assert(motors>=6)
		end)
		test("sanitization preserves clothes cosmetics transforms and the original template",function()
			assert(#original:GetDescendants()==beforeCount and original:FindFirstChild("UnsafeTemplateScript") and original:FindFirstChild("CompetingBodyJoint",true))
			assert(hat.Anchored and hat.CFrame==originalHatFrame)
			local copiedShirt=prepared:FindFirstChildOfClass("Shirt")
			assert(copiedShirt and copiedShirt.Name=="FixtureShirt" and copiedShirt.ShirtTemplate=="rbxassetid://123")
			assert(shirt.Parent==original and shirt.ShirtTemplate=="rbxassetid://123","Sanitization mutated its source garment")
			local copy=prepared:FindFirstChild("LooseTemplateHat")
			assert(copy and (copy.Position-hat.Position).Magnitude<.001)
			local welded=false
			for _,joint in prepared:GetDescendants() do
				if joint:IsA("WeldConstraint") or joint:IsA("Weld") then
					if joint.Part0==copy or joint.Part1==copy then welded=true end
				end
			end
			assert(welded,"Loose cosmetic was not attached to the cloned rig")
		end)
		test("invalid templates return nil for procedural fallback",function()
			local invalid=Instance.new("Model")
			assert(Templates.prepare(invalid)==nil)
			invalid:Destroy()
			assert(Templates.clone("unknown-civilization")==nil)
		end)
		test("all five mapped civilization assets preserve original clothing and gain live tier gear at the requested spawn",function()
			local sources=game.ServerStorage:FindFirstChild("NPCTemplates")
			assert(sources,"Five civilization template assets must be mapped into ServerStorage")
			for _,id in {"sparta","britain","japan","seneca","maurya"} do
				local source=sources:FindFirstChild(id)
				assert(source and source:IsA("Model"),"Missing actual model asset: "..id)
				local originalCount=#source:GetDescendants()
				local originalPivot=source:GetPivot()
				local civ=nil
				for _,entry in catalog do if entry.id==id then civ=entry end end
				local spawn=CFrame.new(900,100,800)*CFrame.Angles(0,.6,0)
				local custom=Rig.create(civ,spawn,101,1,{weaponLevel=1,armorLevel=1})
				assert(custom:GetAttribute("CustomMeleeModel")==true and custom:GetAttribute("TemplateCivilizationId")==id,
					"Actual civilization model silently fell back to a procedural rig: "..id)
				assert((custom:GetPivot().Position-spawn.Position).Magnitude<.01)
				assert(custom:GetPivot().LookVector:Dot(spawn.LookVector)>.9999)
				local bodyNames={HumanoidRootPart=true,Torso=true,Head=true,["Right Arm"]=true,["Left Arm"]=true,["Right Leg"]=true,["Left Leg"]=true}
				local cosmetics={}
				for _,part in source:GetDescendants() do
					if part:IsA("BasePart") and not bodyNames[part.Name] and not part:FindFirstAncestorOfClass("Tool") then
						cosmetics[part.Name]=(cosmetics[part.Name] or 0)+1
					end
				end
				for name,expected in cosmetics do
					local actual=0
					for _,part in custom:GetDescendants() do if part:IsA("BasePart") and part.Name==name then actual+=1 end end
					assert(actual>=expected,"Custom rig lost template headwear or cosmetic parts: "..name)
				end
				for _,class in {"Shirt","Pants","ShirtGraphic"} do
					local clothing=source:FindFirstChildOfClass(class)
					if clothing then
						local copied=custom:FindFirstChildOfClass(class)
						assert(copied,"Custom rig lost its template clothing")
						local property=if class=="Shirt" then "ShirtTemplate" elseif class=="Pants" then "PantsTemplate" else "Graphic"
						assert(copied[property]==clothing[property])
					end
				end
				local retainedCosmetics={}
				local retainedClothing={}
				local retainedBodyColors={}
				for _,definition in {{"Shirt","ShirtTemplate"},{"Pants","PantsTemplate"},{"ShirtGraphic","Graphic"}} do
					local garment=custom:FindFirstChildOfClass(definition[1])
					if garment then retainedClothing[garment]={property=definition[2],value=garment[definition[2]]} end
				end
				for name in bodyNames do
					local part=custom:FindFirstChild(name)
					if part and part:IsA("BasePart") then retainedBodyColors[part]=part.Color end
				end
				for _,part in custom:GetDescendants() do
					if part:IsA("BasePart") and not bodyNames[part.Name] and not part:FindFirstAncestorOfClass("Tool")
						and not part:IsDescendantOf(custom.CivilizationArmor) then
						retainedCosmetics[part]={frame=custom.HumanoidRootPart.CFrame:ToObjectSpace(part.CFrame),color=part.Color,material=part.Material}
					end
				end
				for level=1,50 do
					local damage=Tracks.weapon[level].damage
					Rig.update(custom,civ,{weaponLevel=level,armorLevel=level})
					assert(custom:GetAttribute("WarriorDamage")==damage and math.abs(custom.Humanoid.MaxHealth-Tracks.armor[level].health)<.002)
					for garment,record in retainedClothing do assert(garment.Parent==custom and garment[record.property]==record.value,"Outfit application replaced original custom melee clothing: "..id) end
					for part,color in retainedBodyColors do assert(part.Parent==custom and part.Color==color,"Outfit application recolored original custom melee body: "..id) end
					assert(custom:GetAttribute("OutfitCivilizationId")==nil,"Custom melee unexpectedly received an outfit override")
					for part,originalCosmetic in retainedCosmetics do
						assert(part:IsDescendantOf(custom) and part.Color==originalCosmetic.color and part.Material==originalCosmetic.material,
							"Gear rebuild changed original custom headwear/cosmetic: "..id.." / "..part.Name)
						local current=custom.HumanoidRootPart.CFrame:ToObjectSpace(part.CFrame)
						assert((current.Position-originalCosmetic.frame.Position).Magnitude<.002 and current.LookVector:Dot(originalCosmetic.frame.LookVector)>.9999)
					end
					for _,item in custom.CivilizationArmor:GetDescendants() do
						local templateId=item:GetAttribute("TemplateId")
						assert(templateId~="spartan-helmet" and templateId~="british-tricorn" and templateId~="seneca-headdress"
							and templateId~="egypt-pharaoh" and templateId~="egypt-anubis","Imported hat overlaid custom melee headwear")
					end
				end
				custom:Destroy()
				assert(#source:GetDescendants()==originalCount and source:GetPivot()==originalPivot,"Live gear mutated the stored civilization asset")
			end
		end)
		return count
	end)
	if prepared then prepared:Destroy() end
	original:Destroy(); outside:Destroy()
	assert(ok,result)
	return result
end
