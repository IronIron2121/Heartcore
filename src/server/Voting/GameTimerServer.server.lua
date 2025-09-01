-- GameTimerServer.server.lua
-- Initializes the GameTimer system on server startup

-- Services
local ServerScriptService = game:GetService("ServerScriptService")

-- Folders
local Voting = ServerScriptService:WaitForChild("Voting")

-- Modules 
local GameTimer = require(Voting:WaitForChild("GameTimer"))

-- Initialize the timer system
print("[ThemeTimerStartup] Starting GameTimer system...")
GameTimer.initialiseTimer()
print("[ThemeTimerStartup] GameTimer system started successfully!") 