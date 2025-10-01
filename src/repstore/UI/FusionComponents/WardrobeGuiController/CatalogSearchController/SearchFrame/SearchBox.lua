--!strict
-- SearchBox.lua

-- Services
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AvatarEditorService = game:GetService("AvatarEditorService")

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
	}
): TextBox

	local searchText = scope:Value("")
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

	local textColorSpring = scope:Spring(
		scope:Computed(function(use)
			if use(isFocused) then
				return UI_CONSTANTS.COLOUR_BLACK
			elseif use(isHovering) then
				return UI_CONSTANTS.COLOUR_BLACK:Lerp(UI_CONSTANTS.COLOUR_WHITE, 0.50)
			else
				return UI_CONSTANTS.COLOUR_WHITE
			end
		end),
		20,
		1
	)

	-- Display text logic
	local displayText = scope:Computed(function(use)
		local currentText = use(searchText)
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
		TextColor3 = textColorSpring,
		FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Bold, Enum.FontStyle.Normal),

		[Out "Text"] = searchText,

		[OnEvent "Focused"] = function()
			isFocused:set(true)
			-- Clear placeholder text when focused
			searchText:set("")
		end,

		[OnEvent "FocusLost"] = function(enterPressed: boolean)
			isFocused:set(false)

			if enterPressed and props.onSearch then
				local keyword = peek(searchText)
				if keyword ~= "" then
					props.onSearch(keyword)
				end
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
			}
		}
	} :: TextBox

	return searchBox
end

return SearchBox