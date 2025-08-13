--!strict

--[[
	getCreatorNameAsync - A utility function to get the name of the place's creator.
	Note: This function requires the place to be published.
--]]

local Players = game:GetService("Players")
local GroupService = game:GetService("GroupService")

local function getCreatorNameAsync(): string?
	if game.CreatorId == 0 then
		warn("Place must be published to get creator's name!")
		return nil
	end

	if game.CreatorType == Enum.CreatorType.User then
		local success, result = pcall(Players.GetNameFromUserIdAsync, Players, game.CreatorId)
		if success then
			return result
		else
			warn(`Failed to get user name: {result}`)
		end
	elseif game.CreatorType == Enum.CreatorType.Group then
		local success, result = pcall(GroupService.GetGroupInfoAsync, GroupService, game.CreatorId)
		if success then
			return result.Name
		else
			warn(`Failed to get group info: {result}`)
		end
	end

	return nil
end

return getCreatorNameAsync
