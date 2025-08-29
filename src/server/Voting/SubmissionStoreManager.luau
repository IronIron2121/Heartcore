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

-- Cache for entries to avoid repeated Memory Store calls
local entriesCache: {[string]: any} = {}
local lastCacheUpdate = 0
local lastCacheStoreName = ""
local CACHE_DURATION = 30 -- Cache for 30 seconds

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
        return false
    end
end

-- Helper function to parse all pages from a HashMap (from your printAllHashMapPages)
local function getAllHashMapEntries(hashPages: MemoryStoreHashMapPages): {[string]: any}
    local allEntries: {[string]: any} = {}
    
    while not hashPages.IsFinished do
        local currentPage = hashPages:GetCurrentPage()
        
        -- Process each item in the current page
        for _, item in ipairs(currentPage) do
            allEntries[item.key] = item.value
        end
        
        -- Move to next page if available
        if not hashPages.IsFinished then
            local success, error = pcall(function()
                hashPages:AdvanceToNextPageAsync()
            end)
            
            if not success then
                warn("Failed to advance to next page:", error)
                break
            end
        end
    end
    
    return allEntries
end

-- Get all cached entries (main function used by BalancedSelector)
function SubmissionStoreManager:GetCachedEntries(): {[string]: any}
    local currentTime = tick()
    local currentStoreName = self.getCurrentMemoryStoreName()
    
    -- Clear cache if we've switched to a different store (new day/minute)
    if currentStoreName ~= lastCacheStoreName then
        entriesCache = {}
        lastCacheUpdate = 0
        lastCacheStoreName = currentStoreName
    end
    
    -- Return cached entries if they're still fresh
    if currentTime - lastCacheUpdate < CACHE_DURATION then
        return entriesCache
    end
    
    -- Fetch fresh entries from Memory Store
    local currentStore = self.getCurrentSubmissionsMemoryStore()
    
    if not currentStore then
        warn("Could not get current submissions store")
        return entriesCache -- Return existing cache
    end
    
    local success, pages = callWithRetry(function()
        return currentStore:ListItemsAsync(100) -- Get up to 100 items per page
    end, 3)
    
    if success and pages then
        entriesCache = getAllHashMapEntries(pages)
        lastCacheUpdate = currentTime
        print("Updated submission cache with", self:GetSubmissionCount(), "entries from store:", currentStoreName)
    else
        warn("Failed to fetch submissions from Memory Store")
        -- Return existing cache even if stale, rather than empty table
    end
    
    return entriesCache
end

-- Force refresh the cache (useful when you know data has changed)
function SubmissionStoreManager:RefreshCache()
    lastCacheUpdate = 0 -- Force cache to be considered stale
    return self:GetCachedEntries()
end

-- Get total count of submissions
function SubmissionStoreManager:GetSubmissionCount(): number
    local entries = self:GetCachedEntries()
    local count = 0
    for _ in pairs(entries) do
        count = count + 1
    end
    return count
end

-- Debug function to print all entries (similar to your printAllHashMapPages)
function SubmissionStoreManager:PrintAllEntries()
    local entries = self:GetCachedEntries()
    print("=== All Submission Entries ===")
    for key, value in pairs(entries) do
        print("Key:", key)
        print("Value:", value)
        print("---")
    end
    print("Total entries:", self:GetSubmissionCount())
end

return SubmissionStoreManager