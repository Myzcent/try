-- Test script for ox_target, ox_lib, and oxmysql integration
-- Add this temporarily to test if all systems work

RegisterCommand('test_ox_systems', function()
    print('^2[Animal Farming]^0 Testing ox_target + ox_lib + oxmysql integration...')
    
    -- Test 1: ox_lib notification
    lib.notify({
        title = 'System Test',
        description = 'Testing ox_lib notification system',
        type = 'success'
    })
    
    -- Test 2: ox_lib progress bar
    lib.progressBar({
        duration = 2000,
        label = 'Testing ox_lib progress bar...',
        useWhileDead = false,
        canCancel = false,
    })
    
    -- Test 3: Create test NPC with ox_target
    CreateThread(function()
        local model = GetHashKey('a_m_m_farmer_01')
        RequestModel(model)
        
        local timeout = 0
        while not HasModelLoaded(model) and timeout < 50 do
            Wait(100)
            timeout = timeout + 1
        end
        
        if HasModelLoaded(model) then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local testPed = CreatePed(4, model, playerCoords.x + 2.0, playerCoords.y, playerCoords.z, 0.0, false, true)
            
            if DoesEntityExist(testPed) then
                SetEntityInvincible(testPed, true)
                FreezeEntityPosition(testPed, true)
                SetBlockingOfNonTemporaryEvents(testPed, true)
                
                -- Test ox_target integration
                exports.ox_target:addLocalEntity(testPed, {
                    {
                        name = 'test_ox_target',
                        icon = 'fas fa-test-tube',
                        label = 'Test ox_target (Click Me!)',
                        onSelect = function()
                            lib.notify({
                                title = 'ox_target Test',
                                description = 'ox_target is working perfectly!',
                                type = 'success'
                            })
                            
                            -- Clean up test ped after 3 seconds
                            SetTimeout(3000, function()
                                if DoesEntityExist(testPed) then
                                    DeleteEntity(testPed)
                                end
                            end)
                        end
                    }
                })
                
                lib.notify({
                    title = 'Test NPC Created',
                    description = 'Look for the test NPC near you and interact with it!',
                    type = 'inform'
                })
                
                print('^2[Animal Farming]^0 Test NPC created with ox_target interaction!')
            else
                print('^1[Animal Farming]^0 Failed to create test NPC')
            end
            
            SetModelAsNoLongerNeeded(model)
        else
            print('^1[Animal Farming]^0 Failed to load test model')
        end
    end)
    
    -- Test 4: oxmysql (test database connection)
    MySQL.query('SELECT 1 as connection_test', {}, function(result)
        if result and #result > 0 then
            lib.notify({
                title = 'Database Test',
                description = 'oxmysql connection working!',
                type = 'success'
            })
            print('^2[Animal Farming]^0 oxmysql connection successful!')
        else
            lib.notify({
                title = 'Database Test',
                description = 'oxmysql connection failed!',
                type = 'error'
            })
            print('^1[Animal Farming]^0 oxmysql connection failed!')
        end
    end)
    
end, false)

RegisterCommand('test_ox_context', function()
    -- Test ox_lib context menu
    lib.registerContext({
        id = 'test_context_menu',
        title = 'ox_lib Context Test',
        options = {
            {
                title = 'Test Option 1',
                description = 'This is a test option',
                icon = 'fas fa-test',
                onSelect = function()
                    lib.notify({
                        title = 'Context Menu',
                        description = 'Option 1 selected!',
                        type = 'success'
                    })
                end
            },
            {
                title = 'Test Option 2',
                description = 'Another test option',
                icon = 'fas fa-cog',
                onSelect = function()
                    local alert = lib.alertDialog({
                        header = 'Alert Test',
                        content = 'ox_lib alert dialog is working!',
                        centered = true,
                        cancel = true
                    })
                    
                    if alert == 'confirm' then
                        lib.notify({
                            title = 'Alert Dialog',
                            description = 'You confirmed the alert!',
                            type = 'success'
                        })
                    end
                end
            }
        }
    })
    
    lib.showContext('test_context_menu')
end, false)

RegisterCommand('test_skill_check', function()
    -- Test ox_lib skill check
    lib.notify({
        title = 'Skill Check Test',
        description = 'Prepare for skill check!',
        type = 'inform'
    })
    
    local skillCheck = lib.skillCheck({'easy', 'medium'}, {'e'})
    
    if skillCheck then
        lib.notify({
            title = 'Skill Check',
            description = 'Success! ox_lib skill check working!',
            type = 'success'
        })
    else
        lib.notify({
            title = 'Skill Check',
            description = 'Failed, but ox_lib skill check is working!',
            type = 'error'
        })
    end
end, false)