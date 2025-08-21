local QBCore = exports['qb-core']:GetCoreObject()

-- Check production requirements
local function CheckProductionRequirements(animalData, animalConfig)
    -- Check health, hunger, thirst requirements
    if animalData.health < Config.ProductionRequirements.minHealth then
        return false, 'Animal health is too low (minimum: ' .. Config.ProductionRequirements.minHealth .. '%)'
    end
    
    if animalData.hunger < Config.ProductionRequirements.minHunger then
        return false, 'Animal hunger is too low (minimum: ' .. Config.ProductionRequirements.minHunger .. '%)'
    end
    
    if animalData.thirst < Config.ProductionRequirements.minThirst then
        return false, 'Animal thirst is too low (minimum: ' .. Config.ProductionRequirements.minThirst .. '%)'
    end
    
    -- Check gender requirements
    if animalConfig.genderProduction and animalData.gender ~= 'Female' then
        return false, 'Only female ' .. animalConfig.label:lower() .. 's can produce ' .. animalConfig.productionItem
    end
    
    -- Check production cooldown
    if animalData.lastProduction then
        local lastProduction = os.time({
            year = tonumber(string.sub(animalData.lastProduction, 1, 4)),
            month = tonumber(string.sub(animalData.lastProduction, 6, 7)),
            day = tonumber(string.sub(animalData.lastProduction, 9, 10)),
            hour = tonumber(string.sub(animalData.lastProduction, 12, 13)),
            min = tonumber(string.sub(animalData.lastProduction, 15, 16)),
            sec = tonumber(string.sub(animalData.lastProduction, 18, 19))
        })
        
        local currentTime = os.time()
        local timeDiff = (currentTime - lastProduction) * 1000 -- Convert to milliseconds
        
        if timeDiff < animalConfig.productionTime then
            local remainingTime = math.ceil((animalConfig.productionTime - timeDiff) / 1000 / 60) -- Minutes
            return false, 'Production cooldown active. Try again in ' .. remainingTime .. ' minutes'
        end
    end
    
    return true, nil
end

-- Calculate production amount based on level and bonuses
local function CalculateProductionAmount(animalData, animalConfig)
    local baseAmount = math.random(animalConfig.productionAmount.min, animalConfig.productionAmount.max)
    
    -- Apply level bonuses
    local levelBonus = Config.Experience.levelBonuses[animalData.level]
    if levelBonus and levelBonus.productionBonus then
        local bonusPercentage = levelBonus.productionBonus / 100
        baseAmount = math.ceil(baseAmount * (1 + bonusPercentage))
    end
    
    return baseAmount
end

-- Collect products event
RegisterNetEvent('animal_farming:server:collectProducts', function(animalId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local animalData = exports.animal_farming:GetAnimalData(animalId)
    
    if not animalData then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Animal Farming',
            description = 'Animal not found',
            type = 'error'
        })
        return
    end
    
    -- Check ownership
    if animalData.citizenid ~= citizenid then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Animal Farming',
            description = 'You don\'t own this animal',
            type = 'error'
        })
        return
    end
    
    local animalConfig = Config.Animals[animalData.animalType]
    if not animalConfig then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Animal Farming',
            description = 'Invalid animal type',
            type = 'error'
        })
        return
    end
    
    -- Check production requirements
    local canProduce, errorMessage = CheckProductionRequirements(animalData, animalConfig)
    if not canProduce then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Animal Farming',
            description = errorMessage,
            type = 'error'
        })
        return
    end
    
    -- Calculate production amount
    local productionAmount = CalculateProductionAmount(animalData, animalConfig)
    
    -- Add items to inventory
    local success = exports.ox_inventory:AddItem(src, animalConfig.productionItem, productionAmount)
    
    if success then
        -- Update animal data
        animalData.lastProduction = os.date('%Y-%m-%d %H:%M:%S')
        animalData.experience = animalData.experience + animalConfig.expPerProduction
        animalData.level = math.floor(animalData.experience / Config.Experience.expPerLevel) + 1
        
        -- Save to database
        MySQL.update('UPDATE animal_livestock SET last_production = ?, experience = ?, updated_at = NOW() WHERE animal_id = ?', {
            animalData.lastProduction,
            animalData.experience,
            animalId
        })
        
        -- Notify player
        local itemLabel = exports.ox_inventory:Items(animalConfig.productionItem).label or animalConfig.productionItem
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Animal Farming',
            description = 'Collected ' .. productionAmount .. 'x ' .. itemLabel .. '! +' .. animalConfig.expPerProduction .. ' EXP',
            type = 'success'
        })
        
        -- Update client stats
        TriggerClientEvent('animal_farming:client:updateAnimalStats', src, animalId, {
            health = animalData.health,
            hunger = animalData.hunger,
            thirst = animalData.thirst,
            experience = animalData.experience,
            level = animalData.level
        })
        
        -- Trigger collection animation
        TriggerClientEvent('animal_farming:client:playCollectionAnimation', src, animalId)
        
        if Config.Debug then
            print('^2[Animal Farming]^0 Player ' .. citizenid .. ' collected ' .. productionAmount .. 'x ' .. animalConfig.productionItem .. ' from animal ' .. animalId)
        end
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Animal Farming',
            description = 'Inventory full! Cannot collect products.',
            type = 'error'
        })
    end
end)

-- Get production status for an animal
RegisterNetEvent('animal_farming:server:getProductionStatus', function(animalId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local animalData = exports.animal_farming:GetAnimalData(animalId)
    
    if not animalData or animalData.citizenid ~= citizenid then
        return
    end
    
    local animalConfig = Config.Animals[animalData.animalType]
    if not animalConfig then return end
    
    local canProduce, errorMessage = CheckProductionRequirements(animalData, animalConfig)
    local productionAmount = 0
    
    if canProduce then
        productionAmount = CalculateProductionAmount(animalData, animalConfig)
    end
    
    TriggerClientEvent('animal_farming:client:receiveProductionStatus', src, animalId, {
        canProduce = canProduce,
        errorMessage = errorMessage,
        productionAmount = productionAmount,
        productionItem = animalConfig.productionItem
    })
end)

-- Export functions
exports('CheckProductionRequirements', CheckProductionRequirements)
exports('CalculateProductionAmount', CalculateProductionAmount)