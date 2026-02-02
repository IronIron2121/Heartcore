--!strict
-- VotingFrame.lua

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

-- Folders
local Utility           = ReplicatedStorage:WaitForChild("Utility")
local Remotes           = ReplicatedStorage:WaitForChild("Remotes")
local UI                = ReplicatedStorage:WaitForChild("UI")
local FusionComponents  = UI:WaitForChild("FusionComponents")
local Widgets           = FusionComponents:WaitForChild("Widgets")
local Libraries         = ReplicatedStorage:WaitForChild("Libraries")
local GuiManagerLibrary = Libraries:WaitForChild("GuiManager")
local DataTables        = ReplicatedStorage:WaitForChild("DataTables")

-- Instances
local localPlayer = Players.LocalPlayer

-- GUI
local OutfitVoteTile    = require(script:WaitForChild("OutfitVoteTile"))
local CloseButton       = require(Widgets:WaitForChild("CloseButton"))

-- Modules
local SerialisationService  = require(Utility:WaitForChild("SerialisationService"))
local ImageUris             = require(DataTables:WaitForChild("ImageUris"))
local UI_CONSTANTS          = require(Utility:WaitForChild("UI_CONSTANTS"))
local Fusion                = require(Utility:WaitForChild("Fusion"))
local GuiManager            = require(GuiManagerLibrary:WaitForChild("GuiManager"))

-- Fusion
local peek = Fusion.peek
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>
type Value<T> = Fusion.Value<T>

-- Remotes
local GetNextOutfitRF = Remotes:WaitForChild("GetNextOutfitRF")
local SubmitVoteRF = Remotes:WaitForChild("SubmitVoteRF")
local GetUnseenCountRF = Remotes:WaitForChild("GetUnseenCountRF")
local GetVotingThemeRF = Remotes:WaitForChild("GetVotingThemeRF")

-- Constants
local LEFT_SLOT_POS = UDim2.fromScale(0.25, 0.5)
local RIGHT_SLOT_POS = UDim2.fromScale(0.75, 0.5)
local OFFSCREEN_LEFT = UDim2.fromScale(-0.5, 0.5)
local OFFSCREEN_RIGHT = UDim2.fromScale(1.5, 0.5)
local OFFSCREEN_DOWN = UDim2.fromScale(0.5, 1.8)
local TILE_SIZE = UDim2.fromScale(0.35, 0.85)
local POSITION_TWEEN_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

--

