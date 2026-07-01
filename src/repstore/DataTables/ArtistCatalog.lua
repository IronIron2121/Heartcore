--!strict

-- Services
local AvatarEditorService = game:GetService("AvatarEditorService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")

-- Modules
local callWithRetry = require(ReplicatedStorage.Utility.callWithRetry)

--

local ArtistCatalog = {}

type ArtistEntry = { name: string, ids: { number } }

ArtistCatalog.artists = {
    { name = "AU/RA",          ids = { 71882458840744, 122886395365956, 132770564781374, 123525695589225, 114767830899426 } },
    { name = "0207",          ids = { 17188965231, 17359499800, 17189045404, 17188036479, 17327615233 } },
    { name = "Aurora",        ids = { 74252259208484, 101667273776521, 120058570449063, 71554231655858, 77643937284993, 82456403420822, 97853257222904, 98421368980992, 117993188731779, 76071576718922, 74945382267863, 100517495522998, 105480865113913 } },
    { name = "CHAOS RECORDS", ids = { 78278713732475, 100846545835100, 136068222894901, 98288446486923 } },
    { name = "GLASS ANIMALS", ids = { 16087722036, 18576892010, 16274008184, 16087800665, 18559886365, 16264128485, 16264712804, 16264128485, 16264116133, 16087889204, 16087854308, 16264691136, 16108436852 } },
    { name = "ISLAND RECORDS", ids = { 139490136005351, 79897422375492, 123208615766450, 112286844580713, 121878849969041, 119810493638697, 84022126525055, 127394234908885 } },
    { name = "Jazzy",         ids = { 116851516575300, 81976847580740 } },
    { name = "KISS",          ids = { 83209697274466, 120371876640965, 125349846017502, 86492208439730, 74268447097398 } },
    { name = "SIGRID",        ids = { 138671226809400, 97022942847979, 103160515028694 } },
    { name = "STORMZY",       ids = { 17253243573, 17252890396 } },
    { name = "TLDP",          ids = { 88417487515151, 75232897667101, 128179070776684, 93949586330178, 76017710284220 } },
} :: { ArtistEntry }

ArtistCatalog.itemDetails = {} :: { [string]: { any } }

function ArtistCatalog.initialise()
    for _, artist in ipairs(ArtistCatalog.artists) do
        ArtistCatalog.itemDetails[artist.name] = {}
        for _, id in ipairs(artist.ids) do
            local ok, details = callWithRetry(function()
                return AvatarEditorService:GetItemDetailsAsync(id, Enum.AvatarItemType.Asset)
            end)
            if ok and details then
                table.insert(ArtistCatalog.itemDetails[artist.name], details)
            else
                warn("[ArtistCatalog] Failed to fetch ID", id, details)
            end
        end
    end
end

-- Returns items for a given artist (nil = all artists).
-- If assetTypes is non-empty, only items whose AssetType name matches are included.
function ArtistCatalog.getItems(artistName: string?, assetTypes: { Enum.AvatarAssetType }): { any }
    local result = {}
    local filterByType = #assetTypes > 0
    for name, items in pairs(ArtistCatalog.itemDetails) do
        if artistName == nil or name == artistName then
            for _, item in ipairs(items) do
                if not filterByType then
                    table.insert(result, item)
                else
                    for _, t in ipairs(assetTypes) do
                        if item.AssetType == t.Name then
                            table.insert(result, item)
                            break
                        end
                    end
                end
            end
        end
    end
    return result
end

return ArtistCatalog
