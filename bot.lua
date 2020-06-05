math.randomseed(os.time())

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
local modsys = require('mod-sys')
local cmds = require("cmds")
local md5 = require('md5')

local discord = discordia.Client({
    cacheAllMembers = true
})

local forums = fromage()
local tfm = transfromage.client:new()
local tfmEnum = transfromage.enum
local byteArray = transfromage.byteArray

local guild = nil
local updated = false
local histLogs = {}
local members = {}
local verificationKeys = {}
local commands = {}
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
        if member:hasRole(data.id) and role ~= "manager" and role ~= "member" and role ~= "Verified" and role ~= "cmder" then
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
                print('Found member matching the given instance')
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

local reply = function(author, target)
    xpcall(function()
        print("Requesting useless facts...")
        local head, body = http.request('GET', 'https://uselessfacts.jsph.pl/random.md?language=en', {{ "user-agent", 'Seniru' }})
        target:send(author.mentionString)
        target:send {
            embed = {
                title = hi[math.random(1, #hi)] .. "! Wanna hear a fact? :bulb:",
                description = body,
                color = 0x2987ba
            }
        }
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
                    (p.outfit and "\n[<:dance:689471806624628806> Outfit](" .. p.outfit .. ")" or ""),
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
            if not ({Verified = true, manager = true, member = true, cmder = true, ['Passer-by'] = true})[rankName] then
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

getQuestionQueue = function(member, target)
    if member:hasRole(enum.roles["manager"].id) then
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
    else
        target:send("You are not allowed to do this action!")
    end
end

-- moderation functions

changeRank = function(member, rank, msg)
    if msg.member:hasRole(enum.roles["manager"].id) then
        if not members[member] then
            return msg:reply("Cannot Cannot find the member ¯\\_(ツ)_/¯")
        elseif (not enum.roles[rank]) or (not enum.roles[rank].index) then
            return msg:reply("Rank is not valid!")
        else
            local rankId = enum.totalRanks - enum.roles[rank].index - 1
            tfm:setTribeMemberRole(member, rankId)
            members[member].rank = rank
            msg:reply("Succesfully changed the rank of " .. member .. " to " .. rank .. " (id: " .. rankId .. ")")
            tfm:sendTribeMessage("Set by " .. msg.member.name)
        end
    else
        msg:reply("You are not permitted to do this action")
    end
end

changeGreeting = function(greeting, msg)
    if msg.member:hasRole(enum.roles["manager"].id) then
        print("Changed greeting message")
        tfm:setTribeGreetingMessage(greeting)
        msg:reply("Changed the greeting message!")
    else
        msg:reply("You are not permitted to do this action")
    end
end

kickMember = function(member, msg)
    if msg.member:hasRole(enum.roles["manager"].id) then
        if not members[member] then
            msg:reply("Cannot find the member ¯\\_(ツ)_/¯")
        else
            print("Kicking the member...")
            tfm:kickTribeMember(member)
            tfm:sendTribeMessage("Kicked by " .. msg.member.name)
            msg:reply("Kicked " .. member .."!")
        end
    else
        msg:reply("You are not permitted to do this action")
    end
end

local reportMember = function(accused, reason, reporter)
    guild:getChannel(enum.channels.admin_chat):send {
        embed = {
            title = ":closed_book: Report",
            fields = {
                {name = "Accused",  value = accused},
                {name = "Reason", value = reason or "No reason provided"},
                {name = "Reporter", value = reporter}
            },
            footer = {
                text = "Reported at: " .. os.date() .. " (+00:00 GMT)"
            },
            color = 0xffcc33
        }
    }
    tfm:sendTribeMessage("Reported the member!")
end

local warnMember = function(member, reason, message)
    if message.member:hasRole(enum.roles["manager"].id) then
        if not members[member] then
            message:reply("Cannot Cannot find the member ¯\\_(ツ)_/¯")
        else
            modsys.warnMember(member, reason, http, json)
            tfm:sendWhisper(member, "You have been warned!")
            tfm:sendWhisper(member, "Reason: " .. reason)
            message:reply("Warned the member")
        end
    else
        message:reply("You are not permitted to do this action!")
    end
end

local removeWarning = function(member, id, message)
    if message.member:hasRole(enum.roles["manager"].id) then
        if not members[member] then
            message:reply("Cannot Cannot find the member ¯\\_(ツ)_/¯")
        else
            modsys.removeWarning(member, id, http, json)
            message:reply("Removed the warning #" .. id .. " of " .. member)
        end
    else
        message:reply("You are not permitted to this action")
    end
end

local getWarnings = function(member, target)

    local success, res, count = modsys.getWarnings(member, http, json)
    if type(target) == "string" then -- requests from tfm
        if not success then
            tfm:sendWhisper(target, "An error occurred")
        else
            tfm:sendWhisper(target, "Warnings of " .. member)
            if (not res) or count == 0 then
                tfm:sendWhisper(target, "No warnings")
            else
                for _, warning in next, res do
                    tfm:sendWhisper(target, "• " .. warning)
                end
                tfm:sendWhisper(target, "Total warnings: " .. count)
            end
        end
    else
        if not success then
            target:reply("An error occured!")
        else
            target:reply {
                embed = {
                    title = "Warnings of " .. member,
                    description = res and "• " .. table.concat(res, "\n• ") .. "\n" or "No warnings!\n",
                    footer = {
                        text = "Total Warnings: " .. count
                    },
                    color = 0x2987ba
                }
            }
        end
    end
end

local blacklistPlayer = function(member, message)
    if message.member:hasRole(enum.roles["manager"].id) then
    	modsys.blacklistPlayer(member, http, json)
        message:reply("Blacklisted " .. member)
        tfm:kickTribeMember(member)
        tfm:sendTribeMessage(member .. " has been blacklisted, please do not invite them back!")
    else
        message:reply("You are not permitted to this action")
    end
end

local whitelistPlayer = function(member, message)
    if message.member:hasRole(enum.roles["manager"].id) then
        modsys.whitelistPlayer(member, http, json)
        message:reply("Whitelisted " .. member)
    else
        message:reply("You are not permitted to this action")
    end
end

local getBlacklist = function(target)
    local success, list = modsys.getBlacklist(http, json)
    if not success then
        target:send("An error occured!")
    else
        target:send {
            embed = {
                title = ":skull: Blacklist",
                description = (list and #list > 0) and "• " .. table.concat(list, "\n• ") .. "\n" or "Blacklist is empty!\n",
                color = 0x000000
            }
        }
    end
end

local createCommand = function(name, compiler, source, message)
    if name == nil or compiler == nil or source == nil then
        return message.channel:send(":x: Failed to create the command. Please supply all the arguments\nFormat: `> ccmd <name> <compiler> <source>`")
    elseif name:len() > 10  then
        return message.channel:send(":x: Command name should be less than or equal to 10 characters")
    end

    if message.member:hasRole(enum.roles["manager"].id) or message.member:hasRole(enum.roles["cmder"].id) then
        if commands[name] then
            message.channel:send("Command **" .. name .. "** already exists! Please use `> ecmd` to overwrite it!")
        else
            commands[name] = {runner = compiler, source = source, author = message.author.id}
            local success = cmds.updateCommands(commands, http, json)
            message.channel:send(success and ":white_check_mark: | Created the command" or ":x: | Failed, please try again later!")
        end
    else
        message.channel:send {
            embed = {
                title = ":x: Error",
                description = "You need the <@&" .. enum.roles["cmder"].id .. "> role to manage commands",
                color = 0xcc0000
            }
        }
    end
end

local deleteCommand = function(name, message)
    if message.member:hasRole(enum.roles["manager"].id) or message.member:hasRole(enum.roles["cmder"].id) then
        if commands[name] and (message.member:hasRole(enum.roles["manager"].id) or commands[name].author == message.author.id) then
            commands[name] = nil
            local success = cmds.updateCommands(commands, http, json)
            message.channel:send(success and ":white_check_mark: | Deleted the command" or ":x: | Failed, please try again later!")
        else
            message.channel:send(":x: You are not the author of the specified command or the command doesn't exist!")
        end
    else
        message.channel:send {
            embed = {
                title = ":x: Error",
                description = "You need the <@&" .. enum.roles["cmder"].id .. "> role to manage commands",
                color = 0xcc0000
            }
        }
    end
end

local editCommand = function(name, compiler, source, message)

    if name == nil or compiler == nil or source == nil then
        return message.channel:send(":x: Failed to edit the command. Please supply all the arguments\nFormat: `> ccmd <name> <compiler> <source>`")
    end

    if message.member:hasRole(enum.roles["manager"].id) or message.member:hasRole(enum.roles["cmder"].id) then
        if commands[name] and (message.member:hasRole(enum.roles["manager"].id) or commands[name].author == message.author.id) then
            commands[name] = {runner = compiler, source = source, author = message.author.id}
            local success = cmds.updateCommands(commands, http, json)
            message.channel:send(success and ":white_check_mark: | Editted the command" or ":x: | Failed, please try again later!")
        else
            message.channel:send(":x: You are not the author of the specified command or the command doesn't exist!")
        end
    else
        message.channel:send {
            embed = {
                title = ":x: Error",
                description = "You need the <@&" .. enum.roles["cmder"].id .. "> role to manage commands",
                color = 0xcc0000
            }
        }
    end
end

local runCommand = function(cmd, input, target)
    xpcall(function()
    
        local cmd = commands[cmd]
        if cmd then
            local success, res = cmds.runCommand(cmd.source, cmd.runner, input, http, json)
            if success then
                if res["status"] ~= "0" then
                    target:send {
                        embed = {
                            title = ":x: Error in the command",
                            description = "Contact the author of this command to fix it\n\n**Error log**:\n ```\n" .. (res["program_error"] or "") .. "```",
                            color = 0xcc0000
                        }
                    }
                else
                    res = json.parse(res["program_output"])
                    if not res then
                        target:send(":x: | An error occured while running the command. Please ask the author of this command to fix the output format.")
                    else
                        target:send {
                            embed = res
                        }
                    end
                end
            else
                target:send(":x: | An error occured, please try again later!")
            end
        end
    end, function(err)
        print("An error occured: " .. err)
    end)
end

local displayCommands = function(target)   
    local res = ""
    local count = 0
    for cmd, data in next, commands do
        res = res .. "\n• " .. cmd
        count = count + 1
        if res:len() > 2000 then
            target:send {
                embed = {
                    title = "Available commands",
                    description = res,
                    color = 0x2987ba
                }
            }
            res = ""   
        end
    end
    target:send {
        embed = {
            title = "Available commands",
            description = res,
            color = 0x2987ba,
            footer = {
                text = "Total commands: " .. count
            }
        }
    }    
end

local displayCommandInfo = function(command, target)
    if not commands[command] then
        target:send(":x: | Cannot find that command")
    else
        local cmd = commands[command]
        target:send {
            embed = {
                title = "Command info",
                fields = {
                    {name = "Author", value = "<@!" .. cmd.author .. ">"},
                    {name = "Source", value = "[" .. cmd.source .. "](" .. cmd.source .. ")"}
                },
                color = 0x2987ba
            }
        }
    end
end

local normalizeMessage = function(body)
    return body
        :gsub("<(:%w+:)%d+>", "%1") -- normalizing emojis
        :gsub("<#(%d+)>", function(channelId) -- normalizing channels
            local channel = guild:getChannel(channelId)
            return channel and "#" .. channel.name or nil
        end)
        :gsub("<@([!&]?)(%d+)>", function(mentionType, mentioned) -- normalizing channel and role mentions
            if mentionType == "!" or mentionType == "" then -- member mention
                local member = guild:getMember(mentioned)
                return member and "@" .. member.name or nil
            elseif mentionType == "&" then -- role mention
                local role = guild:getRole(mentioned)
                return role and "@" .. role.name or nil
            end
        end)
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
        local _, blacklisted = modsys.isBlacklisted(member, http, json)
        if blacklisted then
            tfm:kickTribeMember(member)
            tfm:sendTribeMessage(member .. " is in the blacklist! Please do not invite them back")
        else
            tfm:sendTribeMessage("Welcome to 'We Talk a Lot' " .. member .. "!")
            members[member] = {rank='Stooge', joined=os.time(), name=member}
            setRank(member, true)
		    onlineMembers[member] = true
            onlineCount = onlineCount + 1
            totalMembers = totalMembers + 1
            discord:setGame(onlineCount .. " / " .. totalMembers .. " Online!")
        end
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
        elseif message:find("^!report .-#%d+%s?.*") then
            local reported, reason = message:match("^!report (.-#%d+)%s?(.*)")
            reportMember(reported, ((reason == nil or reason == "") and "No reason provided" or reason), member)
        elseif message:find("^!warnings .-#%d+") then
            getWarnings(message:match("^!warnings (.-#%d+)"), member)
        else
            guild:getChannel(enum.channels.tribe_chat):send(
                --("> **[" .. member .. "]** " .. message):gsub("@here", "@|here"):gsub("@everyone", "@|everyone")
		("```css\n[" .. member .. "]" .. message .. "\n```"):gsub("@here", "@|here"):gsub("@everyone", "@|everyone")
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

    tfm:on("tribeMemberGetRole", function(member, setter, role)
        guild:getChannel(enum.channels.tribe_chat):send("> " .. setter .. " has changed the rank of " .. member .. " to " .. role .. ".")
    end)

    tfm:on("tribeMemberKick", function(member, kicker)
        guild:getChannel(enum.channels.tribe_chat):send("> " .. kicker .. " has kicked " .. member .. " out of the tribe.")
    end)


    --[[ Discord events]]

    discord:once("ready", function()
        guild = discord:getGuild(enum.guild)
        forums.connect('Wtal#5272', os.getenv('FORUM_PASSWORD'))
        print("Starting transformice client...")
        tfm:handlePlayers(true)
        tfm:start("89818485", os.getenv('TRANSFROMAGE_KEY'))
        local _, res = cmds.getCommands(http, json)
        commands = res
    end)

    discord:on('messageCreate', function(msg)
        local mentioned = msg.mentionedUsers
        --For testing purposes
        if msg.content:lower() == '> ping' then
            msg:reply('Pong!')
        -- profile command
        elseif mentioned:count() == 1 and msg.author.id ~= "654987403890524160" and mentioned.first.id == '654987403890524160' then
            reply(msg.author, msg.channel)
        elseif msg.content:find("^>%s*p%s*$") then
            getProfile(msg.member.name, msg)
        elseif msg.content:find('^>%s*p%s+<@!%d+>%s*$') and mentioned:count() == 1 and not msg.mentionsEveryone then
            getProfile(discord:getGuild(enum.guild):getMember(mentioned.first.id).name, msg)
        elseif msg.content:find('^>%s*p%s+(.-#?%d*)%s*$') then
            getProfile(msg.content:match("^>%s*p%s+(.+#?%d*)%s*$"), msg)
        -- online users
        elseif msg.content:find("^>%s*who%s*$") then
            printOnlineUsers("tfm", msg.channel)
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
            getQuestionQueue(msg.member, msg.channel)
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
        -- mod commands
        elseif msg.content:find("^>%s*setrank%s+.+$") then
            local member, rank = msg.content:match("^>%s*setrank%s+(%+?.-#%d+)%s+(.+)")
            changeRank(member, rank, msg)
        elseif msg.content:find("^>%s*setmsg%s+.+$") then
            changeGreeting(msg.content:match("^>%s*setmsg%s+(.+)"), msg)
        elseif msg.content:find("^>%s*kick%s+.+$") then
            kickMember(msg.content:match("^>%s*kick%s+(.+)"), msg)
        elseif msg.content:find("^>%s*warn%s+.*$") then
            local member, reason = msg.content:match("^>%s*warn%s+(%+?.-#%d+)%s*(.*)")
            reason = (reason == nil or reason == "") and "No reason provided" or reason
            warnMember(member, reason, msg)
        elseif msg.content:find("^>%s*warnings%s+.+$") then
            getWarnings(msg.content:match("^>%s*warnings%s+(.+)"), msg)
        elseif msg.content:find("^>%s*rwarn%s+.+$") then
            local member, id = msg.content:match("^>%s*rwarn%s+(%+?.-#%d+)%s+(%d+)")
            removeWarning(member, tonumber(id), msg)
        elseif  msg.content:find("^>%s*blacklist$") then
            getBlacklist(msg.channel)
        elseif msg.content:find("^>%s*blacklist%s+.+$") then
            local member = msg.content:match("^>%s*blacklist%s+(.+)")
            blacklistPlayer(member, msg)
        elseif msg.content:find("^>%s*whitelist%s+.+$") then
            local member = msg.content:match("^>%s*whitelist%s+(.+)")
            whitelistPlayer(member, msg)
        -- tribe chat
        elseif msg.channel.id == enum.channels.tribe_chat then
            _, count = msg.content:gsub("`", "")
            if msg.content:find("^`.+`$") and count == 2 then
                local cont = msg.content:gsub("`+", "")
                tfm:sendTribeMessage("[" .. msg.member.name .. "] " .. cont)
            elseif msg.content:find("^>%s*tc?%s+.+$") then
                tfm:sendTribeMessage("[" .. msg.member.name .. "] " .. normalizeMessage(msg.content:match("^>%s*tc?%s+(.+)$")))
            end
        -- custom commands
        elseif msg.content:find("^>%s*cmds$") then
            displayCommands(msg.channel)
        elseif msg.content:find("^>%s*cmd%s+%w+") then
            displayCommandInfo(msg.content:match(">%s*cmd%s+(%w+)"), msg.channel)
        elseif msg.content:find("^>%s*ccmd .- %w+://.+") then -- create new command
            local name, compiler, source = msg.content:match("^>%s*ccmd%s+(%w+)%s+(.+)%s+(%w+://.+)")
            createCommand(name, compiler, source, msg)
        elseif msg.content:find("^>%s*dcmd %w+") then -- delete command
            local name = msg.content:match("^>%s*dcmd%s+(%w+)")
            deleteCommand(name, msg)
        elseif msg.content:find("^>%s*ecmd .- %w+://.+") then -- edit command
            local name, compiler, source = msg.content:match("^>%s*ecmd%s+(%w+)%s+(.+)%s+(%w+://.+)")
            editCommand(name, compiler, source, msg)
        elseif msg.content:find("^>%s*.*") then -- calls a command
            local cmd, input = msg.content:match("^>%s*(%w+)%s*(.*)")
            runCommand(cmd, msg.author.id .. "\n" .. (input and "'" .. input .. "'" or " "), msg.channel)
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
