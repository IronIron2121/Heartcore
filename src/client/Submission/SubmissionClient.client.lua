--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- Folders
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local submissionZone = workspace:WaitForChild("submissionZone")

-- Modules
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))

-- Remotes
local SubmissionResultRE = Remotes:WaitForChild("SubmissionResultRE")
local SubmissionResultRF = Remotes:WaitForChild("SubmissionResultRF")
local PhaseChangedRemote = Remotes:WaitForChild("PhaseChangedRemote")

-- Instances
local SubmissionPad = submissionZone:WaitForChild("SubmissionPad")
local PromptHolder = SubmissionPad:WaitForChild("PromptHolder")
local prompt = PromptHolder:WaitForChild("SubmissionPrompt") :: ProximityPrompt

--

local function enableSubmitButton()
    prompt.Enabled = true
    PromptHolder.Color = Color3.fromRGB(190, 190, 192)
end

local function disableSubmitButton()
        prompt.Enabled = false
        PromptHolder.Color = Color3.fromRGB(100,100,100)
end

local function updateSubmitButton()
    local canPlayerSubmit = SubmissionResultRF:InvokeServer()
    if canPlayerSubmit then
        enableSubmitButton()
    else 
        disableSubmitButton()
    end 
end

local function onSubmissionResult(
    result: {
        ok: boolean, 
        msg: string
    }
): ()
    warn("Got result....")

    if result.msg == Constants.NO_CURRENT_PHASE_MESSAGE then
        warn(result.msg)
        task.wait(5)
        updateSubmitButton()
        return
    end

    if result.ok then
        warn("Player submitted successfully!")
        disableSubmitButton()
        StarterGui:SetCore("SendNotification",{
            Title = "Outfit Submission Success!", -- Required
            Text = "", -- Required
            Icon = "rbxassetid://1234567890" -- Optional
        })
    else 
        enableSubmitButton()
        StarterGui:SetCore("SendNotification",{
            Title = "Outfit Submission Failed", -- Required
            Text = result.msg, -- Required
            Icon = "rbxassetid://1234567890" -- Optional
        })
    end


    --updateSubmitButton()
end

SubmissionResultRE.OnClientEvent:Connect(onSubmissionResult)
PhaseChangedRemote.OnClientEvent:Connect(updateSubmitButton)

-- This is just a clumsy way of making sure we update the button after the player joins
task.wait(10)
updateSubmitButton()