--[[ Client-side target bridge: qb-target / ox_target ]]

Target = {}

local system = Config.Target
if system == 'auto' then
    system = GetResourceState('ox_target') == 'started' and 'ox' or 'qb'
end
Target.System = system

---Add interaction options to a local entity (ped)
---@param entity number
---@param options table[] each: { label = string, icon = string, onSelect = function }
function Target.AddPed(entity, options)
    if system == 'ox' then
        local oxOptions = {}
        for i, opt in ipairs(options) do
            oxOptions[i] = {
                name = ('dev_fishing_%s_%s'):format(entity, i),
                label = opt.label,
                icon = opt.icon,
                distance = 2.5,
                onSelect = opt.onSelect,
            }
        end
        exports.ox_target:addLocalEntity(entity, oxOptions)
    else
        local qbOptions = {}
        for i, opt in ipairs(options) do
            qbOptions[i] = {
                label = opt.label,
                icon = opt.icon,
                action = opt.onSelect,
            }
        end
        exports['qb-target']:AddTargetEntity(entity, { options = qbOptions, distance = 2.5 })
    end
end
