--!strict

-- Services
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local DataTables = ReplicatedStorage:WaitForChild("DataTables")

-- Instances
local localPlayer = Players.LocalPlayer
local ImageUris = require(DataTables:WaitForChild("ImageUris"))


-- Gui Components
local AvatarContainer = require(script:WaitForChild("AvatarContainer"))
local CatalogContainer = require(script:WaitForChild("CatalogContainer")) 

-- Fusion
local Fusion = require(Utility:WaitForChild("Fusion"))

type UsedAs<T> = Fusion.UsedAs<T>

return function(scope: Fusion.Scope, wardrobeContainerVisible: UsedAs<boolean>)
	local isNewTopBar = GuiService.TopbarInset.Max.Y > 36
	local avatarContainer = AvatarContainer(scope)
	local catalogContainer = CatalogContainer(scope)

	return scope:New "Frame" { 
		Name = "WardrobeContainer",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.8, 0.8),
		
		[Fusion.Children] = {
            scope:New "ImageButton" {
				Name = "CloseButton",
				Image = ImageUris["CloseButton"],
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromScale(0.05, 0.05),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(1.01,0.01),
                ZIndex = 3,
						
					[Fusion.Children] = {
						scope:New "UIAspectRatioConstraint" {
							AspectRatio = 1
						}
					},
						
					[Fusion.OnEvent "Activated"] = function()
						wardrobeContainerVisible:set(not Fusion.peek(wardrobeContainerVisible))
					end,
			},
			scope:New "Folder" {
				Name = "ContainerFolder",

				[Fusion.Children] = {
					scope:New "UIListLayout" {
						Padding = UDim.new(0, 20),
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