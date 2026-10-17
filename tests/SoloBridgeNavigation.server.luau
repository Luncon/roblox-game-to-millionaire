-- One ordinary Studio client; the bootstrap injects only in-memory storage.
assert(game:GetService("RunService"):IsStudio())
local context=require(game.ServerStorage.RuntimeTests.SoloTestContext)
assert(context.store.isFakeProfileStore)
local units=0
local ok,result=pcall(function()
	local deadline=os.clock()+60
	repeat task.wait(.1) until context.service or os.clock()>deadline
	assert(context.service,"Fake-store service did not start")
	local specs=game.ServerStorage.Tests:GetChildren()
	table.sort(specs,function(a,b)return a.Name<b.Name end)
	for _,spec in specs do if spec:IsA("ModuleScript") then
		game:SetAttribute("BridgeNavigationVerificationPhase","Module "..spec.Name)
		units+=require(spec)();task.wait()
	end end
	game:SetAttribute("BridgeNavigationVerificationPhase","Physical bridge traversal")
	return require(game.ServerStorage.RuntimeTests.BridgeNavigation)()
end)
game:SetAttribute("BridgeNavigationVerificationPhase",if ok then "Complete" else "Failed")
local encoded=game.HttpService:JSONEncode({ok=ok,units=units,result=if ok then result else tostring(result)})
game:SetAttribute("BridgeNavigationVerificationResult",encoded)
print("BRIDGE_NAVIGATION_RESULT "..encoded)
if not ok then warn(tostring(result)) end
