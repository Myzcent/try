local QBCore = exports.qbx_core:GetCoreObject()

-- Calculate butcher yield based on animal level and success rate
local function CalculateButcherYield(animalData, animalConfig, successRate)
    local baseYield = math.random(animalConfig.butcherYield.min, animalConfig.butcherYield.max)
    
    -- Apply level bonuses
    local levelBonus = Config.Experience.levelBonuses[animalData.level]
    if levelBonus and levelBonus.productionBonus then
        local bonusPercentage = levelBonus.productionBonus / 100
        baseYield = math.ceil(baseYield * (1 + bonusPercentage))
    end
    
    -- Apply success rate modifier
    local successModifier = successRate / 100
    local finalYield = math.ceil(baseYield * successModifier)
    
    return math.max(1, finalYield) -- Minimum 1 item
end

-- Butcher animal event
RegisterNetEvent('animal_farming:server:butcherAnimal', function(animalId)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    
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
    
    -- Check if animal is dead
    if animalData.health > 0 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Animal Farming',
            description = 'Animal must be dead before butchering',
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
    
    -- Check if butchering is enabled
    if not Config.Butchering.enabled then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Animal Farming',
            description = 'Butchering is currently disabled',
            type = 'error'
        })
        return
    end
    
    -- Check if player has knife (if required)
    if Config.Butchering.requiresKnife then
        local hasKnife = exports.ox_inventory:GetItemCount(src, Config.Items.knife)
        if hasKnife < 1 then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Animal Farming',
                description = 'You need a knife to butcher animals',
                type = 'error'
            })
            return
        end
    end
    
    -- Start butchering mini-game
    TriggerClientEvent('animal_farming:client:startButcheringMinigame', src, animalId, {
        duration = Config.Butchering.minigameTime,
        difficulty = Config.Butchering.minigameDifficulty,
        skillCheckCount = Config.Butchering.skillCheckCount,
        baseSuccessRate = Config.Butchering.successRate
    })
    
    if Config.Debug then
        print('^2[Animal Farming]^0 Started butchering mini-game for player ' .. citizenid .. ' on animal ' .. animalId)
    end
end)

-- Handle butchering result
RegisterNetEvent('animal_farming:server:butcheringResult', function(animalId, success, successRate)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local animalData = exports.animal_farming:GetAnimalData(animalId)
    
    if not animalData or animalData.citizenid ~= citizenid then
        return
    end
    
    local animalConfig = Config.Animals[animalData.animalType]
    if not animalConfig then return end
    
    if success then
        -- Calculate yield based on success rate
        local meatYield = CalculateButcherYield(animalData, animalConfig, successRate)
        
        -- Add meat to inventory
        local addSuccess = exports.ox_inventory:AddItem(src, Config.Items.meat, meatYield)
        
        if addSuccess then
            -- Remove animal from database
            MySQL.update('UPDATE animal_livestock SET is_dead = 1, updated_at = NOW() WHERE animal_id = ?', {
                animalId
            })
            
            -- Remove from client
            TriggerClientEvent('animal_farming:client:removeAnimal', src, animalId)
            
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Animal Farming',
                description = 'Successfully butchered animal and obtained ' .. meatYield .. 'x raw meat',
                type = 'success'
            })
            
            if Config.Debug then
                print('^2[Animal Farming]^0 Player ' .. citizenid .. ' successfully butchered animal ' .. animalId .. ' for ' .. meatYield .. ' meat')
            end
        else
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Animal Farming',
                description = 'Inventory full! Cannot store butchered meat.',
                type = 'error'
            })
        end
    else
        -- Failed butchering - still remove animal but give less/no meat
        local failedYield = math.random(0, 1) -- 0-1 meat on failure
        
        if failedYield > 0 then
            exports.ox_inventory:AddItem(src, Config.Items.meat, failedYield)
        end
        
        -- Remove animal from database
        MySQL.update('UPDATE animal_livestock SET is_dead = 1, updated_at = NOW() WHERE animal_id = ?', {
            animalId
        })
        
        -- Remove from client
        TriggerClientEvent('animal_farming:client:removeAnimal', src, animalId)
        
        local message = failedYield > 0 and 
            'Butchering failed! You managed to salvage ' .. failedYield .. 'x raw meat' or
            'Butchering failed! No meat was salvaged'
        
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Animal Farming',
            description = message,
            type = 'error'
        })
        
        if Config.Debug then
            print('^3[Animal Farming]^0 Player ' .. citizenid .. ' failed butchering animal ' .. animalId .. ', salvaged ' .. failedYield .. ' meat')
        end
    end
end)

-- Export functions
exports('CalculateButcherYield', CalculateButcherYield)