local QBCore = exports['qbx_core']:GetCoreObject()

-- Global variables
local activeAnimals = {} -- Store active animal entities
local farmlotOwners = {} -- Cache farmlot ownership
local animalStats = {} -- Store animal stats

-- Utility functions
local function debugPrint(message)
    if Config.Debug then
        print("[Animal Farming] " .. message)
    end
end

local function generateAnimalId()
    return "animal_" .. math.random(100000, 999999) .. "_" .. os.time()
end

local function getRandomGender()
    return math.random(100) <= Config.GenderChance.female and "female" or "male"
end

local function isWithinBoundaries(coords, boundaries)
    return coords.x >= boundaries.min.x and coords.x <= boundaries.max.x and
           coords.y >= boundaries.min.y and coords.y <= boundaries.max.y and
           coords.z >= boundaries.min.z and coords.z <= boundaries.max.z
end

local function getRandomCoordsInBoundary(boundaries)
    local x = math.random() * (boundaries.max.x - boundaries.min.x) + boundaries.min.x
    local y = math.random() * (boundaries.max.y - boundaries.min.y) + boundaries.min.y
    local z = boundaries.min.z + 1.0 -- Spawn slightly above ground
    return vector3(x, y, z)
end

-- Database functions
local function loadFarmlotOwnership()
    local result = MySQL.query.await('SELECT * FROM animal_farmlots')
    for i = 1, #result do
        local data = result[i]
        if not farmlotOwners[data.citizenid] then
            farmlotOwners[data.citizenid] = {}
        end
        farmlotOwners[data.citizenid][data.farmlot_id] = {
            animalType = data.animal_type,
            purchaseDate = data.purchase_date
        }
    end
    debugPrint("Loaded " .. #result .. " farmlot ownerships")
end

local function loadAnimalStats()
    local result = MySQL.query.await('SELECT * FROM animal_livestock WHERE is_alive = 1')
    for i = 1, #result do
        local data = result[i]
        animalStats[data.animal_id] = {
            citizenid = data.citizenid,
            farmlotId = data.farmlot_id,
            animalType = data.animal_type,
            gender = data.gender,
            health = data.health,
            hunger = data.hunger,
            thirst = data.thirst,
            lastFed = data.last_fed,
            lastWatered = data.last_watered,
            lastProduction = data.last_production,
            coords = vector3(data.coords_x or 0, data.coords_y or 0, data.coords_z or 0)
        }
    end
    debugPrint("Loaded " .. #result .. " animal stats")
end

-- Farmlot management
local function getFarmlotById(farmlotId)
    for i = 1, #Config.Farmlots do
        if Config.Farmlots[i].id == farmlotId then
            return Config.Farmlots[i]
        end
    end
    return nil
end

local function getPlayerFarmlots(citizenid)
    return farmlotOwners[citizenid] or {}
end

local function canPurchaseFarmlot(citizenid)
    if Config.MaxFarmlotsPerPlayer == -1 then
        return true
    end
    local ownedCount = 0
    local playerFarmlots = getPlayerFarmlots(citizenid)
    for _ in pairs(playerFarmlots) do
        ownedCount = ownedCount + 1
    end
    return ownedCount < Config.MaxFarmlotsPerPlayer
end

-- Animal management
local function spawnAnimal(citizenid, farmlotId, animalType, animalId, coords, gender)
    local farmlot = getFarmlotById(farmlotId)
    if not farmlot then return false end
    
    local animalConfig = Config.Animals[animalType]
    if not animalConfig then return false end
    
    -- Spawn animal with delay
    SetTimeout(animalConfig.spawnDelay, function()
        local animalHash = GetHashKey(animalConfig.model)
        RequestModel(animalHash)
        
        while not HasModelLoaded(animalHash) do
            Wait(100)
        end
        
        local animal = CreatePed(28, animalHash, coords.x, coords.y, coords.z, 0.0, true, false)
        SetEntityAsMissionEntity(animal, true, true)
        SetPedRandomComponentVariation(animal, false)
        
        -- Store animal reference
        activeAnimals[animalId] = {
            entity = animal,
            citizenid = citizenid,
            farmlotId = farmlotId,
            animalType = animalType,
            gender = gender
        }
        
        debugPrint("Spawned " .. gender .. " " .. animalType .. " with ID: " .. animalId)
        
        -- Set animal to wander within boundaries
        TaskWanderInArea(animal, coords.x, coords.y, coords.z, 10.0, 1.0, 1.0)
    end)
    
    return true
end

local function despawnAnimal(animalId)
    if activeAnimals[animalId] then
        if DoesEntityExist(activeAnimals[animalId].entity) then
            DeleteEntity(activeAnimals[animalId].entity)
        end
        activeAnimals[animalId] = nil
        debugPrint("Despawned animal: " .. animalId)
    end
end

local function spawnPlayerAnimals(citizenid)
    local result = MySQL.query.await('SELECT * FROM animal_livestock WHERE citizenid = ? AND is_alive = 1', {citizenid})
    
    for i = 1, #result do
        local data = result[i]
        local coords = vector3(data.coords_x, data.coords_y, data.coords_z)
        spawnAnimal(citizenid, data.farmlot_id, data.animal_type, data.animal_id, coords, data.gender)
    end
end

local function despawnPlayerAnimals(citizenid)
    for animalId, animalData in pairs(activeAnimals) do
        if animalData.citizenid == citizenid then
            -- Save current position before despawning
            if DoesEntityExist(animalData.entity) then
                local coords = GetEntityCoords(animalData.entity)
                MySQL.update('UPDATE animal_livestock SET coords_x = ?, coords_y = ?, coords_z = ? WHERE animal_id = ?', 
                    {coords.x, coords.y, coords.z, animalId})
            end
            despawnAnimal(animalId)
        end
    end
end

-- Stats degradation system
local function updateAnimalStats()
    for animalId, stats in pairs(animalStats) do
        if stats.health > 0 then
            -- Decrease hunger and thirst over time
            stats.hunger = math.max(0, stats.hunger - Config.DegradationRates.hunger)
            stats.thirst = math.max(0, stats.thirst - Config.DegradationRates.thirst)
            
            -- Decrease health if hungry or thirsty
            if stats.hunger <= Config.DeathThresholds.hunger or stats.thirst <= Config.DeathThresholds.thirst then
                stats.health = math.max(0, stats.health - Config.DegradationRates.health)
            end
            
            -- Check if animal died
            if stats.health <= Config.DeathThresholds.health then
                -- Mark as dead in database
                MySQL.update('UPDATE animal_livestock SET is_alive = 0, health = 0 WHERE animal_id = ?', {animalId})
                
                -- Despawn the animal
                despawnAnimal(animalId)
                
                -- Remove from stats
                animalStats[animalId] = nil
                
                debugPrint("Animal " .. animalId .. " died from neglect")
            else
                -- Update database with new stats
                MySQL.update('UPDATE animal_livestock SET health = ?, hunger = ?, thirst = ? WHERE animal_id = ?', 
                    {stats.health, stats.hunger, stats.thirst, animalId})
            end
        end
    end
end

-- Production system
local function checkAnimalProduction(animalId)
    local stats = animalStats[animalId]
    if not stats then return false end
    
    local animalConfig = Config.Animals[stats.animalType]
    if not animalConfig then return false end
    
    -- Check if animal can produce (gender check)
    if not animalConfig.canProduce[stats.gender] then
        return false
    end
    
    -- Check if enough time has passed since last production
    local currentTime = os.time()
    local lastProduction = stats.lastProduction and MySQL.scalar.await('SELECT UNIX_TIMESTAMP(last_production) FROM animal_livestock WHERE animal_id = ?', {animalId}) or 0
    
    if (currentTime - lastProduction) >= animalConfig.productionTime then
        -- Check if animal is healthy enough to produce
        if stats.health >= 50 and stats.hunger >= 30 then
            return true
        end
    end
    
    return false
end

-- Events
RegisterNetEvent('animal_farming:server:purchaseFarmlot', function(farmlotId)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    
    local farmlot = getFarmlotById(farmlotId)
    if not farmlot then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'Invalid farmlot selected',
            type = 'error'
        })
        return
    end
    
    -- Check if already owned
    if farmlotOwners[player.PlayerData.citizenid] and farmlotOwners[player.PlayerData.citizenid][farmlotId] then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'You already own this farmlot',
            type = 'error'
        })
        return
    end
    
    -- Check if player can purchase more farmlots
    if not canPurchaseFarmlot(player.PlayerData.citizenid) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'You have reached the maximum number of farmlots',
            type = 'error'
        })
        return
    end
    
    -- Check if player has enough money
    if player.PlayerData.money.cash < farmlot.price then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'You need $' .. farmlot.price .. ' to purchase this farmlot',
            type = 'error'
        })
        return
    end
    
    -- Remove money and add farmlot
    player.Functions.RemoveMoney('cash', farmlot.price)
    
    -- Save to database
    MySQL.insert('INSERT INTO animal_farmlots (citizenid, farmlot_id, animal_type) VALUES (?, ?, ?)', 
        {player.PlayerData.citizenid, farmlotId, farmlot.animalType})
    
    -- Update cache
    if not farmlotOwners[player.PlayerData.citizenid] then
        farmlotOwners[player.PlayerData.citizenid] = {}
    end
    farmlotOwners[player.PlayerData.citizenid][farmlotId] = {
        animalType = farmlot.animalType,
        purchaseDate = os.date('%Y-%m-%d %H:%M:%S')
    }
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Success',
        description = 'You purchased ' .. farmlot.name .. ' for $' .. farmlot.price,
        type = 'success'
    })
    
    debugPrint(player.PlayerData.citizenid .. " purchased farmlot " .. farmlotId)
