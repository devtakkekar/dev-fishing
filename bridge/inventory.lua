--[[ Server-side inventory bridge: qb-inventory / ox_inventory ]]

Inventory = {}

local QBCore = exports['qb-core']:GetCoreObject()

local system = Config.Inventory
if system == 'auto' then
    system = GetResourceState('ox_inventory') == 'started' and 'ox' or 'qb'
end
Inventory.System = system
print(('^2[dev-fishing]^7 inventory bridge: %s'):format(system))

---@param src number
---@param item string
---@param count number
---@return boolean success
function Inventory.AddItem(src, item, count)
    if system == 'ox' then
        return exports.ox_inventory:AddItem(src, item, count) and true or false
    end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    if Player.Functions.AddItem(item, count) then
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item], 'add', count)
        return true
    end
    return false
end

---@param src number
---@param item string
---@param count number
---@return boolean success
function Inventory.RemoveItem(src, item, count)
    if system == 'ox' then
        return exports.ox_inventory:RemoveItem(src, item, count) and true or false
    end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    if Player.Functions.RemoveItem(item, count) then
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item], 'remove', count)
        return true
    end
    return false
end

---@param src number
---@param item string
---@return number count
function Inventory.GetItemCount(src, item)
    if system == 'ox' then
        return exports.ox_inventory:GetItemCount(src, item) or 0
    end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return 0 end
    local data = Player.Functions.GetItemByName(item)
    return data and (data.amount or data.count or 0) or 0
end
