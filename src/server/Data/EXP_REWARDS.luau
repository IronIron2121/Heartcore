local ExpRewards = {
    OUTFIT_SUBMIT = 1,
    OUTFIT_VOTE = 0.1,
    FIRST_PLACE = 10,
    SECOND_PLACE = 5,
    THIRD_PLACE = 3,
}

local placeMapping = {
    [1] = "FIRST_PLACE",
    [2] = "SECOND_PLACE",
    [3] = "THIRD_PLACE",
}

setmetatable(ExpRewards, {
    __index = function(self, key)
        if type(key) == "number" and placeMapping[key] then
            return rawget(self, placeMapping[key])
        end
        return nil
    end
})

return ExpRewards