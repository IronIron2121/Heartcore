--!strict

-- Constants
local DEFAULT_RETRIES = 3

local function callWithRetry(
    functionToTry: () -> any, 
    maxRetries: number?
): (boolean, any)
    local success = false
    local result = nil
    local tries = 0

    while not success and tries < (maxRetries or DEFAULT_RETRIES) do
        tries = tries + 1
        success, result = pcall(functionToTry)

        if not success then
            task.wait(tries * 2)
            tries += 1
        end
    end

    return success, result
end

return callWithRetry