--!strict

local Tracks = require(game:GetService("ReplicatedStorage").Shared.UpgradeTracks)
local Visuals = require(script.Parent.EquipmentVisuals)
local Outfits = require(script.Parent.OutfitTemplates)
local Equipment = {}
local OWNER = "CivilizationEquipment"
local styles = {
	sparta={weapon="Dory Spear", kind="spear", armor="Bronze Cuirass", hat="crest", metal=Color3.fromRGB(181,137,65)},
	seneca={weapon="Woodland Bow", kind="bow", armor="Woodland Tunic", hat="band", metal=Color3.fromRGB(130,93,65)},
	britain={weapon="Officer Sword", kind="sword", armor="Redcoat Uniform", hat="tricorn", metal=Color3.fromRGB(160,163,166)},
	mongols={weapon="Steppe Sabre", kind="sabre", armor="Lamellar Armor", hat="cone", metal=Color3.fromRGB(144,151,154)},
	vikings={weapon="Norse Axe", kind="axe", armor="Norse Mail", hat="cone", metal=Color3.fromRGB(145,155,159)},
	persia={weapon="Persian Spear", kind="spear", armor="Scale Cuirass", hat="cap", metal=Color3.fromRGB(189,152,84)},
	japan={weapon="Katana", kind="katana", armor="Sengoku Do Armor", hat="kabuto", metal=Color3.fromRGB(64,69,76)},
	maurya={weapon="Mauryan Spear", kind="spear", armor="Mauryan Cuirass", hat="turban", metal=Color3.fromRGB(176,144,79)},
	spain={weapon="Spanish Rapier", kind="rapier", armor="Steel Breastplate", hat="morion", metal=Color3.fromRGB(178,184,187)},
	egypt={weapon="Khopesh", kind="khopesh", armor="Linen and Bronze", hat="cloth", metal=Color3.fromRGB(189,153,66)},
	rome={weapon="Gladius", kind="sword", armor="Segmented Cuirass", hat="crest", metal=Color3.fromRGB(169,176,181)},
	ottomans={weapon="Kilij", kind="sabre", armor="Ottoman Mail", hat="turban", metal=Color3.fromRGB(174,177,169)},
	ming={weapon="Dao", kind="sabre", armor="Ming Lamellar", hat="cap", metal=Color3.fromRGB(124,139,150)},
}

local function weaponTemplate(civId: string,role: string,kind: string): string?
	if civId=="sparta" then return "spartan-spear" end
	if civId=="britain" and role~="ranged" then return "officer-sword" end
	return ({spear="spear",sword="gladius",bow="bow",katana="katana",sabre="scimitar",axe="axe",
		rapier="rapier",khopesh="khopesh",musket="musket",bayonet="musket",crossbow="crossbow",sling="slingshot"})[kind]
end
local function hatTemplate(civId: string,role: string): string?
	if civId=="egypt" then return if role=="player" then "egypt-pharaoh" else "egypt-anubis" end
	return ({sparta="spartan-helmet",britain="british-tricorn",seneca="seneca-headdress"})[civId]
end
local function mountVisual(parent: Instance,base: BasePart,visual: Model,offset: CFrame,scale: number?)
	if scale and math.abs(scale-1)>.001 then visual:ScaleTo(scale) end
	local handle=visual:FindFirstChild("Handle") :: BasePart
	local delta=base.CFrame*offset*handle.CFrame:Inverse()
	for _,child in visual:GetDescendants() do
		if child:IsA("BasePart") then child.CFrame=delta*child.CFrame end
	end
	visual.Parent=parent
	local weld=Instance.new("WeldConstraint")
	weld.Name,weld.Part0,weld.Part1,weld.Parent="EquipmentVisualGrip",base,handle,handle
end

local function removeOwned(parent: Instance?)
	if not parent then return end
	for _, child in parent:GetChildren() do
		if child:GetAttribute("GeneratedBy") == OWNER then child:Destroy() end
	end
end

