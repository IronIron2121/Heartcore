--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local DataTables = ReplicatedStorage:WaitForChild("DataTables")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Bindables = ReplicatedStorage:WaitForChild("Bindables")

-- Modules
local ImageUris = require(DataTables:WaitForChild("ImageUris"))
local Fusion = require(Utility:WaitForChild("Fusion"))

-- Fusion Components
local OnEvent = Fusion.OnEvent
type UsedAs<T> = Fusion.UsedAs<T>


-- Remotes / Bindables
local PlayerTriggeredCatalogConsole = Bindables:WaitForChild("PlayerTriggeredCatalogConsole")





-- Constants
-- local DEFAULT_TEXT_COLOUR = Color3.new(0.360784, 0.376471, 0.839216)
local COLOUR_BLACK = Color3.new(0, 0, 0)
local COLOUR_PURPLE = Color3.new(0.360784, 0.376471, 0.839216)
local COLOUR_GREY = Color3.new(1, 1, 1)


local BG_FADE_SPEED = 20 -- spring speed units

--

local function OpenWardrobeButton(
	scope: Fusion.Scope
)
	
	local Toggled = scope:Value(false) 

	local OnClick = function()
		Toggled:set(not Fusion.peek(Toggled))
	end

	PlayerTriggeredCatalogConsole.Event:Connect(function()
		Toggled:set(not Fusion.peek(Toggled))
	end)
	
	local isHovering = scope:Value(false)
	local isHeldDown = scope:Value(false)
	
	local COLOUR_BG_TOGGLED = COLOUR_PURPLE
	local COLOUR_BG_NOT_TOGGLED = COLOUR_GREY
	
	local isToggled = scope:Computed(function(use, _)
		return use(Toggled) == true
	end)
	
	return scope:New "TextButton" {
		Name = "CatalogButton",
		
		LayoutOrder = 0,
		Position = UDim2.fromScale(0.45, 0.95),
		AnchorPoint = Vector2.new(0.5, 1),
		ZIndex = 0, 
		Size = UDim2.fromScale(0.1,0.1),
		AutomaticSize = Enum.AutomaticSize.X,
		
		Transparency = 1,

		Visible = scope:Computed(function(use)
			return not use(Toggled)
		end),
		
		[OnEvent "Activated"] = function()
			if OnClick ~= nil then
				OnClick()
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
		
		[Fusion.Children] = {
			scope:New "ImageLabel" {
				Image = ImageUris.OutfitCatalogButton,
				Size = UDim2.fromScale(1,1),
				BackgroundTransparency = 1,
				ImageColor3 = scope:Spring(
					scope:Computed(function(use)
						local baseColor = use(isToggled) and COLOUR_BG_TOGGLED or COLOUR_BG_NOT_TOGGLED
						
						if use(isHeldDown) then
							return baseColor:Lerp(COLOUR_BLACK, 0.8)
						elseif use(isHovering) then
							return baseColor:Lerp(COLOUR_BLACK, 0.25)
						else 
							return baseColor
						end
					end),
					BG_FADE_SPEED
				), 
				
			},
			
			scope:New "UIAspectRatioConstraint" {
				AspectRatio = 1
			}
		}
	},  
		Toggled
end

return OpenWardrobeButton