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
local PlayerSavedOutfitWithUnownedAssets = Remotes:WaitForChild("PlayerSavedOutfitWithUnownedAssets")
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

local function playerSavedOutfitWithUnownedAssets(player: Player)
	OutfitServerService.SaveCurrentOutfitWithUnownedItems(player)
end

local function playerDeletedOutfitWithUnownedAssets(player: Player)

end

local function getPlayerTastemakerOutfits(player: Player)
	local playerTastemakerOutfits = OutfitServerService.GetPlayerTastemakerOutfits(player)
	return playerTastemakerOutfits
end

PlayerSavedOutfitWithUnownedAssets.OnServerEvent:Connect(playerSavedOutfitWithUnownedAssets)
PlayerPurchasedOutfit.OnServerEvent:Connect(playerPurchasedOutfit)
GetPlayerTastemakerOutfits.OnServerInvoke = getPlayerTastemakerOutfits