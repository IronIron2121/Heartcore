--!strict

-- AvatarViewport.lua

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local Widgets = FusionComponents:WaitForChild("Widgets")

-- Modules
local ClientCustomisationService = require(StarterPlayer.StarterPlayerScripts.Clothing.ClientCustomisationService)
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

-- Constants
-- Colors
local COLOUR_WHITE = UI_CONSTANTS.COLOUR_WHITE
local COLOUR_GREY = UI_CONSTANTS.COLOUR_GREY
-- LERP
local COLOUR_HOVER = COLOUR_WHITE:Lerp(COLOUR_GREY, 0.5)

-- Config
local CONFIG = {
	SIZE = UDim2.fromOffset(300, 300),
	ACTIVATION_DURATION = 2.5
}

--

function FusionItemTile( 
	scope: Fusion.Scope,
props: {
    itemDetails: {
        -- Core identification
        Id: number,
        Name: string,
        ItemType: string,
        ProductId: number?,
        
        -- Type information
        AssetType: string?,
        AssetTypeId: number?,
        BundleType: string?,
        
        -- Pricing
        Price: number?,
        LowestPrice: number?,
        LowestResalePrice: number?,
        
        -- Purchase info
        IsPurchasable: boolean?,
        IsOffSale: boolean?,
        Owned: boolean?, 
        HasResellers: boolean?,
        
        -- Creator info
        CreatorName: string?,
        CreatorType: string?,
        CreatorTargetId: number?,
        CreatorHasVerifiedBadge: boolean?,
        ExpectedSellerId: number?,
        
        -- Collectible/Limited info
        CollectibleItemId: string?,
        TotalQuantity: number?,
        QuantityLimitPerUser: number?,
        UnitsAvailableForConsumption: number?,
        
        -- Metadata
        Description: string?,
        FavoriteCount: number?,
        SaleLocationType: string?,
        ItemRestrictions: {any}?,
        ItemStatus: {any}?,
    },
    
    layoutOrder: number,
	onPurchaseCb: () -> ()?,
	pushLoad: () -> ()?,
	popLoad: () -> ()?,
	onTryCb: () -> ()?
})
	if not props.itemDetails.AssetType and not props.itemDetails.BundleType then return end
	
	local isHovering = scope:Value(false)
	local isActivated = scope:Value(false)

	local priceVal
	local isOffSale = scope:Value(false)


	if props.itemDetails.IsOffSale and props.itemDetails.IsOffSale == true or props.itemDetails.IsPurchasable == false then
		priceVal = "Off-Sale"
		isOffSale:set(true)
	elseif props.itemDetails.UnitsAvailableForConsumption and props.itemDetails.UnitsAvailableForConsumption <= 0 then
		priceVal = tostring(props.itemDetails.LowestPrice or 0)
	else
		priceVal = tostring(props.itemDetails.Price)
	end

	local buttonsVisible = scope:Computed(function(use)
		return use(isActivated) or use(isHovering)
	end)

	local function activate(): ()
		isActivated:set(true)
	end

	local function deactivate(): ()
		isActivated:set(false)
	end

	local onTryOnCallback = function()
		deactivate()
		if props.onTryCb then
			props.onTryCb()
		end

		if props.pushLoad then
			props.pushLoad()
		end

		ClientCustomisationService.AddItem(props.itemDetails.Id, props.itemDetails.AssetType or props.itemDetails.BundleType or "", props.itemDetails.ItemType)

		if props.popLoad then
			props.popLoad()
		end
	end

	local function toggleActivationCallback(): ()
		if peek(isActivated) then
			return
		else
			onTryOnCallback()
		end

		activate()
		task.wait(CONFIG.ACTIVATION_DURATION)
		deactivate()
	end
	
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
				Interactable = true,
				
				[OnEvent "MouseEnter"] = function()
					isHovering:set(true)
				end,
				
				[OnEvent "MouseLeave"] = function()
					isHovering:set(false)
				end,

				[OnEvent "MouseButton1Click"] = function()
					toggleActivationCallback()
				end,

				[OnEvent "TouchTap"] = function(touchPositions)
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
						Active = false,
					},
					
					scope:New "Frame"{
						Name = "ButtonsFrame",
						ZIndex = 2,
						Visible = buttonsVisible,
						Active = true,
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
								layoutOrder = 1,
								onTryonCallback = onTryOnCallback,
								text = "EQUIP"
							}),  

							BuyButton(scope, {
								assetId = props.itemDetails.Id,
								assetType = props.itemDetails.AssetType or nil,
								bundleType = props.itemDetails.BundleType or nil,
								layoutOrder = 2,  
								isOffSale = isOffSale,
								text = "PURCHASE",
								onPurchaseCallback = function()
									deactivate()
									if props.onPurchaseCb then
										props.onPurchaseCb()
									end
								end,
								pushLoad = props.pushLoad,
								popLoad = props.popLoad
							})
						}
					}
				}
			},
			
			-- PriceLabel
			PriceLabel(scope, {
				layoutOrder = 2,
				text = priceVal,
				visible = true,
			}),
		}
	}
	
	return fusionItemTile
end

return FusionItemTile
