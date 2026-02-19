--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local Constants = require(ReplicatedStorage.Constants)

-- Fusion
local Fusion        = require(Utility.Fusion)
type UsedAs<T>      = Fusion.UsedAs<T>
type Value<T>       = Fusion.Value<T>
type Computed<T>    = Fusion.Computed<T>
type scope          = Fusion.Scope

--

type SlotInfo = {
    Object: Frame,
    AlwaysOn: boolean,
}

local SLOT_CONSTANTS = {
    Colour = Color3.new(1, 1, 1),
    BackgroundTransparency = 1,
    Visible = true
} 

local SLOT_LAYOUTS = {
    [Constants.GUI_SLOT_NAMES.TopMiddle] = {
        Name =  Constants.GUI_SLOT_NAMES.TopMiddle,
        AnchorPoint = Vector2.new(0.5, 0),
        InPosition = UDim2.fromScale(0.5, 0),
        OutPosition = UDim2.fromScale(0.5, -1),
        Size = UDim2.fromScale(0.5, 0.2)
    },

    [Constants.GUI_SLOT_NAMES.TopRight] = {
        Name =  Constants.GUI_SLOT_NAMES.TopRight,
        AnchorPoint = Vector2.new(1, 0),
        InPosition = UDim2.fromScale(1, 0),
        OutPosition = UDim2.fromScale(2, 0),
        Size = UDim2.fromScale(0.3, 0.4)
    },

    [Constants.GUI_SLOT_NAMES.BottomLeft] = {
        Name =  Constants.GUI_SLOT_NAMES.BottomLeft,
        AnchorPoint = Vector2.new(0, 1),
        InPosition = UDim2.fromScale(0, 1),
        OutPosition = UDim2.fromScale(-1, 2),
        Size = UDim2.fromScale(0.3, 0.2)
    },

    [Constants.GUI_SLOT_NAMES.BottomMiddle] = {
        Name =  Constants.GUI_SLOT_NAMES.BottomMiddle,
        AnchorPoint = Vector2.new(0.5, 1),
        InPosition = UDim2.fromScale(0.5, 1),
        OutPosition = UDim2.fromScale(0.5, 2),
        Size = UDim2.fromScale(0.3, 0.2)
    },

    [Constants.GUI_SLOT_NAMES.BottomRight] = {
        Name =  Constants.GUI_SLOT_NAMES.BottomRight,
        AnchorPoint = Vector2.new(1, 1),
        InPosition = UDim2.fromScale(1, 1),
        OutPosition = UDim2.fromScale(2, 1),
        Size = UDim2.fromScale(0.3, 0.2)
    }
}

export type GuiConfiguration = {
    -- Properties
    Name: string,
    ConfigurationContainer: Frame,
    TopMiddle: Frame,
    TopMiddlePosition: Value<UDim2>,
    TopRight: Frame,
    TopRightPosition: Value<UDim2>,
    BottomLeft: Frame,
    BottomLeftPosition: Value<UDim2>,
    BottomMiddle: Frame,
    BottomMiddlePosition: Value<UDim2>,
    BottomRight: Frame,
    BottomRightPosition: Value<UDim2>,
    Enabled: Value<boolean>,
    GuiSlotPositions: {[string]: Value<UDim2>},
    scope: Fusion.Scope,
    _elements: {
        topMiddle: GuiObject?,
        topRight: GuiObject?,
        bottomLeft: GuiObject?,
        bottomMiddle: GuiObject?,
        bottomRight: GuiObject?,
    },

    -- Methods
    Disable: (self: GuiConfiguration) -> (),
    Enable: (self: GuiConfiguration) -> (),
    HideForModal: (self: GuiConfiguration) -> (),
    ShowFromModal: (self: GuiConfiguration) -> (),
}

local GuiConfiguration = {}
GuiConfiguration.__index = GuiConfiguration

