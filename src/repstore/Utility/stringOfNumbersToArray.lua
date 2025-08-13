--!strict

--[[
	stringOfNumbersToArray - A utility function to convert a string of the form "xxx,yyy,zzz,..." into an array of numbers
	"0000,1111,2222" -> { 0, 1111, 2222 }

	Whitespace is ignored so strings can also be formatted as "0, 1, 2, 3"
--]]

local DELIMITER = ","

-- Takes a string as input and returns an array of numbers as output
local function stringOfNumbersToArray(str: string): { number }
	-- Remove any whitespace from the string
	str = string.gsub(str, "%s", "")
	
	-- Split string by commas
	local numberStrings = string.split(str, DELIMITER)
	local numbers = {}

	for _, numberString in numberStrings do
		local num = tonumber(numberString)
		if not num then
			continue
		end

		table.insert(numbers, num)
	end

	return numbers
end


return stringOfNumbersToArray
