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
local PlayerEquippedItem = Remotes:WaitForChild("PlayerEquippedItem")
local PlayerRemovedItem = Remotes:WaitForChild("PlayerRemovedItem")
local PlayerEquippedOutfit = Remotes:WaitForChild("PlayerEquippedOutfit")


-- Variables
local isCurrentlyEquipping = false

--

local function onPlayerAdded(player: Player)
	
end

local function playerRemovedItem(player: Player, itemId: number)
	if isCurrentlyEquipping then return end
	isCurrentlyEquipping = true
	AvatarCustomisationService.RemoveItemFromAvatar(player, itemId)
	isCurrentlyEquipping = false
end

local function playerEquippedItem(player: Player, itemId: number, assetType: string, itemType: string)
	if isCurrentlyEquipping then return end
	isCurrentlyEquipping = true
	print(player, itemId, assetType, itemType)
	AvatarCustomisationService.AddItemToAvatar(player, itemId, assetType, itemType)
	isCurrentlyEquipping = false
end

local function playerEquippedOutfit(player: Player, outfitId: number)
	warn("Equipping on server side!")
	if isCurrentlyEquipping then warn("Already equipping") return end
	isCurrentlyEquipping = true
	AvatarCustomisationService.ApplyOutfitToAvatar(player, outfitId) 
	isCurrentlyEquipping = false
end

local function playerEquippedTastemakerOutfit(player: Player, tastemakerOutfit: {})
	if isCurrentlyEquipping then return end
	isCurrentlyEquipping = true
	local description = SerialisationService.UnserialiseHumanoidDescription(tastemakerOutfit)
	AvatarCustomisationService.applyDescription(player, description)
	isCurrentlyEquipping = false
end

Plrs.PlayerAdded:Connect(onPlayerAdded)
PlayerEquippedOutfit.OnServerEvent:Connect(playerEquippedOutfit)
PlayerEquippedItem.OnServerEvent:Connect(playerEquippedItem)
PlayerRemovedItem.OnServerEvent:Connect(playerRemovedItem)
