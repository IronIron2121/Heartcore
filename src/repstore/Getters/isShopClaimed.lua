local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.Constants)
--local shopsFolder = workspace:WaitForChild(Constants.SHOP_FOLDER_NAME)

--[[
-- Grabs the shop object from workspace given the shop name
function isShopClaimed(shopName: string): boolean ?
	for _, shop: Part in shopsFolder:GetChildren() do
		local thisShopName = shop.Name
		if thisShopName == shopName then
			return shop:GetAttribute(Constants.SHOP_CLAIM_ATTRIBUTES.CLAIMED_BOOL)
		end
	end
	warn("Failed to obtain shop at isShopClaimed")
	return false
end

return isShopClaimed

]]