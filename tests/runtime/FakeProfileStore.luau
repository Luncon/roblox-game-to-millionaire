-- DataStore boundary fake: no DataStoreService calls or published data access.
-- Values are copied at the boundary; conflicting updates replay the transform.
local FakeProfileStore = {}
local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in value do result[copy(key)] = copy(child) end
	return result
end

function FakeProfileStore.new(initial)
	local values, versions, faults = copy(initial or {}), {}, {}
	local store = {isFakeProfileStore=true, attempts={}, commits={}, callbacks=0}
	function store:seed(key,value)
		values[key] = copy(value)
		versions[key] = (versions[key] or 0)+1
	end
	function store:read(key) return copy(values[key]) end
	function store:snapshot() return copy(values) end
	function store:dump() return self:snapshot() end
	function store:queue(fault) table.insert(faults,fault) end
	function store:gateNext()
		local event = Instance.new("BindableEvent")
		local gate = {entered=false,released=false}
		function gate:release()
			if self.released then return end
			self.released = true
			event:Fire()
		end
		self:queue({beforeCommit=function()
			gate.entered=true
			if not gate.released then event.Event:Wait() end
			event:Destroy()
		end})
		return gate
	end
	function store:UpdateAsync(key, transform)
		assert(type(key)=="string" and type(transform)=="function")
		local fault = table.remove(faults,1) or {}
		table.insert(self.attempts,{key=key,before=copy(values[key])})
		if fault.beforeError then error(fault.beforeError) end
		local version, candidate
		local function evaluate()
			version = versions[key] or 0
			self.callbacks += 1
			candidate = transform(copy(values[key]))
		end
		evaluate()
		for _=1,fault.replay or 0 do evaluate() end
		if fault.beforeCommit then fault.beforeCommit(key,copy(candidate)) end
		local conflicts=0
		while version~=(versions[key] or 0) do
			conflicts+=1
			assert(conflicts<=32,"Fake store update did not converge")
			evaluate()
		end
		if candidate == nil then return nil end
		values[key]=copy(candidate)
		versions[key]=(versions[key] or 0)+1
		table.insert(self.commits,{key=key,value=copy(candidate)})
		if fault.afterError then error(fault.afterError) end
		return copy(candidate)
	end
	return store
end

return FakeProfileStore
