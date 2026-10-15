-- This module is mapped only into test places. It never opens Roblox storage.
assert(game:GetService("RunService"):IsStudio(),"Solo verification is Studio-only")
return {store=require(script.Parent.FakeProfileStore).new()}
