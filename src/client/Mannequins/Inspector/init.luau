--!strict

--[[
	This script handles the inspection GUI and all related functionality for viewing and managing
	items on mannequins.
--]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AvatarEditorService = game:GetService("AvatarEditorService")

-- Folders
local UtiltyFolder = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local ItemFilters = require(ReplicatedStorage.Client.EquipFrame.ItemFilters)
local getHumanoidDescriptionFromPlayer = require(ReplicatedStorage.Getters.getHumanoidDescriptionFromPlayer)
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
local inspectingItems: Value<{{id: number, type: Enum.MarketplaceProductType, itemDetails: {}}}> = scope:Value({})
local isLoading = false
local isLoadingVisible: Value<boolean> = scope:Value(false)

local detailsCache = {}

--

local Inspector = {}

function Inspector.getInspectingItems(): Fusion.Value<{{id: number, type: Enum.MarketplaceProductType, itemDetails: {}}}>
	return inspectingItems
end

function Inspector.getIsLoadingVisible(): Value<boolean>
	return isLoadingVisible
end

function Inspector.inspectMannequin(mannequin: Model)
	if isLoading then return end
	isLoading = true

	inspectingItems:set({})
	isLoadingVisible:set(true)

	-- Show GUI immediately
	WardrobeGuiState.ChangeCurrentView(Constants.WARDROBE_GUI_STATES.InspectFrame)
	GuiManager.PushCentreByName(MODAL_NAMES.WARDROBE_GUI)

	task.spawn(function()
		local accessoryIdsString = mannequin:GetAttribute(Constants.MANNEQUIN_ACCESSORY_IDS_ATTRIBUTE) :: string
		local bundleIdsString = mannequin:GetAttribute(Constants.MANNEQUIN_BUNDLE_IDS_ATTRIBUTE) :: string
		local accessoryIds = stringOfNumbersToArray(accessoryIdsString)
		local bundleIds = stringOfNumbersToArray(bundleIdsString)

		local newItems = {}
		for _, accessoryId in accessoryIds do
			local success, itemDetails = nil, detailsCache[accessoryId]
			if not itemDetails then
				success, itemDetails = callWithRetry(
					function()
						return AvatarEditorService:GetItemDetailsAsync(accessoryId, Enum.AvatarItemType.Asset)
					end
				)
				if not success then
					return
				else
					detailsCache[accessoryId] = itemDetails
				end
			end
			table.insert(newItems, {
				id = accessoryId,
				type = Enum.MarketplaceProductType.AvatarAsset,
				itemDetails = itemDetails
			})
		end

		for _, bundleId in bundleIds do
			local success, itemDetails = nil, detailsCache[bundleId]
			if not itemDetails then
				success, itemDetails = callWithRetry(
					function()
						return AvatarEditorService:GetItemDetailsAsync(bundleId, Enum.AvatarItemType.Bundle)
					end
				)
				if not success then
					return
				else
					detailsCache[bundleId] = itemDetails
				end
			end
			table.insert(newItems, {
				id = bundleId,
				type = Enum.MarketplaceProductType.AvatarBundle,
				itemDetails = nil
			})
		end

		inspectingItems:set(newItems)
		isLoadingVisible:set(false)
		isLoading = false
	end)
end

function Inspector.inspectDescription(description: HumanoidDescription)
	if isLoading then
		return
	end
	isLoading = true

	inspectingItems:set({})
	isLoadingVisible:set(true)

	-- Show GUI immediately
	WardrobeGuiState.ChangeCurrentView(Constants.WARDROBE_GUI_STATES.InspectFrame)
	GuiManager.PushCentreByName(MODAL_NAMES.WARDROBE_GUI)

	task.spawn(function()
		local newItems = {}

		-- Collect current asset IDs from descriptions
		for _, desc in description:GetChildren() do
			if (desc:IsA("AccessoryDescription") or desc:IsA("BodyPartDescription")) and desc.AssetId ~= 0 then
				local accSuccess, itemDetails = nil, detailsCache[desc.AssetId]
				if not itemDetails then
					accSuccess, itemDetails = callWithRetry(
						function()
							return AvatarEditorService:GetItemDetailsAsync(desc.AssetId, Enum.AvatarItemType.Asset)
						end
					)
					if not accSuccess then
						continue
					else
						detailsCache[desc.AssetId] = itemDetails
					end
				end
				table.insert(newItems, {
					id = desc.AssetId,
					type = Enum.MarketplaceProductType.AvatarAsset,
					itemDetails = itemDetails or "NO ITEM DETAILS??"
				})
			end

			warn(newItems)
		end

		-- Collect classic items
		for _, itemType in Constants.CLASSIC_ITEMS do
			local assetId = description[itemType]
			if assetId and assetId ~= 0 then
				local accSuccess, itemDetails = nil, detailsCache[assetId]
				if not itemDetails then
					accSuccess, itemDetails = callWithRetry(
						function()
							return AvatarEditorService:GetItemDetailsAsync(assetId, Enum.AvatarItemType.Asset)
						end
					)
					if not accSuccess then
						continue
					else
						detailsCache[assetId] = itemDetails
					end
				end
				table.insert(newItems, {
					id = assetId,
					type = Enum.MarketplaceProductType.AvatarAsset,
					itemDetails = itemDetails or "NO ITEM DETAILS??"
				})
			end
		end

		inspectingItems:set(newItems)
		isLoadingVisible:set(false)
		isLoading = false
	end)
end

function Inspector.inspectPlayer(player: Player)
	if isLoading then
		return
	end
	isLoading = true

	inspectingItems:set({})
	isLoadingVisible:set(true)

	-- Show GUI immediately
	WardrobeGuiState.ChangeCurrentView(Constants.WARDROBE_GUI_STATES.InspectFrame)
	GuiManager.PushCentreByName(MODAL_NAMES.WARDROBE_GUI)

	task.spawn(function()
		local success, humDesc = callWithRetry(
			function()
				return getHumanoidDescriptionFromPlayer(player)
			end
		)

		if not success then
			success, humDesc = callWithRetry(function()
				return Players:GetHumanoidDescriptionFromUserIdAsync(Constants.DEFAULT_ID)
			end)
		end

		if not success then
			warn("Failed to load humanoid description: ", success, humDesc)
			isLoadingVisible:set(false)
			isLoading = false
			GuiManager.PopCentre()
			return
		end

		local newItems = {}

		-- Collect current asset IDs from descriptions
		for _, desc in humDesc:GetChildren() do
			if (desc:IsA("AccessoryDescription") or desc:IsA("BodyPartDescription")) and desc.AssetId ~= 0 then
				local accSuccess, itemDetails = nil, detailsCache[desc.AssetId]
				if not itemDetails then
					accSuccess, itemDetails = callWithRetry(
						function()
							return AvatarEditorService:GetItemDetailsAsync(desc.AssetId, Enum.AvatarItemType.Asset)
						end
					)
					if not accSuccess then
						return
					else
						detailsCache[desc.AssetId] = itemDetails
					end
				end
				table.insert(newItems, {
					id = desc.AssetId,
					type = Enum.MarketplaceProductType.AvatarAsset,
					itemDetails = itemDetails
				})
			end
		end

		-- Collect classic items
		for _, itemType in Constants.CLASSIC_ITEMS do
			local assetId = humDesc[itemType]
			if assetId and assetId ~= 0 then
				local accSuccess, itemDetails = nil, detailsCache[assetId]
				if not itemDetails then
					accSuccess, itemDetails = callWithRetry(
						function()
							return AvatarEditorService:GetItemDetailsAsync(assetId, Enum.AvatarItemType.Asset)
						end
					)
					if not accSuccess then
						return
					else
						detailsCache[assetId] = itemDetails
					end
				end
				table.insert(newItems, {
					id = assetId,
					type = Enum.MarketplaceProductType.AvatarAsset
				})
			end
		end

		inspectingItems:set(newItems)
		isLoadingVisible:set(false)
		isLoading = false
	end)
end

return Inspector