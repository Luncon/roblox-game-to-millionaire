local result=game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(3,{suite="world-growth"})
assert(type(result)=="table" and result.ok,if type(result)=="table" then result.message else "World growth test ended without a result")
print("WORLD_GROWTH_TEST_RESULT: PASS ("..result.cases.." cases): "..result.message)
