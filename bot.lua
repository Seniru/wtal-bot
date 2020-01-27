local testing = false
--Depenendencies--
local discordia = require('discordia')
local http = require('coro-http')
local fromage = require('fromage')
local transfromage = require('transfromage')
local timer = require('timer')
local json = require('json')
local enum = require(testing and 'enum-test' or 'enum')
local hi = require('replies')

local dClient = discordia.Client({
    cacheAllMembers = true
})

local fClient = fromage()
local tfm = transfromage.client:new()
local clock = discordia.Clock()

local guild = nil
local updated = -1
local histLogs = {}
local members = {}
local tries = 5

coroutine.wrap(function()
    
    
    tfm:once("ready", function()
        print('Logging into transformice...')
	    tfm:connect("Mouseclick1#0000", os.getenv('FORUM_PASSWORD'))
    end)
    
    tfm:on("connection", function(name, comm, id, time)
        print('Logged in successfully!')
        tfm:sendTribeMessage("Connected to tribe chat!")
        tfm:joinTribeHouse()
        -- Rank update process.
        -- TODO: Improve this with transfromage
        print('Logging in with forums...')
        fClient.connect('Mouseclick1#0000', os.getenv('FORUM_PASSWORD'))
        getMembers()
        loop()
    end)

    tfm:on("connectionFailed", function()
        print("Connection to transformice failed!\n Trying again")
        tfm:connect("Mouseclick1#0000", os.getenv('FORUM_PASSWORD'))
        --tfm:start("89818485", os.getenv('TRANSFROMAGE_KEY'))
    end)

    tfm:on("disconnection", function()
        print("disconnected")
    end)

    tfm:on("tribeMemberConnection", function(member)
        tfm:sendTribeMessage("Welcome back " .. member .. "!")
        guild:getChannel(enum.channels.tribe_chat):send("> **" .. member .. "** just connected!")
    end)

    tfm:on("tribeMemberDisconnection", function(member)
        guild:getChannel(enum.channels.tribe_chat):send("> **" .. member .. "** has disconnected!")
    end)

    tfm:on("newTribeMember", function(member)
        tfm:sendTribeMessage("Welcome to 'We Talk a Lot' " .. member .. "!")
        tfm:sendTribeMessage("Don't forget to check our discord server at https://discord.gg/8g7Hfnd")
    end)

   tfm:on("tribeMessage", function(member, message)
        guild:getChannel(enum.channels.tribe_chat):send("> **[" .. member .. "]** " .. message)
   end)


    dClient:once("ready", function()
        guild = dClient:getGuild(enum.guild)
        print("Starting transformice client...")
        tfm:start("89818485", os.getenv('TRANSFROMAGE_KEY'))
    end)

    dClient:on('messageCreate', function(msg)
        local mentioned = msg.mentionedUsers
        --For testing purposes
        if msg.content:lower() == '> ping' then
            msg:reply('Pong!')
        -- profile command
        elseif mentioned:count() == 1 and mentioned.first.id == '654987403890524160' then
            msg:reply(reply(msg.author.mentionString))
        elseif msg.content:find("^>%s*p%s*$") then
            getProfile(msg.member.name, msg)            
        elseif msg.content:find('^>%s*p%s+<@!%d+>%s*$') and mentioned:count() == 1 and not msg.mentionsEveryone then
            getProfile(dClient:getGuild(enum.guild):getMember(mentioned.first.id).name, msg)
        elseif msg.content:find('^>%s*p%s+(.-#?%d*)%s*$') then
            getProfile(msg.content:match("^>%s*p%s+(.+#?%d*)%s*$"), msg)
        -- tribe chat
        elseif msg.channel.id == enum.channels.tribe_chat then
            _, count = msg.content:gsub("`", "")
            if msg.content:find("^`.+`$") and count == 2 then
                local cont = msg.content:gsub("`+", "")
                tfm:sendTribeMessage("[" .. msg.member.name .. "] " .. cont)
            end
        end
    end)

    dClient:on('memberJoin', function(member)
        guild:getChannel(enum.channels.general_chat):send('Welcome ' .. member.user.mentionString .. ' to the WTAL server! Please tell us your in-game name, thanks in advance!! (ﾉ◕ヮ◕)ﾉ*:･ﾟ✧')
    end)

    dClient:on('memberUpdate', function(member)
        print('Member Update event fired!')
        local stored = members[getStoredName(member.name)]
        if not member.user.bot and not member:hasRole(stored and enum.roles[stored.rank] or enum.roles['Passer-by']) then
            setRank(member)
        end
    end)

    
end)()


function loop()
    changes, updatedTime = fetchChanges(updated)
    -- looping again for failed checks
    if not changes then
        if tries == 0 then
            print("Connection failed! Restarting...")
            tfm:disconnect()
            os.exit(1)
        end
        print("Unable to connect the forums, trying again in 60 seconds... (tries left: " .. tries .. ")")
        tries = tries - 1
        return timer.setTimeout(1000*60, coroutine.wrap(loop))
    end
    updateRanks(changes, updatedTime)
    updated = updatedTime
    tries = 5
    timer.setTimeout((testing and 0.5 or 5) * 1000*60, coroutine.wrap(loop))
end

function getStoredName(name, memberList)
    memberList = memberList or members
    for n, r in next, memberList do             
        if not not n:find(name .. '#?%d*') then
            return n
        end
    end
    return nil
end

function setRank(member)
    print('Setting rank of ' .. member.name)
    for name, data in next, members do
        local rank = data.rank
        if name:lower():find(member.name:lower() .. '#?%d*') then
            print('Found member mathcing the given instance')
            print('Removing existing rank')            
            removeRanks(member)
            print('Adding the new rank \'' .. rank .. '\'')
            member:addRole(enum.roles[rank])
            return
        end
    end
    removeRanks(member)
    member:addRole(enum.roles['Passer-by'])
