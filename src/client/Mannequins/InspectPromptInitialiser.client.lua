--!strict

--[[
	This script handles initializing proximity prompts on mannequins and managing their lifecycle.
	CLIENT-SIDE: Handles UI interaction only.
--]]

-- Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer.StarterPlayerScripts
local UserInputService = game:GetService("UserInputService")

-- Folders
local BindablesFolder = ReplicatedStorage:WaitForChild("Bindables")
local Mannequins = StarterPlayerScripts:WaitForChild("Mannequins")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Libraries         = ReplicatedStorage:WaitForChild("Libraries")
local GuiManagerLibrary = Libraries:WaitForChild("GuiManager")

-- Modules
local UI_CONSTANTS = require(ReplicatedStorage.Utility:WaitForChild("UI_CONSTANTS"))
local Constants = require(ReplicatedStorage.Constants)
local peek = require(ReplicatedStorage.Utility.Fusion.State.peek)
local Inspector = require(Mannequins.Inspector) 
local Fusion = require(Utility:WaitForChild("Fusion"))
local votingZone = workspace:WaitForChild("votingZone")
local GuiManager = require(GuiManagerLibrary:WaitForChild("GuiManager"))
local MODAL_NAMES = require(GuiManagerLibrary.MODAL_NAMES)

-- Instances
local VotingPad = votingZone:WaitForChild("VotingPad")
local promptHolder = VotingPad:WaitForChild("PromptHolder")

-- Fusion Modules
local scope = Fusion:scoped()
local OnEvent = Fusion.OnEvent

-- Bindables
local PlayerCreatedPreview = BindablesFolder:WaitForChild("PlayerCreatedPreview")
local PlayerDestroyedPreview = BindablesFolder:WaitForChild("PlayerDestroyedPreview")
local HideAllPromptsBindable = BindablesFolder:WaitForChild("HideAllPromptsBindable")
local ShowAllPromptsBindable = BindablesFolder:WaitForChild("ShowAllPromptsBindable")

-- parent to player gui so buttons are interactable
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local allPrompts = Instance.new("ScreenGui", playerGui)
allPrompts.Name = "allPrompts"

-- Create custom GUI when proximity prompt appears (Cece addition)
local function setupCustomPromptUI(prompt: ProximityPrompt, mannequin: Model)
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.ActionText = "" -- hide Roblox default
	prompt.ObjectText = ""

	local adornee = mannequin.PrimaryPart or mannequin:FindFirstChild("Base")
	if not adornee then return end

	-- Prevent duplicates
	if adornee:FindFirstChild("CustomInspectPrompt") then
		return
	end 

	local billboard = Instance.new("BillboardGui", allPrompts)
	billboard.Name = "CustomInspectPrompt"
	billboard.Adornee = adornee
	billboard.Size = UDim2.new(0, 100, 0, 30)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop = true
	billboard.Active = true
	billboard.Enabled = false

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(90, 47, 243)
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel = 0
	frame.Parent = billboard
	
	-- rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(3,0)
	corner.Parent = frame

	-- Add border
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame

	-- add text button
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 1, 0)
	button.BackgroundTransparency = 1 -- invisible background, just shows text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.FredokaOne
	button.TextSize = 15
	button.Text = "" -- will be set dynamically
	button.AutoButtonColor = false -- stop Roblox’s default hover effect
	button.Parent = frame

	-- rounded button corners
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(3,0)
	buttonCorner.Parent = button

	-- tween settings
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad,	Enum.EasingDirection.Out)
	local function tweenBackground(targetTransparency: number)
		TweenService:Create(frame, tweenInfo, {BackgroundTransparency =  targetTransparency}):Play()
	end

	-- local function tweenStroke(targetColor: Color3, targetThickness: number)
	-- 	TweenService:Create(stroke, tweenInfo, {Color = targetColor, Thickness = targetThickness}):Play()
	-- end

	-- hover animations
	button.MouseEnter:Connect(function()
		tweenBackground(0.1)
	end)

	button.MouseLeave:Connect(function()
		tweenBackground(0.5)
	end)

	button.Activated:Connect(function()
		Inspector.inspectMannequin(mannequin)
	end)

	-- Update the text key prompt dynamically
	local function keyCodeToLabel(keyCode: Enum.KeyCode): string
		if keyCode == Enum.KeyCode.Unknown then
			return ""
		elseif keyCode == Enum.KeyCode.ButtonX then
			return "[X]" -- Xbox / Gamepad X
		elseif keyCode == Enum.KeyCode.ButtonY then
			return "[Y]"
		elseif keyCode == Enum.KeyCode.ButtonA then
			return "[A]"
		elseif keyCode == Enum.KeyCode.ButtonB then
			return "[B]"
		else
			return "[" .. keyCode.Name .. "]"
		end
	end



	local function updateLabel()
		local action = "INSPECT"
		local keyText = ""

		if UserInputService.GamepadEnabled then
			keyText = keyCodeToLabel(prompt.GamepadKeyCode)
		elseif UserInputService.KeyboardEnabled then
			keyText = keyCodeToLabel(prompt.KeyboardKeyCode)
		elseif UserInputService.TouchEnabled then
			keyText = "[Tap]"
		end

		button.Text = action --.. " " .. keyText
	end

	updateLabel()
	-- Re-check if input device changes
	UserInputService.LastInputTypeChanged:Connect(updateLabel)

	-- Show/hide with prompt 
	prompt.PromptShown:Connect(function()
		updateLabel()
		billboard.Enabled = true
	end)

	prompt.PromptHidden:Connect(function()
		billboard.Enabled = false
	end)

	prompt.Triggered:Connect(function()
		billboard.Enabled = false
	end)
