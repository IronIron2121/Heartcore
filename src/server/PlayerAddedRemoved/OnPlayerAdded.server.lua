--!strict

-- Services
local ServerScriptService 		= game:GetService("ServerScriptService")
local ReplicatedStorage 		= game:GetService("ReplicatedStorage")
local DataStoreService 			= game:GetService("DataStoreService")
local Players 					= game:GetService("Players")

-- Folders
local DataTables	= ReplicatedStorage:WaitForChild("DataTables")
local Trackers 		= ReplicatedStorage:WaitForChild("Trackers")
local Classes 		= ReplicatedStorage:WaitForChild("Classes")
local Utility 		= ReplicatedStorage:WaitForChild("Utility")
local Remotes 		= ReplicatedStorage:WaitForChild("Remotes") 
local Voting 		= ServerScriptService:WaitForChild("Voting")



-- Module Scripts
local PlayerViewedOutfitsTracker = require(Voting:WaitForChild("PlayerViewedOutfitsTracker"))
local arrayOfNumbersToString 	= require(Utility:WaitForChild("arrayOfNumbersToString"))
local Constants 				= require(ReplicatedStorage:WaitForChild("Constants")) 
local BuyableShopItems			= require(DataTables:WaitForChild("BuyableShopItems"))
local PlayerTracker 			= require(Trackers:WaitForChild("PlayerTracker"))
local PlayerDetails 			= require(Classes:WaitForChild("PlayerDetails"))

-- Datastores
local ownedItemsDataStore		= DataStoreService:GetDataStore(Constants.OWNEDITEMS_DATASTORE)
local PlayerClothingDatastore 	= DataStoreService:GetDataStore(Constants.PLAYER_CLOTHING_DATASTORE)

-- Remotes / Bindables
local UpdateLocalPlayerDetailsAsync = Remotes:WaitForChild("UpdateLocalPlayerDetails")


-- A table with all names of accessory attributes in a HumanoidDescription
local HUMANOID_ACCESSORY_ATTRIBUTES = {
	"BackAccessory",
	"FaceAccessory",
	"FrontAccessory",
	"HairAccessory",
	"HatAccessory",
	"NeckAccessory",
	"ShouldersAccessory",
	"WaistAccessory",
	"Shirt",
	"Pants",
	"GraphicTShirt",
	"Head",
	"LeftArm",
	"LeftLeg",
	"RightArm",
	"RightLeg",
	"Torso",
}

-- Grabs all accessory IDs from player and adds them to a table
local function getAccessoryAttributes(humanoid: Humanoid, attributesArray: {})
	local clothingTable = {}
	local humanoidDescription = humanoid:GetAppliedDescription() :: HumanoidDescription

	for index, attribute in pairs(attributesArray) do
		local accessoryId = tonumber((humanoidDescription :: any)[attribute])
		if accessoryId ~= 0 and accessoryId ~= nil then
			table.insert(clothingTable, accessoryId)
		end
	end
	return clothingTable
end

local function onCharacterAdded(character: Model)
	local humanoid 		= character:WaitForChild("Humanoid") :: Humanoid
	humanoid.WalkSpeed 	= 32
end

local function updatePlayerOwnedItems(playerOwnedItems: {})

end

local function initialiseOwnedItemsDatastore(userId: number)
	local stringId = tostring(userId)
	local playerOwnedItems
	
	-- Make sure the data is there
	local success, error = pcall(function()
		ownedItemsDataStore:UpdateAsync(tostring(userId), function(oldData)
			local playerOwnedItems = oldData or {}
			for itemName, itemDetails in pairs(BuyableShopItems) do
				local itemName = itemDetails["Name"]
				if not playerOwnedItems[itemName] then
					playerOwnedItems[itemName] = "false"
				else
					--print(itemName, "already added", playerOwnedItems[itemName])
				end
			end
			return playerOwnedItems					
		end)
	end)
	if not success then 
		warn("Failed to load owned items data for player ", userId)
		return 
	end
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(onCharacterAdded)
	local playerDetails = PlayerDetails.new(player)
	if playerDetails then
		PlayerTracker.startTrackingPlayer(playerDetails)
		UpdateLocalPlayerDetailsAsync:FireClient(player, playerDetails)
	else
		assert(playerDetails, "Failed to create player details")
	end
	initialiseOwnedItemsDatastore(player.UserId)

	PlayerViewedOutfitsTracker.OnPlayerAdded(player)
end


Players.PlayerAdded:Connect(onPlayerAdded)