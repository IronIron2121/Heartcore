--!strict

--[[
	ModalManager - A simple library to handle displaying a single modal window at once.
--]]

local modalChangedBindable = Instance.new("BindableEvent")

-- Modals is a list of GuiObjects
local modals: { GuiObject } = {}


local ModalManager = {
	modalChanged = modalChangedBindable.Event,
}

-- Updating visibility only makes the last-added modal visible, I assume?
local function updateVisibility()
	for index, modal in modals do
		modal.Visible = index == #modals
	end
end

--[[
When a modal is pushed, it is (if in the modals list) removed from the modals list and then added again at the end.
Then we fire modalChangedBindable on it,
And update visibility
]]
function ModalManager.push(modal: GuiObject)

	local index = table.find(modals, modal)
	
	if index then
		table.remove(modals, index)
	end

	table.insert(modals, modal)
	modalChangedBindable:Fire(modals[#modals])

	updateVisibility()
end

function ModalManager.pop(modal: GuiObject)

	local index = table.find(modals, modal)
	if index then
		table.remove(modals, index)
	end

	modalChangedBindable:Fire(modals[#modals])

	modal.Visible = false
	updateVisibility()
end

function ModalManager.getModal(): GuiObject?
	return modals[#modals]
end

return ModalManager