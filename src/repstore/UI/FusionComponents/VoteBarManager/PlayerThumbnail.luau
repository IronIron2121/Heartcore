--!strict
-- PlayerThumbnail.luau
-- A circular player avatar thumbnail with reactive rim color and opacity.

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Libraries = ReplicatedStorage:WaitForChild("Libraries")

-- Modules
local OnEvent = require(ReplicatedStorage.Utility.Fusion.Instances.OnEvent)
local UI_CONSTANTS = require(ReplicatedStorage.Utility.UI_CONSTANTS)
local Fusion = require(Utility:WaitForChild("Fusion"))
local GameStateValues = require(Libraries:WaitForChild("GameStateValues"))
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))

-- Fusion
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

-- Types
type VoteSlot = {
	anchorPoint: Vector2,
	position: UDim2,
}

export type PlayerThumbnailController = {
	frame: Frame,
	updateSpring: (VoteSlot) -> (),
	destroy: () -> (),
}

-- Colors
local COLOR_NOT_SUBMITTED = Color3.fromRGB(200, 50, 50)
local COLOR_SUBMITTED = Color3.fromRGB(0, 200, 80)
local COLOR_VOTING = Color3.fromRGB(255, 215, 0)

local defaultThumbnailSuccess, defaultThumbnail = callWithRetry(function()
	return Players:GetUserThumbnailAsync(1640373, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size100x100)
end)

local DEFAULT_THUMBNAIL = if defaultThumbnailSuccess and defaultThumbnail then defaultThumbnail else ""

local function PlayerThumbnail(
	scope: Fusion.Scope,
	props: {
		player: Player,
		targetSlot: VoteSlot,
		size: UsedAs<UDim2>?,
		parent: GuiObject,
		onClickCb: (() -> ())?,
	}
): PlayerThumbnailController
	local hasSubmitted = scope:Value(props.player:GetAttribute("HasSubmitted") == true)
	local hasSubmittedConnection = props.player:GetAttributeChangedSignal("HasSubmitted"):Connect(function()
		hasSubmitted:set(props.player:GetAttribute("HasSubmitted") == true)
	end)

	local targetPosition = scope:Value(props.targetSlot.position)
	local targetAnchorPoint = scope:Value(props.targetSlot.anchorPoint)
	local positionSpring = scope:Spring(targetPosition, 12, 0.8)

	local thumbnailUrl = scope:Value(DEFAULT_THUMBNAIL)
	task.spawn(function()
		local success, url = callWithRetry(function()
			return Players:GetUserThumbnailAsync(
				props.player.UserId,
				Enum.ThumbnailType.AvatarBust,
				Enum.ThumbnailSize.Size100x100
			)
		end)

		if success and url then
			thumbnailUrl:set(url)
		else
			thumbnailUrl:set(DEFAULT_THUMBNAIL)
		end
	end)

	local isHeldDown = scope:Value(false)
	local isHovering = scope:Value(false)

	local rimColor = scope:Computed(function(use)
		local currentColor: Color3
		if use(GameStateValues.isVoting) then
			currentColor = COLOR_VOTING
		elseif use(hasSubmitted) then
			currentColor = COLOR_SUBMITTED
		else
			currentColor = COLOR_NOT_SUBMITTED
		end

		if use(isHeldDown) then
			return currentColor:Lerp(UI_CONSTANTS.COLOUR_BLACK, 0.8)
		elseif use(isHovering) then
			return currentColor:Lerp(UI_CONSTANTS.COLOUR_BLACK, 0.25)
		else
			return currentColor
		end
	end)

	local imageTransparency = scope:Computed(function(use)
		if use(GameStateValues.isVoting) or use(isHeldDown) then
			return 0
		end

		if use(isHovering) then
			return 0.25
		end

		return if use(hasSubmitted) then 0 else 0.5
	end)

	local frame = scope:New "Frame" {
		Name = "Thumbnail_" .. props.player.Name,
		Size = props.size or UDim2.fromScale(0.045, 0.45),
		AnchorPoint = targetAnchorPoint,
		Position = positionSpring,
		BackgroundTransparency = 1,
		Parent = props.parent,

		[Children] = {
			scope:New "UIAspectRatioConstraint" {
				AspectRatio = 1,
			},

			scope:New "Frame" {
				Name = "Rim",
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = scope:Spring(rimColor, 8),

				[Children] = {
					scope:New "UICorner" {
						CornerRadius = UDim.new(1, 0),
					},

					scope:New "ImageButton" {
						Name = "Avatar",
						Image = thumbnailUrl,
						Size = UDim2.fromScale(0.85, 0.85),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						BackgroundTransparency = 1,
						ImageTransparency = scope:Spring(imageTransparency, 10),

						[OnEvent "Activated"] = function()
							if props.onClickCb then
								props.onClickCb()
							else
								warn("No CB at player thumbnail image label")
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
							isHeldDown:set(false)
						end,

						[Children] = {
							scope:New "UICorner" {
								CornerRadius = UDim.new(1, 0),
							},
						},
					},
				},
			},
		},
	} :: Frame

	local function updateSpring(slot: VoteSlot)
		targetPosition:set(slot.position)
		targetAnchorPoint:set(slot.anchorPoint)
	end

	local function destroy()
		hasSubmittedConnection:Disconnect()
		frame:Destroy()
	end

	return {
		frame = frame,
		updateSpring = updateSpring,
		destroy = destroy,
	}
end

return PlayerThumbnail
