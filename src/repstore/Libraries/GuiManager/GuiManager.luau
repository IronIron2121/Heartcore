--!strict

--[[
    GuiManager.luau
    This script manages the whole player GUI.

]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting          = game:GetService("Lighting")
local Players           = game:GetService("Players")
local StarterPlayer     = game:GetService("StarterPlayer")

-- Folders
local BindablesFolder   = ReplicatedStorage:WaitForChild("Bindables")
local Utility           = ReplicatedStorage:WaitForChild("Utility")
local UI                = ReplicatedStorage:WaitForChild("UI")
local Widgets           = UI.FusionComponents.Widgets
local DataTables        = ReplicatedStorage:WaitForChild("DataTables")
local Remotes           = ReplicatedStorage:WaitForChild("Remotes")

-- Modules
local Constants             = require(ReplicatedStorage.Constants)
local Children              = require(ReplicatedStorage.Utility.Fusion.Instances.Children)
local PlayerDisplayManager  = require(StarterPlayer.StarterPlayerScripts.GUI.PlayerDisplayManager)
local ImageUris             = require(DataTables:WaitForChild("ImageUris"))
local UI_CONSTANTS          = require(Utility:WaitForChild("UI_CONSTANTS"))
local Types                 = require(Utility.Types)

-- UI Modules
local FusionImageButton = require(Widgets.FusionImageButton)

-- Fusion
local Fusion        = require(Utility.Fusion)
local guiScope      = Fusion:scoped()
local peek          = Fusion.peek
type UsedAs<T>      = Fusion.UsedAs<T>
type Value<T>       = Fusion.Value<T>
type Computed<T>    = Fusion.Computed<T>

-- Fusion Values
local MESSAGE_ON_SCREEN_POSITION            = UDim2.fromScale(0.5, 0.25)
local MESSAGE_OFF_SCREEN_POSITION           = UDim2.fromScale(0.5, -5)
local messageActive                         = guiScope:Value(false)
local messageText                           = guiScope:Value("")
local messageCloseCallback: Value<() -> ()> = guiScope:Value(function() end)

local messagePosition = guiScope:Computed(function(use)
    return use(messageActive) and MESSAGE_ON_SCREEN_POSITION or MESSAGE_OFF_SCREEN_POSITION
end)

local messageQueue: {{messageName: string, message: string, closeCb: (() -> ())?}} = {}

-- Bindables
local HideAllPromptsBindable   = BindablesFolder:WaitForChild("HideAllPromptsBindable")
local ShowAllPromptsBindable   = BindablesFolder:WaitForChild("ShowAllPromptsBindable")

-- Remotes
local MarkMessageSeenRE = Remotes.MarkMessageSeenRE

-- Instances
local localPlayer = Players.LocalPlayer

-- GUI Elements
local PlayerGui = localPlayer.PlayerGui 

-- Constants
local OFF_SCREEN_POSITION = UDim2.fromScale(0.5, 3)
local ON_SCREEN_POSITION = UDim2.fromScale(0.5, 0.5)
local TWEEN_LENGTH = 0.4
local NOTIFICATION_OFF_SCREEN_POSITION = UDim2.fromScale(0.5, -5)

-- Variable
local currentMessage = guiScope:Value("")

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

-- —— Message System ————————————————————————————————————————————————————————————————

local messageTextLabel = guiScope:New "TextLabel" {
    BackgroundTransparency = 1,
    Name = "messageTextLabel",
    Text = messageText,
    FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Regular),
    Size = UDim2.fromScale(1, 1),
    TextScaled = true,
    TextWrapped = true,
    TextColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
    TextSize = 50,
    LayoutOrder = 1,

    [Children] = {
        guiScope:New "UIStroke" {
            Thickness = 5,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = UI_CONSTANTS.TASTEMAKER_PINK
        },
        guiScope:New "UIPadding" {
            PaddingLeft = UDim.new(0.1, 0),
            PaddingRight = UDim.new(0.1, 0),
        },
        guiScope:New "UICorner" {
            CornerRadius = UDim.new(0.03, 0)
        },
        guiScope:New  "UITextSizeConstraint" {
            MaxTextSize = 45,
            MinTextSize = 45
        },
        -- guiScope:New "UIStroke" {
        --     Thickness = 5,
        --     ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
        --     Color = UI_CONSTANTS.T
        -- },
    }
}

local messageCloseButton = FusionImageButton(guiScope, {
    name = "messageCloseButton",
    visible = false,
    backgroundTransparency = 1,
    image = ImageUris.CloseButton,
    size = UDim2.fromScale(0.4, 0.4),
    layoutOrder = 2,
    onActivated = messageCloseCallback,
})

