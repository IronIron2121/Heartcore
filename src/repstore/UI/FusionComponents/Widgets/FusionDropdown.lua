--!strict
-- FusionDropdown.lua

-- Services
local Players 			= game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility 			= ReplicatedStorage:WaitForChild("Utility")

-- Modules
local Fusion 			= require(Utility:WaitForChild("Fusion"))
local UI_CONSTANTS 		= require(Utility:WaitForChild("UI_CONSTANTS"))

-- Fusion
local OnEvent 			= Fusion.OnEvent
local Children 			= Fusion.Children
local peek 				= Fusion.peek
local Out 				= Fusion.Out
type UsedAs<T> 			= Fusion.UsedAs<T>

-- Player reference
local player 			= Players.LocalPlayer :: Player
local playerGui 		= player.PlayerGui

-- Helper function to create dropdown display
local function createDropdownDisplay(
	scope: Fusion.Scope,
	options: {any},
	position: UsedAs<UDim2>,
	onOptionSelected: (any) -> ()
): ScreenGui
	local screenGui = scope:New "ScreenGui" {
		Name = "DropdownDisplay",
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,

		[Children] = {
			-- Input sink (click outside to close)
			scope:New "TextButton" {
				Name = "InputSink",
				Size = UDim2.fromScale(1, 2),
				BackgroundTransparency = 1,
				Text = "",
				ZIndex = 1,

				[OnEvent "Activated"] = function()
					onOptionSelected(nil) -- Signal to close without selection
				end,
			},

			-- Dropdown options frame
			scope:New "Frame" {
				Name = "OptionsFrame",
				AnchorPoint = Vector2.new(0, 0),
				Position = UDim2.fromScale(0.77, 0.16),
				Size = scope:Computed(function()
					local optionHeight = 35
					local totalHeight = #options * optionHeight
					return UDim2.fromOffset(250, totalHeight)
				end),
				BackgroundColor3 = UI_CONSTANTS.COLOUR_WHITE,
				BackgroundTransparency = 0,
				ZIndex = 2,

				[Children] = {
					-- scope:New "UICorner" {
					-- 	CornerRadius = UDim.new(0.1, 0)
					-- },

					scope:New "UIStroke" {
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						Color = UI_CONSTANTS.TASTEMAKER_PURPLE,
						Thickness = 2,
					},

					scope:New "UICorner" {
						CornerRadius = UDim.new(0.05,0),
					},

					scope:New "UIPadding" {
						PaddingTop = UDim.new(0.02,0),
						PaddingBottom = UDim.new(0.02,0),
						PaddingLeft = UDim.new(0.02,0),
						PaddingRight = UDim.new(0.02,0),			
					},

					scope:New "UIListLayout" {
						FillDirection = Enum.FillDirection.Vertical,
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0.02,0),
					},

					-- Create option buttons
					table.unpack(
						(function()
							local optionButtons = {}
							
							for i, option in ipairs(options) do

								local isHovering = scope:Value(false)

								local textSizeSpring = scope:Spring(
									scope:Computed(function(use)
										if use(isHovering) then
											return 1.2 -- 20% larger when hovering
										else
											return 1 -- normal size
										end
									end),
									20,
									1
								)

								table.insert(optionButtons, scope:New "TextButton" {
									Name = "Option" .. i,
									Size = UDim2.new(1, 0, 0, 30),
									Text = tostring(option),
									BackgroundColor3 = Color3.new(1, 1, 1),
									BackgroundTransparency = 1,
									TextColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
									TextScaled = true,
									FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Regular),
									TextXAlignment = Enum.TextXAlignment.Left,
									LayoutOrder = i,

									[OnEvent "Activated"] = function()
										-- Just call the callback, don't destroy from within
										onOptionSelected(option)
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
											PaddingBottom = UDim.new(0.1,0)
										},

										scope:New "UIScale" {
											Scale = textSizeSpring -- this will still scale the whole label
										}
									}
								})
							end
							return optionButtons
						end)()
					)
				}
			}
		}
	} :: ScreenGui

	return screenGui
end