end)

RegisterNetEvent('animal_farming:server:purchaseAnimal', function(animalType)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    
    local animalConfig = Config.Animals[animalType]
    if not animalConfig then return end
    
    -- Check if player has any farmlots for this animal type
    local playerFarmlots = getPlayerFarmlots(player.PlayerData.citizenid)
    local validFarmlot = nil
    
    for farmlotId, farmlotData in pairs(playerFarmlots) do
        if farmlotData.animalType == animalType then
            validFarmlot = getFarmlotById(farmlotId)
            break
        end
    end
    
    if not validFarmlot then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'You need to own a ' .. animalType .. ' farmlot first',
            type = 'error'
        })
        return
    end
    
    -- Check if player has enough money
    if player.PlayerData.money.cash < animalConfig.price then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'You need $' .. animalConfig.price .. ' to purchase this animal',
            type = 'error'
        })
        return
    end
    
    -- Generate animal data
    local animalId = generateAnimalId()
    local gender = getRandomGender()
    local spawnCoords = getRandomCoordsInBoundary(validFarmlot.boundaries)
    
    -- Remove money
    player.Functions.RemoveMoney('cash', animalConfig.price)
    
    -- Save to database
    MySQL.insert('INSERT INTO animal_livestock (citizenid, farmlot_id, animal_type, animal_id, gender, coords_x, coords_y, coords_z) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', 
        {player.PlayerData.citizenid, validFarmlot.id, animalType, animalId, gender, spawnCoords.x, spawnCoords.y, spawnCoords.z})
    
    -- Add to stats cache
    animalStats[animalId] = {
        citizenid = player.PlayerData.citizenid,
        farmlotId = validFarmlot.id,
        animalType = animalType,
        gender = gender,
        health = animalConfig.maxHealth,
        hunger = animalConfig.maxHunger,
        thirst = animalConfig.maxThirst,
        lastFed = nil,
        lastWatered = nil,
        lastProduction = nil,
        coords = spawnCoords
    }
    
    -- Spawn the animal
    spawnAnimal(player.PlayerData.citizenid, validFarmlot.id, animalType, animalId, spawnCoords, gender)
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Success',
        description = 'You purchased a ' .. gender .. ' ' .. animalConfig.name .. ' for $' .. animalConfig.price,
        type = 'success'
    })
    
    debugPrint(player.PlayerData.citizenid .. " purchased " .. gender .. " " .. animalType .. " with ID: " .. animalId)
