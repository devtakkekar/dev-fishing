--[[ Per-player fish discovery log (Fish Index), persisted as JSON in dev_fishing.discovered ]]

Discovery = {}

local cache = {} -- citizenid -> { [item] = true }

local function load(citizenid)
    if cache[citizenid] then return cache[citizenid] end

    local raw = MySQL.scalar.await('SELECT discovered FROM dev_fishing WHERE citizenid = ?', { citizenid })
    local set = {}
    if raw then
        local list = json.decode(raw)
        if list then
            for _, item in ipairs(list) do set[item] = true end
        end
    end
    cache[citizenid] = set
    return set
end

local function save(citizenid)
    local list = {}
    for item in pairs(cache[citizenid]) do
        list[#list + 1] = item
    end
    MySQL.prepare(
        'INSERT INTO dev_fishing (citizenid, xp, discovered) VALUES (?, 0, ?) ON DUPLICATE KEY UPDATE discovered = VALUES(discovered)',
        { citizenid, json.encode(list) }
    )
end

---@return table set of discovered item names
function Discovery.GetAll(citizenid)
    return load(citizenid)
end

--- Record a catch in the index
---@return boolean isNew true if this is the first time the item was caught
function Discovery.Add(citizenid, item)
    local set = load(citizenid)
    if set[item] then return false end
    set[item] = true
    save(citizenid)
    return true
end

--- Has the player discovered every item in the given tier?
---@param tier table a Config.LootTiers entry
function Discovery.HasCompletedTier(citizenid, tier)
    local set = load(citizenid)
    for _, it in ipairs(tier.items) do
        if not set[it.item] then return false end
    end
    return true
end

--- Wipe a player's discovery log (admin)
function Discovery.Reset(citizenid)
    cache[citizenid] = {}
    save(citizenid)
end
