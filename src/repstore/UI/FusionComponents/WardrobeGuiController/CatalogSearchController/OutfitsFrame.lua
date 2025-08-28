--!strict
-- OutfitsFrame.lua
-- Services
local AvatarEditorService = game:GetService("AvatarEditorService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

-- local
local localPlayer = Players.LocalPlayer
local localChar = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local localHumanoid = localChar:WaitForChild("Humanoid") :: Humanoid

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local Widgets = FusionComponents:WaitForChild("Widgets")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local OutfitClientService = require(Utility:WaitForChild("OutfitClientService"))

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))
local OutfitTile = require(Widgets:WaitForChild("OutfitTile"))
local SerialisationService = require(Utility:WaitForChild("SerialisationService"))

-- Remotes
local PlayerEquippedOutfit = Remotes:WaitForChild("PlayerEquippedOutfit")
local GetPlayerTastemakerOutfits = Remotes:WaitForChild("GetPlayerTastemakerOutfits")

-- Fusion
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek
type UsedAs<T> = Fusion.UsedAs<T>

function OutfitsFrame(
	scope: Fusion.Scope,
	currentView: UsedAs<string>,
	props: {
		size: UsedAs<UDim2>?,
		position: UsedAs<UDim2>?,
		anchorPoint: UsedAs<Vector2>?,
		layoutOrder: UsedAs<number>?,
		backgroundTransparency: UsedAs<number>?,
	}?
): Frame
	local robloxOutfits = scope:Value({})
	local tastemakerOutfits = scope:Value({})
	local isLoading = scope:Value(false)
	local viewObserver = scope:Observer(currentView)
	local inventoryAccessGranted = scope:Value(false)
	
	local function updatePlayerOutfits()
		isLoading:set(true)
		warn("Updating player outfits!")
		-- Get outfits and filter for editable avatar outfits
		local success, outfits = pcall(function()
			return AvatarEditorService:GetOutfits()
		end)
		
		if success then
			local filteredOutfits = {}

			while true do
				for _, outfitPage in pairs(outfits:GetCurrentPage()) do
					if outfitPage["IsEditable"] and outfitPage["OutfitType"] == "Avatar" then
						table.insert(filteredOutfits, outfitPage)
					end
				end
				if outfits.IsFinished then
					break
				end
				outfits:AdvanceToNextPageAsync()
			end

			robloxOutfits:set(filteredOutfits)
		else
			robloxOutfits:set({})
		end
		
		-- Get Tastemaker Outfits
		local success, result = pcall(function()
			return GetPlayerTastemakerOutfits:InvokeServer()
		end) 

		if success and result then
			tastemakerOutfits:set(result)
		elseif success and not result then
			warn("Successful query but no outfits")
		else
			assert("Error on attempt to get tastemaker outfits!")
		end
		isLoading:set(false)
	end
	
	viewObserver:onChange(function()
		if peek(currentView) == "Outfits" then
			isLoading:set(true)

			if not peek(inventoryAccessGranted) then
				AvatarEditorService:PromptAllowInventoryReadAccess()
				local isAccessGranted = AvatarEditorService.PromptAllowInventoryReadAccessCompleted:Wait()
				
				if isAccessGranted then
					inventoryAccessGranted:set(true)
				else
					inventoryAccessGranted:set(false)
					return
				end
			else
				print("Access already granted")
			end
			
			updatePlayerOutfits()
			
			isLoading:set(false)
		else
			print("Outfits frame is not visible")
		end
	end)

	local outfitsFrame = scope:New "Frame" {
		Name = "OutfitsFrame",
		Visible = scope:Computed(function(use)
			return use(currentView) == "Outfits"			
		end),

		Size = (props and props.size) or UDim2.fromScale(1, 1),
		Position = (props and props.position) or UDim2.fromScale(0.5, 0.5),
		AnchorPoint = (props and props.anchorPoint) or Vector2.new(0.5, 0.5),
		LayoutOrder = (props and props.layoutOrder) or 3,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = (props and props.backgroundTransparency) or UI_CONSTANTS.TRANSPARENCY_TRANSLUCENT,

		[Children] = {
			scope:New "UIListLayout" {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Top,
				Padding = UDim.new(0, 10)
			},
			
			scope:New "UICorner" {
				CornerRadius = UDim.new(0.05, 0)
			},

			scope:New "ScrollingFrame" {
				Name = "CategoryScrollFrame",
				Size = UDim2.fromScale(1, 0.9),
				Position = UDim2.fromScale(0, 0),
				BackgroundTransparency = 1,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.fromScale(0, 0),
				ScrollingDirection = Enum.ScrollingDirection.Y,
				ScrollBarThickness = 4,
				LayoutOrder = 2,

				[Children] = {
					scope:New "UIListLayout" {
						FillDirection = Enum.FillDirection.Horizontal,
						Wraps = true,
						SortOrder = Enum.SortOrder.LayoutOrder,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Top,
						Padding = UDim.new(0, 10)
					},

					-- Loading indicator
					scope:New "TextLabel" {
						Name = "LoadingLabel",
						Size = UDim2.fromScale(1, 0.1),
						BackgroundTransparency = 1,
						Text = "Loading outfits...",
						TextColor3 = UI_CONSTANTS.COLOUR_BLACK,
						TextScaled = true,
						Font = Enum.Font.Gotham,
						LayoutOrder = 1,
						Visible = scope:Computed(function(use)
							return use(isLoading)
						end)
					},

					-- Empty state message
					scope:New "TextLabel" {
						Name = "EmptyStateLabel",
						Size = UDim2.fromScale(1, 0.2),
						BackgroundTransparency = 1,
						Text = "No outfits found. Create some outfits to see them here!",
						TextColor3 = UI_CONSTANTS.COLOUR_BLACK,
						TextScaled = true,
						Font = Enum.Font.Gotham,
						LayoutOrder = 2,
						Visible = scope:Computed(function(use)
							return not use(isLoading) and #use(robloxOutfits) == 0
						end)
					},
					
					scope:ForValues(robloxOutfits, function(use, innerScope, outfit)
						local humanoidDescription = Players:GetHumanoidDescriptionFromOutfitId(outfit.Id)
						return OutfitTile(innerScope, {
							humanoidDescription = humanoidDescription,
							outfit = outfit,
							onDelete = function()
								OutfitClientService.DeleteOutfit(outfit.Id)
								updatePlayerOutfits()
							end,
							onSelect = function()
								PlayerEquippedOutfit:FireServer(props.outfit.Id)
							end,
							
							visible = scope:Computed(function(use)
								return use(isLoading) == false
							end)
						})
					end),
					
					scope:ForValues(tastemakerOutfits, function(use, innerScope, serialisedOutfit)
						local humanoidDescription = SerialisationService.UnserialiseHumanoidDescription(serialisedOutfit)
						
						return OutfitTile(innerScope, {
							humanoidDescription = humanoidDescription,
							outfit = outfit,
							onDelete = function()
								OutfitClientService.DeleteOutfit(outfit.Id)
								updatePlayerOutfits()
							end,
							
							onSelect = function()
								print("About to invoke server...")
								
								--TODO: This is a problem for tomorrow!
								PlayerEquippedOutfit:FireServer(props.outfit.Id)
							end,

							visible = scope:Computed(function(use)
								return use(isLoading) == false
							end)
						})
					end),
					
				} 
			},

			scope:New "Frame" {
				Name = "TopBar",
				Size = UDim2.fromScale(1, 0.1),
				BackgroundTransparency = 1,
				BackgroundColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
				LayoutOrder = 1,
				[Children] = {
					scope:New "TextButton" {
						Name = "CatalogButton",
						Size = UDim2.fromScale(0.2, 0.5),
						BackgroundColor3 = UI_CONSTANTS.COLOUR_WHITE,
						Text = "Shop the catalog",
						TextColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
						TextScaled = true,
						Font = Enum.Font.Gotham,

						[OnEvent "Activated"] = function()
							currentView:set("Catalog")
						end,

						[Children] = {
							scope:New "UICorner" {
								CornerRadius = UDim.new(0.1, 0)
							},

							scope:New "UIStroke" {
								ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
								Color = UI_CONSTANTS.TASTEMAKER_PURPLE,
								Thickness = 1,
							},
						}
					},

					scope:New "UIListLayout" {
						Padding = UDim.new(0.02, 0),
						FillDirection = Enum.FillDirection.Horizontal,
						SortOrder = Enum.SortOrder.LayoutOrder,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Center,
					},

					scope:New "Frame" {
						Name = "Filler",
						Size = UDim2.fromScale(0.7, 0.1),
						BackgroundTransparency = 1,
						LayoutOrder = 2
					}
				}
			}
		}
	} :: Frame

	return outfitsFrame
end

return OutfitsFrame