local function VotingFrame(scope: Fusion.Scope): (Frame, () -> ())
	-- State
	local votingTheme = scope:Value("Loading...")
	local votingComplete = scope:Value(false)
	local tilesContainer = scope:Value({})

	-- Tile references (not reactive, just tracking)
	local leftTile: Frame? = nil
	local rightTile: Frame? = nil
	local leftControls: OutfitVoteTile.OutfitVoteTileControls? = nil
	local rightControls: OutfitVoteTile.OutfitVoteTileControls? = nil
	local leftOutfitId: string? = nil
	local rightOutfitId: string? = nil
	local leftPositionValue: Value<UDim2>? = nil
	local rightPositionValue: Value<UDim2>? = nil

	-- Helper functions
	local function cleanupTile(tile: Frame?)
		if tile then
			task.delay(0.6, function()
				if tile then
					tile:Destroy()
				end
			end)
		end
	end

	local function fetchNextOutfit(): { outfitId: string, humanoidDescription: HumanoidDescription }?
		local success, result = pcall(function()
			return GetNextOutfitRF:InvokeServer()
		end)

		if success and result and result.humanoidDescription then
			return {
				outfitId = result.outfitId,
				humanoidDescription = SerialisationService.UnserialiseHumanoidDescription(result.humanoidDescription),
			}
		end
		return nil
	end

	local function getUnseenCount(): number
		local success, result = pcall(function()
			return GetUnseenCountRF:InvokeServer()
		end)

		if success and result then
			return result
		end
		return 0
	end

	local function submitVote(winnerOutfitId: string, loserOutfitId: string)
		pcall(function()
			SubmitVoteRF:InvokeServer(winnerOutfitId, loserOutfitId)
		end)
	end

	local function fetchVotingTheme()
        warn("In fetch")
		local success, result = pcall(function()
			return GetVotingThemeRF:InvokeServer()
		end)

        warn("Got dat ", success, result)

		if success and result then
			votingTheme:set(result)
        else
            warn("Failed to get theme!")
            votingTheme:set("Test Theme")
		end
	end

	-- Forward declarations for callbacks
	local onLeftSelected: () -> ()
	local onRightSelected: () -> ()

	local function spawnTile(
		outfitData: { outfitId: string, humanoidDescription: HumanoidDescription },
		initialPos: UDim2,
		finalPos: UDim2,
		onActivated: () -> ()
	): (Frame, OutfitVoteTile.OutfitVoteTileControls, Value<UDim2>)
		local positionValue = scope:Value(initialPos)
		local positionTween = scope:Tween(positionValue, POSITION_TWEEN_INFO)

		local tile, controls = OutfitVoteTile(scope, {
			name = "VoteTile_" .. outfitData.outfitId,
			position = positionTween,
			size = TILE_SIZE,
			anchorPoint = Vector2.new(0.5, 0.5),
			humanoidDescription = outfitData.humanoidDescription,
			onActivated = onActivated,
		})

		-- Slide to final position
		task.defer(function()
			positionValue:set(finalPos)
		end)

		return tile, controls, positionValue
	end

	local function spawnNewChallenger()
		local unseenCount = getUnseenCount()
		if unseenCount == 0 then
			votingComplete:set(true)
			-- Final winner stays on screen
			if leftControls then
				leftControls.triggerWin()
			end
			return
		end

		local newOutfit = fetchNextOutfit()
		if not newOutfit then
			votingComplete:set(true)
			return
		end

		rightTile, rightControls, rightPositionValue = spawnTile(
			newOutfit,
			OFFSCREEN_RIGHT,
			RIGHT_SLOT_POS,
			function() onRightSelected() end
		)
		rightOutfitId = newOutfit.outfitId

		tilesContainer:set({ leftTile, rightTile })
	end

	onLeftSelected = function()
		if not leftOutfitId or not rightOutfitId then return end
		if not leftControls or not rightControls then return end
		if not rightPositionValue then return end

		-- Left wins
		submitVote(leftOutfitId, rightOutfitId)

		leftControls.triggerWin()
		rightControls.triggerLoss()

		-- Slide loser down
		rightPositionValue:set(OFFSCREEN_DOWN)
		cleanupTile(rightTile)
		rightTile = nil
		rightControls = nil
		rightOutfitId = nil
		rightPositionValue = nil

		-- Spawn new challenger after animation
		task.delay(0.3, spawnNewChallenger)
	end

	onRightSelected = function()
		if not leftOutfitId or not rightOutfitId then return end
		if not leftControls or not rightControls then return end
		if not leftPositionValue or not rightPositionValue then return end

		-- Right wins
		submitVote(rightOutfitId, leftOutfitId)

		rightControls.triggerWin()
		leftControls.triggerLoss()

		-- Slide loser down
		leftPositionValue:set(OFFSCREEN_DOWN)
		cleanupTile(leftTile)

		-- Slide winner to left
		rightPositionValue:set(LEFT_SLOT_POS)

		-- Transfer right to left
		leftTile = rightTile
		leftControls = rightControls
		leftPositionValue = rightPositionValue
		leftOutfitId = rightOutfitId

		-- Clear right references
		rightTile = nil
		rightControls = nil
		rightOutfitId = nil
		rightPositionValue = nil

		-- Spawn new challenger after animation
		task.delay(0.3, spawnNewChallenger)
	end

	local function initialiseVoting()
        warn("Initialising voting")
		votingComplete:set(false)

        warn("Cleaning up")
		-- Cleanup existing tiles
		if leftTile then leftTile:Destroy() end
		if rightTile then rightTile:Destroy() end
		leftTile = nil
		rightTile = nil
		leftControls = nil
		rightControls = nil
		leftOutfitId = nil
		rightOutfitId = nil
		leftPositionValue = nil
		rightPositionValue = nil
		tilesContainer:set({})

        warn("Fetching theme")
		-- Fetch theme
		fetchVotingTheme()

        warn("Getting outfits")
		-- Fetch first two outfits
		local firstOutfit = fetchNextOutfit()
		local secondOutfit = fetchNextOutfit()

		if not firstOutfit or not secondOutfit then
			votingComplete:set(true)
			warn("Not enough outfits to vote on")
			return
		end

		-- Spawn left tile
		leftTile, leftControls, leftPositionValue = spawnTile(
			firstOutfit,
			OFFSCREEN_LEFT,
			LEFT_SLOT_POS,
			function() onLeftSelected() end
		)
		leftOutfitId = firstOutfit.outfitId

		-- Spawn right tile
		rightTile, rightControls, rightPositionValue = spawnTile(
			secondOutfit,
			OFFSCREEN_RIGHT,
			RIGHT_SLOT_POS,
			function() onRightSelected() end
		)
		rightOutfitId = secondOutfit.outfitId

		tilesContainer:set({ leftTile, rightTile })
	end

	-- Build the frame
	local VotingFrameGui = scope:New "Frame" {
		Name = "VotingFrame",
		Size = UDim2.fromScale(0.8, 0.8),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1,
		Visible = true,
		ClipsDescendants = true,

		[Children] = {
			CloseButton(scope, {
				size = UDim2.fromScale(0.08, 0.1),
				anchorPoint = Vector2.new(0.5, 0.5),
				position = UDim2.fromScale(1, 0),

				onClick = function()
					GuiManager.PopCentre()
				end
			}),

			scope:New "Frame" {
				Name = "Background",
				Size = UDim2.fromScale(1, 1),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.2,
				ZIndex = 0,

				[Children] = {
					scope:New "UICorner" {
						CornerRadius = UDim.new(0.05)
					},
				}
			},

			scope:New "Frame" {
				Name = "Body",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ZIndex = 1,

				[Children] = {
					scope:New "UIListLayout" {
						FillDirection = Enum.FillDirection.Vertical,
						SortOrder = Enum.SortOrder.LayoutOrder,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
					},

					scope:New "Frame" {
						Name = "Buffer",
						Size = UDim2.fromScale(1, 0.03),
						LayoutOrder = 0,
						BackgroundTransparency = 1
					},

					scope:New "Frame" {
						Name = "TopBar",
						Size = UDim2.fromScale(1, 0.1),
						LayoutOrder = 1,
						BackgroundTransparency = 1,

						[Children] = {
							scope:New "UIListLayout" {
								FillDirection = Enum.FillDirection.Horizontal,
								SortOrder = Enum.SortOrder.LayoutOrder,
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								Padding = UDim.new(0.02, 0),
							},

							scope:New "TextLabel" {
								Name = "VoteFor",
								Text = "Vote for best fit:",
								TextScaled = true,
								Size = UDim2.fromScale(0.3, 1),
								LayoutOrder = 0,
								BackgroundTransparency = 1,
								TextColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
								FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Bold),
							},

							scope:New "TextLabel" {
								Name = "TodaysTheme",
								Text = votingTheme,
								TextScaled = true,
								Size = UDim2.fromScale(0.3, 1),
								LayoutOrder = 1,
								BackgroundTransparency = 1,
								TextColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
								FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Bold),
							},

							scope:New "Frame" {
								Name = "Buffer",
								Size = UDim2.fromScale(0.03, 1),
								LayoutOrder = 2,
								BackgroundTransparency = 1,
							},

							scope:New "Frame" {
								Name = "TimerContainer",
								Size = UDim2.fromScale(0.2, 1),
								LayoutOrder = 3,
								BackgroundTransparency = 1,

								[Children] = {
									scope:New "UIListLayout" {
										FillDirection = Enum.FillDirection.Horizontal,
										SortOrder = Enum.SortOrder.LayoutOrder,
										HorizontalAlignment = Enum.HorizontalAlignment.Center,
									},

									scope:New "ImageLabel" {
										Image = ImageUris.StopwatchIcon,
										Size = UDim2.fromScale(1, 1),
										LayoutOrder = 1,
										BackgroundTransparency = 1,

										[Children] = {
											scope:New "UIAspectRatioConstraint" {
												AspectRatio = 1,
												DominantAxis = Enum.DominantAxis.Width,
											}
										}
									},

									scope:New "TextLabel" {
										Name = "Timer",
										Text = "3:00", -- TODO: Wire to actual timer
										TextScaled = true,
										Size = UDim2.fromScale(1, 1),
										LayoutOrder = 2,
										BackgroundTransparency = 1,
										TextColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
										FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Bold),
									}
								}
							}
						}
					},

					scope:New "Frame" {
						Name = "Buffer",
						Size = UDim2.fromScale(1, 0.01),
						LayoutOrder = 2,
						BackgroundTransparency = 1
					},

					scope:New "Frame" {
						Name = "TilesContainer",
						Size = UDim2.fromScale(1, 0.8),
						LayoutOrder = 3,
						BackgroundTransparency = 1,

						[Children] = {
							scope:Computed(function(use)
								return use(tilesContainer)
							end),

							-- Voting complete message
							scope:New "TextLabel" {
								Name = "VotingComplete",
								Text = "All outfits viewed",
								TextScaled = true,
								Size = UDim2.fromScale(0.6, 0.15),
								Position = UDim2.fromScale(0.5, 0.5),
								AnchorPoint = Vector2.new(0.5, 0.5),
								BackgroundTransparency = 1,
								TextColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
								FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Bold),
								Visible = votingComplete,
								ZIndex = 10,
							} :: TextLabel ,
						}
					},
				}
			},
		}
	} :: Frame

	return VotingFrameGui, initialiseVoting
end

return VotingFrame