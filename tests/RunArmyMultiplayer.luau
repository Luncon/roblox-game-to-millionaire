local result = game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(2, {suite="warrior-combat"})
assert(type(result) == "table" and result.ok, if type(result) == "table" then result.message else "Army test ended without a result")
print("ARMY_TEST_RESULT: PASS (" .. result.cases .. " cases): " .. result.message)
