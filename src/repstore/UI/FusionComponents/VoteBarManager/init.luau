--!strict
-- VoteBarManager/init.luau
-- Right-side HUD panel showing circular player thumbnails with reactive status.

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local Constants = require(ReplicatedStorage.Constants)
local Fusion = require(Utility:WaitForChild("Fusion"))
local PlayerThumbnail = require(script:WaitForChild("PlayerThumbnail")) 

-- Fusion
local Children = Fusion.Children
local scope = Fusion:scoped()

local playerMap = scope:Value({} :: {
	[number]: Player}
)

-- Go through all players, create a new dictionary assigning their userId to their player object, and then set that as new playerMap fusion value
local function refreshPlayerMap()
	local map: {
		[number]: Player
	} = {}
	for _, player in Players:GetPlayers() do
		map[player.UserId] = player
	end
	playerMap:set(map)
end

local hasSubmitted = scope:Value(false)
local attributeConnections: {[number]: {RBXScriptConnection}} = {}

local function connectPlayerAttributes(player: Player)
	local conns = {}

	table.insert(conns, player:GetAttributeChangedSignal("HasSubmitted"):Connect(function()
		hasSubmitted:set(player:GetAttribute("HasSubmitted"))
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

Players.PlayerAdded:Connect(function(player: Player)  
	connectPlayerAttributes(player)
	task.defer(refreshPlayerMap)
end)

Players.PlayerRemoving:Connect(function(player)
	disconnectPlayerAttributes(player)
	task.defer(refreshPlayerMap)
end)

refreshPlayerMap()

for _, player in Players:GetPlayers() do
	connectPlayerAttributes(player)
end

--

local maxPlayers = scope:Value(8)

local playerThumbnails: {[number] : any} = {}
local VoteBarManager = {}

--[[
VoteBarManager.leftVoteBar: Frame = nil
VoteBarManager.middleVoteBar = nil
VoteBarManager.rightVoteBar = nil
]]

function VoteBarManager.initialise()
	VoteBarManager.leftVoteBar = scope:New "Frame" {
		Name = "LeftVoteBar",
		Size = UDim2.fromScale(0.2, 0.2),
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Children = {

		}
	}

	VoteBarManager.

	VoteBarManager.rightVoteBar = scope:New "Frame" {
		Name = "RightVoteBar",
		Size = UDim2.fromScale(0.2, 0.2),
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(1, 1)
	}

	VoteBarManager.middleVoteBar = scope:New "Frame" {
		Name = "MiddleVoteBar",
		Size = UDim2.fromScale(0.6, 0.2),
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1)
	}

	local voteBarContainer = scope:New "Frame" {
		Name = "VoteBarContainer",
		Size = UDim2.fromScale(1, 0.2),
		Position = UDim2.new(0.5, 1),
		AnchorPoint = Vector2.new(0.5, 1),

		[Children] = {
			VoteBarManager.leftVoteBar,
			VoteBarManager.rightVoteBar,
			VoteBarManager.middleVoteBar,
		}
		
	}
end

function VoteBarManager.splitVotes(listOfVotes: {[number] : string})
	local leftVotes = {}
	local rightVotes = {}

	for userId, voteSide in listOfVotes do
		if voteSide == Constants.VOTE_SIDES.LEFT then
			table.insert(leftVotes, userId)
		elseif voteSide == Constants.VOTE_SIDES.RIGHT then
			table.insert(rightVotes, userId)
		else
			warn("Unhandled vote at SplitVoteIcons", userId, voteSide)
		end
	end

	for index, userId in ipairs(leftVotes) do
		local thumbnail = playerThumbnails[userId]
		if not thumbnail then return end

		--[[
		local targetPos = leftVoteBar.getSlotPosition(index)

		]]

		thumbnail.updateSpring() -- to middle vote box relevant index
	end

	for index, userId in ipairs(rightVotes) do
		--[[
		local thumbnail = voteThumbnails.get(userId)
		if not thumbnail then return end

		thumbnail.shiftRight()		
		]]
	end

end

function VoteBarManager.restoreVotes()
	local step = 0
	for userId, thumbnail in playerThumbnails do
		step += 1
		thumbnail.updateSpring() -- to middleVoteBox.getSlotPositionFromIndex(step)
	end
end

function VoteBarManager.addThumbnail(player: Player)
	playerThumbnails[player.UserId] = PlayerThumbnail(scope, {
		player = player,
		hasSubmitted = hasSubmitted,
		targetX = nil,
		onClickCb = nil,
	})
end

-- Add a thumbnail when a new player joins
function VoteBarManager.onPlayerAdded(player: Player)
	VoteBarManager.addThumbnail(player)
end

-- Remove a thumbnail when a player leaves
function VoteBarManager.onPlayerLeft()

end

return VoteBarManager