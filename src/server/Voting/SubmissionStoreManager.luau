--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MemoryStoreService = game:GetService("MemoryStoreService")
local ServerScriptService = game:GetService("ServerScriptService")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Voting = ServerScriptService:WaitForChild("Voting")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Remotes
local SubmissionResultRE = Remotes:WaitForChild("SubmissionResultRE")

-- Modules
local printAllHashMapPages = require(Utility:WaitForChild("printAllHashMapStorePages"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))
local GameTimer = require(Voting:WaitForChild("GameTimer"))

local SubmissionStoreManager = {}

function SubmissionStoreManager.getCurrentMemoryStoreName(): string
    return GameTimer.getTodayDateTimePrefix() .. Constants.SUBMISSION_MEMORYSTORE_NAME
end

function SubmissionStoreManager.getYesterdaysSubmissionMemoryStore()

end

function SubmissionStoreManager.getCurrentSubmissionMemoryStore()
    print(SubmissionStoreManager.getCurrentMemoryStoreName())
    local success, result = callWithRetry(function()
        return MemoryStoreService:GetHashMap(SubmissionStoreManager.getCurrentMemoryStoreName())
    end)
    
    if success then 
        return result 
    else 
        warn("Failed to get memorystore!")
        warn(success, result)
        return success
    end
end

-- Gets all entries from a given hash map
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

-- Get all entries from the current submission store
function SubmissionStoreManager:GetEntries(): {[string]: any}
    local currentStore = self.getCurrentSubmissionMemoryStore()
    
    if not currentStore then
        warn("Could not get current submissions store")
        return {}
    end
    
    local success, pages = callWithRetry(function()
        return currentStore:ListItemsAsync(100) -- Get up to 100 items per page
    end, 3)
    
    if success and pages then
        return getAllHashMapEntries(pages)
    else
        warn("Failed to fetch submissions from Memory Store")
        return {}
    end
end

function SubmissionStoreManager:AddEntry(player: Player, serialisedHumanoidDescription: {}): ()
    -- Get the submissions memory store
    local CurrentSubmissionsMemoryStore = self:getCurrentSubmissionMemoryStore()
    if not CurrentSubmissionsMemoryStore then 
        warn("Failed to get submissions memory store") 
        return 
    end

    -- Add the serialised humanoid description to the submissions memory store
    local success = callWithRetry(function()
        return CurrentSubmissionsMemoryStore:SetAsync(
            tostring(player.UserId),
            serialisedHumanoidDescription,
            86400
        )
    end, 5)

    if success then
        print("Successfully submitted outfit for player:", player.Name)

        task.spawn(function()
            local pages = CurrentSubmissionsMemoryStore:ListItemsAsync(1)
            printAllHashMapPages(pages)
        end)

        SubmissionResultRE:FireClient(player, {
            ok = true,
            msg = "Outfit submitted successfully!"
        })
    else
        warn("Failed to submit outfit for player:", player.Name)
        SubmissionResultRE:FireClient(player, {
            ok = false,
            msg = "Failed to submit outfit. Please try again."
        })
    end
end

-- Get total count of submissions
function SubmissionStoreManager:GetSubmissionCount(): number
    local entries = self:GetEntries()
    local count = 0
    for _ in pairs(entries) do
        count = count + 1
    end
    return count
end

-- Debug function to print all entries
function SubmissionStoreManager:PrintAllEntries()
    local entries = self:GetEntries()
    print("=== All Submission Entries ===")
    for key, value in pairs(entries) do
        print("Key:", key)
        print("Value:", value)
        print("---")
    end
    print("Total entries:", self:GetSubmissionCount())
end

return SubmissionStoreManager