-- Server exports for other resources to interact with the animal farming system

local function debugPrint(message)
    if Config.Debug then
        print("[Animal Farming Exports] " .. message)
    end
end

-- Export: Get player's farmlots
-- Usage: exports['animal_farming']:GetPlayerFarmlots(citizenid)
function GetPlayerFarmlots(citizenid)
    if not citizenid then
        debugPrint("GetPlayerFarmlots: No citizenid provided")
        return {}
    end
    
    local result = MySQL.query.await('SELECT * FROM animal_farmlots WHERE citizenid = ?', {citizenid})
    local farmlots = {}
    
    for i = 1, #result do
        local data = result[i]
        farmlots[data.farmlot_id] = {
            animalType = data.animal_type,
            purchaseDate = data.purchase_date
        }
    end
    
    debugPrint("Retrieved " .. #result .. " farmlots for " .. citizenid)
    return farmlots
end

-- Export: Get animal stats
-- Usage: exports['animal_farming']:GetAnimalStats(animalId)
function GetAnimalStats(animalId)
    if not animalId then
        debugPrint("GetAnimalStats: No animalId provided")
        return nil
    end
    
    local result = MySQL.single.await('SELECT * FROM animal_livestock WHERE animal_id = ? AND is_alive = 1', {animalId})
    
    if result then
        debugPrint("Retrieved stats for animal " .. animalId)
        return {
            citizenid = result.citizenid,
            farmlotId = result.farmlot_id,
            animalType = result.animal_type,
            gender = result.gender,
            health = result.health,
            hunger = result.hunger,
            thirst = result.thirst,
            lastFed = result.last_fed,
            lastWatered = result.last_watered,
            lastProduction = result.last_production,
            coords = vector3(result.coords_x or 0, result.coords_y or 0, result.coords_z or 0)
        }
    end
    
    debugPrint("Animal " .. animalId .. " not found or is dead")
    return nil
end

-- Export: Spawn animal (for other resources)
-- Usage: exports['animal_farming']:SpawnAnimal(citizenid, farmlotId, animalType, coords, gender)
function SpawnAnimal(citizenid, farmlotId, animalType, coords, gender)
    if not citizenid or not farmlotId or not animalType or not coords then
        debugPrint("SpawnAnimal: Missing required parameters")
        return false
    end
    
    -- Validate animal type
    if not Config.Animals[animalType] then
        debugPrint("SpawnAnimal: Invalid animal type " .. animalType)
        return false
    end
    
    -- Validate farmlot ownership
    local farmlots = GetPlayerFarmlots(citizenid)
    if not farmlots[farmlotId] then
        debugPrint("SpawnAnimal: Player " .. citizenid .. " does not own farmlot " .. farmlotId)
        return false
    end
    
    -- Generate animal data
    local animalId = "export_" .. math.random(100000, 999999) .. "_" .. os.time()
    local animalGender = gender or (math.random(100) <= Config.GenderChance.female and "female" or "male")
    local animalConfig = Config.Animals[animalType]
    
    -- Save to database
    local success = MySQL.insert.await('INSERT INTO animal_livestock (citizenid, farmlot_id, animal_type, animal_id, gender, coords_x, coords_y, coords_z) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', 
        {citizenid, farmlotId, animalType, animalId, animalGender, coords.x, coords.y, coords.z})
    
    if success then
        -- Add to stats cache (assuming the main script's animalStats is accessible)
        if animalStats then
            animalStats[animalId] = {
                citizenid = citizenid,
                farmlotId = farmlotId,
                animalType = animalType,
                gender = animalGender,
                health = animalConfig.maxHealth,
                hunger = animalConfig.maxHunger,
                thirst = animalConfig.maxThirst,
                lastFed = nil,
                lastWatered = nil,
                lastProduction = nil,
                coords = coords
            }
        end
        
        debugPrint("Spawned " .. animalGender .. " " .. animalType .. " with ID: " .. animalId)
        return animalId
    end
    
    debugPrint("Failed to spawn animal in database")
    return false
end

-- Export: Despawn animal (for other resources)
-- Usage: exports['animal_farming']:DespawnAnimal(animalId)
function DespawnAnimal(animalId)
    if not animalId then
        debugPrint("DespawnAnimal: No animalId provided")
        return false
    end
    
    -- Mark as dead in database
    local success = MySQL.update.await('UPDATE animal_livestock SET is_alive = 0 WHERE animal_id = ?', {animalId})
    
    if success then
        -- Remove from active animals and stats cache
        if activeAnimals and activeAnimals[animalId] then
            if DoesEntityExist(activeAnimals[animalId].entity) then
                DeleteEntity(activeAnimals[animalId].entity)
            end
            activeAnimals[animalId] = nil
        end
        
        if animalStats and animalStats[animalId] then
            animalStats[animalId] = nil
        end
        
        debugPrint("Despawned animal " .. animalId)
        return true
    end
    
    debugPrint("Failed to despawn animal " .. animalId)
    return false
end

-- Export: Get all animals in a farmlot
-- Usage: exports['animal_farming']:GetFarmlotAnimals(farmlotId)
function GetFarmlotAnimals(farmlotId)
    if not farmlotId then
        debugPrint("GetFarmlotAnimals: No farmlotId provided")
        return {}
    end
    
    local result = MySQL.query.await('SELECT * FROM animal_livestock WHERE farmlot_id = ? AND is_alive = 1', {farmlotId})
    
    debugPrint("Retrieved " .. #result .. " animals for farmlot " .. farmlotId)
    return result
end

-- Export: Force feed animal (for other resources)
-- Usage: exports['animal_farming']:FeedAnimal(animalId, hungerAmount, healthAmount)
function FeedAnimal(animalId, hungerAmount, healthAmount)
    if not animalId then
        debugPrint("FeedAnimal: No animalId provided")
        return false
    end
    
    hungerAmount = hungerAmount or Config.Feeding.hungerIncrease
    healthAmount = healthAmount or Config.Feeding.healthIncrease
    
    local result = MySQL.single.await('SELECT health, hunger FROM animal_livestock WHERE animal_id = ? AND is_alive = 1', {animalId})
    
    if result then
        local newHunger = math.min(100, result.hunger + hungerAmount)
        local newHealth = math.min(100, result.health + healthAmount)
        
        MySQL.update('UPDATE animal_livestock SET hunger = ?, health = ?, last_fed = NOW() WHERE animal_id = ?', 
            {newHunger, newHealth, animalId})
        
        -- Update stats cache if available
        if animalStats and animalStats[animalId] then
            animalStats[animalId].hunger = newHunger
            animalStats[animalId].health = newHealth
            animalStats[animalId].lastFed = os.date('%Y-%m-%d %H:%M:%S')
        end
        
        debugPrint("Fed animal " .. animalId .. " (Hunger: +" .. hungerAmount .. ", Health: +" .. healthAmount .. ")")
        return true
    end
    
    debugPrint("Animal " .. animalId .. " not found or is dead")
    return false
end

-- Export: Check if animal can produce
-- Usage: exports['animal_farming']:CanAnimalProduce(animalId)
function CanAnimalProduce(animalId)
    if not animalId then
        debugPrint("CanAnimalProduce: No animalId provided")
        return false
    end
    
    local result = MySQL.single.await('SELECT animal_type, gender, health, hunger, last_production FROM animal_livestock WHERE animal_id = ? AND is_alive = 1', {animalId})
    
    if not result then
        debugPrint("Animal " .. animalId .. " not found or is dead")
        return false
    end
    
    local animalConfig = Config.Animals[result.animal_type]
    if not animalConfig then
        debugPrint("Invalid animal type for " .. animalId)
        return false
    end
    
    -- Check gender requirements
    if not animalConfig.canProduce[result.gender] then
        debugPrint("Animal " .. animalId .. " (" .. result.gender .. ") cannot produce " .. animalConfig.product)
        return false
    end
    
    -- Check health and hunger requirements
    if result.health < 50 or result.hunger < 30 then
        debugPrint("Animal " .. animalId .. " is not healthy enough to produce")
        return false
    end
    
    -- Check cooldown
    local currentTime = os.time()
    local lastProduction = result.last_production and MySQL.scalar.await('SELECT UNIX_TIMESTAMP(last_production) FROM animal_livestock WHERE animal_id = ?', {animalId}) or 0
    
    if (currentTime - lastProduction) < animalConfig.productionTime then
        local timeLeft = animalConfig.productionTime - (currentTime - lastProduction)
        debugPrint("Animal " .. animalId .. " needs " .. timeLeft .. " more seconds before next production")
        return false
    end
    
    debugPrint("Animal " .. animalId .. " can produce " .. animalConfig.product)
    return true
end