local function piece(parent: Instance, base: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material?): Part
	local object = Instance.new("Part")
	object.Name = name
	object.Size = size
	object.CFrame = base.CFrame * offset
	object.Color = color
	object.Material = material or Enum.Material.Metal
	object.CanCollide = false
	object.CanTouch = false
	object.CanQuery = false
	object.Massless = true
	object.Parent = parent
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = base
	weld.Part1 = object
	weld.Parent = object
	return object
end

function Equipment.clear(player: Player)
	local character = player.Character
	if character then Outfits.clear(character) end
	removeOwned(character)
	removeOwned(player:FindFirstChildOfClass("Backpack"))
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local base = character:GetAttribute("EquipmentBaseHealth")
		if humanoid and typeof(base) == "number" then
			humanoid.MaxHealth = base
			humanoid.Health = math.min(humanoid.Health, base)
		end
		for _, key in {"EquipmentCivilization", "EquippedWeaponLevel", "EquippedArmorLevel", "EquipmentBaseHealth", "EquipmentRole"} do
			character:SetAttribute(key, nil)
		end
	end
end

local function applyCharacter(character: Model?, backpack: Instance?, civilization, state, warrior: boolean, force: boolean?): boolean
	if not character then return false end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	local head = character:FindFirstChild("Head")
	if not humanoid or humanoid.Health <= 0 or not torso or not torso:IsA("BasePart")
		or not head or not head:IsA("BasePart") then return false end
	local style = styles[civilization.id]
	assert(style, "Unknown civilization equipment")
	if warrior then
		style = table.clone(style)
		local configName = if character:GetAttribute("WarriorClass") == "ranged" then "RangedConfig" else "WarriorConfig"
		local variant = require(game:GetService("ReplicatedStorage").Shared[configName]).variants[civilization.id]
		style.weapon, style.kind = variant.weaponName, variant.weaponKind
	end
	local role = if warrior then character:GetAttribute("WarriorClass") or "warrior" else "player"
	local weaponLevel = state.weaponLevel or 1
	local armorLevel = state.armorLevel or 1
	if not force and character:GetAttribute("EquipmentCivilization") == civilization.id
		and character:GetAttribute("EquippedWeaponLevel") == weaponLevel
		and character:GetAttribute("EquippedArmorLevel") == armorLevel
		and character:GetAttribute("EquipmentRole") == role then return true end
	removeOwned(character)
	removeOwned(backpack)
	character:SetAttribute("EquipmentRole", role)
	character:SetAttribute("EquipmentCivilization", civilization.id)
	character:SetAttribute("EquippedWeaponLevel", weaponLevel)
	character:SetAttribute("EquippedArmorLevel", armorLevel)
	local baseHealth = character:GetAttribute("EquipmentBaseHealth")
	if typeof(baseHealth) ~= "number" then baseHealth = if warrior then 100 else humanoid.MaxHealth; character:SetAttribute("EquipmentBaseHealth", baseHealth) end
	local previousMaximum = humanoid.MaxHealth
	local previousHealth = humanoid.Health
	humanoid.MaxHealth = baseHealth + Tracks.armor[armorLevel].health - 100
	humanoid.Health = math.clamp(previousHealth + humanoid.MaxHealth - previousMaximum, 0, humanoid.MaxHealth)

	local custom = warrior and character:GetAttribute("CustomMeleeModel") == true
	local armor = Instance.new("Model")
	armor.Name = "CivilizationArmor"
	armor:SetAttribute("GeneratedBy", OWNER)
	armor:SetAttribute("CivilizationId", civilization.id)
	armor:SetAttribute("ArmorLevel", armorLevel)
	armor:SetAttribute("Style", style.armor)
	armor.Parent = character
	local hatId=hatTemplate(civilization.id,role)
	local hat=if not custom and hatId then Visuals.clone(hatId) else nil
	local outfitted=not custom and Outfits.apply(character,civilization.id,armor,hat~=nil)
	local outfitHead=false
	for _,visual in armor:GetChildren() do
		if visual:GetAttribute("OutfitBodyPart")=="Head" then outfitHead=true;break end
	end
	local cloth = if civilization.id == "britain" then Color3.fromRGB(170,47,43) else civilization.color
	local chestColor = if armorLevel < 10 then cloth else style.metal
	local chestSize = Vector3.new(torso.Size.X*1.04, torso.Size.Y*.85, torso.Size.Z+.25)
	if custom or outfitted then
		piece(armor,torso,"TierInsignia",Vector3.new(.3,.35,.08),CFrame.new(-torso.Size.X*.3,torso.Size.Y*.3,-torso.Size.Z/2-.08),if armorLevel>=20 then Color3.fromRGB(224,184,74) else cloth)
		if armorLevel >= 10 then
			piece(armor,torso,"UpgradePlate",Vector3.new(torso.Size.X*.6,torso.Size.Y*.45,torso.Size.Z+.15),CFrame.new(0,-torso.Size.Y*.2,0),style.metal)
		end
	else
		piece(armor, torso, "Cuirass", chestSize, CFrame.new(), chestColor, if armorLevel < 10 then Enum.Material.Fabric else Enum.Material.Metal)
		piece(armor, torso, "CivilizationSash", Vector3.new(chestSize.X+.03,.22,chestSize.Z+.03), CFrame.new(0,-chestSize.Y*.22,0), cloth, Enum.Material.Fabric)
	end
	if armorLevel >= 10 then
		for _, x in {-1, 1} do
			piece(armor, torso, "ShoulderGuard", Vector3.new(.55,.3,chestSize.Z), CFrame.new(x*(torso.Size.X/2+.12),torso.Size.Y*.35,0), style.metal)
		end
	end
	if armorLevel >= 20 then
		piece(armor, torso, "TierTrim", Vector3.new(chestSize.X+.08,.15,chestSize.Z+.08), CFrame.new(0,chestSize.Y*.35,0), Color3.fromRGB(224,184,74))
	end
	if armorLevel >= 40 then
		piece(armor, torso, "ChampionCloak", Vector3.new(chestSize.X,2.1,.12), CFrame.new(0,-.65,chestSize.Z/2+.1), cloth, Enum.Material.Fabric)
	end
	if hat then
		local scale=math.clamp(head.Size.Y,.65,1.6)
		local offset=hat:GetAttribute("HeadOffset") or CFrame.new(0,.5,0)
		offset=CFrame.new(offset.Position*scale)*(offset-offset.Position)
		mountVisual(armor,head,hat,offset,scale)
	elseif not custom and not outfitHead then
		local capColor = if style.hat == "turban" or style.hat == "cloth" or style.hat == "band" then cloth else style.metal
		if style.hat == "band" then
			piece(armor, head, "Headband", Vector3.new(head.Size.X+.1,.18,head.Size.Z+.1), CFrame.new(0,.25,0), capColor, Enum.Material.Fabric)
		else
			piece(armor, head, "HelmetCap", Vector3.new(head.Size.X+ .12,.35,head.Size.Z+ .12), CFrame.new(0,head.Size.Y/2,0), capColor)
			if style.hat == "crest" or style.hat == "morion" then
				piece(armor, head, "Crest", Vector3.new(.2,.55,head.Size.Z+ .3), CFrame.new(0,head.Size.Y/2+ .4,0), if style.hat == "crest" then cloth else style.metal)
			elseif style.hat == "tricorn" then
				for angle=0,2 do piece(armor, head, "TricornBrim", Vector3.new(1.65,.18,.35), CFrame.new(0,.55,0)*CFrame.Angles(0,angle*math.pi*2/3,0)*CFrame.new(0,0,.55), Color3.fromRGB(35,35,38), Enum.Material.Fabric) end
			elseif style.hat == "kabuto" or style.hat == "cloth" then
				piece(armor, head, "NeckGuard", Vector3.new(head.Size.X+.15,.7,.2), CFrame.new(0,-.1,head.Size.Z/2+.1), capColor)
			elseif style.hat == "cone" then
				piece(armor, head, "HelmetRidge", Vector3.new(.25,.4,.25), CFrame.new(0,head.Size.Y/2+.3,0), style.metal)
			end
		end
	end

	if role=="medic" then
  piece(armor,torso,"BandageSatchel",Vector3.new(.9,.8,.45),CFrame.new(-1,-.65,-.7),Color3.fromRGB(140,104,64),Enum.Material.Fabric)
  piece(armor,torso,"SatchelFlap",Vector3.new(.95,.2,.5),CFrame.new(-1,-.2,-.7),Color3.fromRGB(238,226,198),Enum.Material.Fabric)
  piece(armor,torso,"BandageRoll",Vector3.new(.55,.4,.4),CFrame.new(-1,-.05,-.7),Color3.fromRGB(246,238,212),Enum.Material.Fabric)
  return true
 end
 local tool = Instance.new("Tool")
	-- NPC weapons use one explicit grip. Omitting the reserved Handle name
	-- prevents Humanoid from adding a competing automatic RightGrip weld.
	tool.RequiresHandle = not warrior
	tool.Name = style.weapon.." · "..Tracks.weapon[weaponLevel].name
	tool.CanBeDropped = false
	tool.ToolTip = if role == "ranged" then "Ranged troop weapon" elseif warrior then "Melee warrior weapon" else "Activate to strike nearby enemies in the battlefield"
	tool:SetAttribute("GeneratedBy", OWNER)
	tool:SetAttribute("CivilizationId", civilization.id)
	tool:SetAttribute("WeaponLevel", weaponLevel)
	tool:SetAttribute("Damage", Tracks.weapon[weaponLevel].damage)
	tool:SetAttribute("WeaponKind", style.kind)
	if warrior then
		tool:SetAttribute("WarriorClass",role)
		if role == "ranged" then
			tool:SetAttribute("Damage",Tracks.weapon[weaponLevel].damage*require(game:GetService("ReplicatedStorage").Shared.RangedConfig).damageMultiplier)
		end
	end
	local handle = Instance.new("Part")
	handle.Name = if warrior then "WarriorHandle" else "Handle"
	handle.Size = Vector3.new(.25,1,.25)
	handle.Color = Color3.fromRGB(104,73,47)
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.CanTouch = false
	handle.CanQuery = false
	handle.Massless = true
	handle.Parent = tool
	local visualId=weaponTemplate(civilization.id,role,style.kind)
	local weaponVisual=if visualId then Visuals.clone(visualId) else nil
	if weaponVisual then
		tool.Grip=weaponVisual:GetAttribute("Grip") or CFrame.identity
		mountVisual(tool,handle,weaponVisual,CFrame.identity)
		local visualHandle=weaponVisual:FindFirstChild("Handle") :: BasePart
		visualHandle.Name="VisualHandle"
		handle.Transparency=1
	end
	local steel = if weaponLevel >= 40 then Color3.fromRGB(226,191,94) else style.metal
	if weaponVisual then
		-- Appearance is imported; all weapon stats above remain server generated.
	elseif style.kind == "musket" or style.kind == "bayonet" then
		piece(tool,handle,"Stock",Vector3.new(.35,3,.45),CFrame.new(0,1,0),handle.Color,Enum.Material.Wood)
		piece(tool,handle,"Barrel",Vector3.new(.22,3,.22),CFrame.new(0,2.8,-.25),steel)
		if style.kind == "bayonet" then piece(tool,handle,"Bayonet",Vector3.new(.15,1.2,.1),CFrame.new(0,4.5,-.25),steel) end
	elseif style.kind == "crossbow" then
		piece(tool,handle,"CrossbowStock",Vector3.new(.35,1.8,.4),CFrame.new(0,.8,0),handle.Color,Enum.Material.Wood)
		piece(tool,handle,"CrossbowLimbs",Vector3.new(2.5,.2,.2),CFrame.new(0,1.4,0),handle.Color,Enum.Material.Wood)
		piece(tool,handle,"CrossbowString",Vector3.new(2.3,.05,.05),CFrame.new(0,1.1,-.2),Color3.fromRGB(227,218,193),Enum.Material.Fabric)
	elseif style.kind == "sling" then
		for _, side in {-1,1} do piece(tool,handle,"SlingCord",Vector3.new(.05,1.7,.05),CFrame.new(side*.3,.8,0),Color3.fromRGB(179,151,100),Enum.Material.Fabric) end
		piece(tool,handle,"SlingPouch",Vector3.new(.65,.3,.25),CFrame.new(0,1.6,0),handle.Color,Enum.Material.Fabric)
	elseif style.kind == "bow" then
		for _, side in {-1,1} do piece(tool,handle,"BowLimb",Vector3.new(.2,1.7,.2),CFrame.new(0,side*1.2,0)*CFrame.Angles(side*.4,0,0),handle.Color,Enum.Material.Wood) end
		piece(tool,handle,"Bowstring",Vector3.new(.04,3,.04),CFrame.new(0,0,-.4),Color3.fromRGB(227,218,193),Enum.Material.Fabric)
	elseif style.kind == "axe" then
		piece(tool,handle,"Haft",Vector3.new(.22,2,.22),CFrame.new(0,1,0),handle.Color,Enum.Material.Wood)
		piece(tool,handle,"AxeHead",Vector3.new(1.2,.8,.2),CFrame.new(.35,1.8,0),steel)
	elseif style.kind == "spear" then
		piece(tool,handle,"Shaft",Vector3.new(.18,4,.18),CFrame.new(0,1.8,0),handle.Color,Enum.Material.Wood)
		piece(tool,handle,"SpearHead",Vector3.new(.4,.8,.12),CFrame.new(0,4.1,0),steel)
	else
		local length = if style.kind == "sword" then 1.8 else 2.6
		piece(tool,handle,"Blade",Vector3.new(if style.kind=="rapier" then .12 else .32,length,.1),CFrame.new(0,length/2+.4,0),steel)
		piece(tool,handle,"Guard",Vector3.new(.9,.16,.2),CFrame.new(0,.5,0),cloth)
		if style.kind == "sabre" or style.kind == "khopesh" then piece(tool,handle,"CurvedTip",Vector3.new(.7,.6,.1),CFrame.new(.25,length+.25,0)*CFrame.Angles(0,0,-.4),steel) end
	end
	if warrior then
		local arm = character:FindFirstChild("Right Arm") :: BasePart
		local grip = arm.CFrame * CFrame.new(0,-1,0) * CFrame.Angles(-math.pi/2,0,0) * tool.Grip:Inverse()
		local delta = grip * handle.CFrame:Inverse()
		for _, item in tool:GetDescendants() do
			if item:IsA("BasePart") then item.CFrame = delta * item.CFrame end
		end
		tool.Parent = character
		local weld = Instance.new("WeldConstraint")
		weld.Name, weld.Part0, weld.Part1, weld.Parent = "WarriorGrip", arm, handle, handle
	else
		tool.Parent = backpack or character
		humanoid:EquipTool(tool)
	end
	if civilization.id=="sparta" and role~="ranged" then
		local leftArm=character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm")
		local shield=if leftArm and leftArm:IsA("BasePart") then Visuals.clone("spartan-shield") else nil
		if shield then mountVisual(armor,leftArm :: BasePart,shield,CFrame.new(0,0,-.7)*CFrame.Angles(0,math.pi,0),.7) end
	end
	return true
end

function Equipment.apply(player: Player, civilization, state, force: boolean?): boolean
	return applyCharacter(player.Character, player:FindFirstChildOfClass("Backpack"), civilization, state, false, force)
end

function Equipment.applyWarrior(character: Model, civilization, state): boolean
	return applyCharacter(character, nil, civilization, state, true)
end

return Equipment
