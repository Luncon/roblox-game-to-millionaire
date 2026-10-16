-- Minimal explicit test doubles for standalone logic checks, never Studio physics.
local Vector3={}
local mt={}
function Vector3.new(x,y,z)return setmetatable({X=x or 0,Y=y or 0,Z=z or 0,_type="Vector3"},mt)end
function mt.__index(v,key)
	if key=="Magnitude" then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z)end
	if key=="Unit" then return v/v.Magnitude end
	if key=="Dot" then return function(a,b)return a.X*b.X+a.Y*b.Y+a.Z*b.Z end end
	if key=="Lerp" then return function(a,b,t)return a+(b-a)*t end end
end
function mt.__add(a,b)return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
function mt.__sub(a,b)return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
function mt.__mul(a,b)if type(a)=="number" then a,b=b,a end;return Vector3.new(a.X*b,a.Y*b,a.Z*b)end
function mt.__div(a,b)return Vector3.new(a.X/b,a.Y/b,a.Z/b)end
function mt.__unm(a)return Vector3.new(-a.X,-a.Y,-a.Z)end
Vector3.zero=Vector3.new(0,0,0)
local CFrame={}
function CFrame.new(x,y,z)
	local position=if type(x)=="table" then x else Vector3.new(x,y,z)
	return {Position=position,LookVector=Vector3.new(0,0,-1)}
end
function CFrame.lookAt(origin,target)return {Position=origin,LookVector=(target-origin).Unit}end
local Enum={HumanoidRigType={R6="R6",R15="R15"},RaycastFilterType={Exclude="Exclude"}}
local Instance={}
function Instance.new(class)
	assert(class=="BindableEvent","Standalone tests do not implement "..class)
	return {Fire=function()end,Destroy=function()end,Event={Wait=function()error("Concurrency requires Studio")end}}
end
return {Instance=Instance,Vector3=Vector3,CFrame=CFrame,Enum=Enum,Color3={fromRGB=function(r,g,b)return {r,g,b}end},
	RaycastParams={new=function()return {}end}}
