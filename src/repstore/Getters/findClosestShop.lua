--[[ 
	Finds the closest shop to the player in the workspace
]]

-- Folders
local PlayerShops = workspace:WaitForChild("PlayerShops")


function findClosestShop(player: Player): Part?
	local character = player.Character or player.CharacterAdded:Wait()
	local characterPosition = character.HumanoidRootPart.Position
	local closestShop = nil
	local closestShopDistance = math.huge
	
	for _, child in ipairs(PlayerShops:GetChildren()) do
		if child:IsA("Model") then
			local shopFloor = child:WaitForChild("shopFloor") :: Part
			local shopPosition = shopFloor.Position
			local distance = (shopPosition - characterPosition).Magnitude
			if distance < closestShopDistance then
				closestShop = child
				closestShopDistance = distance
			end
		end
	end
	
	return closestShop
end


return findClosestShop
