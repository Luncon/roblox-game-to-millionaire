--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProjectInfo = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ProjectInfo"))

print(ProjectInfo.name .. ": server connected through Rojo")

require(script.Parent.CivilizationService).start()
