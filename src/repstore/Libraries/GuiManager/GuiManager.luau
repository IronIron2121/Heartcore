--!strict

-- Minimal modal manager for catalog-only places.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataTables = ReplicatedStorage:WaitForChild("DataTables")
local UI = ReplicatedStorage:WaitForChild("UI")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local FusionComponents = UI:WaitForChild("FusionComponents")

local Fusion = require(Utility:WaitForChild("Fusion"))
local FusionImageButton = require(FusionComponents:WaitForChild("FusionImageButton"))
local ImageUris = require(DataTables:WaitForChild("ImageUris"))
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))

local Children = Fusion.Children
local peek = Fusion.peek

type ModalEntry = {
	guiObject: GuiObject,
	callback: ((any?) -> ())?,
}

local TWEEN_LENGTH = 0.4
local ON_SCREEN_POSITION = UDim2.fromScale(0.5, 0.5)
local OFF_SCREEN_POSITION = UDim2.fromScale(0.5, 3)
local NOTIFICATION_OFF_SCREEN_POSITION = UDim2.fromScale(0.5, -5)

local guiScope = Fusion:scoped()
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local isLoaded = false
local registeredModals: {[string]: ModalEntry} = {}
local registeredConfigurations: {[string]: any} = {}
local currentConfiguration: any? = nil
local currentConfigurationName = guiScope:Value(nil :: string?)
local modalStack = guiScope:Value({} :: {GuiObject})

local centreActive = guiScope:Computed(function(use)
	return #use(modalStack) > 0
end)

local modalPosition = guiScope:Computed(function(use)
	return if use(centreActive) then ON_SCREEN_POSITION else OFF_SCREEN_POSITION
end)

local blurSize = guiScope:Computed(function(use)
	return if use(centreActive) then 24 else 0
end)

local hudContainer = guiScope:New "ScreenGui" {
	Name = "HudGui",
	DisplayOrder = 3,
	Enabled = true,
	IgnoreGuiInset = true,
	Parent = playerGui,
	ZIndexBehavior = Enum.ZIndexBehavior.Global,
}

local modalGui = guiScope:New "ScreenGui" {
	Name = "ModalGui",
	DisplayOrder = 20,
	Enabled = true,
	IgnoreGuiInset = false,
	Parent = playerGui,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}

local modalContainer = guiScope:New "Frame" {
	Name = "ModalContainer",
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundTransparency = 1,
	Parent = modalGui,
	Position = guiScope:Tween(modalPosition, TweenInfo.new(TWEEN_LENGTH, Enum.EasingStyle.Quad)),
	Size = UDim2.fromScale(1, 1),
}

local _modalBlur = guiScope:New "BlurEffect" {
	Name = "ModalBackgroundBlur",
	Enabled = true,
	Parent = Lighting,
	Size = guiScope:Tween(blurSize, TweenInfo.new(TWEEN_LENGTH, Enum.EasingStyle.Quad)),
}

local notificationActive = guiScope:Value(false)

local notificationPosition = guiScope:Computed(function(use)
	return if use(notificationActive) then ON_SCREEN_POSITION else NOTIFICATION_OFF_SCREEN_POSITION
end)

local notificationText = guiScope:Value("")

local notificationTextLabel = guiScope:New "TextLabel" {
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 1,
	FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Regular),
	Name = "notificationTextLabel",
	Size = UDim2.fromScale(1, 0.5),
	Text = notificationText,
	TextColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
	TextScaled = true,
	TextSize = 50,
	TextWrapped = true,

	[Children] = {
		guiScope:New "UICorner" {
			CornerRadius = UDim.new(0.05, 0),
		},

		guiScope:New "UIStroke" {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
			Color = UI_CONSTANTS.TASTEMAKER_GREEN,
			Thickness = 3,
		},
	},
}

local yesCallback = guiScope:Value(function()
	warn("No callback currently assigned to YES button")
end)

local notificationYesButton = FusionImageButton(guiScope, {
	name = "notificationYesButton",
	backgroundTransparency = 1,
	image = ImageUris.ConfirmButton,
	onActivated = yesCallback,
	position = UDim2.fromScale(0.35, 0.5),
	size = UDim2.fromScale(0.5, 0.5),
	visible = true,
})

