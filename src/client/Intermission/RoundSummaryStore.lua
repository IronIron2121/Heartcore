--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RoundSummaryRE = Remotes:WaitForChild("RoundSummaryRE") :: RemoteEvent

--

export type XpEntry = { label: string, amount: number }
export type ChallengeEntry = {
	id: string,
	label: string,
	progress: number,
	target: number,
	xpReward: number,
}
export type RoundSummary = {
	placement: number?,
	previousExp: number,
	xpBreakdown: { XpEntry },
	totalXp: number,
	challenges: { ChallengeEntry },
}

local RoundSummaryStore = {}
RoundSummaryStore.latest = nil :: RoundSummary?

RoundSummaryRE.OnClientEvent:Connect(function(data: RoundSummary)
	RoundSummaryStore.latest = data
end)

return RoundSummaryStore
