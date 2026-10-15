--!strict

local TroopAppearance = {}

-- Fictional character art defaults, not a claim about every historical person.
TroopAppearance.skinColors = table.freeze({
	sparta = Color3.fromRGB(196,151,112),
	britain = Color3.fromRGB(235,198,172),
	seneca = Color3.fromRGB(174,116,78),
	mongols = Color3.fromRGB(204,164,122),
	vikings = Color3.fromRGB(240,210,190),
	persia = Color3.fromRGB(186,137,93),
	japan = Color3.fromRGB(222,185,143),
	maurya = Color3.fromRGB(137,91,59),
	spain = Color3.fromRGB(211,166,124),
	egypt = Color3.fromRGB(158,106,65),
	rome = Color3.fromRGB(199,157,115),
	ottomans = Color3.fromRGB(194,148,104),
	ming = Color3.fromRGB(216,178,131),
})
-- Angry expression already supplied on the user's Seneca melee model.
TroopAppearance.faceTexture = "rbxassetid://10526794"

local bodyColors = {
	Head="HeadColor3", Torso="TorsoColor3",
	["Left Arm"]="LeftArmColor3", ["Right Arm"]="RightArmColor3",
	["Left Leg"]="LeftLegColor3", ["Right Leg"]="RightLegColor3",
}

function TroopAppearance.apply(rig: Model, civilizationId: string)
	local skin = TroopAppearance.skinColors[civilizationId]
	assert(skin, "Unknown troop appearance civilization")
	local palette = rig:FindFirstChildOfClass("BodyColors") or Instance.new("BodyColors")
	for name, property in bodyColors do
		palette[property] = skin
		local part = rig:FindFirstChild(name)
		if part and part:IsA("BasePart") then part.Color = skin end
	end
	palette.Parent = rig

	local head = rig:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then return end
	local face: Decal? = nil
	for _, item in head:GetChildren() do
		if item:IsA("Decal") and item.Face == Enum.NormalId.Front then
			if face then item:Destroy() else face = item end
		end
	end
	local decal = face or Instance.new("Decal")
	decal.Name, decal.Face, decal.Texture = "face", Enum.NormalId.Front, TroopAppearance.faceTexture
	decal.Color3, decal.Transparency = Color3.new(1,1,1), 0
	decal.Parent = head
end

return table.freeze(TroopAppearance)
