local result = game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(2, { suite = "civilization-claims" })
assert(type(result) == "table" and result.ok, if type(result) == "table" then result.message else "Multiplayer test ended without a result")
print("MULTIPLAYER_TEST_RESULT: PASS (" .. result.cases .. " cases): " .. result.message)
