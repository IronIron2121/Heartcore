--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Bindables = ReplicatedStorage:WaitForChild("Bindables")
local UI 		= ReplicatedStorage:WaitForChild("UI")
local Objects 	= UI:WaitForChild("Objects")

-- Modules
local UI_CONSTANTS = require(ReplicatedStorage.Utility.UI_CONSTANTS)

-- GUI Elements
local CategoryButtonTemplate = Objects:WaitForChild("CategoryButton")

-- Remotes / Bindables
local CategoryButtonClickedEvent = Bindables:WaitForChild("CategoryButtonClicked")

-- Constants
local UNSELECTED_BUTTON_COLOUR 	= Color3.new(0.360784, 0.376471, 0.839216)
local UNSELECTED_TEXT_COLOUR 	= Color3.new(1, 1, 1)
local SELECTED_BUTTON_COLOUR 	= Color3.new(1, 1, 1)
local SELECTED_TEXT_COLOUR		= Color3.new(0.360784, 0.376471, 0.839216)
local HOVER_COLOUR 				= Color3.new(0.243137, 0.25098, 0.560784)
local UNSELECTED_BACKGROUND_TRANSPARENCY 	= 1
local SELECTED_BACKGROUND_TRANSPARENCY 		= 0
local SELECTED_ATTRIBUTE = "Selected"

--

function CategoryButton(category : string)
	local categoryButton : TextButton = CategoryButtonTemplate:Clone()
	categoryButton.AutoButtonColor = false
	categoryButton.Name = category
	categoryButton.Text = category
	categoryButton.FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT,Enum.FontWeight.Regular)
	categoryButton.TextColor3 = Color3.new(1, 1, 1)
	categoryButton:SetAttribute(SELECTED_ATTRIBUTE, false)
	
	local function update()
		if categoryButton:GetAttribute("Selected") == true then
			categoryButton.TextColor3 = SELECTED_TEXT_COLOUR
			categoryButton.BackgroundColor3 = SELECTED_BUTTON_COLOUR
			categoryButton.BackgroundTransparency = SELECTED_BACKGROUND_TRANSPARENCY
		else
			categoryButton.TextColor3 = UNSELECTED_TEXT_COLOUR
			categoryButton.BackgroundColor3 = UNSELECTED_BUTTON_COLOUR
			categoryButton.BackgroundTransparency = UNSELECTED_BACKGROUND_TRANSPARENCY
		end
	end
	
	local function onActivated()
		if not categoryButton:GetAttribute(SELECTED_ATTRIBUTE) then
			categoryButton:SetAttribute(SELECTED_ATTRIBUTE, true)
			CategoryButtonClickedEvent:Fire(categoryButton)
			update()
		end
	end
	
	local function onHover()
		print("hover enter")
		categoryButton.BackgroundTransparency = 0
		categoryButton.BackgroundColor3 = HOVER_COLOUR
	end
	
	local function onLeave()
		update()
	end
	
	categoryButton.Activated:Connect(onActivated)
	categoryButton.MouseEnter:Connect(onHover)
	categoryButton.MouseLeave:Connect(onLeave)
	update()

	return {
		Button = CategoryButton,
		
		Select = function()
			categoryButton:SetAttribute(SELECTED_ATTRIBUTE, true)
			CategoryButtonClickedEvent:Fire(CategoryButton)
			update()
		end,

		Unselect = function()
			categoryButton:SetAttribute(SELECTED_ATTRIBUTE, false)
			update()
		end,

		IsSelected = function()
			return categoryButton:GetAttribute(SELECTED_ATTRIBUTE)
		end,

		GetText = function()
			return categoryButton.Text
		end,

		SetEnabled = function(enabled: boolean)
			categoryButton.Active = enabled
			categoryButton.Visible = enabled
		end,

		Destroy = function()
			categoryButton:Destroy()
		end
	}
end

return CategoryButton