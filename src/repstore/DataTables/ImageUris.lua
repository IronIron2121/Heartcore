--!strict

--[[
	This script contains all image asset ids used by image labels or image buttons
	
	The metatable automatically turns any given assetId into an ImageUri
]]


local ImageUris = {}
local assets = {
	OutfitCatalogButton = "93922334459186",
	CloseButton = "86480151535378"
}

setmetatable(ImageUris, {
	__index = function(_, key: string)
		if assets[key] then
			return "rbxassetid://"..assets[key]
		else
			return nil
		end
	end,
})

return ImageUris