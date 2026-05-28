--!strict

--[[
    GuiManager.luau
    This script manages the whole player GUI.

]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting          = game:GetService("Lighting")
local Players           = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")

-- Folders
local BindablesFolder = ReplicatedStorage:WaitForChild("Bindables")
local Utility   = ReplicatedStorage:WaitForChild("Utility")
local UI            = ReplicatedStorage:WaitForChild("UI")
local Widgets       = UI.FusionComponents.Widgets
local DataTables    = ReplicatedStorage:WaitForChild("DataTables")

-- Modules
local Constants = require(ReplicatedStorage.Constants)
local GameStates = require(ReplicatedStorage.GameLoop.GameStates)
local Children = require(ReplicatedStorage.Utility.Fusion.Instances.Children)
local parseError = require(ReplicatedStorage.Utility.Fusion.Logging.parseError)
local PlayerDisplayManager = require(StarterPlayer.StarterPlayerScripts.GUI.PlayerDisplayManager)
local ImageUris     = require(DataTables:WaitForChild("ImageUris"))
local UI_CONSTANTS  = require(Utility:WaitForChild("UI_CONSTANTS"))
local Types         = require(Utility.Types)

-- UI Modules
local FusionImageButton = require(Widgets.FusionImageButton)

-- Fusion
local Fusion        = require(Utility.Fusion)
local guiScope      = Fusion:scoped()
local peek          = Fusion.peek
type UsedAs<T>      = Fusion.UsedAs<T>
type Value<T>       = Fusion.Value<T>
type Computed<T>    = Fusion.Computed<T>

-- Bindables
local HideAllPromptsBindable   = BindablesFolder:WaitForChild("HideAllPromptsBindable")
local ShowAllPromptsBindable   = BindablesFolder:WaitForChild("ShowAllPromptsBindable")
local transitionCompletedEvent = BindablesFolder:WaitForChild("TransitionCompleted") :: BindableEvent

-- Instances
local localPlayer = Players.LocalPlayer

-- GUI Elements
local PlayerGui = localPlayer.PlayerGui 

-- Constants
local OFF_SCREEN_POSITION = UDim2.fromScale(0.5, 3)
local ON_SCREEN_POSITION = UDim2.fromScale(0.5, 0.5)
local TWEEN_LENGTH = 0.4
local NOTIFICATION_OFF_SCREEN_POSITION = UDim2.fromScale(0.5, -5)

--

local currentConfiguration: Types.GuiConfiguration? = nil
local currentConfigurationName: Value<string?> = guiScope:Value(nil)
local registeredConfigurations: {[string]: Types.GuiConfiguration} = {}

local HudContainer = guiScope:New "ScreenGui" {
    Name = "HudGui",
    IgnoreGuiInset = true,
    Enabled = true,
    Parent = PlayerGui,
    ZIndexBehavior = Enum.ZIndexBehavior.Global,
    DisplayOrder = 3
}

local registeredModals: {[string]: {guiObject: GuiObject, callback: (any?) -> (any?)?}} = {}
local modalStack: Value<{GuiObject}> = guiScope:Value({})

local CentreActive = guiScope:Computed(function(use) 
        return #use(modalStack) ~= 0
    end
)

-- —— Modal ——————————————————————————————————————————————————————————————————————

local modalPosition = guiScope:Computed(function(use) : Fusion.UsedAs<UDim2>
    return use(CentreActive) and ON_SCREEN_POSITION or OFF_SCREEN_POSITION 
end)

local modalTween = guiScope:Tween(modalPosition, TweenInfo.new(TWEEN_LENGTH, Enum.EasingStyle.Quad)) 

local ModalGui = guiScope:New "ScreenGui" {
    Name = "ModalGui",
    Enabled = true,
    Parent = PlayerGui,
    IgnoreGuiInset = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 2

} :: ScreenGui

local blurSize: Computed<number> = guiScope:Computed(function(use) 
    return use(CentreActive) and 24 or 0
end)

local modalContainer = guiScope:New "Frame" {
    Name = "ModalContainer",
    AnchorPoint = Vector2.new(0.5,0.5),
    Position = modalTween,
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Parent = ModalGui,
}

-- —— Transitions ————————————————————————————————————————————————————————————————
local tweenTime = Constants.TransitionTweenTime
local transitionTime = Constants.TransitionTotalTime

local messageValue = guiScope:Value("")
local messageLabel = guiScope:New "TextLabel" {
    Name = "textLabel",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    TextColor3 = UI_CONSTANTS.COLOUR_WHITE,
    FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Regular),
    Text = messageValue,
    TextWrapped = false,
    TextScaled = true,
    ZIndex = 1,
    [Children] = {
        guiScope:New "UIStroke" {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
            LineJoinMode = Enum.LineJoinMode.Round,
            Transparency = 0,
            Color = UI_CONSTANTS.TASTEMAKER_GREEN,
            Thickness = 3,
        }
    }
}

