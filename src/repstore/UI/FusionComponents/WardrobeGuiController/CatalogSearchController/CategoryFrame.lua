-- CategoryFrame.lua

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local DataTables = ReplicatedStorage:WaitForChild("DataTables")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local Widgets = FusionComponents:WaitForChild("Widgets")

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))
local TopCategories = require(DataTables:WaitForChild("TopCategories"))

-- Fusion
local Children = Fusion.Children
local peek = Fusion.peek
type UsedAs<T> = Fusion.UsedAs<T>

-- GUI Components
local TopCategoryButton = require(Widgets:WaitForChild("TopCategoryButton"))
local SubCategoryButton = require(Widgets:WaitForChild("SubCategoryButton"))
local CategoryButton    = require(Widgets:WaitForChild("CategoryButton"))

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
		allowedTopCategories: Fusion.Value<{string}?>?,
		selectedTopCategory: Fusion.Value<string?>,
		currentSubCategories: Fusion.Value<{ TopCategories.SubCategoryEntry }>,
	}
): Frame

	-- ─── State ───────────────────────────────────────────────────────────

	local selectedSubCategory  = scope:Value(nil :: string?)

	local allSelected = scope:Computed(function(use)
		return use(props.selectedTopCategory) == nil and not use(props.editorsPickSelected)
	end)

	-- ─── Helpers ─────────────────────────────────────────────────────────

	local function selectAll()
		props.selectedTopCategory:set(nil)
		selectedSubCategory:set(nil)
		props.currentSubCategories:set({})
		props.searchAssetCategories:set({})
		props.searchBundleCategories:set({})
		props.searchCallback()
	end

	local function selectTopCategory(entry: TopCategories.TopCategoryEntry)
		props.selectedTopCategory:set(entry.name)
		selectedSubCategory:set(nil)
		props.currentSubCategories:set(entry.subCategories)
		props.editorsPickSelected:set(false)
		props.searchAssetCategories:set(entry.assetTypes)
		props.searchBundleCategories:set(entry.bundleTypes)
		props.searchCallback()
	end

	local function selectSubCategory(entry: TopCategories.SubCategoryEntry)
		selectedSubCategory:set(entry.name)
		props.searchAssetCategories:set(entry.assetType and { entry.assetType } or {})
		props.searchBundleCategories:set(entry.bundleType and { entry.bundleType } or {})
		props.searchCallback()
	end

	-- Reactive filtered list of top categories (all four, or restricted set)
	local visibleTopCategories = scope:Computed(function(use)
		local allowed = props.allowedTopCategories and use(props.allowedTopCategories)
		if not allowed then return TopCategories end
		local filtered: { TopCategories.TopCategoryEntry } = {}
		for _, entry in TopCategories do
			if table.find(allowed, entry.name) then
				table.insert(filtered, entry)
			end
		end
		return filtered
	end)

	-- ─── SubCategory buttons (reactive) ──────────────────────────────────

	local subCategoryButtons = scope:ForValues(props.currentSubCategories, function(use, innerScope, entry)
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

			-- Top category row
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
						visible = scope:Computed(function(use)
							return not (props.allowedTopCategories and use(props.allowedTopCategories))
						end),
					}),

					CategoryButton(scope, {
						text = "Editor's Pick",
						size = UI_CONSTANTS.CATEGORY_BUTTON_SIZE,
						layoutOrder = 2,
						isSelected = props.editorsPickSelected,
						visible = scope:Computed(function(use)
							return not (props.allowedTopCategories and use(props.allowedTopCategories))
						end),
						onActivated = function()
							if peek(props.editorsPickSelected) then
								selectAll()
							else
								props.selectedTopCategory:set(nil)
								selectedSubCategory:set(nil)
								props.currentSubCategories:set({})
								props.editorsPickCallback()
							end
						end,
					}),

					scope:ForValues(visibleTopCategories, function(use, innerScope, entry)
						local isSelected = innerScope:Computed(function(use)
							return use(props.selectedTopCategory) == entry.name
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

			-- Sub category row
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
