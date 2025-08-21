# 🐄 Animal Farming Script for QB-Core Framework

A comprehensive animal farming system that allows players to purchase farmlots, raise animals, and manage their livestock with realistic stats, gender systems, and production mechanics.

## ✨ Features

### 🏡 Farmlot Ownership
- Purchase multiple personal farmlots through NPC sellers
- Animated confirmation menus via ox_lib
- No license requirement needed to purchase
- Ownership persistently saved in database
- Each lot has its own coordinates and is tied to the player's citizenid
- Fully compatible with ox_target for interaction
- Configurable maximum number of lots per player (default: unlimited)

### 🐷 Animal Management
- **Available Animals**: Pig (Baboy), Cow (Baka)
- Purchase animals through NPC vendor using ox_target
- Requires at least one owned farmlot
- Animals spawn with realistic delays (10–15 seconds)
- Random positioning within farmlot boundaries
- Persistent animal data saved in database
- Animals automatically respawn when owner logs in
- Animals despawn when owner goes offline
- Farmlots can be restricted to one animal type (e.g., Cow-only Lot)
- Players can only spawn animals matching their lot type

### ⚧️ Gender System
- Each animal has a gender (Male/Female)
- 20% chance for Female, 80% Male (configurable)
- Gender is displayed in animal stats
- Gender affects production capabilities

### 📊 Animal Stats & NUI
- **Health**: Overall condition
- **Hunger**: Food requirement (degrades over time)
- **Thirst**: Water requirement (degrades over time)
- **EXP & Level**: Animals gain experience from feeding, roaming, and production
- Real-time stat monitoring and updates
- Only owners can interact via ox_target
- Check Status opens NUI panel showing:
  - Health, Hunger, Thirst
  - EXP & Level
  - Gender
  - Animal type/name
  - Interactive buttons: Feed, Collect Products, Butcher

### 🍎 Feeding System
- Feed animals using "animal_feed" item
- Interactive feeding with animations
- Improves hunger and health stats
- Gain experience points from feeding
- Optional water trough system for automatic hydration

### 🥛 Product Collection
- **Cow**: Female cows produce milk every 3 days; Male cows produce none
- **Pig**: Produces pork every 2 hours
- Cooldown system prevents exploitation
- Health and hunger requirements for production
- Gender-based production restrictions
- Level bonuses increase production yield

### 🔪 Butchering System
- Butcher dead animals for meat
- 30-second skill-based mini-game with multiple skill checks
- Success/failure mechanics with animations
- Variable meat yields based on animal type and skill performance
- Requires knife item (configurable)

## 📋 Installation & Setup

### 1. Extract Files
```bash
# Extract the animal_farming folder to your server's resources directory
/resources/animal_farming/
```

### 2. Database Setup
```sql
# Import the SQL file to create necessary tables
source sql/animal_farming.sql
```

### 3. Add Items to ox_inventory
Add the following items to your `ox_inventory/data/items.lua`:

```lua
-- Copy items from items.lua file
['animal_feed'] = { ... },
['knife'] = { ... },
['raw_meat'] = { ... },
['milk'] = { ... },
['eggs'] = { ... },
['raw_pork'] = { ... },
```

### 4. Add to server.cfg
```cfg
ensure animal_farming
```

### 5. Configure Settings
Edit `shared/config.lua` to customize:
- Farmlot locations and prices
- Animal prices, stats, and gender chance
- Product yield and cooldowns
- NPC locations and models
- Butchering settings
- Water trough system

## 📦 Dependencies

- **ox_lib** → UI and progress systems
- **ox_target** → Interaction system
- **ox_inventory** → Item management
- **oxmysql** → Database operations
- **qb-core** → QB-Core framework

## 🗄️ Database Tables

- **animal_farmlots** → Stores farmlot ownership
- **animal_livestock** → Stores animal data, gender, stats, EXP, Level
- **animal_water_troughs** → Stores water trough locations

## 🎮 Usage

### For Players

