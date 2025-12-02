--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")


-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local DataTables = ReplicatedStorage:WaitForChild("DataTables")
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local Widgets = FusionComponents:WaitForChild("Widgets")
local ImageUris = require(DataTables:WaitForChild("ImageUris"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Modules
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))

-- UI Components
local CloseButton   = require(Widgets:WaitForChild("CloseButton"))
local ChallengeCard = require(Widgets:WaitForChild("ChallengeCard"))

--Instances
local centralPond = workspace:WaitForChild("centralPond")
local pondModel = centralPond:WaitForChild("centralPond")
local SubmissionBillboardHolder = pondModel:WaitForChild("SubmissionBillboardHolder")
local BillboardGui = SubmissionBillboardHolder:WaitForChild("BillboardGui")
local Frame = BillboardGui:WaitForChild("Frame")
local TimeLabel = Frame:WaitForChild("TimeLabel")

-- Fusion
local Fusion = require(Utility:WaitForChild("Fusion"))
local peek = Fusion.peek
local scope = Fusion:scoped()

type UsedAs<T> = Fusion.UsedAs<T> 
local Children = Fusion.Children
type Value<T> = Fusion.Value<T>

local TimeText = scope:Value("Loading...")

-- RemoteEvents
local UpdateChallengeProgress = Remotes:WaitForChild("UpdateChallengeProgress")
local ClaimChallengeReward = Remotes:WaitForChild("ClaimChallengeReward")
local GetActiveChallenges = Remotes:WaitForChild("GetActiveChallenges")


local function updateTimeText(newText: string)
    TimeText:set(newText)
end

task.spawn(function()
        while true do
            task.wait(1)
            updateTimeText(TimeLabel.Text)
        end
    end)

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
        warn("updating challenges locally")
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
                size = UDim2.fromScale(0.13, 0.13),
                anchorPoint = Vector2.new(0.5, 0.5),
                position = UDim2.fromScale(1, 0),

                onClick = function()
                    props.visible:set(not peek(props.visible)) 
                end
            }),

            scope:New "TextLabel" {
                Name = "ChallengesLabel",
                Size = UDim2.fromScale(0.3, 0.1),
                AnchorPoint = Vector2.new(0.5,0.5),
                Position = UDim2.fromScale(0.5, 0),
                BackgroundColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
                BackgroundTransparency = 0,
                Text = "DAILY MISSIONS",
                TextScaled = true,
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

                    scope:New "UIPadding" {
                        PaddingTop = UDim.new(0.02,0),
                        PaddingBottom = UDim.new(0.02,0),
                        PaddingLeft = UDim.new(0.05,0),
                        PaddingRight = UDim.new(0.05,0),
                    }
                }
            },

            scope:New "UICorner" {
                CornerRadius = UDim.new(0, 30)
            },

            scope:New "ScrollingFrame" {
                Name = "ChallengesFrame",
                Size = UDim2.fromScale(1,1),
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