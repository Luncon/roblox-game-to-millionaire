--!strict
local player=game.Players.LocalPlayer
local scene=workspace:WaitForChild('MiniaturePreview')
local screen=Instance.new('ScreenGui');screen.Name='MiniaturePreviewUI';screen.ResetOnSpawn=false;screen.Parent=player:WaitForChild('PlayerGui')
local camera=require(script.Parent.Camera).start(scene,screen)
local ui=require(script.Parent.UI).mount(screen,camera)
for _,building in scene:WaitForChild('Buildings'):GetChildren()do
 local target=building:WaitForChild('SelectTarget')
 target:WaitForChild('ClickDetector').MouseClick:Connect(function()ui.inspect(building)end)
 target:WaitForChild('ProximityPrompt').Triggered:Connect(function()ui.inspect(building)end)
end
