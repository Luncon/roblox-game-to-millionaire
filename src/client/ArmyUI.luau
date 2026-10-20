--!strict

local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ArmyUI={}

function ArmyUI.start(screen: ScreenGui)
	require(script.Parent.WarCouncilUI).start(screen)
 require(script.Parent.BarracksUI).start(screen)
	local player=Players.LocalPlayer
	local hud=screen:WaitForChild("SettlementHUD") :: Frame
	local panel=Instance.new("Frame")
	-- Leave the default Roblox tool hotbar visible beneath the command panel.
	panel.Name,panel.AnchorPoint,panel.Position="ArmyControls",Vector2.new(.5,1),UDim2.new(.5,0,1,-96)
	panel.Size,panel.BackgroundColor3=UDim2.new(1,-32,0,132),Color3.fromRGB(34,41,40)
	panel.BackgroundTransparency,panel.Parent=.08,screen
	local limit=Instance.new("UISizeConstraint")
	limit.MaxSize,limit.Parent=Vector2.new(450,132),panel
	local title=Instance.new("TextLabel")
	title.Name,title.Size,title.Position="OrderStatus",UDim2.new(1,-16,0,23),UDim2.fromOffset(8,3)
	title.BackgroundTransparency,title.TextColor3,title.Font,title.TextSize=1,Color3.fromRGB(246,231,193),Enum.Font.GothamBold,13
	title.Parent=panel
	local feedback=title:Clone()
	feedback.Name,feedback.Position,feedback.Size,feedback.TextSize="CommandFeedback",UDim2.fromOffset(8,104),UDim2.new(1,-16,0,24),11
	feedback.TextWrapped,feedback.Text,feedback.Parent=true,"",panel
	local buttons={}
	local remote: RemoteFunction?=nil
	local busy=false
	local reasons={formation_locked="Build your formation prerequisites first.",formation_unselected="Select a formation at your War Council map.",
		formation_missing_troops="All five troops must be alive: 3 melee, 1 ranged, 1 medic.",formation_wrong_classes="Select 3 melee, 1 ranged and 1 medic at the Barracks; wait for replacements.",
		formation_outside_camp="Regroup all five troops into the training camp first."}
	local function button(name,text,x,y,width,action,value)
		local b=Instance.new("TextButton")
		b.Name,b.Text,b.Position,b.Size=name,text,UDim2.new(x,6,y,0),UDim2.new(width,-12,0,30)
		b.BackgroundColor3,b.TextColor3=Color3.fromRGB(80,98,77),Color3.fromRGB(255,247,224)
		b.Font,b.TextSize,b.Parent=Enum.Font.GothamBold,12,panel
		buttons[name]=b
		b.Activated:Connect(function()
			if busy or not remote then return end
			busy=true
			local ok,result=pcall(function()return remote:InvokeServer(action,value)end)
			busy=false
			if not ok or not result.ok then
				local definition=require(ReplicatedStorage.Shared.FormationConfig).forCivilization(player:GetAttribute('CivilizationId'))
				local composition=if definition then definition.composition or '3 melee, 1 ranged, 1 medic' else 'the required troops'
				reasons.formation_missing_troops='All five must be alive: '..composition..'.'
				reasons.formation_wrong_classes='Recruit '..composition..' at the Barracks; wait for replacements.'
				feedback.Text=if ok and result.reason=="rate_limited" then "Wait a moment before giving another order."
					else (if ok then reasons[result.reason] else nil) or "Order unavailable. Check your buildings and saved session."
			else feedback.Text=if action=="march" then "Order: formation" else "Order: "..value end
		end)
	end
	button("Advance","Advance",0,.23,1/3,"order","advance")
	button("Hold","Hold",1/3,.23,1/3,"order","hold")
	button("Regroup","Regroup",2/3,.23,1/3,"order","regroup")
	button("MarchFormation","March Formation",0,.4,1,"march",nil)
 local hint=title:Clone();hint.Name="RecruitmentHint";hint.Text="Choose troop numbers at the Barracks";hint.TextSize=12;hint.Parent=panel
	local function layout()
		local size=screen.AbsoluteSize
		local beside=size.Y<500 and size.X>=620
		local compact=size.Y<500 and not beside
		local height=if compact then 128 else 168
		limit.MaxSize=Vector2.new(450,height)
		panel.AnchorPoint=if beside then Vector2.new(1,0) else Vector2.new(.5,1)
		local bottom=if compact then math.max(4,math.min(56,size.Y-hud.AbsolutePosition.Y-hud.AbsoluteSize.Y-8-height)) else 96
		panel.Position=if beside then UDim2.new(1,-16,0,16) else UDim2.new(.5,0,1,-bottom)
		panel.Size=if beside then UDim2.fromOffset(math.min(450,size.X-400),height) else UDim2.new(1,-32,0,height)
		title.Size=UDim2.new(1,-16,0,if compact then 17 else 23)
		feedback.Position=UDim2.fromOffset(8,if compact then 106 else 138)
		feedback.Size=UDim2.new(1,-16,0,if compact then 20 else 28)
  hint.Position=UDim2.fromOffset(8,if compact then 78 else 102)
		for name,b in buttons do
			b.Position=UDim2.new(b.Position.X.Scale,6,0,if name=="MarchFormation" then (if compact then 49 else 66) else (if compact then 20 else 30))
			b.Size=UDim2.new(b.Size.X.Scale,-12,0,if compact then 24 else 30)
			b.TextSize=if beside and size.X<700 then 10 else 12
		end
	end
	local function render()
		local selected=player:GetAttribute("CivilizationId")~=nil
		local trained=(player:GetAttribute("TrainingLevel") or 0)>0
		panel.Visible=selected and hud.Visible and trained
		title.Text="ARMY · "..string.upper(player:GetAttribute("FormationPhase") or player:GetAttribute("ArmyOrder") or "advance")
		local writable=player:GetAttribute("ProgressStatus")=="ready" or player:GetAttribute("ProgressStatus")=="saving"
		for name,b in buttons do
			b.Visible=if name=="MarchFormation" then (player:GetAttribute("WarCouncilLevel") or 0)>0 else trained
			b.Active,b.Selectable=writable,writable
			local highlighted=string.lower(name)==player:GetAttribute("ArmyOrder")
			b.BackgroundColor3=if highlighted then Color3.fromRGB(136,109,51) else Color3.fromRGB(80,98,77)
		end
	end
	for _,attribute in {"CivilizationId","TrainingLevel","ArmyCampLevel","ArmyOrder","ExtraTroopClass","ProgressStatus","WarCouncilLevel","FormationPhase"}do
		player:GetAttributeChangedSignal(attribute):Connect(render)
	end
	hud:GetPropertyChangedSignal("Visible"):Connect(render)
	screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	hud:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	layout()
	render()
	task.spawn(function()
		local folder=ReplicatedStorage:WaitForChild("ArmyRemotes",15)
		remote=if folder then folder:WaitForChild("Request",15) :: RemoteFunction else nil
	end)
end

return ArmyUI
