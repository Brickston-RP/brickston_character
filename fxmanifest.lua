fx_version 'cerulean'
game 'gta5'

name 'brickston_character'
description 'Brickston RP - Character Creator'
author 'Brickston RP'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

ui_page 'UI/index.html'

files {
    'UI/index.html',
    'UI/style.css',
    'UI/script.js',
}

dependencies {
    'es_extended',
    'oxmysql',
    'ox_lib',
}
