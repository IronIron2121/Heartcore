local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataTablesFolder = ReplicatedStorage:WaitForChild("DataTables")
local TexturesFolder = ReplicatedStorage:WaitForChild("Textures")



local FurnitureColours = {
	
	
}

local function initColours()
	for _, colour in pairs(DataTablesFolder:WaitForChild("FurnitureColours"):GetChildren()) do
		FurnitureColours[colour.Name] = colour.Name
	end
end

initColours()

return FurnitureColours
