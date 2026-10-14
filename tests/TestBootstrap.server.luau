-- The test-project builder replaces Game.Bootstrap with this script.
assert(game:GetService("RunService"):IsStudio(),"The fake-store bootstrap is Studio-only")
local context=require(game.ServerStorage:WaitForChild("RuntimeTests"):WaitForChild("ProfileTestContext"))
assert(context.store.isFakeProfileStore,"Test bootstrap must use an in-memory profile backend")
context.service=require(script.Parent.CivilizationService).start({profileStore=context.store})
