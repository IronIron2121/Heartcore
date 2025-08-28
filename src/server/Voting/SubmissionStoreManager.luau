--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MemoryStoreService = game:GetService("MemoryStoreService")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")


-- Modules
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))


local SubmissionStoreManager = {}

local function getDateTimePrefix(): string
    local timeNow = DateTime.now()
    local UTC_now = timeNow:ToUniversalTime() :: {
        
    }
    local debug_dayPrefix = UTC_now["Month"] .. UTC_now["Day"] .. UTC_now["Minute"]
    local dayPrefix = UTC_now["Month"] .. UTC_now["Day"]

    return debug_dayPrefix
    --return dayPrefix
end

function SubmissionStoreManager.getCurrentMemoryStoreName(): string
    return getDateTimePrefix() .. Constants.CURRENT_SUBMISSIONS_MEMORYSTORE_NAME
end

function SubmissionStoreManager.getCurrentSubmissionsMemoryStore()
    print(SubmissionStoreManager.getCurrentMemoryStoreName())
    local result, success = callWithRetry(function()
        return MemoryStoreService:GetHashMap(SubmissionStoreManager.getCurrentMemoryStoreName())
    end)
    
    if success then 
        return result 
    else 
        warn("Failed to get memorystore!")
        warn(result, success)
        return nil
    end
end

return SubmissionStoreManager