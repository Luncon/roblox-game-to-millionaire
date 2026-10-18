-- Deterministic async boundary for NavigationLifetime.spec; never in production.
return {CreatePath=function()
 local destination
 local path={Status=Enum.PathStatus.Success,Blocked=script.Parent.Blocked.Event}
 function path:ComputeAsync(_,goal)
  destination=goal;script.Parent:SetAttribute('Started',true);script.Parent.Release.Event:Wait()
 end
 function path:GetWaypoints()return {{Position=destination,Action=Enum.PathWaypointAction.Walk}}end
 function path:Destroy()script.Parent:SetAttribute('Discarded',true)end
 return path
end}
