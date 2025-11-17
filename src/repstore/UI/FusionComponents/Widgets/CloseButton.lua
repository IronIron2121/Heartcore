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

-- Fusion
type UsedAs<T> = Fusion.UsedAs<T>
type Value<T> = Fusion.Value<T>


local function CloseButton(scope: Fusion.Scope, props: {
    position: UsedAs<UDim2>,
    size: UsedAs<UDim2>,
    anchorPoint: UsedAs<Vector2>,
    zIndex: UsedAs<number>?,
    visibilityBoolean: Value<boolean>
})
    local closeButton = scope:New "ImageButton" { 
        Name = "CloseButton",
        Image = ImageUris["CloseButton"],
        AnchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5),
        Size = props.size or UDim2.fromScale(0.05, 0.05),
        BackgroundTransparency = 1,
        Position = props.position or UDim2.fromScale(1.01, 0.01),
        ZIndex = props.zIndex or 3,

        [Fusion.Children] = {
            scope:New "UIAspectRatioConstraint" {
                AspectRatio = 1
            }
        },
                
        [Fusion.OnEvent "Activated"] = function()
            props.visibilityBoolean:set(not props.visibilityBoolean)
        end,
    }
    
    return closeButton
end

return CloseButton