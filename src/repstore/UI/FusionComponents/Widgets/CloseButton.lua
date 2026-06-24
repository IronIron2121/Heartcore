--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local DataTables 	= ReplicatedStorage:WaitForChild("DataTables")
local Utility 		= ReplicatedStorage:WaitForChild("Utility")

-- Modules
local ImageUris 	= require(DataTables:WaitForChild("ImageUris"))
local Fusion 		= require(Utility:WaitForChild("Fusion"))

-- Fusion
type UsedAs<T> 		= Fusion.UsedAs<T>
local OnEvent 		= Fusion.OnEvent
local Children 		= Fusion.Children

-- Constants
local COLOUR_ORANGE = Color3.new(0.901961, 0.380392, 0.078431)
local COLOUR_GREY 	= Color3.new(1, 1, 1)
local BG_FADE_SPEED = 20

local function CloseButton(
    scope: Fusion.Scope,
    props: {
		position: UsedAs<UDim2>,
		onClick: () -> (),
		name: UsedAs<string>?,
		active: UsedAs<boolean>?,
		visible: UsedAs<boolean>?,
		size: UsedAs<UDim2>?,
		layoutOrder: UsedAs<number>?,
		anchorPoint: UsedAs<Vector2>?,
		text: UsedAs<string>?,
		textScaled: UsedAs<boolean>?,
		backgroundColor: UsedAs<Color3>?,
		textColor: UsedAs<Color3>?,
		strokeColor: UsedAs<Color3>?,
		strokeThickness: UsedAs<number>?,
		cornerRadius: UsedAs<UDim>?,
		zIndex: UsedAs<number>?,
		image: UsedAs<string>?,
	}
)
    local Toggled = scope:Value(false)
    local isHovering = scope:Value(false)
	local isHeldDown = scope:Value(false)
	
	local COLOUR_BG_TOGGLED = COLOUR_ORANGE
	local COLOUR_BG_NOT_TOGGLED = COLOUR_GREY
	
	local isToggled = scope:Computed(function(use, _)
		return use(Toggled) == true
	end)
	
	return scope:New "TextButton" {
		Name = "CloseButton",
		Position = props.position or UDim2.fromScale(1, 1),
		AnchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5),
		ZIndex = props.zIndex or 3, 
		Size = props.size or UDim2.fromScale(0.2,0.2),
		BackgroundTransparency = 1,
		Transparency = 1,
		
		[OnEvent "Activated"] = function()
			if props.onClick ~= nil then
				props.onClick()
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

        [Children] = {
			scope:New "ImageLabel" {
				Image = props.image or ImageUris.CloseButton,
				Size = UDim2.fromScale(1,1),
				BackgroundTransparency = 1,
				Rotation = scope:Spring(
					scope:Computed(function(use)
						if use(isHovering) then
							return 30
						else
							return 0
						end
					end),
					BG_FADE_SPEED
				),
			},
			
			scope:New "UIAspectRatioConstraint" {
				AspectRatio = 1
			},
		}
    },
        Toggled
end

return CloseButton