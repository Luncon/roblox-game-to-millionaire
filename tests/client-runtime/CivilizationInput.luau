-- Actual GUI input against the normal selector. No signals or Tools are fired.
return function(options)
	options=options or {action="open"}
	local player=game:GetService("Players").LocalPlayer
	local RunService=game:GetService("RunService")
	local input=game:GetService("UserInputService"):CreateVirtualInput()
	assert(input,"VirtualInput is unavailable; native civilization input was not tested")
	local screen=player.PlayerGui:WaitForChild("CivilizationSelection",10)
	local panel=screen:WaitForChild("SelectionPanel",10)
	local content=panel:WaitForChild("Content",10)
	local hud=screen:WaitForChild("SettlementHUD",10)
	local mouseDown=false
	local performed=0
	local lastPosition=Vector2.zero
	local function waitFor(predicate,description)
		local deadline=os.clock()+10
		repeat if predicate() then return end; task.wait(.05) until os.clock()>deadline
		error("Timed out: "..description)
	end
	local function scrollTo(button)
		local relative=button.AbsolutePosition.Y-content.AbsolutePosition.Y+content.CanvasPosition.Y
		local wanted=relative-(content.AbsoluteSize.Y-button.AbsoluteSize.Y)/2
		content.CanvasPosition=Vector2.new(0,math.clamp(wanted,0,math.max(0,content.AbsoluteCanvasSize.Y-content.AbsoluteSize.Y)))
		RunService.RenderStepped:Wait()
		RunService.RenderStepped:Wait()
	end
	local function click(button,scroll)
		waitFor(function() return button.Visible and button.Active end,"active "..button.Name)
		if scroll then scrollTo(button) end
		local inset=game:GetService("GuiService"):GetGuiInset()
		lastPosition=button.AbsolutePosition+button.AbsoluteSize/2+(if screen.IgnoreGuiInset then Vector2.zero else inset)
		input:SendMousePosition(lastPosition)
		input:SendMouseButton(lastPosition,Enum.UserInputType.MouseButton1,true,0)
		mouseDown=true
		task.wait(.05)
		input:SendMouseButton(lastPosition,Enum.UserInputType.MouseButton1,false,0)
		mouseDown=false
		performed+=1
	end
	local function open()
		if panel.Visible then return end
		click(hud:WaitForChild("SwitchCivilization",10),false)
		waitFor(function() return panel.Visible and not hud.Visible end,"native switch opens selector")
		waitFor(function() return content.Refresh.Active end,"saved previews finish loading")
	end
	local ok,result=pcall(function()
		local action=options.action or "open"
		if action=="open" then open()
		elseif action=="cancel" then
			open(); click(content:WaitForChild("Cancel",10),true)
			waitFor(function() return not panel.Visible and hud.Visible end,"native Cancel restores HUD")
		elseif action=="choose" then
			assert(type(options.civilization)=="string","Choose needs a civilization ID")
			open()
			-- Opening refreshes availability through the normal throttled remote.
			task.wait(.35)
			local button=content:FindFirstChild(options.civilization)
			assert(button and button:IsA("TextButton"),"Civilization row is missing")
			click(button,true)
			waitFor(function() return player:GetAttribute("CivilizationId")==options.civilization and not panel.Visible end,"native civilization row switch")
		elseif action~="inspect" then error("Unknown native civilization action") end
		local rows={}
		for _,civ in require(game.ReplicatedStorage.Shared.Civilizations) do
			local row=content:FindFirstChild(civ.id)
			assert(row and row:FindFirstChild("Progress") and row:FindFirstChild("Availability"))
			rows[civ.id]={active=row.Active,selectable=row.Selectable,progress=row.Progress.Text,
				availability=row.Availability.Text,position={row.AbsolutePosition.X,row.AbsolutePosition.Y}}
		end
		return {ok=true,cases=performed,selectorVisible=panel.Visible,hudVisible=hud.Visible,currentCiv=player:GetAttribute("CivilizationId"),
			plotId=player:GetAttribute("PlotId"),coins=player:GetAttribute("Coins"),rows=rows,
			viewport={workspace.CurrentCamera.ViewportSize.X,workspace.CurrentCamera.ViewportSize.Y}}
	end)
	if mouseDown then pcall(function() input:SendMouseButton(lastPosition,Enum.UserInputType.MouseButton1,false,0) end) end
	assert(ok,result)
	return result
end
