--!strict

local UIS = game:GetService("UserInputService")
local repStore = game:GetService("ReplicatedStorage")

local Remotes = repStore:WaitForChild("Remotes")

local XPHack = Remotes:WaitForChild("XPHack")
local ResetLevel = Remotes:WaitForChild("ResetLevel")
--

local function onUserInputBegan(input: InputObject, gameProc: boolean)
    if input.KeyCode == Enum.KeyCode.U then
        XPHack:FireServer()
    elseif input.KeyCode == Enum.KeyCode.R then
        ResetLevel:FireServer()
    end
end

UIS.InputBegan:Connect(onUserInputBegan)