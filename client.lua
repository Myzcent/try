-- Animal Farm Client Script with Fixed NUI Handling
-- Variables
local animalPeds = {}
local activeBlips = {}
local vendorPed = nil
local farmLotPeds = {}
local animalZones = {}
local farmlotZones = {}
local playerAnimals = {}
local VendorMenuOpen = false
local GlobalAnimalStock = {}
local loadedModels = {}
local loadedAnims = {}

-- 🔹 Enhanced NUI cleanup on resource start
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        -- Force close any existing NUI immediately
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        
        -- Send close message multiple times to ensure it's received
        CreateThread(function()
            for i = 1, 5 do
                SendNUIMessage({ action = "closeAnimalMenu" })
                Wait(50)
            end
        end)
        
        -- Reset all NUI-related variables
        VendorMenuOpen = false
        
        print("[AnimalFarm] NUI forcefully closed on resource start")
    end
end)

-- 🔹 Enhanced NUI callback para sa Close button
RegisterNUICallback('closeMenu', function(data, cb)
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ action = 'closeAnimalMenu' })
    
    -- Ensure callback is called
    if cb then
        cb('ok')
    end
    
    print("[AnimalFarm] NUI closed via closeMenu callback")
end)

-- 🔹 Enhanced fallback callback para sa lahat ng NUI actions
RegisterNUICallback('fallback', function(data, cb)
    -- Force close NUI kung may problema
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    
    if cb then
        cb('ok')
    end
    
    print("[AnimalFarm] NUI fallback callback triggered")
end)

-- 🔹 Add escape key handler to force close NUI
CreateThread(function()
    while true do
        Wait(0)
        if IsControlJustPressed(0, 322) then -- ESC key
            local hasFocus, hasKeepInput = GetNuiFocus()
            if hasFocus then
                SetNuiFocus(false, false)
                SetNuiFocusKeepInput(false)
                SendNUIMessage({ action = 'closeAnimalMenu' })
                print("[AnimalFarm] NUI closed via ESC key")
            end
        end
    end
end)

-- Enhanced emergency fallback command
RegisterCommand('resetnuifocus', function()
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    
    -- Send multiple close messages
    for i = 1, 3 do
        SendNUIMessage({ action = "closeAnimalMenu" })
    end
    
    VendorMenuOpen = false
    print("NUI focus reset manually - all attempts made")
end, false)

-- Helper function to safely set NUI focus
local function SafeSetNuiFocus(focus, keepInput)
    SetNuiFocus(focus, keepInput or false)
    if keepInput ~= nil then
        SetNuiFocusKeepInput(keepInput)
    end
    
    -- Log for debugging
    if focus then
        print("[AnimalFarm] NUI focus enabled")
    else
        print("[AnimalFarm] NUI focus disabled")
    end
end

