--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Tracks = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UpgradeTracks"))
local Development = require(ReplicatedStorage.Shared.SettlementDevelopment)
local EconomyUI = {}
local TEXT = Color3.fromRGB(246, 240, 223)
local GOLD = Color3.fromRGB(220, 181, 98)

local function label(parent: Instance, name: string, size: number): TextLabel
	local object = Instance.new("TextLabel")
	object.Name = name
	object.BackgroundTransparency = 1
	object.Font = Enum.Font.Gotham
	object.TextSize = size
	object.TextColor3 = TEXT
	object.TextXAlignment = Enum.TextXAlignment.Left
	object.TextWrapped = true
	object.Parent = parent
	return object
end

function EconomyUI.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	local hud = screen:WaitForChild("SettlementHUD") :: Frame
	local title = hud:WaitForChild("Civilization") :: TextLabel
	local instruction = hud:WaitForChild("Instruction") :: TextLabel
	local limit = hud:FindFirstChildOfClass("UISizeConstraint") :: UISizeConstraint
	local coins = label(hud, "Coins", 22)
	coins.Font = Enum.Font.GothamBold
	coins.TextColor3 = GOLD
	local progression = label(hud, "Progression", 12)
	local feedback = label(hud, "EconomyFeedback", 11)
	feedback.TextColor3 = GOLD
	local notice = label(hud, "SessionNotice", 10)
	local army = label(hud, "ArmyStatus", 10)
	army.TextColor3 = GOLD
	notice.Text = "Loading saved progress…"
	notice.TextColor3 = Color3.fromRGB(183, 194, 193)
	instruction.Text = "Gold pad: +1 coin · Upgrades beside each building."
	local state = { coins = 0, level = 1, weaponLevel = 1, armorLevel = 1, barracksLevel = 1, revision = -1 }
	local compact = false
	local function renderArmy()
		local level = player:GetAttribute("BarracksLevel") or 0
		if level < 1 then
			army.Text = "Barracks unlocks at settlement 2"
			return
		end
		local tier = Tracks.barracks[level]
		local warrior = player:GetAttribute("WarriorCount") or 0
		local ranged = player:GetAttribute("RangedCount") or 0
		local function status(count,attribute)
			if count > 0 then return "active" end
			local deadline = player:GetAttribute(attribute)
			local remaining = if typeof(deadline) == "number" then math.max(0,math.ceil(deadline-workspace:GetServerTimeNow())) else 0
			return if remaining > 0 then remaining .. "s" else "deploying"
		end
		local units=string.format("Melee %d · Ranged %d",warrior,ranged)
		local capacity=player:GetAttribute("TroopCapacity") or tier.capacity
		local nextSpawn=player:GetAttribute("NextRecruitRespawnAt") or 0
		if nextSpawn>workspace:GetServerTimeNow()then units..=" · Next spawn "..math.ceil(nextSpawn-workspace:GetServerTimeNow()).."s"end
		local medic=player:GetAttribute("MedicCount") or 0
		army.Text = string.format("Barracks %s · %d/%d troops · fighters %gs respawn\n%s",tier.name,warrior+ranged+medic,capacity,tier.respawnDelay,units)
		if player:GetAttribute("HospitalLevel")==1 then
			army.Text..="\nHospital · Medic "..(if player:GetAttribute("RecruitMedic")==0 and medic==0 then "not selected" else status(medic,"MedicRespawnAt")).." · Yard recovery"
		end
	end

	local function trackText(kind: string, level: number): string
		local offer = Development.offer(state,kind)
		if offer.requiredSettlement > state.level then return string.format("%d · Base %d unlock",level,offer.requiredSettlement) end
		local cost = offer.cost
		return if cost then string.format("%d · Next %dc", level, cost) else string.format("%d · MAX", level)
	end
	local function render()
		renderArmy()
		local status=player:GetAttribute("ProgressStatus")
		local reason=player:GetAttribute("ProgressError")
		local saved=player:GetAttribute("ProgressSavedAt")
		notice.Text = if status=="saving" then "Saving your civilization progress…"
			elseif status=="ready" and reason=="save_failed" then "Save delayed · retrying automatically"
			elseif status=="ready" then (if typeof(saved)=="number" then "Progress loaded · autosaving enabled" else "Progress autosaves for each civilization")
			elseif status=="loading" then "Loading saved progress…"
			elseif status=="releasing" then "Saving progress before leaving…"
			elseif status=="lost" then "Progress session ended · rejoin to reload safely"
			else "Saving unavailable · progress changes are paused"
		coins.Text = string.format("%d coins", state.coins)
		if (state.farmLevel or 0)>0 then coins.Text..=string.format(" · Farm %d/%d",state.farmCoins or 0,Development.storageCapacity(state)) end
		if compact then
			local function short(kind: string, level: number): string
				local offer=Development.offer(state,kind)
				if offer.requiredSettlement > state.level then return string.format("%d:Base%d",level,offer.requiredSettlement) end
				local cost = offer.cost
				return string.format("%d:%s", level, if cost then tostring(cost) .. "c" else "MAX")
			end
			progression.Text = string.format("Base %s · Weapon %s · Armor %s", short("settlement", state.level),
				short("weapon", state.weaponLevel), short("armor", state.armorLevel))
		else
			progression.Text = string.format("Settlement %s\nWeapon %s · Armor %s", trackText("settlement", state.level),
				trackText("weapon", state.weaponLevel), trackText("armor", state.armorLevel))
		end
		local offer=Development.offer(state,"settlement")
		if #offer.missing>0 then progression.Text="Level 10 needs: "..table.concat(offer.missing,", ") end
	end
	local function layout()
		compact = screen.AbsoluteSize.Y < 400
		local height = if compact then 146 else 198
		hud.Size = UDim2.new(1, -32, 0, height)
		limit.MaxSize = Vector2.new(360, height)
		local function place(object: TextLabel, y: number, h: number, size: number)
			object.Position = UDim2.fromOffset(12, y)
			object.Size = UDim2.new(1, -24, 0, h)
			object.TextSize = size
		end
		place(title, if compact then 4 else 6, if compact then 18 else 22, if compact then 14 else 16)
		title.Size = UDim2.new(1,-124,0,if compact then 18 else 22)
		local change = hud:FindFirstChild("SwitchCivilization")
		if change and change:IsA("GuiButton") then
			change.Position = UDim2.new(1,-100,0,if compact then 4 else 6)
			change.Size = UDim2.fromOffset(88,if compact then 18 else 22)
		end
		title.TextScaled = true
		title.TextWrapped = false
		place(coins, if compact then 22 else 30, if compact then 20 else 26, if compact then 18 else 22)
		place(progression, if compact then 44 else 58, if compact then 16 else 40, if compact then 10 else 12)
		place(instruction, if compact then 62 else 100, if compact then 12 else 16, 10)
		place(feedback, if compact then 74 else 116, if compact then 12 else 16, 10)
		place(army, if compact then 86 else 134, 44, if compact then 9 else 10)
		place(notice, if compact then 132 else 182, 12, 10)
		render()
	end
	local function acceptState(candidate)
		if type(candidate) ~= "table" or type(candidate.revision) ~= "number" or candidate.revision < state.revision then return end
		for _, key in { "coins", "level", "weaponLevel", "armorLevel" } do
			if type(candidate[key]) ~= "number" then return end
		end
		state = candidate
	end
	local function syncAttributes()
		acceptState({ coins = player:GetAttribute("Coins"), level = player:GetAttribute("SettlementLevel"),
			weaponLevel = player:GetAttribute("WeaponLevel"), armorLevel = player:GetAttribute("ArmorLevel"),
			barracksLevel = player:GetAttribute("BarracksUpgradeLevel"),
			trainingLevel=player:GetAttribute("TrainingLevel"),farmLevel=player:GetAttribute("FarmLevel"),
			workersLevel=player:GetAttribute("WorkersLevel"),armyCampLevel=player:GetAttribute("ArmyCampLevel"),
			farmCoins=player:GetAttribute("FarmCoins"),extraTroopClass=player:GetAttribute("ExtraTroopClass"),
			blacksmithLevel=player:GetAttribute("BlacksmithLevel"),armorerLevel=player:GetAttribute("ArmorerLevel"),
			storehouseLevel=player:GetAttribute("StorehouseLevel"),hospitalLevel=player:GetAttribute("HospitalLevel"),
			revision = player:GetAttribute("EconomyRevision") })
		render()
	end
	for _, attribute in { "Coins", "SettlementLevel", "WeaponLevel", "ArmorLevel", "BarracksUpgradeLevel", "EconomyRevision", "ProgressStatus", "ProgressError", "ProgressSavedAt",
		"TrainingLevel","FarmLevel","WorkersLevel","ArmyCampLevel","FarmCoins","ExtraTroopClass",
		"BlacksmithLevel","ArmorerLevel","StorehouseLevel","HospitalLevel" } do
		player:GetAttributeChangedSignal(attribute):Connect(syncAttributes)
	end
	for _, attribute in { "BarracksLevel", "WarriorCount", "RangedCount", "WarriorRespawnAt", "RangedRespawnAt","CampCount","CampClass","CampRespawnAt","ReinforcementCount","ReinforcementRespawnAt","TroopCapacity","MedicCount","MedicRespawnAt","NextRecruitRespawnAt","RecruitMedic" } do
		player:GetAttributeChangedSignal(attribute):Connect(renderArmy)
	end
	task.spawn(function()
		while screen.Parent do renderArmy(); task.wait(.25) end
	end)
	screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	layout()
	syncAttributes()
	local errors = {
		settlement_locked = "Expand your settlement to unlock this tier.",
		profile_unavailable = "Saved progress is unavailable. Changes are paused.",
		prerequisite = "Buy the preceding tier first.",
		insufficient_funds = "Click the gold pad to afford this upgrade.",
		stale_level = "Upgrade changed. Check the price on the pad.",
		max_level = "This upgrade is already at maximum level.",
		rate_limited = "Please wait a moment, then use the pad again.",
		invalid = "Try your own plot's pad again.",
		not_claimed = "Choose a civilization before using the pads.",
		coin_limit = "The coin limit has been reached.",
		empty_farm = "Your farm crate is empty. Farmers earn while you play.",
	}
	task.spawn(function()
		local remotes = ReplicatedStorage:WaitForChild("EconomyRemotes", 15)
		local updates = if remotes then remotes:WaitForChild("State", 15) else nil
		if not updates or not updates:IsA("RemoteEvent") then
			feedback.Text = "Economy unavailable. Restart Play after syncing."
			return
		end
		updates.OnClientEvent:Connect(function(result)
			if type(result) ~= "table" then return end
			acceptState(result.state)
			if result.ok then
				feedback.Text = if result.action=="farmIncome" then "Farmers added coins to your collection crate."
					elseif result.action=="collectFarm" then string.format("Collected %d farm coins!",result.amount or 0)
					elseif result.action=="training" then "Training yard built! Army orders unlocked."
					elseif result.action=="farm" then "Farmland improved! Visit the fields along your approach road."
					elseif result.action=="workers" then "Worker camp improved! Another farmer is tending the fields."
					elseif result.action=="blacksmith" then "Blacksmith built! Weapon upgrades cost 5% less."
					elseif result.action=="armorer" then "Armorer built! Armor upgrades cost 5% less."
					elseif result.action=="storehouse" then "Storehouse built! Your farm can hold 180 coins."
					elseif result.action=="hospital" then "Hospital built! Medic deployed; troops recover at the training yard."
					elseif result.action=="armyCamp" then "Barracks capacity increased! Choose troop numbers at the Barracks."
					elseif result.action=="troopClass" then "Camp class saved for its next respawn."
					elseif result.action == "upgrade" then "Settlement expanded!"
					elseif result.action == "switch" then "Civilization progress restored!"
					elseif result.action == "weapon" then "Civilization weapon upgraded!"
					elseif result.action == "armor" then "Civilization armor upgraded!"
					elseif result.action == "barracks" then "Barracks upgraded!"
					elseif result.action == "kill" then "+10 coins · Enemy defeated!"
					else "Each gold-pad activation earns one coin."
			else
				feedback.Text = errors[result.reason] or "Try your own plot's pad again."
			end
			render()
		end)
		syncAttributes()
	end)
end

return EconomyUI
