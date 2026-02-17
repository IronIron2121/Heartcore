--!strict
-- OutfitsFrame.lua
-- Services
local AvatarEditorService = game:GetService("AvatarEditorService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- local
local localPlayer = Players.LocalPlayer
local localChar = localPlayer.Character or localPlayer.CharacterAdded:Wait()

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local Widgets = FusionComponents:WaitForChild("Widgets")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ClientOutfitService = require(Utility:WaitForChild("ClientOutfitService"))

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))
local OutfitTile = require(Widgets:WaitForChild("OutfitTile"))
local SerialisationService = require(Utility:WaitForChild("SerialisationService"))
local BaseButton = require(Widgets:WaitForChild("BaseButton"))
local GuiManager = require(ReplicatedStorage.Libraries.GuiManager.GuiManager)

-- Widgets
local LoadingScreenManager = require(ReplicatedStorage.Libraries.LoadingScreenManager)

-- Remotes
local PlayerEquippedOutfit = Remotes:WaitForChild("PlayerEquippedOutfit")
local PlayerEquippedTastemakerOutfit = Remotes:WaitForChild("PlayerEquippedTastemakerOutfit")
local GetPlayerTastemakerOutfits = Remotes:WaitForChild("GetPlayerTastemakerOutfits")

-- Fusion
local Children = Fusion.Children
local peek = Fusion.peek
type UsedAs<T> = Fusion.UsedAs<T>
type Value<T> = Fusion.Value<T>

function OutfitsFrame(
	scope: Fusion.Scope,
	props: {
		currentView: Value<string>,
		size: UsedAs<UDim2>?,
		position: UsedAs<UDim2>?,
		anchorPoint: UsedAs<Vector2>?,
		layoutOrder: UsedAs<number>?,
		backgroundTransparency: UsedAs<number>?,
	}
): Frame
	local robloxOutfits = scope:Value({})
	local tastemakerOutfits = scope:Value({})
	local isLoading = scope:Value(false)
	local viewObserver = scope:Observer(props.currentView)
	local inventoryAccessGranted = scope:Value(false)
	
	local function updatePlayerOutfits()
		if not (peek(props.currentView) == "Outfits") then
			return
		end

		isLoading:set(true)

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
		local tastemakerSuccess, result = pcall(function()
			return GetPlayerTastemakerOutfits:InvokeServer()
		end) 

		if tastemakerSuccess and result then
			tastemakerOutfits:set(result)
		elseif tastemakerSuccess and not result then
			warn("Successful query but no outfits")
		elseif not tastemakerSuccess then
			warn("Error on attempt to get tastemaker outfits!")
		end
		isLoading:set(false)
	end
	
	viewObserver:onChange(function()
		if peek(props.currentView) == "Outfits" then
			isLoading:set(true)

			if not peek(inventoryAccessGranted) then
				AvatarEditorService:PromptAllowInventoryReadAccess()
				local isAccessGranted = AvatarEditorService.PromptAllowInventoryReadAccessCompleted:Wait()
				
				if isAccessGranted == Enum.AvatarPromptResult.Success then
					inventoryAccessGranted:set(true)
				else
					inventoryAccessGranted:set(false)
					props.currentView:set("Catalog")
					return
				end
			end
			
			updatePlayerOutfits()
			isLoading:set(false)
		end
	end)

	local outfitsFrame = scope:New "Frame" {
		Name = "OutfitsFrame",
		Visible = scope:Computed(function(use)
			return use(props.currentView) == "Outfits"			
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
				Padding = UDim.new(0.01, 0)
			},
			
			scope:New "UICorner" {
				CornerRadius = UDim.new(0.05, 0)
			},

			scope:New "ScrollingFrame" {
				Name = "OutfitScrollFrame",
				Size = UDim2.fromScale(1, 0.89),
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

					scope:New "UIPadding" {
						PaddingTop = UDim.new(0.02,0),
						PaddingBottom = UDim.new(0.02,0),
						PaddingLeft = UDim.new(0.02,0),
						PaddingRight = UDim.new(0.02,0),			
					},

					scope:New "Frame" {
						Name = "buffer",
						Size = UDim2.fromScale(1,0.1),
						BackgroundTransparency = 1,
						LayoutOrder = 10
					},

					-- Empty state message
					scope:New "TextLabel" {
						Name = "EmptyStateLabel",
						Size = UDim2.fromScale(1, 0.2),
						BackgroundTransparency = 1,
						Text = "No outfits found. Create some outfits to see them here!",
						TextColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
						TextScaled = true,
						FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT,Enum.FontWeight.Bold),
						LayoutOrder = 2,
						Visible = scope:Computed(function(use)
							return not use(isLoading) and #use(robloxOutfits) == 0 and #use(tastemakerOutfits) == 0
						end) 
					},
					
					scope:ForValues(robloxOutfits, function(use, innerScope, outfit)
						local humanoidDescription = Players:GetHumanoidDescriptionFromOutfitId(outfit.Id)
						return OutfitTile(innerScope, {
							humanoidDescription = humanoidDescription,
							outfit = outfit,
							onDelete = function()
								ClientOutfitService.DeleteOutfit(outfit.Id)
								updatePlayerOutfits()
							end,
							onSelect = function()
								PlayerEquippedOutfit:FireServer(outfit.Id)
							end,
							visible = scope:Computed(function(use)
								return use(isLoading) == false
							end)
						})
					end),
					
					scope:ForPairs(tastemakerOutfits, function(use, innerScope, index, serialisedOutfit)
						local humanoidDescription = SerialisationService.UnserialiseHumanoidDescription(serialisedOutfit)
						
						return index, OutfitTile(innerScope, {
							humanoidDescription = humanoidDescription,
							outfit = serialisedOutfit,
							onDelete = function()
								GuiManager.PushNotificationCentre(
											"DeleteTastemakerOutfit",
											"Are you sure you want to delete this outfit?",
											function()  
												ClientOutfitService.DeleteTastemakerOutfit(index)
												updatePlayerOutfits()
											end
										)
							end,
							
							onSelect = function()
								print("About to invoke server...")
								local equipped = PlayerEquippedTastemakerOutfit:FireServer(serialisedOutfit)
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
					BaseButton(scope, {
						name = "Catalog",
						text = "Back to shopping",
						textScaled = true,
						size = UDim2.fromScale(0.2, 0.5),
						backgroundColor = UI_CONSTANTS.TASTEMAKER_PURPLE,
						strokeColor = Color3.new(1,1,1),
						strokeThickness = 3,
						textColor = Color3.new(1,1,1),

						onActivated = function()
							props.currentView:set("Catalog")
						end,
					}
				),

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

	-- Show/hide loading screen via manager
	scope:Observer(isLoading):onChange(function()
		if peek(isLoading) then
			LoadingScreenManager.show(outfitsFrame)
		else
			LoadingScreenManager.hide(outfitsFrame)
		end
	end)

	return outfitsFrame, updatePlayerOutfits
end

return OutfitsFrame