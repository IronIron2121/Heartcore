--!strict
-- OutfitVoteTile.lua

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local DataTables = ReplicatedStorage:WaitForChild("DataTables")

-- Modules
local Constants = require(ReplicatedStorage.Constants)
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))
local Fusion = require(Utility:WaitForChild("Fusion"))

-- Constants
local HOVER_COLOR = Color3.fromRGB(89, 247, 128)
local HOLD_COLOR = Color3.new(0.117647, 0.023529, 0.941176)

-- Fusion
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>
local peek = Fusion.peek

function OutfitVoteTile(
	scope: Fusion.Scope,
	props: {
		name: UsedAs<string>?,
		visible: UsedAs<boolean>?,
		views: UsedAs<number>?,
		votes: UsedAs<number>?,
		IsSelected: UsedAs<boolean>?,
		userId: UsedAs<number>?,
		size: UsedAs<UDim2>?,
		position: UsedAs<UDim2>?, 
		layoutOrder: UsedAs<number>?,  
		anchorPoint: UsedAs<Vector2>?,
		strokeColor: UsedAs<Color3>?,
		strokeThickness: UsedAs<number>?,
		OnSelected: () -> (),
	}
): Frame
	local strokeColor = Color3.fromRGB(255, 255, 255) or UI_CONSTANTS.TASTEMAKER_PURPLE

	local isHovering = scope:Value(false)
	local isHeld = scope:Value(false)
	
	local strokeColorSpring = scope:Spring(
		scope:Computed(function(use)
			if use(isHeld) then
				return strokeColor:Lerp(HOLD_COLOR, 1)
			elseif use(props.IsSelected) and use(isHovering) then
				return UI_CONSTANTS.TASTEMAKER_PURPLE:Lerp(HOVER_COLOR, 0.5)
			elseif use(props.IsSelected) then
				return strokeColor:Lerp(UI_CONSTANTS.TASTEMAKER_PURPLE, 1)
			elseif use(isHovering) then
				return strokeColor:Lerp(HOVER_COLOR, 0.7)
			else
				return strokeColor
			end
		end),
		20,
		1	
	)

	-- Create viewport camera
	local outfitVoteTile = scope:New "Frame" {
		Name = props.name,
		Visible = props.visible or true,
		Size = props.size or UDim2.fromScale(0.25, 0.3),
		Position = props.position,
		AnchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5),
		LayoutOrder = props.layoutOrder,
		BackgroundColor3 = Color3.fromRGB(218, 214, 231),
		BackgroundTransparency = 0.1,

		[Children] = {
			scope:New "UIListLayout" {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Top,
				Padding = UDim.new(0, 5)
			},

			scope:New "UICorner" {
				CornerRadius = UDim.new(0.05, 0)
			},

			scope:New "UIStroke" {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = strokeColorSpring,
				Thickness = 5,
			},
			-- Outfit thumbnail viewport
			scope:New "Frame" {
				Name = "EmptyVoteFrame",
				Size = UDim2.fromScale(1, 1),
				LayoutOrder = 1,
				BackgroundColor3 = Color3.fromRGB(218, 214, 231),
				BackgroundTransparency = 0,
				BorderSizePixel = 5,

				[Children] = {
					scope:New "UICorner" {
						CornerRadius = UDim.new(0.05, 0)
					},

                    scope:New "ImageButton" {
                        Size = UDim2.fromScale(1, 1),
						BackgroundColor3 = Color3.new(UI_CONSTANTS.COLOUR_GREY),
                        ImageTransparency = 1,
                        BackgroundTransparency = 0.7,


                        [OnEvent "Activated"] = function()
							print("Nothing to do.")
                        end,

						[OnEvent "MouseButton1Down"] = function()
							isHeld:set(true)
						end,
						
						[OnEvent "MouseButton1Up"] = function()
							isHeld:set(false)
						end,
						
						[OnEvent "MouseEnter"] = function()
							isHovering:set(true)
						end,
						
						[OnEvent "MouseLeave"] = function()
							isHovering:set(false)
						end,

                    },

					scope:New "TextLabel" {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromScale(0.5, 0.5),
						Text = "Out of outfits to load! Please wait for next cache refresh in ... [Time Goes Here]",
						TextScaled = true
					}
				},

			},
		}
	} :: Frame

	return outfitVoteTile
end

return OutfitVoteTile