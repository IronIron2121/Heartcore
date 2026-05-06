--!strict
-- VoteBarManager/init.luau
-- Right-side HUD panel showing circular player thumbnails with reactive status.

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local VoteBar = require(script.VoteBar)
local Constants = require(ReplicatedStorage.Constants)
local GuiManager = require(ReplicatedStorage.Libraries.GuiManager.GuiManager)
local MODAL_NAMES = require(ReplicatedStorage.Libraries.GuiManager.MODAL_NAMES)
local Fusion = require(Utility:WaitForChild("Fusion"))
local PlayerThumbnail = require(script:WaitForChild("PlayerThumbnail")) 

-- Fusion
local Children = Fusion.Children
local scope = Fusion:scoped()

-- Values
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

for _, player in Players:GetPlayers() do
	connectPlayerAttributes(player)
end

--

local maxPlayers = 8
local playerThumbnails: {[number] : any} = {}

local VoteBarManager = {}


function VoteBarManager.initialise()
	local slotSize = UDim2.fromScale(1 / (maxPlayers + 2), 10)

	VoteBarManager.leftVoteBar = VoteBar(scope, {
		name = "LeftVoteBar",
		position = UDim2.fromScale(0, 1),
		backgroundColor = Color3.new(0,0,255),
		size = UDim2.fromScale(0.25, 1),
		anchorPoint = Vector2.new(0, 1),
		justification = 'left',
		maxSlots = maxPlayers,
		slotSize = slotSize,
		padding = 0.05
	})

	VoteBarManager.rightVoteBar = VoteBar(scope, {
		name = "RightVoteBar",
		backgroundColor = Color3.new(255,0,0),
		position = UDim2.fromScale(1, 1),
		size = UDim2.fromScale(0.25, 1),
		anchorPoint = Vector2.new(1, 1),
		justification = 'right',
		maxSlots = maxPlayers,
		slotSize = slotSize,
		padding = 0.05
	})

	VoteBarManager.middleVoteBar = VoteBar(scope, {
		name = "RightVoteBar",
		backgroundColor = Color3.new(0,255,0),
		position = UDim2.fromScale(0.5, 1),
		size = UDim2.fromScale(0.5, 1),
		anchorPoint = Vector2.new(0.5, 1.0),
		justification = 'middle',
		maxSlots = maxPlayers,
		slotSize = slotSize,
		padding = 0.05
	})

	local voteBarContainer = scope:New "Frame" {
		Name = "VoteBarContainer",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0.5, 1),
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundTransparency = 1,

		[Children] = {
			VoteBarManager.leftVoteBar.voteBarFrame,
			VoteBarManager.rightVoteBar.voteBarFrame,
			VoteBarManager.middleVoteBar.voteBarFrame,
		}
	} :: Frame

	return voteBarContainer
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

		local targetPos = VoteBarManager.leftVoteBar.getSlotPosition(index)
		thumbnail.updateSpring(targetPos) -- to middle vote box relevant index
	end

	for index, userId in ipairs(rightVotes) do
		local thumbnail = playerThumbnails[userId]
		if not thumbnail then return end

		local targetPos = VoteBarManager.rightVoteBar.getSlotPosition(index)
		thumbnail.updateSpring(targetPos) -- to middle vote box relevant index	
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
	--[[
		if in splitting:
			wait for splitting to end
		else	
	]]
	local numPlayers = #Players:GetPlayers()
	playerThumbnails[player.UserId] = PlayerThumbnail(scope, {
		player = player,
		hasSubmitted = hasSubmitted,
		targetPos = VoteBarManager.middleVoteBar.getSlotPosition(numPlayers),
		onClickCb = function()
			GuiManager.PushCentreByName(MODAL_NAMES.PLAYER_INSPECT_GUI, {
				player = player,
				rig = nil
			})
		end, 
	})
end

-- Add a thumbnail when a new player joins
function VoteBarManager.onPlayerAdded(player: Player)
	VoteBarManager.addThumbnail(player)
	connectPlayerAttributes(player)
end

-- Remove a thumbnail when a player leaves
function VoteBarManager.onPlayerRemoved(player: Player)
	disconnectPlayerAttributes(player)
end


Players.PlayerAdded:Connect(VoteBarManager.onPlayerAdded)

Players.PlayerRemoving:Connect(VoteBarManager.onPlayerRemoved)

return VoteBarManager