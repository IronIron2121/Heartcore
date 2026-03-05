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

local THUMB_GAP = 0.02 -- scale of parent height; used as UIListLayout Padding

-- Slot aspect ratio (width/height), updated from AbsoluteSize
-- Default assumes 16:9 screen; corrected once AbsoluteSize is known
local slotAspectRatio = scope:Value((0.1 * 16) / (0.8 * 9))

-- Dynamic thumb scale: shrinks thumbnails so they always fit in the slot
-- Each thumbnail is square, so its height (in parent-height fraction) = thumbScale * aspectRatio
-- Constraint: count * thumbScale * aspectRatio + (count-1) * THUMB_GAP <= 1
local thumbScale = scope:Computed(function(use)
	local count = #use(sortedPlayers)
	if count <= 1 then return 1 end
	local ar = use(slotAspectRatio)
	if ar <= 0 then return 1 end
	local size = (1 - (count - 1) * THUMB_GAP) / (count * ar)
	return math.clamp(size, 0.05, 1)
end)

-- Rank map: userId → 1-based rank
local rankMap = scope:Computed(function(use)
	local sorted = use(sortedPlayers)
	local map: {[number]: number} = {}
	for i, player in sorted do
		map[player.UserId] = i
	end
	return map
end)

-- Compute each thumbnail's Y position purely from rank, thumbScale, and aspect ratio
-- thumbHeight (as fraction of parent height) = thumbScale * ar
-- Y for rank i = (i-1) * (thumbHeight + THUMB_GAP)
local thumbnailChildren = scope:ForValues(sortedPlayers, function(use, innerScope, player)
	local targetY = innerScope:Computed(function(use)
		local ranks = use(rankMap)
		local rank = ranks[player.UserId] or 1
		local ar = use(slotAspectRatio)
		local thumbHeight = use(thumbScale) * ar
		return (rank - 1) * (thumbHeight + THUMB_GAP)
	end)

	return PlayerThumbnail(innerScope, {
		player = player,
		dirtyCounter = dirtyCounter,
		targetY = targetY,
		thumbScale = thumbScale,
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
	[Children] = { thumbnailChildren },
} :: Frame

-- Update slot aspect ratio from actual rendered size
frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	local abs = frame.AbsoluteSize
	if abs.X > 0 and abs.Y > 0 then
		slotAspectRatio:set(abs.X / abs.Y)
	end
end)

return frame