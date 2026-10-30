--!strict
-- Adapt distances only; variants and original cadence remain immutable sources.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Original = require(ReplicatedStorage.OriginalArmyConfig.RangedConfig)
local Config = require(ReplicatedStorage.MiniatureGame.Config)
local tuned = table.clone(Original)
tuned.range = Config.rangedReach / Config.scale
return table.freeze(tuned)
