--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Instances
local localPlayer = Players.LocalPlayer

-- GUI
local PlayerGui = localPlayer.PlayerGui

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))

-- Fusion Modules
local scope = Fusion:scoped()
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

-- Constants
local maxDisplayedOutfits = 6

--

local VotingGuiController = {}

function VotingGuiController.Initialise(visibilityBoolean: UsedAs<boolean>)
	local _VoteGui = scope:New "ScreenGui" {
		Name = "VotingGui",
        Enabled = visibilityBoolean,
        Parent = PlayerGui,

        [Children] = {
            scope:New "Frame" {
				Name = "Container",
                Size = UDim2.fromScale(0.8, 0.9),
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 1),
				BackgroundTransparency = 1,

				[Children] = {	

					scope:New "UIListLayout" {
						FillDirection = Enum.FillDirection.Vertical,
						SortOrder = Enum.SortOrder.LayoutOrder

					},

					scope:New "Frame"{
						Name = "TopBar",
						Size = UDim2.fromScale(1, 0.1),
						LayoutOrder = 1,

						[Children] = {
							scope:New "UIListLayout" {
								FillDirection = Enum.FillDirection.Horizontal,
								SortOrder = Enum.SortOrder.LayoutOrder
							},

							scope:New "TextLabel" {
								Name = "TodaysTheme",
								Text = "TODAY'S THEME",
								TextScaled = true,
								Size = UDim2.fromScale(0.3, 1),
								LayoutOrder = 1

							},

							scope:New "Frame"{
								Name = "Buffer",
								Size = UDim2.fromScale(0.2, 1),
								LayoutOrder = 2
							},

							scope:New "TextLabel" {
								Name = "Timer",
								Text = "VOTING ENDS: HH:MM:SS",
								TextScaled = true,
								Size = UDim2.fromScale(0.3, 1),
								LayoutOrder = 3
							}

						}

					},

					scope:New "Frame" {
						Name = "Body",
						LayoutOrder = 2,
						Size = UDim2.fromScale(1, 0.8),
						BackgroundColor3 = Color3.new(0.1, 0.5, 0.9),

						[Children] = { 
							scope:New "UIListLayout" {
								FillDirection = Enum.FillDirection.Horizontal,
								SortOrder = Enum.SortOrder.LayoutOrder,
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
							},
							
							scope:New "Frame" {
								Name = "Buffer",
								Size = UDim2.fromScale(0.3, 1),
								LayoutOrder = 1
							},

							scope:New "Frame" {
								Name = "OutfitsContainer",
								BackgroundColor3 = Color3.new(0.1,0.2,0.9),
								Size = UDim2.fromScale(0.4, 1),
								LayoutOrder = 2,

								[Children] = {
									scope:New "UIGridLayout" {
										FillDirection = Enum.FillDirection.Horizontal,
										FillDirectionMaxCells = maxDisplayedOutfits/2,
										SortOrder = Enum.SortOrder.LayoutOrder,
										StartCorner = Enum.StartCorner.TopLeft,
										HorizontalAlignment = Enum.HorizontalAlignment.Left,
										VerticalAlignment = Enum.VerticalAlignment.Top,
										CellSize = UDim2.fromScale(1/maxDisplayedOutfits, 1/maxDisplayedOutfits),
										CellPadding = UDim2.fromOffset(10, 10)
									},

									-- all of the outfits to vote on go here.
								}


							},

							scope:New "Frame" {
								Name = "SubmitFrame",
								Size = UDim2.fromScale(0.3, 1),
								LayoutOrder = 3,
								[Children] = {
									scope:New "UIListLayout" {
										FillDirection = Enum.FillDirection.Vertical,
										SortOrder = Enum.SortOrder.LayoutOrder,
										HorizontalAlignment = Enum.HorizontalAlignment.Center,
										VerticalAlignment = Enum.VerticalAlignment.Center
									},

									scope:New "TextLabel" {
										Name = "RemainingVotes",
										Text = "Votes 2/2 Remaining",
										Size = UDim2.fromScale(0.8, 0.2),
										TextScaled = true,
									},

									scope:New "TextButton" {
										Name = "SubmitButton",
										Text = "Submit Votes",
										TextScaled = true,
										Size = UDim2.fromScale(0.8, 0.1),
										BackgroundColor3 = Color3.new(0.031373, 0.301961, 0),

										[Children] = {
											scope:New "UICorner" {
												CornerRadius = UDim.new(0.2, 0)
											}
										}

									}
								}
							}
						}
					},
				}
            },
        }
    }
end 

return VotingGuiController 
