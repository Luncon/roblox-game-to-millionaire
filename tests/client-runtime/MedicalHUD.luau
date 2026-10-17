-- Inspect actual rendered UI and replicated attributes without changing either.
return function()
 local player=game:GetService("Players").LocalPlayer
 local screen=player.PlayerGui:WaitForChild("CivilizationSelection",10)
 local hud,panel=screen.SettlementHUD,screen.ArmyControls
 task.wait(.3)
 local function inside(parent,child)
  local a,b=parent.AbsolutePosition,child.AbsolutePosition
  local p,c=parent.AbsoluteSize,child.AbsoluteSize
  return b.X>=a.X-1 and b.Y>=a.Y-1 and b.X+c.X<=a.X+p.X+1 and b.Y+c.Y<=a.Y+p.Y+1
 end
 assert(hud.Visible and panel.Visible and inside(screen,hud) and inside(screen,panel),"Army UI leaves the viewport")
 local a,b=hud.AbsolutePosition,panel.AbsolutePosition
 local x,y=hud.AbsoluteSize,panel.AbsoluteSize
 assert(a.X+x.X<=b.X or b.X+y.X<=a.X or a.Y+x.Y<=b.Y or b.Y+y.Y<=a.Y,"Army commands overlap settlement status")
 for _,container in {hud,panel}do for _,object in container:GetChildren()do
  if object:IsA("TextLabel") or object:IsA("TextButton")then if object.Visible then
   assert(inside(container,object),"Clipped army UI: "..object.Name)
   assert(object.TextFits,"Army text does not fit: "..object.Name..": "..object.Text)
  end end
 end end
 local text=hud.ArmyStatus.Text
 assert(player:GetAttribute("HospitalLevel")==1 and text:find("Hospital",1,true) and text:find("Medic",1,true))
 assert(text:find(string.format("%d/%d troops",player:GetAttribute("ArmyCount"),player:GetAttribute("TroopCapacity")),1,true),"Army total omits a hospital slot")
 local deadline=player:GetAttribute("MedicRespawnAt") or 0
 if deadline>workspace:GetServerTimeNow()then
  local displayed=tonumber(text:match("Medic (%d+)s"))
  assert(displayed and math.abs(displayed-math.ceil(deadline-workspace:GetServerTimeNow()))<=1,"Medic countdown uses another slot's timer")
 end
 local skill=player.PlayerGui:FindFirstChild("WeaponSkillHUD")
 if skill and skill.WeaponSkill.Visible then
  local button=skill.WeaponSkill
  assert(inside(skill,button) and button.TextFits,"Skill control is clipped")
  for _,container in {hud,panel}do
   local p,q=container.AbsolutePosition,button.AbsolutePosition
   local u,v=container.AbsoluteSize,button.AbsoluteSize
   assert(p.X+u.X<=q.X or q.X+v.X<=p.X or p.Y+u.Y<=q.Y or q.Y+v.Y<=p.Y,"Skill control overlaps army UI")
  end
 end
 return {ok=true,viewport={workspace.CurrentCamera.ViewportSize.X,workspace.CurrentCamera.ViewportSize.Y},status=text,
  hudBottom=hud.AbsolutePosition.Y+hud.AbsoluteSize.Y,commandTop=panel.AbsolutePosition.Y,medicDeadline=deadline}
end
