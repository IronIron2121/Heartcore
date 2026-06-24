--!strict

--[[
	This script contains all image asset ids used by image labels or image buttons
	
	The metatable automatically turns any given assetId into an ImageUri
]]


local ImageUris = {}
local assets = {
	OutfitCatalogButton = "139941028437891",
	TastemakerLogo 		= "135120895273906",
	HomeButton			= "107733137023980",
	CloseButton 		= "80352400443696",
	ConfirmButton 		= "89968616523764",
	RobuxIcon 			= "81055682730978",
	AuraLogo 			= "90201692488235",
	AuraClose			= "104076997168622"
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
