--!strict

-- Services
local ReplicatedStorage 		= game:GetService("ReplicatedStorage")
local DataStoreService 			= game:GetService("DataStoreService")
local InsertService 			= game:GetService("InsertService")
local Players 					= game:GetService("Players")

-- Local Player
local localPlayer				= Players.LocalPlayer

-- FOlders
local LibrariesFolder			= ReplicatedStorage:WaitForChild("Libraries")
local UtilityFolder 			= ReplicatedStorage:WaitForChild("Utility")
local RemotesFolder 			= ReplicatedStorage:WaitForChild("Remotes")

-- Remotes
local SavePlayerBaseModelRemote = RemotesFolder:WaitForChild("SavePlayerBaseModel")

-- Module Scripts
local arrayOfNumbersToString 	= require(UtilityFolder.arrayOfNumbersToString)
local SerialisationUtilities	= require(UtilityFolder.SerialisationUtilities)
local Constants 				= require(ReplicatedStorage.Constants) 
local TryOn						= require(LibrariesFolder.TryOn)

-- Functions
local serialiseHumanoidDescription 		= SerialisationUtilities.serialiseHumanoidDescription
local deSerialiseHumanoidDescription 	= SerialisationUtilities.deSerialiseHumanoidDescription


-- Adds player clothing to our in-game inventory system
local function makePlayerClothingRemovable(player: Player)
	local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
	local humanoid = char:WaitForChild("Humanoid") :: Humanoid

	local clothingTable = {} 
	local humanoidDescription = humanoid:GetAppliedDescription() :: HumanoidDescription

	for index, attribute in pairs(Constants.HUMANOID_ACCESSORY_ATTRIBUTES) do
		local accessoryId = tonumber((humanoidDescription :: any)[attribute])

		-- Dynamic access is okay here as we know beforehand that these attributes are constant
		if accessoryId ~= 0 and accessoryId ~= nil then
			table.insert(clothingTable, {id = accessoryId, type = Enum.MarketplaceProductType.AvatarAsset})

			if typeof((humanoidDescription :: any)[attribute]) 		== "number" then
				(humanoidDescription :: any)[attribute] = 0

			elseif typeof((humanoidDescription :: any)[attribute]) 	== "string" then 
				(humanoidDescription :: any)[attribute] = ""

			end 
		end
	end

	local playerSaved = SavePlayerBaseModelRemote:InvokeServer(serialiseHumanoidDescription(humanoidDescription))

	-- Register player clothes with equip/un-equip system
	TryOn.setItemsAsync(clothingTable)

end

local function initialise()
	--makePlayerClothingRemovable(localPlayer)
end

initialise()