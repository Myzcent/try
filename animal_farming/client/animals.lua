local QBCore = exports['qb-core']:GetCoreObject()

-- Local variables
local spawnedAnimals = {} -- [animalId] = entity
local animalData = {} -- [animalId] = data
local animalVendorNPC = nil

-- Initialize on player loaded
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    CreateAnimalVendorNPC()
    TriggerServerEvent('animal_farming:server:playerLoaded')
end)

-- Also initialize when resource starts (for already loaded players)
CreateThread(function()
    Wait(2000) -- Wait for everything to load
    if LocalPlayer.state.isLoggedIn then
        CreateAnimalVendorNPC()
        TriggerServerEvent('animal_farming:server:playerLoaded')
    end
end)

-- Create animal vendor NPC
function CreateAnimalVendorNPC()
    if animalVendorNPC and DoesEntityExist(animalVendorNPC) then
        DeleteEntity(animalVendorNPC)
    end
    
    CreateThread(function()
        local vendor = Config.AnimalVendor
        local modelHash = GetHashKey(vendor.model)
        
        -- Request model
        RequestModel(modelHash)
        local timeout = 0
        while not HasModelLoaded(modelHash) and timeout < 100 do
            Wait(100)
            timeout = timeout + 1
        end
        
        if not HasModelLoaded(modelHash) then
            print('^1[Animal Farming]^0 Failed to load animal vendor model: ' .. vendor.model)
            return
        end
        
        -- Create NPC
        animalVendorNPC = CreatePed(4, modelHash, vendor.coords.x, vendor.coords.y, vendor.coords.z, vendor.coords.w, false, true)
        
        if not DoesEntityExist(animalVendorNPC) then
            print('^1[Animal Farming]^0 Failed to create animal vendor NPC')
            SetModelAsNoLongerNeeded(modelHash)
            return
        end
        
        SetEntityInvincible(animalVendorNPC, true)
        FreezeEntityPosition(animalVendorNPC, true)
        SetBlockingOfNonTemporaryEvents(animalVendorNPC, true)
        SetPedDiesWhenInjured(animalVendorNPC, false)
        SetPedCanPlayAmbientAnims(animalVendorNPC, true)
        SetPedCanRagdollFromPlayerImpact(animalVendorNPC, false)
        SetEntityCanBeDamaged(animalVendorNPC, false)
        
        -- Set model as no longer needed
        SetModelAsNoLongerNeeded(modelHash)
        
        -- Add ox_target interaction
        exports.ox_target:addLocalEntity(animalVendorNPC, {
            {
                name = 'animal_vendor',
                icon = 'fas fa-paw',
                label = 'Buy Animals',
                onSelect = function()
                    ShowAnimalPurchaseMenu()
                end
            }
        })
        
        if Config.Debug then
            print('^2[Animal Farming]^0 Created animal vendor NPC')
        end
    end)
end

-- Show animal purchase menu
function ShowAnimalPurchaseMenu()
    local playerFarmlots = exports.animal_farming:GetPlayerFarmlots()
    
    if #playerFarmlots == 0 then
        lib.notify({
            title = 'Animal Farming',
            description = 'You need to own a farmlot first!',
            type = 'error'
        })
        return
    end
    
    local options = {}
    
    for animalType, animalConfig in pairs(Config.Animals) do
        options[#options + 1] = {
            title = animalConfig.label,
            description = 'Price: $' .. animalConfig.price,
            icon = 'fas fa-paw',
            onSelect = function()
                ShowFarmlotSelection(animalType)
            end
        }
    end
    
    lib.registerContext({
        id = 'animal_purchase_menu',
        title = 'Animal Vendor',
        options = options
    })
    
    lib.showContext('animal_purchase_menu')
end

