fx_version 'cerulean'
game 'gta5'

name 'animal_farming'
description 'Advanced Animal Farming System for QB-Core'
author 'YourName'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua'
}

client_scripts {
    'client/farmlots.lua',
    'client/animals.lua',
    'client/test_systems.lua'  -- Temporary test file
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/farmlots.lua',
    'server/animals.lua',
    'server/production.lua',
    'server/butchering.lua'
}

ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/script.js',
    'nui/style.css'
}

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'oxmysql',
    'qb-core'
}