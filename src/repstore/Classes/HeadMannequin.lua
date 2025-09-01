--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService	= game:GetService("InsertService")
local Players = game:GetService("Players")

-- Folders
local Classes = ReplicatedStorage:WaitForChild("Classes")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Templates = ReplicatedStorage:WaitForChild("Templates")

-- Modules
local stringOfNumbersToArray = require(Utility:WaitForChild("stringOfNumbersToArray")) 
local BaseMannequin = require(Classes:WaitForChild("BaseMannequin"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local Types = require(Utility:WaitForChild("Types"))

local SerialisationUtilities = require(Utility:WaitForChild("SerialisationUtilities"))
local unserialiseCFrame = SerialisationUtilities.unserialiseCFrame

-- Templates
local HeadMannequinTemplate = Templates:WaitForChild("HeadMannequin")

local HeadMannequin = setmetatable({}, BaseMannequin)
HeadMannequin.__index = HeadMannequin

function HeadMannequin.new(shopItemRecipe : Types.ShopItemRecipe) 
	local newHeadMannequin = BaseMannequin.new(shopItemRecipe)
	setmetatable(newHeadMannequin, HeadMannequin) 
	newHeadMannequin.instance = newHeadMannequin:initialiseInstance(shopItemRecipe) :: Types.HeadMannequinTemplate
	newHeadMannequin:_initialiseAccessories()

	return newHeadMannequin
end

-- TODO: Refactor this, simplify simplify simplify
function HeadMannequin:initialiseInstance(shopItemRecipe : Types.ShopItemRecipe) : Types.HeadMannequinTemplate
	local instance =  HeadMannequinTemplate:Clone() :: Types.HeadMannequinTemplate
	instance:PivotTo(unserialiseCFrame(shopItemRecipe.itemCFrame) )
 
	-- TODO: This is hacky	
	if shopItemRecipe.itemAttributes then 
		for attributeName, attributeValue in pairs(shopItemRecipe.itemAttributes) do
			instance:SetAttribute(attributeName, attributeValue) 
		end
	end

	return instance
end

function HeadMannequin:addAccessory(accessoryId : number)
	local thisAsset = InsertService:LoadAsset(accessoryId)
	thisAsset = thisAsset:FindFirstChildWhichIsA("Accessory")
	if not thisAsset then
		warn("No accessory found in asset!")
		return
	end
	
	self.instance.Humanoid:AddAccessory(thisAsset)
	thisAsset:SetAttribute(Constants.ACCESSORY_ID_ATTRIBUTE, accessoryId)
	self:_addAssetIdToInstance(accessoryId)
end

function HeadMannequin:removeAccessory(accessoryId : number)
	if not self.instance then
		warn("No instance!")
		return
	end
	
	for _, child in ipairs(self.instance:GetChildren()) do
		if child:IsA("Accessory") and child:GetAttribute(Constants.ACCESSORY_ID_ATTRIBUTE) == accessoryId then
			child:Destroy()
			self:removeAssetIdFromInstance(accessoryId)
		end
	end
	
end

function HeadMannequin:_initialiseAccessories()
	if not self.instance then 
		warn("No instance!")
		return
	end
	local accessoryIdsString = self.instance:GetAttribute(Constants.MANNEQUIN_ACCESSORY_IDS_ATTRIBUTE)
	local accessoryIds 	= stringOfNumbersToArray(accessoryIdsString)
	for _, id in accessoryIds do
		self:addAccessory(id)
	end
end

return HeadMannequin