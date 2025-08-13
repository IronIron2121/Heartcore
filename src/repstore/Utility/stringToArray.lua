--!strict

--[[
	stringOfNumbersToArray - A utility function to convert a string of the form "xxx,yyy,zzz,..." into an array of numbers
	"0000,1111,2222" -> { 0, 1111, 2222 }

	Whitespace is ignored so strings can also be formatted as "0, 1, 2, 3"
--]]

local DELIMITER = ","

-- Takes a string as input and returns an array of numbers as output
local function stringToArray(str: string): { string }
	-- Remove any whitespace from the string
	str = string.gsub(str, "%s", "")
	
	-- Split string by commas
	local stringComponents = string.split(str, DELIMITER)
	local strings = {}

	for _, thisString in stringComponents do
		table.insert(strings, thisString)
	end

	return strings
end

return stringToArray