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

-- Fusion
local peek = Fusion.peek

-- GUI Components
local EquippedItemButton = require(script:WaitForChild("EquippedItemButton"))

-- TODO -- Auto-scaling-canvas size and whatnot
-- TODO: This is so hacky. See if we can improve this
	-- The main problem is there there's no moment to moment tracking of the number of buttons...
function EquippedItemButtons(
	scope: Fusion.Scope,
	props: {
		buttonSize: UsedAs<UDim2>,
		equipItemButtonsVisible: UsedAs<boolean>
	}
)
	local localPlayer = Players.LocalPlayer
	local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
	local humanoid = char.Humanoid
	
	local currentHumanoidDescription = scope:Value(humanoid:WaitForChild("HumanoidDescription"))
	
	local currentItemDescriptions = scope:Computed(function(use)
		return use(currentHumanoidDescription):GetChildren()
	end)

	local equippedItemButtons = scope:ForValues(currentItemDescriptions, function(use, scope, description)
		if description.assetId ~= 0 then
			return EquippedItemButton(scope, {
				buttonSize = props.buttonSize, 
				visible = props.equipItemButtonsVisible,
				itemDescription = description
			})

		else
			-- These are "dud buttons" that allow us to know when all accessories and body parts have a corresponding "EquippedItemButton"
			return EquippedItemButton(scope, {
				buttonSize = UDim2.fromScale(0, 0),
				visible = false
			})
		end
	end)

	-- Watch for when HumanoidDescription gets replaced
	-- We track this because the humanoid description is completely replaced when you change clothing
	humanoid.ChildAdded:Connect(function(child)
		if child:IsA("HumanoidDescription") then
			currentHumanoidDescription:set(child)
			props.equipItemButtonsVisible:set(true)
			-- TODO: Add a while loop that guards against premature display...
		end
	end)

	return equippedItemButtons
end

return EquippedItemButtons