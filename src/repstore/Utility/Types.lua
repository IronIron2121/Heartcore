--!strict

--[[
	Types - This module holds type information for the various data structures returned by
	AvatarEditorService:GetItemDetails(), :SearchCatalog(), etc.
--]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Fusion
local Fusion        = require(Utility.Fusion)
type scope          = Fusion.Scope
type UsedAs<T>      = Fusion.UsedAs<T>
type Value<T>       = Fusion.Value<T>
type Computed<T>    = Fusion.Computed<T>

export type ItemDetails = {
	AssetType: string,
	CreatorHasVerifiedBadge: boolean,
	CreatorName: string,
	CreatorTargetId: number,
	CreatorType: string,
	Description: string,
	FavoriteCount: number,
	IsPurchasable: boolean?,
	IsOffSale: boolean?,
	Id: number,
	ItemRestrictions: { string },
	ItemStatus: { string },
	ItemType: string,
	Name: string,
	Owned: boolean,
	Price: number?,
	LowestPrice: number?,
	LowestResalePrice: number?,
	PriceStatus: string?,
	ProductId: number,
	PurchaseCount: number,
	SaleLocation: string,
}

export type AssetDetails = ItemDetails & {
	ItemType: "Asset",
	AssetType: string,
} 

export type BundledItemDetails = {
	Id: number,
	Name: string,
	Owned: boolean,
	Type: string,
}

export type BundleDetails = ItemDetails & {
	ItemType: "Bundle",
	BundleType: string,
	BundledItems: { BundledItemDetails },
}

export type CatalogPage = { AssetDetails | BundleDetails }

export type BulkItem = {
	Id: string,
	Type: Enum.MarketplaceProductType,
}

export type BulkPurchaseResultItem = {
	id: string,
	status: Enum.MarketplaceItemPurchaseStatus,
	type: Enum.MarketplaceProductType,
}

export type BulkPurchaseResult = {
	Items: { BulkPurchaseResultItem },
	RobuxSpent: number,
}

export type HumanoidDescriptionAccessory = {
	AccessoryType: Enum.AccessoryType,
	AssetId: number,
	IsLayered: boolean?,
	Order: number?,
	Puffiness: number?,
}

export type unspawnedMannequinType = Model & {
	Base: Part,
	Placeholder: MeshPart
}

export type spawnedMannequinType = Model & {
	Base	: Part,
	Rig		: Model 
}

export type ShopDetails = {
	instance : BasePart,
	claimed : boolean,
	claimingPlayerId : number?,
	claimPrompt : ProximityPrompt,
	zone : Part,
	id : number,
	shopItemFolder : Folder,
	listOfShopItems : {},
	region : Region3,
	
	removeAllShopItems: (self: ShopDetails) -> (),
	removeShopItem : (self: ShopDetails, accessoryId : number) -> (),
	place: (self: ShopDetails, ShopItemRecipe) -> (),
	getShopInstance : (self: ShopDetails) -> BasePart,
	getUnusedItemId : (self : ShopDetails) -> number,
	getShopItemFromItemId : (self : ShopDetails, itemId : number) -> BaseShopItem,
	_initialiseAttributes: (self: ShopDetails) -> (),
	_initialiseClaimPrompt: (self: ShopDetails) -> (),
	onPlayerClaimed: (self: ShopDetails, player: Player) -> (),
	unclaim: (self: ShopDetails) -> (),
	_loadFurniture: (self: ShopDetails, playerShopData : {}) -> (),
	_loadMannequins: (self: ShopDetails,  playerShopData : {}) -> (),
	_loadPlayerShopItems: (self: ShopDetails, player : Player) -> (),
	removeShopItem: (self: ShopDetails) -> (),
	addShopItem: (self: ShopDetails, shopItemRecipe : ShopItemRecipe) -> (),
}

export type PlayerDetails = {
	player : Player,
	shop : ShopDetails?,
	id : number,
	
	claimedShop : (self : PlayerDetails, shop : ShopDetails) -> (),
	unclaimShop : (self: PlayerDetails) -> (),
	getPlayerShopData : (self : PlayerDetails) -> {}?,
	getPlayerShopInstance : (self : PlayerDetails) -> BasePart?,
	_initialisePlayerShopData : (self : PlayerDetails, player : Player) -> ()
}

export type ShopItemRecipe = {
	itemType : string,
	itemName : string,
	itemCFrame : {number},
	itemAttributes : {[string] : any}?,
	colour : string?,
	itemId : number?
}


export type BaseShopItem = {
	category : string,
	name : string,
	cframe : CFrame,
	itemId : number,
	itemType : string,
	instance : Model?,
	nudging : boolean,
	initialisePosition : (self : BaseShopItem, cframe : CFrame) -> (),
	
	new : (ShopItemRecipe : ShopItemRecipe) -> BaseShopItem,
	nudge : (self : BaseShopItem, direction : string) -> (),
	place : (self : BaseShopItem) -> (),
	Reposition : (self : BaseShopItem, newCFrame : CFrame) -> (),
	delete : (self : BaseShopItem) -> (),
	initialiseItemId : (self : BaseShopItem, itemId : number) -> (),
	onAddedToShop : (self : BaseShopItem, shopId : number) -> (), 
}

export type BaseMannequin = BaseShopItem & {
	new : (shopItemRecipe : ShopItemRecipe) -> BaseMannequin,
	bundleIds : {number},
	accessoryIds : {number},
	mannequinType : string,
	
	_addAssetIdToInstance : (self : BaseMannequin, assetId : number) -> (),
	_initialiseInspectPrompt : (self : BaseMannequin) -> ProximityPrompt,
	getAccessoryIdArray : (self : BaseMannequin) -> {number}?,
	getBundleIdArray : (self : BaseMannequin) -> {number}?,
	addAccessory : (self : BaseMannequin, accessoryId : number) -> (),
	removeAccessory : (self : BaseMannequin, itemId : number) -> (),
	isAccessoryEquipped : (self : BaseMannequin, accessoryId : number) -> (),
	getAllAssetIds : (self : BaseMannequin) -> {number},
	initialiseInstance : (self : BaseMannequin, shopItemRecipe : ShopItemRecipe) -> (),
}

export type FullMannequinTemplate = Model & {
	Placeholder : MeshPart,
	Base : Part
}

export type HeadMannequinTemplate = Model & {
	Humanoid : Humanoid,
	Base : MeshPart,
	Head : MeshPart,
	UpperTorso : MeshPart,
	HumanoidRootPart : Part,	
}

export type BaseFurniture = BaseShopItem & {
	
}
	
	
export type MannequinRig = Model & {
	Humanoid: Humanoid & {
		BodyDepthScale: NumberValue,
		BodyHeightScale: NumberValue,
		BodyProportionScale: NumberValue,
		BodyTypeScale: NumberValue,
		BodyWidthScale: NumberValue,
		HeadScale: NumberValue,
		Animator: Animator,
	},
	HumanoidRootPart: BasePart,
}

export type GuiConfiguration = {
    -- Properties
    Name: string,
    ConfigurationContainer: Frame,
    TopMiddle: Frame,
    TopMiddlePosition: Value<UDim2>,
    BottomLeft: Frame,
    BottomLeftPosition: Value<UDim2>,
    BottomMiddle: Frame,
    BottomMiddlePosition: Value<UDim2>,
    BottomRight: Frame,
    BottomRightPosition: Value<UDim2>,
    GuiSlotPositions: {[string]: Value<UDim2>},
    scope: scope,

    -- Methods
    Disable: (self: GuiConfiguration) -> (),
    Enable: (self: GuiConfiguration) -> (),
}

export type GuiManager = {
    CurrentDisplayedConfiguration: GuiConfiguration?,
}



return {} 