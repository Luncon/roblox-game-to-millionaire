local testing=game:GetService("StudioTestService")
local result=testing:ExecuteMultiplayerTestAsync(2,{suite="civilization-profiles"})
assert(type(result)=="table" and result.ok,if type(result)=="table" then result.message else "Persistence test ended without a result")
-- Allow Studio to finish tearing down test arguments and clients before
-- starting the next independent server; this does not alter gameplay clocks.
task.wait(2)
local restored=testing:ExecuteMultiplayerTestAsync(2,{suite="civilization-profiles",phase="rejoin",profileSeed=result.saved})
assert(type(restored)=="table" and restored.ok,if type(restored)=="table" then restored.message else "Fresh Studio session ended without a result")
local keys={}
for key in result.saved do table.insert(keys,key) end
table.sort(keys)
local function state(coins,level) return {coins=coins,level=level,weaponLevel=level,armorLevel=level,barracksLevel=level} end
local failureSeed={
	[keys[1]]={schemaVersion=1,civilizations={sparta=state(42,2)},session={token="foreign-session",expiresAt=os.time()+3600}},
	[keys[2]]={schemaVersion=2,civilizations={sparta=state(73,4)}},
}
task.wait(2)
local failed=testing:ExecuteMultiplayerTestAsync(2,{suite="civilization-profiles",phase="failure",profileSeed=failureSeed})
assert(type(failed)=="table" and failed.ok,if type(failed)=="table" then failed.message else "Failure-isolation session ended without a result")
print("PERSISTENCE_TEST_RESULT: PASS ("..(result.cases+restored.cases+failed.cases).." cases): "..restored.message)
