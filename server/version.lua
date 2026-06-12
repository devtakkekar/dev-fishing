--[[ Prints a console notice when a newer version is available.
     Point Config.VersionCheck.url at a raw text file containing the latest version string. ]]

CreateThread(function()
    local cfg = Config.VersionCheck
    if not cfg or not cfg.enabled or cfg.url == '' then return end

    Wait(5000)
    local current = GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or '0.0.0'

    PerformHttpRequest(cfg.url, function(status, body)
        if status ~= 200 or not body then
            print('^3[dev-fishing]^7 version check failed (HTTP ' .. tostring(status) .. ')')
            return
        end

        local latest = body:gsub('%s+', '')
        if latest ~= current then
            print(('^3[dev-fishing]^7 a new version is available: ^2%s^7 (you are on %s)'):format(latest, current))
        else
            print(('^2[dev-fishing]^7 up to date (v%s)'):format(current))
        end
    end, 'GET')
end)
