--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService 	= game:GetService("DataStoreService")
local Players = game:GetService("Players")

-- Folders
local BindablesFolder	= ReplicatedStorage:WaitForChild("Bindables")
local TemplatesFolder 	= ReplicatedStorage:WaitForChild("Templates")
local Factories 		= ReplicatedStorage:WaitForChild("Factories")
local Trackers 			= ReplicatedStorage:WaitForChild("Trackers")
local Utility 			= ReplicatedStorage:WaitForChild("Utility")
local RemotesFolder 	= ReplicatedStorage:WaitForChild("Remotes")

-- Modules
local Constants 	= require(ReplicatedStorage:WaitForChild("Constants"))
local Types 		= require(Utility:WaitForChild("Types"))
local ShopTracker 	= require(Trackers:WaitForChild("ShopTracker"))
local PlayerTracker = require(Trackers:WaitForChild("PlayerTracker"))
local ShopItemFactory = require(Factories:WaitForChild("ShopItemFactory"))
local getRandomIdNumber = require(Utility:WaitForChild("getRandomIdNumber"))
local getRelativePosition = require(Utility:WaitForChild("getRelativePosition"))


local SerialisationUtilities	= require(Utility:WaitForChild("SerialisationUtilities"))
local serialiseAttributes 		= SerialisationUtilities.serialiseAttributes
local unserialiseCFrame   		= SerialisationUtilities.unserialiseCFrame
local serialiseCFrame   		= SerialisationUtilities.serialiseCFrame

local Zone 					= require(Utility:WaitForChild("Zone"))
local ZoneController 		= require(Utility:WaitForChild("Zone"):WaitForChild("ZoneController"))

-- Local Constants
local DEFAULT_CLAIM_PROMPT_ACTIVATION_DISTANCE = 40
local DEFAULT_CLAIM_PROMPT_HOLD_DURATION = 1
local DEFAULT_CLAIM_PROMPT_ACTION_TEXT = "CLAIM SHOP"
local DEFAULT_CLAIM_PROMPT_OBJECT_TEXT = ""
local DEFAULT_CLAIM_PROMPT_KEYCODE = Enum.KeyCode.E

local DEFAULT_HITBOX_COLOUR = Color3.fromRGB(115, 165, 23)
local DEFAULT_HITBOX_HEIGHT = 32
local HITBOX_Y_POSITION_OFFSET = Vector3.new(0, DEFAULT_HITBOX_HEIGHT / 2, 0)

-- Remotes / Bindables
local SetupMannequinFunction	= BindablesFolder:WaitForChild("SetupMannequin")
local PlayerEnteredOwnShopAsync = RemotesFolder:WaitForChild("PlayerEnteredOwnShop")
local PlayerEnteredOtherShopAsync = RemotesFolder:WaitForChild("PlayerEnteredOtherShop")
local PlayerExitedShopAsync = RemotesFolder:WaitForChild("PlayerExitedShop")
local PlayerClaimedShopAsync = RemotesFolder:WaitForChild("PlayerClaimedShop")

-- Data Stores
local playerShopsDataStore 	= DataStoreService:GetDataStore(Constants.PLAYER_SHOPS_DATA_STORE_NAME)

--
 
local ShopDetails = {}
ShopDetails.__index = ShopDetails

function ShopDetails.new(shopFloor : BasePart)
	local newShop = {} :: Types.ShopDetails 
	setmetatable(newShop, ShopDetails)
	
	newShop.instance = shopFloor
	newShop.shopItemFolder = Instance.new("Folder")
	newShop.shopItemFolder.Parent = shopFloor 
	newShop.shopItemFolder.Name = "ShopItems"
	newShop.listOfShopItems = {}

	newShop:_initialiseZone()
	newShop:_initialiseAttributes()
	newShop:_initialiseClaimPrompt()

	print("returning shop")

	return newShop
end

function ShopDetails:GetClaimingPlayer()
	return Players:GetPlayerByUserId(self.claimingPlayerId)
end

