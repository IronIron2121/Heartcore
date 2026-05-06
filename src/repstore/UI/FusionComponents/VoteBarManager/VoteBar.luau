--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Utility.Fusion)
type Value<T> = Fusion.Value<T>
local peek = require(ReplicatedStorage.Utility.Fusion.State.peek)
type UsedAs<T> = Fusion.UsedAs<T>




--

local function VoteBar(scope: Fusion.Scope, props: {
    name: string,
    position: UsedAs<UDim2>,
    slotSize: Value<UDim2>,
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
        if props.justification == 'left' then
            table.insert(slotPositions, {
                anchorPoint = anchorPoint,
                position = UDim2.fromScale(1 - (peek(props.slotSize).X.Scale * i) - props.padding, 0.5) 
            })
        elseif props.justification == 'right' then
            table.insert(slotPositions, {
                anchorPoint = anchorPoint,
                position = UDim2.fromScale((peek(props.slotSize).X.Scale * i) + props.padding, 0.5) 
            })
        elseif props.justification == 'middle' then
            table.insert(slotPositions, {
                anchorPoint = anchorPoint,
                position = UDim2.fromScale((peek(props.slotSize).X.Scale * i) + props.padding, 0.5) 
            })
        end

    end

    local function getSlotPosition(index: number)
        return slotPositions[index]
    end

    local voteBarFrame = scope:New "Frame" {

    } :: Frame

    return {
        voteBarFrame = voteBarFrame,
        getSlotPosition = getSlotPosition
    }
end



