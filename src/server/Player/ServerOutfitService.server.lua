--!strict

-- Types

-- Services
local RepStore = game:GetService("ReplicatedStorage")

-- Folders
local Remotes = RepStore:WaitForChild("Remotes")
local Utility = RepStore:WaitForChild("Utility")

-- Modules
local ServerOutfitService = require(Utility:WaitForChild("ServerOutfitService"))

-- Remotes
local PlayerDeletedTastemakerOutfit = Remotes:WaitForChild("PlayerDeletedTastemakerOutfit")
local PlayerPurchasedCurrentOutfit = Remotes:WaitForChild("PlayerPurchasedCurrentOutfit")
local PlayerSavedTastemakerOutfit = Remotes:WaitForChild("PlayerSavedTastemakerOutfit")
local PlayerSavedInspectedOutfit = Remotes:WaitForChild("PlayerSavedInspectedOutfit")
local GetPlayerTastemakerOutfits = Remotes:WaitForChild("GetPlayerTastemakerOutfits")

--

local function playerPurchasedCurrentOutfit(player: Player, shoppingCart: {Type: Enum.MarketplaceProductType, itemId: number})
	ServerOutfitService.PlayerPurchasedCurrentOutfit(player, shoppingCart)
end

local function playerSavedTastemakerOutfit(player: Player)
	ServerOutfitService.SaveCurrentOutfitWithUnownedItems(player)
end

local function playerDeletedTastemakerOutfit(player: Player, index: number)
 	return ServerOutfitService.playerDeletedTastemakerOutfit(player, index)
end

local function getPlayerTastemakerOutfits(player: Player)
	local playerTastemakerOutfits = ServerOutfitService.GetPlayerTastemakerOutfits(player)
	return playerTastemakerOutfits
end

local function playerSavedInspectedOutfit(player: Player, inspectedPlayer: Player)
	ServerOutfitService.playerSavedInspectedOutfit(player, inspectedPlayer)
end	

PlayerDeletedTastemakerOutfit.OnServerInvoke = playerDeletedTastemakerOutfit
PlayerPurchasedCurrentOutfit.OnServerInvoke = playerPurchasedCurrentOutfit
GetPlayerTastemakerOutfits.OnServerInvoke = getPlayerTastemakerOutfits

PlayerSavedInspectedOutfit.OnServerEvent:Connect(playerSavedInspectedOutfit)
PlayerSavedTastemakerOutfit.OnServerEvent:Connect(playerSavedTastemakerOutfit)
