local screenW, screenH = guiGetScreenSize()

local ui = {}
local state = {
    open = false,
    online = {},
    selectedContact = "",
    chats = {},
    toast = nil,
}

local function safeName(playerName)
    return tostring(playerName or ""):gsub("#%x%x%x%x%x%x", "")
end

local function createToast(text, tone)
    state.toast = {
        text = text,
        tone = tone or "info",
        startTime = getTickCount(),
    }
end

local function drawRoundedPanel(x, y, w, h, borderColor, fillColor)
    dxDrawRectangle(x, y, w, h, fillColor, true)
    dxDrawRectangle(x, y, w, 2, borderColor, true)
    dxDrawRectangle(x, y + h - 2, w, 2, borderColor, true)
    dxDrawRectangle(x, y, 2, h, borderColor, true)
    dxDrawRectangle(x + w - 2, y, 2, h, borderColor, true)
end

local function renderToast()
    if not state.toast then
        return
    end

    local elapsed = getTickCount() - state.toast.startTime
    if elapsed > 4000 then
        state.toast = nil
        return
    end

    local alpha = 255
    if elapsed > 3200 then
        alpha = math.max(0, 255 - ((elapsed - 3200) / 800) * 255)
    end

    local toastW, toastH = 420, 62
    local toastX = (screenW - toastW) / 2
    local toastY = screenH * 0.08

    local rgb = {40, 64, 90}
    if state.toast.tone == "success" then
        rgb = {20, 118, 76}
    elseif state.toast.tone == "error" then
        rgb = {148, 34, 34}
    elseif state.toast.tone == "info" then
        rgb = {37, 99, 234}
    end

    drawRoundedPanel(toastX, toastY, toastW, toastH, tocolor(90, 115, 180, alpha), tocolor(rgb[1], rgb[2], rgb[3], 170))
    dxDrawText(state.toast.text, toastX + 24, toastY + 16, toastX + toastW - 24, toastY + toastH - 14,
        tocolor(255, 255, 255, alpha), 1, "default-bold", "center", "center", false, false, false, true)
end

local function refreshOnlinePlayers()
    if not ui.playerList then
        return
    end

    guiGridListClear(ui.playerList)

    for _, name in ipairs(state.online) do
        local row = guiGridListAddRow(ui.playerList)
        guiGridListSetItemText(ui.playerList, row, 1, name, false, false)
    end

    if #state.online > 0 and not state.chats[state.selectedContact] then
        state.selectedContact = state.online[1]
    end

    if state.selectedContact ~= "" then
        local rowCount = guiGridListGetRowCount(ui.playerList)
        for row = 0, rowCount - 1 do
            if guiGridListGetItemText(ui.playerList, row, 1) == state.selectedContact then
                guiGridListSetSelectedItem(ui.playerList, row, 1)
                break
            end
        end
    end
end

local function renderChatWindow()
    if not ui.chatMemo then
        return
    end

    if state.selectedContact == "" then
        guiSetText(ui.chatMemo, "اختر مستخدم من القائمة للبدأ في المحادثة.")
        return
    end

    local list = state.chats[state.selectedContact] or {}
    local text = ""

    for _, msg in ipairs(list) do
        local prefix = msg.mine and "أنت" or msg.sender
        text = text .. "[" .. prefix .. "] " .. msg.text .. "\n\n"
    end

    guiSetText(ui.chatMemo, text)
end

local function openMessagingUI()
    if not ui.window then
        createMessagingUI()
    end

    state.open = true
    guiSetVisible(ui.window, true)
    showCursor(true)
    triggerServerEvent("messaging:requestOnlinePlayers", localPlayer)
    renderChatWindow()
end

local function closeMessagingUI()
    state.open = false
    if ui.window then
        guiSetVisible(ui.window, false)
    end
    showCursor(false)
end

local function toggleMessagingUI()
    if state.open then
        closeMessagingUI()
    else
        openMessagingUI()
    end
end

local function sendMessageToSelected()
    if state.selectedContact == "" then
        createToast("اختر مستخدمًا أولاً", "info")
        return
    end

    local message = guiGetText(ui.input)
    local trimmed = tostring(message or ""):gsub("^%s+", ""):gsub("%s+$", "")

    if trimmed == "" then
        createToast("لا يمكنك إرسال رسالة فارغة", "error")
        return
    end

    triggerServerEvent("messaging:sendMessage", localPlayer, state.selectedContact, trimmed)
    guiSetText(ui.input, "")
end

