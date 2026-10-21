-- Fingerprint original assets in Edit before starting the preview.
return function()
 local rows={}
 for _,folder in game.ServerStorage:GetChildren()do if folder.Name:match('Templates$')then
  for _,item in folder:GetDescendants()do
   local value=item:GetFullName()..':'..item.ClassName
   if item:IsA('BasePart')then value..=':'..tostring(item.Size)..':'..tostring(item.CFrame)
   elseif item:IsA('Model')then value..=':'..tostring(item:GetScale())end
   table.insert(rows,value)
  end
 end end
 table.sort(rows);local s=table.concat(rows,'\n');local hash=0
 for i=1,#s do hash=(hash+i*string.byte(s,i))%4294967296 end
 return tostring(#s)..':'..tostring(hash)
end
