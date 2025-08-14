--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Folder
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Trackers = ReplicatedStorage:WaitForChild("Trackers")

-- Modules
local ShopTracker = require(Trackers:WaitForChild("ShopTracker"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local Types = require(Utility:WaitForChild("Types"))

local defaultNudge = 1
local defaultRotate = 45
local NUDGE_TWEEN_DURATION 	= 0.2

local BaseShopItem = {}
BaseShopItem.__index = BaseShopItem

local CFrameDict = {
	UP = CFrame.new(0, 0, defaultNudge),
	DOWN = CFrame.new(0, 0, -defaultNudge),
	LEFT = CFrame.new(defaultNudge, 0, 0),
	RIGHT = CFrame.new(-defaultNudge, 0, 0),
	PLUS45 = CFrame.fromEulerAnglesXYZ(0, math.rad(defaultRotate), 0),
	MINUS45 = CFrame.fromEulerAnglesXYZ(0, math.rad(-defaultRotate), 0)
}

function BaseShopItem.new(shopItemRecipe : Types.ShopItemRecipe) : Types.BaseShopItem
	local self = {} :: Types.BaseShopItem
	setmetatable(self, BaseShopItem)
	
	self.nudging = false
	self[Constants.ITEM_TYPE_ATTRIBUTE] = shopItemRecipe.itemType
	
	return self
end

function BaseShopItem:place()
	warn("BaseShopItem:place() not implemented")
end

function BaseShopItem:remove()
	warn("BaseShopItem:remove() not implemented")
end

function BaseShopItem:nudge(direction : string)
	if self.nudging then
		warn("Already nudging!")
		return
	end
	
	self.nudging = true
	
	local startCFrame = self.instance:GetPivot() :: CFrame

	local targetCFrame = startCFrame * CFrameDict[direction]
	if not targetCFrame then warn (`Invalid Direction {direction} at NudgeShopItem`) end

	local tweenInfo = TweenInfo.new(
		NUDGE_TWEEN_DURATION, -- Duration of the tween (in seconds)
		Enum.EasingStyle.Quad, -- Easing style
		Enum.EasingDirection.Out -- Easing direction
	)

	local tweenValue = Instance.new("CFrameValue")
	tweenValue.Value = startCFrame
	tweenValue.Parent = self.instance

	local tween = TweenService:Create(tweenValue, tweenInfo, { Value = targetCFrame })
	tweenValue.Changed:Connect(function()
		self.instance:PivotTo(tweenValue.Value)
	end)
	tween:Play()
	tween.Completed:Connect(function()
		self.instance:PivotTo(targetCFrame)
		tweenValue:Destroy()
		-- Save the mannequin's new position
		self.nudging = false
	end)
end

function BaseShopItem:isPlaced()
	warn("BaseShopItem:isPlaced() not implemented")
end

function BaseShopItem:initialisePosition(shopCFrame : CFrame)
	local relativeCFrame = shopCFrame:ToWorldSpace(self.instance:GetPivot())
	self.instance:PivotTo(relativeCFrame)
end

function BaseShopItem:initialiseItemId(itemId : number)
	self.itemId = itemId
	self.instance:SetAttribute(Constants.ITEM_ID_ATTRIBUTE, itemId)
	self.instance:SetAttribute(Constants.ITEM_TYPE_ATTRIBUTE, self.itemType)
end

function BaseShopItem:Destroy()
	self.instance:Destroy()
end

function BaseShopItem:Reposition(newCFrame : CFrame)
	local shop = ShopTracker.getShopFromShopId(self.shopId)
	if not shop then
		return
	end
	
	local shopPivot = shop.instance:GetPivot()
	
	local relativeCFrame = shopPivot:ToWorldSpace(newCFrame)
	self.instance:PivotTo(relativeCFrame)
end

function BaseShopItem:onAddedToShop(shopId : number)
	self.shopId = shopId
end

return BaseShopItem