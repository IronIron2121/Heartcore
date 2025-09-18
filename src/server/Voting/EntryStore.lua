-- EntryStore.lua
-- Per-entry DataStore + in-memory cache + batching (flush every FLUSH_INTERVAL_SECONDS).
-- Keys:
--   ContestEntry_<entryId> -> { userId, userName, outfit, wins, views, theme }
--   ContestEntriesList_v1  -> { entryId, ... }

local DataStoreService = game:GetService("DataStoreService")
local ContestStore = DataStoreService:GetDataStore("OutfitContest_v1")

local EntryStore = {}
EntryStore._cache = {}        -- [entryId] = record
EntryStore._pending = {}      -- [entryId] = { addWins, addViews }
EntryStore._entryListKey = "ContestEntriesList_v1"
EntryStore._entryIds = {}
EntryStore.FLUSH_INTERVAL_SECONDS = 1
EntryStore._runningFlush = false

function EntryStore:LoadEntryIds()
	local success, ids = pcall(function() 
		return ContestStore:GetAsync(self._entryListKey) 
	end)

	self._entryIds = (success and type(ids) == "table") and ids or {}
end

function EntryStore:_addEntryId(entryId)
	pcall(function()
		ContestStore:UpdateAsync(self._entryListKey, function(old)
			local list = old or {}
			for _, v in ipairs(list) do if v == entryId then return list end end
			table.insert(list, entryId); return list
		end)
	end)
end

function EntryStore:SubmitEntry(entryId, userName, serializedOutfit, themeId)
	local key = "ContestEntry_"..entryId
	local ok, err = pcall(function()
		ContestStore:SetAsync(key, {
			userId = entryId, userName = userName, outfit = serializedOutfit,
			wins = 0, views = 0, theme = themeId
		})
	end)
	if not ok then return false, err end
	self._cache[entryId] = { userId=entryId, userName=userName, outfit=serializedOutfit, wins=0, views=0, theme=themeId }
	self:_addEntryId(entryId)
	return true
end

function EntryStore:Init(preload)
	self:LoadEntryIds()
	if preload then
		for _, id in ipairs(self._entryIds) do
			local ok, data = pcall(function() return ContestStore:GetAsync("ContestEntry_"..id) end)
			if ok and data then
				self._cache[id] = {
					userId=data.userId, userName=data.userName, outfit=data.outfit,
					wins=data.wins or 0, views=data.views or 0, theme=data.theme
				}
			end
			task.wait(0.02)
		end
	end
	if not self._runningFlush then
		self._runningFlush = true
		task.spawn(function()
			while true do
				task.wait(self.FLUSH_INTERVAL_SECONDS)
				self:_flushPending()
			end
		end)
	end
end

function EntryStore:QueueIncrement(entryId, addWins, addViews)
	local p = self._pending[entryId]
	if not p then p = { addWins=0, addViews=0 }; self._pending[entryId] = p end
	p.addWins += (addWins or 0)
	p.addViews += (addViews or 0)
	local c = self._cache[entryId]
	if c then
		c.wins = (c.wins or 0) + (addWins or 0)
		c.views = (c.views or 0) + (addViews or 0)
	end
end

function EntryStore:IncrementViewsBatch(ids)
	for _, id in ipairs(ids) do self:QueueIncrement(id, 0, 1) end
end

function EntryStore:RecordWins(ids)
	for _, id in ipairs(ids) do self:QueueIncrement(id, 1, 0) end
end

function EntryStore:GetCachedEntries() return self._cache end

function EntryStore:GetAllFromDataStore()
	local results = {}
	local ok, ids = pcall(function() return ContestStore:GetAsync(self._entryListKey) end)
	local list = (ok and type(ids) == "table") and ids or self._entryIds or {}
	for _, id in ipairs(list) do
		local lok, data = pcall(function() return ContestStore:GetAsync("ContestEntry_"..id) end)
		if lok and data then
			results[id] = {
				userId=data.userId, userName=data.userName, outfit=data.outfit,
				wins=data.wins or 0, views=data.views or 0, theme=data.theme
			}
		else
			warn("EntryStore:GetAllFromDataStore failed for", id)
		end
		task.wait(0.03)
	end
	return results
end

function EntryStore:_flushPending()
	if next(self._pending) == nil then return end
	local toFlush = self._pending; self._pending = {}
	for entryId, inc in pairs(toFlush) do
		local key = "ContestEntry_"..entryId
		local ok, err = pcall(function()
			ContestStore:UpdateAsync(key, function(old)
				local v = old or { userId=entryId, userName="Unknown", outfit=nil, wins=0, views=0 }
				v.wins  = (v.wins or 0)  + (inc.addWins  or 0)
				v.views = (v.views or 0) + (inc.addViews or 0)
				return v
			end)
		end)
		if not ok then
			warn("EntryStore UpdateAsync failed for", entryId, err)
			local back = self._pending[entryId] or { addWins=0, addViews=0 }
			back.addWins += (inc.addWins or 0)
			back.addViews += (inc.addViews or 0)
			self._pending[entryId] = back
		else
			local ok2, data = pcall(function() return ContestStore:GetAsync(key) end)
			if ok2 and data then
				self._cache[entryId] = {
					userId=data.userId, userName=data.userName, outfit=data.outfit,
					wins=data.wins or 0, views=data.views or 0, theme=data.theme
				}
			end
		end
	end
end

return EntryStore