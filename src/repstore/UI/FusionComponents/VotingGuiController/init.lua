--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Folders
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Widgets = FusionComponents:WaitForChild("Widgets")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Instances
local localPlayer = Players.LocalPlayer

-- GUI
local PlayerGui = localPlayer.PlayerGui
local OutfitVoteTile = require(script:WaitForChild("OutfitVoteTile"))

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))

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
local GetBalancedOutfit = Remotes:WaitForChild("GetBalancedOutfit")

--

local VotingGuiController = {}

local outfitVoteTiles = scope:Value({})
local selectedTileName = scope:Value(nil)
local isRefreshing = false

local function refreshOutfitVoteTiles()
    if isRefreshing then
        warn("Already refreshing outfit tiles, skipping...")
        return
    end
    
    isRefreshing = true
    print("Refreshing outfit vote tiles...")
    
    -- Clear selection and destroy existing tiles
    selectedTileName:set(nil)
    for _, tile in ipairs(peek(outfitVoteTiles)) do
        if tile and tile.Destroy then
            tile:Destroy()
        end
    end
    
    -- Clear the tiles array
    outfitVoteTiles:set({})
    
    -- Fetch new outfits
    local newTiles = {}
    local successCount = 0
    
    for i = 1, maxDisplayedOutfits do
        local success, outfitData = pcall(function()
            return GetBalancedOutfit:InvokeServer()
        end)
        
        if success and outfitData then
            -- Create the tile data that OutfitVoteTile expects
            newTiles[i] = {
                entryKey = outfitData.entryKey or ("outfit_" .. i),
                humanoidDescription = outfitData.humanoidDescription,
                userId = outfitData.userId,
                playerName = outfitData.playerName,
                votes = outfitData.votes or 0,
                views = outfitData.views or 0
            }
            successCount = successCount + 1
        else
            warn("Failed to get balanced outfit for slot " .. i .. ":", outfitData)
            -- Create a placeholder tile
            newTiles[i] = {
                entryKey = "placeholder_" .. i,
                humanoidDescription = nil,
                userId = 0,
                playerName = "Loading...",
                votes = 0,
                views = 0
            }
        end
    end
    
    -- Update the tiles
    outfitVoteTiles:set(newTiles)
    
    print("Refreshed outfit tiles: " .. successCount .. "/" .. maxDisplayedOutfits .. " loaded successfully")
    isRefreshing = false
end

-- Public function to refresh tiles (can be called from other scripts)
function VotingGuiController.refreshOutfits()
    refreshOutfitVoteTiles()
end

-- Get the currently selected outfit
function VotingGuiController.getSelectedOutfit()
    return peek(selectedTileName)
end

-- Set the selected outfit (called by OutfitVoteTile)
function VotingGuiController.setSelectedOutfit(entryKey: string)
    selectedTileName:set(entryKey)
end

