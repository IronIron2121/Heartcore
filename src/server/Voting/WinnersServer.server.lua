--!strict

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


-- Folders
local Voting = ServerScriptService:WaitForChild("Voting")
local Bindables = ReplicatedStorage:WaitForChild("Bindables")

-- Modules
local WinnersStoreManager = require(Voting:WaitForChild("WinnersStoreManager")) 

-- Remotes
local SetNewWinners = Bindables:WaitForChild("SetNewWinners")

--

local function setNewWinnersFunc()
    return WinnersStoreManager.setNewWinners()
end

SetNewWinners.OnInvoke = setNewWinnersFunc