local function ApplyAnimalExtras(animalId, ped, animalType, animalCfg)
    if not animalId or not ped or not animalCfg then return false end

    -- Remove old target
    exports.ox_target:removeLocalEntity(ped)

    -- Remove old blip
    local blipKey = "animal_" .. animalId
    if activeBlips[blipKey] and DoesBlipExist(activeBlips[blipKey]) then
        RemoveBlip(activeBlips[blipKey])
        activeBlips[blipKey] = nil
    end

    -- Targets array
    local targetOptions = {}

    -- Check Status (only opens onSelect)
    table.insert(targetOptions, {
        name = 'animal_status_' .. animalId,
        icon = 'fa-solid fa-paw',
        label = 'Check Status',
        distance = 2.0,
        onSelect = function()
            -- 🔹 Enhanced NUI opening with safety checks
            SafeSetNuiFocus(true, true)
            
            SendNUIMessage({
                action = 'openAnimalMenu',
                animalId = animalId,
                animalType = animalType,
                animalLabel = animalCfg.label or animalType,
                isFemale = animalCfg.isFemale or false,
                productReady = animalCfg.productReady or false,
                hunger = animalCfg.hunger or 0,
                water = animalCfg.water or 0,
                age = animalCfg.age or "Unknown",
                gender = animalCfg.gender or "Unknown",
                despawnTime = animalCfg.despawnTime or 60
            })
            
            print("[AnimalFarm] Animal menu opened for ID: " .. animalId)
        end
    })

    -- Feed
    table.insert(targetOptions, {
        name = 'feed_' .. animalId,
        icon = 'fa-solid fa-carrot',
        label = 'Feed ' .. (animalCfg.label or animalType),
        distance = 2.0,
        onSelect = function()
            TriggerServerEvent('animalfarm:feedAnimal', animalId)
        end
    })

    -- Milk collection for females
    if animalCfg.isFemale then
        table.insert(targetOptions, {
            name = 'harvest_' .. animalId,
            icon = 'fa-solid fa-cow',
            label = 'Collect Milk',
            distance = 2.0,
            onSelect = function()
                TriggerServerEvent('animalfarm:collectMilk', animalId)
            end
        })
    end

    -- Add targets
    exports.ox_target:addLocalEntity(ped, targetOptions)

    -- Blip setup
    if animalCfg.blip then
        local blip = AddBlipForEntity(ped)
        SetBlipSprite(blip, animalCfg.blip.sprite or 141)
        SetBlipScale(blip, animalCfg.blip.scale or 0.7)
        SetBlipColour(blip, animalCfg.blip.color or 2)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(animalCfg.blip.name or animalCfg.label or animalType)
        EndTextCommandSetBlipName(blip)
        activeBlips[blipKey] = blip
    end

    -- Unload model
    if animalCfg.model then
        SetModelAsNoLongerNeeded(animalCfg.model)
    end

    return true
end

