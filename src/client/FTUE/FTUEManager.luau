--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Constants = require(ReplicatedStorage.Constants)
local GuiManager = require(ReplicatedStorage.Libraries.GuiManager.GuiManager)
local PointerManager = require(StarterPlayer.StarterPlayerScripts.GUI.PointerManager)
local Fusion = require(ReplicatedStorage.Utility.Fusion)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local IsMessageSeenRF = Remotes:WaitForChild("IsMessageSeenRF") :: RemoteFunction
local MarkMessageSeenRE = Remotes:WaitForChild("MarkMessageSeenRE") :: RemoteEvent

local peek = Fusion.peek

--

local FTUE_KEY = "ftueCompleted"

local FTUE_STEPS: { { name: string } } = {
    { name = "Body" },
    { name = "Dresses & Skirts" },
    { name = "Tops" },
    { name = "Bottoms" },
    { name = "Hair" },
    { name = "Accessories" },
}

local FTUEManager = {}

local currentStep = 1
local active = false
local ftueCompleted = false
local ftueCheckDone = false

task.spawn(function()
    ftueCompleted = IsMessageSeenRF:InvokeServer(FTUE_KEY)
    ftueCheckDone = true
    print("FTUE completed?", ftueCompleted)
end)

local function showBeamForStep()
    local step = FTUE_STEPS[currentStep]
    if not step then return end
    for _, part in CollectionService:GetTagged(Constants.CATALOG_CONSOLE_TAG) do
        if (part :: BasePart).Name == step.name then
            PointerManager.startBeam(part :: BasePart)
            PointerManager.ShowBeam()
            return
        end
    end
    warn("[FTUEManager] No console part found for step:", step.name)
end

function FTUEManager.startRound()
    while not ftueCheckDone do task.wait() end
    if ftueCompleted then return end
    currentStep = 1
    active = true
    showBeamForStep()
end

function FTUEManager.endRound()
    active = false
    PointerManager.endBeam()
end

function FTUEManager.onCatalogOpened(consoleName: string)
    if not active then return end
    if currentStep > #FTUE_STEPS then return end
    if consoleName ~= FTUE_STEPS[currentStep].name then return end
    currentStep += 1
    if currentStep > #FTUE_STEPS then
        print("FTUE COMPLETE!")
        active = false
        PointerManager.endBeam()
        MarkMessageSeenRE:FireServer(FTUE_KEY)
        ftueCompleted = true
    end
end

function FTUEManager.isCompleted(): boolean
    return ftueCompleted
end

-- Observe modal state; hide beam while any modal is open, show again when closed
local ftueScope = Fusion:scoped()
local centreActive = GuiManager.GetCentreActiveValue()
ftueScope:Observer(centreActive):onChange(function()
    if not active then return end
    if peek(centreActive) then
        PointerManager.HideBeam()
    elseif currentStep <= #FTUE_STEPS then
        showBeamForStep()
    end
end)

return FTUEManager
