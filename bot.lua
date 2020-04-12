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
local qotd = require('qotd-client')
local md5 = require('md5')

local discord = discordia.Client({
    cacheAllMembers = true
})

local forums = fromage()
local tfm = transfromage.client:new()

local guild = nil
local updated = false
local histLogs = {}
local members = {}
local verificationKeys = {}
local onlineMembers = {
    ["Wtal#5272"] = true
}
local tribeHouseCount = 0
local onlineCount = 1
local totalMembers = 0
local attempts = 5

loop = function()
    tfm:playEmoticon(math.random(0, 9))
    local _, inCooldown = qotd.isInCooldown(http, json)
    if not inCooldown then
        askQuestion(guild:getMember(discord.user.id))
    else
        print("[QOTD] In cooldown")
    end
    timer.setTimeout(1000 * 60 * (testing and 1 or 15), coroutine.wrap(loop))
end

local getStoredName = function(name, memberList)
    memberList = memberList or members
    for n, r in next, memberList do             
        if not not n:find(name .. '#?%d*') then
            return n
        end
    end
    return nil
end

local removeRanks = function(member)
    for role, data in next, enum.roles do
        if member:hasRole(data.id) and role ~= "manager" and role ~= "member" and role ~= "Verified" then
            member:removeRole(data.id)
        end
    end
end

setRank = function(member, fromTfm)
    print('setting rank')
    if (not fromTfm) and updated and member:hasRole(enum.roles["Verified"].id) then
        print('Setting rank of ' .. member.name)
        for name, data in next, members do
            local rank = data.rank
            if name:lower():find(member.name:lower() .. '#?%d*') then
                print('Found member mathcing the given instance')
                print('Removing existing rank')            
                removeRanks(member)
                print('Adding the new rank \'' .. rank .. '\'')
                member:addRole(enum.roles[rank].id)
                return
            end
        end
        removeRanks(member)
        member:addRole(enum.roles['Passer-by'].id)
    elseif fromTfm and updated then
        print('Setting rank of ' .. member)
        for k, v in pairs(guild.members) do      
            if member:find(v.name .. '#?%d*') then
                setRank(v, false)
            end
        end
    end
end


local getMembers = function()
    print('Connecting to members...')
    local page = 1
    local p1 = forums.getTribeMembers(enum.id, page)
    print('Fetching members... (total pages:' .. p1._pages .. ')')
    while page <= p1._pages do
        print('Getting page ' .. page .. ' of ' ..p1._pages .. ' ...')
        for _, member in next, forums.getTribeMembers(enum.id, page) do
            if (type(member) == 'table') then
                members[member.name] = {rank=member.rank, joined=member.timestamp / 1000, name=member.name}
                totalMembers = totalMembers + 1
            end
        end
        page = page + 1
    end
    print('Updated all members!')
    updated = true
    tfm:joinTribeHouse()
end

local encodeUrl = function(url)
	local out, counter = {}, 0

	for letter in string.gmatch(url, '.') do
		counter = counter + 1
		out[counter] = string.upper(string.format("%02x", string.byte(letter)))
	end

	return '%' .. table.concat(out, '%')
end

