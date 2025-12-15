--!strict

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Voting = ServerScriptService:WaitForChild("Voting")
local votingZone = workspace:WaitForChild("votingZone")
local Values = ReplicatedStorage:WaitForChild("Values")

-- Modules
local CacheBasedBalancedSelector = require(Voting:WaitForChild("CacheBasedBalancedSelector"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))
local GameTimer = require(Voting:WaitForChild("GameTimer"))
local ThemeManager = require(Voting:WaitForChild("ThemeManager"))

-- Instances
local VotingHut = votingZone:WaitForChild("VotingHut")
local themeDisplay = VotingHut:WaitForChild("themeDisplay")
local ThemeNameGui = themeDisplay:WaitForChild("ThemeNameGui")
local VoteThemeText = ThemeNameGui:WaitForChild("ThemeText")

local VotingStoreManager = {}

-- Current voting phase
local activeVotingPhasePrefix = nil -- Which day's submissions we're voting on
local currentTheme = nil -- Theme for the voting phase (yesterday's theme)

-- Active store tracking
local currentActiveStore = nil -- The ONE store this server is currently working with
local currentActiveStoreName = "" -- Name of that store
local STORE_ROTATION_INTERVAL = 600 -- 10 minutes

-- Caching variables
local pendingUpdates = {} -- {entryKey = {votes = 0, views = 0}}
local lastFlush = tick()
local FLUSH_INTERVAL = 60 
local MAX_PENDING_UPDATES = 50
local isFlushingInProgress = false
local TIMER_TICK_INTERVAL = 1

-- Public cache for current voting entries (from the current active store)
local publicCache = {} -- {entryKey = {userId, description, votes, views}}
local isCacheUpdating = false

-- Cache update lock configuration
local CACHE_UPDATE_LOCK_DURATION = 120 -- 2 minutes for crash recovery
local CACHE_UPDATE_COOLDOWN = 60 -- 1 minute cooldown between cache updates
local CACHE_UPDATE_LOCK_KEY = "voting_cache_update_lock"

-- Replicated values for rotation timing
local LastRotationTime = Instance.new("IntValue")
LastRotationTime.Name = "LastStoreRotationTime"
LastRotationTime.Value = 0
LastRotationTime.Parent = Values

local NextRotationTime = Instance.new("IntValue")
NextRotationTime.Name = "NextRotationTime"
NextRotationTime.Value = 0
NextRotationTime.Parent = Values

local TimeToNextRotation = Instance.new("IntValue")
TimeToNextRotation.Name = "TimeToNextRotation"
TimeToNextRotation.Value = 0
TimeToNextRotation.Parent = Values

local NextRotationText = Instance.new("StringValue")
NextRotationText.Name = "NextRotationText"
NextRotationText.Value = "LOADING..."
NextRotationText.Parent = Values

local rotationTimerStarted = false

-- Balanced selector instance
local balancedSelector = CacheBasedBalancedSelector.new()

-- Rotation timer functions
local function updateNextRotationText()
	if LastRotationTime.Value == 0 or TimeToNextRotation.Value == 0 then
		NextRotationText.Value = "LOADING..."
	else
		local minutes = math.floor(TimeToNextRotation.Value / 60)
		local seconds = TimeToNextRotation.Value % 60
		NextRotationText.Value = string.format("%d:%02d", minutes, seconds)
	end
end

local function updateTimeUntilNextRotation()
	if LastRotationTime.Value == 0 then
		TimeToNextRotation.Value = 0
		NextRotationTime.Value = 0
		updateNextRotationText()
		return
	end
	
	local nextRotationTime = LastRotationTime.Value + STORE_ROTATION_INTERVAL
	local currentTime = DateTime.now().UnixTimestamp
	local timeRemaining = nextRotationTime - currentTime
	
	NextRotationTime.Value = nextRotationTime
	TimeToNextRotation.Value = math.max(0, timeRemaining)
	updateNextRotationText()
end

local function updateLastRotationTime(newTime: number)
	LastRotationTime.Value = newTime
	updateTimeUntilNextRotation()
end

local function initialiseRotationTimer()
	task.spawn(function()
		if rotationTimerStarted then return end
		rotationTimerStarted = true
		while true do
			task.wait(TIMER_TICK_INTERVAL)
			updateTimeUntilNextRotation()
		end
	end)
end

local function updateVotingThemeBillboard()
	local themeNameText = currentTheme and currentTheme.theme or "Loading..."
	VoteThemeText.Text = themeNameText
end

local function getCacheUpdateLockStore()
	if not activeVotingPhasePrefix then 
		return nil
	end
	
	local success, lockStore = callWithRetry(function()
		return MemoryStoreService:GetSortedMap(tostring(activeVotingPhasePrefix) .. "_VotingCacheUpdateLocks")
	end, 3)
	
	if success then
		return lockStore
	end
	return nil
end

local function acquireCacheUpdateLock(): boolean?
	local lockStore = getCacheUpdateLockStore()
	if not lockStore then
		--warn("Failed to get cache update lock store")
		return false
	end
	
	local currentTime = DateTime.now().UnixTimestamp
	
	-- Try to acquire lock
	local success, result = callWithRetry(function()
		return lockStore:UpdateAsync(
			CACHE_UPDATE_LOCK_KEY,
			function(lockData)
				-- If no lock exists, create one
				if not lockData then
					return {
						serverId = game.JobId,
						timestamp = currentTime
					}
				end
				
				-- Check if lock has expired (for crash recovery)
				local lockAge = currentTime - lockData.timestamp
				if lockAge > CACHE_UPDATE_LOCK_DURATION then
					print("Lock expired, taking over")
					return {
						serverId = game.JobId,
						timestamp = currentTime
					}
				end
				
				-- Check cooldown period
				if lockAge < CACHE_UPDATE_COOLDOWN then
					-- Still in cooldown, don't take lock
					return nil
				end
				
				-- Cooldown passed, we can take the lock
				return {
					serverId = game.JobId,
					timestamp = currentTime
				}
			end,
			CACHE_UPDATE_LOCK_DURATION
		)
	end, 3)
	
	if success and result and result.serverId == game.JobId then
		--print("Successfully acquired cache update lock")
		return true
	else
		--print("Failed to acquire cache update lock - another server recently updated or is updating")
		return false
	end
end

local function releaseCacheUpdateLock(): ()
	local lockStore = getCacheUpdateLockStore()
	if not lockStore then
		return
	end
	
	-- We don't actually remove the lock - we keep the timestamp
	-- so other servers know when the last update was
	--print("Cache update completed, lock retained with timestamp")
end

-- Voting Phase Management
function VotingStoreManager.setActiveVotingPhase(phasePrefix: string)
	--print("Setting active voting phase to:", phasePrefix)
	activeVotingPhasePrefix = phasePrefix
	
	-- Load the theme for this phase (yesterday's theme)
	currentTheme = ThemeManager.getThemeForPhase(phasePrefix)
	if currentTheme then
		updateVotingThemeBillboard()
	else
		--warn("Could not load theme for voting phase:", phasePrefix)
	end
	
	-- Pick a random store and load it
	VotingStoreManager.rotateStore()
end

function VotingStoreManager.getActiveVotingPhase(): string?
	return activeVotingPhasePrefix
end

function VotingStoreManager.getCurrentTheme(): {}?
	return currentTheme
end

function VotingStoreManager.getThemeName(): string
	return currentTheme and currentTheme.theme or "Loading..."
end

-- Get all submission store names for a given phase
local function getSubmissionStoreNames(phasePrefix: string): {string}
	local storeNames = {}
	
	-- Get the info store to find out how many submission stores exist
	local infoStoreName = phasePrefix .. Constants.SUBMISSION_INFO_MEMORYSTORE_NAME
	local success, infoStore = callWithRetry(function()
		return MemoryStoreService:GetSortedMap(infoStoreName)
	end, 3)
	
	if not success or not infoStore then
		--warn("Could not get submission info store for phase:", phasePrefix)
		return storeNames
	end
	
	local infoSuccess, info = callWithRetry(function()
		return infoStore:GetAsync(Constants.CURRENT_SUBMISSION_INFO_KEY)
	end, 3)
	
	if not infoSuccess or not info then
		--warn("Could not get submission info for phase:", phasePrefix)
		return storeNames
	end
	
	-- Generate store names from 1 to currentStoreNumber
	local maxStoreNumber = info.currentStoreNumber or 1
	for i = 1, maxStoreNumber do
		local storeName = phasePrefix .. Constants.SUBMISSION_MEMORYSTORE_NAME .. i
		table.insert(storeNames, storeName)
	end
	
	--print("Found", #storeNames, "submission stores for phase:", phasePrefix)
	return storeNames
end

-- Read all entries from a submission store
local function getAllEntriesFromSubmissionStore(storeName: string): {[string]: any}
	local entries = {}
	
	local success, store = callWithRetry(function()
		return MemoryStoreService:GetSortedMap(storeName)
	end, 3)
	
	if not success or not store then
		--warn("Failed to get submission store:", storeName)
		return entries
	end
	
	local rangeSuccess, items = callWithRetry(function()
		return store:GetRangeAsync(Enum.SortDirection.Ascending, 200)
	end, 3)
	
	if not rangeSuccess or not items then
		--warn("Failed to get range from store:", storeName)
		return entries
	end
	
	for _, item in ipairs(items) do
		entries[item.key] = item.value
	end
	
	return entries
end

-- Pick a random store and load it into cache
function VotingStoreManager.rotateStore()
	if not activeVotingPhasePrefix then
		--warn("No active voting phase set, cannot rotate store")
		return
	end
	
	-- Flush any pending updates to the current store before rotating
	if currentActiveStore and next(pendingUpdates) then
		VotingStoreManager.flushPendingUpdates()
	end
	
	-- Get all available stores for this phase
	local storeNames = getSubmissionStoreNames(activeVotingPhasePrefix)
	
	if #storeNames == 0 then
		--warn("No submission stores available for phase:", activeVotingPhasePrefix)
		return
	end
	
	-- Pick a random store
	local randomIndex = math.random(1, #storeNames)
	local selectedStoreName = storeNames[randomIndex]
	
	-- Get the store
	local success, store = callWithRetry(function()
		return MemoryStoreService:GetSortedMap(selectedStoreName)
	end, 3)
	
	if not success or not store then
		--warn("Failed to get selected store:", selectedStoreName)
		return
	end
	
	-- Update active store references
	currentActiveStore = store
	currentActiveStoreName = selectedStoreName
	
	-- Load entries from this store
	VotingStoreManager.loadCacheFromCurrentStore()

	-- Update rotation timing
	updateLastRotationTime(DateTime.now().UnixTimestamp)
end

-- Load cache from the current active store
function VotingStoreManager.loadCacheFromCurrentStore()
	if not currentActiveStore or not currentActiveStoreName then
		--warn("No active store set")
		return
	end
	
	if isCacheUpdating then
		--warn("Cache update already in progress")
		return
	end
	
	-- Try to acquire the cache update lock
	local gotLock = acquireCacheUpdateLock()
	if not gotLock then
		--print("Skipping cache update - another server recently updated or is currently updating")
		return
	end
	
	isCacheUpdating = true
	--print("Loading cache from store:", currentActiveStoreName)
	
	local entries = getAllEntriesFromSubmissionStore(currentActiveStoreName)
	
	local newCache = {}
	local totalEntries = 0
	
	for entryKey, entryData in pairs(entries) do
		totalEntries += 1
		
		newCache[entryKey] = {
			userId = entryData.userId,
			humanoidDescription = entryData.humanoidDescription,
			theme = currentTheme and currentTheme.theme or "Unknown",
			votes = entryData.votes or 0,
			views = entryData.views or 0
		}
	end
	
	-- Update the public cache
	publicCache = newCache
	
	--print("Loaded", totalEntries, "entries from", currentActiveStoreName)
	
	-- Rebuild selection buckets
	local rebuildSuccess = balancedSelector:onCacheUpdated(publicCache)
	
	isCacheUpdating = false
	
	-- Release lock (keeps timestamp for cooldown tracking)
	releaseCacheUpdateLock()
end

function VotingStoreManager.initialise(): ()
	-- Set active voting phase to previous day (if it exists)
	local previousPrefix = GameTimer.getPreviousPhasePrefix()
	if previousPrefix then
		VotingStoreManager.setActiveVotingPhase(previousPrefix)
	else
		--warn("No previous phase available for voting yet")
	end
	
	-- Start periodic systems
	VotingStoreManager.startPeriodicFlush()
	VotingStoreManager.startStoreRotation()
	initialiseRotationTimer()
end

function VotingStoreManager.addViews(entryKey: string, viewAmount: number): ()
	if not currentActiveStore then
		return
	end
	
	-- initialise entry in pending updates if it doesn't exist
	if not pendingUpdates[entryKey] then
		pendingUpdates[entryKey] = {votes = 0, views = 0}
	end
	
	-- Add to pending updates
	pendingUpdates[entryKey].views += viewAmount
	
	-- Also update the public cache immediately for real-time UI updates
	if publicCache[entryKey] then 
		publicCache[entryKey].views += viewAmount
	end
	
	-- Check if we should flush
	local pendingCount = 0
	for _ in pairs(pendingUpdates) do
		pendingCount += 1
	end
	
	local shouldFlushByTime = tick() - lastFlush > FLUSH_INTERVAL
	local shouldFlushByCount = pendingCount >= MAX_PENDING_UPDATES
	
	if (shouldFlushByTime or shouldFlushByCount) and not isFlushingInProgress then
		VotingStoreManager.flushPendingUpdates()
	end
end

function VotingStoreManager.addVotes(entryKey: string, voteAmount: number): ()
	if not currentActiveStore then
		return
	end
	
	-- initialise entry in pending updates if it doesn't exist
	if not pendingUpdates[entryKey] then
		pendingUpdates[entryKey] = {votes = 0, views = 0}
	end
	
	-- Add to pending updates
	pendingUpdates[entryKey].votes += voteAmount
	
	-- Also update the public cache immediately for real-time UI updates
	if publicCache[entryKey] then
		publicCache[entryKey].votes += voteAmount
	end
	
	-- Check if we should flush
	local pendingCount = 0
	for _ in pairs(pendingUpdates) do
		pendingCount += 1
	end
	
	local shouldFlushByTime = tick() - lastFlush > FLUSH_INTERVAL
	local shouldFlushByCount = pendingCount >= MAX_PENDING_UPDATES
	
	if (shouldFlushByTime or shouldFlushByCount) and not isFlushingInProgress then
		VotingStoreManager.flushPendingUpdates()
	end
end

function VotingStoreManager.flushPendingUpdates(): ()
	if isFlushingInProgress then
		return 
	end
	
	if next(pendingUpdates) == nil then
		return 
	end
	
	if not currentActiveStore or not currentActiveStoreName then
		return
	end
	
	isFlushingInProgress = true
	
	local updatesToFlush = {}
	for entryKey, updates in pairs(pendingUpdates) do
		updatesToFlush[entryKey] = {
			votes = updates.votes,
			views = updates.views
		}
	end
	pendingUpdates = {}
	
	-- Update entries in the current active store
	for entryKey, updates in pairs(updatesToFlush) do
		if updates.votes ~= 0 or updates.views ~= 0 then
			local success = callWithRetry(function()
				return currentActiveStore:UpdateAsync(entryKey, function(oldValue)
					if oldValue then
						oldValue.votes = (oldValue.votes or 0) + updates.votes
						oldValue.views = (oldValue.views or 0) + updates.views
						return oldValue
					else
						--warn("Entry not found during flush:", entryKey)
						return nil
					end
				end, Constants.MEMORYSTORE_STORE_DURATION)
			end, 3)
			
			if not success then
				--warn("Failed to flush updates for entry:", entryKey)
			end
		end
	end
	
	lastFlush = tick()
	isFlushingInProgress = false
end

function VotingStoreManager.startPeriodicFlush(): ()
	task.spawn(function()
		while true do
			task.wait(FLUSH_INTERVAL)
			if not isFlushingInProgress and next(pendingUpdates) then
				VotingStoreManager.flushPendingUpdates()
			end
		end
	end)
end

function VotingStoreManager.startStoreRotation(): ()
	task.spawn(function()
		while true do
			task.wait(STORE_ROTATION_INTERVAL)
			VotingStoreManager.rotateStore()
		end
	end)
end

-- Get the public cache
function VotingStoreManager.getPublicCache(): {}
	return publicCache
end

-- Get a specific entry from the public cache
function VotingStoreManager.getCachedEntry(entryKey: string): {}?
	local cachedEntry = publicCache[entryKey]
	if not cachedEntry then
		return nil
	end
	
	-- Create a copy and add any pending updates
	local entry = {
		userId = cachedEntry.userId,
		humanoidDescription = cachedEntry.humanoidDescription,
		theme = cachedEntry.theme,
		votes = cachedEntry.votes,
		views = cachedEntry.views
	}
	
	-- Add pending updates if they exist
	if pendingUpdates[entryKey] then
		entry.votes += pendingUpdates[entryKey].votes
		entry.views += pendingUpdates[entryKey].views
	end
	
	return entry
end

-- Get a balanced outfit selection
function VotingStoreManager.getBalancedOutfit(player: Player): string?
	local outfit = balancedSelector:selectOutfit(player)
	return outfit
end

function VotingStoreManager.forceFlush(): ()
	VotingStoreManager.flushPendingUpdates()
end

function VotingStoreManager.getPendingUpdates(): {}
	return pendingUpdates
end

-- Phase transition handler
function VotingStoreManager.onPhaseTransition()
	-- Flush any pending updates before switching phases
	if next(pendingUpdates) then
		VotingStoreManager.flushPendingUpdates() 
	end

	balancedSelector:resetCache()
	
	-- Set voting to yesterday's submissions (theme will be loaded and billboard updated automatically)
	local previousPrefix = GameTimer.getPreviousPhasePrefix()
	if previousPrefix then
		VotingStoreManager.setActiveVotingPhase(previousPrefix)
	else
		--warn("No previous phase available for voting")
	end

end

return VotingStoreManager