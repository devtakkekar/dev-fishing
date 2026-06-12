Config = {}

-- ────────────────────────────────────────────────
-- Framework bridges
-- ────────────────────────────────────────────────
Config.Inventory = 'auto'   -- 'qb' | 'ox' | 'auto' (auto-detects ox_inventory, falls back to qb-inventory)
Config.Target    = 'auto'   -- 'qb' | 'ox' | 'auto' (auto-detects ox_target, falls back to qb-target)

Config.Debug = false        -- enables /testcatch [item] (admin) to test global chat notify + webhook without giving loot

Config.Locale = 'en'        -- language file from locales/ (e.g. 'en')

-- ────────────────────────────────────────────────
-- Items
-- ────────────────────────────────────────────────
Config.RodItem        = 'fishingrod'
Config.BaitItem       = 'fishbait'
Config.BaitRequired   = true   -- consume 1 bait per cast
Config.RodBreakChance = 4      -- % chance the rod snaps after a catch (0 = never)

-- ────────────────────────────────────────────────
-- Gameplay
-- ────────────────────────────────────────────────
Config.FishingTime   = { min = 6000, max = 10000 } -- ms per cast (random between min/max)
Config.CatchCooldown = 4000                        -- server-side anti-spam between catches (ms)
Config.RequireWater  = true                        -- player must be facing open water to fish
Config.MaxCastDrift  = 20.0                        -- anticheat: max metres a player may move between cast and catch

-- ────────────────────────────────────────────────
-- Hot streak (catch counter UI while the rod is equipped)
-- Every catch fills the meter; the final catch of the streak rolls loot with
-- boosted odds for rarer tiers, then the meter resets and the cycle repeats.
-- Unequipping the rod resets the streak. /clearfshingui hides a stuck UI.
-- ────────────────────────────────────────────────
Config.HotStreak = {
    enabled = true,
    catches = 10,        -- catches needed to fill the meter (the Nth catch is boosted)
    rareTierBoost = 3.0, -- weight multiplier applied to every tier above common on the boosted catch
}

-- ────────────────────────────────────────────────
-- Reel-in minigame (runs when a fish bites; fail = fish gets away)
-- ────────────────────────────────────────────────
Config.Minigame = {
    enabled = true,
    type = 'skillcheck',                       -- built-in: ox_lib skillCheck
    difficulty = { 'easy', 'easy', 'medium' }, -- ox_lib skillCheck difficulty stages
    keys = { 'w', 'a', 's', 'd' },             -- ox_lib skillCheck input keys

    -- Use a different minigame from another resource (must return true on success):
    -- e.g. { resource = 'ps-ui', export = 'Circle' }
    custom = {
        resource = 'bl_ui',
        export = 'CircleProgress',
        colon = true,   -- Set to true if the export expects colon syntax (e.g. bl_ui:CircleProgress)
        iterations = 3, -- Default iterations (amount of times to complete)
        difficulty = 50 -- Default difficulty (1-100, affects circle speed)
    },
}

-- ────────────────────────────────────────────────
-- XP / Leveling
-- ────────────────────────────────────────────────
Config.NotifyXPGain = true -- notify XP gained + updated total XP on every catch

-- Levels gate the loot tiers (see config/loot.lua -> minLevel)
Config.Levels = {
    { level = 1, name = 'Novice',  xp = 0 },
    { level = 2, name = 'Amateur', xp = 100 },
    { level = 3, name = 'Skilled', xp = 350 },
    { level = 4, name = 'Expert',  xp = 800 },
    { level = 5, name = 'Master',  xp = 1600 },
}

-- ────────────────────────────────────────────────
-- Leaderboard
-- ────────────────────────────────────────────────
Config.LeaderboardLimit = 10 -- entries shown in /fishingtop and the ped menu

-- ────────────────────────────────────────────────
-- Dynamic market prices (anti-botting: sell prices fluctuate)
-- ────────────────────────────────────────────────
Config.DynamicPrices = {
    enabled = true,
    variance = 15, -- max +/- % applied to base sell prices
    interval = 60, -- minutes between market refreshes (also refreshes on restart)
}

-- ────────────────────────────────────────────────
-- Discord webhook logging (anti-exploit auditing)
-- ────────────────────────────────────────────────
Config.Webhook = {
    enabled = false,
    url = '',                -- Discord webhook URL
    logAllCatches = true,    -- log EVERY catch (item + XP)
    logRareCatches = true,   -- log catches that have globalNotify = true (highlighted)
    logAllSales = true,      -- log EVERY sale at the sell ped
    bigSaleThreshold = 1000, -- highlight sales >= this amount ($); 0 = no highlight
}

-- ────────────────────────────────────────────────
-- Boat rental (deposit refunded when the boat is returned to the dock)
-- ────────────────────────────────────────────────
Config.Boat = {
    enabled = true,
    model = 'dinghy',
    deposit = 500,       -- $ taken on rent, refunded on return
    returnRadius = 40.0, -- boat must be within this range of the spawn point to return it
    spawn = vector4(-1625.44, -1146.6, 0.76, 127.32), -- water spawn point near the boat ped
}

-- ────────────────────────────────────────────────
-- Version checker (console notice when a newer version is available)
-- ────────────────────────────────────────────────
Config.VersionCheck = {
    enabled = false,
    url = '', -- raw URL of a text file containing the latest version string
}
