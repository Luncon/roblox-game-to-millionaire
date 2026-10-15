return function()
	local module=game.ServerScriptService.Game:FindFirstChild("TroopAppearance")
	assert(module,"Civilization troop skin and warrior faces are not implemented")
	local Appearance=require(module)
	local Rig=require(game.ServerScriptService.Game.WarriorRig)
	local Equipment=require(game.ServerScriptService.Game.Equipment)
	local catalog=require(game.ReplicatedStorage.Shared.Civilizations)
	local Tracks=require(game.ReplicatedStorage.Shared.UpgradeTracks)
	local Ranged=require(game.ReplicatedStorage.Shared.RangedConfig)
	local faceTexture="rbxassetid://10526794"
	local bodyNames={"Head","Torso","Left Arm","Right Arm","Left Leg","Right Leg"}
	local paletteFields={"HeadColor3","TorsoColor3","LeftArmColor3","RightArmColor3","LeftLegColor3","RightLegColor3"}
	local owned={}
	local function keep(item) table.insert(owned,item);return item end
	local cases=0
	local function test(name,callback) callback();cases+=1;print("PASS: "..name) end
	local function countClass(parent,class)
		local count=0;for _,item in parent:GetChildren() do if item:IsA(class) then count+=1 end end;return count
	end
	local function assertAppearance(rig,civ)
		local color=Appearance.skinColors[civ.id]
		assert(typeof(color)=="Color3","Missing civilization skin art default: "..civ.id)
		for _,name in bodyNames do assert(rig[name].Color==color,"Wrong troop skin on "..civ.id.." / "..name) end
		assert(countClass(rig,"BodyColors")==1,"Troop skin refresh duplicated BodyColors")
		local palette=rig:FindFirstChildOfClass("BodyColors")
		for _,field in paletteFields do assert(palette[field]==color,"Troop BodyColors disagrees with its visible skin") end
		local count=0
		for _,item in rig.Head:GetChildren() do
			if item:IsA("Decal") and item.Face==Enum.NormalId.Front then
				count+=1;assert(item.Texture==faceTexture,"Troop retained a non-warrior front face")
			end
		end
		assert(count==1,"Troop needs exactly one canonical front face")
	end
	local ok,result=pcall(function()
		test("all civilization troop classes retain their skin face and head meshes through upgrades without mutating sources",function()
			assert(type(Appearance.apply)=="function" and Appearance.faceTexture==faceTexture)
			local snapshots={}
			for _,id in {"sparta","britain","japan","seneca","maurya"} do
				local source=game.ServerStorage.NPCTemplates[id]
				local record={count=#source:GetDescendants(),pivot=source:GetPivot(),fields={}}
				for _,item in source:GetDescendants() do
					if item:IsA("BasePart") then record.fields[item]={Color=item.Color,CFrame=item.CFrame}
					elseif item:IsA("SpecialMesh") then record.fields[item]={Scale=item.Scale,MeshType=item.MeshType,MeshId=item.MeshId,TextureId=item.TextureId}
					elseif item:IsA("Decal") then record.fields[item]={Face=item.Face,Texture=item.Texture}
					elseif item:IsA("Shirt") then record.fields[item]={ShirtTemplate=item.ShirtTemplate,Color3=item.Color3}
					elseif item:IsA("Pants") then record.fields[item]={PantsTemplate=item.PantsTemplate,Color3=item.Color3}
					elseif item:IsA("ShirtGraphic") then record.fields[item]={Graphic=item.Graphic,Color3=item.Color3}
					elseif item:IsA("BodyColors") then
						local values={};for _,field in paletteFields do values[field]=item[field] end;record.fields[item]=values
					end
				end
				snapshots[source]=record
			end
			for _,civ in catalog do
				for _,kind in {"warrior","ranged"} do
					local rig=keep(Rig.create(civ,CFrame.new(200,10000,-300)*CFrame.Angles(0,.8,0),101,1,nil,kind))
					assert(rig.Parent==nil)
					assertAppearance(rig,civ)
					local head=rig.Head;local mesh=head:FindFirstChildOfClass("SpecialMesh")
					assert(mesh and mesh.MeshType==Enum.MeshType.Head)
					local scale=mesh.Scale
					for _,level in {25,50} do
						Rig.update(rig,civ,{weaponLevel=level,armorLevel=level})
						assertAppearance(rig,civ)
						assert(rig.Head==head and mesh.Parent==head and mesh.Scale==scale,"Troop appearance replaced or reshaped a normal head")
						assert(math.abs(rig.Humanoid.MaxHealth-Tracks.armor[level].health)<.002)
						local damage=Tracks.weapon[level].damage*(if kind=="ranged" then Ranged.damageMultiplier else 1)
						assert(rig:GetAttribute("WarriorDamage")==damage,"Skin/face appearance changed combat damage")
					end
				end
			end
			for source,record in snapshots do
				assert(#source:GetDescendants()==record.count and source:GetPivot()==record.pivot,"Troop appearance mutated an original custom template")
				for item,fields in record.fields do
					assert(item:IsDescendantOf(source))
					for property,value in fields do assert(item[property]==value,"Troop skin/face policy changed its stored source: "..source.Name.." / "..property) end
				end
			end
		end)
		test("same-tier refresh reasserts troop skin and canonical face after foreign changes without healing or duplicates",function()
			for _,civ in catalog do
				for _,kind in {"warrior","ranged"} do
					local state={weaponLevel=25,armorLevel=25}
					local rig=keep(Rig.create(civ,CFrame.new(),101,1,state,kind))
					local head,mesh=rig.Head,rig.Head:FindFirstChildOfClass("SpecialMesh")
					local scale=mesh.Scale
					local health=rig.Humanoid.MaxHealth-30;rig.Humanoid.Health=health
					for _,name in bodyNames do rig[name].Color=Color3.fromRGB(255,0,255) end
					local palette=rig:FindFirstChildOfClass("BodyColors")
					for _,field in paletteFields do palette[field]=Color3.fromRGB(0,255,0) end
					local intruder=Instance.new("Decal");intruder.Name="ForeignFrontFace";intruder.Face=Enum.NormalId.Front;intruder.Texture="rbxassetid://999999";intruder.Parent=head
					local back=Instance.new("Decal");back.Name="UnrelatedBackDecoration";back.Face=Enum.NormalId.Back;back.Texture="rbxassetid://888888";back.Parent=head
					for _=1,3 do
						Rig.update(rig,civ,state)
						assertAppearance(rig,civ)
						assert(rig.Head==head and mesh.Parent==head and mesh.Scale==scale)
						assert(back.Parent==head and back.Face==Enum.NormalId.Back and back.Texture=="rbxassetid://888888","Front-face policy deleted an unrelated face-side decoration")
						assert(math.abs(rig.Humanoid.Health-health)<.002,"Cosmetic refresh healed the troop")
					end
				end
			end
		end)
		test("player equipment leaves the avatar face untouched and clears back to its original skin",function()
			local character=keep(Instance.new("Model"));character.Name="TroopAppearancePlayerBoundaryFixture"
			local originalColors={}
			for index,name in {"HumanoidRootPart","Torso","Head","Left Arm","Right Arm","Left Leg","Right Leg"} do
				local part=Instance.new("Part");part.Name=name;part.Anchored=true;part.CanCollide=false
				part.Size=if name=="Head" then Vector3.new(2,1,1) else Vector3.new(2,2,1)
				part.CFrame=CFrame.new(7000,7000+index*3,7000);part.Color=Color3.fromRGB(75+index*9,103,169);part.Parent=character
				originalColors[part]=part.Color
			end
			local humanoid=Instance.new("Humanoid");humanoid.RequiresNeck=false;humanoid.Parent=character
			local mesh=Instance.new("SpecialMesh");mesh.MeshType=Enum.MeshType.Head;mesh.Scale=Vector3.new(1.1,1.2,1.3);mesh.Parent=character.Head
			local face=Instance.new("Decal");face.Name="OriginalPlayerFace";face.Face=Enum.NormalId.Front;face.Texture="rbxasset://textures/face.png";face.Parent=character.Head
			local inventory=keep(Instance.new("Folder"));local backpack=Instance.new("Backpack");backpack.Parent=inventory
			local player={Character=character}
			function player:FindFirstChildOfClass(class) return inventory:FindFirstChildOfClass(class) end
			for _,civ in catalog do
				assert(Equipment.apply(player,civ,{weaponLevel=25,armorLevel=25}))
				assert(face.Parent==character.Head and face.Texture=="rbxasset://textures/face.png" and countClass(character.Head,"Decal")==1,"Troop warrior face leaked into player equipment")
				assert(mesh.Parent==character.Head and mesh.Scale==Vector3.new(1.1,1.2,1.3))
				assert(countClass(character,"BodyColors")==0,"NPC BodyColors policy leaked into player equipment")
			end
			Equipment.clear(player)
			for part,color in originalColors do assert(part.Color==color,"NPC skin policy prevented original player skin restoration") end
			assert(face.Parent==character.Head and face.Texture=="rbxasset://textures/face.png")
		end)
		return cases
	end)
	for _,item in owned do item:Destroy() end
	assert(ok,result)
	return result
end
