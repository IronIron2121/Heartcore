--!strict
-- ExpandingOptionsButton.lua

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))

-- Contstants
local COLOUR_SELECTED = UI_CONSTANTS.COLOUR_GREY
local DEFAULT_COLOUR = UI_CONSTANTS.TASTEMAKER_PURPLE
local HOVER_SCALE = 1.2 

-- Fusion
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek
type UsedAs<T> = Fusion.UsedAs<T>



--

function ExpandingOptionsButton(
	scope: Fusion.Scope,
	props: {
		onActivated: (() -> ())?,
		text: UsedAs<string>,
		size: UsedAs<UDim2>?,
		layoutOrder: UsedAs<number>?,
		isSelected: UsedAs<boolean>?,
		children: {any}?,
		textSize: UsedAs<number>?
	}
): Frame
	local playerIsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled
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
			local expanded = use(isExpanded)
			if expanded then
				return COLOUR_SELECTED
			else
				return DEFAULT_COLOUR
			end
		end)
	)

	local sizeSpring = scope:Spring(
		scope:Computed(function(use)
			local hovering = use(isHovering)
			local expanded = use(isExpanded)
			if hovering or expanded then
				return HOVER_SCALE
			else
				return 1
			end
		end),
		20, 
		1  
	)

	local expandingOptionsButton = scope:New "Frame" {
		Name = "ExpandingOptionsButton",
		Size = UI_CONSTANTS.CATEGORY_BUTTON_SIZE,  -- Width auto, height in scale
		AutomaticSize = Enum.AutomaticSize.X,
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
				Size = props.size or UDim2.new(1, 0, 0, 60),
				LayoutOrder = 1,
				Text = "",  -- Custom layout instead
				BackgroundColor3 = backgroundColorSpring,
				TextColor3 = textColorSpring,
				BackgroundTransparency = 1,
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
					scope:New "UIPadding" {
						PaddingTop = UDim.new(0.1,0),
						PaddingBottom = UDim.new(0.1,0),
						PaddingLeft = UDim.new(0.05,0),
						PaddingRight = UDim.new(0.05,0)
					},

					scope:New "UIScale" {
						Scale = sizeSpring
					},

					-- Content container for text + arrow
					scope:New "Frame" {
						Name = "ContentContainer",
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,

						[Children] = {
							-- Category text
							scope:New "TextLabel" {
								Name = "CategoryText",
								Size = UDim2.new(1, -24, 1, 0),
								BackgroundTransparency = 1,
								Text = props.text,
								TextColor3 = textColorSpring,
								TextScaled = playerIsMobile,
								TextWrapped = true,
								FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Regular),
								LayoutOrder = 2,
								TextSize = props.textSize or 20,
								TextXAlignment = Enum.TextXAlignment.Left,
							}
						}
					}
				}
			},

			-- Dropdown content (children)
			scope:New "Frame" {
				Name = "DropdownContent",
				Size = UDim2.fromScale(0.75, 0), 
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