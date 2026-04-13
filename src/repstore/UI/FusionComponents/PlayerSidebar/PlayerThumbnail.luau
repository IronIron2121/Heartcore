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

-- Colors
local COLOR_NOT_SUBMITTED = Color3.fromRGB(200, 50, 50)
local COLOR_SUBMITTED = Color3.fromRGB(0, 200, 80)
local COLOR_VOTING = Color3.fromRGB(255, 215, 0)

local _success, DEFAULT_THUMBNAIL = callWithRetry(function()
	return Players:GetUserThumbnailAsync(1640373, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size100x100)
end)

local function PlayerThumbnail(
	scope: Fusion.Scope,
	props: {
		player: Player,
		dirtyCounter: Fusion.Value<number>,
		targetY: Fusion.Value<number>,
		thumbScale: UsedAs<number>,
		onClickCb: () -> ()
	}

): Frame
	-- Fetch thumbnail async
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
			thumbnailUrl:set()
		end
	end)

	--
	local isHeldDown = scope:Value(false)
	local isHovering = scope:Value(false)

	-- Rim color
	local rimColor = scope:Computed(function(use)
		use(props.dirtyCounter)
		local currentColor 
		local hasSubmitted = props.player:GetAttribute("HasSubmitted")

		if use(GameStateValues.isVoting) then
			currentColor = COLOR_VOTING
		elseif hasSubmitted then
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


	-- Image transparency
	local imageTransparency = scope:Computed(function(use)
		use(props.dirtyCounter)
		if use(GameStateValues.isVoting) or use(isHeldDown) then
			return 0
		end
		
		if (use(isHovering)) then
			return 0.25
		end

		local hasSubmitted = props.player:GetAttribute("HasSubmitted")
		return hasSubmitted and 0 or 0.5
	end)

	local springY = scope:Spring(props.targetY, 12, 0.8)

	local position = scope:Computed(function(use)
		return UDim2.fromScale(0, use(springY))
	end)

	return scope:New "Frame" {
		Name = "Thumbnail_" .. props.player.Name,
		Size = scope:Computed(function(use)
			return UDim2.fromScale(use(props.thumbScale), 0)
		end),
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
end


return PlayerThumbnail
