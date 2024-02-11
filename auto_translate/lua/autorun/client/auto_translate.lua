local target_language = CreateConVar("cl_translator_target_language", "ru", FCVAR_ARCHIVE)
local target_send_language = CreateConVar("cl_translator_send_target_language", "ru", FCVAR_ARCHIVE)

local delay = CreateConVar("cl_translator_delay", "5", FCVAR_ARCHIVE)
local typee = CreateConVar("cl_translator_type", "google", FCVAR_ARCHIVE, "libre - libretranslate.com (use a selfhosted instance), google - translate.google.com")
local libreurl = CreateConVar("cl_translator_libreurl", "http://localhost:5000/", FCVAR_ARCHIVE, "The URL to use when using libre translator type.")
local librekey = CreateConVar("cl_translator_librekey", "", FCVAR_ARCHIVE, "Depending on what instance you use, you might or not need to configure this.")

local chat_prefix = CreateConVar("cl_translator_chat_prefix", "!at", FCVAR_ARCHIVE, "Prefix with which you auto translate your own text for others to see.")

local translation_queue = {}
local translation_send_queue = {}

local wait = 0
local wait_send = 0

hook.Add("Think", "auto_translate", function() 
    wait = math.max(0, wait - FrameTime())

    if wait <= 0 then
        local thing = table.remove(translation_queue, 1)

        if not thing then return end

        local ply = thing[1]
        local text = thing[2]

        wait = delay:GetFloat()

        if typee:GetString() == "google" then
            local function on_fail(err)
                print(err)
                chat.AddText(Color(100, 200, 200), "[Failed Translation. Random error]")
            end
            
            local function on_success(body, size, headers, code)
                local data = util.JSONToTable(body)

                if not data then
                    print(body)
                    chat.AddText(Color(100, 200, 200), "[Failed Translation. No data?] ", Color(150, 150, 150), ply:Name(), ": ", text)
                    return 
                end

                if not data["sentences"] then
                    print(body)
                    chat.AddText(Color(100, 200, 200), "[Failed Translation. No sentences.] ", Color(150, 150, 150), ply:Name(), ": ", text)
                    return 
                end

                local translation = data["sentences"][1]["trans"]
                local source_lang = data["src"]
        
                chat.AddText(Color(100, 200, 200), "[Source: "..source_lang.."] ", Color(150, 150, 150), ply:Name(), ": ", translation)
            end

            http.Post("https://translate.google.com/translate_a/single?client=at&dt=t&dt=rm&dj=1", {
                ["sl"] = "auto",
                ["tl"] = target_language:GetString(),
                ["q"] = text
            }, on_success, on_fail, {["Content-Type"] = "application/x-www-form-urlencoded;charset=utf-8"})
        elseif typee:GetString() == "libre" then
            local function on_fail(err)
                print(err)
                chat.AddText(Color(100, 200, 200), "[Failed Translation. Random error]")
            end
            
            local function on_success(body, size, headers, code)
                local data = util.JSONToTable(body)

                if not data then
                    print(body)
                    chat.AddText(Color(100, 200, 200), "[Failed Translation. No data?] ", Color(150, 150, 150), ply:Name(), ": ", text)
                    return 
                end

                if not data["translatedText"] or not data["detectedLanguage"] then
                    print(body)
                    chat.AddText(Color(100, 200, 200), "[Failed Translation. No translatedText or detectedLanguage.] ", Color(150, 150, 150), ply:Name(), ": ", text)
                    return 
                end

                local translation = data["translatedText"]
                local source_lang = data["detectedLanguage"]["language"]
        
                chat.AddText(Color(100, 200, 200), "[Source: "..source_lang.."] ", Color(150, 150, 150), ply:Name(), ": ", translation)
            end

            http.Post(libreurl:GetString(), {
                ["q"] = text,
                ["source"] = "auto",
                ["target"] = target_language:GetString(),
                ["format"] = "text",
                ["api_key"] = librekey:GetString()
            }, on_success, on_fail, {["Content-Type"] = "application/json"})
        else
            print("Invalid translator type... noob")
        end
    end
end)

hook.Add("Think", "auto_translate_send", function()
    wait_send = math.max(0, wait_send - FrameTime())

    if wait_send <= 0 then 
        local text = table.remove(translation_send_queue, 1)

        if not text then return end

        local ply = LocalPlayer()

        wait_send = delay:GetFloat()

        if typee:GetString() == "google" then
            local function on_fail(err)
                print(err)
                chat.AddText(Color(100, 200, 200), "[Failed Translation. Random error]")
            end
            
            local function on_success(body, size, headers, code)
                local data = util.JSONToTable(body)

                if not data then
                    print(body)
                    chat.AddText(Color(100, 200, 200), "[Failed Translation. No data?] ", Color(150, 150, 150), ply:Name(), ": ", text)
                    return 
                end

                if not data["sentences"] then
                    print(body)
                    chat.AddText(Color(100, 200, 200), "[Failed Translation. No sentences.] ", Color(150, 150, 150), ply:Name(), ": ", text)
                    return 
                end

                local translation = data["sentences"][1]["trans"]

                timer.Simple(1, function() 
                    LocalPlayer():ConCommand("say "..utf8.force(translation))
                end)
            end

            http.Post("https://translate.google.com/translate_a/single?client=at&dt=t&dt=rm&dj=1", {
                ["sl"] = "auto",
                ["tl"] = target_send_language:GetString(),
                ["q"] = text
            }, on_success, on_fail, {["Content-Type"] = "application/x-www-form-urlencoded;charset=utf-8"})
        elseif typee:GetString() == "libre" then
            local function on_fail(err)
                print(err)
                chat.AddText(Color(100, 200, 200), "[Failed Translation. Random error]")
            end
            
            local function on_success(body, size, headers, code)
                local data = util.JSONToTable(body)

                if not data then
                    print(body)
                    chat.AddText(Color(100, 200, 200), "[Failed Translation. No data?] ", Color(150, 150, 150), ply:Name(), ": ", text)
                    return 
                end

                if not data["translatedText"] or not data["detectedLanguage"] then
                    print(body)
                    chat.AddText(Color(100, 200, 200), "[Failed Translation. No translatedText or detectedLanguage.] ", Color(150, 150, 150), ply:Name(), ": ", text)
                    return 
                end

                local translation = data["translatedText"]

                timer.Simple(1, function() 
                    LocalPlayer():ConCommand("say "..utf8.force(translation))
                end)
            end

            http.Post(libreurl:GetString(), {
                ["q"] = text,
                ["source"] = "auto",
                ["target"] = target_send_language:GetString(),
                ["format"] = "text",
                ["api_key"] = librekey:GetString()
            }, on_success, on_fail, {["Content-Type"] = "application/json"})
        else
            print("Invalid translator type... noob")
        end
    end
end)

hook.Add("OnPlayerChat", "auto_translate", function(ply, text, is_teamchat, is_dead) 
    if string.len(string.Replace(text, " ", "")) <= 0 then return end

    if not IsValid(ply) then return end

    if ply == LocalPlayer() and string.StartsWith(text, chat_prefix:GetString()) then
        text = string.TrimLeft(text, chat_prefix:GetString())
        table.insert(translation_send_queue, text)

        return true
    elseif ply == LocalPlayer() then
        return
    end

    table.insert(translation_queue, {ply, text})
end)