--!strict

--[[
	removeSimilar - A utility function to remove accessories that are categorized the same as others from a table.
	This is used when trying on clothing to remove e.g. shorts/dresses when trying on a pair of pants, since they
	have different AccessoryTypes but are still in the same 'category'.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Utility.Types)
local getAccessoryCategory = require(ReplicatedStorage.Utility.getAccessoryCategory)

local function removeSimilarAccessories(
	accessoryType: Enum.AccessoryType,
	accessories: { Types.HumanoidDescriptionAccessory }
): { Types.HumanoidDescriptionAccessory }
	local accessoryCategory = getAccessoryCategory(accessoryType)

	-- We loop backwards through the array since removing entries will shift the later ones,
	-- which would cause skipping if we were looping forward.
	for i = #accessories, 1, -1 do
		local accessory = accessories[i]
		local otherAccessoryCategory = getAccessoryCategory(accessory.AccessoryType)

		if accessoryCategory == otherAccessoryCategory then
			table.remove(accessories, i)
		end
	end

	return accessories
end

return removeSimilarAccessories