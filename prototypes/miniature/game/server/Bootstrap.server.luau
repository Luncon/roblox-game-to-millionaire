--!strict
local RunService = game:GetService("RunService")
assert(RunService:IsStudio(), "Miniature settlement sandbox is Studio-only")

local FakeProfileStore = require(game:GetService("ServerStorage"):WaitForChild("FakeProfileStore"))
local Runtime = require(script.Parent.Runtime)
Runtime.start({ store = FakeProfileStore.new() })
