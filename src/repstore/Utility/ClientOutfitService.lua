--!strict

local AvatarEditorService = game:GetService("AvatarEditorService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

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
local PlayerSavedInspectedOutfit = Remotes:WaitForChild("PlayerSavedInspectedOutfit")

-- Instances
local localPlayer = Players.LocalPlayer

--

local ClientOutfitService = {}

function ClientOutfitService.PurchasePlayerOutfit(): boolean
	local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local humanoidDescription = humanoid:GetAppliedDescription()
	
	local shoppingCart = {}

	for _, description in ipairs(humanoidDescription:GetChildren()) do
		if description:IsA("AccessoryDescription") and description.AssetId ~= 0 and not MarketplaceService:PlayerOwnsAsset(localPlayer, description.AssetId) then
			table.insert(shoppingCart, {
				["Type"] = Enum.MarketplaceProductType.AvatarAsset,
				["Id"] = tostring(description.AssetId)
			})
		elseif description:IsA("BodyPartDescription") and description.AssetId ~= 0 and not MarketplaceService:PlayerOwnsAsset(localPlayer, description.AssetId) then
			local success, assetDetails = callWithRetry(function()
				return MarketplaceService:GetProductInfo(description.AssetId, Enum.InfoType.Asset)
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
		if not table.find(Constants.DEFAULT_CLASSIC_CLOTHING_IDS_TABLE, classicItemId) and not MarketplaceService:PlayerOwnsAsset(localPlayer, classicItemId) then
			table.insert(shoppingCart, {
				["Type"] = Enum.MarketplaceProductType.AvatarAsset,
				["Id"] = tostring(classicItemId)
			})
		end
	end
	
	if #shoppingCart == 0 then
		warn("No items to purchase!")
		return false
	else
		local success = callWithRetry(function()  
			return PlayerPurchasedCurrentOutfit:InvokeServer(shoppingCart)
		end)
		return success
	end
end

function ClientOutfitService.SaveInspectedPlayerOutfit(inspectedPlayer: Player)
	PlayerSavedInspectedOutfit:FireServer(inspectedPlayer) 
end

function ClientOutfitService.SaveCurrentPlayerOutfit()
	local success = callWithRetry(function()
		return PlayerSavedTastemakerOutfit:FireServer()
	end)

	if success then
        StarterGui:SetCore("SendNotification", {
            Title = "Outfit Saved Successfully!",
            Text = "",
        })
	end

	-- The below code is commented out until we need to implement saving outfits via Roblox official API


	--local character = player.Character or player.CharacterAdded:Wait()
	--local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	--local humanoidDescription = humanoid:GetAppliedDescription()
	
	--[[
	for _, description in ipairs(humanoidDescription:GetChildren()) do
		if description:IsA("AccessoryDescription") or description:IsA("BodyPartDescription") and description.AssetId ~= 0 then
			if MarketplaceService:PlayerOwnsAsset(player, description.AssetId) then
				continue
			else
				-- do local outfit creation
				return
			end
		end
	end

	for _, itemType in Constants.CLASSIC_HUMANOID_CLOTHING_ASSET_TYPES do
		if not humanoidDescription[itemType] or humanoidDescription[itemType] <= 0 or table.find(Constants.DEFAULT_CLASSIC_CLOTHING_IDS_TABLE, humanoidDescription[itemType]) or MarketplaceService:PlayerOwnsAsset(player, humanoidDescription[itemType]) then
			continue
		else
			PlayerSavedTastemakerOutfit:FireServer()
			-- do local outfit creation
			return
		end
	end
	]]
	
	--AvatarEditorService:PromptCreateOutfit(humanoidDescription, Enum.HumanoidRigType.R15)
end

function ClientOutfitService.DeleteOutfit(outfitId: number)
	AvatarEditorService:PromptDeleteOutfit(outfitId)
	AvatarEditorService.PromptDeleteOutfitCompleted:Wait()
end

function ClientOutfitService.DeleteTastemakerOutfit(outfitIndex: number)
	return PlayerDeletedTastemakerOutfit:InvokeServer(outfitIndex)
end

return ClientOutfitService