--!strict

-- FusionComponents
local DailyChallengeGui = require(script:WaitForChild("DailyChallengeGui"))

--

local DailyChallengeGuiController = {}

-- TODO: I think it would make more sense if we initialiased the mainhud elsewhere, but this will do for now
function DailyChallengeGuiController.Initialise()
	-- Get the open outfit catalog button so we can pass it to the catalog gui that uses it
	local DailyChallengeGui = DailyChallengeGui()
end 

return DailyChallengeGuiController