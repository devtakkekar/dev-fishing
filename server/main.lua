local QBCore = exports['qb-core']:GetCoreObject()

local casts = {}     -- src -> { token, time }
local lastCatch = {} -- src -> game timer of last catch

local function notify(src, msg, type)
    TriggerClientEvent('ox_lib:notify', src, { title = L('notify_title'), description = msg, type = type or 'inform' })
end

-- ────────────────────────────────────────────────
-- Useable items
-- ────────────────────────────────────────────────
QBCore.Functions.CreateUseableItem(Config.RodItem, function(source)
    TriggerClientEvent('dev-fishing:client:useRod', source)
end)

-- Useable bait: starts a single cast (rod must be equipped client-side)
QBCore.Functions.CreateUseableItem(Config.BaitItem, function(source)
    TriggerClientEvent('dev-fishing:client:useBait', source)
end)

-- ────────────────────────────────────────────────
-- Casting (server validates rod/bait, consumes bait, issues a one-time token)
-- ────────────────────────────────────────────────
lib.callback.register('dev-fishing:server:startCast', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end

    if Inventory.GetItemCount(source, Config.RodItem) < 1 then
        notify(source, L('need_rod'), 'error')
        return false
    end

    if Config.BaitRequired then
        if Inventory.GetItemCount(source, Config.BaitItem) < 1 then
            notify(source, L('no_bait'), 'error')
            return false
        end
        Inventory.RemoveItem(source, Config.BaitItem, 1)
    end

    local token = ('%d-%d'):format(math.random(100000, 999999), GetGameTimer())
    casts[source] = {
        token = token,
        time = GetGameTimer(),
        coords = GetEntityCoords(GetPlayerPed(source)), -- anticheat: position locked at cast
    }
    return token
end)

-- ────────────────────────────────────────────────
-- Catch (token + timing + cooldown validated server-side)
-- ────────────────────────────────────────────────
RegisterNetEvent('dev-fishing:server:catch', function(token)
    local src = source
    local cast = casts[src]
    casts[src] = nil

    if not cast or cast.token ~= token then return end
    if (GetGameTimer() - cast.time) < Config.FishingTime.min then return end
    if lastCatch[src] and (GetGameTimer() - lastCatch[src]) < Config.CatchCooldown then return end

    -- Anticheat: reject the catch if the player moved too far from where they cast
    if #(GetEntityCoords(GetPlayerPed(src)) - cast.coords) > Config.MaxCastDrift then return end

    lastCatch[src] = GetGameTimer()

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if Inventory.GetItemCount(src, Config.RodItem) < 1 then return end

    local citizenid = Player.PlayerData.citizenid
    local oldXP = FishingXP.Get(citizenid)
    local oldLevel = FishingXP.GetLevel(oldXP)

    local loot = Loot.Roll(oldLevel.level)
    if not loot then return end

    if not Inventory.AddItem(src, loot.item, 1) then
        notify(src, L('pockets_full'), 'error')
        return
    end

    notify(src, L('caught', loot.label), 'success')

    -- Fish index / discovery
    local bonusXP = 0
    if Discovery.Add(citizenid, loot.item) then
        notify(src, L('new_discovery', loot.label), 'success')

        local tier = Loot.ItemTier[loot.item]
        if tier and (tier.bonusXP or 0) > 0 and Discovery.HasCompletedTier(citizenid, tier) then
            bonusXP = tier.bonusXP
            notify(src, L('tier_completed', tier.name, bonusXP), 'success')
        end
    end

    -- Lifetime stats (totals, rarest catch, session streak)
    Stats.AddCatch(src, citizenid, loot.item, Loot.TierIndex[loot.item] or 0)

    -- XP gain + optional per-catch XP notification
    local totalGain = (loot.xp or 0) + bonusXP
    local newXP = FishingXP.Add(citizenid, totalGain)
    local newLevel = FishingXP.GetLevel(newXP)

    if Config.NotifyXPGain then
        notify(src, L('xp_gain', totalGain, newXP))
    end

    if newLevel.level > oldLevel.level then
        notify(src, L('level_up', newLevel.name, newLevel.level), 'success')
    end

    -- Global chat broadcast for special catches: "<name> <msg>"
    if loot.globalNotify then
        local info = Player.PlayerData.charinfo
        local name = ('%s %s'):format(info.firstname, info.lastname)
        TriggerClientEvent('chat:addMessage', -1, {
            color = { 255, 170, 0 },
            multiline = true,
            args = { L('lucky_catch_title'), ('%s %s'):format(name, loot.msg or L('found_a', loot.label)) },
        })
    end

    -- Discord webhook: catches (every catch if logAllCatches, rare ones highlighted)
    local isRare = loot.globalNotify == true
    if Config.Webhook.logAllCatches or (isRare and Config.Webhook.logRareCatches) then
        local info = Player.PlayerData.charinfo
        Webhook.Send(isRare and '⭐ Rare Catch' or 'Catch',
            ('**%s %s** (`%s`) caught **%s** | +%d XP (total %d)'):format(
                info.firstname, info.lastname, citizenid, loot.label, (loot.xp or 0) + bonusXP, newXP),
            isRare and 16755200 or 5763719)
    end

    -- Rod durability
    if Config.RodBreakChance > 0 and math.random(100) <= Config.RodBreakChance then
        Inventory.RemoveItem(src, Config.RodItem, 1)
        notify(src, L('rod_snapped'), 'error')
        TriggerClientEvent('dev-fishing:client:stop', src)
    end
end)

