--!strict

-- ItemButtons.lua

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))
type UsedAs<T> = Fusion.UsedAs<T>

-- GUI Components
local EquippedClassicItemButton = require(script:WaitForChild("EquippedClassicItemButton"))
local EquippedItemButton = require(script:WaitForChild("EquippedItemButton"))

-- Constants
local DUD_SIZE = UDim2.fromScale(0, 0)

local function combineItemButtons(scope: Fusion.Scope, itemButtons, classicItemButtons)
	return scope:Computed(function(use)
		local combined = {}
		
		-- Add all regular item buttons
		for _, button in use(itemButtons) do
			--warn("item new", button)
			table.insert(combined, button)
		end
		
		-- Add all classic item buttons
		for _, button in pairs(use(classicItemButtons)) do
			--warn("item classic: ", button)
			table.insert(combined, button)
		end
		
		return combined
	end)
end

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
	
	local currentHumanoidDescription = scope:Value(humanoid:WaitForChild("HumanoidDescription") :: HumanoidDescription) 
	
	local currentItemDescriptions = scope:Computed(function(use)
		return use(currentHumanoidDescription):GetChildren()
	end)

	local currentClassicItems = scope:Computed(function(use)
		return {
			["GraphicTShirt"] = use(currentHumanoidDescription).GraphicTShirt,
			["Shirt"] = use(currentHumanoidDescription).Shirt,
			["Pants"] = use(currentHumanoidDescription).Pants,
		}
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
				buttonSize = DUD_SIZE,
				visible = false
			})
		end
	end)

	local equippedClassicItemButtons = scope:ForPairs(currentClassicItems, function(use, scope, itemType, itemId)
		if itemId ~= nil then
			return itemType, EquippedClassicItemButton(scope, {
				buttonSize = props.buttonSize,
				visible = props.equipItemButtonsVisible,
				itemId = itemId,
				itemType = itemType
			}) 
		else
			return itemType, EquippedClassicItemButton(scope, {
				buttonSize = DUD_SIZE,
				visible = false,
				itemId = 0,
				itemType = itemType
			})
		end
	end)

	-- Combine both button lists into one reactive table
	local allEquippedButtons = combineItemButtons(scope, equippedItemButtons, equippedClassicItemButtons)

	-- Watch for when HumanoidDescription gets replaced
	-- We track this because the humanoid description is completely replaced when you change clothing
	humanoid.ChildAdded:Connect(function(child)
		if child:IsA("HumanoidDescription") then
			currentHumanoidDescription:set(child)
			props.equipItemButtonsVisible:set(true)
			-- TODO: Add a while loop that guards against premature display...
		end
	end)

	return allEquippedButtons
end

return EquippedItemButtons