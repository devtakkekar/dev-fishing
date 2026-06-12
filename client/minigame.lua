--[[ Pluggable reel-in minigame

    Resolution order:
      1. Runtime override  : exports['dev-fishing']:SetMinigame(fn)  -- fn must return true/false
      2. Config export     : Config.Minigame.custom = { resource = 'my-minigame', export = 'Start' }
      3. Built-in          : ox_lib skillCheck (Config.Minigame.type = 'skillcheck')

    Any minigame function must be synchronous (block until finished) and return
    `true` on success, anything else counts as a fail.
]]

Minigame = {}

local customFn = nil

--- Replace the minigame at runtime from another resource:
--- exports['dev-fishing']:SetMinigame(function() return exports.myui:circleGame(2) end)
exports('SetMinigame', function(fn)
    if type(fn) == 'function' then
        customFn = fn
        return true
    end
    return false
end)

--- Restore the default (config-driven) minigame
exports('ResetMinigame', function()
    customFn = nil
end)

local builtin = {
    skillcheck = function()
        return lib.skillCheck(Config.Minigame.difficulty, Config.Minigame.keys)
    end,
}

---@return boolean success
function Minigame.Run()
    local cfg = Config.Minigame
    if not cfg or not cfg.enabled then return true end

    -- 1. Runtime override
    if customFn then
        local ok, result = pcall(customFn)
        if not ok then
            print('^1[dev-fishing]^7 custom minigame errored: ' .. tostring(result))
            return false
        end
        return result == true
    end

    -- 2. External resource export from config
    if cfg.custom and cfg.custom.resource ~= '' and cfg.custom.export ~= '' then
        local ok, result = pcall(function()
            local resource = exports[cfg.custom.resource]
            local args = cfg.custom.args
            local isColon = cfg.custom.colon or cfg.custom.resource == 'bl_ui'

            if isColon then
                if type(args) == 'table' then
                    return resource[cfg.custom.export](resource, table.unpack(args))
                else
                    return resource[cfg.custom.export](resource, cfg.custom.iterations, cfg.custom.difficulty)
                end
            else
                if type(args) == 'table' then
                    return resource[cfg.custom.export](table.unpack(args))
                else
                    return resource[cfg.custom.export](cfg.custom.iterations, cfg.custom.difficulty)
                end
            end
        end)
        if not ok then
            print(('^1[dev-fishing]^7 minigame export %s:%s errored: %s'):format(cfg.custom.resource, cfg.custom.export, tostring(result)))
            return false
        end
        return result == true
    end

    -- 3. Built-in
    local fn = builtin[cfg.type] or builtin.skillcheck
    return fn() == true
end
