--!strict

-- Services
local RepStore = game:GetService("ReplicatedStorage")
local Plrs = game:GetService("Players")

-- Folders
local Utility = RepStore:WaitForChild("Utility")
local Remotes = RepStore:WaitForChild("Remotes")

-- Modules
local ServerCustomisationService = require(Utility:WaitForChild("ServerCustomisationService"))
local SerialisationService = require(Utility:WaitForChild("SerialisationService"))

-- Remotes
local PlayerEquippedTastemakerOutfit = Remotes:WaitForChild("PlayerEquippedTastemakerOutfit")
local PlayerEquippedInspectedOutfit = Remotes:WaitForChild("PlayerEquippedInspectedPlayer")
local PlayerEquippedInspectedItemsRF = Remotes:WaitForChild("PlayerEquippedInspectedItemsRF")
local PlayerRemovedClassicItem = Remotes:WaitForChild("PlayerRemovedClassicItem")
local PlayerEquippedOutfit = Remotes:WaitForChild("PlayerEquippedOutfit")
local PlayerEquippedItem = Remotes:WaitForChild("PlayerEquippedItem")
local PlayerRemovedItem = Remotes:WaitForChild("PlayerRemovedItem")
local PlayerResetOutfit = Remotes:WaitForChild("PlayerResetOutfit")

-- Variables
local equippingCache = {}

-- Cache management functions
local function setPlayerEquipping(player: Player, isEquipping: boolean)
	equippingCache[player.UserId] = isEquipping
end

local function isPlayerEquipping(player: Player): boolean
	return equippingCache[player.UserId] == true
end

local function clearPlayerFromCache(player: Player)
	equippingCache[player.UserId] = nil
end

local function onPlayerAdded(player: Player)
	-- initialise player in cache as not equipping
	setPlayerEquipping(player, false)
end

local function onPlayerRemoving(player: Player)
	-- Clean up cache when player leaves
	clearPlayerFromCache(player)
end

local function playerRemovedItem(player: Player, itemId: number)
	if isPlayerEquipping(player) then return end
	setPlayerEquipping(player, true)
	local success = ServerCustomisationService.RemoveItemFromAvatar(player, itemId)
	setPlayerEquipping(player, false)
	return success
end

local function playerRemovedClassicItem(player, itemId: number, itemType: string)
	if isPlayerEquipping(player) then return end
	setPlayerEquipping(player, true)
	ServerCustomisationService.RemoveClassicClothingFromAvatar(player, itemId, itemType)
	setPlayerEquipping(player, false)
end

local function playerEquippedItem(player: Player, itemId: number, assetType: string, itemType: string)
	if isPlayerEquipping(player) then return end
	setPlayerEquipping(player, true)
	print(player, itemId, assetType, itemType)
	ServerCustomisationService.AddItemToAvatar(player, itemId, assetType, itemType)
	setPlayerEquipping(player, false)
end

local function playerEquippedOutfit(player: Player, outfitId: number)
	warn("Equipping on server side!")
	if isPlayerEquipping(player) then 
		warn("Already equipping") 
		return 
	end
	
	setPlayerEquipping(player, true)
	ServerCustomisationService.ApplyOutfitToAvatar(player, outfitId) 
	setPlayerEquipping(player, false)
end

local function playerEquippedTastemakerOutfit(player: Player, tastemakerOutfit: {})
	if isPlayerEquipping(player) then return end
	setPlayerEquipping(player, true)
	local description = SerialisationService.UnserialiseHumanoidDescription(tastemakerOutfit)
	ServerCustomisationService.applyDescription(player, description)
	setPlayerEquipping(player, false)
end

local function playerEquippedInspectedItems(player: Player, items: {{assetId: number, type: Enum.MarketplaceProductType}})
	if isPlayerEquipping(player) then 
		return
	else
		warn("Player equipped inspected items", items)
		return
	end
	setPlayerEquipping(player, true)
	for _, item in pairs(items) do
		ServerCustomisationService.AddItemToAvatar(player, item.assetId, "Asset", itemType)
	end
	setPlayerEquipping(player, false)
end



local function playerEquippedInspectedPlayer(player: Player, inspectedPlayer: Player)
	if isPlayerEquipping(player) then return end
	setPlayerEquipping(player, true) 
	ServerCustomisationService.ApplyInspectedOutfitToPlayer(player, inspectedPlayer)
	setPlayerEquipping(player, false)
end

local function playerResetOutfit(player: Player)
	if isPlayerEquipping(player) then return end
	setPlayerEquipping(player, true)
	local success = ServerCustomisationService.ResetPlayerOutfit(player)
	setPlayerEquipping(player, false)

	return success
end

PlayerEquippedOutfit.OnServerEvent:Connect(playerEquippedOutfit)
PlayerEquippedTastemakerOutfit.OnServerEvent:Connect(playerEquippedTastemakerOutfit)
PlayerEquippedInspectedOutfit.OnServerEvent:Connect(playerEquippedInspectedPlayer)
PlayerRemovedClassicItem.OnServerEvent:Connect(playerRemovedClassicItem)
PlayerEquippedItem.OnServerEvent:Connect(playerEquippedItem)
PlayerRemovedItem.OnServerInvoke = playerRemovedItem
PlayerResetOutfit.OnServerInvoke = playerResetOutfit
PlayerEquippedInspectedItemsRF.OnServerInvoke = playerEquippedInspectedItems
Plrs.PlayerRemoving:Connect(onPlayerRemoving)
Plrs.PlayerAdded:Connect(onPlayerAdded)
