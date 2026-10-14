--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProjectInfo = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ProjectInfo"))

print(ProjectInfo.name .. ": client connected through Rojo")

require(script.Parent.CivilizationUI).start()
