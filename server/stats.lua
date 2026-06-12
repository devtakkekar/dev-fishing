--[[ Lifetime fishing statistics, persisted as JSON in dev_fishing.stats ]]

Stats = {}

local cache = {}   -- citizenid -> stats table
local streaks = {} -- src -> { count, last } (session catch streaks)

local STREAK_TIMEOUT = 10 * 60 * 1000 -- streak resets after 10 min without a catch

local function default()
    return { catches = 0, earned = 0, rarest = nil, rarestTier = 0, beststreak = 0 }
end

local function load(citizenid)
    if cache[citizenid] then return cache[citizenid] end

    local raw = MySQL.scalar.await('SELECT stats FROM dev_fishing WHERE citizenid = ?', { citizenid })
    local stats = raw and json.decode(raw) or nil
    if type(stats) ~= 'table' then stats = default() end
    cache[citizenid] = stats
    return stats
end

local function save(citizenid)
    MySQL.prepare(
        'INSERT INTO dev_fishing (citizenid, xp, stats) VALUES (?, 0, ?) ON DUPLICATE KEY UPDATE stats = VALUES(stats)',
        { citizenid, json.encode(cache[citizenid]) }
    )
end

function Stats.Get(citizenid)
    return load(citizenid)
end

--- Record a catch: totals, rarest catch (by tier index) and session streak
function Stats.AddCatch(src, citizenid, item, tierIndex)
    local stats = load(citizenid)
    stats.catches = (stats.catches or 0) + 1

    if (tierIndex or 0) > (stats.rarestTier or 0) then
        stats.rarestTier = tierIndex
        stats.rarest = item
    end

    local now = GetGameTimer()
    local streak = streaks[src]
    if not streak or (now - streak.last) > STREAK_TIMEOUT then
        streak = { count = 0, last = now }
        streaks[src] = streak
    end
    streak.count = streak.count + 1
    streak.last = now
    if streak.count > (stats.beststreak or 0) then
        stats.beststreak = streak.count
    end

    save(citizenid)
end

function Stats.AddEarned(citizenid, amount)
    local stats = load(citizenid)
    stats.earned = (stats.earned or 0) + amount
    save(citizenid)
end

function Stats.ClearSession(src)
    streaks[src] = nil
end
