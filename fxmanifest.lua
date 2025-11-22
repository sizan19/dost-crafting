shared_script '@blocker/shared_fg-obfuscated.lua'
fx_version 'cerulean'
game 'gta5'

description 'dost_crafting'
version '2.1.0'

lua54 'yes'

ui_page 'html/form.html'  -- ✅ Make sure this file exists

files {
    'html/form.html',
    'html/script.js',
    'html/css.css',
    'html/jquery-3.4.1.min.js',
    'html/water.png',
    'html/img/*.png',
    'html/*.mp3'
}

shared_scripts {
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server/main.lua',
}
