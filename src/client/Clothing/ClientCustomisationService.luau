--!strict

-- Services
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Folders
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local StarterPlayer = game:GetService("StarterPlayer")
local Inspector = require(StarterPlayer.StarterPlayerScripts.Mannequins.Inspector)
local Constants = require(ReplicatedStorage.Constants)
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))

-- Remotes
local PlayerEquippedInspectedItemsRF = Remotes:WaitForChild("PlayerEquippedInspectedItemsRF")
local PlayerEquippedInspectedPlayer = Remotes:WaitForChild("PlayerEquippedInspectedPlayer")
local PlayerRemovedAllAccessoriesRF = Remotes:WaitForChild("PlayerRemovedAllAccessoriesRF")
local PlayerRemovedClassicItem = Remotes:WaitForChild("PlayerRemovedClassicItem")
local PlayerResetOutfit = Remotes:WaitForChild("PlayerResetOutfit")
local PlayerRemovedItem = Remotes:WaitForChild("PlayerRemovedItem")
local PlayerEquippedItemRF = Remotes:WaitForChild("PlayerEquippedItemRF")

-- Fusion
local Fusion = require(Utility:WaitForChild("Fusion"))
local peek = Fusion.peek
local scope = Fusion:scoped()
type UsedAs<T> = Fusion.UsedAs<T>

-- Variables
local currentlyResetting = false
local isEquipping = false

local localPlayer = Players.LocalPlayer
local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")

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
	local success, err = callWithRetry(function()  
		return MarketplaceService:PromptPurchase(Players.LocalPlayer, itemId)
	end)

	if not success then warn(err) end

	return success
end

function ClientCustomisationService.AddItem(assetId: number, assetTypeOrBundleType: string, itemType: string): boolean
	if isEquipping then 
		warn("Already equipping!")
		return true 
	end
	warn("Adding...")
	isEquipping = true
	local success = callWithRetry(
		function()  
			return PlayerEquippedItemRF:InvokeServer(assetId, assetTypeOrBundleType, itemType)
		end
	)
	isEquipping = false
	return success
end

function ClientCustomisationService.RemoveItem(assetId: number): boolean
	local success = callWithRetry(
		function()
			return PlayerRemovedItem:InvokeServer(assetId)
		end
	)

	return success
end

function ClientCustomisationService.PlayerEquippedInspectedPlayer(description: HumanoidDescription): boolean
	local success = callWithRetry(function()
		return PlayerEquippedInspectedPlayer:FireServer(description)
	end)

	return success
end

function ClientCustomisationService.RemoveAllAccessories(): boolean
	local success = callWithRetry(function()  
		return PlayerRemovedAllAccessoriesRF:InvokeServer()
	end)

	return success
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

function ClientCustomisationService.PlayerEquippedInspectedItems()
	local items = peek(Inspector.getInspectingItems())
	callWithRetry(function()
		return PlayerEquippedInspectedItemsRF:InvokeServer(items)
	end)
end

function ClientCustomisationService.GetCurrentEquippedItems(): {any}
	return peek(currentHumanoidDescription):GetChildren()
end

return ClientCustomisationService