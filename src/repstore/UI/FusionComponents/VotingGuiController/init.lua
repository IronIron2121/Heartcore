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
local DataTables = ReplicatedStorage:WaitForChild("DataTables")

-- Instances
local localPlayer = Players.LocalPlayer

-- GUI
local PlayerGui = localPlayer.PlayerGui
local OutfitVoteTile = require(script:WaitForChild("OutfitVoteTile"))

-- Modules
local SerialisationService = require(Utility:WaitForChild("SerialisationService"))
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))
local ImageUris = require(DataTables:WaitForChild("ImageUris"))
local Fusion = require(Utility:WaitForChild("Fusion"))

-- Fusion Modules
local scope = Fusion:scoped()
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>
local Value = Fusion.Value

-- GUI Modules
local BaseButton = require(Widgets:WaitForChild("BaseButton"))

-- Constants
local maxDisplayedOutfits = 3

-- Remotes / Bindables
local PlayerRequestedVotingTheme = Remotes:WaitForChild("PlayerRequestedVotingTheme")
local PlayerSubmittedVote = Remotes:WaitForChild("PlayerSubmittedVote")
local GetBalancedOutfit = Remotes:WaitForChild("GetBalancedOutfit")

local VotingGuiController = {}

local outfitVoteTiles = scope:Value({})
local isRefreshing = false
 


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
                warn("outfit == ", outfitData)
                print("outfit == ", outfitData)
                assert(outfitData.humanoid, "No humanoid description here!")
                warn("outfit == ", outfitData)
                print("outfit == ", outfitData)
                return
            end
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

local votingTheme = scope:Value("")

function VotingGuiController.Initialise(
    VoteGuiVisible: UsedAs<boolean>
)
    local visibilityObserver = scope:Observer(VoteGuiVisible)

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
                Visible = VoteGuiVisible,

                [Children] = {
                    scope:New "ImageButton" {
						Name = "CloseButton",
						Image = ImageUris["CloseButton"],
						AnchorPoint = Vector2.new(0.5, 0),
						Size = UDim2.fromScale(0.05, 0.05),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(1,0),
                        ZIndex = 3,
						
						[Children] = {
							scope:New "UIAspectRatioConstraint" {
								AspectRatio = 1
							}
						},
						
						[OnEvent "Activated"] = function()
							VoteGuiVisible:set(not peek(VoteGuiVisible))
						end,
					},

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
                        Size = UDim2.fromScale(1, 0.8),
                        BackgroundTransparency = 1,

                        [Children] = { 
                            scope:New "UIListLayout" {
                                FillDirection = Enum.FillDirection.Vertical,
                                SortOrder = Enum.SortOrder.LayoutOrder,
                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
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
                                        LayoutOrder = 0,
                                        BackgroundTransparency = 1,
                                        TextColor3 = Color3.fromRGB(92, 96, 214)
                                    },

                                    scope:New "TextLabel" {
                                        Name = "TodaysTheme",
                                        Text = votingTheme,--themeName,
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

                                        return index, OutfitVoteTile(scope, {
                                            Name = tileName,
                                            layoutOrder = index,
                                            userId = outfitData.userId,
                                            humanoidDescription = outfitData.humanoidDescription,
                                            playerName = outfitData.playerName,
                                            votes = outfitData.votes,
                                            views = outfitData.views,
                                            size = UDim2.fromScale(0.3, 0.9),
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

                                                    PlayerSubmittedVote:FireServer(outfitData.userId, viewIds)
                                                    VotingGuiController.refreshOutfits()
                                                else
                                                    warn("No outfitData user id!")
                                                end
                                            end}
                                        )
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