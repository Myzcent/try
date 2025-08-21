# 🚀 Quick Installation Guide

## Step-by-Step Installation

### 1. Prerequisites Check ✅
Make sure you have these resources installed and working:
- ✅ QBX Core (qbx_core)
- ✅ ox_lib 
- ✅ ox_target
- ✅ ox_inventory
- ✅ oxmysql

### 2. File Installation 📁
1. Download/extract the `animal_farming` folder
2. Place it in your `resources` folder
3. Your folder structure should look like:
```
resources/
└── animal_farming/
    ├── client/
    ├── server/
    ├── shared/
    ├── sql/
    ├── fxmanifest.lua
    └── README.md
```

### 3. Database Setup 🗄️
1. Open your database management tool (phpMyAdmin, HeidiSQL, etc.)
2. Import the file: `animal_farming/sql/animal_farming.sql`
3. Verify these tables were created:
   - `animal_farmlots`
   - `animal_livestock` 
   - `animal_water_troughs`

### 4. Add Items to ox_inventory 📦
1. Open `ox_inventory/data/items.lua`
2. Add the items from `animal_farming/items_config.lua`:
   - `animal_feed`
   - `knife`
   - `raw_meat`
   - `milk`
   - `eggs`
   - `raw_pork`
   - `water_bucket` (optional)

### 5. Add Item Images 🖼️
Add these images to `ox_inventory/web/images/`:
- `animal_feed.png`
- `knife.png`
- `raw_meat.png`
- `milk.png`
- `eggs.png`
- `raw_pork.png`
- `water_bucket.png`

**Note**: You can find free icons on websites like:
- [FlatIcon](https://www.flaticon.com/)
- [Icons8](https://icons8.com/)
- [Feather Icons](https://feathericons.com/)

### 6. Server Configuration 🔧
Add to your `server.cfg`:
```cfg
# Animal Farming System
ensure animal_farming
```

### 7. Test Installation 🧪
1. Start your server
2. Join the game
3. Check console for: `[Animal Farming] Animal Farming Server initialized`
4. Look for NPCs on the map (blips should appear)
5. Visit Sandy Shores area to find the NPCs

## 🎯 Quick Test Checklist

### In-Game Testing:
- [ ] Can see farmlot seller NPC with blip
- [ ] Can see animal seller NPC with blip
- [ ] Can open farmlot purchase menu
- [ ] Can purchase a farmlot
- [ ] Can open animal purchase menu
- [ ] Can buy an animal (after owning farmlot)
- [ ] Animal spawns in farmlot area
- [ ] Can interact with animal (feed, check stats)
- [ ] Items work properly (animal_feed)

### Console Checks:
- [ ] No errors in server console
- [ ] No errors in client console (F8)
- [ ] Debug messages appear (if Config.Debug = true)

## 🐛 Common Issues & Solutions

### "Animals not spawning"
- ✅ Check database connection
- ✅ Verify farmlot ownership in database
- ✅ Check console for errors
- ✅ Ensure ox_target is working

### "No interaction options"
- ✅ Verify ox_target installation
- ✅ Check if you're close enough to animals
- ✅ Restart ox_target resource

### "Items not working"
- ✅ Check ox_inventory item configuration
- ✅ Verify item images exist
- ✅ Restart ox_inventory

### "Database errors"
- ✅ Check MySQL connection
- ✅ Verify table creation
- ✅ Check oxmysql resource

## 🎮 First Time Setup

### For Server Owners:
1. Configure farmlot locations in `shared/config.lua`
2. Adjust prices and settings as needed
3. Set up item images
4. Test all features before going live

### For Players:
1. Visit the Farmlot Seller NPC (Sandy Shores area)
2. Purchase your first farmlot
3. Visit the Animal Seller NPC
4. Buy your first animal
5. Start feeding and caring for your animals!

## 📞 Need Help?

If you encounter issues:
1. Check the console for error messages
2. Enable debug mode: `Config.Debug = true`
3. Verify all dependencies are installed
4. Check the troubleshooting section in README.md

## 🎉 You're Ready!

Once everything is working, your players can enjoy:
- 🏠 Purchasing and managing farmlots
- 🐄 Buying and caring for animals
- 📊 Monitoring animal health and stats
- 🥛 Collecting valuable products
- 💰 Building their farming empire!

---
**Happy Farming! 🚜**