#### Purchasing Farmlots
1. Visit farmlot seller NPCs around the map
2. Use ox_target to interact with NPCs
3. Select "Purchase Farmlot" option
4. Confirm purchase through animated menu
5. Pay with cash (no bank transactions)

#### Buying Animals
1. Visit the Animal Vendor NPC
2. Select desired animal type (Pig or Cow)
3. Choose which owned farmlot to place the animal
4. Confirm purchase
5. Wait 10-15 seconds for animal to spawn

#### Animal Care
- **Feed**: Use ox_target on animals and select "Feed Animal"
  - Requires "animal_feed" item
  - Improves hunger and health
  - Grants experience points
- **Check Stats**: Opens detailed NUI panel showing all animal information
- **Collect Products**: Available when production requirements are met
  - Female cows produce milk every 3 days
  - Pigs produce pork every 2 hours
  - Requires minimum health, hunger, and thirst levels
- **Butcher**: Only available for dead animals
  - Requires knife item
  - Skill-based mini-game determines meat yield
  - Multiple skill checks for better rewards

### For Administrators

#### Configuration
- Set `Config.Debug = true` for console logging
- Adjust degradation rates in config
- Enable/disable butchering system
- Modify product cooldowns and yields
- Change female spawn percentage
- Configure maximum farmlots per player

#### Commands
No admin commands are currently implemented, but you can:
- Modify database directly for emergency situations
- Adjust config values and restart resource
- Monitor debug logs for system performance

## ⚙️ Configuration Options

### Animal Settings
```lua
Config.Animals = {
    pig = {
        label = 'Baboy (Pig)',
        model = 'a_c_pig',
        price = 5000,
        maxHealth = 100,
        productionItem = 'raw_pork',
        productionTime = 7200000, -- 2 hours
        genderProduction = false -- Both genders produce
    },
    cow = {
        label = 'Baka (Cow)',
        model = 'a_c_cow',
        price = 8000,
        maxHealth = 100,
        productionItem = 'milk',
        productionTime = 259200000, -- 3 days
        genderProduction = true -- Only females produce
    }
}
```

### Gender System
```lua
Config.FemaleChance = 20 -- 20% chance for female animals
Config.MaleChance = 80   -- 80% chance for male animals
```

### Production Requirements
```lua
Config.ProductionRequirements = {
    minHealth = 50,
    minHunger = 30,
    minThirst = 30
}
```

### Butchering System
```lua
Config.Butchering = {
    enabled = true,
    requiresKnife = true,
    minigameTime = 30000, -- 30 seconds
    skillCheckCount = 3,
    successRate = 75 -- Base success rate percentage
}
```

## 🔧 Framework Compatibility

Designed specifically for **QB-Core framework** using:
- `exports.qb-core:GetPlayer(src)` → Player data
- `player.Functions.RemoveMoney('cash', amount)` → Transactions
- `exports.ox_inventory:AddItem/RemoveItem` → Inventory management
- `player.PlayerData.citizenid` → Player identification

## 🐛 Troubleshooting

### Common Issues

1. **Animals not spawning**
   - Check if player owns a farmlot
   - Verify lot type compatibility
   - Check console for errors

2. **NUI not opening**
   - Ensure ox_lib is properly installed
   - Check browser console for JavaScript errors
   - Verify resource files are not corrupted

3. **Database errors**
   - Ensure SQL file was imported correctly
   - Check MySQL connection
   - Verify table structure matches expected schema

4. **Items not working**
   - Add all items to ox_inventory items.lua
   - Restart ox_inventory after adding items
   - Check item names match config exactly

### Debug Mode
Enable debug mode in config for detailed logging:
```lua
Config.Debug = true
```

## 📝 License

This script is provided as-is for educational and development purposes. Feel free to modify and adapt to your server's needs.

## 🤝 Support

For support and updates, please check the documentation and configuration files. Make sure all dependencies are properly installed and configured.

---

**Enjoy your animal farming experience!** 🐄🐷🥛🥩