--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Remotes / Bindables

-- Constants
local LOCAL_TIMER_UPDATE_INTERVAL = 1

-- Variables
local nextPhaseStartTime = 0
local timeToNextPhase = 0
local timeText = ""

--

local LocalTimer = {}

function LocalTimer.updateNextPhaseStartTime(serverNextPhaseStartTime: number)
    nextPhaseStartTime = serverNextPhaseStartTime
end

function LocalTimer.initialiseLocalTimer()
    task.spawn(
        function()
            task.wait(LOCAL_TIMER_UPDATE_INTERVAL)
            local currentTime = DateTime.now().UnixTimestamp

            if not nextPhaseStartTime or nextPhaseStartTime <= currentTime then
                timeText = "LOADING..."
            else
                local timeToNextPhase = nextPhaseStartTime - currentTime
                local hours = timeToNextPhase // 3600
                local minutes = (timeToNextPhase % 3600) // 60
                local seconds = timeToNextPhase % 60


                timeText = string.format("%d:%02d:%02d", hours, minutes, seconds)
            end

        end
    )
end

function LocalTimer.getTimeText()
    return timeText
end

function LocalTimer.getTimeToNextPhase()
    return timeToNextPhase
end

return LocalTimer