local function createMessagingUI()
    if ui.window then
        return
    end

    ui.window = guiCreateWindow((screenW - 980) / 2, (screenH - 680) / 2, 980, 680, "Private Messaging", false)
    guiSetAlpha(ui.window, 0.92)
    guiSetVisible(ui.window, false)

    ui.header = guiCreateLabel(30, 30, 500, 28, "MTA Private Messaging", false, ui.window)
    guiSetFont(ui.header, "default-bold")

    ui.playerList = guiCreateGridList(30, 85, 240, 470, false, ui.window)
    guiGridListAddColumn(ui.playerList, "Online", 0.9)
    guiSetProperty(ui.playerList, "NoDataText", "No players online")

    ui.chatMemo = guiCreateMemo(290, 85, 660, 470, "", false, ui.window)
    guiMemoSetReadOnly(ui.chatMemo, true)

    ui.input = guiCreateEdit(290, 575, 560, 42, "", false, ui.window)
    guiEditSetMaxLength(ui.input, 260)

    ui.sendButton = guiCreateButton(860, 575, 90, 42, "Send", false, ui.window)

    addEventHandler("onClientGUIClick", ui.sendButton, function(button, stateButton)
        if button == "left" and stateButton == "up" then
            sendMessageToSelected()
        end
    end, false)

    addEventHandler("onClientGUIClick", ui.playerList, function(button, stateButton)
        if button ~= "left" or stateButton ~= "up" then
            return
        end

        local row, _ = guiGridListGetSelectedItem(ui.playerList)
        if row ~= -1 then
            state.selectedContact = guiGridListGetItemText(ui.playerList, row, 1)
            renderChatWindow()
        end
    end, false)

    addEventHandler("onClientGUIAccepted", ui.input, function()
        sendMessageToSelected()
    end, false)

    guiSetInputMode("no_binds_when_editing")
end

addEvent("messaging:onlinePlayers", true)
addEventHandler("messaging:onlinePlayers", root, function(players)
    state.online = players or {}
    refreshOnlinePlayers()

    if state.selectedContact == "" and #state.online > 0 then
        state.selectedContact = state.online[1]
    end

    renderChatWindow()
end)

addEvent("messaging:messageReceived", true)
addEventHandler("messaging:messageReceived", root, function(from, message)
    local sender = safeName(from)
    if not state.chats[sender] then
        state.chats[sender] = {}
    end

    table.insert(state.chats[sender], {
        sender = sender,
        text = tostring(message or ""),
        mine = false,
    })

    if not state.selectedContact or state.selectedContact == "" then
        state.selectedContact = sender
    end

    if state.open then
        renderChatWindow()
    end

    createToast("رسالة جديدة من " .. sender, "info")
    playSoundFrontEnd(10)
end)

addEvent("messaging:messageSent", true)
addEventHandler("messaging:messageSent", root, function(targetName, message)
    local target = safeName(targetName)
    if not state.chats[target] then
        state.chats[target] = {}
    end

    table.insert(state.chats[target], {
        sender = "أنت",
        text = tostring(message or ""),
        mine = true,
    })

    state.selectedContact = target
    renderChatWindow()
    createToast("تم الإرسال إلى " .. target, "success")
    playSoundFrontEnd(1)
end)

addEvent("messaging:messageError", true)
addEventHandler("messaging:messageError", root, function(errorText)
    createToast(errorText, "error")
    playSoundFrontEnd(2)
end)

addEvent("messaging:playerJoined", true)
addEventHandler("messaging:playerJoined", root, function(playerName)
    if playerName and playerName ~= localPlayerName then
        createToast(playerName .. " انضم إلى السيرفر", "info")
    end
end)

addEvent("messaging:playerLeft", true)
addEventHandler("messaging:playerLeft", root, function(playerName)
    createToast(playerName .. " غادر السيرفر", "info")
end)

addEventHandler("onClientRender", root, function()
    if state.open then
        local panelX, panelY, panelW, panelH = screenW * 0.24, screenH * 0.12, screenW * 0.52, screenH * 0.74
        drawRoundedPanel(panelX, panelY, panelW, panelH, tocolor(37, 99, 234, 255), tocolor(10, 14, 24, 210))
        dxDrawText("Online Contacts", panelX + 18, panelY + 16, panelX + panelW - 18, panelY + 52,
            tocolor(255, 255, 255, 230), 1.1, "default-bold", "left", "center")
    end

    renderToast()
end)

bindKey("F7", "down", toggleMessagingUI)

addEventHandler("onClientResourceStart", resourceRoot, function()
    showChat(false)
    createMessagingUI()
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
    showCursor(false)
end)

showChat(false)
