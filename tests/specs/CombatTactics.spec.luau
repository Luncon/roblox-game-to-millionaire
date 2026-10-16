return function()
	local module=game.ServerScriptService.Game:FindFirstChild("CombatTactics")
	assert(module,"Tactical target selection and engagement spacing are not implemented")
	local Tactics=require(module)
	local Config=require(game.ReplicatedStorage.Shared.TacticalCombatConfig)
	local models={}
	local cases=0
	local function test(name,fn) fn();cases+=1;print("PASS: "..name) end
	local function actor(owner,kind,x,z,slot)
		local rig=Instance.new("Model");rig.Name="TacticsFixture";rig:SetAttribute("ArmySlot",slot or kind)
		table.insert(models,rig)
		return {rig=rig,ownerId=owner,claimed=true,alive=true,kind=kind,position=Vector3.new(x,4,z or 0)}
	end
	local ok,result=pcall(function()
		test("stable targets survive minor distance changes and invalid targets are replaced",function()
			local source=actor(1,"warrior",0)
			local current,closer=actor(2,"warrior",10),actor(3,"warrior",9)
			assert(Tactics.chooseTarget(source,{source,current,closer},current.rig,"advance")==current)
			current.alive=false
			assert(Tactics.chooseTarget(source,{source,current,closer},current.rig,"advance")==closer)
			closer.claimed=false
			assert(Tactics.chooseTarget(source,{source,current,closer},nil,"advance")==nil)
		end)
		test("hostility filtering and Hold retain existing protected target rules",function()
			local source,friend=actor(1,"warrior",0),actor(1,"ranged",2)
			local near,far=actor(2,"warrior",4),actor(3,"warrior",7)
			assert(Tactics.chooseTarget(source,{source,friend,far},nil,"hold")==nil)
			assert(Tactics.chooseTarget(source,{friend,far,near},nil,"hold")==near)
			local neutral=actor(nil,"warrior",3);neutral.neutral=true
			local other=actor(nil,"warrior",2);other.neutral=true
			assert(Tactics.chooseTarget(neutral,{other,near},nil,"advance")==near)
		end)
		test("melee considers threatened friendly ranged and crowded enemy approaches",function()
			local source=actor(1,"warrior",0)
			local archer=actor(1,"ranged",22)
			local ordinary,threat=actor(2,"warrior",15,10),actor(3,"warrior",19)
			assert(Tactics.chooseTarget(source,{source,archer,ordinary,threat},nil,"advance")==threat,
				"Melee ignored a nearby threat to its friendly ranged troop")
			local a,b=actor(2,"warrior",10),actor(3,"warrior",11)
			assert(Tactics.chooseTarget(source,{source,a,b},nil,"advance",{[a.rig]=Config.engagementSlots})==b,
				"Available enemy was ignored in favor of a full engagement ring")
		end)
		test("melee ring offers finite distinct reachable positions even for coincident roots",function()
			local source,target=actor(1,"warrior",0),actor(2,"warrior",0)
			local points=Tactics.meleePoints(source,target)
			assert(#points==Config.engagementSlots)
			for i,point in points do
				assert(point.X==point.X and point.Z==point.Z)
				assert(math.abs(Tactics.flatDistance(point,target.position)-Config.meleeRadius)<.001)
				assert((point-target.position).Magnitude<=5,"Melee destination is outside current combat reach")
				for j=1,i-1 do assert(Tactics.flatDistance(point,points[j])>=Config.minimumSeparation-.01) end
			end
			local again=Tactics.meleePoints(source,target)
			for i,point in points do assert(point==again[i],"Coincident approach changed without any state change") end
		end)
		test("ranged retreat candidates are bounded finite and move away from pressure",function()
			for _,x in {0,6} do
				local source,target=actor(1,"ranged",x),actor(2,"warrior",0)
				local points=Tactics.rangedPoints(source,target,true)
				assert(#points>0)
				local farther=false
				for _,point in points do
					assert(point.X==point.X and point.Z==point.Z)
					assert(Tactics.flatDistance(source.position,point)<=Config.retreatStep+.01)
					if Tactics.flatDistance(point,target.position)>Tactics.flatDistance(source.position,target.position) then farther=true end
				end
				assert(farther,"No retreat option increases distance from melee")
			end
		end)
		test("attack phases have a bounded contact window and preserve current cadence",function()
			for _,kind in {"warrior","ranged"} do
				local durations=Config.phases[kind]
				local phase,progress=Tactics.attackPhase(10,10,kind)
				assert(phase=="windup" and progress==0)
				phase=Tactics.attackPhase(10,10+durations.windup+.001,kind);assert(phase=="contact")
				phase=Tactics.attackPhase(10,10+durations.windup+durations.contact+.001,kind);assert(phase=="recovery")
				phase=Tactics.attackPhase(10,10+durations.windup+durations.contact+durations.recovery+.001,kind)
				assert(phase=="idle")
				assert(durations.windup+durations.contact+durations.recovery>=(if kind=="warrior" then 1 else 2))
			end
		end)
		return cases
	end)
	for _,model in models do model:Destroy() end
	assert(ok,result)
	return result
end