local messageContentFrame = guiScope:New "Frame" {
    Name = "messageContentFrame",
    BackgroundColor3 = UI_CONSTANTS.COLOUR_WHITE,
    BackgroundTransparency = 0.3,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    ZIndex = 1,
    Size = UDim2.fromScale(0.35, 0.2),
    [Children] = {
        messageTextLabel,
        --messageCloseButton,
        guiScope:New "UIListLayout" {
            SortOrder = Enum.SortOrder.LayoutOrder,
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
        },
        guiScope:New "UICorner" {
            CornerRadius = UDim.new(0.04, 0)
        },
        guiScope:New "UIStroke" {
            Thickness = 5,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = UI_CONSTANTS.TASTEMAKER_GREEN
        }
    }
}
local messageContainer = guiScope:New "Frame" {
    Name = "messageContainer",
    Visible = true,
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1,
    Position = guiScope:Spring(messagePosition, 10, 0.8),
    ZIndex = 2,
    Size = UDim2.fromScale(1, 1),
    [Children] = {
        messageContentFrame
    }
}

local _MessageGui = guiScope:New "ScreenGui" {
    Name = "MessageGui",
    Enabled = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
    DisplayOrder = 4,
    Parent = PlayerGui,
    [Children] = {
        messageContainer,
    }
}

-- —— Transitions ————————————————————————————————————————————————————————————————
local tweenTime = Constants.TransitionTweenTime

local minTTextSize                  = 1
local maxTTextSize                  = 100
local transitionTextSize            = guiScope:Value(minTTextSize)
local transitionTextSizeTween       = guiScope:Tween(transitionTextSize)
local transitionTextVisibleSwitch   = guiScope:Value(true)
local messageValue = guiScope:Value("")
local messageLabel = guiScope:New "TextLabel" {
    Name = "transitionTextLabel",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    TextColor3 = UI_CONSTANTS.COLOUR_WHITE,
    FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Regular),
    Text = messageValue,
    TextSize = transitionTextSizeTween,
    TextWrapped = false,
    TextScaled = false,
    Visible = transitionTextVisibleSwitch,
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

local transitionMessageVisible = guiScope:Value(false)
local transitionMessagePositions = {
    ['IN'] = UDim2.fromScale(0.5, 0.5),
    ['OUT'] = UDim2.fromScale(0.5, -0.5)
}
local transitionMessagePosition = guiScope:Value(
    transitionMessagePositions.OUT
)
local messageSizes = {
    ['IN'] = UDim2.fromScale(1, 0.5),
    ['OUT'] = UDim2.fromScale(0, 0)
}
local messageSize = guiScope:Value(messageSizes.OUT)

local messageRotation = guiScope:Value(0)

local transitionMessageContainer = guiScope:New "Frame" {
    Name = "transitionMessageContainer",
    BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(0.5, 0.5),
    ZIndex = 2,
    Position = guiScope:Tween(
        transitionMessagePosition, 
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
    Visible = transitionMessageVisible,
    [Children] = {
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
    ZIndex = 2,

    [Children] = {
        guiScope:New "UIGradient" {
            Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(176, 183, 253)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(114,119,224)),
                ColorSequenceKeypoint.new(1, UI_CONSTANTS.TASTEMAKER_PURPLE)
            }
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
    ZIndex = 2,
    [Children] = {
        guiScope:New "UIGradient" {
            Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, UI_CONSTANTS.TASTEMAKER_PURPLE),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(114,119,224)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(176, 183, 253))
            }
        }
    }
}


local countdownText     = guiScope:Value("3")
local countdownColor    = guiScope:Value(UI_CONSTANTS.TASTEMAKER_PINK)
local countdownVisible  = guiScope:Value(false)
local countdownSize     = guiScope:Value(UDim2.fromScale(0.25, 0.25))
local countdownRotation = guiScope:Value(0)
local countdownTransparency = guiScope:Value(1)
local countdownLabel = guiScope:New "TextLabel" {
    Name = "countdownLabel",
    BackgroundTransparency = countdownTransparency,
    Text = countdownText,
    Size = guiScope:Spring(countdownSize, 14, 0.55),
    Rotation = guiScope:Spring(countdownRotation, 14, 0.55),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    BackgroundColor3 = countdownColor,
    TextColor3 = Color3.new(1, 1, 1),
    Visible = countdownVisible,
    TextScaled = true,
    FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Bold),
    LayoutOrder = 2,

    [Children] = {
        guiScope:New "UICorner" {
            CornerRadius = UDim.new(1, 0)
        },

        guiScope:New "UIAspectRatioConstraint" {
            AspectRatio = 1,
            DominantAxis = Enum.DominantAxis.Width,
            AspectType = Enum.AspectType.FitWithinMaxSize
        },
    }
}

