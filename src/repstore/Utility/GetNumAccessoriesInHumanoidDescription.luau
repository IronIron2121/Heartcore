--!strict


local function getNumAccessoriesInHumanoidDescription(humanoidDescription: HumanoidDescription)
    local num = 0

    for _, child in pairs(humanoidDescription:GetChildren()) do
        if child:IsA("AccessoryDescription") then
            num += 1
        end
    end

    return num
end

return getNumAccessoriesInHumanoidDescription