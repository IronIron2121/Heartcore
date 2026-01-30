--!strict
-- GameLoopInit.server.lua

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local GameLoop = ReplicatedStorage:WaitForChild("GameLoop")

local GameOutfitManager = require(GameLoop.GameOutfitManager)
local GameStateManager = require(GameLoop.GameStateManager)

GameOutfitManager.initialize()
GameStateManager.start()