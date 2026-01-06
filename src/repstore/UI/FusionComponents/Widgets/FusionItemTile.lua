--!strict

-- AvatarViewport.lua

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
local BuyButton = require(Widgets:WaitForChild("BuyButton"))
local TryButton = require(Widgets:WaitForChild("TryButton"))
local NameLabel = require(Widgets:WaitForChild("NameLabel"))
local PriceLabel = require(Widgets:WaitForChild("PriceLabel"))

-- Fusion
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

-- Colors
local COLOUR_WHITE = UI_CONSTANTS.COLOUR_WHITE
local COLOUR_GREY = UI_CONSTANTS.COLOUR_GREY
-- LERP
local COLOUR_HOVER = COLOUR_WHITE:Lerp(COLOUR_GREY, 0.5)

-- Config
local CONFIG = {
	SIZE = UDim2.fromOffset(300, 300),
}

-- BIG NOTE / TODO: This should really be what we use for all item tiles, i.e. also the ones when we equip
function FusionItemTile( 
	scope: Fusion.Scope,
	props: {
		itemDetails: {
			Id: number,
			Name: string,
			ItemType: string,
			AssetType: string?,
			AssetTypeId: number?,
			BundleType: string?,
			Price: number,
		},
		
		layoutOrder: number
	}
)
	print(props.itemDetails)
	local isHovering = scope:Value(false)
	local isActivated = scope:Value(false)
	
	local function toggleActivationCallback(): ()
		isActivated:set(not peek(isActivated))
	end
	
	local backgroundColorSpring = scope:Spring(
		scope:Computed(function(use)
			if use(isActivated) or use(isHovering) then
				return COLOUR_HOVER
			else
				return COLOUR_WHITE
			end
		end),
		20,
		1
	)
	
	local fusionItemTile = scope:New "Frame" {
		Name = props.itemDetails.Name,
		Size = CONFIG.SIZE,
		BackgroundTransparency = 1,
		Active = false,
		LayoutOrder = props.layoutOrder,
		
		[Children] = {
			scope:New "UIListLayout" {
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalFlex = Enum.UIFlexAlignment.Fill,
				VerticalFlex = Enum.UIFlexAlignment.Fill,
				Padding = UDim.new(0.05, 0),
				ItemLineAlignment = Enum.ItemLineAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			},

			scope:New "UICorner" {
				CornerRadius = UDim.new(0.1,0)
			},

			scope:New "UIStroke" {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = UI_CONSTANTS.TASTEMAKER_PURPLE,
				Thickness = 2,
			},

			scope:New "UIPadding" {
				PaddingTop = UDim.new(0.01,0),
				PaddingBottom = UDim.new(0.01,0),
				PaddingLeft = UDim.new(0.01,0),
				PaddingRight = UDim.new(0.01,0),
			},
			
			NameLabel(scope, {
				layoutOrder = 0, 
				text = props.itemDetails.Name,
				textSize = 20,
			}),
			
			scope:New "TextButton" {
				Name = "ItemButton",
				LayoutOrder = 1,
				Text = props.itemDetails.Name,
				TextTransparency = 1,
				Size = UDim2.fromScale(0.8, 0.8),
				BackgroundColor3 = backgroundColorSpring,
				BackgroundTransparency = 0,
				ZIndex = 1,
				Active = true, 
				
				[OnEvent "MouseEnter"] = function()
					isHovering:set(true)
				end,
				
				[OnEvent "MouseLeave"] = function()
					isHovering:set(false)
				end,

				[OnEvent "MouseButton1Click"] = function()
					toggleActivationCallback()
				end,
				
				[Children] = {
					scope:New "UIAspectRatioConstraint" {
						AspectRatio = 1,
						AspectType = Enum.AspectType.ScaleWithParentSize
					},
					
					scope:New "UICorner" {
						CornerRadius = UDim.new(0.1, 0),
					},
					
					scope:New "ImageLabel" {
						BackgroundTransparency = 1,
						ImageColor3 = backgroundColorSpring,
						Size = UDim2.fromScale(1, 1),
						Image = "rbxthumb://type=" .. (props.itemDetails.ItemType == "Asset" and "Asset" or "BundleThumbnail") .. "&id=" .. props.itemDetails.Id .. "&w=420&h=420",
						ZIndex = 1,
						Active = false
					},
					
					scope:New "Frame"{
						Name = "ButtonsFrame",
						ZIndex = 2,
						Visible = isActivated or isHovering,
						Active = false,
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromScale(0.9, 0.8),
						BackgroundTransparency = 1,

						[Children] = {
							scope:New "UIListLayout" {
								SortOrder = Enum.SortOrder.LayoutOrder,
								FillDirection = Enum.FillDirection.Vertical,
								HorizontalFlex = Enum.UIFlexAlignment.Fill,
								VerticalFlex = Enum.UIFlexAlignment.Fill,
								Padding = UDim.new(0.3, 0),
								ItemLineAlignment = Enum.ItemLineAlignment.Center,
								VerticalAlignment = Enum.VerticalAlignment.Center,
								HorizontalAlignment = Enum.HorizontalAlignment.Center,

							},

							TryButton(scope, {
								assetId = props.itemDetails.Id,
								assetOrBundleType = props.itemDetails.AssetType or props.itemDetails.BundleType,
								itemType = props.itemDetails.ItemType,
								layoutOrder = 1,
								onTryonCallback = toggleActivationCallback
							}), 

							BuyButton(scope, {
								assetId = props.itemDetails.Id,
								layoutOrder = 2,  
								onPurchaseCallback = toggleActivationCallback
							})
						}
					}
				}
			},
			
			-- PriceLabel
			PriceLabel(scope, {
				layoutOrder = 2,
				text = props.itemDetails.Price,
			}),
		}
	}
	
	return fusionItemTile
end

return FusionItemTile