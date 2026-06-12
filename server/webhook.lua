--[[ Discord webhook logging ]]

Webhook = {}

---@param title string
---@param description string
---@param color number|nil decimal embed color
function Webhook.Send(title, description, color)
    local cfg = Config.Webhook
    if not cfg or not cfg.enabled or cfg.url == '' then return end

    PerformHttpRequest(cfg.url, function() end, 'POST', json.encode({
        username = 'dev-fishing',
        embeds = {
            {
                title = title,
                description = description,
                color = color or 5763719,
                footer = { text = os.date('%Y-%m-%d %H:%M:%S') },
            },
        },
    }), { ['Content-Type'] = 'application/json' })
end
