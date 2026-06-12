--[[ Weighted, level-gated loot rolling ]]

Loot = { Items = {}, ItemTier = {}, TierIndex = {} }

-- Flat lookups (sell prices, validation, tier/rarity resolution)
for i, tier in ipairs(Config.LootTiers) do
    for _, it in ipairs(tier.items) do
        Loot.Items[it.item] = it
        Loot.ItemTier[it.item] = tier
        Loot.TierIndex[it.item] = i -- higher = rarer
    end
end

---@param entries table[] entries with a numeric `weight`
---@return table|nil picked
local function weightedPick(entries)
    local total = 0
    for _, e in ipairs(entries) do
        total = total + (e.weight or 0)
    end
    if total <= 0 then return nil end

    local roll = math.random(total)
    local acc = 0
    for _, e in ipairs(entries) do
        acc = acc + (e.weight or 0)
        if roll <= acc then return e end
    end
end

--- Roll loot for a given fishing level. Tiers above the player's level never drop.
--- When `boosted` is true (hot streak), tiers above common get their weight
--- multiplied by Config.HotStreak.rareTierBoost, increasing rare odds.
---@param level number
---@param boosted boolean|nil
---@return table|nil item
function Loot.Roll(level, boosted)
    local eligible = {}
    for i, tier in ipairs(Config.LootTiers) do
        if level >= (tier.minLevel or 1) then
            local weight = tier.weight or 0
            if boosted and i > 1 then
                weight = math.floor(weight * (Config.HotStreak.rareTierBoost or 1.0) + 0.5)
            end
            eligible[#eligible + 1] = { weight = weight, items = tier.items }
        end
    end

    local tier = weightedPick(eligible)
    if not tier then return nil end
    return weightedPick(tier.items)
end

-- ────────────────────────────────────────────────
-- Dynamic market: per-item sell price multipliers, refreshed on a timer
-- ────────────────────────────────────────────────
local multipliers = {}

local function refreshMarket()
    local v = Config.DynamicPrices.variance
    for item, data in pairs(Loot.Items) do
        if (data.price or 0) > 0 then
            multipliers[item] = 1.0 + (math.random(-v, v) / 100)
        end
    end
end

--- Current sell price for an item (base price +/- market variance)
---@param item string
---@return number price 0 if the item cannot be sold
function Loot.GetPrice(item)
    local data = Loot.Items[item]
    if not data or (data.price or 0) <= 0 then return 0 end
    if not Config.DynamicPrices.enabled then return data.price end
    return math.max(1, math.floor(data.price * (multipliers[item] or 1.0)))
end

CreateThread(function()
    if not Config.DynamicPrices.enabled then return end
    refreshMarket()
    while true do
        Wait(Config.DynamicPrices.interval * 60000)
        refreshMarket()
    end
end)
