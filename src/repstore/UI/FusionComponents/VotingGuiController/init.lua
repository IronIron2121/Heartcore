--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")


-- Folders
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Widgets = FusionComponents:WaitForChild("Widgets")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local DataTables = ReplicatedStorage:WaitForChild("DataTables")
local Voting = ServerScriptService:WaitForChild("Voting")


-- Instances
local localPlayer = Players.LocalPlayer

-- GUI
local PlayerGui = localPlayer.PlayerGui
local OutfitVoteTile = require(script:WaitForChild("OutfitVoteTile"))

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))
local SerialisationService = require(Utility:WaitForChild("SerialisationService"))
local ImageUris = require(DataTables:WaitForChild("ImageUris"))
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))
local ThemeManager = require(Voting:WaitForChild("ThemeManager"))




-- Fusion Modules
local scope = Fusion:scoped()
local peek = Fusion.peek
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

-- GUI Modules
local BaseButton = require(Widgets:WaitForChild("BaseButton"))

-- Constants
local maxDisplayedOutfits = 3

-- Remotes / Bindables
local PlayerSubmittedVote = Remotes:WaitForChild("PlayerSubmittedVote")
local GetBalancedOutfit = Remotes:WaitForChild("GetBalancedOutfit")

local VotingGuiController = {}

local outfitVoteTiles = scope:Value({})
local selectedTileId = scope:Value(nil)
local isRefreshing = false

local function refreshOutfitVoteTiles()
    if isRefreshing then
        warn("Already refreshing outfit tiles, skipping...")
        return
    end
    
    isRefreshing = true
    
    -- Clear selection and existing tiles
    selectedTileId:set(nil)
    for _, tile in ipairs(peek(outfitVoteTiles)) do
        if tile and tile.Destroy then
            tile:Destroy()
        end
    end
    
    outfitVoteTiles:set({})
    
    -- Fetch new outfits
    local newTiles = {}
    local successCount = 0
    local usedIds = {}

    for i = 1, maxDisplayedOutfits do
        local success, outfitData = pcall(function()
            return GetBalancedOutfit:InvokeServer()
        end)
        
        if success and outfitData and not table.find(usedIds, outfitData.userId) then
            newTiles[i] = {
                userId = outfitData.userId,
                humanoidDescription = SerialisationService.UnserialiseHumanoidDescription(outfitData.humanoidDescription),
                playerName = outfitData.playerName,
                votes = outfitData.votes or "FAILURE_NO_VOTES",
                views = outfitData.views or "FAILURE_NO_VIEWS"
            }
            table.insert(usedIds, outfitData.userId)
            successCount = successCount + 1
        else
            newTiles[i] = {
                userId = 0,
                humanoidDescription = Instance.new("HumanoidDescription"),
                playerName = "NO_MORE_OUTFITS_AVAILABLE",
                votes = 0,
                views = 0
            }
        end
    end
    
    outfitVoteTiles:set(newTiles)
    print("Refreshed outfit tiles: " .. successCount .. "/" .. maxDisplayedOutfits .. " loaded successfully")
    isRefreshing = false
end

function VotingGuiController.refreshOutfits()
    refreshOutfitVoteTiles()
end

function VotingGuiController.getSelectedOutfit()
    return peek(selectedTileId)
end

function VotingGuiController.setSelectedOutfit(userId: number)
    selectedTileId:set(userId)
end

local currentTheme = ThemeManager.getCurrentTheme()
local themeName = currentTheme or "Unknown"
    
   