end

function removeRanks(member)
    for role, id in next, enum.roles do
        if member:hasRole(id) then
            member:removeRole(id)
        end
    end
end

function getMembers()
    local hist = fClient.getTribeHistory(enum.id)
    if not hist[1] or not hist[1].timestamp then
        print("Connection failed! Restarting...")
        tfm:disconnect()
        os.exit(1)
    end
    print('Connecting to members...')
    local page = 1
    local p1 = fClient.getTribeMembers(enum.id, page)
    print('Fetching members... (total pages:' .. p1._pages .. ')')
    while page <= p1._pages do
        print('Getting page ' .. page .. ' of ' ..p1._pages .. ' ...')
        for _, member in next, fClient.getTribeMembers(enum.id, page) do
            if (type(member) == 'table') then
                members[member.name] = {rank=member.rank, joined=member.timestamp / 1000, name=member.name}
            end
        end
        page = page + 1
    end
    print('Fetching finished!')
    updated = hist[1].timestamp
    print('Updated all members!')
end


function fetchChanges(till)
    print('Checking history changes...')
    local page = 1
    local h1 = fClient.getTribeHistory(enum.id)
    if not h1[1] or not h1[1].timestamp then
        return false
    end
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
    for l = #logs, 1, -1 do
        v = logs[l]
        if getRankUpdate(v) then   
            local n, r = getRankUpdate(v)
            print('Queued ' .. n .. '!')
            if not members[n] then
                members[n] = {rank=r, joined=os.time(), name=n}
            end
            members[n].rank = r
            toUpdate[n] = r
        end
    end
    print('Updating ranks!')
    for k, v in pairs(guild.members) do
        for n, r in next, toUpdate do
            if not not n:find(v.name .. '#?%d*') then
                print('Updating ' .. n .. '...')
                removeRanks(v)
                v:addRole(enum.roles[r] or enum.roles['Passer-by'])
                print('Updated ' .. v.name .. '!')
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
        return log:match('(.-#?%d*) has left the tribe'), 'Passer-by'
    end    
end

--[[Encode URL
    copied shamelessly from Lautenschlager-id/ModuleBot
]]
local encodeUrl = function(url)
	local out, counter = {}, 0

	for letter in string.gmatch(url, '.') do
		counter = counter + 1
		out[counter] = string.upper(string.format("%02x", string.byte(letter)))
	end

	return '%' .. table.concat(out, '%')
end

--[[MISC]]

function reply(name)
    local head, body = http.request('GET', 'https://uselessfacts.jsph.pl/random.md?language=en', {{ "user-agent", 'Seniru' }})
    return hi[math.random(1, #hi)] .. " " .. name .. "! Wanna hear a fact?\n" .. body
end

function formatName(name)
    return name:sub(1, 1):upper() .. name:sub(2):lower()
end

function getProfile(name, msg)
    xpcall(function()
    name = formatName(name)
    print('> p ' .. name)
    local mem = members[getStoredName(name)]
    if not mem then
        msg:reply("The user is not in the tribe or is not indexed yet!")
        return
    end

    local fName = mem.name:sub(1, -6)
    local disc = mem.name:sub(-4)

    --retrieving html chunk from cfm and atelier801 forums
    local _, cfm = http.request('GET', 'https://cheese.formice.com/transformice/mouse/' .. fName .. "%23" .. disc)
    --extracting data from html chunk
    title = cfm:match("«(.+)»")
    title = encodeUrl(title or 'Little mouse')
    local _, tb = http.request('GET', 'https://translate.yandex.net/api/v1.5/tr.json/translate?key=' .. os.getenv('TRANSLATE_KEY') .. '&text=' .. title .. '&lang=es-en&format=plain')
    title = json.parse(tb)["text"][1]
    print(title)
    level = cfm:match("<b>Level</b>: (%d+)<br>")
    outfit = cfm:match("<a href=\"(https://cheese.formice.com/dressroom.+)\" target=\"_blank\">View outfit in use</a>")
    --retrieving profile data from forums (using fromage)
    local p = fClient.getProfile(mem.name)
    --returning the string containing profile data
    msg.channel:send {
        embed = {
            title = name .. "'s Profile",
            description = 
                "**" .. mem.name .. "** \n*«" .. (title or "Little mouse") .. 
                "»*\n\nRank: " .. (mem.rank or "Passer by") .. 
                "\nMember since: " .. (mem.joined and os.date('%d-%m-%Y %H:%M', mem.joined) or 'NA') .. 
                "\nGender: " .. ({"None", "Female", "Male"})[p.gender + 1] .. 
                "\nLevel: " .. (level or 1) .. 
                "\nBirthday: " .. (p.birthday or 'NA') .. 
                "\nLocation: " .. (p.location or 'NA') .. 
                "\nSoulmate: " .. (p.soulmate or 'NA') ..
                "\nRegistration date: " .. p.registrationDate ..
                "\n\n[Forum Profile](https://atelier801.com/profile?pr=" .. fName .. "%23" .. disc ..")" ..
                "\n[CFM Profile](https://cheese.formice.com/transformice/mouse/" .. fName .. "%23" .. disc .. ")" ..
                "\n[Outfit](" .. outfit .. ")",
            thumbnail = {url = p.avatarUrl}           
        }
    }
    end, function(err) print("Error occured: " .. err) end)
end

dClient:run('Bot ' .. os.getenv('DISCORD'))
