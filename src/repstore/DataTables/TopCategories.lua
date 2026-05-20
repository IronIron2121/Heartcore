--!strict
-- TopCategories.lua
-- Defines the top-level catalog categories and their subcategory mappings.
-- Shared by CategoryFrame (for rendering) and CatalogSearchController (for filtering).

export type SubCategoryEntry = {
	name: string,
	assetType: Enum.AvatarAssetType?,
	bundleType: Enum.BundleType?,
}

export type TopCategoryEntry = {
	name: string,
	assetTypes: { Enum.AvatarAssetType },
	bundleTypes: { Enum.BundleType },
	subCategories: { SubCategoryEntry },
}

local TopCategories: { TopCategoryEntry } = {
	{
		name = "Tops",
		assetTypes = {
			Enum.AvatarAssetType.TShirtAccessory,
			Enum.AvatarAssetType.ShirtAccessory,
			Enum.AvatarAssetType.JacketAccessory,
			Enum.AvatarAssetType.SweaterAccessory,
			Enum.AvatarAssetType.TShirt,
			Enum.AvatarAssetType.Shirt,
		},
		bundleTypes = {},
		subCategories = {
			{ name = "Classic T-Shirts", assetType = Enum.AvatarAssetType.TShirt 	},
			{ name = "Classic Shirts", assetType = Enum.AvatarAssetType.Shirt 		},
			{ name = "T-Shirts", assetType = Enum.AvatarAssetType.TShirtAccessory 	},
			{ name = "Shirts",   assetType = Enum.AvatarAssetType.ShirtAccessory	},
			{ name = "Jackets",  assetType = Enum.AvatarAssetType.JacketAccessory  	},
			{ name = "Sweaters", assetType = Enum.AvatarAssetType.SweaterAccessory	},
		},
	},
	{
		name = "Bottoms",
		assetTypes = {
			Enum.AvatarAssetType.PantsAccessory,
			Enum.AvatarAssetType.ShortsAccessory,
			Enum.AvatarAssetType.Pants
		},
		bundleTypes = {},
		subCategories = {
			{ name = "Pants",			assetType = Enum.AvatarAssetType.PantsAccessory	},
			{ name = "Shorts",			assetType = Enum.AvatarAssetType.ShortsAccessory},
			{ name = "Classic Pants",	assetType = Enum.AvatarAssetType.Pants     		},
		},
	},
	{
		name = "Hair",
		assetTypes = { Enum.AvatarAssetType.HairAccessory },
		bundleTypes = {},
		subCategories = {},
	},
	{
		name = "Body",
		assetTypes = {},
		bundleTypes = {
			Enum.BundleType.BodyParts,
			Enum.BundleType.DynamicHead,
		},
		subCategories = {
			{ name = "Body Parts",    bundleType = Enum.BundleType.BodyParts   },
			{ name = "Dynamic Heads", bundleType = Enum.BundleType.DynamicHead },
		},
	},
	{
		name = "Dresses & Skirts",
		assetTypes = { 
			Enum.AvatarAssetType.DressSkirtAccessory 
		},
		bundleTypes = {},
		subCategories = {},
	},

}

return TopCategories