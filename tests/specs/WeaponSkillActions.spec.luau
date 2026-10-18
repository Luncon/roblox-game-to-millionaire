-- Deterministic action tests with explicit actor/physics doubles; not engine evidence.
return function()
	local Skills=require(game.ServerScriptService.Game.WeaponSkillService)
	local Data=require(game.ServerScriptService.Game.ProfileData)
	local count=0
	local function test(name,fn) fn();count+=1;print("PASS: "..name) end
	local function fixture(civ,kind,tier)
		local time=0
		local state=Data.defaultState();state.level,state.weaponLevel,state.trainingLevel,state.skillLevel=50,50,1,tier or 5
		local values,actors,hits={},{},{}
		local combat={writable=true,clear=true}
		local function rig(owner,civilization,class,point,slot)
			local model={Name=slot or "actor",attributes={ArmySlot=slot or class},Parent=true}
			function model:GetAttribute(name)return self.attributes[name]end
			function model:SetAttribute(name,value)self.attributes[name]=value end
			local hum={Health=100,WalkSpeed=12,AutoRotate=true,HipHeight=0,RigType=Enum.HumanoidRigType.R6}
			function hum:Move()end
			function hum:TakeDamage(amount)self.Health=math.max(0,self.Health-amount)end
			local root={Position=point,CFrame=CFrame.lookAt(point,point+Vector3.new(0,0,-1)),Size=Vector3.new(2,2,1),Anchored=true,Parent=true}
			function model:FindFirstChildOfClass(className)
				if className=="Humanoid" then return hum end
				if className=="Tool" then return self.tool end
			end
			local actor={rig=model,root=root,humanoid=hum,position=point,ownerId=owner,civilizationId=civilization,plotId=owner,
				kind=class,alive=true,claimed=true}
			actors[model]=actor
			return model,actor
		end
		function combat:actor(model)
			local a=actors[model]
			if not a or not model.Parent or a.humanoid.Health<=0 then return nil end
			-- Real roots update Position automatically; the double reads CFrame here.
			a.position=a.root.CFrame.Position;a.root.Position=a.position
			return a
		end
		function combat:actors()
			local list={};for model in actors do local a=self:actor(model);if a then table.insert(list,a) end end;return list
		end
		function combat:canAct(model)return self.writable and self:actor(model)~=nil end
		function combat:visible()return self.clear end
		local arena={Size=Vector3.new(2,500,500),CFrame={}}
		function arena.CFrame:PointToObjectSpace(point)return Vector3.new(point.Y-3,point.X,point.Z)end
		local physics={blocked=false,floor=true}
		function physics:Blockcast()return if self.blocked then {} else nil end
		function physics:Raycast(origin)
			return if self.floor then {Position=Vector3.new(origin.X,0,origin.Z),Normal=Vector3.new(0,1,0)} else nil
		end
		local economy={};function economy:get(id)return values[id]end
		values[1]=state
		local source,actor=rig(1,civ or "britain",kind or "warrior",Vector3.new(0,3,0),"warrior")
		local target,victim=rig(2,"sparta","warrior",Vector3.new(0,3,-4),"enemy")
		local service=Skills.new({model={Battlefield=arena}},combat,economy,function(a,b,amount)
			table.insert(hits,{source=a.rig,target=b.rig,amount=amount,at=time})
			b.humanoid.Health=math.max(0,b.humanoid.Health-amount);return {ok=true}
		end,function()return time end,physics)
		local function step(value)time=value;return service:step()end
		return {service=service,combat=combat,state=state,source=source,target=target,actor=actor,victim=victim,
			hits=hits,step=step,create=rig,physics=physics,values=values,arena=arena,clock=function()return time end}
	end
	local function run(civ,kind,fn,tier)
		local f=fixture(civ,kind,tier);local ok,message=pcall(fn,f);f.service:destroy();assert(ok,message)
	end
	test("medics cannot activate weapon skills even with maximum owner upgrades",function()
  run("sparta","medic",function(f)
   assert(f.service:info(f.source)==nil)
   assert(not f.service:activate(f.source,"advance",true).ok and #f.hits==0)
  end)
 end)
 test("skills begin immediately and release movement at the final active frame",function()
		for _,entry in {{"britain","sword",.24},{"vikings","axe",.35},{"sparta","spear",.2}} do run(entry[1],"warrior",function(f)
			if entry[2]=="spear" then f.victim.root.CFrame=CFrame.new(0,3,-40) end
			assert(f.service:activate(f.source,"advance",false).ok)
			if entry[2]=="spear" then
				f.step(.01);assert(f.actor.root.Position.Z<0,"Dash has startup lag")
				for i=2,20 do f.step(i/100) end
				assert(math.abs(f.actor.root.Position.Z+12)<.001,"Dash must travel twelve studs in .2 seconds")
			else
				assert(#f.hits==1,"Accepted skill must contact immediately")
				f.step(entry[3]-.001);assert(f.service:busy(f.source))
				assert(f.step(entry[3]),"NPC routing was not notified of the completed skill")
				assert(#f.hits==(if entry[2]=="sword" then 2 else 1))
			end
			assert(not f.service:busy(f.source) and f.actor.humanoid.WalkSpeed==12 and f.actor.humanoid.AutoRotate)
			assert(f.source.attributes.WeaponSkillActive==nil)
		end)end
	end)
	test("cancelling a skill releases its ordinary lock without refunding cooldown",function()run("sparta","warrior",function(f)
		assert(f.service:activate(f.source,"advance",false).ok)
		f.service:cancel(f.source)
		-- Same rig may change equipment family after cancellation.
		f.actor.civilizationId="britain"
		assert(f.service:activate(f.source,"advance",false).ok,"Canceled action left a recovery lock")
	end)end)
	test("an expired sword action cannot deliver its second slash after a stalled heartbeat",function()run("britain","warrior",function(f)
		local result=f.service:activate(f.source,"advance",false)
		assert(result.ok and result.rig==f.source and result.endsAt-result.startedAt<.241)
		assert(#f.hits==1)
		f.step(.5);assert(#f.hits==1 and not f.service:busy(f.source))
	end)end)
	test("sword resolves each contact once and releases ordinary attacks at the second slash",function()run("britain","warrior",function(f)
		assert(f.service:activate(f.source,"advance",true).ok)
		assert(#f.hits==1)
		f.step(.12);f.step(.23);assert(#f.hits==1 and f.service:busy(f.source))
		f.step(.24);f.step(.25);assert(#f.hits==2)
		assert(math.abs(f.hits[1].amount-15.3)<.0001 and math.abs(f.hits[2].amount-17.1)<.0001)
		assert(not f.service:busy(f.source) and not f.service:activate(f.source,"advance",true).ok)
		f.step(1.21);assert(not f.service:busy(f.source) and f.actor.humanoid.WalkSpeed==12)
		assert(f.service:activate(f.source,"advance",true).reason=="cooldown")
	end)end)
	test("sword second contact cannot hit an escaped or replaced target life",function()
		for _,mutation in {"escape","new_life","blocked","friendly","protected"} do run("japan","warrior",function(f)
			assert(f.service:activate(f.source,"advance",true).ok);f.step(.21)
			if mutation=="escape" then f.victim.root.CFrame=CFrame.new(0,3,-20)
			elseif mutation=="new_life" then f.victim.humanoid={Health=100}
			elseif mutation=="blocked" then f.combat.clear=false
			elseif mutation=="friendly" then f.victim.ownerId=1
			else f.victim.root.CFrame=CFrame.new(251,3,0) end
			f.step(.24);assert(#f.hits==1)
		end)end
	end)
	test("spin selects only nearest three visible hostiles and does not duplicate targets",function()run("vikings","warrior",function(f)
		f.create(3,"sparta","warrior",Vector3.new(2,3,0),"near")
		f.create(4,"sparta","warrior",Vector3.new(-3,3,0),"middle")
		local far=f.create(5,"sparta","warrior",Vector3.new(0,3,5),"far")
		f.create(1,"vikings","warrior",Vector3.new(1,3,0),"friendly")
		assert(f.service:activate(f.source,"hold",true).ok)
		f.step(.26);f.step(.4);f.step(.6)
		assert(#f.hits==3)
		for _,hit in f.hits do assert(hit.target~=far and math.abs(hit.amount-21.6)<.0001)end
	end)end)
	test("dash strikes first in-lane hostile once and Hold forbids it",function()run("sparta","warrior",function(f)
		assert(f.service:activate(f.source,"hold",true).reason=="order_locked")
		local flank=f.create(3,"britain","warrior",Vector3.new(3,3,-2),"flank")
		assert(f.service:activate(f.source,"advance",true).ok)
		f.step(.1);f.step(.21);f.step(.3)
		assert(#f.hits==1 and f.hits[1].target~=flank and math.abs(f.hits[1].amount-30.6)<.0001)
	end)end)
	test("formed frontline thrust strikes once without moving and retains the normal spear cooldown",function()run("sparta","warrior",function(f)
		f.source:SetAttribute("FormationActive",true)
		-- A foe within spear reach can stand outside the dash's narrow travel lane.
		f.victim.root.CFrame=CFrame.new(2,3,-3.5)
		local start=f.actor.root.CFrame
		assert(f.service:activate(f.source,"formation",true).ok)
		assert(#f.hits==1 and math.abs(f.hits[1].amount-30.6)<.0001)
		for i=1,20 do f.step(i/100);assert(f.actor.root.CFrame==start,'Formation thrust dashed out of its slot')end
		assert(#f.hits==1 and not f.service:busy(f.source) and f.actor.humanoid.WalkSpeed==12)
		assert(f.service:activate(f.source,"advance",true).reason=="cooldown")
	end)end)
	test("formation thrust requires a captured frontline spear and a visible hostile in normal melee reach",function()
		for _,kind in {'warrior','ranged'}do run('sparta',kind,function(f)
			f.source:SetAttribute('FormationActive',true)
			if kind=='ranged' then assert(f.service:activate(f.source,'formation',true).reason=='order_locked');return end
			f.victim.root.CFrame=CFrame.new(0,3,-8)
			assert(f.service:activate(f.source,'formation',true).reason=='no_target')
			f.victim.root.CFrame=CFrame.new(0,3,-4);f.combat.clear=false
			assert(f.service:activate(f.source,'formation',true).reason=='no_target')
			f.combat.clear=true;f.source:SetAttribute('FormationActive',false)
			assert(f.service:activate(f.source,'formation',true).reason=='order_locked')
		end)end
	end)
	test("Roman formed sword skill keeps both contacts stationary and uses the normal cooldown",function()run('rome','warrior',function(f)
		f.source:SetAttribute('FormationActive',true)
		local start=f.actor.root.CFrame
		assert(f.service:activate(f.source,'formation',true).ok and #f.hits==1)
		f.step(.24);assert(#f.hits==2 and f.actor.root.CFrame==start and not f.service:busy(f.source))
		assert(f.service:activate(f.source,'formation',true).reason=='cooldown')
	end)end)
	test("dash collision grounding and distance are bounded even with skipped frames",function()
		for _,obstacle in {"clear","wall","no_floor","stall"} do run("maurya","warrior",function(f)
			f.victim.root.CFrame=CFrame.new(0,3,-40)
			f.physics.blocked=obstacle=="wall";f.physics.floor=obstacle~="no_floor"
			assert(f.service:activate(f.source,"advance",false).ok)
			if obstacle=="stall" then f.step(.6) else for i=1,50 do f.step(i/100)end end
			assert(f.source.attributes.WeaponSkillActive==nil)
			assert(f.actor.root.CFrame.Position.Magnitude<14)
			if obstacle~="clear" then assert((f.actor.root.CFrame.Position-Vector3.new(0,3,0)).Magnitude<.001)end
			f.step(1.1);assert(not f.service:busy(f.source))
		end)end
	end)
	test("ranged axes and javelins use role damage but bow and neutral actors cannot activate",function()
		for _,id in {"vikings","sparta","rome"} do run(id,"ranged",function(f)
			assert(f.service:activate(f.source,"advance",true).ok)
			f.step(.1);f.step(.21);f.step(.27)
			assert(#f.hits==1)
			local multiplier=if id=="vikings" then 1.2 else 1.7
			assert(math.abs(f.hits[1].amount-18*.8*multiplier)<.0001)
		end)end
		run("japan","ranged",function(f) assert(f.service:activate(f.source,"advance",true).reason=="not_equipped")end)
		run("britain","warrior",function(f) f.actor.neutral=true;assert(not f.service:activate(f.source,"advance",true).ok)end)
	end)
	test("ordinary action lock misses and cancellation cannot bypass family cooldowns",function()run("britain","warrior",function(f)
		f.service:lockOrdinary(f.source,1)
		assert(f.service:activate(f.source,"advance",false).reason=="busy")
		f.step(1.01);f.victim.root.CFrame=CFrame.new(0,3,-20)
		assert(f.service:activate(f.source,"advance",false).ok)
		f.service:cancel(f.source);f.step(2.5)
		assert(#f.hits==0 and f.service:activate(f.source,"advance",false).reason=="cooldown")
		local replacement,actor=f.create(1,"rome","warrior",Vector3.new(0,3,0),"warrior")
		assert(f.service:activate(replacement,"advance",false).reason=="cooldown")
		f.state.skillLevel=4;assert(f.service:activate(replacement,"advance",false).reason=="cooldown")
	end)end)
	test("source authority and lifetime cancellation prevent pending contacts",function()
		for _,mutation in {"lease","death","switch","outside"} do run("britain","warrior",function(f)
			assert(f.service:activate(f.source,"advance",true).ok)
			if mutation=="lease" then f.combat.writable=false elseif mutation=="death" then f.actor.humanoid.Health=0
			elseif mutation=="switch" then f.actor.civilizationId="rome" else f.actor.root.CFrame=CFrame.new(251,3,0) end
			f.step(.24);assert(#f.hits==1 and not f.service:busy(f.source))
		end)end
	end)
	test("players must equip matching server-generated weapons and share the same skill rules",function()run("britain","player",function(f)
		assert(f.service:activate(f.source,nil,false).reason=="not_equipped")
		local attrs={GeneratedBy="CivilizationEquipment",CivilizationId="britain",WeaponLevel=50,WeaponKind="sword"}
		f.source.tool={GetAttribute=function(_,name)return attrs[name]end,FindFirstChild=function()return nil end}
		assert(f.service:activate(f.source,nil,false).ok);f.step(.21);assert(#f.hits==1)
		attrs.CivilizationId="sparta";f.step(.24);assert(#f.hits==1 and not f.service:busy(f.source))
	end)end)
	test("dash keeps troops server-owned and restores automatic ownership only for players",function()
		for _,kind in {"warrior","player"} do run("sparta",kind,function(f)
			if kind=="player" then
				local attrs={GeneratedBy="CivilizationEquipment",CivilizationId="sparta",WeaponLevel=50,WeaponKind="spear"}
				f.source.tool={GetAttribute=function(_,name)return attrs[name]end,FindFirstChild=function()return nil end}
			end
			local root=f.actor.root;root.Anchored=false;root.automatic=false
			function root:SetNetworkOwner(owner)assert(owner==nil)end
			function root:SetNetworkOwnershipAuto()self.automatic=true end
			assert(f.service:activate(f.source,"advance",true).ok)
			f.step(.1);f.step(.21);f.step(1.1)
			assert(root.automatic==(kind=="player"))
		end)end
	end)
	test("production damage pipeline awards a combo kill exactly once and blocks overlapping ordinary hits",function()run("britain","warrior",function(f)
		local Combat=require(game.ServerScriptService.Game.CombatService)
		local Economy=require(game.ServerScriptService.Game.Economy)
		local economy=Economy.new(f.clock);assert(economy:open(1,f.state))
		local registry={get=function(_,id)return if id==1 then {civilizationId="britain",plotId=1} else nil end}
		local published=0
		local actual=Combat.new({model={Battlefield=f.arena}},registry,economy,function(_,result,action)
			assert(action=="kill" and result.ok);published+=1
		end,f.clock)
		-- Explicit actor doubles isolate this test from player instances and real stores.
		actual.actor=function(_,rig)return f.combat:actor(rig)end
		actual.actors=function()return f.combat:actors()end
		actual.visible=function()return true end
		f.actor.player={Parent=game:GetService("Players")}
		f.victim.humanoid.Health=25
		local ok,message=pcall(function()
			assert(actual.skills:activate(f.source,"advance",true).ok)
			assert(actual:hit(f.source,f.target).reason=="busy")
			f.step(.21);actual.skills:step();assert(f.victim.humanoid.Health>0 and published==0)
			f.step(.24);actual.skills:step();actual.skills:step()
			assert(f.victim.humanoid.Health==0 and published==1 and economy:get(1).coins==10)
			local nextVictim=f.create(3,"sparta","warrior",Vector3.new(1,3,-3),"next")
			assert(actual:hit(f.source,nextVictim).ok,"Ordinary attack retained a skill recovery lock")
		end)
		actual:destroy();assert(ok,message)
	end)end)
 test("medics remain damageable for one kill reward while their own ordinary attacks reject",function()run("britain","warrior",function(f)
  local Combat=require(game.ServerScriptService.Game.CombatService)
  local Economy=require(game.ServerScriptService.Game.Economy)
  local economy=Economy.new(f.clock);assert(economy:open(1,f.state))
  local registry={get=function(_,id)return if id==1 then {civilizationId="britain",plotId=1} else nil end}
  local published=0
  local actual=Combat.new({model={Battlefield=f.arena}},registry,economy,function(_,result,action)assert(action=="kill" and result.ok);published+=1 end,f.clock)
  actual.actor=function(_,rig)return f.combat:actor(rig)end
  actual.actors=function()return f.combat:actors()end
  actual.visible=function()return true end
  f.actor.player={Parent=game:GetService("Players")};f.victim.kind="medic";f.victim.humanoid.Health=18
  local ok,msg=pcall(function()
   assert(actual:hit(f.source,f.target).killed)
   assert(not actual:hit(f.source,f.target).ok and published==1 and economy:get(1).coins==10)
   f.actor.kind="medic"
   local nextTarget=f.create(3,"sparta","warrior",Vector3.new(1,3,-3),"other")
   assert(actual:hit(f.source,nextTarget).reason=="invalid_actor")
   assert(not actual.skills:activate(f.source,"advance",true).ok)
   assert(published==1 and economy:get(1).coins==10)
  end)
  actual:destroy();assert(ok,msg)
 end)end)
 return count
end
