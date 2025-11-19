--!strict
-- FusionDropdown.lua

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))

-- Fusion
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local peek = Fusion.peek
local Out = Fusion.Out
type UsedAs<T> = Fusion.UsedAs<T>

-- Player reference
local player = Players.LocalPlayer :: Player
local playerGui = player.PlayerGui

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

		[Children] = {
			-- Input sink (click outside to close)
			scope:New "TextButton" {
				Name = "InputSink",
				Size = UDim2.fromScale(1, 1),
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
				AnchorPoint = Vector2.new(0.5, 0),
				Position = position,
				Size = scope:Computed(function()
					local optionHeight = 30
					local totalHeight = #options * optionHeight
					return UDim2.fromOffset(200, totalHeight)
				end),
				BackgroundColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
				BackgroundTransparency = 0.1,
				ZIndex = 2,

				[Children] = {
					scope:New "UICorner" {
						CornerRadius = UDim.new(0.1, 0)
					},

					scope:New "UIStroke" {
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						Color = Color3.new(1, 1, 1),
						Thickness = 1,
					},

					scope:New "UIListLayout" {
						FillDirection = Enum.FillDirection.Vertical,
						SortOrder = Enum.SortOrder.LayoutOrder,
					},

					-- Create option buttons
					table.unpack(
						(function()
							local optionButtons = {}
							for i, option in ipairs(options) do
								table.insert(optionButtons, scope:New "TextButton" {
									Name = "Option" .. i,
									Size = UDim2.new(1, 0, 0, 30),
									Text = tostring(option),
									BackgroundColor3 = Color3.new(0.2, 0.2, 0.2),
									BackgroundTransparency = 0.3,
									TextColor3 = Color3.new(1, 1, 1),
									TextScaled = true,
									LayoutOrder = i,

									[OnEvent "Activated"] = function()
										-- Just call the callback, don't destroy from within
										onOptionSelected(option)
									end,

									[Children] = {
										scope:New "UICorner" {
											CornerRadius = UDim.new(0.05, 0)
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
		searchCallback: () -> ()
	}
): Frame
	local isHovering = scope:Value(false)
	local isOpen = scope:Value(false)
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
	local backgroundColorSpring = scope:Spring(
		scope:Computed(function(use)
			if use(isHovering) then
				return UI_CONSTANTS.TASTEMAKER_PURPLE:Lerp(UI_CONSTANTS.COLOUR_BLACK, 0.20)
			else
				return UI_CONSTANTS.TASTEMAKER_PURPLE
			end
		end),
		20,
		1
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

	-- Arrow direction
	local arrowText = scope:Computed(function(use)
		return use(isOpen) and "?" or "?"
	end)

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
		BackgroundColor3 = backgroundColorSpring,
		BackgroundTransparency = UI_CONSTANTS.TRANSPARENCY_TRANSLUCENT,

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
				CornerRadius = UDim.new(0.1, 0)
			},

			scope:New "UIStroke" {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = Color3.new(1, 1, 1),
				Thickness = 1,
			},

			scope:New "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 5),
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

			-- Arrow button
			scope:New "TextButton" {
				Name = "ArrowButton",
				Size = UDim2.fromScale(0.15, 1),
				Text = arrowText,
				BackgroundTransparency = 1,
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				LayoutOrder = 2,

				[OnEvent "Activated"] = toggleDropdown,
			}
		}
	} :: Frame

	return dropdownFrame
end

return FusionDropdown