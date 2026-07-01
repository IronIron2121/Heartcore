--!strict

-- Services
local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer.StarterPlayerScripts

-- Folders
local Audio = StarterPlayerScripts.Audio

-- Modules
local AudioManager = require(Audio.AudioManager)

--

AudioManager.initialise()