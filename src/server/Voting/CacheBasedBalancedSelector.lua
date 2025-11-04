-- CacheBasedBalancedSelector.lua
-- Uses VotingStoreManager's public cache to build selection buckets

-- Services
local ServerScriptService = game:GetService("ServerScriptService")

-- Folders
local Voting = ServerScriptService:WaitForChild("Voting")

--
local PlayerVotedOutfitsTracker = require(script.Parent.PlayerVotedOutfitsTracker)
local PlayerOutedOutfitsTracker = require(Voting:WaitForChild("PlayerVotedOutfitsTracker"))
--

local CacheBasedBalancedSelector = {}
CacheBasedBalancedSelector.__index = CacheBasedBalancedSelector

-- Configuration for 100k+ outfits
local CONFIG = {
    -- View count tiers (designed for large scale distribution)
    VIEW_TIERS = {
        {min = 0, max = 2, weight = 50},      -- Fresh outfits (highest priority)
        {min = 3, max = 9, weight = 25},      -- Low views
        {min = 10, max = 24, weight = 15},    -- Medium-low views  
        {min = 25, max = 49, weight = 7},     -- Medium views
        {min = 50, max = 99, weight = 2},     -- High views
        {min = 100, max = math.huge, weight = 1}  -- Very high views (lowest priority)
    },
    
    -- Sampling limits for performance
    MAX_OUTFITS_PER_TIER = 1000,  -- Sample from each tier to limit memory
    MIN_SELECTION_POOL = 50,       -- Minimum outfits to select from
    
    -- Hash-based fallback for extreme scale
    HASH_BUCKETS = 500,            -- For deterministic distribution
    FALLBACK_SAMPLE_SIZE = 200     -- When tiers fail
}

function CacheBasedBalancedSelector.new()
    local self = setmetatable({}, CacheBasedBalancedSelector)
    
    -- Selection buckets built from cache
    self.selectionBuckets = {}
    self.totalWeightedOutfits = 0
    self.lastBucketUpdate = 0
    
    -- Performance tracking
    self.stats = {
        selectionsServed = 0,
        cacheHits = 0,
        fallbackSelections = 0,
        lastRebuildTime = 0
    }
    
    return self 
end

