--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- Folders
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local submissionZone = workspace:WaitForChild("submissionZone")
local Values = ReplicatedStorage:WaitForChild("Values")

-- Remotes
local SubmissionResultRE = Remotes:WaitForChild("SubmissionResultRE")
local CanSubmitRF = Remotes:WaitForChild("CanSubmitRF") -- RemoteFunction to check submission status

-- Instances
local SubmissionPad = submissionZone:WaitForChild("SubmissionPad")
local PromptHolder = SubmissionPad:WaitForChild("PromptHolder")
local prompt = PromptHolder:WaitForChild("SubmissionPrompt") :: ProximityPrompt

-- State
local CurrentStateName = Values:WaitForChild("CurrentStateName") :: StringValue

--

local hasSubmittedThisRound = false

local function updateSubmitButton()
    local isDressingPhase = CurrentStateName.Value == "Dressing"
    local canSubmit = isDressingPhase and not hasSubmittedThisRound
    
    prompt.Enabled = canSubmit
    PromptHolder.Color = if canSubmit 
        then Color3.fromRGB(0, 255, 110) 
        else Color3.fromRGB(100, 100, 100)
end

local function onSubmissionResult(result: { ok: boolean, msg: string })
    if result.ok then
        hasSubmittedThisRound = true
        StarterGui:SetCore("SendNotification", {
            Title = "Outfit Submitted Successfully!",
            Text = "",
        })
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
        hasSubmittedThisRound = false
    end
    
    updateSubmitButton()
end

-- Connections
SubmissionResultRE.OnClientEvent:Connect(onSubmissionResult)
CurrentStateName.Changed:Connect(onStateChanged)

-- Initial setup
local function initialize()
    -- Check with server if we've already submitted (handles rejoins mid-round)
    hasSubmittedThisRound = CanSubmitRF:InvokeServer() == false
    updateSubmitButton()
end

initialize()