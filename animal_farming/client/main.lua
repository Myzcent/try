local QBCore = exports['qbx_core']:GetCoreObject()

-- Local variables
local playerFarmlots = {}
local nearbyAnimals = {}
local isNearFarmlot = false
local currentFarmlot = nil

-- Utility functions
local function debugPrint(message)
    if Config.Debug then
        print("[Animal Farming Client] " .. message)
    end
end

local function showNotification(title, description, type)
    if Config.Notifications.type == "ox_lib" then
        lib.notify({
            title = title,
            description = description,
            type = type,
            duration = Config.Notifications.duration
        })
    else
        -- Fallback to QBCore notifications
        QBCore.Functions.Notify(description, type, Config.Notifications.duration)
    end
end

local function createBlip(coords, sprite, color, scale, label)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, scale)
    SetBlipColour(blip, color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(label)
    EndTextCommandSetBlipName(blip)
    return blip
end

-- NPC Management
local function createNPC(npcData)
    local npcHash = GetHashKey(npcData.model)
    RequestModel(npcHash)
    
    while not HasModelLoaded(npcHash) do
        Wait(100)
    end
    
    local npc = CreatePed(4, npcHash, npcData.coords.x, npcData.coords.y, npcData.coords.z, npcData.coords.w, false, true)
    SetEntityHeading(npc, npcData.coords.w)
    FreezeEntityPosition(npc, true)
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    
    if npcData.scenario then
        TaskStartScenarioInPlace(npc, npcData.scenario, 0, true)
    end
    
    return npc
end

local function setupNPCs()
    -- Create farmlot seller NPC
    local farmlotSeller = createNPC(Config.NPCs.farmlotSeller)
    
    exports.ox_target:addLocalEntity(farmlotSeller, {
        {
            name = 'farmlot_seller',
            icon = 'fas fa-home',
            label = 'Purchase Farmlot',
            distance = Config.Distances.farmlotPurchase,
            onSelect = function()
                openFarmlotMenu()
            end
        }
    })
    
    -- Create animal seller NPC
    local animalSeller = createNPC(Config.NPCs.animalSeller)
    
    exports.ox_target:addLocalEntity(animalSeller, {
        {
            name = 'animal_seller',
            icon = 'fas fa-cow',
            label = 'Purchase Animals',
            distance = Config.Distances.animalPurchase,
            onSelect = function()
                openAnimalMenu()
            end
        }
    })
    
    -- Create blips for NPCs if enabled
    if Config.Blips.showNPCBlips then
        createBlip(Config.NPCs.farmlotSeller.coords, 374, 2, 0.8, "Farmlot Seller")
        createBlip(Config.NPCs.animalSeller.coords, 463, 3, 0.8, "Animal Seller")
    end
end

-- Menu functions
function openFarmlotMenu()
    local options = {}
    
    for i = 1, #Config.Farmlots do
        local farmlot = Config.Farmlots[i]
        local isOwned = playerFarmlots[farmlot.id] ~= nil
        
        table.insert(options, {
            title = farmlot.name,
            description = "Price: $" .. farmlot.price .. " | Type: " .. farmlot.animalType .. (isOwned and " (OWNED)" or ""),
            icon = isOwned and 'fas fa-check' or 'fas fa-dollar-sign',
            disabled = isOwned,
            onSelect = function()
                if not isOwned then
                    lib.alertDialog({
                        header = 'Purchase Farmlot',
                        content = 'Do you want to purchase ' .. farmlot.name .. ' for $' .. farmlot.price .. '?',
                        centered = true,
                        cancel = true,
                        labels = {
                            confirm = 'Purchase',
                            cancel = 'Cancel'
                        }
                    }, function(confirmed)
                        if confirmed then
                            TriggerServerEvent('animal_farming:server:purchaseFarmlot', farmlot.id)
                        end
                    end)
                end
            end
        })
    end
    
    lib.registerContext({
        id = 'farmlot_menu',
        title = 'Farmlot Purchase',
        options = options
    })
    
    lib.showContext('farmlot_menu')
end

function openAnimalMenu()
    local options = {}
    
    for animalType, animalData in pairs(Config.Animals) do
        -- Check if player has a farmlot for this animal type
        local hasValidFarmlot = false
        for farmlotId, _ in pairs(playerFarmlots) do
            local farmlot = nil
            for i = 1, #Config.Farmlots do
                if Config.Farmlots[i].id == farmlotId then
                    farmlot = Config.Farmlots[i]
                    break
                end
            end
            if farmlot and farmlot.animalType == animalType then
                hasValidFarmlot = true
                break
            end
        end
        
        table.insert(options, {
            title = animalData.name,
            description = "Price: $" .. animalData.price .. (not hasValidFarmlot and " (No valid farmlot owned)" or ""),
            icon = hasValidFarmlot and 'fas fa-paw' or 'fas fa-times',
            disabled = not hasValidFarmlot,
            onSelect = function()
                if hasValidFarmlot then
                    lib.alertDialog({
                        header = 'Purchase Animal',
                        content = 'Do you want to purchase a ' .. animalData.name .. ' for $' .. animalData.price .. '?\\n\\nNote: Gender will be randomly assigned (20% female, 80% male)',
                        centered = true,
                        cancel = true,
                        labels = {
                            confirm = 'Purchase',
                            cancel = 'Cancel'
                        }
                    }, function(confirmed)
                        if confirmed then
                            TriggerServerEvent('animal_farming:server:purchaseAnimal', animalType)
                        end
                    end)
                end
            end
        })
    end
    
    lib.registerContext({
        id = 'animal_menu',
        title = 'Animal Purchase',
        options = options
    })
    
    lib.showContext('animal_menu')
end

-- Animal interaction functions
local function getAnimalIdFromEntity(entity)
    -- This is a simplified approach - in a real implementation you'd need to track entity-to-animalId mapping
    -- For now, we'll use the entity handle as a temporary ID
    return "temp_" .. entity
end

local function openAnimalStatsMenu(animalId)
    lib.callback('animal_farming:getAnimalStats', false, function(stats)
        if stats then
            local genderText = Config.UI.showGenderInStats and ("Gender: " .. stats.gender:gsub("^%l", string.upper) .. "\\n") or ""
            
            lib.alertDialog({
                header = 'Animal Stats',
                content = genderText ..
                         "Health: " .. stats.health .. "/100\\n" ..
                         "Hunger: " .. stats.hunger .. "/100\\n" ..
                         "Thirst: " .. stats.thirst .. "/100\\n" ..
                         "Type: " .. stats.animalType:gsub("^%l", string.upper),
                centered = true,
                cancel = false,
                labels = {
                    confirm = 'Close'
                }
            })
        else
            showNotification('Error', 'Could not load animal stats', 'error')
        end
    end, animalId)
end

local function setupAnimalInteractions()
    -- This will be called when animals are detected nearby
    CreateThread(function()
        while true do
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            
            -- Find nearby animals
            local animals = GetGamePool('CPed')
            nearbyAnimals = {}
            
            for i = 1, #animals do
                local animal = animals[i]
                if DoesEntityExist(animal) and not IsPedAPlayer(animal) then
                    local animalCoords = GetEntityCoords(animal)
                    local distance = #(playerCoords - animalCoords)
                    
                    if distance <= Config.Distances.animalInteraction then
                        local model = GetEntityModel(animal)
                        local animalType = nil
                        
                        -- Determine animal type by model
                        for type, data in pairs(Config.Animals) do
                            if GetHashKey(data.model) == model then
                                animalType = type
                                break
                            end
                        end
                        
                        if animalType then
                            nearbyAnimals[animal] = {
                                type = animalType,
                                coords = animalCoords,
                                distance = distance
                            }
                        end
                    end
                end
            end
            
            Wait(1000) -- Update every second
        end
    end)
    
    -- Setup ox_target for animals
    exports.ox_target:addGlobalPed({
        {
            name = 'feed_animal',
            icon = 'fas fa-apple-alt',
            label = 'Feed Animal',
            distance = Config.Distances.animalInteraction,
            canInteract = function(entity)
                return nearbyAnimals[entity] ~= nil
            end,
            onSelect = function(data)
                local animalId = getAnimalIdFromEntity(data.entity)
                
                -- Show feeding animation
                local playerPed = PlayerPedId()
                lib.requestAnimDict(Config.Feeding.animationDict)
                TaskPlayAnim(playerPed, Config.Feeding.animationDict, Config.Feeding.animationName, 8.0, -8.0, Config.Feeding.feedingTime, 1, 0, false, false, false)
                
                lib.progressBar({
                    duration = Config.Feeding.feedingTime,
                    label = 'Feeding animal...',
                    useWhileDead = false,
                    canCancel = true,
                    disable = {
                        car = true,
                        move = true,
                        combat = true
                    }
                }, function(cancelled)
                    ClearPedTasks(playerPed)
                    if not cancelled then
                        TriggerServerEvent('animal_farming:server:feedAnimal', animalId)
                    end
                end)
            end
        },
        {
            name = 'collect_product',
            icon = 'fas fa-hand-paper',
            label = 'Collect Product',
            distance = Config.Distances.animalInteraction,
            canInteract = function(entity)
                return nearbyAnimals[entity] ~= nil
            end,
            onSelect = function(data)
                local animalId = getAnimalIdFromEntity(data.entity)
                TriggerServerEvent('animal_farming:server:collectProduct', animalId)
            end
        },
        {
            name = 'check_stats',
            icon = 'fas fa-info-circle',
            label = 'Check Stats',
            distance = Config.Distances.animalInteraction,
            canInteract = function(entity)
                return nearbyAnimals[entity] ~= nil
            end,
            onSelect = function(data)
                local animalId = getAnimalIdFromEntity(data.entity)
                openAnimalStatsMenu(animalId)
            end
        },
        {
            name = 'butcher_animal',
            icon = 'fas fa-cut',
            label = 'Butcher Animal',
            distance = Config.Distances.animalInteraction,
            canInteract = function(entity)
                if not Config.Butchering.enabled then return false end
                if not nearbyAnimals[entity] then return false end
                
                -- Check if animal is dead (simplified check)
                return GetEntityHealth(entity) <= 0
            end,
            onSelect = function(data)
                local animalId = getAnimalIdFromEntity(data.entity)
                startButcheringMinigame(animalId)
            end
        }
    })
end

-- Butchering minigame
function startButcheringMinigame(animalId)
    local playerPed = PlayerPedId()
    
    -- Check if player has knife
    lib.callback('ox_inventory:GetItemCount', false, function(count)
        if count < 1 then
            showNotification('Error', 'You need a knife to butcher animals', 'error')
            return
        end
        
        -- Start minigame
        lib.progressBar({
            duration = Config.Butchering.minigameDuration,
            label = 'Butchering animal...',
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
                move = true,
                combat = true
            }
        }, function(cancelled)
            if not cancelled then
                -- Simple skill check (you can replace with more complex minigame)
                local success = lib.skillCheck({Config.Butchering.skillCheckDifficulty, Config.Butchering.skillCheckDifficulty}, {'e'})
                
                if success then
                    TriggerServerEvent('animal_farming:server:butcherAnimal', animalId)
                else
                    showNotification('Failed', 'You failed to properly butcher the animal', 'error')
                end
            end
        end)
    end, Config.Butchering.requiredItem)
