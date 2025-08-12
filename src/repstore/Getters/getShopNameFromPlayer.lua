local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.Constants)

function getShopNameFromPlayer(player: Player)
	return player:GetAttribute(Constants.PLAYER_CLAIM_ATTRIBUTES.SHOP_NAME)
end

return getShopNameFromPlayer