-- Show farmlot selection for animal purchase
function ShowFarmlotSelection(animalType)
    local playerFarmlots = exports.animal_farming:GetPlayerFarmlots()
    local options = {}
    
    for i = 1, #playerFarmlots do
        local lot = playerFarmlots[i]
        local lotConfig = nil
        
        -- Find lot config
        for j = 1, #Config.Farmlots do
            if Config.Farmlots[j].id == lot.id then
                lotConfig = Config.Farmlots[j]
                break
            end
        end
        
        if lotConfig then
            local canPlace = lotConfig.type == 'mixed' or lotConfig.type == animalType
            
            options[#options + 1] = {
                title = lotConfig.label,
                description = canPlace and ('Type: ' .. string.upper(lotConfig.type)) or 'Incompatible lot type',
                icon = canPlace and 'fas fa-check' or 'fas fa-times',
                disabled = not canPlace,
                onSelect = function()
                    if canPlace then
                        local animalConfig = Config.Animals[animalType]
                        local alert = lib.alertDialog({
                            header = 'Purchase Animal',
                            content = 'Purchase ' .. animalConfig.label .. ' for $' .. animalConfig.price .. '?',
                            centered = true,
                            cancel = true
                        })
                        
                        if alert == 'confirm' then
                            TriggerServerEvent('animal_farming:server:purchaseAnimal', animalType, lot.id)
                        end
                    end
                end
            }
        end
    end
    
    if #options == 0 then
        lib.notify({
            title = 'Animal Farming',
            description = 'No compatible farmlots found',
            type = 'error'
        })
        return
    end
    
    lib.registerContext({
        id = 'farmlot_selection_menu',
        title = 'Select Farmlot',
        menu = 'animal_purchase_menu',
        options = options
    })
    
    lib.showContext('farmlot_selection_menu')
end

-- Spawn animal
RegisterNetEvent('animal_farming:client:spawnAnimal', function(animalInfo)
    local animalId = animalInfo.id
    local animalType = animalInfo.type
    local coords = animalInfo.coordinates
    local data = animalInfo.data
    
    -- Store animal data
    animalData[animalId] = data
    
    CreateThread(function()
        local animalConfig = Config.Animals[animalType]
        if not animalConfig then return end
        
        -- Request model
        RequestModel(animalConfig.model)
        while not HasModelLoaded(animalConfig.model) do
            Wait(100)
        end
        
        -- Spawn animal
        local animal = CreatePed(28, animalConfig.model, coords.x, coords.y, coords.z, 0.0, true, false)
        SetEntityAsMissionEntity(animal, true, true)
        SetPedCanRagdoll(animal, false)
        SetEntityInvincible(animal, data.health <= 0)
        
        -- Store spawned animal
        spawnedAnimals[animalId] = animal
        
        -- Add ox_target interactions
        exports.ox_target:addLocalEntity(animal, {
            {
                name = 'check_animal_stats_' .. animalId,
                icon = 'fas fa-info-circle',
                label = 'Check Stats',
                onSelect = function()
                    TriggerServerEvent('animal_farming:server:getAnimalData', animalId)
                end
            },
            {
                name = 'feed_animal_' .. animalId,
                icon = 'fas fa-apple-alt',
                label = 'Feed Animal',
                onSelect = function()
                    TriggerServerEvent('animal_farming:server:feedAnimal', animalId)
                end
            },
            {
                name = 'collect_products_' .. animalId,
                icon = 'fas fa-hand-holding',
                label = 'Collect Products',
                onSelect = function()
                    TriggerServerEvent('animal_farming:server:collectProducts', animalId)
                end
            },
            {
                name = 'butcher_animal_' .. animalId,
                icon = 'fas fa-cut',
                label = 'Butcher Animal',
                canInteract = function()
                    return data.health <= 0
                end,
                onSelect = function()
                    TriggerServerEvent('animal_farming:server:butcherAnimal', animalId)
                end
            }
        })
        
        -- Start animal AI behavior
        StartAnimalBehavior(animal, animalId, data)
        
        if Config.Debug then
            print('^2[Animal Farming]^0 Spawned animal: ' .. animalId .. ' (' .. animalType .. ')')
        end
    end)
end)

