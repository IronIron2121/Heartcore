-- CategoryFrame.lua

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Folders
local DataTables = ReplicatedStorage:WaitForChild("DataTables")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local Widgets = FusionComponents:WaitForChild("Widgets")

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))
local AssetFilterCategories = require(DataTables:WaitForChild("AssetFilterCategories"))
local BundleFilterCategories = require(DataTables:WaitForChild("BundleFilterCategories"))

-- Constants
local COLOUR_SELECTED = UI_CONSTANTS.COLOUR_ORANGE
local DEFAULT_COLOUR = Color3.new(0.92549, 0.545098, 0.321569)

-- Fusion
local Children = Fusion.Children
local peek = Fusion.peek
type UsedAs<T> = Fusion.UsedAs<T>

-- GUI Components
local ExpandingOptionsButton = require(Widgets:WaitForChild("ExpandingOptionsButton"))
local CategoryButton = require(Widgets:WaitForChild("CategoryButton"))


--

function CategoryFrame(
	scope: Fusion.Scope,
	props: {
		size: UsedAs<UDim2>?,
		position: UsedAs<UDim2>?,
		anchorPoint: UsedAs<Vector2>?,
		layoutOrder: UsedAs<number>?,
		backgroundColor3: UsedAs<Color3>?,
		backgroundTransparency: UsedAs<number>?,
		visible: UsedAs<boolean>?,
		name: UsedAs<string>?,
		isSelected: UsedAs<boolean>?,
		currentView: Fusion.Value<string>,
		searchAssetCategories: Fusion.Value<{Enum.AvatarAssetType}>,
		searchBundleCategories: Fusion.Value<{Enum.BundleType}>,
		searchCallback: () -> (),
		editorsPickCallback: () -> (),
		editorsPickSelected: UsedAs<boolean>
	}
): Frame

	local textColorSpring = scope:Spring(
    scope:Computed(function(use)
        if use(props.editorsPickSelected) then  
            return COLOUR_SELECTED
        else
            return DEFAULT_COLOUR
        end
    end))

	local allSelected = scope:Computed(function(use)
		return #use(props.searchAssetCategories) == #AssetFilterCategories.getAllAssetTypes()
			and #use(props.searchBundleCategories) == #BundleFilterCategories.getAllRobloxBundleTypes()
	end)

	local function selectAll()
		props.searchAssetCategories:set(AssetFilterCategories.getAllAssetTypes())
		props.searchBundleCategories:set(BundleFilterCategories.getAllRobloxBundleTypes())
	end

	local function toggleCategory(assetType: Enum.AvatarAssetType?, bundleType: Enum.BundleType?)
		if peek(allSelected) then
			if assetType then
				props.searchAssetCategories:set({assetType})
				props.searchBundleCategories:set({})
			elseif bundleType then
				props.searchBundleCategories:set({bundleType})
				props.searchAssetCategories:set({})
			end
			props.searchCallback()
			return
		end

		local isCurrentlySelected = false
		if assetType then
			isCurrentlySelected = table.find(peek(props.searchAssetCategories), assetType) ~= nil
		elseif bundleType then
			isCurrentlySelected = table.find(peek(props.searchBundleCategories), bundleType) ~= nil
		end

		if isCurrentlySelected then
			selectAll()
		else
			if assetType then
				props.searchAssetCategories:set({assetType})
				props.searchBundleCategories:set({})
			elseif bundleType then
				props.searchBundleCategories:set({bundleType})
				props.searchAssetCategories:set({})
			end
		end
		props.searchCallback()
	end

	local function isAssetSelected(assetType: Enum.AvatarAssetType): Fusion.Computed<boolean>
		return scope:Computed(function(use)
			if use(allSelected) then
				return false
			end
			return table.find(use(props.searchAssetCategories), assetType) ~= nil
		end)
	end

	local function isBundleSelected(bundleType: Enum.BundleType): Fusion.Computed<boolean>
		return scope:Computed(function(use)
			if use(allSelected) then
				return false
			end
			return table.find(use(props.searchBundleCategories), bundleType) ~= nil
		end)
	end

	-- Outer container frame
	local categoryFrame = scope:New "Frame" {
		Name = (props and props.name) or "CategoryFrame",
		Size = (props and props.size) or UDim2.fromScale(1, 0.2),
		Position = (props and props.position) or UDim2.fromScale(0.5, 0.1),
		AnchorPoint = (props and props.anchorPoint) or Vector2.new(0.5, 0.5),
		LayoutOrder = (props and props.layoutOrder) or 1,
		BackgroundColor3 = UI_CONSTANTS.COLOUR_WHITE,
		BackgroundTransparency = (props and props.backgroundTransparency) or UI_CONSTANTS.TRANSPARENCY_TRANSLUCENT,
		Visible = scope:Computed(function(use)
			return use(props.currentView) == "Catalog"
		end),

		[Children] = {
			scope:New "UIListLayout" {
				Padding = UDim.new(0.02, 0),
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			},
			
			scope:New "UICorner" {
				CornerRadius = UDim.new(0.2, 0)
			},
			
			-- Inner scrolling frame
			scope:New "ScrollingFrame" {
				Name = "CategoryScrollFrame",
				AnchorPoint = Vector2.new(0.5, 0),
				Size = UDim2.fromScale(0.95, 0.99),
				Position = UDim2.fromScale(0, 0),
				BackgroundTransparency = 1,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.fromScale(0, 0),
				ScrollingDirection = Enum.ScrollingDirection.Y,
				ScrollBarThickness = 4,

				[Children] = {
					scope:New "UIListLayout" {
						FillDirection = Enum.FillDirection.Vertical,
						SortOrder = Enum.SortOrder.LayoutOrder,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Top,
						Padding = UDim.new(0, 10)
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
						onActivated = function()
							if peek(allSelected) then
								props.searchAssetCategories:set({})
								props.searchBundleCategories:set({})
							else
								selectAll()
							end
							props.searchCallback()
						end
					}),
					
					CategoryButton(scope, {
						text = "Editor's Pick",
						size = UI_CONSTANTS.CATEGORY_BUTTON_SIZE,
						textColor3 = textColorSpring,
						layoutOrder = 2,
						isSelected = props.editorsPickSelected,
						onActivated = function()
							if peek(props.editorsPickSelected) then
								selectAll()
								props.searchCallback()
							else
								props.editorsPickCallback()
							end
						end
					}),

					ExpandingOptionsButton(scope, {
						text = "Accessories",
						layoutOrder = 15,
						textSize = 20,
						isSelected = scope:Computed(function(use) 
							if use(allSelected) then
								return false
							end
							local currentAssets = use(props.searchAssetCategories)
							for _, categoryInfo in AssetFilterCategories.getAllAssetSearchTypes() do
								if table.find(currentAssets, categoryInfo.assetType) then
									return true
								end
							end
							return false
						end),

						children = {
							scope:ForPairs(scope:Value(AssetFilterCategories.getAllAssetSearchTypes()), function(use, scope, index, categoryInfo)
								return index, CategoryButton(scope, {
									text = "- " ..categoryInfo.name,
									size = UI_CONSTANTS.CATEGORY_BUTTON_SIZE,
									layoutOrder = index,
									isSelected = isAssetSelected(categoryInfo.assetType),
									onActivated = function()
										toggleCategory(categoryInfo.assetType, nil)
									end
								})
							end)
						}
					}),

					ExpandingOptionsButton(scope, {
						text = "2D Clothing",
						layoutOrder = 16,
						isSelected = scope:Computed(function(use) 
							if use(allSelected) then
								return false
							end
							local currentAssets = use(props.searchAssetCategories)
							for _, categoryInfo in AssetFilterCategories.getAllClassicAssetSearchTypes() do
								if table.find(currentAssets, categoryInfo.assetType) then
									return true
								end
							end
							return false
						end),

						children = {
							scope:ForPairs(scope:Value(AssetFilterCategories.getAllClassicAssetSearchTypes()), function(use, scope, index, categoryInfo)
								return index, CategoryButton(scope, {
									text = "- " ..categoryInfo.name,
									size = UI_CONSTANTS.CATEGORY_BUTTON_SIZE,
									layoutOrder = index,
									isSelected = isAssetSelected(categoryInfo.assetType),
									onActivated = function()
										toggleCategory(categoryInfo.assetType, nil)
									end
								})
							end)
						}
					}),

					CategoryButton(scope, {
						text = "Hair",
						size = UI_CONSTANTS.CATEGORY_BUTTON_SIZE,
						layoutOrder = 5,
						isSelected = isAssetSelected(Enum.AvatarAssetType.HairAccessory),
						onActivated = function()
							toggleCategory(Enum.AvatarAssetType.HairAccessory, nil)
						end
					}),

					CategoryButton(scope, {
						text = "Hats",
						size = UI_CONSTANTS.CATEGORY_BUTTON_SIZE,
						layoutOrder = 6,
						isSelected = isAssetSelected(Enum.AvatarAssetType.Hat),
						onActivated = function()
							toggleCategory(Enum.AvatarAssetType.Hat, nil)
						end
					}),

					CategoryButton(scope, {
						text = "Shoes",
						size = UI_CONSTANTS.CATEGORY_BUTTON_SIZE,
						layoutOrder = 7,
						isSelected = scope:Computed(function(use)
							if use(allSelected) then
								return false
							end
							local currentAssets = use(props.searchAssetCategories)
							return table.find(currentAssets, Enum.AvatarAssetType.RightShoeAccessory) ~= nil
								or table.find(currentAssets, Enum.AvatarAssetType.LeftShoeAccessory) ~= nil
						end),
						onActivated = function()
							toggleCategory(nil, Enum.BundleType.Shoes)
						end
					}),

					CategoryButton(scope, {
						text = "T-Shirts",
						size = UI_CONSTANTS.CATEGORY_BUTTON_SIZE,
						layoutOrder = 8,
						isSelected = isAssetSelected(Enum.AvatarAssetType.TShirtAccessory),
						onActivated = function()
							toggleCategory(Enum.AvatarAssetType.TShirtAccessory, nil)
						end
					}),

					CategoryButton(scope, {
						text = "Shirts",
						size = UI_CONSTANTS.CATEGORY_BUTTON_SIZE,
						layoutOrder = 9,
						isSelected = isAssetSelected(Enum.AvatarAssetType.ShirtAccessory),
						onActivated = function()
							toggleCategory(Enum.AvatarAssetType.ShirtAccessory, nil)
						end
					}),

					CategoryButton(scope, {
						text = "Pants",
						size = UI_CONSTANTS.CATEGORY_BUTTON_SIZE,
						layoutOrder = 10,
						isSelected = isAssetSelected(Enum.AvatarAssetType.PantsAccessory),
						onActivated = function()
							toggleCategory(Enum.AvatarAssetType.PantsAccessory, nil)
						end
					}),

					CategoryButton(scope, {
						text = "Jackets",
						size = UI_CONSTANTS.CATEGORY_BUTTON_SIZE,
						layoutOrder = 11,
						isSelected = isAssetSelected(Enum.AvatarAssetType.JacketAccessory),
						onActivated = function()
							toggleCategory(Enum.AvatarAssetType.JacketAccessory, nil)
						end
					}),

					CategoryButton(scope, {
						text = "Sweaters",
						size = UI_CONSTANTS.CATEGORY_BUTTON_SIZE,
						layoutOrder = 12,
						isSelected = isAssetSelected(Enum.AvatarAssetType.SweaterAccessory),
						onActivated = function()
							toggleCategory(Enum.AvatarAssetType.SweaterAccessory, nil)
						end
					}),

					CategoryButton(scope, {
						text = "Shorts",
						size = UI_CONSTANTS.CATEGORY_BUTTON_SIZE,
						layoutOrder = 13,
						isSelected = isAssetSelected(Enum.AvatarAssetType.ShortsAccessory),
						onActivated = function()
							toggleCategory(Enum.AvatarAssetType.ShortsAccessory, nil)
						end
					}),

					CategoryButton(scope, {
						text = "Dresses & Skirts",
						size = UI_CONSTANTS.CATEGORY_BUTTON_SIZE,
						layoutOrder = 14,
						isSelected = isAssetSelected(Enum.AvatarAssetType.DressSkirtAccessory),
						onActivated = function()
							toggleCategory(Enum.AvatarAssetType.DressSkirtAccessory, nil)
						end
					}),

					ExpandingOptionsButton(scope, {
						text = "Body",
						layoutOrder = 3,
						isSelected = scope:Computed(function(use) 
							if use(allSelected) then
								return false
							end
							local currentBundles = use(props.searchBundleCategories)
							for _, bundleTypeInfo in BundleFilterCategories.getAllRobloxBundleSearchTypes() do
								if table.find(currentBundles, bundleTypeInfo.bundleType) then
									return true
								end
							end
							return false
						end),

						children = {
							scope:ForPairs(scope:Value(BundleFilterCategories.getAllRobloxBundleSearchTypes()), function(use, scope, index, bundleTypeInfo)
								return index, CategoryButton(scope, {
									text = "- " ..bundleTypeInfo.name,
									size = UI_CONSTANTS.CATEGORY_BUTTON_SIZE,
									layoutOrder = index,
									isSelected = isBundleSelected(bundleTypeInfo.bundleType),
									onActivated = function()
										toggleCategory(nil, bundleTypeInfo.bundleType)
									end
								})
							end)
						}
					}),

					ExpandingOptionsButton(scope, {
						text = "Animations",
						layoutOrder = 17,
						isSelected = scope:Computed(function(use) 
							if use(allSelected) then
								return false
							end
							local currentAssets = use(props.searchAssetCategories)
							local currentBundles = use(props.searchBundleCategories)
							return table.find(currentAssets, Enum.AvatarAssetType.EmoteAnimation) ~= nil
								or table.find(currentBundles, Enum.BundleType.Animations) ~= nil
						end),

						children = {
							CategoryButton(scope, {
								text = "- Emotes",
								size = UI_CONSTANTS.CATEGORY_BUTTON_SIZE,
								layoutOrder = 1,
								isSelected = isAssetSelected(Enum.AvatarAssetType.EmoteAnimation),
								onActivated = function()
									toggleCategory(Enum.AvatarAssetType.EmoteAnimation, nil)
								end
							}),

							CategoryButton(scope, {
								text = "- Animation Bundles",
								size = UI_CONSTANTS.CATEGORY_BUTTON_SIZE,
								layoutOrder = 2,
								isSelected = isBundleSelected(Enum.BundleType.Animations),
								onActivated = function()
									toggleCategory(nil, Enum.BundleType.Animations)
								end
							})
						}
					})
				}
			}
		}
	} :: Frame

	return categoryFrame
end

return CategoryFrame