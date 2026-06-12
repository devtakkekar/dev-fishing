-- Ped locations, blips and the fishing shop catalogue
Config.Peds = {
    buy = {
        model  = 's_m_m_cntrybar_01',
        coords = vector4(-1816.92, -1193.99, 14.31, 320.0),
        blip   = { sprite = 356, color = 3, scale = 0.7, label = 'Fishing Shop' },
        shop = {
            { item = 'fishingrod', label = 'Fishing Rod', price = 250 },
            { item = 'fishbait',   label = 'Fish Bait',   price = 5 },
        },
    },
    sell = {
        model  = 'a_m_m_salton_04',
        coords = vector4(-1685.13, -1072.31, 13.15, 140.0),
        blip   = { sprite = 78, color = 2, scale = 0.7, label = 'Fish Buyer' },
    },
    boat = {
        model  = 'a_m_y_surfer_01',
        coords = vector4(-1604.42, -1131.62, 2.05, 140.0),
        blip   = { sprite = 410, color = 38, scale = 0.7, label = 'Boat Rental' },
    },
}
