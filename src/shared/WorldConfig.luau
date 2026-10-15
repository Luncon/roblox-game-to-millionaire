--!strict

local Progression = require(script.Parent.SettlementProgression)
local maxPlotSize = Progression[#Progression].size
local plotCount = 8
-- Conservative bounding circles leave room even for rotated square capitals.
local plotRadius = math.ceil((maxPlotSize*math.sqrt(2)+64)/(2*math.sin(math.pi/plotCount))/20)*20
local arenaRadius = math.floor(plotRadius*.45/10)*10
local groundSize = math.ceil(2*(plotRadius+maxPlotSize/math.sqrt(2)+56)/100)*100
local Config = {
	plotCount = plotCount,
	plotRadius = plotRadius,
	maxPlotSize = maxPlotSize,
	arenaRadius = arenaRadius,
	groundSize = groundSize,
	laneWidth = 28,
}
function Config.plotFrame(plotId: number): CFrame
	local angle = (plotId-1)*2*math.pi/plotCount
	local position = Vector3.new(math.sin(angle)*plotRadius,1,math.cos(angle)*plotRadius)
	return CFrame.lookAt(position,Vector3.new(0,1,0))
end
return table.freeze(Config)
