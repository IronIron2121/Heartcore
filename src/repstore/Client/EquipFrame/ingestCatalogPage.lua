--!strict

--[[
	ingestCatalogPage - A utility function to add a page of item details returned from
	AvatarEditorService:SearchCatalog() to the item details cache.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Utility.Types)
local ItemDetailsCache = require(ReplicatedStorage.Libraries.ItemDetailsCache)

local function ingestCatalogPage(catalogPage: Types.CatalogPage)
	for _, itemDetails in catalogPage do
		ItemDetailsCache.ingestItemDetails(itemDetails)
	end
end

return ingestCatalogPage
