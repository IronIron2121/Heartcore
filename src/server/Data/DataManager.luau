local DataManager = {}

-- Store profiles from ProfileStore
DataManager.Profiles = {}

function DataManager.AddGold(player: Player, amount: number)
    local profile = DataManager.Profiles[player]

    if not profile or not player.leaderstats then
        return
    end

    profile.Data.Gold += amount
    player.leaderstats.Gold.Value = profile.Data.Gold 

end

function DataManager.AddGems(player: Player, amount: number)
    local profile = DataManager.Profiles[player]

    if not profile then
        return
    end

    profile.Data.Gems += amount
    player.leaderstats.Gems.Value = profile.Data.Gems
end


return DataManager