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
local ANIMATIONS = {Enum.AvatarAssetType.EmoteAnimation, Enum.BundleType.Animations}

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
				Size = UDim2.fromScale(1, 0.99),
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
						PaddingTop = UDim.new(0.01,0),
						PaddingLeft = UDim.new(0.01,0),
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
					
					CategoryButton(scope, {
						text = "Editor's Pick",
						size = UI_CONSTANTS.CATEGORY_BUTTON_SIZE,
						layoutOrder = 2,
						isSelected = props.editorsPickSelected,
						onActivated = function()
							if not peek(props.editorsPickSelected) then
								props.editorsPickCallback()
							else
								SelectAll()
								props.searchCallback()
							end
						end
					}),

					ExpandingOptionsButton(scope, {
						text = "Accessories",
						layoutOrder = 2,
						textSize = 20,
						isSelected = scope:Computed(function(use) 
							if use(allSelected) then
								return false
							else
								local currentAssets = use(props.searchAssetCategories)  
								for _, categoryInfo in AssetFilterCategories.getAllAssetSearchTypes() do
									if table.find(currentAssets, categoryInfo.assetType) then
										return true
									end
								end
								return false
							end
						end),

						children = {
							scope:ForPairs(scope:Value(AssetFilterCategories.getAllAssetSearchTypes()), function(use, scope, index, categoryInfo)
								return index, CategoryButton(scope, {
									text = categoryInfo.name,
									size = UI_CONSTANTS.CATEGORY_BUTTON_SIZE,
									layoutOrder = index,
									isSelected = scope:Computed(function(use)
										if use(allSelected) then
											return false
										else
											return table.find(use(props.searchAssetCategories), categoryInfo.assetType) ~= nil
										end
									end),

									onActivated = function()
										if use(allSelected) then
											props.searchAssetCategories:set({categoryInfo.assetType})
											props.searchBundleCategories:set({})
											props.searchCallback()
											return
										end 

										local currentAssets = peek(props.searchAssetCategories)
										local assetIndex = table.find(currentAssets, categoryInfo.assetType)

										if assetIndex then
											SelectAll()
											props.searchCallback()
										else
											props.searchAssetCategories:set({categoryInfo.assetType})
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
								for _, categoryInfo in AssetFilterCategories.getAllClassicAssetSearchTypes() do
									if table.find(currentAssets, categoryInfo.assetType) then
										return true
									end
								end
								return false
							end
						end),

						children = {
							scope:ForPairs(scope:Value(AssetFilterCategories.getAllClassicAssetSearchTypes()), function(use, scope, index, categoryInfo)
								return index, CategoryButton(scope, {
									text = categoryInfo.name,
									size = UI_CONSTANTS.CATEGORY_BUTTON_SIZE,
									layoutOrder = index,
									isSelected = scope:Computed(function(use)
										if use(allSelected) then
											return false
										else
											return table.find(use(props.searchAssetCategories), categoryInfo.assetType) ~= nil
										end
									end),

									onActivated = function()
										if use(allSelected) then
											props.searchAssetCategories:set({categoryInfo.assetType})
											props.searchBundleCategories:set({})
											props.searchCallback()
											return
										end 

										local currentAssets = peek(props.searchAssetCategories)
										local assetIndex = table.find(currentAssets, categoryInfo.assetType)

										if assetIndex then
											SelectAll()
											props.searchCallback()
										else
											props.searchAssetCategories:set({categoryInfo.assetType})
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
								for _, bundleType in BundleFilterCategories.getAllRobloxBundleSearchTypes() do
									if table.find(currentBundles, bundleType) then
										return true
									end
								end
								return false
							end
						end),

						children = {
							scope:ForPairs(scope:Value(BundleFilterCategories.getAllRobloxBundleSearchTypes()), function(use, scope, index, bundleTypeInfo)
								return index, CategoryButton(scope, {
									text = bundleTypeInfo.name,
									size = UI_CONSTANTS.CATEGORY_BUTTON_SIZE,
									layoutOrder = index,
									isSelected = scope:Computed(function(use)
										if use(allSelected) then
											return false
										else
											return table.find(use(props.searchBundleCategories), bundleTypeInfo.bundleType) ~= nil
										end
									end),

									onActivated = function()
										if use(allSelected) then
											props.searchBundleCategories:set({bundleTypeInfo.bundleType})
											props.searchAssetCategories:set({})
											props.searchCallback()
											return
										end 

										local currentBundles = peek(props.searchBundleCategories)
										local assetIndex = table.find(currentBundles, bundleTypeInfo.bundleType)

										if assetIndex then
											SelectAll()
											props.searchCallback()
										else
											props.searchBundleCategories:set({bundleTypeInfo.bundleType})
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
							CategoryButton(scope, {
								text = "Emotes",
								size = UI_CONSTANTS.CATEGORY_BUTTON_SIZE,
								layoutOrder = 1,
								isSelected = scope:Computed(function(use)
									if use(allSelected) then
										return false
									else
										return table.find(use(props.searchAssetCategories), Enum.AvatarAssetType.EmoteAnimation) ~= nil
									end
								end),

								onActivated = function()
									if peek(allSelected) then
										props.searchBundleCategories:set({})
										props.searchAssetCategories:set({Enum.AvatarAssetType.EmoteAnimation})
										props.searchCallback()
										return
									end 

									local currentAssets = peek(props.searchAssetCategories)
									local assetIndex = table.find(currentAssets, Enum.AvatarAssetType.EmoteAnimation)

									if assetIndex then
										SelectAll()
										props.searchCallback()
									else
										props.searchBundleCategories:set({})
										props.searchAssetCategories:set({Enum.AvatarAssetType.EmoteAnimation})
										props.searchCallback()
									end
								end
							}),
								CategoryButton(scope, {
									text = "Animations",
									size = UI_CONSTANTS.CATEGORY_BUTTON_SIZE,
									layoutOrder = 2,
									isSelected = scope:Computed(function(use)
										if use(allSelected) then
											return false
										else
											return table.find(use(props.searchBundleCategories), Enum.BundleType.Animations) ~= nil
										end
									end),

									onActivated = function()
										if peek(allSelected) then
											props.searchBundleCategories:set({Enum.BundleType.Animations})
											props.searchAssetCategories:set({})
											props.searchCallback()
											return
										end 

										local currentBundles = peek(props.searchBundleCategories)
										local assetIndex = table.find(currentBundles, Enum.BundleType.Animations)

										if assetIndex then
											SelectAll()
											props.searchCallback()
										else
											props.searchBundleCategories:set({Enum.BundleType.Animations})
											props.searchAssetCategories:set({})
											props.searchCallback()
										end
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