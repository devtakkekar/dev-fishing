--[[ Persistent fishing XP (oxmysql), cached in memory ]]

FishingXP = {}

local cache = {}

CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `dev_fishing` (
            `citizenid` VARCHAR(64) NOT NULL,
            `xp` INT UNSIGNED NOT NULL DEFAULT 0,
            `discovered` LONGTEXT NULL,
            `stats` LONGTEXT NULL,
            PRIMARY KEY (`citizenid`)
        )
    ]])
    -- migrate older installs (errors if the column already exists, which is fine)
    pcall(MySQL.query.await, 'ALTER TABLE `dev_fishing` ADD COLUMN `discovered` LONGTEXT NULL')
    pcall(MySQL.query.await, 'ALTER TABLE `dev_fishing` ADD COLUMN `stats` LONGTEXT NULL')
end)

---@param citizenid string
---@return number xp
function FishingXP.Get(citizenid)
    if cache[citizenid] then return cache[citizenid] end
    local xp = MySQL.scalar.await('SELECT xp FROM dev_fishing WHERE citizenid = ?', { citizenid }) or 0
    cache[citizenid] = xp
    return xp
end

---@param citizenid string
---@param amount number
---@return number newXP
function FishingXP.Add(citizenid, amount)
    local newXP = FishingXP.Get(citizenid) + (amount or 0)
    cache[citizenid] = newXP
    MySQL.prepare(
        'INSERT INTO dev_fishing (citizenid, xp) VALUES (?, ?) ON DUPLICATE KEY UPDATE xp = VALUES(xp)',
        { citizenid, newXP }
    )
    return newXP
end

--- Resolve the level (and next level) for a given XP amount
---@param xp number
---@return table current
---@return table|nil nextLevel
function FishingXP.GetLevel(xp)
    local current = Config.Levels[1]
    local nextLevel = nil
    for i = 1, #Config.Levels do
        if xp >= Config.Levels[i].xp then
            current = Config.Levels[i]
            nextLevel = Config.Levels[i + 1]
        end
    end
    return current, nextLevel
end

--- Overwrite a player's XP (admin)
---@param citizenid string
---@param amount number
function FishingXP.Set(citizenid, amount)
    amount = math.max(0, math.floor(amount or 0))
    cache[citizenid] = amount
    MySQL.prepare(
        'INSERT INTO dev_fishing (citizenid, xp) VALUES (?, ?) ON DUPLICATE KEY UPDATE xp = VALUES(xp)',
        { citizenid, amount }
    )
    return amount
end

-- ────────────────────────────────────────────────
-- Exports for other resources (crafting, restaurants, etc.)
-- ────────────────────────────────────────────────
exports('GetFishingXP', function(citizenid)
    return FishingXP.Get(citizenid)
end)

exports('AddFishingXP', function(citizenid, amount)
    return FishingXP.Add(citizenid, amount)
end)

exports('SetFishingXP', function(citizenid, amount)
    return FishingXP.Set(citizenid, amount)
end)

--- Returns level number, rank name (e.g. 3, 'Skilled')
exports('GetFishingLevel', function(citizenid)
    local current = FishingXP.GetLevel(FishingXP.Get(citizenid))
    return current.level, current.name
end)
