local inicfg = require("inicfg")
local effil = require("effil")
local ffi = require("ffi")
local imgui = require("mimgui")
local hotkey = require("mimhotkey")
local fa = require("fAwesome6")
local encoding = require("encoding")
local memory = require('memory')
local sampev = require('lib.samp.events')
encoding.default = "CP1251"
u8 = encoding.UTF8

hotkey.no_flood = false
hotkey.Text.wait_for_key = u8("Нажмите клавишу")
hotkey.Text.no_key = u8("Нет")

local mainIni = inicfg.load({
    main = {
        cmd = "gah",
        binds = true,
        weather = false,
        time = false,
        chatfix = false,
        antibh = false,
        cleandl = false,
        sbiv = false,
        weather_slider = 0,
        time_slider = 0,
    },
    binds = {
        boff = "[81, 49]",
        adoff = "[81, 50]",
        pmoff = "[81, 51]",
        pviewhp = "[81, 52]",
        aoff = "[81, 53]",
        plogo = "[81, 54]",
        phone = "[80]",
        inv = "[73]"
    },
    style = {
        fon = "[0.07, 0.07, 0.07, 1.00]",
        elm = "[0.12, 0.12, 0.12, 1.00]",
        stroke = "[0.25, 0.25, 0.26, 0.54]",
        text = "[1.00, 1.00, 1.00, 1.00]",
        others = "[0.50, 0.50, 0.50, 1.00]",
        textChat = "31743"
    },
    sshelper = {
        auto = true,
        notif = true,
        bind = "[120]",
        fontsize = -1,
        pagesize = 10,
        wait = 1000
    }
}, "HELPERUGA.ini")
inicfg.save(mainIni, "HELPERUGA.ini")
if not doesDirectoryExist(getWorkingDirectory() .. "\\resource\\HELPERUGA") then createDirectory(getWorkingDirectory() .. "\\resource\\HELPERUGA") end

local json = {}
local image = {}

local blind = {
    id = nil,
    fontsize = 0,
    pagesize = 0
}

local menu = {
    count = 0,
    logo = nil,
    weather = imgui.new.bool(mainIni.main.weather),
    time = imgui.new.bool(mainIni.main.time),
    weather_slider = imgui.new.int(mainIni.main.weather_slider),
    time_slider = imgui.new.int(mainIni.main.time_slider),

    window = imgui.new.bool(false),
    popup = imgui.new.bool(false),
    chatfix = imgui.new.bool(mainIni.main.chatfix),
    antibh = imgui.new.bool(mainIni.main.antibh),
    cleandl = imgui.new.bool(mainIni.main.cleandl),
    sbiv = imgui.new.bool(mainIni.main.sbiv),
    cmd = imgui.new.char[256](u8(mainIni.main.cmd)),
    binds = imgui.new.bool(mainIni.main.binds),

    list = imgui.new.int(0),
    items = {},
    listItems = nil,

    fon = imgui.new.float[4](decodeJson(mainIni.style.fon)[1], decodeJson(mainIni.style.fon)[2], decodeJson(mainIni.style.fon)[3], decodeJson(mainIni.style.fon)[4]),
    elm = imgui.new.float[4](decodeJson(mainIni.style.elm)[1], decodeJson(mainIni.style.elm)[2], decodeJson(mainIni.style.elm)[3], decodeJson(mainIni.style.elm)[4]),
    stroke = imgui.new.float[4](decodeJson(mainIni.style.stroke)[1], decodeJson(mainIni.style.stroke)[2], decodeJson(mainIni.style.stroke)[3], decodeJson(mainIni.style.stroke)[4]),
    text = imgui.new.float[4](decodeJson(mainIni.style.text)[1], decodeJson(mainIni.style.text)[2], decodeJson(mainIni.style.text)[3], decodeJson(mainIni.style.text)[4]),
    others = imgui.new.float[4](decodeJson(mainIni.style.others)[1], decodeJson(mainIni.style.others)[2], decodeJson(mainIni.style.others)[3], decodeJson(mainIni.style.others)[4]),
    textChat = imgui.new.float[4](bit.band(bit.rshift(mainIni.style.textChat, 16), 0xFF) / 255, bit.band(bit.rshift(mainIni.style.textChat, 8), 0xFF) / 255, bit.band(mainIni.style.textChat, 0xFF) / 255, bit.band(bit.rshift(mainIni.style.textChat, 24), 0xFF) / 255),
    
    auto = imgui.new.bool(mainIni.sshelper.auto),
    notif = imgui.new.bool(mainIni.sshelper.notif),
    fontsize = imgui.new.int(mainIni.sshelper.fontsize),
    pagesize = imgui.new.int(mainIni.sshelper.pagesize),
    bind = decodeJson(mainIni.sshelper.bind),
    wait = imgui.new.int(mainIni.sshelper.wait / 1000)
}

local siteText = {
    main = u8("Загрузка данных. Подождите..."),
    rules = u8("Загрузка данных. Подождите..."),
    price = u8("Загрузка данных. Подождите...")
}
local filter = imgui.ImGuiTextFilter()




