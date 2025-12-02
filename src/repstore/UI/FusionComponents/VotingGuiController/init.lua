--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

-- Folders
local DataTables        = ReplicatedStorage:WaitForChild("DataTables")
local Utility           = ReplicatedStorage:WaitForChild("Utility")
local Remotes           = ReplicatedStorage:WaitForChild("Remotes")
local Values            = ReplicatedStorage:WaitForChild("Values")
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local Widgets = FusionComponents:WaitForChild("Widgets")

-- Instances
local localPlayer = Players.LocalPlayer

-- GUI
local PlayerGui = localPlayer.PlayerGui
local OutfitVoteTile = require(script:WaitForChild("OutfitVoteTile"))
local EmptyVoteTile = require(script:WaitForChild("EmptyVoteTile"))
local CloseButton   = require(Widgets:WaitForChild("CloseButton"))


-- Modules
local SerialisationService = require(Utility:WaitForChild("SerialisationService"))
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))
local ImageUris = require(DataTables:WaitForChild("ImageUris"))
local Fusion = require(Utility:WaitForChild("Fusion"))
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))

-- Fusion Modules
local scope = Fusion:scoped()
local peek = Fusion.peek
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>
type Value<T> = Fusion.Value<T>

-- Constants
local maxDisplayedOutfits = 3
local VOTE_TILE_SIZE = UDim2.fromScale(0.3, 0.9)

-- Remotes / Bindables
local PlayerRequestedVotingTheme = Remotes:WaitForChild("PlayerRequestedVotingTheme")
local PlayerSubmittedVote = Remotes:WaitForChild("PlayerSubmittedVote")
local GetBalancedOutfit = Remotes:WaitForChild("GetBalancedOutfit")

-- Variables
-- TODO - or get next round if that's closer
local timeToNextRotation = scope:Value("LOADING...")

--

local VotingGuiController = {}

local outfitVoteTiles = scope:Value({})
local isRefreshing = false

-- Types
type TileData = {
    userId: number,
    humanoidDescription: HumanoidDescription?,
    playerName: string,
    votes: number,
    views: number
}

--
 
local function refreshOutfitVoteTiles()
    if isRefreshing then
        warn("Already refreshing outfit tiles, skipping...")
        return
    end
    
    isRefreshing = true
    
    -- Clear selection and existing tiles
    outfitVoteTiles:set({})
    
    -- Fetch new outfits
    local newTiles = {}
    local successCount = 0
    local usedIds = {}

    for i = 1, maxDisplayedOutfits do
        local success, outfitData = callWithRetry(
            function()
                return GetBalancedOutfit:InvokeServer()
            end,
            5
        )
        
        if success and outfitData and not table.find(usedIds, outfitData.userId) then
            if not outfitData.humanoidDescription then 
                return
            end
            newTiles[i] = {
                userId = outfitData.userId,
                humanoidDescription = SerialisationService.UnserialiseHumanoidDescription(outfitData.humanoidDescription),
                playerName = outfitData.playerName,
                votes = outfitData.votes or "FAILURE_NO_VOTES",
                views = outfitData.views or "FAILURE_NO_VIEWS"
            } :: TileData
            
            table.insert(usedIds, outfitData.userId)
            successCount = successCount + 1
        else
            newTiles[i] = {
                userId = 0,
                humanoidDescription = nil,
                playerName = "NO_MORE_OUTFITS_AVAILABLE",
                votes = 0,
                views = 0
            } :: TileData
        end
    end
    
    outfitVoteTiles:set(newTiles)
    isRefreshing = false
end

function VotingGuiController.refreshOutfits()
    refreshOutfitVoteTiles()
end

local function initialiseRotationTimer()
    task.spawn(function()
        local NextRotationText = Values:WaitForChild("NextRotationText", 10) :: StringValue
        while true do
            task.wait(1) 
            timeToNextRotation:set("Out of outfits to load! Please wait for next voting phase!") --.. NextRotationText.Value)        
        end
    end)
end

local votingTheme = scope:Value("")

