-- UI verification uses only the explicitly injected fake store.
return function(context,player,round,gameplayOnly)
 assert(context.store.isFakeProfileStore and game.RunService:IsStudio())
 local service=context.service;local cases=0
 local function check(action)
  game.ReplicatedStorage:SetAttribute('FormationVerificationPhase','UI '..action)
  local result=round('panelInput',{action=action},30);cases+=result.cases or 1;return result
 end
 check('selector')
 local s=require(game.ServerScriptService.Game.ProfileData).defaultState()
 s.coins,s.level,s.weaponLevel,s.armorLevel,s.barracksLevel=3000,20,20,15,6
 s.trainingLevel,s.armyCampLevel,s.hospitalLevel,s.warCouncilLevel,s.armorerLevel,s.shieldLevel,s.formationLevel=1,2,1,1,1,1,1
 s.selectedFormation='spartan-shieldwall'
 assert(service.profiles:set(player.UserId,'sparta',s))
 round('civilizationInput',{action='choose',civilization='sparta'},30)
 service.neutralOpponents:destroy();task.wait(.4);assert(service.command(player,'order','hold').ok)
 check('gameplayMinimize')
 local claim=service.registry:get(player.UserId);local plot=service.world.model.Plots['Plot'..claim.plotId]
 player.Character:PivotTo(plot.Controls.CoinButton.CFrame*CFrame.new(-10,3,0))
 local before=service.economy:get(player.UserId).coins
 assert(service.buttons:activate(player,claim.plotId,'earn').ok)
 assert(service.economy:get(player.UserId).coins==before+50)
 check('gameplayRestore');check('selectorCancel')
 if not gameplayOnly then
  player.Character:PivotTo(plot.Settlement.Barracks.RecruitmentBoard.CFrame*CFrame.new(0,-1,-3));task.wait(.3)
  check('recruitmentDraft')
  assert(service.economy:get(player.UserId).recruitMelee==nil,'Minimization saved an unsaved draft')
  player.Character:PivotTo(plot.Foundation.CFrame*CFrame.new(0,3,0));task.wait(.5)
  check('recruitmentClosed')
  player.Character:PivotTo(plot.Foundation.CFrame*CFrame.new(-148,3,35));task.wait(.3)
  check('councilMinimize')
  player.Character.Humanoid.Health=0;task.wait(.5);check('councilClosed')
  local deadline=os.clock()+15
  repeat task.wait(.1)until player.Character and player.Character:FindFirstChildOfClass('Humanoid')and player.Character.Humanoid.Health>0 or os.clock()>deadline
  assert(player.Character.Humanoid.Health>0)
  player.Character:PivotTo(plot.Settlement.Barracks.RecruitmentBoard.CFrame*CFrame.new(0,-1,-3));task.wait(.3)
  check('recruitmentReopen');round('civilizationInput',{action='choose',civilization='britain'},30)
  check('contextsClosed')
 end
 check('layout')
 return {ok=true,cases=cases}
end
