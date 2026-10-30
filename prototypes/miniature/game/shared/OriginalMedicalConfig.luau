--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Original = require(ReplicatedStorage.OriginalArmyConfig.MedicalConfig)
local Config = require(ReplicatedStorage.MiniatureGame.Config)
local tuned = table.clone(Original)
tuned.range = Config.medicHealRange / Config.scale
-- The original recovery planner needs a reachable point inside healing coverage.
tuned.recoveryDistance = math.min(Original.recoveryDistance, tuned.range - 4)
return table.freeze(tuned)
