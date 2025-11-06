--!strict

--[[
	This script handles setting up mannequin clothing and appearance.
	SERVER-SIDE: Handles asset loading and humanoid description setup.
--]]

-- Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local InsertService = game:GetService("InsertService")
local AssetService = game:GetService("AssetService")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local stringOfNumbersToArray = require(Utility:WaitForChild("stringOfNumbersToArray"))
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))

local function makeMannequinInvisible(mannequin: Instance)
	for _, part in mannequin:GetDescendants() do
		if part:IsA("BasePart") then
			part.Transparency = 1
		end
	end
end

--
local function clearHumanoidDescriptionChildren(humanoid: Humanoid)


	return true
end

local function setupMannequinAsync(mannequin: Instance)
	-- Get the list of accessories, bundles, and skin color to apply to the mannequin
	local accessoryIdsString = mannequin:GetAttribute(Constants.MANNEQUIN_ACCESSORY_IDS_ATTRIBUTE)
	local bundleIdsString = mannequin:GetAttribute(Constants.MANNEQUIN_BUNDLE_IDS_ATTRIBUTE)

	-- Bundles usually contain body parts; any mannequins without body parts can be totally invisible
	if bundleIdsString == "" or not bundleIdsString then
		makeMannequinInvisible(mannequin)
	end

	-- Convert the accessory and bundle ID strings into arrays
	local accessoryIds = stringOfNumbersToArray(accessoryIdsString)
	local bundleIds = stringOfNumbersToArray(bundleIdsString)

	local humanoid = mannequin:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end

	local humDesc = humanoid:WaitForChild("HumanoidDescription", 1)
	if not humDesc then return false end

	for _, description in ipairs(humDesc:GetChildren()) do
		if description:IsA("AccessoryDescription") then
			description:Destroy()
		end
	end

	assert(humanoid, "No humanoid found for " .. mannequin.Name .. "!")

	-- Apply accessories to the mannequin
	for _, accessoryId in accessoryIds do
		local success, asset = pcall(function()
			return InsertService:LoadAsset(accessoryId)
		end)
		
		if success and asset then
			local accessory = asset:FindFirstChildOfClass("Accessory")
			if accessory then
				humanoid:AddAccessory(accessory)
			else
				warn("No accessory found in asset " .. accessoryId .. " for mannequin " .. mannequin.Name)
			end
		else
			warn("Failed to load accessory " .. accessoryId .. " for mannequin " .. mannequin.Name)
		end
	end

	-- TODO: It could be nice to turn this into a "MannequinCustomisationService", like we have for player avatars
	if #bundleIds > 0 then
		local bodyParts = {}
		for _, bundleId in ipairs(bundleIds) do
			-- Get the bundle details
			local success, bundleInfo = callWithRetry(function()
				return AssetService:GetBundleDetailsAsync(bundleId)
			end, 3)

			if success then
				print(("gaddeee"))
				warn(success, bundleInfo)
			else
				warn("Failed to get bundle!", success, bundleId)
			end
			local bundleItems = bundleInfo.Items
		

			for _, item in ipairs(bundleItems) do
				if item.Type ~= "UserOutfit" then

					local assetSuccess, assetInfo = callWithRetry(function()
						return MarketplaceService:GetProductInfo(item.Id, Enum.InfoType.Asset)
					end, 3)

					if assetSuccess and assetInfo then
						if assetInfo.AssetTypeId == 19 then
							warn("gear!")
							continue
						elseif assetInfo.AssetTypeId == 79 then
							table.insert(bodyParts, {
								itemId = item.Id,
								bodyPartType = Enum.BodyPart.Head.Name
							})
						elseif table.find(Constants.ANIMATION_ASSET_TYPE_IDS, assetInfo.AssetTypeId) then
							warn("Item is an animation!")
							continue
						else
							-- We should probably disambiguate between Accessories and Bodyparts here
							local assetTypeEnum = Enum.AssetType:FromValue(assetInfo.AssetTypeId)
							if assetTypeEnum then
								table.insert(bodyParts, {
									itemId = item.Id,
									bodyPartType = assetTypeEnum.Name
								})
							else
								warn("Failed to get assetType for", assetTypeEnum)
							end
						end
					end
				end
			end

			local clonedDescription = humanoid:WaitForChild("HumanoidDescription", 1) :: HumanoidDescription
			if not clonedDescription then return end

			for _, bodyPart in ipairs(bodyParts) do
				local bodyPartEnum = Enum.BodyPart[bodyPart.bodyPartType]
				if not bodyPartEnum then
					warn("Bad bodypart type:", bodyPart.bodyPartType)
					continue
				end

				-- Remove existing body part on the same slot after copying its colours
				local bodyPartDescription = Instance.new("BodyPartDescription")
				for _, description in ipairs(clonedDescription:GetChildren()) do
					if description:IsA("BodyPartDescription") and description.BodyPart == bodyPartEnum then
						bodyPartDescription.Color = description.Color
						description:Destroy()
					end
				end

				-- Create and add new body part
				bodyPartDescription.AssetId = bodyPart.itemId
				bodyPartDescription.BodyPart = bodyPartEnum
				bodyPartDescription.Parent = clonedDescription
			end

			humanoid:ApplyDescription(clonedDescription)
			warn("Just applied desc to mannequin!")
			warn(bodyParts)

			-- Get the asset details of every part in the bundle
			-- Compare that to a list containing the correspondence between body parts and rig MeshParts
			-- Add every part in the bundle to a list
		end
		-- Make all mesh part children of the rig that aren't affected by the bundle invisible
	end
end

local function onMannequinAdded(mannequin: Model)
	-- Wait for humanoid to be ready
	local humanoid = mannequin:WaitForChild("Humanoid", 5)
	if not humanoid then
		warn("Timed out waiting for humanoid in mannequin:", mannequin.Name)
		return
	end

	-- Setup clothing asynchronously to avoid delays
	task.spawn(function()
		setupMannequinAsync(mannequin)
	end)
end

local function onMannequinRemoved(mannequin: Instance)
	print("Mannequin removed:", mannequin.Name)
	-- Cleanup logic if needed
end

local function initialise()
	-- Set up mannequin tracking
	CollectionService:GetInstanceAddedSignal(Constants.FLOOR_MANNEQUIN_TAG):Connect(onMannequinAdded)
	CollectionService:GetInstanceRemovedSignal(Constants.FLOOR_MANNEQUIN_TAG):Connect(onMannequinRemoved)

	-- Initialise existing mannequins
	for _, mannequin in CollectionService:GetTagged(Constants.FLOOR_MANNEQUIN_TAG) do
		onMannequinAdded(mannequin)
	end
end

initialise() 