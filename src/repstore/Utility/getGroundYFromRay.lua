local raycastParams = RaycastParams.new()
raycastParams.FilterDescendantsInstances = {} -- Optionally add parts to ignore
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true

function getGroundYFromRay(originPosition: Vector3)
	local rayOrigin = originPosition + Vector3.new(0, 10, 0) -- Slightly above
	local rayDirection = Vector3.new(0, -50, 0) -- Cast downward

	local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if raycastResult then
		return raycastResult.Position.Y
	else
		-- Fallback: default to a safe ground level
		return 1
	end
end

return getGroundYFromRay
