-- Native GUI layout in bounded frames; this does not simulate mobile hardware.
return function()
 local player=game.Players.LocalPlayer
 local gui=Instance.new('ScreenGui');gui.Name='FormationLayoutFixture';gui.IgnoreGuiInset=true;gui.Parent=player.PlayerGui
 local function inside(a,b)
  local p,s=a.AbsolutePosition,a.AbsoluteSize;local q,t=b.AbsolutePosition,b.AbsoluteSize
  return p.X>=q.X-.1 and p.Y>=q.Y-.1 and p.X+s.X<=q.X+t.X+.1 and p.Y+s.Y<=q.Y+t.Y+.1
 end
 local function overlaps(a,b)
  local p,s=a.AbsolutePosition,a.AbsoluteSize;local q,t=b.AbsolutePosition,b.AbsoluteSize
  return p.X<q.X+t.X and q.X<p.X+s.X and p.Y<q.Y+t.Y and q.Y<p.Y+s.Y
 end
 local cases=0
 local ok,result=pcall(function()
  for _,size in {Vector2.new(320,360),Vector2.new(320,568),Vector2.new(640,360),Vector2.new(1024,768)}do
   local shell=Instance.new('Frame');shell.Size=UDim2.fromOffset(size.X,size.Y);shell.ClipsDescendants=true;shell.Parent=gui
   local hud=Instance.new('Frame');hud.Name='SettlementHUD';hud.Position=UDim2.fromOffset(16,16)
   hud.Size=UDim2.fromOffset(math.min(360,size.X-32),if size.Y<400 then 146 else 198);hud.Parent=shell
   require(player.PlayerScripts.Game.ArmyUI).start(shell)
   task.wait(.2)
   local controls=shell.ArmyControls;assert(inside(controls,shell),'Command panel exceeds viewport '..tostring(size))
   assert(not overlaps(controls,hud),'Commands overlap settlement status '..tostring(size))
   local buttons={}
   for _,name in {'Advance','Hold','Regroup','MarchFormation'}do
    local b=controls[name];assert(b.Visible and inside(b,controls) and b.TextFits,'Clipped command '..name..' '..tostring(size))
    for _,other in buttons do assert(not overlaps(b,other),'Command buttons overlap')end;table.insert(buttons,b)
   end
   shell.CouncilOverlay.Visible=true;task.wait(.1)
   local room=shell.CouncilOverlay.WarCouncil
   assert(inside(room,shell) and inside(room.SelectShieldwall,room) and inside(room.CloseCouncil,room))
   assert(room.FormationDescription.TextFits and not overlaps(room.SelectShieldwall,room.CloseCouncil))
   shell.CouncilOverlay.Visible=false
   shell.RecruitmentOverlay.Visible=true;task.wait(.1)
   local recruitment=shell.RecruitmentOverlay.BarracksRecruitment
   assert(inside(recruitment,shell) and inside(recruitment.ApplyComposition,recruitment) and inside(recruitment.CloseRecruitment,recruitment))
   assert(recruitment.Heading.TextFits and recruitment.ApplyComposition.TextFits)
   for _,id in {'melee','ranged','medic'}do
    assert(recruitment.Composition[id..'Plus'].AbsoluteSize==Vector2.new(44,44))
    assert(not overlaps(recruitment.Composition[id..'Plus'],recruitment.Composition[id..'Minus']))
   end
   shell:Destroy();cases+=1
  end
  return {ok=true,cases=cases}
 end)
 gui:Destroy();assert(ok,result);return result
end