function ShopDetails:_initialiseZone()
	local shopHitbox = Instance.new("Part")
	local shopFloor = self.instance
	shopHitbox.Name = "Hitbox"
	shopHitbox.Color = DEFAULT_HITBOX_COLOUR
	shopHitbox.Size = Vector3.new(shopFloor.Size.X, DEFAULT_HITBOX_HEIGHT, shopFloor.Size.Z)
	shopHitbox.Anchored = true
	shopHitbox.CanCollide = false
	shopHitbox.CanQuery = true
	shopHitbox.CanTouch = false
	shopHitbox.Transparency = 0.5
	shopHitbox.Position = self.instance.Position + HITBOX_Y_POSITION_OFFSET
	shopHitbox.Parent = self.instance
	
	local shopZone = Zone.new(shopHitbox)
	shopZone.playerEntered:Connect(function(player : Player)
		if self:isClaimed() and player.UserId == self.claimingPlayerId then
			PlayerEnteredOwnShopAsync:FireClient(player)
		else
			PlayerEnteredOtherShopAsync:FireClient(player)
		end
	end)
	shopZone.playerExited:Connect(function(player)
		PlayerExitedShopAsync:FireClient(player)
	end)
	shopZone.Name = self.instance.Name
	self.region = shopZone["exactRegion"]
	shopZone:relocate()
end

function ShopDetails:_initialiseAttributes() 
	self.claimed = false
	self.claimingPlayerId = nil 
	self.id = ShopTracker.getUnusedShopId()
end

function ShopDetails:_initialiseClaimPrompt() : ()
	self.claimPrompt = Instance.new("ProximityPrompt") 
	self.claimPrompt.RequiresLineOfSight = false
	self.claimPrompt.ClickablePrompt = true
	self.claimPrompt.Enabled = true
	self.claimPrompt.MaxActivationDistance = DEFAULT_CLAIM_PROMPT_ACTIVATION_DISTANCE
	self.claimPrompt.KeyboardKeyCode = DEFAULT_CLAIM_PROMPT_KEYCODE
	self.claimPrompt.HoldDuration = DEFAULT_CLAIM_PROMPT_HOLD_DURATION
	self.claimPrompt.ActionText = DEFAULT_CLAIM_PROMPT_ACTION_TEXT
	self.claimPrompt.ObjectText = DEFAULT_CLAIM_PROMPT_OBJECT_TEXT
	self.claimPrompt.Triggered:Connect(function(playerWhoTriggered)
		local playerDetails = PlayerTracker.getPlayerDetails(playerWhoTriggered)
		if playerDetails then
			playerDetails:claimedShop(self)
		else
			assert(playerDetails, "Player details not found")
		end
	end)

	self.claimPrompt.Parent = self.instance
end

function ShopDetails:getShopInstance() : BasePart
	return self.instance
end

function ShopDetails:removeAllShopItems()
	for _, child in ipairs(self.shopItemFolder:GetChildren()) do
		child:Destroy()
	end 
end

function ShopDetails:isClaimed()
	if self.claimingPlayerId then
		return true
	else
		return false
	end
end

-- TODO: At some point we will need to update this with the functionality for mutliple different player stores
function ShopDetails:onPlayerClaimed(playerDetails : Types.PlayerDetails) : ()
	self.claimPrompt.Enabled = false
	self.claimed = true
	self.claimingPlayerId = playerDetails.id
	self.instance:SetAttribute(Constants.SHOP_CLAIM_ATTRIBUTES.CLAIMED_BY, playerDetails.player.UserId)
	self.instance:SetAttribute(Constants.SHOP_CLAIM_ATTRIBUTES.CLAIMED_BOOL, true)
	self:_loadPlayerShopItems(playerDetails)
	
	--TODO: Make this more principled
	local shopModel = self.instance.Parent :: Model
	local shopFront = shopModel:WaitForChild("shopFront", 2) :: Model
	if shopFront then
		for _, child in pairs(shopFront:GetDescendants()) do
			if child:IsA("BasePart") and (child.Name == "door" or child.Name == "handles" or child.Name == "Part") then
				child.Transparency = 1
				child.CanCollide = false
			elseif child:IsA("SurfaceGui") then
				child.Enabled = false
			end
		end
	else
		warn("No shop front")
	end
end

-- 120.018, 96.947, -369

function ShopDetails:unclaim() : ()
	self:SaveState()
	self:removeAllShopItems()
	self.listOfShopItems = {}
	self.claimed = false
	self.claimingPlayerId = nil
	self.claimPrompt.Enabled = true
	self.instance:SetAttribute(Constants.SHOP_CLAIM_ATTRIBUTES.CLAIMED_BY, nil)
	self.instance:SetAttribute(Constants.SHOP_CLAIM_ATTRIBUTES.CLAIMED_BOOL, false)
	
	--TODO: Make this more principled
	local shopModel = self.instance.Parent :: Model
	local shopFront = shopModel:WaitForChild("shopFront", 2) :: Model
	if shopFront then
		for _, child in pairs(shopFront:GetDescendants()) do
			if child:IsA("BasePart") then
				if child.Name == "door" then
					child.Transparency = 0.5
					child.CanCollide = true
				elseif child.Name == "handles" then
					child.Transparency = 0
					child.CanCollide = true
				end
			elseif child:IsA("SurfaceGui") then
				child.Enabled = true
			end
		end		
	else
		warn("No shopfront")
	end

