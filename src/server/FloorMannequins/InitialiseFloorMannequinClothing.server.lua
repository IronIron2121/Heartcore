--!strict

--[[
	This script handles setting up mannequin clothing and appearance.
	SERVER-SIDE: Handles asset loading and humanoid description setup.
--]]

-- Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local applyItemsToDescriptionAsync = require(Utility:WaitForChild("applyItemsToDescriptionAsync"))
local setDescriptionSkinColor = require(Utility:WaitForChild("setDescriptionSkinColor"))
local stringOfNumbersToArray = require(Utility:WaitForChild("stringOfNumbersToArray"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))

local function makeMannequinInvisible(mannequin: Instance)
	for _, part in mannequin:GetDescendants() do
		if part:IsA("BasePart") then
			part.Transparency = 1
		end
	end
end

local function setupMannequinAsync(mannequin: Instance)
	makeMannequinInvisible(mannequin)
	-- Get the list of accessories, bundles, and skin color to apply to the mannequin
	local accessoryIdsString = mannequin:GetAttribute(Constants.MANNEQUIN_ACCESSORY_IDS_ATTRIBUTE)
	local bundleIdsString = mannequin:GetAttribute(Constants.MANNEQUIN_BUNDLE_IDS_ATTRIBUTE)

	-- Convert the accessory and bundle ID strings into arrays
	local accessoryIds = stringOfNumbersToArray(accessoryIdsString)
	local bundleIds = stringOfNumbersToArray(bundleIdsString)

	local humanoid = mannequin:FindFirstChildOfClass("Humanoid")
	assert(humanoid, "No humanoid found for " .. mannequin.Name .. "!!")

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

	-- Note: Bundle handling might need additional logic depending on your requirements
	-- You may want to apply bundles to the humanoid description here as well
	if #bundleIds > 0 then
		-- Add bundle handling logic here if needed
		print("Mannequin has bundles:", bundleIds, "- bundle setup not implemented yet")
	end
	
	--print("Finished setting up clothing for mannequin:", mannequin.Name)
end

local function onMannequinAdded(mannequin: Model)
	--print("Setting up mannequin clothing:", mannequin.Name)
	
	-- Wait for humanoid to be ready
	local humanoid = mannequin:WaitForChild("Humanoid", 5)
	if not humanoid then
		warn("Timed out waiting for humanoid in mannequin:", mannequin.Name)
		return
	end

	-- Setup clothing asynchronously to avoid blocking
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
		--print("Initialising clothing for existing mannequin:", mannequin.Name)
		onMannequinAdded(mannequin)
	end
end

initialise() 