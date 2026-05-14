--!strict
-- SearchFrame.lua

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local Widgets = FusionComponents:WaitForChild("Widgets")

-- Modules
local Constants = require(ReplicatedStorage.Constants)
local Fusion = require(Utility:WaitForChild("Fusion"))
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))

-- Fusion
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

-- GUI Components
local SearchBox = require(script:WaitForChild("SearchBox"))
local SearchResultsFrame = require(script:WaitForChild("SearchResultsFrame"))
local FusionDropdown = require(Widgets:WaitForChild("FusionDropdown"))
local SEARCH_SORT_BOX_SIZE = UDim2.fromScale(.15, .5)
local options = {
	"Relevance",
	"Bestselling",
	"Most Favorited",
	"Price High To Low",
	"Price Low To High",
	"Recently Created",
}

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
		searchBundleCategories: UsedAs<{Enum.BundleType}>,
		searchSort: UsedAs<Enum.CatalogSortType>,
		searchResults: UsedAs<CatalogPages>,
		searchText: UsedAs<string>,
		searchCallback: () -> (),
		loadMoreCallback: () -> ()
	}
): (Frame, ScrollingFrame, Frame)
	local searchResultsFrame = SearchResultsFrame(scope) :: ScrollingFrame
	local canvasPositionObserver = searchResultsFrame:GetPropertyChangedSignal("CanvasPosition")

    canvasPositionObserver:Connect(function()
        local scrollPosition = searchResultsFrame.CanvasPosition.Y
        local canvasSize = searchResultsFrame.AbsoluteCanvasSize.Y
        local frameSize = searchResultsFrame.AbsoluteSize.Y
        -- If scrolled to within 200 pixels of bottom, load more
        if scrollPosition + frameSize >= canvasSize - 200 then
            props.loadMoreCallback()
        end
    end)

	local topBar = scope:New "Frame" {
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
				Size = UDim2.fromScale(0.02, 1),
				BackgroundTransparency = 1,
				LayoutOrder = 1
			},

			-- Search box
			SearchBox(scope, {
				name = "CatalogSearch",
				size = SEARCH_SORT_BOX_SIZE,
				layoutOrder = 2,
				placeholder = Constants.SEARCH_PLACEHOLDER,
				searchText = props.searchText,
				searchCallback = props.searchCallback,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),

			-- Sort dropdown
			FusionDropdown(scope, {
				name = "SortDropdown",
				options = options,
				selectedValue = props.searchSort,
				size = UDim2.fromScale(0.08, 0.5),
				layoutOrder = 3,
				placeholder = "Sort by...",
				searchCallback = props.searchCallback
			})
		}
	}

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
			topBar,
 
			-- Search results
			searchResultsFrame
		}
	} :: Frame

	return searchFrame, searchResultsFrame, topBar
end

return SearchFrame