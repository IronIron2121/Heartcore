--!strict
-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Getters = ReplicatedStorage:WaitForChild("Getters")

-- Modules
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))
local Fusion = require(Utility:WaitForChild("Fusion"))
local peek = Fusion.peek

-- Variables

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local LoadEmoteRF = Remotes:WaitForChild("LoadEmoteRF")

-- Folders
local Emotes = ReplicatedStorage:WaitForChild("Emotes")

local AvatarPreviewModel = {}
AvatarPreviewModel.__index = AvatarPreviewModel
 
function AvatarPreviewModel.new(scope: Fusion.Scope, props: {
	showLoading: (() -> ())?,
	hideLoading: (() -> ())?,
})
	local self = setmetatable({}, AvatarPreviewModel)
	self.showLoading = props.showLoading
	self.hideLoading = props.hideLoading

	-- Get local player info
	local localPlayer = Players.LocalPlayer
	local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
	local humanoid = char:WaitForChild("Humanoid")

	-- Store the current HumanoidDescription as a reactive Value
	self.currentHumanoidDescription = scope:Value(humanoid:WaitForChild("HumanoidDescription"))

	-- Plain Value so CreateHumanoidModelFromDescription is never called inside Fusion's
	-- reactive graph (it can yield and fire events, both of which break Computeds)
	self.instance = scope:Value(
		Players:CreateHumanoidModelFromDescription(
			humanoid:WaitForChild("HumanoidDescription"),
			Enum.HumanoidRigType.R15
		)
	)

	self.currentTrack = scope:Value(nil)
	self.currentTrackSignal = scope:Value(nil)

	-- Watch for HumanoidDescription changes
	-- task.defer ensures set() is never called while Fusion's graph update is still
	-- propagating (e.g. CreateHumanoidModelFromDescription firing ChildAdded mid-Computed)
	humanoid.ChildAdded:Connect(function(child)
		if child:IsA("HumanoidDescription") then
			task.defer(function()
				self:onHumanoidDescriptionChanged(child) 
			end)
		end
 	end) 

	return self
end

function AvatarPreviewModel:onHumanoidDescriptionChanged(child: HumanoidDescription)
	self.currentHumanoidDescription:set(child)
	local newModel = Players:CreateHumanoidModelFromDescription(child, Enum.HumanoidRigType.R15)
	self.instance:set(newModel)
end

function AvatarPreviewModel:getInstance()
	return self.instance
end

function AvatarPreviewModel:getDescription()
	return self.currentHumanoidDescription
end

function AvatarPreviewModel:PlayAnimation(animationId: number)
	local model = peek(self.instance)
	if not model then 
		warn("No model at play animation!")
		return  end

	local humanoid = model:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then 
		warn("No humanoid at play animation!") 
		return 
	end

	local animator: Animator = humanoid:FindFirstChild("Animator") :: Animator
	if not animator then
		animator = Instance.new("Animator") :: Animator
		animator.Parent = humanoid
	end

	if self.showLoading then self.showLoading() end

	local success, emoteLoaded = callWithRetry(function()
		return LoadEmoteRF:InvokeServer(animationId)
	end)

	if not success or not emoteLoaded then
		if self.hideLoading then self.hideLoading() end
		return
	end

	local emoteSuccess, animation = callWithRetry(function()
		return Emotes:FindFirstChild(tostring(animationId))
	end)

	if self.hideLoading then self.hideLoading() end

	if not emoteSuccess or not animation then
		return
	end

	if peek(self.currentTrack) ~= nil then
		peek(self.currentTrack):Stop()
		self.currentTrack:set(nil)
	end

	self.currentTrack:set((animator :: Animator):LoadAnimation(animation))
	peek(self.currentTrack).Looped = false
	peek(self.currentTrack):Play()

end

return AvatarPreviewModel