end

-- Blip management
local function createFarmlotBlips()
    if not Config.Blips.showFarmlotBlips then return end
    
    for i = 1, #Config.Farmlots do
        local farmlot = Config.Farmlots[i]
        local isOwned = playerFarmlots[farmlot.id] ~= nil
        
        if Config.Blips.showOwnedFarmlots or not isOwned then
            local color = isOwned and farmlot.blip.color or 1 -- Gray for unowned
            local label = farmlot.name .. (isOwned and " (OWNED)" or "")
            
            createBlip(farmlot.coords, farmlot.blip.sprite, color, farmlot.blip.scale, label)
        end
    end
end

-- Floating stats display (optional)
local function showFloatingStats()
    if not Config.UI.showFloatingStats then return end
    
    CreateThread(function()
        while true do
            for entity, animalData in pairs(nearbyAnimals) do
                if DoesEntityExist(entity) and animalData.distance <= 5.0 then
                    local animalId = getAnimalIdFromEntity(entity)
                    
                    lib.callback('animal_farming:getAnimalStats', false, function(stats)
                        if stats then
                            local coords = GetEntityCoords(entity)
                            coords = coords + vector3(0.0, 0.0, 1.0) -- Slightly above the animal
                            
                            -- Draw 3D text (simplified - you might want to use a more sophisticated UI)
                            local onScreen, screenX, screenY = World3dToScreen2d(coords.x, coords.y, coords.z)
                            if onScreen then
                                SetTextScale(0.35, 0.35)
                                SetTextFont(4)
                                SetTextProportional(1)
                                SetTextColour(255, 255, 255, 215)
                                SetTextEntry("STRING")
                                SetTextCentre(true)
                                AddTextComponentString(
                                    "Health: " .. stats.health .. 
                                    "\\nHunger: " .. stats.hunger .. 
                                    "\\nThirst: " .. stats.thirst ..
                                    (Config.UI.showGenderInStats and ("\\n" .. stats.gender:gsub("^%l", string.upper)) or "")
                                )
                                DrawText(screenX, screenY)
                            end
                        end
                    end, animalId)
                end
            end
            
            Wait(Config.UI.statUpdateInterval)
        end
    end)
end

-- Event handlers
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    -- Load player farmlots
    lib.callback('animal_farming:getPlayerFarmlots', false, function(farmlots)
        playerFarmlots = farmlots
        createFarmlotBlips()
    end)
end)

-- Initialize
CreateThread(function()
    -- Setup NPCs
    setupNPCs()
    
    -- Setup animal interactions
    setupAnimalInteractions()
    
    -- Show floating stats if enabled
    showFloatingStats()
    
    debugPrint("Animal Farming Client initialized")
end)