local reply = function(name)
    local res = ""
    xpcall(function()
        print("Requesting useless facts...")
        local head, body = http.request('GET', 'https://uselessfacts.jsph.pl/random.md?language=en', {{ "user-agent", 'Seniru' }})
        res = hi[math.random(1, #hi)] .. " " .. name .. "! Wanna hear a fact?\n" .. body
        print("Request completed!")
    end, function() print("Request failed!") res = "Oops! An error occured!" end)
    return res
end

local formatName = function(name)
    return name:sub(1, 1):upper() .. name:sub(2):lower()
end

local getProfile = function(name, msg)
    xpcall(function()
        name = formatName(name)
        print('> p ' .. name)
        local mem = members[getStoredName(name)]
        
        -- setting member name to the name given if the member is not in the tribe
        if not mem then
            if name:find("#%d%d%d%d") then
                mem = {name = name}
            else 
                mem = {name = name .. "#0000"}
            end
        end

        local fName = mem.name:sub(1, -6)
        local disc = mem.name:sub(-4)

        local p = {}

        --retrieving html chunk from cfm and atelier801 forums
        local _, cfm = http.request('GET', 'https://cheese.formice.com/transformice/mouse/' .. fName .. "%23" .. disc)
        --retrieving profile data from forums (using fromage)
        local _, a801p = http.request('GET', 'https://atelier801.com/profile?pr=' .. fName .. '%23' .. disc)

        if a801p:find("La requête contient un ou plusieurs paramètres invalides") then
            msg:reply("We couldn't find what you were looking for :(")
            return
        end

        p.registrationDate = a801p:match("Date d'inscription</span> : (.-)</span>")
        p.gender = a801p:match("Genre :.- (%S+)%s+<br>")
        p.gender = p.gender and ({Masculin="Male", Féminin="Female"})[p.gender] or "None"
        p.birthday = a801p:match("Date de naissance :</span> (.-)</span>")
        p.location = a801p:match("Localisation :</span> (.-)<br>")
        p.tribe = a801p:match("cadre%-tribu%-nom\">(.-)</span>")
        soulFname, souldisc = a801p:match("nom%-utilisateur%-scindable\">.->%s*(.-)<.-hashtag%-pseudo\"> #(%d+)</span>")
        p.soulmate = soulFname and (soulFname .. "#" .. souldisc) or nil
        p.avatarUrl = a801p:match("(http://avatars%.atelier801%.com/%d+/(%d+)%.%a+)")
        
        --extracting data from html chunk
        p.title = cfm:match("«(.+)»")
        p.title = encodeUrl(p.title or 'Little mouse')
        local _, tb = http.request('GET', 'https://translate.yandex.net/api/v1.5/tr.json/translate?key=' .. os.getenv('TRANSLATE_KEY') .. '&text=' .. p.title .. '&lang=es-en&format=plain')
        p.title = json.parse(tb)["text"][1]
        p.level = cfm:match("<b>Level</b>: (%d+)<br>")
        p.outfit = cfm:match("<a href=\"(https://cheese.formice.com/dressroom.+)\" target=\"_blank\">View outfit in use</a>")
        --returning the string containing profile data
        msg.channel:send {
            embed = {
                title = name .. "'s Profile",
                description = 
                    "**" .. mem.name .. "** \n*«" .. (p.title or "Little mouse") .. 
                    "»*" .. (mem.rank and "\n\n:star: Rank: " .. mem.rank or (p.tribe and "\n\n<:tribehouse:689470787950084154> Tribe: " .. p.tribe or "")) ..
                    (mem.joined and "\n:calendar: Member since: " .. os.date('%d-%m-%Y %H:%M',mem.joined) or "") .. 
                    "\n:male_sign: Gender: " .. p.gender .. 
                    "\n:crossed_swords: Level: " .. (p.level or 1) .. 
                    (p.birthday and "\n:birthday: Birthday: " .. p.birthday or "") ..
                    (p.location and "\n:map: Location: " .. p.location or "") .. 
                    (p.soulmate and "\n:revolving_hearts: Soulmate: " .. p.soulmate or "") ..
                    "\n:calendar: Registration date: " .. p.registrationDate ..
                    "\n\n[<:a801:689472184229691472> Forum Profile](https://atelier801.com/profile?pr=" .. fName .. "%23" .. disc ..")" ..
                    "\n[<:cheese:691158951563362314> CFM Profile](https://cheese.formice.com/transformice/mouse/" .. fName .. "%23" .. disc .. ")" ..
                    ("\n[<:dance:689471806624628806> Outfit](" .. p.outfit .. ")"),
                thumbnail = {url = p.avatarUrl},
                color = 0x2987ba          
            }
        }
    end, function(err) print("Error occured: " .. err) end)
end

local printOnlineUsers = function(from, target)
    local res = ""
    if from == "tfm" and updated then
        local online = {}
        -- iterating through all online members in transformice
        for name, _ in next, onlineMembers do
            if online[members[name].rank] then
                online[members[name].rank] = online[members[name].rank] .. "\n• ".. name
            else
                online[members[name].rank] = "\n• ".. name
            end
        end
        -- storing the ranks in order
        local orderedRanks = {}
        for rankName, data in next, enum.roles do
            if not ({Verified = true, manager = true, member = true, ['Passer-by'] = true})[rankName] then
                table.insert(orderedRanks, {rank = rankName, index = data.index})
            end
        end

        table.sort(orderedRanks, function(e1, e2)
            return e1.index < e2.index
        end)
        
        for _, data in next, orderedRanks do
            if online[data.rank] then
                res = res .. "\n\n**" .. data.rank .. "**" .. online[data.rank]
            end
        end
      
        target:send {
            embed = {
                title = "Online members from transformice",
                description = res == "" and "Nobody is online right now!" or res,
                color = 0x2987ba
            }
        }

    elseif from == "discord" then
        local totalCount = 0
        -- iterating through all the members in discord
        tfm:sendWhisper(target, "Online members from disord: ")
        for id, member in pairs(guild.members) do
            if member ~= nil and member.name ~= nil and not member.user.bot and member.status ~= "offline" then
                res = res .. member.name .. ", "
                totalCount = totalCount + 1
            end
            if res:len() > 230 then
                tfm:sendWhisper(target, res:sub(1, -3))
                res = ""
            end
        end
        tfm:sendWhisper(target, total == 0 and "Nobody is online right now" or res:sub(1, -3))
        tfm:sendWhisper(target, "Total members: " .. totalCount .. " (Ingame member list is accessible with the tribe menu)")
    end
end

local generateVerificationkey = function(id, randomseed)
    math.randomseed(randomseed or os.time())
    return md5.sumhexa(tostring(math.random(0, 10000) * id + math.random(0, 10000)))
end

local sendVerificationKey = function(member, channel, force)
    if member:hasRole(enum.roles['Verified'].id) then
        if force and member:hasRole(enum.roles["manager"].id) then
            local key = generateVerificationkey(member.user.id)
            verificationKeys[key] = member
            member.user:send("Here's your verification key! `" .. key .. "\n`Whisper the following to Wtal#5272 (`/c Wtal#5272`) to get verified\n")
            member.user:send("```!verify " .. key .. "```")
        elseif force then
            channel:send("You are not permitted for force verification")
        else
            channel:send("You are verified already!")
        end
    else
        local key = generateVerificationkey(member.user.id)
        verificationKeys[key] = member
        member.user:send("Here's your verification key! `" .. key .. "\n`Whisper the following to Wtal#5272 (`/c Wtal#5272`) to get verified\n")
        member.user:send("```!verify " .. key .. "```")
    end
end

addQuestion = function(question, member, target)
    if question == nil or question:find("^%s*$") then
        target:send("You must add a valid question!")
    elseif not member:hasRole(enum.roles["manager"].id) then
        target:send("You are not permitted to do this action!")
    else
        print("Adding a new QOTD")
        local success = qotd.addQuestion(question, http, json)
        target:send(success and "Added the new question!" or "An error occured in the endpoint!")
    end
end

askQuestion = function(member, target, force)
    if (member.user.id ~= discord.user.id) and (not member:hasRole(enum.roles["manager"].id)) then
        target:send("You are not permitted to do this action!")
    else
        print("Posting a new QOTD...")
        local _, res, success = qotd.retrieveQuestion(http, json, force)
        if success then
            guild:getChannel(enum.channels.question_otd):send {
                embed = {
                    color = 0x2987ba,
                    title = "QOTD #" .. res.index,
                    description = res.question
                }
            }
            if target then target:send("Asked a new question!") end
        else
            if target then
                target:send(res)
            end
            print(res)
        end
    end
end

deleteQuestion = function(question, member, target)
    -- validation
    if not member:hasRole(enum.roles["manager"].id) then    
        target:send("You are not permitted to this action!")
    elseif question == nil or question:find("^%s$*") then
        target:send("You must provide a valid number as the argument!")
    else
        local qId = tonumber(question)
        local success = qotd.deleteQuestion(qId, http, json)
        target:send(success and "Deleted the question" or "An error occured!")
    end
end

getQuestionQueue = function(target)
    local success, list, count = qotd.getQuestionQueue(http, json)
    if not success then
        target:send(list)
        return
    end
    target:send {
        embed = {
            title = "QOTD queue",
            description = list .. "\n",
            footer = {
                text = "Total Questions: " .. count
            },
            color = 0x2987ba
        }
    }
end

coroutine.wrap(function()
    
    --[[Transfromage events]]

    tfm:once("ready", function()
        print('Logging into transformice...')
	    tfm:connect("Wtal#5272", os.getenv('FORUM_PASSWORD'))
    end)
    
    tfm:on("connection", function(name, comm, id, time)
        attempts = 5
        print('Logged in successfully!')
        tfm:sendTribeMessage("Connected to tribe chat!")
        print('Logging in with forums...')
        forums.connect('Wtal#5272', os.getenv('FORUM_PASSWORD'))
        getMembers()
        discord:setGame(onlineCount .. " / " .. totalMembers .. " Online!")
        loop()
    end)

    tfm:on("connectionFailed", function()
        if attempts > 0 then
            print("Connection to transformice failed!\nTrying again (Attempts: " .. attempts .. " / 5)")
            attempts = attempts - 1
            tfm:connect("Wtal#5272", os.getenv('FORUM_PASSWORD'))
        else
            print("Connection to transformice failed!\nRestarting!")
			os.exit(1)
        end
    end)

    tfm:on("disconnection", function()
        print("disconnected")
    end)

    tfm:on("tribeMemberConnection", function(member)
        tfm:sendTribeMessage("Welcome back " .. member .. "!")
        guild:getChannel(enum.channels.tribe_chat):send("> **" .. member .. "** just connected!")
        onlineMembers[member] = true
        onlineCount = onlineCount + 1
        discord:setGame(onlineCount .. " / " .. totalMembers .. " Online!")
    end)

    tfm:on("tribeMemberDisconnection", function(member)
        guild:getChannel(enum.channels.tribe_chat):send("> **" .. member .. "** has disconnected!")
        if onlineMembers[member] then
			onlineCount = onlineCount - 1
			onlineMembers[member] = nil
			discord:setGame(onlineCount .. " / " .. totalMembers .. " Online!")
        end
    end)

    tfm:on("newTribeMember", function(member)
        tfm:sendTribeMessage("Welcome to 'We Talk a Lot' " .. member .. "!")
        members[member] = {rank='Stooge', joined=os.time(), name=member}
        setRank(member, true)
		onlineMembers[member] = true
        onlineCount = onlineCount + 1
        totalMembers = totalMembers + 1
        discord:setGame(onlineCount .. " / " .. totalMembers .. " Online!")
    end)

    tfm:on("tribeMemberLeave", function(member)
        members[member].rank = 'Passer-by'
        setRank(member, true)
		if onlineMembers[member] then
        	onlineCount = onlineCount - 1
			onlineMembers[member] = nil
		end
        totalMembers = totalMembers - 1
        discord:setGame(onlineCount .. " / " .. totalMembers .. " Online!")
    end)

    tfm:on("tribeMemberGetRole", function(member, setter, role)
        members[member].rank = role
        setRank(member, true)
    end)

    tfm:on("tribeMessage", function(member, message)
        
        if message == "!who" then
            printOnlineUsers("discord", member)
        else
            guild:getChannel(enum.channels.tribe_chat):send(
                ("> **[" .. member .. "]** " .. message):gsub("@here", "@|here"):gsub("@everyone", "@|everyone")
            )
        end

        if not onlineMembers[member] then
            onlineCount = onlineCount + 1
            onlineMembers[member] = true
            discord:setGame(onlineCount .. " / " .. totalMembers .. " Online!")
        end
    end)

    tfm:on("whisperMessage", function(playerName, message, community)
        if message:find("!verify .+") then
            local key = message:match("!verify (.+)")
            if not verificationKeys[key] then
                tfm:sendWhisper(playerName, "Your verification key doesn't match with any key in the database!")
                tfm:sendWhisper(playerName, "Try verify again (> verify) or contact the admininstration for support")
            else
                tfm:sendWhisper(playerName, "Succesfully verified and connected player with " .. verificationKeys[key].name .. " on discord!")
                verificationKeys[key]:setNickname(playerName:sub(1, -6))
                verificationKeys[key]:addRole(enum.roles['Verified'].id)
                guild:getChannel(enum.channels.general_chat):send(verificationKeys[key].mentionString )
                guild:getChannel(enum.channels.general_chat):send {
                    embed = {
                        description = "**Welcome here buddy･:+(ﾉ◕ヮ◕)ﾉ*:･**\n\nIf you like introduce yourself in <#696348125060792370>. Also head to <#620437243944763412> to add some roles!\n\nWe hope you enjoy your stay here :smile:",
                        color = 0x22ff22                        
                    }
                }
                verificationKeys[key] = nil
            end
        end
    end)

    tfm:on("newPlayer", function(playerData)
        tribeHouseCount = tribeHouseCount + 1
        print("Player joined: (total players: " .. tribeHouseCount .. ")") 
        if updated then tfm:sendRoomMessage("Hello " .. playerData.playerName .. "!") end
        if not onlineMembers[playerData.playerName] and members[playerData.playerName] then
            onlineCount = onlineCount + 1
            onlineMembers[playerData.playerName] = true
            discord:setGame(onlineCount .. " / " .. totalMembers .. " Online!")
        end
    end)

    tfm:on("playerLeft", function(playerData)
        tribeHouseCount = tribeHouseCount - 1
        print("Player left: (total players: " .. tribeHouseCount .. ")")
        if tribeHouseCount == 1 then
            tfm:sendCommand("module stop")
        end
    end)

    tfm:on("joinTribeHouse", function(tribeName)
        tfm:emit("refreshPlayerList")
    end)

    tfm:on("refreshPlayerList", function(playerList)
        tribeHouseCount = playerList and (playerList.count or 0) or 0
        if playerList and updated then
            print("Joined tribe house. (Player count: " .. tribeHouseCount .. ")")
            for name, data in next, playerList do
                if (not onlineMembers[name]) and members[name] then
                    onlineCount = onlineCount + 1
                    onlineMembers[name] = true
                    discord:setGame(onlineCount .. " / " .. totalMembers .. " Online!")
                end
            end
        end
    end)


    --[[ Discord events]]

    discord:once("ready", function()
        guild = discord:getGuild(enum.guild)
        forums.connect('Wtal#5272', os.getenv('FORUM_PASSWORD'))
        print("Starting transformice client...")
        tfm:handlePlayers(true)
        tfm:start("89818485", os.getenv('TRANSFROMAGE_KEY'))
    end)

    discord:on('messageCreate', function(msg)
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
            getProfile(discord:getGuild(enum.guild):getMember(mentioned.first.id).name, msg)
        elseif msg.content:find('^>%s*p%s+(.-#?%d*)%s*$') then
            getProfile(msg.content:match("^>%s*p%s+(.+#?%d*)%s*$"), msg)
        -- online users
        elseif msg.content:find("^>%s*who%s*$") then
            printOnlineUsers("tfm", msg.channel)
        -- tribe chat
        elseif msg.channel.id == enum.channels.tribe_chat then
            _, count = msg.content:gsub("`", "")
            if msg.content:find("^`.+`$") and count == 2 then
                local cont = msg.content:gsub("`+", "")
                tfm:sendTribeMessage("[" .. msg.member.name .. "] " .. cont)
            end
        -- verification
        elseif msg.content:lower() == "> verify" then
            sendVerificationKey(msg.member, msg.channel, false)
        elseif msg.content:lower() == "> verify force" then
            sendVerificationKey(msg.member, msg.channel, true)
        -- QOTD commands
        elseif msg.content:find("^>%s*qotd add.*") then
            addQuestion(msg.content:match(">%s*qotd add (.*)"), msg.member, msg.channel)
        elseif msg.content:find("^>%s*qotd ask%s*$") then
            askQuestion(msg.member, msg.channel)
        elseif msg.content:find("^>%s*qotd ask%s+force%s*$") then
            askQuestion(msg.member, msg.channel, true)
        elseif msg.content:find("^>%s*qotd queue%s*$") then
            getQuestionQueue(msg.channel)
        elseif msg.content:find("^>%s*qotd delete.*$") then
            deleteQuestion(msg.content:match("^>%s*qotd delete (%d+)$"), msg.member, msg.channel)
        -- restart command
        elseif msg.content:lower() == "> restart" then
            if msg.member:hasRole(enum.roles["manager"].id) then
                msg:reply("Restarting the bot...")
                os.exit(1)
            else
                msg:reply("You don't have enough permissions to do this action!")
            end
        end

    end)

    discord:on('memberJoin', function(member)
        guild:getChannel(enum.channels.lobby):send(member.user.mentionString)
        guild:getChannel(enum.channels.lobby):send { 
            embed = {
                title = "Welcome!",
                description = 'Welcome to the WTAL server (ﾉ◕ヮ◕)ﾉ*:･ﾟ✧\nWe have sent you a DM to verify you in order to give you the best experience!',
                color = 0x0066ff
            }
         }
        member:addRole(enum.roles["member"].id)
        sendVerificationKey(member)
    end)

    discord:on('memberUpdate', function(member)
        print('Member Update event fired!')
        local stored = members[getStoredName(member.name)]
        if not member.user.bot and not member:hasRole(stored and enum.roles[stored.rank].id or enum.roles['Passer-by'].id) then
            setRank(member)
        end
    end)
end)()


discord:run('Bot ' .. os.getenv('DISCORD'))
