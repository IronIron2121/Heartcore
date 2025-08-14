--!strict

--[[
	ItemFilters - A list of item filters for the catalog search, as well as which asset/bundle
	types to include in each filter.
--]]

local ItemFilters = {
	list = {
		"All Items",
		"Characters",
		"Hair",
		"Hats",
		"Accessories",
		"Tops",
		"Outerwear",
		"Bottoms",
		"Shoes",
	},
	filters = {
		["All Items"] = {
			assets = {},
			bundles = {},
		},
		["Characters"] = {
			assets = {
				Enum.AvatarAssetType.EyebrowAccessory,
				Enum.AvatarAssetType.EyelashAccessory,
			},
			bundles = {
				Enum.BundleType.BodyParts,
				Enum.BundleType.DynamicHead,
			},
		},
		["Hair"] = {
			assets = {
				Enum.AvatarAssetType.HairAccessory,
			},
			bundles = {},
		},
		["Hats"] = {
			assets = {
				Enum.AvatarAssetType.Hat,
			},
			bundles = {},
		},
		["Accessories"] = {
			assets = {
				Enum.AvatarAssetType.BackAccessory,
				Enum.AvatarAssetType.FaceAccessory,
				Enum.AvatarAssetType.NeckAccessory,
				Enum.AvatarAssetType.FrontAccessory,
				Enum.AvatarAssetType.WaistAccessory,
				Enum.AvatarAssetType.ShoulderAccessory,
			},
			bundles = {},
		},
		["Tops"] = {
			assets = {
				Enum.AvatarAssetType.ShirtAccessory,
				Enum.AvatarAssetType.SweaterAccessory,
				Enum.AvatarAssetType.TShirtAccessory,
				Enum.AvatarAssetType.Shirt,
			},
			bundles = {},
		},
		["Outerwear"] = {
			assets = {
				Enum.AvatarAssetType.JacketAccessory,
			},
			bundles = {},
		},
		["Bottoms"] = {
			assets = {
				Enum.AvatarAssetType.PantsAccessory,
				Enum.AvatarAssetType.ShortsAccessory,
				Enum.AvatarAssetType.DressSkirtAccessory,
				Enum.AvatarAssetType.Pants,
			},
			bundles = {},
		},
		["Shoes"] = {
			assets = {},
			bundles = {
				Enum.BundleType.Shoes,
			},
		},
	},
}

return ItemFilters