local roundStartsLabel = guiScope:New "TextLabel" {
    Name = "roundStartsLabel",
    TextScaled = true,
    Size = UDim2.fromScale(0.45, 0.10),
    AnchorPoint = Vector2.new(0.5, 0.5),
    LayoutOrder = 1,
    Text = "Round starts in...",
    Visible = countdownVisible,
    FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Bold),
    Position = UDim2.fromScale(0.5, 0.25),
    TextColor3 = UI_CONSTANTS.COLOUR_WHITE,
    BackgroundTransparency = 1,

    [Children] = {
        guiScope:New "UICorner" {
            CornerRadius = UDim.new(0.25)

        },
        guiScope:New "UIStroke" {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
            LineJoinMode = Enum.LineJoinMode.Round,
            Transparency = 0,
            Color = UI_CONSTANTS.TASTEMAKER_PINK,
            Thickness = 3,
        }
    }
}

local countdownContainer = guiScope:New "Frame" {
    Name = "countdownContainer",
    BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Size = UDim2.fromScale(1, 1),
    Position = UDim2.fromScale(0.5, 0.5),
    ZIndex = 1,
    [Children] = {
        roundStartsLabel,
        countdownLabel
    }
}

local _transitionGui = guiScope:New "ScreenGui" {
    Name = "TransitionGui", 
    Enabled = true,
    Parent = PlayerGui,
    IgnoreGuiInset = true,
    DisplayOrder = 209,
    [Children] = {
        leftTransitionWing,
        rightTransitionWing,
        transitionMessageContainer,
        countdownContainer
    }
}

-- —— Modal ——————————————————————————————————————————————————————————————————————
local _BackgroundBlur = guiScope:New "BlurEffect" {
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
        },
        guiScope:New "UIStroke" {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
            Thickness = 3,
            Color = UI_CONSTANTS.TASTEMAKER_GREEN
        }
    }
}

local yesCallback = guiScope:Value(function()
    warn("No callback currently assigned to YES button")
end)
local notificationYesButton = FusionImageButton(guiScope, {
    name = "notificationYesButton",
    visible = true,
    backgroundTransparency = 1,
    image = ImageUris.ConfirmButton,
    size = UDim2.fromScale(0.5, 0.5),
    position = UDim2.fromScale(0.35,0.5),
    onActivated = yesCallback

})
local noCallback = guiScope:Value(function()
    print("No callback currently assigned to no button")
end)

local notificationNoButton = FusionImageButton(guiScope, {
    name = "notificationNoButton",
    visible = true,
    backgroundTransparency = 1,
    image = ImageUris.CloseButton,
    size = UDim2.fromScale(0.5, 0.5),
    position = UDim2.fromScale(0.65,0.5),
    onActivated = noCallback
})

local notificationButtonContainer = guiScope:New "Frame" {
    Name = "notificationButtonContainer",
    Visible = true,
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 0.5),
    LayoutOrder = 2,
    [Children] = {
        -- guiScope:New "UIListLayout" {
        --     SortOrder = Enum.SortOrder.LayoutOrder,
        --     FillDirection = Enum.FillDirection.Horizontal,
        --     HorizontalAlignment = Enum.HorizontalAlignment.Center,
        --     VerticalAlignment = Enum.VerticalAlignment.Center,
        -- },
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

function GuiManager.PushMessageCentre(messageName: string, message: string, closeCb: (() -> ())?, messageLength: number?)
    if peek(messageActive) then
        warn("Message already active!")
        return
    end
    currentMessage:set(messageName)
    messageText:set(message)
    MarkMessageSeenRE:FireServer(messageName)
    messageActive:set(true)
    messageCloseCallback:set(function()
        if messageName == peek(currentMessage) then
            GuiManager.PopMessage()
            if closeCb then 
                closeCb() 
            end
        else
            print("Not popping; message closed before close callback")
        end
    end)
 
    task.delay(messageLength or 5, peek(messageCloseCallback))
end

function GuiManager.PopMessage()
    currentMessage:set("")
    messageActive:set(false)
    messageText:set("")
    messageCloseCallback:set(function()
        print("Default message close callback")
    end)
end

function GuiManager.QueueMessage(messageName: string, message: string, closeCb: (() -> ())?, messageLength: number?)
    if peek(CentreActive) or peek(messageActive) then
        table.insert(messageQueue, {
            messageName = messageName, 
            message = message, 
            closeCb = closeCb, 
            messageLength = messageLength
        })
    else
        GuiManager.PushMessageCentre(
            messageName, 
            message, 
            closeCb, 
            messageLength
        )
    end
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
    if noCallback then
        peek(noCallback)()
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