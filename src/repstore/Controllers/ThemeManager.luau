-- ThemeManager.lua (ModuleScript in ReplicatedStorage)
-- CLIENT-SAFE: Only contains data access functions

local RunService = game:GetService("RunService")

local ThemeManager = {}
ThemeManager.CurrentTheme = nil

-- Default themes list (for client reference)
ThemeManager.Themes = {
	"Cyberpunk Streetwear",
	"Medieval Knight",
	"Beach Party",
	"Winter Wonderland",
	"Space Explorer",
	"Royal Ball",
	"Sports Day"
}

-- Client-safe functions only
function ThemeManager:getCurrentTheme()
	return self.CurrentTheme or "No theme yet"
end

function ThemeManager:getThemeName()
	print("Getting theme name!")
	return self.CurrentTheme and self.CurrentTheme.Theme or "Loading..."
end

function ThemeManager:getTimeChanged()
	return self.CurrentTheme and self.CurrentTheme.TimeChanged or nil
end

-- Internal function for server to update theme data
function ThemeManager:_updateThemeData(themeData)
	-- Only callable from server, but safe for clients to have
	if RunService:IsServer() then
		self.CurrentTheme = themeData
	end
end

return ThemeManager