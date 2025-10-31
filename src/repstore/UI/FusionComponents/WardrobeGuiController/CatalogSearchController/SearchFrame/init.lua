--!strict
-- SearchFrame.lua

-- Services
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AvatarEditorService = game:GetService("AvatarEditorService")

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
type UsedAs<T> = Fusion.UsedAs<T>

-- GUI Components
local SearchBox = require(script:WaitForChild("SearchBox"))
local SearchResultsFrame = require(script:WaitForChild("SearchResultsFrame"))
local FusionDropdown = require(Widgets:WaitForChild("FusionDropdown"))

function SearchFrame(
	scope: Fusion.Scope,
	props: {
		size: UsedAs<UDim2>?,
		position: UsedAs<UDim2>?,
		anchorPoint: UsedAs<Vector2>?,
		layoutOrder: UsedAs<number>?,
		backgroundTransparency: UsedAs<number>?,
		currentView: UsedAs<string>,
		searchAssetCategories: UsedAs<{Enum.AvatarAssetType}>, 
		searchBundleCategories: UsedAs<Enum.BundleType>,
		searchSort: UsedAs<Enum.CatalogSortType>,
		searchResults: UsedAs<CatalogPages>,
		searchText: UsedAs<string>,
		searchCallback: () -> ()
	}
): Frame
	local searchFrame = scope:New "Frame" {
		Name = "SearchFrame",
		Visible = scope:Computed(function(use)
			return use(props.currentView) == "Catalog"
		end),
		Size = (props and props.size) or UDim2.fromScale(1, 1),
		Position = (props and props.position) or UDim2.fromScale(0.5, 0.5),
		AnchorPoint = (props and props.anchorPoint) or Vector2.new(0.5, 0.5),
		LayoutOrder = (props and props.layoutOrder) or 2,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = (props and props.backgroundTransparency) or UI_CONSTANTS.TRANSPARENCY_TRANSLUCENT,

		[Children] = {
			scope:New "UIListLayout" {
				Padding = UDim.new(0, 10),
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
			},

			scope:New "UICorner" {
				CornerRadius = UDim.new(0.05, 0)
			},

			-- Top bar with search controls
			scope:New "Frame" {
				Name = "TopBar",
				Size = UDim2.fromScale(1, 0.1),
				BackgroundTransparency = 1,
				LayoutOrder = 1,

				[Children] = {
					scope:New "UIListLayout" {
						Padding = UDim.new(0, 10),
						FillDirection = Enum.FillDirection.Horizontal,
						SortOrder = Enum.SortOrder.LayoutOrder,
						HorizontalAlignment = Enum.HorizontalAlignment.Left,
						VerticalAlignment = Enum.VerticalAlignment.Center,
					},

					-- Spacer
					scope:New "Frame" {
						Name = "LeftSpacer",
						Size = UDim2.fromScale(0.1, 1),
						BackgroundTransparency = 1,
						LayoutOrder = 1
					},

					-- Search box
					SearchBox(scope, {
						name = "CatalogSearch",
						size = UI_CONSTANTS.SEARCH_SORT_BOX_SIZE,
						layoutOrder = 2,
						placeholder = "Search for items...",
						searchText = props.searchText,
						searchCallback = props.searchCallback
					}),

					-- Sort dropdown
					FusionDropdown(scope, {
						name = "SortDropdown",
						options = Enum.CatalogSortType:GetEnumItems(),
						selectedValue = props.searchSort,
						size = UI_CONSTANTS.SEARCH_SORT_BOX_SIZE,
						layoutOrder = 3,
						placeholder = "Sort by..."
					})
				}
			},
 
			-- Search results
			SearchResultsFrame(scope, props.searchResults)
		}
	} :: Frame

	return searchFrame
end

return SearchFrame