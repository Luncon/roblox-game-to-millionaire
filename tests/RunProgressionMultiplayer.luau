local result = game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(3, {suite="army-progression"})
assert(type(result)=="table" and result.ok, if type(result)=="table" then result.message else "Progression test ended without a result")
print("PROGRESSION_TEST_RESULT: PASS ("..result.cases.." cases): "..result.message)
