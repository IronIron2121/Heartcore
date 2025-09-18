-- ThemeController.lua (ServerScript)
-- SERVER-ONLY: Handles all MemoryStore operations

--[[
-- Services
local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Controllers = ReplicatedStorage:WaitForChild("Controllers")

-- Modules
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))
local ThemeManager = require(Controllers:WaitForChild("ThemeManager"))

-- Memory Stores
local CurrentThemeMemoryStore = MemoryStoreService:GetSortedMap(Constants.CONTEST_MEMORYSTORE_NAME)

-- Create RemoteEvent for theme updates
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes") 

local ThemeChangedRemote = RemotesFolder:WaitForChild("ThemeChanged")

-- Server-only functions
local function getCurrentUniversalTime()
	return DateTime.now().UnixTimestamp
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
	local success, currentThemeData = callWithRetry(
		function()
			return CurrentThemeMemoryStore:GetAsync(Constants.CURRENT_THEME_KEY)
		end, 
		5
	)

	if not success then
		warn("Failed to initialise themes!", currentThemeData)
		return false
	end

	if not currentThemeData or not currentThemeData["Theme"] then
		warn("No current theme! Initialising...")
		local newTheme = setNewTheme()
		local setSuccess, result = callWithRetry(
			function()
				return CurrentThemeMemoryStore:SetAsync(
					Constants.CURRENT_THEME_KEY,
					newTheme,
					Constants.MEMORYSTORE_STORE_DURATION
				)
			end,
			5
		)
		
		if setSuccess then
			ThemeManager:_updateThemeData(newTheme)
			ThemeChangedRemote:FireAllClients(newTheme)
			return setSuccess
		else
			warn("Failed to set new theme!")
			return setSuccess, result
		end
	else
		warn("Memory store already existent!")
		ThemeManager:_updateThemeData(currentThemeData)
		ThemeChangedRemote:FireAllClients(currentThemeData)
		return true
	end
end

local function updateTheme()
	print("Theme has expired, updating...")
	-- BEFORE getting a new theme, we need to port over all of our submissions to the contest store
	-- Means figuring out some more stuff...

	-- BEFORE the below, we need to move the current 
	local newTheme = setNewTheme()
	local _, success = callWithRetry(
		function()
			return CurrentThemeMemoryStore:SetAsync(
				Constants.CURRENT_THEME_KEY,
				newTheme,
				Constants.MEMORYSTORE_STORE_DURATION
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
task.wait(2)
local success, err = initialiseTheme()
if not success then
	error("Failed to initialize theme system", err)
end
]]