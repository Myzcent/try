local QBCore = exports['qb-core']:GetCoreObject()

-- Local variables
local playerFarmlots = {}
local farmlotNPCs = {}

-- Initialize farmlots on player loaded
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('animal_farming:server:getPlayerFarmlots')
    CreateFarmlotNPCs()
end)

-- Update player farmlots
RegisterNetEvent('animal_farming:client:updateFarmlots', function(farmlots)
    playerFarmlots = farmlots
    if Config.Debug then
        print('^2[Animal Farming]^0 Updated player farmlots: ' .. #farmlots)
    end
end)

-- Receive farmlot info
RegisterNetEvent('animal_farming:client:receiveFarmlotInfo', function(lotInfo)
    ShowFarmlotPurchaseMenu(lotInfo)
end)

-- Function to create farmlot NPCs
function CreateFarmlotNPCs()
    -- Clear existing NPCs
    for i = 1, #farmlotNPCs do
        if DoesEntityExist(farmlotNPCs[i]) then
            DeleteEntity(farmlotNPCs[i])
        end
    end
    farmlotNPCs = {}
    
    -- Create new NPCs
    for i = 1, #Config.Farmlots do
        local lot = Config.Farmlots[i]
        
        CreateThread(function()
            -- Request model
            RequestModel(lot.npc.model)
            while not HasModelLoaded(lot.npc.model) do
                Wait(100)
            end
            
            -- Create NPC
            local npc = CreatePed(4, lot.npc.model, lot.npc.coords.x, lot.npc.coords.y, lot.npc.coords.z - 1.0, lot.npc.coords.w, false, true)
            SetEntityInvincible(npc, true)
            FreezeEntityPosition(npc, true)
            SetBlockingOfNonTemporaryEvents(npc, true)
            
            farmlotNPCs[#farmlotNPCs + 1] = npc
            
            -- Add ox_target interaction
            exports.ox_target:addLocalEntity(npc, {
                {
                    name = 'farmlot_seller_' .. lot.id,
                    icon = 'fas fa-home',
                    label = 'Purchase Farmlot',
                    onSelect = function()
                        TriggerServerEvent('animal_farming:server:getFarmlotInfo', lot.id)
                    end
                }
            })
            
            if Config.Debug then
                print('^2[Animal Farming]^0 Created farmlot NPC for lot: ' .. lot.id)
            end
        end)
    end
end

-- Function to show farmlot purchase menu
function ShowFarmlotPurchaseMenu(lotInfo)
    local options = {}
    
    if lotInfo.ownedByPlayer then
        options[#options + 1] = {
            title = 'Farmlot Status',
            description = 'You already own this farmlot',
            icon = 'fas fa-check-circle',
            disabled = true
        }
        options[#options + 1] = {
            title = 'Manage Animals',
            description = 'View and manage your animals',
            icon = 'fas fa-paw',
            onSelect = function()
                TriggerEvent('animal_farming:client:openAnimalManagement', lotInfo.id)
            end
        }
    elseif lotInfo.owned then
        options[#options + 1] = {
            title = 'Unavailable',
            description = 'This farmlot is already owned by another player',
            icon = 'fas fa-times-circle',
            disabled = true
        }
    else
        options[#options + 1] = {
            title = 'Purchase Farmlot',
            description = 'Buy this farmlot for $' .. lotInfo.price,
            icon = 'fas fa-dollar-sign',
            onSelect = function()
                ShowPurchaseConfirmation(lotInfo)
            end
        }
    end
    
    options[#options + 1] = {
        title = 'Farmlot Information',
        description = 'Type: ' .. string.upper(lotInfo.type) .. ' | Price: $' .. lotInfo.price,
        icon = 'fas fa-info-circle',
        disabled = true
    }
    
    lib.registerContext({
        id = 'farmlot_menu',
        title = lotInfo.label,
        options = options
    })
    
    lib.showContext('farmlot_menu')
end

-- Function to show purchase confirmation
function ShowPurchaseConfirmation(lotInfo)
    local alert = lib.alertDialog({
        header = 'Purchase Farmlot',
        content = 'Are you sure you want to purchase ' .. lotInfo.label .. ' for $' .. lotInfo.price .. '?',
        centered = true,
        cancel = true
    })
    
    if alert == 'confirm' then
        TriggerServerEvent('animal_farming:server:purchaseFarmlot', lotInfo.id)
    end
end

-- Function to check if player owns a specific farmlot
function PlayerOwnsLot(lotId)
    for i = 1, #playerFarmlots do
        if playerFarmlots[i].id == lotId then
            return true
        end
    end
    return false
end

-- Function to get farmlot by ID
function GetFarmlotById(lotId)
    for i = 1, #playerFarmlots do
        if playerFarmlots[i].id == lotId then
            return playerFarmlots[i]
        end
    end
    return nil
end

-- Function to check if coordinates are within farmlot boundaries
function IsWithinFarmlotBoundaries(coords, lotId)
    local lotConfig = nil
    for i = 1, #Config.Farmlots do
        if Config.Farmlots[i].id == lotId then
            lotConfig = Config.Farmlots[i]
            break
        end
    end
    
    if not lotConfig or not lotConfig.boundaries then
        return true -- If no boundaries defined, allow anywhere
    end
    
    local min = lotConfig.boundaries.min
    local max = lotConfig.boundaries.max
    
    return coords.x >= min.x and coords.x <= max.x and
           coords.y >= min.y and coords.y <= max.y and
           coords.z >= min.z and coords.z <= max.z
end

-- Export functions
exports('PlayerOwnsLot', PlayerOwnsLot)
exports('GetFarmlotById', GetFarmlotById)
exports('IsWithinFarmlotBoundaries', IsWithinFarmlotBoundaries)
exports('GetPlayerFarmlots', function() return playerFarmlots end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for i = 1, #farmlotNPCs do
            if DoesEntityExist(farmlotNPCs[i]) then
                DeleteEntity(farmlotNPCs[i])
            end
        end
    end
end)