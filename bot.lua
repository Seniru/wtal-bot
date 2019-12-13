local discordia = require('discordia')
local http = require('coro-http')
local api = require('fromage')
local timer = require('timer')
local utils = require('utils')

local dClient = discordia.Client()
local fClient = api()

local id = 1051168
local updated = 1575632902000
local histLogs = {}

coroutine.wrap(function()
    
    print('Logging...')
    fClient.connect('Mouseclick1#0000', os.getenv('FORUM_PASSWORD'))

    dClient:on('messageCreate', function(msg) 
        if msg.content:lower() == '> ping' then
            msg:reply('Pong!')
        end
    end)

    
    updateRanks(fetchChanges())

    --[[timer.setInterval(1000, function()
        if history[1].timestamp > updated then
            local log = 1
            while not history[log].timestamp == updated do
                print(history[log].timestamp)
                log = log + 1
            end
            updated = history[log].timestamp
        end 
    end)]]
end)()

function fetchChanges()
    print('Fetching history')
    local history = fClient.getTribeHistory(id)
    local toUpdate = {}
    if history[1].timestamp > updated then
        print('History has updated!')
        local log = 1
        while not (history[log].timestamp == updated) do
            local name, rank = getRankUpdate(history[log].log)
            if name then
                toUpdate[name] = rank
            end                
            log = log + 1
        end
        updated = history[log].timestamp
    end
    return toUpdate
end

function updateRanks(logs)
    for k, v in next, logs do
        print(k .. ' ' .. v)
    end
end

function getRankUpdate(log)
    return log:match('.* has changed the rank of (.+#%d+) to (.+)')

end

dClient:run('Bot ' .. os.getenv('DISCORD'))