local siteLoad = {
    {"https://raw.githubusercontent.com/Holodilnik228666/HELPERUGA/main/main", function(response)
        siteText.main = response.text
        print("Загрузка страницы \"Основной\" завершена...")
    end},
    {"https://raw.githubusercontent.com/Holodilnik228666/HELPERUGA/main/rules", function(response)
        siteText.rules = response.text
        print("Загрузка страницы \"Правила\" завершена...")
    end},
    {"https://raw.githubusercontent.com/Holodilnik228666/HELPERUGA/main/price", function(response)
        siteText.price = response.text
        print("Загрузка страницы \"Ценовая политика\" завершена...")
    end},
    
    {"https://raw.githubusercontent.com/Holodilnik228666/HELPERUGA/main/maps/settings", function(response)
        for n in response.text:gmatch("[^\r\n]+") do
            json[#json + 1] = decodeJson(n)
            menu.items[#menu.items + 1] = decodeJson(n)["name"]
        end

        menu.listItems = imgui.new["const char*"][#menu.items](menu.items)
        print("Загрузка страницы \"Зелёные зоны\" завершена...")

        for i = 1, #json do
            if not doesFileExist(getWorkingDirectory() .. "\\resource\\HELPERUGA\\" .. u8:decode(json[i]["file"]) .. ".png") then
                downloadUrlToFile("https://github.com/Holodilnik228666/HELPERUGA/raw/main/maps/" .. u8:decode(json[i]["file"]) .. ".png", getWorkingDirectory() .. "\\resource\\HELPERUGA\\" .. u8:decode(json[i]["file"]) .. ".png",
                    function(id, status, p1, p2)
                        if status == 6 then
                            print("Установлен \"" .. u8:decode(json[i]["file"]) .. ".png\"")
                        end
                    end)

            end
        end
    end}
}




local hotcb = {
    {"boff", "Скрывать /b", decodeJson(mainIni.binds.boff)},
    {"adoff", "Скрывать объявления", decodeJson(mainIni.binds.adoff)},
    {"pmoff", "Скрывать личные сообщения", decodeJson(mainIni.binds.pmoff)},
    {"pviewhp", "Отображать HP бар", decodeJson(mainIni.binds.pviewhp)},
    {"aoff", "Скрывать сообщения админов", decodeJson(mainIni.binds.aoff)},
    {"plogo", "Скрывать логотип", decodeJson(mainIni.binds.plogo)},
    {"phone", "Открытие телефона", decodeJson(mainIni.binds.phone)},
    {"inv", "Открытие инвентаря", decodeJson(mainIni.binds.inv)}
}

function main()
    while not isSampAvailable() do wait(0) end
    local address = sampGetBase() + 0xD83A8

    print("Загрузка скрипта завершена...")
    msg("Скрипт загружен | Активация: /" .. mainIni.main.cmd)

    for i = 1, #siteLoad do
        asyncHttpRequest("GET", siteLoad[i][1], nil, 
        function(response)
            siteLoad[i][2](response)
        end,
        function(err)
            msg("Произошла ошибка при загрузке данных")
            print(err)
            thisScript():unload()
        end)
    end

    for i = 1, #hotcb do
        hotkey.RegisterCallback(hotcb[i][1], hotcb[i][3], function()
            if mainIni.main.binds and not sampIsChatInputActive() and not sampIsDialogActive() and not sampIsScoreboardOpen() and not isSampfuncsConsoleActive() and not menu.window[0] then
                sampSendChat("/" .. hotcb[i][1])
            end
        end)
    end

    if not doesFileExist(getWorkingDirectory() .. "\\resource\\HELPERUGA\\main_logo.png") then
        downloadUrlToFile("https://github.com/Holodilnik228666/HELPERUGA/raw/main/maps/main_logo.png", getWorkingDirectory() .. "\\resource\\HELPERUGA\\main_logo.png", 
        function(id, status, p1, p2)
           if status == 6 then
                print("Установлен \"main_logo.png\"")
           end
        end)
    end

    sampRegisterChatCommand(mainIni.main.cmd, function() menu.window[0] = not menu.window[0] end)
    hotkey.RegisterCallback("bind", menu.bind, function()
        if blind.id == nil then
            local file = io.open(getFolderPath(5) .. '\\GTA San Andreas User Files\\SAMP\\sa-mp.cfg')
            local sampCfg = file:read("*a")
            file:close()

            blind.fontsize = sampCfg:match("fontsize=(-?%d+)")
            blind.pagesize = sampCfg:match("pagesize=(-?%d+)")

            sampProcessChatInput("/fontsize " .. mainIni.sshelper.fontsize)
            sampProcessChatInput("/pagesize " .. mainIni.sshelper.pagesize)

            for i = 0, 10000 do
                if not sampTextdrawIsExists(i) then
                    blind.id = i
                    break
                end
            end

            local sw, sh = getScreenResolution()
            sampTextdrawCreate(blind.id, "usebox", -7.000000, -7.000000)
            sampTextdrawSetLetterSizeAndColor(blind.id, 0.474999, 55.000000, 0x00000000)
            sampTextdrawSetBoxColorAndSize(blind.id, 1, 0xFF000000, sw, sh)
            sampTextdrawSetShadow(blind.id, 0, 0xFF000000)
            sampTextdrawSetOutlineColor(id, 1, 0xFF000000)
            sampTextdrawSetAlign(blind.id, 1)
            sampTextdrawSetProportional(blind.id, 1)
            msg1("\"Темнота\" включена. Можете делать скриншот")

            if mainIni.sshelper.auto then
                lua_thread.create(function()
                    setVirtualKeyDown(0x77, true)
                    wait(10)
                    setVirtualKeyDown(0x77, false)
                    wait(mainIni.sshelper.wait)
                    msg1("Скриншот успешно сохранён. Выключаю \"Темноту\"")
                    sampProcessChatInput("/fontsize " .. blind.fontsize)
                    sampProcessChatInput("/pagesize " .. blind.pagesize)
                    sampTextdrawDelete(blind.id)
                    blind.id = nil
                end)
            end
        else
            msg1("\"Темнота\" выключена")
            sampTextdrawDelete(blind.id)
            blind.id = nil
        end
    end)

    while true do
        wait(0)
        if menu.cleandl[0] then
            local protect = memory.unprotect(address, 0x87)
            ffi.copy(ffi.cast('void*', address), '[id: %d, type: %d subtype: %d Health: %.1f]', 0x87)
            memory.protect(address, protect)
        else
            local protect = memory.unprotect(address, 0x87) 
            ffi.copy(ffi.cast('void*', address), '[id: %d, type: %d subtype: %d Health: %.1f preloaded: %u]\nDistance: %.2fm\nPassengerSeats: %u\ncPos: %.3f,%.3f,%.3f\nsPos: %.3f,%.3f,%.3f', 0x87) 
            memory.protect(address, protect)
        end
        if menu.sbiv[0] then
            if isKeyJustPressed(VK_X) and not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() and not sampIsScoreboardOpen() and not sampIsDialogActive() then
                if isCharInAnyCar(PLAYER_PED) then
                    freezeCarPosition(storeCarCharIsInNoSave(PLAYER_PED), false)
                else
                    setPlayerControl(PLAYER_HANDLE, true)
                    freezeCharPosition(PLAYER_PED, false)
                    clearCharTasksImmediately(PLAYER_PED)
                end
            end
        end
        if menu.time[0] then
            memory.setint8(0xB70153, tonumber(menu.time_slider[0]), true)
        end
        if menu.weather[0] then
            memory.setint8(0xC81320, tonumber(menu.weather_slider[0]), true)
        end
        if menu.chatfix[0] then
            if isKeyJustPressed(0x54 --[[VK_T]]) and not sampIsDialogActive() and not sampIsScoreboardOpen() and not isSampfuncsConsoleActive()  then
			    sampSetChatInputEnabled(true)
            end
        end
    end
end




imgui.OnFrame(
    function() return menu.window[0] end,
    function(self)
        imgui.SetNextWindowPos(imgui.ImVec2(getScreenResolution() / 2, select(2, getScreenResolution()) / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(720, 475), imgui.Cond.FirstUseEver)
        imgui.Begin("##HELPERUGA", menu.window, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize)
        if imgui.BeginChild("##menu", imgui.ImVec2(200, 454), false, imgui.WindowFlags.NoScrollbar) then
            imgui.Image(menu.logo, imgui.ImVec2(190, 100))
            imgui.Separator()
            if imgui.GradientPB(menu.count == 0, fa("ADDRESS_CARD"), u8("Основное")) then menu.count = 0 end
            if imgui.GradientPB(menu.count == 1, fa("ROBOT"), u8("Бинды")) then menu.count = 1 end
            if imgui.GradientPB(menu.count == 2, fa("LOCATION_DOT"), u8("Зелёные зоны")) then menu.count = 2 end
            if imgui.GradientPB(menu.count == 3, fa("BOOKMARK"), u8("Правила")) then menu.count = 3 end
            if imgui.GradientPB(menu.count == 4, fa("WALLET"), u8("Ценовая политика")) then menu.count = 4 end
            if imgui.GradientPB(menu.count == 5, fa("GEAR"), u8("Настройки скрипта")) then menu.count = 5 end
            if imgui.GradientPB(menu.count == 6, fa("CAMERA"), u8("SS Helper")) then menu.count = 6 end
            imgui.EndChild()
        end
        imgui.SameLine()
        if imgui.BeginChild("##main", imgui.ImVec2(500, 454), false, imgui.WindowFlags.NoScrollbar) then
            if menu.count == 0 then
                imgui.Caption(u8("Основное"))
                imgui.TextWrapped(siteText.main)
                imgui.NewLine()
                if imgui.CollapsingHeader(u8'Основные функции') then
                    if imgui.Checkbox(u8('Чат на Т'),menu.chatfix) then
                        mainIni.main.chatfix = menu.chatfix[0]
                        save()
                    end
                    if imgui.IsItemHovered() then
                        imgui.BeginTooltip()
                        imgui.Text(u8'Чат теперь может открываться как на Т,так и на русскую Е ')
                        imgui.EndTooltip()
                    end
                    if imgui.Checkbox(u8('Анти-баннихоп'),menu.antibh) then
                        mainIni.main.antibh = menu.antibh[0]
                        save()
                    end
                    if imgui.IsItemHovered() then
                        imgui.BeginTooltip()
                        imgui.Text(u8'Теперь вы сможете нормально бежать с прыжком одновременно')
                        imgui.EndTooltip()
                    end
                    if imgui.Checkbox(u8('Убрать мусор из /dl'),menu.cleandl) then
                        mainIni.main.cleandl = menu.cleandl[0]
                        save()
                    end
                    if imgui.IsItemHovered() then
                        imgui.BeginTooltip()
                        imgui.Text(u8'Данная функция оставляет только самое важное в /dl')
                        imgui.EndTooltip()
                    end
                    if imgui.Checkbox(u8('Сбив на X'),menu.sbiv) then
                        mainIni.main.sbiv = menu.sbiv[0]
                        save()
                    end
                    if imgui.IsItemHovered() then
                        imgui.BeginTooltip()
                        imgui.Text(u8'Сбив анимаций на клавишу X')
                        imgui.EndTooltip()
                    end
                end
                if imgui.CollapsingHeader(u8'Settime/Weather') then
                    if imgui.Checkbox(u8('##'),menu.weather) then
                        mainIni.main.weather = menu.weather[0]
                        save()
                    end
                    imgui.SameLine()
                    if imgui.SliderInt(u8('Погода'),menu.weather_slider,0,45) then
                        mainIni.main.weather_slider = menu.weather_slider[0]
                        save()
                    end
                    if imgui.Checkbox(u8(''),menu.time) then
                        mainIni.main.time = menu.time[0]
                        save()
                    end
                    imgui.SameLine()
                    if imgui.SliderInt(u8('Время'),menu.time_slider,0,24) then
                        mainIni.main.time_slider = menu.time_slider[0]
                        save()
                    end
                end
            elseif menu.count == 1 then
                imgui.Caption(u8("Бинды"))
                imgui.PushStyleVarVec2(imgui.StyleVar.FramePadding, imgui.ImVec2(10, 4))
                imgui.PushItemWidth(350)
                if imgui.InputText("##cmd", menu.cmd, 256, imgui.InputTextFlags.EnterReturnsTrue) then
                    if #ffi.string(menu.cmd) > 0 then
                        sampUnregisterChatCommand(mainIni.main.cmd)
                        mainIni.main.cmd = u8:decode(ffi.string(menu.cmd))
                        save()
                        sampRegisterChatCommand(mainIni.main.cmd, function() menu.window[0] = not menu.window[0] end)
                    else
                        sampUnregisterChatCommand(mainIni.main.cmd)
                        mainIni.main.cmd = "gah"
                        save()
                        imgui.StrCopy(menu.cmd, "gah")
                        sampRegisterChatCommand("gah", function() menu.window[0] = not menu.window[0] end)
                    end
                end
                if #ffi.string(menu.cmd) > 0 then
                    imgui.SameLine(5)
                    imgui.Text("/")
                else
                    imgui.SameLine(10)
                    imgui.Text(u8("Активация скрипта"))
                end
                imgui.PopItemWidth()
                imgui.PopStyleVar()
                imgui.Separator()
                if imgui.Checkbox(u8("Комбинации клавиш"), menu.binds) then
                    mainIni.main.binds = menu.binds[0]
                    save()
                end
                if mainIni.main.binds then
                    for i = 1, #hotcb do
                        local hot = hotkey.KeyEditor(hotcb[i][1], u8(hotcb[i][2]), imgui.ImVec2(350))
                        if hot then
                            mainIni.binds[hotcb[i][1]] = encodeJson(hot)
                            save()
                        end
                    end
                end
            elseif menu.count == 2 then
                imgui.Caption(u8("Зелёные зоны"))
                if menu.listItems ~= nil then
                    imgui.Combo("##list", menu.list, menu.listItems, #menu.items)
                    imgui.SameLine()
                    if imgui.Button(u8("Описание места"), imgui.ImVec2(170)) then
                        menu.popup[0] = true
                        imgui.OpenPopup(u8("Описание места"))
                    end
                    if imgui.BeginPopupModal(u8("Описание места"), menu.popup, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse) then
                        imgui.SetWindowSizeVec2(imgui.ImVec2(500, 300))
                        imgui.Text(u8("Название: ")  .. json[menu.list[0] + 1]["name"])
                        imgui.Separator()
                        imgui.Text(u8("Описание: "))
                        imgui.TextWrapped(json[menu.list[0] + 1]["description"])
                        imgui.EndPopup()
                    end
                    if doesFileExist(getWorkingDirectory() .. "\\resource\\HELPERUGA\\" .. u8:decode(json[menu.list[0] + 1]["file"]) .. ".png") then
                        imgui.Image(image[menu.list[0] + 1], imgui.ImVec2(500, 264))
                    else
                        imgui.Text(u8("Загрузка данных. Подождите..."))
                    end
                else
                    imgui.Text(u8("Загрузка данных. Подождите..."))
                end
            elseif menu.count == 3 then
                imgui.Caption(u8("Правила"))
                local function extractParagraphs(text)
                    local paragraphs = {}
                    local currentParagraph = nil
                    
                    for line in text:gmatch("[^\r\n]+") do -- 1. Общение
                        if line:match("^%d+%.%s.*") or line:match("^%d+%.%d+%.%s.*") then --2.1 Игровая атмосфера
                            if currentParagraph then
                                table.insert(paragraphs, currentParagraph)
                            end
                            currentParagraph = {title = line, content = ""}
                        elseif currentParagraph then
                            currentParagraph.content = currentParagraph.content .. line .. "\n"
                        end
                    end
                    
                    if currentParagraph then
                        table.insert(paragraphs, currentParagraph)
                    end
                    
                    return paragraphs
                end
                
                filter:Draw(u8"Поиск", 80) -- отрисовываем поле для поиска, 2-й аргумент его ширина
                if filter:IsActive() then -- проверка на то используется ли фильтр
                    imgui.SameLine()
                    if imgui.Button("Clear") then
                        filter:Clear() -- очищаем поле с поиском, если нажата клавиша
                    end
                end
                local paragraphs = extractParagraphs(siteText.rules)

                for i = 1, #paragraphs do
                    local title = paragraphs[i].title
                    local content = paragraphs[i].content
                
                    if filter:PassFilter(title) or filter:PassFilter(content) then
                        imgui.PushFont(TitleFont)
                        imgui.CenterText(title)
                        imgui.PopFont()
                        imgui.TextWrapped(content)
                    end
                end
            elseif menu.count == 4 then
                
                imgui.Caption(u8("Ценовая политика"))
                if imgui.BeginTabBar('Tabs') then
                    if imgui.BeginTabItem(u8'Эконом класс') then
                        imgui.TextWrapped(u8('Sadler - 2500$\nPerenniel - 4000$\nTampa - 4000$\nWalton - 4000$\nRegina - 4500$\nNebula - 4950$\nHustler - 5000$\nManana - 5000$\nPicador - 5500$\nVirgo - 5950$\nPrevion - 6000$\nMajestic - 6438$\nRumpo - 6500$\nSolair - 6500$\nTopfunvan - 6500$\nBravura - 6750$\nEsperanto - 7000$\nClover - 7000$\nMoonbeam - 7500$\nVoodoo - 7500$\nBroadway - 7500$\nHermes - 7500$\nCamper - 8000$\nBuccaneer - 8000$\nPrimo - 8300$\nGlendale - 8400$\nPony - 8500$\nRemington - 8500$\nSabre - 8500$\nBlade - 8500$\nOceanic - 9500$\nTornado - 9500$\nGreenwood - 9800$\nFortune - 10000$\nSlamwan - 10000$\nSunrise - 11500$\nStallion - 12500$\nSavanna - 14500$\nTahoma - 17500$'))
                        imgui.EndTabItem()
                    end
                    if imgui.BeginTabItem(u8'Средний класс') then
                        imgui.TextWrapped(u8('Intruder - 6500$\nEmperor - 7000$\nSentinel - 7500$\nWillard - 8000$\nCadrona - 8500$\nVincent - 9000$\nMerit - 10000$\nAdmiral - 10000$\nWindsor - 10500$\nBobcat - 11500$\nBlistacompact - 11500$\nBurrito - 12500$\nPremier - 13000$\nElegant - 13500$\nPhoenix - 13500$\nClub - 14000$\nAlpha - 14500$\nFeltzer - 14500$\nStafford - 15000$\nMesa - 16000$\nWashington - 17500$\nYosemite - 17500$\nUranus - 17500$\nRancher - 18000$\nEuros - 19000$\nLandstalker - 20000$\nJester - 20000$\nFlash - 20000$\nStratum - 23000$\nSultan - 25000$\nElegy - 27500$\nHuntley - 27500$\nComet - 28000$'))
                        imgui.EndTabItem()
                    end
                    if imgui.BeginTabItem(u8'Спорт-кары') then
                        imgui.TextWrapped(u8('Hotknife - 27500$\nZR-350 - 40000$\nBuffalo - 75000$\nBanshee - 215000$\nSuperGT - 250000$\nCheetah - 575000$\nTurismo - 625000$\nInfernus - 725000$\nBullet - 745000$'))
                        imgui.EndTabItem()
                    end
                    if imgui.BeginTabItem(u8'Мото и байки') then
                        imgui.TextWrapped(u8('BMX - 250$\nBike - 300$\nFaggio - 1000$\nMountainbike - 1750$\nSanchez - 4500$\nPCJ-600 - 5000$\nQuad - 6000$\nBF-400 - 7500$\nFCR-900 - 7500$\nFreeway - 10000$\nWayfarer - 10000$\nNRG-500 - 31500$'))
                        imgui.EndTabItem()
                    end
                    if imgui.BeginTabItem(u8'Воздушный транспорт') then
                        imgui.TextWrapped(u8('Maverick - 725000$\nSparrow - 470000$\nNevada - 2100000$\nShamal - 1300000$\nStuntplane - 710000$\nCropduster - 690000$\nSkimmer - 500000$\nRustler - 420000$\nBeagle - 200000$'))
                        imgui.EndTabItem()
                    end
                    if imgui.BeginTabItem(u8'Водный транспорт') then
                        imgui.TextWrapped(u8('Jetmax - 900000$\nSquallo - 830000$\nSpeeder - 260000$\nReefer - 100000$\nDinghy - 50000$\nMarquis - 1600000$\nTropic - 700000$'))
                        imgui.EndTabItem()
                    end
                    imgui.EndTabBar()
                end
            elseif menu.count == 5 then
                imgui.Caption(u8("Настройки скрипта"))
                if imgui.ColorEdit4("##fon", menu.fon, imgui.ColorEditFlags.NoInputs + imgui.ColorEditFlags.AlphaBar) then
                    mainIni.style.fon = "[" .. menu.fon[0] .. ", " .. menu.fon[1] .. ", " .. menu.fon[2] .. ", " .. menu.fon[3] .. "]"
                    save()
                    imgui.Style()
                end
                imgui.SameLine(30)
                imgui.Text(u8("Фон"))
                imgui.SameLine(120)
                if imgui.ColorEdit4("##elm", menu.elm, imgui.ColorEditFlags.NoInputs + imgui.ColorEditFlags.AlphaBar) then
                    mainIni.style.elm = "[" .. menu.elm[0] .. ", " .. menu.elm[1] .. ", " .. menu.elm[2] .. ", " .. menu.elm[3] .. "]"
                    save()
                    imgui.Style()
                end
                imgui.SameLine(150)
                imgui.Text(u8("Элементы"))
                if imgui.ColorEdit4("##stroke", menu.stroke, imgui.ColorEditFlags.NoInputs + imgui.ColorEditFlags.AlphaBar) then
                    mainIni.style.stroke = "[" .. menu.stroke[0] .. ", " .. menu.stroke[1] .. ", " .. menu.stroke[2] .. ", " .. menu.stroke[3] .. "]"
                    save()
                    imgui.Style()
                end
                imgui.SameLine(30)
                imgui.Text(u8("Обводка"))
                imgui.SameLine(120)
                if imgui.ColorEdit4("##text", menu.text, imgui.ColorEditFlags.NoInputs + imgui.ColorEditFlags.AlphaBar) then
                    mainIni.style.text = "[" .. menu.text[0] .. ", " .. menu.text[1] .. ", " .. menu.text[2] .. ", " .. menu.text[3] .. "]"
                    save()
                    imgui.Style()
                end
                imgui.SameLine(150)
                imgui.Text(u8("Текст в меню"))
                if imgui.ColorEdit3("##textChat", menu.textChat, imgui.ColorEditFlags.NoInputs) then
                    mainIni.style.textChat = "0x" .. string.sub(bit.tohex(join_argb(menu.textChat[3] * 255, menu.textChat[0] * 255, menu.textChat[1] * 255, menu.textChat[2] * 255)), 3, 8)
                    save()
                    imgui.Style()
                end
                imgui.SameLine(30)
                imgui.Text(u8("Текст в чате"))
                imgui.SameLine(120)
                if imgui.ColorEdit4("##others", menu.others, imgui.ColorEditFlags.NoInputs + imgui.ColorEditFlags.AlphaBar) then
                    mainIni.style.others = "[" .. menu.others[0] .. ", " .. menu.others[1] .. ", " .. menu.others[2] .. ", " .. menu.others[3] .. "]"
                    save()
                end
                imgui.SameLine(150)
                imgui.Text(u8("Прочее"))
                if imgui.Button(u8("Вернуть стандартный стиль")) then
                    mainIni.style.fon = "[0.07, 0.07, 0.07, 1.00]"
                    mainIni.style.elm = "[0.12, 0.12, 0.12, 1.00]"
                    mainIni.style.stroke = "[0.25, 0.25, 0.26, 0.54]"
                    mainIni.style.text = "[1.00, 1.00, 1.00, 1.00]"
                    mainIni.style.others = "[0.50, 0.50, 0.50, 1.00]"
                    mainIni.style.textChat = "31743"
                    save()
                    menu.fon = imgui.new.float[4](decodeJson(mainIni.style.fon)[1], decodeJson(mainIni.style.fon)[2], decodeJson(mainIni.style.fon)[3], decodeJson(mainIni.style.fon)[4])
                    menu.elm = imgui.new.float[4](decodeJson(mainIni.style.elm)[1], decodeJson(mainIni.style.elm)[2], decodeJson(mainIni.style.elm)[3], decodeJson(mainIni.style.elm)[4])
                    menu.stroke = imgui.new.float[4](decodeJson(mainIni.style.stroke)[1], decodeJson(mainIni.style.stroke)[2], decodeJson(mainIni.style.stroke)[3], decodeJson(mainIni.style.stroke)[4])
                    menu.text = imgui.new.float[4](decodeJson(mainIni.style.text)[1], decodeJson(mainIni.style.text)[2], decodeJson(mainIni.style.text)[3], decodeJson(mainIni.style.text)[4])
                    menu.others = imgui.new.float[4](decodeJson(mainIni.style.others)[1], decodeJson(mainIni.style.others)[2], decodeJson(mainIni.style.others)[3], decodeJson(mainIni.style.others)[4])
                    menu.textChat = imgui.new.float[4](bit.band(bit.rshift(mainIni.style.textChat, 16), 0xFF) / 255, bit.band(bit.rshift(mainIni.style.textChat, 8), 0xFF) / 255, bit.band(mainIni.style.textChat, 0xFF) / 255, bit.band(bit.rshift(mainIni.style.textChat, 24), 0xFF) / 255)
                    imgui.Style()
                end
            elseif menu.count == 6 then
                imgui.Caption(u8("SS Helper"))
                if imgui.Checkbox(u8("Автоматический режим"), menu.auto) then
                    mainIni.sshelper.auto = menu.auto[0]
                    inicfg.save(mainIni, "HELPERUGA.ini")
                end
                imgui.Ques(u8("Автоматически будет делать скриншот и выключать \"темноту\""))
                if imgui.Checkbox(u8("Уведомления"), menu.notif) then
                    mainIni.sshelper.notif = menu.notif[0]
                    inicfg.save(mainIni, "HELPERUGA.ini")
                end
                imgui.Ques(u8("Оповещает вас о загрузке скрипта и других событиях"))
                imgui.PushItemWidth(150)
                if imgui.SliderInt(u8("Задержка"), menu.wait, 0, 20, u8("%d секунд")) then
                    mainIni.sshelper.wait = menu.wait[0] * 1000
                    inicfg.save(mainIni, "HELPERUGA.ini")
                end
                imgui.Ques(u8("Задержка нужна для выключения \"Темноты\", после сделанного скриншота\nРаботает только в автоматическом режиме"))
                if imgui.SliderInt(u8("Размер текста"), menu.fontsize, -3, 5, u8("%d сантиметров")) then
                    mainIni.sshelper.fontsize = menu.fontsize[0]
                    inicfg.save(mainIni, "HELPERUGA.ini")
                end
                imgui.Ques(u8("Меняет размер текста при \"темноте\""))
                if imgui.SliderInt(u8("Количество строк"), menu.pagesize, 10, 20, u8("%d строк")) then
                    mainIni.sshelper.pagesize = menu.pagesize[0]
                    inicfg.save(mainIni, "HELPERUGA.ini")
                end
                imgui.Ques(u8("Меняет количество строк в чате при \"темноте\""))
                local keyEditor = hotkey.KeyEditor("bind", u8("Активация скрипта"))
                if keyEditor then
                    mainIni.sshelper.bind = encodeJson(keyEditor)
                    inicfg.save(mainIni, "HELPERUGA.ini")
                end
            end
            imgui.EndChild()
        end
        imgui.End()
end)

local usedIcons = {
    "ADDRESS_CARD",
    "ROBOT",
    "LOCATION_DOT",
    "BOOKMARK",
    "WALLET",
    "GEAR",
    "CAMERA"
}
function imgui.CenterText(text)
    local width = imgui.GetWindowWidth()
    local calc = imgui.CalcTextSize(text)
    imgui.SetCursorPosX( width / 2 - calc.x / 2 )
    imgui.Text(text)
end


imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    imgui.Style()
    menu.logo = imgui.CreateTextureFromFile(getWorkingDirectory() .. "\\resource\\HELPERUGA\\main_logo.png")
    for i = 1, #json do
        if doesFileExist(getWorkingDirectory() .. "\\resource\\HELPERUGA\\" .. u8:decode(json[i]["file"]) .. ".png") then
            if image[#image + 1] == nil then
                image[#image + 1] = imgui.CreateTextureFromFile(getWorkingDirectory() .. "\\resource\\HELPERUGA\\" .. u8:decode(json[i]["file"]) .. ".png")
            end
        end
    end
    local config = imgui.ImFontConfig()
    config.MergeMode = true
    config.PixelSnapH = true
    local builder = imgui.ImFontGlyphRangesBuilder()
    for _, b in ipairs(usedIcons) do
        builder:AddText(fa(b))
    end
    defaultGlyphRanges1 = imgui.ImVector_ImWchar()
    builder:BuildRanges(defaultGlyphRanges1)
    local mainFont = getFolderPath(0x14) .. '\\trebucbd.ttf'
    local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
    imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(fa.get_font_data_base85("solid"), 14, config, defaultGlyphRanges1[0].Data)
    TitleFont = imgui.GetIO().Fonts:AddFontFromFileTTF(mainFont, 18.0, nil, glyph_ranges)
end)

function imgui.Style()
    imgui.SwitchContext()

    imgui.GetStyle().WindowPadding = imgui.ImVec2(5, 5)
    imgui.GetStyle().FramePadding = imgui.ImVec2(5, 5)
    imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 5)
    imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(2, 2)
    imgui.GetStyle().TouchExtraPadding = imgui.ImVec2(0, 0)
    imgui.GetStyle().IndentSpacing = 0
    imgui.GetStyle().ScrollbarSize = 10
    imgui.GetStyle().GrabMinSize = 10
    imgui.GetStyle().WindowBorderSize = 1
    imgui.GetStyle().ChildBorderSize = 1
    imgui.GetStyle().PopupBorderSize = 1
    imgui.GetStyle().FrameBorderSize = 1
    imgui.GetStyle().TabBorderSize = 1
    imgui.GetStyle().WindowRounding = 8
    imgui.GetStyle().ChildRounding = 3
    imgui.GetStyle().FrameRounding = 8
    imgui.GetStyle().PopupRounding = 8
    imgui.GetStyle().ScrollbarRounding = 8
    imgui.GetStyle().GrabRounding = 8
    imgui.GetStyle().TabRounding = 5
    imgui.GetStyle().WindowPadding = imgui.ImVec2(10, 10)
    imgui.GetStyle().WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
	imgui.GetStyle().ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

    imgui.GetStyle().Colors[imgui.Col.WindowBg] = imgui.ImVec4(decodeJson(mainIni.style.fon)[1], decodeJson(mainIni.style.fon)[2], decodeJson(mainIni.style.fon)[3], decodeJson(mainIni.style.fon)[4])
    imgui.GetStyle().Colors[imgui.Col.FrameBg] = imgui.ImVec4(decodeJson(mainIni.style.elm)[1], decodeJson(mainIni.style.elm)[2], decodeJson(mainIni.style.elm)[3], decodeJson(mainIni.style.elm)[4])
    imgui.GetStyle().Colors[imgui.Col.FrameBgHovered] = imgui.ImVec4(decodeJson(mainIni.style.elm)[1] + 0.1, decodeJson(mainIni.style.elm)[2] + 0.1, decodeJson(mainIni.style.elm)[3] + 0.1, decodeJson(mainIni.style.elm)[4])
    imgui.GetStyle().Colors[imgui.Col.FrameBgActive] = imgui.ImVec4(decodeJson(mainIni.style.elm)[1] + 0.3, decodeJson(mainIni.style.elm)[2] + 0.3, decodeJson(mainIni.style.elm)[3] + 0.3, decodeJson(mainIni.style.elm)[4])
    imgui.GetStyle().Colors[imgui.Col.Border] = imgui.ImVec4(decodeJson(mainIni.style.stroke)[1], decodeJson(mainIni.style.stroke)[2], decodeJson(mainIni.style.stroke)[3], decodeJson(mainIni.style.stroke)[4])
    imgui.GetStyle().Colors[imgui.Col.BorderShadow] = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
    imgui.GetStyle().Colors[imgui.Col.Header] = imgui.ImVec4(decodeJson(mainIni.style.elm)[1], decodeJson(mainIni.style.elm)[2], decodeJson(mainIni.style.elm)[3], decodeJson(mainIni.style.elm)[4])
    imgui.GetStyle().Colors[imgui.Col.HeaderHovered] = imgui.ImVec4(decodeJson(mainIni.style.elm)[1] + 0.1, decodeJson(mainIni.style.elm)[2] + 0.1, decodeJson(mainIni.style.elm)[3] + 0.1, decodeJson(mainIni.style.elm)[4])
    imgui.GetStyle().Colors[imgui.Col.HeaderActive] = imgui.ImVec4(decodeJson(mainIni.style.elm)[1] + 0.3, decodeJson(mainIni.style.elm)[2] + 0.3, decodeJson(mainIni.style.elm)[3] + 0.3, decodeJson(mainIni.style.elm)[4])
    imgui.GetStyle().Colors[imgui.Col.Separator] = imgui.ImVec4(decodeJson(mainIni.style.others)[1], decodeJson(mainIni.style.others)[2], decodeJson(mainIni.style.others)[3], decodeJson(mainIni.style.others)[4])
    imgui.GetStyle().Colors[imgui.Col.SeparatorHovered] = imgui.ImVec4(decodeJson(mainIni.style.others)[1], decodeJson(mainIni.style.others)[2], decodeJson(mainIni.style.others)[3], decodeJson(mainIni.style.others)[4])
    imgui.GetStyle().Colors[imgui.Col.SeparatorActive] = imgui.ImVec4(decodeJson(mainIni.style.others)[1], decodeJson(mainIni.style.others)[2], decodeJson(mainIni.style.others)[3], decodeJson(mainIni.style.others)[4])
    imgui.GetStyle().Colors[imgui.Col.TitleBg] = imgui.ImVec4(decodeJson(mainIni.style.elm)[1], decodeJson(mainIni.style.elm)[2], decodeJson(mainIni.style.elm)[3], decodeJson(mainIni.style.elm)[4])
    imgui.GetStyle().Colors[imgui.Col.TitleBgActive] = imgui.ImVec4(decodeJson(mainIni.style.elm)[1], decodeJson(mainIni.style.elm)[2], decodeJson(mainIni.style.elm)[3], decodeJson(mainIni.style.elm)[4])
    imgui.GetStyle().Colors[imgui.Col.TitleBgCollapsed] = imgui.ImVec4(0.00, 0.00, 0.00, 0.51)
    imgui.GetStyle().Colors[imgui.Col.Button] = imgui.ImVec4(decodeJson(mainIni.style.elm)[1], decodeJson(mainIni.style.elm)[2], decodeJson(mainIni.style.elm)[3], decodeJson(mainIni.style.elm)[4])
    imgui.GetStyle().Colors[imgui.Col.ButtonHovered] = imgui.ImVec4(decodeJson(mainIni.style.elm)[1] + 0.1, decodeJson(mainIni.style.elm)[2] + 0.1, decodeJson(mainIni.style.elm)[3] + 0.1, decodeJson(mainIni.style.elm)[4])
    imgui.GetStyle().Colors[imgui.Col.ButtonActive] = imgui.ImVec4(decodeJson(mainIni.style.elm)[1] + 0.3, decodeJson(mainIni.style.elm)[2] + 0.3, decodeJson(mainIni.style.elm)[3] + 0.3, decodeJson(mainIni.style.elm)[4])
    imgui.GetStyle().Colors[imgui.Col.SliderGrab] = imgui.ImVec4(decodeJson(mainIni.style.elm)[1] + 0.1, decodeJson(mainIni.style.elm)[2] + 0.1, decodeJson(mainIni.style.elm)[3] + 0.1, decodeJson(mainIni.style.elm)[4])
    imgui.GetStyle().Colors[imgui.Col.SliderGrabActive] = imgui.ImVec4(decodeJson(mainIni.style.elm)[1] + 0.3, decodeJson(mainIni.style.elm)[2] + 0.3, decodeJson(mainIni.style.elm)[3] + 0.3, decodeJson(mainIni.style.elm)[4])
    imgui.GetStyle().Colors[imgui.Col.Text] = imgui.ImVec4(decodeJson(mainIni.style.text)[1], decodeJson(mainIni.style.text)[2], decodeJson(mainIni.style.text)[3], decodeJson(mainIni.style.text)[4])
    imgui.GetStyle().Colors[imgui.Col.TextDisabled] = imgui.ImVec4(decodeJson(mainIni.style.others)[1], decodeJson(mainIni.style.others)[2], decodeJson(mainIni.style.others)[3], decodeJson(mainIni.style.others)[4])
    imgui.GetStyle().Colors[imgui.Col.TextSelectedBg] = imgui.ImVec4(decodeJson(mainIni.style.elm)[1] + 0.7, decodeJson(mainIni.style.elm)[2] + 0.7, decodeJson(mainIni.style.elm)[3], decodeJson(mainIni.style.elm)[4])
    imgui.GetStyle().Colors[imgui.Col.CheckMark] = imgui.ImVec4(decodeJson(mainIni.style.text)[1], decodeJson(mainIni.style.text)[2], decodeJson(mainIni.style.text)[3], decodeJson(mainIni.style.text)[4])
    imgui.GetStyle().Colors[imgui.Col.Tab] = imgui.ImVec4(decodeJson(mainIni.style.elm)[1], decodeJson(mainIni.style.elm)[2], decodeJson(mainIni.style.elm)[3], decodeJson(mainIni.style.elm)[4])
    imgui.GetStyle().Colors[imgui.Col.TabHovered] = imgui.ImVec4(decodeJson(mainIni.style.elm)[1] + 0.1, decodeJson(mainIni.style.elm)[2] + 0.1, decodeJson(mainIni.style.elm)[3] + 0.1, decodeJson(mainIni.style.elm)[4])
    imgui.GetStyle().Colors[imgui.Col.TabActive] = imgui.ImVec4(decodeJson(mainIni.style.elm)[1] + 0.1, decodeJson(mainIni.style.elm)[2] + 0.1, decodeJson(mainIni.style.elm)[3] + 0.1, decodeJson(mainIni.style.elm)[4])
end
GradientPB = {}

function imgui.GradientPB(bool, icon, text, duration)
    icon = icon or "#"
    text = text or "None"
    color = imgui.ColorConvertFloat4ToU32(imgui.GetStyle().Colors[imgui.Col.Button])
    duration = 0.50
    local black = imgui.ColorConvertFloat4ToU32(imgui.GetStyle().Colors[imgui.Col.ChildBg])
    local dl = imgui.GetWindowDrawList()
    local p = imgui.GetCursorScreenPos()
    if not GradientPB[text] then
        GradientPB[text] = {time = nil}
    end
    local result = imgui.InvisibleButton(text, imgui.ImVec2(200, 35))
    if result and not bool then
        GradientPB[text].time = os.clock()
    end
    if bool then
        if GradientPB[text].time and (os.clock() - GradientPB[text].time) < duration then
            local wide = (os.clock() - GradientPB[text].time) * (imgui.ImVec2(200, 35).x / duration)
            dl:AddRectFilledMultiColor(imgui.ImVec2(p.x, p.y), imgui.ImVec2(p.x + wide, p.y + imgui.ImVec2(200, 35).y), color, black, black, color)
        else
            dl:AddRectFilledMultiColor(imgui.ImVec2(p.x, p.y), imgui.ImVec2(p.x + imgui.ImVec2(200, 35).x, p.y + imgui.ImVec2(200, 35).y), color, black, black, color)
        end
    else
        if imgui.IsItemHovered() then
            dl:AddRectFilledMultiColor(imgui.ImVec2(p.x, p.y), imgui.ImVec2(p.x + imgui.ImVec2(200, 35).x, p.y + imgui.ImVec2(200, 35).y), color, black, black, color)
        end
    end
    imgui.SameLine(10); imgui.SetCursorPosY(imgui.GetCursorPos().y + 9)
    if bool then
        imgui.Text((" "):rep(3) .. icon)
        imgui.SameLine(60)
        imgui.Text(text)
    else
        imgui.TextDisabled((" "):rep(3) .. icon)
        imgui.SameLine(60)
        imgui.TextDisabled(text)
    end
    imgui.SetCursorPosY(imgui.GetCursorPos().y - 9)
    return result
end

function imgui.Caption(name, func)
    imgui.SetCursorPosX(imgui.GetWindowWidth() / 2 - imgui.CalcTextSize("HELPERUGA | " .. name).x / 2)
    imgui.Text("HELPERUGA | " .. name)
    imgui.SameLine(480)
    if imgui.InvisibleButton("##closed", imgui.ImVec2(17, 17)) then
        menu.window[0] = false
        if func ~= nil then func() end
    end
    imgui.SameLine(486)
    if not imgui.IsItemHovered() then
        imgui.Text("X")
    else
        imgui.TextDisabled("X")
    end
    imgui.Separator()
end

function imgui.Ques(text)
    imgui.SameLine()
    imgui.TextDisabled("(?)")
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.TextUnformatted(text)
        imgui.EndTooltip()
    end
end

function join_argb(a, r, g, b)
    local argb = b
    argb = bit.bor(argb, bit.lshift(g, 8))
    argb = bit.bor(argb, bit.lshift(r, 16))
    argb = bit.bor(argb, bit.lshift(a, 24))
    return argb
end

function msg(text) sampAddChatMessage("[HELPERUGA] {FFFFFF}" .. text, mainIni.style.textChat) end
function save() inicfg.save(mainIni, "HELPERUGA.ini") end
function msg1(text)
    if mainIni.sshelper.notif then
        sampAddChatMessage("[HELPERUGA] {FFFFFF}" .. text, mainIni.style.textChat)
    end
end
function asyncHttpRequest(method, url, args, resolve, reject)
    local request_thread = effil.thread(function(method, url, args)
        local requests = require("requests")
        local result, response = pcall(requests.request, method, url, args)
        if result then
            response.json, response.xml = nil, nil
            return true, response
        else
            return false, response
        end
    end)(method, url, args)

    if not resolve then
        resolve = function() end
    end
    if not reject then
        reject = function() end
    end
    lua_thread.create(function()
        local runner = request_thread
        while true do
            local status, err = runner:status()
            if not err then
                if status == "completed" then
                    local result, response = runner:get()
                    if result then
                        resolve(response)
                    else
                        reject(response)
                    end
                    return
                elseif status == "canceled" then
                    return reject(status)
                end
            else
                return reject(err)
            end
            wait(0)
        end
    end)
end

function sampev.onSendPlayerSync(data)
	if bit.band(data.keysData, 0x28) == 0x28 and menu.antibh[0] then
		data.keysData = bit.bxor(data.keysData, 0x20)
	end
end