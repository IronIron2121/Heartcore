-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players			= game:GetService("Players")
local RunSercice		= game:GetService("RunService")

-- Folders
local GettersFolder 	= ReplicatedStorage:WaitForChild("Getters")

-- Module Scripts
local getPlayerPos 		= require(GettersFolder:WaitForChild("getPlayerPos"))

-- Instances
local arrow 			= script:WaitForChild("Arrow")
local localPlayer 		= Players.LocalPlayer 

-- Constants
local defaultWait		= 5
local arrowColour 		= Color3.new(1, 0.933333, 0)

-- Vars
local pointing

local function updateArrowPosition(arrow: BasePart, root: BasePart, target: BasePart)
	pcall(function()
		arrow.CFrame = CFrame.new(root.Position,target.Position) * CFrame.Angles(0,math.rad(-45),0) * CFrame.new(-2,0,-2)
		local mag = (arrow.Position - target.Position).Magnitude - 1
		arrow.Transparency = 1-(math.clamp(mag,0,2)/2)
	end)
	task.wait()
	
	
end

function makeArrowPointingAtPart(player: Player, part: BasePart, duration: number?)
	duration = duration or defaultWait
	
	local character = player.Character or player.CharacterAdded:Wait()
	local root = character:WaitForChild("HumanoidRootPart")
	
	local newArrow = arrow:Clone()
	newArrow.Color = arrowColour	
	newArrow.Parent = character
	
	for _ = 1, duration*60 do
		updateArrowPosition(newArrow, root, part)
	end


	newArrow:Destroy()
	newArrow = nil
end

return makeArrowPointingAtPart