--!strict

local Constants = {
	-- Memory Store Names
	GAME_TIMER_MEMORYSTORE_NAME = "GameTimer",
	SUBMISSION_MEMORYSTORE_NAME = "CurrentSubmissionsMemoryStore",
	CONTEST_MEMORYSTORE_NAME = "CurrentContestMemoryStore",
	WINNERS_MEMORYSTORE_NAME = "CurrentWinnersMemoryStore",
	MEMORYSTORE_STORE_DURATION = 129600, -- 36 hours
	
	-- Memory Store Keys
	CURRENT_THEME_KEY = "CurrentTheme",
	CURRENT_WINNERS_KEY = "CurrentWinners",
	FIRST_PLACE_KEY = "FirstPlace",
	SECOND_PLACE_KEY = "SecondPlace",
	THIRD_PLACE_KEY = "ThirdPlace",
	
	-- Datastore Names
	PLAYER_SHOPS_DATA_STORE_NAME = "PlayerShops",
	OWNEDITEMS_DATASTORE = "PlayerOwnedItems",
	PLAYER_OUTFITS_DATASTORE = "PlayerOutfits",
	PLAYER_CLOTHING_DATASTORE = "PlayerClothing",
	
	-- Mannequin Constants
	FULL_MANNEQUIN_NAME = "FullMannequin",
	HEAD_MANNEQUIN_NAME = "HeadMannequin",
	MANNEQUINS_NAME = "Mannequin",
	MANNEQUIN_TAG = "Mannequin",
	FLOOR_MANNEQUIN_TAG = "FloorMannequin",
	RECENT_MANNEQUIN_ATTRIBUTE = "CurrentMannequin",
	MANNEQUIN_ITEM_TYPE = "Mannequin",
	MANNEQUIN_BUNDLE_IDS_ATTRIBUTE = "bundleIds",
	MANNEQUIN_ACCESSORY_IDS_ATTRIBUTE = "accessoryIds",
	
	-- Humanoid Attributes
	SKIN_COLOR_ATTRIBUTE = "skinColor",
	POSE_ANIMATION_ATTRIBUTE = "poseAnimation",
	BODY_DEPTH_SCALE_ATTRIBUTE = "bodyDepthScale",
	BODY_HEIGHT_SCALE_ATTRIBUTE = "bodyHeightScale",
	BODY_PROPORTION_SCALE_ATTRIBUTE = "bodyProportionScale",
	BODY_TYPE_SCALE_ATTRIBUTE = "bodyTypeScale",
	BODY_WIDTH_SCALE_ATTRIBUTE = "bodyWidthScale",
	HEAD_SCALE_ATTRIBUTE = "headScale",
	
	HUMANOID_ACCESSORY_ATTRIBUTES = {
		"BackAccessory",
		"FaceAccessory",
		"FrontAccessory",
		"HairAccessory",
		"HatAccessory",
		"NeckAccessory",
		"ShouldersAccessory",
		"WaistAccessory",
		"Shirt",
		"Pants",
		"GraphicTShirt",
		"Head",
		"LeftArm",
		"LeftLeg",
		"RightArm",
		"RightLeg",
		"Torso",
	},
	
	-- Shop Constants
	SHOP_ITEMS_KEY = "ShopItems",
	SHOP_ITEM_OWNED_BY_ATTRIBUTE = "ownedBy",
	SHOP_FOLDER_NAME = "Shops",
	SHOP_ZONE_GROUP_NAME = "ShopZones",
	NUMBER_OF_SHOPS = 4,
	BLANK_SHOP_TAG = "BlankShop",
	
	SHOP_CLAIM_ATTRIBUTES = {
		CLAIMED_BOOL = "CLAIMED",
		CLAIMED_BY = "CLAIMED_BY"
	},
	
	PLAYER_CLAIM_ATTRIBUTES = {
		SHOP_BOOL = "HAS_SHOP",
		SHOP_NAME = "SHOP_NAME"
	},
	
	-- Item Attributes
	ITEM_ID_ATTRIBUTE = "Id",
	ITEM_COLOUR_ATTRIBUTE = "itemColour",
	ITEM_TYPE_ATTRIBUTE = "itemType",
	ITEM_NAME_KEY = "itemName",
	ITEM_ATTRIBUTES_KEY = "itemAttributes",
	ACCESSORY_ID_ATTRIBUTE = "accessoryId",
	FURNITURE_ITEM_TYPE = "Furniture",
	DEFAULT_FURNITURE_COLOUR = "Default",
	
	-- Datastore Keys
	DATASTORE_ITEM_CFRAME = "itemCFrame",
	
	-- Catalog/Marketplace Constants
	PAGE_SIZE = 30,
	SCROLL_LOAD_FACTOR = 0.9,
	QUERY_ATTEMPTS = 3,
	ASSET_TYPE_ID = Enum.MarketplaceProductType.AvatarAsset.Value,
	BUNDLE_TYPE_ID = Enum.MarketplaceProductType.AvatarBundle.Value,
	
	ITEM_RESTRICTIONS = {
		LIMITED = "Limited",
		LIMITED_U = "LimitedUnique",
		COLLECTIBLE = "Collectible",
	},
	
	-- UI Constants
	ROBUX_CHAR = utf8.char(0xe002),
	BUTTON_DISABLED_TRANSPARENCY = 0.5,
	ITEM_TILE_SIZE = Vector2.new(100, 200),
	ITEM_TILE_PADDING = 4,
	CAMERA_OFFSET = 0.65,
	
	-- Tags
	UI_BUTTON_TAG = "UIButton",
	INSPECT_PROMPT_TAG = "InspectPrompt",
	CLAIM_PROMPT_TAG = "ClaimPrompt",
	CATALOG_CONSOLE_TAG = "Console",
	CATALOG_CONSOLE_PROMPT_NAME = "ConsolePrompt",
	
	-- Editing Commands
	PLACE_COMMAND = "place",
	REPOSITION_COMMAND = "reposition",
	DEFAULT_NUDGE = 1,
	DEFAULT_ROTATE = 45,
}

return Constants