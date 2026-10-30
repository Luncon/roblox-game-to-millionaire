--!strict
-- Frame measurements must execute in a native LocalScript, like the renderer.
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
assert(RunService:IsStudio(), "Smoothing verification is Studio-only")
local running = false
local function requested()
	if running or Replicated:GetAttribute("RunMiniatureArmySmoothing") ~= true then
		return
	end
	running = true
	Replicated:SetAttribute("MiniatureArmySmoothingRunnerFinished", false)
	Replicated:SetAttribute("MiniatureArmySmoothingResult", nil)
	task.spawn(function()
		local ok, failure = pcall(function()
			require(Replicated.NativeArmySmoothing)({ timeout = 240, observeSeconds = 3 })
		end)
		if not ok then
			warn(failure)
		end
		Replicated:SetAttribute("MiniatureArmySmoothingRunnerFinished", true)
	end)
end
Replicated:GetAttributeChangedSignal("RunMiniatureArmySmoothing"):Connect(requested)
requested()