-- Main spawn function with better validation
local function SpawnAnimal(animalId, animalType, spawnLocation, citizenid)
    local animalCfg = Config.AnimalModels[animalType]
    if not animalCfg or not animalCfg.model then
        print(("[AnimalFarm] ERROR: Invalid animal type '%s'"):format(tostring(animalType)))
        return false
    end

    -- cleanup old animal if exists
    if animalPeds[animalId] and animalPeds[animalId].ped and DoesEntityExist(animalPeds[animalId].ped) then
        exports.ox_target:removeLocalEntity(animalPeds[animalId].ped)
        if activeBlips["animal_"..animalId] then
            RemoveBlip(activeBlips["animal_"..animalId])
            activeBlips["animal_"..animalId] = nil
        end
        DeleteEntity(animalPeds[animalId].ped)
        animalPeds[animalId] = nil
    end

    -- get spawn coords
    local coords = vec4from(spawnLocation or animalCfg.spawnLocation or {})
    if coords.x == 0.0 and coords.y == 0.0 and coords.z == 0.0 then
        print(("[AnimalFarm] ERROR: No spawn location for '%s'"):format(animalType))
        return false
    end

    -- load model
    local modelHash = LoadModel(animalCfg.model)
    if not modelHash then
        return false
    end

    -- create ped
    local ped = CreatePed(28, modelHash, coords.x, coords.y, coords.z, coords.w or 0.0, true, true)
    if not DoesEntityExist(ped) then
        print(("[AnimalFarm] ERROR: Failed to spawn animal '%s'"):format(animalType))
        UnloadModel(modelHash)
        return false
    end

    SetEntityAsMissionEntity(ped, true, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    -- store animal
    animalPeds[animalId] = {
        ped = ped,
        type = animalType,
        citizenid = citizenid,
        homePosition = vector3(coords.x, coords.y, coords.z), -- fixed spawn point
        lastPosition = vector3(coords.x, coords.y, coords.z) -- for distance checks
    }

    -- simple wander
    TaskWanderStandard(ped, 10.0, 10)

    -- add interaction + blip
    ApplyAnimalExtras(animalId, ped, animalType, animalCfg)

    -- unload model
    SetModelAsNoLongerNeeded(modelHash)
    return true
end

-- Animal position tracking loop
CreateThread(function()
    while true do
        for animalId, data in pairs(animalPeds) do
            if DoesEntityExist(data.ped) then
                local currentPos = GetEntityCoords(data.ped)
                local distance = #(currentPos - data.homePosition)

                -- keep within 100m of home
                if distance > 100.0 then
                    SetEntityCoords(data.ped, data.homePosition.x, data.homePosition.y, data.homePosition.z, false, false, false, false)
                else
                    data.lastPosition = currentPos
                end
            end
        end
        Wait(30000) -- every 30s
    end
end)

-- ----------------------------------------------------------------------------
-- Vendor with better error handling - FIXED VECTOR MUTATION
-- ----------------------------------------------------------------------------
local function SpawnVendor()
    if vendorPed and DoesEntityExist(vendorPed) then
        exports.ox_target:removeLocalEntity(vendorPed)
        DeleteEntity(vendorPed)
        vendorPed = nil
    end

    if not Config or not Config.Vendor then
        print("[AnimalFarm] ERROR: Config.Vendor missing.")
        return false
    end

    local modelHash = LoadModel(Config.Vendor.npcModel or "a_m_m_farmer_01")
    if not modelHash then
        print("[AnimalFarm] ERROR: Failed to load vendor ped model.")
        return false
    end

    local coords = vec4from(Config.Vendor.spawnLocation or {})
    if coords.x == 0.0 and coords.y == 0.0 and coords.z == 0.0 then
        print("[AnimalFarm] ERROR: Vendor spawnLocation invalid or missing.")
        UnloadModel(modelHash)
        return false
    end

    -- Get accurate ground Z - FIXED VECTOR MUTATION
    local success, groundZ = false, coords.z
    for i = 1, 3 do
        success, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 50.0, 0)
        if success then
            -- Create a new vector instead of modifying the existing one
            local spawnCoords = vector3(coords.x, coords.y, groundZ)
            coords = vector4(spawnCoords.x, spawnCoords.y, spawnCoords.z, coords.w)
            break
        end
        Wait(100)
    end

    -- Create vendor NPC
    local ped = CreatePed(0, modelHash, coords.x, coords.y, coords.z, coords.w, false, true)
    if not DoesEntityExist(ped) then
        print("[AnimalFarm] ERROR: Failed to create vendor ped.")
        UnloadModel(modelHash)
        return false
    end

    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityAsMissionEntity(ped, true, true)

    -- Add idle animation
    if LoadAnimDict("amb@world_human_stand_impatient@male@base") then
        TaskPlayAnim(ped, "amb@world_human_stand_impatient@male@base", "base", 8.0, -8.0, -1, 1, 0, false, false, false)
    end

    -- ox_target interaction
    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'animal_vendor',
            icon = 'fas fa-paw',
            label = 'Buy Animals',
            onSelect = function()
                TriggerServerEvent('animalfarm:requestStock')
            end
        }
    })

    -- Setup blip
    if activeBlips["animal_vendor"] and DoesBlipExist(activeBlips["animal_vendor"]) then
        RemoveBlip(activeBlips["animal_vendor"])
    end

    local blip = AddBlipForEntity(ped)
    SetBlipSprite(blip, 280)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.85)
    SetBlipColour(blip, 2)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Animal Vendor")
    EndTextCommandSetBlipName(blip)
    activeBlips["animal_vendor"] = blip

    vendorPed = ped
    UnloadModel(modelHash)
    print("[AnimalFarm] Vendor NPC spawned successfully.")
    return true
end

-- ----------------------------------------------------------------------------
-- Vendor Menu (ox_lib) with better UI
-- ----------------------------------------------------------------------------
local function GetCurrentStock(animalType)
    return GlobalAnimalStock[animalType] or 0
end

function OpenVendorMenu()
    local stockLimits = (Config.Vendor and Config.Vendor.stockLimits) or {}
    local prices = (Config.Vendor and Config.Vendor.animalPrices) or {}
    local options = {}

    for animalType, maxStock in pairs(stockLimits) do
        local price = prices[animalType] or 0
        local currentStock = GetCurrentStock(animalType)
        local animalCfg = (Config.AnimalModels and Config.AnimalModels[animalType]) or {}
        local disabled = currentStock <= 0

        options[#options + 1] = {
            title = ("%s - $%d | Stock: %d/%d"):format(
                animalCfg.label or animalType:gsub("^%l", string.upper),
                price,
                currentStock,
                maxStock
            ),
            description = animalCfg.description or "Purchase this animal for your farm",
            icon = animalCfg.icon or "paw",
            disabled = disabled,
            onSelect = function()
                if not disabled then
                    TriggerServerEvent("animalfarm:buyAnimal", animalType)
                    lib.hideContext()
                    VendorMenuOpen = false
                end
            end
        }
    end

    -- Add close button
    options[#options + 1] = {
        title = "Close",
        icon = "x",
        onSelect = function()
            lib.hideContext()
            VendorMenuOpen = false
        end
    }

    lib.registerContext({
        id = "vendor_menu",
        title = "🐄 Animal Vendor",
        options = options
    })

    lib.showContext("vendor_menu")
    VendorMenuOpen = true
