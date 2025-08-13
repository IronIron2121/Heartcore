--!strict

--[[
	safeClamp - A utility function to perform clamping which ensures that max is not less than min.
	This is used in place of math.clamp, which throws an error when max is less than min.
--]]

local function safeClamp(num: number, min: number, max: number): number
	return math.clamp(num, min, math.max(min, max))
end

return safeClamp
