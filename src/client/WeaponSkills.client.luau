--!strict

local Players=game:GetService("Players")
local Replicated=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local Context=game:GetService("ContextActionService")
local Shared=Replicated:WaitForChild("Shared")
local Config=require(Shared:WaitForChild("WeaponSkillConfig"))
local Animation=require(Shared:WaitForChild("WeaponSkillAnimation"))
local Playback=require(Shared:WaitForChild("WeaponSkillPlayback"))
local player=Players.LocalPlayer
local remotes=Replicated:WaitForChild("CombatRemotes")
local remote=remotes:WaitForChild("Skill")
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
local function layout()
	local size=gui.AbsoluteSize
	local beside=size.Y<500 and size.X>=620
	local narrow=size.X<900
	if beside or narrow then
		local width=if beside then 180 elseif size.X>=500 then math.min(180,size.X-400) else 180
		local y=if beside then 152 elseif size.X>=500 then 16 else 222
		button.AnchorPoint=Vector2.new(1,0)
		button.Position,button.Size=UDim2.new(1,-16,0,y),UDim2.fromOffset(width,if beside then 44 else 58)
		button.TextSize=if width<180 then 10 else 12
		feedback.Position,feedback.Size=UDim2.new(1,-width-16,0,y+button.Size.Y.Offset+4),UDim2.fromOffset(width,24)
	else
		button.AnchorPoint=Vector2.new(1,.5)
		button.Position,button.Size=UDim2.new(1,-20,.52,0),UDim2.fromOffset(180,58)
		button.TextSize=13
		feedback.Position,feedback.Size=UDim2.new(1,-230,.52,36),UDim2.fromOffset(210,44)
	end
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
layout()
local feedbackUntil,lastRequest=0,-math.huge
local playback=Playback.new()
local acceptedReadyAt={}
local function activate()
	if game:GetService("UserInputService"):GetFocusedTextBox() then return end
	if os.clock()-lastRequest<.15 then return end
	local rig=player.Character
	local now=workspace:GetServerTimeNow()
	if rig and playback:pending(rig,now) then return end
	lastRequest=os.clock()
	local hum=rig and rig:FindFirstChildOfClass("Humanoid")
	local tool=rig and rig:FindFirstChildOfClass("Tool")
	local family=if tool and tool:GetAttribute("GeneratedBy")=="CivilizationEquipment" then Config.family(tool:GetAttribute("WeaponKind")) else nil
	local tier=player:GetAttribute("SkillLevel") or 0
	local status=player:GetAttribute("ProgressStatus")
	local readyAt=math.max(acceptedReadyAt[family] or 0,if rig then rig:GetAttribute("WeaponSkillReadyAt") or 0 else 0)
	if family and hum and hum.Health>0 and tier>0 and (status=="ready" or status=="saving") and now>=readyAt then
		playback:predict(rig,family,now)
	end
	remote:FireServer()
end
button.Activated:Connect(activate)
Context:BindAction("CivilizationWeaponSkill",function(_,state)
	if game:GetService("UserInputService"):GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
	if state==Enum.UserInputState.Begin then activate() end
	return Enum.ContextActionResult.Sink
end,false,Enum.KeyCode.R,Enum.KeyCode.ButtonY)
remote.OnClientEvent:Connect(function(result)
	if result.visual then
		playback:accept(result,workspace:GetServerTimeNow())
		if result.rig==player.Character then acceptedReadyAt[result.family]=math.max(acceptedReadyAt[result.family] or 0,result.readyAt or 0) end
		return
	end
	if result.ok then
		feedback.Text=""
		playback:accept(result,workspace:GetServerTimeNow())
		acceptedReadyAt[result.family]=math.max(acceptedReadyAt[result.family] or 0,result.readyAt or 0)
	else
		if player.Character then playback:reject(player.Character) end
		feedback.Text=({skill_locked="Buy this skill beside the training camp.",cooldown="Skill is recharging.",busy="Finish the current attack first.",
			protected="Skills work inside the battlefield.",not_equipped="Equip a spear, axe or sword first.",not_alive="Your fighter is not ready.",
			rate_limited="Wait a moment."})[result.reason] or "Skill unavailable. Check your saved session."
	end
	feedbackUntil=os.clock()+2.5
end)

-- Render input prediction immediately, then reconcile the reliable server start.
-- These local diagnostics describe rendered poses; combat never reads them.
local animation=Animation.new()
local visualRigs={}
Run.PreSimulation:Connect(function()
	local performances=playback:performances(Players:GetPlayers(),workspace:GetServerTimeNow())
	local active={}
	animation:step(performances)
	for _,performance in performances do
		local rig=performance.rig
		active[rig]=true
		rig:SetAttribute("WeaponSkillVisualFamily",performance.family)
		rig:SetAttribute("WeaponSkillVisualElapsed",performance.elapsed)
	end
	for rig in visualRigs do
		if not active[rig] then
			rig:SetAttribute("WeaponSkillVisualFamily",nil)
			rig:SetAttribute("WeaponSkillVisualElapsed",nil)
		end
	end
	visualRigs=active
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
