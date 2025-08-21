fx_version 'cerulean'
game 'gta5'

name 'animal_farming'
description 'Comprehensive Animal Farming System for FiveM'
author 'Your Name'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/exports.lua'
}

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'oxmysql',
    'qbx_core'
}

-- Optional: Add data files for custom props/models if needed
-- data_file 'DLC_ITYP_REQUEST' 'stream/props.ytyp'

-- Server exports (if you want other resources to interact with this system)
server_exports {
    'GetPlayerFarmlots',
    'GetAnimalStats',
    'SpawnAnimal',
    'DespawnAnimal'
}