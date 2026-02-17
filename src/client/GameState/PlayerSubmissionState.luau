--!strict
-- PlayerSubmissionState.luau
-- Client-side state tracking if player has submitted their outfit

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utility = ReplicatedStorage:WaitForChild("Utility")
local Fusion = require(Utility:WaitForChild("Fusion"))

local scope = Fusion:scoped()

-- State value tracking if player has submitted this round
local cooldown = scope:Value(false)

return {
	cooldown = cooldown,
}