-- Rebuild selection buckets from the public cache (call this in updatePublicCache!)
function CacheBasedBalancedSelector:rebuildFromCache(publicCache)
    local startTime = tick()
    print("Rebuilding selection buckets from cache...")
     
    -- initialise empty buckets for each tier
    local newBuckets = {}
    for i, tier in ipairs(CONFIG.VIEW_TIERS) do
        newBuckets[i] = {
            outfits = {},
            weight = tier.weight,
            minViews = tier.min,
            maxViews = tier.max,
            totalOutfits = 0
        }
    end
    
    -- Distribute outfits into tiers based on view count
    local totalProcessed = 0
    for entryKey, entryData in pairs(publicCache) do
        totalProcessed = totalProcessed + 1
        local views = entryData.views or 0
        
        -- Find appropriate tier for this outfit
        for tierIndex, tier in ipairs(CONFIG.VIEW_TIERS) do
            if views >= tier.min and views <= tier.max then
                local bucket = newBuckets[tierIndex]
                 
                -- Add to bucket if there's room, otherwise sample replace
                if #bucket.outfits < CONFIG.MAX_OUTFITS_PER_TIER then
                    table.insert(bucket.outfits, {
                        entryKey = entryKey,
                        views = views,
                        votes = entryData.votes,
                        userId = entryData.userId,
                        humanoidDescription = entryData.humanoidDescription
                    })
                else
                    -- Reservoir sampling to maintain randomness
                    local randomIndex = math.random(1, bucket.totalOutfits + 1)
                    if randomIndex <= CONFIG.MAX_OUTFITS_PER_TIER then
                        bucket.outfits[randomIndex] = {
                            entryKey = entryKey,
                            views = views,
                            votes = entryData.votes,
                            userId = entryData.userId,
                            humanoidDescription = entryData.humanoidDescription
                        }
                    end
                end
                
                bucket.totalOutfits = bucket.totalOutfits + 1
                break
            end
        end
    end
    
    -- Calculate total weighted outfits for selection
    local totalWeighted = 0
    for _, bucket in ipairs(newBuckets) do
        local bucketContribution = math.min(bucket.totalOutfits, CONFIG.MAX_OUTFITS_PER_TIER) * bucket.weight
        totalWeighted = totalWeighted + bucketContribution
        
        print(string.format("Tier %d-%d views: %d outfits (using %d, weight %d)", 
            bucket.minViews, bucket.maxViews == math.huge and 999 or bucket.maxViews,
            bucket.totalOutfits, #bucket.outfits, bucket.weight))
    end
    
    -- Update instance variables
    self.selectionBuckets = newBuckets
    self.totalWeightedOutfits = totalWeighted
    self.lastBucketUpdate = tick()
    
    local rebuildTime = tick() - startTime
    self.stats.lastRebuildTime = rebuildTime
    
    print(string.format("Bucket rebuild complete: %d outfits processed in %.2fs, %d weighted selections available", 
        totalProcessed, rebuildTime, totalWeighted))
    
    return true
end

-- Select an outfit using the pre-built buckets (main selection method)
function CacheBasedBalancedSelector:selectOutfit(player: Player)
    self.stats.selectionsServed = self.stats.selectionsServed + 1
    
    -- Check if we have valid buckets
    if #self.selectionBuckets == 0 or self.totalWeightedOutfits == 0 then
        self.stats.fallbackSelections = self.stats.fallbackSelections + 1
        return self:hashBasedFallback()
    end
    
    self.stats.cacheHits = self.stats.cacheHits + 1
    
    -- Step 1: Select tier using weighted random selection
    local selectedTierIndex = self:selectWeightedTier()
    local selectedBucket = self.selectionBuckets[selectedTierIndex]
    
    if #selectedBucket.outfits == 0 then
        -- This tier is empty, try others
        for i, bucket in ipairs(self.selectionBuckets) do
            if #bucket.outfits > 0 then
                selectedBucket = bucket
                break
            end
        end
        
        if #selectedBucket.outfits == 0 then
            return self:hashBasedFallback()
        end
    end
    
    -- Step 2: Within tier, prefer outfits with fewer views (weighted by inverse view count)
    local selectedOutfit = self:selectFromBucket(selectedBucket, player)

    return selectedOutfit
end

-- Select tier using weighted random selection
function CacheBasedBalancedSelector:selectWeightedTier()
    local totalWeight = 0
    local tierWeights = {}
    
    -- Calculate actual weights based on available outfits
    for i, bucket in ipairs(self.selectionBuckets) do
        local availableOutfits = #bucket.outfits
        if availableOutfits > 0 then
            local effectiveWeight = bucket.weight * availableOutfits
            tierWeights[i] = effectiveWeight
            totalWeight = totalWeight + effectiveWeight
        else
            tierWeights[i] = 0
        end
    end
    
    -- Weighted selection
    local randomValue = math.random() * totalWeight
    local currentWeight = 0
    
    for tierIndex, weight in pairs(tierWeights) do
        currentWeight = currentWeight + weight
        if randomValue <= currentWeight then
            return tierIndex
        end
    end
    
    -- Fallback to first non-empty tier
    for i, bucket in ipairs(self.selectionBuckets) do
        if #bucket.outfits > 0 then
            return i
        end
    end
    
    return 1
end

-- Select outfit from within a bucket (weighted by inverse view count)
function CacheBasedBalancedSelector:selectFromBucket(bucket, player: Player)
    local outfits = bucket.outfits
    
    -- Filter out already-voted outfits and player's own outfit
    local availableOutfits = {}
    for _, outfit in ipairs(outfits) do
        if outfit.userId ~= player.UserId and not PlayerVotedOutfitsTracker.HasPlayerVotedOutfit(player, outfit.userId) then
            warn("Inserting available outfit!")
            table.insert(availableOutfits, outfit)
        end
    end
    
    -- If no outfits (only player's own outfit), return nil
    if #availableOutfits == 0 then
        warn("No available outfits!")
        return nil
    end
    
    if #availableOutfits == 1 then
        return availableOutfits[1]
    end
    
    -- Calculate weights (inverse of view count + 1)
    local weights = {}
    local totalWeight = 0
    local maxViews = 0
    
    -- Find max views for normalization
    for _, outfit in ipairs(availableOutfits) do
        maxViews = math.max(maxViews, outfit.views)
    end
    
    -- Calculate inverse weights
    for i, outfit in ipairs(availableOutfits) do
        -- Higher weight for lower view counts
        local weight = (maxViews + 1) - outfit.views
        weights[i] = weight
        totalWeight = totalWeight + weight
    end
    
    -- Weighted random selection
    local randomValue = math.random() * totalWeight
    local currentWeight = 0
    
    for i, weight in ipairs(weights) do
        currentWeight = currentWeight + weight
        if randomValue <= currentWeight then
            return availableOutfits[i]
        end
    end
    
    -- Fallback to random selection
    local randomIndex = math.random(1, #availableOutfits)
    return availableOutfits[randomIndex]
end

-- Hash-based fallback for when buckets aren't available
function CacheBasedBalancedSelector:hashBasedFallback()
    -- Use a simple hash-based selection that doesn't require full enumeration
    local currentTime = tick()
    local hashInput = tostring(currentTime) .. tostring(math.random(1000000))
    
    -- Create a deterministic but random hash
    local hash = 0
    for i = 1, #hashInput do
        local char = string.byte(hashInput, i)
        hash = (hash * 31 + char) % 1000000
    end
    
    local bucketNumber = hash % CONFIG.HASH_BUCKETS
    
    return nil -- Return nil to indicate fallback selection needed
end

-- Integration helper: call this method in VotingStoreManager.updatePublicCache()
function CacheBasedBalancedSelector:onCacheUpdated(publicCache)
    return self:rebuildFromCache(publicCache)
end

-- Get detailed statistics about the selection system
function CacheBasedBalancedSelector:getDetailedStats()
    local tierStats = {}
    for i, bucket in ipairs(self.selectionBuckets) do
        tierStats[i] = {
            viewRange = bucket.minViews .. "-" .. (bucket.maxViews == math.huge and "∞" or bucket.maxViews),
            availableOutfits = #bucket.outfits,
            totalOutfits = bucket.totalOutfits,
            weight = bucket.weight,
            selectionProbability = (#bucket.outfits * bucket.weight) / math.max(self.totalWeightedOutfits, 1)
        }
    end
    
    return {
        -- Performance stats
        selectionsServed = self.stats.selectionsServed,
        cacheHitRate = self.stats.cacheHits / math.max(self.stats.selectionsServed, 1),
        fallbackRate = self.stats.fallbackSelections / math.max(self.stats.selectionsServed, 1),
        lastRebuildTime = self.stats.lastRebuildTime,
        
        -- System stats
        totalWeightedOutfits = self.totalWeightedOutfits,
        bucketsAge = tick() - self.lastBucketUpdate,
        tierStats = tierStats
    }
end

-- Simple stats for monitoring
function CacheBasedBalancedSelector:getStats()
    return {
        selectionsServed = self.stats.selectionsServed,
        cacheHitRate = math.floor((self.stats.cacheHits / math.max(self.stats.selectionsServed, 1)) * 100),
        totalWeightedOutfits = self.totalWeightedOutfits,
        bucketsAge = math.floor(tick() - self.lastBucketUpdate)
    }
end

function CacheBasedBalancedSelector:resetCache()
    print("Resetting selection cache...")
    
    -- Clear all buckets
    self.selectionBuckets = {}
    self.totalWeightedOutfits = 0
    self.lastBucketUpdate = 0
    
    -- Reset stats
    self.stats = {
        selectionsServed = 0,
        cacheHits = 0,
        fallbackSelections = 0,
        lastRebuildTime = 0
    }
    
    print("Selection cache reset complete")
end

return CacheBasedBalancedSelector