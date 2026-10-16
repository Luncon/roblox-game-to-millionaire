-- Native keyboard input, never fires a production RemoteEvent directly.
return function()
	local player=game:GetService("Players").LocalPlayer
	local input=game:GetService("UserInputService"):CreateVirtualInput()
	assert(input,"Native keyboard input is unavailable")
	local remote=game.ReplicatedStorage.CombatRemotes.Skill
	local response=nil
	local connection=remote.OnClientEvent:Connect(function(value)response=value end)
	local ok,result=pcall(function()
		input:SendKey(true,Enum.KeyCode.R,false);task.wait(.06)
		input:SendKey(false,Enum.KeyCode.R,false)
		local deadline=os.clock()+3
		repeat task.wait(.02)until response or os.clock()>deadline
		assert(response,"R did not produce a server skill response")
		if response.ok then task.wait(1.3)end
		local hud=player.PlayerGui:WaitForChild("WeaponSkillHUD",5)
		return {ok=true,accepted=response.ok,reason=response.reason,text=hud.WeaponSkill.Text}
	end)
	pcall(function()input:SendKey(false,Enum.KeyCode.R,false)end)
	connection:Disconnect();assert(ok,result);return result
end
