-- GameStateManager.lua

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local GameLoop = ReplicatedStorage:WaitForChild("GameLoop")

-- Modules
local GameOutfitManager = require(GameLoop:WaitForChild("GameOutfitManager"))

--

local STATES = require(GameLoop.GameStates)


local currentState: string = nil
local timerThread: thread? = nil

local currentStateName = ReplicatedStorage:FindFirstChild("CurrentStateName") or Instance.new("StringValue")
currentStateName.Name = "CurrentStateName"
currentStateName.Parent = ReplicatedStorage

local secondsRemaining = ReplicatedStorage:FindFirstChild("SecondsRemaining") or Instance.new("IntValue")
secondsRemaining.Name = "SecondsRemaining"
secondsRemaining.Parent = ReplicatedStorage

local GameStateManager = {}

local function startCountdown(duration: number)
    secondsRemaining.Value = duration
    
    timerThread = task.spawn(function()
        while secondsRemaining.Value > 0 do
            task.wait(1)
            secondsRemaining.Value -= 1
            print("Ticked to ", secondsRemaining.Value, currentState)
        end 
        GameStateManager.transitionTo(STATES[currentState].next)
    end)
end

function GameStateManager.transitionTo(stateName: string)
    warn("transing...")
    local config = STATES[stateName]
    
    if timerThread then
        pcall(function()
            return task.defer(task.cancel, timerThread)
        end)
        timerThread = nil
    end
    
    currentState = stateName
    currentStateName.Value = stateName
    
    GameStateManager._onStateEnter(stateName)
    startCountdown(config.duration)
end

function GameStateManager._onStateEnter(stateName: string)
    print(`[GameStateManager] Entered {stateName}`)
    
    if stateName == "Dressing" then
        GameOutfitManager.reset()
    elseif stateName == "Voting" then
        
    elseif stateName == "Intermission" then
        
    end
end

function GameStateManager.getCurrentState(): string
    return currentState
end

function GameStateManager.getSecondsRemaining(): number
    return secondsRemaining.Value
end

function GameStateManager.start()
    GameStateManager.transitionTo("Dressing")
end

return GameStateManager