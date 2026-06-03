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
    enabled: UsedAs<boolean>?,
}

local Children = Fusion.Children

local SLOT_PADDING = UDim.new(0.02, 0)

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

    [Constants.GUI_SLOT_NAMES.MiddleRight] = {
        Name =  Constants.GUI_SLOT_NAMES.MiddleRight,
        AnchorPoint = Vector2.new(1, 0.5),
        InPosition = UDim2.fromScale(1, 0.5),
        OutPosition = UDim2.fromScale(2, 0),
        Size = UDim2.fromScale(0.2, 0.8)
    },

    [Constants.GUI_SLOT_NAMES.MiddleLeft] = {
        Name = Constants.GUI_SLOT_NAMES.MiddleLeft,
        AnchorPoint = Vector2.new(0, 0.5),
        InPosition = UDim2.fromScale(0, 0.5),
        OutPosition = UDim2.fromScale(-0.15, 0.5),
        Size = UDim2.fromScale(0.1, 0.8),
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
        Size = UDim2.fromScale(1, 0.2)
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
    MiddleRight: Frame,
    MiddleRightPosition: Frame,
    MiddleLeft: Frame,
    MiddleLeftPosition: Value<UDim2>,
    BottomLeft: Frame,
    BottomLeftPosition: Value<UDim2>,
    BottomMiddle: Frame,
    BottomMiddlePosition: Value<UDim2>,
    BottomRight: Frame,
    BottomRightPosition: Value<UDim2>,
    Enabled: Value<boolean>,
    GuiSlotPositions: {[string]: Value<UDim2>},
    scope: Fusion.Scope,
    topMiddleEnabled: Value<boolean>,
    topRightEnabled: Value<boolean>,
    middleRightEnabled: Value<boolean>,
    middleLeftEnabled: Value<boolean>,
    bottomLeftEnabled: Value<boolean>,
    bottomMiddleEnabled: Value<boolean>,
    bottomRightEnabled: Value<boolean>,
    _elements: {
        topMiddle: GuiObject?,
        topRight: GuiObject?,
        middleRight: GuiObject?,
        middleLeft: GuiObject?,
        bottomLeft: GuiObject?,
        bottomMiddle: GuiObject?,
        bottomRight: GuiObject?,
    },

    -- Methods
    Disable: (self: GuiConfiguration) -> (),
    Enable: (self: GuiConfiguration, startHidden: boolean?) -> (),
    HideForModal: (self: GuiConfiguration) -> (),
    ShowFromModal: (self: GuiConfiguration) -> (),
    HideAll: (self: GuiConfiguration) -> (),
    ShowAll: (self: GuiConfiguration) -> (),
}

