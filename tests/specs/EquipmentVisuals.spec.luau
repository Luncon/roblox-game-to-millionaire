return function()
	local module=game.ServerScriptService.Game:FindFirstChild("EquipmentVisuals")
	assert(module,"Sanitized imported equipment visuals are not implemented")
	local Visuals=require(module)
	local count=0
	local owned={}
	local function keep(item) if item then table.insert(owned,item) end; return item end
	local function test(name,callback) callback(); count+=1; print("PASS: "..name) end
	local function nearFrame(actual,expected)
		assert((actual.Position-expected.Position).Magnitude<.002,"Imported visual offset changed")
		assert(actual.LookVector:Dot(expected.LookVector)>.9999 and actual.UpVector:Dot(expected.UpVector)>.9999,"Imported visual orientation changed")
	end
	local ok,result=pcall(function()
		local source=keep(Instance.new("Model")); source.Name="UnsafeEquipmentFixture"
		source:SetAttribute("Damage",99999); source:SetAttribute("WeaponLevel",50); source:SetAttribute("GeneratedBy","CivilizationEquipment")
		source:SetAttribute("TemplateId","forged-template")
		source:SetAttribute("Grip",CFrame.new(.1,.2,.3)*CFrame.Angles(.2,0,0))
		source:SetAttribute("HeadOffset",CFrame.new(0,.6,0))
		local handle=Instance.new("Part"); handle.Name="Handle"; handle.CFrame=CFrame.new(21,50,-15)*CFrame.Angles(.2,.5,.1)
		handle.Anchored=true; handle.Parent=source
		local nested=Instance.new("Model"); nested.Name="NestedVisual"; nested.Parent=source
		local blade=Instance.new("Part"); blade.Name="DecorativeBlade"; blade.Size=Vector3.new(.3,4,.5)
		blade.CFrame=handle.CFrame*CFrame.new(.4,2,-.6)*CFrame.Angles(.3,0,.2)
		blade.Color=Color3.fromRGB(201,155,66); blade.Material=Enum.Material.Metal; blade.Anchored=true; blade.Parent=nested
		blade:SetAttribute("OwnerId",999); blade:SetAttribute("Damage",99999)
		local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.Sphere; mesh.Scale=Vector3.new(.5,1,.7); mesh.Parent=blade
		local attachment=Instance.new("Attachment"); attachment.Name="HatAttachment"; attachment.CFrame=CFrame.new(0,.2,.3); attachment.Parent=handle
		local unsafe=Instance.new("Script"); unsafe.Name="ImportedScript"; unsafe.Disabled=true; unsafe.Parent=nested
		Instance.new("ModuleScript").Parent=nested
		Instance.new("Tool").Parent=nested
		Instance.new("RemoteEvent").Parent=nested
		Instance.new("BodyVelocity").Parent=blade
		Instance.new("ForceField").Parent=source
		local outside=keep(Instance.new("Part"))
		local reference=Instance.new("ObjectValue"); reference.Value=outside; reference.Parent=nested
		local unsafeJoint=Instance.new("Weld"); unsafeJoint.Part0=handle; unsafeJoint.Part1=outside; unsafeJoint.Parent=handle
		local force=Instance.new("VectorForce"); force.Attachment0=attachment; force.Parent=handle
		local beforeCount=#source:GetDescendants()
		local beforeHandle,beforeBlade=handle.CFrame,blade.CFrame
		local copied=nil
		test("import preparation strips executable content foreign references forces and gameplay attributes",function()
			copied=keep(Visuals.prepare(source))
			assert(copied and copied~=source and copied.Parent==nil and copied:IsA("Model"))
			local root=copied:FindFirstChild("Handle")
			assert(root and root:IsA("BasePart"),"Prepared visual needs a direct Handle")
			for _,item in copied:GetDescendants() do
				assert(not item:IsA("LuaSourceContainer") and not item:IsA("Tool") and not item:IsA("RemoteEvent")
					and not item:IsA("RemoteFunction") and not item:IsA("BodyMover") and not item:IsA("ForceField")
					and not item:IsA("ObjectValue") and not item:IsA("VectorForce"),"Unsafe imported descendant survived: "..item.ClassName)
				assert(item:GetAttribute("Damage")==nil and item:GetAttribute("OwnerId")==nil and item:GetAttribute("WeaponLevel")==nil)
				if item:IsA("BasePart") then
					assert(not item.Anchored and item.Massless and not item.CanCollide and not item.CanTouch and not item.CanQuery)
				end
				if item:IsA("JointInstance") or item:IsA("WeldConstraint") then
					assert(item.Part0 and item.Part1 and item.Part0:IsDescendantOf(copied) and item.Part1:IsDescendantOf(copied),"Imported joint escaped clone")
				end
			end
			assert(copied:GetAttribute("Damage")==nil and copied:GetAttribute("WeaponLevel")==nil and copied:GetAttribute("GeneratedBy")==nil)
			assert(copied:GetAttribute("TemplateId")~="forged-template","Imported authority metadata was trusted")
		end)
		test("nested imported geometry preserves appearance handle offsets and source without mutation",function()
			local copyHandle=copied.Handle
			local copyBlade=copied:FindFirstChild("DecorativeBlade",true)
			assert(copyBlade and copyBlade.Material==blade.Material and copyBlade.Color==blade.Color and copyBlade.Size==blade.Size)
			nearFrame(copyHandle.CFrame:ToObjectSpace(copyBlade.CFrame),beforeHandle:ToObjectSpace(beforeBlade))
			assert(copyBlade:FindFirstChildOfClass("SpecialMesh").Scale==mesh.Scale)
			nearFrame(copyHandle:FindFirstChild("HatAttachment").CFrame,attachment.CFrame)
			nearFrame(copied:GetAttribute("Grip"),source:GetAttribute("Grip"))
			nearFrame(copied:GetAttribute("HeadOffset"),source:GetAttribute("HeadOffset"))
			local attached=false
			for _,joint in copied:GetDescendants() do
				if joint:IsA("WeldConstraint") or joint:IsA("JointInstance") then
					if (joint.Part0==copyHandle and joint.Part1==copyBlade) or (joint.Part1==copyHandle and joint.Part0==copyBlade) then attached=true end
				end
			end
			assert(attached,"Nested visual must be rigidly attached to Handle")
			assert(#source:GetDescendants()==beforeCount and unsafe.Parent==nested and reference.Value==outside)
			assert(handle.Anchored and blade.Anchored and handle.CFrame==beforeHandle and blade.CFrame==beforeBlade)
			assert(source:GetAttribute("Damage")==99999 and blade:GetAttribute("OwnerId")==999)
		end)
		test("missing or invalid import handles fall back without affecting source assets",function()
			local invalid=keep(Instance.new("Model"))
			assert(Visuals.prepare(invalid)==nil)
			assert(Visuals.clone("missing-equipment-fixture")==nil)
			local fakeHandle=Instance.new("Folder"); fakeHandle.Name="Handle"; fakeHandle.Parent=invalid
			assert(Visuals.prepare(invalid)==nil and fakeHandle.Parent==invalid)
		end)
		test("all nineteen exported equipment sources produce distinct canonical clean clones",function()
			local sources=game.ServerStorage:FindFirstChild("EquipmentTemplates")
			assert(sources,"Imported equipment assets must be mapped into ServerStorage")
			for _,id in {"spartan-helmet","british-tricorn","seneca-headdress","egypt-pharaoh","egypt-anubis",
				"spartan-spear","spartan-shield","officer-sword","katana","spear","bow",
				"axe","scimitar","gladius","rapier","khopesh","musket","crossbow","slingshot"} do
				local original=sources:FindFirstChild(id)
				assert(original and original:IsA("Model"),"Missing exported equipment: "..id)
				local before=#original:GetDescendants(); local pivot=original:GetPivot()
				local first=keep(Visuals.clone(id)); local second=keep(Visuals.clone(id))
				assert(first and second and first~=second and first~=original and first.Parent==nil)
				assert(first:GetAttribute("TemplateId")==id and second:GetAttribute("TemplateId")==id)
				assert(first:FindFirstChild("Handle") and first:FindFirstChild("Handle"):IsA("BasePart"))
				for _,item in first:GetDescendants() do
					assert(not item:IsA("LuaSourceContainer") and not item:IsA("Tool"))
					if item:IsA("BasePart") then assert(not item.Anchored and item.Massless and not item.CanCollide and not item.CanTouch and not item.CanQuery) end
				end
				first.Handle.Color=Color3.new(1,0,1)
				assert(#original:GetDescendants()==before and original:GetPivot()==pivot,"Cloning mutated source equipment: "..id)
			end
		end)
		return count
	end)
	for _,item in owned do item:Destroy() end
	assert(ok,result)
	return result
end
