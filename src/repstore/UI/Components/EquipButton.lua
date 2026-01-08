--!strict

--[[
	EquipButton - This function acts as a simple UI component, implementing a UI button that displays
	an item icon. When clicked, it adds an accessory to a mannequin
--]]


--[[
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Folders
local BindablesFolder = ReplicatedStorage:WaitForChild("Bindables")
local UtilityFolder = ReplicatedStorage:WaitForChild("Utility")
local GettersFolder = ReplicatedStorage:WaitForChild("Getters")
local CheckersFolder = ReplicatedStorage:WaitForChild("Checkers")
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local UIFolder = ReplicatedStorage:WaitForChild("UI")
local ObjectsFolder = UIFolder:WaitForChild("Objects")

-- Instances
local localPlayer = Players.LocalPlayer

-- Module Scripts
local doesMannequinHaveAssetEquipped = require(CheckersFolder:WaitForChild("doesMannequinHaveAssetEquipped"))
local ItemContainer = require(UtilityFolder:WaitForChild("ItemContainer"))
local getItemIcon = require(UtilityFolder:WaitForChild("getItemIcon"))

-- Remotes / Bindables
local UpdateInspectorAsync = BindablesFolder:WaitForChild("UpdateInspector")
local DeleteAccessoryAsync = RemotesFolder:WaitForChild("DeleteAccessory")
local AddAccessoryAsync = RemotesFolder:WaitForChild("AddAccessory")
 
-- GUI Elements
local equipButtonTemplate = ObjectsFolder:WaitForChild("EquipButton")

local function EquipButton(itemId: number, itemType: Enum.MarketplaceProductType): ImageButton?
	local icon = getItemIcon(itemId, itemType)
	local recentMannequinId = getRecentMannequinId()
	if not recentMannequinId then
		warn("No recent mannequin to equip to!")
		return nil
	end

	local equipButton = equipButtonTemplate:Clone()
	equipButton.Image = icon
	
	local function equippedVisibilityToggle()
		equipButton.EquipFrame.Visible = doesMannequinHaveAssetEquipped(localPlayer, itemId, itemType, recentMannequinId)
	end

	local function onActivated()
		local success
		if doesMannequinHaveAssetEquipped(localPlayer, itemId, itemType, recentMannequinId) then
			--equipButton.EquipFrame.Visible = false
			success = DeleteAccessoryAsync:InvokeServer(itemId, recentMannequinId)
		else
			success = AddAccessoryAsync:InvokeServer(itemId, recentMannequinId)	
		end
		if success then
			equipButton.EquipFrame.Visible = not equipButton.EquipFrame.Visible
			UpdateInspectorAsync:Fire()
		end
 	end
	
	-- A function here that make "EquipFrame" visible based on whether the mannequin has this item equipped or not
	equippedVisibilityToggle()
	
	equipButton.Activated:Connect(onActivated)
	return equipButton
end

return EquipButton
]]