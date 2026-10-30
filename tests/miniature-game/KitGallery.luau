--!strict
-- Edit-only visual evidence. Creates original factory outputs in one owned model.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Shared = ReplicatedStorage.MiniatureGame
local Presentation = require(Shared.Presentation)
local Civilizations = require(Shared.Civilizations)
local modules = {
	sparta = "SpartanKit",
	rome = "RomanKit",
	persia = "PersianKit",
	egypt = "EgyptianKit",
	maurya = "MauryanKit",
	seneca = "SenecaKit",
	vikings = "VikingKit",
	mongols = "MongolKit",
	japan = "JapaneseKit",
	ming = "MingKit",
	ottomans = "OttomanKit",
	spain = "SpanishKit",
	britain = "BritishKit",
}
local order = { "civic", "house", "farm", "timber", "material", "workshop", "storehouse", "training", "healer" }
local galleryName, owner = "MiniatureKitEvidenceGallery", "MiniatureKitGallery.v1"

local function inertPart(parent, name, size, point, color)
	local object = Instance.new("Part")
	object.Name, object.Size, object.CFrame = name, size, CFrame.new(point)
	object.Anchored = true
	object.CanCollide = false
	object.CanTouch = false
	object.CanQuery = false
	object.Color, object.Material = color, Enum.Material.SmoothPlastic
	object.TopSurface, object.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	object.Parent = parent
	return object
end

local function label(parent, text, point, title)
	local anchor = inertPart(parent, "EvidenceLabelAnchor", Vector3.new(0.1, 0.1, 0.1), point, Color3.new(1, 1, 1))
	anchor.Transparency = 1
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "EvidenceLabel"
	billboard.Adornee = anchor
	billboard.Size = UDim2.fromOffset(if title then 680 else 200, if title then 72 else 48)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 300
	billboard.Parent = anchor
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Caption"
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundColor3 = Color3.fromRGB(240, 235, 218)
	textLabel.BackgroundTransparency = 0.08
	textLabel.TextColor3 = Color3.fromRGB(37, 43, 38)
	textLabel.Text = text
	textLabel.Font = Enum.Font.GothamMedium
	textLabel.TextSize = if title then 19 else 13
	textLabel.TextWrapped = true
	textLabel.BorderSizePixel = 0
	textLabel.Parent = billboard
	local border = Instance.new("UIStroke")
	border.Color, border.Transparency, border.Thickness = Color3.fromRGB(88, 95, 81), 0.3, 1
	border.Parent = textLabel
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft, padding.PaddingRight = UDim.new(0, 5), UDim.new(0, 5)
	padding.Parent = textLabel
end

local function inspect(model, civilizationId)
	assert(model:GetAttribute("CivilizationId") == civilizationId, "Gallery factory returned foreign art")
	assert(math.abs(model:GetScale() - 0.25) < 0.001, "Gallery factory changed miniature scale")
	local count = 0
	for _, item in model:GetDescendants() do
		assert(
			not item:IsA("LuaSourceContainer") and not item:IsA("Tool") and not item:IsA("Humanoid"),
			"Gallery art contains behavior"
		)
		assert(not item:IsA("ClickDetector") and not item:IsA("ProximityPrompt"), "Gallery art contains interactions")
		if item:IsA("BasePart") then
			assert(
				item.Anchored and not item.CanCollide and not item.CanTouch and not item.CanQuery,
				"Gallery art is active: " .. item:GetFullName()
			)
			count += 1
		end
	end
	return count
end

return function(civilizationId: string)
	assert(RunService:IsStudio() and not RunService:IsRunning(), "Stop Play before creating the Edit gallery")
	local moduleName = modules[civilizationId]
	assert(moduleName, "Unknown gallery civilization")
	local civilization
	for _, entry in Civilizations do
		if entry.id == civilizationId then
			civilization = entry
			break
		end
	end
	assert(civilization, "Gallery civilization metadata is missing")
	local kit = require(ServerScriptService.Sandbox[moduleName])
	for _, previous in Workspace:GetChildren() do
		if previous.Name == galleryName and previous:GetAttribute("GalleryOwner") == owner then
			previous:Destroy()
		end
	end
	local gallery = Instance.new("Model")
	gallery.Name = galleryName
	gallery:SetAttribute("GalleryOwner", owner)
	gallery:SetAttribute("CivilizationId", civilizationId)
	gallery:SetAttribute("EvidenceOnly", true)
	gallery.Parent = Workspace
	local ok, result = pcall(function()
		inertPart(
			gallery,
			"GalleryFloor",
			Vector3.new(43, 0.3, 60),
			Vector3.new(0, -0.15, 3),
			Color3.fromRGB(160, 169, 153)
		)
		label(
			gallery,
			civilization.name
				.. " · "
				.. civilization.period
				.. "\nQuarter-scale buildings and passive role candidates",
			Vector3.new(0, 5.5, -23),
			true
		)
		local buildingParts, actorParts = 0, 0
		for index, kind in order do
			local x, z = ((index - 1) % 3 - 1) * 12, (math.floor((index - 1) / 3) - 1) * 12
			inertPart(
				gallery,
				"BuildingPlinth_" .. kind,
				Vector3.new(10.5, 0.12, 10.5),
				Vector3.new(x, 0.06, z),
				Color3.fromRGB(191, 196, 177)
			)
			assert(kit.available(kind), "Gallery building role is missing: " .. kind)
			local model = kit.create(kind)
			model.Name = string.format("%02d_%s", index, kind)
			model.Parent = gallery
			buildingParts += inspect(model, civilizationId)
			model:PivotTo(CFrame.new(x, 0.12, z))
			label(
				gallery,
				string.format(
					"%02d  %s\n%s · %s",
					index,
					Presentation.buildingName(civilizationId, kind),
					civilization.name,
					kind
				),
				Vector3.new(x, 0.4, z + 5.3),
				false
			)
			-- Flush one model at a time for the native Edit bridge and viewport.
			task.wait()
		end
		for index, role in { "melee", "ranged", "medic" } do
			local x = (index - 2) * 8
			local actor = kit.createActor(role)
			actor.Name = "Role_" .. role
			actor.Parent = gallery
			actorParts += inspect(actor, civilizationId)
			actor:PivotTo(CFrame.new(x, 0.12, 24) * CFrame.Angles(0, math.pi, 0))
			label(
				gallery,
				Presentation.roleName(civilizationId, role) .. "\n" .. civilization.name .. " · " .. role,
				Vector3.new(x, 0.4, 26.2),
				false
			)
			task.wait()
		end
		local partCount = 0
		for _, item in gallery:GetDescendants() do
			if item:IsA("BasePart") then
				partCount += 1
			end
		end
		gallery:SetAttribute("BuildingCount", #order)
		gallery:SetAttribute("ActorCount", 3)
		gallery:SetAttribute("PartCount", partCount)
		return {
			gallery = galleryName,
			civilizationId = civilizationId,
			buildings = #order,
			actors = 3,
			buildingParts = buildingParts,
			actorParts = actorParts,
			partCount = partCount,
			cameraPosition = { 24, 34, 42 },
			lookAt = { 0, 2, 2 },
			fieldOfView = 50,
			views = {
				front = { cameraPosition = { 0, 23, 55 }, lookAt = { 0, 2, 2 } },
				side = { cameraPosition = { 48, 27, 4 }, lookAt = { 0, 2, 2 } },
				roles = { cameraPosition = { 0, 4.5, 35 }, lookAt = { 0, 1.2, 24 } },
			},
		}
	end)
	if not ok then
		gallery:Destroy()
		error(tostring(result), 0)
	end
	return result
end
