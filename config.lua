Config = {}

Config.JobLocation = vector4(73.16, -1027.3, 29.48, 247.73)  -- Krantenbedrijf

Config.NPCBlip = {
    coords = vector3(72.8, -1027.66, 29.48),
    sprite = 357, color = 2, scale = 0.8, label = "📰 Krantenbedrijf"
}

Config.DeliveryBlip = {
    sprite = 1, color = 5, scale = 0.7, label = "📦 Bezorgpunt"
}

Config.Areas = {
    {
        name = "Downtown", minReward = 50, maxReward = 120,
        locations = {
            vector3(-1342.77, -872.1, 16.87), 
            vector3(-1317.69, -832.02, 16.97),
            vector3(-1289.22, -852.38, 14.93),
            vector3(-1317.1, -903.82, 11.31),
            --More locations can be added here
        }
    },
    {
        name = "Vinewood", minReward = 80, maxReward = 200,
        locations = {
           vector3(340.23, 179.25, 103.02), 
           vector3(333.8, 118.44, 104.31),
           --More locations can be added here
    
         }
    }
}

Config.NewspaperItem = 'lockpick' -- change to your newspaper item name (Lockpick is just a placeholder for testing)
Config.RequiredPapers = 5
Config.BorgAmount = 100
