-- CategoryFrame.lua

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local Widgets = FusionComponents:WaitForChild("Widgets")

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))

-- Fusion
local Children = Fusion.Children
local peek = Fusion.peek
type UsedAs<T> = Fusion.UsedAs<T>

-- GUI Components
local TopCategoryButton = require(Widgets:WaitForChild("TopCategoryButton"))
local SubCategoryButton = require(Widgets:WaitForChild("SubCategoryButton"))
local CategoryButton    = require(Widgets:WaitForChild("CategoryButton"))

-- ─── Category data ───────────────────────────────────────────────────────────

type SubCategoryEntry = {
	name: string,
	assetType: Enum.AvatarAssetType?,
	bundleType: Enum.BundleType?,
}

type TopCategoryEntry = {
	name: string,
	subCategories: { SubCategoryEntry },
	-- For direct-filter top categories (no subcategories), list the types to apply
	assetTypes: { Enum.AvatarAssetType },
	bundleTypes: { Enum.BundleType },
}

local TOP_CATEGORIES: { TopCategoryEntry } = {
	{
		name = "Tops",
		assetTypes = {
			Enum.AvatarAssetType.TShirtAccessory,
			Enum.AvatarAssetType.ShirtAccessory,
			Enum.AvatarAssetType.JacketAccessory,
			Enum.AvatarAssetType.SweaterAccessory,
		},
		bundleTypes = {},
		subCategories = {
			{ name = "T-Shirts", assetType = Enum.AvatarAssetType.TShirtAccessory },
			{ name = "Shirts",   assetType = Enum.AvatarAssetType.ShirtAccessory   },
			{ name = "Jackets",  assetType = Enum.AvatarAssetType.JacketAccessory  },
			{ name = "Sweaters", assetType = Enum.AvatarAssetType.SweaterAccessory },
		},
	},
	{
		name = "Bottoms",
		assetTypes = {
			Enum.AvatarAssetType.PantsAccessory,
			Enum.AvatarAssetType.ShortsAccessory,
			Enum.AvatarAssetType.DressSkirtAccessory,
		},
		bundleTypes = {},
		subCategories = {
			{ name = "Pants",           assetType = Enum.AvatarAssetType.PantsAccessory       },
			{ name = "Shorts",          assetType = Enum.AvatarAssetType.ShortsAccessory      },
			{ name = "Dresses & Skirts",assetType = Enum.AvatarAssetType.DressSkirtAccessory  },
		},
	},
	{
		name = "Hair",
		assetTypes = { Enum.AvatarAssetType.HairAccessory },
		bundleTypes = {},
		subCategories = {},  -- direct filter; no subcategory row
	},
	{
		name = "Body",
		assetTypes = {},
		bundleTypes = {
			Enum.BundleType.BodyParts,
			Enum.BundleType.DynamicHead,
		},
		subCategories = {
			{ name = "Body Parts",    bundleType = Enum.BundleType.BodyParts    },
			{ name = "Dynamic Heads", bundleType = Enum.BundleType.DynamicHead  },
		},
	},
}

-- ─── Component ───────────────────────────────────────────────────────────────

