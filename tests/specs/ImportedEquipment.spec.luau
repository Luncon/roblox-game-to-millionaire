return function()
	local Equipment=require(game.ServerScriptService.Game.Equipment)
	local Rig=require(game.ServerScriptService.Game.WarriorRig)
	local Tracks=require(game.ReplicatedStorage.Shared.UpgradeTracks)
	local Ranged=require(game.ReplicatedStorage.Shared.RangedConfig)
	local Melee=require(game.ReplicatedStorage.Shared.WarriorConfig)
	local catalog=require(game.ReplicatedStorage.Shared.Civilizations)
	local byId={}; for _,civ in catalog do byId[civ.id]=civ end
	local hats={sparta="spartan-helmet",britain="british-tricorn",seneca="seneca-headdress",egypt="egypt-pharaoh"}
	local meleeWeapons={sparta="spartan-spear",britain="officer-sword",seneca="axe",mongols="scimitar",vikings="axe",
		persia="spear",japan="katana",maurya="spear",spain="rapier",egypt="khopesh",rome="gladius",ottomans="scimitar",ming="scimitar"}
	local playerWeapons=table.clone(meleeWeapons); playerWeapons.seneca="bow"
	local rangedWeapons={sparta="spartan-spear",britain="musket",seneca="bow",mongols="bow",vikings="axe",persia="bow",
		japan="bow",maurya="bow",spain="crossbow",egypt="slingshot",rome="spear",ottomans="musket",ming="crossbow"}
	local owned={}
	local function keep(item) table.insert(owned,item); return item end
	local count=0
	local function test(name,callback) callback(); count+=1; print("PASS: "..name) end
	local function imported(parent)
		local result={}
		for _,item in parent:GetDescendants() do
			local id=item:GetAttribute("TemplateId")
			if id then result[id]=(result[id] or 0)+1 end
		end
		return result
	end
	local function expectImports(parent,expected)
		local actual=imported(parent)
		for id,n in actual do assert(expected[id]==n,"Unexpected or duplicated imported visual: "..id) end
		for id,n in expected do assert(actual[id]==n,"Missing intended imported visual: "..id) end
	end
	local function expectOutfit(character,civ,custom)
		local source=(if custom then game.ServerStorage.NPCTemplates else game.ServerStorage.OutfitTemplates):FindFirstChild(civ.id)
		assert(source,"Missing intended civilization outfit source: "..civ.id)
		local clothed=false
		for _,definition in {{"Shirt","ShirtTemplate"},{"Pants","PantsTemplate"},{"ShirtGraphic","Graphic"}} do
			local garment=source:FindFirstChildOfClass(definition[1])
			if garment and garment[definition[2]]~="" then
				local actual=character:FindFirstChildOfClass(definition[1])
				assert(actual and actual[definition[2]]==garment[definition[2]],"Civilization garment mismatch: "..civ.id)
				clothed=true
			end
		end
		local count=0
		for _,item in character.CivilizationArmor:GetDescendants() do
			if item:GetAttribute("OutfitCivilizationId") then
				assert(not custom and item:GetAttribute("OutfitCivilizationId")==civ.id,"Civilization outfit overrode original custom melee clothing")
				count+=1; clothed=true
			end
		end
		if not custom then
			local expected=0
			local map={Torso="UpperTorso",["Left Arm"]="LeftUpperArm",["Right Arm"]="RightUpperArm",["Left Leg"]="LeftUpperLeg",["Right Leg"]="RightUpperLeg"}
			for _,piece in source:GetChildren() do
				if piece:IsA("Model") and piece:FindFirstChild("Handle") then
					local bodyPart=piece:GetAttribute("BodyPart")
					local base=if bodyPart then character:FindFirstChild(bodyPart) or (map[bodyPart] and character:FindFirstChild(map[bodyPart])) else nil
					if base and not (bodyPart=="Head" and hats[civ.id]) then expected+=1 end
				end
			end
			assert(count==expected,"Missing or duplicated actual outfit body pieces: "..civ.id.." expected="..expected.." actual="..count)
		end
		assert(clothed,"No actual mapped outfit/clothing equipped: "..civ.id)
	end
	local function playerFixture(r15)
		local char=keep(Instance.new("Model")); char.Name="ImportedEquipmentPlayerFixture"
		local definitions={{"HumanoidRootPart",Vector3.new(2,2,1),Vector3.zero},
			{if r15 then "UpperTorso" else "Torso",Vector3.new(2,2,1),Vector3.zero},
			{"Head",Vector3.new(2,1,1),Vector3.new(0,1.5,0)},
			{if r15 then "RightHand" else "Right Arm",Vector3.new(1,2,1),Vector3.new(1.5,0,0)},
			{if r15 then "LeftHand" else "Left Arm",Vector3.new(1,2,1),Vector3.new(-1.5,0,0)},
			{if r15 then "RightUpperLeg" else "Right Leg",Vector3.new(1,2,1),Vector3.new(.5,-2,0)},
			{if r15 then "LeftUpperLeg" else "Left Leg",Vector3.new(1,2,1),Vector3.new(-.5,-2,0)}}
		if r15 then
			table.insert(definitions,{"RightUpperArm",Vector3.new(1,2,1),Vector3.new(1.5,.5,0)})
			table.insert(definitions,{"LeftUpperArm",Vector3.new(1,2,1),Vector3.new(-1.5,.5,0)})
		end
		for _,definition in definitions do
			local part=Instance.new("Part"); part.Name=definition[1]; part.Size=definition[2]
			part.CFrame=CFrame.new(7000,7000,7000)*CFrame.Angles(0,.8,0)*CFrame.new(definition[3])
			part.Anchored=true; part.CanCollide=false; part.Parent=char
		end
		local hum=Instance.new("Humanoid"); hum.RequiresNeck=false; hum.Parent=char
		char.Parent=workspace
		local inventory=keep(Instance.new("Folder")); inventory.Parent=workspace
		local backpack=Instance.new("Backpack"); backpack.Parent=inventory
		local player={Character=char}
		function player:FindFirstChildOfClass(class) return inventory:FindFirstChildOfClass(class) end
		return player,char,backpack
	end
	local function toolOf(character,backpack)
		local tools={}
		for _,parent in {character,backpack} do
			if parent then for _,item in parent:GetChildren() do
				if item:IsA("Tool") and item:GetAttribute("GeneratedBy")=="CivilizationEquipment" then table.insert(tools,item) end
			end end
		end
		assert(#tools==1,"Expected exactly one authoritative generated Tool")
		return tools[1]
	end
	local ok,result=pcall(function()
		test("R6 and R15 player equipment select intended imports without duplicating fallback geometry",function()
			for _,r15 in {false,true} do
				local player,char,backpack=playerFixture(r15)
				local avatar=Instance.new("Accessory"); avatar.Name="UnrelatedAvatarHat"; avatar.Parent=char
				for _,civ in catalog do
					for _,level in {1,25,50} do
						assert(Equipment.apply(player,civ,{weaponLevel=level,armorLevel=level}))
						local tool=toolOf(char,backpack)
						local expected={}
						if hats[civ.id] then expected[hats[civ.id]]=1 end
						if playerWeapons[civ.id] then expected[playerWeapons[civ.id]]=1 end
						if civ.id=="sparta" then expected["spartan-shield"]=1 end
						local actual=imported(char)
						if tool.Parent==backpack then for id,n in imported(tool) do actual[id]=(actual[id] or 0)+n end end
						for id,n in expected do assert(actual[id]==n,"Player import mismatch: "..civ.id.." / "..id) end
						for id,n in actual do assert(expected[id]==n,"Unexpected player imported visual: "..id) end
						assert(tool.RequiresHandle and tool:FindFirstChild("Handle") and not tool:FindFirstChild("WarriorHandle"))
						assert(tool:GetAttribute("Damage")==Tracks.weapon[level].damage and tool:GetAttribute("WeaponLevel")==level)
						expectOutfit(char,civ,false)
						if playerWeapons[civ.id] then
							for _,name in {"Stock","Barrel","Bayonet","Blade","Guard","Shaft","SpearHead","BowLimb","Bowstring"} do
								assert(tool:FindFirstChild(name)==nil,"Procedural weapon was layered over imported skin: "..name)
							end
						end
						if hats[civ.id] then
							for _,name in {"HelmetCap","Headband","Crest","TricornBrim","NeckGuard","HelmetRidge"} do assert(not char.CivilizationArmor:FindFirstChild(name),"Fallback hat overlaid imported headwear") end
						end
						local armor=char.CivilizationArmor
						assert(Equipment.apply(player,civ,{weaponLevel=level,armorLevel=level}))
						assert(char.CivilizationArmor==armor and toolOf(char,backpack)==tool,"Same-tier apply duplicated imported equipment")
						assert(avatar.Parent==char)
					end
				end
				Equipment.clear(player)
				assert(char:FindFirstChild("CivilizationArmor")==nil and #backpack:GetChildren()==0 and avatar.Parent==char)
			end
		end)
		test("all troop roles select matching imports while retaining fractional authority and one manual grip",function()
			for _,civ in catalog do
				for _,role in {"warrior","ranged"} do
					local rig=keep(Rig.create(civ,CFrame.new(150,10000,200)*CFrame.Angles(0,.7,0),101,1,nil,role))
					for _,level in {1,25,50} do
						Rig.update(rig,civ,{weaponLevel=level,armorLevel=level})
						local expected={}
						local hat=if civ.id=="egypt" then "egypt-anubis" else hats[civ.id]
						if hat and rig:GetAttribute("CustomMeleeModel")~=true then expected[hat]=1 end
						local skin=if role=="warrior" then meleeWeapons[civ.id] else rangedWeapons[civ.id]
						if skin then expected[skin]=1 end
						if role=="warrior" and civ.id=="sparta" then expected["spartan-shield"]=1 end
						expectImports(rig,expected)
						expectOutfit(rig,civ,rig:GetAttribute("CustomMeleeModel")==true)
						local tool=toolOf(rig)
						local damage=Tracks.weapon[level].damage*(if role=="ranged" then Ranged.damageMultiplier else 1)
						assert(tool:GetAttribute("Damage")==damage and rig:GetAttribute("WarriorDamage")==damage)
						local variant=(if role=="ranged" then Ranged else Melee).variants[civ.id]
						assert(tool:GetAttribute("WeaponKind")==variant.weaponKind,"Visual import changed the authoritative troop weapon kind")
						assert(math.abs(rig.Humanoid.MaxHealth-Tracks.armor[level].health)<.002)
						assert(not tool.RequiresHandle and tool:FindFirstChild("WarriorHandle") and not tool:FindFirstChild("Handle"))
						local grips=0
						for _,joint in rig:GetDescendants() do
							assert(joint.Name~="RightGrip","NPC gained a competing engine grip")
							if joint.Name=="WarriorGrip" then grips+=1; assert(joint.Part0==rig["Right Arm"] and joint.Part1==tool.WarriorHandle) end
						end
						assert(grips==1)
						if role=="ranged" and (civ.id=="britain" or civ.id=="ottomans") then
							assert(imported(tool).musket==1 and tool:FindFirstChild("Barrel")==nil,"Ranged musket was not replaced by its intended imported visual")
						end
					end
				end
			end
		end)
		test("imported NPC visuals remain rigidly handle-local across rotated spawn and tier rebuild",function()
			local sources=game.ServerStorage.EquipmentTemplates
			for _,id in {"sparta","britain","japan","maurya","persia"} do
				local rig=keep(Rig.create(byId[id],CFrame.new(420,10000,-360)*CFrame.Angles(.1,1.2,0),101,1))
				for _,level in {1,25,50} do
					Rig.update(rig,byId[id],{weaponLevel=level,armorLevel=level})
					local tool=toolOf(rig)
					local visual=nil
					for _,item in tool:GetDescendants() do if item:GetAttribute("TemplateId")==meleeWeapons[id] then visual=item end end
					assert(visual,"Missing imported NPC weapon")
					local importedHandle=visual:FindFirstChild("VisualHandle") or visual:FindFirstChild("Handle")
					assert(importedHandle and (importedHandle.Position-tool.WarriorHandle.Position).Magnitude<.01,"Imported weapon detached from NPC grip")
					local source=sources[meleeWeapons[id]]
					for _,part in source:GetDescendants() do
						if part:IsA("BasePart") and part~=source.Handle then
							local offset=source.Handle.CFrame:ToObjectSpace(part.CFrame)
							local match=false
							for _,copy in visual:GetDescendants() do
								if copy:IsA("BasePart") and copy~=importedHandle then
									local actual=importedHandle.CFrame:ToObjectSpace(copy.CFrame)
									if copy.Size==part.Size and (actual.Position-offset.Position).Magnitude<.01 and actual.LookVector:Dot(offset.LookVector)>.999 then match=true; break end
								end
							end
							assert(match,"Nested imported geometry moved independently of grip: "..id.." / "..part.Name)
						end
					end
				end
			end
		end)
		test("forced same-tier player refresh incorporates late avatar clothes and clear restores them",function()
			local civ=nil; local sourceShirt=nil
			for _,entry in catalog do
				local garment=game.ServerStorage.OutfitTemplates[entry.id]:FindFirstChildOfClass("Shirt")
				if garment and garment.ShirtTemplate~="" then civ=entry; sourceShirt=garment; break end
			end
			assert(civ and sourceShirt,"Actual outfits must include at least one usable classic shirt for late-appearance coverage")
			local player,char,backpack=playerFixture(true)
			local state={weaponLevel=25,armorLevel=25}
			assert(Equipment.apply(player,civ,state))
			local late=Instance.new("Shirt"); late.Name="LateLoadedAvatarShirt"; late.ShirtTemplate="rbxassetid://987654"; late.Parent=char
			local tool=toolOf(char,backpack)
			assert(Equipment.apply(player,civ,state,true))
			assert(late.Parent==char and late.ShirtTemplate==sourceShirt.ShirtTemplate,"Forced appearance refresh failed to dress late-loaded original clothing")
			assert(toolOf(char,backpack)~=tool and toolOf(char,backpack):GetAttribute("Damage")==Tracks.weapon[25].damage)
			Equipment.clear(player)
			assert(late.Parent==char and late.ShirtTemplate=="rbxassetid://987654","Clearing forced refresh lost the late avatar garment")
		end)
		return count
	end)
	for _,item in owned do item:Destroy() end
	assert(ok,result)
	return result
end
