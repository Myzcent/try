local QBCore = exports.qbx_core:GetCoreObject()

-- Local variables
local spawnedAnimals = {} -- [animalId] = {entity, data}
local animalData = {} -- [animalId] = {database data}

-- Generate unique animal ID
local function GenerateAnimalId()
    return 'animal_' .. math.random(100000, 999999) .. '_' .. os.time()
end

-- Generate random gender based on config
local function GenerateGender()
    local chance = math.random(1, 100)
    return chance <= Config.FemaleChance and 'Female' or 'Male'
end

-- Calculate level from experience
local function CalculateLevel(experience)
    return math.floor(experience / Config.Experience.expPerLevel) + 1
end

-- Get random position within farmlot boundaries
local function GetRandomPositionInLot(lotId)
    local lotConfig = nil
    for i = 1, #Config.Farmlots do
        if Config.Farmlots[i].id == lotId then
            lotConfig = Config.Farmlots[i]
            break
        end
    end
    
    if not lotConfig or not lotConfig.boundaries then
        return lotConfig.coordinates
    end
    
    local min = lotConfig.boundaries.min
    local max = lotConfig.boundaries.max
    
    return vector3(
        math.random(min.x * 100, max.x * 100) / 100,
        math.random(min.y * 100, max.y * 100) / 100,
        min.z
    )
end

-- Load animals from database
local function LoadAnimalsFromDatabase()
    MySQL.query('SELECT * FROM animal_livestock WHERE is_dead = 0', {}, function(result)
        if result then
            for i = 1, #result do
                local animal = result[i]
                animalData[animal.animal_id] = {
                    id = animal.animal_id,
                    citizenid = animal.citizenid,
                    lotId = animal.lot_id,
                    animalType = animal.animal_type,
                    gender = animal.gender,
                    health = animal.health,
                    hunger = animal.hunger,
                    thirst = animal.thirst,
                    experience = animal.experience,
                    level = CalculateLevel(animal.experience),
                    coordinates = json.decode(animal.coordinates),
                    lastFed = animal.last_fed,
                    lastWatered = animal.last_watered,
                    lastProduction = animal.last_production,
                    createdAt = animal.created_at
                }
            end
            if Config.Debug then
                print('^2[Animal Farming]^0 Loaded ' .. #result .. ' animals from database')
            end
        end
    end)
end

-- Save animal data to database
local function SaveAnimalData(animalId)
    local animal = animalData[animalId]
    if not animal then return end
    
    MySQL.update('UPDATE animal_livestock SET health = ?, hunger = ?, thirst = ?, experience = ?, coordinates = ?, last_fed = ?, last_watered = ?, last_production = ?, updated_at = NOW() WHERE animal_id = ?', {
        animal.health,
        animal.hunger,
        animal.thirst,
        animal.experience,
        json.encode(animal.coordinates),
        animal.lastFed,
        animal.lastWatered,
        animal.lastProduction,
        animalId
    })
end

-- Spawn animal for player
local function SpawnAnimalForPlayer(src, animalId)
    local animal = animalData[animalId]
    if not animal then return end
    
    TriggerClientEvent('animal_farming:client:spawnAnimal', src, {
        id = animalId,
        type = animal.animalType,
        coordinates = animal.coordinates,
        data = animal
    })
    
    if Config.Debug then
        print('^2[Animal Farming]^0 Spawned animal ' .. animalId .. ' for player')
    end
end

-- Initialize system
CreateThread(function()
    LoadAnimalsFromDatabase()
    
    -- Start stat degradation loop
    while true do
        Wait(Config.StatDegradationInterval)
        
        for animalId, animal in pairs(animalData) do
            if animal.health > 0 then
                local animalConfig = Config.Animals[animal.animalType]
                if animalConfig then
                    -- Degrade hunger and thirst
                    animal.hunger = math.max(0, animal.hunger - animalConfig.hungerDegradation)
                    animal.thirst = math.max(0, animal.thirst - animalConfig.thirstDegradation)
                    
                    -- Health degradation based on hunger/thirst
                    if animal.hunger <= 10 or animal.thirst <= 10 then
                        animal.health = math.max(0, animal.health - 5)
                    end
                    
                    -- Save changes
                    SaveAnimalData(animalId)
                    
                    -- Update client if animal is spawned
                    TriggerClientEvent('animal_farming:client:updateAnimalStats', -1, animalId, {
                        health = animal.health,
                        hunger = animal.hunger,
                        thirst = animal.thirst,
                        experience = animal.experience,
                        level = animal.level
                    })
                end
            end
        end
    end
end)

-- Purchase animal event
RegisterNetEvent('animal_farming:server:purchaseAnimal', function(animalType, lotId)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local animalConfig = Config.Animals[animalType]
    
    if not animalConfig then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Animal Farming',
            description = 'Invalid animal type',
            type = 'error'
        })
        return
    end
    
    -- Check if player owns the lot
    if not exports.animal_farming:PlayerOwnsLot(citizenid, lotId) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Animal Farming',
            description = 'You don\'t own this farmlot',
            type = 'error'
        })
        return
    end
    
    -- Check lot type compatibility
    local lotConfig = nil
    for i = 1, #Config.Farmlots do
        if Config.Farmlots[i].id == lotId then
            lotConfig = Config.Farmlots[i]
            break
        end
    end
    
    if lotConfig and lotConfig.type ~= 'mixed' and lotConfig.type ~= animalType then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Animal Farming',
            description = 'This farmlot only allows ' .. string.upper(lotConfig.type) .. ' animals',
            type = 'error'
        })
        return
    end
    
    -- Check if player has enough money
    if Player.Functions.GetMoney('cash') < animalConfig.price then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Animal Farming',
            description = 'You don\'t have enough cash. Required: $' .. animalConfig.price,
            type = 'error'
        })
        return
    end
    
    -- Remove money
    Player.Functions.RemoveMoney('cash', animalConfig.price)
    
    -- Generate animal data
    local animalId = GenerateAnimalId()
    local gender = GenerateGender()
    local position = GetRandomPositionInLot(lotId)
    
    -- Insert into database
    MySQL.insert('INSERT INTO animal_livestock (citizenid, lot_id, animal_id, animal_type, gender, health, hunger, thirst, experience, level, coordinates, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())', {
        citizenid,
        lotId,
        animalId,
        animalType,
        gender,
        animalConfig.maxHealth,
        animalConfig.maxHunger,
        animalConfig.maxThirst,
        0,
        1,
        json.encode({x = position.x, y = position.y, z = position.z})
    }, function(insertId)
        if insertId then
            -- Add to local cache
            animalData[animalId] = {
                id = animalId,
                citizenid = citizenid,
                lotId = lotId,
                animalType = animalType,
                gender = gender,
                health = animalConfig.maxHealth,
                hunger = animalConfig.maxHunger,
                thirst = animalConfig.maxThirst,
                experience = 0,
                level = 1,
                coordinates = {x = position.x, y = position.y, z = position.z},
                lastFed = nil,
                lastWatered = nil,
                lastProduction = nil,
                createdAt = os.date('%Y-%m-%d %H:%M:%S')
            }
            
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Animal Farming',
                description = 'Successfully purchased ' .. gender .. ' ' .. animalConfig.label .. ' for $' .. animalConfig.price,
                type = 'success'
            })
            
            -- Spawn animal with delay
            SetTimeout(Config.AnimalSpawnDelay, function()
                SpawnAnimalForPlayer(src, animalId)
            end)
            
            if Config.Debug then
                print('^2[Animal Farming]^0 Player ' .. citizenid .. ' purchased ' .. animalType .. ' with ID: ' .. animalId)
            end
        else
            -- Refund money if database insert failed
            Player.Functions.AddMoney('cash', animalConfig.price)
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Animal Farming',
                description = 'Failed to purchase animal. Money refunded.',
                type = 'error'
            })
        end
    end)
