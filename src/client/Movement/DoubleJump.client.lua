local maxJumps = 3 -- amount of jumps in the air
local jumpCooldown = 0.1 -- how fast you can jump again while in the air
local defaultJumpPower = 50 -- default jump power (Roblox default is 50)
local extraJumpPower = 100 -- jump power for jumps 2 and 3

local userInputService = game:GetService("UserInputService")
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local jumpCount = 0
local canJump = false

-- Make sure humanoid uses JumpPower instead of JumpHeight
humanoid.UseJumpPower = true
humanoid.JumpPower = defaultJumpPower

local function onStateChanged(oldState, newState)
	if newState == Enum.HumanoidStateType.Landed then
		jumpCount = 0
		canJump = false
		humanoid.JumpPower = defaultJumpPower -- reset to default
	elseif newState == Enum.HumanoidStateType.Freefall then
		task.wait(jumpCooldown)
		canJump = true
	elseif newState == Enum.HumanoidStateType.Jumping then
		canJump = false
		jumpCount = jumpCount + 1
	end
end

humanoid.StateChanged:Connect(onStateChanged)

userInputService.JumpRequest:Connect(function()
	if canJump and jumpCount < maxJumps then
		-- Set extra jump power for jumps 2 and 3
		if jumpCount >= 1 then
			humanoid.JumpPower = extraJumpPower
		end
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)