local veilSizes = {
    ['IN'] = UDim2.fromScale(1, 1),
    ['OUT'] = UDim2.fromScale(0, 1)
}

local veilSize = guiScope:Value(
    veilSizes.IN
)
local veilFrame = guiScope:New "Frame" {
    Name = "veilFrame",
    Size = guiScope:Tween(
        veilSize,
        TweenInfo.new(tweenTime)
    ),
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.fromScale(1, 0.5),
    BackgroundColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
    BackgroundTransparency = 0,
    ZIndex = 2
}


local messageVisible = guiScope:Value(false)
local messagePositions = {
    ['IN'] = UDim2.fromScale(0.5, 0.5),
    ['OUT'] = UDim2.fromScale(0.5, -0.5)
}
local messagePosition = guiScope:Value(
    messagePositions.OUT
)
local messageSizes = {
    ['IN'] = UDim2.fromScale(1, 0.5),
    ['OUT'] = UDim2.fromScale(0, 0)
}
local messageSize = guiScope:Value(messageSizes.OUT)

local messageRotation = guiScope:Value(0)

task.spawn(function()
    while true do
        messageRotation:set(10)
        task.wait(0.5)
        messageRotation:set(-10)
        task.wait(0.5)
    end
end)

local messageContainer = guiScope:New "Frame" {
    Name = "messageContainer",
    BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = guiScope:Tween(
        messagePosition, 
        TweenInfo.new(0.5)
    ),
    Size = guiScope:Tween(
        messageSize,
        TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
    ),
    Rotation = guiScope:Tween(
        messageRotation,
        TweenInfo.new(2, Enum.EasingStyle.Quad)
    ),
    Visible = messageVisible,
    [Children] = {
        --veilFrame,
        messageLabel
    }
}

local leftWingPositions = {
    ['IN'] = UDim2.fromScale(0.5, 0.5),
    ['OUT'] = UDim2.fromScale(-0.5, 0.5)
}
local leftWingPos = guiScope:Value(
    leftWingPositions.OUT
)
local leftWingTween = guiScope:Tween(
    leftWingPos,
    TweenInfo.new(tweenTime)
)
local leftTransitionWing = guiScope:New "Frame" {
    Name = "leftTransitionWing",
    BackgroundColor3 = UI_CONSTANTS.COLOUR_WHITE,
    BackgroundTransparency = 0,
    AnchorPoint = Vector2.new(1, 0.5),
    Size = UDim2.fromScale(0.5, 1),
    Position = leftWingTween,

    [Children] = {
        guiScope:New "UIGradient" {
            Color = ColorSequence.new(
                Color3.fromRGB(176, 183, 253), 
                UI_CONSTANTS.TASTEMAKER_PURPLE
            ),
            Offset = Vector2.new(5,0)
        }
    }
}

