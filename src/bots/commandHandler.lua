local cmds = {}

cmds["ping"] = {
    discord = {
        f = function(args, msg, author)
            msg:reply("Pong!")
        end
    }
}

cmds["t"] = {
    discord = {
        f = function(args, msg, author, discord, tfm)
            tfm:sendTribeMessage("[" .. msg.member.name .. "] " .. table.concat(args, " "))
        end
    }
}
cmds["tc"] = cmds["t"]

return cmds
