local testFolder = workspace.TestFolder;
local head = testFolder.StoreMannequinHead;

local player = game.Players.Gaby2107
local char = player.Character
local hum = head.Humanoid :: Humanoid

--local hum = head:WaitForChild("Humanoid");

local descClone = hum:WaitForChild("HumanoidDescription"):Clone()
local bodyPartEnum = Enum.BodyPart["Head"]

for _, description in ipairs(descClone:GetChildren()) do
    if description:IsA("BodyPartDescription") or description:IsA("AccessoryDescription") then
        warn("zapping here")
        description:Destroy()
    end
end

local newDesc = Instance.new("BodyPartDescription")
newDesc.AssetId = 139999746614666
newDesc.BodyPart = Enum.BodyPart.Head
newDesc.Parent = descClone


hum:ApplyDescription(descClone)
