-- CategoryFrame.lua

-- Services
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AvatarEditorService = game:GetService("AvatarEditorService")

-- Folders
local DataTables = ReplicatedStorage:WaitForChild("DataTables")
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
local OnEvent = Fusion.OnEvent
type UsedAs<T> = Fusion.UsedAs<T>

-- GUI Components
local CategoryButton = require(Widgets:WaitForChild("CategoryButton"))
local BaseButton = require(Widgets:WaitForChild("BaseButton"))


function CategoryFrame(
	scope: Fusion.Scope,
	currentView: UsedAs<string>,
	searchAssetCategories: Fusion.Value<{Enum.AvatarAssetType}>,
	searchBundleCategories: Fusion.Value<{Enum.BundleType}>,
	props: {
		size: UsedAs<UDim2>?,
		position: UsedAs<UDim2>?,
		anchorPoint: UsedAs<Vector2>?,
		layoutOrder: UsedAs<number>?,
		backgroundColor3: UsedAs<Color3>?,
		backgroundTransparency: UsedAs<number>?,
		visible: UsedAs<boolean>?,
		name: UsedAs<string>?,
		isSelected: UsedAs<boolean>?
	}?
): Frame
	local AssetFilterCategories = require(DataTables:WaitForChild("AssetFilterCategories"))
	local BundleFilterCategories = require(DataTables:WaitForChild("BundleFilterCategories"))
	
	local allSelected = scope:Computed(function(use)
		if #use(searchAssetCategories) == #AssetFilterCategories.getAllAssetTypes() and #use(searchBundleCategories) == #BundleFilterCategories.getAllRobloxBundleTypes() then
			return true
		else
			return false
		end
	end)



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
			return use(currentView) == "Catalog"
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
				CornerRadius = UDim.new(0.05, 0)
			},
			
			-- Button to open outfits view
			scope:New "Frame" {
				Name = "OutfitsButtonFrame",
				LayoutOrder = 2,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(0.8, 0.1),
				
				[Children] = {

					BaseButton(scope, {
						name = "MyOutfits",
						text = "My Outfits",
						textScaled = true,
						size = UDim2.fromScale(1, 1),
						backgroundColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
						strokeColor = Color3.new(1,1,1),
						strokeThickness = 2,
						textColor = Color3.new(1,1,1),

						onActivated = function()
							currentView:set("Outfits")
						end,
						
						[Children] = {
							scope:New "UICorner" {
								CornerRadius = UDim.new(0.05, 0)
							},
							scope:New "UIStroke" {
								ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
								Color = Color3.new(1, 1, 1),
								Thickness = 1,
							}
						}
					}
				)
					
				}
			},
			
			-- Inner scrolling frame
			scope:New "ScrollingFrame" {
				Name = "CategoryScrollFrame",
				Size = UDim2.fromScale(0.9, 0.8),
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
						size = UDim2.fromScale(0.8, 0.1),
						layoutOrder = 0,
						isSelected = allSelected,
						onActivated = function()
							if not peek(allSelected) then
								searchAssetCategories:set(AssetFilterCategories.getAllAssetTypes())
								searchBundleCategories:set(BundleFilterCategories.getAllRobloxBundleTypes())
							else
								searchAssetCategories:set({})
								searchBundleCategories:set({})
							end
						end
					}),

					-- Create category buttons for assets
					scope:ForValues(scope:Value(AssetFilterCategories.getAllAssetTypes()), function(use, scope, assetType)
						return CategoryButton(scope, {
							text = assetType.Name,
							size = UDim2.fromScale(0.8, 0.1),
							isSelected = scope:Computed(function(use)
								if use(allSelected) then
									return false
								else
									return table.find(use(searchAssetCategories), assetType) ~= nil
								end
							end),
							
							onActivated = function()
								if use(allSelected) then
									searchBundleCategories:set({})
									searchAssetCategories:set({assetType})
									return
								end

								local currentAssets = peek(searchAssetCategories) -- Use peek instead of use
								local assetIndex = table.find(currentAssets, assetType)

								if assetIndex then
									-- Create new array without the asset
									local newAssets = {}

									for i, asset in ipairs(currentAssets) do
										if i ~= assetIndex then 
											table.insert(newAssets, asset)
										end
									end

									searchAssetCategories:set(newAssets) -- Set the new array
								else
									-- Create new array with the asset added
									local newAssets = {table.unpack(currentAssets)}
									table.insert(newAssets, assetType)
									searchAssetCategories:set(newAssets) -- Set the new array
								end
							end

						})
					end),
					
					-- Create category buttons for bundles
					scope:ForValues(scope:Value(BundleFilterCategories.getAllRobloxBundleTypes()), function(use, scope, bundleType)
						return CategoryButton(scope, {
							text = bundleType.Name,
							size = UDim2.fromScale(0.8, 0.1),
							isSelected = scope:Computed(function(use)
								if use(allSelected) then
									return false
								else
									return table.find(use(searchBundleCategories), bundleType) ~= nil
								end
							end),

							onActivated = function()
								if use(allSelected) then
									searchBundleCategories:set({bundleType})
									searchAssetCategories:set({})
									return
								end

								local currentBundles = peek(searchBundleCategories) -- Use peek instead of use
								local assetIndex = table.find(currentBundles, bundleType)

								if assetIndex then
									-- Create new array without the asset
									local newAssets = {}
									for i, asset in ipairs(currentBundles) do
										if i ~= assetIndex then
											table.insert(newAssets, asset)
										end
									end
									searchBundleCategories:set(newAssets) -- Set the new array
								else
									-- Create new array with the asset added
									local newAssets = {table.unpack(currentBundles)}
									table.insert(newAssets, bundleType)
									searchBundleCategories:set(newAssets) -- Set the new array
								end
							end
						})
					end)
				}
			}
		}
	} :: Frame

	return categoryFrame
end

return CategoryFrame