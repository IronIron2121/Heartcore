--!strict

-- Services
local AvatarEditorService = game:GetService("AvatarEditorService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))


local EditorsPick = {}

EditorsPick.ids = {
    {
        id = 192557913, -- Sparkling Angel Wings
        itemType = Enum.AvatarItemType.Asset
    },

    {
        id = 85956071743151, -- Black Sparkling Angel Wings 
        itemType = Enum.AvatarItemType.Asset
    },

    {
        id = 299, -- Superhero
        itemType = Enum.AvatarItemType.Bundle 
    },

    {
        id = 306, -- pirate swashbuckler
        itemType = Enum.AvatarItemType.Bundle 
    },

    {
        id = 191101707, -- flaming mohawk
        itemType = Enum.AvatarItemType.Asset
    },

    {
        id = 592, -- Davy Bazooka
        itemType = Enum.AvatarItemType.Bundle
    },

    {
        id = 390970950, -- Paper Tix Hat
        itemType = Enum.AvatarItemType.Asset
    },

    {
        id = 21025037, -- Wintertime R&R&R
        itemType = Enum.AvatarItemType.Asset
    },

    {
        id = 1567446, -- Verified Sign
        itemType = Enum.AvatarItemType.Asset
    },

}

EditorsPick.itemDetails = {}

function EditorsPick.initialiseItemDetails()
    for _, info in ipairs(EditorsPick.ids) do
        local success, itemDetails = callWithRetry(
            function()  
                return AvatarEditorService:GetItemDetailsAsync(info.id, info.itemType)
            end
        ) 
        if success and itemDetails then
            table.insert(EditorsPick.itemDetails, itemDetails)
        else
            warn("Failed to get details for", info, info.id, info.itemType)
            warn(success, itemDetails)
        end
    end
end

return EditorsPick