--!strict
-- Isolated visual gallery. Its pose-only gait has no Battle, damage or UI requests.
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
type Entry =
	{ civilizationId: string, name: string, animal: string, position: { number }, facilityPosition: { number } }
export type Gallery = {
	model: Model,
	sourceFolder: Folder,
	clientFolderName: string,
	entries: { Entry },
	destroy: () -> (),
}
local function caption(parent: BasePart, text: string, color: Color3, name: string)
	local gui = Instance.new("BillboardGui")
	gui.Name, gui.Size = name, UDim2.fromOffset(250, 44)
	gui.StudsOffsetWorldSpace, gui.AlwaysOnTop, gui.MaxDistance = Vector3.new(0, 1.1, 0), true, 180
	local label = Instance.new("TextLabel")
	label.Name, label.Size, label.BackgroundTransparency = "Text", UDim2.fromScale(1, 1), 1
	label.Font, label.TextSize, label.TextWrapped = Enum.Font.GothamMedium, 14, true
	label.Text, label.TextColor3, label.TextStrokeTransparency = text, color, 0.25
	label.Parent, gui.Parent = gui, parent
end
local function run(): Gallery
	assert(
		RunService:IsStudio() and Replicated:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore",
		"Wrong mounted gallery boundary"
	)
	local Server = game:GetService("ServerScriptService").Sandbox
	local Mounted = require(Server.MountedTroops)
	local Structures = require(Server.MountStructures)
	local Shared = Replicated.MiniatureGame
	local Civilizations = require(Shared.Civilizations)
	local Config = require(Shared.MountConfig)
	local Codec = require(Shared.PoseCodec)
	local Kinematics = require(Shared.RigKinematics)
	local existing = Workspace:FindFirstChild("NativeMountedGallery")
	if existing then
		assert(existing:GetAttribute("OwnedMountedGallery") == true, "Gallery name belongs to unrelated scenery")
		existing:Destroy()
	end
	local gallery = Instance.new("Model")
	gallery.Name = "NativeMountedGallery"
	gallery:SetAttribute("OwnedMountedGallery", true)
	local actors = Instance.new("Folder")
	actors.Name, actors.Parent = "Actors", gallery
	local facilities = Instance.new("Folder")
	facilities.Name, facilities.Parent = "Facilities", gallery
	local entries: { Entry } = {}
	local records = {}
	local stopped = false
	local connection: RBXScriptConnection? = nil
	local function destroy()
		if stopped then
			return
		end
		stopped = true
		if connection then
			connection:Disconnect()
			connection = nil
		end
		table.clear(records)
		gallery:Destroy()
	end
	gallery.Destroying:Connect(function()
		if connection then
			connection:Disconnect()
			connection = nil
		end
		stopped = true
		table.clear(records)
	end)
	gallery.Parent = Workspace
	local ok, failure = pcall(function()
		for index, civilization in Civilizations do
			local definition = Config.get(civilization.id)
			local column, row = (index - 1) % 4, math.floor((index - 1) / 4)
			local point = Vector3.new(450 + column * 18, 0, -450 + row * 18)
			local facility = Structures.create(civilization.id)
			facility.Name = civilization.id
			facility:PivotTo(CFrame.new(point))
			facility:SetAttribute("GalleryOnly", true)
			facility.Parent = facilities
			local labelAnchor = Instance.new("Part")
			labelAnchor.Name, labelAnchor.Size, labelAnchor.CFrame =
				"GalleryCaption", Vector3.one * 0.1, CFrame.new(point + Vector3.new(0, 4, -2))
			labelAnchor.Anchored, labelAnchor.CanCollide, labelAnchor.CanTouch, labelAnchor.CanQuery =
				true, false, false, false
			labelAnchor.Transparency, labelAnchor.Parent = 1, facility
			caption(
				labelAnchor,
				civilization.name .. " · " .. definition.structureName,
				civilization.color,
				"FacilityDisplay"
			)
			local position = point + Vector3.new(0, 0, 7)
			local actor =
				{ x = position.X, z = position.Z, headingX = 0, headingZ = -1, phase = "moving", moving = true }
			local rig = Mounted.create(civilization.id)
			rig.Name = "gallery:" .. civilization.id
			rig:SetAttribute("ActorId", rig.Name)
			rig:SetAttribute("Life", 1)
			rig:SetAttribute("Role", "mounted")
			rig:SetAttribute("Team", "gallery")
			rig:SetAttribute("CombatActor", false)
			rig:SetAttribute("PoseMovingOnly", true)
			rig:SetAttribute("GalleryOnly", true)
			Mounted.pose(rig, actor, os.clock())
			local kin = Kinematics.new(rig)
			assert(kin and kin.mount, "Gallery animal anatomy is incomplete")
			local head = rig:FindFirstChild("Head")
			assert(head and head:IsA("BasePart"), "Gallery original rider has no head")
			caption(
				head,
				civilization.name .. " · " .. definition.animal .. " rider",
				Color3.fromRGB(245, 233, 204),
				"HealthDisplay"
			)
			rig.Parent = actors
			table.insert(records, { rig = rig, kin = kin })
			table.insert(entries, {
				civilizationId = civilization.id,
				name = civilization.name,
				animal = definition.animal,
				position = { position.X, position.Y, position.Z },
				facilityPosition = { point.X, point.Y, point.Z },
			})
			task.wait()
		end
	end)
	if not ok then
		destroy()
		error(failure)
	end
	local elapsed = 0
	connection = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.1 or stopped then
			return
		end
		elapsed = 0
		for _, record in records do
			local packet = Codec.decode(record.rig:GetAttribute("PoseSnapshot"))
			if packet then
				-- Explicit pose-only treadmill. The real actor root never travels and
				-- this folder is never registered with Battle or any troop service.
				packet.speed = 9
				packet.time = Workspace:GetServerTimeNow()
				Kinematics.apply(record.kin, packet, { actors })
				local root = record.rig:FindFirstChild("HumanoidRootPart")
				if root and root:IsA("BasePart") then
					packet.root = root.CFrame
				end
				record.rig:SetAttribute("PoseSnapshot", Codec.encode(packet))
			end
		end
	end)
	return {
		model = gallery,
		sourceFolder = actors,
		clientFolderName = "MiniatureClientActors_Actors",
		entries = entries,
		destroy = destroy,
	}
end
return run