end

-- ----------------------------------------------------------------------------
-- Events with better error handling
-- ----------------------------------------------------------------------------
RegisterNetEvent('animalfarm:updateStock', function(animalType, newStock)
    if not animalType then return end
    GlobalAnimalStock[animalType] = newStock
    if VendorMenuOpen then
        lib.hideContext('vendor_menu')
        OpenVendorMenu()
    end
end)

RegisterNetEvent('animalfarm:sendStock', function(stockData)
    if not stockData then return end
    GlobalAnimalStock = stockData or {}
    OpenVendorMenu()
end)

RegisterNetEvent('animalfarm:clientSpawnAnimal', function(animalId, animalType, coords, citizenid)
    if not animalId or not animalType then
        print("[AnimalFarm] ERROR: Tried to spawn animal without valid ID or type!")
        return
    end
    SpawnAnimal(animalId, animalType, coords, citizenid)
end)

RegisterNetEvent('animalfarm:removeAnimal', function(animalId)
    if not animalId then return end
    
    if animalPeds[animalId] and DoesEntityExist(animalPeds[animalId].ped) then
        exports.ox_target:removeLocalEntity(animalPeds[animalId].ped)
        if activeBlips["animal_"..animalId] then
            RemoveBlip(activeBlips["animal_"..animalId])
            activeBlips["animal_"..animalId] = nil
        end
        DeleteEntity(animalPeds[animalId].ped)
        animalPeds[animalId] = nil
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    -- Spawn vendor with retry logic
    local vendorSpawned = false
    local attempts = 0
    while not vendorSpawned and attempts < 3 do
        vendorSpawned = SpawnVendor()
        attempts = attempts + 1
        if not vendorSpawned then
            Wait(1000)
        end
    end

    -- Spawn farmlot NPCs
    for animalType, config in pairs((Config.Farmlots and Config.Farmlots.types) or {}) do
        SpawnFarmlotNPC(animalType, config)
    end

    -- Start asset cleanup thread
    CreateThread(function()
        while true do
            CleanupUnusedAssets()
            Wait(60000) -- Cleanup every minute
        end
    end)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    -- 🔹 Enhanced cleanup with NUI safety
    SafeSetNuiFocus(false, false)
    SendNUIMessage({ action = "closeAnimalMenu" })
    
    -- Cleanup all entities
    if vendorPed and DoesEntityExist(vendorPed) then
        exports.ox_target:removeLocalEntity(vendorPed)
        DeleteEntity(vendorPed)
        vendorPed = nil
    end

    for id, data in pairs(animalPeds) do
        if DoesEntityExist(data.ped) then
            exports.ox_target:removeLocalEntity(data.ped)
            DeleteEntity(data.ped)
        end
    end

    for k, ped in pairs(farmLotPeds) do
        if DoesEntityExist(ped) then
            exports.ox_target:removeLocalEntity(ped)
            DeleteEntity(ped)
        end
    end

    for k, blip in pairs(activeBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end

    for _, zoneId in pairs(animalZones) do
        exports.ox_target:removeZone(zoneId)
    end

    for _, zoneId in pairs(farmlotZones) do
        exports.ox_target:removeZone(zoneId)
    end

    animalPeds = {}
    animalZones = {}
    farmLotPeds = {}
    farmlotZones = {}
    activeBlips = {}
    playerAnimals = {}
    VendorMenuOpen = false
end)

-- 🔹 Enhanced resource stop handler with multiple safety measures
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end

    -- 🔴 CRITICAL: Multiple attempts to close NUI
    print("[AnimalFarm] Resource stopping - forcing NUI cleanup...")
    
    CreateThread(function()
        for i = 1, 10 do
            SetNuiFocus(false, false)
            SetNuiFocusKeepInput(false)
            SendNUIMessage({ action = "closeAnimalMenu" })
            Wait(50)
        end
    end)

    -- Wait a bit for NUI cleanup
    Wait(200)

    -- Vendor ped cleanup
    if vendorPed and DoesEntityExist(vendorPed) then
        if exports.ox_target then
            exports.ox_target:removeLocalEntity(vendorPed)
        end
        DeleteEntity(vendorPed)
        vendorPed = nil
    end

    -- Animal ped cleanup
    for id, data in pairs(animalPeds) do
        if data.ped and DoesEntityExist(data.ped) then
            if exports.ox_target then
                exports.ox_target:removeLocalEntity(data.ped)
            end
            DeleteEntity(data.ped)
        end
    end
    animalPeds = {}

    -- Farm lot ped cleanup
    for _, ped in pairs(farmLotPeds) do
        if DoesEntityExist(ped) then
            if exports.ox_target then
                exports.ox_target:removeLocalEntity(ped)
            end
            DeleteEntity(ped)
        end
    end
    farmLotPeds = {}

    -- Blip cleanup
    for _, blip in pairs(activeBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    activeBlips = {}

    -- Zones cleanup
    for _, zoneId in pairs(animalZones) do
        if exports.ox_target then
            exports.ox_target:removeZone(zoneId)
        end
    end
    for _, zoneId in pairs(farmlotZones) do
        if exports.ox_target then
            exports.ox_target:removeZone(zoneId)
        end
    end
    animalZones, farmlotZones = {}, {}

    -- Unload models and anims
    for modelHash, _ in pairs(loadedModels) do
        SetModelAsNoLongerNeeded(modelHash)
    end
    loadedModels = {}

    for dict, _ in pairs(loadedAnims) do
        RemoveAnimDict(dict)
    end
    loadedAnims = {}

    print("[AnimalFarm] Resource stopped - all entities and NUI cleaned up")
end)

-- ----------------------------------------------------------------------------
-- Threads with better performance
-- ----------------------------------------------------------------------------
CreateThread(function()
    -- If character is already in-session when resource starts
    if LocalPlayer and LocalPlayer.state and LocalPlayer.state.isLoggedIn then
        Wait(1000) -- Wait for everything to initialize
        
        local vendorSpawned = false
        local attempts = 0
        while not vendorSpawned and attempts < 3 do
            vendorSpawned = SpawnVendor()
            attempts = attempts + 1
            if not vendorSpawned then
                Wait(1000)
            end
        end

        for animalType, config in pairs((Config.Farmlots and Config.Farmlots.types) or {}) do
            SpawnFarmlotNPC(animalType, config)
        end
    end
end)

-- Draw farm area markers with distance-based optimization
CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local sleep = 1000

        for animalType, config in pairs((Config.Farmlots and Config.Farmlots.types) or {}) do
            local area = config.farmArea
            if area and area.coords then
                local c4 = vec4from(area.coords)
                local dist = #(playerCoords - vector3(c4.x, c4.y, c4.z))

                if dist < 150.0 then
                    sleep = 0
                    local size = area.size or vector3(6.0, 6.0, 2.0)
                    DrawMarker(
                        1, c4.x, c4.y, c4.z - 1.0,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        size.x or 6.0, size.y or 6.0,
                        100, 50, 200, 120, 120,
                        false, true, 2, false, nil, nil, false
                    )
                end
            end
        end
        Wait(sleep)
    end
end)

-- 🔹 Additional safety: Monitor NUI focus state
CreateThread(function()
    while true do
        Wait(5000) -- Check every 5 seconds
        
        local hasFocus, hasKeepInput = GetNuiFocus()
        
        -- If NUI has focus but no menu is supposed to be open, force close it
        if hasFocus and not VendorMenuOpen then
            print("[AnimalFarm] WARNING: NUI focus detected without active menu - forcing close")
            SafeSetNuiFocus(false, false)
            SendNUIMessage({ action = "closeAnimalMenu" })
        end
    end
end)