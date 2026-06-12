--[[
    Loot pools, organised by tier.

    Tier fields:
      weight       relative chance of the tier being rolled
      minLevel     fishing level required before this tier can drop
      bonusXP      one-time XP bonus when every item in the tier has been discovered

    Item fields:
      item         inventory item name
      label        display name
      weight       relative chance within the tier
      xp           XP rewarded for catching it
      price        sell price at the sell ped (0 = cannot be sold)
      globalNotify when true, a chat message is broadcast to ALL players on catch:
                   "<player name> <msg>"
      msg          customisable broadcast message, defined right below the item
]]

Config.LootTiers = {
    { -- Common
        name = 'common',
        weight = 60,
        minLevel = 1,
        bonusXP = 50,
        items = {
            { item = 'anchovy',  label = 'Anchovy',  weight = 40, xp = 5, price = 15 },
            { item = 'sardine',  label = 'Sardine',  weight = 35, xp = 6, price = 18 },
            { item = 'mackerel', label = 'Mackerel', weight = 25, xp = 8, price = 25 },
        },
    },
    { -- Uncommon
        name = 'uncommon',
        weight = 27,
        minLevel = 1,
        bonusXP = 75,
        items = {
            { item = 'bass',   label = 'Bass',   weight = 60, xp = 12, price = 45 },
            { item = 'salmon', label = 'Salmon', weight = 40, xp = 15, price = 60 },
        },
    },
    { -- Rare
        name = 'rare',
        weight = 10,
        minLevel = 2,
        bonusXP = 150,
        items = {
            { item = 'tuna',      label = 'Tuna',      weight = 45, xp = 25, price = 120 },
            { item = 'swordfish', label = 'Swordfish', weight = 35, xp = 30, price = 160 },
            {
                item = 'clam', label = 'Clam', weight = 20, xp = 35, price = 200,
                globalNotify = false,
                msg = 'pried a gleaming Clam from the seabed!',
            },
        },
    },
    { -- Legendary
        name = 'legendary',
        weight = 3,
        minLevel = 3,
        bonusXP = 300,
        items = {
            {
                item = 'treasure_map', label = 'Treasure Map', weight = 30, xp = 60, price = 0,
                globalNotify = true,
                msg = 'reeled in a Treasure Map... X marks the spot!',
            },
            {
                item = 'ancient_relic', label = 'Ancient Relic', weight = 25, xp = 75, price = 850,
                globalNotify = true,
                msg = 'dredged up an Ancient Relic from the depths!',
            },
            {
                item = 'lottery_ticket', label = 'Lottery Ticket', weight = 25, xp = 50, price = 0,
                globalNotify = true,
                msg = 'hooked a Lottery Ticket - luck is on their side!',
            },
            {
                item = 'fishing_voucher', label = 'Fishing Voucher', weight = 20, xp = 50, price = 0,
                globalNotify = true,
                msg = 'snagged a Fishing Voucher! Free gear, anyone?',
            },
        },
    },
}
