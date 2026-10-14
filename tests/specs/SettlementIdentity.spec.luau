return function()
	local Map = require(game.ServerScriptService.Game.BattlefieldMap)
	local catalog = require(game.ReplicatedStorage.Shared.Civilizations)
	local container = Instance.new("Folder")
	container.Name, container.Parent = "SettlementIdentityFixture", workspace
	local count = 0
	local function test(name, callback) callback(); count += 1; print("PASS: "..name) end
	local ok, result = pcall(function()
		local world = Map.build(container)
		world.model:PivotTo(CFrame.new(600,20,700)*CFrame.Angles(0,.8,0)*world.model:GetPivot())
		local plot = world.model.Plots.Plot1
		local function displays()
			return {plot.Settlement:FindFirstChild("CivilizationNameplate",true),
				plot.Settlement:FindFirstChild("CourtyardNameplate",true)}
		end
		test("every civilization and stage embeds identity on existing hall surfaces", function()
			local styles = {}
			for _, civ in catalog do
				for level=1,4 do
					world:setOwner(1,civ,101,"Commander_With_A_Long_Display_Name",level)
					assert(not plot:FindFirstChild("Sign"),"A freestanding identity board still blocks the settlement")
					local labels = displays()
					assert(#labels==2)
					for _, gui in labels do
						assert(gui:IsA("SurfaceGui") and gui.Parent:IsA("BasePart") and gui.Parent.Parent==plot.Settlement)
						assert(not gui.AlwaysOnTop,"Embedded identity renders through buildings")
						assert(gui:GetAttribute("CivilizationId")==civ.id and gui:GetAttribute("SettlementLevel")==level)
						assert(gui:GetAttribute("OwnerName")=="Commander_With_A_Long_Display_Name" and gui:GetAttribute("PlotId")==1)
						assert(gui.TextLabel.TextScaled and gui.TextLabel.TextWrapped)
						assert(string.find(gui.TextLabel.Text,civ.name,1,true))
					end
					assert(string.find(labels[1].TextLabel.Text,require(game.ReplicatedStorage.Shared.SettlementProgression)[level].name,1,true))
					local style = labels[1]:GetAttribute("Style")
					assert(type(style)=="string" and #style>0)
					if level==1 then assert(not styles[style],"Civilizations reuse the same identity theme"); styles[style]=true end
				end
			end
		end)
		test("rebuilding a settlement replaces both owner labels without stale identity", function()
			world:setOwner(1,catalog[1],101,"FirstOwner",2)
			local old = displays()
			world:setOwner(1,catalog[2],202,"SecondOwner",3)
			for _, gui in old do assert(not gui:IsDescendantOf(workspace)) end
			for _, gui in displays() do
				assert(string.find(gui.TextLabel.Text,"SecondOwner",1,true) and not string.find(gui.TextLabel.Text,"FirstOwner",1,true))
				assert(gui:GetAttribute("CivilizationId")==catalog[2].id)
			end
		end)
		test("longhouse nameplates fit beside their central support posts", function()
			for _, civ in catalog do
				if civ.id~="seneca" and civ.id~="vikings" then continue end
				world:setOwner(1,civ,101,"LonghouseCommander",4)
				for _, gui in displays() do
					local label, width = gui.TextLabel, gui.Parent.Size.X
					local left = (label.Position.X.Scale-label.Size.X.Scale/2-.5)*width
					local right = (label.Position.X.Scale+label.Size.X.Scale/2-.5)*width
					assert(left>=-width/2 and right<=width/2)
					assert(right< -1.05 or left>1.05,"The central two-stud support post covers the identity text")
				end
			end
		end)
		test("release removes building identity and restores a low unclaimed plot marker", function()
			world:setOwner(1,nil,nil,nil)
			assert(#plot.Settlement:GetChildren()==0)
			local marker = plot:FindFirstChild("Sign")
			assert(marker and string.find(marker.SurfaceGui.TextLabel.Text,"UNCLAIMED",1,true))
			local localPosition = plot.Foundation.CFrame:PointToObjectSpace(marker.Position)
			assert(localPosition.Y<4,"Unclaimed marker remains a tall blocking board")
			assert(plot.Controls.CoinButton and plot.Controls.UpgradeButton and #plot.Controls:GetChildren()==2)
		end)
		return count
	end)
	container:Destroy()
	assert(ok,result)
	return result
end
