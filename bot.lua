local discordia = require('discordia')
local http = require('coro-http')
local api = require('fromage')
local timer = require('timer')
local enum = require('enum')

local dClient = discordia.Client({
    cacheAllMembers = true
})

local fClient = api()
local clock = discordia.Clock()

local guild = nil
local updated = 1574635902000
local histLogs = {}
local members = {}

coroutine.wrap(function()
    
    --clock.start()
    print('Logging...')
    fClient.connect('Mouseclick1#0000', os.getenv('FORUM_PASSWORD'))
    guild = dClient:getGuild('522976111836004353')

    dClient:on('messageCreate', function(msg)
        --For testing purposes
        if msg.content:lower() == '> ping' then
            msg:reply('Pong!')
        elseif msg.content:lower():find('> set%s+name%s+.-#?%d*%s*') then
            local nick = msg.content:match('> set%s+name%s+(.+#?%d*)%s*')
            msg.member:setNickname(nick)
            setRank(msg.member)
            msg:reply('Successfully set the nickname to ' .. nick .. '!')
        end
    end)

    dClient:on('memberJoin', function(member)
        guild.getChannel(enum.channels.general_chat):send('Hello ' .. member.user.mentionString .. '!. Please set your in-game name game using `> set name TRANSFORMICE_USERNAME` command')
    end)

    dClient:on('memberUpdate', function(member)
        print('Member Update event fired!')
        setRank(member)
    end)

    getMembers()
    loop()
    
end)()


function loop()
    changes, updated = fetchChanges(updated)
    updateRanks(changes, updated)
    timer.setTimeout(1000*60*5, coroutine.wrap(function()
        loop()
    end))
end

function setRank(member)
    print('Setting rank of ' .. member.nickname)
    for name, rank in next, members do
        if name:lower():find(member.nickname:lower() .. '#?%d*') then
            print('Found member mathcing the given instance')
            print('Removing existing rank')            
            for role, id in next, enum.roles do
                if member:hasRole(id) then
                    member:removeRole(id)
                end
            end           
            print('Adding the new rank \'' .. rank .. '\'')
            member:addRole(enum.roles[rank])
            break
        end
    end
end

function getMembers()
    print('Connecting to members...')
    local page = 1
    local p1 = fClient.getTribeMembers(enum.id, page)
    print('Fetching members... (total pages:' .. p1._pages .. ')')
    while page <= p1._pages do
        print('Getting page ' .. page .. ' of ' ..p1._pages .. ' ...')
        for _, member in next, fClient.getTribeMembers(enum.id, page) do
            if (type(member) == 'table') then
                members[member.name] = member.rank
            end
        end
        page = page + 1
    end
    print('Fetching finished!')
    updated = fClient.getTribeHistory(enum.id)[1].timestamp
    print('Updated all members!')
end


function fetchChanges(till)
    print('Checking history changes...')
    local page = 1
    local h1 = fClient.getTribeHistory(enum.id)
    local hist = {}
    local completed = false
    if h1[1].timestamp > updated then
        print('Detected new changes')
        while not completed do
            print('Fetching page ' .. page .. '...')
            for _, log in next, fClient.getTribeHistory(enum.id, page) do
                if type(log) == 'table' then
                    if log.timestamp <= till then
                        print('Fetched new records')
                        completed = true
                        break    
                    end
                    table.insert(hist, log.log)
                end
            end
            page = page + 1
        end
    end
    return hist, h1[1].timestamp
end


function updateRanks(logs, lastUpdated)
    if lastUpdated == updated then return end
    print('Queueing members and ranks...')
    local toUpdate = {}
    for _, v in next, logs do
        if getRankUpdate(v) then   
            local n, r = getRankUpdate(v)
            print('Queued ' .. n .. '!')
            members[n] = r
            toUpdate[n] = r
        end
    end

    print('Updating ranks!')
    for k, v in pairs(guild.members) do
        for n, r in next, toUpdate do
            print('Updating ' .. n .. '...')
            if v.nickname  and not not n:find(v.nickname .. '#?%d*') then
                v:addRole('655289933463945246')
                print('Updated ' .. v.nickname .. '!')
            end
        end
    end
    print('Updating finished!')
end

function getRankUpdate(log)
    --return log:match('.* has changed the rank of (.+#%d+) to (.+)')
    --Detecting rank changes
    if log:match('.- has changed the rank of (.-#?%d*) to (.+).') then
        return log:match('.- has changed the rank of (.-#?%d*) to (.+).')
    --Detecting joinings
    elseif log:match('(.-#?%d*) has joined the tribe.') then
        return log:match('(.-#?%d*) has joined the tribe.'), 'Stooge'
    --Detecting leaves
    elseif log:match('(.-#?%d*) has left the tribe.') then
        return log:match('(.-#?%d*) has left the tribe'), 'Passer By'
    end    
end

dClient:run('Bot ' .. os.getenv('DISCORD'))
