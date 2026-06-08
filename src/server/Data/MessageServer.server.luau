--!strict

-- Services
local ReplicatedStorage     = game:GetService("ReplicatedStorage")
local ServerScriptService   = game:GetService("ServerScriptService")

-- Folders
local Remotes               = ReplicatedStorage:WaitForChild("Remotes")
local DataFolder            = ServerScriptService:WaitForChild("Data")

-- Modules
local DataManager           = require(DataFolder.DataManager)

-- Remotes
local IsMessageSeenRF       = Remotes.IsMessageSeenRF
local MarkMessageSeenRE     = Remotes.MarkMessageSeenRE

--

IsMessageSeenRF.OnServerInvoke = function(player: Player, messageName: string): boolean
    return DataManager.HasSeenMessage(player, messageName)
end

MarkMessageSeenRE.OnServerEvent:Connect(function(player: Player, messageName: string)
    print("Received message to mark ", messageName, "seen for player", player.Name)
    DataManager.MarkMessageSeen(player, messageName)
end)