function CategoryFrame(
	scope: Fusion.Scope,
	props: {
		size: UsedAs<UDim2>?,
		position: UsedAs<UDim2>?,
		anchorPoint: UsedAs<Vector2>?,
		layoutOrder: UsedAs<number>?,
		backgroundTransparency: UsedAs<number>?,
		currentView: Fusion.Value<string>,
		searchAssetCategories: Fusion.Value<{Enum.AvatarAssetType}>,
		searchBundleCategories: Fusion.Value<{Enum.BundleType}>,
		searchCallback: () -> (),
		editorsPickCallback: () -> (),
		editorsPickSelected: Fusion.Value<boolean>,
	}
): Frame

	-- ─── State ───────────────────────────────────────────────────────────

	local selectedTopCategory  = scope:Value(nil :: string?)
	local selectedSubCategory  = scope:Value(nil :: string?)
	local currentSubCategories = scope:Value({} :: { SubCategoryEntry })

	local allSelected = scope:Computed(function(use)
		return use(selectedTopCategory) == nil and not use(props.editorsPickSelected)
	end)

	-- ─── Helpers ─────────────────────────────────────────────────────────

	local function selectAll()
		selectedTopCategory:set(nil)
		selectedSubCategory:set(nil)
		currentSubCategories:set({})
		props.searchAssetCategories:set({})
		props.searchBundleCategories:set({})
		props.searchCallback()
	end

	local function selectTopCategory(entry: TopCategoryEntry)
		selectedTopCategory:set(entry.name)
		selectedSubCategory:set(nil)
		currentSubCategories:set(entry.subCategories)
		props.editorsPickSelected:set(false)
		props.searchAssetCategories:set(entry.assetTypes)
		props.searchBundleCategories:set(entry.bundleTypes)
		props.searchCallback()
	end

	local function selectSubCategory(entry: SubCategoryEntry)
		selectedSubCategory:set(entry.name)
		props.searchAssetCategories:set(entry.assetType and { entry.assetType } or {})
		props.searchBundleCategories:set(entry.bundleType and { entry.bundleType } or {})
		props.searchCallback()
	end

	-- ─── SubCategory buttons (reactive) ──────────────────────────────────

	local subCategoryButtons = scope:ForValues(currentSubCategories, function(use, innerScope, entry)
		local isSelected = innerScope:Computed(function(use)
			return use(selectedSubCategory) == entry.name
		end)
		return SubCategoryButton(innerScope, {
			text = entry.name,
			size = UI_CONSTANTS.CATEGORY_BUTTON_SIZE,
			isSelected = isSelected,
			onActivated = function()
				selectSubCategory(entry)
			end,
		})
	end)

	-- ─── Frame ───────────────────────────────────────────────────────────

	return scope:New "Frame" {
		Name = "CategoryFrame",
		Size = props.size or UDim2.fromScale(1, 0.2),
		Position = props.position or UDim2.fromScale(0.5, 0.1),
		AnchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5),
		LayoutOrder = props.layoutOrder or 1,
		BackgroundColor3 = UI_CONSTANTS.COLOUR_WHITE,
		BackgroundTransparency = props.backgroundTransparency or UI_CONSTANTS.TRANSPARENCY_TRANSLUCENT,
		Visible = scope:Computed(function(use)
			return use(props.currentView) == "Catalog"
		end),

		[Children] = {
			scope:New "UICorner" { CornerRadius = UDim.new(0.2, 0) },
			scope:New "UIListLayout" {
				Padding = UDim.new(0.02, 0),
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			},

			-- Top category row: All, Editor's Pick, Tops, Bottoms, Hair, Body
			scope:New "ScrollingFrame" {
				Name = "TopCategoryFrame",
				LayoutOrder = 1,
				Size = UDim2.fromScale(0.95, 0.5),
				BackgroundTransparency = 1,
				AutomaticCanvasSize = Enum.AutomaticSize.X,
				CanvasSize = UDim2.fromScale(0, 0),
				ScrollingDirection = Enum.ScrollingDirection.X,
				ScrollBarThickness = 1,

				[Children] = {
					scope:New "UIListLayout" {
						FillDirection = Enum.FillDirection.Horizontal,
						SortOrder = Enum.SortOrder.LayoutOrder,
						HorizontalAlignment = Enum.HorizontalAlignment.Left,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						Padding = UDim.new(0, 10),
					},
					scope:New "UIPadding" {
						PaddingTop = UDim.new(0.01, 0),
						PaddingLeft = UDim.new(0.01, 0),
					},

					CategoryButton(scope, {
						text = "All",
						size = UI_CONSTANTS.CATEGORY_BUTTON_SIZE,
						layoutOrder = 1,
						isSelected = allSelected,
						onActivated = selectAll,
					}),

					CategoryButton(scope, {
						text = "Editor's Pick",
						size = UI_CONSTANTS.CATEGORY_BUTTON_SIZE,
						layoutOrder = 2,
						isSelected = props.editorsPickSelected,
						onActivated = function()
							if peek(props.editorsPickSelected) then
								selectAll()
							else
								selectedTopCategory:set(nil)
								selectedSubCategory:set(nil)
								currentSubCategories:set({})
								props.editorsPickCallback()
							end
						end,
					}),

					scope:ForValues(scope:Value(TOP_CATEGORIES), function(use, innerScope, entry)
						local isSelected = innerScope:Computed(function(use)
							return use(selectedTopCategory) == entry.name
						end)
						return TopCategoryButton(innerScope, {
							text = entry.name,
							size = UI_CONSTANTS.CATEGORY_BUTTON_SIZE,
							layoutOrder = 3,
							isSelected = isSelected,
							onActivated = function()
								selectTopCategory(entry)
							end,
						})
					end),
				},
			},

			-- Sub category row: repopulates when a top category is selected
			scope:New "ScrollingFrame" {
				Name = "SubCategoryFrame",
				LayoutOrder = 2,
				Size = UDim2.fromScale(0.95, 0.5),
				BackgroundTransparency = 1,
				AutomaticCanvasSize = Enum.AutomaticSize.X,
				CanvasSize = UDim2.fromScale(0, 0),
				ScrollingDirection = Enum.ScrollingDirection.X,
				ScrollBarThickness = 4,

				[Children] = {
					scope:New "UIListLayout" {
						FillDirection = Enum.FillDirection.Horizontal,
						SortOrder = Enum.SortOrder.LayoutOrder,
						HorizontalAlignment = Enum.HorizontalAlignment.Left,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						Padding = UDim.new(0, 10),
					},
					scope:New "UIPadding" {
						PaddingTop = UDim.new(0.01, 0),
						PaddingLeft = UDim.new(0.01, 0),
					},
					subCategoryButtons,
				},
			},
		},
	} :: Frame
end

return CategoryFrame
