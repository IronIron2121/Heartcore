-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Instances
local localPlayer = Players.LocalPlayer

-- GUI Elements
local playerGui = localPlayer.PlayerGui
local shoppingGui = playerGui:WaitForChild("ShoppingGui")
local inspectFrame = shoppingGui:WaitForChild("InspectFrame")

-- Module Scripts
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))

function getRecentMannequinId()
	return inspectFrame:GetAttribute(Constants.RECENT_MANNEQUIN_ATTRIBUTE)
end

return getRecentMannequinId