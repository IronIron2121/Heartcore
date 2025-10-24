--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

-- Folders
local UI = ReplicatedStorage:WaitForChild("UI")
local Objects = UI:WaitForChild("Objects")
local Libraries = ReplicatedStorage:WaitForChild("Libraries")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local getItemIcon = require(Utility:WaitForChild("getItemIcon"))

-- GUI Components
local AccessoryTileTemplate = Objects:WaitForChild("AccessoryTileFrame")

-- Remotes / Bindables
local purchaseRemote = Remotes:WaitForChild("Purchase")

-- Constants
local BUY_BUTTON_VISIBLE_TIME = 5
local DEFAULT_X_SCALE = 0.1
local DEFAULT_Y_SCALE = 0.1


function AccessoryTile(itemId : number, itemType : Enum.MarketplaceProductType)
	local productInfo = MarketplaceService:GetProductInfo(itemId)
	
	local accessoryTile = AccessoryTileTemplate:Clone()
	
	accessoryTile.Size = UDim2.fromScale(DEFAULT_X_SCALE, DEFAULT_Y_SCALE)
	
	local buyButton = accessoryTile:WaitForChild("BuyButton")
	local imageButton = accessoryTile:WaitForChild("ImageButton")
	imageButton.UICorner.CornerRadius = UDim.new(0.2, 0)
	local deleteButton = accessoryTile:WaitForChild("DeleteButton")
	
	imageButton.Image = getItemIcon(itemId, itemType)
	
	local function Destroy()
		accessoryTile:Destroy()
	end
	
	local function onDeleteButtonActivated()
		Destroy()
	end
	
	local function onButtonActivated()
		task.spawn(function()
			buyButton.Visible = true
			task.wait(BUY_BUTTON_VISIBLE_TIME)
			buyButton.Visible = false
		end)

	end
	
	local function onBuyButtonActivated()
		purchaseRemote:FireServer(itemId, itemType)
	end

	imageButton.Activated:Connect(onButtonActivated)
	buyButton.Activated:Connect(onButtonActivated)
	deleteButton.Activated:Connect(onDeleteButtonActivated)
	
	return accessoryTile
end

return AccessoryTile
