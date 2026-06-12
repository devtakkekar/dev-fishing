local spawnedPeds = {}

local function notify(msg, type)
    lib.notify({ title = L('notify_title'), description = msg, type = type or 'inform' })
end

-- ────────────────────────────────────────────────
-- Menus
-- ────────────────────────────────────────────────
local function openBuyMenu()
    local options = {}
    for i, entry in ipairs(Config.Peds.buy.shop) do
        options[#options + 1] = {
            title = entry.label,
            description = L('price_each', entry.price),
            icon = 'sack-dollar',
            onSelect = function()
                local input = lib.inputDialog(L('buy_prompt', entry.label), {
                    { type = 'number', label = L('quantity'), default = 1, min = 1, max = 50, required = true },
                })
                if input and input[1] then
                    TriggerServerEvent('dev-fishing:server:buyItem', i, math.floor(input[1]))
                end
            end,
        }
    end
    lib.registerContext({ id = 'dev_fishing_shop', title = L('shop_title'), options = options })
    lib.showContext('dev_fishing_shop')
end

local function openSellMenu()
    local sellables = lib.callback.await('dev-fishing:server:getSellables', false)
    if not sellables or #sellables == 0 then
        return notify(L('nothing_to_sell_menu'), 'error')
    end

    local options = {
        {
            title = L('sell_everything'),
            description = L('sell_everything_desc'),
            icon = 'money-bill-wave',
            onSelect = function()
                TriggerServerEvent('dev-fishing:server:sellItem', 'all')
            end,
        },
    }
    for _, entry in ipairs(sellables) do
        options[#options + 1] = {
            title = ('%s (x%d)'):format(entry.label, entry.count),
            description = L('price_each_total', entry.price, entry.price * entry.count),
            icon = 'fish',
            onSelect = function()
                TriggerServerEvent('dev-fishing:server:sellItem', entry.item)
            end,
        }
    end
    lib.registerContext({ id = 'dev_fishing_sell', title = L('sell_title'), options = options })
    lib.showContext('dev_fishing_sell')
end

local function capitalize(s)
    return s:sub(1, 1):upper() .. s:sub(2)
end

local function openIndexMenu()
    local index = lib.callback.await('dev-fishing:server:getIndex', false)
    if not index then return end

    -- XP summary with a green progress bar towards the next level
    local xpInfo = index.xp
    local tierOptions = {
        {
            title = L('level_angler', xpInfo.level, xpInfo.name),
            description = xpInfo.nextXP
                and L('xp_to_next', xpInfo.total, xpInfo.nextXP)
                or L('xp_max', xpInfo.total),
            icon = 'star',
            progress = xpInfo.progress,
            colorScheme = 'green',
            readOnly = true,
        },
    }
    for i, tier in ipairs(index.tiers) do
        local title = L('tier_progress', capitalize(tier.name), tier.found, tier.total)

        -- Submenu listing each fish in the tier ('???' until discovered)
        local itemOptions = {}
        for _, entry in ipairs(tier.items) do
            itemOptions[#itemOptions + 1] = {
                title = entry.label,
                icon = entry.discovered and 'fish' or 'question',
                disabled = not entry.discovered,
            }
        end
        lib.registerContext({
            id = 'dev_fishing_index_' .. i,
            title = title,
            menu = 'dev_fishing_index',
            options = itemOptions,
        })

        local completed = tier.found >= tier.total
        tierOptions[#tierOptions + 1] = {
            title = title,
            description = completed and L('completed')
                or (tier.bonusXP > 0 and L('discover_bonus', tier.bonusXP) or nil),
            icon = completed and 'check' or 'book-open',
            menu = 'dev_fishing_index_' .. i,
        }
    end

    lib.registerContext({ id = 'dev_fishing_index', title = L('index_title'), options = tierOptions })
    lib.showContext('dev_fishing_index')
end

local function openLeaderboard()
    local rows = lib.callback.await('dev-fishing:server:getLeaderboard', false)
    if not rows or #rows == 0 then
        return notify(L('no_anglers'), 'error')
    end

    local medals = { '🥇', '🥈', '🥉' }
    local options = {}
    for i, row in ipairs(rows) do
        options[#options + 1] = {
            title = ('%s %s'):format(medals[i] or ('#%d'):format(i), row.name),
            description = L('leaderboard_entry', row.level, row.rank, row.xp),
            icon = 'trophy',
            readOnly = true,
        }
    end

    lib.registerContext({ id = 'dev_fishing_top', title = L('top_title'), options = options })
    lib.showContext('dev_fishing_top')
