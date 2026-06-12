--[[ Tiny locale helper. Add new languages as locales/<code>.lua and set Config.Locale. ]]

local dict = Locales[Config.Locale] or Locales['en']
local fallback = Locales['en']

--- Translate a locale key, optionally formatting with extra arguments
---@param key string
---@return string
function L(key, ...)
    local str = dict[key] or fallback[key] or key
    if select('#', ...) > 0 then
        return str:format(...)
    end
    return str
end