function GuiConfiguration.new(props: {
    ConfigurationName: string,
    color: Color3?,
    topMiddle: SlotInfo?,
    topRight: SlotInfo?,
    bottomLeft: SlotInfo?,
    bottomMiddle: SlotInfo?,
    bottomRight: SlotInfo?,
}): GuiConfiguration
    -- Initialise an object of this class (Luau OOP)
    local self = {}
    setmetatable(self, GuiConfiguration) 
    self.Name = props.ConfigurationName

    -- Establish a scope for this configuration
    self.scope = Fusion:scoped()

    self.Enabled = self.scope:Value(false)
    self.ModalVisible = self.scope:Value(true)

    -- Extract AlwaysOn flags
    local topMiddleAlwaysOn = props.topMiddle and props.topMiddle.AlwaysOn or false
    local topRightAlwaysOn = props.topRight and props.topRight.AlwaysOn or false
    local bottomLeftAlwaysOn = props.bottomLeft and props.bottomLeft.AlwaysOn or false
    local bottomMiddleAlwaysOn = props.bottomMiddle and props.bottomMiddle.AlwaysOn or false
    local bottomRightAlwaysOn = props.bottomRight and props.bottomRight.AlwaysOn or false

    -- Store element references for reparenting on Enable()
    self._elements = {
        topMiddle = props.topMiddle and props.topMiddle.Object or nil,
        topRight = props.topRight and props.topRight.Object or nil,
        bottomLeft = props.bottomLeft and props.bottomLeft.Object or nil,
        bottomMiddle = props.bottomMiddle and props.bottomMiddle.Object or nil,
        bottomRight = props.bottomRight and props.bottomRight.Object or nil,
    }

    -- Empty list that will contain the screen positions for each slot
    self.GuiSlotPositions = {}

    self.ConfigurationContainer = self.scope:New "Frame" {
        Name = props.ConfigurationName,
        Size = UDim2.fromScale(1, 1),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 1,
        Visible = true
    } :: Frame
    
    self.TopMiddlePosition = self.scope:Computed(function(use)
        local visible = if topMiddleAlwaysOn then use(self.Enabled) else (use(self.Enabled) and use(self.ModalVisible))
        return visible and SLOT_LAYOUTS[Constants.GUI_SLOT_NAMES.TopMiddle].InPosition or SLOT_LAYOUTS[Constants.GUI_SLOT_NAMES.TopMiddle].OutPosition
    end)
    self.TopMiddle = self.scope:New "Frame" {
        Name        = SLOT_LAYOUTS.TopMiddle.Name,
        AnchorPoint = SLOT_LAYOUTS.TopMiddle.AnchorPoint,
        Position    = self.scope:Tween(self.TopMiddlePosition, Constants.DEFAULT_TWEEN),
        Size        = SLOT_LAYOUTS.TopMiddle.Size,
        BackgroundColor3      = props.color or SLOT_CONSTANTS.Colour,
        Visible     = SLOT_CONSTANTS.Visible,
        Parent      = self.ConfigurationContainer,
        BackgroundTransparency = SLOT_CONSTANTS.BackgroundTransparency,
    } :: Frame
    self.GuiSlotPositions[Constants.GUI_SLOT_NAMES.TopMiddle] = self.TopMiddlePosition

    self.TopRightPosition = self.scope:Computed(function(use)
        local visible = if topRightAlwaysOn then use(self.Enabled) else (use(self.Enabled) and use(self.ModalVisible))
        return visible and SLOT_LAYOUTS[Constants.GUI_SLOT_NAMES.TopRight].InPosition or SLOT_LAYOUTS[Constants.GUI_SLOT_NAMES.TopRight].OutPosition
    end)
    self.TopRight = self.scope:New "Frame" {
        Name        = SLOT_LAYOUTS[Constants.GUI_SLOT_NAMES.TopRight].Name,
        AnchorPoint = SLOT_LAYOUTS[Constants.GUI_SLOT_NAMES.TopRight].AnchorPoint,
        Position    = self.scope:Tween(self.TopRightPosition, Constants.DEFAULT_TWEEN),
        Size        = SLOT_LAYOUTS[Constants.GUI_SLOT_NAMES.TopRight].Size,
        BackgroundColor3      = props.color or SLOT_CONSTANTS.Colour,
        Visible     = SLOT_CONSTANTS.Visible,
        Parent      = self.ConfigurationContainer,
        BackgroundTransparency = SLOT_CONSTANTS.BackgroundTransparency,
    } :: Frame
    self.GuiSlotPositions[Constants.GUI_SLOT_NAMES.TopRight] = self.TopRightPosition

    self.BottomLeftPosition = self.scope:Computed(function(use)
        local visible = if bottomLeftAlwaysOn then use(self.Enabled) else (use(self.Enabled) and use(self.ModalVisible))
        return visible and SLOT_LAYOUTS[Constants.GUI_SLOT_NAMES.BottomLeft].InPosition or SLOT_LAYOUTS[Constants.GUI_SLOT_NAMES.BottomLeft].OutPosition
    end)    
    self.BottomLeft = self.scope:New "Frame" {
        Name        = SLOT_LAYOUTS.BottomLeft.Name,
        AnchorPoint = SLOT_LAYOUTS.BottomLeft.AnchorPoint,
        Position    = self.scope:Tween(self.BottomLeftPosition, Constants.DEFAULT_TWEEN),
        Size        = SLOT_LAYOUTS.BottomLeft.Size,
        BackgroundColor3      = props.color or SLOT_CONSTANTS.Colour,
        Visible     = SLOT_CONSTANTS.Visible,
        Parent      = self.ConfigurationContainer,
        BackgroundTransparency = SLOT_CONSTANTS.BackgroundTransparency,
    } :: Frame
    self.GuiSlotPositions[Constants.GUI_SLOT_NAMES.BottomLeft] = self.BottomLeftPosition

    self.BottomMiddlePosition = self.scope:Computed(function(use)
        local visible = if bottomMiddleAlwaysOn then use(self.Enabled) else (use(self.Enabled) and use(self.ModalVisible))
        return visible and SLOT_LAYOUTS[Constants.GUI_SLOT_NAMES.BottomMiddle].InPosition or SLOT_LAYOUTS[Constants.GUI_SLOT_NAMES.BottomMiddle].OutPosition
    end)      
    self.BottomMiddle = self.scope:New "Frame" {
        Name        = SLOT_LAYOUTS.BottomMiddle.Name,
        AnchorPoint = SLOT_LAYOUTS.BottomMiddle.AnchorPoint,
        Position    = self.scope:Tween(self.BottomMiddlePosition, Constants.DEFAULT_TWEEN),
        Size        = SLOT_LAYOUTS.BottomMiddle.Size,
        BackgroundColor3 = props.color or SLOT_CONSTANTS.Colour,
        Visible     = SLOT_CONSTANTS.Visible,
        Parent      = self.ConfigurationContainer,
        BackgroundTransparency = SLOT_CONSTANTS.BackgroundTransparency,
    } :: Frame
    self.GuiSlotPositions[Constants.GUI_SLOT_NAMES.BottomMiddle] = self.BottomMiddlePosition

    self.BottomRightPosition = self.scope:Computed(function(use)
        local visible = if bottomRightAlwaysOn then use(self.Enabled) else (use(self.Enabled) and use(self.ModalVisible))
        return visible and SLOT_LAYOUTS[Constants.GUI_SLOT_NAMES.BottomRight].InPosition or SLOT_LAYOUTS[Constants.GUI_SLOT_NAMES.BottomRight].OutPosition
    end)      
    self.BottomRight = self.scope:New "Frame" {
        Name        = SLOT_LAYOUTS.BottomRight.Name,
        AnchorPoint = SLOT_LAYOUTS.BottomRight.AnchorPoint,
        Position    = self.scope:Tween(self.BottomRightPosition, Constants.DEFAULT_TWEEN),
        Size        = SLOT_LAYOUTS.BottomRight.Size,
        BackgroundColor3      = props.color or SLOT_CONSTANTS.Colour,
        Visible     = SLOT_CONSTANTS.Visible,
        Parent      = self.ConfigurationContainer,
        BackgroundTransparency = SLOT_CONSTANTS.BackgroundTransparency,
    } :: Frame
    self.GuiSlotPositions[Constants.GUI_SLOT_NAMES.BottomRight] = self.BottomRightPosition

    -- Immediately reparent AlwaysOn elements so they're visible before Enable()
    if topMiddleAlwaysOn and self._elements.topMiddle then self._elements.topMiddle.Parent = self.TopMiddle end
    if topRightAlwaysOn and self._elements.topRight then self._elements.topRight.Parent = self.TopRight end
    if bottomLeftAlwaysOn and self._elements.bottomLeft then self._elements.bottomLeft.Parent = self.BottomLeft end
    if bottomMiddleAlwaysOn and self._elements.bottomMiddle then self._elements.bottomMiddle.Parent = self.BottomMiddle end
    if bottomRightAlwaysOn and self._elements.bottomRight then self._elements.bottomRight.Parent = self.BottomRight end

    return (self :: any) :: GuiConfiguration
end

function GuiConfiguration:Disable()
    self.Enabled:set(false)
end

function GuiConfiguration:Enable()
    task.spawn(function()
        if self._elements.topMiddle then self._elements.topMiddle.Parent = self.TopMiddle end
        if self._elements.topRight then self._elements.topRight.Parent = self.TopRight end
        if self._elements.bottomLeft then self._elements.bottomLeft.Parent = self.BottomLeft end
        if self._elements.bottomMiddle then self._elements.bottomMiddle.Parent = self.BottomMiddle end
        if self._elements.bottomRight then self._elements.bottomRight.Parent = self.BottomRight end
        self.ModalVisible:set(true)
        self.Enabled:set(true)
    end)
end

function GuiConfiguration:HideForModal()
    self.ModalVisible:set(false)
end

function GuiConfiguration:ShowFromModal()
    self.ModalVisible:set(true)
end

return GuiConfiguration