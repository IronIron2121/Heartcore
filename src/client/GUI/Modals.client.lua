--!strict

--[[
	Modals - This script handles offseting the camera and hiding the shop button
	whenever a modal (either the shop or inspect UI) is open.
--]]

local GamepadService = game:GetService("GamepadService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local Constants = require(ReplicatedStorage.Constants)
local Settings = require(ReplicatedStorage.Settings)
local CameraOffset = require(ReplicatedStorage.Libraries.CameraOffset)
local ModalManager = require(ReplicatedStorage.Libraries.ModalManager)

local player = Players.LocalPlayer :: Player
local playerGui = player.PlayerGui
local shoppingGui = playerGui:WaitForChild("ShoppingGui")

local isUsingGamepad = false
local isModalVisible = false

local function updateGamepadCursor()
	local shouldEnableCursor = isUsingGamepad and isModalVisible

	if GamepadService.GamepadCursorEnabled == shouldEnableCursor then
		return
	end

	if shouldEnableCursor then
		GamepadService:EnableGamepadCursor(ModalManager.getModal() :: GuiObject)
	else
		GamepadService:DisableGamepadCursor()
	end
end

local function update()
	-- Update touch controls visibility -- disable touch controls if Modal is Visible
	GuiService.TouchControlsEnabled = not isModalVisible

	-- Update gamepad cursor visibility
	updateGamepadCursor()

	-- Update leaderboard visibility
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, not isModalVisible)

	-- Update shop button

	-- Update camera offset
	if isModalVisible then
		CameraOffset.enable(Constants.CAMERA_OFFSET)
	else
		CameraOffset.disable()
	end
end

local function popCurrentModal()
	local modal = ModalManager.getModal()

	if modal then
		ModalManager.pop(modal)
	end
end

local function onInputTypeChanged(inputType: Enum.UserInputType)
	if string.find(inputType.Name, "Gamepad") then
		isUsingGamepad = true
	else
		isUsingGamepad = false
	end

	update()
end

local function onInputBegan(inputObject: InputObject, processed: boolean)
	if processed then
		return
	end

	if inputObject.KeyCode == Settings.BACK_GAMEPAD_KEY_CODE then
		popCurrentModal()
	end
end

local function onModalChanged(modal: GuiObject?)
	isModalVisible = modal ~= nil
	update()
end

local function initialize()
	ModalManager.modalChanged:Connect(onModalChanged)
	UserInputService.InputBegan:Connect(onInputBegan)
	UserInputService.LastInputTypeChanged:Connect(onInputTypeChanged)

	onModalChanged(ModalManager.getModal())
	onInputTypeChanged(UserInputService:GetLastInputType())
end

initialize()
