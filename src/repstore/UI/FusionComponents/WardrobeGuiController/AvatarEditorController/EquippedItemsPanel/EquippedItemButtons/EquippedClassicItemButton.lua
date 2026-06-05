--!strict
-- EquippedClassicItemButton.lua

-- Services
local MarketplaceService 	= game:GetService("MarketplaceService")
local ReplicatedStorage 	= game:GetService("ReplicatedStorage")
local Players 				= game:GetService("Players")

-- Folders
local DataTables 	= ReplicatedStorage:WaitForChild("DataTables")
local Utility 		= ReplicatedStorage:WaitForChild("Utility")

-- Modules
local UI_CONSTANTS 	= require(Utility:WaitForChild("UI_CONSTANTS"))
local ImageUris 	= require(DataTables:WaitForChild("ImageUris"))
local Fusion 		= require(Utility:WaitForChild("Fusion"))
local Constants 	= require(ReplicatedStorage.Constants)
local GameStateValues = require(ReplicatedStorage.Libraries.GameStateValues)
local callWithRetry = require(ReplicatedStorage.Utility.callWithRetry)

-- Fusion
type UsedAs<T>	= Fusion.UsedAs<T>
local Children 	= Fusion.Children
local OnEvent 	= Fusion.OnEvent
local peek 		= Fusion.peek

-- Constants
local BUY_BUTTON_DISPLAY_TIME 	= 5
local BG_FADE_SPEED 			= 20
local COLOUR_ORANGE 			= Color3.new(0.901961, 0.380392, 0.078431)
local COLOUR_GREY 				= Color3.new(1, 1, 1)

--

function EquippedClassicItemButton(
	scope: Fusion.Scope,
	props: {
		buttonSize: UsedAs<UDim2>,
		itemId: number,
		itemType: string,
		visible: UsedAs<boolean>,
		buyCb: () -> ()?,
		removeCb: () -> ()?,
	}
): Frame
	if not props.itemId or props.itemId == 0 then
		return scope:New "Frame"{
			Name = "DummyFrame",
			Visible = false
		} :: Frame
	end

	-- This was used when default clothing was not removeable but is now vestigial
	-- local isDefaultItem = scope:Value(table.find(Constants.DEFAULT_CLASSIC_CLOTHING_IDS_TABLE, props.itemId))

	-- Get product info
	local success, productInfo = callWithRetry(function()
		return MarketplaceService:GetProductInfo(props.itemId, Enum.InfoType.Asset)
	end)

	if not success then
		return scope:New "Frame" {

		} :: Frame
	end

	-- State management
	local Toggled = scope:Value(false)
	local isHovering = scope:Value(false)
	local isHeldDown = scope:Value(false)
	local isToggled = scope:Value(false)

	local COLOUR_BG_TOGGLED = COLOUR_ORANGE
	local COLOUR_BG_NOT_TOGGLED = COLOUR_GREY

	local isClicked = scope:Computed(function(use, _)
		return use(Toggled) == true
	end)

	-- Visual feedback
	local imageColor = scope:Spring(
		scope:Computed(function(use)
			return use(isHovering) 
				and UI_CONSTANTS.COLOUR_WHITE:Lerp(UI_CONSTANTS.TASTEMAKER_PURPLE, 0.5)
				or UI_CONSTANTS.COLOUR_WHITE
		end),
		20,
		1
	)

	local backgroundTransparencySpring = scope:Spring(
		scope:Computed(function(use)
			if use(props.visible) then
				return 0
			else
				return 1
			end
		end),
		10,
		1
	)	

	-- Buy button toggle logic
	local function toggleBuyButton()
		if not peek(GameStateValues.isIntermission) then
			return
		end
		task.spawn(function()
			isToggled:set(true)
			task.wait(BUY_BUTTON_DISPLAY_TIME)
			isToggled:set(false)
		end)
	end

	return scope:New "Frame" {
		Name = productInfo.AssetId,
		Size = props.buttonSize,
		Visible = props.visible,
		BackgroundTransparency = backgroundTransparencySpring,
		BackgroundColor3 = imageColor,

		[Children] = {
			scope:New "UICorner" {
				CornerRadius = UDim.new(0.2, 0)
			},

			scope:New "UIAspectRatioConstraint" {
				AspectRatio = 1,
				AspectType = Enum.AspectType.ScaleWithParentSize,
				DominantAxis = Enum.DominantAxis.Width
			},

			-- Main interaction button
			scope:New "ImageButton" {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ImageTransparency = backgroundTransparencySpring,
				Active = true,

				[OnEvent "Activated"] = function()
					if not peek(isToggled) then
						toggleBuyButton()
					end
				end,

				[OnEvent "MouseEnter"] = function()
					isHovering:set(true)
				end,

				[OnEvent "MouseLeave"] = function()
					isHovering:set(false)
				end,
			},

			-- Item thumbnail
			scope:New "ImageLabel" {
				Name = "ItemThumbnail",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ImageTransparency = backgroundTransparencySpring,
				ImageColor3 = imageColor,
				Image = "rbxthumb://type=Asset&id=" .. props.itemId .. "&w=420&h=420",
				Active = false
			},

			-- Buy button overlay
			scope:New "TextButton" {
				Name = "BuyButton",
				Visible = isToggled,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.8, 0.5),
				Text = "BUY",
				TextColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
				FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Bold),
				TextStrokeTransparency = 1,
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = backgroundTransparencySpring,
				BorderSizePixel = 0,

				[OnEvent "Activated"] = function()
					MarketplaceService:PromptPurchase(Players.LocalPlayer, props.itemId)
				end,

				[Children] = {
					scope:New "UICorner" {
						CornerRadius = UDim.new(0.5, 0)
					},

					scope:New "UIStroke" {
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						Color = UI_CONSTANTS.TASTEMAKER_PURPLE,
						Thickness = 2,
					}
				}
			},

			-- Remove button TODO: Create an "image button" component so we can do reactive stuff
			scope:New "ImageButton" {
				Name = "RemoveButton",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.fromScale(0.5, 0.5),
				ZIndex = 3,
				BackgroundTransparency = 1,
				ImageTransparency = backgroundTransparencySpring,
				Image = ImageUris.CloseButton,
				Active = true,
				Visible = true,


				[OnEvent "Activated"] = function()
					if props.removeCb ~= nil then
						props.removeCb()
					else
						warn("No CB")
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
				end,

				ImageColor3 = scope:Spring(
					scope:Computed(function(use)
						local baseColor = use(isClicked) and COLOUR_BG_TOGGLED or COLOUR_BG_NOT_TOGGLED
						
						if use(isHeldDown) then
							return baseColor:Lerp(COLOUR_ORANGE, 0.8)
						elseif use(isHovering) then
							return baseColor:Lerp(COLOUR_ORANGE, 0.25)
						else 
							return baseColor
						end
					end),
					BG_FADE_SPEED
				), 
			}
		}
	} :: Frame 
end

return EquippedClassicItemButton