function VotingGuiController.Initialise(
    visibilityBoolean: UsedAs<boolean>
)
    local _VoteGui = scope:New "ScreenGui" {
        Name = "VotingGui",
        Enabled = visibilityBoolean,
        Parent = PlayerGui,

        [Children] = {
            scope:New "Frame" {
                Name = "Container",
                Size = UDim2.fromScale(0.8, 0.8),
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

                    scope:New "UIPadding" {
                        PaddingBottom = UDim.new(0.05,0),
                        PaddingTop = UDim.new(0.05,0),
                        PaddingRight = UDim.new(0.05,0),
                        PaddingLeft = UDim.new(0.05,0)
                    },

                    scope:New "Frame"{
                        Name = "TopBar",
                        Size = UDim2.fromScale(1, 0.1),
                        LayoutOrder = 1,
                        BackgroundTransparency = 1,

                        [Children] = {
                            scope:New "UIListLayout" {
                                FillDirection = Enum.FillDirection.Horizontal,
                                SortOrder = Enum.SortOrder.LayoutOrder
                            },

                            scope:New "TextLabel" {
                                Name = "VoteFor",
                                Text = "Vote for best fit:",
                                TextScaled = true,
                                Size = UDim2.fromScale(0.3, 1),
                                LayoutOrder = 1,
                                BackgroundTransparency = 1,
                                TextColor3 = Color3.fromRGB(92, 96, 214)
                            },

                            scope:New "TextLabel" {
                                Name = "TodaysTheme",
                                Text = themeName,
                                TextScaled = true,
                                Size = UDim2.fromScale(0.3, 1),
                                LayoutOrder = 1,
                                BackgroundTransparency = 1,
                                TextColor3 = Color3.fromRGB(92, 96, 214)
                            },

                            scope:New "Frame"{
                                Name = "Buffer",
                                Size = UDim2.fromScale(0.1, 1),
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
                                        SortOrder = Enum.SortOrder.LayoutOrder
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
                                        Text = "HH:MM:SS",
                                        TextScaled = true,
                                        Size = UDim2.fromScale(1, 1),
                                        LayoutOrder = 2,
                                        BackgroundTransparency = 1,
                                        TextColor3 = Color3.fromRGB(92, 96, 214)
                                    }
                                }
                            }
                        }
                    },

                    scope:New "Frame" {
                        Name = "Body",
                        LayoutOrder = 2,
                        Size = UDim2.fromScale(1, 0.8),
                        BackgroundTransparency = 1,

                        [Children] = { 
                            scope:New "UIListLayout" {
                                FillDirection = Enum.FillDirection.Vertical,
                                SortOrder = Enum.SortOrder.LayoutOrder,
                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
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

                                    scope:ForValues(outfitVoteTiles, function(use, scope, outfitData)
                                        local randomId = math.random(1, 99999)
                                        local tileName = "OutfitTile_" .. randomId
                                        return OutfitVoteTile(scope, {
                                            Name = tileName,
                                            userId = outfitData.userId,
                                            humanoidDescription = outfitData.humanoidDescription,
                                            playerName = outfitData.playerName,
                                            votes = outfitData.votes,
                                            views = outfitData.views,
                                            size = UDim2.fromScale(0.3, 0.9),
                                            IsSelected = scope:Computed(function(use)
                                                return use(selectedTileId) == outfitData.userId
                                            end),
                                            OnSelected = function()
                                                if outfitData.userId ~= 0 then
                                                    VotingGuiController.setSelectedOutfit(outfitData.userId)
                                                end
                                            end
                                        })
                                    end)
                                } 
                            },

                            scope:New "Frame" {
                                Name = "Buffer",
                                Size = UDim2.fromScale(1, 0.05),
                                LayoutOrder = 3,
                                BackgroundTransparency = 1
                            },

                            scope:New "Frame" {
                                Name = "SubmitFrame",
                                Size = UDim2.fromScale(0.5, 0.2),
                                LayoutOrder = 4,
                                BackgroundTransparency = 1,
                                
                                [Children] = {
                                                                       
                                    BaseButton(scope, {
                                        name = "SubmitButton",
                                        text = "Submit Vote",
                                        textScaled = true,
                                        size = UDim2.fromScale(0.8, 1),
                                        backgroundColor = Color3.new(1, 1, 1),
                                        strokeColor = Color3.new(0.360784, 0.376471, 0.839216),
                                        strokeThickness = 5,
                                        textColor = Color3.new(0.360784, 0.376471, 0.839216),

                                        layoutOrder = 1,
                                        onActivated = function()
                                            local selectedUserId = VotingGuiController.getSelectedOutfit()
                                            if selectedUserId then
                                                local viewIds = {}
                                                for _, tile in ipairs(peek(outfitVoteTiles)) do
                                                    if tile.userId ~= 0 then
                                                        table.insert(viewIds, tile.userId)
                                                    end
                                                end
                                                
                                                PlayerSubmittedVote:FireServer(selectedUserId, viewIds)
                                                VotingGuiController.refreshOutfits()
                                            else
                                                warn("No outfit selected for voting")
                                            end
                                        end
                                    }),

                                    
                                }
                            }
                        }
                    },
                }
            },
        }
    }
    
    task.wait(0.1)
    refreshOutfitVoteTiles()
end 

return VotingGuiController