--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService 	= game:GetService("DataStoreService")

-- Folders
local Templates = ReplicatedStorage:WaitForChild("Templates")
local Utility 	= ReplicatedStorage:WaitForChild("Utility")
local Getters	= ReplicatedStorage:WaitForChild("Getters")


-- Utilities / Module Scripts
local getMannequinFromId 		= require(Getters:WaitForChild("getMannequinFromId"))
local SerialisationUtilities	= require(Utility:WaitForChild("SerialisationUtilities"))
local serialiseAttributes 		= SerialisationUtilities.serialiseAttributes
local serialiseCFrame   		= SerialisationUtilities.serialiseCFrame
local Types 					= require(Utility:WaitForChild("Types"))
local Constants					= require(ReplicatedStorage:WaitForChild("Constants")) 
local stringOfNumbersToArray = require(Utility:WaitForChild("stringOfNumbersToArray")) 

local getRelativePosition 		= require(Utility:WaitForChild("getRelativePosition"))

-- Datastores
local playerShopsDataStore 	= DataStoreService:GetDataStore(Constants.PLAYER_SHOPS_DATA_STORE_NAME)

local MannequinUtilities = {}

function MannequinUtilities.getBundleIdArray(instance : Model) : {number} ?
	local bundleIdsString = instance:GetAttribute(Constants.BUNDLE_IDS_ATTRIBUTE) :: string
	local bundleIdArray = stringOfNumbersToArray(bundleIdsString)
	return bundleIdArray
end

function MannequinUtilities.getAccessoryIdArray(instance : Model) : {number} ?
	local accessoryIdsString = instance:GetAttribute(Constants.MANNEQUIN_ACCESSORY_IDS_ATTRIBUTE) :: string
	local accessoryIdArray = stringOfNumbersToArray(accessoryIdsString)
	return accessoryIdArray
end


return MannequinUtilities
