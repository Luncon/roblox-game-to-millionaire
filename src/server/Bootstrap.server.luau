--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProjectInfo = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ProjectInfo"))

print(ProjectInfo.name .. ": server connected through Rojo")

if game:GetService("RunService"):IsStudio() and game.PlaceId == 0 then
	ReplicatedStorage:SetAttribute("GameStartupError", "unpublished_place")
	warn("Publish a test experience and enable Studio Access to API Services to use saved profiles. Use the isolated test project for temporary progress.")
	return
end

local ok, message = xpcall(function()
	require(script.Parent.CivilizationService).start()
end, debug.traceback)
if not ok then
	ReplicatedStorage:SetAttribute("GameStartupError", "startup_failed")
	warn(message)
end
