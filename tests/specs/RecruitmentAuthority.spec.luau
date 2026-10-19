return function()
 local G=game.ServerScriptService.Game
 local Service=require(G.BarracksRecruitment);local Data=require(G.ProfileData)
 local container=Instance.new('Model');container.Parent=workspace
 local plots=Instance.new('Folder');plots.Name='Plots';plots.Parent=container
 local plot=Instance.new('Model');plot.Name='Plot1';plot:SetAttribute('OwnerId',101);plot:SetAttribute('CivilizationId','rome');plot.Parent=plots
 local settlement=Instance.new('Folder');settlement.Name='Settlement';settlement.Parent=plot
 local barracks=Instance.new('Model');barracks.Name='Barracks';barracks.Parent=settlement
 local board=Instance.new('Part');board.Name='RecruitmentBoard';board.Anchored=true;board.Position=Vector3.new(9000,9000,9000);board.Parent=barracks
 local character=Instance.new('Model');character.Parent=container
 local root=Instance.new('Part');root.Name='HumanoidRootPart';root.Anchored=true;root.Position=board.Position;root.Parent=character
 local hum=Instance.new('Humanoid');hum.RequiresNeck=false;hum.Parent=character
 local player={Parent=game.Players,UserId=101,Character=character}
 local state=Data.defaultState();state.level,state.barracksLevel=4,4
 local writable=true;local economy=require(G.Economy).new(function()return 10 end,function()return writable end);assert(economy:open(101,state))
 local registry={get=function()return {civilizationId='rome',plotId=1}end}
 local fired=0;local event={FireClient=function()fired+=1 end}
 local controller=Service.new({model=container},registry,economy,event,function()end)
 local ok,result=pcall(function()
  assert(controller:open(player).ok and fired==1)
  local selection={melee=0,ranged=2,medic=0}
  root.Position+=Vector3.new(30,0,0);assert(not controller:select(player,selection).ok);root.Position=board.Position
  writable=false;assert(not controller:select(player,selection).ok);writable=true
  plot:SetAttribute('OwnerId',102);assert(not controller:select(player,selection).ok);plot:SetAttribute('OwnerId',101)
  plot:SetAttribute('CivilizationId','sparta');assert(not controller:select(player,selection).ok);plot:SetAttribute('CivilizationId','rome')
  hum.Health=0;assert(not controller:select(player,selection).ok)
  assert(economy:get(101).recruitMelee==nil)
  return 1
 end)
 controller:destroy();container:Destroy();assert(ok,result);return result
end
