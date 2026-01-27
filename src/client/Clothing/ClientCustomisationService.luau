--!strict

-- Services
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Folders
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local Constants = require(ReplicatedStorage.Constants)
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))

-- Remotes
local PlayerEquippedInspectedOutfit = Remotes:WaitForChild("PlayerEquippedInspectedOutfit")
local PlayerRemovedClassicItem = Remotes:WaitForChild("PlayerRemovedClassicItem")
local PlayerResetOutfit = Remotes:WaitForChild("PlayerResetOutfit")
local PlayerRemovedItem = Remotes:WaitForChild("PlayerRemovedItem")
local PlayerEquippedItem = Remotes:WaitForChild("PlayerEquippedItem")

-- Fusion
local Fusion = require(Utility:WaitForChild("Fusion"))
local peek = Fusion.peek
local scope = Fusion:scoped()
type UsedAs<T> = Fusion.UsedAs<T>

-- Variables
local currentlyResetting = false

local localPlayer = Players.LocalPlayer
local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid = char.Humanoid

local currentHumanoidDescription = scope:Value(humanoid:WaitForChild("HumanoidDescription") :: HumanoidDescription) 

humanoid.ChildAdded:Connect(function(child)
	if child:IsA("HumanoidDescription") then
		currentHumanoidDescription:set(child)
	end
end)

--

local ClientCustomisationService = {}

function ClientCustomisationService.ResetPlayerOutfit(player: Player): boolean
	if currentlyResetting then 
		warn("Already resetting!")
	end

	currentlyResetting = true

	local success, result = callWithRetry(
		function()	
			return PlayerResetOutfit:InvokeServer()
		end
	)

	currentlyResetting = false

	return success and result
end

function ClientCustomisationService.PlayerPurchasedItem(itemId: number)
	MarketplaceService:PromptPurchase(Players.LocalPlayer, itemId)
end

function ClientCustomisationService.AddItem(assetId: number, assetTypeOrBundleType: string, itemType: string): boolean
	local success = callWithRetry(
		function()  
			return PlayerEquippedItem:FireServer(assetId, assetTypeOrBundleType, itemType)
		end
	)

	-- Add the item tile here

	return success
end

function ClientCustomisationService.RemoveItem(assetId: number): boolean
	local success = callWithRetry(
		function()
			warn("Removing item!")
			return PlayerRemovedItem:InvokeServer(assetId)
		end
	)

	-- Remove the item tile
	return success
end

function ClientCustomisationService.PlayerEquippedInspectedOutfit(inspectedPlayer: Player)
	PlayerEquippedInspectedOutfit:FireServer(inspectedPlayer)
end

function ClientCustomisationService.RemoveClassicItem(assetId: number, itemType: string): boolean
	if table.find(Constants.DEFAULT_CLASSIC_CLOTHING_IDS_TABLE, assetId) then
		return true
	end

	local success = callWithRetry(function()  
		return PlayerRemovedClassicItem:FireServer(assetId, itemType)
	end)

	return success
end

function ClientCustomisationService.GetCurrentEquippedItems(): {any}
	return peek(currentHumanoidDescription):GetChildren()
end

return ClientCustomisationService