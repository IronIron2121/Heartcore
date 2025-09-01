-- GameTimer.lua (ServerScript)
-- SERVER-ONLY: Handles phase transitions and timing

-- Services
local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Controllers = ReplicatedStorage:WaitForChild("Controllers")

-- Modules
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))
local ThemeManager = require(Controllers:WaitForChild("ThemeManager"))

-- Memory Stores
local GameTimerMemoryStore = MemoryStoreService:GetHashMap(Constants.GAME_TIMER_MEMORYSTORE_NAME)
local TransitionLockStore = MemoryStoreService:GetHashMap("TransitionLocks")

-- Constants
local CHECK_TIME_LAPSE_INTERVAL = 10
local DEBUG_SECONDS_BETWEEN_THEME_CHANGE = 60
local SECONDS_BETWEEN_THEME_CHANGE = 86400 -- 24 hours

-- Create RemoteEvent for theme updates
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes") 
local ThemeChangedRemote = RemotesFolder:WaitForChild("ThemeChanged")

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

function GameTimer.getYesterdayDateTimePrefix(): string
    local currentUniversalTime = getCurrentUniversalTime()
    local yesterdayDateTimePrefix = ""

    if currentUniversalTime["Day"] ~= 1 then
        yesterdayDateTimePrefix = currentUniversalTime["Month"] .. (currentUniversalTime["Day"] - 1) .. currentUniversalTime["Minute"]
    else
        if table.find(PRIOR_MONTH_HAS_31_DAYS, currentUniversalTime["Month"]) then
            yesterdayDateTimePrefix = (currentUniversalTime["Month"] - 1) .. 31 .. currentUniversalTime["Minute"]
        elseif table.find(PRIOR_MONTH_HAS_30_DAYS, currentUniversalTime["Month"]) then
            yesterdayDateTimePrefix = (currentUniversalTime["Month"] - 1) .. 30 .. currentUniversalTime["Minute"]
        else
            -- February case - handle leap years
            local year = currentUniversalTime["Year"]
            local isLeapYear = (year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0)
            local februaryDays = isLeapYear and 29 or 28
            yesterdayDateTimePrefix = (currentUniversalTime["Month"] - 1) .. februaryDays .. currentUniversalTime["Minute"]
        end
    end

    return yesterdayDateTimePrefix
end

local function getLastPhaseTransition()
    return GameTimerCache.lastPhaseTransition
end

function GameTimer.getLastTransitionDateTimePrefix(): string
    local lastTransition = getLastPhaseTransition()
    if lastTransition then
        local date = DateTime.fromUnixTimestamp(lastTransition):ToUniversalTime()
        local debug_dayPrefix = date.Month .. date.Day .. date.Minute
        return debug_dayPrefix
    else
        -- Fallback to yesterday's date calculation if no transition recorded
        local currentUniversalTime = getCurrentUniversalTime()
        if currentUniversalTime["Day"] ~= 1 then
            return currentUniversalTime["Month"] .. (currentUniversalTime["Day"] - 1) .. currentUniversalTime["Minute"]
        else
            if table.find(PRIOR_MONTH_HAS_31_DAYS, currentUniversalTime["Month"]) then
                return (currentUniversalTime["Month"] - 1) .. 31 .. currentUniversalTime["Minute"]
            elseif table.find(PRIOR_MONTH_HAS_30_DAYS, currentUniversalTime["Month"]) then
                return (currentUniversalTime["Month"] - 1) .. 30 .. currentUniversalTime["Minute"]
            else
                -- February case - handle leap years
                local year = currentUniversalTime["Year"]
                local isLeapYear = (year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0)
                local februaryDays = isLeapYear and 29 or 28
                return (currentUniversalTime["Month"] - 1) .. februaryDays .. currentUniversalTime["Minute"]
            end
        end
    end
end

local function currentPhaseHasExpired()
    local currentTime = os.time()
    local lastPhaseTransition = getLastPhaseTransition()
    
    if not lastPhaseTransition then
        return true -- No phase transition recorded yet - start first phase
    end
    
    -- Check if 24 hours have passed since the last phase transition
    return (currentTime - lastPhaseTransition) >= DEBUG_SECONDS_BETWEEN_THEME_CHANGE
end

local function updatePhase()
    print("Starting phase transition...")
    
    -- TODO: Copy yesterday's submissions to contest store
    -- This is where you'll implement the logic to move submissions to voting
    
    -- Update both the theme and the phase transition time
    local currentTime = os.time()
    GameTimerCache.lastPhaseTransition = currentTime
    
    -- Save the new phase transition time to persistent storage
    local success = callWithRetry(function()
        return GameTimerMemoryStore:SetAsync("lastPhaseTransition", currentTime, 86400 * 7) -- Keep for a week
    end, 3)
    
    if success then
        print("Phase transition completed at:", currentTime)
        print("Next transition will be at:", currentTime + DEBUG_SECONDS_BETWEEN_THEME_CHANGE)
    else
        warn("Failed to update phase transition time in GameTimerMemoryStore")
    end
    
    -- Update the theme system
    -- ThemeManager should handle the actual theme change logic
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
    local success, data = callWithRetry(function()
        return GameTimerMemoryStore:GetAsync("lastPhaseTransition")
    end, 3)
    
    if success and data then
        GameTimerCache.lastPhaseTransition = data
        local timeUntilNext = DEBUG_SECONDS_BETWEEN_THEME_CHANGE - (os.time() - data)
        print("Loaded last phase transition time:", data)
        print("Time until next phase:", math.max(0, timeUntilNext), "seconds")
    else
        GameTimerCache.lastPhaseTransition = nil
        print("No previous phase transition found - will start first phase on next check")
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
                local lastTransition = getLastPhaseTransition()
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