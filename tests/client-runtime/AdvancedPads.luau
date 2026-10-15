-- Native ground input for persistent tier-four-and-higher pads; no event firing.
return function()
	local Players,Run=game:GetService("Players"),game:GetService("RunService")
	local player=Players.LocalPlayer
	local character=player.Character
	local root,humanoid=character.HumanoidRootPart,character.Humanoid
	local plot=workspace.CivilizationPrototype.Plots["Plot"..player:GetAttribute("PlotId")]
	local controls=plot.Controls
	local weapon,armor,settlement=controls.Weapon4Button,controls.Armor4Button,controls.UpgradeButton
	local camera=workspace.CurrentCamera
	local original={type=camera.CameraType,frame=camera.CFrame,subject=camera.CameraSubject,anchor=root.Anchored}
	local input=game:GetService("UserInputService"):CreateVirtualInput()
	assert(input,"Native advanced pad input is unavailable")
	local binding="AdvancedPadWalk"..player.UserId
	local cases=0
	local down,keyDown=false,false
	local last=Vector2.zero
	local function waitFor(predicate,description)
		local deadline=os.clock()+12
		repeat if predicate() then return end;task.wait(.05) until os.clock()>deadline
		error("Timed out: "..description.." coins="..tostring(player:GetAttribute("Coins")))
	end
	local function walk(point)
		root.Anchored=false
		Run:UnbindFromRenderStep(binding)
		Run:BindToRenderStep(binding,Enum.RenderPriority.Last.Value+1,function()
			local delta=point-root.Position
			local horizontal=Vector3.new(delta.X,0,delta.Z)
			humanoid:Move(if horizontal.Magnitude>1 then horizontal.Unit else Vector3.zero,false)
		end)
		waitFor(function() local d=point-root.Position;return Vector3.new(d.X,0,d.Z).Magnitude<1.2 end,"physical pad movement")
		Run:UnbindFromRenderStep(binding);humanoid:Move(Vector3.zero,false);task.wait(.3)
	end
	-- Pad rows are centered at z14 and z24; z19 fully exits either pad.
	local function forecourt(x) walk(plot.Foundation.CFrame:PointToWorldSpace(Vector3.new(x,5,19))) end
	local function leave(pad)
		local localPoint=plot.Foundation.CFrame:PointToObjectSpace(pad.Position)
		forecourt(localPoint.X);task.wait(.4)
	end
	local function aim(pad)
		camera.CameraType=Enum.CameraType.Scriptable
		camera.CFrame=CFrame.lookAt((pad.CFrame*CFrame.new(0,20,22)).Position,pad.Position)
		task.wait(.2)
	end
	local function click(pad)
		aim(pad)
		local point,visible=camera:WorldToViewportPoint(pad.Position+Vector3.new(0,pad.Size.Y/2,0))
		assert(visible)
		last=Vector2.new(point.X,point.Y)
		input:SendMousePosition(last);input:SendMouseButton(last,Enum.UserInputType.MouseButton1,true,0);down=true
		task.wait(.04)
		input:SendMouseButton(last,Enum.UserInputType.MouseButton1,false,0);down=false
	end
	local ok,result=pcall(function()
		assert(player:GetAttribute("SettlementLevel")==5 and player:GetAttribute("WeaponLevel")==3 and player:GetAttribute("ArmorLevel")==3 and player:GetAttribute("Coins")==1000)
		forecourt(-24);walk(weapon.Position)
		waitFor(function() return player:GetAttribute("WeaponLevel")==4 end,"tier three to four touch")
		task.wait(2)
		assert(player:GetAttribute("WeaponLevel")==4 and player:GetAttribute("Coins")==979,"First repeat-pad entry bought another affordable level while standing")
		assert(controls.Weapon4Button==weapon);cases+=1
		leave(weapon);walk(weapon.Position)
		waitFor(function() return player:GetAttribute("WeaponLevel")==5 end,"repeat-pad exit and reentry")
		assert(player:GetAttribute("Coins")==955 and controls.Weapon4Button==weapon)
		assert(not weapon:FindFirstChildOfClass("ProximityPrompt").Enabled,"Gear cap failed to disable the prompt")
		click(weapon);task.wait(.5)
		assert(player:GetAttribute("Coins")==955 and player:GetAttribute("WeaponLevel")==5);cases+=1
		leave(weapon);forecourt(12);walk(settlement.Position)
		waitFor(function() return player:GetAttribute("SettlementLevel")==6 end,"settlement six")
		leave(settlement);walk(settlement.Position)
		waitFor(function() return player:GetAttribute("SettlementLevel")==7 end,"settlement seven")
		assert(player:GetAttribute("Coins")==815 and controls.Weapon4Button==weapon);cases+=1
		leave(settlement);forecourt(-24);walk(weapon.Position)
		waitFor(function() return player:GetAttribute("WeaponLevel")==6 end,"stable pad buys level six")
		task.wait(2)
		assert(player:GetAttribute("WeaponLevel")==6 and player:GetAttribute("Coins")==788,"Level-six entry bought affordable level seven while standing")
		assert(controls.Weapon4Button==weapon);cases+=1
		leave(weapon);forecourt(33)
		walk(plot.Foundation.CFrame:PointToWorldSpace(Vector3.new(33,5,24)))
		assert(player:GetAttribute("ArmorLevel")==3 and player:GetAttribute("Coins")==788)
		click(armor)
		waitFor(function() return player:GetAttribute("ArmorLevel")==4 end,"repeat armor mouse purchase")
		assert(player:GetAttribute("Coins")==767 and controls.Armor4Button==armor)
		assert(math.abs(humanoid.MaxHealth-(100+40*3/49))<.002);cases+=1
		aim(armor);task.wait(.5)
		input:SendKey(true,Enum.KeyCode.E,false);keyDown=true;task.wait(.1)
		input:SendKey(false,Enum.KeyCode.E,false);keyDown=false
		waitFor(function() return player:GetAttribute("ArmorLevel")==5 end,"repeat armor proximity purchase")
		assert(player:GetAttribute("Coins")==743 and controls.Armor4Button==armor)
		assert(math.abs(humanoid.MaxHealth-(100+40*4/49))<.002);cases+=1
		return {ok=true,cases=cases,coins=743,level=7,weaponLevel=6,armorLevel=5,
			message="Actual repeated high-tier pad identity, touch-entry latches, cap lock, continued upgrades, fractional armor and mouse/prompt purchases passed"}
	end)
	Run:UnbindFromRenderStep(binding);humanoid:Move(Vector3.zero,false)
	if down then pcall(function() input:SendMouseButton(last,Enum.UserInputType.MouseButton1,false,0) end) end
	if keyDown then pcall(function() input:SendKey(false,Enum.KeyCode.E,false) end) end
	root.Anchored=original.anchor
	camera.CameraType,camera.CFrame,camera.CameraSubject=original.type,original.frame,original.subject
	assert(ok,result)
	return result
end
