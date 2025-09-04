-- GameTimer.lua (ServerScript)
-- SERVER-ONLY: Handles phase transitions and timing

-- Services
local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
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
local PhaseChanged = Bindables:WaitForChild("PhaseChanged")

-- Flags
local TimerStarted = false

-- Cache for GameTimer data
local GameTimerCache = {}

local GameTimer = {}

local function getCurrentPhaseTimestamp()
    return GameTimerCache.currentPhaseTimestamp
end

local function getPreviousPhaseTimestamp()
    return GameTimerCache.previousPhaseTimestamp
end

function GameTimer.getCurrentPhasePrefix(): string?
    local currentPhaseTimestamp = getCurrentPhaseTimestamp()

    if currentPhaseTimestamp then
        local date = DateTime.fromUnixTimestamp(currentPhaseTimestamp):ToUniversalTime()
        local debug_dayPrefix = date.Month .. date.Day .. date.Minute
        return debug_dayPrefix
    else
        warn("No current phase transition!")
        task.wait(5)
        return nil
    end
end

function GameTimer.getPreviousPhasePrefix(): string?
    local previousPhaseTimestamp = getPreviousPhaseTimestamp()
    if previousPhaseTimestamp then
        local date = DateTime.fromUnixTimestamp(previousPhaseTimestamp):ToUniversalTime()
        local debug_dayPrefix = date.Month .. date.Day .. date.Minute
        return debug_dayPrefix
    else
        warn("No previous phase transition!")
        return nil
    end
end

local function currentPhaseHasExpired()
    local currentTime = os.time()
    local currentPhaseTimestamp = getCurrentPhaseTimestamp()
    
    if not currentPhaseTimestamp then
        return true -- No phase transition recorded yet - start first phase
    end
    
    -- Check if time has passed since the last phase transition
    return (currentTime - currentPhaseTimestamp) >= DEBUG_SECONDS_BETWEEN_THEME_CHANGE
end

local function updatePhase()
    print("Starting phase transition...")
    local currentTime = os.time()
    
    -- Store the current "recent" transition as "previous" before updating
    GameTimerCache.previousPhaseTimestamp = GameTimerCache.currentPhaseTimestamp
    GameTimerCache.currentPhaseTimestamp = currentTime
    
    -- Save both transition times to persistent storage
    local recentSuccess = callWithRetry(function()
        return GameTimerMemoryStore:SetAsync("currentPhaseTimestamp", currentTime, Constants.MEMORYSTORE_STORE_DURATION)
    end, 3)
    
    if GameTimerCache.previousPhaseTimestamp then
        local previousSuccess = callWithRetry(function()
            return GameTimerMemoryStore:SetAsync("previousPhaseTimestamp", GameTimerCache.previousPhaseTimestamp, Constants.MEMORYSTORE_STORE_DURATION)
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
        return GameTimerMemoryStore:GetAsync("currentPhaseTimestamp")
    end, 3)
    
    -- Load previous phase transition
    local previousSuccess, previousData = callWithRetry(function()
        return GameTimerMemoryStore:GetAsync("previousPhaseTimestamp")
    end, 3)
    
    if recentSuccess and recentData then
        GameTimerCache.currentPhaseTimestamp = recentData
        local timeUntilNext = DEBUG_SECONDS_BETWEEN_THEME_CHANGE - (os.time() - recentData)
        print("Loaded recent phase transition time:", recentData)
        print("Time until next phase:", math.max(0, timeUntilNext), "seconds")
    else
        GameTimerCache.currentPhaseTimestamp = nil
        print("No recent phase transition found - will start first phase on next check")
    end
    
    if previousSuccess and previousData then
        GameTimerCache.previousPhaseTimestamp = previousData
        print("Loaded previous phase transition time:", previousData)
    else
        GameTimerCache.previousPhaseTimestamp = nil
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
                local lastTransition = getCurrentPhaseTimestamp()
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