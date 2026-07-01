--!strict

-- Services
local StarterPlayer 		= game:GetService("StarterPlayer")
local StarterPlayerScripts 	= StarterPlayer.StarterPlayerScripts
local ReplicatedStorage 	= game:GetService("ReplicatedStorage")

-- Folders
local AudioFiles = ReplicatedStorage:WaitForChild("Audio")
local AudioFolder = StarterPlayerScripts.Audio

-- Modules
local AudioFileNames = require(AudioFolder.AudioFileNames)

local AudioManager = {}

function AudioManager.initialise()
	for _, audio in ReplicatedStorage.Audio:GetChildren() do
		if audio:IsA("Sound") then
			audio.Volume = 0.6
		end
	end

	AudioFiles[AudioFileNames.ClickFx0201CombNEG].Volume	= 0.1
	AudioFiles[AudioFileNames.ClickFx0201Comb].Volume		= 0.1
	AudioFiles[AudioFileNames.RoundLast5Sec].Volume			= 0.1
	AudioFiles[AudioFileNames.RoundChange].Volume 			= 0.1
	AudioFiles[AudioFileNames.Clickv3].Volume				= 0.1
	AudioFiles[AudioFileNames.Reset].Volume 				= 0.1 

	local atmosphereBG = AudioFiles[AudioFileNames.Atmosphere002] :: Sound
	atmosphereBG.Looped = true
	atmosphereBG.Volume = 0.3
	atmosphereBG:Play()
end

function AudioManager.playSound(soundName: string)
	local sound = AudioFiles:FindFirstChild(soundName) :: Sound?
	if sound then
		sound:Play()
	else
		warn("[AudioManager] Sound not found:", soundName)
	end
end

return AudioManager