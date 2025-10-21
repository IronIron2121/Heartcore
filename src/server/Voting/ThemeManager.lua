--!strict

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Voting = ServerScriptService:WaitForChild("Voting")
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")

-- Modules
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))
local GameTimer = require(Voting:WaitForChild("GameTimer"))

-- Remotes
local ThemeChangedRemote = RemotesFolder:WaitForChild("ThemeChanged")

local ThemeManager = {}

-- Theme configuration
local AVAILABLE_THEMES = {
    "Cyberpunk Streetwear",
    "Medieval Knight", 
    "Beach Party",
    "Winter Wonderland",
    "Space Explorer",
    "Royal Ball",
    "Sports Day"
}

-- Cache for themes
local currentThemeCache = nil
local previousThemeCache = nil
local erePreviousThemeCache = nil

-- Helper Functions
local function getCurrentUniversalTime()
    return DateTime.now().UnixTimestamp
end

local function pickRandomTheme(): string
    return AVAILABLE_THEMES[math.random(1, #AVAILABLE_THEMES)]
end

local function createNewTheme(): {}
    return {
        theme = pickRandomTheme(),
        timeChanged = getCurrentUniversalTime(),
        phasePrefix = GameTimer.getCurrentPhasePrefix()
    }
end

local function getThemeStoreName(phasePrefix: string): string
    return phasePrefix .. Constants.THEME_MEMORYSTORE_NAME
end

local function getThemeMemoryStore(phasePrefix: string)
    local storeName = getThemeStoreName(phasePrefix)
    local success, memoryStore = callWithRetry(
        function()
            return MemoryStoreService:GetHashMap(storeName)
        end,
        3
    )
    return success and memoryStore or nil
end

-- Public Functions

function ThemeManager.getAvailableThemes(): {string}
    return AVAILABLE_THEMES
end

-- Current theme functions
function ThemeManager.getCurrentTheme(): {}?
    return currentThemeCache
end

function ThemeManager.getCurrentThemeName(): string
    return currentThemeCache and currentThemeCache.theme or "Loading..."
end

function ThemeManager.getCurrentThemeTimeChanged(): number?
    return currentThemeCache and currentThemeCache.timeChanged or nil
end

-- Previous theme functions
function ThemeManager.getPreviousTheme(): {}?
    return previousThemeCache
end

function ThemeManager.getPreviousThemeName(): string
    return previousThemeCache and previousThemeCache.theme or "Loading..."
end

-- Ere-previous theme functions
function ThemeManager.getErePreviousTheme(): {}?
    return erePreviousThemeCache
end

function ThemeManager.getErePreviousThemeName(): string
    return erePreviousThemeCache and erePreviousThemeCache.theme or "Loading..."
end

-- Get theme for a specific phase (for any phase lookup)
function ThemeManager.getThemeForPhase(phasePrefix: string): {}?
    if not phasePrefix then
        warn("No phase prefix provided")
        return nil
    end
    
    local themeStore = getThemeMemoryStore(phasePrefix)
    if not themeStore then
        warn("Failed to get theme store for phase:", phasePrefix)
        return nil
    end
    
    local success, themeData = callWithRetry(
        function()
            return themeStore:GetAsync(Constants.CURRENT_THEME_KEY)
        end,
        3
    )
    
    if success and themeData then
        return themeData
    else
        warn("Failed to get theme for phase:", phasePrefix)
        return nil
    end
end

-- Get yesterday's theme (for voting)
function ThemeManager.getPreviousPhaseTheme(): {}?
    local previousPrefix = GameTimer.getPreviousPhasePrefix()
    if not previousPrefix then
        warn("No previous phase prefix available")
        return nil
    end
    
    return ThemeManager.getThemeForPhase(previousPrefix)
end

function ThemeManager.getPreviousPhaseThemeName(): string
    return currentThemeCache and currentThemeCache.theme or "Loading..."
end

-- Get day-before-yesterday's theme (for winners)
function ThemeManager.getErePreviousPhaseTheme(): {}?
    local erePrefix = GameTimer.getErePreviousPhasePrefix()
    if not erePrefix then
        warn("No ere-previous phase prefix available")
        return nil
    end
    
    return ThemeManager.getThemeForPhase(erePrefix)
end

local function createAndStoreNewTheme(): boolean
    print("Creating new theme for current phase...")
    local currentPrefix = GameTimer.getCurrentPhasePrefix()
    
    if not currentPrefix then
        warn("No current phase prefix available")
        return false
    end
    
    local newTheme = createNewTheme()
    local themeStore = getThemeMemoryStore(currentPrefix)
    
    if not themeStore then
        warn("Failed to get theme memory store")
        return false
    end
    
    local success = callWithRetry(
        function()
            return themeStore:SetAsync(
                Constants.CURRENT_THEME_KEY,
                newTheme,
                Constants.MEMORYSTORE_STORE_DURATION
            )
        end,
        5
    )
    
    if success then
        currentThemeCache = newTheme
        ThemeChangedRemote:FireAllClients(newTheme)
        print("Created and stored new theme:", newTheme.theme, "for phase:", currentPrefix)
        return true
    else
        warn("Failed to store new theme")
        return false 
    end
end

local function loadCurrentTheme(): boolean
    print("Loading current phase theme...")
    local currentPrefix = GameTimer.getCurrentPhasePrefix()
    
    if not currentPrefix then
        warn("No current phase prefix available")
        return false
    end
    
    local themeStore = getThemeMemoryStore(currentPrefix)
    if not themeStore then
        warn("Failed to get theme memory store")
        return false
    end
    
    local success, themeData = callWithRetry(
        function()
            return themeStore:GetAsync(Constants.CURRENT_THEME_KEY)
        end,
        5
    )
    
    if not success then
        warn("Failed to retrieve theme data")
        return false
    end
    
    if not themeData or not themeData.theme then
        print("No existing theme found for current phase, creating new one...")
        return createAndStoreNewTheme()
    else
        currentThemeCache = themeData
        ThemeChangedRemote:FireAllClients(themeData)
        print("Loaded existing theme:", themeData.theme, "for phase:", currentPrefix)
        return true
    end
end

local function loadPreviousTheme(): ()
    print("Loading previous phase theme...")
    local previousPrefix = GameTimer.getPreviousPhasePrefix()
    
    if not previousPrefix then
        warn("No previous phase prefix available")
        previousThemeCache = nil
        return
    end
    
    local themeData = ThemeManager.getThemeForPhase(previousPrefix)
    if themeData then
        previousThemeCache = themeData
        print("Loaded previous theme:", themeData.theme, "for phase:", previousPrefix)
    else
        warn("Failed to load previous theme")
        previousThemeCache = nil
    end
end

local function loadErePreviousTheme(): ()
    print("Loading ere-previous phase theme...")
    local erePrefix = GameTimer.getErePreviousPhasePrefix()
    
    if not erePrefix then
        warn("No ere-previous phase prefix available")
        erePreviousThemeCache = nil
        return
    end
    
    local themeData = ThemeManager.getThemeForPhase(erePrefix)
    if themeData then
        erePreviousThemeCache = themeData
        print("Loaded ere-previous theme:", themeData.theme, "for phase:", erePrefix)
    else
        warn("Failed to load ere-previous theme")
        erePreviousThemeCache = nil
    end
end

-- Called when phase transitions (24-hour cycle)
function ThemeManager.onPhaseTransition()
    print("ThemeManager handling phase transition...")
    
    -- Create and store new theme for the new phase
    local success = createAndStoreNewTheme()
    
    if not success then
        warn("Failed to create new theme during phase transition")
    end
    
    -- Reload previous and ere-previous themes (they've shifted)
    loadPreviousTheme()
    loadErePreviousTheme()
end

-- Initialize the theme system
function ThemeManager.initialise(): boolean
    print("Initializing ThemeManager...")
    
    -- Load current theme
    local success = loadCurrentTheme()
    
    if not success then
        warn("Failed to initialize theme system")
        return false
    end
    
    -- Load previous and ere-previous themes (if they exist)
    loadPreviousTheme()
    loadErePreviousTheme()
    
    print("ThemeManager initialized successfully")
    return true
end

return ThemeManager