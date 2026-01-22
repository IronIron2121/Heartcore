--!strict

-- Services
local ServerScriptService 		= game:GetService("ServerScriptService")
--local ReplicatedStorage 		= game:GetService("ReplicatedStorage")
--local DataStoreService 			= game:GetService("DataStoreService")
local Players 					= game:GetService("Players")

-- Folders
local DailyChallenges 	= ServerScriptService:WaitForChild("DailyChallenges")
local Voting 			= ServerScriptService:WaitForChild("Voting")
local Data 				= ServerScriptService:WaitForChild("Data")
--[[
local DataTables		= ReplicatedStorage:WaitForChild("DataTables")
local Trackers 			= ReplicatedStorage:WaitForChild("Trackers")
local Classes 			= ReplicatedStorage:WaitForChild("Classes")
local Remotes 			= ReplicatedStorage:WaitForChild("Remotes") 
]]

-- Module Scripts
local PlayerDisplayManager = require(ServerScriptService.Player.PlayerDisplayManager)
local PlayerVotedOutfitsTracker = require(Voting:WaitForChild("PlayerVotedOutfitsTracker"))
local ChallengeManager 			= require(DailyChallenges:WaitForChild("ChallengeManager"))
--[[
local Constants 				= require(ReplicatedStorage:WaitForChild("Constants")) 
local BuyableShopItems			= require(DataTables:WaitForChild("BuyableShopItems"))
local PlayerTracker 			= require(Trackers:WaitForChild("PlayerTracker"))
local PlayerDetails 			= require(Classes:WaitForChild("PlayerDetails"))
]]
local DataManager 				= require(Data:WaitForChild("DataManager"))

-- Datastores
--local ownedItemsDataStore		= DataStoreService:GetDataStore(Constants.OWNEDITEMS_DATASTORE)

-- Remotes / Bindables
--local UpdateLocalPlayerDetailsAsync = Remotes:WaitForChild("UpdateLocalPlayerDetails")

local function onCharacterAdded(player: Player, character: Model)
	warn("On character added!")
	local humanoid 		= character:WaitForChild("Humanoid") :: Humanoid
	humanoid.WalkSpeed 	= 32

	PlayerDisplayManager.AddRankDisplayToCharacter(player, character)
end

--[[
local function initialiseOwnedItemsDatastore(userId: number)
	-- Make sure the data is there
	local success, error = pcall(function()
		ownedItemsDataStore:UpdateAsync(tostring(userId), function(oldData)
			local playerOwnedItems = oldData or {}
			for itemName, itemDetails in pairs(BuyableShopItems) do
				local itemName = itemDetails["Name"]
				if not playerOwnedItems[itemName] then
					playerOwnedItems[itemName] = "false"
				else
					--print(itemName, "already added", playerOwnedItems[itemName])
				end
			end
			return playerOwnedItems					
		end)
	end)
	if not success then 
		warn("Failed to load owned items data for player ", userId)
		return 
	end
end
]]

local function onPlayerAdded(player: Player)
    repeat task.wait(0.1) until DataManager.Profiles[player]

	onCharacterAdded(player, player.Character or player.CharacterAdded:Wait())
	player.CharacterAdded:Connect(function(character: Model)  
		warn("Char added 1")
		onCharacterAdded(player, character)
	end)

	--[[
	local playerDetails = PlayerDetails.new(player)
	if playerDetails then
		PlayerTracker.startTrackingPlayer(playerDetails)
		UpdateLocalPlayerDetailsAsync:FireClient(player, playerDetails)
	else
		assert(playerDetails, "Failed to create player details")
	end
	initialiseOwnedItemsDatastore(player.UserId)
	]]

	PlayerVotedOutfitsTracker.OnPlayerAdded(player)
	ChallengeManager.InitialiseChallenges(player)
end


Players.PlayerAdded:Connect(onPlayerAdded)