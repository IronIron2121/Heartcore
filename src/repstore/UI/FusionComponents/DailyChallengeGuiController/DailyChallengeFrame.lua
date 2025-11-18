--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Remotes           = ReplicatedStorage:WaitForChild("Remotes")
local Utility           = ReplicatedStorage:WaitForChild("Utility")
local UI                = ReplicatedStorage:WaitForChild("UI")
local FusionComponents  = UI:WaitForChild("FusionComponents")
local Widgets           = FusionComponents:WaitForChild("Widgets")

-- Modules
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))

-- UI Components
local CloseButton   = require(Widgets:WaitForChild("CloseButton"))
local ChallengeCard = require(Widgets:WaitForChild("ChallengeCard"))

-- Fusion
local Fusion    = require(Utility:WaitForChild("Fusion"))
local Children  = Fusion.Children
local peek      = Fusion.peek
type UsedAs<T>  = Fusion.UsedAs<T>
type Value<T>   = Fusion.Value<T>

-- RemoteEvents
local UpdateChallengeProgress = Remotes:WaitForChild("UpdateChallengeProgress")
local ClaimChallengeReward = Remotes:WaitForChild("ClaimChallengeReward")
local GetActiveChallenges = Remotes:WaitForChild("GetActiveChallenges")

local function DailyChallengeFrame(
    scope: Fusion.Scope,
    props: {
        visible: Value<boolean>
    }
): Frame
    -- Fetch challenges from server
    local challenges = Fusion.Value(scope, {})
    
    -- Load challenges on open
    local function loadChallenges()
        task.wait(5)
        local activeChallenges = GetActiveChallenges:InvokeServer()
        challenges:set(activeChallenges or {})
    end

    -- Listen for challenge updates
    UpdateChallengeProgress.OnClientEvent:Connect(function(update)
        local currentChallenges = peek(challenges)
        for i, challenge in ipairs(currentChallenges) do
            if challenge.id == update.id then
                challenge.progress = update.progress
                challenge.claimed = update.claimed
                challenges:set(currentChallenges) -- Trigger update
                break
            end
        end
    end)

    -- Load challenges initially
    task.spawn(loadChallenges)
    
    local DailyChallengeFrame = scope:New "Frame" {
        Name = "DailyChallengeFrame",
        BackgroundTransparency = UI_CONSTANTS.TRANSPARENCY_TRANSLUCENT,
        Size = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Visible = props.visible,


        [Children] = {
            CloseButton(scope, {
                size = UDim2.fromScale(0.1, 0.1),
                anchorPoint = Vector2.new(0.5, 0.5),
                position = UDim2.fromScale(1, 0),
                visibilityBoolean = props.visible
            }),

            scope:New "TextLabel" {
                Name = "ChallengesLabel",
                Size = UDim2.fromScale(0.25, 0.1),
                AnchorPoint = Vector2.new(0.5,0.5),
                Position = UDim2.fromScale(0.5, 0),
                BackgroundColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
                BackgroundTransparency = 0,
                Text = "DAILY CHALLENGES",
                TextSize = 20,
                TextColor3 = UI_CONSTANTS.COLOUR_WHITE,
                FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Bold, Enum.FontStyle.Normal),

                [Children] = {
                    scope:New "UICorner" {
                        CornerRadius = UDim.new(0, 10),
                    },

                    scope:New "UIStroke" {
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                        Thickness = 3,
                        Color = UI_CONSTANTS.COLOUR_WHITE
                    },
                }
            },

            scope:New "UICorner" {
                CornerRadius = UDim.new(0, 30)
            },

            scope:New "ScrollingFrame" {
                Name = "ChallengesFrame",
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                ScrollingDirection = Enum.ScrollingDirection.X,
                AutomaticCanvasSize = Enum.AutomaticSize.XY,
                ScrollingEnabled = true,
            
                [Children] = {
                    scope:New "UIListLayout" {
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Left,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = UDim.new(0, 10),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    },
                    
                    -- Dynamically create cards based on challenges
                    scope:ForValues(challenges, function(use, scope, challenge)
                        local def = challenge.definition
                        local isCompleted = challenge.progress >= challenge.target
                        local canClaim = isCompleted and not challenge.claimed
                        
                        return ChallengeCard(scope, {
                            layoutOrder = index,
                            description = def.description,
                            progress = string.format("%d/%d", challenge.progress, challenge.target),
                            reward = tostring(def.reward.exp),
                            isClaimed = challenge.claimed,
                            onClaim = function()
                                if canClaim then
                                    local success = ClaimChallengeReward:InvokeServer(challenge.id)
                                    if success then
                                        print("Claimed reward for:", challenge.id)
                                        loadChallenges() -- Refresh
                                    else
                                        warn("Failed to claim reward")
                                    end
                                end
                            end
                        })
                    end)
                }
            }
        }
    } :: Frame

    return DailyChallengeFrame
end

return DailyChallengeFrame