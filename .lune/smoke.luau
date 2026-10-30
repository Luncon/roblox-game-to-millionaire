--!strict
local fs = require("@lune/fs")
local luau = require("@lune/luau")

local function verify(directory: string): number
	local count = 0
	for _, name in fs.readDir(directory) do
		local file = directory .. "/" .. name
		if fs.isDir(file) then
			count += verify(file)
		elseif string.match(name, "%.luau$") or string.match(name, "%.lua$") then
			local ok, message = pcall(luau.compile, fs.readFile(file))
			assert(ok, file .. ": " .. tostring(message))
			count += 1
		end
	end
	return count
end

local count = 0
for _, directory in { "src", "tests", "prototypes/miniature", ".lune" } do
	count += verify(directory)
end
print(`Compiled {count} Luau files (syntax only; Studio checks still required)`)