function VotingGuiController.Initialise(
    VoteGuiVisible: UsedAs<boolean>,
    TimeText: UsedAs<string>,
    props: {
        visible: Value<boolean>
    }
)
    local visibilityObserver = scope:Observer(VoteGuiVisible)

    initialiseRotationTimer()

    -- TODO: Make this more efficient with caching or something such...
    visibilityObserver:onChange(function()
        if peek(VoteGuiVisible) == true then
            votingTheme:set(PlayerRequestedVotingTheme:InvokeServer())
        elseif peek(VoteGuiVisible) == false then
            -- delete / reset the mannequins? ...
        end
    end)

    local _VoteGui = scope:New "ScreenGui" {
        Name = "VotingGui",
        Enabled = true,
        Parent = PlayerGui,

        [Children] = {
            scope:New "Frame" {
                Name = "Container",
                Size = UDim2.fromScale(0.8, 0.8),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.48),
                BackgroundColor3 = Color3.new(1,1,1),
                BackgroundTransparency = 1,
                Visible = props.visible,

                [Children] = {
                    CloseButton(scope, {
                        size = UDim2.fromScale(0.1, 0.1),
                        anchorPoint = Vector2.new(0.5, 0.5),
                        position = UDim2.fromScale(1, 0),

                        onClick = function()
                            props.visible:set(not peek(props.visible))
                        end
                    }),

                    scope:New "Frame" {
                        Name = "Background",
                        Size = UDim2.fromScale(1,1),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.fromScale(0.5, 0.48),
                        BackgroundColor3 = Color3.new(1,1,1),
                        BackgroundTransparency = 0.2,

                        [Children] = {    
                            scope:New "UIListLayout" {
                                FillDirection = Enum.FillDirection.Vertical,
                                SortOrder = Enum.SortOrder.LayoutOrder
                            },

                            scope:New "UICorner" {
                                CornerRadius = UDim.new(0.05)
                            },
                        }
                    },

                    scope:New "Frame" {
                        Name = "Body",
                        LayoutOrder = 2,
                        Size = UDim2.fromScale(1, 1),
                        BackgroundTransparency = 1,

                        [Children] = { 
                            scope:New "UIListLayout" {
                                FillDirection = Enum.FillDirection.Vertical,
                                SortOrder = Enum.SortOrder.LayoutOrder,
                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                            },

                            scope:New "Frame" {
                                Name = "Buffer",
                                Size = UDim2.fromScale(1, 0.03),
                                LayoutOrder = 0,
                                BackgroundTransparency = 1
                            },

                            scope:New "Frame" {
                                Name = "TopBar",
                                Size = UDim2.fromScale(1, 0.1),
                                LayoutOrder = 1,
                                BackgroundTransparency = 1,

                                [Children] = {
                                    scope:New "UIListLayout" {
                                        FillDirection = Enum.FillDirection.Horizontal,
                                        SortOrder = Enum.SortOrder.LayoutOrder,
                                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                        Padding = UDim.new(0.02,0),
                                    },

                                    scope:New "TextLabel" {
                                        Name = "VoteFor",
                                        Text = "Vote for best fit:",
                                        TextScaled = true,
                                        Size = UDim2.fromScale(0.3, 1),
                                        LayoutOrder = 0,
                                        BackgroundTransparency = 1,
                                        TextColor3 = Color3.fromRGB(92, 96, 214),
                                        FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT,Enum.FontWeight.Bold),

                                    },

                                    scope:New "TextLabel" {
                                        Name = "TodaysTheme",
                                        Text = votingTheme,--themeName,
                                        TextScaled = true,
                                        Size = UDim2.fromScale(0.3, 1),
                                        LayoutOrder = 1,
                                        BackgroundTransparency = 1,
                                        TextColor3 = Color3.fromRGB(92, 96, 214),
                                        FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT,Enum.FontWeight.Bold),
                                    },

                                    scope:New "Frame"{
                                        Name = "Buffer",
                                        Size = UDim2.fromScale(0.03, 1),
                                        LayoutOrder = 2,
                                        BackgroundTransparency = 1,
                                    },

                                    scope:New "Frame"{
                                        Name = "TimerContainer",
                                        Size = UDim2.fromScale(0.2, 1),
                                        LayoutOrder = 3,
                                        BackgroundTransparency = 1,
                                        
                                        [Children] = {

                                            scope:New "UIListLayout" {
                                                FillDirection = Enum.FillDirection.Horizontal,
                                                SortOrder = Enum.SortOrder.LayoutOrder,
                                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                            },

                                            scope:New "ImageLabel"{
                                                Image = ImageUris.StopwatchIcon,
                                                Size = UDim2.fromScale(1, 1),
                                                LayoutOrder = 1,
                                                BackgroundTransparency = 1,
                                                
                                                [Children] = {
                                                    scope:New "UIAspectRatioConstraint" {
                                                        AspectRatio = 1,
                                                        DominantAxis = Enum.DominantAxis.Width,
                                                    }
                                                }
                                            },

                                            scope:New "TextLabel" {
                                                Name = "Timer",
                                                -- Text = "HH:MM:SS",
                                                Text = TimeText,
                                                TextScaled = true,
                                                Size = UDim2.fromScale(1, 1),
                                                LayoutOrder = 2,
                                                BackgroundTransparency = 1,
                                                TextColor3 = Color3.fromRGB(92, 96, 214),
                                                FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT,Enum.FontWeight.Bold),
                                            }
                                        }
                                    }
                                }
                            },
                            
                            scope:New "Frame" {
                                Name = "Buffer",
                                Size = UDim2.fromScale(1, 0.01),
                                LayoutOrder = 1,
                                BackgroundTransparency = 1
                            },

                            scope:New "Frame" {
                                Name = "OutfitsContainer",
                                BackgroundTransparency = 1,
                                Size = UDim2.fromScale(1, 0.8),
                                LayoutOrder = 2,

                                [Children] = {
                                    scope:New "UIListLayout" {
                                        FillDirection = Enum.FillDirection.Horizontal,
                                        SortOrder = Enum.SortOrder.LayoutOrder,
                                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                        VerticalAlignment = Enum.VerticalAlignment.Center,
                                        Padding = UDim.new(0.01, 0),
                                        Wraps = false
                                    },

                                    scope:New "UICorner" {
                                        CornerRadius = UDim.new(0.05)
                                    },

                                    scope:ForPairs(outfitVoteTiles, function(use, scope, index, outfitData)
                                        local randomId = math.random(1, 99999)
                                        local tileName = "OutfitTile_" .. randomId
                                        local userId = outfitData.userId

                                        if outfitData.humanoidDescription then
                                            return index, OutfitVoteTile(scope, {
                                                Name = tileName,
                                                layoutOrder = index,
                                                userId = outfitData.userId,
                                                humanoidDescription = outfitData.humanoidDescription,
                                                playerName = outfitData.playerName,
                                                votes = outfitData.votes,
                                                views = outfitData.views,
                                                size = VOTE_TILE_SIZE,
                                                IsSelected = scope:Computed(function(use)
                                                    return use(selectedTileId) == userId
                                                end), 

                                                OnSelected = function()
                                                    if outfitData.userId ~= 0 then
                                                        local viewIds = {}
                                                        for _, tile in ipairs(peek(outfitVoteTiles)) do
                                                            if tile.userId ~= 0 then
                                                                table.insert(viewIds, tile.userId)
                                                            end
                                                        end

                                                        PlayerSubmittedVote:InvokeServer(outfitData.userId, viewIds)
                                                        VotingGuiController.refreshOutfits()
                                                    else
                                                        warn("No outfitData user id!")
                                                    end
                                                end
                                            })
                                        else
                                            return index, EmptyVoteTile(scope, {
                                                name = tileName,
                                                layoutOrder = index,
                                                size = VOTE_TILE_SIZE,
                                                timeToNextRotation = timeToNextRotation
                                            })
                                        end
                                        
                                    end)
                                } 
                            },
                        }
                    },
                }
            },
        }
    }
end 

return VotingGuiController