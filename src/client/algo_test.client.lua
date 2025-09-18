-- Weighted Random Selection Algorithm Test
-- Tests the performance and fairness of view-count weighted selection

--[[
local function generateTestData(count)
    local outfits = {}
    
    for i = 1, count do
        -- Create realistic view count distribution
        -- Most outfits have low views, some have moderate, few have high
        local viewCount
        local rand = math.random()
        
        if rand < 0.6 then
            -- 60% have 0-10 views
            viewCount = math.random(0, 10)
        elseif rand < 0.85 then
            -- 25% have 11-50 views  
            viewCount = math.random(11, 50)
        elseif rand < 0.95 then
            -- 10% have 51-200 views
            viewCount = math.random(51, 200)
        else
            -- 5% have 201-1000 views (popular outfits)
            viewCount = math.random(201, 1000)
        end
        
        outfits["outfit_" .. i] = {
            userId = i,
            playerName = "Player" .. i,
            views = viewCount,
            votes = math.random(0, viewCount), -- Votes somewhat correlate with views
            humanoidDescription = "dummy_data_" .. i
        }
    end
    
    return outfits
end

local function pickGroupWeighted(outfits, numberOfOutfits)
    numberOfOutfits = numberOfOutfits or 6
    
    -- STEP 1: Calculate weights (inverse of view count)
    local candidates = {}
    local totalWeight = 0
    
    for outfitId, outfitData in pairs(outfits) do
        -- Weight formula: higher views = lower selection probability
        -- Adding 1 prevents division by zero and gives 0-view outfits max weight
        local weight = 1 / (outfitData.views + 1)
        
        table.insert(candidates, {
            id = outfitId,
            data = outfitData,
            weight = weight
        })
        totalWeight = totalWeight + weight
    end
    
    -- STEP 2: Select outfits using weighted random selection
    local selectedOutfits = {}
    local tempCandidates = {} -- Copy for selection without replacement
    for i, candidate in ipairs(candidates) do
        tempCandidates[i] = candidate
    end
    
    for selection = 1, math.min(numberOfOutfits, #tempCandidates) do
        -- Recalculate total weight for remaining candidates
        local currentTotalWeight = 0
        for _, candidate in ipairs(tempCandidates) do
            if candidate then
                currentTotalWeight = currentTotalWeight + candidate.weight
            end
        end
        
        -- Random selection based on weight
        local randomValue = math.random() * currentTotalWeight
        local cumulativeWeight = 0
        
        for i, candidate in ipairs(tempCandidates) do
            if candidate then
                cumulativeWeight = cumulativeWeight + candidate.weight
                if randomValue <= cumulativeWeight then
                    -- Selected this outfit
                    table.insert(selectedOutfits, candidate.id)
                    tempCandidates[i] = nil -- Remove from candidates
                    break
                end
            end
        end
    end
    
    return selectedOutfits
end

-- Performance test function
local function runPerformanceTest()
    print("=== Weighted Selection Algorithm Performance Test ===")
    
    -- Test with different data sizes
    local testSizes = {100, 1000, 5000, 10000, 100000, 1000000}
    
    for _, size in ipairs(testSizes) do
        print(string.format("\nTesting with %d outfits:", size))
        
        -- Generate test data
        local startTime = tick()
        local testOutfits = generateTestData(size)
        local generationTime = tick() - startTime
        print(string.format("  Data generation: %.3f seconds", generationTime))
        
        -- Test selection performance
        local selectionStartTime = tick()
        local selectedOutfits = pickGroupWeighted(testOutfits, 3)
        local selectionTime = tick() - selectionStartTime
        print(string.format("  Selection time: %.3f seconds", selectionTime))
        print(string.format("  Selected %d outfits", #selectedOutfits))
    end
end

-- Fairness test function
local function runFairnessTest()
    print("\n=== Fairness Analysis ===")
    
    -- Create test data with known view distribution
    local testOutfits = generateTestData(1000)
    
    -- Track how often outfits with different view counts get selected
    local selectionStats = {
        [0] = 0,   -- 0-10 views
        [1] = 0,   -- 11-50 views  
        [2] = 0,   -- 51-200 views
        [3] = 0    -- 201+ views
    }
    
    local viewDistribution = {
        [0] = 0,   -- Count of outfits with 0-10 views
        [1] = 0,   -- Count of outfits with 11-50 views
        [2] = 0,   -- Count of outfits with 51-200 views
        [3] = 0    -- Count of outfits with 201+ views
    }
    
    -- Categorize outfits by view count
    for outfitId, outfitData in pairs(testOutfits) do
        local views = outfitData.views
        if views <= 10 then
            viewDistribution[0] = viewDistribution[0] + 1
        elseif views <= 50 then
            viewDistribution[1] = viewDistribution[1] + 1
        elseif views <= 200 then
            viewDistribution[2] = viewDistribution[2] + 1
        else
            viewDistribution[3] = viewDistribution[3] + 1
        end
    end
    
    -- Run many selections to gather statistics
    local numTests = 500
    for test = 1, numTests do
        local selected = pickGroupWeighted(testOutfits, 6)
        
        for _, outfitId in ipairs(selected) do
            local views = testOutfits[outfitId].views
            if views <= 10 then
                selectionStats[0] = selectionStats[0] + 1
            elseif views <= 50 then
                selectionStats[1] = selectionStats[1] + 1
            elseif views <= 200 then
                selectionStats[2] = selectionStats[2] + 1
            else
                selectionStats[3] = selectionStats[3] + 1
            end
        end
    end
    
    -- Print results
    print("View Range Distribution vs Selection Rate:")
    local categories = {"0-10 views", "11-50 views", "51-200 views", "201+ views"}
    
    for i = 0, 3 do
        local populationPercent = (viewDistribution[i] / 1000) * 100
        local selectionPercent = (selectionStats[i] / (numTests * 6)) * 100
        print(string.format("  %s: %.1f%% of population, %.1f%% of selections", 
            categories[i+1], populationPercent, selectionPercent))
    end
end

-- Sample usage test
local function runSampleTest()
    print("\n=== Sample Selection Test ===")
    
    local sampleOutfits = generateTestData(20)
    
    print("Sample outfit data (first 5):")
    local count = 0
    for outfitId, outfitData in pairs(sampleOutfits) do
        if count < 5 then
            print(string.format("  %s: %d views, %d votes", outfitId, outfitData.views, outfitData.votes))
            count = count + 1
        end
    end
    
    print("\nRunning 3 selections:")
    for i = 1, 3 do
        local selected = pickGroupWeighted(sampleOutfits, 3)
        print(string.format("Selection %d:", i))
        for _, outfitId in ipairs(selected) do
            local outfit = sampleOutfits[outfitId]
            print(string.format("  %s (%d views)", outfitId, outfit.views))
        end
    end
end

-- Run all tests
runPerformanceTest()
runFairnessTest()
runSampleTest()

print("\n=== Test Complete ===")
print("The weighted selection algorithm should:")
print("1. Complete selections in reasonable time even with 10,000+ outfits")
print("2. Favor low-view outfits while still giving some chance to high-view ones")
print("3. Provide variety in selections through weighted randomness")
]]