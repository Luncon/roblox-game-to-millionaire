return function(options)
 local melee=if options then options.melee or 2 else 2
 local ranged=4-melee
 local player=game.Players.LocalPlayer
 local screen=player.PlayerGui:WaitForChild('CivilizationSelection',10)
 local overlay=screen:WaitForChild('RecruitmentOverlay',10)
 local input=game:GetService('UserInputService'):CreateVirtualInput()
 local plot=workspace.CivilizationPrototype.Plots['Plot'..player:GetAttribute('PlotId')]
 local board=plot.Settlement.Barracks.RecruitmentBoard
 local camera=workspace.CurrentCamera;local old={kind=camera.CameraType,frame=camera.CFrame}
 local function waitFor(fn,label)
  local deadline=os.clock()+10;repeat if fn()then return end;task.wait(.03)until os.clock()>deadline;error('Timed out: '..label)
 end
 local function click(button)
  local inset=game.GuiService:GetGuiInset();local p=button.AbsolutePosition+button.AbsoluteSize/2+(if screen.IgnoreGuiInset then Vector2.zero else inset)
  input:SendMousePosition(p);input:SendMouseButton(p,Enum.UserInputType.MouseButton1,true,0)
  task.wait(.08);input:SendMouseButton(p,Enum.UserInputType.MouseButton1,false,0);task.wait(.12)
 end
 local ok,result=pcall(function()
  camera.CameraType=Enum.CameraType.Scriptable;camera.CFrame=CFrame.lookAt(player.Character.HumanoidRootPart.Position+Vector3.new(0,2,0),board.Position)
  task.wait(.5);input:SendKey(true,Enum.KeyCode.E,false);task.wait(.1);input:SendKey(false,Enum.KeyCode.E,false)
  waitFor(function()return overlay.Visible end,'native Barracks prompt')
  local panel=overlay.BarracksRecruitment;local body=panel.Composition
  assert(body.meleeCount.Text=='3' and body.rangedCount.Text=='1' and body.medicCount.Text=='1')
  assert(not body.meleePlus.Active,'Capacity overflow button must be disabled')
  for _=1,3-melee do click(body.meleeMinus);click(body.rangedPlus)end
  assert(body.meleeCount.Text==tostring(melee) and body.rangedCount.Text==tostring(ranged))
  click(panel.ApplyComposition)
  waitFor(function()return player:GetAttribute('RecruitMelee')==melee and player:GetAttribute('RecruitRanged')==ranged end,'saved native count selection')
  assert(body.RecruitmentFeedback.Text:find('saved',1,true))
  click(panel.CloseRecruitment);waitFor(function()return not overlay.Visible end,'native recruitment close')
  return {ok=true,melee=melee,ranged=ranged,medic=1}
 end)
 camera.CameraType=old.kind;camera.CFrame=old.frame;assert(ok,result);return result
end
