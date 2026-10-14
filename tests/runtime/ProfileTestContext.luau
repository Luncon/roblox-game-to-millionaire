-- Shared only by the generated test-place bootstrap and test harnesses.
-- Trusted Studio test arguments can carry a flushed snapshot into a fresh server.
local args=game:GetService("StudioTestService"):GetTestArgs()
local seed=if type(args)=="table" and type(args.profileSeed)=="table" then args.profileSeed else nil
return {store=require(script.Parent.FakeProfileStore).new(seed)}
