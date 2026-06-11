--!strict

--[[
	This script contains all image asset ids used by image labels or image buttons
	
	The metatable automatically turns any given assetId into an ImageUri
]]


local ImageUris = {}
local assets = {
	OutfitCatalogButton = "139941028437891",
	CloseButton = "80352400443696",
	RobuxIcon = "81055682730978",
	TastemakerLogo = "135120895273906"
}

setmetatable(ImageUris, {
	__index = function(_, key: string)
		if assets[key] then
			return "rbxassetid://"..assets[key]
		else
			assert(assets[key], "No value stored at provided key!")
			return nil
		end
	end,
})

return ImageUris
