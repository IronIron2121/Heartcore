--[[
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Folders
local DataTablesFolder = ReplicatedStorage:WaitForChild("DataTables")
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local BindablesFolder = ReplicatedStorage:WaitForChild("Bindables")
local TexturesFolder = ReplicatedStorage:WaitForChild("Textures")
local UtilityFolder = ReplicatedStorage:WaitForChild("Utility")
local GettersFolder = ReplicatedStorage:WaitForChild("Getters")

-- Instances
local localPlayer = Players.LocalPlayer

-- GUI Elements
local playerGui = localPlayer.PlayerGui
local ClaimedShopGui = playerGui:WaitForChild("ClaimedShopGui")
local RecolourFrame = ClaimedShopGui:WaitForChild("RecolourFrame")
local ColoursFrame = RecolourFrame:WaitForChild("ColoursFrame")
local TopBar = RecolourFrame:WaitForChild("TopBar")
local closeButton = TopBar:WaitForChild("CloseButton")

-- Module Scripts
local getFurnitureColours = require(GettersFolder:WaitForChild("getFurnitureColours"))
local ItemSelection = require(UtilityFolder:WaitForChild("ItemSelection"))
local ShopGuiFSM = require(UtilityFolder:WaitForChild("ShopGuiFSM"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))

-- Remotes / Bindables
local CloseColoursBindable = BindablesFolder:WaitForChild("CloseColours")
local InitialiseColours = BindablesFolder:WaitForChild("InitialiseColours")
local recolourFurniture = RemotesFolder:WaitForChild("recolourFurniture")

-- Constants
local TEXTBOX_BACKGROUND = Color3.new(0.305882, 0.52549, 1)
local TEXTBOX_SIZE = UDim2.new(0.2, 0, 0.05, 0)

local function populateColours()
	local selectedItem = ItemSelection.getSelectedItem()
	local furnitureColours = getFurnitureColours(selectedItem)
	if not furnitureColours then
		warn("No furniture colours for this item!")
	else
		print("Got colours!", furnitureColours)
	end

	for i, colour in pairs(furnitureColours) do
		local colourButton = Instance.new("TextButton")
		colourButton.Text = colour
		colourButton.BackgroundColor3 = TEXTBOX_BACKGROUND
		colourButton.Size = UDim2.new(1/#furnitureColours, 0, 0.1, 0) 
		colourButton.Parent = ColoursFrame

		colourButton.MouseButton1Click:Connect(function()
			recolourFurniture:FireServer(colour, selectedItem:GetAttribute(Constants.ITEM_ID_ATTRIBUTE))

		end)
	end
end

local function dePopulateColours()
	for i, colourButton in pairs(ColoursFrame:GetChildren()) do
		if colourButton:IsA("TextButton") then
			colourButton:Destroy()
		end
	end
end

local function initialise()
	dePopulateColours()
	populateColours()
end

local function onCloseButtonActivated()
	dePopulateColours()
	ShopGuiFSM.setState("HighlightedMannequin")
end

closeButton.Activated:Connect(onCloseButtonActivated)
CloseColoursBindable.Event:Connect(dePopulateColours)
InitialiseColours.Event:Connect(initialise)
]]