end

-- TODO: Rationalise this...
function ShopDetails:createShopItemRecipe(item: Types.BaseShopItem): Types.ShopItemRecipe?
	if not item.instance then
		return nil
	end
	
	local relativeItemCFrame = getRelativePosition(self.instance:GetPivot(), item.instance:GetPivot())
	local itemAttributes = serialiseAttributes(item.instance:GetAttributes())

	itemAttributes["skinColor"] = nil

	local shopItemRecipe = {
		itemName = item.instance.Name,
		itemType = item.itemType, 
		itemId = item.itemId,
		itemCFrame = serialiseCFrame(relativeItemCFrame),
		itemAttributes = itemAttributes,
		itemColour = item.instance:GetAttribute(Constants.ITEM_COLOUR_ATTRIBUTE),
	}

	return shopItemRecipe
end

-- TODO: Make this quicker by creating a table and then putting it into the player shop data all in one go.
function ShopDetails:SaveState()
	local newState = {}
	
	for itemId, item in pairs(self.listOfShopItems) do
		local shopItemRecipe = self:createShopItemRecipe(item) :: Types.ShopItemRecipe
		if not shopItemRecipe then
			warn("Failed to save", itemId, item)
		end

		newState[shopItemRecipe.itemId] = shopItemRecipe
	end
	
	-- TODO: Add a couple of tries here?
	local success, errorMessage = pcall(function()
		playerShopsDataStore:UpdateAsync(tostring(self.claimingPlayerId), function(oldData)
			local playerShopData = oldData or {}
			playerShopData[Constants.SHOP_ITEMS_KEY] = newState
			return playerShopData
		end) 
	end)
	if not success then
		warn("Failed to save new state: " .. errorMessage)
	end
end

function ShopDetails:addShopItem(shopItemRecipe : Types.ShopItemRecipe) : ()
	-- TODO: This is horrendous, fix at soonest possible date
	local newShopItem = ShopItemFactory.createShopItem(shopItemRecipe)
	if not newShopItem.instance then
		return
	end
	
	local itemId = shopItemRecipe.itemId or self:getUnusedItemId()
	newShopItem:initialiseItemId(itemId)
	newShopItem:initialisePosition(self.instance.CFrame) 

	newShopItem:onAddedToShop(self.id)  
	newShopItem.instance.Parent = self.shopItemFolder 
	newShopItem.instance:SetAttribute(Constants.SHOP_ITEM_OWNED_BY_ATTRIBUTE, self.claimingPlayerId)
	
	self.listOfShopItems[newShopItem.itemId] = newShopItem
end

function ShopDetails:getShopItemFromItemId(itemId : number) : Types.BaseShopItem?
	return self.listOfShopItems[itemId]
end

function ShopDetails:getUnusedItemId() : number
	local itemId
	repeat 
		itemId = getRandomIdNumber()
	until not self:getShopItemFromItemId(itemId)
	return itemId
end

function ShopDetails:_loadPlayerShopItems(playerDetails : Types.PlayerDetails)
	local playerShopData = playerDetails:getPlayerShopData()   
	if not playerShopData then
		-- TODO: do something here? 
		warn("Player has no shop data!")
		return
	end
	
	local playerShopItems = playerShopData[Constants.SHOP_ITEMS_KEY]
	if not playerShopItems then
		warn("No player shop items found to load")
		return
	end

	for id, shopItem in pairs(playerShopItems) do
		self:addShopItem(shopItem)
	end
end


function ShopDetails:removeShopItem(accessoryId : number) 
	local accessory = self:getShopItemFromItemId(accessoryId)
	if not accessory then 
		return 
	else
		accessory:Destroy()
		self.listOfShopItems[accessoryId] = nil
	end
end

function ShopDetails:isItemInShop(shopitem : Instance)
	return shopitem:IsDescendantOf(self.shopItemFolder)	
end

function ShopDetails:getShopItemFromId(itemId : number)
	return self.shopItemList:FindFirstChild(itemId)
end


return ShopDetails
