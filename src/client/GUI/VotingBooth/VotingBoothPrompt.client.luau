--!strict 

-- Services

-- Instances
local votingBooth = workspace:WaitForChild("VotingBooth")
local promptHolder = votingBooth:WaitForChild("PromptHolder")
local votePrompt = promptHolder:WaitForChild("VotePrompt")

--

local function onVotePromptActivated()
    warn("Player prompted!")
end



votePrompt.Triggered:Connect(onVotePromptActivated)