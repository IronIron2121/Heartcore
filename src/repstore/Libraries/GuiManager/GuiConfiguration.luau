--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utility = ReplicatedStorage:WaitForChild("Utility")

local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local Fusion = require(Utility:WaitForChild("Fusion"))

local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

type SlotInfo = {
	Object: GuiObject,
	AlwaysOn: boolean?,
	enabled: UsedAs<boolean>?,
}

type SlotDefinition = {
	propName: string,
	slotName: string,
	positionName: string,
	enabledName: string,
	info: SlotInfo?,
	anchorPoint: Vector2,
	inPosition: UDim2,
	outPosition: UDim2,
	size: UDim2,
}

local SLOT_PADDING = UDim.new(0.02, 0)
local SLOT_CONSTANTS = {
	Colour = Color3.new(1, 1, 1),
	BackgroundTransparency = 1,
	Visible = true,
}

local SLOT_LAYOUTS = {
	[Constants.GUI_SLOT_NAMES.TopMiddle] = {
		Name = Constants.GUI_SLOT_NAMES.TopMiddle,
		AnchorPoint = Vector2.new(0.5, 0),
		InPosition = UDim2.fromScale(0.5, 0),
		OutPosition = UDim2.fromScale(0.5, -1),
		Size = UDim2.fromScale(0.5, 0.2),
	},

	[Constants.GUI_SLOT_NAMES.TopRight] = {
		Name = Constants.GUI_SLOT_NAMES.TopRight,
		AnchorPoint = Vector2.new(1, 0),
		InPosition = UDim2.fromScale(1, 0),
		OutPosition = UDim2.fromScale(2, 0),
		Size = UDim2.fromScale(0.3, 0.4),
	},

	[Constants.GUI_SLOT_NAMES.MiddleRight] = {
		Name = Constants.GUI_SLOT_NAMES.MiddleRight,
		AnchorPoint = Vector2.new(1, 0.5),
		InPosition = UDim2.fromScale(1, 0.5),
		OutPosition = UDim2.fromScale(2, 0),
		Size = UDim2.fromScale(0.2, 0.8),
	},

	[Constants.GUI_SLOT_NAMES.MiddleLeft] = {
		Name = Constants.GUI_SLOT_NAMES.MiddleLeft,
		AnchorPoint = Vector2.new(0, 0.5),
		InPosition = UDim2.fromScale(0, 0.5),
		OutPosition = UDim2.fromScale(-0.15, 0.5),
		Size = UDim2.fromScale(0.1, 0.8),
	},

	[Constants.GUI_SLOT_NAMES.BottomLeft] = {
		Name = Constants.GUI_SLOT_NAMES.BottomLeft,
		AnchorPoint = Vector2.new(0, 1),
		InPosition = UDim2.fromScale(0, 1),
		OutPosition = UDim2.fromScale(-1, 2),
		Size = UDim2.fromScale(0.3, 0.2),
	},

	[Constants.GUI_SLOT_NAMES.BottomMiddle] = {
		Name = Constants.GUI_SLOT_NAMES.BottomMiddle,
		AnchorPoint = Vector2.new(0.5, 1),
		InPosition = UDim2.fromScale(0.5, 1),
		OutPosition = UDim2.fromScale(0.5, 2),
		Size = UDim2.fromScale(1, 0.2),
	},

	[Constants.GUI_SLOT_NAMES.BottomRight] = {
		Name = Constants.GUI_SLOT_NAMES.BottomRight,
		AnchorPoint = Vector2.new(1, 1),
		InPosition = UDim2.fromScale(1, 1),
		OutPosition = UDim2.fromScale(2, 1),
		Size = UDim2.fromScale(0.3, 0.2),
	},
}

local GuiConfiguration = {}
GuiConfiguration.__index = GuiConfiguration

