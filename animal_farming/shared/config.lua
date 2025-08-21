Config = {}

-- Debug mode for console logging
Config.Debug = true

-- Maximum farmlots per player (set to -1 for unlimited)
Config.MaxFarmlotsPerPlayer = -1

-- Animal degradation rates (per minute)
Config.DegradationRates = {
    health = 0.5,  -- Health decreases by 0.5 per minute if hungry/thirsty
    hunger = 1.0,  -- Hunger decreases by 1.0 per minute
    thirst = 1.2   -- Thirst decreases by 1.2 per minute
}

-- Animal death thresholds
Config.DeathThresholds = {
    health = 10,   -- Animal dies if health drops below 10
    hunger = 5,    -- Critical hunger level
    thirst = 5     -- Critical thirst level
}

-- Gender system
Config.GenderChance = {
    female = 20,   -- 20% chance for female
    male = 80      -- 80% chance for male
}

-- Animal types and their properties
Config.Animals = {
    pig = {
        name = "Baboy (Pig)",
        model = "a_c_pig",
        price = 500,
        maxHealth = 100,
        maxHunger = 100,
        maxThirst = 100,
        productionTime = 2 * 60 * 60, -- 2 hours in seconds
        product = "raw_pork",
        productAmount = {min = 2, max = 4},
        spawnDelay = 10000, -- 10 seconds
        canProduce = {male = true, female = true} -- Both genders produce meat
    },
    cow = {
        name = "Baka (Cow)",
        model = "a_c_cow",
        price = 1200,
        maxHealth = 100,
        maxHunger = 100,
        maxThirst = 100,
        productionTime = 3 * 24 * 60 * 60, -- 3 days in seconds
        product = "milk",
        productAmount = {min = 3, max = 6},
        spawnDelay = 15000, -- 15 seconds
        canProduce = {male = false, female = true} -- Only females produce milk
    },
    chicken = {
        name = "Manok (Chicken)",
        model = "a_c_hen",
        price = 150,
        maxHealth = 100,
        maxHunger = 100,
        maxThirst = 100,
        productionTime = 30 * 60, -- 30 minutes in seconds
        product = "eggs",
        productAmount = {min = 1, max = 3},
        spawnDelay = 5000, -- 5 seconds
        canProduce = {male = false, female = true} -- Only females produce eggs
    }
}

-- Farmlot locations and configurations
Config.Farmlots = {
    {
        id = 1,
        name = "Sandy Shores Farm Lot 1",
        price = 5000,
        animalType = "pig", -- This lot can only have pigs
        coords = vector3(1905.24, 4926.51, 48.86),
        boundaries = {
            min = vector3(1895.24, 4916.51, 48.0),
            max = vector3(1915.24, 4936.51, 52.0)
        },
        blip = {
            sprite = 162,
            color = 2,
            scale = 0.8
        }
    },
    {
        id = 2,
        name = "Sandy Shores Farm Lot 2",
        price = 8000,
        animalType = "cow", -- This lot can only have cows
        coords = vector3(1920.45, 4940.12, 48.90),
        boundaries = {
            min = vector3(1910.45, 4930.12, 48.0),
            max = vector3(1930.45, 4950.12, 52.0)
        },
        blip = {
            sprite = 162,
            color = 3,
            scale = 0.8
        }
    },
    {
        id = 3,
        name = "Grapeseed Chicken Coop",
        price = 3000,
        animalType = "chicken",
        coords = vector3(1678.12, 4881.45, 42.05),
        boundaries = {
            min = vector3(1668.12, 4871.45, 41.0),
            max = vector3(1688.12, 4891.45, 45.0)
        },
        blip = {
            sprite = 162,
            color = 5,
            scale = 0.8
        }
    }
}

-- NPC Sellers
Config.NPCs = {
    farmlotSeller = {
        name = "Farm Lot Seller",
        model = "a_m_m_farmer_01",
        coords = vector4(1902.34, 4923.67, 48.86, 45.0),
        scenario = "WORLD_HUMAN_CLIPBOARD"
    },
    animalSeller = {
        name = "Animal Seller",
        model = "a_m_m_hillbilly_01", 
        coords = vector4(1898.12, 4919.45, 48.86, 135.0),
        scenario = "WORLD_HUMAN_SMOKING"
    }
}

-- Feeding system
Config.Feeding = {
    feedItem = "animal_feed",
    hungerIncrease = 25,
    healthIncrease = 10,
    animationDict = "amb@world_human_gardener_plant@male@base",
    animationName = "base",
    feedingTime = 3000 -- 3 seconds
}

-- Butchering system
Config.Butchering = {
    enabled = true,
    requiredItem = "knife",
    minigameDuration = 30000, -- 30 seconds
    skillCheckDifficulty = "medium",
    meatYields = {
        pig = {min = 3, max = 6},
        cow = {min = 5, max = 10},
        chicken = {min = 1, max = 2}
    }
}

-- Water trough system
Config.WaterTroughs = {
    enabled = true,
    autoHydration = true,
    hydrationRate = 2, -- Points per minute
    troughModel = "prop_water_trough_01",
    maxTroughsPerLot = 2
}

-- UI Settings
Config.UI = {
    showFloatingStats = true,
    statUpdateInterval = 5000, -- Update every 5 seconds
    showGenderInStats = true
}

-- Interaction distances
Config.Distances = {
    farmlotPurchase = 3.0,
    animalPurchase = 3.0,
    animalInteraction = 2.0,
    waterTroughPlace = 2.0
}

-- Notification settings
Config.Notifications = {
    type = "ox_lib", -- or "qb" for qb-core notifications
    duration = 5000
}

-- Blip settings
Config.Blips = {
    showFarmlotBlips = true,
    showOwnedFarmlots = true,
    showNPCBlips = true
}