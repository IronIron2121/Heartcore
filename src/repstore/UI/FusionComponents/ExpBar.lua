--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local DataTables = ReplicatedStorage:WaitForChild("DataTables")

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))
local ImageUris = require(DataTables:WaitForChild("ImageUris"))

-- Fusion
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>


-- Instances
local localPlayer = Players.LocalPlayer

local leaderstats = localPlayer:WaitForChild("leaderstats")
local exp = leaderstats:WaitForChild("Exp")




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

    local scale = (exp.Value % 10) * 0.075
    local expBarSize = Fusion.Value(scope, UDim2.fromScale(scale, 0.15))

    local function updateExpBar()
        local newScale = (exp.Value % 10) * 0.075
        expBarSize:set(UDim2.fromScale(newScale, 0.15))
    end 

    exp:GetPropertyChangedSignal("Value"):Connect(updateExpBar)


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
                    },
                    
                    scope:New "Frame" {
                        Name = "ProgressFill",
                        AnchorPoint = Vector2.new(0,0.5),
                        Size = expBarSize,
                        Position = UDim2.fromScale(0.2,0.47),
                        BackgroundColor3 = Color3.new(1,1,1),
                        ZIndex = 1,

                        [Children] = {
                            scope:New "UIGradient"{
                                Color = ColorSequence.new(Color3.fromRGB(24, 107, 79), Color3.fromRGB(130, 194, 144)),
                            },

                            scope:New "UICorner" {
                                CornerRadius = UDim.new(0.5,0)
                            },

                            --[[
                            scope:New "UIAspectRatioConstraint" {
                                AspectRatio = 10,
                            }
                            ]]
                        }
                    }
                }
            },
            

        }
    } :: Frame

    return frame
end

return ExpBar