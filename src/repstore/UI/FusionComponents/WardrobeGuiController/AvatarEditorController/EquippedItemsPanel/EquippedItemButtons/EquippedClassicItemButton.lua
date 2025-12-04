--!strict
-- EquippedItemButton.lua

-- Services
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local DataTables = ReplicatedStorage:WaitForChild("DataTables")

-- Remotes
local PlayerRemovedClassicItem = Remotes:WaitForChild("PlayerRemovedClassicItem")
 
-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))
local ImageUris = require(DataTables:WaitForChild("ImageUris"))

-- Fusion
type UsedAs<T> = Fusion.UsedAs<T>
local peek = Fusion.peek
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children

-- Constants
local BUY_BUTTON_DISPLAY_TIME = 5

function EquippedClassicItemButton(
	scope: Fusion.Scope,
	props: {
		buttonSize: UsedAs<UDim2>,
		itemId: number,
		itemType: string,
		visible: UsedAs<boolean>
	}
): Frame
	if not props.itemId or props.itemId == 0 then
		return scope:New "Frame"{
			Name = "DummyFrame",
			Visible = false
		} :: Frame
	end

	-- Get product info
	local productInfo = MarketplaceService:GetProductInfo(props.itemId, Enum.InfoType.Asset)

	-- State management
	local isHovering = scope:Value(false)
	local isToggled = scope:Value(false)

	-- Visual feedback
	local imageColor = scope:Spring(
		scope:Computed(function(use)
			return use(isHovering) 
				and UI_CONSTANTS.COLOUR_WHITE:Lerp(UI_CONSTANTS.COLOUR_BLACK, 0.5)
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
		isToggled:set(true)
		task.spawn(function()
			task.wait(BUY_BUTTON_DISPLAY_TIME)
			isToggled:set(false)
		end)
	end

	return scope:New "Frame" {
		Name = productInfo.Name,
		Size = props.buttonSize,
		Visible = props.visible,
		BackgroundTransparency = backgroundTransparencySpring,

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
				FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Bold, Enum.FontStyle.Normal),
				TextStrokeTransparency = 0,
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = backgroundTransparencySpring,
				BorderSizePixel = 0,

				[OnEvent "Activated"] = function()
					MarketplaceService:PromptPurchase(Players.LocalPlayer, props.itemId)
				end,

				[Children] = {
					scope:New "UICorner" {
						CornerRadius = UDim.new(0.2, 0)
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
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.fromScale(0.5, 0.5),
				ZIndex = 3,
				BackgroundTransparency = 1,
				ImageTransparency = backgroundTransparencySpring,
				Image = ImageUris.CloseButton,
				Active = true,

				[OnEvent "Activated"] = function()
					-- TODO: Only set invisible if successfully removed...?
					PlayerRemovedClassicItem:FireServer(props.itemId, props.itemType)
					props.visible:set(false)
				end,
			}
		}
	} :: Frame 
end

return EquippedClassicItemButton