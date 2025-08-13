function isPointInRegion(region : Region3, point : Vector3)
	local minX, maxX = region.CFrame.X - region.Size.X/2, region.CFrame.X + region.Size.X/2
	local minY, maxY = region.CFrame.Y - region.Size.Y/2, region.CFrame.Y + region.Size.Y/2
	local minZ, maxZ = region.CFrame.Z - region.Size.Z/2, region.CFrame.Z + region.Size.Z/2
	
	return point.X >= minX and point.X <= maxX and
		point.Y >= minY and point.Y <= maxY and
		point.Z >= minZ and point.Z <= maxZ
end

return isPointInRegion
