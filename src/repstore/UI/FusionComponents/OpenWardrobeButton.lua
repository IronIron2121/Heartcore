--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local DataTables = ReplicatedStorage:WaitForChild("DataTables")
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local GuiManager = require(ReplicatedStorage.Libraries.GuiManager.GuiManager)
local MODAL_NAMES = require(ReplicatedStorage.Libraries.GuiManager.MODAL_NAMES)
local WardrobeGuiState = require(ReplicatedStorage.UI.FusionComponents.WardrobeGuiController.WardrobeGuiState)
local ImageUris = require(DataTables:WaitForChild("ImageUris"))
local Fusion = require(Utility:WaitForChild("Fusion"))

-- Fusion Components
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>


-- Constants
local COLOUR_ORANGE = Color3.new(0.901961, 0.380392, 0.078431)
local COLOUR_GREY = Color3.new(1, 1, 1)


local BG_FADE_SPEED = 20 -- spring speed units

--

local function OpenWardrobeButton(
	scope: Fusion.Scope,
	props: {
		onClick: () -> ()
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
		Name = "CatalogButton",
		
		LayoutOrder = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = 0, 
		Size = UDim2.fromScale(1,1),
		AutomaticSize = Enum.AutomaticSize.X,
		
		Transparency = 1,

		Visible = scope:Computed(function(use)
			return not use(Toggled)
		end),
		
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
				Image = ImageUris.OutfitCatalogButton,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
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
			}
		}
	},  
		Toggled
end

return OpenWardrobeButton