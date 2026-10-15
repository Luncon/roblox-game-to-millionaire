-- Ordinary server Script only; genuine avatar appearance loading and production switching.
return function(player)
	local Players,RunService=game:GetService("Players"),game:GetService("RunService")
	assert(RunService:IsStudio() and RunService:IsServer() and RunService:IsRunning())
	local context=require(script.Parent.SoloTestContext)
	assert(context.store.isFakeProfileStore and game:GetAttribute("SoloVerificationEnabled"),"Appearance fixtures require the fake solo bootstrap")
	assert(game:GetAttribute("SoloChecksComplete"),"Run appearance verification after the base solo checks")
	assert(player and player:IsA("Player") and player.Parent==Players)
	local service=context.service
	assert(service and service.profiles:isWritable(player.UserId),"Fake profile must remain writable during inspection")
	local Equipment=require(game.ServerScriptService.Game.Equipment)
	local catalog={}; for _,civ in require(game.ReplicatedStorage.Shared.Civilizations) do catalog[civ.id]=civ end
	local fields={"coins","level","weaponLevel","armorLevel","barracksLevel"}
	local clothing={{"Shirt","ShirtTemplate"},{"Pants","PantsTemplate"},{"ShirtGraphic","Graphic"}}
	local originalClaim=service.registry:get(player.UserId)
	assert(originalClaim and originalClaim.civilizationId=="sparta","Base solo profile must finish as Sparta")
	local original=service.economy:get(player.UserId)
	assert(original.level==50 and original.weaponLevel==50 and original.armorLevel==50 and original.barracksLevel==4)
	local profiles={}; for id in catalog do profiles[id]=service.profiles:get(player.UserId,id) end
	local function sameState(actual,expected)
		assert(actual and expected)
		for _,field in fields do assert(actual[field]==expected[field],"Appearance check changed progression field "..field) end
	end
	local function waitFor(predicate,description,seconds)
		local deadline=os.clock()+(seconds or 15)
		repeat if predicate() then return end;task.wait(.05) until os.clock()>deadline
		error("Timed out: "..description)
	end
	local function dressed(id)
		local char=player.Character
		if not char or char:GetAttribute("EquipmentCivilization")~=id or char:GetAttribute("OutfitCivilizationId")~=id then return false end
		local source=game.ServerStorage.OutfitTemplates:FindFirstChild(id)
		if not source then return false end
		for _,definition in clothing do
			local preset=source:FindFirstChildOfClass(definition[1])
			local expected=if preset then preset[definition[2]] else ""
			local found=false
			for _,garment in char:GetChildren() do
				if garment.ClassName==definition[1] then
					found=true
					if garment[definition[2]]~=expected then return false end
				end
			end
			if expected~="" and not found then return false end
		end
		return true
	end
	local eventCharacter=nil
	local observer=nil
	local foreign=nil
	local cases=0
	local function test(name,callback) callback();cases+=1;print("PASS: "..name) end
	local ok,result=pcall(function()
		test("native CharacterAppearanceLoaded reapplies the selected outfit without changing saved progress",function()
			local oldCharacter=player.Character
			observer=player.CharacterAppearanceLoaded:Connect(function(character) eventCharacter=character end)
			local loading,loadFailure=true,nil
			task.spawn(function()
				local success,message=pcall(function() player:LoadCharacterAsync() end)
				if not success then loadFailure=tostring(message) end
				loading=false
			end)
			waitFor(function()
				assert(loadFailure==nil,loadFailure)
				return not loading and player.Character~=oldCharacter and eventCharacter==player.Character and dressed("sparta")
			end,"genuine avatar appearance event and production Spartan outfit reapply",45)
			assert(player:HasAppearanceLoaded(),"Avatar appearance event did not describe a loaded current character")
			sameState(service.economy:get(player.UserId),original)
			assert(service.registry:get(player.UserId).plotId==originalClaim.plotId)
		end)
		local baseline=nil
		test("production civilization switches restore exact real-avatar garment instances tints and body colors",function()
			Equipment.clear(player)
			local char=player.Character
			baseline={character=char,garments={},parts={},children={},palettes={}}
			for _,item in char:GetChildren() do
				baseline.children[item]=true
				if item:IsA("BasePart") then baseline.parts[item]=item.Color end
				if item:IsA("BodyColors") then
					local palette={}
					for _,key in {"HeadColor3","TorsoColor3","LeftArmColor3","RightArmColor3","LeftLegColor3","RightLegColor3"} do palette[key]=item[key] end
					baseline.palettes[item]=palette
				end
				for _,definition in clothing do
					if item.ClassName==definition[1] then baseline.garments[item]={property=definition[2],template=item[definition[2]],tint=item.Color3} end
				end
			end
			foreign=Instance.new("Folder"); foreign.Name="ForeignAvatarWardrobeSentinel"; foreign.Parent=char
			for _,id in {"rome","egypt","ming"} do
				assert(service.select(player,id,true).ok,"Production switch rejected "..id)
				waitFor(function() return dressed(id) end,"production "..id.." outfit")
				sameState(service.economy:get(player.UserId),profiles[id])
				assert(service.registry:get(player.UserId).plotId==originalClaim.plotId)
			end
			Equipment.clear(player)
			assert(player.Character==baseline.character and foreign.Parent==char)
			for item in baseline.children do assert(item.Parent==char,"Outfit switch deleted an original avatar instance: "..item.Name) end
			for garment,record in baseline.garments do
				assert(garment.Parent==char and garment[record.property]==record.template and garment.Color3==record.tint,"Outfit clear did not restore the original avatar garment")
			end
			for part,color in baseline.parts do assert(part.Parent==char and part.Color==color,"Outfit clear did not restore the original avatar body color") end
			for palette,values in baseline.palettes do for key,value in values do assert(palette[key]==value,"Outfit changed the avatar BodyColors instance") end end
			for _,item in char:GetChildren() do
				assert(item:GetAttribute("GeneratedBy")~="CivilizationOutfit" and item:GetAttribute("GeneratedBy")~="CivilizationEquipment","Cleared avatar retained owned outfit instances")
			end
		end)
		test("forced outfit reapply and return to Sparta preserve each civilization profile",function()
			assert(Equipment.apply(player,catalog.ming,service.economy:get(player.UserId),true))
			assert(dressed("ming"))
			assert(service.select(player,"sparta",true).ok)
			waitFor(function() return dressed("sparta") end,"restored completed Spartan outfit")
			sameState(service.economy:get(player.UserId),original)
			for id,state in profiles do sameState(service.profiles:get(player.UserId,id),state) end
			assert(service.registry:get(player.UserId).plotId==originalClaim.plotId)
		end)
		return {ok=true,cases=cases,nativeAppearanceEvent=true,restoredOriginalInstances=true,
			message="Real avatar reload, production Rome/Egypt/Ming outfit switches, original wardrobe restoration and unchanged per-civilization progress passed"}
	end)
	if observer then observer:Disconnect() end
	if foreign then foreign:Destroy() end
	if not ok and service.profiles:isWritable(player.UserId) and player.Parent==Players then
		pcall(function()
			local current=service.registry:get(player.UserId)
			if current and current.civilizationId~="sparta" then service.select(player,"sparta",true) end
			if player.Character then Equipment.apply(player,catalog.sparta,service.economy:get(player.UserId),true) end
		end)
	end
	assert(ok,result)
	return result
end
