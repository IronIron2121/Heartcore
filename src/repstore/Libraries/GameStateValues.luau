--!strict
-- GameStateValues.lua
-- Bridges Roblox ValueObjects to Fusion reactive Values

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utility = ReplicatedStorage:WaitForChild("Utility")
local Fusion = require(Utility:WaitForChild("Fusion"))

local Values = ReplicatedStorage:WaitForChild("Values")
local CurrentStateName = Values:WaitForChild("CurrentStateName") :: StringValue
local CurrentThemeName = Values:WaitForChild("CurrentThemeName") :: StringValue
local SecondsRemaining = Values:WaitForChild("SecondsRemaining") :: IntValue

local scope = Fusion:scoped()

-- Bridge ValueObjects to Fusion Values
local stateName = scope:Value(CurrentStateName.Value)
local themeName = scope:Value(CurrentThemeName.Value)
local secondsRemaining = scope:Value(SecondsRemaining.Value)

CurrentStateName.Changed:Connect(function(newValue)
	stateName:set(newValue)
end)

CurrentThemeName.Changed:Connect(function(newValue)
	themeName:set(newValue)
end)

SecondsRemaining.Changed:Connect(function(newValue)
	secondsRemaining:set(newValue)
end)

-- Pre-built computed values for common state checks
local isVoting = scope:Computed(function(use)
	return use(stateName) == "Voting"
end)

local isDressing = scope:Computed(function(use)
	return use(stateName) == "Dressing"
end)

local isIntermission = scope:Computed(function(use)
	return use(stateName) == "Intermission"
end)

-- Formatted time string (e.g., "3:45")
local formattedTime = scope:Computed(function(use)
	local seconds = use(secondsRemaining)
	local minutes = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%d:%02d", minutes, secs)
end)

return {
	-- Raw Fusion Values (can be used with `use()`)
	stateName = stateName,
	themeName = themeName,
	secondsRemaining = secondsRemaining,
	
	-- Pre-built boolean computeds for state checks
	isVoting = isVoting,
	isDressing = isDressing,
	isIntermission = isIntermission,
	
	-- Utility computeds
	formattedTime = formattedTime,
}