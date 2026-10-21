--!strict
-- Deliberately separate from Game.Bootstrap: no economy, profiles or combat.
assert(game.RunService:IsStudio(),'The miniature scale preview is Studio-only')
local scene=require(script.Parent.World).create()
require(script.Parent.Actors).start(scene)
game.Players.PlayerAdded:Connect(function(player)
 player:SetAttribute('MiniatureCommander',true)
end)
scene:SetAttribute('Ready',true)
