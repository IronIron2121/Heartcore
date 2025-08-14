--!strict

-- Services
local ReplicatedStorage 		  	= game:GetService("ReplicatedStorage")
local Players 					  	= game:GetService("Players")

-- Folders
local BindablesFolder 			  	= ReplicatedStorage:WaitForChild("Bindables")
local LibrariesFolder				= ReplicatedStorage:WaitForChild("Libraries")
local TemplatesFolder 				= ReplicatedStorage:WaitForChild("Templates")
local GettersFolder					= ReplicatedStorage:WaitForChild("Getters")
local UIFolder 					  	= ReplicatedStorage:WaitForChild("UI")
local ComponentsFolder 			  	= UIFolder:WaitForChild("Components")

-- Bindables / Remotes
local PlayerClickedPlayerBindable 	= BindablesFolder:WaitForChild("PlayerClickedPlayer")

-- Player and Player GUI Elements
local localPlayer 				  	= Players.LocalPlayer
local playerGui   				  	= localPlayer.PlayerGui
local PlayerClickGui   			  	= playerGui:WaitForChild("PlayerClickGui")
local PlayerFrame 	   			  	= PlayerClickGui:WaitForChild("PlayerFrame")
local MutableElementsFolder 		= PlayerFrame:WaitForChild("MutableElements")
local PreviewFrame 					= MutableElementsFolder:WaitForChild("PreviewFrame")
local PreviewLabel 					= PreviewFrame:WaitForChild("PreviewLabel")
local RigFrame 						= PreviewLabel:WaitForChild("RigFrame")
local OptionsFrame 					= MutableElementsFolder:WaitForChild("OptionsFrame")

local WorldModel 					= RigFrame:WaitForChild("WorldModel")
local PreviewRig					= WorldModel:WaitForChild("PreviewRig")

-- GUI Elements
local ImmutableElementsFolder 		= PlayerFrame:WaitForChild("ImmutableElements")
local closeButton 	   			  	= ImmutableElementsFolder:WaitForChild("CloseButton")

-- Module Scripts
local ItemTile 				   		= require(ComponentsFolder:WaitForChild("ItemTile"))
local ItemDetailsCache 		   		= require(ReplicatedStorage.Libraries.ItemDetailsCache)

local getListOfAccessoryIdsFromPlayer = require(GettersFolder:WaitForChild("getListOfAccessoryIdsFromPlayer"))


-- TODO: Find a solution to this that's a lot more efficient
local constantElements = {
	"CloseButton",
	"PreviewFrame",
	"OptionsFrame",
	"OutfitFrame",
	"UIGridLayout",
	"UIListLayout"
}

local inconstantElements = {
	"OptionsFrame",
}

-- Module scripts
local getPlayerFromPlayerName 		= require(GettersFolder:WaitForChild("getPlayerFromPlayerName"))
local TeleportButton 			  	= require(ComponentsFolder:WaitForChild("TeleportButton"))
local ModalManager 			   	  	= require(LibrariesFolder:WaitForChild("ModalManager"))

-- Templates
local PreviewRigTemplate 			= TemplatesFolder:WaitForChild("PreviewRig")

-- Copy the player's rig to the PreviewRig
local function updatePreviewRig(player: Player)
	-- Get character from player
	local character = player.Character or player.CharacterAdded:Wait()
	if not character then return end
	
	-- Create a copy of player's rig
	character.Archivable = true
	local newRig = character:Clone()
	character.Archivable = false
	
	-- Send the clone to GUI World Model
	newRig:PivotTo(PreviewRig:GetPivot())
	newRig.Parent = WorldModel
	
	-- Destroy and re-assign PreviewRig
	PreviewRig:Destroy()
	PreviewRig = newRig
end

local function resetPreviewRig()
	local newRig = PreviewRigTemplate:Clone()
	newRig.Parent = WorldModel
	PreviewRig:Destroy()
	PreviewRig = newRig
	-- Destroy all accessories
	for _, accessory in pairs(PreviewRig:GetChildren()) do
		if accessory:IsA("Accessory") then
			accessory:Destroy()
		end
	end
end

local function clearOutfitTiles()
	print("Clearing...")
	for _, child in outfitFrame:GetChildren() do
		if not table.find(constantElements, child.Name) then
			child:Destroy()
		end
	end
end

-- Fills the outfit frame with purchasable/try-on-able ItemTiles for the clicked player's outfit
local function populateOutfitFrame(clickedPlayer: Player)
	local playerOutfits = getListOfAccessoryIdsFromPlayer(clickedPlayer)
	if not playerOutfits then return end
	
	for _, accessoryId in playerOutfits do
		local assetDetails = ItemDetailsCache.getAssetDetailsAsync(accessoryId)
		if not assetDetails then
			continue
		end

		local itemTile = ItemTile(assetDetails)
		itemTile.Parent = outfitFrame
	end
end

-- Destroys all inconstant items when closing the GUI
local function destroyMutables()
	for _, descendant in pairs(OptionsFrame:GetDescendants()) do
		if not table.find(constantElements, descendant.Name) then
			print(descendant)
			descendant:Destroy()
		end
	end
end

-- Sets up the player inspect GUI on clicking another player
local function playerClickedAsync(playerName: string)
	-- Make the playerGUI visible
	-- TODO: Make sure there are no errors whith clicking multiple players
	-- Include some kind of error checking for when players leave mid-view?
	clearOutfitTiles()
	destroyMutables()
	ModalManager.push(PlayerFrame)

	-- Update rig and get outfit
	local clickedPlayer = getPlayerFromPlayerName(playerName) 
	if not clickedPlayer then return end
	updatePreviewRig(clickedPlayer)
	populateOutfitFrame(clickedPlayer)
	
	-- Create teleport button if player has a shop
	local teleportButton = TeleportButton(localPlayer, clickedPlayer)
	if not teleportButton then return end
	
	teleportButton.Parent = OptionsFrame	
end


local function closeButtonPressed()
	ModalManager.pop(PlayerFrame)
end

PlayerClickedPlayerBindable.Event:Connect(playerClickedAsync)
closeButton.Activated:Connect(closeButtonPressed)