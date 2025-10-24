--!strict

local AvatarEditorService = game:GetService("AvatarEditorService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))

-- Remotes
local PlayerDeletedTastemakerOutfit = Remotes:WaitForChild("PlayerDeletedTastemakerOutfit")
local PlayerPurchasedCurrentOutfit = Remotes:WaitForChild("PlayerPurchasedCurrentOutfit")
local PlayerSavedTastemakerOutfit = Remotes:WaitForChild("PlayerSavedTastemakerOutfit")
local PlayerResetOutfit = Remotes:WaitForChild("PlayerResetOutfit")

-- Variables
local currentlyResetting = false

--

local OutfitClientService = {}

function OutfitClientService.ResetPlayerOutfit(player: Player)
	if currentlyResetting then 
		warn("Already resetting!")
	end

	currentlyResetting = true

	local success, result = callWithRetry(
		function()	
			return PlayerResetOutfit:InvokeServer()
		end
	)

	currentlyResetting = false

	return result
end

function OutfitClientService.PurchasePlayerOutfit(player: Player): boolean
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local humanoidDescription = humanoid:GetAppliedDescription()
	
	local shoppingCart = {}

	for _, description in ipairs(humanoidDescription:GetChildren()) do
		if description:IsA("AccessoryDescription") and description.AssetId ~= 0 and not MarketplaceService:PlayerOwnsAsset(player, description.AssetId) then
			table.insert(shoppingCart, {
				["Type"] = Enum.MarketplaceProductType.AvatarAsset,
				["Id"] = tostring(description.AssetId)
			})
		elseif description:IsA("BodyPartDescription") and description.AssetId ~= 0 and not MarketplaceService:PlayerOwnsAsset(player, description.AssetId) then
			local success, assetDetails = callWithRetry(function()
				return MarketplaceService:GetProductInfo(description.AssetId, Enum.MarketplaceProductType.AvatarAsset)
			end)

			if not success or not assetDetails then
				continue
			end

			if not assetDetails["IsForSale"] then
				continue
			end
			
			-- TODO: We will probably have to disambiguate with dynamic heads etcee
			table.insert(shoppingCart, {
				["Type"] = Enum.MarketplaceProductType.AvatarAsset,
				["Id"] = tostring(description.AssetId)
			})

		end
	end

	for _, itemType in Constants.CLASSIC_HUMANOID_CLOTHING_ASSET_TYPES do
		local classicItemId = humanoidDescription[itemType] :: number
		if not table.find(Constants.DEFAULT_CLASSIC_CLOTHING_IDS_TABLE, classicItemId) and not MarketplaceService:PlayerOwnsAsset(player, classicItemId) then
			table.insert(shoppingCart, {
				["Type"] = Enum.MarketplaceProductType.AvatarAsset,
				["Id"] = tostring(classicItemId)
			})
		end
	end
	
	warn("Prompting purchase now!")
	if #shoppingCart == 0 then
		warn("No items to purchase!")
		return false
	else
		warn("purchasing with ", shoppingCart)
		return PlayerPurchasedCurrentOutfit:InvokeServer(shoppingCart)
	end
end



function OutfitClientService.SaveCurrentPlayerOutfit(player: Player)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local humanoidDescription = humanoid:GetAppliedDescription()
	
	for _, description in ipairs(humanoidDescription:GetChildren()) do
		if description:IsA("AccessoryDescription") or description:IsA("BodyPartDescription") and description.AssetId ~= 0 then
			if MarketplaceService:PlayerOwnsAsset(player, description.AssetId) then
				continue
			else
				PlayerSavedTastemakerOutfit:FireServer()
				-- do local outfit creation
				return
			end
		end
	end

	for _, itemType in Constants.CLASSIC_HUMANOID_CLOTHING_ASSET_TYPES do
		if not humanoidDescription[itemType] or table.find(Constants.DEFAULT_CLASSIC_CLOTHING_IDS_TABLE, humanoidDescription[itemType]) or MarketplaceService:PlayerOwnsAsset(player, humanoidDescription[itemType]) then
			continue
		else
			PlayerSavedTastemakerOutfit:FireServer()
			-- do local outfit creation
			return
		end
	end
	
	AvatarEditorService:PromptCreateOutfit(humanoidDescription, Enum.HumanoidRigType.R15)
end

function OutfitClientService.DeleteOutfit(outfitId: number)
	AvatarEditorService:PromptDeleteOutfit(outfitId)
	AvatarEditorService.PromptDeleteOutfitCompleted:Wait()
end

function OutfitClientService.DeleteTastemakerOutfit(outfitIndex: number)
	return PlayerDeletedTastemakerOutfit:InvokeServer(outfitIndex)
end

return OutfitClientService