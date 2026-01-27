--!strict

--[[
	This script handles the inspection GUI and all related functionality for viewing and managing
	items on mannequins.
--]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local UtiltyFolder = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local GuiManager = require(ReplicatedStorage.Libraries.GuiManager.GuiManager)
local MODAL_NAMES = require(ReplicatedStorage.Libraries.GuiManager.MODAL_NAMES)
local WardrobeGuiState = require(ReplicatedStorage.UI.FusionComponents.WardrobeGuiController.WardrobeGuiState)
local stringOfNumbersToArray = require(UtiltyFolder:WaitForChild("stringOfNumbersToArray"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))

-- Fusion
local Fusion = require(ReplicatedStorage.Utility.Fusion)
local callWithRetry = require(ReplicatedStorage.Utility.callWithRetry)
local scope = Fusion:scoped()
type UsedAs<T> = Fusion.UsedAs<T>
type Value<T> = Fusion.Value<T>
-- State
local inspectingItems: Value<{{id: number, type: Enum.MarketplaceProductType}}> = scope:Value({})
local isLoading = false

--

local Inspector = {}

function Inspector.getInspectingItems(): Fusion.Value<{{id: number, type: Enum.MarketplaceProductType}}>
	return inspectingItems
end

function Inspector.inspectMannequin(mannequin: Model)
	if isLoading then return end
	isLoading = true

	-- Clear current inspected items and grab the new ones
	inspectingItems:set({})
	local accessoryIdsString = mannequin:GetAttribute(Constants.MANNEQUIN_ACCESSORY_IDS_ATTRIBUTE) :: string
	local bundleIdsString = mannequin:GetAttribute(Constants.MANNEQUIN_BUNDLE_IDS_ATTRIBUTE) :: string
	local accessoryIds = stringOfNumbersToArray(accessoryIdsString)
	local bundleIds = stringOfNumbersToArray(bundleIdsString)

	local newItems = {}
	for _, accessoryId in accessoryIds do
		table.insert(newItems, {
			id = accessoryId, 
			type = Enum.MarketplaceProductType.AvatarAsset 
		})
	end

	for _, bundleId in bundleIds do
		table.insert(newItems, {
			id = bundleId, 
			type = Enum.MarketplaceProductType.AvatarBundle
		})
	end

	inspectingItems:set(newItems)

	-- Make the shopping GUI visible and switch to the correct view	
	WardrobeGuiState.ChangeCurrentView(Constants.WARDROBE_GUI_STATES.InspectFrame)
	GuiManager.PushCentreByName(MODAL_NAMES.WARDROBE_GUI)

	isLoading = false
end

function Inspector.inspectPlayer(player: Player)
	if isLoading then 
		return 
	end
	isLoading = true
	inspectingItems:set({})
	
	local success, humDesc = callWithRetry(function()  
		local inspectId = player.UserId >= 0 and player.UserId or Constants.DEFAULT_ID
		return Players:GetHumanoidDescriptionFromUserIdAsync(inspectId)
	end)

	if not success then
		success, humDesc = callWithRetry(function()  
			return Players:GetHumanoidDescriptionFromUserIdAsync(Constants.DEFAULT_ID)
		end)
	end

	if not success then
		warn("Failed to load humanoid description: ", success, humDesc)
		GuiManager.PopCentre()
	end
	
	local newItems = {}

	-- Collect current asset IDs from descriptions
	for _, desc in humDesc:GetChildren() do
		if (desc:IsA("AccessoryDescription") or desc:IsA("BodyPartDescription")) and desc.AssetId ~= 0 then
			table.insert(newItems, {
				id = desc.AssetId, 
				type = Enum.MarketplaceProductType.AvatarAsset 
			})		
		end
	end

	-- Collect classic items
	for _, itemType in Constants.CLASSIC_ITEMS do
		local assetId = humDesc[itemType]
		if assetId and assetId ~= 0 then
			table.insert(newItems, {
				id = assetId, 
				type = Enum.MarketplaceProductType.AvatarAsset 
			})	
		end
	end
	
	inspectingItems:set(newItems)

	WardrobeGuiState.ChangeCurrentView(Constants.WARDROBE_GUI_STATES.InspectFrame)
	GuiManager.PushCentreByName(MODAL_NAMES.WARDROBE_GUI)
	isLoading = false
	warn("done player")
end

return Inspector