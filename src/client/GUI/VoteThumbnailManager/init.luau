--!strict

-- Services
local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer.StarterPlayerScripts

-- GUI
local PlayerThumbnail = script:WaitForChild("PlayerThumbnail")

--

local thumbnails = {}
local VoteThumbnailManager = {}

function VoteThumbnailManager.onPlayerAdded(player: Player) 
    thumbnails[player.UserId] = PlayerThumbnail({
        player
    })
end


return VoteThumbnailManager