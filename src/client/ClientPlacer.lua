--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CAS = game:GetService("ContextActionService")
local UIS = game:GetService("UserInputService")

-- Folders
local PreviewTemplate = ReplicatedStorage:WaitForChild("PreviewTemplates")
local Templates = ReplicatedStorage:WaitForChild("NewPreviewTemplates")
local Bindables = ReplicatedStorage:WaitForChild("Bindables")
local Trackers = ReplicatedStorage:WaitForChild("Trackers")
local Checkers = ReplicatedStorage:WaitForChild("Checkers")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Getters = ReplicatedStorage:WaitForChild("Getters")
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Bindables | Remotes
local PlayerClickedAddToShop = Bindables:WaitForChild("PlayerClickedAddToShop")
local RepositionShopItemBindable = Bindables:WaitForChild("RepositionShopItemBindable")
local PlayerDestroyedPreview = Bindables:WaitForChild("PlayerDestroyedPreview") 
local PlayerCreatedPreview = Bindables:WaitForChild("PlayerCreatedPreview")

local RepositionShopItemEvent = Remotes:WaitForChild("RepositionShopItem")
local PlayerPlacedShopItemAsync = Remotes:WaitForChild("PlayerPlacedShopItem")
local playerExitedShopAsync = Remotes:WaitForChild("PlayerExitedShop")

-- Templates | Placeholders
local mannequinPlaceholder = PreviewTemplate:WaitForChild("FullMannequin")

