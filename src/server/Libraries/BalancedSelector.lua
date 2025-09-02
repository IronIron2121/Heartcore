-- BalancedSelector.lua
-- WHAT THIS DOES:
-- This module ensures fair exposure for all outfit submissions by prioritizing outfits
-- that have been viewed the least. It creates balanced groups where less popular
-- outfits get more chances to be seen, preventing the same popular outfits from
-- dominating the voting interface.

-- Services
local ServerScriptService = game:GetService("ServerScriptService")

-- Folders
local Voting = ServerScriptService:WaitForChild("Voting")

-- Modules
local ContestStoreManager = require(Voting:WaitForChild("ContestStoreManager"))

local BalancedSelector = {}

--[[
	ALGORITHM EXPLANATION:
	1. Find the minimum view count among all eligible outfits
	2. Create a "candidate pool" of outfits with view counts close to the minimum (within buffer range)
	3. Randomly shuffle this candidate pool to add variety
	4. Return the requested number of outfits from this balanced pool
	
	This ensures less-viewed outfits get priority while still maintaining some randomness.
]]

function BalancedSelector.PickGroup(numberOfOutfits, alreadySeenOutfits, requiredTheme)
	-- Default to 6 outfits if not specified (typical voting UI size)
	numberOfOutfits = numberOfOutfits or 3
	
	-- Get all available outfit submissions from the store
	local allAvailableOutfits = ContestStoreManager.getPublicCache()
	
	-- STEP 1: Find the minimum view count among eligible outfits
	local minimumViewCount = math.huge
	
	for outfitId, outfitData in pairs(allAvailableOutfits) do
		-- Check if this outfit meets our criteria:
		-- - Not already seen by this user (if we're tracking that)
		-- - Matches the required theme (if specified)
		--local isAlreadySeen = alreadySeenOutfits and alreadySeenOutfits[outfitId]
		--local hasCorrectTheme = not requiredTheme or outfitData.theme == requiredTheme
		
		--if not isAlreadySeen and hasCorrectTheme then
		--if not isAlreadySeen and hasCorrectTheme then
		local currentViewCount = outfitData.views or 0
		if currentViewCount < minimumViewCount then
			minimumViewCount = currentViewCount
		end
	end
	
	-- If no eligible outfits found, return empty table
	if minimumViewCount == math.huge then 
		return {} 
	end

	-- STEP 2: Build candidate pool of outfits with low view counts
	local viewCountBuffer = 2  -- Allow outfits with up to 2 more views than minimum
	local candidateOutfitPool = {}
	
	for outfitId, outfitData in pairs(allAvailableOutfits) do
		-- Apply the same eligibility criteria as above
		local isAlreadySeen = alreadySeenOutfits and alreadySeenOutfits[outfitId]
		local hasCorrectTheme = not requiredTheme or outfitData.theme == requiredTheme
		
		if not isAlreadySeen and hasCorrectTheme then
			local currentViewCount = outfitData.views or 0
			-- Include outfits that are within the buffer range of minimum views
			if currentViewCount <= minimumViewCount + viewCountBuffer then
				table.insert(candidateOutfitPool, outfitId)
			end
		end
	end

	-- STEP 3: Randomly shuffle the candidate pool using Fisher-Yates algorithm
	-- This ensures variety even among equally-viewed outfits
	for i = #candidateOutfitPool, 2, -1 do
		local randomIndex = math.random(i)
		candidateOutfitPool[i], candidateOutfitPool[randomIndex] = candidateOutfitPool[randomIndex], candidateOutfitPool[i]
	end

	-- STEP 4: Select the requested number of outfits from the shuffled pool
	local selectedOutfits = {}
	local maxOutfitsToReturn = math.min(numberOfOutfits, #candidateOutfitPool)
	
	for i = 1, maxOutfitsToReturn do 
		table.insert(selectedOutfits, candidateOutfitPool[i]) 
	end
	
	return selectedOutfits
end

return BalancedSelector