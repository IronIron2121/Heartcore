-- GameTimer.lua (ServerScript)

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
local PHASE_START_HOUR = 12 -- every phase starts at 12:00:00

-- Remotes / Bindables
local PhaseChanged = Bindables:WaitForChild("PhaseChanged")

-- Flags
local TimerStarted = false

local GameTimerCache = {}
GameTimerCache.currentPhaseUnixTime = nil
GameTimerCache.previousPhaseUnixTime = nil

local GameTimer = {}

local function getUniversalTimeFromUnixTimestamp(unixTimestamp: number)
    return DateTime.fromUnixTimestamp(unixTimestamp):ToUniversalTime()    
end

local function getCurrentPhaseUnixTime()
    return GameTimerCache.currentPhaseUnixTime
end

local function getPreviousPhaseUnixTime()
    return GameTimerCache.previousPhaseUnixTime
end

function GameTimer.getCurrentPhasePrefix(): string?
    local currentPhaseUnixTime = getCurrentPhaseUnixTime()

    if currentPhaseUnixTime then
        local date = getUniversalTimeFromUnixTimestamp(currentPhaseUnixTime)
        --local debug_dayPrefix = date.Month .. date.Day .. date.Minute
        local dayPrefix = date.Month .. date.Day 
        return dayPrefix
    else
        warn("No current phase transition!")
        return nil
    end
end

function GameTimer.getPreviousPhasePrefix(): string?
    local previousPhaseUnixTime = getPreviousPhaseUnixTime()
    if previousPhaseUnixTime then
        local date = getUniversalTimeFromUnixTimestamp(previousPhaseUnixTime)
        local debug_dayPrefix = date.Month .. date.Day .. date.Minute
        return debug_dayPrefix
    else
        warn("No previous phase transition!")
        return nil
    end
end

local function getCurrentUniversalTime()
    local currentDateTime = DateTime.now()
    return currentDateTime:ToUniversalTime()
end

local function getNextPhaseStartUnixTime(unixTimestamp: number)
    local currentUniversalTime = getUniversalTimeFromUnixTimestamp(unixTimestamp)
    local currentHour = currentUniversalTime["Hour"]
    
    -- Set to phase start hour (12 PM)
    currentUniversalTime["Hour"] = PHASE_START_HOUR
    currentUniversalTime["Minute"] = 0
    currentUniversalTime["Second"] = 0
    currentUniversalTime["Millisecond"] = 0
    
    local todayPhaseStartUnix = DateTime.fromUniversalTime(table.unpack(currentUniversalTime)).UnixTimestamp
    
    -- If we've already passed today's phase start, return tomorrow's
    if currentHour >= PHASE_START_HOUR then
        return todayPhaseStartUnix + 86400
    else
        return todayPhaseStartUnix
    end
end

local function currentPhaseHasExpired()
    local currentPhaseUnixTime = getCurrentPhaseUnixTime()
    
    if not currentPhaseUnixTime then
        return true -- No phase exists, need to create one
    end

    local nextPhaseStartTime = getNextPhaseStartUnixTime(currentPhaseUnixTime)
    local currentUnixTime = DateTime.now().UnixTimestamp
    
    return currentUnixTime >= nextPhaseStartTime
end

local function updatePhase()
    print("Starting phase transition...")
    local currentUnixTime = DateTime.now().UnixTimestamp 
    
    -- Don't update cache until we confirm Memory Store success
    local recentSuccess = callWithRetry(function()
        return GameTimerMemoryStore:SetAsync("currentPhaseUnixTime", currentUnixTime, Constants.MEMORYSTORE_STORE_DURATION)
    end, 3)
    
    local previousSuccess = true -- Default to true if no previous phase
    if GameTimerCache.currentPhaseUnixTime then
        previousSuccess = callWithRetry(function()
            return GameTimerMemoryStore:SetAsync("previousPhaseUnixTime", GameTimerCache.currentPhaseUnixTime, Constants.MEMORYSTORE_STORE_DURATION)
        end, 3)
    end
    
    -- Only update cache if both Memory Store operations succeeded
    if recentSuccess and previousSuccess then
        GameTimerCache.previousPhaseUnixTime = GameTimerCache.currentPhaseUnixTime
        GameTimerCache.currentPhaseUnixTime = currentUnixTime
        
        PhaseChanged:Fire()
        
        local currentDateTime = DateTime.fromUnixTimestamp(currentUnixTime)
        local nextPhaseUnixTime = getNextPhaseStartUnixTime(currentUnixTime)
        local tomorrowDateTime = DateTime.fromUnixTimestamp(nextPhaseUnixTime)
        
        print("Phase transition completed at:", currentDateTime:FormatUniversalTime("YYYY-MM-DD HH:mm", "en-us"))
        print("Next transition at:", tomorrowDateTime:FormatUniversalTime("YYYY-MM-DD HH:mm", "en-us"))
    else
        warn("Failed to update phase transition times in GameTimerMemoryStore")
        return false
    end
    
    return true
end

local function attemptPhaseTransition()
    local currentTime = os.time()
    local lockKey = "phase_transition_" .. tostring(currentTime)
    
    local success, result = callWithRetry(function()
        return TransitionLockStore:UpdateAsync(lockKey, function(currentOwner)
            if currentOwner == nil then
                -- no one owns this transition yet, claim it
                return {
                    serverId = game.JobId,
                    startTime = currentTime
                }
            else
                -- another server is already doing the transition
                return nil 
            end
        end, 600) -- 10 mins
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
    local recentSuccess, recentUnixTime = callWithRetry(function()
        return GameTimerMemoryStore:GetAsync("currentPhaseUnixTime")
    end, 3)
    
    -- Load previous phase transition
    local previousSuccess, previousUnixTime = callWithRetry(function()
        return GameTimerMemoryStore:GetAsync("previousPhaseUnixTime")
    end, 3)
    
    if recentSuccess and recentUnixTime then
        GameTimerCache.currentPhaseUnixTime = recentUnixTime

        local nextPhaseTimestamp = getNextPhaseStartUnixTime(recentUnixTime)
        local timeUntilNext = (nextPhaseTimestamp - DateTime.now().UnixTimestamp)
        print("Loaded recent phase transition time:", recentUnixTime)
        print("Time until next phase:", math.max(0, timeUntilNext), "seconds")
    else
        GameTimerCache.currentPhaseUnixTime = nil
        print("No recent phase transition found - will start first phase on next check")
    end
    
    if previousSuccess and previousUnixTime then
        GameTimerCache.previousPhaseUnixTime = previousUnixTime
        print("Loaded previous phase transition time:", previousUnixTime)
    else
        GameTimerCache.previousPhaseUnixTime = nil
        print("No previous phase transition found") 
    end
end

function GameTimer.initialiseTimer(): ()
    if TimerStarted then return end
    TimerStarted = true


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
                local lastTransition = getCurrentPhaseUnixTime()

                if lastTransition then
                    local timeUntilNext = getNextPhaseStartUnixTime(lastTransition) - DateTime.now().UnixTimestamp
                    print("Phase is still valid! Time until next:", timeUntilNext, "seconds")
                else
                    print("No phase transition recorded yet")
                end
            end
        end
    end)

    print("GameTimer system started successfully!")
end

return GameTimer