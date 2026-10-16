return function()
	local Playback=require(game.ReplicatedStorage.Shared.WeaponSkillPlayback)
	local function fixture()
		local rig={Parent=true,attributes={EquipmentCivilization="sparta"},humanoid={Health=100}}
		function rig:GetAttribute(name)return self.attributes[name]end
		function rig:FindFirstChildOfClass(name)return if name=="Humanoid" then self.humanoid else nil end
		return Playback.new(),rig,{{Character=rig}}
	end
	local playback,rig,owners=fixture()
	-- The dash ended on the server before its reliable start message arrived.
	playback:accept({rig=rig,family="spear",startedAt=10,endsAt=10.2},10.3)
	local frames=playback:performances(owners,10.3)
	assert(#frames==1 and frames[1].elapsed==0,"Accepted player dash lost its entire animation to network transit")
	assert(#playback:performances(owners,10.4)==1)
	assert(#playback:performances(owners,10.51)==0)
	print("PASS: late accepted dash remains visible for its complete local animation")
	local count=1
	local function test(name,fn)
		local current,actor,players=fixture();fn(current,actor,players);count+=1;print("PASS: "..name)
	end
	test("local input poses immediately before any server response",function(p,r,players)
		assert(p:predict(r,"spear",20) and p:pending(r,20))
		local now=p:performances(players,20);assert(#now==1 and now[1].elapsed==0)
		assert(not p:predict(r,"spear",20.1),"Repeat input restarted a pending pose")
		assert(#p:performances(players,20.21)==0 and p:pending(r,20.21),"Pending reply added visual recovery")
	end)
	test("acceptance preserves the input timeline instead of restarting it",function(p,r,players)
		p:predict(r,"spear",20)
		p:accept({rig=r,family="spear",startedAt=20.05,endsAt=20.25},20.1)
		local frame=p:performances(players,20.1)[1]
		assert(frame and math.abs(frame.elapsed-.1)<.001 and not p:pending(r,20.1))
		assert(#p:performances(players,20.21)==0)
	end)
	test("a late acknowledgement cannot replay a completed local preview",function(p,r,players)
		p:predict(r,"spear",20);assert(#p:performances(players,20.21)==0)
		p:accept({rig=r,family="spear",startedAt=20.05,endsAt=20.25},20.4)
		assert(#p:performances(players,20.4)==0)
	end)
	test("broadcast acknowledgement and stale attributes cannot duplicate an action",function(p,r,players)
		p:accept({rig=r,family="spear",startedAt=20,endsAt=20.2},20.3)
		p:accept({rig=r,family="spear",startedAt=20,endsAt=20.2},20.4)
		p:accept({rig=r,family="spear",startedAt=19,endsAt=19.2},20.4)
		assert(math.abs(p:performances(players,20.4)[1].elapsed-.1)<.001)
		r.attributes.WeaponSkillActive="spear";r.attributes.WeaponSkillStartedAt=20;r.attributes.WeaponSkillEndsAt=21
		assert(#p:performances(players,20.6)==0)
	end)
	test("a rejected prediction releases immediately without canceling an accepted action",function(p,r,players)
		p:predict(r,"spear",20);p:reject(r);assert(#p:performances(players,20.01)==0)
		p:accept({rig=r,family="spear",startedAt=21,endsAt=21.2},21);p:reject(r)
		assert(#p:performances(players,21.01)==1)
	end)
	test("death reset switch and observed cancellation release local poses",function()
		for _,mutation in {"death","reset","switch","cancel"} do
			local p,r,players=fixture()
			p:accept({rig=r,family="spear",startedAt=20,endsAt=20.2},20)
			r.attributes.WeaponSkillActive="spear";r.attributes.WeaponSkillStartedAt=20;r.attributes.WeaponSkillEndsAt=20.2
			assert(#p:performances(players,20.01)==1)
			if mutation=="death" then r.humanoid.Health=0 elseif mutation=="reset" then players[1].Character=nil
			elseif mutation=="switch" then r.attributes.EquipmentCivilization="persia" else r.attributes.WeaponSkillActive=nil end
			assert(#p:performances(players,20.02)==0)
		end
	end)
	test("a reliable start from a previous civilization cannot animate the new one",function(p,r,players)
		p:accept({rig=r,civilizationId="persia",family="spear",startedAt=20,endsAt=20.2},20.3)
		assert(#p:performances(players,20.3)==0)
	end)
	return count
end
