--!strict
local Tracks=require(script.Parent.UpgradeTracks)
local R={}

function R.capacity(state): number
 return Tracks.barracks[state.barracksLevel or 1].capacity+(state.armyCampLevel or 0)
end

function R.counts(state)
 if type(state.recruitMelee)=='number' and type(state.recruitRanged)=='number' and type(state.recruitMedic)=='number' then
  return {melee=state.recruitMelee,ranged=state.recruitRanged,medic=state.recruitMedic}
 end
 local ranged=if (state.barracksLevel or 1)>=4 then 1 else 0
 if (state.armyCampLevel or 0)>0 and state.extraTroopClass=='ranged'then ranged+=1 end
 return {melee=R.capacity(state)-ranged,ranged=ranged,medic=state.hospitalLevel or 0}
end

function R.valid(state,value): boolean
 if type(value)~='table'then return false end
 for _,key in {'melee','ranged','medic'}do
  local v=value[key]
  if type(v)~='number' or v<0 or v>4 or v%1~=0 then return false end
 end
 return value.melee+value.ranged<=R.capacity(state)
  and (value.ranged==0 or (state.barracksLevel or 1)>=4)
  and value.medic<=(state.hospitalLevel or 0)
end

function R.slots(state)
 local slots={{id='warrior',kind='warrior'}}
 if (state.barracksLevel or 1)>=4 then table.insert(slots,{id='ranged',kind='ranged'})end
 if (state.armyCampLevel or 0)>0 then table.insert(slots,{id='camp',kind=state.extraTroopClass or 'warrior'})end
 if state.armyCampLevel==2 then table.insert(slots,{id='reinforcement',kind='warrior'})end
 if state.hospitalLevel==1 then table.insert(slots,{id='medic',kind='medic'})end
 if state.recruitMelee==nil then return slots end
 local byId={};for _,slot in slots do byId[slot.id]=slot;slot.kind='none'end
 local counts=R.counts(state);local melee,ranged=counts.melee,counts.ranged
 -- Canonical formation front IDs receive melee before the rear archer ID.
 for _,id in {'warrior','camp','reinforcement','ranged'}do
  local slot=byId[id]
  if slot then
   if melee>0 then slot.kind='warrior';melee-=1
   elseif ranged>0 then slot.kind='ranged';ranged-=1 end
  end
 end
 if byId.medic and counts.medic==1 then byId.medic.kind='medic'end
 return slots
end

return table.freeze(R)
