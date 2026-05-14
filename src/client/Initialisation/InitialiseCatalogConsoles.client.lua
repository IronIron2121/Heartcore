--!strict

-- Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Folders
local Bindables = ReplicatedStorage:WaitForChild("Bindables")

-- Modules
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))

-- Remotes / Bindables
local PlayerTriggeredCatalogConsole = Bindables:WaitForChild("PlayerTriggeredCatalogConsole")
local HideAllPromptsBindable = Bindables:WaitForChild("HideAllPromptsBindable")
local ShowAllPromptsBindable = Bindables:WaitForChild("ShowAllPromptsBindable")

-- Parent to player gui so buttons are interactable
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local allPrompts = Instance.new("ScreenGui", playerGui)
allPrompts.Name = "CatalogPrompts"

-- State
local catalogPrompts: { [Instance]: ProximityPrompt } = {}

local function hideAllPrompts()
	for _, prompt in catalogPrompts do
		prompt.Enabled = false
	end
end

local function showAllPrompts()
	for _, prompt in catalogPrompts do
		prompt.Enabled = true
	end
end

-- Create custom GUI when proximity prompt appears
local function setupCustomPromptUI(prompt: ProximityPrompt, consoleBase: BasePart)
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.ActionText = "" -- hide Roblox default
	prompt.ObjectText = ""

	-- Prevent duplicates
	if consoleBase:FindFirstChild("CustomCatalogPrompt") or not consoleBase.Parent then
		return
	end 

	local consoleType = consoleBase.Parent.Name

	local billboard = Instance.new("BillboardGui", allPrompts)
	billboard.Name = "CustomCatalogPrompt"
	billboard.Adornee = consoleBase
	billboard.Size = UDim2.new(0, 120, 0, 35)
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
	
	-- Rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(3, 0)
	corner.Parent = frame

	-- Add border
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame

	-- Add text button
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 1, 0)
	button.BackgroundTransparency = 1
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.FredokaOne
	button.TextSize = 15
	button.Text = ""
    button.TextWrapped = true
	button.AutoButtonColor = false
	button.Parent = frame

	-- Rounded button corners
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(3, 0)
	buttonCorner.Parent = button

	-- Tween settings
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local function tweenBackground(targetTransparency: number)
		TweenService:Create(frame, tweenInfo, {BackgroundTransparency = targetTransparency}):Play()
	end

	-- Hover animations
	button.MouseEnter:Connect(function()
		tweenBackground(0.1)
	end)

	button.MouseLeave:Connect(function()
		tweenBackground(0.5)
	end)

	button.Activated:Connect(function()
		PlayerTriggeredCatalogConsole:Fire(consoleType)
	end)

	-- Update the text key prompt dynamically
	local function keyCodeToLabel(keyCode: Enum.KeyCode): string
		if keyCode == Enum.KeyCode.Unknown then
			return ""
		elseif keyCode == Enum.KeyCode.ButtonX then
			return "[X]"
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
		local action = "Browse the catalog"
		local keyText = ""

		if UserInputService.GamepadEnabled then
			keyText = keyCodeToLabel(prompt.GamepadKeyCode)
		elseif UserInputService.KeyboardEnabled then
			keyText = keyCodeToLabel(prompt.KeyboardKeyCode)
		elseif UserInputService.TouchEnabled then
			keyText = "[Tap]"
		end

		button.Text = action
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

local function onCatalogConsoleActivated(player: Player, consoleName: string)
    PlayerTriggeredCatalogConsole:Fire(consoleName)
end

local function initialiseCatalogConsole(ConsoleBase: BasePart)
	if not ConsoleBase.Parent then return end
	local consoleType = ConsoleBase.Parent.Name

    if not ConsoleBase:FindFirstChildOfClass("ProximityPrompt") then
        local consolePrompt = Instance.new("ProximityPrompt", ConsoleBase)
        consolePrompt.Name = Constants.CATALOG_CONSOLE_PROMPT_NAME
        consolePrompt.HoldDuration = 0
        consolePrompt.Enabled = true
        consolePrompt.ClickablePrompt = true
        consolePrompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
        consolePrompt.GamepadKeyCode = Enum.KeyCode.ButtonX
        consolePrompt.KeyboardKeyCode = Enum.KeyCode.E
        consolePrompt.ActionText = ""
        consolePrompt.ObjectText = ""
        consolePrompt.MaxActivationDistance = 10
        consolePrompt.RequiresLineOfSight = false
        
        consolePrompt.Triggered:Connect(function(player)
            onCatalogConsoleActivated(player, consoleType)
        end)
        
        -- Setup custom UI for this prompt
        setupCustomPromptUI(consolePrompt, ConsoleBase)
        
        -- Store the prompt for show/hide functionality
        catalogPrompts[ConsoleBase] = consolePrompt
    end
end

local function initialiseAllCatalogConsoles()
    local catalogConsoles = CollectionService:GetTagged(Constants.CATALOG_CONSOLE_TAG)
    for _, ConsoleBase in ipairs(catalogConsoles) do
        initialiseCatalogConsole(ConsoleBase)
    end

    -- Run the function on any new consoles added
    CollectionService:GetInstanceAddedSignal(Constants.CATALOG_CONSOLE_TAG):Connect(initialiseCatalogConsole)
    
    -- Connect prompt visibility controls
    HideAllPromptsBindable.Event:Connect(hideAllPrompts)
    ShowAllPromptsBindable.Event:Connect(showAllPrompts)
end

initialiseAllCatalogConsoles()