--!strict
-- VoteBarManager/init.luau
-- Bottom HUD panel showing circular player thumbnails moving between vote bars.

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

-- Constants
local MAX_PLAYERS = 8
local SLOT_SIZE = UDim2.fromScale(1 / (MAX_PLAYERS + 2), 1)
local THUMBNAIL_SIZE = UDim2.fromScale(0.045, 0.45)
local VOTE_BAR_PADDING = 0.02

local playerThumbnails: {[string]: any} = {}

local VoteBarManager = {}

local function getSortedPlayers(): {Player}
	local players = Players:GetPlayers()
	table.sort(players, function(left, right)
		return left.UserId < right.UserId
	end)
	return players
end

local function createInspectCallback(player: Player): () -> ()
	return function()
		GuiManager.PushCentreByName(MODAL_NAMES.PLAYER_INSPECT_GUI, {
			player = player,
			rig = nil,
		})
	end
end

local function getPlayerSlotIndex(player: Player): number
	for index, currentPlayer in ipairs(getSortedPlayers()) do
		if currentPlayer == player then
			return index - 1
		end
	end

	return 0
end

local function createThumbnail(player: Player, slotIndex: number)
	if playerThumbnails[tostring(player.UserId)] then
		return
	end

	if not VoteBarManager.voteBarContainer or not VoteBarManager.middleVoteBar then
		return
	end

	playerThumbnails[tostring(player.UserId)] = PlayerThumbnail(scope, {
		player = player,
		targetSlot = VoteBarManager.middleVoteBar.getSlotPosition(slotIndex),
		size = THUMBNAIL_SIZE,
		parent = VoteBarManager.voteBarContainer,
		onClickCb = createInspectCallback(player),
	})
end

function VoteBarManager.initialise()
	if VoteBarManager.voteBarContainer then
		return VoteBarManager.voteBarContainer
	end

	VoteBarManager.leftVoteBar = VoteBar(scope, {
		name = "LeftVoteBar",
		position = UDim2.fromScale(0, 1),
		backgroundColor = Color3.fromRGB(0, 0, 255),
		size = UDim2.fromScale(0.25, 1),
		anchorPoint = Vector2.new(0, 1),
		justification = "left",
		maxSlots = MAX_PLAYERS,
		slotSize = SLOT_SIZE,
		padding = VOTE_BAR_PADDING,
	})

	VoteBarManager.rightVoteBar = VoteBar(scope, {
		name = "RightVoteBar",
		backgroundColor = Color3.fromRGB(255, 0, 0),
		position = UDim2.fromScale(1, 1),
		size = UDim2.fromScale(0.25, 1),
		anchorPoint = Vector2.new(1, 1),
		justification = "right",
		maxSlots = MAX_PLAYERS,
		slotSize = SLOT_SIZE,
		padding = VOTE_BAR_PADDING,
	})

	VoteBarManager.middleVoteBar = VoteBar(scope, {
		name = "MiddleVoteBar",
		backgroundColor = Color3.fromRGB(0, 255, 0),
		position = UDim2.fromScale(0.5, 1),
		size = UDim2.fromScale(0.5, 1),
		anchorPoint = Vector2.new(0.5, 1),
		justification = "middle",
		maxSlots = MAX_PLAYERS,
		slotSize = SLOT_SIZE,
		padding = VOTE_BAR_PADDING,
	})

	VoteBarManager.voteBarContainer = scope:New "Frame" {
		Name = "VoteBarContainer",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0.5, 1),
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundTransparency = 1,

		[Children] = {
			VoteBarManager.leftVoteBar.voteBarFrame,
			VoteBarManager.rightVoteBar.voteBarFrame,
			VoteBarManager.middleVoteBar.voteBarFrame,
		},
	} :: Frame

	for index, player in ipairs(getSortedPlayers()) do
		createThumbnail(player, index - 1)
	end

	return VoteBarManager.voteBarContainer
end

function VoteBarManager.splitVotes(listOfVotes: {[number]: string})
	if not VoteBarManager.leftVoteBar or not VoteBarManager.rightVoteBar then
		return
	end

	local leftVotes = {}
	local rightVotes = {}

	print("Splitting vote icons", listOfVotes)

	for userId, voteSide in listOfVotes do
		if voteSide == Constants.VOTE_SIDES.LEFT then
			table.insert(leftVotes, userId)
		elseif voteSide == Constants.VOTE_SIDES.RIGHT then
			table.insert(rightVotes, userId)
		else
			warn("Unhandled vote at SplitVoteIcons", userId, voteSide)
		end
	end

	table.sort(leftVotes)
	table.sort(rightVotes)

	for index, userId in ipairs(leftVotes) do
		local thumbnail = playerThumbnails[tostring(userId)]
		if not thumbnail then
			warn("No thumbnail for player ", userId, "!")
			print(playerThumbnails)
			continue
		end

		thumbnail.updateSpring(VoteBarManager.leftVoteBar.getSlotPosition(index - 1))
	end

	for index, userId in ipairs(rightVotes) do
		local thumbnail = playerThumbnails[tostring(userId)]
		if not thumbnail then
			warn("No thumbnail for player ", userId, "!")
			continue
		end

		thumbnail.updateSpring(VoteBarManager.rightVoteBar.getSlotPosition(index - 1))
	end
end

function VoteBarManager.restoreVotes()
	if not VoteBarManager.middleVoteBar then
		return
	end

	for index, player in ipairs(getSortedPlayers()) do
		local thumbnail = playerThumbnails[tostring(player.UserId)]
		if not thumbnail then
			continue
		end

		thumbnail.updateSpring(VoteBarManager.middleVoteBar.getSlotPosition(index - 1))
	end
end

function VoteBarManager.addThumbnail(player: Player)
	createThumbnail(player, getPlayerSlotIndex(player))
	VoteBarManager.restoreVotes()
end

function VoteBarManager.onPlayerAdded(player: Player)
	VoteBarManager.addThumbnail(player)
end

function VoteBarManager.onPlayerRemoved(player: Player)
	local thumbnail = playerThumbnails[tostring(player.UserId)]
	if thumbnail then
		thumbnail.destroy()
		playerThumbnails[tostring(player.UserId)] = nil
	end

	task.defer(VoteBarManager.restoreVotes)
end

Players.PlayerAdded:Connect(VoteBarManager.onPlayerAdded)
Players.PlayerRemoving:Connect(VoteBarManager.onPlayerRemoved)

return VoteBarManager