local function makeSlot(self: any, definition: SlotDefinition, color: Color3?): Frame
	local alwaysOn = definition.info and definition.info.AlwaysOn == true
	local slotEnabled = (definition.info and definition.info.enabled) or self.scope:Value(true)
	local slotLayout = SLOT_LAYOUTS[definition.slotName]

	self[definition.enabledName] = slotEnabled
	self._slotEnabledValues[definition.slotName] = slotEnabled
	self._elements[definition.propName] = definition.info and definition.info.Object or nil

	local position = self.scope:Computed(function(use)
		local visible = use(self.Enabled)
			and not use(self.ForceHidden)
			and use(slotEnabled)
			and (alwaysOn or use(self.ModalVisible))

		return if visible then definition.inPosition else definition.outPosition
	end)

	local slot = self.scope:New "Frame" {
		Name = slotLayout.Name,
		AnchorPoint = definition.anchorPoint,
		BackgroundColor3 = color or SLOT_CONSTANTS.Colour,
		BackgroundTransparency = SLOT_CONSTANTS.BackgroundTransparency,
		Parent = self.ConfigurationContainer,
		Position = self.scope:Tween(position, Constants.DEFAULT_TWEEN),
		Size = definition.size,
		Visible = SLOT_CONSTANTS.Visible,

		[Children] = {
			self.scope:New "UIPadding" {
				PaddingBottom = SLOT_PADDING,
				PaddingLeft = SLOT_PADDING,
				PaddingRight = SLOT_PADDING,
				PaddingTop = SLOT_PADDING,
			},
		},
	} :: Frame

	self[definition.positionName] = position
	self[definition.slotName] = slot
	self.GuiSlotPositions[definition.slotName] = position

	if alwaysOn and self._elements[definition.propName] then
		self._elements[definition.propName].Parent = slot
	end

	return slot
end

function GuiConfiguration.new(props: {
	ConfigurationName: string,
	color: Color3?,
	topMiddle: SlotInfo?,
	topRight: SlotInfo?,
	middleRight: SlotInfo?,
	middleLeft: SlotInfo?,
	bottomLeft: SlotInfo?,
	bottomMiddle: SlotInfo?,
	bottomRight: SlotInfo?,
})
	local self: any = setmetatable({}, GuiConfiguration)

	self.Name = props.ConfigurationName
	self.scope = Fusion:scoped()
	self.Enabled = self.scope:Value(false)
	self.ModalVisible = self.scope:Value(true)
	self.ForceHidden = self.scope:Value(false)
	self.GuiSlotPositions = {}
	self._elements = {}
	self._slotEnabledValues = {}

	self.ConfigurationContainer = self.scope:New "Frame" {
		Name = props.ConfigurationName,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		Visible = true,
	} :: Frame

	local definitions: {SlotDefinition} = {
		{
			propName = "topMiddle",
			slotName = Constants.GUI_SLOT_NAMES.TopMiddle,
			positionName = "TopMiddlePosition",
			enabledName = "topMiddleEnabled",
			info = props.topMiddle,
			anchorPoint = SLOT_LAYOUTS.TopMiddle.AnchorPoint,
			inPosition = SLOT_LAYOUTS.TopMiddle.InPosition,
			outPosition = SLOT_LAYOUTS.TopMiddle.OutPosition,
			size = SLOT_LAYOUTS.TopMiddle.Size,
		},
		{
			propName = "topRight",
			slotName = Constants.GUI_SLOT_NAMES.TopRight,
			positionName = "TopRightPosition",
			enabledName = "topRightEnabled",
			info = props.topRight,
			anchorPoint = SLOT_LAYOUTS.TopRight.AnchorPoint,
			inPosition = SLOT_LAYOUTS.TopRight.InPosition,
			outPosition = SLOT_LAYOUTS.TopRight.OutPosition,
			size = SLOT_LAYOUTS.TopRight.Size,
		},
		{
			propName = "middleRight",
			slotName = Constants.GUI_SLOT_NAMES.MiddleRight,
			positionName = "MiddleRightPosition",
			enabledName = "middleRightEnabled",
			info = props.middleRight,
			anchorPoint = SLOT_LAYOUTS.MiddleRight.AnchorPoint,
			inPosition = SLOT_LAYOUTS.MiddleRight.InPosition,
			outPosition = SLOT_LAYOUTS.MiddleRight.OutPosition,
			size = SLOT_LAYOUTS.MiddleRight.Size,
		},
		{
			propName = "middleLeft",
			slotName = Constants.GUI_SLOT_NAMES.MiddleLeft,
			positionName = "MiddleLeftPosition",
			enabledName = "middleLeftEnabled",
			info = props.middleLeft,
			anchorPoint = SLOT_LAYOUTS.MiddleLeft.AnchorPoint,
			inPosition = SLOT_LAYOUTS.MiddleLeft.InPosition,
			outPosition = SLOT_LAYOUTS.MiddleLeft.OutPosition,
			size = SLOT_LAYOUTS.MiddleLeft.Size,
		},
		{
			propName = "bottomLeft",
			slotName = Constants.GUI_SLOT_NAMES.BottomLeft,
			positionName = "BottomLeftPosition",
			enabledName = "bottomLeftEnabled",
			info = props.bottomLeft,
			anchorPoint = SLOT_LAYOUTS.BottomLeft.AnchorPoint,
			inPosition = SLOT_LAYOUTS.BottomLeft.InPosition,
			outPosition = SLOT_LAYOUTS.BottomLeft.OutPosition,
			size = SLOT_LAYOUTS.BottomLeft.Size,
		},
		{
			propName = "bottomMiddle",
			slotName = Constants.GUI_SLOT_NAMES.BottomMiddle,
			positionName = "BottomMiddlePosition",
			enabledName = "bottomMiddleEnabled",
			info = props.bottomMiddle,
			anchorPoint = SLOT_LAYOUTS.BottomMiddle.AnchorPoint,
			inPosition = SLOT_LAYOUTS.BottomMiddle.InPosition,
			outPosition = SLOT_LAYOUTS.BottomMiddle.OutPosition,
			size = SLOT_LAYOUTS.BottomMiddle.Size,
		},
		{
			propName = "bottomRight",
			slotName = Constants.GUI_SLOT_NAMES.BottomRight,
			positionName = "BottomRightPosition",
			enabledName = "bottomRightEnabled",
			info = props.bottomRight,
			anchorPoint = SLOT_LAYOUTS.BottomRight.AnchorPoint,
			inPosition = SLOT_LAYOUTS.BottomRight.InPosition,
			outPosition = SLOT_LAYOUTS.BottomRight.OutPosition,
			size = SLOT_LAYOUTS.BottomRight.Size,
		},
	}

	for _, definition in definitions do
		makeSlot(self, definition, props.color)
	end

	return self
