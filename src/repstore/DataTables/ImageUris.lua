--!strict

--[[
	This script contains all image asset ids used by image labels or image buttons
	
	The metatable automatically turns any given assetId into an ImageUri
]]


local ImageUris = {}
local assets = {
	OutfitCatalogButton = "90158612092236",
	CloseButton = "105526811105669",
	StopwatchIcon = "73600277679991",
	RobuxIcon = "81055682730978",
	ExpBar = "73207886316381",
	ClaimButton = "96236040552707",
	DailyChallengeButton = "129184509423001",
	VoteButton = "137550678558366"
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