local noCallback = guiScope:Value(function()
	print("No callback currently assigned to no button")
end)

local notificationNoButton = FusionImageButton(guiScope, {
	name = "notificationNoButton",
	backgroundTransparency = 1,
	image = ImageUris.CloseButton,
	onActivated = noCallback,
	position = UDim2.fromScale(0.65, 0.5),
	size = UDim2.fromScale(0.5, 0.5),
	visible = true,
})

local notificationButtonContainer = guiScope:New "Frame" {
	Name = "notificationButtonContainer",
	BackgroundTransparency = 1,
	LayoutOrder = 2,
	Size = UDim2.fromScale(1, 0.5),
	Visible = true,

	[Children] = {
		notificationYesButton,
		notificationNoButton,
	},
}

local notificationMessageContainer = guiScope:New "Frame" {
	Name = "NotificationMessageContainer",
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 0.2,
	LayoutOrder = 2,
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.3, 0.3),
	ZIndex = 1,

	[Children] = {
		notificationTextLabel,
		notificationButtonContainer,

		guiScope:New "UIListLayout" {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		},

		guiScope:New "UICorner" {
			CornerRadius = UDim.new(0.05, 0),
		},

		guiScope:New "UIPadding" {
			PaddingLeft = UDim.new(0.1, 0),
			PaddingRight = UDim.new(0.1, 0),
		},
	},
}

local notificationContainer = guiScope:New "Frame" {
	Name = "notificationContainer",
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundTransparency = 1,
	LayoutOrder = 1,
	Position = guiScope:Spring(notificationPosition, 10, 0.8),
	Size = UDim2.fromScale(1, 1),
	Visible = true,
	ZIndex = 2,

	[Children] = {
		notificationMessageContainer,
	},
}

local inputSinkTransparency = guiScope:Computed(function(use)
	return if use(notificationActive) then 0.4 else 1
end)

local notificationInputSink = guiScope:New "Frame" {
	Name = "notificationInputSink",
	Active = notificationActive,
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = guiScope:Tween(inputSinkTransparency, TweenInfo.new(TWEEN_LENGTH, Enum.EasingStyle.Quad)),
	LayoutOrder = 1,
	Position = ON_SCREEN_POSITION,
	Size = UDim2.fromScale(1, 1),
	Visible = notificationActive,
	ZIndex = 1,
}

local _notificationGui = guiScope:New "ScreenGui" {
	Name = "NotificationGui",
	DisplayOrder = 30,
	Enabled = true,
	IgnoreGuiInset = true,
	Parent = playerGui,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,

	[Children] = {
		notificationContainer,
		notificationInputSink,
	},
}

local GuiManager = {}
local hiddenNotifications: {[string]: boolean} = {}

function GuiManager.IsLoaded(): boolean
	return isLoaded
end

function GuiManager.SetLoaded()
	isLoaded = true
end

function GuiManager.RegisterModal(objectName: string, guiObject: GuiObject, onActivated: ((any?) -> ())?)
	assert(objectName and guiObject, "Inadequate information to register modal")

	registeredModals[objectName] = {
		guiObject = guiObject,
		callback = onActivated,
	}

	guiObject.AnchorPoint = Vector2.new(0.5, 0.5)
	guiObject.Parent = modalContainer
	guiObject.Visible = false
end

function GuiManager.GetRegisteredModal(modalName: string): ModalEntry
	return registeredModals[modalName]
end

