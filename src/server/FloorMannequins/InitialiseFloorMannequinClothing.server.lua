--!strict

--[[
	This script handles setting up mannequin clothing and appearance.
	SERVER-SIDE: Handles asset loading and humanoid description setup.
--]]

-- Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")
local AssetService = game:GetService("AssetService")
local Players = game:GetService("Players")

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

local function setupMannequinAsync(mannequin: Instance)
	local accessoryIdsString = mannequin:GetAttribute(Constants.MANNEQUIN_ACCESSORY_IDS_ATTRIBUTE)
	local bundleIdsString = mannequin:GetAttribute(Constants.MANNEQUIN_BUNDLE_IDS_ATTRIBUTE)

	if bundleIdsString == "" or not bundleIdsString then
		makeMannequinInvisible(mannequin)
	end

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

	for _, accessoryId in accessoryIds do
		local success, asset = callWithRetry(
			function()
				return InsertService:LoadAsset(accessoryId)
			end
		)
		
		if success and asset then
			local accessory = asset:FindFirstChildOfClass("Accessory")
			if accessory then
				humanoid:AddAccessory(accessory)
			else
				warn("No accessory found in asset " .. accessoryId .. " for mannequin " .. mannequin.Name)
			end
		else
			warn("Failed to load accessory " .. accessoryId .. " for mannequin ")
		end
	end

	if #bundleIds > 0 then
		local bodyParts = {}
		
		for _, bundleId in ipairs(bundleIds) do
			-- Get each bundle's details
			local success, bundleInfo = callWithRetry(function()
				return AssetService:GetBundleDetailsAsync(bundleId)
			end, 3)

			if not success then
				warn("Failed to get bundle!", bundleId)
				continue
			end
			
			-- Extract the constituent items
			local bundleItems = bundleInfo.Items

			for _, item in ipairs(bundleItems) do
				if item.Type == "UserOutfit" then
					local descSuccess, outfitDescription = pcall(
						function()
							return Players:GetHumanoidDescriptionFromOutfitId(item.Id)
						end
					)

					if descSuccess then
						humanoid:ApplyDescriptionResetAsync(outfitDescription)
					end
					break
				end
			end
		end
	end

	return true
end

local function onMannequinAdded(mannequin: Model)
	local humanoid = mannequin:WaitForChild("Humanoid", 5)
	if not humanoid then
		warn("Timed out waiting for humanoid in mannequin:", mannequin.Name)
		return
	end

	task.spawn(function()
		setupMannequinAsync(mannequin)
	end)
end

local function onMannequinRemoved(mannequin: Instance)
	print("Mannequin removed:", mannequin.Name)
end

local function initialise()
	CollectionService:GetInstanceAddedSignal(Constants.FLOOR_MANNEQUIN_TAG):Connect(onMannequinAdded)
	CollectionService:GetInstanceRemovedSignal(Constants.FLOOR_MANNEQUIN_TAG):Connect(onMannequinRemoved)

	for _, mannequin in CollectionService:GetTagged(Constants.FLOOR_MANNEQUIN_TAG) do
		onMannequinAdded(mannequin)
	end
end

initialise()