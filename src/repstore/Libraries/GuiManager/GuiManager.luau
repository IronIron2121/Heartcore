--!strict

-- Minimal modal manager for catalog-only places.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utility = ReplicatedStorage:WaitForChild("Utility")
local Fusion = require(Utility:WaitForChild("Fusion"))

local Children = Fusion.Children
local peek = Fusion.peek

type ModalEntry = {
	guiObject: GuiObject,
	callback: ((any?) -> ())?,
}

local TWEEN_LENGTH = 0.25
local ON_SCREEN_POSITION = UDim2.fromScale(0.5, 0.5)
local OFF_SCREEN_POSITION = UDim2.fromScale(0.5, 1.65)

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
	return if use(centreActive) then 16 else 0
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
local notificationText = guiScope:Value("")
local yesCallback = guiScope:Value(function() end)
local noCallback = guiScope:Value(function() end)

local notificationGui = guiScope:New "ScreenGui" {
	Name = "NotificationGui",
	DisplayOrder = 30,
	Enabled = true,
	IgnoreGuiInset = true,
	Parent = playerGui,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,

	[Children] = {
		guiScope:New "Frame" {
			Name = "InputSink",
			Active = notificationActive,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.35,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			Visible = notificationActive,
			ZIndex = 1,
		},

		guiScope:New "Frame" {
			Name = "NotificationPanel",
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.new(1, 1, 1),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.32, 0.22),
			Visible = notificationActive,
			ZIndex = 2,

			[Children] = {
				guiScope:New "UICorner" {
					CornerRadius = UDim.new(0, 8),
				},

				guiScope:New "UIPadding" {
					PaddingBottom = UDim.new(0, 16),
					PaddingLeft = UDim.new(0, 16),
					PaddingRight = UDim.new(0, 16),
					PaddingTop = UDim.new(0, 16),
				},

				guiScope:New "UIListLayout" {
					FillDirection = Enum.FillDirection.Vertical,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					Padding = UDim.new(0, 12),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				},

				guiScope:New "TextLabel" {
					BackgroundTransparency = 1,
					LayoutOrder = 1,
					Size = UDim2.fromScale(1, 0.55),
					Text = notificationText,
					TextColor3 = Color3.fromRGB(48, 42, 77),
					TextScaled = true,
					TextWrapped = true,
				},

				guiScope:New "Frame" {
					BackgroundTransparency = 1,
					LayoutOrder = 2,
					Size = UDim2.fromScale(1, 0.3),

					[Children] = {
						guiScope:New "UIListLayout" {
							FillDirection = Enum.FillDirection.Horizontal,
							HorizontalAlignment = Enum.HorizontalAlignment.Center,
							Padding = UDim.new(0, 12),
							SortOrder = Enum.SortOrder.LayoutOrder,
							VerticalAlignment = Enum.VerticalAlignment.Center,
						},

						guiScope:New "TextButton" {
							BackgroundColor3 = Color3.fromRGB(91, 83, 207),
							LayoutOrder = 1,
							Size = UDim2.fromScale(0.35, 0.8),
							Text = "Yes",
							TextColor3 = Color3.new(1, 1, 1),

							[Fusion.OnEvent "Activated"] = function()
								notificationActive:set(false)
								peek(yesCallback)()
							end,

							[Children] = {
								guiScope:New "UICorner" {
									CornerRadius = UDim.new(0, 6),
								},
							},
						},

						guiScope:New "TextButton" {
							BackgroundColor3 = Color3.fromRGB(232, 232, 241),
							LayoutOrder = 2,
							Size = UDim2.fromScale(0.35, 0.8),
							Text = "No",
							TextColor3 = Color3.fromRGB(48, 42, 77),

							[Fusion.OnEvent "Activated"] = function()
								notificationActive:set(false)
								peek(noCallback)()
							end,

							[Children] = {
								guiScope:New "UICorner" {
									CornerRadius = UDim.new(0, 6),
								},
							},
						},
					},
				},
			},
		},
	},
}

local GuiManager = {}

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
	_notificationName: string,
	message: string,
	onConfirm: () -> (),
	onCancel: (() -> ())?
)
	notificationText:set(message)
	yesCallback:set(onConfirm)
	noCallback:set(onCancel or function() end)
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
