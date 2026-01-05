--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local Constants = require(ReplicatedStorage.Constants)

-- Fusion
local Fusion        = require(Utility.Fusion)
local Children      = Fusion.Children
type UsedAs<T>      = Fusion.UsedAs<T>
type Value<T>       = Fusion.Value<T>
type Computed<T>    = Fusion.Computed<T>
type scope          = Fusion.Scope

--

local SLOT_CONSTANTS = {
    Colour = Color3.new(0.686275, 0.105882, 0.105882),
    BackgroundTransparency = 0.5,
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
    BottomLeft: Frame,
    BottomLeftPosition: Value<UDim2>,
    BottomMiddle: Frame,
    BottomMiddlePosition: Value<UDim2>,
    BottomRight: Frame,
    BottomRightPosition: Value<UDim2>,
    GuiSlotPositions: {[string]: Value<UDim2>},
    scope: Fusion.Scope,

    -- Methods
    Disable: (self: GuiConfiguration) -> (),
    Enable: (self: GuiConfiguration) -> (),
}

local GuiConfiguration = {}
GuiConfiguration.__index = GuiConfiguration

function GuiConfiguration.new(props: {
    ConfigurationName: string,
    color: Color3?,
    topMiddle: GuiObject?,
    bottomLeft: GuiObject?,
    bottomMiddle: GuiObject?,
    bottomRight: GuiObject?
}): GuiConfiguration
    -- Initialise an object of this class (Luau OOP)
    local self = {}
    setmetatable(self, GuiConfiguration) 
    self.Name = props.ConfigurationName

    -- Establish a scope for this configuration
    self.scope = Fusion:scoped()

    self.Enabled = self.scope:Value(false)


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
        return use(self.Enabled) and SLOT_LAYOUTS[Constants.GUI_SLOT_NAMES.TopMiddle].InPosition or SLOT_LAYOUTS[Constants.GUI_SLOT_NAMES.TopMiddle].OutPosition  
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
            props.topMiddle
        }
    } :: Frame
    self.GuiSlotPositions[Constants.GUI_SLOT_NAMES.TopMiddle] = self.TopMiddlePosition

    self.BottomLeftPosition = self.scope:Computed(function(use)  
        return use(self.Enabled) and SLOT_LAYOUTS[Constants.GUI_SLOT_NAMES.BottomLeft].InPosition or SLOT_LAYOUTS[Constants.GUI_SLOT_NAMES.BottomLeft].OutPosition  
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
            props.bottomLeft
        }
    } :: Frame
    self.GuiSlotPositions[Constants.GUI_SLOT_NAMES.BottomLeft] = self.BottomLeftPosition

    self.BottomMiddlePosition = self.scope:Computed(function(use)  
        return use(self.Enabled) and SLOT_LAYOUTS[Constants.GUI_SLOT_NAMES.BottomMiddle].InPosition or SLOT_LAYOUTS[Constants.GUI_SLOT_NAMES.BottomMiddle].OutPosition  
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
            props.bottomMiddle
        }
    } :: Frame
    self.GuiSlotPositions[Constants.GUI_SLOT_NAMES.BottomMiddle] = self.BottomMiddlePosition

    self.BottomRightPosition = self.scope:Computed(function(use)  
        return use(self.Enabled) and SLOT_LAYOUTS[Constants.GUI_SLOT_NAMES.BottomRight].InPosition or SLOT_LAYOUTS[Constants.GUI_SLOT_NAMES.BottomRight].OutPosition  
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
            props.bottomRight
        }
    } :: Frame
    self.GuiSlotPositions[Constants.GUI_SLOT_NAMES.BottomRight] = self.BottomRightPosition

    return self
end

function GuiConfiguration:Disable()
    self.Enabled:set(false)
end

function GuiConfiguration:Enable()
    self.Enabled:set(true)
end

return GuiConfiguration