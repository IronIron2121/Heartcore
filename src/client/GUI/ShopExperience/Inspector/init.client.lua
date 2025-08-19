--!strict

--[[
	 - This script handles inspecting items on mannequins. A ProximityPrompt is
	created in each mannequin, which when triggered opens up the inspect menu.
--]]


-- Services
local CollectionService 	   	= game:GetService("CollectionService")
local ReplicatedStorage 	   	= game:GetService("ReplicatedStorage")
local UserInputService 			= game:GetService("UserInputService")
local Players 				   	= game:GetService("Players")

-- Folders
local GettersFolder 			= ReplicatedStorage:WaitForChild("Getters")
local CheckersFolder			= ReplicatedStorage:WaitForChild("Checkers")
local UtiltyFolder				= ReplicatedStorage:WaitForChild("Utility")
local BindablesFolder 			= ReplicatedStorage:WaitForChild("Bindables")
local LibrariesFolder			= ReplicatedStorage:WaitForChild("Libraries")
local UIFolder 					= ReplicatedStorage:WaitForChild("UI")
local UIComponentsFolder		= UIFolder:WaitForChild("Components")

local localPlayer 			   	= Players.LocalPlayer
local playerGui 			   	= localPlayer.PlayerGui
local inspectPromptTemplate    	= script.InspectPrompt

-- GUI Elements
local shoppingGui 			   	= playerGui:WaitForChild("ShoppingGui")
local equipFrame 				= shoppingGui:WaitForChild("EquipFrame")
local inspectFrame 			   	= shoppingGui:WaitForChild("InspectFrame")
local topBar 				   	= inspectFrame:WaitForChild("TopBar")
local buyAllButton 			   	= topBar:WaitForChild("BuyAllButton")
local deleteButton 			   	= topBar:WaitForChild("DeleteButton") 
local closeButton 			   	= topBar:WaitForChild("CloseButton")
local tryOnButton 			   	= topBar:WaitForChild("TryOnButton")
local editButton 			   	= topBar:WaitForChild("EditButton")
local addButton 			   	= topBar:WaitForChild("AddButton")
local itemsFrame: ScrollingFrame
local loadingDisplay: Frame

-- Module script GUI elements
local stringOfNumbersToArray   	= require(UtiltyFolder:WaitForChild("stringOfNumbersToArray"))
local Constants 			   	= require(ReplicatedStorage:WaitForChild("Constants"))
local ResponsiveGrid 		   	= require(UIComponentsFolder:WaitForChild("ResponsiveGrid"))
local LoadingDisplay 		   	= require(UIComponentsFolder:WaitForChild("LoadingDisplay"))
local CartButton 			   	= require(UIComponentsFolder:WaitForChild("CartButton"))
local ItemTile 				   	= require(UIComponentsFolder:WaitForChild("ItemTile"))
local ItemDetailsCache  	   	= require(LibrariesFolder:WaitForChild("ItemDetailsCache"))
local ModalManager 			  	= require(LibrariesFolder:WaitForChild("ModalManager"))
local TryOn 				   	= require(LibrariesFolder:WaitForChild("TryOn"))

-- Module script functions
local getMannequinFromId 	   	= require(GettersFolder:WaitForChild("getMannequinFromId"))
local getRecentMannequinId		= require(GettersFolder:WaitForChild("getRecentMannequinId"))

-- Remotes | Bindables
local RepositionShopItemBindable= BindablesFolder:WaitForChild("RepositionShopItemBindable")
local shopClosedBindable 	   	= BindablesFolder:WaitForChild("PlayerClosedShopBindable")
local PlayerDestroyedPreview	= BindablesFolder:WaitForChild("PlayerDestroyedPreview")
local HideAllPromptsBindable	= BindablesFolder:WaitForChild("HideAllPromptsBindable")
local ShowAllPromptsBindable	= BindablesFolder:WaitForChild("ShowAllPromptsBindable")
local PlayerCreatedPreview 		= BindablesFolder:WaitForChild("PlayerCreatedPreview")
local UpdateInspector 			= BindablesFolder:WaitForChild("UpdateInspector")
local remotes 				   	= ReplicatedStorage:WaitForChild("Remotes")
local bulkPurchaseRemote 	   	= remotes:WaitForChild("BulkPurchase")



-- A dictionary mapping instances (presumably mannequins) to proximity prompts
local inspectPrompts: { [Instance]: ProximityPrompt } = {}
local inspectingItems: { { id: number, type: Enum.MarketplaceProductType } } = {}
local isLoading = false
local isEditing = false

local function hideAllPrompts()
	for _, prompt in inspectPrompts do
		prompt.Enabled = false
	end
end

