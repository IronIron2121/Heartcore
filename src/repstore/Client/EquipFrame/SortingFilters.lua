--!strict

--[[
	SortingFilters - A list of item filters for the catalog search, as well as which asset/bundle
	types to include in each filter.
--]]

local SortingFilters = {
	list = {
		"Sort by: Bestselling",
		"Sort by: Most favorited",
		"Sort by: Recently created",
		"Sort by: Relevance",
		"Sort by: Price ascending",
		"Sort by: Price descending",
	},
	filters = {
		["Sort by: Bestselling"] = Enum.CatalogSortType.Bestselling,
		["Sort by: Most favorited"] = Enum.CatalogSortType.MostFavorited,
		["Sort by: Recently created"] = Enum.CatalogSortType.RecentlyCreated,
		["Sort by: Relevance"] = Enum.CatalogSortType.Relevance,
		["Sort by: Price ascending"] = Enum.CatalogSortType.PriceLowToHigh,
		["Sort by: Price descending"] = Enum.CatalogSortType.PriceHighToLow,
	},
}

return SortingFilters
 