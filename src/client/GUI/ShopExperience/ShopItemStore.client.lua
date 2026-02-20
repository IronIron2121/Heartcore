--!strict
--[[
-- Services
local ReplicatedStorage 		= game:GetService("ReplicatedStorage")
local Players 					= game:GetService("Players")

-- Instances
local localPlayer 				= Players.LocalPlayer

-- Folders
local DataTablesFolder			= ReplicatedStorage:WaitForChild("DataTables")
local LibrariesFolder			= ReplicatedStorage:WaitForChild("Libraries")
local UtilityFolder				= ReplicatedStorage:WaitForChild("Utility")
local RemotesFolder 			= ReplicatedStorage:WaitForChild("Remotes")
local UIFolder 					= ReplicatedStorage:WaitForChild("UI")
local Bindables 				= ReplicatedStorage:WaitForChild("Bindables")
local UIComponentsFolder		= UIFolder:WaitForChild("Components")

-- GUI elements
local PlayerGui					= localPlayer.PlayerGui
	-- ClaimedShopGui
local ClaimedShopGui 			= PlayerGui:WaitForChild("ClaimedShopGui")
local ShopItemStoreButton 		= ClaimedShopGui:WaitForChild("ShopItemStoreButton")
local ShopItemStoreFrame		= ClaimedShopGui:WaitForChild("ShopItemStoreFrame")

	-- Item Master
local ItemMaster 				= ShopItemStoreFrame:WaitForChild("ItemMaster")
local CategoryFrame				= ShopItemStoreFrame:WaitForChild("CategoryFrame") 
local ItemFrame					= ItemMaster:WaitForChild("ItemFrame")
local TopBar 					= ItemMaster:WaitForChild("TopBar")
-- Topbar
local CloseShopItemStoreFrameButton = TopBar:WaitForChild("CloseShopItemStoreButton")
local OwnedButton 				= TopBar:WaitForChild("OwnedButton")

-- Module Scripts
local AddTile					= require(UIComponentsFolder:WaitForChild("AddTile"))
local CategoryButton			= require(UIComponentsFolder:WaitForChild("CategoryButton"))
local BuyableShopItems			= require(DataTablesFolder:WaitForChild("BuyableShopItems"))
local stringToArray				= require(UtilityFolder:WaitForChild("stringToArray"))
local ShopGuiFSM 				= require(UtilityFolder:WaitForChild("ShopGuiFSM"))
local ShopItemStoreCategories 	= require(DataTablesFolder:WaitForChild("ShopItemStoreCategories"))

-- Remotes | Bindables
local CategoryButtonClickedEvent= Bindables:WaitForChild("CategoryButtonClicked")
local ShopItemStoreOpenedAsync 	= Bindables:WaitForChild("ShopItemStoreOpened")

-- Variables
local categoryButtons 			= {}

-- Constants
local DEFAULT_SELECT 			= ShopItemStoreCategories[1]


local function getHoverColour(buttonColour : Color3)
	return buttonColour:Lerp(Color3.new(1, 1, 1), 0.2)
end

-- Shows all placeable items
local function showAllItemButtons()
	for _, child in pairs(ItemFrame:GetChildren()) do
		if child:IsA("Frame") then
			child.Visible = true
		end
	end
end

-- Hides all item buttons
local function hideAllItemButtons()
	for _, child in pairs(ItemFrame:GetChildren()) do
		if child:IsA("Frame") then
			child.Visible = false
		end
	end
end

-- Filters addable items based on category button clicked 
local function showCategoryButton(category: string)
	for _, child in pairs(ItemFrame:GetChildren()) do
		if child:IsA("Frame") then
			local childTags = stringToArray(child:GetAttribute("Tags"))
			local categoryIndex = table.find(childTags, category)
			if categoryIndex then
				child.Visible = true
			else
				child.Visible = false
			end
		end
	end
end

local function populateItemFrame()
	print("populating item frame")
	for itemName, itemDetails in pairs(BuyableShopItems) do
		print("item here", itemDetails)
		local newTile = AddTile(itemDetails) 
		newTile.Parent = ItemFrame
	end 
	print("finished populating item frame")

end

local function populateCategories()
	print("Populating categories")
	for index, category in ipairs(ShopItemStoreCategories) do
		print(category)
		local newButton = CategoryButton(category)
		newButton.Button.Parent = CategoryFrame
		newButton.Button.LayoutOrder = index
		categoryButtons[newButton.GetText()] = newButton
	end
	print("finished populating categories")
end

-- Remove all populated options
local function dePopulateItemFrame()
	local allButtons = ItemFrame:GetChildren()
	for _, child in pairs(allButtons) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function dePopulateCategories()
	for _, child in pairs(categoryButtons) do
		child.Destroy()
	end
end



local function closeShopItemStoreFrameButtonClicked()
	ShopGuiFSM.setState("EditingBase")
end


-- TODO: This should all probably be updated to be a module script
local function selectCategory(button: CategoryButton)
	if button.Name == "All" then
		showAllItemButtons()
	else
		showCategoryButton(button.Name)
	end
	
	for _, child in categoryButtons do
		if child.Button.Name ~= button.Name then
			child.Unselect()
		end
	end	
end
]]
--local function selectCategoryByText(category : string)
	--[[
	if not categoryButtons[category] then
		return 
	end
	]]
--	selectCategory(categoryButtons[category].Button)
--end


--[[
local function initialiseShopItemStoreFrame()
	-- POPULATE ITEM FRAME
	dePopulateItemFrame()
	dePopulateCategories()
	populateItemFrame()
	populateCategories()
	if categoryButtons[DEFAULT_SELECT] then
		categoryButtons[DEFAULT_SELECT].Select()
	end
end

local function onShopItemStoreButtonClicked()
	ShopGuiFSM.setState("FurnitureStore")
	print("button clicked!")
end

-- Connections
CloseShopItemStoreFrameButton.Activated:Connect(closeShopItemStoreFrameButtonClicked)
ShopItemStoreButton.Activated:Connect(onShopItemStoreButtonClicked)
CategoryButtonClickedEvent.Event:Connect(selectCategory)
ShopItemStoreOpenedAsync.Event:Connect(initialiseShopItemStoreFrame)
]]