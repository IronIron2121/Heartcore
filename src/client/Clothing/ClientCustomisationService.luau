--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Folders
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))

-- Remotes
local PlayerResetOutfit = Remotes:WaitForChild("PlayerResetOutfit")
local PlayerRemovedItem = Remotes:WaitForChild("PlayerRemovedItem")
local PlayerEquippedItem = Remotes:WaitForChild("PlayerEquippedItem")

-- Fusion
local Fusion = require(Utility:WaitForChild("Fusion"))
local scope = Fusion:scoped()
type UsedAs<T> = Fusion.UsedAs<T>

-- Variables
local currentlyResetting = false

local localPlayer = Players.LocalPlayer
local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid = char.Humanoid

local currentHumanoidDescription = scope:Value(humanoid:WaitForChild("HumanoidDescription") :: HumanoidDescription) 

local currentItemDescriptions = scope:Computed(function(use)
	return use(currentHumanoidDescription):GetChildren() :: {AccessoryDescription | BodyPartDescription}
end)

--

local ClientCustomisationService = {}

function ClientCustomisationService.ResetPlayerOutfit(player: Player)
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

function ClientCustomisationService.AddItem(assetId: number, assetTypeOrBundleType: string, itemType: string)
	PlayerEquippedItem:FireServer(assetId, assetTypeOrBundleType, itemType)
end

function ClientCustomisationService.RemoveItem(assetId: number)
	return PlayerRemovedItem:InvokeServer(assetId)	
end

function ClientCustomisationService.GetCurrentEquippedItems()
	return currentItemDescriptions
end

return ClientCustomisationService