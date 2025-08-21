-- ============================================================================
-- Animal Farm Configuration
-- ============================================================================

Config = {}

-- Animal Models Configuration
Config.AnimalModels = {
    cow = {
        model = "a_c_cow",
        label = "Cow",
        description = "A dairy cow for milk production",
        icon = "cow",
        isFemale = true,
        productReady = false,
        hunger = 100,
        water = 100,
        age = "2 Years",
        gender = "Female",
        despawnTime = 60,
        spawnLocation = { x = 0.0, y = 0.0, z = 0.0, w = 0.0 },
        blip = {
            sprite = 141,
            scale = 0.7,
            color = 2,
            name = "Cow"
        }
    },
    pig = {
        model = "a_c_pig",
        label = "Pig",
        description = "A pig for meat production",
        icon = "pig",
        isFemale = false,
        productReady = false,
        hunger = 100,
        water = 100,
        age = "1 Year",
        gender = "Male",
        despawnTime = 60,
        spawnLocation = { x = 0.0, y = 0.0, z = 0.0, w = 0.0 },
        blip = {
            sprite = 515,
            scale = 0.7,
            color = 8,
            name = "Pig"
        }
    }
}

-- Vendor Configuration
Config.Vendor = {
    npcModel = "a_m_m_farmer_01",
    spawnLocation = { x = 1000.0, y = 1000.0, z = 100.0, w = 0.0 },
    stockLimits = {
        cow = 10,
        pig = 15
    },
    animalPrices = {
        cow = 5000,
        pig = 3000
    }
}

-- Farmlots Configuration
Config.Farmlots = {
    types = {
        cow = {
            price = 50000,
            seller = {
                model = "a_m_m_farmer_01",
                coords = { x = 2000.0, y = 2000.0, z = 100.0, w = 0.0 }
            },
            farmArea = {
                coords = { x = 2000.0, y = 2000.0, z = 100.0, w = 0.0 },
                size = { x = 20.0, y = 20.0, z = 5.0 }
            },
            spawnAnimals = true
        },
        pig = {
            price = 30000,
            seller = {
                model = "a_m_m_farmer_01",
                coords = { x = 3000.0, y = 3000.0, z = 100.0, w = 0.0 }
            },
            farmArea = {
                coords = { x = 3000.0, y = 3000.0, z = 100.0, w = 0.0 },
                size = { x = 15.0, y = 15.0, z = 5.0 }
            },
            spawnAnimals = true
        }
    }
}