-- Start animal behavior (roaming, animations, etc.)
function StartAnimalBehavior(animal, animalId, data)
    CreateThread(function()
        local lastUpdate = GetGameTimer()
        
        while DoesEntityExist(animal) and animalData[animalId] do
            Wait(5000) -- Update every 5 seconds
            
            local currentTime = GetGameTimer()
            
            -- Basic roaming behavior
            if data.health > 0 then
                local currentCoords = GetEntityCoords(animal)
                local lotId = data.lotId
                
                -- Random movement within boundaries
                if math.random(1, 100) <= 30 then -- 30% chance to move
                    local lotConfig = nil
                    for i = 1, #Config.Farmlots do
                        if Config.Farmlots[i].id == lotId then
                            lotConfig = Config.Farmlots[i]
                            break
                        end
                    end
                    
                    if lotConfig and lotConfig.boundaries then
                        local min = lotConfig.boundaries.min
                        local max = lotConfig.boundaries.max
                        local newPos = vector3(
                            math.random(min.x * 100, max.x * 100) / 100,
                            math.random(min.y * 100, max.y * 100) / 100,
                            min.z
                        )
                        
                        TaskGoToCoordAnyMeans(animal, newPos.x, newPos.y, newPos.z, 1.0, 0, 0, 786603, 0xbf800000)
                        
                        -- Update position on server
                        TriggerServerEvent('animal_farming:server:updateAnimalPosition', animalId, {
                            x = newPos.x,
                            y = newPos.y,
                            z = newPos.z
                        })
                    end
                end
                
                -- Random animations
                if math.random(1, 100) <= 10 then -- 10% chance for animation
                    local animations = {'WORLD_COW_GRAZING', 'WORLD_COW_EAT_GROUND'}
                    local randomAnim = animations[math.random(1, #animations)]
                    TaskStartScenarioInPlace(animal, randomAnim, 0, true)
                end
            else
                -- Animal is dead, stop AI
                SetEntityInvincible(animal, true)
                break
            end
            
            lastUpdate = currentTime
        end
    end)
end

-- Update animal stats
RegisterNetEvent('animal_farming:client:updateAnimalStats', function(animalId, stats)
    if animalData[animalId] then
        animalData[animalId].health = stats.health
        animalData[animalId].hunger = stats.hunger
        animalData[animalId].thirst = stats.thirst
        animalData[animalId].experience = stats.experience
        animalData[animalId].level = stats.level
        
        -- Update entity invincibility based on health
        local animal = spawnedAnimals[animalId]
        if animal and DoesEntityExist(animal) then
            SetEntityInvincible(animal, stats.health <= 0)
        end
    end
end)

-- Receive animal data and show NUI
RegisterNetEvent('animal_farming:client:receiveAnimalData', function(animalId, data)
    animalData[animalId] = data
    ShowAnimalStatsNUI(animalId, data)
end)

-- Show animal stats NUI
function ShowAnimalStatsNUI(animalId, data)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'showStats',
        animalId = animalId,
        data = data,
        config = Config.Animals[data.animalType]
    })
end

-- Play feeding animation
RegisterNetEvent('animal_farming:client:playFeedingAnimation', function(animalId)
    local animal = spawnedAnimals[animalId]
    if animal and DoesEntityExist(animal) then
        TaskStartScenarioInPlace(animal, 'WORLD_COW_EAT_GROUND', 0, true)
        
        -- Show progress bar
        lib.progressBar({
            duration = Config.UI.animationDuration,
            label = 'Feeding animal...',
            useWhileDead = false,
            canCancel = false,
            disable = {
                car = true,
            },
        })
    end
end)

-- Play collection animation
RegisterNetEvent('animal_farming:client:playCollectionAnimation', function(animalId)
    local animal = spawnedAnimals[animalId]
    if animal and DoesEntityExist(animal) then
        -- Show progress bar
        lib.progressBar({
            duration = Config.UI.animationDuration,
            label = 'Collecting products...',
            useWhileDead = false,
            canCancel = false,
            disable = {
                car = true,
            },
            anim = {
                dict = 'mini@repair',
                clip = 'fixing_a_player'
            }
        })
        
        -- Play animal animation
        TaskStartScenarioInPlace(animal, 'WORLD_COW_GRAZING', 0, true)
    end
end)

-- Receive production status
RegisterNetEvent('animal_farming:client:receiveProductionStatus', function(animalId, status)
    if status.canProduce then
        lib.notify({
            title = 'Animal Farming',
            description = 'Ready to collect ' .. status.productionAmount .. 'x ' .. status.productionItem,
            type = 'inform'
        })
    else
        lib.notify({
            title = 'Animal Farming',
            description = status.errorMessage,
            type = 'error'
        })
    end
end)

-- Despawn player animals
RegisterNetEvent('animal_farming:client:despawnPlayerAnimals', function(citizenid)
    local playerData = QBCore.Functions.GetPlayerData()
    if playerData.citizenid == citizenid then
        -- Despawn all animals for this player
        for animalId, animal in pairs(spawnedAnimals) do
            if DoesEntityExist(animal) then
                DeleteEntity(animal)
            end
            spawnedAnimals[animalId] = nil
            animalData[animalId] = nil
        end
    end
end)