end)

RegisterNetEvent('animal_farming:server:feedAnimal', function(animalId)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    
    local stats = animalStats[animalId]
    if not stats or stats.citizenid ~= player.PlayerData.citizenid then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'This is not your animal',
            type = 'error'
        })
        return
    end
    
    -- Check if player has feed
    local hasItem = exports.ox_inventory:GetItemCount(src, Config.Feeding.feedItem)
    if hasItem < 1 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'You need animal feed to feed this animal',
            type = 'error'
        })
        return
    end
    
    -- Remove feed item
    exports.ox_inventory:RemoveItem(src, Config.Feeding.feedItem, 1)
    
    -- Update stats
    stats.hunger = math.min(100, stats.hunger + Config.Feeding.hungerIncrease)
    stats.health = math.min(100, stats.health + Config.Feeding.healthIncrease)
    stats.lastFed = os.date('%Y-%m-%d %H:%M:%S')
    
    -- Update database
    MySQL.update('UPDATE animal_livestock SET hunger = ?, health = ?, last_fed = NOW() WHERE animal_id = ?', 
        {stats.hunger, stats.health, animalId})
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Success',
        description = 'You fed the animal',
        type = 'success'
    })
    
    debugPrint(player.PlayerData.citizenid .. " fed animal " .. animalId)
