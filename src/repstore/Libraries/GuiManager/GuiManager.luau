--!strict

--[[
    GuiManager.luau
    This script manages the whole player GUI.

]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting          = game:GetService("Lighting")
local Players           = game:GetService("Players")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local Constants = require(ReplicatedStorage.Constants)
local Types         = require(Utility.Types)

-- Fusion
local Fusion        = require(Utility.Fusion)
local modalScope    = Fusion:scoped()
local peek          = Fusion.peek
type UsedAs<T>      = Fusion.UsedAs<T>
type Value<T>       = Fusion.Value<T>
type Computed<T>    = Fusion.Computed<T>

-- Instances
local localPlayer = Players.LocalPlayer

-- GUI Elements
local PlayerGui = localPlayer.PlayerGui 

-- Constants
local OFF_SCREEN_POSITION = UDim2.fromScale(0.5, 3)
local ON_SCREEN_POSITION = UDim2.fromScale(0.5, 0.5)
local TWEEN_LENGTH = 0.4

--

local currentConfiguration: Types.GuiConfiguration? = nil
local registeredConfigurations: {[string]: Types.GuiConfiguration} = {}

local HudContainer = modalScope:New "ScreenGui" {
    Name = "HudContainer",
    IgnoreGuiInset = true,
    Enabled = true,
    Parent = PlayerGui,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}

local registeredModals: {[string]: GuiObject} = {}
local modalStack: Value<{GuiObject}> = modalScope:Value({})

local CentreActive = modalScope:Computed(function(use) 
        return #use(modalStack) ~= 0
    end
)

local modalPosition = modalScope:Computed(function(use)
    return use(CentreActive) and ON_SCREEN_POSITION or OFF_SCREEN_POSITION
end)

local ModalGui = modalScope:New "ScreenGui" {
        Name = "ModalGui",
        Enabled = true,
        Parent = PlayerGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
} :: ScreenGui

local blurSize: Computed<number> = modalScope:Computed(function(use) 
    return use(CentreActive) and 24 or 0
end)

local modalContainer = modalScope:New "Frame" {
    Name = "ModalContainer",
    AnchorPoint = Vector2.new(0.5,0.5),
    Position = modalScope:Tween(modalPosition, TweenInfo.new(TWEEN_LENGTH, Enum.EasingStyle.Quad)),
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Parent = ModalGui
}

local BackgroundBlur = modalScope:New "BlurEffect" {
    Archivable = true,
    Name = "ModalBackgroundBlur",
    Parent = Lighting,
    Enabled = true,
    Size = modalScope:Tween(blurSize, TweenInfo.new(TWEEN_LENGTH, Enum.EasingStyle.Quad))
} :: BlurEffect

local GuiManager = {} 

function GuiManager.DisplayConfiguration(configurationName: string): ()
    if currentConfiguration then
        currentConfiguration:Disable()
    end
    local newConfiguration = registeredConfigurations[configurationName]
    currentConfiguration = newConfiguration
    assert(currentConfiguration, "Configuration should not be nil") -- type checker unfortunately redlines if we don't put this here
    if not peek(CentreActive) then
        currentConfiguration:Enable()
    end

end 

function GuiManager.HideCurrentConfiguration(): ()
    if currentConfiguration then
        currentConfiguration:Disable()
    end
end

function GuiManager.ShowCurrentConfiguration(): ()
    if currentConfiguration then
        currentConfiguration:Enable()
    end
end

function GuiManager.IsModalActive(modal: GuiObject): boolean
    return table.find(peek(modalStack), modal) ~= nil
end

function GuiManager.IsCentreActive(): boolean
    return peek(CentreActive)
end

function GuiManager.RegisterConfiguration(config: Types.GuiConfiguration)
    registeredConfigurations[config.Name] = config
    registeredConfigurations[config.Name].ConfigurationContainer.Parent = HudContainer
end

-- Registers a modal so that it can easily be referenced from within the GUI manager
function GuiManager.RegisterModal(objectName: string, guiObject: GuiObject): ()
    assert(objectName and guiObject, "Inadequate information to register modal! Name = " .. objectName)
    registeredModals[objectName] = guiObject
    guiObject.Parent = modalContainer
    guiObject.AnchorPoint = Vector2.new(0.5, 0.5)
    guiObject.Visible = false
end

function GuiManager.GetRegisteredModal(modalName: string): GuiObject
    return registeredModals[modalName]
end

function GuiManager.PushCentreByName(modalName: string): ()
    assert(registeredModals[modalName], "Attempt to push modal " .. modalName .. " but no such modal found in registered modals!")

    -- Clone to avoid mutating the original table
    local currentModals = table.clone(peek(modalStack))
    local modalToPush = GuiManager.GetRegisteredModal(modalName)

    if table.find(currentModals, modalToPush) then
        warn("Cannot push already active modal!")
        return
    end

    -- Hide previous top modal if exists
    if #currentModals >= 1 then
        currentModals[#currentModals].Visible = false
    else
        GuiManager.HideCurrentConfiguration()
    end

    table.insert(currentModals, modalToPush)
    modalToPush.Visible = true

    modalStack:set(currentModals)
end

function GuiManager.PopCentre(guiObject: GuiObject?): ()
    -- Clone to avoid mutating the original table
    local modals = table.clone(peek(modalStack))

    if #modals == 0 then
        warn("Cannot pop with no active modals!")
        return
    end

    local topModal = modals[#modals]
    table.remove(modals, #modals)

    -- Show previous modal if exists
    if #modals > 0 then
        modals[#modals].Visible = true
        topModal.Visible = false 
    else
        -- Only show config when stack is empty
        -- Hide the popped modal after it slides off-screen
        task.delay(TWEEN_LENGTH, function()
            topModal.Visible = false
        end)
        GuiManager.ShowCurrentConfiguration()
    end

    modalStack:set(modals)
end

return GuiManager