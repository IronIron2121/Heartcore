--!strict

--[[
-- Folders
local labelStores           = workspace:WaitForChild("LabelStores")
local capitol               = labelStores:WaitForChild("capitol")
local groundTp              = capitol:WaitForChild("groundTp")
local storeTp               = capitol:WaitForChild("storeTp")
local storeDestination      = capitol:WaitForChild("storeDestination")
local groundDestination     = capitol:WaitForChild("groundDestination")


-- TP up code
groundTp.Touched:Connect(function(hit)
	local character = hit.Parent
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	
	if humanoidRootPart and character:FindFirstChild("Humanoid") then
		humanoidRootPart.CFrame = storeDestination.CFrame + Vector3.new(0,15,0)
	end
end)

-- TP down code
storeTp.Touched:Connect(function(hit)
    print("storeTp touched by:", hit.Name) 
    local character = hit.Parent
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

    if humanoidRootPart and character:FindFirstChild("Humanoid") then
        print("Teleporting to:", groundDestination.CFrame)
        humanoidRootPart.CFrame = groundDestination.CFrame + Vector3.new(0, 15, 0)
    end
end)
]]