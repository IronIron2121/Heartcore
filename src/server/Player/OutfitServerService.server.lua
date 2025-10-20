--!strict

-- Types

-- Services
local RepStore = game:GetService("ReplicatedStorage")
local Plrs = game:GetService("Players")
local AvatarEditorService = game:GetService("AvatarEditorService")
local MarketplaceService = game:GetService("MarketplaceService")

-- Folders
local Remotes = RepStore:WaitForChild("Remotes")
local Utility = RepStore:WaitForChild("Utility")

-- Modules
local OutfitServerService = require(Utility:WaitForChild("OutfitServerService"))

-- Remotes
local PlayerDeletedTastemakerOutfit = Remotes:WaitForChild("PlayerDeletedTastemakerOutfit")
local PlayerSavedTastemakerOutfit = Remotes:WaitForChild("PlayerSavedTastemakerOutfit")
local GetPlayerTastemakerOutfits = Remotes:WaitForChild("GetPlayerTastemakerOutfits")
local PlayerPurchasedOutfit = Remotes:WaitForChild("PlayerPurchasedOutfit")

-- Variables
local isCurrentlyPurchasing = false

--

-- TODO:
local function playerPurchasedOutfit(player: Player, outfitId: number)
	isCurrentlyPurchasing = true
	local outfitDetails = AvatarEditorService:GetOutfitDetails(outfitId)
	
	for _, asset in ipairs(outfitDetails["Assets"]) do
		--print(AvatarEditorService:GetItemDetails(asset["Id"], Enum.AvatarItemType.Asset))
		
		local success, result = pcall(function()
			return MarketplaceService:GetProductInfo(asset["Id"], Enum.InfoType.Asset)
		end)
		
		if success then 
			print(result) 
		else 
			print("None here") 
		end
	end
	
	isCurrentlyPurchasing = false
end

local function playerSavedTastemakerOutfit(player: Player)
	OutfitServerService.SaveCurrentOutfitWithUnownedItems(player)
end

local function playerDeletedTastemakerOutfit(player: Player, index: number)
 	return OutfitServerService.playerDeletedTastemakerOutfit(player, index)
end

local function getPlayerTastemakerOutfits(player: Player)
	local playerTastemakerOutfits = OutfitServerService.GetPlayerTastemakerOutfits(player)
	return playerTastemakerOutfits
end

PlayerSavedTastemakerOutfit.OnServerEvent:Connect(playerSavedTastemakerOutfit)
PlayerPurchasedOutfit.OnServerEvent:Connect(playerPurchasedOutfit)
PlayerDeletedTastemakerOutfit.OnServerInvoke = playerDeletedTastemakerOutfit
GetPlayerTastemakerOutfits.OnServerInvoke = getPlayerTastemakerOutfits