--!strict
local Camp=require(game:GetService("ReplicatedStorage").Shared.TrainingCampConfig)
local Recovery={}
function Recovery.contains(position: Vector3): boolean
 -- Root clearance above the exterior ground; coordinates are relative to Foundation.
 return Camp.contains(position,1) and position.Y>=.5 and position.Y<=5.5
end
function Recovery.step(record,life,eligible,now,lastHit): boolean
 local damaged=record.life==life and record.health~=nil and life.Health<record.health
 local interrupted=record.lastAt~=nil and now-record.lastAt>1.5
 local changedHit=lastHit~=nil and lastHit~=record.hit
 if record.life~=life or not eligible or life.Health<=0 or life.Health>=life.MaxHealth
  or damaged or changedHit or interrupted then
  record.entered,record.nextAt=nil,nil
 end
 record.life,record.health,record.lastAt,record.hit=life,life.Health,now,lastHit
 if not eligible or life.Health<=0 or life.Health>=life.MaxHealth then return false end
 if not record.entered then record.entered=now;return false end
 if now-record.entered<2 or (record.nextAt and now<record.nextAt) then return false end
 record.nextAt=now+1 -- Deliberately never repay missed ticks.
 return true
end
return table.freeze(Recovery)
