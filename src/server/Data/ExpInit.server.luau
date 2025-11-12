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
local ProfileTemplate = require(Data:WaitForChild("ProfileTemplate"))
local DataManager = require(Data:WaitForChild("DataManager"))

-- Remotes
local XPHack = Remotes:WaitForChild("XPHack")

local function GetStoreName()
    return RunService:IsStudio() and "Test" or "Live"
end

-- ProfileStore
local PlayerStore = ProfileStore.New(GetStoreName(), ProfileTemplate)

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

    local LevelName = Instance.new("StringValue", leaderstats)
    LevelName.Name = "LevelName"
    LevelName.Value = DataManager.GetLevelName(profile.Data.Level or 1)

    local LoginStreak = Instance.new("IntValue", leaderstats)
    LoginStreak.Name = "LoginStreak"
    LoginStreak.Value = profile.Data.LoginStreak or 0

    local Flair = Instance.new("NumberValue", leaderstats)
    Flair.Name = "Flair" 
    Flair.Value = profile.Data.Flair or 1

    -- Process login bonuses and streaks (this might update the values)
    DataManager.ProcessLogin(player)
    
    -- Update leaderstats after processing login (in case values changed)
    Exp.Value = profile.Data.Exp
    Level.Value = profile.Data.Level or 1
    LevelName.Value = DataManager.GetLevelName(profile.Data.Level or 1)
    LoginStreak.Value = profile.Data.LoginStreak or 0
end

local function XpHack(player)
    DataManager.AddExp(player, 1)
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
        profile:Reconcile() -- Fill in missing data variables from ProfileTemplate
        
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
XPHack.OnServerEvent:Connect(XpHack)