local function showAllPrompts()
	for _, prompt in inspectPrompts do
		prompt.Enabled = true
	end
end

-- Function to make loading GUI visible when loading GUI elements
local function setLoading(loading: boolean)
	isLoading = loading
	loadingDisplay.Visible = loading
end

local function clearItemTiles()
	for _, child in itemsFrame:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

-- TODO - modularise this
local function editButtonOwnershipToggle(mannequin)
	if mannequin:GetAttribute(Constants.SHOP_ITEM_OWNED_BY_ATTRIBUTE) == localPlayer.UserId then
		editButton.Visible = true
	else
		editButton.Visible = false
	end
end

local function makeItemsDeletable()
	for _, child in itemsFrame:GetChildren() do
		if child:IsA("GuiObject") then
			local DeleteButton 		= child:WaitForChild("DeleteButton") :: TextButton
			local ButtonsFrame 		= child:WaitForChild("ButtonsFrame") :: Frame
			DeleteButton.Visible 	= true			
			ButtonsFrame.Visible 	= false
		end
	end 
end

local function makeItemsBuyable()
	for _, child in itemsFrame:GetChildren() do
		if child:IsA("GuiObject") then
			local DeleteButton 		= child:WaitForChild("DeleteButton") :: TextButton
			local ButtonsFrame 		= child:WaitForChild("ButtonsFrame") :: Frame
			DeleteButton.Visible 	= false
			ButtonsFrame.Visible 	= true
		end
	end 
end

-- TODO: Refactor refactor refactor!!
local function inspectAsync(mannequin: Model, updating: boolean?)	
	warn("Inspect async!")
	updating = updating or false

	-- Update the inspect frame's current mannequinID if it doesn't match the mannequin we're inspecting
	local mannequinId = mannequin:GetAttribute(Constants.ITEM_ID_ATTRIBUTE)
	local recentMannequinId = inspectFrame:GetChildren(Constants.RECENT_MANNEQUIN_ATTRIBUTE, mannequinId)

	if mannequinId ~= recentMannequinId then
		inspectFrame:SetAttribute(Constants.RECENT_MANNEQUIN_ATTRIBUTE, mannequinId)
	end

	if not updating then
		-- Make the inspect frame visible
		ModalManager.push(inspectFrame)
	end
	
	editButtonOwnershipToggle(mannequin)
	
	if isLoading then
		return
	end
	
	local accessoryIdsString = mannequin:GetAttribute(Constants.MANNEQUIN_ACCESSORY_IDS_ATTRIBUTE)
	local bundleIdsString = mannequin:GetAttribute(Constants.BUNDLE_IDS_ATTRIBUTE)
	
	local accessoryIds = stringOfNumbersToArray(accessoryIdsString)
	local bundleIds = stringOfNumbersToArray(bundleIdsString)

	-- Wipe the inspected items list and then re-fill it with the items we're currently inspecting
	table.clear(inspectingItems)
	for _, accessoryId in accessoryIds do
		table.insert(inspectingItems, { id = accessoryId, type = Enum.MarketplaceProductType.AvatarAsset })
	end
	
	for _, bundleId in bundleIds do
		table.insert(inspectingItems, { id = bundleId, type = Enum.MarketplaceProductType.AvatarBundle })
	end

	-- Clear all pre-existing item tiles
	clearItemTiles()
	setLoading(true)

	-- Create tiles for each of the accessories and bundles on the mannequin
	for _, accessoryId in accessoryIds do
		local assetDetails = ItemDetailsCache.getAssetDetailsAsync(accessoryId)
		if not assetDetails then
			continue
		end

		local itemTile = ItemTile(assetDetails, mannequinId)
		itemTile.Parent = itemsFrame
	end

	for _, bundleId in bundleIds do
		local bundleDetails = ItemDetailsCache.getBundleDetailsAsync(bundleId)
		if not bundleDetails then
			continue
		end

		local itemTile = ItemTile(bundleDetails, mannequinId)
		itemTile.Parent = itemsFrame
	end
	
	if isEditing then
		makeItemsDeletable()
	end

	setLoading(false)
end

local function updateInspector()
	local recentMannequinId = getRecentMannequinId()
	local mannequin = getMannequinFromId(localPlayer, recentMannequinId)
	if not mannequin then return end
	inspectAsync(mannequin, true)
end

