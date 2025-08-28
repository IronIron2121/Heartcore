--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")

-- Folders
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Remotes
local SubmissionResultRE = Remotes:WaitForChild("SubmissionResultRE")
local ClientPrintSubmissions = Remotes:WaitForChild("ClientPrintSubmissions")

local function onSubmissionResult(
    result: {
        ok: boolean, 
        msg: string
    }
)
    print(result.ok, result.msg)
end

SubmissionResultRE.OnClientEvent:Connect(onSubmissionResult)

UIS.InputBegan:Connect(function(inputObject, processed)
    if inputObject.KeyCode == Enum.KeyCode.H then
        ClientPrintSubmissions:FireServer()
    end
end)