# dev-fishing

Polished, modular fishing script for **QBCore** with an XP leveling system, tiered loot pools, buy/sell peds and dual inventory/target support.

## Features

- 🎣 Equip-to-fish flow: **use the rod to equip it**, then **use bait to cast** - one cast per bait, no AFK loop
- 📖 **Fish Index** on both peds: undiscovered fish show as `???`; first catches trigger a 'New fish discovery' notify; discovering a full tier awards one-time bonus XP with a 'Completed <tier>' notify
- 🎮 **Reel-in minigame** on every bite (ox_lib skillCheck by default) - fail and the fish gets away
- 🔌 **Swappable minigame**: point the config at any resource export, or override at runtime via `exports['dev-fishing']:SetMinigame()`
- 🧩 Bridges: **qb-inventory / ox_inventory** and **qb-target / ox_target** (`auto` detection or forced via config)
- 📈 Persistent **XP & level system** (oxmysql, table auto-created) - higher levels unlock higher loot tiers
- 🛒 **Buy ped** (fishing shop with quantity input) and 💰 **sell ped** (sell single stacks or everything)
- 🗂️ **Tiered loot pools** (common / uncommon / rare / legendary) with weighted chances and per-tier level gates
- 💎 Rare loot: Clam, Treasure Map, Ancient Relic, Lottery Ticket, Fishing Voucher (easy to add more)
- 📢 Per-item `globalNotify` + customisable `msg`: broadcasts `<player name> <msg>` to all players in chat
- 🔔 `Config.NotifyXPGain = true`: every catch shows XP earned + updated total
- ⌨️ `/fishingxp` command: current XP, level and progress to next level
- 🏆 **Leaderboard**: `/fishingtop` or the shop ped's *Top Anglers* menu (top anglers by XP)
- 🛠️ **Admin commands**: `/setfishingxp <id> <amount>`, `/resetindex <id>`
- 📡 **Discord webhook logging** for rare catches and big sales (anti-exploit auditing)
- 📉 **Dynamic market prices**: sell prices fluctuate per restart/interval to discourage botting
- 🔗 **Server exports**: `GetFishingXP`, `AddFishingXP`, `SetFishingXP`, `GetFishingLevel` for other resources
- 🌐 **Locale support**: all user-facing text lives in `locales/en.lua`; add `locales/<code>.lua` and set `Config.Locale`
- ⛵ **Boat rental ped**: rent a dinghy for a deposit, refunded when the boat is returned to the dock
- 📊 **`/fishingstats`**: lifetime totals (catches, money earned, rarest catch, best catch streak)
- 🪝 **Client export** `IsPlayerFishing()`: returns `equipped, casting` for other scripts
- 🛡️ **Cast position anticheat**: catches are rejected if the player moved too far from where they cast
- 🔄 **Version checker**: console notice on startup when a newer version is published
- 🔒 Server-side validation: cast tokens, minimum cast time, catch cooldown, rod/bait ownership, server-priced shop

## Dependencies

