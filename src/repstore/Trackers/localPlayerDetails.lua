--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Modules
local Types = require(Utility:WaitForChild("Types"))

-- Remotes / Bindables
local UpdateLocalPlayerDetailsAsync = Remotes:WaitForChild("UpdateLocalPlayerDetails")

export type localPlayerDetails = {
	details : Types.PlayerDetails 
}

local localPlayerDetails = {}

function localPlayerDetails.update(playerDetails : Types.PlayerDetails)
	localPlayerDetails.details = playerDetails
end

function localPlayerDetails.getShopInstance() : Instance?
	if not localPlayerDetails.details or not localPlayerDetails.details.shop then
		warn("Not found")
		print(localPlayerDetails.details)

		return nil
	else
		print("Got it!", localPlayerDetails.details)
		return localPlayerDetails.details.shop.instance
	end
end

function localPlayerDetails.getShopDetails() : Types.ShopDetails?
	return localPlayerDetails.details.shop
end

function localPlayerDetails.playerHasShop()
	return localPlayerDetails.details.shop ~= nil
end

function localPlayerDetails.getShopZone()
	return localPlayerDetails
end

return localPlayerDetails