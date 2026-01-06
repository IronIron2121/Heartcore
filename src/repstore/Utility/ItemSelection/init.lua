--[[
	This module processes the highlighting of in-world objects when the players hovers over them with a mouse
	The functionality for this is particularly geared toward the edit functionality for our player shops
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CAS = game:GetService("ContextActionService")

-- Instances
local localPlayer = Players.LocalPlayer
local mouse = localPlayer:GetMouse()
local hoverHighlight = script:WaitForChild("HoverHighlight")
local selectedHighlight	= script:WaitForChild("SelectedHighlight")

-- Folders
local RemotesFolder	= ReplicatedStorage:WaitForChild("Remotes")
local GettersFolder = ReplicatedStorage:WaitForChild("Getters")
local UtilityFolder = ReplicatedStorage:WaitForChild("Utility")
local BindablesFolder = ReplicatedStorage:WaitForChild("Bindables")
local Trackers = ReplicatedStorage:WaitForChild("Trackers")

-- Module Scripts
local localPlayerDetails = require(Trackers:WaitForChild("localPlayerDetails"))
local getTopLevelModel = require(GettersFolder:WaitForChild("getTopLevelModel"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local Types = require(UtilityFolder:WaitForChild("Types"))

-- Remotes | Bindables
local DeleteShopItemEvent = RemotesFolder:WaitForChild("DeleteShopItem")
local PlayerSelectedMannequin 	= BindablesFolder:WaitForChild("PlayerSelectedMannequin")
local PlayerDeSelectedMannequin = BindablesFolder:WaitForChild("PlayerDeSelectedMannequin")
local GetShopGuiFSMState = GettersFolder:WaitForChild("GetShopGuiFSMState")

-- Variables
local mouseHoverConnection: RBXScriptConnection? = nil
local mouseClickConnection: RBXScriptSignal? = nil

-- Constants
local UNSELECTED_HIGHLIGHT_COLOUR = Color3.new(0, 0.984314, 1)
local SELECTED_HIGHLIGHT_COLOUR	= Color3.new(0.0666667, 1, 0)

-- Cache
local shopDetails = nil

hoverHighlight.FillColor = UNSELECTED_HIGHLIGHT_COLOUR
selectedHighlight.FillColor = SELECTED_HIGHLIGHT_COLOUR

--

local ItemSelection = {}

ItemSelection.selectedItem = nil

-- Sets our HOVER highlight to the passed item
local function setHoverHighlightAdornee(adornee: Model?)
	hoverHighlight.Adornee = adornee	
end

local function setSelectionHighlightAdornee()
	selectedHighlight.Adornee = ItemSelection.selectedItem
end

function ItemSelection.getSelectedItem()
	return ItemSelection.selectedItem
end

function ItemSelection.getSelectedItemName()
	if not ItemSelection.selectedItem then
		return nil
	end
	return ItemSelection.selectedItem.Name
end

function ItemSelection.getSelectedItemId()
	if not ItemSelection.selectedItem then
		return nil
	end
	return ItemSelection.selectedItem:GetAttribute(Constants.ITEM_ID_ATTRIBUTE)
end

function ItemSelection.getSelectedItemType()
	if not ItemSelection.selectedItem then
		return nil
	end
	return ItemSelection.selectedItem:GetAttribute(Constants.ITEM_TYPE_ATTRIBUTE)
end

function ItemSelection.deleteSelectedItem()
	if not ItemSelection.selectedItem then return end
	DeleteShopItemEvent:FireServer(ItemSelection.getSelectedItemId(), ItemSelection.getSelectedItemType())
end

function ItemSelection.unSelectItem(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.End or not ItemSelection.selectedItem then return end
	ItemSelection.selectedItem = nil
	setSelectionHighlightAdornee()
	PlayerDeSelectedMannequin:Fire()
end

local function selectItem(item: Model?)
	ItemSelection.selectedItem = item
	setSelectionHighlightAdornee()
	PlayerSelectedMannequin:Fire()
end

local function isInstanceAShopItem(instance: Instance)
	if not instance then return nil end
	local playerShop = getShopFromPlayer(localPlayer)
	
	if instance:IsA("Model") and instance:IsDescendantOf(playerShop) then
		return true
	end
end

local function onMouseClicked(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.End then return end
	local mouseTarget = getTopLevelModel(mouse.Target)
	if not mouseTarget then 
		return
	end
	
	local shopDetails = localPlayerDetails.getShopDetails() :: Types.ShopDetails
	local playerShop = shopDetails.instance
	
	if mouseTarget:IsDescendantOf(playerShop) and mouseTarget:GetAttribute(Constants.SHOP_ITEM_OWNED_BY_ATTRIBUTE) then
		selectItem(mouseTarget)
		--ShopGuiFSM.setState("HighlightedMannequin")
	else
		if GetShopGuiFSMState:Invoke() == "PlacingShopItem" then return end
		ItemSelection.unSelectItem()
		--ShopGuiFSM.setState("EditingBase")
	end
end

-- Tracks the movement of the mouse over items and moves the HOVER highlight accordingly
function ItemSelection.mouseTargetChanged()
	local target = mouse.Target
	
	if not target then
		setHoverHighlightAdornee(nil)
		return
	end
	
	local targetParent = target.Parent
	-- TODO: We need to make this compatible with claiming a new shop
	shopDetails = shopDetails or localPlayerDetails.getShopDetails() :: Types.ShopDetails? 	
	if not shopDetails then
		assert(shopDetails, "Error: No shop details for player! This should not be possible in edit mode")
	else
		print("Shop details found")
	end
	local playerShop = shopDetails.instance
	
	if not(targetParent:IsA("Model") and target:IsDescendantOf(playerShop)) then
		setHoverHighlightAdornee(nil) 
		return
	end
	
	targetParent = getTopLevelModel(targetParent)
	
	if targetParent ~= ItemSelection.selectedItem then
		setHoverHighlightAdornee(targetParent)
	else
		setHoverHighlightAdornee(nil)
	end
end

function ItemSelection.startHoverTracking()
	if mouseHoverConnection == nil then
		mouseHoverConnection = RunService.RenderStepped:Connect(ItemSelection.mouseTargetChanged)
	end
	
	if mouseClickConnection == nil then
		CAS:BindAction("SelectMannequin", onMouseClicked, false, Enum.UserInputType.MouseButton1)
		mouseClickConnection = true
	end
end

function ItemSelection.stopClickTracking()
	if mouseClickConnection then
		warn("Disconnecting mouse click")
		mouseClickConnection = nil
		CAS:UnbindAction("SelectMannequin")
		selectedHighlight.Adornee = nil 
	else
		print(mouseClickConnection)
	end
end

function ItemSelection.stopHoverTracking()
	if mouseHoverConnection then
		warn("Disconnecting mouse hover")
		mouseHoverConnection:Disconnect()
		mouseHoverConnection = nil
		hoverHighlight.Adornee = nil
	end
end

return ItemSelection