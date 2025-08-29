-- ThemeController.lua (ServerScript)
-- SERVER-ONLY: Handles all MemoryStore operations

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

-- Constants
local CHECK_TIME_LAPSE_INTERVAL = 10
local DEBUG_SECONDS_BETWEEN_THEME_CHANGE = 60
local SECONDS_BETWEEN_THEME_CHANGE = 3880000

-- Create RemoteEvent for theme updates
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes") 
local ThemeChangedRemote = RemotesFolder:WaitForChild("ThemeChanged")

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

return GameTimer