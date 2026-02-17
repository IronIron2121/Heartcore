--!strict
-- GameLoopInit.server.lua

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local GameLoop = ReplicatedStorage:WaitForChild("GameLoop")

local GameStateManager = require(GameLoop.GameStateManager)

GameStateManager.start()