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
				for _,level in {1,2,4,10,25,40,50} do
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
			local studio=game:GetService('RunService'):IsStudio()
			assert(plot.Controls.CoinButton and plot.Controls.UpgradeButton and #plot.Controls:GetChildren()==(if studio then 3 else 2))
			assert((plot.Controls:FindFirstChild('TestCoinButton')~=nil)==studio)
			for _,name in {"BuildFrame","BuildOwnerName","BuildPlotId","BuiltLevel","Architecture","GrowthFeatureCount"} do
				assert(plot.Settlement:GetAttribute(name)==nil,"Release retained stale builder metadata: "..name)
			end
		end)
		test("grand identity panels physically clear civilization roofs columns posts and ornaments",function()
			local function bounds(part)
				local minimum,maximum=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
				for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
					local point=plot.Foundation.CFrame:PointToObjectSpace(part.CFrame:PointToWorldSpace(part.Size*Vector3.new(x,y,z)/2))
					minimum=minimum:Min(point);maximum=maximum:Max(point)
				end end end
				return minimum,maximum
			end
			for _,civ in catalog do
				for _,level in {30,50} do
					world:setOwner(1,civ,101,"GrandFacadeCommander",level)
					local host=plot.Settlement:FindFirstChild("GrandIdentityHost")
					assert(host and host:GetAttribute("IntegratedFacade") and displays()[1].Parent==host)
					local left,right=bounds(host)
					local grand=plot.Settlement.GrowthFeature_30:FindFirstChildWhichIsA("Model")
					assert(grand,"Grand civic building is missing")
					local checked=0
					local roofCorners=0
					for _,obstacle in grand:GetChildren() do
						if not obstacle:IsA("BasePart") then continue end
						local a,b=bounds(obstacle)
						if obstacle.Name=="RoofSlope" and (civ.id=="seneca" or civ.id=="vikings") then
							for _,x in {-1,1} do for _,y in {-1,1} do
								local point=obstacle.CFrame:PointToObjectSpace(host.CFrame:PointToWorldSpace(Vector3.new(x*host.Size.X/2,y*host.Size.Y/2,-host.Size.Z/2)))
								if math.abs(point.X)<=obstacle.Size.X/2 and math.abs(point.Z)<=obstacle.Size.Z/2 then
									assert(point.Y< -obstacle.Size.Y/2-.01,civ.id.." physical grand plaque reaches into the pitched roof underside")
									roofCorners+=1
								end
							end end
						elseif obstacle.Name=="WovenRoof" or obstacle.Name=="OverhangingRoof" or obstacle.Name=="CivicArchHeader" then
							assert(right.Y<a.Y-.01,civ.id.." grand identity reaches into "..obstacle.Name);checked+=1
						elseif obstacle.Name=="Column" or obstacle.Name=="WhiteSashWindow" or obstacle.Name=="ArcadePier" then
							assert(right.X<a.X-.01 or left.X>b.X+.01,civ.id.." grand identity overlaps "..obstacle.Name);checked+=1
						elseif obstacle.Name=="CarvedEndPost" or obstacle.Name=="RoundShield" or obstacle.Name=="WovenWallPanel" then
							assert(right.X<-.01,"Longhouse grand identity is outside its negative side bay")
							assert(right.X<a.X-.01 or left.X>b.X+.01,civ.id.." grand identity overlaps "..obstacle.Name);checked+=1
						end
					end
					if civ.id=="seneca" or civ.id=="vikings" then assert(roofCorners>=4,"Pitched-roof regression did not exercise plaque corners beneath the roof") end
					if civ.id~="maurya" and civ.id~="ottomans" and civ.id~="egypt" then assert(checked>0,"Facade obstruction fixture checked no obstacles") end
				end
			end
		end)
		return count
	end)
	container:Destroy()
	assert(ok,result)
	return result
end
