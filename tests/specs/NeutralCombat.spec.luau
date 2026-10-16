return function(rulesOverride)
	local Game=game.ServerScriptService.Game
	local Rules=require(rulesOverride or Game.CombatRules)
	local Combat=require(Game.CombatService)
	local Registry=require(Game.ClaimRegistry)
	local Economy=require(Game.Economy)
	local catalog=require(game.ReplicatedStorage.Shared.Civilizations)
	local world={model=Instance.new("Model")}
	world.model.Name="NeutralCombatFixture"
	local arena=Instance.new("Part")
	arena.Name,arena.Shape,arena.Size="Battlefield",Enum.PartType.Cylinder,Vector3.new(2,500,500)
	arena.CFrame=CFrame.new(0,10000,0)*CFrame.Angles(0,0,math.pi/2)
	arena.Anchored=true;arena.Parent=world.model
	local folder=Instance.new("Folder");folder.Name="NeutralOpponents";folder.Parent=world.model
	world.model.Parent=workspace
	local combat
	local count=0
	local function test(name,fn) fn();count+=1;print("PASS: "..name) end
	local function rig(x,kind)
		local model=Instance.new("Model")
		local root=Instance.new("Part");root.Name="HumanoidRootPart";root.Anchored=true
		root.Position=Vector3.new(x,10004,0);root.Parent=model
		local humanoid=Instance.new("Humanoid");humanoid.BreakJointsOnDeath=false;humanoid.Parent=model
		model:SetAttribute("WarriorClass",kind or "warrior");model.Parent=folder
		return model
	end
	local ok,result=pcall(function()
		local registry=Registry.new(8,{sparta=true})
		local economy=Economy.new()
		combat=Combat.new(world,registry,economy)
		test("neutral registration requires the explicit server path and dedicated folder",function()
			local neutral=rig(0)
			neutral:SetAttribute("NeutralOpponent",true)
			assert(combat:actor(neutral)==nil,"Attributes alone authorized a neutral")
			assert(combat:registerNeutral(neutral,"warrior"),"Neutral registration rejected")
			local actor=combat:actor(neutral)
			assert(actor and actor.neutral==true and actor.ownerId==nil and actor.player==nil)
			neutral.Parent=world.model
			assert(combat:actor(neutral)==nil,"Moved neutral remained authoritative")
			assert(not combat:registerNeutral(neutral,"warrior"))
			neutral:Destroy()
		end)
		test("all civilizations and negative Studio IDs can fight neutrals",function()
			local a,b=rig(0),rig(3)
			assert(combat:registerNeutral(a,"warrior") and combat:registerNeutral(b,"warrior"))
			local neutral,other=combat:actor(a),combat:actor(b)
			assert(not Rules.canDamage(neutral,other,arena))
			for i,civ in catalog do
				local owned={ownerId=-i,claimed=true,alive=true,position=Vector3.new(3,10004,0),civilizationId=civ.id}
				assert(Rules.canDamage(owned,neutral,arena) and Rules.canDamage(neutral,owned,arena),civ.id)
				owned.claimed=false
				assert(not Rules.canDamage(neutral,owned,arena))
				owned.claimed=true;owned.position=Vector3.new(251,10004,0)
				assert(not Rules.canDamage(neutral,owned,arena,1000))
			end
			a:Destroy();b:Destroy()
		end)
		test("neutral friendliness and dead actors cannot cause damage",function()
			local a,b=rig(0),rig(3)
			combat:registerNeutral(a,"warrior");combat:registerNeutral(b,"warrior")
			assert(not combat:hit(a,b).ok and b.Humanoid.Health==100)
			b.Humanoid.Health=0;assert(combat:actor(b)==nil)
			a:Destroy();b:Destroy()
		end)
		test("neutral damage uses fixed basic stats without a player profile",function()
			-- Only the connected-owner actor boundary is doubled; neutral registration,
			-- range, visibility, Humanoid damage and cooldowns remain real.
			local owned=rig(3)
			local original=combat.actor
			combat.actor=function(self,model)
				if model==owned then return {ownerId=-1,claimed=true,alive=owned.Humanoid.Health>0,
					position=owned.HumanoidRootPart.Position,rig=owned,humanoid=owned.Humanoid} end
				return original(self,model)
			end
			for _,kind in {"warrior","ranged"} do
				local source=rig(0,kind);combat:registerNeutral(source,kind)
				local hit=combat:hit(source,owned)
				assert(hit.ok and hit.damage==(if kind=="ranged" then 8 else 10) and hit.reward==nil)
				assert(not combat:hit(source,owned).ok,"Neutral cooldown bypassed")
				source:Destroy()
			end
			combat.actor=original;owned:Destroy()
		end)
		test("owned final hit on a neutral pays exactly once",function()
			registry:claim(-1,"sparta");economy:open(-1)
			local source,victim=rig(0),rig(3)
			combat:registerNeutral(victim,"warrior")
			local original=combat.actor
			combat.actor=function(self,model)
				if model==source then return {ownerId=-1,kind="warrior",civilizationId="sparta",plotId=1,
					claimed=true,alive=true,position=source.HumanoidRootPart.Position,rig=source,humanoid=source.Humanoid,
					player={Parent=game:GetService("Players")}} end
				return original(self,model)
			end
			victim.Humanoid.Health=10
			local hit=combat:hit(source,victim)
			assert(hit.ok and hit.killed and hit.reward.ok and economy:get(-1).coins==10)
			assert(not combat:hit(source,victim).ok and economy:get(-1).coins==10)
			combat.actor=original;source:Destroy();victim:Destroy()
		end)
		return count
	end)
	if combat then combat:destroy() end
	world.model:Destroy()
	assert(ok,result)
	return result
end
