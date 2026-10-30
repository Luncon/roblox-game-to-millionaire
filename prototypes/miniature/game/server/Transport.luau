--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Transport = {}

function Transport.start(options)
	assert(not ReplicatedStorage:FindFirstChild("MiniatureActions"), "Sandbox transport already exists")
	local folder = Instance.new("Folder")
	folder.Name = "MiniatureActions"
	local receipt = Instance.new("RemoteEvent")
	receipt.Name = "Receipt"
	receipt.Parent = folder
	local clients = {}
	local connections = {}
	local transport = {}

	function transport:send(player, result, requestId)
		if player.Parent == Players then
			receipt:FireClient(player, { snapshot = options.snapshot(player), result = result, requestId = requestId })
		end
	end

	function transport:remove(userId)
		clients[userId] = nil
	end

	local function budget(player, snapshot): boolean
		local now = os.clock()
		local client = clients[player.UserId]
		if not client then
			client = { tokens = 8, last = now, lastSnapshot = -math.huge }
			clients[player.UserId] = client
		end
		if snapshot then
			if now - client.lastSnapshot < 0.5 then
				return false
			end
			client.lastSnapshot = now
			return true
		end
		client.tokens = math.min(8, client.tokens + math.max(0, now - client.last) * 4)
		client.last = now
		if client.tokens < 1 then
			return false
		end
		client.tokens -= 1
		return true
	end

	local snapshot = Instance.new("RemoteEvent")
	snapshot.Name = "Snapshot"
	snapshot.Parent = folder
	table.insert(
		connections,
		snapshot.OnServerEvent:Connect(function(player)
			if budget(player, true) then
				transport:send(player)
			end
		end)
	)
	for _, action in options.actions do
		local remote = Instance.new("RemoteEvent")
		remote.Name = action
		remote.Parent = folder
		table.insert(
			connections,
			remote.OnServerEvent:Connect(function(player, intent)
				if budget(player, false) then
					local result = options.request(player, action, intent)
					local requestId = if type(intent) == "table"
							and type(intent.requestId) == "string"
							and #intent.requestId <= 64
						then intent.requestId
						else nil
					transport:send(player, result, requestId)
				end
			end)
		)
	end
	folder.Parent = ReplicatedStorage

	function transport:destroy()
		for _, connection in connections do
			connection:Disconnect()
		end
		table.clear(clients)
		folder:Destroy()
	end
	return transport
end

return Transport
