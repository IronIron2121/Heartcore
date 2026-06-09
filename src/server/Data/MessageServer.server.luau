--!strict

-- Services
local ReplicatedStorage     = game:GetService("ReplicatedStorage")
local ServerScriptService   = game:GetService("ServerScriptService")

-- Folders
local Remotes               = ReplicatedStorage:WaitForChild("Remotes")
local DataFolder            = ServerScriptService:WaitForChild("Data")

-- Modules
local Constants             = require(ReplicatedStorage.Constants)
local DataManager           = require(DataFolder.DataManager)

-- Remotes
local IsMessageSeenRF       = Remotes.IsMessageSeenRF
local MarkMessageSeenRE     = Remotes.MarkMessageSeenRE
local ResetFtueRE           = Remotes.ResetFtueRE

--

IsMessageSeenRF.OnServerInvoke = function(player: Player, messageName: string): boolean
    return DataManager.HasSeenMessage(player, messageName)
end

MarkMessageSeenRE.OnServerEvent:Connect(function(player: Player, messageName: string)
    DataManager.MarkMessageSeen(player, messageName)
end)

ResetFtueRE.OnServerEvent:Connect(function(player: Player, ...)
    DataManager.MarkMessageUnseen(player, Constants.MESSAGE_KEYS.FTUE_KEY)
end)