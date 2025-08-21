--!strict
-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

-- Folders
local Libraries = ServerScriptService:WaitForChild("Libraries")
local Data = ServerScriptService:WaitForChild("Data")

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
    local Gold = Instance.new("NumberValue", leaderstats)
    Gold.Name = "Gold"
    Gold.Value = profile.Data.Gold
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


Players.PlayerAdded:Connect(PlayerAdded)