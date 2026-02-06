--!strict

--[[
	This script contains all image asset ids used by image labels or image buttons
	
	The metatable automatically turns any given assetId into an ImageUri
]]


local ImageUris = {}
local assets = {
	OutfitCatalogButton = "116118796974877",
	CloseButton = "80840559307041",
	ConfirmButton = "137275759314686",
	StopwatchIcon = "73600277679991",
	RobuxIcon = "81055682730978",
	ExpBar = "73207886316381",
	ClaimButton = "140623730526268",
	ClaimedButton = "71218500167955",
	DailyChallengeButton = "93273619202001",
	VoteButton = "137550678558366",
	TrashButton = "72654613290117",
	ViewportBackground = "75117962948738",
	ViewportBG = "118393578077171",
	PlayFitCheck = "105617271254134",
	ExitFitCheck = "109235442991718",
	Submit = "119739436734284",
	Vote = "85654210815705",
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