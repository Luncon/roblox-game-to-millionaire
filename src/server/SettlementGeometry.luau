--!strict

local Geometry={surfaceY=1}
local PITCH=.4

local function piece(parent,name,size,frame,color,material,solid,wedge)
	local object=Instance.new(if wedge then "WedgePart" else "Part")
	object.Name,object.Size,object.CFrame=name,size,frame
	object.Color,object.Material=color,material
	object.Anchored,object.CanCollide=true,solid==true
	object.CanTouch,object.CanQuery=false,solid==true
	object.TopSurface,object.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
	object.Parent=parent
	return object
end

-- Width preserves the callers' nominal ridge spacing; depth is the complete
-- panel depth. The minimum length also covers wide walls at the lower face.
function Geometry.pitchedRoof(parent,frame,shape,appearance)
	local cosine,slope=math.cos(PITCH),math.tan(PITCH)
	local centerX=shape.width/4
	local thickness=shape.thickness or 1
	local height=shape.wallWidth/2*slope
	local centerY=shape.wallTop+slope*(shape.wallWidth/2-centerX)+thickness/(2*cosine)
	-- Cover both the outer wall's lower-face contact and the inner ridge's
	-- upper face; wide roofs otherwise leave a narrow gap between panels.
	local outerCoverage=2*((shape.wallWidth/2-centerX)/cosine+thickness*slope/2)+.02
	local ridgeCoverage=2*(centerX/cosine+thickness*slope/2)+.02
	local panelWidth=math.max(shape.width/2+(shape.overhang or 1),outerCoverage,ridgeCoverage)
	for _,side in {-1,1} do
		piece(parent,"RoofSlope",Vector3.new(panelWidth,thickness,shape.depth),
			frame*CFrame.new(side*centerX,centerY,0)*CFrame.Angles(0,0,-side*PITCH),
			appearance.roofColor,Enum.Material.WoodPlanks,appearance.solid,false)
		piece(parent,"RoofGable",Vector3.new(shape.wallDepth,height,shape.wallWidth/2),
			frame*CFrame.new(side*shape.wallWidth/4,shape.wallTop+height/2,0)*CFrame.Angles(0,-side*math.pi/2,0),
			appearance.wallColor,appearance.wallMaterial or Enum.Material.Sandstone,appearance.solid,true)
	end
	return {centerY=centerY,ridgeY=shape.wallTop+height+thickness/cosine,
		slope=slope,wallTop=shape.wallTop,wallWidth=shape.wallWidth,thickness=thickness}
end

function Geometry.roofY(profile,x: number): number
	return profile.ridgeY-profile.slope*math.abs(x)
end

return table.freeze(Geometry)