function FusionDropdown<T>(
	scope: Fusion.Scope,
	props: {
		name: UsedAs<string>?,
		options: {T},
		selectedValue: UsedAs<Enum.CatalogSortType>,
		size: UsedAs<UDim2>?,
		position: UsedAs<UDim2>?,
		layoutOrder: UsedAs<number>?,
		anchorPoint: UsedAs<Vector2>?,
		placeholder: UsedAs<string>?,
		searchCallback: () -> (),
		isOpen: UsedAs<boolean>?
	}
): Frame
	local isHovering = scope:Value(false)
	local isOpen = scope:Value(initialValue)
	local currentDisplay = scope:Value(nil)

	-- Track absolute position for dropdown positioning
	local absolutePosition = scope:Value(Vector2.new())
	local absoluteSize = scope:Value(Vector2.new())

	-- Calculate dropdown position
	local dropdownPosition = scope:Computed(function(use)
		local pos = use(absolutePosition)
		local size = use(absoluteSize)
		local targetX = pos.X + (size.X / 2)
		local targetY = pos.Y + size.Y
		return UDim2.fromOffset(targetX, targetY)
	end)

	-- Visual feedback
	-- local backgroundColorSpring = scope:Spring(
	-- 	scope:Computed(function(use)
	-- 		if use(isHovering) then
	-- 			return UI_CONSTANTS.TASTEMAKER_PURPLE:Lerp(UI_CONSTANTS.COLOUR_WHITE, 0.20)
	-- 		else
	-- 			return UI_CONSTANTS.TASTEMAKER_PURPLE
	-- 		end
	-- 	end),
	-- 	20,
	-- 	1
	-- )

	local backgroundTransparencySpring = scope:Spring(
		scope:Computed(function(use)
			if use(isHovering) then
				return 0
			else
				return UI_CONSTANTS.TRANSPARENCY_TRANSLUCENT
			end
		end)
	)

	-- Current selection text
	local displayText = scope:Computed(function(use)
		local selected = use(props.selectedValue)
		if selected then
			return tostring(selected)
		else
			return use(props.placeholder) or "Select..."
		end
	end)



	-- Toggle dropdown function
	local function toggleDropdown()
		isOpen:set(not peek(isOpen))
	end

	local dropdownFrame = scope:New "Frame" {
		Name = props.name or "FusionDropdown",
		Size = props.size or UDim2.fromScale(0.2, 1),
		Position = props.position or UDim2.fromScale(0, 0),
		AnchorPoint = props.anchorPoint or Vector2.new(0, 0),
		LayoutOrder = props.layoutOrder or 1,
		BackgroundColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
		BackgroundTransparency = backgroundTransparencySpring,

		[Out "AbsolutePosition"] = absolutePosition,
		[Out "AbsoluteSize"] = absoluteSize,

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
				Thickness = 2,
			},

			scope:New "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 5),
			},

			scope:New "UIPadding" {
				PaddingTop = UDim.new(0.2,0),
				PaddingBottom = UDim.new(0.2,0),
				PaddingLeft = UDim.new(0.05,0),
				PaddingRight = UDim.new(0.05,0),
			},

			scope:New "TextLabel" {
				Name = "SortBy",
				Size = UDim2.fromScale(0.15,1),
				Text = "▼",
				BackgroundTransparency = 1,
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 0,
				FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Medium, Enum.FontStyle.Normal),

			},

			-- Main selection button
			scope:New "TextButton" {
				Name = "SelectionButton",
				Size = UDim2.fromScale(0.8, 1),
				Text = displayText,
				BackgroundTransparency = 1,
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 1,
				FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Medium, Enum.FontStyle.Normal),

				[OnEvent "Activated"] = toggleDropdown,

			},
		}
	} :: Frame

	-- Watch for isOpen changes and manage display
	scope:Observer(isOpen):onChange(function()
		local display = peek(currentDisplay)
		local open = peek(isOpen)

		if open and not display then
			-- Create new display
			local newDisplay = createDropdownDisplay(
				scope,
				props.options,
				dropdownPosition,
				function(selectedOption)
					if selectedOption then
						props.selectedValue:set(selectedOption)
					end
					isOpen:set(false)
					props.searchCallback()
				end
			)
			newDisplay.Parent = playerGui
			currentDisplay:set(newDisplay)
		elseif not open and display then
			-- Destroy existing display
			display:Destroy()
			currentDisplay:set(nil)
		end
	end)

	return dropdownFrame
end

return FusionDropdown