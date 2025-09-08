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
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))
local GameTimer = require(Voting:WaitForChild("GameTimer"))

local SubmissionStoreManager = {}

function SubmissionStoreManager.getCurrentMemoryStoreName(): string?
    local currentPrefix = GameTimer.getCurrentPhasePrefix()
    
    if currentPrefix then
        return currentPrefix .. Constants.SUBMISSION_MEMORYSTORE_NAME
    else
        return nil
    end
end

function SubmissionStoreManager.getPreviousMemoryStoreName(): string?
    local previousPrefix = GameTimer.getPreviousPhasePrefix()
    if previousPrefix then
        return previousPrefix .. Constants.SUBMISSION_MEMORYSTORE_NAME
    else
        return nil
    end
end

function SubmissionStoreManager.getPreviousSubmissionMemoryStore()
    local previousStoreName = SubmissionStoreManager.getPreviousMemoryStoreName()
    if not previousStoreName then
        warn("No previous store name available")
        return nil
    end
    
    print("Getting previous submission store:", previousStoreName)
    
    local success, result = callWithRetry(function()
        return MemoryStoreService:GetHashMap(previousStoreName)
    end, 3)
    
    if success then 
        return result 
    else 
        warn("Failed to get previous memorystore!")
        warn(success, result)
        return nil
    end
end

function SubmissionStoreManager.getCurrentSubmissionMemoryStore()
    local currentStoreName = SubmissionStoreManager.getCurrentMemoryStoreName()
    if not currentStoreName then
        warn("Memory store not ready!") 
        return nil 
    end

    print("Getting current submission store:", currentStoreName)
    
    local success, result = callWithRetry(function()
        return MemoryStoreService:GetHashMap(currentStoreName)
    end, 3)
    
    if success then 
        return result 
    else 
        warn("Failed to get current memorystore!")
        warn(success, result)
        return nil
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
        return currentStore:ListItemsAsync(200)
    end, 3)
    
    if success and pages then
        return getAllHashMapEntries(pages)
    else
        warn("Failed to fetch submissions from Memory Store")
        return {}
    end
end

-- Get all entries from previous phase's submission store
function SubmissionStoreManager:GetPreviousPhaseEntries(): {[string]: any}
    local previousStore = self.getPreviousSubmissionMemoryStore()
    
    if not previousStore then
        warn("Could not get previous submissions store")
        return {}
    end
    
    local success, pages = callWithRetry(function()
        return previousStore:ListItemsAsync(200)
    end, 3)
    
    if success and pages then
        return getAllHashMapEntries(pages)
    else
        warn("Failed to fetch previous submissions from Memory Store")
        return {}
    end
end

function SubmissionStoreManager:AddEntry(player: Player, serialisedHumanoidDescription: {}): ()
    -- Get the submissions memory store
    local currentSubmissionsMemoryStore = self.getCurrentSubmissionMemoryStore()
    if not currentSubmissionsMemoryStore then 
        warn("Failed to get submissions memory store") 
        return 
    end

    -- Add the serialised humanoid description to the submissions memory store
    local success = callWithRetry(function()
        return currentSubmissionsMemoryStore:SetAsync(
            tostring(player.UserId), {
                userId = player.UserId,
                playerName = player.Name,
                humanoidDescription = serialisedHumanoidDescription,
            },
            240
        )
    end, 5)

    if success then
        print("Successfully submitted outfit for player:", player.Name)
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



return SubmissionStoreManager