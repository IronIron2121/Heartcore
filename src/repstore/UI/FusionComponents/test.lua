-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Fusion = require(ReplicatedStorage.Fusion)local scoped = Fusion.scoped

local Children, OnEvent = Fusion.Children, Fusion.OnEvent
type UsedAs<T> = Fusion.UsedAs<T>

local COLOUR_BLACK = Color3.new(0, 0, 0)
local COLOUR_WHITE = Color3.new(1, 1, 1)

local COLOUR_TEXT = COLOUR_WHITE
local COLOUR_BG_REST = Color3.fromHex("0085FF")
local COLOUR_BG_HOVER = COLOUR_BG_REST:Lerp(COLOUR_WHITE, 0.25)
local COLOUR_BG_HELD = COLOUR_BG_REST:Lerp(COLOUR_BLACK, 0.25)
local COLOUR_BG_DISABLED = Color3.fromHex("CCCCCC")

local BG_FADE_SPEED = 20 -- spring speed units

local ROUNDED_CORNERS = UDim.new(0, 4)
local PADDING = UDim2.fromOffset(6, 4)

local function Button(
	scope: Fusion.Scope,
	props: {
		Name: UsedAs<string>?,
		Layout: {
			LayoutOrder: UsedAs<number>?,
			Position: UsedAs<UDim2>?,
			AnchorPoint: UsedAs<Vector2>?,
			ZIndex: UsedAs<number>?, 
			Size: UsedAs<UDim2>?,
			AutomaticSize: UsedAs<Enum.AutomaticSize>?
		},
		Text: UsedAs<string>?,
		Disabled: UsedAs<boolean>?, 
		OnClick: (() -> ())?
	}
): Fusion.Child
	local isHovering = scope:Value(false)
	local isHeldDown = scope:Value(false)

	return scope:New "TextButton" {
		Name = props.Name,

		LayoutOrder = props.Layout.LayoutOrder,
		Position = props.Layout.Position,
		AnchorPoint = props.Layout.AnchorPoint,
		ZIndex = props.Layout.ZIndex,
		Size = props.Layout.Size,
		AutomaticSize = props.Layout.AutomaticSize,

		Text = props.Text,
		TextColor3 = COLOUR_TEXT,

		BackgroundColor3 = scope:Spring(
			scope:Computed(function(use)
				-- The order of conditions matter here; it defines which states
				-- visually override other states, with earlier states being
				-- more important.
				return
					if use(props.Disabled) then COLOUR_BG_DISABLED
					elseif use(isHeldDown) then COLOUR_BG_HELD
					elseif use(isHovering) then COLOUR_BG_HOVER
					else return COLOUR_BG_REST
			end
		end), 
	BG_FADE_SPEED
	),

[OnEvent "Activated"] = function()
	if props.OnClick ~= nil and not peek(props.Disabled) then
		-- Explicitly called with no arguments to match the typedef. 
		-- If passed straight to `OnEvent`, the function might receive
		-- arguments from the event. If the function secretly *does*
		-- take arguments (despite the type) this would cause problems.
		props.OnClick()
	end
end,

[OnEvent "MouseButton1Down"] = function()
	isHeldDown:set(true)
end,
[OnEvent "MouseButton1Up"] = function()
	isHeldDown:set(false)
end,

[OnEvent "MouseEnter"] = function()
	-- Roblox calls this event even if the button is being covered by
	-- other UI. For simplicity, this does not account for that.
	isHovering:set(true)
end,
[OnEvent "MouseLeave"] = function()
	-- If the button is being held down, but the cursor moves off the
	-- button, then we won't receive the mouse up event. To make sure
	-- the button doesn't get stuck held down, we'll release it if the
	-- cursor leaves the button.
	isHeldDown:set(false)
	isHovering:set(false)
end,

[Children] = {
	New "UICorner" {
		CornerRadius = ROUNDED_CORNERS
	},

	New "UIPadding" {
		PaddingTop = PADDING.Y,
		PaddingBottom = PADDING.Y,
		PaddingLeft = PADDING.X,
		PaddingRight = PADDING.X
	}
}
}
end

return Button
