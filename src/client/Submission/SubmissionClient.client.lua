--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local centralPond = workspace:WaitForChild("centralPond")
local centralPond = workspace:WaitForChild("centralPond")

-- Remotes
local SubmissionResultRE = Remotes:WaitForChild("SubmissionResultRE")
local SubmissionResultRF = Remotes:WaitForChild("SubmissionResultRF")
local PhaseChangedRemote = Remotes:WaitForChild("PhaseChangedRemote")

-- Instances
local SubmissionPad = centralPond:WaitForChild("SubmissionPad")
local PromptHolder = SubmissionPad:WaitForChild("PromptHolder")
local prompt = PromptHolder:WaitForChild("SubmissionPrompt") :: ProximityPrompt

--

local function updateSubmitButton()
    warn("Updating submit button...")
    local canPlayerSubmit = SubmissionResultRF:InvokeServer()
    if canPlayerSubmit then
        warn("Player can submit!", canPlayerSubmit)
        prompt.Enabled = true
        PromptHolder.Color = Color3.fromRGB(190, 190, 192)
    else
        warn("Player cannot submit!", canPlayerSubmit)
        prompt.Enabled = false
        PromptHolder.Color = Color3.fromRGB(100,100,100)
    end
end
local SubmissionResultRF = Remotes:WaitForChild("SubmissionResultRF")
local PhaseChangedRemote = Remotes:WaitForChild("PhaseChangedRemote")

-- Instances
local SubmissionPad = centralPond:WaitForChild("SubmissionPad")
local PromptHolder = SubmissionPad:WaitForChild("PromptHolder")
local prompt = PromptHolder:WaitForChild("SubmissionPrompt") :: ProximityPrompt

--

local function updateSubmitButton()
    warn("Updating submit button...")
    local canPlayerSubmit = SubmissionResultRF:InvokeServer()
    if canPlayerSubmit then
        warn("Player can submit!", canPlayerSubmit)
        prompt.Enabled = true
        PromptHolder.Color = Color3.fromRGB(190, 190, 192)
    else
        warn("Player cannot submit!", canPlayerSubmit)
        prompt.Enabled = false
        PromptHolder.Color = Color3.fromRGB(100,100,100)
    end
end

local function onSubmissionResult(
    result: {
        ok: boolean, 
        msg: string
    }
): ()
    warn("Got result....")
    updateSubmitButton()
    print(result.msg)
): ()
    warn("Got result....")
    updateSubmitButton()
    print(result.msg)
end

SubmissionResultRE.OnClientEvent:Connect(onSubmissionResult)
PhaseChangedRemote.OnClientEvent:Connect(updateSubmitButton)

-- This is just a clumsy way of making sure we update the button after the player joins
task.wait(2)
updateSubmitButton()