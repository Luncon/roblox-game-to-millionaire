--!strict
local Shared=game:GetService("ReplicatedStorage").Shared
local Camp=require(Shared.TrainingCampConfig)
local Sites=require(Shared.SettlementSites)
local Route={}
-- Local plot coordinates keep the homeward corridor aligned for every plot.
function Route.contains(foundation,arenaPosition,point): boolean
 local p=foundation.CFrame:PointToObjectSpace(point)
 local center=foundation.CFrame:PointToObjectSpace(arenaPosition)
 local halfWidth=math.max(foundation.Size.X/2,math.abs(Camp.center.X)+Camp.size.X/2)+8
 return math.abs(p.X)<=halfWidth and p.Z>=center.Z-5 and p.Z<=Sites.hospital.Z+14
end
return table.freeze(Route)
