local flipId = 134227711062993
local fallId = 131035550365656

local animPrefix = "rbxassetid://"


game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAppearanceLoaded:Connect(function(char)
        local hum = char:WaitForChild("Humanoid")
        local animator = hum:WaitForChild("Animator")
        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
            track:Stop(0)
        end
        local animScript = char:WaitForChild("Animate")
        
        
        --All custom animations go here vvv --
        --animScript.jump.JumpAnim.AnimationId = animPrefix .. tostring(flipId)
        --animScript.fall.FallAnim.AnimationId = animPrefix .. tostring(fallId)

    end)
end)