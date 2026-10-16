--!strict

-- Cosmetic time belongs to the viewing client. It never controls combat locks,
-- movement, cooldowns or hits, which retain their server deadlines.
local Config=require(script.Parent.WeaponSkillConfig)
local Playback={}
function Playback.new()
	local controller={}
	local records=setmetatable({}, {__mode="k"})
	local lastStarted=setmetatable({}, {__mode="k"})
	local function record(rig,family,time,predicted)
		return {rig=rig,family=family,startedAt=time,endsAt=time+Config.families[family].duration,
			predicted=predicted,civilization=rig:GetAttribute("EquipmentCivilization"),observed=false}
	end
	function controller:pending(rig,time)
		local current=records[rig]
		return current~=nil and current.predicted and time<current.startedAt+2
	end
	function controller:predict(rig,family,time)
		local current=records[rig]
		if current and (time<current.endsAt or self:pending(rig,time)) then return false end
		records[rig]=record(rig,family,time,true)
		return true
	end
	function controller:accept(result,receivedAt)
		local rig,family,serverStart=result.rig,result.family,result.startedAt
		if not rig or not Config.families[family] or type(serverStart)~="number" then return end
		if result.civilizationId and result.civilizationId~=rig:GetAttribute("EquipmentCivilization") then return end
		if lastStarted[rig] and serverStart<=lastStarted[rig] then return end
		lastStarted[rig]=serverStart
		local current=records[rig]
		if not current or not current.predicted or current.family~=family then
			current=record(rig,family,receivedAt,false)
			records[rig]=current
		end
		-- An acknowledgement must not rewind or extend an immediate local preview,
		-- including one that already completed while its reply was in transit.
		current.predicted=false
		current.serverStart=serverStart
	end
	function controller:reject(rig)
		local current=records[rig]
		if current and current.predicted then records[rig]=nil end
	end
	function controller:performances(owners,time)
		local performances={}
		local present={}
		for _,owner in owners do
			local rig=owner.Character
			if not rig then continue end
			present[rig]=true
			local hum=rig:FindFirstChildOfClass("Humanoid")
			if not rig.Parent or not hum or hum.Health<=0 then records[rig]=nil;continue end
			local family=rig:GetAttribute("WeaponSkillActive")
			local started=rig:GetAttribute("WeaponSkillStartedAt")
			local ends=rig:GetAttribute("WeaponSkillEndsAt")
			-- Attributes remain a fallback for clients joining an ongoing action.
			if family and started and ends and time<ends and (not lastStarted[rig] or started>lastStarted[rig]) then
				self:accept({rig=rig,family=family,startedAt=started},time)
			end
			local current=records[rig]
			if not current then continue end
			if current.civilization~=rig:GetAttribute("EquipmentCivilization") then records[rig]=nil;continue end
			if current.serverStart and family and started==current.serverStart then current.observed=true
			elseif current.observed then records[rig]=nil;continue end
			if time<current.endsAt then
				table.insert(performances,{rig=rig,family=current.family,elapsed=math.max(0,time-current.startedAt)})
			elseif time>=current.endsAt+2 then records[rig]=nil end
		end
		for rig in records do if not present[rig] then records[rig]=nil end end
		return performances
	end
	return controller
end
return Playback
