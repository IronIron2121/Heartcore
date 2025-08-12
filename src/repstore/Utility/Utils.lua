local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Utils = {}

--- returns any number of thing
function Utils.callWithRetry(
	func: () -> any,
	max_tries: number
)
	
	local success = false
	local result = nil
	local tries = 1

	while not success and tries < max_tries do
		success, result = pcall(func)

		if not success then
			task.wait(tries * 2)
			tries += 1
		end
	end
	print(result, success)
	return result, success
end



return Utils
