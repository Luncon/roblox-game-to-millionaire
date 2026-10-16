--!strict

local Players=game:GetService("Players")
local Replicated=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local Context=game:GetService("ContextActionService")
local Config=require(Replicated.Shared.WeaponSkillConfig)
local Pose=require(Replicated.Shared.WeaponSkillPose)
local player=Players.LocalPlayer
local remotes=Replicated:WaitForChild("CombatRemotes",20)
local remote=if remotes then remotes:WaitForChild("Skill",10) else nil
if not remote or not remote:IsA("RemoteEvent") then return end

local gui=Instance.new("ScreenGui")
gui.Name,gui.ResetOnSpawn,gui.Parent="WeaponSkillHUD",false,player:WaitForChild("PlayerGui")
local button=Instance.new("TextButton")
button.Name,button.AnchorPoint="WeaponSkill",Vector2.new(1,.5)
button.Position,button.Size=UDim2.new(1,-20,.52,0),UDim2.fromOffset(180,58)
button.BackgroundColor3,button.TextColor3=Color3.fromRGB(58,72,68),Color3.fromRGB(255,240,204)
button.Font,button.TextSize,button.TextWrapped=Enum.Font.GothamBold,13,true
button.Parent=gui
local feedback=Instance.new("TextLabel")
feedback.Position,feedback.Size=UDim2.new(1,-230,.52,36),UDim2.fromOffset(210,44)
feedback.BackgroundTransparency,feedback.TextColor3,feedback.TextSize=1,Color3.fromRGB(255,220,150),12
feedback.TextWrapped,feedback.Text,feedback.Parent=true,"",gui
local feedbackUntil,lastRequest=0,-math.huge
local function activate()
	if game:GetService("UserInputService"):GetFocusedTextBox() then return end
	if os.clock()-lastRequest<.15 then return end
	lastRequest=os.clock()
	remote:FireServer()
end
button.Activated:Connect(activate)
Context:BindAction("CivilizationWeaponSkill",function(_,state)
	if game:GetService("UserInputService"):GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
	if state==Enum.UserInputState.Begin then activate() end
	return Enum.ContextActionResult.Sink
end,false,Enum.KeyCode.R,Enum.KeyCode.ButtonY)
remote.OnClientEvent:Connect(function(result)
	if result.ok then feedback.Text=""
	else
		feedback.Text=({skill_locked="Buy this skill beside the training camp.",cooldown="Skill is recharging.",busy="Finish the current attack first.",
			protected="Skills work inside the battlefield.",not_equipped="Equip a spear, axe or sword first.",not_alive="Your fighter is not ready.",
			rate_limited="Wait a moment."})[result.reason] or "Skill unavailable. Check your saved session."
	end
	feedbackUntil=os.clock()+2.5
end)

-- Animate player R6/R15 joints locally for every observing client. NPC R6 poses
-- remain on the existing server animation path. Preserve concurrent external C0 edits.
local joints={}
local function restore(motor,record)
	if motor.Parent and motor.C0==record.applied then motor.C0=record.base end
end
Run.PreSimulation:Connect(function()
	local active={}
	for _,owner in Players:GetPlayers() do
		local rig=owner.Character
		local family=rig and rig:GetAttribute("WeaponSkillActive")
		local started=rig and rig:GetAttribute("WeaponSkillStartedAt")
		if not family or not started then continue end
		local sample=Pose.sample(family,workspace:GetServerTimeNow()-started)
		for _,motor in rig:GetDescendants() do
			if not motor:IsA("Motor6D") then continue end
			local angles,offset
			if motor.Name=="RightShoulder" or motor.Name=="Right Shoulder" then angles,offset=sample.right,sample.offset
			elseif motor.Name=="LeftShoulder" or motor.Name=="Left Shoulder" then angles,offset=sample.left,Vector3.zero
			elseif motor.Name=="Root" or motor.Name=="RootJoint" then angles,offset=Vector3.new(sample.lean,sample.twist,0),Vector3.zero
			elseif motor.Name=="Waist" then angles,offset=Vector3.new(sample.lean*.5,0,0),Vector3.zero end
			if not angles then continue end
			active[motor]=true
			local record=joints[motor]
			if not record then record={base=motor.C0};joints[motor]=record
			elseif motor.C0~=record.applied then record.base=motor.C0 end
			local base=record.base
			record.applied=CFrame.new(base.Position+offset)*CFrame.Angles(angles.X,angles.Y,angles.Z)*(base-base.Position)
			motor.C0=record.applied
		end
	end
	for motor,record in joints do if not active[motor] then restore(motor,record);joints[motor]=nil end end
end)
local elapsed=0
Run.Heartbeat:Connect(function(dt)
	elapsed+=dt;if elapsed<.1 then return end;elapsed=0
	local rig=player.Character
	local tool=rig and rig:FindFirstChildOfClass("Tool")
	local family=if tool and tool:GetAttribute("GeneratedBy")=="CivilizationEquipment" then Config.family(tool:GetAttribute("WeaponKind")) else nil
	button.Visible=player:GetAttribute("CivilizationId")~=nil
	feedback.Visible=button.Visible
	local tier=player:GetAttribute("SkillLevel") or 0
	local readyAt=if rig then rig:GetAttribute("WeaponSkillReadyAt") or 0 else 0
	local remaining=math.max(0,readyAt-workspace:GetServerTimeNow())
	local name=if family then Config.families[family].name else "Weapon skill"
	local writable=player:GetAttribute("ProgressStatus")=="ready" or player:GetAttribute("ProgressStatus")=="saving"
	button.Text="R / Y · "..name.."\n"..(if not family then "Equip spear / axe / sword" elseif tier==0 then "Unlock at weapon 10 · Training Camp"
		elseif not writable then "Progress unavailable" elseif remaining>0 then string.format("Tier %s · %.1fs",Config.tiers[tier].name,remaining) else "Tier "..Config.tiers[tier].name.." · Ready")
	button.BackgroundColor3=if family and tier>0 and writable and remaining==0 then Color3.fromRGB(72,125,79) else Color3.fromRGB(58,72,68)
	if os.clock()>feedbackUntil then feedback.Text="" end
end)