-- NUI Callbacks
RegisterNUICallback('closeStats', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('feedAnimal', function(data, cb)
    TriggerServerEvent('animal_farming:server:feedAnimal', data.animalId)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('collectProducts', function(data, cb)
    TriggerServerEvent('animal_farming:server:collectProducts', data.animalId)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('butcherAnimal', function(data, cb)
    TriggerServerEvent('animal_farming:server:butcherAnimal', data.animalId)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Start butchering mini-game
RegisterNetEvent('animal_farming:client:startButcheringMinigame', function(animalId, gameConfig)
    local animal = spawnedAnimals[animalId]
    if not animal or not DoesEntityExist(animal) then
        return
    end
    
    -- Start the mini-game
    StartButcheringMinigame(animalId, gameConfig)
end)

-- Butchering mini-game function
function StartButcheringMinigame(animalId, gameConfig)
    local success = false
    local totalSuccessRate = 0
    local completedChecks = 0
    
    -- Show initial notification
    lib.notify({
        title = 'Butchering',
        description = 'Prepare for skill checks! (' .. gameConfig.skillCheckCount .. ' checks)',
        type = 'inform'
    })
    
    -- Start progress bar with skill checks
    local progressSuccess = lib.progressCircle({
        duration = gameConfig.duration,
        label = 'Butchering animal...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            dict = 'amb@world_human_hammering@male@base',
            clip = 'base'
        }
    })
    
    if not progressSuccess then
        TriggerServerEvent('animal_farming:server:butcheringResult', animalId, false, 0)
        return
    end
    
    -- Perform skill checks
    CreateThread(function()
        for i = 1, gameConfig.skillCheckCount do
            Wait(math.random(2000, 4000)) -- Random delay between skill checks
            
            local skillCheck = lib.skillCheck({gameConfig.difficulty, gameConfig.difficulty}, {'e'})
            
            if skillCheck then
                completedChecks = completedChecks + 1
                totalSuccessRate = totalSuccessRate + (100 / gameConfig.skillCheckCount)
                
                lib.notify({
                    title = 'Skill Check',
                    description = 'Success! (' .. completedChecks .. '/' .. gameConfig.skillCheckCount .. ')',
                    type = 'success'
                })
            else
                lib.notify({
                    title = 'Skill Check',
                    description = 'Failed! (' .. completedChecks .. '/' .. gameConfig.skillCheckCount .. ')',
                    type = 'error'
                })
            end
        end
        
        -- Calculate final success
        success = completedChecks >= math.ceil(gameConfig.skillCheckCount / 2) -- Need at least half successful
        
        -- Send result to server
        TriggerServerEvent('animal_farming:server:butcheringResult', animalId, success, totalSuccessRate)
        
        if success then
            lib.notify({
                title = 'Butchering',
                description = 'Butchering completed successfully! (' .. math.floor(totalSuccessRate) .. '% efficiency)',
                type = 'success'
            })
        else
            lib.notify({
                title = 'Butchering',
                description = 'Butchering failed! Poor technique resulted in wasted meat.',
                type = 'error'
            })
        end
    end)
end

-- Remove animal from client
RegisterNetEvent('animal_farming:client:removeAnimal', function(animalId)
    local animal = spawnedAnimals[animalId]
    if animal and DoesEntityExist(animal) then
        DeleteEntity(animal)
    end
    
    spawnedAnimals[animalId] = nil
    animalData[animalId] = nil
    
    if Config.Debug then
        print('^2[Animal Farming]^0 Removed animal: ' .. animalId)
    end
end)

-- Debug command to manually create animal vendor NPC
RegisterCommand('createanimal_vendor', function()
    print('^2[Animal Farming]^0 Manually creating animal vendor NPC...')
    CreateAnimalVendorNPC()
end, false)

-- Debug command to check animal vendor status
RegisterCommand('checkanimal_vendor', function()
    if animalVendorNPC and DoesEntityExist(animalVendorNPC) then
        local coords = GetEntityCoords(animalVendorNPC)
        print('^2[Animal Farming]^0 Animal vendor NPC exists at: ' .. coords.x .. ', ' .. coords.y .. ', ' .. coords.z)
    else
        print('^1[Animal Farming]^0 Animal vendor NPC does not exist')
    end
end, false)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        -- Cleanup spawned animals
        for animalId, animal in pairs(spawnedAnimals) do
            if DoesEntityExist(animal) then
                DeleteEntity(animal)
            end
        end
        
        -- Cleanup vendor NPC
        if animalVendorNPC and DoesEntityExist(animalVendorNPC) then
            DeleteEntity(animalVendorNPC)
        end
        
        -- Close NUI
        SetNuiFocus(false, false)
    end
end)