end

-- State
local inspectPrompts: { [Instance]: ProximityPrompt } = {}

local function getInspectPrompt(): ProximityPrompt
	local inspectPrompt = Instance.new("ProximityPrompt")
	inspectPrompt.Enabled = true
	inspectPrompt.ClickablePrompt = true
	inspectPrompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
	inspectPrompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	inspectPrompt.HoldDuration = 0
	inspectPrompt.KeyboardKeyCode = Enum.KeyCode.E
	inspectPrompt.MaxActivationDistance = 16
	inspectPrompt.MaxIndicatorDistance = 0
	inspectPrompt.Name = "InspectPrompt"
	inspectPrompt.ActionText = "" -- hide interact
	inspectPrompt.ObjectText = "" -- hide object label
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
	-- Create a new ProximityPrompt in the mannequin
	local inspectPrompt = getInspectPrompt() 
	inspectPrompt:AddTag(Constants.INSPECT_PROMPT_TAG)
	inspectPrompt.Parent = mannequin.PrimaryPart or mannequin:FindFirstChildOfClass("BasePart")

	local maxTries = 3
	local tries = 0
	while not inspectPrompt.Parent and tries < maxTries do
		tries += 1
		task.wait(tries)

		local highlight = Instance.new("Highlight")
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.Enabled = true
		highlight.FillColor = Color3.new(1,0,0)
		highlight.Name = "BadMannequin"
		highlight.Parent = mannequin
		warn("Error: No parent of inspect prompt! Attempt: ", tries)
	end
	
	if not inspectPrompt.Parent then
		assert(inspectPrompt.Parent, "Failure to add parent to prompt")
	end

	setupCustomPromptUI(inspectPrompt, mannequin) -- Cece addition

	inspectPrompts[mannequin] = inspectPrompt
end

local function onMannequinRemoved(mannequin: Instance)
	if inspectPrompts[mannequin] then
		inspectPrompts[mannequin]:Destroy()
		inspectPrompts[mannequin] = nil
	end
end



--[[
local function onStateChanged()
    -- Reset submission tracking when Dressing starts
    if CurrentStateName.Value == "Voting" then
        isVoting:set() = false
    end
    
    updateSubmitButton()
end

CurrentStateName.Changed:Connect(onStateChanged)
]]

local CurrentStateName = ReplicatedStorage:WaitForChild("CurrentStateName") :: StringValue
local stateValue = scope:Value(CurrentStateName.Value)

local isVoting = scope:Computed(function(use)  
	return use(stateValue) == "Voting"
end)

local function onStateChanged()
	stateValue:set(CurrentStateName.Value)
	promptHolder.Material = peek(isVoting) and Enum.Material.Neon or Enum.Material.Asphalt
	promptHolder.Color = peek(isVoting) and Color3.fromRGB(0,255,0) or Color3.fromRGB(150,150,150)
end

CurrentStateName.Changed:Connect(onStateChanged)

onStateChanged()

local function initialise()
	-- Set up mannequin tracking
	CollectionService:GetInstanceAddedSignal(Constants.FLOOR_MANNEQUIN_TAG):Connect(onMannequinAdded)
	CollectionService:GetInstanceRemovedSignal(Constants.FLOOR_MANNEQUIN_TAG):Connect(onMannequinRemoved)

	-- Initialise existing mannequins
	for _, mannequin in CollectionService:GetTagged(Constants.FLOOR_MANNEQUIN_TAG) do
		onMannequinAdded(mannequin)
	end

    local VotePrompt = scope:New "ProximityPrompt" {
		Name = "VotePrompt",
        Parent = promptHolder,
        MaxActivationDistance = 20,
        RequiresLineOfSight = false,
        ActionText = "Vote Here!",
		Enabled = isVoting,
        [OnEvent "Triggered"] = function()
            GuiManager.PushCentreByName(MODAL_NAMES.VOTING_GUI)
        end
    } :: ProximityPrompt

	local dudInstance = Instance.new("Model")
	inspectPrompts[dudInstance] = VotePrompt

	-- Connect prompt visibility controls
	PlayerCreatedPreview.Event:Connect(hideAllPrompts)
	PlayerDestroyedPreview.Event:Connect(showAllPrompts)
	HideAllPromptsBindable.Event:Connect(hideAllPrompts)
	ShowAllPromptsBindable.Event:Connect(showAllPrompts)
end
 
task.wait(5)

initialise()