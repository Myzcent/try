Config = {}

-- Debug mode
Config.Debug = true

-- General Settings
Config.MaxFarmlotsPerPlayer = 0 -- 0 = unlimited
Config.AnimalSpawnDelay = math.random(10000, 15000) -- 10-15 seconds
Config.StatDegradationInterval = 300000 -- 5 minutes
Config.ExperienceGainRate = 10 -- Base EXP gain per action

-- Gender System
Config.FemaleChance = 20 -- 20% chance for female animals
Config.MaleChance = 80 -- 80% chance for male animals

-- Animal Types and Stats
Config.Animals = {
    pig = {
        label = 'Baboy (Pig)',
        model = 'a_c_pig',
        price = 5000,
        maxHealth = 100,
        maxHunger = 100,
        maxThirst = 100,
        productionItem = 'raw_pork',
        productionTime = 7200000, -- 2 hours in milliseconds
        productionAmount = {min = 1, max = 3},
        butcherYield = {min = 2, max = 5},
        hungerDegradation = 2, -- Points per interval
        thirstDegradation = 3, -- Points per interval
        expPerFeed = 15,
        expPerProduction = 25,
        genderProduction = false -- Both genders can produce
    },
    cow = {
        label = 'Baka (Cow)',
        model = 'a_c_cow',
        price = 8000,
        maxHealth = 100,
        maxHunger = 100,
        maxThirst = 100,
        productionItem = 'milk',
        productionTime = 259200000, -- 3 days in milliseconds
        productionAmount = {min = 2, max = 4},
        butcherYield = {min = 5, max = 8},
        hungerDegradation = 1, -- Points per interval
        thirstDegradation = 2, -- Points per interval
        expPerFeed = 20,
        expPerProduction = 35,
        genderProduction = true -- Only females produce
    }
}

-- Farmlot Configurations
Config.Farmlots = {
    {
        id = 'lot_1',
        label = 'Farmlot #1 (Mixed)',
        type = 'mixed', -- Can house any animal type
        price = 25000,
        coordinates = vector3(2447.3, 4968.5, 51.7),
        boundaries = {
            min = vector3(2440.0, 4960.0, 50.0),
            max = vector3(2455.0, 4975.0, 55.0)
        },
        npc = {
            model = 's_m_m_farmer_01', -- Different model to test
            coords = vector4(2447.3, 4968.5, 51.7, 180.0)
        }
    },
    {
        id = 'lot_2',
        label = 'Farmlot #2 (Cow Only)',
        type = 'cow',
        price = 30000,
        coordinates = vector3(2435.1, 4980.2, 51.8),
        boundaries = {
            min = vector3(2428.0, 4973.0, 50.0),
            max = vector3(2443.0, 4988.0, 55.0)
        },
        npc = {
            model = 'a_m_m_farmer_01',
            coords = vector4(2435.1, 4980.2, 51.8, 90.0)
        }
    },
    {
        id = 'lot_3',
        label = 'Farmlot #3 (Pig Only)',
        type = 'pig',
        price = 20000,
        coordinates = vector3(2460.7, 4955.3, 51.6),
        boundaries = {
            min = vector3(2453.0, 4948.0, 50.0),
            max = vector3(2468.0, 4963.0, 55.0)
        },
        npc = {
            model = 'cs_old_man1a', -- Different model to test
            coords = vector4(2460.7, 4955.3, 51.6, 270.0)
        }
    }
}

-- Animal Vendor NPC
Config.AnimalVendor = {
    model = 's_m_m_trucker_01', -- Different model to test
    coords = vector4(2472.5, 4942.1, 51.7, 45.0),
    label = 'Animal Vendor'
}

-- Water Trough System
Config.WaterTroughs = {
    enabled = true,
    autoRefill = true,
    refillTime = 1800000, -- 30 minutes
    maxWaterLevel = 100,
    thirstReduction = 5 -- Points reduced per drink
}

-- Butchering System
Config.Butchering = {
    enabled = true,
    requiresKnife = true,
    minigameTime = 30000, -- 30 seconds
    minigameDifficulty = 'easy', -- easy, medium, hard
    skillCheckCount = 3,
    successRate = 75 -- Base success rate percentage
}

-- Production Requirements
Config.ProductionRequirements = {
    minHealth = 50,
    minHunger = 30,
    minThirst = 30
}

-- Experience and Leveling
Config.Experience = {
    maxLevel = 10,
    expPerLevel = 100, -- EXP required per level
    levelBonuses = {
        [2] = {healthBonus = 10, productionBonus = 5},
        [3] = {healthBonus = 15, productionBonus = 10},
        [4] = {healthBonus = 20, productionBonus = 15},
        [5] = {healthBonus = 25, productionBonus = 20},
        [6] = {healthBonus = 30, productionBonus = 25},
        [7] = {healthBonus = 35, productionBonus = 30},
        [8] = {healthBonus = 40, productionBonus = 35},
        [9] = {healthBonus = 45, productionBonus = 40},
        [10] = {healthBonus = 50, productionBonus = 50}
    }
}

-- UI Settings
Config.UI = {
    showFloatingStats = true,
    statUpdateInterval = 5000, -- 5 seconds
    animationDuration = 2000 -- 2 seconds for feeding animations
}

-- Items
Config.Items = {
    feed = 'animal_feed',
    knife = 'knife',
    meat = 'raw_meat',
    milk = 'milk',
    eggs = 'eggs',
    pork = 'raw_pork'
}