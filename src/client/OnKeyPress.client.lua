--!strict

-- ReplicatedStorage
local UIS = game:GetService("UserInputService")
local repStore = game:GetService("ReplicatedStorage")

-- Folders
local Remotes = repStore:WaitForChild("Remotes")

-- Remotes
local ResetPlayerChallenges = Remotes:WaitForChild("ResetPlayerChallenges")
local ResetLevel = Remotes:WaitForChild("ResetLevel")
local XPHack = Remotes:WaitForChild("XPHack")
local RolloverSubStore = Remotes:WaitForChild("RolloverSubStore")

--

local function onUserInputBegan(input: InputObject, gameProc: boolean)
    if input.KeyCode == Enum.KeyCode.U then
        XPHack:FireServer()
    elseif input.KeyCode == Enum.KeyCode.R then
        ResetLevel:FireServer()
    elseif input.KeyCode == Enum.KeyCode.J then
        ResetPlayerChallenges:FireServer()
    elseif input.KeyCode == Enum.KeyCode.Z then
        RolloverSubStore:FireServer()
    end
end

UIS.InputBegan:Connect(onUserInputBegan)