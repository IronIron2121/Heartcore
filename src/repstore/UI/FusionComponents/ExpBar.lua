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
        AnchorPoint = Vector2.new(0,0),
        Size = UDim2.fromScale(0.15,0.5),
        Position = UDim2.fromScale(0,0),

        [Children] = {
            scope:New "ImageLabel" {
            Name = props.name or "ExpBar",
            Image = ImageUris.ExpBar,
            Visible = true,
            AnchorPoint = props.anchorPoint or Vector2.new(0,0.5),
            Position = props.position or UDim2.fromScale(0,0.5),
            Size = props.size or UDim2.fromScale(1,1),
            BackgroundTransparency = 1,
            ZIndex = 2,

                [Children] = {
                    scope:New "UIAspectRatioConstraint" {
                        AspectRatio = 3,
                    }
                }
            },
            
            scope:New "Frame" {
                Name = "ProgressFill",
                AnchorPoint = Vector2.new(0,0.5),
                Size = UDim2.fromScale(0.75,0.15),
                Position = UDim2.fromScale(0.2,0.47),
                BackgroundColor3 = Color3.new(1,1,1),
                ZIndex = 1,

                [Children] = {
                    scope:New "UIGradient"{
                        Color = ColorSequence.new(Color3.fromRGB(24, 107, 79), Color3.fromRGB(130, 194, 144)),
                    },

                    scope:New "UICorner" {
                        CornerRadius = UDim.new(0.5,0)
                    }
                }
            }
        }
    } :: Frame

    return frame
end

return ExpBar