--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local DataManager = require(ServerScriptService.Data.DataManager)

--

export type XpEntry = { label: string, amount: number }
type PlayerRecord = { breakdown: { XpEntry }, total: number }

local pending: { [number]: PlayerRecord } = {}

local RoundXpTracker = {}

function RoundXpTracker.accumulate(userId: number, amount: number, label: string)
	if amount <= 0 then return end

	if not pending[userId] then
		pending[userId] = { breakdown = {}, total = 0 }
	end

	local record = pending[userId]
	record.total += amount

	-- Merge repeated labels (e.g. multiple VOTES_RECEIVED calls become one row)
	for _, entry in record.breakdown do
		if entry.label == label then
			entry.amount += amount
			return
		end
	end

	table.insert(record.breakdown, { label = label, amount = amount })
end

function RoundXpTracker.getForPlayer(userId: number): PlayerRecord?
	return pending[userId]
end

function RoundXpTracker.applyAll(players: { Player })
	for _, player in players do
		local record = pending[player.UserId]
		if record and record.total > 0 then
			DataManager.AddExp(player, record.total)
		end
	end
	pending = {}
end

function RoundXpTracker.reset()
	pending = {}
end

return RoundXpTracker