end

RegisterNetEvent('dev-fishing:client:openLeaderboard', openLeaderboard)

local function openStats()
    local stats = lib.callback.await('dev-fishing:server:getStats', false)
    if not stats then return end

    lib.registerContext({
        id = 'dev_fishing_stats',
        title = L('stats_title'),
        options = {
            { title = L('stats_catches'), description = tostring(stats.catches), icon = 'fish', readOnly = true },
            { title = L('stats_earned'), description = ('$%d'):format(stats.earned), icon = 'money-bill-wave', readOnly = true },
            { title = L('stats_rarest'), description = stats.rarest or L('stats_none'), icon = 'gem', readOnly = true },
            { title = L('stats_streak'), description = tostring(stats.beststreak), icon = 'fire', readOnly = true },
        },
    })
    lib.showContext('dev_fishing_stats')
end

RegisterNetEvent('dev-fishing:client:openStats', openStats)

-- ────────────────────────────────────────────────
-- Boat rental
-- ────────────────────────────────────────────────
local rentedBoat = nil

local function rentBoat()
    if rentedBoat and DoesEntityExist(rentedBoat) then
        return notify(L('already_rented'), 'error')
    end

    -- Server takes the deposit and registers the rental
    local ok = lib.callback.await('dev-fishing:server:rentBoat', false)
    if not ok then return end

    local model = joaat(Config.Boat.model)
    lib.requestModel(model)
    local s = Config.Boat.spawn
    rentedBoat = CreateVehicle(model, s.x, s.y, s.z, s.w, true, false)
    SetVehicleHasBeenOwnedByPlayer(rentedBoat, true)
    SetModelAsNoLongerNeeded(model)
    notify(L('boat_rented', Config.Boat.deposit), 'success')
end

local function returnBoat()
    if not rentedBoat then
        return notify(L('no_rental'), 'error')
    end

    if not DoesEntityExist(rentedBoat) then
        -- Boat destroyed/lost: clear the rental without a refund
        rentedBoat = nil
        TriggerServerEvent('dev-fishing:server:returnBoat', false)
        return
    end

    local s = Config.Boat.spawn
    if #(GetEntityCoords(rentedBoat) - vec3(s.x, s.y, s.z)) > Config.Boat.returnRadius then
        return notify(L('boat_too_far'), 'error')
    end

    DeleteEntity(rentedBoat)
    rentedBoat = nil
    TriggerServerEvent('dev-fishing:server:returnBoat', true)
end

-- ────────────────────────────────────────────────
-- Ped + blip spawning
-- ────────────────────────────────────────────────
local function spawnPed(data, options)
    local model = joaat(data.model)
    lib.requestModel(model)

    local ped = CreatePed(0, model, data.coords.x, data.coords.y, data.coords.z - 1.0, data.coords.w, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetModelAsNoLongerNeeded(model)
    spawnedPeds[#spawnedPeds + 1] = ped

    Target.AddPed(ped, options)

    if data.blip then
        local blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
        SetBlipSprite(blip, data.blip.sprite)
        SetBlipColour(blip, data.blip.color)
        SetBlipScale(blip, data.blip.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(data.blip.label)
        EndTextCommandSetBlipName(blip)
    end
end

CreateThread(function()
    spawnPed(Config.Peds.buy, {
        { label = L('target_shop'), icon = 'fas fa-shopping-basket', onSelect = openBuyMenu },
        { label = L('target_index'), icon = 'fas fa-book-open', onSelect = openIndexMenu },
        { label = L('target_top'), icon = 'fas fa-trophy', onSelect = openLeaderboard },
    })
    spawnPed(Config.Peds.sell, {
        { label = L('target_sell'), icon = 'fas fa-dollar-sign', onSelect = openSellMenu },
    })
    if Config.Boat.enabled and Config.Peds.boat then
        spawnPed(Config.Peds.boat, {
            { label = L('target_boat_rent'), icon = 'fas fa-ship', onSelect = rentBoat },
            { label = L('target_boat_return'), icon = 'fas fa-anchor', onSelect = returnBoat },
        })
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
    if rentedBoat and DoesEntityExist(rentedBoat) then DeleteEntity(rentedBoat) end
end)
