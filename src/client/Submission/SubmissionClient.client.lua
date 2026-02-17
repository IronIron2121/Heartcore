--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")

-- Folders
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local submissionZone = workspace:WaitForChild("submissionZone")
local Values = ReplicatedStorage:WaitForChild("Values")
local StarterPlayerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
local GameState = StarterPlayerScripts:WaitForChild("GameState")

-- Modules
local peek = require(ReplicatedStorage.Utility.Fusion.State.peek)
local PlayerSubmissionState = require(GameState:WaitForChild("PlayerSubmissionState"))

-- Remotes
local SubmissionResultRE = Remotes:WaitForChild("SubmissionResultRE")

-- Instances
local SubmissionPad = submissionZone:WaitForChild("SubmissionPad")
local PromptHolder = SubmissionPad:WaitForChild("PromptHolder")
local prompt = PromptHolder:WaitForChild("SubmissionPrompt") :: ProximityPrompt

-- State
local CurrentStateName = Values:WaitForChild("CurrentStateName") :: StringValue

-- Constands
local COOLDOWN_TIME = 10

--

local function updateSubmitButton()
    local isDressingPhase = CurrentStateName.Value == "Dressing"
    local canSubmit = isDressingPhase and not peek(PlayerSubmissionState.cooldown)
    
    prompt.Enabled = canSubmit
    PromptHolder.Color = if canSubmit 
        then Color3.fromRGB(0, 255, 110) 
        else Color3.fromRGB(100, 100, 100)
end

local function onSubmissionResult(result: { ok: boolean, msg: string })
    if result.ok then
        StarterGui:SetCore("SendNotification", {
            Title = "Outfit Submitted Successfully!",
            Text = "",
        })
        task.spawn(function()
            PlayerSubmissionState.cooldown:set(true)
            updateSubmitButton()
            task.wait(COOLDOWN_TIME)
            PlayerSubmissionState.cooldown:set(false)
            updateSubmitButton()
        end)
    else
        StarterGui:SetCore("SendNotification", {
            Title = "Outfit Submission Failed!",
            Text = result.msg,
        })
    end

    updateSubmitButton()
end

local function onStateChanged()
    -- Reset submission tracking when Dressing starts
    if CurrentStateName.Value == "Dressing" then
        PlayerSubmissionState.cooldown:set(false)
    end

    updateSubmitButton()
end

-- Connections
SubmissionResultRE.OnClientEvent:Connect(onSubmissionResult)
CurrentStateName.Changed:Connect(onStateChanged)

local function initialize()
    updateSubmitButton()
end

initialize()