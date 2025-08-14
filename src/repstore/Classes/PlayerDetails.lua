--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService 	= game:GetService("DataStoreService")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Remotes 	= ReplicatedStorage:WaitForChild("Remotes")

-- Modules
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local Types = require(Utility:WaitForChild("Types"))

-- Remotes / Bindables
local PlayerClaimedShopAsync = Remotes:WaitForChild("PlayerClaimedShop")
local PlayerUnclaimedShopAsync = Remotes:WaitForChild("PlayerUnclaimedShop")

-- Data Stores
local playerShopsDataStore 	= DataStoreService:GetDataStore(Constants.PLAYER_SHOPS_DATA_STORE_NAME)

local PlayerDetails = {}
PlayerDetails.__index = PlayerDetails

function PlayerDetails.new(player : Player)
	local newPlayerDetails = {} :: Types.PlayerDetails
	setmetatable(newPlayerDetails, PlayerDetails)

	newPlayerDetails.player = player
	newPlayerDetails.id = player.UserId
	newPlayerDetails.shop = nil
	newPlayerDetails:_initialisePlayerShopData(player)
	
	return newPlayerDetails
end

function PlayerDetails:_initialisePlayerShopData(player : Player) : ()
	if not self:getPlayerShopData() then
		local success, error = pcall(function()
			playerShopsDataStore:SetAsync(player.UserId, {})
		end)
		if not success then
			warn("Failed to set player store")
		end
	else
		warn("Player shop data already exists")
	end
end

function PlayerDetails:getPlayerShopData() : {}?
	local playerShopData
	local success, error = pcall(function()
		playerShopData = playerShopsDataStore:GetAsync(self.player.UserId)
	end)
	if not success then
		warn("Failed to get player store")
		return nil
	end

	return playerShopData
end

-- TODO: This should be in shop class
function PlayerDetails:getPlayerShopInstance() : BasePart?
	if self.shop then
		return self.shop:getShopInstance()
	else
		return nil
	end
end

-- TODO: Code is more consistent if entry to claiming a shop is here
function PlayerDetails:claimedShop(shop : Types.ShopDetails) : ()
	if not shop then
		return
	end
	
	if self.shop then
		self:unclaimShop()
	end
	
	self.shop = shop
	self.shop:onPlayerClaimed(self) 
	
	-- TODO: Maybe rename the below to "PlayerStatusUpdate" to client or w/e
	PlayerClaimedShopAsync:FireClient(self.player, self)
end

function PlayerDetails:doesPlayerHaveShop()
	if self.shop then
		return true
	else
		return false
	end
end

function PlayerDetails:unclaimShop()
	if self.shop then
		self.shop:unclaim()
		self.shop = nil
	end 
	
	PlayerUnclaimedShopAsync:FireClient(self.player, self)
end

return PlayerDetails