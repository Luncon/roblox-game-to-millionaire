return function()
	local Tenders=require(game.ServerScriptService.Game.FarmTenders)
	assert(type(Tenders.sample)=="function","Crop-row routine is missing")
	local cases=0
	for _,level in {1,2}do
		local duration=Tenders.cycle(level)
		for _,index in {1,2,3}do
			local visited,paused={},0
			local previous=nil
			for t=0,duration+.1,.05 do
				local frame,working=Tenders.sample(level,t,index)
				local p=frame.Position
				local center=if index==2 then 60 else -60
				assert(math.abs(p.X-center)<=23.01 and math.abs(p.Z+172)<=18.01,"Farmer left its field")
				if previous then assert((p-previous).Magnitude<=.201,"Farmer teleported or exceeded walking speed")end
				previous=p
				if working then
					paused+=1;visited[math.round(p.Z+172)]=true
					assert(math.abs(p.X-center)<.001,"Tending pause is outside crops")
				end
			end
			local rows=0;for _ in visited do rows+=1 end
			assert(rows==(if level==2 then 7 else 5) and paused>20,"Routine missed crop rows or tending pauses")
			local start=Tenders.sample(level,0,index)
			local finish=Tenders.sample(level,duration,index)
			assert((start.Position-finish.Position).Magnitude<.001,"Routine does not loop continuously")
		end
		local a=Tenders.sample(level,0,1)
		local b=Tenders.sample(level,0,3)
		assert((a.Position-b.Position).Magnitude>8,"Shared-field workers have identical phases")
		cases+=1
	end
	return cases
end
