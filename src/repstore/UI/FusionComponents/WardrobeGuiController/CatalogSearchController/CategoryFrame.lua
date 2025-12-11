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
local AssetFilterCategories = require(DataTables:WaitForChild("AssetFilterCategories"))
local BundleFilterCategories = require(DataTables:WaitForChild("BundleFilterCategories"))

-- Fusion
local Children = Fusion.Children
local peek = Fusion.peek
type UsedAs<T> = Fusion.UsedAs<T>

-- GUI Components
local ExpandingOptionsButton = require(Widgets:WaitForChild("ExpandingOptionsButton"))
local CategoryButton = require(Widgets:WaitForChild("CategoryButton"))

-- Button Categories
local CLASSIC_CLOTHING = {Enum.AvatarAssetType.TShirt, Enum.AvatarAssetType.Shirt, Enum.AvatarAssetType.Pants}
local ACCESSORIES = {
	Enum.AvatarAssetType.Hat,
	Enum.AvatarAssetType.HairAccessory,
	Enum.AvatarAssetType.FaceAccessory,
	Enum.AvatarAssetType.NeckAccessory,
	Enum.AvatarAssetType.ShoulderAccessory,
	Enum.AvatarAssetType.FrontAccessory,
	Enum.AvatarAssetType.BackAccessory,
	Enum.AvatarAssetType.WaistAccessory
}
local ANIMATIONS = {Enum.AvatarAssetType.EmoteAnimation}

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
		searchCallback: () -> ()
	}
): Frame
	local allSelected = scope:Computed(function(use)
		if #use(props.searchAssetCategories) == #AssetFilterCategories.getAllAssetTypes() and #use(props.searchBundleCategories) == #BundleFilterCategories.getAllRobloxBundleTypes() then
			return true
		else
			return false
		end
	end)

	local function SelectAll()
		props.searchAssetCategories:set(AssetFilterCategories.getAllAssetTypes())
		props.searchBundleCategories:set(BundleFilterCategories.getAllRobloxBundleTypes())
	end

	-- Outer container frame
	local categoryFrame = scope:New "Frame" {
		Name = (props and props.name) or "CategoryFrame",
		Size = (props and props.size) or UDim2.fromScale(1, 0.2),
		Position = (props and props.position) or UDim2.fromScale(0.5, 0.1),
		AnchorPoint = (props and props.anchorPoint) or Vector2.new(0.5, 0.5),
		LayoutOrder = (props and props.layoutOrder) or 1,
		BackgroundColor3 = (props and props.backgroundColor3) or UI_CONSTANTS.TASTEMAKER_PURPLE,
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
				CornerRadius = UDim.new(0.1, 0)
			},
			
			-- Inner scrolling frame
			scope:New "ScrollingFrame" {
				Name = "CategoryScrollFrame",
				Size = UDim2.fromScale(0.9, 1),
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
					
					CategoryButton(scope, {
						text = "All",
						size = UI_CONSTANTS.CATEGORY_BUTTON_SIZE,
						layoutOrder = 1,
						isSelected = allSelected,
						onActivated = function()
							if not peek(allSelected) then
								SelectAll()
								props.searchCallback()
							else
								props.searchAssetCategories:set({})
								props.searchBundleCategories:set({})
								props.searchCallback()
							end
						end
					}),

					ExpandingOptionsButton(scope, {
						text = "Accessories",
						layoutOrder = 2,
						isSelected = scope:Computed(function(use) 
							if use(allSelected) then
								return false
							else
								local currentAssets = use(props.searchAssetCategories)  
								for _, assetType in ACCESSORIES do
									if table.find(currentAssets, assetType) then
										return true
									end
								end
								return false
							end
						end),

						children = {
							scope:ForPairs(scope:Value(ACCESSORIES), function(use, scope, index, assetType)
								return index, CategoryButton(scope, {
									text = assetType.Name,
									size = UI_CONSTANTS.CATEGORY_BUTTON_SIZE,
									layoutOrder = index,
									isSelected = scope:Computed(function(use)
										if use(allSelected) then
											return false
										else
											return table.find(use(props.searchAssetCategories), assetType) ~= nil
										end
									end),

									onActivated = function()
										if use(allSelected) then
											props.searchAssetCategories:set({assetType})
											props.searchBundleCategories:set({})
											props.searchCallback()
											return
										end 

										local currentAssets = peek(props.searchAssetCategories)
										local assetIndex = table.find(currentAssets, assetType)

										if assetIndex then
											SelectAll()
											props.searchCallback()
										else
											props.searchAssetCategories:set({assetType})
											props.searchBundleCategories:set({})
											props.searchCallback()
										end
									end
								})
							end)
						}
					}),

					ExpandingOptionsButton(scope, {
						text = "Classic Clothing",
						layoutOrder = 3,
						isSelected = scope:Computed(function(use) 
							if use(allSelected) then
								return false
							else
								local currentAssets = use(props.searchAssetCategories)  
								for _, assetType in CLASSIC_CLOTHING do
									if table.find(currentAssets, assetType) then
										return true
									end
								end
								return false
							end
						end),

						children = {
							scope:ForPairs(scope:Value(CLASSIC_CLOTHING), function(use, scope, index, assetType)
								return index, CategoryButton(scope, {
									text = assetType.Name,
									size = UI_CONSTANTS.CATEGORY_BUTTON_SIZE,
									layoutOrder = index,
									isSelected = scope:Computed(function(use)
										if use(allSelected) then
											return false
										else
											return table.find(use(props.searchAssetCategories), assetType) ~= nil
										end
									end),

									onActivated = function()
										if use(allSelected) then
											props.searchAssetCategories:set({assetType})
											props.searchBundleCategories:set({})
											props.searchCallback()
											return
										end 

										local currentAssets = peek(props.searchAssetCategories)
										local assetIndex = table.find(currentAssets, assetType)

										if assetIndex then
											SelectAll()
											props.searchCallback()
										else
											props.searchAssetCategories:set({assetType})
											props.searchBundleCategories:set({})
											props.searchCallback()
										end
									end
								})
							end)
						}
					}),

					CategoryButton(scope, {
						text = "Hair",
						size = UI_CONSTANTS.CATEGORY_BUTTON_SIZE,
						layoutOrder = 4,
						isSelected = scope:Computed(function(use)
							if use(allSelected) then
								return false
							else
								local currentAssets = use(props.searchAssetCategories)
								if table.find(currentAssets, Enum.AvatarAssetType.HairAccessory) then
									return true
								end
								return false
							end
						end),

						onActivated = function()
							if peek(allSelected) then
								props.searchBundleCategories:set({})
								props.searchAssetCategories:set({Enum.AvatarAssetType.HairAccessory})
								props.searchCallback()
								return
							end 

							local currentAssets = peek(props.searchAssetCategories)
							local assetIndex = table.find(currentAssets, Enum.AvatarAssetType.HairAccessory)

							if assetIndex then
								SelectAll()
								props.searchCallback()
							else
								props.searchBundleCategories:set({})
								props.searchAssetCategories:set({Enum.AvatarAssetType.HairAccessory})
								props.searchCallback()
							end
						end
					}),

					CategoryButton(scope, {
						text = "Hats",
						size = UI_CONSTANTS.CATEGORY_BUTTON_SIZE,
						layoutOrder = 5,
						isSelected = scope:Computed(function(use)
							if use(allSelected) then
								return false
							else
								local currentAssets = use(props.searchAssetCategories)
								if table.find(currentAssets, Enum.AvatarAssetType.Hat) then
									return true
								end
								return false
							end
						end),

						onActivated = function()
							if peek(allSelected) then
								props.searchBundleCategories:set({})
								props.searchAssetCategories:set({Enum.AvatarAssetType.Hat})
								props.searchCallback()
								return
							end 

							local currentAssets = peek(props.searchAssetCategories)
							local assetIndex = table.find(currentAssets, Enum.AvatarAssetType.Hat)

							if assetIndex then
								SelectAll()
								props.searchCallback()
							else
								props.searchBundleCategories:set({})
								props.searchAssetCategories:set({Enum.AvatarAssetType.Hat})
								props.searchCallback()
							end
						end
					}),

					ExpandingOptionsButton(scope, {
						text = "Bundles",
						layoutOrder = 6,
						isSelected = scope:Computed(function(use) 
							if use(allSelected) then
								return false
							else
								local currentBundles = use(props.searchBundleCategories)  
								for _, bundleType in BundleFilterCategories.getAllRobloxBundleTypes() do
									if table.find(currentBundles, bundleType) then
										return true
									end
								end
								return false
							end
						end),

						children = {
							scope:ForPairs(scope:Value(BundleFilterCategories.getAllRobloxBundleTypes()), function(use, scope, index, bundleType)
								return index, CategoryButton(scope, {
									text = bundleType.Name,
									size = UI_CONSTANTS.CATEGORY_BUTTON_SIZE,
									layoutOrder = index,
									isSelected = scope:Computed(function(use)
										if use(allSelected) then
											return false
										else
											return table.find(use(props.searchBundleCategories), bundleType) ~= nil
										end
									end),

									onActivated = function()
										if use(allSelected) then
											props.searchBundleCategories:set({bundleType})
											props.searchAssetCategories:set({})
											props.searchCallback()
											return
										end 

										local currentBundles = peek(props.searchBundleCategories)
										local assetIndex = table.find(currentBundles, bundleType)

										if assetIndex then
											SelectAll()
											props.searchCallback()
										else
											props.searchBundleCategories:set({bundleType})
											props.searchAssetCategories:set({})
											props.searchCallback()
										end
									end
								})
							end)
						}
					}),

					ExpandingOptionsButton(scope, {
						text = "Animations",
						layoutOrder = 7,
						isSelected = scope:Computed(function(use) 
							if use(allSelected) then
								return false
							else
								local currentAssets = use(props.searchAssetCategories)  
								for _, assetType in ANIMATIONS do
									if table.find(currentAssets, assetType) then
										return true
									end
								end
								return false
							end
						end),

						children = {
							scope:ForPairs(scope:Value(ANIMATIONS), function(use, scope, index, assetType)
								return index, CategoryButton(scope, {
									text = assetType.Name,
									size = UI_CONSTANTS.CATEGORY_BUTTON_SIZE,
									layoutOrder = index,
									isSelected = scope:Computed(function(use)
										if use(allSelected) then
											return false
										else
											return table.find(use(props.searchAssetCategories), assetType) ~= nil
										end
									end),

									onActivated = function()
										if use(allSelected) then
											props.searchAssetCategories:set({assetType})
											props.searchBundleCategories:set({})
											props.searchCallback()
											return
										end 

										local currentAssets = peek(props.searchAssetCategories)
										local assetIndex = table.find(currentAssets, assetType)

										if assetIndex then
											SelectAll()
											props.searchCallback()
										else
											props.searchAssetCategories:set({assetType})
											props.searchBundleCategories:set({})
											props.searchCallback()
										end
									end
								})
							end)
						}
					})
				}
			}
		}
	} :: Frame

	return categoryFrame
end

return CategoryFrame