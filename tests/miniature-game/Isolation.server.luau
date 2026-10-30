--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local ok, message = pcall(function()
	local deadline = os.clock() + 10
	repeat
		task.wait(0.1)
	until ReplicatedStorage:GetAttribute("MiniatureSandboxReady") or os.clock() > deadline
	assert(ReplicatedStorage:GetAttribute("MiniatureSandboxReady"), "Sandbox did not start")
	assert(ReplicatedStorage:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore", "Wrong storage")
	assert(ServerScriptService:FindFirstChild("Sandbox"), "Sandbox mapping is missing")
	local bootstraps = 0
	for _, child in ServerScriptService.Sandbox:GetChildren() do
		if child:IsA("Script") and child.Name == "Bootstrap" then
			bootstraps += 1
		end
	end
	assert(bootstraps == 1, "Sandbox must have exactly one Bootstrap")
	assert(not ServerScriptService:FindFirstChild("Game"), "Production server mapping was loaded")
	assert(not Workspace:FindFirstChild("MiniaturePreview"), "Decorative preview was started twice")
	assert(Workspace:FindFirstChild("MiniatureSandbox"), "Sandbox scene is missing")
	for _, name in { "CombatRemotes", "EconomyRemotes", "ProfileService" } do
		assert(not ReplicatedStorage:FindFirstChild(name), "Production dependency loaded: " .. name)
	end
	local actions = ReplicatedStorage:FindFirstChild("MiniatureActions")
	assert(actions and actions:IsA("Folder"), "Missing isolated action boundary")
	local allowed = {
		Snapshot = true,
		Receipt = true,
		select = true,
		travel = true,
		collect = true,
		sellAll = true,
		buy = true,
		place = true,
		reclaim = true,
		targetOutpost = true,
	}
	for name in allowed do
		local remote = actions:FindFirstChild(name)
		assert(remote and remote:IsA("RemoteEvent"), "Missing isolated action: " .. name)
	end
	for _, remote in actions:GetChildren() do
		assert(allowed[remote.Name] and remote:IsA("RemoteEvent"), "Unexpected isolated action: " .. remote.Name)
	end
	for _, name in { "sell", "hire", "assign", "move", "unpack", "upgradeHall", "research", "settings", "roster" } do
		assert(not actions:FindFirstChild(name), "Retired action is still exposed: " .. name)
	end
end)
ReplicatedStorage:SetAttribute("MiniatureIsolationResult", if ok then "passed" else tostring(message))
assert(ok, tostring(message))
