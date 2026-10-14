--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("CombatRemotes",20)
local attack = if remotes then remotes:WaitForChild("Attack",10) else nil
if not attack or not attack:IsA("RemoteEvent") then return end
local connections = {}
local boundTools = {}
local added: RBXScriptConnection?
local lastSwing = -math.huge

local function bindCharacter(character: Model)
	if added then added:Disconnect() end
	for _, connection in connections do connection:Disconnect() end
	table.clear(connections)
	table.clear(boundTools)
	local function bindTool(tool: Instance)
		if not tool:IsA("Tool") then return end
		if boundTools[tool] then return end
		boundTools[tool] = true
		table.insert(connections,tool.Activated:Connect(function()
			if tool:GetAttribute("GeneratedBy") ~= "CivilizationEquipment" then return end
			if player.Character ~= character or tool.Parent ~= character or os.clock()-lastSwing < 1 then return end
			lastSwing = os.clock()
			attack:FireServer()
			local animation = Instance.new("StringValue")
			animation.Name, animation.Value, animation.Parent = "toolanim", "Slash", tool
			Debris:AddItem(animation,.5)
		end))
	end
	for _, tool in character:GetChildren() do bindTool(tool) end
	added = character.ChildAdded:Connect(bindTool)
end
player.CharacterAdded:Connect(bindCharacter)
if player.Character then bindCharacter(player.Character) end
