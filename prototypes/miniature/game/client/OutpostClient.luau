--!strict
local Players = game:GetService("Players")
local ProximityPrompts = game:GetService("ProximityPromptService")
local Run = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

type View = {
	loaded: boolean?,
	writable: boolean?,
	claim: { civilizationId: string, plotId: number }?,
	capabilities: { [string]: boolean? }?,
}
export type Callbacks = {
	getView: () -> View?,
	guard: (action: string, targetId: string?) -> string?,
	send: (action: string, args: { outpostId: string }) -> boolean,
	message: (text: string) -> (),
}
export type Controller = { destroy: () -> () }
local OutpostClient = {}

local function targetId(prompt: ProximityPrompt): string?
	local current: Instance? = prompt
	local armyTarget = false
	local id: string? = nil
	while current ~= nil and current ~= Workspace do
		armyTarget = armyTarget or current:GetAttribute("ArmyTarget") == true
		local value = current:GetAttribute("OutpostId")
		if type(value) == "string" and value ~= "" then
			id = value
		end
		current = current.Parent
	end
	return if armyTarget then id else nil
end

function OutpostClient.start(screen: ScreenGui, callbacks: Callbacks): Controller
	local player = Players.LocalPlayer
	local prompts: { [ProximityPrompt]: boolean? } = {}
	local connections: { RBXScriptConnection } = {}
	local stopped = false
	local function available(): boolean
		local view = callbacks.getView()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		return view ~= nil
			and view.loaded == true
			and view.writable == true
			and view.claim ~= nil
			and view.capabilities ~= nil
			and view.capabilities.targetOutpost == true
			and humanoid ~= nil
			and humanoid.Health > 0
	end
	local function register(instance: Instance)
		if not instance:IsA("ProximityPrompt") or targetId(instance) == nil or prompts[instance] ~= nil then
			return
		end
		prompts[instance] = instance.Enabled
		instance.Enabled = instance.Enabled and available()
	end
	table.insert(connections, Workspace.DescendantAdded:Connect(register))
	table.insert(connections, ProximityPrompts.PromptShown:Connect(register))
	table.insert(
		connections,
		ProximityPrompts.PromptTriggered:Connect(function(prompt, who)
			if stopped or who ~= player or not available() then
				return
			end
			local id = targetId(prompt)
			if id == nil then
				return
			end
			local blocked = callbacks.guard("targetOutpost", id)
			if blocked ~= nil then
				callbacks.message(blocked)
				return
			end
			if callbacks.send("targetOutpost", { outpostId = id }) then
				callbacks.message("Army target requested")
			end
		end)
	)
	local sandbox = Workspace:FindFirstChild("MiniatureSandbox")
	if sandbox ~= nil then
		for _, instance in sandbox:GetDescendants() do
			register(instance)
		end
	end
	-- These eight world prompts need only a small presentation refresh. Range
	-- remains the engine/server's responsibility; no capture state is written.
	local elapsed = 0
	table.insert(
		connections,
		Run.Heartbeat:Connect(function(dt)
			elapsed += dt
			if elapsed < 0.25 then
				return
			end
			elapsed = 0
			local enabled = available()
			for prompt, original in prompts do
				if prompt.Parent == nil then
					prompts[prompt] = nil
				else
					prompt.Enabled = original and enabled
				end
			end
		end)
	)
	local function destroy()
		if stopped then
			return
		end
		stopped = true
		for _, connection in connections do
			connection:Disconnect()
		end
		for prompt, original in prompts do
			if prompt.Parent ~= nil then
				prompt.Enabled = original
			end
		end
		table.clear(prompts)
	end
	table.insert(connections, screen.Destroying:Connect(destroy))
	return { destroy = destroy }
end

return table.freeze(OutpostClient)
