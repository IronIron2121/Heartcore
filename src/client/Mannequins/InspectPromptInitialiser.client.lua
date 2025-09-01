--!strict

--[[
	This script handles initializing proximity prompts on mannequins and managing their lifecycle.
	CLIENT-SIDE: Handles UI interaction only.
--]]

-- Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Folders
local BindablesFolder = ReplicatedStorage:WaitForChild("Bindables")

-- Modules
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))

-- Bindables
local PlayerCreatedPreview = BindablesFolder:WaitForChild("PlayerCreatedPreview")
local PlayerDestroyedPreview = BindablesFolder:WaitForChild("PlayerDestroyedPreview")
local HideAllPromptsBindable = BindablesFolder:WaitForChild("HideAllPromptsBindable")
local ShowAllPromptsBindable = BindablesFolder:WaitForChild("ShowAllPromptsBindable")
local PlayerInspectedMannequin = BindablesFolder:WaitForChild("PlayerInspectedMannequin")

-- State
local inspectPrompts: { [Instance]: ProximityPrompt } = {}

local function getInspectPrompt(): ProximityPrompt
	local inspectPrompt = Instance.new("ProximityPrompt")
	inspectPrompt.Enabled = true
	inspectPrompt.ClickablePrompt = true
	inspectPrompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
	inspectPrompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	inspectPrompt.HoldDuration = 0
	inspectPrompt.KeyboardKeyCode = Enum.KeyCode.E
	inspectPrompt.MaxActivationDistance = 8
	inspectPrompt.MaxIndicatorDistance = 0
	inspectPrompt.Name = "InspectPrompt"
	inspectPrompt.ActionText = "Inspect"
	inspectPrompt.RequiresLineOfSight = false

	return inspectPrompt
end

local function hideAllPrompts()
	for _, prompt in inspectPrompts do
		prompt.Enabled = false
	end
end

local function showAllPrompts()
	for _, prompt in inspectPrompts do
		prompt.Enabled = true
	end
end

local function onMannequinAdded(mannequin: Model)
	print("Adding inspect prompt to mannequin:", mannequin.Name)
	local base = mannequin:WaitForChild("Base", 1)

	-- Create a new ProximityPrompt in the mannequin
	local inspectPrompt = getInspectPrompt()
	inspectPrompt:AddTag(Constants.INSPECT_PROMPT_TAG)
	inspectPrompt.Parent = mannequin.PrimaryPart or base
	
	assert(inspectPrompt.Parent, "Error: No parent of inspect prompt!")

	inspectPrompt.Triggered:Connect(function(_: Player)
		-- Fire bindable to trigger inspection in the other script
		PlayerInspectedMannequin:Fire(mannequin)
	end)

	inspectPrompts[mannequin] = inspectPrompt
end

local function onMannequinRemoved(mannequin: Instance)
	if inspectPrompts[mannequin] then
		inspectPrompts[mannequin]:Destroy()
		inspectPrompts[mannequin] = nil
	end
end

local function initialise()
	warn("Initialising inspect prompts")
	-- Set up mannequin tracking
	CollectionService:GetInstanceAddedSignal(Constants.FLOOR_MANNEQUIN_TAG):Connect(onMannequinAdded)
	CollectionService:GetInstanceRemovedSignal(Constants.FLOOR_MANNEQUIN_TAG):Connect(onMannequinRemoved)

	-- Initialise existing mannequins
	for _, mannequin in CollectionService:GetTagged(Constants.FLOOR_MANNEQUIN_TAG) do
		warn("Initialising inspect prompt for:", mannequin.Name)
		onMannequinAdded(mannequin)
	end

	-- Connect prompt visibility controls
	PlayerCreatedPreview.Event:Connect(hideAllPrompts)
	PlayerDestroyedPreview.Event:Connect(showAllPrompts)
	HideAllPromptsBindable.Event:Connect(hideAllPrompts)
	ShowAllPromptsBindable.Event:Connect(showAllPrompts)
end

task.wait(2)
initialise()