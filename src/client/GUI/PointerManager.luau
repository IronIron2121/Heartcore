--!strict

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local getThumbnailFromId = require(ReplicatedStorage.Getters.getThumbnailFromId)

-- Instances
local localPlayer = Players.LocalPlayer
local localChar = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local rootPart = localChar:WaitForChild("HumanoidRootPart")

local playerAttachment = Instance.new("Attachment", rootPart)
local targetAttachment = Instance.new("Attachment", script)

local beam = Instance.new("Beam", rootPart)
beam.FaceCamera = true
beam.Attachment0 = targetAttachment
beam.Attachment1 = playerAttachment
beam.Texture = getThumbnailFromId(9006027964)
beam.TextureLength = 5
beam.TextureMode = Enum.TextureMode.Static
beam.LightInfluence = 1
beam.LightEmission = 1
beam.TextureSpeed = -1
beam.Transparency = NumberSequence.new(0)

--

local Pointer = {}

function Pointer.startBeam(target: BasePart)
    targetAttachment.Parent = target
end

function Pointer.endBeam()
    beam.Enabled = false
    targetAttachment.Parent = script
end

function Pointer.HideBeam()
    beam.Enabled = false
end

function Pointer.ShowBeam()
    beam.Enabled = true
end

return Pointer