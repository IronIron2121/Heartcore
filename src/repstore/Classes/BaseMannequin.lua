--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Classes = ReplicatedStorage:WaitForChild("Classes")
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local arrayOfNumbersToString = require(Utility:WaitForChild("arrayOfNumbersToString"))
local stringOfNumbersToArray = require(Utility:WaitForChild("stringOfNumbersToArray")) 
local MarketplaceUtilities = require(Utility:WaitForChild("MarketplaceUtilities"))
local MannequinUtilities = require(Utility:WaitForChild("MannequinUtilities"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local BaseShopItem = require(Classes:WaitForChild("BaseShopItem"))
local Types = require(Utility:WaitForChild("Types"))

--

local BaseMannequin = setmetatable({}, BaseShopItem)
BaseMannequin.__index = BaseMannequin


function BaseMannequin:_getBundleIdArray() : {number} ?
	local bundleIdsString = self.instance:GetAttribute(Constants.MANNEQUIN_BUNDLE_IDS_ATTRIBUTE) :: string
	local bundleIdArray = stringOfNumbersToArray(bundleIdsString)
	return bundleIdArray
end

function BaseMannequin:_getAccessoryIdArray() : {number} ? 
	local accessoryIdsString = self.instance:GetAttribute(Constants.MANNEQUIN_ACCESSORY_IDS_ATTRIBUTE) :: string
	local accessoryIdArray = stringOfNumbersToArray(accessoryIdsString)
	return accessoryIdArray
end

function BaseMannequin.new(shopItemRecipe : Types.ShopItemRecipe)
	local newMannequin = BaseShopItem.new(shopItemRecipe)
	
	setmetatable(newMannequin, BaseMannequin)
	
	newMannequin[Constants.MANNEQUIN_ACCESSORY_IDS_ATTRIBUTE] = {}
	newMannequin[Constants.MANNEQUIN_BUNDLE_IDS_ATTRIBUTE] = {}
	
	--local inspectPrompt = newMannequin:_initialiseInspectPrompt()
	--inspectPrompt.Parent = newMannequin.instance
	 
	return newMannequin :: Types.BaseMannequin
end

function BaseMannequin:getAllAssetIds()
	-- return combined accessory and bundle ids
	local allIds = {
		[Constants.MANNEQUIN_ACCESSORY_IDS_ATTRIBUTE] = {self[Constants.ACCESSORY_IDS_ATTRIBUTE]},
		[Constants.MANNEQUIN_BUNDLE_IDS_ATTRIBUTE] = {self[Constants.MANNEQUIN_BUNDLE_IDS_ATTRIBUTE]}
	}
	
	return allIds
end

function BaseMannequin:isAccessoryEquipped(accessoryId : number)
	return table.find(self[Constants.MANNEQUIN_ACCESSORY_IDS_ATTRIBUTE], accessoryId)
end

function BaseMannequin:_initialiseInspectPrompt()
	-- TODO: constant these parameters
	local inspectPrompt = Instance.new("ProximityPrompt")
	inspectPrompt.ActionText = "inspect"
	inspectPrompt.ClickablePrompt = true
	inspectPrompt.Enabled = true
	inspectPrompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	inspectPrompt.HoldDuration = 0
	inspectPrompt.KeyboardKeyCode = Enum.KeyCode.E
	inspectPrompt.MaxActivationDistance = 8
	inspectPrompt.Name = "InspectPrompt"
	inspectPrompt.Triggered:Connect(function(player : Player)
		
	end)
	
	return inspectPrompt
end

function BaseMannequin:addAccessory(accessoryId : number)
	warn("Not implemented in BaseMannequin.addAccessory()")
end

function BaseMannequin.removeAccessory(itemId : string)
	warn("Not implemented in BaseMannequin.addAccessory()")
end


-- TODO: THis will do for now, but could probably be optimised
function BaseMannequin:_addAssetIdToInstance(assetId : number)
	local assetType = MarketplaceUtilities.getAssetTypeFromAssetId(assetId) :: number
	
	if assetType == Constants.BUNDLE_TYPE_ID then
		local bundleIdArray = self:_getBundleIdArray() 
		if not bundleIdArray then
			warn("No bundle ids for this mannequin!")
			return
		end

		if table.find(bundleIdArray, assetId) then
			--TODO: GUI Pop-Up saying already added!
			warn("Asset already added to mannequin!")
			return
		else
			table.insert(bundleIdArray, assetId)
		end

		self[Constants.MANNEQUIN_BUNDLE_IDS_ATTRIBUTE] = bundleIdArray
		
		local bundleIdsString = arrayOfNumbersToString(bundleIdArray) 
		self.instance:SetAttribute(Constants.MANNEQUIN_BUNDLE_IDS_ATTRIBUTE, bundleIdsString)

	elseif assetType == Constants.ASSET_TYPE_ID then
		local accessoryIdArray = self:_getAccessoryIdArray()
		if not accessoryIdArray then
			return
		end
		
		if table.find(accessoryIdArray, assetId) then
			--TODO: GUI Pop-Up saying already added!
			warn("Asset already added to mannequin")
			return
		else
			table.insert(accessoryIdArray, assetId)
		end
		
		self[Constants.MANNEQUIN_ACCESSORY_IDS_ATTRIBUTE] = accessoryIdArray

		local accessoryIdsString = arrayOfNumbersToString(accessoryIdArray)
		self.instance:SetAttribute(Constants.MANNEQUIN_ACCESSORY_IDS_ATTRIBUTE, accessoryIdsString)
	else
		warn("No asset type identified with ", assetId, assetType)
		return
	end
end

function BaseMannequin:_removeAssetIdFromInstance(accessoryId : number)
	-- Get the mannequin that the player is requesting to delete
	if not self.instance then 
		return 
	end
	
	local productType = MarketplaceUtilities.getAssetTypeFromAssetId(accessoryId)
	if not productType then
		return
	end

	local accessoryIdsString = self.instance:GetAttribute(Constants.MANNEQUIN_ACCESSORY_IDS_ATTRIBUTE)
	local bundleIdsString = self.instance:GetAttribute(Constants.MANNEQUIN_BUNDLE_IDS_ATTRIBUTE)

	if productType == Constants.BUNDLE_TYPE_ID then
		local bundleIds = stringOfNumbersToArray(bundleIdsString)
		for index, id in bundleIds do
			if id == accessoryId then
				table.remove(bundleIds, index)
			end
		end
		-- Convert the bundle IDs array back into a string
		bundleIdsString = arrayOfNumbersToString(bundleIds) 
		self[Constants.MANNEQUIN_BUNDLE_IDS_ATTRIBUTE] = bundleIds
		self.instance:SetAttribute(Constants.MANNEQUIN_BUNDLE_IDS_ATTRIBUTE, bundleIdsString)

	elseif productType == Constants.ASSET_TYPE_ID then
		local accessoryIds: {number} = stringOfNumbersToArray(accessoryIdsString)
		for index, id in accessoryIds do
			if id == accessoryId then
				table.remove(accessoryIds, index)
			end
		end
		-- Convert the accessory IDs array back into a string
		accessoryIdsString = arrayOfNumbersToString(accessoryIds) 
		self[Constants.MANNEQUIN_ACCESSORY_IDS_ATTRIBUTE] = accessoryIds
		self.instance:SetAttribute(Constants.MANNEQUIN_ACCESSORY_IDS_ATTRIBUTE, accessoryIdsString)
	end
end






return BaseMannequin
  