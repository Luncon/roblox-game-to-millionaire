-- Run this in the SERVER context after starting ordinary solo Studio Play.
-- It polls the harness; it never starts another Studio session or client.
assert(game:GetService("RunService"):IsStudio(),"Solo verification is Studio-only")
local output=game.ServerStorage:WaitForChild("SoloVerificationResult",30)
assert(output,"Build the solo test project and start ordinary Studio Play")
local deadline=os.clock()+360
while output.Value=="" and os.clock()<deadline do task.wait(.25) end
assert(output.Value~="","Solo checks did not finish: "..tostring(game:GetAttribute("SoloVerificationPhase")))
local result=game:GetService("HttpService"):JSONDecode(output.Value)
assert(result.ok,result.message)
print("SOLO_CHECKS: "..result.unitCases.." module cases; "..result.cases.." runtime cases")
return result
