--!strict

local Tracks = require(game:GetService("ReplicatedStorage").Shared.UpgradeTracks)
local Development = require(game:GetService("ReplicatedStorage").Shared.SettlementDevelopment)
local ProfileData = require(script.Parent.ProfileData)
local Formation = require(game.ReplicatedStorage.Shared.FormationConfig)
local Recruitment=require(game.ReplicatedStorage.Shared.ArmyRecruitment)
local Economy = {}
local BURST = 20
local REFILL = 15
local MAX_COINS = 1000000000

type Account = ProfileData.State & {
	revision: number, tokens: number, updatedAt: number, purchasedAt: { [string]: number }, farmUpdatedAt: number,
	testGrantedAt: number?,
}

function Economy.new(clock: (() -> number)?, canMutate: ((number) -> boolean)?, civilizationFor: ((number) -> string?)?, studioCheck: (() -> boolean)?)
	local now = clock or os.clock
	local studio=studioCheck or function()return game:GetService("RunService"):IsStudio()end
	local accounts: { [number]: Account } = {}
	local revisions: { [number]: number } = {}
	local economy = {}
	local function nextRevision(playerId: number): number
		local value = (revisions[playerId] or -1) + 1
		revisions[playerId] = value
		return value
	end

	function economy:get(playerId: number)
		local account = accounts[playerId]
		if not account then return nil end
		local state={revision=account.revision}
		for _,field in Development.persistentFields do state[field]=account[field] end
		return state
	end
	function economy:canMutate(playerId: number): boolean
		return accounts[playerId]~=nil and (canMutate==nil or canMutate(playerId))
	end

	function economy:open(playerId: number, initialState: any?)
		if not accounts[playerId] then
			local state = if initialState == nil then ProfileData.defaultState() else ProfileData.copyState(initialState,if civilizationFor then civilizationFor(playerId) else nil)
			if not state then return nil end
			local time=now()
			local account=table.clone(state)
			account.revision,account.tokens,account.updatedAt,account.purchasedAt=nextRevision(playerId),BURST,time,{}
			account.farmUpdatedAt=time
			accounts[playerId]=account
		end
		return self:get(playerId)
	end

	-- Switching imports progress without refilling this server session's input budgets.
	function economy:replace(playerId: number, initialState: any)
		local account = accounts[playerId]
		local state = ProfileData.copyState(initialState,if civilizationFor then civilizationFor(playerId) else nil)
		if not account or not state or (canMutate and not canMutate(playerId)) then return nil end
		for _, field in Development.persistentFields do
			account[field] = state[field]
		end
		account.revision = nextRevision(playerId)
		account.farmUpdatedAt=now()
		return self:get(playerId)
	end

	local function rejected(playerId: number, reason: string)
		return { ok = false, reason = reason, state = economy:get(playerId) }
	end
	local function accrue(account,time): number
		local capacity=Development.storageCapacity(account)
		if account.farmLevel==0 or account.farmCoins>=capacity then account.farmUpdatedAt=time;return 0 end
		local ticks=math.floor(math.max(0,time-account.farmUpdatedAt)/Development.tickSeconds)
		if ticks==0 then return 0 end
		local amount=math.min(capacity-account.farmCoins,ticks*Development.farmYield(account))
		account.farmCoins+=amount
		account.farmUpdatedAt=if account.farmCoins==capacity then time else account.farmUpdatedAt+ticks*Development.tickSeconds
		return amount
	end

	function economy:earn(playerId: number)
		local account = accounts[playerId]
		if not account then return rejected(playerId, "not_claimed") end
		if canMutate and not canMutate(playerId) then return rejected(playerId, "profile_unavailable") end
		local time = now()
		account.tokens = math.min(BURST, account.tokens + math.max(0, time - account.updatedAt) * REFILL)
		account.updatedAt = time
		if account.tokens < 1 then return rejected(playerId, "rate_limited") end
		if account.coins >= MAX_COINS then return rejected(playerId, "coin_limit") end
		account.tokens -= 1
		account.coins += 1
		account.revision = nextRevision(playerId)
		return { ok = true, state = self:get(playerId) }
	end

	-- Fixed testing amount, never exposed through a client currency remote.
	function economy:grantTestCoins(playerId: number)
		if not studio() then return rejected(playerId,"testing_disabled") end
		local account=accounts[playerId]
		if not account then return rejected(playerId,"not_claimed") end
		if not self:canMutate(playerId) then return rejected(playerId,"profile_unavailable") end
		local time=now()
		if account.testGrantedAt and time-account.testGrantedAt<.5 then return rejected(playerId,"rate_limited") end
		if account.coins>MAX_COINS-1000 then return rejected(playerId,"coin_limit") end
		account.testGrantedAt=time
		account.coins+=1000;account.revision=nextRevision(playerId)
		return {ok=true,amount=1000,state=self:get(playerId)}
	end

	function economy:upgrade(playerId: number, expectedLevel: unknown, kind: unknown)
		local account = accounts[playerId]
		if not account then return rejected(playerId, "not_claimed") end
		if canMutate and not canMutate(playerId) then return rejected(playerId, "profile_unavailable") end
		local trackId = if kind == nil then "settlement" else kind
		if type(trackId) ~= "string" or not Development.fields[trackId] then return rejected(playerId, "invalid") end
		local field = Development.fields[trackId]
		local currentLevel = account[field]
		local building=Development.buildings[trackId]
		local minimum=if building or trackId=="skill" then 0 else 1
		local maximum=if trackId=="skill" then 5 elseif building then building.maxLevel else #Tracks[trackId]
		if type(expectedLevel) ~= "number" or expectedLevel % 1 ~= 0
			or expectedLevel < minimum or expectedLevel > maximum then
			return rejected(playerId, "invalid")
		end
		if expectedLevel ~= currentLevel then return rejected(playerId, "stale_level") end
		local offer=Development.offer(account,trackId,if civilizationFor then civilizationFor(playerId) else nil)
		local cost = offer.cost
		if not cost then return rejected(playerId, "max_level") end
		local required = offer.requiredSettlement
		if account.level < required then return rejected(playerId, "settlement_locked") end
		if #offer.missing>0 then return rejected(playerId,"prerequisite") end
		local time = now()
		if account.purchasedAt[trackId] and time - account.purchasedAt[trackId] < .4 then
			return rejected(playerId, "rate_limited")
		end
		account.purchasedAt[trackId] = time
		if account.coins < cost then return rejected(playerId, "insufficient_funds") end
		-- No yielding between checking the price and committing both values.
		if trackId=="farm" or trackId=="workers" or trackId=="storehouse" then
			accrue(account,time)
			account.farmUpdatedAt=time
		end
		account.coins -= cost
		account[field] += 1
		account.revision = nextRevision(playerId)
		return { ok = true, state = self:get(playerId) }
	end

	function economy:farmStep(playerId: number)
		local account=accounts[playerId]
		if not account then return rejected(playerId,"not_claimed") end
		local time=now()
		if not self:canMutate(playerId) then account.farmUpdatedAt=time;return rejected(playerId,"profile_unavailable") end
		if account.farmLevel==0 then account.farmUpdatedAt=time;return rejected(playerId,"no_farm") end
		local amount=accrue(account,time)
		if amount>0 then account.revision=nextRevision(playerId) end
		return {ok=true,amount=amount,state=self:get(playerId)}
	end
	function economy:collectFarm(playerId: number)
		local account=accounts[playerId]
		if not account then return rejected(playerId,"not_claimed") end
		if not self:canMutate(playerId) then account.farmUpdatedAt=now();return rejected(playerId,"profile_unavailable") end
		if account.farmCoins==0 then return rejected(playerId,"empty_farm") end
		local amount=math.min(account.farmCoins,MAX_COINS-account.coins)
		if amount==0 then return rejected(playerId,"coin_limit") end
		if account.farmCoins==Development.storageCapacity(account) then account.farmUpdatedAt=now() end
		account.coins+=amount;account.farmCoins-=amount
		account.revision=nextRevision(playerId)
		return {ok=true,amount=amount,state=self:get(playerId)}
	end
	function economy:selectComposition(playerId: number,selection: unknown)
  local account=accounts[playerId]
  if not account then return rejected(playerId,'not_claimed')end
  if not self:canMutate(playerId)then return rejected(playerId,'profile_unavailable')end
  if account.level<2 or not Recruitment.valid(account,selection)then return rejected(playerId,'invalid_composition')end
  local time=now()
  if account.purchasedAt.troop and time-account.purchasedAt.troop<.4 then return rejected(playerId,'rate_limited')end
  account.purchasedAt.troop=time
  account.recruitMelee,account.recruitRanged,account.recruitMedic=selection.melee,selection.ranged,selection.medic
  account.revision=nextRevision(playerId)
  return {ok=true,state=self:get(playerId)}
 end
	function economy:selectTroop(playerId: number,kind: unknown)
		local account=accounts[playerId]
		if not account then return rejected(playerId,"not_claimed") end
		if not self:canMutate(playerId) then return rejected(playerId,"profile_unavailable") end
		if kind~="warrior" and kind~="ranged" then return rejected(playerId,"invalid") end
		if account.armyCampLevel<1 then return rejected(playerId,"prerequisite") end
		if kind==account.extraTroopClass then return {ok=true,state=self:get(playerId)} end
		local time=now()
		if account.purchasedAt.troop and time-account.purchasedAt.troop<.4 then return rejected(playerId,"rate_limited") end
		account.purchasedAt.troop=time
		account.extraTroopClass=kind
  -- Legacy internal callers return to the legacy automatic composition.
  account.recruitMelee,account.recruitRanged,account.recruitMedic=nil,nil,nil
		account.revision=nextRevision(playerId)
		return {ok=true,state=self:get(playerId)}
	end

 function economy:selectFormation(playerId: number,selection: unknown)
  local account=accounts[playerId]
  if not account then return rejected(playerId,"not_claimed") end
  if not self:canMutate(playerId) then return rejected(playerId,"profile_unavailable") end
  if selection~="none" and not Formation.byId[selection] then return rejected(playerId,"invalid") end
  if account.warCouncilLevel~=1 or (selection~="none" and (account.formationLevel~=1
   or not civilizationFor or Formation.byId[selection]~=Formation.forCivilization(civilizationFor(playerId)))) then return rejected(playerId,"prerequisite") end
  if account.selectedFormation==selection then return {ok=true,state=self:get(playerId)} end
  account.selectedFormation=selection
  account.revision=nextRevision(playerId)
  return {ok=true,state=self:get(playerId)}
 end

	-- Called only by server-validated lethal combat, independently of click tokens.
	function economy:rewardKill(playerId: number)
		local account = accounts[playerId]
		if not account then return rejected(playerId, "not_claimed") end
		if canMutate and not canMutate(playerId) then return rejected(playerId, "profile_unavailable") end
		if account.coins > MAX_COINS - 10 then return rejected(playerId, "coin_limit") end
		account.coins += 10
		account.revision = nextRevision(playerId)
		return {ok=true, amount=10, state=self:get(playerId)}
	end

	function economy:close(playerId: number)
		accounts[playerId] = nil
	end

	return economy
end

return Economy
