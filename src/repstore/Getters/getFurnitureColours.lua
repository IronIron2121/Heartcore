-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local GettersFolder = ReplicatedStorage:WaitForChild("Getters")

-- Module Scripts
local getFurnitureTableEntry = require(GettersFolder:WaitForChild("getFurnitureTableEntry"))

function getFurnitureColours(furnitureItem: Model): {string}?
	local furnitureTableEntry = getFurnitureTableEntry(furnitureItem)
	
	if not furnitureTableEntry then
		warn("Could not find furniture entry at furniture colours", furnitureItem)
		return nil
	end
	
	local furnitureColours = furnitureTableEntry["Colours"]
	
	return furnitureColours
end

return getFurnitureColours
