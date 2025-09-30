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

local function getNextPhaseStartTime()
    warn("Getting next phase start time")
    local currentPhaseUnixTime = getCurrentPhaseUnixTime()
    warn("current phase == ", currentPhaseUnixTime)
    if not currentPhaseUnixTime then
        return nil
    end
    
    local currentUniversalTime = getUniversalTimeFromUnixTimestamp(currentPhaseUnixTime)
    local currentHour = currentUniversalTime["Hour"]
    warn("Universal time = ", currentUniversalTime)
    currentUniversalTime["Hour"] = PHASE_START_HOUR
    currentUniversalTime["Minute"] = 0
    currentUniversalTime["Second"] = 0
    currentUniversalTime["Millisecond"] = 0
    
    local timeArray = {
        currentUniversalTime.Year,
        currentUniversalTime.Month,
        currentUniversalTime.Day,
        currentUniversalTime.Hour,
        currentUniversalTime.Minute,
        currentUniversalTime.Second,
        currentUniversalTime.Millisecond
    }

    local nextPhaseStartUnix = DateTime.fromUniversalTime(table.unpack(timeArray)).UnixTimestamp
    

    if currentHour >= PHASE_START_HOUR then
        warn("nextPhaseStart tomorrow: ", DateTime.fromUnixTimestamp(nextPhaseStartUnix + 86400):FormatUniversalTime("YYYY-MM-DD HH:mm", "en-us"))
        return nextPhaseStartUnix + 86400
    else
        warn("nextPhaseStart: today", DateTime.fromUnixTimestamp(nextPhaseStartUnix):FormatUniversalTime("YYYY-MM-DD HH:mm", "en-us"))
        return nextPhaseStartUnix
    end
end

local function currentPhaseHasExpired()
    local currentPhaseUnixTime = getCurrentPhaseUnixTime()
    
    if not currentPhaseUnixTime then
        warn("No current phase unix time!")
        return true
    end

local nextPhaseStartTime = getNextPhaseStartTime()
    if not nextPhaseStartTime then
        warn("No next phase start time!")
        return true
    end
    
    local currentUnixTime = DateTime.now().UnixTimestamp
    warn("comparing...", currentUnixTime, nextPhaseStartTime)
    return currentUnixTime >= nextPhaseStartTime
end

local function updatePhase()
    print("Starting phase transition...")
    local currentUnixTime = DateTime.now().UnixTimestamp 
    
    local recentSuccess = callWithRetry(function()
        return GameTimerMemoryStore:SetAsync("currentPhaseUnixTime", currentUnixTime, Constants.MEMORYSTORE_STORE_DURATION)
    end, 3)
    
    local previousSuccess = true
    if GameTimerCache.currentPhaseUnixTime then
        previousSuccess = callWithRetry(function()
            return GameTimerMemoryStore:SetAsync("previousPhaseUnixTime", GameTimerCache.currentPhaseUnixTime, Constants.MEMORYSTORE_STORE_DURATION)
        end, 3)
    end
    
    if recentSuccess and previousSuccess then
        GameTimerCache.previousPhaseUnixTime = GameTimerCache.currentPhaseUnixTime
        GameTimerCache.currentPhaseUnixTime = currentUnixTime
        
        PhaseChanged:Fire()
        
        local currentDateTime = DateTime.fromUnixTimestamp(currentUnixTime)
        local nextPhaseUnixTime = getNextPhaseStartTime()
        local tomorrowDateTime = nextPhaseUnixTime and DateTime.fromUnixTimestamp(nextPhaseUnixTime) or nil
        
        print("Phase transition completed at:", currentDateTime:FormatUniversalTime("YYYY-MM-DD HH:mm", "en-us"))
        if tomorrowDateTime then
            print("Next transition at:", tomorrowDateTime:FormatUniversalTime("YYYY-MM-DD HH:mm", "en-us"))
        end
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
                return {
                    serverId = game.JobId,
                    startTime = currentTime
                }
            else
                return nil 
            end
        end, 600)
    end, 3)
    
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
    local recentSuccess, recentUnixTime = callWithRetry(function()
        return GameTimerMemoryStore:GetAsync("currentPhaseUnixTime")
    end, 3)
    
    local previousSuccess, previousUnixTime = callWithRetry(function()
        return GameTimerMemoryStore:GetAsync("previousPhaseUnixTime")
    end, 3)
    
    if recentSuccess and recentUnixTime then
        GameTimerCache.currentPhaseUnixTime = recentUnixTime

        local nextPhaseTimestamp = getNextPhaseStartTime()
        if nextPhaseTimestamp then
            local timeUntilNext = nextPhaseTimestamp - DateTime.now().UnixTimestamp
            print("Loaded recent phase transition time:", recentUnixTime)
            print("Time until next phase:", math.max(0, timeUntilNext), "seconds")
        end
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
    
    initializeGameTimerCache()

    task.spawn(function()
        while true do
            task.wait(CHECK_TIME_LAPSE_INTERVAL)
            warn("Checking phase expiry...")
            
            if currentPhaseHasExpired() then
                print("Phase has expired, attempting transition...")
                attemptPhaseTransition()
            else
                local nextPhaseTime = getNextPhaseStartTime()
                if nextPhaseTime then
                    local timeUntilNext = nextPhaseTime - DateTime.now().UnixTimestamp
                    print("Phase is still valid! Time until next:", math.floor(timeUntilNext), "seconds")
                else
                    print("No phase transition recorded yet")
                end
            end
        end
    end)

    print("GameTimer system started successfully!")
end

return GameTimer