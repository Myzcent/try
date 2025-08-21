-- ============================================================================
-- Animal Farm Client (QBCore + ox_target + ox_lib) - Fixed NUI Version
-- ============================================================================

local QBCore = exports['qb-core']:GetCoreObject()

-- ----------------------------------------------------------------------------
-- State Management
-- ----------------------------------------------------------------------------
local animalPeds = {}        -- [animalId] = {ped = entity, type = animalType}
local animalZones = {}       -- [animalId] = ox_target zone id
local vendorPed = nil
local farmLotPeds = {}       -- [animalType] = ped
local farmlotZones = {}      -- [animalType] = ox_target zone id
local playerAnimals = {}     -- [citizenid] = { [animalId]=true }
local loadedModels = {}
local loadedAnims = {}
local activeBlips = {}
local VendorMenuOpen = false
local GlobalAnimalStock = {}
local ox_lib = exports.ox_lib

-- Cache frequently used functions
local GetGameTimer = GetGameTimer
local Wait = Wait
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local GetEntityCoords = GetEntityCoords
local PlayerPedId = PlayerPedId
local vector3 = vector3
local vector4 = vector4
local pairs = pairs
local type = type

-- Quick helpers with validation
local function vec3from(v)
    if type(v) == 'vector3' then 
        return v 
    end
    
    if type(v) == 'table' then 
        return vector3(
            tonumber(v.x or v[1] or 0.0) or 0.0, 
            tonumber(v.y or v[2] or 0.0) or 0.0, 
            tonumber(v.z or v[3] or 0.0) or 0.0
        ) 
    end
    
    return vector3(0.0, 0.0, 0.0)
end

local function vec4from(v)
    if type(v) == 'vector4' then 
        return v 
    end
    
    if type(v) == 'table' then 
        return vector4(
            tonumber(v.x or v[1] or 0.0) or 0.0, 
            tonumber(v.y or v[2] or 0.0) or 0.0, 
            tonumber(v.z or v[3] or 0.0) or 0.0,
            tonumber(v.w or v[4] or 0.0) or 0.0
        ) 
    end
    
    return vector4(0.0, 0.0, 0.0, 0.0)
end

-- ----------------------------------------------------------------------------
-- 🔹 ENHANCED NUI MANAGEMENT - FIX FOR RESTART ISSUE
-- ----------------------------------------------------------------------------

-- Helper function to safely set NUI focus with logging
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

