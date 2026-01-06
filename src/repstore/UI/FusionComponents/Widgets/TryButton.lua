--!strict
-- BuyButton.lua

-- Services
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))

-- Remotes
local PlayerEquippedItem = Remotes:WaitForChild("PlayerEquippedItem")

-- Fusion
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

-- TODO: Maybe this should have a parent class which try, remove and buy item can all inherit from
function TryButton(
	scope: Fusion.Scope,
	props: {
		assetId: number,
		assetOrBundleType: string?,
		itemType: string,
		layoutOrder: UsedAs<number>?,
		visible: UsedAs<boolean>?,
		size: UsedAs<UDim2>?,
		position: UsedAs<UDim2>?,
		anchorPoint: UsedAs<Vector2>?,
		text: UsedAs<string>?,
		onTryonCallback: (() -> ())?,
	}
): TextButton
	local isHovering = scope:Value(false)
	local isHeldDown = scope:Value(false)
	
	local backgroundColorSpring = scope:Spring(
		scope:Computed(function(use)
			if use(isHeldDown) then
				return UI_CONSTANTS.COLOUR_WHITE:Lerp(UI_CONSTANTS.COLOUR_BLACK, 0.55)
			elseif use(isHovering) then
				return UI_CONSTANTS.COLOUR_WHITE:Lerp(UI_CONSTANTS.COLOUR_BLACK, 0.20)
			else
				return UI_CONSTANTS.COLOUR_WHITE
			end
		end),
		20,
		1
	)


	local tryButton = scope:New "TextButton" {
		Name = "TryButton",
		Active = true,
		Visible = props.visible or true,
		AnchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5),
		Position = props.position or UDim2.fromScale(0.5, 0.5),
		Size = props.size or UDim2.fromScale(0.8, 0.5),
		Text = props.text or "TRY",
		TextColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
		BorderColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
		BorderSizePixel = 4,
		TextStrokeTransparency = 1,
		BackgroundColor3 = backgroundColorSpring,
		BackgroundTransparency = 0,
		LayoutOrder = props.layoutOrder or 1,
		TextScaled = true,
		TextWrapped = true,

		[OnEvent "Activated"] = function()
			--local productInfo = MarketplaceService:GetProductInfo(itemDetails.Id, infoType)
			PlayerEquippedItem:FireServer(props.assetId, props.assetOrBundleType, props.itemType)

			-- Call optional callback after purchase prompt
			if props.onTryonCallback then
				props.onTryonCallback()
			end
		end,
		 
		[OnEvent "MouseButton1Down"] = function()
			isHeldDown:set(true)
		end,
		
		[OnEvent "MouseButton1Up"] = function()
			isHeldDown:set(false)
		end,
		
		[OnEvent "MouseEnter"] = function()
			isHovering:set(true)
		end,
		
		[OnEvent "MouseLeave"] = function()
			isHovering:set(false)
			isHeldDown:set(false)
		end,

		[Children] = {
			scope:New "UICorner" {
				CornerRadius = UDim.new(0.4, 0)
			},

			scope:New "UIStroke" {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = UI_CONSTANTS.TASTEMAKER_PURPLE,
				Thickness = 2,
			}
		}
	} :: TextButton

	return tryButton
end

return TryButton