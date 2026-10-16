return function()
	local Game=game.ServerScriptService.Game
	local Data=require(Game.ProfileData)
	local Camp=require(game.ReplicatedStorage.Shared.TrainingCampConfig)
	local civ=require(game.ReplicatedStorage.Shared.Civilizations)[1]
	local folder=Instance.new("Folder");folder.Name="WeaponSkillPadFixture";folder.Parent=workspace
	local cases=0
	local ok,message=pcall(function()
		local world=require(Game.BattlefieldMap).build(folder)
		world:setOwner(1,civ,101,"Skill pad fixture",50)
		local state=Data.defaultState();state.level=50
		local plot=world.model.Plots.Plot1
		world:syncControls(1,state);assert(not plot.Controls:FindFirstChild("SkillButton"));cases+=1
		state.weaponLevel,state.trainingLevel=10,1
		world:syncControls(1,state)
		local pad=assert(plot.Controls:FindFirstChild("SkillButton"))
		local point=plot.Foundation.CFrame:PointToObjectSpace(pad.Position)
		assert((point-Vector3.new(Camp.pad.X+12,Camp.pad.Y,Camp.pad.Z)).Magnitude<.01)
		assert(not Camp.contains(point,0) and pad:FindFirstChildOfClass("ProximityPrompt"));cases+=1
		state.weaponLevel=50;state.skillLevel=1;world:syncControls(1,state)
		assert(plot.Controls.SkillButton==pad,"Eligible repeat pad lost its contact latch identity");cases+=1
		state.weaponLevel=19;world:syncControls(1,state)
		assert(not plot.Controls:FindFirstChild("SkillButton"));cases+=1
		state.weaponLevel,state.skillLevel=50,5;world:syncControls(1,state)
		assert(not plot.Controls:FindFirstChild("SkillButton"));cases+=1
	end)
	folder:Destroy();assert(ok,message)
	return cases
end