-- 🔹 Enhanced resource start handler - MAIN FIX
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print("[AnimalFarm] Resource starting - forcing NUI cleanup...")
        
        -- Force close any existing NUI immediately
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        
        -- Send close message multiple times to ensure it's received
        CreateThread(function()
            for i = 1, 10 do
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

-- 🔹 ESC key handler to force close NUI (Fixed - no GetNuiFocus)
CreateThread(function()
    while true do
        Wait(0)
        if IsControlJustPressed(0, 322) then -- ESC key
            -- Force close NUI without checking focus state
            SetNuiFocus(false, false)
            SetNuiFocusKeepInput(false)
            SendNUIMessage({ action = 'closeAnimalMenu' })
            VendorMenuOpen = false
            print("[AnimalFarm] NUI closed via ESC key")
        end
    end
end)

-- Enhanced emergency fallback command
RegisterCommand('resetnuifocus', function()
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    
    -- Send multiple close messages
    for i = 1, 5 do
        SendNUIMessage({ action = "closeAnimalMenu" })
    end
    
    VendorMenuOpen = false
    print("NUI focus reset manually - all attempts made")
end, false)

-- 🔹 NUI state monitoring system (Fixed - removed GetNuiFocus)
CreateThread(function()
    while true do
        Wait(10000) -- Check every 10 seconds
        
        -- Periodic NUI cleanup to prevent stuck states
        -- This runs less frequently to avoid performance issues
        if not VendorMenuOpen then
            -- Force close NUI if no menus should be open
            SetNuiFocus(false, false)
            SetNuiFocusKeepInput(false)
            SendNUIMessage({ action = "closeAnimalMenu" })
        end
    end
end)

-- ----------------------------------------------------------------------------
-- Model / Anim loading with better memory management
-- ----------------------------------------------------------------------------
local function LoadModel(model)
    if not model then return nil end
    
    local modelHash = type(model) == "string" and GetHashKey(model) or model
    if loadedModels[modelHash] then 
        return modelHash 
    end

    if not IsModelInCdimage(modelHash) or not IsModelValid(modelHash) then
        print(("[AnimalFarm] ❌ Invalid model: %s (%s)"):format(tostring(model), tostring(modelHash)))
        return nil
    end

    RequestModel(modelHash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(modelHash) do
        if GetGameTimer() > timeout then
            print(("[AnimalFarm] ⏳ Timeout loading model: %s"):format(tostring(model)))
            return nil
        end
        Wait(10)
    end

    loadedModels[modelHash] = GetGameTimer()
    return modelHash
end

local function UnloadModel(model)
    local modelHash = type(model) == "string" and GetHashKey(model) or model
    if loadedModels[modelHash] then
        SetModelAsNoLongerNeeded(modelHash)
        loadedModels[modelHash] = nil
    end
end

local function LoadAnimDict(dict)
    if not dict or type(dict) ~= "string" then return false end
    
    if loadedAnims[dict] then 
        return true 
    end
    
    RequestAnimDict(dict)
    local deadline = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) do
        if GetGameTimer() > deadline then
            print(("[AnimalFarm] ERROR: Failed to load anim dict: %s"):format(dict))
            return false
        end
        Wait(10)
    end
    loadedAnims[dict] = GetGameTimer()
    return true
end

-- Function to unload all unused assets
local function CleanupUnusedAssets()
    local currentTime = GetGameTimer()
    
    -- Unload models not used in the last 60 seconds
    for modelHash, lastUsed in pairs(loadedModels) do
        if currentTime - lastUsed > 60000 then
            SetModelAsNoLongerNeeded(modelHash)
            loadedModels[modelHash] = nil
        end
    end
    
    -- Unload anim dicts not used in the last 60 seconds
    for dict, lastUsed in pairs(loadedAnims) do
        if currentTime - lastUsed > 60000 then
            RemoveAnimDict(dict)
            loadedAnims[dict] = nil
        end
    end
end

-- ----------------------------------------------------------------------------
-- Props with better error handling
-- ----------------------------------------------------------------------------
local function AttachPropToPed(ped, propModel, boneId, pos, rot)
    if not DoesEntityExist(ped) then return nil end
    
    local modelHash = LoadModel(propModel)
    if not modelHash then return nil end

    local pCoords = GetEntityCoords(ped)
    local obj = CreateObject(modelHash, pCoords.x, pCoords.y, pCoords.z, true, true, true)
    if not DoesEntityExist(obj) then
        print("[AnimalFarm] ERROR: Failed to create prop object")
        return nil
    end

    local P = pos or vector3(0.0, 0.0, 0.0)
    local R = rot or vector3(0.0, 0.0, 0.0)
    
    local boneIndex
    if boneId then
        boneIndex = GetPedBoneIndex(ped, boneId)
    else
        boneIndex = GetPedBoneIndex(ped, 57005) -- Default to PH_R_Hand
    end
    
    AttachEntityToEntity(
        obj, ped, boneIndex,
        P.x, P.y, P.z,
        R.x, R.y, R.z,
        true, true, false, true, 1, true
    )
    return obj
end

-- ----------------------------------------------------------------------------
-- Farmlot NPCs with better cleanup and validation
-- ----------------------------------------------------------------------------
local function SpawnFarmlotNPC(animalType, configData)
    if not configData or not configData.seller or not configData.farmArea then
        print(("[AnimalFarm] ERROR: Missing config for %s Farmlot"):format(animalType))
        return false
    end

    -- Cleanup existing NPC
    if farmLotPeds[animalType] and DoesEntityExist(farmLotPeds[animalType]) then
        exports.ox_target:removeLocalEntity(farmLotPeds[animalType])
        DeleteEntity(farmLotPeds[animalType])
        farmLotPeds[animalType] = nil
    end

    -- Load ped model
    local pedModel = configData.seller.model or "a_m_m_farmer_01"
    local modelHash = LoadModel(pedModel)
    if not modelHash then
        print(("[AnimalFarm] ERROR: Could not load model for %s Farmlot"):format(animalType))
        return false
    end

    local v4 = configData.seller.coords
    if not v4 then
        print(("[AnimalFarm] ERROR: No coordinates for %s Farmlot seller"):format(animalType))
        UnloadModel(modelHash)
        return false
    end
    
    local pedX, pedY, pedZ, pedW = v4.x, v4.y, v4.z, v4.w
    
    -- Get accurate ground Z
    local success, groundZ = false, pedZ
    for i = 1, 3 do -- Try multiple times
        success, groundZ = GetGroundZFor_3dCoord(pedX, pedY, pedZ + 50.0, 0)
        if success then 
            pedZ = groundZ 
            break 
        end
        Wait(100)
    end

    -- Create NPC seller
    local ped = CreatePed(0, modelHash, pedX, pedY, pedZ, pedW, false, true)
    if not DoesEntityExist(ped) then
        print(("[AnimalFarm] ERROR: Failed to create %s Farmlot NPC"):format(animalType))
        UnloadModel(modelHash)
        return false
    end

    farmLotPeds[animalType] = ped
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, false) -- allow wandering
    SetBlockingOfNonTemporaryEvents(ped, false)
    SetEntityAsMissionEntity(ped, true, true)
    SetPedFleeAttributes(ped, 0, false) -- Don't flee
    SetPedConfigFlag(ped, 208, true) -- Ped can aggro

    print(("[AnimalFarm] %s Farmlot NPC created at %.2f %.2f %.2f"):format(animalType, pedX, pedY, pedZ))

    -- Setup Blip
    if activeBlips[animalType .. "_farmer"] and DoesBlipExist(activeBlips[animalType .. "_farmer"]) then
        RemoveBlip(activeBlips[animalType .. "_farmer"])
    end
    
    local blip = AddBlipForEntity(ped)
    if animalType == "cow" then
        SetBlipSprite(blip, 141)
        SetBlipColour(blip, 5)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Cow Farmer")
        EndTextCommandSetBlipName(blip)
    elseif animalType == "pig" then
        SetBlipSprite(blip, 515)
        SetBlipColour(blip, 8)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Pig Farmer")
        EndTextCommandSetBlipName(blip)
    end
    
    SetBlipScale(blip, 0.8)
    SetBlipDisplay(blip, 4)
    SetBlipAsShortRange(blip, true)
    activeBlips[animalType .. "_farmer"] = blip

    -- Add animations based on animal type
    if animalType == "cow" and LoadAnimDict("amb@world_human_stand_impatient@male@no_sign@base") then
        TaskPlayAnim(ped, "amb@world_human_stand_impatient@male@no_sign@base", "base", 8.0, -8.0, -1, 1, 0, false, false, false)
    end

    -- Wandering behavior for all farmers
    CreateThread(function()
        local farmCenter = configData.farmArea.coords
        local farmSize = configData.farmArea.size
        local roamRadius = math.min(farmSize.x, farmSize.y) / 2
        local stopDistance = 5.0 -- distance to player at which NPC stops

        while DoesEntityExist(ped) do
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local pedCoords = GetEntityCoords(ped)
            local dist = #(playerCoords - pedCoords)

            if dist > stopDistance then
                -- Only move if player is far enough
                local randX = farmCenter.x + (math.random() - 0.5) * 2 * roamRadius
                local randY = farmCenter.y + (math.random() - 0.5) * 2 * roamRadius
                local success, randZ = GetGroundZFor_3dCoord(randX, randY, farmCenter.z + 50.0, 0)
                if not success then randZ = farmCenter.z end

                TaskGoToCoordAnyMeans(ped, randX, randY, randZ, 1.0, 0, 0, 786603, 0xbf800000)
            else
                -- Player is close: stop movement
                ClearPedTasksImmediately(ped)
                
                -- Play idle animation if close to player
                if animalType == "cow" and not IsEntityPlayingAnim(ped, "amb@world_human_stand_impatient@male@no_sign@base", "base", 3) then
                    LoadAnimDict("amb@world_human_stand_impatient@male@no_sign@base")
                    TaskPlayAnim(ped, "amb@world_human_stand_impatient@male@no_sign@base", "base", 8.0, -8.0, -1, 1, 0, false, false, false)
                end
            end

            Wait(3000 + math.random(0, 2000)) -- wait before next move/check
        end
    end)

    -- Spawn roaming animals for the farm
    if configData.spawnAnimals then
        CreateThread(function()
            local farmCenter = configData.farmArea.coords
            local farmSize = configData.farmArea.size
            local roamRadius = math.min(farmSize.x, farmSize.y) / 2

            local animalModel = animalType == "cow" and `a_c_cow` or `a_c_pig`
            local animalHash = LoadModel(animalModel)
            if not animalHash then
                print(("[AnimalFarm] ERROR: Failed to load %s model."):format(animalType))
                return
            end

            local animal = CreatePed(28, animalHash, farmCenter.x, farmCenter.y, farmCenter.z, 0.0, true, true)
            if not DoesEntityExist(animal) then
                print(("[AnimalFarm] ERROR: Failed to create %s entity."):format(animalType))
                return
            end

            SetEntityAsMissionEntity(animal, true, true)
            SetBlockingOfNonTemporaryEvents(animal, true)
            SetEntityInvincible(animal, true)
            FreezeEntityPosition(animal, false)

            while DoesEntityExist(animal) do
                local randX = farmCenter.x + (math.random() - 0.5) * 2 * roamRadius
                local randY = farmCenter.y + (math.random() - 0.5) * 2 * roamRadius
                local success, randZ = GetGroundZFor_3dCoord(randX, randY, farmCenter.z + 50.0, 0)
                if not success then randZ = farmCenter.z end

                TaskGoToCoordAnyMeans(animal, randX, randY, randZ, 1.0, 0, 0, 786603, 0xbf800000)
                Wait(4000 + math.random(0, 3000))
            end
        end)
    end

    -- ox_target interaction
    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'farmlot_seller_' .. animalType,
            icon = 'fas fa-seedling',
            label = ('Buy %s Farmlot - $%d'):format(animalType:gsub("^%l", string.upper), configData.price or 0),
            onSelect = function()
                TriggerServerEvent('animalfarm:buyFarmlot', animalType)
            end
        }
    })

    return true
