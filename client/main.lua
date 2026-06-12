local equipped = false
local casting = false
local rodProp = nil

local ANIM_DICT = 'amb@world_human_stand_fishing@idle_a'
local ANIM_NAME = 'idle_c'
local ROD_MODEL = `prop_fishing_rod_01`

local function notify(msg, type)
    lib.notify({ title = L('notify_title'), description = msg, type = type or 'inform' })
end

-- ────────────────────────────────────────────────
-- Hot streak UI (right-side ox_lib text UI while the rod is equipped)
-- ────────────────────────────────────────────────
local function showStreakUI(count)
    if not Config.HotStreak.enabled then return end
    local target = Config.HotStreak.catches
    lib.showTextUI(L('streak_counter', count, target), {
        position = 'right-center',
        icon = count >= target - 1 and 'fire' or 'fish',
    })
end

local function hideStreakUI()
    if lib.isTextUIOpen() then lib.hideTextUI() end
end

--- Probe the water in front of the player
local function isNearWater()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local probe = coords + GetEntityForwardVector(ped) * 8.0
    local hit, height = GetWaterHeight(probe.x, probe.y, probe.z + 5.0)
    return hit and math.abs(coords.z - height) < 12.0
end

local function attachRod()
    lib.requestModel(ROD_MODEL)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    rodProp = CreateObject(ROD_MODEL, coords.x, coords.y, coords.z, true, true, false)
    AttachEntityToEntity(rodProp, ped, GetPedBoneIndex(ped, 18905),
        0.1, 0.05, 0.0, 70.0, 120.0, 160.0, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(ROD_MODEL)
end

local function playIdleAnim()
    lib.requestAnimDict(ANIM_DICT)
    TaskPlayAnim(PlayerPedId(), ANIM_DICT, ANIM_NAME, 2.0, 2.0, -1, 11, 0, false, false, false)
end

local function unequipRod(silent)
    if not equipped then return end
    equipped = false
    casting = false
    ClearPedTasks(PlayerPedId())
    if rodProp and DoesEntityExist(rodProp) then DeleteEntity(rodProp) end
    rodProp = nil
    hideStreakUI()
    TriggerServerEvent('dev-fishing:server:resetStreak')
    if not silent then notify(L('rod_packed')) end
end

local function equipRod()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) or IsPedSwimming(ped) or IsEntityDead(ped) then
        return notify(L('cannot_fish'), 'error')
    end
    equipped = true
    playIdleAnim()
    attachRod()
    TriggerServerEvent('dev-fishing:server:resetStreak')
    showStreakUI(0)
    notify(L('rod_equipped'))
end

-- ────────────────────────────────────────────────
-- Useable rod: equip / unequip only
-- ────────────────────────────────────────────────
RegisterNetEvent('dev-fishing:client:useRod', function()
    if equipped then
        if casting then
            return notify(L('catching_wait'), 'error')
        end
        unequipRod()
        return
    end
    equipRod()
end)

-- ────────────────────────────────────────────────
-- Useable bait: one cast per use (find fish -> minigame -> catch)
-- ────────────────────────────────────────────────
RegisterNetEvent('dev-fishing:client:useBait', function()
    if not equipped then
        return notify(L('equip_first'), 'error')
    end
    if casting then return end

    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) or IsPedSwimming(ped) or IsEntityDead(ped) then
        return notify(L('cannot_fish'), 'error')
    end
    if Config.RequireWater and not isNearWater() then
        return notify(L('face_water'), 'error')
    end

    casting = true

    -- Server validates rod ownership, consumes the bait and issues a cast token
    local castToken = lib.callback.await('dev-fishing:server:startCast', false)
    if castToken then
        local duration = math.random(Config.FishingTime.min, Config.FishingTime.max)
        local done = lib.progressBar({
            duration = duration,
            label = L('waiting_bite'),
            useWhileDead = false,
            canCancel = true,
            disable = { move = true, car = true, combat = true },
        })

        if done and equipped and not (Config.RequireWater and not isNearWater()) then
            -- A fish bit: reel it in!
            if Minigame.Run() then
                TriggerServerEvent('dev-fishing:server:catch', castToken)
            else
                notify(L('fish_got_away'), 'error')
            end
        end
    end

    if equipped then playIdleAnim() end
    casting = false
end)

-- Hot streak counter updates (server-authoritative)
RegisterNetEvent('dev-fishing:client:updateStreak', function(count, boosted)
    if not equipped or not Config.HotStreak.enabled then return end
    showStreakUI(count)
    if boosted then
        notify(L('streak_bonus'), 'success')
    elseif count == Config.HotStreak.catches - 1 then
        notify(L('streak_almost'))
    end
end)

-- Failsafe: hide the streak text UI if it ever gets stuck on screen
RegisterCommand('clearfshingui', function()
    if lib.isTextUIOpen() then lib.hideTextUI() end
end, false)

-- Server can force-stop (e.g. rod snapped)
RegisterNetEvent('dev-fishing:client:stop', function()
    unequipRod(true)
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then unequipRod(true) end
end)

-- Export: other resources (emotes, jobs, etc.) can check fishing state
-- Returns: equipped (rod in hand), casting (actively waiting for / reeling a fish)
exports('IsPlayerFishing', function()
    return equipped, casting
end)
