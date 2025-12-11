--!strict
-- ExpandingOptionsButton.lua

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))

-- Fusion
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek
type UsedAs<T> = Fusion.UsedAs<T>

function ExpandingOptionsButton(
	scope: Fusion.Scope,
	props: {
		onActivated: (() -> ())?,
		text: UsedAs<string>,
		size: UsedAs<UDim2>?,
		layoutOrder: UsedAs<number>?,
		isSelected: UsedAs<boolean>?,
		children: {any}?
	}
): Frame
	local isHovering = scope:Value(false)
	local isExpanded = scope:Value(false)  -- Track expansion state

	-- Visual feedback based on selection and hover state
	local backgroundColorSpring = scope:Spring(scope:Computed(function(use)
		local selected = use(props.isSelected) or false
		local hovering = use(isHovering)

		if selected then
			return UI_CONSTANTS.COLOUR_WHITE
		elseif hovering then
			return UI_CONSTANTS.TASTEMAKER_PURPLE:Lerp(UI_CONSTANTS.COLOUR_BLACK, 0.25)
		else
			return UI_CONSTANTS.TASTEMAKER_PURPLE
		end
	end),
		20,
		1
	)
	
	local textColorSpring = scope:Spring(
		scope:Computed(function(use)
			if use(props.isSelected) then
				return UI_CONSTANTS.TASTEMAKER_PURPLE
			else
				return UI_CONSTANTS.COLOUR_WHITE
			end
		end)
	)
	
	local backgroundTransparencySpring = scope:Spring(
		scope:Computed(function(use)
			if use(props.isSelected) then
				return 0
			else
				return UI_CONSTANTS.TRANSPARENCY_TRANSLUCENT
			end
		end)
	)

	local arrowRotation = scope:Spring(
		scope:Computed(function(use)
			return use(isExpanded) and 90 or 0 
		end),
		20,
		1
	)

	local expandingOptionsButton = scope:New "Frame" {
		Name = "ExpandingOptionsButton",
		Size = UDim2.fromScale(0.9, 0),  -- Width in scale, height auto
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = props.layoutOrder or 1,
		
		[Children] = {
			scope:New "UIListLayout" {
				Padding = UDim.new(0, 5),
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Top,
			},

			-- Header button
			scope:New "TextButton" {
				Name = "HeaderButton",
				Size = props.size or UDim2.new(1, 0, 0, 45),
				LayoutOrder = 1,
				Text = "",  -- Custom layout instead
				BackgroundColor3 = backgroundColorSpring,
				BackgroundTransparency = backgroundTransparencySpring,
				BorderSizePixel = 0,
				AutoButtonColor = false,

				[OnEvent "Activated"] = function()
					isExpanded:set(not peek(isExpanded))
					if props.onActivated then
						props.onActivated()
					end
				end, 

				[OnEvent "MouseEnter"] = function()
					isHovering:set(true)
				end,

				[OnEvent "MouseLeave"] = function()
					isHovering:set(false)
				end,

				[Children] = {
					scope:New "UICorner" {
						CornerRadius = UDim.new(0.5, 0)
					},

					scope:New "UIStroke" {
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						Color = Color3.new(1, 1, 1),
						Thickness = 1,
					},

					scope:New "UIPadding" {
						PaddingTop = UDim.new(0.1,0),
						PaddingBottom = UDim.new(0.1,0),
						PaddingLeft = UDim.new(0.1,0),
						PaddingRight = UDim.new(0.1,0)
					},

					-- Content container for text + arrow
					scope:New "Frame" {
						Name = "ContentContainer",
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,

						[Children] = {
							scope:New "UIListLayout" {
								FillDirection = Enum.FillDirection.Horizontal,
								VerticalAlignment = Enum.VerticalAlignment.Center,
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								Padding = UDim.new(0, 8),
								SortOrder = Enum.SortOrder.LayoutOrder
							},

							-- Arrow indicator
							scope:New "TextLabel" {
								Name = "Arrow",
								Size = UDim2.new(0, 16, 0, 16),
								BackgroundTransparency = 1,
								Text = "▶",
								TextSize = 14,
								TextColor3 = textColorSpring,
								Font = Enum.Font.GothamBold,
								LayoutOrder = 1,
								Rotation = arrowRotation  -- Animated rotation
							},

							-- Category text
							scope:New "TextLabel" {
								Name = "CategoryText",
								Size = UDim2.new(1, -24, 1, 0),
								BackgroundTransparency = 1,
								Text = props.text,
								TextColor3 = textColorSpring,
								TextScaled = true,
								FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Regular),
								LayoutOrder = 2
							}
						}
					}
				}
			},

			-- Dropdown content (children)
			scope:New "Frame" {
				Name = "DropdownContent",
				Size = UDim2.fromScale(0.95, 0), 
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Visible = isExpanded, 
				LayoutOrder = 2,

				[Children] = {
					scope:New "UIListLayout" {
						Padding = UDim.new(0, 5),
						FillDirection = Enum.FillDirection.Vertical,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder,
						VerticalAlignment = Enum.VerticalAlignment.Top,
					},

					-- Children passed in from props
					table.unpack(props.children or {})
				}
			}
		}
	} :: Frame

	return expandingOptionsButton
end

return ExpandingOptionsButton