end)

-- Get animal data event
RegisterNetEvent('animal_farming:server:getAnimalData', function(animalId)
    local src = source
    local animal = animalData[animalId]
    
    if animal then
        TriggerClientEvent('animal_farming:client:receiveAnimalData', src, animalId, animal)
    end
end)

-- Player loaded - spawn their animals
RegisterNetEvent('animal_farming:server:playerLoaded', function()
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Spawn all player's animals
    for animalId, animal in pairs(animalData) do
        if animal.citizenid == citizenid then
            SpawnAnimalForPlayer(src, animalId)
        end
    end
end)

-- Player disconnected - despawn their animals
RegisterNetEvent('animal_farming:server:playerDisconnected', function(citizenid)
    -- Save all animal data for the disconnected player
    for animalId, animal in pairs(animalData) do
        if animal.citizenid == citizenid then
            SaveAnimalData(animalId)
        end
    end
    
    -- Notify clients to despawn animals
    TriggerClientEvent('animal_farming:client:despawnPlayerAnimals', -1, citizenid)
end)

-- Update animal position
RegisterNetEvent('animal_farming:server:updateAnimalPosition', function(animalId, coordinates)
    local animal = animalData[animalId]
    if animal then
        animal.coordinates = coordinates
        SaveAnimalData(animalId)
    end
end)

-- Feed animal event
RegisterNetEvent('animal_farming:server:feedAnimal', function(animalId)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local animal = animalData[animalId]
    
    if not animal or animal.citizenid ~= citizenid then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Animal Farming',
            description = 'You don\'t own this animal',
            type = 'error'
        })
        return
    end
    
    -- Check if player has feed
    local hasItem = exports.ox_inventory:GetItemCount(src, Config.Items.feed)
    if hasItem < 1 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Animal Farming',
            description = 'You need animal feed to feed this animal',
            type = 'error'
        })
        return
    end
    
    -- Remove feed item
    exports.ox_inventory:RemoveItem(src, Config.Items.feed, 1)
    
    -- Update animal stats
    local animalConfig = Config.Animals[animal.animalType]
    animal.hunger = math.min(animalConfig.maxHunger, animal.hunger + 30)
    animal.health = math.min(animalConfig.maxHealth, animal.health + 10)
    animal.experience = animal.experience + animalConfig.expPerFeed
    animal.level = CalculateLevel(animal.experience)
    animal.lastFed = os.date('%Y-%m-%d %H:%M:%S')
    
    SaveAnimalData(animalId)
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Animal Farming',
        description = 'Animal fed successfully! +' .. animalConfig.expPerFeed .. ' EXP',
        type = 'success'
    })
    
    -- Update client stats
    TriggerClientEvent('animal_farming:client:updateAnimalStats', src, animalId, {
        health = animal.health,
        hunger = animal.hunger,
        thirst = animal.thirst,
        experience = animal.experience,
        level = animal.level
    })
    
    -- Trigger feeding animation
    TriggerClientEvent('animal_farming:client:playFeedingAnimation', src, animalId)
end)

-- Export functions
exports('GetAnimalData', function(animalId)
    return animalData[animalId]
end)

exports('GetPlayerAnimals', function(citizenid)
    local playerAnimals = {}
    for animalId, animal in pairs(animalData) do
        if animal.citizenid == citizenid then
            playerAnimals[#playerAnimals + 1] = animal
        end
    end
    return playerAnimals
end)

-- Handle QBCore player loaded
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    SetTimeout(2000, function() -- Small delay to ensure everything is loaded
        TriggerEvent('animal_farming:server:playerLoaded')
    end)
end)