end

-- ----------------------------------------------------------------------------
-- Animals with improved management
-- ----------------------------------------------------------------------------
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

    -- Check Status (only opens onSelect) - FIXED NUI OPENING
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
    if not modelHash then return false end

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
        homePosition = vector3(coords.x, coords.y, coords.z),  -- fixed spawn point
        lastPosition = vector3(coords.x, coords.y, coords.z)   -- for distance checks
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
                local distance   = #(currentPos - data.homePosition)

                -- keep within 100m of home
                if distance > 100.0 then
                    SetEntityCoords(data.ped, data.homePosition.x, data.homePosition.y, data.homePosition.z,
                        false, false, false, false)
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
                price, currentStock, maxStock
            ),
            description = animalCfg.description or "Purchase this animal for your farm",
            icon = animalCfg.icon or "paw",
            disabled = disabled,
            onSelect = function()
                if not disabled then
                    TriggerServerEvent("animalfarm:buyAnimal", animalType)
                    exports.ox_lib:hideContext()
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
            exports.ox_lib:hideContext()
            VendorMenuOpen = false
        end
    }

    exports.ox_lib:registerContext({
        id = "vendor_menu",
        title = "🐄 Animal Vendor",
        options = options
    })

    exports.ox_lib:showContext("vendor_menu")
    VendorMenuOpen = true
