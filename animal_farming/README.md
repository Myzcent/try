# 🐄 Animal Farming System for FiveM

A comprehensive animal farming system for FiveM servers using QBX framework. This resource allows players to purchase farmlots, buy animals, manage their health and stats, feed them, collect products, and butcher dead animals.

## ✨ Features

### 🏠 Farmlot Ownership
- Purchase multiple personal farmlots through NPC sellers
- Animated confirmation menus via ox_lib
- No license requirement needed to purchase
- Ownership persistently saved in database
- Each lot has specific animal type restrictions
- Configurable maximum number of lots per player

### 🐷 Animal Management
- **Available Animals**: Pig (Baboy), Cow (Baka), Chicken (Manok)
- Purchase animals through NPC vendor using ox_target
- Animals spawn with realistic delays
- Random positioning within farmlot boundaries
- Persistent animal data with automatic respawning
- Animals despawn when owner goes offline
- **Gender System**: 20% female, 80% male chance

### 📊 Animal Stats System
- **Health**: Overall animal condition
- **Hunger**: Food requirement (degrades over time)
- **Thirst**: Water requirement (degrades over time)
- Real-time stat monitoring and updates
- Animals die from neglect if stats drop too low
- Optional floating 3D status display

### 🍎 Feeding System
- Feed animals using "animal_feed" item
- Interactive feeding with animations
- Improves hunger and health stats
- Optional water trough system for automatic hydration

### 🥛 Product Collection
- **Female Cows**: Produce milk every 3 days
- **Female Chickens**: Produce eggs every 30 minutes  
- **Pigs**: Produce meat every 2 hours (both genders)
- Cooldown system prevents exploitation
- Health/hunger requirements for production

### 🔪 Butchering System
- Butcher dead animals for meat
- 30-second skill-based mini-game
- Success/failure mechanics with animations
- Variable meat yields based on animal type

## 📋 Requirements

### Dependencies
- [ox_lib](https://github.com/overextended/ox_lib) - UI and progress systems
- [ox_target](https://github.com/overextended/ox_target) - Interaction system
- [ox_inventory](https://github.com/overextended/ox_inventory) - Item management
- [oxmysql](https://github.com/overextended/oxmysql) - Database operations
- [qbx_core](https://github.com/Qbox-project/qbx_core) - QBX framework

## 🚀 Installation

### 1. Download and Setup
1. Extract the `animal_farming` folder to your server's `resources` directory
2. Import the SQL file: `sql/animal_farming.sql` into your database

### 2. Add Items to ox_inventory
Add the following items from `items_config.lua` to your `ox_inventory/data/items.lua`:
- `animal_feed` - For feeding animals
- `knife` - For butchering (if enabled)
- `raw_meat` - Butchering product
- `milk` - Cow product
- `eggs` - Chicken product
- `raw_pork` - Pig product

### 3. Add to server.cfg
```cfg
ensure animal_farming
```

### 4. Add Item Images
Make sure to add the corresponding item images to your `ox_inventory/web/images/` folder:
- `animal_feed.png`
- `knife.png`
- `raw_meat.png`
- `milk.png`
- `eggs.png`
- `raw_pork.png`

## ⚙️ Configuration

Edit `shared/config.lua` to customize:

### Farmlot Settings
- Locations and prices
- Animal type restrictions
- Boundaries for each lot
- Blip settings

### Animal Settings
- Prices and stats
- Gender distribution
- Product yield and cooldowns
- Spawn delays

### NPC Settings
- Locations and models
- Interaction distances

### Gameplay Settings
- Degradation rates
- Death thresholds
- Feeding mechanics
- Butchering system

## 🎮 Usage

### For Players

#### Purchasing Farmlots
1. Visit the Farmlot Seller NPC (marked on map)
2. Browse available farmlots
3. Each farmlot is restricted to one animal type
4. Purchase with cash - no license required

#### Buying Animals
1. Visit the Animal Seller NPC
2. You must own a compatible farmlot first
3. Gender is randomly assigned (20% female, 80% male)
4. Animals spawn in your farmlot after purchase

#### Animal Care
Use ox_target on animals to:
- **Feed them** (requires animal_feed item)
- **Check stats** (health, hunger, thirst, gender)
- **Collect products** (when available)
- **Butcher** (dead animals only)

#### Product Collection
- **Female Cows**: Milk every 3 days
- **Female Chickens**: Eggs every 30 minutes
- **All Pigs**: Meat every 2 hours
- Animals must be healthy and fed to produce

### For Administrators

#### Debug Mode
Set `Config.Debug = true` for console logging

#### Customization Options
- Adjust degradation rates
- Modify product cooldowns
- Change gender spawn rates
- Enable/disable features
- Configure farmlot locations

## 🗄️ Database Tables

The script creates three main tables:

### `animal_farmlots`
Stores farmlot ownership data
- `citizenid` - Player identifier
- `farmlot_id` - Farmlot location ID
- `animal_type` - Allowed animal type

### `animal_livestock` 
Stores individual animal data
- `animal_id` - Unique animal identifier
- `gender` - Male or female
- `health`, `hunger`, `thirst` - Current stats
- `last_fed`, `last_watered`, `last_production` - Timestamps

### `animal_water_troughs`
Stores water trough locations (if enabled)

## 🔧 Commands & Events

### Server Events
- `animal_farming:server:purchaseFarmlot`
- `animal_farming:server:purchaseAnimal`
- `animal_farming:server:feedAnimal`
- `animal_farming:server:collectProduct`

### Client Events  
- `animal_farming:client:openFarmlotMenu`
- `animal_farming:client:openAnimalMenu`

### Callbacks
- `animal_farming:getPlayerFarmlots`
- `animal_farming:getAnimalStats`

## 🐛 Troubleshooting

### Common Issues
1. **Animals not spawning**: Check farmlot ownership and database entries
2. **No interaction options**: Ensure ox_target is properly installed
3. **Stats not updating**: Verify database connection and permissions
4. **Items not working**: Check ox_inventory item configuration

### Debug Mode
Enable `Config.Debug = true` to see detailed console logs for troubleshooting.

## 📝 Changelog

### Version 1.0.0
- Initial release
- Full farmlot management system
- Animal spawning and stats
- Gender system implementation
- Product collection mechanics
- Butchering mini-game
- Complete database integration

## 🤝 Support

For support and updates, please visit our GitHub repository or Discord server.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Created for QBX Framework | Compatible with ox_lib, ox_target, ox_inventory**