function VotingGuiController.Initialise(
    visibilityBoolean: UsedAs<boolean>,
    OutfitsTable: UsedAs<{}>
)
    local _VoteGui = scope:New "ScreenGui" {
        Name = "VotingGui",
        Enabled = visibilityBoolean,
        Parent = PlayerGui,

        [Children] = {
            scope:New "Frame" {
                Name = "Container",
                Size = UDim2.fromScale(0.8, 0.9),
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.fromScale(0.5, 1),
                BackgroundTransparency = 1,

                [Children] = {    

                    scope:New "UIListLayout" {
                        FillDirection = Enum.FillDirection.Vertical,
                        SortOrder = Enum.SortOrder.LayoutOrder
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
                                Name = "TodaysTheme",
                                Text = "TODAY'S THEME",
                                TextScaled = true,
                                Size = UDim2.fromScale(0.3, 1),
                                LayoutOrder = 1,
                                BackgroundTransparency = 1,
                                TextColor3 = Color3.new(1, 1, 1)
                            },

                            scope:New "Frame"{
                                Name = "Buffer",
                                Size = UDim2.fromScale(0.2, 1),
                                LayoutOrder = 2,
                                BackgroundTransparency = 1
                            },

                            scope:New "TextLabel" {
                                Name = "Timer",
                                Text = "VOTING ENDS: HH:MM:SS",
                                TextScaled = true,
                                Size = UDim2.fromScale(0.3, 1),
                                LayoutOrder = 3,
                                BackgroundTransparency = 1,
                                TextColor3 = Color3.new(1, 1, 1)
                            }
                        }
                    },

                    scope:New "Frame" {
                        Name = "Body",
                        LayoutOrder = 2,
                        Size = UDim2.fromScale(1, 0.8),
                        BackgroundColor3 = Color3.new(0.1, 0.5, 0.9),

                        [Children] = { 
                            scope:New "UIListLayout" {
                                FillDirection = Enum.FillDirection.Horizontal,
                                SortOrder = Enum.SortOrder.LayoutOrder,
                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                            },
                            
                            scope:New "Frame" {
                                Name = "Buffer",
                                Size = UDim2.fromScale(0.1, 1),
                                LayoutOrder = 1,
                                BackgroundTransparency = 1
                            },

                            scope:New "Frame" {
                                Name = "OutfitsContainer",
                                BackgroundColor3 = Color3.new(0.1, 0.2, 0.9),
                                Size = UDim2.fromScale(0.7, 1),
                                LayoutOrder = 2,

                                [Children] = {
                                    scope:New "UIGridLayout" {
                                        FillDirection = Enum.FillDirection.Horizontal,
                                        FillDirectionMaxCells = maxDisplayedOutfits,
                                        SortOrder = Enum.SortOrder.LayoutOrder,
                                        StartCorner = Enum.StartCorner.TopLeft,
                                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                        VerticalAlignment = Enum.VerticalAlignment.Center,
                                        CellSize = UDim2.fromScale(1/maxDisplayedOutfits, 0.9),
                                        CellPadding = UDim2.fromOffset(10, 0)
                                    },

                                    scope:New "UICorner" {
                                        CornerRadius = UDim.new(0.05)
                                    },

                                    scope:ForValues(outfitVoteTiles, function(use, scope, outfitData)
                                        return OutfitVoteTile(scope, {
                                            UserId = outfitData.userId,  -- The key identifier
                                            HumanoidDescription = outfitData.humanoidDescription,
                                            Votes = outfitData.votes,
                                            Views = outfitData.views,
                                            IsSelected = scope:Computed(function(use)
                                                return use(selectedTileName) == outfitData.userId
                                            end),
                                            OnSelected = function()
                                                VotingGuiController.setSelectedOutfit(outfitData.userId)
                                            end
                                        })
                                    end)
                                }
                            },

                            scope:New "Frame" {
                                Name = "SubmitFrame",
                                Size = UDim2.fromScale(0.2, 1),
                                LayoutOrder = 3,
                                BackgroundTransparency = 1,
                                
                                [Children] = {
                                    scope:New "UIListLayout" {
                                        FillDirection = Enum.FillDirection.Vertical,
                                        SortOrder = Enum.SortOrder.LayoutOrder,
                                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                        VerticalAlignment = Enum.VerticalAlignment.Center,
                                        Padding = UDim.new(0.05, 0)
                                    },

                                    scope:New "TextLabel" {
                                        Name = "RemainingVotes",
                                        Text = "Votes 1/1 Remaining",
                                        Size = UDim2.fromScale(0.8, 0.2),
                                        TextScaled = true,
                                        BackgroundTransparency = 1,
                                        TextColor3 = Color3.new(1, 1, 1),
                                        LayoutOrder = 1
                                    },

                                    BaseButton(scope, {
                                        name = "SubmitButton",
                                        text = "Submit Vote",
                                        textScaled = true,
                                        size = UDim2.fromScale(0.8, 0.1),
                                        backgroundColor = Color3.new(0.031373, 0.301961, 0),
                                        layoutOrder = 2,
                                        onClick = function()
                                            local selected = VotingGuiController.getSelectedOutfit()
                                            if selected then
                                                print("Submitting vote for:", selected)
                                                -- TODO: Call vote submission remote
                                                -- SubmitVote:FireServer(selected)
                                            else
                                                warn("No outfit selected for voting")
                                            end
                                        end
                                    }),

                                    BaseButton(scope, {
                                        name = "RefreshButton",
                                        text = "Refresh Outfits",
                                        textScaled = true,
                                        size = UDim2.fromScale(0.8, 0.08),
                                        backgroundColor = Color3.new(0.3, 0.3, 0.3),
                                        layoutOrder = 3,
                                        onClick = function()
                                            VotingGuiController.refreshOutfits()
                                        end
                                    })
                                }
                            }
                        }
                    },
                }
            },
        }
    }
    
    -- Initial load of outfits
    task.wait(0.1) -- Small delay to ensure everything is set up
    refreshOutfitVoteTiles()
end 

return VotingGuiController