-- Module Scripts
local getRelativePosition 		= require(Utility:WaitForChild("getRelativePosition"))
local getShopNameFromPlayer = require(Getters:WaitForChild("getShopNameFromPlayer"))
local localPlayerDetails = require(Trackers:WaitForChild("localPlayerDetails"))
local getGroundYFromRay = require(Utility:WaitForChild("getGroundYFromRay"))
local isPointInRegion = require(Checkers:WaitForChild("isPointInRegion"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local playerHasShop = require(Getters:WaitForChild("playerHasShop"))
local ItemSelection = require(Utility:WaitForChild("ItemSelection"))
local Types = require(Utility:WaitForChild("Types"))


-- 3rd Party 
local Zone = require(Utility:WaitForChild("Zone"))
local ZoneController = require(Utility.Zone.ZoneController)

-- Misc. Variables
local camera = workspace.CurrentCamera
local castParams = RaycastParams.new()
castParams:AddToFilter(script.Parent)

local preview -- Global variable for the preview part
local currentId
local gridSize = 2 

local localPlayer = Players.LocalPlayer

-- Constants
local ROTATE_TWEEN_DURATION = 0.2
local DEFAULT_ROTATION_ANGLE = 45 
local VALID_COLOUR = Color3.new(0.0666667, 1, 0)
local INVALID_COLOUR = Color3.new(1, 0, 0)

local rotating = false


--

-- TODO: At some point it will probably make sense to object class this
-- e.g. local localPreview = LocalPreview.new(), preview.place(), etc etc

local function snapToGrid(position: Vector3, previewCFrame: CFrame)
	local snappedX = math.floor((position.X / gridSize) + 0.5) * gridSize
	local snappedY = getGroundYFromRay(position)
	local snappedZ = math.floor((position.Z / gridSize) + 0.5) * gridSize
	
	local newCFrame = CFrame.new(snappedX, snappedY, snappedZ) * previewCFrame.Rotation
	
	return newCFrame
end

-- TODO: Modularise this
-- Get the shop zone for a given player
local function getShopZoneForPlayer(player: Player)
	local shopName = getShopNameFromPlayer(player)
	local zonesArray = ZoneController.getGroup(Constants.SHOP_ZONE_GROUP_NAME)
	
	for _, zone in zonesArray._memberZones do
		if zone.Name == shopName then
			return zone 
		end
	end

	return nil 
end

local function isPositionInShop(position: Vector3): boolean
	local playerShopDetails = localPlayerDetails.getShopDetails()
	if not playerShopDetails then
		return false
	end
	
	local shopRegion = playerShopDetails.region
	
	return isPointInRegion(shopRegion, position)
end

local function setAllDescendantColours(Model : Model, colour : Color3)
	for _, descendant in Model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Color = colour
		end
	end
end

-- Creates a preview for placing objects in stores
local function renderPreview()
	if not preview then return end -- Ensure preview exists

	local mouseLocation = UIS:GetMouseLocation()
	local unitRay = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
	local cast = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, castParams)

	if cast and not rotating then
		-- Calculate the snapped position
		local snappedPosition = snapToGrid(cast.Position, preview.PrimaryPart.CFrame) 
		preview:PivotTo(snappedPosition)

		if isPositionInShop(preview:GetPivot().Position) then
			setAllDescendantColours(preview, VALID_COLOUR)
		else
			setAllDescendantColours(preview, INVALID_COLOUR)
		end
	end
end

-- Initialiases preview part
local function preparePreviewPart(modelToPreview: string): Model?
	if not modelToPreview then return nil end
	if not Templates[modelToPreview] then return nil end

	-- Get the preview part for model to place
	--local newPreview = PLACEHOLDER_DICTIONARY[modelToPreview]:Clone() :: BasePart
	local newPreview = Templates[modelToPreview]:Clone() :: Model
	if not newPreview then
		return nil
	end
	
	newPreview.Parent = workspace
	for _, child in newPreview:GetDescendants() do
		if child:IsA("BasePart") then	
			child.Transparency = 0.5 
			child.CanCollide = false
			child.CanQuery = false
		end
	end
	return newPreview
end


-- Rotate placement preview
local function rotatePreview(degrees: number)
	if not preview or rotating then return end
	
	rotating = true
	
	if not preview.PrimaryPart then
		assert(preview.PrimaryPart, "No primary part in model!")
		return
	end
	
	-- Calculate the target CFrame
	local currentCFrame = preview.PrimaryPart.CFrame
	local rotation = CFrame.Angles(0, math.rad(degrees), 0)
	local targetCFrame = currentCFrame * rotation

	-- Create a tween and play itA
	local tweenInfo = TweenInfo.new(
		ROTATE_TWEEN_DURATION, -- Duration of the tween (in seconds)
		Enum.EasingStyle.Quad, -- Easing style
		Enum.EasingDirection.Out -- Easing direction
	)
	
	local tween = TweenService:Create(
		preview.PrimaryPart, 
		tweenInfo, 
		{ CFrame = targetCFrame}
	)
	
	tween:Play()
	rotating = false
end

-- The below rotation functions rotate placement items by our assigned default rotation value
-- They are necessary because you cannot pass parameters in a Context Action Service binding


local function rotateMinus(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.End then return end
	rotatePreview(-DEFAULT_ROTATION_ANGLE)
end

local function rotatePlus(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.End then return end
	rotatePreview(DEFAULT_ROTATION_ANGLE)
end

local function unbindPreviewActions()
	CAS:UnbindAction("RotateMinus")
	CAS:UnbindAction("RotatePlus")
	CAS:UnbindAction("DestroyPreview")
	-- Unbind all actions in actionDictionary
	CAS:UnbindAction("place")
	CAS:UnbindAction("reposition")
end

-- Destroy placement preview
local function destroyPreview()
	if not preview then return end

	PlayerDestroyedPreview:Fire()
	preview:Destroy()
	preview = nil
	currentId = nil
	RunService:UnbindFromRenderStep("Preview")
	unbindPreviewActions()
	ItemSelection.unSelectItem()
end

local function bindPreviewActions()
	CAS:BindAction("RotateMinus", rotateMinus, false, Enum.KeyCode.Q)
	CAS:BindAction("RotatePlus", rotatePlus, false, Enum.KeyCode.E)
	CAS:BindAction("DestroyPreview", destroyPreview, false, Enum.UserInputType.MouseButton2)
end

local SerialisationUtilities = require(Utility:WaitForChild("SerialisationUtilities"))

local function place(_name, inputState, _inputObj)
	if inputState == Enum.UserInputState.Begin and preview then
		if isPositionInShop(preview:GetPivot().Position) then
			-- Relativise the preview's position
			local playerShopDetails = localPlayerDetails.getShopDetails()
			if not playerShopDetails then
				return
			end
			
			local relativePosition = getRelativePosition(playerShopDetails.instance:GetPivot(), preview:GetPivot()) 

			preview:PivotTo(relativePosition)
			
			local shopItemRecipe = {
				itemName = preview.Name,
				itemType = preview:GetAttribute(Constants.ITEM_TYPE_ATTRIBUTE),
				itemCFrame = SerialisationUtilities.serialiseCFrame(preview:GetPivot()),
				colour = nil,
				itemId = nil,
				attributes = nil,
			} :: Types.ShopItemRecipe
			
			PlayerPlacedShopItemAsync:FireServer(shopItemRecipe) 
			destroyPreview()
		else
			warn("Invalid position!", preview:GetPivot().Position)
		end
	end
end

-- Place a repositioned item
local function reposition(_name, inputState, _inputObj)
	if inputState == Enum.UserInputState.Begin and preview then
		if isPositionInShop(preview:GetPivot().Position) then	
			-- Relativise the preview's position
			local playerShopDetails = localPlayerDetails.getShopDetails()
			if not playerShopDetails then
				return
			end
			
			local relativePosition = getRelativePosition(playerShopDetails.instance:GetPivot(), preview:GetPivot()) 

			
				RepositionShopItemEvent:FireServer(ItemSelection.getSelectedItemId(), SerialisationUtilities.serialiseCFrame(relativePosition))
				ItemSelection.unSelectItem()
				destroyPreview()
			else
				warn("Invalid position!", preview:GetPivot().Position)
			end
	end
end

local actionDictionary = {
	place = place,
	reposition = reposition
}

-- Creates a preview for object placement
local function createPreview(modelToPreview: string, modelType: string, actionToTake: string)
	if preview then warn("Already previewing!") return end 

	local actionFunction = actionDictionary[actionToTake]
	if not actionFunction then warn("No relevant place command") return end

	PlayerCreatedPreview:Fire()
	preview = preparePreviewPart(modelToPreview) :: Model 
	if not preview then warn("couldn't prepare a preview part!") return end
	
	preview:SetAttribute(Constants.ITEM_TYPE_ATTRIBUTE, modelType)
	RunService:BindToRenderStep("Preview", Enum.RenderPriority.Camera.Value, renderPreview)
	CAS:BindAction(actionToTake, actionFunction, false, Enum.UserInputType.MouseButton1)
	bindPreviewActions()
end

PlayerClickedAddToShop.Event:Connect(createPreview)
RepositionShopItemBindable.Event:Connect(createPreview)
playerExitedShopAsync.OnClientEvent:Connect(destroyPreview)