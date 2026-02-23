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
local Fusion = require(Utility:WaitForChild("Fusion"))
local GameStateValues = require(Libraries:WaitForChild("GameStateValues"))
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))

-- Fusion
local Children = Fusion.Children
local peek = Fusion.peek
type UsedAs<T> = Fusion.UsedAs<T>

-- Colors
local COLOR_NOT_SUBMITTED = Color3.fromRGB(200, 50, 50)
local COLOR_SUBMITTED = Color3.fromRGB(0, 200, 80)
local COLOR_VOTING = Color3.fromRGB(255, 215, 0)

local THUMB_HEIGHT = 0.1
local THUMB_GAP = 0.1

local _success, DEFAULT_THUMBNAIL = callWithRetry(function()
	return Players:GetUserThumbnailAsync(1640373, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size100x100)
end)

local function PlayerThumbnail(
	scope: Fusion.Scope,
	player: Player,
	dirtyCounter: Fusion.Value<number>,
	rankMap: Fusion.Computed<{[number]: number}>
): Frame
	-- Fetch thumbnail async
	local thumbnailUrl = scope:Value(DEFAULT_THUMBNAIL)
	task.spawn(function()
		local success, url = callWithRetry(function()
			return Players:GetUserThumbnailAsync(
				player.UserId,
				Enum.ThumbnailType.AvatarBust,
				Enum.ThumbnailSize.Size100x100
			)
		end)
		if success and url then
			thumbnailUrl:set(url)
		end
	end)

	-- Rim color
	local rimColor = scope:Computed(function(use)
		use(dirtyCounter)
		if use(GameStateValues.isVoting) then
			return COLOR_VOTING
		end
		local hasSubmitted = player:GetAttribute("HasSubmitted")
		return hasSubmitted and COLOR_SUBMITTED or COLOR_NOT_SUBMITTED
	end)

	-- Image transparency
	local imageTransparency = scope:Computed(function(use)
		use(dirtyCounter)
		if use(GameStateValues.isVoting) then
			return 0
		end
		local hasSubmitted = player:GetAttribute("HasSubmitted")
		return hasSubmitted and 0 or 0.5
	end)

	-- Y position from rank
	local yPosition = scope:Computed(function(use)
		local ranks = use(rankMap)
		local rank = ranks[player.UserId] or 1
		return (rank - 1) * (THUMB_HEIGHT + THUMB_GAP)
	end)

	local springY = scope:Spring(yPosition, 12, 0.8)

	local position = scope:Computed(function(use)
		return UDim2.fromScale(0, use(springY))
	end)

	return scope:New "Frame" {
		Name = "Thumbnail_" .. player.Name,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = position,
		BackgroundTransparency = 1,

		[Children] = {
			scope:New "UIAspectRatioConstraint" {
				AspectRatio = 1,
			},

			-- Rim
			scope:New "Frame" {
				Name = "Rim",
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = scope:Spring(rimColor, 8),

				[Children] = {
					scope:New "UICorner" {
						CornerRadius = UDim.new(1, 0),
					},

					-- Avatar image
					scope:New "ImageLabel" {
						Name = "Avatar",
						Image = thumbnailUrl,
						Size = UDim2.fromScale(0.85, 0.85),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						BackgroundTransparency = 1,
						ImageTransparency = scope:Spring(imageTransparency, 10),

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
end

return PlayerThumbnail
