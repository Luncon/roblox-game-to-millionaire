-- Native keyboard input, never fires a production RemoteEvent directly.
return function()
	local player=game:GetService("Players").LocalPlayer
	local input=game:GetService("UserInputService"):CreateVirtualInput()
	assert(input,"Native keyboard input is unavailable")
	local remote=game.ReplicatedStorage.CombatRemotes.Skill
	local Run=game:GetService("RunService")
	local Pose=require(game.ReplicatedStorage.Shared.WeaponSkillPose)
	local rig=player.Character
	local shoulder=rig:FindFirstChild("RightShoulder",true) or rig:FindFirstChild("Right Shoulder",true)
	assert(shoulder,"Player skill fixture has no right shoulder")
	local c0,c1=shoulder.C0,shoulder.C1
	local frames,matching=0,0
	local spearFrames,minimumAlignment=0,1
	local response=nil
	local connection=remote.OnClientEvent:Connect(function(value)if not value.visual then response=value end end)
	local animationConnection=Run.PreSimulation:Connect(function()
		local family,elapsed=rig:GetAttribute("WeaponSkillVisualFamily"),rig:GetAttribute("WeaponSkillVisualElapsed")
		if not family or not elapsed then return end
		frames+=1
		local sample=Pose.sample(family,elapsed)
		local basis=shoulder.C0.Rotation
		local expected=basis:Inverse()*CFrame.new(sample.offset)*CFrame.Angles(sample.right.X,sample.right.Y,sample.right.Z)*basis
		local difference=expected:Inverse()*shoulder.Transform
		local _,angle=difference:ToAxisAngle()
		if math.abs(angle)<.25 and difference.Position.Magnitude<.15 then matching+=1 end
	end)
	-- Joint Transforms have reached the actual parts by PostSimulation.
	local alignmentConnection=Run.PostSimulation:Connect(function()
		if rig:GetAttribute("WeaponSkillVisualFamily")~="spear" then return end
		local tool=rig:FindFirstChildOfClass("Tool")
		local handle=tool and tool:FindFirstChild("Handle")
		local root=rig:FindFirstChild("HumanoidRootPart")
		if not handle or not root then return end
		spearFrames+=1
		minimumAlignment=math.min(minimumAlignment,handle.CFrame.UpVector:Dot(root.CFrame.LookVector))
	end)
	local ok,result=pcall(function()
		input:SendKey(true,Enum.KeyCode.R,false);task.wait(.06)
		input:SendKey(false,Enum.KeyCode.R,false)
		local deadline=os.clock()+3
		repeat task.wait(.02)until response or os.clock()>deadline
		assert(response,"R did not produce a server skill response")
		if response.ok then
			task.wait(.5)
			assert(frames>0 and matching>0,"Accepted player skill had no matching visible animation frames")
			assert(rig:GetAttribute("WeaponSkillVisualFamily")==nil,"Player visual outlived its active animation")
			assert(shoulder.C0==c0 and shoulder.C1==c1,"Player skill mutated its rest joints")
			if response.family=="spear" then
				assert(spearFrames>0 and minimumAlignment>=.98,"Player spear did not stay level and forward: "..minimumAlignment)
			end
		end
		local hud=player.PlayerGui:WaitForChild("WeaponSkillHUD",5)
		return {ok=true,accepted=response.ok,reason=response.reason,text=hud.WeaponSkill.Text,animationFrames=frames,matchingFrames=matching,spearFrames=spearFrames,spearAlignment=minimumAlignment}
	end)
	pcall(function()input:SendKey(false,Enum.KeyCode.R,false)end)
	connection:Disconnect();animationConnection:Disconnect();alignmentConnection:Disconnect();assert(ok,result);return result
end
