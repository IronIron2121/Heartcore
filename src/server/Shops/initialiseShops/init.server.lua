--!strict
-- Services
local ReplicatedStorage   		= game:GetService("ReplicatedStorage")
local DataStoreService 	  		= game:GetService("DataStoreService")
local Players 			  		= game:GetService("Players")

-- Folders
local Trackers 					= ReplicatedStorage:WaitForChild("Trackers")
local UtilityFolder 			= ReplicatedStorage:WaitForChild("Utility")
local RemotesFolder 		 	= ReplicatedStorage:WaitForChild("Remotes")
local Classes 					= ReplicatedStorage:WaitForChild("Classes")

local playerShops 		  		= workspace:WaitForChild("PlayerShops")

-- Module Scripts
local waitForShops 		  		= require(UtilityFolder:WaitForChild("waitForShops"))
local Types 					= require(UtilityFolder:WaitForChild("Types"))
local Constants 		  		= require(ReplicatedStorage:WaitForChild("Constants"))
local Shop						= require(Classes:WaitForChild("ShopDetails"))
local ShopTracker 				= require(Trackers:WaitForChild("ShopTracker"))
local PlayerTracker 			= require(Trackers:WaitForChild("PlayerTracker"))

-- Datastores
local ownedItemsDataStore		= DataStoreService:GetDataStore(Constants.OWNEDITEMS_DATASTORE)

-- Instances
local localPlayer 		  		= Players.LocalPlayer
local playerShopsDataStore 		= DataStoreService:GetDataStore(Constants.PLAYER_SHOPS_DATA_STORE_NAME)

-- TODO: Delete this block
local function initialisePlayerDatastore(player: Player)
	playerShopsDataStore:SetAsync(player.UserId, {})
	-- TODO: Add below item to onPlayerAdded or w/e
	ownedItemsDataStore:SetAsync(player.UserId, {})
end

local function initialise()
	print("Waiting for shops")
	-- Wait for shops to load in
	waitForShops()
	print("Shops now loaded")
	
	for _, shop in pairs(playerShops:GetChildren()) do
		for _, part in pairs(shop:GetChildren()) do
			if part.Name == "shopFloor" then
				local shop = Shop.new(part)
				ShopTracker.trackNewShop(shop)  
			end
		end
	end 
end

initialise()
