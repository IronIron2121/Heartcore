--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Utility.Fusion)

type UsedAs<T> = Fusion.UsedAs<T>

export type VoteSlot = {
	anchorPoint: Vector2,
	position: UDim2,
}

type VoteBarProps = {
	name: string,
	backgroundColor: UsedAs<Color3>,
	backgroundTransparency: number,
	position: UsedAs<UDim2>,
	size: UsedAs<UDim2>,
	anchorPoint: UsedAs<Vector2>,
	slotSize: UDim2,
	justification: string,
	maxSlots: number,
	padding: number,
}

type VoteBarController = {
	voteBarFrame: Frame,
	getSlotPosition: (number) -> VoteSlot,
}

local function toContainerPosition(localPosition: UDim2, props: VoteBarProps): UDim2
	local barPosition = Fusion.peek(props.position)
	local barSize = Fusion.peek(props.size)
	local barAnchorPoint = Fusion.peek(props.anchorPoint)

	local barLeftX = barPosition.X.Scale - (barAnchorPoint.X * barSize.X.Scale)
	local barTopY = barPosition.Y.Scale - (barAnchorPoint.Y * barSize.Y.Scale)

	return UDim2.fromScale(
		barLeftX + (localPosition.X.Scale * barSize.X.Scale),
		barTopY + (localPosition.Y.Scale * barSize.Y.Scale)
	)
end

local function VoteBar(scope: Fusion.Scope, props: VoteBarProps): VoteBarController
	local anchorPoint: Vector2
	if props.justification == "left" then
		anchorPoint = Vector2.new(1, 0.5)
	elseif props.justification == "right" then
		anchorPoint = Vector2.new(0, 0.5)
	elseif props.justification == "middle" then
		anchorPoint = Vector2.new(0.5, 0.5)
	else
		warn("Unhandled vote bar justification", props.justification)
		anchorPoint = Vector2.new(0.5, 0.5)
	end

	local slotPositions: {VoteSlot} = {}
	local stepScale = props.slotSize.X.Scale + props.padding

	for i = 0, props.maxSlots - 1 do
		local x: number
		if props.justification == "left" then
			x = 1 - (stepScale * i) - props.padding
		elseif props.justification == "right" then
			x = (stepScale * i) + props.padding
		else
			x = (i + 1) / (props.maxSlots + 1)
		end

		table.insert(slotPositions, {
			anchorPoint = anchorPoint,
			position = toContainerPosition(UDim2.fromScale(x, 0.5), props),
		})
	end

	local function getSlotPosition(index: number): VoteSlot
		local clampedIndex = math.clamp(index + 1, 1, #slotPositions)
		return slotPositions[clampedIndex]
	end

	local voteBarFrame = scope:New "Frame" {
		Name = props.name,
		AnchorPoint = props.anchorPoint,
		BackgroundTransparency = 1,
		Position = props.position,
		BackgroundColor3 = props.backgroundColor or Color3.fromRGB(255, 255, 255),
		Size = props.size,
	} :: Frame

	return {
		voteBarFrame = voteBarFrame,
		getSlotPosition = getSlotPosition,
	}
end

return VoteBar
