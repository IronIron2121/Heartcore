--[[ 
	Defines a state manager for the shop item store GUI
]]

--[[
-- Services
local ReplicatedStorage 		= game:GetService("ReplicatedStorage")
local Players 					= game:GetService("Players")

-- Folders
local Bindables 			= ReplicatedStorage:WaitForChild("Bindables")
local Utility				= ReplicatedStorage:WaitForChild("Utility")
local Getters				= ReplicatedStorage:WaitForChild("Getters")

-- Module Scripts
local ItemSelection				= require(Utility:WaitForChild("ItemSelection"))

-- Remotes / Bindables
local PlayerDeSelectedMannequin = Bindables:WaitForChild("PlayerDeSelectedMannequin")
local PlayerSelectedMannequin 	= Bindables:WaitForChild("PlayerSelectedMannequin")
local ShowAllPromptsBindable 	= Bindables:WaitForChild("ShowAllPromptsBindable")
local HideAllPromptsBindable 	= Bindables:WaitForChild("HideAllPromptsBindable")
local InitialiseColoursBindable = Bindables:WaitForChild("InitialiseColours")
local CloseColoursBindable 		= Bindables:WaitForChild("CloseColours")
local GetShopGuiFSMState		= Getters:WaitForChild("GetShopGuiFSMState")
local ShopItemStoreOpenedAsync 	= Bindables:WaitForChild("ShopItemStoreOpened")


-- Instances
local localPlayer 	= Players.LocalPlayer

-- GUI Elements
local PlayerGui		= localPlayer.PlayerGui
	-- ClaimedShopGui
local ClaimedShopGui 		= PlayerGui:WaitForChild("ClaimedShopGui")
local ShopItemStoreButton 	= ClaimedShopGui:WaitForChild("ShopItemStoreButton")
local ShopItemStoreFrame	= ClaimedShopGui:WaitForChild("ShopItemStoreFrame")
local RepositionFrame 		= ClaimedShopGui:WaitForChild("RepositionFrame")
local EditFurnitureFrame	= ClaimedShopGui:WaitForChild("EditFurnitureFrame")
local RecolourFrame 		= ClaimedShopGui:WaitForChild("RecolourFrame")
local MainHUDGui 			= PlayerGui:WaitForChild("MainHUD")
local ShopButtons 			= MainHUDGui:WaitForChild("ShopButtons")
local editShopButton 		= ShopButtons:WaitForChild("EditShopButton")
local ShopItemFocusFrame 	= ClaimedShopGui:WaitForChild("ShopItemFocusFrame")



-- Module
local ShopGuiFSM = {}

-- Constants
local ENTER_EDIT_THUMBNAIL_ID = "rbxassetid://85288180065579"
local EXIT_EDIT_THUMBNAIL_ID = "rbxassetid://78529680120264"

-- Variables
ShopGuiFSM.editingShop = false
ShopGuiFSM.currentState = nil

local stateBehaviors = {
	OutOfShop = {
		
	},
	
	None = {
		enter = function()
			if ItemSelection.selectedItem then ItemSelection.unSelectItem() end
			ShowAllPromptsBindable:Fire()
			ItemSelection.stopClickTracking()
			editShopButton.Image = ENTER_EDIT_THUMBNAIL_ID

		end,
		exit = function()
			-- Nothing to clean up
		end,
	},
	
	EditingBase = {
		enter = function()
			ShopGuiFSM.editingShop = true
			ShopItemStoreButton.Visible = true
			HideAllPromptsBindable:Fire()
			ItemSelection.startHoverTracking()
			editShopButton.Image = EXIT_EDIT_THUMBNAIL_ID
		end,
		
		exit = function()
			ShopGuiFSM.editingShop = false
			ShopItemStoreButton.Visible = false
			ItemSelection.stopHoverTracking()
		end,
	},
	
	FurnitureStore = {
		enter = function()
			-- Show item selection
			ModalManager.push(ShopItemStoreFrame)
			ShopItemStoreOpenedAsync:Fire()
		end,
		exit = function()
			-- Hide item selection
			ModalManager.pop(ShopItemStoreFrame)
		end,
	},
	
	HighlightedMannequin = {
		enter = function()
			-- Highlight a mannequin and show options
			ItemSelection.startHoverTracking()

			ModalManager.push(EditFurnitureFrame)
		end,
		exit = function()
			-- Remove highlights
			ModalManager.pop(EditFurnitureFrame) 
		end,
	},
	
	RepositioningMannequin = {
		enter = function()
			-- Show reposition UI
			ModalManager.push(RepositionFrame)
		end,
		exit = function()
			-- Hide reposition UI
			ModalManager.pop(RepositionFrame)
		end,
	},

	PlacingShopItem = {
		enter = function()
			-- Enable placement preview, ghost item, grid snap, etc.
		end,
		exit = function()
			-- Confirm or cancel placement, clean up
		end,
	},
	
	ShopItemFocus = {
		enter = function()
			ModalManager.push(ShopItemFocusFrame)
			
		end,
		
		exit = function()
			ModalManager.pop(ShopItemFocusFrame)
		end,
		
	},
	
	ColouringFurniture = {
		enter = function()
			ModalManager.push(RecolourFrame)	
			InitialiseColoursBindable:Fire()
		end,
		
		exit = function()
			ModalManager.pop(RecolourFrame)
			CloseColoursBindable:Fire()
		end
	}
}

function ShopGuiFSM.setState(newState)
	if newState == ShopGuiFSM.CurrentState then return end
	if ShopGuiFSM.CurrentState and stateBehaviors[ShopGuiFSM.CurrentState] then
		stateBehaviors[ShopGuiFSM.CurrentState].exit()
	end
	ShopGuiFSM.CurrentState = newState
	if newState and stateBehaviors[newState] then
		stateBehaviors[newState].enter()
		print("Current state is: " .. newState)
	else
		warn("No behavior for state:", newState)
	end
end

local function mannequinSelected()
	ShopGuiFSM.setState("HighlightedMannequin")
end

local function mannequinDeSelected()
	if ShopGuiFSM.CurrentState == "RepositioningMannequin" or ShopGuiFSM.CurrentState == "HighlightedMannequin" then
		ShopGuiFSM.setState("EditingBase")
	end
end

local function getShopGuiFSMState()
	return ShopGuiFSM.CurrentState
end

PlayerSelectedMannequin.Event:Connect(mannequinSelected)
PlayerDeSelectedMannequin.Event:Connect(mannequinDeSelected)
GetShopGuiFSMState.OnInvoke = getShopGuiFSMState
]]

return {}
--return ShopGuiFSM
