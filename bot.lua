local discordia = require('discordia')
local http = require('coro-http')
local fromage = require('fromage')
local timer = require('timer')

local client = discordia.Client()

client:on('messageCreate', function(msg) 
    if msg.content:lower() == '> ping' then
        msg:reply('Pong!')
    end
end)

timer.setInterval(1000, function()
    print('lol')
end)

client:run('Bot ' .. os.getenv('DISCORD'))