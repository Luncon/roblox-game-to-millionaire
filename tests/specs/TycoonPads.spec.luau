return function()
	local BattlefieldMap = require(game.ServerScriptService.Game.BattlefieldMap)
	local catalog = require(game.ReplicatedStorage.Shared.Civilizations)
	local parent = Instance.new("Folder")
	parent.Name = "TycoonPadLayoutTest"
	parent.Parent = workspace
	local count = 0
	local function test(name, callback)
		callback()
		count += 1
		print("PASS: " .. name)
	end
	local ok, result = pcall(function()
		local world = BattlefieldMap.build(parent)
		test("all eight plots contain tangible coin and upgrade pads", function()
			for plotId = 1, 8 do
				local plot = world.model.Plots["Plot" .. plotId]
				local controls = plot:FindFirstChild("Controls")
				assert(controls, "Missing physical controls for plot " .. plotId)
				assert(controls:FindFirstChild("WeaponButton")==nil and controls:FindFirstChild("ArmorButton")==nil,"Outpost exposed locked gear pads")
				world:setOwner(plotId,catalog[1],101,"PadTester",2)
				world:syncControls(plotId,{coins=0,level=2,weaponLevel=1,armorLevel=1,barracksLevel=1})
				local pads = {}
				for _, name in { "CoinButton", "UpgradeButton", "WeaponButton", "ArmorButton", "Barracks2Button" } do
					local pad = controls:FindFirstChild(name)
					assert(pad and pad:IsA("BasePart"), "Missing ground pad " .. name)
					assert(pad.Anchored and pad.CanCollide and pad.CanQuery)
					assert(pad.Size.X >= 4 and pad.Size.Z >= 4, "Ground pad too small")
					assert((pad.Position - plot.Foundation.Position).Magnitude < 40)
					assert(pad:FindFirstChildOfClass("ClickDetector"), "Missing click input")
					assert(pad:FindFirstChildOfClass("ProximityPrompt"), "Missing alternate input")
					local surface = pad:FindFirstChildOfClass("SurfaceGui")
					assert(surface and surface:FindFirstChildOfClass("TextLabel"), "Missing pad label")
					table.insert(pads, pad)
					if name ~= "CoinButton" then assert(pad.CanTouch, "Upgrade pads support stepping") end
				end
				for i = 1, #pads do
					for j = i + 1, #pads do
						assert((pads[i].Position - pads[j].Position).Magnitude > 6, "Pads overlap")
					end
				end
				assert(controls.CoinButton.CanTouch == false, "Standing on coin pad must not generate clicks")
			end
		end)
		test("upgrading settlement preserves physical pad instances", function()
			local plot = world.model.Plots.Plot1
			local coin, upgrade = plot.Controls.CoinButton, plot.Controls.UpgradeButton
			for _,level in {1,2,4,10,25,40,50} do
				world:setOwner(1, catalog[1], 101, "PadTester", level)
				assert(coin.Parent == plot.Controls and upgrade.Parent == plot.Controls,
					"Settlement rebuild destroyed pad input bindings")
			end
		end)
		test("Studio-only testing pads are absent at creation and after claim sync in a disabled environment",function()
			assert(world.model.Plots.Plot1.Controls:FindFirstChild('TestCoinButton'))
			local liveParent=Instance.new('Folder');liveParent.Parent=workspace
			local live=BattlefieldMap.build(liveParent,function()return false end)
			for id=1,8 do assert(not live.model.Plots['Plot'..id].Controls:FindFirstChild('TestCoinButton'))end
			live:setOwner(1,catalog[1],101,'NoTestCoins',1)
			live:syncControls(1,{coins=0,level=1,weaponLevel=1,armorLevel=1,barracksLevel=1})
			assert(not live.model.Plots.Plot1.Controls:FindFirstChild('TestCoinButton'))
			liveParent:Destroy()
		end)
		test("every civilization leaves standing room above every upgrade pad", function()
			local plot = world.model.Plots.Plot1
			local overlap = OverlapParams.new()
			overlap.FilterType = Enum.RaycastFilterType.Include
			overlap.FilterDescendantsInstances = {plot.Settlement}
			for _, civ in catalog do
				for _,level in {1,2,4,10,25,40,50} do
					world:setOwner(1, civ, 101, "PadTester", level)
					world:syncControls(1,{coins=0,level=level,weaponLevel=1,armorLevel=1,barracksLevel=1})
					for _, pad in plot.Controls:GetChildren() do
						if pad:IsA("BasePart") then
							local obstacles = workspace:GetPartBoundsInBox(pad.CFrame * CFrame.new(0, 3.5, 0),
								Vector3.new(pad.Size.X - 1, 6, pad.Size.Z - 1), overlap)
							assert(#obstacles == 0, civ.id .. " level " .. level .. " blocks " .. pad.Name)
						end
					end
				end
			end
		end)
		test("plot release preserves the coin pad and restores starter controls after a capped settlement", function()
			local plot = world.model.Plots.Plot1
			local coin = plot.Controls.CoinButton
			assert(not plot.Controls:FindFirstChild("UpgradeButton"),"Completed settlement retained its purchase pad")
			world:setOwner(1, nil, nil, nil)
			assert(coin.Parent == plot.Controls and plot.Controls:FindFirstChild("UpgradeButton"))
			assert(plot.Controls.UpgradeButton:FindFirstChildOfClass("ClickDetector") and plot.Controls.UpgradeButton:FindFirstChildOfClass("ProximityPrompt"))
			assert(plot:GetAttribute("OwnerId") == nil and plot:GetAttribute("SettlementLevel") == nil)
			assert(plot.Foundation.Size.X == 60 and #plot.Settlement:GetChildren() == 0)
		end)
		return count
	end)
	parent:Destroy()
	assert(ok, result)
	return result
end
