--!strict

--[[
	Audio - This script handles all of the UI audio, including hover/click sounds and purchase sounds.
	UI buttons are all tagged so this script can easily add sound effects when they are hovered/clicked.
--]]

local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Constants = require(ReplicatedStorage.Constants)
local Types = require(ReplicatedStorage.Utility.Types)
local ItemContainer = require(ReplicatedStorage.Utility.ItemContainer)
local playFromStart = require(script.playFromStart)

local audioPlayers = SoundService.Audio.Players
local purchasePlayer = audioPlayers.UI.Purchase
local cartAddPlayer = audioPlayers.UI.CartAdd
local cartRemovePlayer = audioPlayers.UI.CartRemove
local hoverStartPlayer = audioPlayers.UI.HoverStart
local clickPlayer = audioPlayers.UI.Click

local function onBulkPurchaseFinished(
	_: Instance,
	status: Enum.MarketplaceBulkPurchasePromptStatus,
	_: Types.BulkPurchaseResult
)
	if status ~= Enum.MarketplaceBulkPurchasePromptStatus.Completed then
		return
	end

	playFromStart(purchasePlayer)
end

local function onPurchaseFinished(_: Instance, _: number, wasPurchased: boolean)
	if not wasPurchased then
		return
	end

	playFromStart(purchasePlayer)
end

local function onBundlePurchaseFinished(_: Instance, _: number, wasPurchased: boolean)
	if not wasPurchased then
		return
	end

	playFromStart(purchasePlayer)
end

local function onUIButtonAdded(button: Instance)
	assert(button:IsA("GuiButton"), `{button:GetFullName()} is not a GuiButton!`)

	button.MouseEnter:Connect(function()
		playFromStart(hoverStartPlayer)
	end)

	button.Activated:Connect(function()
		playFromStart(clickPlayer)
	end)
end

local function onInspectPromptAdded(prompt: Instance)
	assert(prompt:IsA("ProximityPrompt"), `{prompt:GetFullName()} is not a ProximityPrompt!`)

	prompt.Triggered:Connect(function()
		playFromStart(clickPlayer)
	end)
end

local function initialise()
	CollectionService:GetInstanceAddedSignal(Constants.UI_BUTTON_TAG):Connect(onUIButtonAdded)
	CollectionService:GetInstanceAddedSignal(Constants.INSPECT_PROMPT_TAG):Connect(onInspectPromptAdded)
	MarketplaceService.PromptPurchaseFinished:Connect(onPurchaseFinished)
	MarketplaceService.PromptBundlePurchaseFinished:Connect(onBundlePurchaseFinished)
	MarketplaceService.PromptBulkPurchaseFinished:Connect(onBulkPurchaseFinished)

	for _, button in CollectionService:GetTagged(Constants.UI_BUTTON_TAG) do
		onUIButtonAdded(button)
	end

	for _, prompt in CollectionService:GetTagged(Constants.INSPECT_PROMPT_TAG) do
		onInspectPromptAdded(prompt)
	end

end

initialise()
