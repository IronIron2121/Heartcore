-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local GettersFolder = ReplicatedStorage:WaitForChild("Getters")

-- Module Scripts
local getListOfAccessoryIdsFromMannequin = require(GettersFolder:WaitForChild("getListOfAccessoryIdsFromMannequin"))
local getListOfBundleIdsFromMannequin = require(GettersFolder:WaitForChild("getListOfBundleIdsFromMannequin"))

function doesMannequinHaveAssetEquipped(player: Player, accessoryId: number, itemType, mannequinId: number)
	if itemType == Enum.MarketplaceProductType.AvatarAsset then
		local mannequinAccessoryList = getListOfAccessoryIdsFromMannequin(player, mannequinId)
		if not mannequinAccessoryList then return nil end
		if table.find(mannequinAccessoryList, accessoryId) then
			return true
		else
			return false
		end
	elseif itemType == Enum.MarketplaceProductType.AvatarBundle then
		local mannequinBundleList = getListOfBundleIdsFromMannequin(player, mannequinId)
		if not mannequinBundleList then return nil end
		if table.find(mannequinBundleList, accessoryId) then
			return true
		else
			return false
		end
	else
		warn("Invalid item type!", itemType)
		return nil
	end
end

return doesMannequinHaveAssetEquipped