-- TODO: Revisit this and rationalise it
local function onMannequinAdded(mannequin: Model)
	print("Adding to mannequin")
	local base = mannequin:WaitForChild("Base", 0.1)
	--assert(base, `{mannequin:GetFullName()} is missing Base`)

	-- Create a new ProximityPrompt in the mannequin, calling the inspect function when it is triggered
	local inspectPrompt = inspectPromptTemplate:Clone() :: ProximityPrompt
	inspectPrompt:AddTag(Constants.INSPECT_PROMPT_TAG)
	inspectPrompt.Parent = mannequin.PrimaryPart or base


	inspectPrompt.Triggered:Connect(function(_: Player)
		-- Since this prompt is created locally, we don't need to check which player triggered it
		inspectAsync(mannequin)
	end)

	inspectPrompts[mannequin] = inspectPrompt
end

-- Destroy the mannequin's ProximityPrompt when deleted
local function onMannequinRemoved(mannequin: Instance)
	if inspectPrompts[mannequin] then
		inspectPrompts[mannequin]:Destroy()
		inspectPrompts[mannequin] = nil
	end
end

-- Restores inspect GUI to its default state
local function resetInspectGui()
	topBar.BuyAllButton.Visible = true
	topBar.TryOnButton.Visible 	= true
	topBar.CartButton.Visible 	= true
	deleteButton.Visible 		= false
	addButton.Visible 			= false
	isEditing 					= false
end

-- Reset and close GUI
local function onCloseButtonActivated()
	ModalManager.pop(inspectFrame)
	resetInspectGui()
end


-- Try on all items in inspect frame
local function onTryOnButtonActivated()
	TryOn.setItemsAsync(inspectingItems)
end


-- Deletes a given mannequin from player store
local function onDeleteButtonActivated()
	onCloseButtonActivated()
end

local function onBuyAllButtonActivated()
	-- We need to convert the list of items to the format expected by MarketplaceService:PromptBulkPurchase()
	local bulkPurchaseItems = {}
	for _, item in inspectingItems do
		table.insert(bulkPurchaseItems, {
			Id = tostring(item.id),
			Type = item.type,
		})
	end

	-- Since PromptBulkPurchase can't be used on the client, we send the list of items to the server
	bulkPurchaseRemote:FireServer(bulkPurchaseItems)
end

local function onAddButtonActivated()
	ModalManager.push(equipFrame)
end


local function onEditButtonActivated()
	isEditing = not isEditing
	
	if isEditing then
		addButton.Visible = true
		topBar.DeleteButton.Visible = true
		topBar.BuyAllButton.Visible = false
		topBar.TryOnButton.Visible 	= false
		topBar.CartButton.Visible 	= false
		makeItemsDeletable()

	else
		addButton.Visible 			= false
		topBar.DeleteButton.Visible = false
		topBar.BuyAllButton.Visible = true
		topBar.TryOnButton.Visible 	= true
		topBar.CartButton.Visible 	= true
		makeItemsBuyable()
	end
end

local function initialize()
	-- Initialise buttons	
	deleteButton.Activated:Connect(onDeleteButtonActivated)
	buyAllButton.Activated:Connect(onBuyAllButtonActivated)
	closeButton.Activated:Connect(onCloseButtonActivated)
	tryOnButton.Activated:Connect(onTryOnButtonActivated)
	editButton.Activated:Connect(onEditButtonActivated)
	addButton.Activated:Connect(onAddButtonActivated)

	-- Mannequins are all tagged with Constants.MANNEQUIN_TAG, so we can use CollectionService to
	-- easily keep track of them
	CollectionService:GetInstanceAddedSignal(Constants.MANNEQUIN_TAG):Connect(onMannequinAdded)
	CollectionService:GetInstanceRemovedSignal(Constants.MANNEQUIN_TAG):Connect(onMannequinRemoved)

	-- Initialize items frame
	itemsFrame = ResponsiveGrid(Constants.ITEM_TILE_SIZE, Constants.ITEM_TILE_PADDING)
	itemsFrame.LayoutOrder 	= 1
	itemsFrame.Parent 		= inspectFrame

	-- Initialize cart button
	local cartButton 		= CartButton()
	cartButton.LayoutOrder 	= 3
	cartButton.Parent 		= topBar

	-- Initialize loading display
	loadingDisplay 			= LoadingDisplay()
	loadingDisplay.Parent 	= inspectFrame

	for _, mannequin in CollectionService:GetTagged(Constants.MANNEQUIN_TAG) do
		print(mannequin)
		onMannequinAdded(mannequin)
	end
end

initialize()

-- Connections
shopClosedBindable.Event:Connect(onCloseButtonActivated)
PlayerCreatedPreview.Event:Connect(hideAllPrompts)
PlayerDestroyedPreview.Event:Connect(showAllPrompts)

HideAllPromptsBindable.Event:Connect(hideAllPrompts)
ShowAllPromptsBindable.Event:Connect(showAllPrompts)

UpdateInspector.Event:Connect(updateInspector)