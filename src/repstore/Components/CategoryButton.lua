--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local DataTablesFolder = ReplicatedStorage:WaitForChild("DataTables")
local Bindables = ReplicatedStorage:WaitForChild("Bindables")
local UI = ReplicatedStorage:WaitForChild("UI")
local Objects = UI:WaitForChild("Objects")

-- Modules
local ShopItemStoreCategories 	= require(DataTablesFolder:WaitForChild("ShopItemStoreCategories"))

-- GUI Elements
local CategoryButtonTemplate = Objects:WaitForChild("CategoryButton")

-- Remotes / Bindables
local CategoryButtonClickedEvent = Bindables:WaitForChild("CategoryButtonClicked")

-- Constants
local DEFAULT_SELECT 			= ShopItemStoreCategories[1]
local UNSELECTED_BUTTON_COLOUR 	= Color3.new(0.360784, 0.376471, 0.839216)
local UNSELECTED_TEXT_COLOUR 	= Color3.new(1, 1, 1)
local SELECTED_BUTTON_COLOUR 	= Color3.new(1, 1, 1)
local SELECTED_TEXT_COLOUR		= Color3.new(0.360784, 0.376471, 0.839216)
local HOVER_COLOUR 				= Color3.new(0.243137, 0.25098, 0.560784)
local UNSELECTED_BACKGROUND_TRANSPARENCY 	= 1
local SELECTED_BACKGROUND_TRANSPARENCY 		= 0
local SELECTED_ATTRIBUTE = "Selected"


function CategoryButton(category : string)
	local CategoryButton : TextButton = CategoryButtonTemplate:Clone()
	CategoryButton.AutoButtonColor = false
	CategoryButton.Name = category
	CategoryButton.Text = category
	CategoryButton.TextColor3 = Color3.new(1, 1, 1)
	CategoryButton:SetAttribute(SELECTED_ATTRIBUTE, false)
	
	local function update()
		if CategoryButton:GetAttribute("Selected") == true then
			CategoryButton.TextColor3 = SELECTED_TEXT_COLOUR
			CategoryButton.BackgroundColor3 = SELECTED_BUTTON_COLOUR
			CategoryButton.BackgroundTransparency = SELECTED_BACKGROUND_TRANSPARENCY
						
		else
			CategoryButton.TextColor3 = UNSELECTED_TEXT_COLOUR
			CategoryButton.BackgroundColor3 = UNSELECTED_BUTTON_COLOUR
			CategoryButton.BackgroundTransparency = UNSELECTED_BACKGROUND_TRANSPARENCY
		end
	end
	
	local function onActivated()
		if not CategoryButton:GetAttribute(SELECTED_ATTRIBUTE) then
			CategoryButton:SetAttribute(SELECTED_ATTRIBUTE, true)
			CategoryButtonClickedEvent:Fire(CategoryButton)
			update()
		end
	end
	
	local function getHoverColour()
		return CategoryButton.BackgroundColor3:Lerp(Color3.new(1, 1, 1), 0.2)
	end
	
	local function onHover()
		print("hover enter")
		CategoryButton.BackgroundTransparency = 0
		CategoryButton.BackgroundColor3 = HOVER_COLOUR
	end
	
	local function onLeave()
		update()
	end
	
	CategoryButton.Activated:Connect(onActivated)
	CategoryButton.MouseEnter:Connect(onHover)
	CategoryButton.MouseLeave:Connect(onLeave)
	update()

	return {
		Button = CategoryButton,
		
		Select = function()
			CategoryButton:SetAttribute(SELECTED_ATTRIBUTE, true)
			CategoryButtonClickedEvent:Fire(CategoryButton)
			update()
		end,

		Unselect = function()
			CategoryButton:SetAttribute(SELECTED_ATTRIBUTE, false)
			update()
		end,

		IsSelected = function()
			return CategoryButton:GetAttribute(SELECTED_ATTRIBUTE)
		end,

		GetText = function()
			return CategoryButton.Text
		end,

		SetEnabled = function(enabled: boolean)
			CategoryButton.Active = enabled
			CategoryButton.Visible = enabled
		end,

		Destroy = function()
			CategoryButton:Destroy()
		end
	}
end

return CategoryButton