local rightWingPositions = {
    ['IN'] = UDim2.fromScale(0.5, 0.5),
    ['OUT'] = UDim2.fromScale(1.5, 0.5)
}
local rightWingPos = guiScope:Value(
    rightWingPositions.OUT
)
local rightWingTween = guiScope:Tween(
    rightWingPos,
    TweenInfo.new(tweenTime)
)
local rightTransitionWing = guiScope:New "Frame" {
    Name = "rightTransitionWing",
    BackgroundColor3 = UI_CONSTANTS.COLOUR_WHITE,
    BackgroundTransparency = 0,
    AnchorPoint = Vector2.new(0, 0.5),
    Size = UDim2.fromScale(0.5, 1),
    Position = rightWingTween,
    [Children] = {
        guiScope:New "UIGradient" {
            Color = ColorSequence.new(
                UI_CONSTANTS.TASTEMAKER_PURPLE,
                Color3.fromRGB(176, 183, 253)
            ),
            Offset = Vector2.new(5,0)
        }
    }
}
local transitionGui = guiScope:New "ScreenGui" {
    Name = "TransitionGui", 
    Enabled = true,
    Parent = PlayerGui,
    IgnoreGuiInset = true,
    DisplayOrder = 209,
    [Children] = {
        leftTransitionWing,
        rightTransitionWing,
        messageContainer
    }
}

-- —— Modal ——————————————————————————————————————————————————————————————————————

local BackgroundBlur = guiScope:New "BlurEffect" {
    Archivable = true,
    Name = "ModalBackgroundBlur",
    Parent = Lighting,
    Enabled = true,
    Size = guiScope:Tween(blurSize, TweenInfo.new(TWEEN_LENGTH, Enum.EasingStyle.Quad))
} :: BlurEffect


-- —— Notification Manager————————————————————————————————————————————————————————

local notificationActive = guiScope:Value(false)

local notificationPosition = guiScope:Computed(function(use)
    return use(notificationActive) and ON_SCREEN_POSITION or NOTIFICATION_OFF_SCREEN_POSITION
end)

local notificationText = guiScope:Value("")

local notificationTextLabel = guiScope:New "TextLabel" {
    BackgroundTransparency = 1,
    Name = "notificationTextLabel",
    Text = notificationText,
    FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT,Enum.FontWeight.Regular),
    Size = UDim2.fromScale(1, 0.5),
    TextScaled = true,
    TextWrapped = true,
    TextColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
    TextSize = 50,
    BackgroundColor3 = Color3.new(0,0,0),
    [Children] = {
        guiScope:New "UICorner" {
            CornerRadius = UDim.new(0.05, 0)
        }
    }
}

local yesCallback = guiScope:Value(function()
    warn("No callback current assigned to YES button")
end)
local notificationYesButton = FusionImageButton(guiScope, {
    name = "notificationYesButton",
    visible = true,
    backgroundTransparency = 1,
    image = ImageUris.ConfirmButton,
    size = UDim2.fromScale(0.5, 0.5),
    onActivated = yesCallback

})
local noCallback = guiScope:Value(function()
    warn("No callback current assigned to no button")
end)
local notificationNoButton = FusionImageButton(guiScope, {
    name = "notificationNoButton",
    visible = true,
    backgroundTransparency = 1,
    image = ImageUris.CloseButton,
    size = UDim2.fromScale(0.5, 0.5),
    onActivated = noCallback
})

local notificationButtonContainer = guiScope:New "Frame" {
    Name = "notificationButtonContainer",
    Visible = true,
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 0.5),
    LayoutOrder = 2,
    [Children] = {
        guiScope:New "UIListLayout" {
            SortOrder = Enum.SortOrder.LayoutOrder,
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
        },
        notificationYesButton,
        notificationNoButton
    }
}

