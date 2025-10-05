-- GameTimer.lua (ServerScript)

-- Services
local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Bindables = ReplicatedStorage:WaitForChild("Bindables")
local centralPond = workspace:WaitForChild("centralPond")

-- Modules
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))

-- Memory Stores
local GameTimerMemoryStore = MemoryStoreService:GetHashMap(Constants.GAME_TIMER_MEMORYSTORE_NAME)
local TransitionLockStore = MemoryStoreService:GetHashMap("TransitionLocks")

-- Constants
local CHECK_TIME_LAPSE_INTERVAL = 10
local PHASE_START_HOUR = 12 -- every phase starts at 12:00:00
local PHASE_CLOCK_UPDATE_INTERVAL = 1

-- Remotes / Bindables
local PhaseChanged = Bindables:WaitForChild("PhaseChanged")

-- Instances
local centralPondModel = centralPond:WaitForChild("centralPond")
local Text = centralPondModel:WaitForChild("Text")
local BillboardGui = Text:WaitForChild("BillboardGui")
local Frame = BillboardGui:WaitForChild("Frame")
local TimeLabel = Frame:WaitForChild("TimeLabel")

-- Flags
local TimerStarted = false

local GameTimerCache = {}
GameTimerCache.currentPhaseUnixTime = nil
GameTimerCache.previousPhaseUnixTime = nil
GameTimerCache.nextPhaseUnixTime = nil

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

local function getNextPhaseUnixTime()
    return GameTimerCache.nextPhaseUnixTime
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
    -- Return cached value if it's still valid
    if GameTimerCache.nextPhaseUnixTime then
        local currentUnixTime = DateTime.now().UnixTimestamp
        if currentUnixTime < GameTimerCache.nextPhaseUnixTime then
            return GameTimerCache.nextPhaseUnixTime
        end
    end
    
    -- Cache is invalid or doesn't exist, recalculate
    local currentPhaseUnixTime = getCurrentPhaseUnixTime()
    if not currentPhaseUnixTime then
        return nil
    end
    
    local currentUniversalTime = getUniversalTimeFromUnixTimestamp(currentPhaseUnixTime)
    local currentHour = currentUniversalTime["Hour"]
    
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
        nextPhaseStartUnix = nextPhaseStartUnix + 86400
    end
    
    -- Update cache
    GameTimerCache.nextPhaseUnixTime = nextPhaseStartUnix
    
    return nextPhaseStartUnix
end

local function currentPhaseHasExpired()
    local currentPhaseUnixTime = getCurrentPhaseUnixTime()
    
    if not currentPhaseUnixTime then
        return true
    end

    local nextPhaseStartTime = getNextPhaseStartTime()
    if not nextPhaseStartTime then
        return true
    end
    
    local currentUnixTime = DateTime.now().UnixTimestamp
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
        GameTimerCache.nextPhaseUnixTime = nil -- Invalidate cache so it recalculates
        
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
        end
    else
        GameTimerCache.currentPhaseUnixTime = nil
        print("No recent phase transition found - will start first phase on next check")
    end
    
    if previousSuccess and previousUnixTime then
        GameTimerCache.previousPhaseUnixTime = previousUnixTime
    else
        GameTimerCache.previousPhaseUnixTime = nil
        print("No previous phase transition found") 
    end
end

function GameTimer.initialiseTimer(): ()
    if TimerStarted then return end 
    TimerStarted = true

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

    task.spawn(function()
        while true do
            local timestampNow = DateTime.now().UnixTimestamp
            local nextPhaseTime = getNextPhaseUnixTime()
            
            if not nextPhaseTime or nextPhaseTime <= timestampNow then
                TimeLabel.Text = "LOADING..."
            else
                local timeRemaining = nextPhaseTime - timestampNow
                local hours = timeRemaining // 3600
                local minutes = (timeRemaining % 3600) // 60
                local seconds = timeRemaining % 60
                TimeLabel.Text = string.format("%d:%02d:%02d", hours, minutes, seconds)      
            end

            task.wait(PHASE_CLOCK_UPDATE_INTERVAL)
        end
    end)

    print("GameTimer system started successfully!")
end

return GameTimer