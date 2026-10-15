return function()
	local module=game.ServerScriptService.Game:FindFirstChild("OutfitTemplates")
	assert(module,"Civilization outfit application and avatar restoration are not implemented")
	local Outfits=require(module)
	local count=0
	local function test(name,callback) callback(); count+=1; print("PASS: "..name) end
	local sources=game.ServerStorage:FindFirstChild("OutfitTemplates")
	assert(sources,"Civilization outfits must be mapped into ServerStorage")
	local container=Instance.new("Folder"); container.Name="OutfitLifecycleFixture"; container.Parent=workspace
	local sourceStash=Instance.new("Folder"); sourceStash.Name="OutfitSourceFixtureStash"; sourceStash.Parent=game.ServerStorage
	local saved={}
	local colors={"HeadColor3","TorsoColor3","LeftArmColor3","RightArmColor3","LeftLegColor3","RightLegColor3"}
	local bodyColors={Head="HeadColor3",Torso="TorsoColor3",["Left Arm"]="LeftArmColor3",["Right Arm"]="RightArmColor3",["Left Leg"]="LeftLegColor3",["Right Leg"]="RightLegColor3"}
	local function replaceSource(id,number)
		local original=sources:FindFirstChild(id)
		assert(original,"Missing source for isolated replacement fixture")
		saved[id]=original; original.Parent=sourceStash
		local model=Instance.new("Model"); model.Name=id
		local shirt=Instance.new("Shirt"); shirt.ShirtTemplate="rbxassetid://"..(100+number); shirt.Parent=model
		shirt:SetAttribute("Damage",99999)
		local pants=Instance.new("Pants"); pants.PantsTemplate="rbxassetid://"..(200+number); pants.Parent=model
		local graphic=Instance.new("ShirtGraphic"); graphic.Graphic="rbxassetid://"..(300+number); graphic.Parent=model
		local palette=Instance.new("BodyColors")
		for index,key in colors do palette[key]=Color3.fromRGB(40+number*20,index*25,90) end
		palette.Parent=model
		local unsafe=Instance.new("Script"); unsafe.Disabled=true; unsafe.Parent=model
		model.Parent=sources
		return model
	end
	local function character(withClothing)
		local char=Instance.new("Model"); char.Name="OutfitTestCharacter"; char.Parent=container
		for index,name in {"HumanoidRootPart","Torso","Head","Left Arm","Right Arm","Left Leg","Right Leg"} do
			local part=Instance.new("Part"); part.Name=name; part.Anchored=true
			part.Size=if name=="Head" then Vector3.new(2,1,1) else Vector3.new(2,2,1)
			part.CFrame=CFrame.new(7000,7000+index*3,7000)*CFrame.Angles(0,.7,0)
			part.Color=Color3.fromRGB(index*20,40,50); part.Parent=char
		end
		local armor=Instance.new("Model"); armor.Name="CivilizationArmor"; armor.Parent=char
		local palette=Instance.new("BodyColors"); palette.Parent=char
		if withClothing then
			local shirt=Instance.new("Shirt"); shirt.ShirtTemplate="rbxassetid://801"; shirt.Parent=char
			local pants=Instance.new("Pants"); pants.PantsTemplate="rbxassetid://802"; pants.Parent=char
			local graphic=Instance.new("ShirtGraphic"); graphic.Graphic="rbxassetid://803"; graphic.Parent=char
		end
		return char,armor
	end
	local function clothingCount(char,class)
		local result=0; for _,item in char:GetChildren() do if item:IsA(class) then result+=1 end end; return result
	end
	local ok,result=pcall(function()
		test("all thirteen exported outfits apply without source mutation and keep head visuals near the head",function()
			for _,civ in require(game.ReplicatedStorage.Shared.Civilizations) do
				local source=sources:FindFirstChild(civ.id)
				assert(source and source:IsA("Model"),"Missing exported civilization outfit: "..civ.id)
				local beforeCount=#source:GetDescendants()
				local originalParts={}
				for _,part in source:GetDescendants() do if part:IsA("BasePart") then originalParts[part]={frame=part.CFrame,anchored=part.Anchored} end end
				local char,armor=character(false)
				assert(Outfits.apply(char,civ.id,armor,false),"Exported outfit supplies no usable clothing or body cosmetics: "..civ.id)
				for _,visual in armor:GetChildren() do
					if visual:GetAttribute("OutfitBodyPart")=="Head" then
						local minimum,maximum=nil,nil
						for _,part in visual:GetDescendants() do
							if part:IsA("BasePart") and part.Transparency<.99 then
								local mesh=part:FindFirstChildOfClass("SpecialMesh")
								local size=if mesh then part.Size*mesh.Scale else part.Size
								local frame=part.CFrame*(if mesh then CFrame.new(mesh.Offset) else CFrame.identity)
								for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
									local point=char.Head.CFrame:PointToObjectSpace(frame:PointToWorldSpace(size*Vector3.new(x,y,z)/2))
									minimum=if minimum then Vector3.new(math.min(minimum.X,point.X),math.min(minimum.Y,point.Y),math.min(minimum.Z,point.Z)) else point
									maximum=if maximum then Vector3.new(math.max(maximum.X,point.X),math.max(maximum.Y,point.Y),math.max(maximum.Z,point.Z)) else point
								end end end
							end
						end
						assert(minimum and maximum,"Outfit head piece contains no visible geometry: "..civ.id)
						local center=(minimum+maximum)/2
						assert(center.Magnitude<=3.5,"Outfit head visual floats away from its actual head: "..civ.id.." center="..tostring(center))
					end
				end
				Outfits.clear(char)
				assert(#source:GetDescendants()==beforeCount,"Outfit application mutated exported descendants: "..civ.id)
				for part,original in originalParts do assert(part.CFrame==original.frame and part.Anchored==original.anchored,"Outfit fitting moved its exported source: "..civ.id) end
				char:Destroy()
			end
		end)
		local rome=replaceSource("rome",1)
		local mongols=replaceSource("mongols",2)
		test("outfit switches and repeats preserve the original avatar clothing and body palette",function()
			local char,armor=character(true)
			local shirt,pants,graphic=char:FindFirstChildOfClass("Shirt"),char:FindFirstChildOfClass("Pants"),char:FindFirstChildOfClass("ShirtGraphic")
			local originalTint=Color3.fromRGB(82,171,64); shirt.Color3=originalTint
			local palette=char:FindFirstChildOfClass("BodyColors")
			local paletteValues={}; for _,key in colors do paletteValues[key]=palette[key] end
			local originalColors={}; for name in bodyColors do originalColors[name]=char[name].Color end
			local foreign=Instance.new("Accessory"); foreign.Name="UnrelatedAvatarAccessory"; foreign.Parent=char
			for _,id in {"rome","rome","mongols","rome"} do
				assert(Outfits.apply(char,id,armor,false))
				assert(char:FindFirstChildOfClass("Shirt")==shirt and char:FindFirstChildOfClass("Pants")==pants and char:FindFirstChildOfClass("ShirtGraphic")==graphic)
				assert(shirt.ShirtTemplate==sources[id]:FindFirstChildOfClass("Shirt").ShirtTemplate)
				assert(pants.PantsTemplate==sources[id]:FindFirstChildOfClass("Pants").PantsTemplate)
				assert(graphic.Graphic==sources[id]:FindFirstChildOfClass("ShirtGraphic").Graphic)
				assert(clothingCount(char,"Shirt")==1 and clothingCount(char,"Pants")==1 and clothingCount(char,"ShirtGraphic")==1)
				for name,key in bodyColors do assert(char[name].Color==sources[id]:FindFirstChildOfClass("BodyColors")[key]) end
				for _,key in colors do assert(palette[key]==paletteValues[key],"Outfit mutated the avatar's BodyColors instance") end
			end
			Outfits.clear(char)
			assert(shirt.ShirtTemplate=="rbxassetid://801" and pants.PantsTemplate=="rbxassetid://802" and graphic.Graphic=="rbxassetid://803")
			assert(shirt.Color3==originalTint,"Clearing outfit failed to restore original garment tint")
			for name,color in originalColors do assert(char[name].Color==color,"Clearing outfit failed to restore avatar body color") end
			assert(foreign.Parent==char and shirt.Parent==char and pants.Parent==char and graphic.Parent==char)
			assert(rome:FindFirstChildOfClass("Shirt").ShirtTemplate=="rbxassetid://101" and rome:FindFirstChildOfClass("Shirt"):GetAttribute("Damage")==99999)
			assert(char:FindFirstChild("Script",true)==nil and shirt:GetAttribute("Damage")==nil)
		end)
		test("external wardrobe edits remain the restore baseline across later outfit and gear refreshes",function()
			local char,armor=character(true)
			local shirt,pants,graphic=char:FindFirstChildOfClass("Shirt"),char:FindFirstChildOfClass("Pants"),char:FindFirstChildOfClass("ShirtGraphic")
			local originalTint=Color3.fromRGB(67,123,198); shirt.Color3=originalTint
			assert(Outfits.apply(char,"rome",armor,false))
			shirt.ShirtTemplate="rbxassetid://901"; pants.PantsTemplate="rbxassetid://902"; graphic.Graphic="rbxassetid://903"
			local externalColor=Color3.fromRGB(14,191,112); char.Torso.Color=externalColor
			assert(Outfits.apply(char,"mongols",armor,false))
			assert(Outfits.apply(char,"mongols",armor,false))
			Outfits.clear(char)
			assert(shirt.ShirtTemplate=="rbxassetid://901" and pants.PantsTemplate=="rbxassetid://902" and graphic.Graphic=="rbxassetid://903","Refresh discarded an intervening external wardrobe edit")
			assert(shirt.Color3==originalTint,"A foreign template edit prevented restoration of an independently owned tint field")
			assert(char.Torso.Color==externalColor,"Refresh discarded an intervening external body color")
			assert(Outfits.apply(char,"rome",armor,false))
			shirt.ShirtTemplate="rbxassetid://904"
			Outfits.clear(char)
			assert(shirt.ShirtTemplate=="rbxassetid://904","Clear overwrote a foreign edit after the last apply")
		end)
		test("late avatar clothes survive while only outfit-created clothing is removed",function()
			local char,armor=character(false)
			assert(Outfits.apply(char,"rome",armor,false))
			assert(clothingCount(char,"Shirt")==1 and clothingCount(char,"Pants")==1)
			local late=Instance.new("Shirt"); late.Name="LateAvatarShirt"; late.ShirtTemplate="rbxassetid://911"; late.Parent=char
			assert(Outfits.apply(char,"rome",armor,false))
			assert(late.ShirtTemplate=="rbxassetid://101","Late avatar appearance was not incorporated on reapply")
			Outfits.clear(char)
			assert(late.Parent==char and late.ShirtTemplate=="rbxassetid://911")
			assert(clothingCount(char,"Shirt")==1 and clothingCount(char,"Pants")==0 and clothingCount(char,"ShirtGraphic")==0,"Clear retained generated clothes or deleted foreign late clothes")
		end)
		test("destroyed clothing is not resurrected and new characters take independent snapshots",function()
			local first,armor=character(true)
			local destroyed=first:FindFirstChildOfClass("Shirt")
			assert(Outfits.apply(first,"rome",armor,false))
			destroyed:Destroy()
			assert(Outfits.apply(first,"rome",armor,false))
			Outfits.clear(first)
			assert(clothingCount(first,"Shirt")==0,"Outfit clear resurrected a destroyed original shirt")
			first:Destroy()
			local second,secondArmor=character(true)
			local fresh=second:FindFirstChildOfClass("Shirt"); fresh.ShirtTemplate="rbxassetid://991"
			assert(Outfits.apply(second,"mongols",secondArmor,false))
			Outfits.clear(second)
			assert(fresh.ShirtTemplate=="rbxassetid://991","Character reset reused another character's wardrobe snapshot")
			assert(not Outfits.apply(second,"missing-outfit-fixture",secondArmor,false))
			assert(fresh.ShirtTemplate=="rbxassetid://991","Missing outfit erased existing avatar appearance")
			assert(Outfits.apply(second,"rome",secondArmor,false))
			assert(not Outfits.apply(second,"missing-outfit-fixture",secondArmor,false))
			assert(fresh.ShirtTemplate=="rbxassetid://991","Unavailable outfit switch failed to restore the original wardrobe")
		end)
		test("foreign edits to outfit-created clothing survive later refresh and clear",function()
			local char,armor=character(false)
			assert(Outfits.apply(char,"rome",armor,false))
			local edited=char:FindFirstChildOfClass("Shirt")
			edited.ShirtTemplate="rbxassetid://951"
			assert(Outfits.apply(char,"mongols",armor,false))
			assert(edited.Parent==char and edited.ShirtTemplate=="rbxassetid://102")
			Outfits.clear(char)
			assert(edited.Parent==char and edited.ShirtTemplate=="rbxassetid://951","Clear deleted a garment that gained a foreign wardrobe edit")
			assert(clothingCount(char,"Shirt")==1 and clothingCount(char,"Pants")==0)
		end)
		test("R6 and R15 body pieces use scaled body-local offsets with sanitized clones and head precedence",function()
			local function piece(name,bodyPart,offset)
				local model=Instance.new("Model"); model.Name=name
				model:SetAttribute("BodyPart",bodyPart); model:SetAttribute("BodyOffset",offset)
				model:SetAttribute("ReferenceSize",Vector3.new(2,2,1))
				model:SetAttribute("OutfitCivilizationId","forged"); model:SetAttribute("Damage",99999)
				local handle=Instance.new("Part"); handle.Name="Handle"; handle.Size=Vector3.new(.5,.3,.4)
				handle.CFrame=CFrame.new(20,40,60); handle.Anchored=true; handle.Parent=model
				local detail=Instance.new("Part"); detail.Name="NestedOutfitDetail"; detail.Size=Vector3.new(.2,.4,.2)
				detail.CFrame=handle.CFrame*CFrame.new(.3,.2,.1); detail.Anchored=true; detail.Parent=model
				local unsafe=Instance.new("Script"); unsafe.Disabled=true; unsafe.Parent=model
				local external=Instance.new("ObjectValue"); external.Value=container; external.Parent=model
				model.Parent=rome
				return model
			end
			local offset=CFrame.new(.3,.2,-.4)*CFrame.Angles(.2,.1,.3)
			local sourcePiece=piece("OutfitTorsoFixture","Torso",offset)
			local headPiece=piece("OutfitHeadFixture","Head",CFrame.new(0,.5,0))
			local invalidPiece=piece("InvalidOutfitBody","InvalidBodyPart",CFrame.identity)
			local sourceCount=#sourcePiece:GetDescendants(); local sourceFrame=sourcePiece.Handle.CFrame
			for _,r15 in {false,true} do
				local char,armor=character(true)
				local torso=char.Torso
				if r15 then torso.Name="UpperTorso"; torso.Size=Vector3.new(4,3,2) end
				local foreign=Instance.new("Model"); foreign.Name="ForeignArmorAdornment"; foreign.Parent=armor
				for _,skipHead in {false,true,true} do
					assert(Outfits.apply(char,"rome",armor,skipHead))
					local found=nil; local countTorso,countHead=0,0
					for _,item in armor:GetChildren() do
						if item:GetAttribute("OutfitCivilizationId") then
							assert(item:GetAttribute("OutfitCivilizationId")=="rome" and item:GetAttribute("Damage")==nil)
							local bodyPart=item:GetAttribute("OutfitBodyPart")
							assert(bodyPart=="Torso" or bodyPart=="Head","Invalid imported body attachment was trusted")
							if bodyPart=="Torso" then countTorso+=1; found=item else countHead+=1 end
							for _,child in item:GetDescendants() do
								assert(not child:IsA("LuaSourceContainer") and not child:IsA("ObjectValue"))
								if child:IsA("BasePart") then assert(not child.Anchored and child.Massless and not child.CanCollide and not child.CanTouch and not child.CanQuery) end
							end
						end
					end
					assert(countTorso==1 and countHead==(if skipHead then 0 else 1),"Outfit reapply duplicated body pieces or ignored mapped-headwear precedence")
					local ratio=torso.Size/Vector3.new(2,2,1)
					local expected=torso.CFrame*CFrame.new(offset.Position*ratio)*(offset-offset.Position)
					assert((found.Handle.Position-expected.Position).Magnitude<.003 and found.Handle.CFrame.LookVector:Dot(expected.LookVector)>.9999,"Outfit piece did not follow scaled body-local attachment")
					local scale=math.clamp(math.max(ratio.X,ratio.Z),.5,2)
					assert((found.Handle.Size-sourcePiece.Handle.Size*scale).Magnitude<.003,"Outfit mesh scaled independently of target body width")
					assert(foreign.Parent==armor)
				end
				Outfits.clear(char)
				for _,item in armor:GetChildren() do assert(item:GetAttribute("OutfitCivilizationId")==nil,"Cleared outfit retained its body clone") end
				assert(foreign.Parent==armor)
			end
			assert(#sourcePiece:GetDescendants()==sourceCount and sourcePiece.Handle.Anchored and sourcePiece.Handle.CFrame==sourceFrame)
			assert(headPiece.Parent==rome and invalidPiece.Parent==rome,"Outfit fitting mutated source piece ownership")
		end)
		test("usable shirt-only outfits hide omitted avatar garments and restore them without creating empty clothes",function()
			mongols:FindFirstChildOfClass("Pants"):Destroy()
			mongols:FindFirstChildOfClass("ShirtGraphic"):Destroy()
			local char,armor=character(true)
			local pants,graphic=char:FindFirstChildOfClass("Pants"),char:FindFirstChildOfClass("ShirtGraphic")
			assert(Outfits.apply(char,"mongols",armor,false))
			assert(pants.Parent==char and pants.PantsTemplate=="" and graphic.Parent==char and graphic.Graphic=="","Omitted avatar layers obscure the chosen outfit")
			Outfits.clear(char)
			assert(pants.PantsTemplate=="rbxassetid://802" and graphic.Graphic=="rbxassetid://803","Omitted avatar layers were not restored")
			local bare,bareArmor=character(false)
			assert(Outfits.apply(bare,"mongols",bareArmor,false))
			assert(clothingCount(bare,"Shirt")==1 and clothingCount(bare,"Pants")==0 and clothingCount(bare,"ShirtGraphic")==0,"Outfit generated unnecessary empty garments")
			Outfits.clear(bare)
			assert(clothingCount(bare,"Shirt")==0)
		end)
		return count
	end)
	for id,original in saved do
		local fixture=sources:FindFirstChild(id); if fixture then fixture:Destroy() end
		original.Parent=sources
	end
	container:Destroy()
	sourceStash:Destroy()
	assert(ok,result)
	return result
end
