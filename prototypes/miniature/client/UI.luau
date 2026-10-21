--!strict
local Panels=require(script.Parent.PanelVisibility)
local UI={}
local function text(parent,name,value,y,height,size)
 local label=Instance.new('TextLabel');label.Name=name;label.Text=value;label.Position=UDim2.fromOffset(12,y)
 label.Size=UDim2.new(1,-24,0,height);label.BackgroundTransparency=1;label.TextColor3=Color3.fromRGB(244,235,213)
 label.Font=Enum.Font.Gotham;label.TextSize=size;label.TextWrapped=true;label.TextXAlignment=Enum.TextXAlignment.Left
 label.Parent=parent;return label
end
local function button(parent,name,value,position,size)
 local b=Instance.new('TextButton');b.Name=name;b.Text=value;b.Position=position;b.Size=size
 b.BackgroundColor3=Color3.fromRGB(92,105,75);b.TextColor3=Color3.fromRGB(255,244,214)
 b.Font=Enum.Font.GothamBold;b.TextSize=13;b.BorderSizePixel=0;b.Parent=parent;return b
end
function UI.mount(screen,camera)
 local header=Instance.new('Frame');header.Name='PreviewControls';header.BackgroundColor3=Color3.fromRGB(34,43,40)
 header.BackgroundTransparency=.08;header.BorderSizePixel=0;header.Parent=screen
 local title=text(header,'Title','MINIATURE SPARTA',8,24,16);title.Font=Enum.Font.GothamBold;title.Size=UDim2.new(1,-72,0,24)
 text(header,'Hint','Quarter scale · Unarmed commander\nSelect buildings to inspect. Scroll to zoom.',40,40,12)
 local walk=button(header,'Walk','Walk',UDim2.fromOffset(12,88),UDim2.new(.5,-18,0,44))
 local overview=button(header,'Overview','Overview',UDim2.new(.5,6,0,88),UDim2.new(.5,-18,0,44))
 walk.Activated:Connect(function()camera.walk()end);overview.Activated:Connect(camera.overview)
 local visibility=Panels.attach(screen,header,header,'Preview','preview');visibility:setVisible(true)
 local info=Instance.new('Frame');info.Name='BuildingInformation';info.BackgroundColor3=header.BackgroundColor3
 info.BackgroundTransparency=.05;info.BorderSizePixel=0;info.Parent=screen
 local name=text(info,'BuildingName','',8,28,15);name.Font=Enum.Font.GothamBold;name.Size=UDim2.new(1,-116,0,28)
 local description=text(info,'Description','',48,104,13)
 local close=button(info,'Close','X',UDim2.new(1,-48,0,4),UDim2.fromOffset(44,44))
 local infoVisibility=Panels.attach(screen,info,info,'Building','building')
 infoVisibility.button.Position=UDim2.new(1,-96,0,4)
 local highlight=Instance.new('Highlight');highlight.Name='InspectedBuilding';highlight.FillTransparency=.85
 highlight.FillColor=Color3.fromRGB(244,211,128);highlight.OutlineColor=highlight.FillColor;highlight.Enabled=false;highlight.Parent=workspace.CurrentCamera
 screen.Destroying:Once(function()highlight:Destroy()end)
 close.Activated:Connect(function()infoVisibility:setVisible(false);highlight.Enabled=false;screen:SetAttribute('InspectedBuilding',nil)end)
 local function layout()
  local size=screen.AbsoluteSize;local beside=size.Y<500 and size.X>=620
  local width=math.min(360,size.X-32)
  header.Position=UDim2.fromOffset(16,16);header.Size=UDim2.fromOffset(if beside then math.min(280,width)else width,140)
  info.AnchorPoint=if beside then Vector2.new(1,0)else Vector2.new(0,1)
  info.Position=if beside then UDim2.new(1,-16,0,16)else UDim2.new(0,16,1,-16)
  info.Size=UDim2.fromOffset(if beside then math.min(360,size.X-328)else width,if size.Y<500 then 164 else 184)
  description.Size=UDim2.new(1,-24,1,-60)
 end
 screen:GetPropertyChangedSignal('AbsoluteSize'):Connect(layout);layout()
 local controller={}
 function controller.inspect(building)
  name.Text=building:GetAttribute('DisplayName');description.Text=building:GetAttribute('Description')
  highlight.Adornee=building;highlight.Enabled=true
  infoVisibility:restore();infoVisibility:setVisible(true);screen:SetAttribute('InspectedBuilding',building.Name)
 end
 return controller
end
return UI
