-- ThemeManager.lua
-- Manages staggered contests: one submission & one voting active.

-- Services
local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))

-- Memory Stores
local CurrentThemeMemoryStore = MemoryStoreService:GetSortedMap(Constants.CURRENT_THEME_MEMORYSTORE_NAME)
local CurrentTheme = nil -- To be initialised later

-- Constants
local CHECK_TIME_LAPSE_INTERVAL = 10
local DEBUG_SECONDS_BETWEEN_THEME_CHANGE = 60
local SECONDS_BETWEEN_THEME_CHANGE = 3880000

local Themes = {
	"Cyberpunk Streetwear",
	"Medieval Knight",
	"Beach Party",
	"Winter Wonderland",
	"Space Explorer",
	"Royal Ball",
	"Sports Day"
}

local function getCurrentUniversalTime()
	return DateTime.now().UnixTimestamp
end

local function getLastTimeChanged()
	return CurrentTheme and CurrentTheme.TimeChanged or nil
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
	return Themes[math.random(1,#Themes)] 
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
		-- TODO: shutdown the server
		warn("Failed to initialise themes!")
		return
	end

	if not currentThemeData or not currentThemeData["Theme"] then
		warn("No current theme! Initialising...")
		local newTheme = setNewTheme()
		local _, setSuccess = callWithRetry(
			function()
				return CurrentThemeMemoryStore:SetAsync(
					Constants.CURRENT_THEME_KEY,
					newTheme,
					3888000 -- 45 days max
				)
			end,
			5
		)
		
		if setSuccess then
			CurrentTheme = newTheme
			print("Initialized new theme: " .. newTheme.Theme)
		else
			warn("Failed to set new theme!")
		end
	else
		warn("Memory store already existent!")
		CurrentTheme = currentThemeData
		print("Loaded existing theme: " .. currentThemeData.Theme)
	end
end

initialiseTheme()

task.spawn(function()
	while true do
		task.wait(CHECK_TIME_LAPSE_INTERVAL)
		warn("Checking theme expiry...")
		
		if currentThemeHasExpired() then
			print("Theme has expired, updating...")
			local newTheme = setNewTheme()
			local _, success = callWithRetry(
				function()
					return CurrentThemeMemoryStore:SetAsync(
						Constants.CURRENT_THEME_KEY,
						newTheme,
						3888000 -- TODO: This can be more like 2 days or 4 days or whatever
					)
				end,
				5
			)
			
			if success then
				CurrentTheme = newTheme
				print("Updated to new theme: " .. newTheme.Theme)
			else
				warn("Failed to update theme!")
			end
		else
			print("Theme is still valid!")
			print(CurrentTheme)
		end
	end
end)