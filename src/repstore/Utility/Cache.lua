--!strict

--[[
	Cache - A simple key-value cache which will automatically refresh when fetching a stale entry
	as well as clear out entries after a period of time without being accessed.

	A refresh function is passed to update entries, as well as parameters for how long entries
	should be cached for and how long to wait before clearing them.
--]]

local Cache = {}
Cache.__index = Cache

type RefreshCallback<K, V> = (K) -> V

function Cache.new<K, V>(refreshCallback: RefreshCallback<K, V>, cacheSeconds: number)
	local self = {
		cacheSeconds = cacheSeconds,
		refreshCallback = refreshCallback,
		entries = {},
		refreshTimes = {},
	}
	setmetatable(self, Cache)
	return self
end

function Cache:refresh<K, V>(key: K): V?
	local success, result = pcall(self.refreshCallback, key)
	if success then
		if result ~= nil then
			self:set(key, result)
			return result
		end
	else
		warn(`Failed to refresh key {key} because: {result}`)
	end
	return nil
end

function Cache:set<K, V>(key: K, value: V)
	local refreshTime = os.clock()
	self.refreshTimes[key] = refreshTime
	self.entries[key] = value

	-- After the set cache time, check if the key has been recently refreshed. If it has not,
	-- clear it from the cache.
	task.delay(self.cacheSeconds :: number, function()
		if not (self.refreshTimes[key] and self.entries[key]) then
			return
		end

		if self.refreshTimes[key] == refreshTime then
			self.refreshTimes[key] = nil
			self.entries[key] = nil
		end
	end)
end

function Cache:get<K, V>(key: K, forceRefresh: boolean?): V?
	local isCached = self.entries[key] ~= nil

	-- If the key isn't cached, is being force refreshed, or has expired, return a refreshed
	-- value. Otherwise, return the currently cached value.
	if (not isCached) or forceRefresh then
		local value = self:refresh(key)
		if value ~= nil then
			return value
		end
	end

	return self.entries[key]
end

return Cache
