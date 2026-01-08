--!strict

local Constants = {
	-- Mannequin Names
	FULL_MANNEQUIN_NAME = "FullMannequin",
	HEAD_MANNEQUIN_NAME = "HeadMannequin",
	
	-- Shop Item Attributes
	SHOP_ITEMS_KEY = "ShopItems",
	SHOP_ITEM_OWNED_BY_ATTRIBUTE = "ownedBy",
	
	--
	DEFAULT_NUDGE = 1,
	DEFAULT_ROTATE = 45,	

	-- Voting Constants
	SUBMISSION_MEMORYSTORE_NAME = "CSMS",
	CONTEST_MEMORYSTORE_NAME = "CCMS",
	WINNERS_MEMORYSTORE_NAME = "CWMS",
	THEME_MEMORYSTORE_NAME = "ThemesMemoryStore",
	CURRENT_WINNERS_KEY = "CurrentWinners",
	CURRENT_TOP_TWENTY_KEY = "TopTwenty",
	FIRST_PLACE_KEY = "FirstPlace",
	SECOND_PLACE_KEY = "SecondPlace",
	THIRD_PLACE_KEY = "ThirdPlace",

	CURRENT_THEME_KEY = "CurrentTheme",
	GAME_TIMER_MEMORYSTORE_NAME = "GameTimer",
	
	-- Datastore names
	PLAYER_SHOPS_DATA_STORE_NAME = "PlayerShops",
	OWNEDITEMS_DATASTORE = "PlayerOwnedItems",
	PLAYER_OUTFITS_DATASTORE = "PlayerOutfits",
	PLAYER_CLOTHING_DATASTORE = "PlayerClothing",
	-- Object names
	MANNEQUINS_NAME = "Mannequin",
	-- Folder names
	SHOP_FOLDER_NAME = "Shops",
	-- ZoneGroup Names
	SHOP_ZONE_GROUP_NAME = "ShopZones",
	-- Product Codes
	ASSET_TYPE_ID = Enum.MarketplaceProductType.AvatarAsset.Value,
	BUNDLE_TYPE_ID = Enum.MarketplaceProductType.AvatarBundle.Value,
	-- Tags
	MANNEQUIN_TAG = "Mannequin",
	FLOOR_MANNEQUIN_TAG = "FloorMannequin",
	BLANK_SHOP_TAG = "BlankShop",
	UI_BUTTON_TAG = "UIButton",
	INSPECT_PROMPT_TAG = "InspectPrompt",
	CLAIM_PROMPT_TAG = "ClaimPrompt",
	CATALOG_CONSOLE_TAG = "Console",
	-- Attributes
	ITEM_ID_ATTRIBUTE = "Id",
	ITEM_COLOUR_ATTRIBUTE = "itemColour",
	MANNEQUIN_BUNDLE_IDS_ATTRIBUTE = "bundleIds",
	MANNEQUIN_ACCESSORY_IDS_ATTRIBUTE = "accessoryIds",
	ACCESSORY_ID_ATTRIBUTE = "accessoryId",
	SKIN_COLOR_ATTRIBUTE = "skinColor",
	POSE_ANIMATION_ATTRIBUTE = "poseAnimation",
	BODY_DEPTH_SCALE_ATTRIBUTE = "bodyDepthScale",
	BODY_HEIGHT_SCALE_ATTRIBUTE = "bodyHeightScale",
	BODY_PROPORTION_SCALE_ATTRIBUTE = "bodyProportionScale",
	BODY_TYPE_SCALE_ATTRIBUTE = "bodyTypeScale",
	BODY_WIDTH_SCALE_ATTRIBUTE = "bodyWidthScale",
	HEAD_SCALE_ATTRIBUTE = "headScale", 
	ITEM_ATTRIBUTES_KEY = "itemAttributes",
	ITEM_TYPE_ATTRIBUTE = "itemType",
	ITEM_NAME_KEY		= "itemName",
	MANNEQUIN_ITEM_TYPE 	= "Mannequin",
	FURNITURE_ITEM_TYPE  	= "Furniture",
	-- Datastore variable names
	DATASTORE_ITEM_CFRAME = "itemCFrame",
	-- Amount of items to load per catalog page
	PAGE_SIZE = 30,
	-- UI constants
	ROBUX_CHAR = utf8.char(0xe002),
	BUTTON_DISABLED_TRANSPARENCY = 0.5,
	ITEM_TILE_SIZE = Vector2.new(100, 200),
	ITEM_TILE_PADDING = 4,
	ITEM_RESTRICTIONS = {
		LIMITED = "Limited",
		LIMITED_U = "LimitedUnique",
		COLLECTIBLE = "Collectible",
	},
	CATALOG_CONSOLE_PROMPT_NAME = "ConsolePrompt",
	-- Amount of the page that needs to be scrolled through before loading the next one
	SCROLL_LOAD_FACTOR = 0.9,
	-- Factor to offset the character by onscreen when shop/inspect UI is open
	CAMERA_OFFSET = 0.65,
	NUMBER_OF_SHOPS = 4,
	-- Folders	
	RECENT_MANNEQUIN_ATTRIBUTE = "CurrentMannequin",
	
	SHOP_CLAIM_ATTRIBUTES = {
		CLAIMED_BOOL = "CLAIMED",
		CLAIMED_BY = "CLAIMED_BY"
	},
	
	PLAYER_CLAIM_ATTRIBUTES = {
		SHOP_BOOL = "HAS_SHOP",
		SHOP_NAME = "SHOP_NAME"
	},
	
	PLACE_COMMAND = "place",
	REPOSITION_COMMAND = "reposition",
	DEFAULT_FURNITURE_COLOUR = "Default",
	
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

	HUMANOID_SCALE_VARIABLES = {
		"BodyTypeScale",
		"DepthScale",
		"HeadScale",
		"HeightScale",
		"ProportionScale",
		"WidthScale"
	},

	-- We have to list this slightly differently as the actual assetType in Enum does not appear in the humanoid description
	CLASSIC_HUMANOID_CLOTHING_ASSET_TYPES = {
		"GraphicTShirt",
		Enum.AssetType.Shirt.Name,
		Enum.AssetType.Pants.Name
	},

	CLASSIC_CLOTHING_ASSET_TYPES = {
		Enum.AssetType.TShirt.Name,
		Enum.AssetType.Shirt.Name,
		Enum.AssetType.Pants.Name
	},

	EMOTE_ASSET_TYPE = Enum.AssetType.EmoteAnimation.Name,
	
	DEFAULT_CLASSIC_CLOTHING_IDS = {
		["GraphicTShirt"] = 0,
		["Shirt"] = 855779323,
		["Pants"] = 855785499,
	},
	
	DEFAULT_CLASSIC_CLOTHING_IDS_TABLE = {
		0,
		855779323,
		855785499,
	},

	ANIMATION_ASSET_TYPE_IDS = {
		24,
		48,
		49,
		50,
		51,
		52,
		53,
		54,
		55,
		56,
		61,
		78
	},

	QUERY_ATTEMPTS = 3,

	MEMORYSTORE_STORE_DURATION = 600, -- 10 minutes
	--MEMORYSTORE_STORE_DURATION = 259200, -- 72 hours - production timing limit
	MAX_SUBMISSIONS_PER_MEMORYSTORE = 500,
	SUBMISSION_INFO_MEMORYSTORE_NAME = "SubmissionsInfo",
	SUBMISSION_INFO_INDEX = "currentStoreNumber",
	CURRENT_SUBMISSION_INFO_KEY = "currentSubmissionsInfo",

	NO_CURRENT_PHASE_MESSAGE = "NO_CURRENT_PHASE",

    DEFAULT_TWEEN = TweenInfo.new(0.5, Enum.EasingStyle.Quad),
    GUI_SLOT_NAMES = {
        ["TopMiddle"] = "TopMiddle",
        ["BottomLeft"] = "BottomLeft",
        ["BottomMiddle"] = "BottomMiddle",
        ["BottomRight"] = "BottomRight",
    },

	WARDROBE_GUI_STATES = {
		InspectFrame = "if",
	}

}

return Constants