end)

RegisterNetEvent('animal_farming:server:collectProduct', function(animalId)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    
    local stats = animalStats[animalId]
    if not stats or stats.citizenid ~= player.PlayerData.citizenid then return end
    
    if not checkAnimalProduction(animalId) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'This animal is not ready to produce yet',
            type = 'error'
        })
        return
    end
    
    local animalConfig = Config.Animals[stats.animalType]
    local productAmount = math.random(animalConfig.productAmount.min, animalConfig.productAmount.max)
    
    -- Add product to inventory
    exports.ox_inventory:AddItem(src, animalConfig.product, productAmount)
    
    -- Update last production time
    stats.lastProduction = os.date('%Y-%m-%d %H:%M:%S')
    MySQL.update('UPDATE animal_livestock SET last_production = NOW() WHERE animal_id = ?', {animalId})
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Success',
        description = 'You collected ' .. productAmount .. 'x ' .. animalConfig.product,
        type = 'success'
    })
    
    debugPrint(player.PlayerData.citizenid .. " collected " .. productAmount .. "x " .. animalConfig.product .. " from animal " .. animalId)
end)

-- Player connection events
RegisterNetEvent('QBCore:Server:PlayerLoaded', function(playerId)
    local player = exports.qbx_core:GetPlayer(playerId)
    if player then
        SetTimeout(5000, function() -- Wait 5 seconds for player to fully load
            spawnPlayerAnimals(player.PlayerData.citizenid)
        end)
    end
end)

RegisterNetEvent('QBCore:Server:OnPlayerUnload', function(playerId)
    local player = exports.qbx_core:GetPlayer(playerId)
    if player then
        despawnPlayerAnimals(player.PlayerData.citizenid)
    end
end)

-- Callbacks
lib.callback.register('animal_farming:getPlayerFarmlots', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return {} end
    
    return getPlayerFarmlots(player.PlayerData.citizenid)
end)

lib.callback.register('animal_farming:getAnimalStats', function(source, animalId)
    return animalStats[animalId]
end)

-- Initialize
CreateThread(function()
    -- Load data from database
    loadFarmlotOwnership()
    loadAnimalStats()
    
    -- Start stats degradation loop
    while true do
        Wait(60000) -- Update every minute
        updateAnimalStats()
    end
end)

debugPrint("Animal Farming Server initialized")