local notificationMessageContainer = guiScope:New "Frame" {
    Name = "NotificationMessageContainer",
    LayoutOrder = 2,
    BackgroundColor3 = Color3.new(1, 1, 1),
    BackgroundTransparency = 0.2,
    AnchorPoint = Vector2.new(0.5,0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    ZIndex = 1,
    Size = UDim2.fromScale(0.3, 0.3),

    [Children] = {
        notificationTextLabel,
        notificationButtonContainer,
        guiScope:New "UIListLayout" {
            SortOrder = Enum.SortOrder.LayoutOrder,
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
        },
        guiScope:New "UICorner" {
            CornerRadius = UDim.new(0.05, 0)
        },
        guiScope:New "UIPadding" {
            PaddingLeft = UDim.new(0.1,0),
            PaddingRight = UDim.new(0.1,0)
        }
    }
}

local notificationContainer = guiScope:New "Frame" {
    Name = "notificationContainer",
    Visible = true,
    LayoutOrder = 1,
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1,
    Position = guiScope:Spring(notificationPosition, 10, 0.8),
    ZIndex = 2,
    Size = UDim2.fromScale(1, 1),
    [Children] = {
        notificationMessageContainer
    }
}

local inputSinkTransparency = guiScope:Computed(function(use)
    return use(notificationActive) and 0.4 or 1
end)

local notificationInputSink = guiScope:New "Frame" {
    Name = "notificationContainer",
    Visible = notificationActive,
    Active = notificationActive,
    LayoutOrder = 1,
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = Color3.new(0,0,0),
    BackgroundTransparency = guiScope:Tween(inputSinkTransparency, TweenInfo.new(TWEEN_LENGTH, Enum.EasingStyle.Quad)),
    Position = ON_SCREEN_POSITION,
    ZIndex = 1,
    Size = UDim2.fromScale(1, 1),
}

local NotificationGui = guiScope:New "ScreenGui" {
    Name = "NotificationGui",
    Enabled = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
    DisplayOrder = 3,
    Parent = PlayerGui,
    [Children] = {
        notificationContainer,
        notificationInputSink
    }
}
-- ## NOTIFICATION MANAGER END -- ##

local isLoaded = false
local GuiManager = {} 
local hiddenNotifications = {

}

function GuiManager.ResetNotificationDetails()
    notificationText:set("")
    yesCallback:set(function()
        return
    end)
    noCallback:set(function()
        return
    end)
end

function GuiManager.PushNotificationCentre(notificationName: string, message: string, yesCb: () -> (), noCb: () -> ()?, showAgain: boolean?)
    if hiddenNotifications[notificationName] then
        -- TODO
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

function GuiManager.IsLoaded()
    return isLoaded
end

function GuiManager.SetLoaded()
    isLoaded = true
end

function GuiManager.DisplayConfiguration(configurationName: string): ()
    if currentConfiguration then
        currentConfiguration:Disable()
    end

    local newConfiguration = registeredConfigurations[configurationName]
    currentConfiguration = newConfiguration
    currentConfigurationName:set(configurationName)
    currentConfiguration:Enable(peek(CentreActive))
end
 
function GuiManager.HideCurrentConfiguration(): ()
    if currentConfiguration then
        currentConfiguration:HideForModal()
    end
end

function GuiManager.ShowCurrentConfiguration(): ()
    if currentConfiguration then
        currentConfiguration:ShowFromModal()
    end
end

function GuiManager.ForceHideCurrentConfiguration(): ()
    if currentConfiguration then
        currentConfiguration:HideAll()
    end
end

function GuiManager.ForceShowCurrentConfiguration(): ()
    if currentConfiguration then
        currentConfiguration:ShowAll()
    end
end

function GuiManager.GetCurrentConfigurationNameValue(): Value<string?>
    return currentConfigurationName
end

function GuiManager.IsModalActive(modal: GuiObject): boolean
    return table.find(peek(modalStack), modal) ~= nil
end

function GuiManager.GetCentreActiveValue(): Fusion.Computed<boolean>
    return CentreActive
end

function GuiManager.IsCentreActive(): boolean
    return peek(CentreActive)
end

function GuiManager.RegisterConfiguration(config: Types.GuiConfiguration)
    registeredConfigurations[config.Name] = config
    registeredConfigurations[config.Name].ConfigurationContainer.Parent = HudContainer
end

-- Registers a modal so that it can easily be referenced from within the GUI manager
function GuiManager.RegisterModal(objectName: string, guiObject: GuiObject, onActivated: (any?) -> ()?): ()
    assert(objectName and guiObject, "Inadequate information to register modal! Name = " .. objectName)

    registeredModals[objectName] = {
        ["guiObject"] = guiObject,
        ["callback"] = onActivated
    }
    
    guiObject.Parent = modalContainer
    guiObject.AnchorPoint = Vector2.new(0.5, 0.5)
    guiObject.Visible = false
end

function GuiManager.GetRegisteredModal(modalName: string): {guiObject: GuiObject, callback: () -> ()?}
    return registeredModals[modalName]
end

function GuiManager.doTransition(phaseName: string)

    local screenMessage: string
    if phaseName == GameStates.Dressing.name then
        -- text
        screenMessage = "Time to dress!"
    elseif phaseName == GameStates.Intermission.name then
        -- text
        screenMessage = "And the winners are..."
    elseif phaseName == GameStates.Voting.name then
        -- text
        screenMessage = "Time to Vote!"
    else
        warn("Unhandled message at GuiManager.doTransition()", phaseName)
    end 

    -- Hide top bar
    messageValue:set(screenMessage)
    messagePosition:set(messagePositions.IN)
    leftWingPos:set(leftWingPositions.IN)
    rightWingPos:set(rightWingPositions.IN)

    task.wait(tweenTime)

    veilSize:set(veilSizes.OUT)
    messageSize:set(messageSizes.IN)
    messageVisible:set(true)

    task.wait(tweenTime)

    messagePosition:set(messagePositions.OUT)
    leftWingPos:set(leftWingPositions.OUT)
    rightWingPos:set(rightWingPositions.OUT)
    messagePosition:set(messagePositions.OUT)
    messageSize:set(messageSizes.OUT)

    transitionCompletedEvent:Fire(phaseName)

    task.defer(function()
        task.wait(tweenTime)
        veilSize:set(veilSizes.IN)
        messageVisible:set(false)
        messagePosition:set(messagePositions.IN)
        messageSize:set(messageSizes.OUT)
        messageValue:set("")

    end)
end

function GuiManager.PushCentreByName(modalName: string, params: any?): ()
    if not isLoaded  then 
        warn("Still initialising GUI!", isLoaded)
        return
    end 

    assert(registeredModals[modalName], "Attempt to push modal " .. modalName .. " but no such modal found in registered modals!")
    -- Clone to avoid mutating the original table
    local currentModals = table.clone(peek(modalStack))
    local modalToPush = GuiManager.GetRegisteredModal(modalName)

    if table.find(currentModals, modalToPush.guiObject) then
        warn("Modal already pushed!")
        return
    end

    -- Hide previous top modal if exists
    if #currentModals >= 1 then
        currentModals[#currentModals].Visible = false
    else
        HideAllPromptsBindable:Fire()
        GuiManager.HideCurrentConfiguration()
    end

    table.insert(currentModals, modalToPush.guiObject)
    modalToPush.guiObject.Visible = true
    
    if modalToPush.callback then
        modalToPush.callback(params)
    end 

    modalStack:set(currentModals)
    PlayerDisplayManager.HideAllDisplays()

end

function GuiManager.PopCentre(guiObject: GuiObject?): ()
    -- Clone to avoid mutating the original table
    local modals = table.clone(peek(modalStack))

    if #modals == 0 then
        print("Cannot pop with no active modals!")
        return
    end

    local topModal = modals[#modals]
    table.remove(modals, #modals)

    -- Show previous modal if there is one
    if #modals > 0 then
        modals[#modals].Visible = true
        topModal.Visible = false 

    -- Otherwise, return to the HUD configuration
    else
        GuiManager.ShowCurrentConfiguration()
        
        -- Only show HUD when stack is empty
        -- Hide the popped modal after it slides off-screen
        task.delay(TWEEN_LENGTH, function()
            topModal.Visible = false
            ShowAllPromptsBindable:Fire()
        end)
    end

    -- Show all player name/level labels
    PlayerDisplayManager.ShowAllDisplays()
    -- Update modal stack after changes 
    modalStack:set(modals)
end

return GuiManager