Locales = Locales or {}

Locales['en'] = {
    -- General
    notify_title       = 'Fishing',
    lucky_catch_title  = '🎣 Lucky Catch',

    -- Fishing (client)
    cannot_fish        = 'You cannot fish right now',
    face_water         = 'Face open water to cast your line',
    rod_equipped       = 'Rod equipped - use bait to cast your line',
    rod_packed         = 'You packed up your fishing rod',
    catching_wait      = 'You are currently catching a fish - wait and try again',
    equip_first        = 'Equip your fishing rod first',
    waiting_bite       = 'Waiting for a bite...',
    fish_got_away      = 'The fish got away...',

    -- Menus
    shop_title         = '🎣 Fishing Shop',
    sell_title         = '🐟 Fish Buyer',
    index_title        = '📖 Fish Index',
    top_title          = '🏆 Top Anglers',
    buy_prompt         = 'Buy %s',
    quantity           = 'Quantity',
    price_each         = '$%s each',
    price_each_total   = '$%s each | $%s total',
    sell_everything    = 'Sell Everything',
    sell_everything_desc = 'Sell all of your catches at once',
    nothing_to_sell_menu = 'You have nothing to sell',
    level_angler       = 'Level %d - %s Angler',
    xp_to_next         = '%d / %d XP to next level',
    xp_max             = '%d XP | Max level reached',
    tier_progress      = '%s (%d/%d)',
    completed          = 'Completed!',
    discover_bonus     = 'Discover all for +%d bonus XP',
    no_anglers         = 'No anglers on the leaderboard yet',
    leaderboard_entry  = 'Level %d - %s | %d XP',

    -- Target labels
    target_shop        = 'Browse Fishing Shop',
    target_index       = 'Fish Index',
    target_top         = 'Top Anglers',
    target_sell        = 'Sell Catches',

    -- Server notifications
    need_rod           = 'You need a fishing rod',
    no_bait            = 'You ran out of bait',
    pockets_full       = 'Your pockets are full!',
    caught             = 'You caught: %s!',
    new_discovery      = 'New fish discovery: %s!',
    tier_completed     = 'Completed %s tier! Bonus XP +%d',
    xp_gain            = '+%d XP | Total: %d XP',
    level_up           = 'Level up! You are now a %s angler (Lv. %d)',
    rod_snapped        = 'Your fishing rod snapped!',
    found_a            = 'found a %s!',
    sold_for           = 'You sold your catches for $%d',
    nothing_to_sell    = 'Nothing to sell',
    need_cash          = 'You need $%d in cash',
    cannot_carry       = 'You cannot carry that',
    bought             = 'Bought %dx %s for $%d',
    xp_progress        = '%d / %d XP to %s',
    max_level          = 'Max level reached',
    xp_status          = 'Level %d - %s | %d XP | %s',

    -- Admin / debug
    invalid_args       = 'Invalid player ID or amount',
    set_xp_ok          = 'Set fishing XP of ID %s to %d',
    xp_was_set         = 'Your fishing XP was set to %d',
    player_not_found   = 'Player not found',
    reset_index_ok     = 'Reset fish index of ID %s',
    enable_debug       = 'Enable Config.Debug to use this command',
    unknown_item       = 'Unknown loot item: %s',
    no_global_notify   = '%s has globalNotify = false, nothing to broadcast',
    broadcast_sent     = 'Broadcast sent for %s',

    -- Stats
    stats_title        = '📊 Fishing Stats',
    stats_catches      = 'Total Catches',
    stats_earned       = 'Money Earned',
    stats_rarest       = 'Rarest Catch',
    stats_streak       = 'Best Catch Streak',
    stats_none         = 'None yet',

    -- Boat rental
    target_boat_rent   = 'Rent Boat',
    target_boat_return = 'Return Boat',
    already_rented     = 'You already rented a boat',
    no_rental          = 'You have no rented boat',
    boat_rented        = 'Boat rented! $%d deposit - return it to the dock to get it back',
    boat_returned      = 'Boat returned - $%d deposit refunded',
    boat_lost          = 'Your boat was lost - deposit forfeited',
    boat_too_far       = 'Bring the boat closer to the dock to return it',
}
