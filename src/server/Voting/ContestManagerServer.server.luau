-- ThemeController.lua (ServerScript)
-- SERVER-ONLY: Handles all MemoryStore operations

-- Services
local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))
local ThemeManager = require(ReplicatedStorage:WaitForChild("Controllers"):WaitForChild("ThemeManager"))

-- Memory Stores
local CurrentThemeMemoryStore = MemoryStoreService:GetSortedMap(Constants.CURRENT_CONTEST_MEMORYSTORE_NAME)

-- Constants
local CHECK_TIME_LAPSE_INTERVAL = 10
local DEBUG_SECONDS_BETWEEN_THEME_CHANGE = 60
local SECONDS_BETWEEN_THEME_CHANGE = 3880000

-- Create RemoteEvent for theme updates
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes") 

local ThemeChangedRemote = RemotesFolder:WaitForChild("ThemeChanged")

-- Server-only functions
local function getCurrentUniversalTime()
	return DateTime.now().UnixTimestamp
end

local function getLastTimeChanged()
	return ThemeManager.CurrentTheme and ThemeManager.CurrentTheme.TimeChanged or nil
end

local function currentThemeHasExpired()
	local currentTime = getCurrentUniversalTime()
	local lastChanged = getLastTimeChanged()
	
	if not lastChanged then
		return true -- No theme set yet
	end
	
	return (currentTime - lastChanged) >= DEBUG_SECONDS_BETWEEN_THEME_CHANGE
end

local function pickTheme()
	return ThemeManager.Themes[math.random(1, #ThemeManager.Themes)] 
end

local function setNewTheme()
	local newTheme = {
		Theme = pickTheme(),
		TimeChanged = getCurrentUniversalTime()
	}
	return newTheme
end

local function initialiseTheme()
	local currentThemeData, success = callWithRetry(
		function()
			return CurrentThemeMemoryStore:GetAsync(Constants.CURRENT_THEME_KEY)
		end, 
		5
	)

	if not success then
		warn("Failed to initialise themes!")
		return false
	end

	if not currentThemeData or not currentThemeData["Theme"] then
		warn("No current theme! Initialising...")
		local newTheme = setNewTheme()
		local _, setSuccess = callWithRetry(
			function()
				return CurrentThemeMemoryStore:SetAsync(
					Constants.CURRENT_THEME_KEY,
					newTheme,
					3888000
				)
			end,
			5
		)
		
		if setSuccess then
			ThemeManager:_updateThemeData(newTheme)
			ThemeChangedRemote:FireAllClients(newTheme)
			return true
		else
			warn("Failed to set new theme!")
			return false
		end
	else
		warn("Memory store already existent!")
		ThemeManager:_updateThemeData(currentThemeData)
		ThemeChangedRemote:FireAllClients(currentThemeData)
		print("Loaded existing theme: " .. currentThemeData.Theme)
		return true
	end
end

local function updateTheme()
	print("Theme has expired, updating...")
	local newTheme = setNewTheme()
	local _, success = callWithRetry(
		function()
			return CurrentThemeMemoryStore:SetAsync(
				Constants.CURRENT_THEME_KEY,
				newTheme,
				3888000
			)
		end,
		5
	)
	
	if success then
		-- TODO: Make a datastore that only says if we're currently changing the theme
		ThemeManager:_updateThemeData(newTheme)
		ThemeChangedRemote:FireAllClients(newTheme)
		print("Updated to new theme: " .. newTheme.Theme)
		return true
	else
		warn("Failed to update theme!")

		--TODO: Destroy server?
		return false
	end
end

-- Initialize the theme system
local success = initialiseTheme()
if not success then
	error("Failed to initialize theme system")
end

-- Start the monitoring loop
task.spawn(function()
	while true do
		task.wait(CHECK_TIME_LAPSE_INTERVAL)
		warn("Checking theme expiry...")
		
		if currentThemeHasExpired() then
			updateTheme()
		else
			print("Theme is still valid!")
			print(ThemeManager:getCurrentTheme())
		end
	end
end)

