-- GameTimer.lua (ServerScript)
-- SERVER-ONLY: Handles phase transitions and timing

-- Services
local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Remotes = ReplicatedStorage:WaitForChild("Remotes") 
local Bindables = ReplicatedStorage:WaitForChild("Bindables")

-- Modules
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))

-- Memory Stores
local GameTimerMemoryStore = MemoryStoreService:GetHashMap(Constants.GAME_TIMER_MEMORYSTORE_NAME)
local TransitionLockStore = MemoryStoreService:GetHashMap("TransitionLocks")

-- Constants
local CHECK_TIME_LAPSE_INTERVAL = 10
local DEBUG_SECONDS_BETWEEN_THEME_CHANGE = 120
local SECONDS_BETWEEN_THEME_CHANGE = 86400 -- 24 hours

-- Remotes / Bindables
local ThemeChangedRemote = Remotes:WaitForChild("ThemeChanged")
local PhaseChanged = Bindables:WaitForChild("PhaseChanged")

-- Flags
local TimerStarted = false

-- Cache for GameTimer data
local GameTimerCache = {}

-- Constants
local PRIOR_MONTH_HAS_31_DAYS = {
    1,
    2,
    4,
    6,
    8,
    9,
    11,
}

local PRIOR_MONTH_HAS_30_DAYS = {
    5,
    7,
    10,
    12,
}

local GameTimer = {}

local function getCurrentUniversalTime(): {}
    local timeNow = DateTime.now()
    local UTC_now = timeNow:ToUniversalTime() :: {}
    return UTC_now
end

function GameTimer.getTodayDateTimePrefix(): string
    local currentUniversalTime = getCurrentUniversalTime()

    local debug_dayPrefix = currentUniversalTime["Month"] .. currentUniversalTime["Day"] .. currentUniversalTime["Minute"]
    local dayPrefix = currentUniversalTime["Month"] .. currentUniversalTime["Day"]

    return debug_dayPrefix
    --return dayPrefix
end

local function getRecentPhaseTransition()
    return GameTimerCache.RecentPhaseTransition
end

local function getPreviousPhaseTransition()
    return GameTimerCache.PreviousPhaseTransition
end

function GameTimer.getLastTransitionDateTimePrefix(): string?
    local lastTransition = getPreviousPhaseTransition()
    if lastTransition then
        local date = DateTime.fromUnixTimestamp(lastTransition):ToUniversalTime()
        local debug_dayPrefix = date.Month .. date.Day .. date.Minute
        return debug_dayPrefix
    else
        warn("No previous phase transition!")
        return nil
    end
end

function GameTimer.getPreviousTransitionDateTimePrefix(): string?
    local previousTransition = getPreviousPhaseTransition()
    if previousTransition then
        local date = DateTime.fromUnixTimestamp(previousTransition):ToUniversalTime()
        local debug_dayPrefix = date.Month .. date.Day .. date.Minute
        return debug_dayPrefix
    else
        warn("No previous phase transition!")
        return nil
    end
end

local function currentPhaseHasExpired()
    local currentTime = os.time()
    local recentPhaseTransition = getRecentPhaseTransition()
    
    if not recentPhaseTransition then
        return true -- No phase transition recorded yet - start first phase
    end
    
    -- Check if time has passed since the last phase transition
    return (currentTime - recentPhaseTransition) >= DEBUG_SECONDS_BETWEEN_THEME_CHANGE
end

local function updatePhase()
    print("Starting phase transition...")
    
    local currentTime = os.time()
    
    -- Store the current "recent" transition as "previous" before updating
    GameTimerCache.PreviousPhaseTransition = GameTimerCache.RecentPhaseTransition
    GameTimerCache.RecentPhaseTransition = currentTime
    
    print("Updated transitions - Previous:", GameTimerCache.PreviousPhaseTransition, "Recent:", GameTimerCache.RecentPhaseTransition)
    
    -- Save both transition times to persistent storage
    local recentSuccess = callWithRetry(function()
        return GameTimerMemoryStore:SetAsync("RecentPhaseTransition", currentTime, 86400 * 7)
    end, 3)
    
    if GameTimerCache.PreviousPhaseTransition then
        local previousSuccess = callWithRetry(function()
            return GameTimerMemoryStore:SetAsync("PreviousPhaseTransition", GameTimerCache.PreviousPhaseTransition, 86400 * 7)
        end, 3)
    end

    
    if recentSuccess then
        PhaseChanged:Fire()
        print("Phase transition completed at:", currentTime)
        print("Next transition will be at:", currentTime + DEBUG_SECONDS_BETWEEN_THEME_CHANGE)
    else
        warn("Failed to update phase transition times in GameTimerMemoryStore")
    end
end

local function attemptPhaseTransition()
    local currentTime = os.time()
    local lockKey = "phase_transition_" .. tostring(currentTime)
    
    local success, result = callWithRetry(function()
        return TransitionLockStore:UpdateAsync(lockKey, function(currentOwner)
            if currentOwner == nil then
                -- No one owns this transition yet - claim it
                return {
                    serverId = game.JobId,
                    startTime = currentTime
                }
            else
                -- Another server already claimed it
                return nil -- Return nil = no change, don't claim
            end
        end, 600) -- 10 minute expiration
    end, 3)
    
    -- Check if this server won the lock
    if success and result and result.serverId == game.JobId then
        print("Server", game.JobId, "won the transition lock at time", currentTime)
        updatePhase()
        return true
    else
        print("Server", game.JobId, "lost the transition lock at time", currentTime)
        return false
    end
end

local function initializeGameTimerCache()
    -- Load recent phase transition
    local recentSuccess, recentData = callWithRetry(function()
        return GameTimerMemoryStore:GetAsync("RecentPhaseTransition")
    end, 3)
    
    -- Load previous phase transition
    local previousSuccess, previousData = callWithRetry(function()
        return GameTimerMemoryStore:GetAsync("PreviousPhaseTransition")
    end, 3)
    
    if recentSuccess and recentData then
        GameTimerCache.RecentPhaseTransition = recentData
        local timeUntilNext = DEBUG_SECONDS_BETWEEN_THEME_CHANGE - (os.time() - recentData)
        print("Loaded recent phase transition time:", recentData)
        print("Time until next phase:", math.max(0, timeUntilNext), "seconds")
    else
        GameTimerCache.RecentPhaseTransition = nil
        print("No recent phase transition found - will start first phase on next check")
    end
    
    if previousSuccess and previousData then
        GameTimerCache.PreviousPhaseTransition = previousData
        print("Loaded previous phase transition time:", previousData)
    else
        GameTimerCache.PreviousPhaseTransition = nil
        print("No previous phase transition found")
    end
end

function GameTimer.initialiseTimer(): ()
    if TimerStarted then return end

    print("Initializing GameTimer system...")
    
    -- Initialize cache from GameTimerMemoryStore
    initializeGameTimerCache()

    -- Start the monitoring loop
    task.spawn(function()
        while true do
            task.wait(CHECK_TIME_LAPSE_INTERVAL)
            warn("Checking phase expiry...")
            
            if currentPhaseHasExpired() then
                print("Phase has expired, attempting transition...")
                attemptPhaseTransition()
            else
                local lastTransition = getRecentPhaseTransition()
                if lastTransition then
                    local timeUntilNext = DEBUG_SECONDS_BETWEEN_THEME_CHANGE - (os.time() - lastTransition)
                    print("Phase is still valid! Time until next:", timeUntilNext, "seconds")
                else
                    print("No phase transition recorded yet")
                end
            end
        end
    end)

    TimerStarted = true
    print("GameTimer system started successfully!")
end

return GameTimer