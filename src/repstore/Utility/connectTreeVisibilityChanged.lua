--!strict

--[[
	getTreeVisibilityChangedEvent - A utility function used to check when any of a GuiObject's parents
	change visibility, allowing us to check if a descendant has been rendered invisible by one of its parents.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local disconnectAndClear = require(ReplicatedStorage.Utility.disconnectAndClear)

type Callback = (boolean) -> ()
type DisconnectCallback = () -> ()

local function connectTreeVisibilityChanged(guiObject: GuiObject, callback: Callback): DisconnectCallback
	local tree: { GuiObject } = {}
	local connections = {}
	local isVisible = false

	local function checkVisibility(): boolean
		for _, object in tree do
			if not object.Visible then
				return false
			end
		end
		return true
	end

	local function onVisibilityChanged()
		local nowIsVisible = checkVisibility()
		if isVisible ~= nowIsVisible then
			isVisible = nowIsVisible
			callback(isVisible)
		end
	end

	local function fillTree(object: Instance?)
		if not object then
			return
		end

		if not object:IsA("GuiObject") then
			return
		end

		table.insert(tree, object)
		table.insert(connections, object:GetPropertyChangedSignal("Visible"):Connect(onVisibilityChanged))

		fillTree(object.Parent)
	end

	local function disconnect()
		disconnectAndClear(connections)
	end

	fillTree(guiObject)
	isVisible = checkVisibility()

	return disconnect
end

return connectTreeVisibilityChanged
