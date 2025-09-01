--!strict

--[[
	SortingFilters - A list of item filters for the catalog search, as well as which asset/bundle
	types to include in each filter.
--]]

local SortingFilters = {
	list = {
		"Bestselling",
		"Most favorited",
		"Recently created",
		"Relevance",
		"Price ascending",
		"Price descending",
	},
	filters = {
		["Bestselling"] = Enum.CatalogSortType.Bestselling,
		["Most favorited"] = Enum.CatalogSortType.MostFavorited,
		["Recently created"] = Enum.CatalogSortType.RecentlyCreated,
		["Relevance"] = Enum.CatalogSortType.Relevance,
		["Price ascending"] = Enum.CatalogSortType.PriceLowToHigh,
		["Price descending"] = Enum.CatalogSortType.PriceHighToLow,
	},
}

return SortingFilters
