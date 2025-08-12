--!strict

--[[
	getItemIcon - A utility function to get the icon for an item, using the rbxthumb:// format.
	See: https://create.roblox.com/docs/projects/assets#asset-format-strings
--]]

local RESOLUTION = 600

local function getThumbnailFromId(imageId: number): string
	return `rbxassetid://{imageId}`
	--return `rbxassetid://{imageId}--[[&w={RESOLUTION}&h={RESOLUTION}`

end

return getThumbnailFromId