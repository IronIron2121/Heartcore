game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAppearanceLoaded:Connect(function(char)
        local hum = char:WaitForChild("Humanoid")
        local animator = hum:WaitForChild("Animator")
        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
            track:Stop(0)
        end
        local animScript = char:WaitForChild("Animate")
        -- All custom animations go here vvv --
        animScript.jump.JumpAnim.AnimationId = script:WaitForChild("FrontFlip").AnimationId
        animScript.fall.FallAnim.AnimationId = script:WaitForChild("Fall").AnimationId
    end)
end)