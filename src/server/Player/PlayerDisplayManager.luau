--!strict

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Data = ServerScriptService:WaitForChild("Data")
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local nameOf = require(ReplicatedStorage.Utility.Fusion.Utility.nameOf)
local DataManager = require(Data.DataManager)
local UI_CONSTANTS = require(Utility.UI_CONSTANTS)

-- Constants
local TEXT_LABEL_SIZE = UDim2.fromScale(1, 0.5)

--

local PlayerDisplayManager = {}

function PlayerDisplayManager.RemoveRankDisplayFromCharacter(character: Player)

end

function PlayerDisplayManager.AddRankDisplayToCharacter(player: Player, character: Model?)
    character = character or player.Character or player.CharacterAdded:Wait()

    if not character then return end

    local Head = character:FindFirstChild("Head")
    if not Head then 
        return 
    end

    local BillboardGui = Instance.new("BillboardGui", Head)
    BillboardGui.Name = "RankBillboard"
    BillboardGui.Adornee = Head
    BillboardGui.Size = UDim2.fromScale(3, 1)
    BillboardGui.SizeOffset = Vector2.new(0, 1.5)
    BillboardGui.AlwaysOnTop = true

    local uiListLayout = Instance.new("UIListLayout", BillboardGui)
    uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uiListLayout.FillDirection = Enum.FillDirection.Vertical

    -- Add label to display player rank
    local playerRank = DataManager.GetRankName(player)
    local RankLabel = Instance.new("TextLabel", BillboardGui)
    RankLabel.Text = playerRank
    RankLabel.TextColor3 = Color3.new(1,1,1)
    RankLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    RankLabel.TextStrokeTransparency = 0    
    RankLabel.TextScaled = true
    RankLabel.BackgroundTransparency = 1
    RankLabel.LayoutOrder = 1
    RankLabel.FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT,Enum.FontWeight.Bold)
    RankLabel.Size = TEXT_LABEL_SIZE

    -- Add label to display player level and name
    local playerLevel = DataManager.GetLevel(player)
    local NameLabel = Instance.new("TextLabel", BillboardGui)
    NameLabel.Text = player.Name .. " (Lv. " .. playerLevel .. ")"
    NameLabel.TextColor3 = Color3.new(1, 1, 1)
    NameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    NameLabel.TextStrokeTransparency = 0
    NameLabel.TextScaled = true
    NameLabel.BackgroundTransparency = 1
    NameLabel.LayoutOrder = 2
    NameLabel.FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT,Enum.FontWeight.Bold)
    NameLabel.Size = TEXT_LABEL_SIZE

end

function PlayerDisplayManager.UpdateLevelDisplay(player: Player)

end

function PlayerDisplayManager.UpdateRankDisplay(player: Player)

end

function PlayerDisplayManager.OnCharacterAdded()

end




return PlayerDisplayManager