end

function GuiConfiguration:SetSlotEnabled(slotName: string, enabled: boolean)
	local slotEnabled = self._slotEnabledValues[slotName]
	if typeof(slotEnabled) == "table" and slotEnabled.set then
		slotEnabled:set(enabled)
	end
end

function GuiConfiguration:Disable()
	self.Enabled:set(false)
end

function GuiConfiguration:Enable(startHidden: boolean?)
	task.spawn(function()
		if self._elements.topMiddle then self._elements.topMiddle.Parent = self.TopMiddle end
		if self._elements.topRight then self._elements.topRight.Parent = self.TopRight end
		if self._elements.middleRight then self._elements.middleRight.Parent = self.MiddleRight end
		if self._elements.middleLeft then self._elements.middleLeft.Parent = self.MiddleLeft end
		if self._elements.bottomLeft then self._elements.bottomLeft.Parent = self.BottomLeft end
		if self._elements.bottomMiddle then self._elements.bottomMiddle.Parent = self.BottomMiddle end
		if self._elements.bottomRight then self._elements.bottomRight.Parent = self.BottomRight end

		self.ForceHidden:set(false)
		self.ModalVisible:set(not startHidden)
		self.Enabled:set(true)
	end)
end

function GuiConfiguration:HideForModal()
	self.ModalVisible:set(false)
end

function GuiConfiguration:ShowFromModal()
	self.ModalVisible:set(true)
end

function GuiConfiguration:HideAll()
	self.ForceHidden:set(true)
end

function GuiConfiguration:ShowAll()
	self.ForceHidden:set(false)
end

return GuiConfiguration
