local result = game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(8, {suite="civilization-full-server"})
assert(type(result) == "table" and result.ok, if type(result) == "table" then result.message else "Eight-player test ended without a result")
print("FULL_SERVER_TEST_RESULT: PASS (" .. result.cases .. " cases, " .. result.clicks .. " clicks): " .. result.message)
