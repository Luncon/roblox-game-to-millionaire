--!strict

local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local Visuals = {}
local warned = {}
local allowed = {
	Part=true, MeshPart=true, WedgePart=true, CornerWedgePart=true,
	UnionOperation=true, Folder=true, Model=true, Attachment=true, Bone=true,
	SpecialMesh=true, BlockMesh=true, CylinderMesh=true,
	Decal=true, Texture=true, SurfaceAppearance=true,
}

local function validFrame(value): boolean
	if typeof(value)~="CFrame" then return false end
	for _,component in {value:GetComponents()} do
		if component~=component or math.abs(component)>1e7 then return false end
	end
	return true
end
local function clean(instance: Instance)
	for name in instance:GetAttributes() do instance:SetAttribute(name,nil) end
	for _,tag in CollectionService:GetTags(instance) do CollectionService:RemoveTag(instance,tag) end
end

-- Clone only inert visual classes; no imported behavior or authority crosses
-- this boundary. Originals remain untouched, including their attachment data.
function Visuals.prepare(template: Model): Model?
	if not template:IsA("Model") then return nil end
	local originalHandle=template:FindFirstChild("Handle")
	if not originalHandle or not originalHandle:IsA("BasePart") or not validFrame(originalHandle.CFrame) then return nil end
	local output=Instance.new("Model")
	output.Name=template.Name
	local count=0
	local failed=false
	local function copyChildren(source: Instance,parent: Instance)
		for _,child in source:GetChildren() do
			if not allowed[child.ClassName] then continue end
			if child:IsA("BasePart") then
				count+=1
				if count>256 or not validFrame(child.CFrame) or child.Size.Magnitude>128
					or (originalHandle.CFrame:PointToObjectSpace(child.Position)).Magnitude>64 then failed=true;return end
			end
			local clone=child:Clone()
			if not clone then continue end
			clone:ClearAllChildren()
			clean(clone)
			if clone:IsA("Model") then clone.PrimaryPart=nil end
			if clone:IsA("BasePart") then
				clone.CFrame=originalHandle.CFrame:ToObjectSpace(child.CFrame)
				clone.Anchored,clone.Massless=true,true
				clone.CanCollide,clone.CanTouch,clone.CanQuery=false,false,false
				clone.AssemblyLinearVelocity,clone.AssemblyAngularVelocity=Vector3.zero,Vector3.zero
			end
			clone.Parent=parent
			copyChildren(child,clone)
			if failed then return end
		end
	end
	copyChildren(template,output)
	local handle=output:FindFirstChild("Handle")
	if failed or not handle or not handle:IsA("BasePart") then output:Destroy();return nil end
	output.PrimaryPart=handle
	for _,key in {"Grip","HeadOffset"} do
		local value=template:GetAttribute(key)
		if validFrame(value) and value.Position.Magnitude<=20 then output:SetAttribute(key,value) end
	end
	for _,child in output:GetDescendants() do
		if child:IsA("BasePart") then
			child.Anchored=false
			if child~=handle then
				local weld=Instance.new("WeldConstraint")
				weld.Name,weld.Part0,weld.Part1,weld.Parent="VisualWeld",handle,child,child
			end
		end
	end
	return output
end

function Visuals.clone(id: string): Model?
	local folder=ServerStorage:FindFirstChild("EquipmentTemplates")
	local template=if folder then folder:FindFirstChild(id) else nil
	local clone=if template and template:IsA("Model") then Visuals.prepare(template) else nil
	if clone then
		clone:SetAttribute("TemplateId",id)
	elseif not warned[id] then
		warned[id]=true
		warn("Equipment visual unavailable; using procedural equipment: "..id)
	end
	return clone
end

return Visuals
