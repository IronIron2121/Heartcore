--!strict

--[[
	arrayOfNumbersToString - A utility function to convert an array of numbers
	"0000,1111,2222" -> { 0, 1111, 2222 } into a string of the form "xxx,yyy,zzz,..." 

	Whitespace is ignored so strings can also be formatted as "0, 1, 2, 3"
--]]

local DELIMITER = ","

local function arrayOfNumbersToString(array: { number })
	return table.concat(array, DELIMITER)
end

return arrayOfNumbersToString
