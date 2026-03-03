--!strict
-- PlayerSidebar/init.luau
-- Right-side HUD panel showing circular player thumbnails with reactive status.

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Libraries = ReplicatedStorage:WaitForChild("Libraries")

-- Modules
local GuiManager = require(ReplicatedStorage.Libraries.GuiManager.GuiManager)
local MODAL_NAMES = require(ReplicatedStorage.Libraries.GuiManager.MODAL_NAMES)
local Fusion = require(Utility:WaitForChild("Fusion"))
local GameStateValues = require(Libraries:WaitForChild("GameStateValues"))
local PlayerThumbnail = require(script:WaitForChild("PlayerThumbnail"))

-- Fusion
local Children = Fusion.Children
local peek = Fusion.peek

local scope = Fusion:scoped()

-- Reactive player map: { [userId]: Player }
local playerMap = scope:Value({} :: {[number]: Player})

local function refreshPlayerMap()
	local map: {[number]: Player} = {}
	for _, player in Players:GetPlayers() do
		map[player.UserId] = player
	end
	playerMap:set(map)
end

Players.PlayerAdded:Connect(refreshPlayerMap)
Players.PlayerRemoving:Connect(function()
	task.defer(refreshPlayerMap)
end)
refreshPlayerMap()

-- Dirty counter: incremented when any player attribute changes to force Fusion re-evaluation
local dirtyCounter = scope:Value(0)
local attributeConnections: {[number]: {RBXScriptConnection}} = {}

local function connectPlayerAttributes(player: Player)
	local conns = {}
	table.insert(conns, player:GetAttributeChangedSignal("HasSubmitted"):Connect(function()
		dirtyCounter:set(peek(dirtyCounter) + 1)
	end))
	table.insert(conns, player:GetAttributeChangedSignal("VoteScore"):Connect(function()
		dirtyCounter:set(peek(dirtyCounter) + 1)
	end))
	attributeConnections[player.UserId] = conns
end

local function disconnectPlayerAttributes(player: Player)
	local conns = attributeConnections[player.UserId]
	if conns then
		for _, conn in conns do
			conn:Disconnect()
		end
	end
	attributeConnections[player.UserId] = nil
end

Players.PlayerAdded:Connect(connectPlayerAttributes)
Players.PlayerRemoving:Connect(disconnectPlayerAttributes)
for _, player in Players:GetPlayers() do
	connectPlayerAttributes(player)
end

-- Sorted player list
local sortedPlayers = scope:Computed(function(use)
	use(dirtyCounter)
	local map = use(playerMap)
	local list: {Player} = {}
	for _, player in map do
		table.insert(list, player)
	end

	if use(GameStateValues.isVoting) then
		table.sort(list, function(a, b)
			local scoreA = a:GetAttribute("VoteScore") or 0
			local scoreB = b:GetAttribute("VoteScore") or 0
			if scoreA ~= scoreB then return scoreA > scoreB end
			return a.UserId < b.UserId
		end)
	else
		table.sort(list, function(a, b)
			return a.UserId < b.UserId
		end)
	end

	return list
end)

local THUMB_GAP = 0.1 -- scale of parent height; used as UIListLayout Padding

-- Rank map: userId → 1-based rank
local rankMap = scope:Computed(function(use)
	local sorted = use(sortedPlayers)
	local map: {[number]: number} = {}
	for i, player in sorted do
		map[player.UserId] = i
	end
	return map
end)

-- Anchor layer: UIListLayout drives invisible per-player slot frames
local anchorLayer = scope:New "Frame" {
	Name = "AnchorLayer",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	[Children] = {
		scope:New "UIListLayout" {
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(THUMB_GAP, 0),
		},
	},
}

-- ForValues: per player, create an invisible anchor (parented to anchorLayer)
-- and return a thumbnail that springs toward the anchor's AbsolutePosition
local thumbnailChildren = scope:ForValues(sortedPlayers, function(use, innerScope, player)
	local anchorFrame = innerScope:New "Frame" {
		Name = "Anchor_" .. player.Name,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = innerScope:Computed(function(use)
			return use(rankMap)[player.UserId] or 999
		end),
		Parent = anchorLayer,
	} :: Frame

	(innerScope :: any):New "UIAspectRatioConstraint" {
		AspectRatio = 1,
		Parent = anchorFrame,
	}

	local targetY: Fusion.Value<number> = innerScope:Value(0) :: Fusion.Value<number>

	local aLayer = anchorLayer :: Frame
	local function readAnchorY()
		if aLayer.AbsoluteSize.Y == 0 then return end
		targetY:set(
			(anchorFrame.AbsolutePosition.Y - aLayer.AbsolutePosition.Y)
			/ aLayer.AbsoluteSize.Y
		)
	end

	local conn = anchorFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(readAnchorY)
	table.insert(innerScope :: any, function() conn:Disconnect() end)

	task.defer(readAnchorY)

	return PlayerThumbnail(innerScope, {
		player = player,
		dirtyCounter = dirtyCounter,
		targetY = targetY,
		onClickCb = function()
			GuiManager.PushCentreByName(MODAL_NAMES.PLAYER_INSPECT_GUI, {
				player = player,
				rig = nil,
			})
		end,
	})
end)

-- Build sidebar frame
local frame = scope:New "Frame" {
	Name = "PlayerSidebar",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	[Children] = {
		anchorLayer,
		scope:New "Frame" {
			Name = "ThumbnailLayer",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			[Children] = { thumbnailChildren },
		},
	},
}

return frame