fx_version 'cerulean'
game 'gta5'

name 'qbx_animalfarmingv1'
description 'Animal Farming System for QBCore with NUI'
author 'Your Name'
version '1.0.0'

-- Dependencies
dependencies {
    'qb-core',
    'ox_target',
    'ox_lib'
}

-- Client Scripts
client_scripts {
    'client/animal.lua'
}

-- Server Scripts (add these when you have server files)
-- server_scripts {
--     'server/main.lua'
-- }

-- Shared Scripts
shared_scripts {
    'shared/config.lua'
}

-- NUI Files
ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

-- Lua 5.4
lua54 'yes'

-- Use FXv2 Onesync
use_fxv2_onesync 'yes'