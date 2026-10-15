--!strict

local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ArmyUI={}

function ArmyUI.start(screen: ScreenGui)
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
				feedback.Text=if ok and result.reason=="rate_limited" then "Wait a moment before giving another order."
					else "Order unavailable. Check your buildings and saved session."
			else feedback.Text=if action=="class" then "Camp class changes on its next respawn." else "Order: "..value end
		end)
	end
	button("Advance","Advance",0,.23,1/3,"order","advance")
	button("Hold","Hold",1/3,.23,1/3,"order","hold")
	button("Regroup","Regroup",2/3,.23,1/3,"order","regroup")
	button("CampWarrior","Camp: Melee",0,.55,.5,"class","warrior")
	button("CampRanged","Camp: Ranged",.5,.55,.5,"class","ranged")
	local function render()
		local selected=player:GetAttribute("CivilizationId")~=nil
		local trained=(player:GetAttribute("TrainingLevel") or 0)>0
		local camp=(player:GetAttribute("ArmyCampLevel") or 0)>0
		panel.Visible=selected and hud.Visible and (trained or camp)
		title.Text="ARMY · "..string.upper(player:GetAttribute("ArmyOrder") or "advance")
		local writable=player:GetAttribute("ProgressStatus")=="ready" or player:GetAttribute("ProgressStatus")=="saving"
		for name,b in buttons do
			local isClass=name=="CampWarrior" or name=="CampRanged"
			b.Visible=if isClass then camp else trained
			b.Active,b.Selectable=writable,writable
			local selectedClass=player:GetAttribute("ExtraTroopClass") or "warrior"
			local highlighted=(name=="CampWarrior" and selectedClass=="warrior") or (name=="CampRanged" and selectedClass=="ranged")
				or (not isClass and string.lower(name)==player:GetAttribute("ArmyOrder"))
			b.BackgroundColor3=if highlighted then Color3.fromRGB(136,109,51) else Color3.fromRGB(80,98,77)
		end
	end
	for _,attribute in {"CivilizationId","TrainingLevel","ArmyCampLevel","ArmyOrder","ExtraTroopClass","ProgressStatus"}do
		player:GetAttributeChangedSignal(attribute):Connect(render)
	end
	hud:GetPropertyChangedSignal("Visible"):Connect(render)
	render()
	task.spawn(function()
		local folder=ReplicatedStorage:WaitForChild("ArmyRemotes",15)
		remote=if folder then folder:WaitForChild("Request",15) :: RemoteFunction else nil
	end)
end

return ArmyUI
