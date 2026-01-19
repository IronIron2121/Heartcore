--!strict

-- Services
local CollectionService =  game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Bindables = ReplicatedStorage:WaitForChild("Bindables")

-- Modules
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))

-- Remotes / Bindables
local PlayerTriggeredCatalogConsole = Bindables:WaitForChild("PlayerTriggeredCatalogConsole")

--

local function onCatalogConsoleActivated(player: Player)
    PlayerTriggeredCatalogConsole:Fire() 
end

local function initialiseCatalogConsole(ConsoleBase: BasePart)
    if not ConsoleBase:FindFirstChildOfClass("ProximityPrompt") then
        local consolePrompt = Instance.new("ProximityPrompt", ConsoleBase)
        consolePrompt.Name = Constants.CATALOG_CONSOLE_PROMPT_NAME
        consolePrompt.HoldDuration = 0
        consolePrompt.Enabled = true
        consolePrompt.ActionText = "Browse the catalog"
        consolePrompt.MaxActivationDistance = 10
        consolePrompt.RequiresLineOfSight = false
        consolePrompt.Triggered:Connect(function(player)
            onCatalogConsoleActivated(player)
        end)
    end
end

local function initialiseAllCatalogConsoles()
    local catalogConsoles = CollectionService:GetTagged(Constants.CATALOG_CONSOLE_TAG)
    for _, ConsoleBase in ipairs(catalogConsoles) do
        initialiseCatalogConsole(ConsoleBase)
    end

    -- run the function on any 
    CollectionService:GetInstanceAddedSignal(Constants.CATALOG_CONSOLE_TAG):Connect(initialiseCatalogConsole)
end

initialiseAllCatalogConsoles()