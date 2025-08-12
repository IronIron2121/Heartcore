--!strict

-- ItemButtons.lua

-- Services
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Remotes
local PlayerRemovedItem = Remotes:WaitForChild("PlayerRemovedItem")

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))
type UsedAs<T> = Fusion.UsedAs<T>

-- GUI Components
local EquippedItemButton = require(script:WaitForChild("EquippedItemButton"))

-- TODO -- Auto-scaling-canvas size and whatnot
function EquippedItemButtons(
	scope: Fusion.Scope,
	buttonSize: UsedAs<UDim2>
)
	local localPlayer = Players.LocalPlayer
	local char = localPlayer.Character
	local humanoid = char.Humanoid
	local humanoidDescription = humanoid:WaitForChild("HumanoidDescription")
	
	local currentHumanoidDescription = scope:Value(humanoid:WaitForChild("HumanoidDescription"))

	-- Watch for when HumanoidDescription gets replaced
	-- We track this because the humanoid description is completely replaced when you change clothing
	humanoid.ChildAdded:Connect(function(child)
		if child:IsA("HumanoidDescription") then
			currentHumanoidDescription:set(child)
		end
	end)
	
	local currentItemDescriptions = scope:Computed(function(use)
		return use(currentHumanoidDescription):GetChildren()
	end)
	
	local equippedItemButtons = scope:ForValues(currentItemDescriptions, function(use, scope, description)
		if description.AssetId ~= 0 then
			return EquippedItemButton(scope, buttonSize, description)
		end
	end)

	return equippedItemButtons
end

return EquippedItemButtons