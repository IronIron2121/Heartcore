local UIS = game:GetService("UserInputService")
local RepStore = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local testCode: Enum.KeyCode = Enum.KeyCode.T 
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Zone = require(ReplicatedStorage.Utility.Zone)
local ZoneController = require(ReplicatedStorage.Utility.Zone.ZoneController)
local KeyPressFunction = ReplicatedStorage.Remotes.KeyPressFunction

local function onKeyPressed(input: InputObject)
	RepStore.Remotes.UserKeyPressed:FireServer(input.KeyCode.Value)
end

UIS.InputBegan:Connect(onKeyPressed)