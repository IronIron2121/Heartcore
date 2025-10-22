--!strict

-- Services
local RepStore = game:GetService("ReplicatedStorage")
local Plrs = game:GetService("Players")

-- Folders
local Utility = RepStore:WaitForChild("Utility")
local Remotes = RepStore:WaitForChild("Remotes")

-- Modules
local AvatarCustomisationService = require(Utility:WaitForChild("AvatarCustomisationService"))
local SerialisationService = require(Utility:WaitForChild("SerialisationService"))

-- Remotes
local PlayerEquippedTastemakerOutfit = Remotes:WaitForChild("PlayerEquippedTastemakerOutfit")
local PlayerRemovedClassicItem = Remotes:WaitForChild("PlayerRemovedClassicItem")
local PlayerEquippedOutfit = Remotes:WaitForChild("PlayerEquippedOutfit")
local PlayerEquippedItem = Remotes:WaitForChild("PlayerEquippedItem")
local PlayerRemovedItem = Remotes:WaitForChild("PlayerRemovedItem")

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
	AvatarCustomisationService.RemoveItemFromAvatar(player, itemId)
	setPlayerEquipping(player, false)
end

local function playerRemovedClassicItem(player, itemId: number, itemType: string)
	if isPlayerEquipping(player) then return end
	setPlayerEquipping(player, true)
	AvatarCustomisationService.RemoveClassicClothingFromAvatar(player, itemId, itemType)
	setPlayerEquipping(player, false)
end

local function playerEquippedItem(player: Player, itemId: number, assetType: string, itemType: string)
	if isPlayerEquipping(player) then return end
	setPlayerEquipping(player, true)
	print(player, itemId, assetType, itemType)
	AvatarCustomisationService.AddItemToAvatar(player, itemId, assetType, itemType)
	setPlayerEquipping(player, false)
end

local function playerEquippedOutfit(player: Player, outfitId: number)
	warn("Equipping on server side!")
	if isPlayerEquipping(player) then 
		warn("Already equipping") 
		return 
	end
	
	setPlayerEquipping(player, true)
	AvatarCustomisationService.ApplyOutfitToAvatar(player, outfitId) 
	setPlayerEquipping(player, false)
end

local function playerEquippedTastemakerOutfit(player: Player, tastemakerOutfit: {})
	if isPlayerEquipping(player) then return end
	setPlayerEquipping(player, true)
	local description = SerialisationService.UnserialiseHumanoidDescription(tastemakerOutfit)
	AvatarCustomisationService.applyDescription(player, description)
	setPlayerEquipping(player, false)
end

PlayerEquippedOutfit.OnServerEvent:Connect(playerEquippedOutfit)
PlayerEquippedTastemakerOutfit.OnServerEvent:Connect(playerEquippedTastemakerOutfit)
PlayerRemovedClassicItem.OnServerEvent:Connect(playerRemovedClassicItem)
PlayerEquippedItem.OnServerEvent:Connect(playerEquippedItem)
PlayerRemovedItem.OnServerEvent:Connect(playerRemovedItem)
Plrs.PlayerRemoving:Connect(onPlayerRemoving)
Plrs.PlayerAdded:Connect(onPlayerAdded)