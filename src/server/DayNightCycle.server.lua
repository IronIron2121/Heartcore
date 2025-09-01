--[[
Day/Night Cycle Script with Dynamic Lighting
--------------------------------------------
Full day length: 1 hour real-time
Changes sun/moon position and adjusts lighting colors.
Place in ServerScriptService.
--]]

-- SETTINGS
local fullDayLength = 10 * 10 -- seconds (1 hour real-time)
local lighting = game:GetService("Lighting")

-- Initial settings
lighting.ClockTime = 6 -- Start at 6:00 AM
lighting.GeographicLatitude = 45
lighting.Brightness = 2
lighting.GlobalShadows = true

-- Cycle speed calculation
local hoursPerSecond = 24 / fullDayLength

-- Function to set lighting based on current time
local function updateLightingColors(time)
	-- Morning (6�8)
	if time >= 6 and time < 8 then
		lighting.Ambient = Color3.fromRGB(111, 133, 206) -- Warm sunrise
		lighting.OutdoorAmbient = Color3.fromRGB(200, 180, 160)
		lighting.Brightness = 1.5
		lighting.ColorShift_Top = Color3.fromRGB(255, 243, 112)
 
		-- Daytime (8�17)
	elseif time >= 8 and time < 17 then
		lighting.Ambient = Color3.fromRGB(74, 75, 124)
		lighting.OutdoorAmbient = Color3.fromRGB(200, 180, 160)
		lighting.Brightness = 2
		lighting.ColorShift_Top = Color3.fromRGB(216, 235, 255)


		-- Sunset (17�19)
	elseif time >= 17 and time < 19 then
		lighting.Ambient = Color3.fromRGB(74, 75, 124)
		lighting.OutdoorAmbient = Color3.fromRGB(180, 120, 90)
		lighting.Brightness = 1.5
		lighting.ColorShift_Top = Color3.fromRGB(255, 76, 44)


		-- Night (19�6)
	else
		lighting.Ambient = Color3.fromRGB(100, 100, 150)
		lighting.OutdoorAmbient = Color3.fromRGB(50, 50, 80)
		lighting.Brightness = 1
		lighting.ColorShift_Top = Color3.fromRGB(128, 185, 255)

	end
end

-- MAIN LOOP
while true do
	local delta = task.wait() -- Wait for frame time
	lighting.ClockTime = (lighting.ClockTime + hoursPerSecond * delta) % 24
	updateLightingColors(lighting.ClockTime)
end

