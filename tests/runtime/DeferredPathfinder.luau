-- Deterministic async boundary for NavigationLifetime.spec; never in production.
return {CreatePath=function()
 local start,destination
 local path={Status=Enum.PathStatus.Success,Blocked=script.Parent.Blocked.Event}
 function path:ComputeAsync(origin,goal)
  start,destination=origin,goal;script.Parent:SetAttribute('Started',true);script.Parent.Release.Event:Wait()
 end
 function path:GetWaypoints()
  local middle=script.Parent:GetAttribute('Middle')
  local last={Position=destination,Action=if script.Parent:GetAttribute('Jump')then Enum.PathWaypointAction.Jump else Enum.PathWaypointAction.Walk}
  if script.Parent:GetAttribute('IncludeStart')then return {{Position=start,Action=Enum.PathWaypointAction.Walk},last}end
  return if middle then {{Position=middle,Action=Enum.PathWaypointAction.Walk},last} else {last}
 end
 function path:Destroy()script.Parent:SetAttribute('Discarded',true)end
 return path
end}
