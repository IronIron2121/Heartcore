--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService   = game:GetService("TeleportService")

-- Folders
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PlayerTeleportedToPlaceRE = Remotes.PlayerTeleportedToPlaceRE

--

local function onPlayerTeleported(player: Player, placeId: number)
    TeleportService:TeleportAsync(placeId, { player })
end

PlayerTeleportedToPlaceRE.OnServerEvent:Connect(onPlayerTeleported)