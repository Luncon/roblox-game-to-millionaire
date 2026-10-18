--!strict

local Tracks=require(script.Parent.UpgradeTracks)
local Skills=require(script.Parent.WeaponSkillConfig)
local Formation=require(script.Parent.FormationConfig)
local Development={}
Development.fields=table.freeze({settlement="level",weapon="weaponLevel",armor="armorLevel",barracks="barracksLevel",
	training="trainingLevel",farm="farmLevel",workers="workersLevel",armyCamp="armyCampLevel",
	blacksmith="blacksmithLevel",armorer="armorerLevel",storehouse="storehouseLevel",skill="skillLevel",hospital="hospitalLevel",shield="shieldLevel",warCouncil="warCouncilLevel",formation="formationLevel"})
Development.persistentFields=table.freeze({"coins","level","weaponLevel","armorLevel","barracksLevel",
	"trainingLevel","farmLevel","workersLevel","armyCampLevel","farmCoins","extraTroopClass",
	"blacksmithLevel","armorerLevel","storehouseLevel","skillLevel","hospitalLevel","shieldLevel","warCouncilLevel","formationLevel","selectedFormation"})
local buildings={
 shield={field="shieldLevel",title="Shield Training",tiers={{unlock=Formation.shieldUnlock,cost=Formation.shieldCost}}},
 warCouncil={field="warCouncilLevel",title="War Council",tiers={{unlock=Formation.councilUnlock,cost=Formation.councilCost}}},
 formation={field="formationLevel",title="Formation Training",tiers={{unlock=Formation.unlock,cost=Formation.cost}}},
	hospital={field="hospitalLevel",title="Hospital",tiers={{unlock=10,cost=200}}},
	training={field="trainingLevel",title="Training Yard",tiers={{unlock=5,cost=50}}},
	farm={field="farmLevel",title="Farm",tiers={{unlock=7,cost=80},{unlock=12,cost=180}}},
	workers={field="workersLevel",title="Worker Camp",tiers={{unlock=7,cost=60},{unlock=12,cost=140}}},
	armyCamp={field="armyCampLevel",title="Army Camp",tiers={{unlock=10,cost=120},{unlock=Formation.campUnlock,cost=Formation.campCost}}},
	blacksmith={field="blacksmithLevel",title="Blacksmith",tiers={{unlock=13,cost=150}}},
	armorer={field="armorerLevel",title="Armorer",tiers={{unlock=13,cost=150}}},
	storehouse={field="storehouseLevel",title="Storehouse",tiers={{unlock=16,cost=140}}},
}
for _,building in buildings do
	building.unlock,building.cost=building.tiers[1].unlock,building.tiers[1].cost
	building.maxLevel=#building.tiers
	for _,tier in building.tiers do table.freeze(tier) end
	table.freeze(building.tiers)
	table.freeze(building)
end
Development.buildings=table.freeze(buildings)
Development.farmCapacity,Development.tickSeconds=60,5

function Development.offer(state,track: string,civilizationId: string?)
	local field=Development.fields[track]
	if not field then return nil end
	local building=buildings[track]
	local current=state[field] or (if building or track=="skill" then 0 else 1)
	local cost,required,nextLevel
	if track=="skill" then
		local tier=Skills.tiers[current+1]
		cost=if tier then tier.cost else nil
		required=if tier then tier.unlock else 50
		nextLevel=if tier then current+1 else nil
	elseif building then
		local tier=building.tiers[current+1]
		cost=if tier then tier.cost else nil
		required=(tier or building.tiers[current] or building.tiers[1]).unlock
		nextLevel=if tier then current+1 else nil
	else
		local tier=Tracks[track][current]
		if not tier then return nil end
		cost,required=tier.nextCost,tier.requiredSettlement or 1
		nextLevel=if cost then current+1 else nil
		if cost and ((track=="weapon" and state.blacksmithLevel==1) or (track=="armor" and state.armorerLevel==1)) then
			cost=math.ceil(cost*.95)
		end
	end
	local missing={}
	if track=="skill" then
		if state.trainingLevel~=1 then table.insert(missing,"Training Yard I") end
		if (state.weaponLevel or 1)<required then table.insert(missing,"Weapon "..required) end
	end
	if track=="workers" and nextLevel and (state.farmLevel or 0)<nextLevel then
		table.insert(missing,if nextLevel==2 then "Farm II" else "Farm I")
	end
 if track=="shield" or track=="formation" then
  if not Formation.forCivilization(civilizationId) then table.insert(missing,"Shield formation unavailable") end
 end
 if track=="shield" then
  if (state.armorLevel or 1)<Formation.shieldUnlock then table.insert(missing,"Armor 15") end
  if state.armorerLevel~=1 then table.insert(missing,"Armorer I") end
 end
 if track=="warCouncil" and state.trainingLevel~=1 then table.insert(missing,"Training Yard I") end
 if track=="armyCamp" and nextLevel==2 and (state.barracksLevel or 1)<6 then table.insert(missing,"Barracks VI") end
 if track=="formation" then
  if state.warCouncilLevel~=1 then table.insert(missing,"War Council I") end
  if state.shieldLevel~=1 then table.insert(missing,"Shield Training I") end
  if state.armyCampLevel~=2 then table.insert(missing,"Army Camp II") end
  if state.hospitalLevel~=1 then table.insert(missing,"Hospital I") end
 end
	if track=="hospital" and state.trainingLevel~=1 then table.insert(missing,"Training Yard I") end
	if track=="storehouse" and (state.farmLevel or 0)<1 then table.insert(missing,"Farm I") end
	if track=="armyCamp" and (state.barracksLevel or 1)<4 then table.insert(missing,"Barracks IV") end
	if track=="settlement" and current==9 then
		if (state.barracksLevel or 1)<4 then table.insert(missing,"Barracks IV") end
		if (state.trainingLevel or 0)<1 then table.insert(missing,"Training Yard I") end
		if (state.farmLevel or 0)<1 then table.insert(missing,"Farm I") end
		if (state.workersLevel or 0)<1 then table.insert(missing,"Worker Camp I") end
	end
	local definition=Formation.forCivilization(civilizationId)
	return {title=if track=="formation" and definition then definition.name elseif building then building.title else track,
		current=current,nextLevel=nextLevel,cost=cost,requiredSettlement=required,missing=missing,
		available=cost~=nil and state.level>=required and #missing==0}
end
function Development.farmYield(state): number
	return if (state.farmLevel or 0)>0 then state.farmLevel+(state.workersLevel or 0) else 0
end
function Development.storageCapacity(state): number
	return if state.storehouseLevel==1 then 180 else Development.farmCapacity
end
function Development.armyCapacity(state): number
	return Tracks.barracks[state.barracksLevel or 1].capacity+(state.armyCampLevel or 0)+(state.hospitalLevel or 0)
end
return table.freeze(Development)
