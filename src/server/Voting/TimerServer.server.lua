--!strict 

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Voting = ServerScriptService:WaitForChild("Voting")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Modules
local GameTimer = require(Voting:WaitForChild("GameTimer"))

-- Remotes
local PlayerRequestedNextPhaseTime = Remotes:WaitForChild("PlayerRequestedNextPhaseTime")

--

local function nextPhaseTimeRequested(player: Player): number?
    return GameTimer.getNextPhaseUnixTime()
end

PlayerRequestedNextPhaseTime.OnServerInvoke = nextPhaseTimeRequested