local GuiConfiguration = {}
GuiConfiguration.__index = GuiConfiguration

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
}): GuiConfiguration
    -- Initialise an object of this class (Luau OOP)
    local self = {}
    setmetatable(self, GuiConfiguration) 
    self.Name = props.ConfigurationName

    -- Establish a scope for this configuration
    self.scope = Fusion:scoped()

    self.Enabled = self.scope:Value(false)
    self.ModalVisible = self.scope:Value(true)
    self.ForceHidden = self.scope:Value(false)

    -- Extract AlwaysOn flags and per-slot enabled values
    local topMiddleAlwaysOn    = props.topMiddle    and props.topMiddle.AlwaysOn    or false
    local topRightAlwaysOn     = props.topRight     and props.topRight.AlwaysOn     or false
    local middleRightAlwaysOn  = props.middleRight  and props.middleRight.AlwaysOn  or false
    local middleLeftAlwaysOn   = props.middleLeft   and props.middleLeft.AlwaysOn   or false
    local bottomLeftAlwaysOn   = props.bottomLeft   and props.bottomLeft.AlwaysOn   or false
    local bottomMiddleAlwaysOn = props.bottomMiddle and props.bottomMiddle.AlwaysOn or false
    local bottomRightAlwaysOn  = props.bottomRight  and props.bottomRight.AlwaysOn  or false

    -- Per-slot enabled Values — callers can set these to slide slots in/out
    self.topMiddleEnabled    = (props.topMiddle    and props.topMiddle.enabled)    or self.scope:Value(true)
    self.topRightEnabled     = (props.topRight     and props.topRight.enabled)     or self.scope:Value(true)
    self.middleRightEnabled  = (props.middleRight  and props.middleRight.enabled)  or self.scope:Value(true)
    self.middleLeftEnabled   = (props.middleLeft   and props.middleLeft.enabled)   or self.scope:Value(true)
    self.bottomLeftEnabled   = (props.bottomLeft   and props.bottomLeft.enabled)   or self.scope:Value(true)
    self.bottomMiddleEnabled = (props.bottomMiddle and props.bottomMiddle.enabled) or self.scope:Value(true)
    self.bottomRightEnabled  = (props.bottomRight  and props.bottomRight.enabled)  or self.scope:Value(true)

    -- Store element references for reparenting on Enable()
    self._elements = {
        topMiddle = props.topMiddle and props.topMiddle.Object or nil,
        topRight = props.topRight and props.topRight.Object or nil,
        middleRight = props.middleRight and props.middleRight.Object or nil,
        middleLeft = props.middleLeft and props.middleLeft.Object or nil,
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
        local slotOn = use(self.topMiddleEnabled :: UsedAs<boolean>)
        local visible = use(self.Enabled) and not use(self.ForceHidden) and slotOn and (topMiddleAlwaysOn or use(self.ModalVisible))
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
        [Children] = {
            self.scope:New "UIPadding" {
                PaddingTop = SLOT_PADDING, PaddingBottom = SLOT_PADDING,
                PaddingLeft = SLOT_PADDING, PaddingRight = SLOT_PADDING,
            },
        },
    } :: Frame
    self.GuiSlotPositions[Constants.GUI_SLOT_NAMES.TopMiddle] = self.TopMiddlePosition

    self.TopRightPosition = self.scope:Computed(function(use)
        local slotOn = use(self.topRightEnabled :: UsedAs<boolean>)
        local visible = use(self.Enabled) and not use(self.ForceHidden) and slotOn and (topRightAlwaysOn or use(self.ModalVisible))
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
        [Children] = {
            self.scope:New "UIPadding" {
                PaddingTop = SLOT_PADDING, PaddingBottom = SLOT_PADDING,
                PaddingLeft = SLOT_PADDING, PaddingRight = SLOT_PADDING,
            },
        },
    } :: Frame
    self.GuiSlotPositions[Constants.GUI_SLOT_NAMES.TopRight] = self.TopRightPosition

    self.MiddleRightPosition = self.scope:Computed(function(use)
        local slotOn = use(self.middleRightEnabled :: UsedAs<boolean>)
        local visible = use(self.Enabled) and not use(self.ForceHidden) and slotOn and (middleRightAlwaysOn or use(self.ModalVisible))
        return visible and SLOT_LAYOUTS[Constants.GUI_SLOT_NAMES.MiddleRight].InPosition or SLOT_LAYOUTS[Constants.GUI_SLOT_NAMES.MiddleRight].OutPosition
    end)
    self.MiddleRight = self.scope:New "Frame" {
        Name        = SLOT_LAYOUTS[Constants.GUI_SLOT_NAMES.MiddleRight].Name,
        AnchorPoint = SLOT_LAYOUTS[Constants.GUI_SLOT_NAMES.MiddleRight].AnchorPoint,
        Position    = self.scope:Tween(self.MiddleRightPosition, Constants.DEFAULT_TWEEN),
        Size        = SLOT_LAYOUTS[Constants.GUI_SLOT_NAMES.MiddleRight].Size,
        BackgroundColor3      = props.color or SLOT_CONSTANTS.Colour,
        Visible     = SLOT_CONSTANTS.Visible,
        Parent      = self.ConfigurationContainer,
        BackgroundTransparency = SLOT_CONSTANTS.BackgroundTransparency,
        [Children] = {
            self.scope:New "UIPadding" {
                PaddingTop = SLOT_PADDING, PaddingBottom = SLOT_PADDING,
                PaddingLeft = SLOT_PADDING, PaddingRight = SLOT_PADDING,
            },
        },
    } :: Frame
    self.GuiSlotPositions[Constants.GUI_SLOT_NAMES.MiddleRight] = self.MiddleRightPosition

    self.MiddleLeftPosition = self.scope:Computed(function(use)
        local slotOn = use(self.middleLeftEnabled :: UsedAs<boolean>)
        local visible = use(self.Enabled) and not use(self.ForceHidden) and slotOn and (middleLeftAlwaysOn or use(self.ModalVisible))
        return visible and SLOT_LAYOUTS[Constants.GUI_SLOT_NAMES.MiddleLeft].InPosition or SLOT_LAYOUTS[Constants.GUI_SLOT_NAMES.MiddleLeft].OutPosition
    end)
    self.MiddleLeft = self.scope:New "Frame" {
        Name        = SLOT_LAYOUTS[Constants.GUI_SLOT_NAMES.MiddleLeft].Name,
        AnchorPoint = SLOT_LAYOUTS[Constants.GUI_SLOT_NAMES.MiddleLeft].AnchorPoint,
        Position    = self.scope:Tween(self.MiddleLeftPosition, Constants.DEFAULT_TWEEN),
        Size        = SLOT_LAYOUTS[Constants.GUI_SLOT_NAMES.MiddleLeft].Size,
        BackgroundColor3      = props.color or SLOT_CONSTANTS.Colour,
        Visible     = SLOT_CONSTANTS.Visible,
        Parent      = self.ConfigurationContainer,
        BackgroundTransparency = SLOT_CONSTANTS.BackgroundTransparency,
        [Children] = {
            self.scope:New "UIPadding" {
                PaddingTop = SLOT_PADDING, PaddingBottom = SLOT_PADDING,
                PaddingLeft = SLOT_PADDING, PaddingRight = SLOT_PADDING,
            },
        },
    } :: Frame
    self.GuiSlotPositions[Constants.GUI_SLOT_NAMES.MiddleLeft] = self.MiddleLeftPosition

    self.BottomLeftPosition = self.scope:Computed(function(use)
        local slotOn = use(self.bottomLeftEnabled :: UsedAs<boolean>)
        local visible = use(self.Enabled) and not use(self.ForceHidden) and slotOn and (bottomLeftAlwaysOn or use(self.ModalVisible))
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
        [Children] = {
            self.scope:New "UIPadding" {
                PaddingTop = SLOT_PADDING, PaddingBottom = SLOT_PADDING,
                PaddingLeft = SLOT_PADDING, PaddingRight = SLOT_PADDING,
            },
        },
    } :: Frame
    self.GuiSlotPositions[Constants.GUI_SLOT_NAMES.BottomLeft] = self.BottomLeftPosition

    self.BottomMiddlePosition = self.scope:Computed(function(use)
        local slotOn = use(self.bottomMiddleEnabled :: UsedAs<boolean>)
        local visible = use(self.Enabled) and not use(self.ForceHidden) and slotOn and (bottomMiddleAlwaysOn or use(self.ModalVisible))
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
        [Children] = {
            self.scope:New "UIPadding" {
                PaddingTop = SLOT_PADDING, PaddingBottom = SLOT_PADDING,
                PaddingLeft = SLOT_PADDING, PaddingRight = SLOT_PADDING,
            },
        },
    } :: Frame
    self.GuiSlotPositions[Constants.GUI_SLOT_NAMES.BottomMiddle] = self.BottomMiddlePosition

    self.BottomRightPosition = self.scope:Computed(function(use)
        local slotOn = use(self.bottomRightEnabled :: UsedAs<boolean>)
        local visible = use(self.Enabled) and not use(self.ForceHidden) and slotOn and (bottomRightAlwaysOn or use(self.ModalVisible))
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
        [Children] = {
            self.scope:New "UIPadding" {
                PaddingTop = SLOT_PADDING, PaddingBottom = SLOT_PADDING,
                PaddingLeft = SLOT_PADDING, PaddingRight = SLOT_PADDING,
            },
        },
    } :: Frame
    self.GuiSlotPositions[Constants.GUI_SLOT_NAMES.BottomRight] = self.BottomRightPosition

    -- Immediately reparent AlwaysOn elements so they're visible before Enable()
    if topMiddleAlwaysOn and self._elements.topMiddle then self._elements.topMiddle.Parent = self.TopMiddle end
    if topRightAlwaysOn and self._elements.topRight then self._elements.topRight.Parent = self.TopRight end
    if middleRightAlwaysOn and self._elements.middleRight then self._elements.middleRight.Parent = self.MiddleRight end
    if middleLeftAlwaysOn and self._elements.middleLeft then self._elements.middleLeft.Parent = self.MiddleLeft end
    if bottomLeftAlwaysOn and self._elements.bottomLeft then self._elements.bottomLeft.Parent = self.BottomLeft end
    if bottomMiddleAlwaysOn and self._elements.bottomMiddle then self._elements.bottomMiddle.Parent = self.BottomMiddle end
    if bottomRightAlwaysOn and self._elements.bottomRight then self._elements.bottomRight.Parent = self.BottomRight end


    return (self :: any) :: GuiConfiguration
end

function GuiConfiguration:Disable()
    self.Enabled:set(false)
end

function GuiConfiguration:Enable(startHidden: boolean?)
    -- TODO: Simplify these by putting them in an array and iterating through it
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