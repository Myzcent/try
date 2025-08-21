local QBCore = exports.qbx_core:GetCoreObject()

-- Initialize farmlots table
local farmlots = {}

-- Load farmlots from database on server start
CreateThread(function()
    local result = MySQL.query.await('SELECT * FROM animal_farmlots')
    if result then
        for i = 1, #result do
            local lot = result[i]
            farmlots[lot.lot_id] = {
                id = lot.lot_id,
                citizenid = lot.citizenid,
                type = lot.lot_type,
                coordinates = json.decode(lot.coordinates)
            }
        end
        if Config.Debug then
            print('^2[Animal Farming]^0 Loaded ' .. #result .. ' farmlots from database')
        end
    end
end)

-- Function to check if player owns a farmlot
local function PlayerOwnsLot(citizenid, lotId)
    return farmlots[lotId] and farmlots[lotId].citizenid == citizenid
end

-- Function to get player's farmlots
local function GetPlayerFarmlots(citizenid)
    local playerLots = {}
    for lotId, lotData in pairs(farmlots) do
        if lotData.citizenid == citizenid then
            playerLots[#playerLots + 1] = lotData
        end
    end
    return playerLots
end

-- Function to count player's farmlots
local function CountPlayerFarmlots(citizenid)
    local count = 0
    for _, lotData in pairs(farmlots) do
        if lotData.citizenid == citizenid then
            count = count + 1
        end
    end
    return count
end

-- Purchase farmlot event
RegisterNetEvent('animal_farming:server:purchaseFarmlot', function(lotId)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Find the lot configuration
    local lotConfig = nil
    for i = 1, #Config.Farmlots do
        if Config.Farmlots[i].id == lotId then
            lotConfig = Config.Farmlots[i]
            break
        end
    end
    
    if not lotConfig then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Animal Farming',
            description = 'Invalid farmlot selected',
            type = 'error'
        })
        return
    end
    
    -- Check if lot is already owned
    if farmlots[lotId] then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Animal Farming',
            description = 'This farmlot is already owned',
            type = 'error'
        })
        return
    end
    
    -- Check maximum farmlots per player
    if Config.MaxFarmlotsPerPlayer > 0 then
        local currentCount = CountPlayerFarmlots(citizenid)
        if currentCount >= Config.MaxFarmlotsPerPlayer then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Animal Farming',
                description = 'You have reached the maximum number of farmlots (' .. Config.MaxFarmlotsPerPlayer .. ')',
                type = 'error'
            })
            return
        end
    end
    
    -- Check if player has enough money
    if Player.Functions.GetMoney('cash') < lotConfig.price then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Animal Farming',
            description = 'You don\'t have enough cash. Required: $' .. lotConfig.price,
            type = 'error'
        })
        return
    end
    
    -- Remove money and purchase lot
    Player.Functions.RemoveMoney('cash', lotConfig.price)
    
    -- Insert into database
    local coordinates = json.encode({
        x = lotConfig.coordinates.x,
        y = lotConfig.coordinates.y,
        z = lotConfig.coordinates.z
    })
    
    MySQL.insert('INSERT INTO animal_farmlots (citizenid, lot_id, lot_type, coordinates) VALUES (?, ?, ?, ?)', {
        citizenid,
        lotId,
        lotConfig.type,
        coordinates
    }, function(insertId)
        if insertId then
            -- Add to local cache
            farmlots[lotId] = {
                id = lotId,
                citizenid = citizenid,
                type = lotConfig.type,
                coordinates = lotConfig.coordinates
            }
            
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Animal Farming',
                description = 'Successfully purchased ' .. lotConfig.label .. ' for $' .. lotConfig.price,
                type = 'success'
            })
            
            -- Update client farmlots
            TriggerClientEvent('animal_farming:client:updateFarmlots', src, GetPlayerFarmlots(citizenid))
            
            if Config.Debug then
                print('^2[Animal Farming]^0 Player ' .. citizenid .. ' purchased farmlot ' .. lotId)
            end
        else
            -- Refund money if database insert failed
            Player.Functions.AddMoney('cash', lotConfig.price)
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Animal Farming',
                description = 'Failed to purchase farmlot. Money refunded.',
                type = 'error'
            })
        end
    end)
end)

-- Get farmlot info event
RegisterNetEvent('animal_farming:server:getFarmlotInfo', function(lotId)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Find the lot configuration
    local lotConfig = nil
    for i = 1, #Config.Farmlots do
        if Config.Farmlots[i].id == lotId then
            lotConfig = Config.Farmlots[i]
            break
        end
    end
    
    if not lotConfig then return end
    
    local lotInfo = {
        id = lotId,
        label = lotConfig.label,
        type = lotConfig.type,
        price = lotConfig.price,
        owned = farmlots[lotId] ~= nil,
        ownedByPlayer = PlayerOwnsLot(citizenid, lotId)
    }
    
    TriggerClientEvent('animal_farming:client:receiveFarmlotInfo', src, lotInfo)
end)

-- Get player farmlots event
RegisterNetEvent('animal_farming:server:getPlayerFarmlots', function()
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local playerLots = GetPlayerFarmlots(citizenid)
    
    TriggerClientEvent('animal_farming:client:updateFarmlots', src, playerLots)
end)

-- Export functions for other scripts
exports('PlayerOwnsLot', PlayerOwnsLot)
exports('GetPlayerFarmlots', GetPlayerFarmlots)
exports('CountPlayerFarmlots', CountPlayerFarmlots)

-- Player disconnect cleanup (animals will be handled separately)
AddEventHandler('playerDropped', function()
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    
    if Player then
        local citizenid = Player.PlayerData.citizenid
        if Config.Debug then
            print('^3[Animal Farming]^0 Player ' .. citizenid .. ' disconnected, cleaning up...')
        end
        -- Animal cleanup will be handled in animals.lua
        TriggerEvent('animal_farming:server:playerDisconnected', citizenid)
    end
end)