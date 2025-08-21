# QB-Core Version - Installation Notes

This animal farming script has been specifically adapted for **QB-Core** framework.

## Key Changes Made:

1. **Core Object**: Uses `exports['qb-core']:GetCoreObject()` instead of QBX format
2. **Player Functions**: Uses `QBCore.Functions.GetPlayer(src)` for player data
3. **Dependencies**: Updated to use `qb-core` instead of `qbx_core`

## Installation:

1. Make sure you have **QB-Core** framework installed
2. Extract to `resources/[qb]/animal_farming/` or `resources/animal_farming/`
3. Import the SQL file: `sql/animal_farming.sql`
4. Add items to your `ox_inventory/data/items.lua` (see `items.lua`)
5. Add to `server.cfg`: `ensure animal_farming`

## Dependencies Required:
- `qb-core` (QB-Core framework)
- `ox_lib` (UI and progress systems)
- `ox_target` (Interaction system)  
- `ox_inventory` (Item management)
- `oxmysql` (Database operations)

## Compatibility:
✅ QB-Core Framework
❌ QBX Framework (use original version for QBX)
❌ ESX Framework

The script is now fully compatible with QB-Core and should work without the previous errors.