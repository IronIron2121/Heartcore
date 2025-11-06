--!strict
-- SearchBox.lua

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
local Out = Fusion.Out
type UsedAs<T> = Fusion.UsedAs<T>
local peek = Fusion.peek

-- Constants
local INITIAL_SEARCH_TEXT = "Search..."

function SearchBox(
	scope: Fusion.Scope,
	props: {
		name: UsedAs<string>?,
		size: UsedAs<UDim2>?,
		position: UsedAs<UDim2>?,
		anchorPoint: UsedAs<Vector2>?,
		layoutOrder: UsedAs<number>?,
		placeholder: UsedAs<string>?,
		onSearch: (keyword: string) -> ()?,
		searchResults: Fusion.UsedAs<{}>?,
		searchText: UsedAs<string>,
		textScaled: UsedAs<boolean>?,
		searchCallback: () -> ()
	}
): TextBox
	local isFocused = scope:Value(false)
	local isHovering = scope:Value(false)

	-- Dynamic styling based on interaction state
	local backgroundTransparencySpring = scope:Spring(
		scope:Computed(function(use)
			if use(isHovering) or use(isFocused) then
				return 0
			else
				return UI_CONSTANTS.TRANSPARENCY_TRANSLUCENT
			end
		end),
		20,
		1
	)

	-- Display text logic
	local displayText = scope:Computed(function(use)
		local currentText = use(props.searchText)
		local focused = use(isFocused)

		if focused then
			return currentText
		else
			if currentText == "" then
				return use(props.placeholder) or "Search..."
			else
				return currentText
			end
		end
	end)

	local searchBox = scope:New "TextBox" {
		Name = props.name or "SearchBox",
		Size = props.size or UDim2.fromScale(0.4, 0.5),
		Position = props.position or UDim2.fromScale(0.5, 0.5),
		AnchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5),
		LayoutOrder = props.layoutOrder or 1,
		BackgroundColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
		BackgroundTransparency = backgroundTransparencySpring,
		Text = displayText,
		TextColor3 = UI_CONSTANTS.COLOUR_WHITE,
		TextScaled = props.textScaled or true,
		FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Bold, Enum.FontStyle.Normal),

		[Out "Text"] = props.searchText,

		[OnEvent "Focused"] = function()
			isFocused:set(true)
			-- Clear placeholder text when focused
			if peek(props.searchText) == peek(props.placeholder) or peek(props.searchText) == peek(INITIAL_SEARCH_TEXT) then
				props.searchText:set("")
			end
		end,

		[OnEvent "FocusLost"] = function(enterPressed: boolean)
			isFocused:set(false)

			if enterPressed and props.searchCallback then
				props.searchCallback()
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
				Color = Color3.fromRGB(255, 255, 255),
				Thickness = 2,
			},

			scope:New "UIPadding"{
				PaddingTop = UDim.new(0.1,0),
				PaddingBottom = UDim.new(0.1,0),
				PaddingRight = UDim.new(0.1,0),
				PaddingLeft = UDim.new(0.1,0),
			}
		}
	} :: TextBox

	return searchBox
end

return SearchBox