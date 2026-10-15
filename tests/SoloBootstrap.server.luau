-- Replace Game.Bootstrap with this script for ONE ordinary Studio Play session.
assert(game:GetService("RunService"):IsStudio(),"Solo fake-store bootstrap is Studio-only")
local context=require(game.ServerStorage:WaitForChild("RuntimeTests"):WaitForChild("SoloTestContext"))
assert(context.store.isFakeProfileStore,"Solo verification must never touch player data")
game:SetAttribute("SoloVerificationEnabled",true)
context.service=require(script.Parent.CivilizationService).start({profileStore=context.store})