function GuiManager.PushCentreByName(modalName: string, params: any?)
	if not isLoaded then
		warn("Still initialising GUI")
		return
	end

	local modalToPush = registeredModals[modalName]
	assert(modalToPush, "Attempt to push unregistered modal " .. modalName)

	local currentModals = table.clone(peek(modalStack))
	if table.find(currentModals, modalToPush.guiObject) then
		return
	end

	if #currentModals > 0 then
		currentModals[#currentModals].Visible = false
	elseif currentConfiguration and currentConfiguration.HideForModal then
		currentConfiguration:HideForModal()
	end

	table.insert(currentModals, modalToPush.guiObject)
	modalToPush.guiObject.Visible = true
	modalStack:set(currentModals)

	if modalToPush.callback then
		modalToPush.callback(params)
	end
end

function GuiManager.PopCentre()
	local currentModals = table.clone(peek(modalStack))
	if #currentModals == 0 then
		return
	end

	local topModal = currentModals[#currentModals]
	table.remove(currentModals, #currentModals)

	if #currentModals > 0 then
		topModal.Visible = false
		currentModals[#currentModals].Visible = true
	elseif currentConfiguration and currentConfiguration.ShowFromModal then
		currentConfiguration:ShowFromModal()
		task.delay(TWEEN_LENGTH, function()
			topModal.Visible = false
		end)
	else
		task.delay(TWEEN_LENGTH, function()
			topModal.Visible = false
		end)
	end

	modalStack:set(currentModals)
end

function GuiManager.IsCentreActive(): boolean
	return peek(centreActive)
end

function GuiManager.GetCentreActiveValue()
	return centreActive
end

function GuiManager.IsModalActive(modal: GuiObject): boolean
	return table.find(peek(modalStack), modal) ~= nil
end

function GuiManager.RegisterConfiguration(config: any)
	registeredConfigurations[config.Name] = config
	if config.ConfigurationContainer then
		config.ConfigurationContainer.Parent = hudContainer
	end
end

function GuiManager.DisplayConfiguration(configurationName: string)
	if currentConfiguration and currentConfiguration.Disable then
		currentConfiguration:Disable()
	end

	currentConfiguration = registeredConfigurations[configurationName]
	currentConfigurationName:set(configurationName)

	if currentConfiguration and currentConfiguration.Enable then
		currentConfiguration:Enable(peek(centreActive))
	end
end

function GuiManager.HideCurrentConfiguration()
	if currentConfiguration and currentConfiguration.HideForModal then
		currentConfiguration:HideForModal()
	end
end

function GuiManager.ShowCurrentConfiguration()
	if currentConfiguration and currentConfiguration.ShowFromModal then
		currentConfiguration:ShowFromModal()
	end
end

function GuiManager.ForceHideCurrentConfiguration()
	if currentConfiguration and currentConfiguration.HideAll then
		currentConfiguration:HideAll()
	end
end

function GuiManager.ForceShowCurrentConfiguration()
	if currentConfiguration and currentConfiguration.ShowAll then
		currentConfiguration:ShowAll()
	end
end

function GuiManager.GetCurrentConfigurationNameValue()
	return currentConfigurationName
end

function GuiManager.PushNotificationCentre(
	notificationName: string,
	message: string,
	yesCb: () -> (),
	noCb: (() -> ())?,
	_showAgain: boolean?
)
	if hiddenNotifications[notificationName] then
		return
	end

	if peek(notificationActive) then
		warn("Notification already active!")
		return
	end

	notificationText:set(message)
	yesCallback:set(function()
		GuiManager.PopNotification()
		GuiManager.ResetNotificationDetails()
		yesCb()
	end)
	noCallback:set(function()
		GuiManager.PopNotification()
		GuiManager.ResetNotificationDetails()
		if noCb then
			noCb()
		end
	end)
	notificationActive:set(true)
end

function GuiManager.PopNotification()
	notificationActive:set(false)
end

function GuiManager.ResetNotificationDetails()
	notificationText:set("")
	yesCallback:set(function() end)
	noCallback:set(function() end)
end

function GuiManager.PushMessageCentre(_messageName: string, message: string, closeCb: (() -> ())?, messageLength: number?)
	task.delay(messageLength or 3, function()
		if closeCb then
			closeCb()
		end
	end)
	print(message)
end

function GuiManager.QueueMessage(messageName: string, message: string, closeCb: (() -> ())?, messageLength: number?)
	GuiManager.PushMessageCentre(messageName, message, closeCb, messageLength)
end

function GuiManager.PopMessage() end
function GuiManager.doTransition(_phaseName: string) end

return GuiManager
