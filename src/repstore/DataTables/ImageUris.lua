--!strict

--[[
	This script contains all image asset ids used by image labels or image buttons
	
	The metatable automatically turns any given assetId into an ImageUri
]]


local ImageUris = {}
local assets = {
	OutfitCatalogButton = "116118796974877",
	CloseButton = "85940627430036",
	StopwatchIcon = "73600277679991",
	RobuxIcon = "81055682730978",
	ExpBar = "73207886316381",
	ClaimButton = "140623730526268",
	ClaimedButton = "71218500167955",
	DailyChallengeButton = "93273619202001",
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