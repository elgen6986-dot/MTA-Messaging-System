local onlinePlayers = {}

local function getSafeName(player)
    return getPlayerName(player):gsub("#%x%x%x%x%x%x", "")
end

local function getOnlineListForPlayer(sourcePlayer)
    local list = {}
    for _, player in ipairs(getElementsByType("player")) do
        if player ~= sourcePlayer then
            table.insert(list, getSafeName(player))
        end
    end
    table.sort(list, function(a, b)
        return a:lower() < b:lower()
    end)
    return list
end

addEvent("messaging:requestOnlinePlayers", true)
addEvent("messaging:sendMessage", true)

addEventHandler("messaging:requestOnlinePlayers", root, function()
    triggerClientEvent(source, "messaging:onlinePlayers", source, getOnlineListForPlayer(source))
end)

addEventHandler("messaging:sendMessage", root, function(targetName, message)
    local senderName = getSafeName(source)
    local cleanMessage = tostring(message or "")

    if not targetName or targetName == "" then
        triggerClientEvent(source, "messaging:messageError", source, "لم يتم تحديد مستلم الرسالة.")
        return
    end

    if cleanMessage:len() > 260 then
        cleanMessage = cleanMessage:sub(1, 260)
    end

    if cleanMessage == "" then
        triggerClientEvent(source, "messaging:messageError", source, "لا يمكنك إرسال رسالة فارغة.")
        return
    end

    local targetPlayer = getPlayerFromName(targetName)
    if not targetPlayer then
        triggerClientEvent(source, "messaging:messageError", source, "اللاعب غي�� متصل.")
        return
    end

    triggerClientEvent(source, "messaging:messageSent", source, targetName, cleanMessage)
    triggerClientEvent(targetPlayer, "messaging:messageReceived", targetPlayer, senderName, cleanMessage)
end)

addEventHandler("onPlayerJoin", root, function()
    for _, player in ipairs(getElementsByType("player")) do
        if player ~= source then
            triggerClientEvent(player, "messaging:playerJoined", player, getSafeName(source))
        end
    end
end)

addEventHandler("onPlayerQuit", root, function()
    for _, player in ipairs(getElementsByType("player")) do
        triggerClientEvent(player, "messaging:playerLeft", player, getSafeName(source))
    end
end)
