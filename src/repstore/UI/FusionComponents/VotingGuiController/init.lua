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
local SerialisationService = require(Utility:WaitForChild("SerialisationService"))

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
            warn("SUCCESSFULLY GOT AN OUTFIT")
            print(outfitData)
            -- Create the tile data that OutfitVoteTile expects
            newTiles[i] = {
                userId = outfitData.userId,  -- Use userId as the key
                humanoidDescription = SerialisationService.UnserialiseHumanoidDescription(outfitData.humanoidDescription),
                playerName = outfitData.playerName,
                votes = outfitData.votes or 0,
                views = outfitData.views or 0
            }
            successCount = successCount + 1
        else
            warn("Failed to get balanced outfit for slot " .. i .. ":", outfitData)
            -- Create a placeholder tile
            newTiles[i] = {
                userId = 0,  -- Placeholder user ID
                humanoidDescription = nil,
                playerName = "Loading...",
                votes = 0,
                views = 0
            }
        end
    end
    
    -- Update the tiles
    outfitVoteTiles:set(newTiles)
    
    print("Refreshed outfit tiles: " .. successCount .. "/" .. maxDisplayedOutfits .. " loaded successfully")
    warn(peek(outfitVoteTiles))
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
function VotingGuiController.setSelectedOutfit(tileName: string)
    selectedTileName:set(tileName)
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
                                    scope:New "UIListLayout" {
                                        FillDirection = Enum.FillDirection.Horizontal,
                                        SortOrder = Enum.SortOrder.LayoutOrder,
                                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                        VerticalAlignment = Enum.VerticalAlignment.Center,
                                        Padding = UDim.new(0, 10),
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
                                                return use(selectedTileName) == tileName
                                            end),
                                            onSelect = function()
                                                VotingGuiController.setSelectedOutfit(tileName)
                                                print(peek(selectedTileName))
                                                print(outfitData.humanoidDescription)
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
                                            local selectedUserId = VotingGuiController.getSelectedOutfit()
                                            if selectedUserId then
                                                print("Submitting vote for userId:", selectedUserId)
                                                -- TODO: Call vote submission remote
                                                -- SubmitVote:FireServer(selectedUserId)
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