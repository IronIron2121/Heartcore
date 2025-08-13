--!strict

local SETTINGS = {
	-- Automatically fetch the place creator's name
	FETCH_CREATOR_NAME 		= true,
	-- Fallback creator name to use if the place is not published or FETCH_CREATOR_NAME = false
	DEFAULT_CREATOR_NAME 	= "Roblox",
	-- Gamepad button to use as a shortcut for opening the shop
	SHOP_GAMEPAD_KEY_CODE 	= Enum.KeyCode.ButtonY,
	BACK_GAMEPAD_KEY_CODE 	= Enum.KeyCode.ButtonB,
	-- Limit the amount of items being tried on
	MAX_TRY_ON_ITEMS 		= 15,
}

return SETTINGS
