--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Folders
local Templates = ReplicatedStorage:WaitForChild("Templates")
local Classes = ReplicatedStorage:WaitForChild("Classes")
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local applyItemsToDescriptionAsync 	= require(Utility:WaitForChild("applyItemsToDescriptionAsync"))
local setDescriptionSkinColor = require(Utility:WaitForChild("setDescriptionSkinColor"))
local stringOfNumbersToArray = require(Utility:WaitForChild("stringOfNumbersToArray")) 
local arrayOfNumbersToString = require(Utility:WaitForChild("arrayOfNumbersToString"))
local BaseMannequin = require(Classes:WaitForChild("BaseMannequin"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local Types = require(Utility:WaitForChild("Types"))
local SerialisationUtilities = require(Utility:WaitForChild("SerialisationUtilities"))
local getGroundYFromRay = require(Utility:WaitForChild("getGroundYFromRay"))
local MarketplaceUtilities = require(Utility:WaitForChild("MarketplaceUtilities"))



-- Templates
local FullMannequinTemplate = Templates:WaitForChild("FullMannequin")

local FullMannequin = setmetatable({}, BaseMannequin)
FullMannequin.__index = FullMannequin

-- TODO - tidy this expeditiously
local function initialiseRigDescription(mannequin: Instance)
	-- Get list of items to apply to mannequin
	local accessoryIdsString 	= mannequin:GetAttribute(Constants.MANNEQUIN_ACCESSORY_IDS_ATTRIBUTE)
	local bundleIdsString 		= mannequin:GetAttribute(Constants.MANNEQUIN_BUNDLE_IDS_ATTRIBUTE)
	local skinColor 			= mannequin:GetAttribute(Constants.SKIN_COLOR_ATTRIBUTE)

	local accessoryIds 	= stringOfNumbersToArray(accessoryIdsString)
	local bundleIds 	= stringOfNumbersToArray(bundleIdsString)

	-- Create a new humanoid description for this mannequin and apply given items to it
	local description = Instance.new("HumanoidDescription")
	description = setDescriptionSkinColor(description, skinColor)
	description = applyItemsToDescriptionAsync(description, accessoryIds, bundleIds, true)
	

	return description
end

function FullMannequin.new(shopItemRecipe : Types.ShopItemRecipe) 
	local newFullMannequin = BaseMannequin.new(shopItemRecipe)
	setmetatable(newFullMannequin, FullMannequin) 
	newFullMannequin.instance = newFullMannequin:initialiseInstance(shopItemRecipe)
	
	return newFullMannequin
end

function FullMannequin.load(ShopItemRecipe : Types.ShopItemRecipe) 
	
end 

-- TODO: Refactor this, simplify simplify simplify
function FullMannequin:initialiseInstance(shopItemRecipe : Types.ShopItemRecipe)
	local instance =  FullMannequinTemplate:Clone() :: Types.FullMannequinTemplate
	
	-- TODO: This is hacky	
	if shopItemRecipe.itemAttributes then 
		for attributeName, attributeValue in pairs(shopItemRecipe.itemAttributes) do
			instance:SetAttribute(attributeName, attributeValue) 
		end
	else
		print("No Attributes! at", shopItemRecipe)
	end
	
	instance.Base.CFrame = SerialisationUtilities.unserialiseCFrame(shopItemRecipe.itemCFrame) 
	
	if not instance:GetAttribute("initialised") then
		instance.Base.Position = Vector3.new(
			instance.Base.Position.X, 
			instance.Base.Position.Y --[[- instance.Placeholder.Size.Y / 2]],  -- The base needs be in contact with the ground as it defines the mannequin's position
			instance.Base.Position.Z
		)
		
		instance:SetAttribute("initialised", true)
	end
	
	local base = instance:FindFirstChild("Base")
	assert(base and base:IsA("BasePart"), `{instance:GetFullName()} is missing a Base`)

	local description = initialiseRigDescription(instance)

	-- Create a new rig from the HumanoidDescription we just created
	local rig = Players:CreateHumanoidModelFromDescription(
		description,
		Enum.HumanoidRigType.R15,
		Enum.AssetTypeVerification.Always
	) :: Types.MannequinRig
	
	--print("HipHeight BEFORE setting scales:", rig.Humanoid.HipHeight)

	-- This rig includes an animation script by default, which we need to remove
	for _, descendant in rig:GetDescendants() do
		if descendant:IsA("Script") then
			descendant:Destroy()
		end
	end

	rig.Name 	= "Rig"
	rig.Parent 	= instance
	rig.Humanoid.BodyProportionScale.Value 	= instance:GetAttribute(Constants.BODY_PROPORTION_SCALE_ATTRIBUTE) or 1
	rig.Humanoid.BodyHeightScale.Value 		= instance:GetAttribute(Constants.BODY_HEIGHT_SCALE_ATTRIBUTE) or 1
	rig.Humanoid.BodyDepthScale.Value 		= instance:GetAttribute(Constants.BODY_DEPTH_SCALE_ATTRIBUTE) or 1
	rig.Humanoid.BodyWidthScale.Value 		= instance:GetAttribute(Constants.BODY_WIDTH_SCALE_ATTRIBUTE) or 1
	rig.Humanoid.BodyTypeScale.Value 		= instance:GetAttribute(Constants.BODY_TYPE_SCALE_ATTRIBUTE) or 1
	rig.Humanoid.HeadScale.Value 			= instance:GetAttribute(Constants.HEAD_SCALE_ATTRIBUTE) or 1
	rig.Humanoid.DisplayDistanceType 		= Enum.HumanoidDisplayDistanceType.None
	rig.HumanoidRootPart.Anchored 			= true
	

	-- We need to use hip height otherwise the rig ends up being buried in the ground
	local targetHipHeight = 2.6423325538635254 -- Use your preferred height

	-- TODO: This is an ugly workaround but I do not have time to wait for roblox to start working properly again
	-- Refer to tastemakers 4 where, with the exacty same code, the above floating point value is received
	--local height = rig.Humanoid.HipHeight + rig.HumanoidRootPart.Size.Y * 0.5
	local height = targetHipHeight + rig.HumanoidRootPart.Size.Y * 0.5
	
	rig:PivotTo(base.CFrame * CFrame.new(0, height, 0))

	-- Play the pose animation if one is set
	local poseAnimationId = instance:GetAttribute(Constants.POSE_ANIMATION_ATTRIBUTE)
	if poseAnimationId ~= nil and poseAnimationId ~= "" then
		local animation 		= Instance.new("Animation")
		animation.Name 			= "PoseAnimation"
		animation.AnimationId 	= poseAnimationId
		animation.Parent 		= rig

		local animationTrack 	= rig.Humanoid.Animator:LoadAnimation(animation)
		animationTrack:Play()
	end

	-- Remove the placeholder mannequin if there is one
	local placeholder = instance:FindFirstChild("Placeholder")
	if placeholder then
		placeholder:Destroy()
	end	
	
	return instance
end

local function copyAttributesToNewMannequin(oldMannequin, newMannequin)
	for ATTRIBUTE_NAME, ATTRIBUTE_VALUE in oldMannequin:GetAttributes() do
		newMannequin:SetAttribute(ATTRIBUTE_NAME, ATTRIBUTE_VALUE)
	end

	return newMannequin
end

function FullMannequin:reinstantiate()
	local newInstance =  FullMannequinTemplate:Clone() :: Types.FullMannequinTemplate
	newInstance = copyAttributesToNewMannequin(self.instance, newInstance)

	newInstance:PivotTo(self.instance:GetPivot()) 
	newInstance.Parent = self.instance.Parent

	self.instance:Destroy()
	self.instance = newInstance

	newInstance.Base.Position = Vector3.new(
		newInstance.Base.Position.X, 
		newInstance.Base.Position.Y,  -- The base needs be in contact with the ground as it defines the mannequin's position
		newInstance.Base.Position.Z
	)

	local base = newInstance:FindFirstChild("Base")
	assert(base and base:IsA("BasePart"), `{newInstance:GetFullName()} is missing a Base`)

	local description = initialiseRigDescription(newInstance)

	-- Create a new rig from the HumanoidDescription we just created
	local rig = Players:CreateHumanoidModelFromDescription(
		description,
		Enum.HumanoidRigType.R15,
		Enum.AssetTypeVerification.Always
	) :: Types.MannequinRig

	-- Add this after creating the rig but before setting scales
	print("HipHeight BEFORE setting scales:", rig.Humanoid.HipHeight)

	-- This rig includes an animation script by default, which we need to remove
	for _, descendant in rig:GetDescendants() do
		if descendant:IsA("Script") then
			descendant:Destroy()
		end
	end

	rig.Name 	= "Rig"
	rig.Parent 	= newInstance
	rig.Humanoid.BodyProportionScale.Value 	= newInstance:GetAttribute(Constants.BODY_PROPORTION_SCALE_ATTRIBUTE) or 1
	rig.Humanoid.BodyHeightScale.Value 		= newInstance:GetAttribute(Constants.BODY_HEIGHT_SCALE_ATTRIBUTE) or 1
	rig.Humanoid.BodyDepthScale.Value 		= newInstance:GetAttribute(Constants.BODY_DEPTH_SCALE_ATTRIBUTE) or 1
	rig.Humanoid.BodyWidthScale.Value 		= newInstance:GetAttribute(Constants.BODY_WIDTH_SCALE_ATTRIBUTE) or 1
	rig.Humanoid.BodyTypeScale.Value 		= newInstance:GetAttribute(Constants.BODY_TYPE_SCALE_ATTRIBUTE) or 1
	rig.Humanoid.HeadScale.Value 			= newInstance:GetAttribute(Constants.HEAD_SCALE_ATTRIBUTE) or 1
	rig.Humanoid.DisplayDistanceType 		= Enum.HumanoidDisplayDistanceType.None
	rig.HumanoidRootPart.Anchored 			= true


	-- We need to use hip height otherwise the rig ends up being buried in the ground
	local targetHipHeight = 2.6423325538635254 -- Use your preferred height

	-- TODO: This is an ugly workaround but I do not have time to wait for roblox to start working properly again
	-- Refer to tastemakers 4 where, with the exacty same code, the above floating point value is received
	--local height = rig.Humanoid.HipHeight + rig.HumanoidRootPart.Size.Y * 0.5
	local height = targetHipHeight + rig.HumanoidRootPart.Size.Y * 0.5

	rig:PivotTo(base.CFrame * CFrame.new(0, height, 0))

	-- Play the pose animation if one is set
	local poseAnimationId = newInstance:GetAttribute(Constants.POSE_ANIMATION_ATTRIBUTE)
	if poseAnimationId ~= nil and poseAnimationId ~= "" then
		local animation 		= Instance.new("Animation")
		animation.Name 			= "PoseAnimation"
		animation.AnimationId 	= poseAnimationId
		animation.Parent 		= rig

		local animationTrack 	= rig.Humanoid.Animator:LoadAnimation(animation)
		animationTrack:Play()
	end

	-- Remove the placeholder mannequin if there is one
	local placeholder = newInstance:FindFirstChild("Placeholder")
	if placeholder then
		placeholder:Destroy()
	end	

end

-- TODO: Separate concerns
function FullMannequin:removeAccessory(accessoryId : number)
	self:_removeAssetIdFromInstance(accessoryId)
	self:reinstantiate()
	return true
end


function FullMannequin:addAccessory(accessoryId : number)
	self:_addAssetIdToInstance(accessoryId)
	self:reinstantiate()
end

local MannequinUtilities = require(Utility:WaitForChild("MannequinUtilities"))


return FullMannequin