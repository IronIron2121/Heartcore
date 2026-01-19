--!strict

-- Types

-- Services
local RepStore = game:GetService("ReplicatedStorage")
local AvatarEditorService = game:GetService("AvatarEditorService")
local MarketplaceService = game:GetService("MarketplaceService")

-- Folders
local Remotes = RepStore:WaitForChild("Remotes")
local Utility = RepStore:WaitForChild("Utility")

-- Modules
local OutfitServerService = require(Utility:WaitForChild("OutfitServerService"))

-- Remotes
local PlayerDeletedTastemakerOutfit = Remotes:WaitForChild("PlayerDeletedTastemakerOutfit")
local PlayerPurchasedCurrentOutfit = Remotes:WaitForChild("PlayerPurchasedCurrentOutfit")
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

local function playerPurchasedCurrentOutfit(player: Player, shoppingCart: {Type: Enum.MarketplaceProductType, itemId: number})
	OutfitServerService.PlayerPurchasedCurrentOutfit(player, shoppingCart)
end

local function playerSavedTastemakerOutfit(player: Player)
	OutfitServerService.SaveTastemakerOutfit(player)
end

local function playerDeletedTastemakerOutfit(player: Player, index: number)
 	return OutfitServerService.playerDeletedTastemakerOutfit(player, index)
end

local function getPlayerTastemakerOutfits(player: Player)
	local playerTastemakerOutfits = OutfitServerService.GetPlayerTastemakerOutfits(player)
	return playerTastemakerOutfits
end

PlayerDeletedTastemakerOutfit.OnServerInvoke = playerDeletedTastemakerOutfit
PlayerPurchasedCurrentOutfit.OnServerInvoke = playerPurchasedCurrentOutfit
GetPlayerTastemakerOutfits.OnServerInvoke = getPlayerTastemakerOutfits

PlayerSavedTastemakerOutfit.OnServerEvent:Connect(playerSavedTastemakerOutfit)
PlayerPurchasedOutfit.OnServerEvent:Connect(playerPurchasedOutfit)