-- ────────────────────────────────────────────────
-- Selling
-- ────────────────────────────────────────────────
lib.callback.register('dev-fishing:server:getSellables', function(source)
    local result = {}
    for item, data in pairs(Loot.Items) do
        if (data.price or 0) > 0 then
            local count = Inventory.GetItemCount(source, item)
            if count > 0 then
                result[#result + 1] = { item = item, label = data.label, count = count, price = Loot.GetPrice(item) }
            end
        end
    end
    table.sort(result, function(a, b) return a.label < b.label end)
    return result
end)

-- Fish Index: XP summary + tiers with per-item discovery state (undiscovered items are masked)
lib.callback.register('dev-fishing:server:getIndex', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return nil end

    local citizenid = Player.PlayerData.citizenid

    -- XP summary with progress towards the next level (0-100)
    local xp = FishingXP.Get(citizenid)
    local current, nextLevel = FishingXP.GetLevel(xp)
    local progress = 100
    if nextLevel then
        progress = math.floor(((xp - current.xp) / (nextLevel.xp - current.xp)) * 100)
        progress = math.max(0, math.min(100, progress))
    end

    local discovered = Discovery.GetAll(citizenid)
    local tiers = {}
    for _, tier in ipairs(Config.LootTiers) do
        local entries, found = {}, 0
        for _, it in ipairs(tier.items) do
            local isFound = discovered[it.item] == true
            if isFound then found = found + 1 end
            entries[#entries + 1] = { label = isFound and it.label or '???', discovered = isFound }
        end
        tiers[#tiers + 1] = {
            name = tier.name,
            bonusXP = tier.bonusXP or 0,
            total = #tier.items,
            found = found,
            items = entries,
        }
    end

    return {
        xp = {
            total = xp,
            level = current.level,
            name = current.name,
            nextXP = nextLevel and nextLevel.xp or nil,
            progress = progress,
        },
        tiers = tiers,
    }
end)

local function sellSingle(src, Player, item)
    local price = Loot.GetPrice(item) -- dynamic market price
    if price <= 0 then return 0 end

    local count = Inventory.GetItemCount(src, item)
    if count < 1 then return 0 end
    if not Inventory.RemoveItem(src, item, count) then return 0 end

    local total = count * price
    Player.Functions.AddMoney('cash', total, 'dev-fishing-sale')
    return total
end

RegisterNetEvent('dev-fishing:server:sellItem', function(item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local total = 0
    if item == 'all' then
        for name in pairs(Loot.Items) do
            total = total + sellSingle(src, Player, name)
        end
    elseif type(item) == 'string' then
        total = sellSingle(src, Player, item)
    end

    if total > 0 then
        notify(src, L('sold_for', total), 'success')
        Stats.AddEarned(Player.PlayerData.citizenid, total)

        -- Discord webhook: sales (every sale if logAllSales, big ones highlighted)
        local isBig = Config.Webhook.bigSaleThreshold > 0 and total >= Config.Webhook.bigSaleThreshold
        if Config.Webhook.logAllSales or isBig then
            local info = Player.PlayerData.charinfo
            Webhook.Send(isBig and '💰 Big Sale' or 'Sale',
                ('**%s %s** (`%s`) sold catches for **$%d**'):format(info.firstname, info.lastname, Player.PlayerData.citizenid, total),
                isBig and 15844367 or 5763719)
        end
    else
        notify(src, L('nothing_to_sell'), 'error')
    end
end)

-- ────────────────────────────────────────────────
-- Buying (prices validated server-side from config)
-- ────────────────────────────────────────────────
RegisterNetEvent('dev-fishing:server:buyItem', function(index, quantity)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local entry = Config.Peds.buy.shop[index]
    quantity = math.floor(tonumber(quantity) or 0)
    if not entry or quantity < 1 or quantity > 50 then return end

    local total = entry.price * quantity
    if not Player.Functions.RemoveMoney('cash', total, 'dev-fishing-shop') then
        notify(src, L('need_cash', total), 'error')
        return
    end

    if not Inventory.AddItem(src, entry.item, quantity) then
        Player.Functions.AddMoney('cash', total, 'dev-fishing-refund')
        notify(src, L('cannot_carry'), 'error')
        return
    end

    notify(src, L('bought', quantity, entry.label, total), 'success')
end)

-- ────────────────────────────────────────────────
-- Boat rental (deposit held server-side, refunded on dock return)
-- ────────────────────────────────────────────────
local rentals = {}

lib.callback.register('dev-fishing:server:rentBoat', function(source)
    if not Config.Boat.enabled then return false end
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end

    if rentals[source] then
        notify(source, L('already_rented'), 'error')
        return false
    end
    if not Player.Functions.RemoveMoney('cash', Config.Boat.deposit, 'dev-fishing-boat-deposit') then
        notify(source, L('need_cash', Config.Boat.deposit), 'error')
        return false
    end

    rentals[source] = true
    return true
end)

RegisterNetEvent('dev-fishing:server:returnBoat', function(refund)
    local src = source
    if not rentals[src] then return end
    rentals[src] = nil

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if refund then
        Player.Functions.AddMoney('cash', Config.Boat.deposit, 'dev-fishing-boat-refund')
        notify(src, L('boat_returned', Config.Boat.deposit), 'success')
    else
        notify(src, L('boat_lost'), 'error')
    end
end)

-- ────────────────────────────────────────────────
-- /fishingxp command
-- ────────────────────────────────────────────────
QBCore.Commands.Add('fishingxp', 'Check your fishing XP and level', {}, false, function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    local xp = FishingXP.Get(Player.PlayerData.citizenid)
    local current, nextLevel = FishingXP.GetLevel(xp)
    local progress = nextLevel
        and L('xp_progress', xp, nextLevel.xp, nextLevel.name)
        or L('max_level')

    notify(source, L('xp_status', current.level, current.name, xp, progress))
end)

-- ────────────────────────────────────────────────
-- Leaderboard
-- ────────────────────────────────────────────────
lib.callback.register('dev-fishing:server:getLeaderboard', function()
    local rows = MySQL.query.await([[
        SELECT p.charinfo, f.xp
        FROM dev_fishing f
        JOIN players p ON p.citizenid = f.citizenid
        ORDER BY f.xp DESC
        LIMIT ?
    ]], { Config.LeaderboardLimit })

    local result = {}
    for _, row in ipairs(rows or {}) do
        local info = json.decode(row.charinfo) or {}
        local level = FishingXP.GetLevel(row.xp)
        result[#result + 1] = {
            name = ('%s %s'):format(info.firstname or '?', info.lastname or ''),
            xp = row.xp,
            level = level.level,
            rank = level.name,
        }
    end
    return result
end)

QBCore.Commands.Add('fishingtop', 'View the top anglers', {}, false, function(source)
    TriggerClientEvent('dev-fishing:client:openLeaderboard', source)
end)

-- ────────────────────────────────────────────────
-- /fishingstats command
-- ────────────────────────────────────────────────
lib.callback.register('dev-fishing:server:getStats', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return nil end

    local stats = Stats.Get(Player.PlayerData.citizenid)
    local rarest = stats.rarest and Loot.Items[stats.rarest]
    return {
        catches = stats.catches or 0,
        earned = stats.earned or 0,
        rarest = rarest and rarest.label or nil,
        beststreak = stats.beststreak or 0,
    }
end)

QBCore.Commands.Add('fishingstats', 'View your lifetime fishing stats', {}, false, function(source)
    TriggerClientEvent('dev-fishing:client:openStats', source)
end)

-- ────────────────────────────────────────────────
-- Admin commands
-- ────────────────────────────────────────────────
local function reply(src, msg, type)
    if src and src > 0 then
        notify(src, msg, type)
    else
        print('[dev-fishing] ' .. msg)
    end
end

QBCore.Commands.Add('setfishingxp', "Set a player's fishing XP (Admin)", {
    { name = 'id', help = 'Player server ID' },
    { name = 'amount', help = 'XP amount' },
}, true, function(source, args)
    local target = QBCore.Functions.GetPlayer(tonumber(args[1]))
    local amount = tonumber(args[2])
    if not target or not amount or amount < 0 then
        return reply(source, L('invalid_args'), 'error')
    end

    FishingXP.Set(target.PlayerData.citizenid, amount)
    reply(source, L('set_xp_ok', args[1], amount), 'success')
    notify(target.PlayerData.source, L('xp_was_set', amount))
end, 'admin')

QBCore.Commands.Add('resetindex', "Reset a player's fish index (Admin)", {
    { name = 'id', help = 'Player server ID' },
}, true, function(source, args)
    local target = QBCore.Functions.GetPlayer(tonumber(args[1]))
    if not target then
        return reply(source, L('player_not_found'), 'error')
    end

    Discovery.Reset(target.PlayerData.citizenid)
    reply(source, L('reset_index_ok', args[1]), 'success')
end, 'admin')

-- Debug: simulate a rare catch to test the global chat broadcast + webhook.
-- Does NOT give items or XP. Requires Config.Debug = true.
QBCore.Commands.Add('testcatch', 'Simulate a rare catch broadcast (Admin, Debug only)', {
    { name = 'item', help = 'Loot item name (default: lottery_ticket)' },
}, false, function(source, args)
    if not Config.Debug then
        return reply(source, L('enable_debug'), 'error')
    end

    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    local item = args[1] or 'lottery_ticket'
    local loot = Loot.Items[item]
    if not loot then
        return reply(source, L('unknown_item', item), 'error')
    end
    if not loot.globalNotify then
        return reply(source, L('no_global_notify', loot.label), 'error')
    end

    local info = Player.PlayerData.charinfo
    local name = ('%s %s'):format(info.firstname, info.lastname)

    TriggerClientEvent('chat:addMessage', -1, {
        color = { 255, 170, 0 },
        multiline = true,
        args = { L('lucky_catch_title'), ('%s %s'):format(name, loot.msg or L('found_a', loot.label)) },
    })

    if Config.Webhook.logRareCatches then
        Webhook.Send('⭐ Rare Catch (TEST)',
            ('**%s** (`%s`) test-broadcast **%s**'):format(name, Player.PlayerData.citizenid, loot.label),
            16755200)
    end

    reply(source, L('broadcast_sent', loot.label), 'success')
end, 'admin')

-- ────────────────────────────────────────────────
-- Cleanup
-- ────────────────────────────────────────────────
AddEventHandler('playerDropped', function()
    local src = source
    casts[src] = nil
    lastCatch[src] = nil
    rentals[src] = nil -- abandoned rental: deposit forfeited
    Stats.ClearSession(src)
end)
