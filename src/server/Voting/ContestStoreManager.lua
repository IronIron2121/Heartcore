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
local SubmissionStoreManager = require(Voting:WaitForChild("SubmissionStoreManager"))

--

local ContestStoreManager = {}
ContestStoreManager.__index = ContestStoreManager
setmetatable(ContestStoreManager, ContestStoreManager)

local function addContestSubmission(submission: {
    [string] : {string} }
)

end

function ContestStoreManager.getCurrentMemoryStoreName(): string
    return GameTimer.getTodayDateTimePrefix() .. Constants.CONTEST_MEMORYSTORE_NAME
end

function ContestStoreManager.initialiseNewContest(): ()
    local contestStoreName = ContestStoreManager.getCurrentMemoryStoreName()
    local currentMemoryStore = MemoryStoreService:GetHashMap(contestStoreName)

    local allSubmissions = SubmissionStoreManager:GetEntries()

    for key, entry in allSubmissions do
            -- add the 
            local contestSubmission = {
                id = entry.Id,
                description = entry.humanoidDescription,
                votes = 0
            }
    end

end