--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))
local LoadingScreen = require(ReplicatedStorage.UI.FusionComponents.Widgets.LoadingScreen)

-- Fusion
type Value<T> = Fusion.Value<T>

--

local scope = Fusion:scoped()

type CacheEntry = {
	frame: Frame,
	visible: Value<boolean>,
}

local cache: { [GuiObject]: CacheEntry } = {}

local LoadingScreenManager = {}

function LoadingScreenManager.show(parent: GuiObject)
	local entry = cache[parent]
	if not entry then
		local visible = scope:Value(true)
		local frame = LoadingScreen(scope, {
			size = UDim2.fromScale(1, 1),
			backgroundColor = UI_CONSTANTS.COLOUR_WHITE,
			visible = visible,
			zIndex = 100,
			backgroundTransparency = 0.2,
			parent = parent,
		})
		cache[parent] = { frame = frame, visible = visible }
	else
		entry.visible:set(true)
	end
end

function LoadingScreenManager.hide(parent: GuiObject)
	local entry = cache[parent]
	if entry then
		entry.visible:set(false)
	end
end

return LoadingScreenManager