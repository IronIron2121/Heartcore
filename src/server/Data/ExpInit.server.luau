--!strict

-- DataInit.server.luau

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Folders
local Libraries = ServerScriptService:WaitForChild("Libraries")
local Data = ServerScriptService:WaitForChild("Data")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Modules
local ProfileStore = require(Libraries:WaitForChild("ProfileStore"))
local Template = require(Data:WaitForChild("Template"))
local DataManager = require(Data:WaitForChild("DataManager"))

local function GetStoreName()
    return RunService:IsStudio() and "Test" or "Live"
end

-- ProfileStore
local PlayerStore = ProfileStore.New(GetStoreName(), Template)

--

-- Add leaderstats and synchronise player data
local function Initialise(player: Player, profile: typeof(PlayerStore:StartSessionAsync()))
    local leaderstats = Instance.new("Folder", player)
    leaderstats.Name = "leaderstats"
    
    local Exp = Instance.new("NumberValue", leaderstats)
    Exp.Name = "Exp"
    Exp.Value = profile.Data.Exp

    local Level = Instance.new("NumberValue", leaderstats)
    Level.Name = "Level"
    Level.Value = profile.Data.Level or 1

    -- Process login bonuses and streaks
    DataManager.ProcessLogin(player)

    -- Sync player data
    --ReplicatedStorage
end


-- Creates and stores a profile
local function PlayerAdded(player: Player)
    -- Start a new profile session
    local profile = PlayerStore:StartSessionAsync("Player_" .. player.UserId, {
        Cancel = function()
            return player.Parent ~= Players
        end
    })

    if profile ~= nil then
        profile:AddUserId(player.UserId) -- GDPR compliance
        profile:Reconcile() -- Fill in missing data variables from template
        
        -- Handles session-locking
        profile.OnSessionEnd:Connect(function()
            DataManager.Profiles[player] = nil
            player:Kick("Data error occurred. Please rejoin.")
        end)    

        -- Save profile for later use
        if player.Parent == Players then
            DataManager.Profiles[player] = profile
            Initialise(player, profile)
        else
            profile:EndSession()
        end

    else
        -- Server shuts down while player is joining
        player:Kick("Data error occurred. Please rejoin")
    end


end

local function PlayerRemoved(player: Player)
    local profile = DataManager.Profiles[player]
    if not profile then
        return
    end

    profile:EndSession()
    DataManager.Profiles[player] = nil

end

for _, player in Players:GetPlayers() do
    task.spawn(PlayerAdded, player)
end

Players.PlayerAdded:Connect(PlayerAdded)
Players.PlayerRemoving:Connect(PlayerRemoved)