- [qb-core](https://github.com/qbcore-framework/qb-core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [oxmysql](https://github.com/overextended/oxmysql)
- qb-inventory **or** ox_inventory
- qb-target **or** ox_target

## Installation

1. Drop the `dev-fishing` folder into your `resources` directory.
2. Add `ensure dev-fishing` to your `server.cfg` (after qb-core, ox_lib, oxmysql, your inventory and target).
3. Add the items below to your inventory system.
4. Restart the server - the `dev_fishing` SQL table is created automatically.

### qb-core items (`qb-core/shared/items.lua`)

```lua
fishingrod      = { name = 'fishingrod',      label = 'Fishing Rod',     weight = 2000, type = 'item', image = 'fishingrod.png',      unique = false, useable = true,  shouldClose = true,  description = 'A sturdy fishing rod' },
fishbait        = { name = 'fishbait',        label = 'Fish Bait',       weight = 50,   type = 'item', image = 'fishbait.png',        unique = false, useable = true,  shouldClose = true,  description = 'Wriggly worms - use to cast your line' },
anchovy         = { name = 'anchovy',         label = 'Anchovy',         weight = 100,  type = 'item', image = 'anchovy.png',         unique = false, useable = false, shouldClose = false, description = 'A small anchovy' },
sardine         = { name = 'sardine',         label = 'Sardine',         weight = 100,  type = 'item', image = 'sardine.png',         unique = false, useable = false, shouldClose = false, description = 'A shiny sardine' },
mackerel        = { name = 'mackerel',        label = 'Mackerel',        weight = 150,  type = 'item', image = 'mackerel.png',        unique = false, useable = false, shouldClose = false, description = 'A striped mackerel' },
bass            = { name = 'bass',            label = 'Bass',            weight = 250,  type = 'item', image = 'bass.png',            unique = false, useable = false, shouldClose = false, description = 'A decent bass' },
salmon          = { name = 'salmon',          label = 'Salmon',          weight = 300,  type = 'item', image = 'salmon.png',          unique = false, useable = false, shouldClose = false, description = 'A fresh salmon' },
tuna            = { name = 'tuna',            label = 'Tuna',            weight = 500,  type = 'item', image = 'tuna.png',            unique = false, useable = false, shouldClose = false, description = 'A hefty tuna' },
swordfish       = { name = 'swordfish',       label = 'Swordfish',       weight = 600,  type = 'item', image = 'swordfish.png',       unique = false, useable = false, shouldClose = false, description = 'A mighty swordfish' },
clam            = { name = 'clam',            label = 'Clam',            weight = 100,  type = 'item', image = 'clam.png',            unique = false, useable = false, shouldClose = false, description = 'Might hold a pearl...' },
treasure_map    = { name = 'treasure_map',    label = 'Treasure Map',    weight = 50,   type = 'item', image = 'treasure_map.png',    unique = true,  useable = false, shouldClose = false, description = 'X marks the spot' },
ancient_relic   = { name = 'ancient_relic',   label = 'Ancient Relic',   weight = 400,  type = 'item', image = 'ancient_relic.png',   unique = true,  useable = false, shouldClose = false, description = 'A relic from the deep' },
lottery_ticket  = { name = 'lottery_ticket',  label = 'Lottery Ticket',  weight = 10,   type = 'item', image = 'lottery_ticket.png',  unique = true,  useable = false, shouldClose = false, description = 'Feeling lucky?' },
fishing_voucher = { name = 'fishing_voucher', label = 'Fishing Voucher', weight = 10,   type = 'item', image = 'fishing_voucher.png', unique = true,  useable = false, shouldClose = false, description = 'Redeemable for fishing gear' },
```

### ox_inventory items (`ox_inventory/data/items.lua`)

```lua
['fishingrod']      = { label = 'Fishing Rod',     weight = 2000, stack = false, close = true },
['fishbait']        = { label = 'Fish Bait',       weight = 50 },
['anchovy']         = { label = 'Anchovy',         weight = 100 },
['sardine']         = { label = 'Sardine',         weight = 100 },
['mackerel']        = { label = 'Mackerel',        weight = 150 },
['bass']            = { label = 'Bass',            weight = 250 },
['salmon']          = { label = 'Salmon',          weight = 300 },
['tuna']            = { label = 'Tuna',            weight = 500 },
['swordfish']       = { label = 'Swordfish',       weight = 600 },
['clam']            = { label = 'Clam',            weight = 100 },
['treasure_map']    = { label = 'Treasure Map',    weight = 50,  stack = false },
['ancient_relic']   = { label = 'Ancient Relic',   weight = 400, stack = false },
['lottery_ticket']  = { label = 'Lottery Ticket',  weight = 10,  stack = false },
['fishing_voucher'] = { label = 'Fishing Voucher', weight = 10,  stack = false },
```

> **Note (ox_inventory):** `QBCore.Functions.CreateUseableItem` works through the qb bridge. If you run ox_inventory standalone, add `server = { export = 'dev-fishing.useRod' }`-style hooks or keep the qb bridge enabled.

## Configuration

| File | Purpose |
|---|---|
| `config/config.lua` | Bridges, items, timings, rod break chance, XP levels, `NotifyXPGain` |
| `config/loot.lua` | Loot tiers, weights, level gates, XP/prices, `globalNotify` + `msg` per item |
| `config/peds.lua` | Buy/sell ped models, coords, blips and the shop catalogue |

### Minigame

When a fish bites, a reel-in minigame runs. Failing it means the fish gets away (bait is still consumed).

```lua
Config.Minigame = {
    enabled = true,
    type = 'skillcheck',                       -- built-in ox_lib skillCheck
    difficulty = { 'easy', 'easy', 'medium' },
    keys = { 'w', 'a', 's', 'd' },
    custom = { resource = '', export = '' },   -- use another resource's minigame export
}
```

**Use a different minigame** (no code changes needed) - any export that returns `true` on success works:

```lua
custom = { resource = 'ps-ui', export = 'Circle' }
```

**Override at runtime** from any other resource:

```lua
-- in your own resource (client-side)
exports['dev-fishing']:SetMinigame(function()
    return exports['my-minigames']:keypad({ difficulty = 'hard' })
end)

-- restore the config-driven default
exports['dev-fishing']:ResetMinigame()
```

The minigame function must block until finished and return `true` for success.

### Adding a rare item with a global chat broadcast

```lua
{
    item = 'golden_hook', label = 'Golden Hook', weight = 10, xp = 100, price = 0,
    globalNotify = true,                                  -- broadcast to all players
    msg = 'fished up the legendary Golden Hook!',          -- customisable message
},
```

Broadcast format in chat: `🎣 Lucky Catch | <Firstname Lastname> <msg>`

## Usage

- Buy a rod + bait from the **Fishing Shop** ped.
- **Use the rod** to equip it (use it again to pack up).
- Stand facing open water and **use bait** to cast - each cast consumes 1 bait.
- When a fish bites, beat the reel-in minigame to land the catch.
- First-time catches are logged in the **Fish Index** (available on both peds); discover every fish in a tier for one-time bonus XP.
- Sell your catches at the **Fish Buyer** ped (single stacks or everything).
- Check progress with `/fishingxp`.

## Commands

| Command | Permission | Description |
|---|---|---|
| `/fishingxp` | everyone | Current XP, level and progress to next level |
| `/fishingtop` | everyone | Leaderboard of top anglers by XP |
| `/fishingstats` | everyone | Lifetime stats: catches, money earned, rarest catch, best streak |
| `/setfishingxp <id> <amount>` | admin | Set a player's fishing XP |
| `/resetindex <id>` | admin | Wipe a player's fish index discoveries |

## Exports (server)

```lua
local xp = exports['dev-fishing']:GetFishingXP(citizenid)
local newXP = exports['dev-fishing']:AddFishingXP(citizenid, 50)
exports['dev-fishing']:SetFishingXP(citizenid, 500)
local level, rank = exports['dev-fishing']:GetFishingLevel(citizenid) -- e.g. 3, 'Skilled'
```

Client-side:

```lua
local equipped, casting = exports['dev-fishing']:IsPlayerFishing()
```

## Webhook & market

```lua
Config.Webhook = {
    enabled = false,
    url = '',                -- Discord webhook URL
    logAllCatches = true,    -- logs every catch (item + XP gained + total XP)
    logRareCatches = true,   -- logs globalNotify catches even if logAllCatches = false
    logAllSales = true,      -- logs every sale at the sell ped
    bigSaleThreshold = 1000, -- highlights sales >= $1000 (0 = no highlight)
}

Config.DynamicPrices = {
    enabled = true,
    variance = 15, -- sell prices vary +/- 15% around the base price
    interval = 60, -- market refreshes every 60 minutes and on restart
}
```

## Localization

All user-facing strings live in `locales/en.lua`. To add a language:

1. Copy `locales/en.lua` to e.g. `locales/de.lua` and change `Locales['en']` to `Locales['de']`.
2. Translate the values (keep the `%s` / `%d` placeholders intact).
3. Add the file to `shared_scripts` in `fxmanifest.lua` and set `Config.Locale = 'de'`.

Missing keys automatically fall back to English.

## SQL

The table is created automatically, but for reference:

```sql
CREATE TABLE IF NOT EXISTS `dev_fishing` (
    `citizenid` VARCHAR(64) NOT NULL,
    `xp` INT UNSIGNED NOT NULL DEFAULT 0,
    `discovered` LONGTEXT NULL,
    PRIMARY KEY (`citizenid`)
);
```
