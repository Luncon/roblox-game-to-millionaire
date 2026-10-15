-- Native ground input for available tier-four-and-higher pads; no event firing.
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
	local function exitPoint(pad)
		-- Leave each logical input zone by ten studs. The main-hall pad exits
		-- toward the central aisle rather than walking into the armory pads.
		local offset=if pad:GetAttribute("Action")=="upgrade" then Vector3.new(-10,3,0) else Vector3.new(0,3,10)
		return pad.CFrame:PointToWorldSpace(offset)
	end
	local function leave(pad)
		local action=pad:GetAttribute("Action")
		if type(action)=="string" and action:sub(1,6)=="weapon" then
			-- Approach the outer armory aisle before crossing toward the pad;
			-- a direct diagonal from the main hall can brush its upgrade zone.
			walk(pad.CFrame:PointToWorldSpace(Vector3.new(-8,3,10)))
		end
		walk(exitPoint(pad));task.wait(.4)
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
		leave(weapon);walk(weapon.Position)
		waitFor(function() return player:GetAttribute("WeaponLevel")==4 end,"tier three to four touch")
		task.wait(2)
		assert(player:GetAttribute("WeaponLevel")==4 and player:GetAttribute("Coins")==979,"First repeat-pad entry bought another affordable level while standing")
		assert(controls.Weapon4Button==weapon);cases+=1
		leave(weapon);walk(weapon.Position)
		waitFor(function() return player:GetAttribute("WeaponLevel")==5 end,"repeat-pad exit and reentry")
		assert(player:GetAttribute("Coins")==955)
		waitFor(function() return weapon.Parent==nil and not controls:FindFirstChild("Weapon4Button") end,"settlement-capped pad removal")
		assert(weapon.Parent==nil and not controls:FindFirstChild("Weapon4Button"),"Settlement-capped gear pad should be absent")
		humanoid:UnequipTools()
		click(weapon);task.wait(.5)
		assert(player:GetAttribute("Coins")==955 and player:GetAttribute("WeaponLevel")==5);cases+=1
		local retiredWeapon=weapon
		leave(weapon);leave(settlement);walk(settlement.Position)
		waitFor(function() return player:GetAttribute("SettlementLevel")==6 end,"settlement six")
		waitFor(function() return controls:FindFirstChild("Weapon4Button")~=nil end,"newly available weapon pad")
		weapon=controls.Weapon4Button
		assert(weapon~=retiredWeapon,"Unlocking the next gear tier should create a fresh available pad")
		local definition=require(game.ReplicatedStorage.Shared.PadCatalog).byAction.weapon4
		local expected=plot.Foundation.CFrame*CFrame.new(definition.x,definition.y or 2,definition.z)
		assert((weapon.Position-expected.Position).Magnitude<.01,"Available pad did not use the current armory position")
		leave(settlement);walk(settlement.Position)
		waitFor(function() return player:GetAttribute("SettlementLevel")==7 end,"settlement seven")
		assert(player:GetAttribute("Coins")==815 and controls.Weapon4Button==weapon);cases+=1
		leave(settlement);leave(weapon);walk(weapon.Position)
		waitFor(function() return player:GetAttribute("WeaponLevel")==6 end,"stable pad buys level six")
		task.wait(2)
		assert(player:GetAttribute("WeaponLevel")==6 and player:GetAttribute("Coins")==788,"Level-six entry bought affordable level seven while standing")
		assert(controls.Weapon4Button==weapon);cases+=1
		leave(weapon)
		walk(armor.CFrame:PointToWorldSpace(Vector3.new(0,3,8)))
		assert(player:GetAttribute("ArmorLevel")==3 and player:GetAttribute("Coins")==788)
		-- Native Tool activation takes priority over ClickDetector mouse input.
		-- Unequip for the mouse case; the resulting gear refresh equips a new tool.
		humanoid:UnequipTools()
		click(armor)
		waitFor(function() return player:GetAttribute("ArmorLevel")==4 end,"repeat armor mouse purchase")
		assert(player:GetAttribute("Coins")==767 and controls.Armor4Button==armor)
		assert(math.abs(humanoid.MaxHealth-(100+40*3/49))<.002);cases+=1
		waitFor(function() return character:FindFirstChildOfClass("Tool")~=nil end,"equipped tool before native proximity input")
		aim(armor);task.wait(.5)
		input:SendKey(true,Enum.KeyCode.E,false);keyDown=true;task.wait(.1)
		input:SendKey(false,Enum.KeyCode.E,false);keyDown=false
		waitFor(function() return player:GetAttribute("ArmorLevel")==5 end,"repeat armor proximity purchase")
		assert(player:GetAttribute("Coins")==743 and controls.Armor4Button==armor)
		assert(math.abs(humanoid.MaxHealth-(100+40*4/49))<.002);cases+=1
		return {ok=true,cases=cases,coins=743,level=7,weaponLevel=6,armorLevel=5,
			message="Available high-tier pad identity, touch-entry latches, hidden cap/renewed pad, continued upgrades, fractional armor and native mouse/armed-prompt purchases passed"}
	end)
	Run:UnbindFromRenderStep(binding);humanoid:Move(Vector3.zero,false)
	if down then pcall(function() input:SendMouseButton(last,Enum.UserInputType.MouseButton1,false,0) end) end
	if keyDown then pcall(function() input:SendKey(false,Enum.KeyCode.E,false) end) end
	root.Anchored=original.anchor
	camera.CameraType,camera.CFrame,camera.CameraSubject=original.type,original.frame,original.subject
	assert(ok,result)
	return result
end
