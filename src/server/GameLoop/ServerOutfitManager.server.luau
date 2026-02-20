--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local GameLoop = ReplicatedStorage:WaitForChild("GameLoop")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Remotes
local PlayerRequestedOutfitRF = Remotes:WaitForChild("PlayerRequestedOutfitRF")

-- Modules
local GameOutfitManager = require(GameLoop.GameOutfitManager)

--

local function onPlayerRequestedOutfit(_player: Player, outfitId: string)
    return GameOutfitManager.getOutfit(outfitId)
end

PlayerRequestedOutfitRF.OnServerInvoke = onPlayerRequestedOutfit