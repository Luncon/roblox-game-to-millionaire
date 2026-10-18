-- Native engine keyboard/mouse input only; no production signals are forged.
return function(options)
	options=options or {}
	local Players,Run=game:GetService("Players"),game:GetService("RunService")
	local player=Players.LocalPlayer
	local char=player.Character;local root=char and char:FindFirstChild("HumanoidRootPart")
	local hum=char and char:FindFirstChildOfClass("Humanoid")
	assert(root and hum and hum.Health>0)
	local input=game:GetService("UserInputService"):CreateVirtualInput()
	assert(input,"Native development input is unavailable")
	local camera=workspace.CurrentCamera
	local original={type=camera.CameraType,frame=camera.CFrame,subject=camera.CameraSubject}
	local binding="NativeDevelopmentWalk"..player.UserId
	local down,keyDown=false,false;local last=Vector2.zero
	local response=nil;local connection=nil
	local promptConnections={}
	local function waitFor(predicate,description,seconds)
		local deadline=os.clock()+(seconds or 12)
		repeat if predicate() then return end;task.wait(.03) until os.clock()>deadline
		error("Timed out: "..description.." position="..tostring(root.Position).." mouse="..tostring(player:GetMouse().Target))
	end
	local function click(position)
		last=position;input:SendMousePosition(last);input:SendMouseButton(last,Enum.UserInputType.MouseButton1,true,0);down=true
		task.wait(.06);input:SendMouseButton(last,Enum.UserInputType.MouseButton1,false,0);down=false
	end
	local function walk(point)
		Run:UnbindFromRenderStep(binding)
		Run:BindToRenderStep(binding,Enum.RenderPriority.Last.Value+1,function()
			local d=point-root.Position;local flat=Vector3.new(d.X,0,d.Z)
			hum:Move(if flat.Magnitude>1 then flat.Unit else Vector3.zero,false)
		end)
		waitFor(function() local d=point-root.Position;return Vector3.new(d.X,0,d.Z).Magnitude<1.2 end,"physical tier-pad entry",15)
		Run:UnbindFromRenderStep(binding);hum:Move(Vector3.zero,false);task.wait(.3)
	end
	local function walkToPad(pad,distance)
		distance=distance or 7
		local frame=pad.Parent.Parent.Foundation.CFrame
		local start=frame:PointToObjectSpace(root.Position)
		-- Only the measured inter-rural route needs collection-zone avoidance.
		-- Normal plot spawns can begin above a main-hall pad's XZ bounds.
		local guardRuralPads=start.Z< -100 and frame:PointToObjectSpace(pad.Position).Z< -100
		local function crossesPad(a,b,other)
			a,b=other.CFrame:PointToObjectSpace(a),other.CFrame:PointToObjectSpace(b)
			local first,last=0,1
			-- Include avatar width and waypoint stopping tolerance, not just its root.
			for _,axis in {"X","Z"} do
				local half=other.Size[axis]/2+3.5
				local delta=b[axis]-a[axis]
				if math.abs(delta)<.00001 then
					if math.abs(a[axis])>half then return false end
				else
					local low,high=(-half-a[axis])/delta,(half-a[axis])/delta
					if low>high then low,high=high,low end
					first,last=math.max(first,low),math.min(last,high)
					if first>last then return false end
				end
			end
			return true
		end
		local candidates={}
		local plot=pad.Parent.Parent
		local standing=OverlapParams.new()
		standing.FilterType=Enum.RaycastFilterType.Include;standing.RespectCanCollide=true
		standing.FilterDescendantsInstances={plot.Settlement,plot.Infrastructure}
		for _,offset in {Vector3.new(-distance,3,0),Vector3.new(distance,3,0),Vector3.new(0,3,-distance),Vector3.new(0,3,distance)} do
			local point=pad.CFrame:PointToWorldSpace(offset)
			local clear=#workspace:GetPartBoundsInBox(pad.CFrame*CFrame.new(offset+Vector3.new(0,.5,0)),Vector3.new(6,6,4),standing)==0
			for _,other in pad.Parent:GetChildren() do
				if other~=pad and other:IsA("BasePart") then
					local localPoint=other.CFrame:PointToObjectSpace(point)
					if math.abs(localPoint.X)<other.Size.X/2+3.5 and math.abs(localPoint.Z)<other.Size.Z/2+3.5 then clear=false end
				end
			end
			if clear then table.insert(candidates,point) end
		end
		table.sort(candidates,function(a,b) return (a-root.Position).Magnitude<(b-root.Position).Magnitude end)
		local waypoints=nil
		local selectedGoal=nil
		local blockedBy=nil
		local function route(points)
			local cursor=root.Position;local result={}
			for _,point in points do
				local path=game:GetService("PathfindingService"):CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=false,WaypointSpacing=5})
				local success=pcall(function() path:ComputeAsync(cursor,point) end)
				if not success or path.Status~=Enum.PathStatus.Success then return nil end
				for _,waypoint in path:GetWaypoints() do
					for _,other in pad.Parent:GetChildren() do
						if guardRuralPads and other~=pad and other:IsA("BasePart") and crossesPad(cursor,waypoint.Position,other) then
							blockedBy=other.Name;return nil
						end
					end
					table.insert(result,waypoint);cursor=waypoint.Position
				end
			end
			return result
		end
		for _,point in candidates do waypoints=route({point});if waypoints then selectedGoal=point;break end end
		if not waypoints and guardRuralPads then
			for _,point in candidates do
				local goal=frame:PointToObjectSpace(point)
				if start.Z< -100 or goal.Z< -100 then
					-- Cross the rural aisle before approaching a field. The direct
					-- farm-to-workers diagonal crosses the real collection button.
					waypoints=route({frame:PointToWorldSpace(Vector3.new(start.X,5,-128)),
						frame:PointToWorldSpace(Vector3.new(goal.X,5,-128)),point})
					if waypoints then selectedGoal=point;break end
				end
			end
		end
		assert(waypoints,"No pad-safe actual player route to "..pad.Name.."; blocked by "..tostring(blockedBy))
		for _,waypoint in waypoints do
			if waypoint.Action==Enum.PathWaypointAction.Jump then hum.Jump=true end
			Run:UnbindFromRenderStep(binding)
			Run:BindToRenderStep(binding,Enum.RenderPriority.Last.Value+1,function()
				local delta=waypoint.Position-root.Position;local flat=Vector3.new(delta.X,0,delta.Z)
				hum:Move(if flat.Magnitude>1 then flat.Unit else Vector3.zero,false)
			end)
			waitFor(function()
				assert(hum.Health>0,"Player died during native pad navigation")
				local delta=waypoint.Position-root.Position;return Vector3.new(delta.X,0,delta.Z).Magnitude<1.4
			end,"real waypoint toward "..pad.Name.." target="..tostring(waypoint.Position).." candidate="..tostring(selectedGoal),10)
		end
		Run:UnbindFromRenderStep(binding);hum:Move(Vector3.zero,false)
		task.wait(.3)
		if distance==7 then assert((root.Position-pad.Position).Magnitude<10,"Native player remained outside the prompt range")
		else assert((root.Position-pad.Position).Magnitude>10,"Native player did not physically exit the prompt range") end
	end
	local function ui()
		return player.PlayerGui:WaitForChild("CivilizationSelection",10):WaitForChild("ArmyControls",10)
	end
	local ok,result=pcall(function()
		if options.kind=="inspect" then
			local panel=ui();return {ok=true,panelVisible=panel.Visible,training=player:GetAttribute("TrainingLevel"),camp=player:GetAttribute("ArmyCampLevel"),
				armyText=panel.Parent.SettlementHUD.ArmyStatus.Text,campCount=player:GetAttribute("CampCount"),warriorDeadline=player:GetAttribute("WarriorRespawnAt")}
		elseif options.kind=="tierLatch" then
			assert(player:GetAttribute("SettlementLevel")==5 and player:GetAttribute("WeaponLevel")==1)
			local plot=workspace.CivilizationPrototype.Plots["Plot"..player:GetAttribute("PlotId")]
			local old=plot.Controls.WeaponButton;local frame=old.CFrame
			local coins=player:GetAttribute("Coins")
			walk(plot.Foundation.CFrame:PointToWorldSpace(Vector3.new(18,5,33)))
			walk(frame.Position)
			waitFor(function() return player:GetAttribute("WeaponLevel")==2 end,"first early-tier touch purchase")
			task.wait(1.5)
			assert(player:GetAttribute("WeaponLevel")==2 and player:GetAttribute("Coins")==coins-15,
				"Replacing a purchased tier pad charged another tier while the same character stood on it")
			assert(old.Parent==nil and plot.Controls:FindFirstChild("Weapon3Button"),"Expected a real tier-pad replacement")
			walk(frame:PointToWorldSpace(Vector3.new(0,3,10)));task.wait(.4)
			walk(frame.Position)
			waitFor(function() return player:GetAttribute("WeaponLevel")==3 end,"full exit and next-tier reentry")
			task.wait(1.5)
			assert(player:GetAttribute("WeaponLevel")==3 and player:GetAttribute("Coins")==coins-33)
			walk(frame:PointToWorldSpace(Vector3.new(0,3,10)))
			return {ok=true,cases=1,coins=player:GetAttribute("Coins"),weaponLevel=3,standingSeconds=1.5}
		elseif options.kind=="command" then
			local allowed={Advance="advance",Hold="hold",Regroup="regroup",CampWarrior="warrior",CampRanged="ranged",MarchFormation="formation"}
			assert(allowed[options.button],"Unknown native commander button")
			local panel=ui();local button=panel:WaitForChild(options.button,10)
			waitFor(function() return panel.Visible and button.Visible and button.Active end,"unlocked commander "..options.button)
			task.wait(.4)
			local screen=panel:FindFirstAncestorOfClass("ScreenGui")
			local inset=game:GetService("GuiService"):GetGuiInset()
			click(button.AbsolutePosition+button.AbsoluteSize/2+(if screen.IgnoreGuiInset then Vector2.zero else inset))
			local field=if string.sub(options.button,1,4)=="Camp" then "ExtraTroopClass" else "ArmyOrder"
			local feedback=panel:WaitForChild("CommandFeedback",10)
			local expected=if field=="ArmyOrder" then "Order: "..allowed[options.button] else "Camp class changes on its next respawn."
			waitFor(function() return player:GetAttribute(field)==allowed[options.button] and feedback.Text==expected end,"native commander result")
			return {ok=true,cases=1,button=options.button,order=player:GetAttribute("ArmyOrder"),choice=player:GetAttribute("ExtraTroopClass")}
		else
			assert(options.kind=="pad" and type(options.action)=="string")
			local plot=workspace.CivilizationPrototype.Plots["Plot"..player:GetAttribute("PlotId")]
			local pad=nil
			for _,item in plot.Controls:GetChildren() do if item:GetAttribute("Action")==options.action then pad=item end end
			assert(pad and pad:IsA("BasePart"),"Requested development pad is absent: "..options.action)
			local definition=require(game.ReplicatedStorage.Shared.PadCatalog).byAction[options.action]
			local responseAction=if options.action=="upgrade" then "upgrade" else definition.track
			local movementBefore={coins=player:GetAttribute("Coins"),reserve=player:GetAttribute("FarmCoins")}
			local movementEvents={};local interacting=false
			connection=game.ReplicatedStorage.EconomyRemotes.State.OnClientEvent:Connect(function(value)
				if value.action~="farmIncome" then
					local position=plot.Foundation.CFrame:PointToObjectSpace(root.Position)
					table.insert(movementEvents,{action=value.action,ok=value.ok,amount=value.amount,coins=value.state and value.state.coins,
						reserve=value.state and value.state.farmCoins,x=position.X,z=position.Z})
				end
				if value.action==responseAction and (value.ok or interacting) and not response then response=value end
			end)
			local prompt=pad:FindFirstChildOfClass("ProximityPrompt")
			assert(prompt and prompt.Enabled,"Requested pad has no enabled interaction prompt")
			local before={coins=player:GetAttribute("Coins"),reserve=player:GetAttribute("FarmCoins"),
				label=pad:FindFirstChildOfClass("SurfaceGui"):FindFirstChildOfClass("TextLabel").Text,prompt=prompt.ActionText}
			local shown=false
			local prompts=game:GetService("ProximityPromptService")
			table.insert(promptConnections,prompts.PromptShown:Connect(function(item) if item==prompt then shown=true end end))
			table.insert(promptConnections,prompts.PromptHidden:Connect(function(item) if item==prompt then shown=false end end))
			-- A replacement tier may already have shown its prompt before this
			-- helper subscribed. Physically leave/reenter to observe a fresh show.
			if (root.Position-pad.Position).Magnitude<10 then walkToPad(pad,16) end
			if not response then walkToPad(pad) end
			if not response then
				camera.CameraType=Enum.CameraType.Scriptable
				-- Prompt sightlines come from the standing player's eye.
				camera.CFrame=CFrame.lookAt(root.Position+Vector3.new(0,2.5,0),pad.Position)
				task.wait(.2)
				local projected,visible=camera:WorldToViewportPoint(pad.Position+Vector3.new(0,pad.Size.Y/2,0))
				assert(visible)
				waitFor(function() return shown or response~=nil end,"visible native "..options.action.." proximity prompt or touch purchase")
			end
			-- Walking can legitimately purchase a pad through its native Touched
			-- handler. Observe that response before waiting on a destroyed prompt.
			local interaction=if response then "touch" else "prompt"
			if not response then
				before.coins,before.reserve=player:GetAttribute("Coins"),player:GetAttribute("FarmCoins")
				-- Equipped Tools consume native M1 before ClickDetector. E preserves
				-- the weapon while using the normal ground interaction path.
				interacting=true
				input:SendKey(true,Enum.KeyCode.E,false);keyDown=true;task.wait(.1)
				input:SendKey(false,Enum.KeyCode.E,false);keyDown=false
			end
			waitFor(function() return response~=nil end,"actual "..options.action.." pad response")
			assert(response.ok,"Physical purchase rejected: "..tostring(response.reason))
			return {ok=true,cases=1,action=options.action,event=response,before=before,movementBefore=movementBefore,
				movementEvents=movementEvents,interaction=interaction,distance=(root.Position-pad.Position).Magnitude}
		end
	end)
	Run:UnbindFromRenderStep(binding);hum:Move(Vector3.zero,false)
	if connection then connection:Disconnect() end
	for _,item in promptConnections do item:Disconnect() end
	if down then pcall(function()input:SendMouseButton(last,Enum.UserInputType.MouseButton1,false,0)end) end
	if keyDown then pcall(function()input:SendKey(false,Enum.KeyCode.E,false)end) end
	camera.CameraType,camera.CFrame,camera.CameraSubject=original.type,original.frame,original.subject
	assert(ok,result)
	return result
end
