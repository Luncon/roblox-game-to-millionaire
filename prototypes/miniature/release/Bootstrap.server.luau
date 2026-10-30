--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ok, message = xpcall(function()
	local LiveStartup = require(script.Parent.LiveStartup)
	LiveStartup.start({ verificationScope = script:GetAttribute("VerificationScope") })
end, debug.traceback)
if not ok then
	ReplicatedStorage:SetAttribute("MiniatureStartupError", "startup_failed")
	warn("Clash of Civilizations startup failed: " .. tostring(message))
end
