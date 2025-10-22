--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local DataTables = ReplicatedStorage:WaitForChild("DataTables")


-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))
local ImageUris = require(DataTables:WaitForChild("ImageUris"))


-- Fusion
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

function ExpBar(
    scope: Fusion.Scope,
    props: {
        name: UsedAs<string>?,
		active: UsedAs<boolean>?,
		visible: UsedAs<boolean>?,
		size: UsedAs<UDim2>?,
		position: UsedAs<UDim2>?,
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
		onActivated: (() -> ())?,
	}
): Frame 


    local frame = scope:New "Frame" {
        Name = "ExpBarContainer",
        BackgroundColor3 = Color3.new(1,1,1),
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(0.3,1),
        Position = UDim2.fromScale(1, 1),

        [Children] = {
            scope:New "ImageLabel" {
            Name = props.name or "XpBar",
            Image = ImageUris.XpBar,
            Visible = props.visible or false,
            AnchorPoint = props.anchorPoint or Vector2.new(0.5,0.5),
            Position = props.position or UDim2.fromScale(0.5,0.5),
            Size = props.size or UDim2.fromScale(1,1),
            BackgroundTransparency = 1,
            ZIndex = 2,

                [Children] = {
                    scope:New "UIAspectRatioConstraint" {
                        AspectRatio = 2,
                    }
                }
            },
            
            scope:New "Frame" {
                Name = "ProgressFill",
                AnchorPoint = Vector2.new(0.5,0.5),
                Size = UDim2.fromScale(0.3,0.7),    
                Position = UDim2.fromScale(0.2,1),
                BackgroundColor3 = Color3.new(1,1,1),

                [Children] = {
                    scope:New "UIGradient"{
                        Color = ColorSequence.new(Color3.fromRGB(24, 107, 79), Color3.fromRGB(130, 194, 144)),
                    },
                    
                    scope:New "UIAspectRatioConstraint" {
                        AspectRatio = 2,
                    }
                }
            }
        }
    } :: Frame

    return frame
end

return ExpBar