--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Utility.Fusion)
type Value<T> = Fusion.Value<T>
local peek = require(ReplicatedStorage.Utility.Fusion.State.peek)
type UsedAs<T> = Fusion.UsedAs<T>




--

local function VoteBar(scope: Fusion.Scope, props: {
    name: string,
    backgroundColor: UsedAs<Color3>,
    position: UsedAs<UDim2>,
    size: UsedAs<UDim2>,
    anchorPoint: UsedAs<Vector2>,
    slotSize: UDim2,
    justification: string,
    maxSlots: number,
    padding: number
}): {voteBarFrame: Frame, getSlotPosition: (number) -> (any)}

    local anchorPoint
    if props.justification == 'left' then
        anchorPoint = scope:Value(Vector2.new(1, 0.5))
    elseif props.justification == 'right' then
        anchorPoint = scope:Value(Vector2.new(0, 0.5))
    elseif props.justification == 'middle' then
        anchorPoint = scope:Value(Vector2.new(0.5, 0.5))
    end

    local slotPositions = {}

    for i = 0, props.maxSlots, 1 do
        local x
        if props.justification == 'left' then
            x = 1 - (props.slotSize.X.Scale * i) - props.padding
            table.insert(slotPositions, {
                anchorPoint = anchorPoint,
                position = UDim2.fromScale(x, 0.5) 
            })
        elseif props.justification == 'right' then
            x = (peek(props.slotSize).X.Scale * i)
            table.insert(slotPositions, {
                anchorPoint = anchorPoint,
                position = UDim2.fromScale(x + props.padding, 0.5) 
            })
        elseif props.justification == 'middle' then
            x = (i + 1) / (props.maxSlots + 1)
            table.insert(slotPositions, {
                anchorPoint = anchorPoint,
                position = UDim2.fromScale(x + props.padding, 0.5) 
            })
        end
    end

    local function getSlotPosition(index: number)
        return slotPositions[index]
    end

    local voteBarFrame = scope:New "Frame" {
        Name = props.name,
        AnchorPoint = props.anchorPoint, 
        BackgroundTransparency = 0.6,
        Position = props.position,
        BackgroundColor3 = props.backgroundColor or Color3.new(255,255,255),
        Size = props.size
    } :: Frame

    return {
        voteBarFrame = voteBarFrame,
        getSlotPosition = getSlotPosition
    }
end



return VoteBar