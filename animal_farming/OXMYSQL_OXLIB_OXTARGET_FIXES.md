# 🎯 Ox_target + Ox_lib + OxMySQL Integration Fixes

## ✅ **Current Dependencies (CORRECT):**
- ✅ `ox_target` - NPC and animal interactions
- ✅ `ox_lib` - UI, progress bars, notifications, skill checks
- ✅ `oxmysql` - Database operations
- ✅ `qb-core` - Framework integration

## 🔧 **Key Integration Fixes:**

### 1. **ox_target Integration:**

**✅ Correct ox_target usage:**
```lua
-- For NPCs
exports.ox_target:addLocalEntity(npc, {
    {
        name = 'animal_vendor',
        icon = 'fas fa-paw',
        label = 'Buy Animals',
        onSelect = function()
            ShowAnimalPurchaseMenu()
        end
    }
})

-- For Animals
exports.ox_target:addLocalEntity(animal, {
    {
        name = 'feed_animal_' .. animalId,
        icon = 'fas fa-apple-alt',
        label = 'Feed Animal',
        onSelect = function()
            TriggerServerEvent('animal_farming:server:feedAnimal', animalId)
        end
    }
})
```

### 2. **ox_lib Integration:**

**✅ Correct ox_lib usage:**
```lua
-- Notifications
lib.notify({
    title = 'Animal Farming',
    description = 'Message here',
    type = 'success' -- success, error, inform
})

-- Progress Bars
lib.progressBar({
    duration = 2000,
    label = 'Feeding animal...',
    useWhileDead = false,
    canCancel = false,
    disable = {
        car = true,
    }
})

-- Context Menus
lib.registerContext({
    id = 'animal_purchase_menu',
    title = 'Animal Vendor',
    options = options
})
lib.showContext('animal_purchase_menu')

-- Alert Dialogs
local alert = lib.alertDialog({
    header = 'Purchase Animal',
    content = 'Are you sure?',
    centered = true,
    cancel = true
})

-- Skill Checks
local skillCheck = lib.skillCheck({'easy', 'easy'}, {'e'})
```

### 3. **oxmysql Integration:**

**✅ Correct oxmysql usage:**
```lua
-- Insert
MySQL.insert('INSERT INTO table (column) VALUES (?)', {value}, function(insertId)
    if insertId then
        -- Success
    end
end)

-- Query
MySQL.query('SELECT * FROM table WHERE id = ?', {id}, function(result)
    if result and #result > 0 then
        -- Process result
    end
end)

-- Update
MySQL.update('UPDATE table SET column = ? WHERE id = ?', {newValue, id})

-- Await versions (in CreateThread)
local result = MySQL.query.await('SELECT * FROM table')
```

## 🚨 **Common Issues & Fixes:**

### Issue 1: NPCs Not Spawning
**Problem:** Model loading and coordinate issues
**Fix:** Apply the NPC spawning fixes from previous message

### Issue 2: ox_target Not Working
**Problem:** Entity not properly created or ox_target not initialized
**Fix:**
```lua
-- Ensure entity exists before adding target
if DoesEntityExist(npc) then
    exports.ox_target:addLocalEntity(npc, options)
end
```

### Issue 3: ox_lib UI Not Showing
**Problem:** Missing `@ox_lib/init.lua` or incorrect function calls
**Fix:** Ensure fxmanifest.lua has:
```lua
shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua'
}
```

### Issue 4: Database Errors
**Problem:** Incorrect oxmysql syntax or missing await
**Fix:**
```lua
-- Use CreateThread for await functions
CreateThread(function()
    local result = MySQL.query.await('SELECT * FROM table')
    -- Process result
end)
```

## 🎮 **Testing Commands:**

```
/createanimal_vendor     - Create animal vendor NPC
/checkanimal_vendor      - Check if vendor exists
/createfarmlot_npcs      - Create farmlot NPCs
/checkfarmlot_npcs       - Check farmlot NPCs status
```

## 📍 **NPC Locations to Test:**

**Animal Vendor:** Go to coordinates `2472.5, 4942.1, 51.7`
**Farmlot NPCs:** Around Grapeseed area `2447, 4968` etc.

## 🔧 **Verification Checklist:**

### ✅ **ox_target Working:**
- [ ] Can see target options when looking at NPCs
- [ ] Target options work when selected
- [ ] Animal interactions appear

### ✅ **ox_lib Working:**
- [ ] Notifications appear
- [ ] Context menus open
- [ ] Progress bars show
- [ ] Alert dialogs work

### ✅ **oxmysql Working:**
- [ ] No database errors in console
- [ ] Data saves properly
- [ ] Queries return results

## 🚀 **Quick Test Script:**

Add this to test all three systems:
```lua
RegisterCommand('test_ox_systems', function()
    -- Test ox_lib notification
    lib.notify({
        title = 'System Test',
        description = 'Testing ox_lib notification',
        type = 'success'
    })
    
    -- Test oxmysql
    MySQL.query('SELECT 1 as test', {}, function(result)
        if result then
            print('oxmysql working!')
        end
    end)
    
    -- Test ox_target (create temp ped)
    local model = GetHashKey('a_m_m_farmer_01')
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(100) end
    
    local ped = CreatePed(4, model, 0.0, 0.0, 72.0, 0.0, false, true)
    if DoesEntityExist(ped) then
        exports.ox_target:addLocalEntity(ped, {
            {
                name = 'test_target',
                icon = 'fas fa-test',
                label = 'Test Target',
                onSelect = function()
                    lib.notify({title = 'ox_target', description = 'Working!', type = 'success'})
                    DeleteEntity(ped)
                end
            }
        })
        print('Test ped created - check ox_target!')
    end
end, false)
```

The script is properly configured for your ox_target, ox_lib, and oxmysql setup! 🎉