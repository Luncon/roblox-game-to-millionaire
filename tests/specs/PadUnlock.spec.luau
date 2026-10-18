return function()
	local Map=require(game.ServerScriptService.Game.BattlefieldMap)
	local catalog=require(game.ReplicatedStorage.Shared.Civilizations)
	local container=Instance.new("Folder")
	container.Name="PadUnlockFixture"
	container.Parent=workspace
	local count=0
	local function test(name,callback) callback(); count+=1; print("PASS: "..name) end
	local ok,result=pcall(function()
		local world=Map.build(container)
		assert(type(world.syncControls)=="function","Dynamic floor pad sync is not implemented")
		local plot=world.model.Plots.Plot1
		local function state(level,weapon,armor,barracks)
			return {coins=1000,level=level,weaponLevel=weapon or 1,armorLevel=armor or 1,barracksLevel=barracks or 1,revision=0}
		end
		test("settlement expansion creates actual newly unlocked floor pads",function()
			world:setOwner(1,catalog[1],101,"UnlockTester",1)
			world:syncControls(1,state(1))
			for _,name in {"CoinButton","UpgradeButton"} do assert(plot.Controls:FindFirstChild(name)) end
			for _,name in {"WeaponButton","ArmorButton","Weapon3Button","Armor3Button","Weapon4Button","Armor4Button","Barracks2Button","Barracks3Button","Barracks4Button"} do
				assert(plot.Controls:FindFirstChild(name)==nil,"Future pad exists before its settlement unlock: "..name)
			end
			world:setOwner(1,catalog[1],101,"UnlockTester",2)
			world:syncControls(1,state(2))
			for _,name in {"WeaponButton","ArmorButton","Barracks2Button"} do
				local pad=plot.Controls:FindFirstChild(name)
				assert(pad and pad:IsA("BasePart") and pad:FindFirstChildOfClass("ClickDetector") and pad:FindFirstChildOfClass("ProximityPrompt"))
			end
			assert(plot.Controls:FindFirstChild("Weapon3Button")==nil and plot.Controls:FindFirstChild("Armor3Button")==nil)
			world:setOwner(1,catalog[1],101,"UnlockTester",3)
			world:syncControls(1,state(3))
			assert(plot.Controls:FindFirstChild("WeaponButton") and not plot.Controls:FindFirstChild("Weapon3Button"),"Settlement growth exposed an unpurchased intervening gear tier")
			world:syncControls(1,state(3,2,2,2))
			for _,name in {"Weapon3Button","Armor3Button","Barracks3Button"} do assert(plot.Controls:FindFirstChild(name)) end
			assert(plot.Controls:FindFirstChild("Weapon4Button")==nil and plot.Controls:FindFirstChild("Armor4Button")==nil and plot.Controls:FindFirstChild("Barracks4Button")==nil)
			world:setOwner(1,catalog[1],101,"UnlockTester",4)
			world:syncControls(1,state(4,3,3,3))
			assert(plot.Controls:FindFirstChild("Barracks4Button") and plot.Controls:FindFirstChild("Weapon4Button") and plot.Controls:FindFirstChild("Armor4Button"))
		end)
		test("purchased tier pads retire without replacing coin and settlement pads",function()
			local coin,settlement=plot.Controls.CoinButton,plot.Controls.UpgradeButton
			world:syncControls(1,state(4,2,2,2))
			assert(plot.Controls:FindFirstChild("WeaponButton")==nil and plot.Controls:FindFirstChild("ArmorButton")==nil)
			assert(plot.Controls:FindFirstChild("Barracks2Button")==nil)
			assert(plot.Controls.CoinButton==coin and plot.Controls.UpgradeButton==settlement)
			assert(plot.Controls:FindFirstChild("Weapon3Button") and plot.Controls:FindFirstChild("Barracks3Button"))
			world:syncControls(1,state(5,3,3,4))
			for _,name in {"Weapon3Button","Armor3Button","Barracks3Button","Barracks4Button"} do assert(plot.Controls:FindFirstChild(name)==nil) end
			local weapon,armor=plot.Controls.Weapon4Button,plot.Controls.Armor4Button
			world:syncControls(1,state(5,4,4,4))
			assert(plot.Controls.Weapon4Button==weapon and plot.Controls.Armor4Button==armor,"Higher gear purchase replaced its contact-latched physical pad")
			world:syncControls(1,state(6,5,5,4))
			assert(plot.Controls.Weapon4Button==weapon and plot.Controls.Armor4Button==armor,"Still-eligible repeated gear controls were replaced")
			world:syncControls(1,state(6,6,6,4))
			assert(not plot.Controls:FindFirstChild("Weapon4Button") and not plot.Controls:FindFirstChild("Armor4Button"),"Settlement-capped gear retained a purchase pad")
			world:syncControls(1,state(50,50,50,4))
			assert(not plot.Controls:FindFirstChild("Weapon4Button") and not plot.Controls:FindFirstChild("Armor4Button"),"Maximum gear retained a purchase pad")
			assert(plot.Controls.CoinButton==coin and not plot.Controls:FindFirstChild("UpgradeButton"))
		end)
		test("newly unlocked pads use the current moved and rotated foundation",function()
			world.model:PivotTo(CFrame.new(900,20,-1200)*CFrame.Angles(0,.7,0)*world.model:GetPivot())
			world:setOwner(1,catalog[1],101,"UnlockTester",50)
			world:syncControls(1,state(50))
			local expected={earn=true,testCoins=game:GetService("RunService"):IsStudio(),weapon=true,armor=true,barracks2=true,training=true,farm=true,blacksmith=true,armorer=true}
			for _,definition in require(game.ReplicatedStorage.Shared.PadCatalog).definitions do
				local pad=plot.Controls:FindFirstChild(definition.name)
				assert((pad~=nil)==(expected[definition.action]==true),"Moved-world pad eligibility mismatch: "..definition.action)
				if pad then
					local position=plot.Foundation.CFrame:PointToObjectSpace(pad.Position)
					assert((position-Vector3.new(definition.x,definition.y or 2,definition.z)).Magnitude<.01)
					if definition.action=="training" then
						assert(position.X+pad.Size.X/2< -128,"Training construction must stay outside the final foundation")
					elseif definition.action~="farm" then
						assert(math.abs(position.X)+pad.Size.X/2<=128 and math.abs(position.Z)+pad.Size.Z/2<=128)
					end
				end
			end
		end)
		return count
	end)
	container:Destroy()
	assert(ok,result)
	return result
end
