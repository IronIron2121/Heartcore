--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local getRandomIdNumber = require(Utility:WaitForChild("getRandomIdNumber"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local Types = require(Utility:WaitForChild("Types"))

-- Constants
local RANDOM_ID_LOWER_BOUND = 1
local RANDOM_ID_UPPER_BOUND = 99999

--

local ShopTracker = {}

local listOfShops = {}

function ShopTracker.trackNewShop(shop : Types.ShopDetails)
	listOfShops[shop.id] = shop
end
 
function ShopTracker.getUnusedShopId() : number
	local newId
	repeat
		newId = getRandomIdNumber()
	until not ShopTracker.getShopFromShopId(newId)
	return newId
end

function ShopTracker.getShopFromShopId(id : number) : Types.ShopDetails?
	return listOfShops[id]
end

function ShopTracker.getShopFromPlayer(player : Player) : Types.ShopDetails?
	for shopId, shop in pairs(listOfShops) do
		if shop.claimingPlayerId == player.UserId then
			return shop			
		end
	end
	
	warn("Player has no shop!", listOfShops)
	return nil
end



return ShopTracker