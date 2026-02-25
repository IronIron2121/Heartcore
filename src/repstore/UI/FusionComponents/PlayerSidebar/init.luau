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

-- Rank map: userId → 1-based rank
local rankMap = scope:Computed(function(use)
	local sorted = use(sortedPlayers)
	local map: {[number]: number} = {}
	for i, player in sorted do
		map[player.UserId] = i
	end
	return map
end)

-- Build sidebar frame
local frame = scope:New "Frame" {
	Name = "PlayerSidebar",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,

	[Children] = {
		scope:ForValues(sortedPlayers, function(use, innerScope, player)
			return PlayerThumbnail(innerScope, {
				player = player, 
				dirtyCounter = dirtyCounter, 
				rankMap = rankMap,
				onClickCb = function()
		            GuiManager.PushCentreByName(MODAL_NAMES.PLAYER_INSPECT_GUI, {
						player = player, 
						rig = nil
					}
				)
			end})
		end),

	},
}

return frame