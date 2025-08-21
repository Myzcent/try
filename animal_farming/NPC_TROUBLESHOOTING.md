# 🔧 NPC Spawning Troubleshooting Guide

## ❌ Problem: NPCs Not Spawning

### 🔍 **Fixes Applied:**

1. **Model Loading Issues**
   - ✅ Added proper model hash conversion with `GetHashKey()`
   - ✅ Added timeout protection (10 second max wait)
   - ✅ Added model loading error handling
   - ✅ Added `SetModelAsNoLongerNeeded()` cleanup

2. **Entity Creation Issues**
   - ✅ Removed `-1.0` Z-coordinate offset that could cause underground spawning
   - ✅ Added entity existence verification
   - ✅ Enhanced NPC properties for stability

3. **Player Loading Issues**
   - ✅ Added fallback initialization for already-loaded players
   - ✅ Multiple initialization triggers

4. **Debug Tools**
   - ✅ Enabled debug mode in config
   - ✅ Added manual creation commands
   - ✅ Added status checking commands

## 🎮 **How to Test:**

### Step 1: Check Debug Output
1. Enable debug mode: `Config.Debug = true`
2. Restart the resource: `restart animal_farming`
3. Check console for debug messages

### Step 2: Manual Commands
Use these commands in game to test:

```
/createfarmlot_npcs    - Manually create farmlot NPCs
/checkfarmlot_npcs     - Check farmlot NPC status
/createanimal_vendor   - Manually create animal vendor
/checkanimal_vendor    - Check animal vendor status
```

### Step 3: Check Coordinates
Go to these locations to see if NPCs spawned:

**Farmlot NPCs:**
- Lot 1: `2447.3, 4968.5, 51.7` (Mixed - s_m_m_farmer_01)
- Lot 2: `2435.1, 4980.2, 51.8` (Cow Only - a_m_m_farmer_01)  
- Lot 3: `2460.7, 4955.3, 51.6` (Pig Only - cs_old_man1a)

**Animal Vendor:**
- Location: `2472.5, 4942.1, 51.7` (s_m_m_trucker_01)

## 🔧 **If NPCs Still Don't Spawn:**

### Option 1: Change Locations
Edit `shared/config.lua` and use these tested coordinates:

```lua
-- Sandy Shores Area (more accessible)
Config.Farmlots = {
    {
        id = 'lot_1',
        npc = {
            model = 'a_m_m_farmer_01',
            coords = vector4(1905.6, 4906.4, 48.7, 90.0) -- Sandy Shores
        }
    }
}

Config.AnimalVendor = {
    model = 'a_m_m_farmer_01',
    coords = vector4(1900.0, 4900.0, 48.5, 180.0) -- Sandy Shores
}
```

### Option 2: Alternative Models
Try these models if current ones fail:

```lua
-- Reliable models
'a_m_m_farmer_01'      -- Basic farmer
'mp_m_freemode_01'     -- Basic male
'a_m_y_hipster_01'     -- Hipster
'cs_old_man1a'         -- Old man
's_m_m_trucker_01'     -- Trucker
```

### Option 3: Check Dependencies
Ensure these are installed and working:
- ✅ `ox_target` - For NPC interactions
- ✅ `ox_lib` - For UI components
- ✅ `qb-core` - For framework

## 📋 **Console Output to Look For:**

### ✅ **Success Messages:**
```
[Animal Farming] Created farmlot NPC for lot: lot_1
[Animal Farming] Created animal vendor NPC
```

### ❌ **Error Messages:**
```
[Animal Farming] Failed to load model: model_name
[Animal Farming] Failed to create NPC for lot: lot_id
[Animal Farming] Failed to create animal vendor NPC
```

## 🚨 **Emergency Fix:**

If nothing works, use this simple test NPC:

```lua
-- Add this to any client file for testing
RegisterCommand('testnpc', function()
    local model = GetHashKey('a_m_m_farmer_01')
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(100) end
    
    local ped = CreatePed(4, model, 0.0, 0.0, 72.0, 0.0, false, true) -- Spawn at player location
    if DoesEntityExist(ped) then
        print('Test NPC created successfully!')
    else
        print('Failed to create test NPC')
    end
end, false)
```

## 📞 **Next Steps:**

1. Try the manual commands first
2. Check console for error messages
3. Test with alternative coordinates
4. Verify all dependencies are working
5. Use the emergency test NPC command

The NPCs should now spawn correctly with all the fixes applied! 🎉