end

-- ----------------------------------------------------------------------------
-- Events with better error handling
-- ----------------------------------------------------------------------------
RegisterNetEvent('animalfarm:updateStock', function(animalType, newStock)
    if not animalType then return end
    GlobalAnimalStock[animalType] = newStock
    if VendorMenuOpen then
        exports.ox_lib:hideContext('vendor_menu')
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
    -- 🔹 Enhanced player load with NUI safety
    print("[AnimalFarm] Player loaded - ensuring NUI is closed")
    SafeSetNuiFocus(false, false)
    SendNUIMessage({ action = "closeAnimalMenu" })
    
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
    print("[AnimalFarm] Player unloading - cleaning up NUI and entities")
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
    
    -- Immediate NUI cleanup
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    
    -- Send multiple close messages in a thread
    CreateThread(function()
        for i = 1, 15 do
            SendNUIMessage({ action = "closeAnimalMenu" })
            Wait(25)
        end
    end)

    -- Wait a bit for NUI cleanup
    Wait(500)

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
        
        -- 🔹 Additional NUI cleanup for already logged in players
        SafeSetNuiFocus(false, false)
        SendNUIMessage({ action = "closeAnimalMenu" })
        
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
                        1,
                        c4.x, c4.y, c4.z - 1.0,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        size.x or 6.0, size.y or 6.0, 100,
                        50, 200, 120, 120,
                        false, true, 2, false, nil, nil, false
                    )
                end
            end
        end

        Wait(sleep)
    end
end)