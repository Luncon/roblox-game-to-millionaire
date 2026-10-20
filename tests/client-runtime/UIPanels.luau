-- Native activation, local focus and bounded layout; never changes gameplay attributes.
return function(options)
 local player=game.Players.LocalPlayer;local screen=player.PlayerGui:WaitForChild('CivilizationSelection',10)
 local hud,army,selector=screen.SettlementHUD,screen.ArmyControls,screen.SelectionPanel
 local input=game.UserInputService:CreateVirtualInput();local gui=game.GuiService
 local function waitFor(fn,label)
  local deadline=os.clock()+10;repeat if fn()then return end;task.wait(.03)until os.clock()>deadline;error('Timed out: '..label)
 end
 local function click(button)
  assert(button and button.Visible and button.Active,'Missing active UI control')
  local inset=gui:GetGuiInset();local p=button.AbsolutePosition+button.AbsoluteSize/2+(if screen.IgnoreGuiInset then Vector2.zero else inset)
  input:SendMousePosition(p);task.wait(.1);input:SendMouseButton(p,Enum.UserInputType.MouseButton1,true,0)
  task.wait(.05);input:SendMouseButton(p,Enum.UserInputType.MouseButton1,false,0);task.wait(.12)
 end
 local function minimize(panel,root,tab)
  local button=assert(panel:FindFirstChild('MinimizePanel'),'Panel minimize control is missing: '..panel.Name)
  click(button);waitFor(function()return not root.Visible and screen[tab].Visible and root:GetAttribute('PanelOpen')end,'minimize '..panel.Name)
 end
 local function restore(root,tab)
  click(screen[tab]);waitFor(function()return root.Visible and not screen[tab].Visible end,'restore '..root.Name)
 end
 local function prompt(kind)
  local plot=workspace.CivilizationPrototype.Plots['Plot'..player:GetAttribute('PlotId')]
  local target=if kind=='council'then plot.Infrastructure.WarCouncil.MapTable else plot.Settlement.Barracks.RecruitmentBoard
  local camera=workspace.CurrentCamera;local oldKind,oldFrame=camera.CameraType,camera.CFrame
  camera.CameraType=Enum.CameraType.Scriptable
  camera.CFrame=CFrame.lookAt(player.Character.HumanoidRootPart.Position+Vector3.new(0,2,0),target.Position)
  task.wait(.4)
  input:SendKey(true,Enum.KeyCode.E,false);task.wait(.1);input:SendKey(false,Enum.KeyCode.E,false);task.wait(.3)
  camera.CameraType=oldKind;camera.CFrame=oldFrame
 end
 local action=options.action
 if action=='selector'then
  waitFor(function()return selector.Visible end,'initial selector');minimize(selector,selector,'RestoreCivilizations')
  assert(player:GetAttribute('CivilizationId')==nil);restore(selector,'RestoreCivilizations')
 elseif action=='gameplayMinimize'then
  assert(hud.Visible and army.Visible);minimize(hud,hud,'RestoreSettlement');assert(army.Visible,'HUD minimization hid army commands')
  gui.SelectedObject=army.Hold;minimize(army,army,'RestoreArmy');assert(gui.SelectedObject==screen.RestoreArmy,'Hidden panel retained focus')
 elseif action=='gameplayRestore'then
  assert(hud:GetAttribute('PanelMinimized')and army:GetAttribute('PanelMinimized')and not hud.Visible and not army.Visible)
  assert(hud.Coins.Text:find(tostring(player:GetAttribute('Coins')),1,true),'Minimized HUD stopped updating')
  restore(hud,'RestoreSettlement');assert(not army.Visible,'Restoring HUD reopened army controls')
  restore(army,'RestoreArmy');assert(gui.SelectedObject==army.Hold,'Restore lost the previous selectable control')
 elseif action=='selectorCancel'then
  click(hud.SwitchCivilization);waitFor(function()return selector.Visible end,'change civ')
  minimize(selector,selector,'RestoreCivilizations');assert(not hud.Visible and not army.Visible)
  restore(selector,'RestoreCivilizations')
  return require(script.Parent.CivilizationInput)({action='cancel'})
 elseif action=='recruitmentDraft'or action=='recruitmentReopen'then
  local overlay=screen.RecruitmentOverlay;local panel=overlay.BarracksRecruitment;prompt()
  waitFor(function()return overlay.Visible end,'recruitment prompt')
  if action=='recruitmentDraft'then
   assert(panel.Composition.meleeCount.Text=='3');click(panel.Composition.meleeMinus)
   minimize(panel,overlay,'RestoreRecruitment');restore(overlay,'RestoreRecruitment')
   assert(panel.Composition.meleeCount.Text=='2','Minimize discarded recruitment draft')
  else assert(panel.Composition.meleeCount.Text=='3','Fresh interaction retained stale draft')end
  minimize(panel,overlay,'RestoreRecruitment')
 elseif action=='recruitmentClosed'then
  waitFor(function()return not screen.RecruitmentOverlay:GetAttribute('PanelOpen')and not screen.RestoreRecruitment.Visible end,'minimized recruitment distance closure')
 elseif action=='councilMinimize'then
  prompt('council');local root=screen.CouncilOverlay;waitFor(function()return root.Visible end,'council prompt')
  minimize(root.WarCouncil,root,'RestoreCouncil');restore(root,'RestoreCouncil');minimize(root.WarCouncil,root,'RestoreCouncil')
 elseif action=='councilClosed'then
  waitFor(function()return not screen.CouncilOverlay:GetAttribute('PanelOpen')and not screen.RestoreCouncil.Visible end,'minimized council death closure')
 elseif action=='contextsClosed'then
  assert(not screen.RecruitmentOverlay:GetAttribute('PanelOpen')and not screen.RestoreRecruitment.Visible and not screen.RestoreCouncil.Visible)
 elseif action=='layout'then
  return require(script.Parent.FormationLayout)()
 else error('Unknown UI action: '..tostring(action))end
 return {ok=true,cases=1}
end
