fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'dev-fishing'
description 'Modular QBCore fishing script with XP leveling, tiered loot pools and buy/sell peds. Supports ox_lib, qb-inventory / ox_inventory and qb-target / ox_target.'
author 'dev'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config/config.lua',
    'config/loot.lua',
    'config/peds.lua',
    'locales/en.lua',
    'shared/locale.lua',
}

client_scripts {
    'bridge/target.lua',
    'client/minigame.lua',
    'client/main.lua',
    'client/peds.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/inventory.lua',
    'server/webhook.lua',
    'server/xp.lua',
    'server/discovery.lua',
    'server/stats.lua',
    'server/loot.lua',
    'server/main.lua',
    'server/version.lua',
}

dependencies {
    'qb-core',
    'ox_lib',
    'oxmysql',
}
