--!strict

-- AvatarViewport.lua

-- Services
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Getters = ReplicatedStorage:WaitForChild("Getters")
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local Widgets = FusionComponents:WaitForChild("Widgets")

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))
local getItemIcon = require(Utility:WaitForChild("getItemIcon"))
local BuyButton = require(Widgets:WaitForChild("BuyButton"))
local TryButton = require(Widgets:WaitForChild("TryButton"))
local NameLabel = require(Widgets:WaitForChild("NameLabel"))
local PriceLabel = require(Widgets:WaitForChild("PriceLabel"))

-- Remotes
local PlayerEquippedItem = Remotes:WaitForChild("PlayerEquippedItem")

-- Fusion
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local ForValues = Fusion.ForValues
local peek = Fusion.peek
local Value = Fusion.Value

-- Colors
local COLOUR_WHITE = UI_CONSTANTS.COLOUR_WHITE
local COLOUR_BLACK = UI_CONSTANTS.COLOUR_BLACK
local COLOUR_GREY = UI_CONSTANTS.COLOUR_GREY
-- LERP
local COLOUR_HOVER = COLOUR_WHITE:Lerp(COLOUR_GREY, 0.5)

-- Config
local CONFIG = {
	SIZE = UDim2.fromOffset(200, 200),
}

-- BIG NOTE / TODO: This should really be what we use for all item tiles, i.e. also the ones when we equip
function FusionItemTile(
	scope: Fusion.Scope,
	itemDetails: {
		Id: number,
		Name: string,
		ItemType: string,
		AssetType: string?,
		BundleType: string?,
		Price: number,
	}
)
	
	print(itemDetails)
	-- Get info type for product info query
	local infoType
	
	if itemDetails.ItemType == Enum.InfoType.Asset.Name then
		infoType = Enum.InfoType.Asset.Name
	elseif itemDetails.ItemType == Enum.InfoType.Bundle.Name then
		infoType = Enum.InfoType.Bundle.Name
	end
	
	local isHovering = scope:Value(false)
	
	local backgroundColorSpring = scope:Spring(
		scope:Computed(function(use)
			if use(isHovering) then
				return COLOUR_HOVER
			else
				return COLOUR_WHITE
			end
		end),
		20,
		1
	)
	
	local fusionItemTile = scope:New "Frame" {
		Name = itemDetails.Name,
		Size = CONFIG.SIZE,
		BackgroundTransparency = 1,
		Active = false,
		
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
			
			NameLabel(scope, {
				layoutOrder = 1, 
				text = itemDetails.Name,
			}),
			
			scope:New "TextButton" {
				LayoutOrder = 2,
				Text = itemDetails.Name,
				TextTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = backgroundColorSpring,
				BackgroundTransparency = 0,
				ZIndex = 1,
				Active = false,
				
				[OnEvent "MouseEnter"] = function()
					isHovering:set(true)
				end,
				
				[OnEvent "MouseLeave"] = function()
					isHovering:set(false)
				end,
				
				[Children] = {
					scope:New "UICorner" {
						CornerRadius = UDim.new(0.1, 0),
					},
					
					scope:New "ImageLabel" {
						BackgroundTransparency = 1,
						ImageColor3 = backgroundColorSpring,
						Size = UDim2.fromScale(1, 1),
						-- TODO: We have to make this compatible with bundles my guy...
						Image = "rbxthumb://type=" .. (itemDetails.ItemType == "Asset" and "Asset" or "BundleThumbnail") .. "&id=" .. itemDetails.Id .. "&w=420&h=420",
						ZIndex = 1,
						Active = false
					},
					
					-- TODO: Turn this into a module component
					scope:New "Frame"{
						Name = "ButtonsFrame",
						ZIndex = 2,
						Visible = isHovering,
						Active = isHovering,
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromScale(0.8, 0.5),
						BackgroundTransparency = 1,

						[Children] = {
							scope:New "UIListLayout" {
								SortOrder = Enum.SortOrder.LayoutOrder,
								FillDirection = Enum.FillDirection.Vertical,
								HorizontalFlex = Enum.UIFlexAlignment.Fill,
								VerticalFlex = Enum.UIFlexAlignment.Fill,
								Padding = UDim.new(0.1, 0),
								ItemLineAlignment = Enum.ItemLineAlignment.Center,
								VerticalAlignment = Enum.VerticalAlignment.Center,
								HorizontalAlignment = Enum.HorizontalAlignment.Center,

							},

							TryButton(scope, {
								assetId = itemDetails.Id,
								assetOrBundleType = itemDetails.AssetType or itemDetails.BundleType,
								itemType = itemDetails.ItemType,
								layoutOrder = 1 
							}), 

							BuyButton(scope, {
								assetId = itemDetails.Id,
								layoutOrder = 2,  
							})
						}
					}
				}
			},
			
			-- PriceLabel
			PriceLabel(scope, {
				text = itemDetails.Price,
			})
		}
	}
	
	return fusionItemTile
end

return FusionItemTile