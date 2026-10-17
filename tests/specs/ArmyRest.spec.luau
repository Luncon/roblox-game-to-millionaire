return function(moduleOverride)
	local module=moduleOverride or game.ServerScriptService.Game:FindFirstChild("ArmyRest")
	assert(module,"Army rest movement is not implemented")
	local Rest=require(module)
	local Camp=require(game.ReplicatedStorage.Shared.TrainingCampConfig)
	local cases=0
	local function test(name,fn) fn();cases+=1;print("PASS: "..name) end
	test("regroup first returns at normal speed then pauses at camp",function()
		local state=Rest.new("warrior")
		local goal,speed,arrived=Rest.step(state,Vector3.new(-24,5,-11),0)
		assert((goal-Camp.entryPoint(state.index)).Magnitude<.001 and speed==12 and not arrived)
		goal,speed,arrived=Rest.step(state,Camp.point(1),1)
		assert(goal==nil and speed==5 and arrived and state.phase=="pausing")
		local deadline=state.pauseUntil
		Rest.step(state,Camp.point(1),1.5)
		assert(state.pauseUntil==deadline,"A think tick reset the resting pause")
	end)
	test("slow walking retains adjacent safe goals until arrival",function()
		for _,slot in {"warrior","ranged","camp"} do
			local state=Rest.new(slot);local position=Camp.point(state.index)
			Rest.step(state,position,0)
			for cycle=1,12 do
				local goal,speed,arrived=Rest.step(state,position,state.pauseUntil+.01)
				assert(goal and speed==5 and arrived and Camp.contains(goal,2))
				local previous=position
				for tick=1,5 do
					local same=Rest.step(state,position,state.deadline-1)
					assert((same-goal).Magnitude<.001,"The retained wander goal changed on a think tick")
				end
				for t=0,1,.1 do
					local delta=previous:Lerp(goal,t)-Camp.center
					assert(Vector3.new(delta.X,0,delta.Z).Magnitude>5,"Walk crossed the fire")
				end
				position=goal
				local stopped=Rest.step(state,position,state.deadline-1)
				assert(stopped==nil and state.phase=="pausing")
			end
		end
	end)
	test("blocked goals reverse to another safe adjacent point without teleporting",function()
		local state=Rest.new("warrior");local position=Camp.point(1)
		Rest.step(state,position,0)
		local first=Rest.step(state,position,state.pauseUntil+.01)
		local deadline=state.deadline
		local fallback,speed=Rest.step(state,position,deadline+.01)
		assert((fallback-first).Magnitude>1 and (fallback-Camp.point(8)).Magnitude<.001 and speed==5)
		assert(Camp.contains(fallback,2) and state.phase=="walking")
	end)
	test("displaced resting troops return to their own yard at normal speed",function()
		local state=Rest.new("camp")
		Rest.step(state,Camp.point(8),0)
		local goal,speed,arrived=Rest.step(state,Vector3.zero,1)
		assert((goal-Camp.entryPoint(state.index)).Magnitude<.001 and speed==12 and not arrived)
	end)
	test("separate camp entrances fit inside the settlement gate with body clearance",function()
		local entries={}
		for _,slot in {"warrior","ranged","camp","medic"}do
			local p=Camp.entryPoint(Camp.arrivalIndex(slot))
			assert(math.abs(p.Z-Camp.center.Z)<=Camp.approachHalfWidth-2.5,"Arrival lane clips the gate")
			for _,other in entries do assert((p-other).Magnitude>=3.5,"Arrival lanes overlap")end
			table.insert(entries,p)
		end
	end)
	return cases
end
