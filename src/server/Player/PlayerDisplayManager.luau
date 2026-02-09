--!strict

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Data = ServerScriptService:WaitForChild("Data")
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local DataManager = require(Data.DataManager)
local UI_CONSTANTS = require(Utility.UI_CONSTANTS)

-- Constants
local TEXT_LABEL_SIZE = UDim2.fromScale(1, 0.5)
local BILLBOARD_GUI_NAME = "PlayerDisplayBillboard"
local NAME_LABEL_NAME = "PlayerNameLabel"
local RANK_LABEL_NAME = "PlayerRankLabel"

--

local PlayerDisplayManager = {}

function PlayerDisplayManager.RemoveRankDisplayFromCharacter(character: Player)

end

function PlayerDisplayManager.AddRankDisplayToCharacter(player: Player, character: Model?)
    character = character or player.Character or player.CharacterAdded:Wait()
    if not character then return end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end -- xD

    local BillboardGui = Instance.new("BillboardGui", character)
    BillboardGui.Name = BILLBOARD_GUI_NAME
    BillboardGui.Adornee = humanoidRootPart
    BillboardGui.Size = UDim2.fromScale(3, 1)
    BillboardGui.SizeOffset = Vector2.new(0, 3.5)
    BillboardGui.AlwaysOnTop = true

    local uiListLayout = Instance.new("UIListLayout", BillboardGui)
    uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uiListLayout.FillDirection = Enum.FillDirection.Vertical

    -- Add label to display player rank
    local playerRank = DataManager.GetRankName(player)
    local RankLabel = Instance.new("TextLabel", BillboardGui)
    RankLabel.Name = RANK_LABEL_NAME
    RankLabel.Text = playerRank
    RankLabel.TextColor3 = Color3.new(1,1,1)
    RankLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    RankLabel.TextStrokeTransparency = 0    
    RankLabel.TextScaled = true
    RankLabel.BackgroundTransparency = 1
    RankLabel.LayoutOrder = 1
    RankLabel.FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Bold)
    RankLabel.Size = TEXT_LABEL_SIZE

    -- Add label to display player level and name
    local playerLevel = DataManager.GetLevel(player)
    local NameLabel = Instance.new("TextLabel", BillboardGui)
    NameLabel.Name = NAME_LABEL_NAME
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
    local character = player.Character or player.CharacterAdded:Wait()
    local Head = character:WaitForChild("Head")
    local PlayerBillboard = Head:FindFirstChild(BILLBOARD_GUI_NAME)
    if not PlayerBillboard then return end
    
    local NameLabel = PlayerBillboard:FindFirstChild(NAME_LABEL_NAME) :: TextLabel
    if not NameLabel then return end

    local newLevel = DataManager.GetLevel(player)
    NameLabel.Text = player.Name .. " (Lv. " .. newLevel .. ")"
end

function PlayerDisplayManager.UpdateRankDisplay(player: Player)
    local character = player.Character or player.CharacterAdded:Wait()
    local Head = character:WaitForChild("Head")
    local PlayerBillboard = Head:FindFirstChild(BILLBOARD_GUI_NAME)
    if not PlayerBillboard then return end
    
    local RankLabel = PlayerBillboard:FindFirstChild(RANK_LABEL_NAME) :: TextLabel
    if not RankLabel then return end

    local newRank = DataManager.GetRankName(player)
    RankLabel.Text = newRank
end

function PlayerDisplayManager.UpdatePlayerDisplay(player: Player)
    PlayerDisplayManager.UpdateRankDisplay(player)
    PlayerDisplayManager.UpdateLevelDisplay(player)
end

return PlayerDisplayManager