-- Inspect the real replicated HUD. This helper never changes player attributes.
return function(options)
	options=options or {}
	local player=game:GetService("Players").LocalPlayer
	local screen=player.PlayerGui:WaitForChild("CivilizationSelection",10)
	local hud=screen:WaitForChild("SettlementHUD",10)
	local deadline=os.clock()+10
	local expected=options.expected or {level=4,weaponLevel=4,armorLevel=4,barracksLevel=4}
	local attributes={level="SettlementLevel",weaponLevel="WeaponLevel",armorLevel="ArmorLevel",barracksLevel="BarracksUpgradeLevel",coins="Coins"}
	repeat
		local ready=hud.Visible
		for field,value in expected do ready=ready and player:GetAttribute(attributes[field])==value end
		if ready then break end
		task.wait(.05)
	until os.clock()>deadline
	assert(hud.Visible,"Settlement HUD is hidden")
	for field,value in expected do assert(player:GetAttribute(attributes[field])==value,"Unexpected replicated "..field) end
	task.wait(.3)
	local switch=hud:WaitForChild("SwitchCivilization",10)
	assert(switch and switch:IsA("GuiButton") and switch.Visible and switch.Active,"Switch control is unavailable")
	local evidence={viewport={workspace.CurrentCamera.ViewportSize.X,workspace.CurrentCamera.ViewportSize.Y},labels={},status=player:GetAttribute("ProgressStatus")}
	local function bounds(object)
		return {x=object.AbsolutePosition.X,y=object.AbsolutePosition.Y,width=object.AbsoluteSize.X,height=object.AbsoluteSize.Y}
	end
	local function contains(parent,child)
		local a,b=parent.AbsolutePosition,child.AbsolutePosition
		local p,c=parent.AbsoluteSize,child.AbsoluteSize
		return b.X>=a.X-1 and b.Y>=a.Y-1 and b.X+c.X<=a.X+p.X+1 and b.Y+c.Y<=a.Y+p.Y+1
	end
	assert(contains(screen,hud),"HUD extends outside the actual client viewport")
	for _,object in hud:GetDescendants() do
		if object:IsA("GuiButton") then assert(object==switch,"Currency or upgrade action leaked into the HUD") end
		if object:IsA("TextLabel") and object.Visible then
			assert(contains(hud,object),"HUD clips label "..object.Name)
			assert(object.TextFits,"HUD text does not fit "..object.Name..": "..object.Text)
			evidence.labels[object.Name]={text=object.Text,bounds=bounds(object)}
		end
	end
	assert(contains(hud,switch),"Switch button extends outside the HUD")
	local title=hud.Civilization
	assert(title.AbsolutePosition.X+title.AbsoluteSize.X<=switch.AbsolutePosition.X+1,"Civilization title overlaps switch control")
	local previousBottom=-math.huge
	for _,name in {"Civilization","Coins","Progression","Instruction","EconomyFeedback","ArmyStatus","SessionNotice"} do
		local object=hud:WaitForChild(name,10)
		assert(object.AbsolutePosition.Y>=previousBottom-1,"HUD rows overlap before "..name)
		previousBottom=object.AbsolutePosition.Y+object.AbsoluteSize.Y
	end
	if expected.coins then assert(hud.Coins.Text==tostring(expected.coins).." coins") end
	if expected.level==4 and expected.weaponLevel==4 and expected.armorLevel==4 then
		local _,maxCount=string.gsub(hud.Progression.Text,"MAX","")
		assert(maxCount==3,"Maximum settlement/weapon/armor must each display MAX")
	end
	if expected.barracksLevel==4 then
		assert(string.find(hud.ArmyStatus.Text,"IV",1,true),"Barracks IV status is missing")
		assert(string.find(hud.ArmyStatus.Text,"/2",1,true) and string.find(hud.ArmyStatus.Text,"Ranged",1,true),"Barracks IV must show both troop slots")
	end
	local notice=string.lower(hud.SessionNotice.Text)
	assert(not string.find(notice,"session only",1,true) and not string.find(notice,"not saved",1,true),"HUD still claims saving is unavailable")
	assert(type(evidence.status)=="string" and evidence.status~="", "Progress status was not replicated")
	evidence.deadlines={warrior=player:GetAttribute("WarriorRespawnAt"),ranged=player:GetAttribute("RangedRespawnAt")}
	evidence.ok,evidence.cases=true,4
	if options.requireCountdowns then
		local warrior=tonumber(string.match(hud.ArmyStatus.Text,"Warrior (%d+)s"))
		local ranged=tonumber(string.match(hud.ArmyStatus.Text,"Ranged (%d+)s"))
		assert(warrior and ranged,"Both independently waiting troop slots must display countdowns")
		local now=workspace:GetServerTimeNow()
		assert(type(evidence.deadlines.warrior)=="number" and type(evidence.deadlines.ranged)=="number")
		assert(math.abs(warrior-math.ceil(evidence.deadlines.warrior-now))<=1,"Warrior countdown does not match its own deadline")
		assert(math.abs(ranged-math.ceil(evidence.deadlines.ranged-now))<=1,"Ranged countdown does not match its own deadline")
		assert(math.abs(warrior-ranged)>=2,"Staggered deaths were not reflected as distinct slot countdowns")
		evidence.countdowns={warrior=warrior,ranged=ranged}
		evidence.cases+=1
	end
	return evidence
end
