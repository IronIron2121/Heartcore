--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local Widgets = FusionComponents:WaitForChild("Widgets")

-- Gui Components
local AvatarContainer = require(script:WaitForChild("AvatarContainer"))
local CatalogContainer = require(script:WaitForChild("CatalogContainer")) 
local CloseButton   = require(Widgets:WaitForChild("CloseButton"))

-- Fusion
local Fusion = require(Utility:WaitForChild("Fusion"))
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

return function(scope: Fusion.Scope, wardrobeContainerVisible: UsedAs<boolean>)
	local avatarContainer = AvatarContainer(scope)
	local catalogContainer = CatalogContainer(scope)

	return scope:New "Frame" { 
		Name = "WardrobeContainer",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.95, 0.9),
		
		[Children] = {
            CloseButton(scope, {
                size = UDim2.fromScale(0.08, 0.08),
                anchorPoint = Vector2.new(0.5, 0.5),
                position = UDim2.fromScale(1, 0.02),
						
				onClick = function()
					wardrobeContainerVisible:set(not Fusion.peek(wardrobeContainerVisible))
				end,
			}),

			scope:New "Folder" {
				Name = "ContainerFolder",

				[Children] = {
					scope:New "UIListLayout" {
						Padding = UDim.new(0.01, 0),
						FillDirection = Enum.FillDirection.Horizontal,
						SortOrder = Enum.SortOrder.LayoutOrder,
						HorizontalAlignment = Enum.HorizontalAlignment.Left,
						VerticalAlignment = Enum.VerticalAlignment.Top,
					},
					avatarContainer,
					catalogContainer
				}
			}
		}
	},
		avatarContainer,
		catalogContainer
end