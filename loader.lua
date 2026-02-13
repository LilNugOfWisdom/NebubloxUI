-- [1] SCRIPT KILLER / RELOAD LOGIC
if getgenv().Nebublox_Window then
    pcall(function() getgenv().Nebublox_Window:Destroy() end)
    getgenv().Nebublox_Window = nil
end

if getgenv().UniversalHubLoaded then
    getgenv().UniversalHubLoaded = false
end

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local function CleanupGui(name)
    if CoreGui:FindFirstChild(name) then CoreGui[name]:Destroy() end
    if Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui") and Players.LocalPlayer.PlayerGui:FindFirstChild(name) then
        Players.LocalPlayer.PlayerGui[name]:Destroy()
    end
end
CleanupGui("NebubloxAuth")
CleanupGui("UniversalHub")

-- // UNIVERSAL HUB LOADER //
-- // Optimized by Gemini & Antigravity //

-- [1] PREVENT MULTIPLE EXECUTIONS
-- [1] PREVENT DUPLICATES / ALLOW RELOAD
if getgenv().Nebublox_Window then
    pcall(function() getgenv().Nebublox_Window:Destroy() end)
    getgenv().Nebublox_Window = nil
end

if getgenv().UniversalHubLoaded then 
    getgenv().UniversalHubLoaded = false -- Reset for reload
end

-- [2] SERVICES & VARS
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local UniverseId = game.GameId

-- [3] LIBRARY LOADER
local ANUI_URL = "https://raw.githubusercontent.com/LilNugOfWisdom/NebubloxUIUI/main/Library/anui_source.lua"
local success, libraryCode = pcall(function() return game:HttpGet(ANUI_URL) end)

if not success or not libraryCode or libraryCode:find("404: Not Found") or libraryCode:find("<!DOCTYPE html>") then
    warn("[UniversalHub] Failed to fetch UI Library from:", ANUI_URL)
    return
end

local libFunc, libErr = loadstring(libraryCode)
if not libFunc then
    warn("[UniversalHub] UI Library Syntax Error:", libErr)
    return
end

local ANUI = libFunc()
getgenv().UniversalHubLoaded = true -- Only set after successful init

-- [4] HELPER FUNCTIONS
local function SafeNotify(data)
    task.defer(function() 
        pcall(function() ANUI:Notify(data) end) 
    end)
end

local function LoadScript(url)
    SafeNotify({Title = "Fetching...", Content = "Downloading script data...", Icon = "download", Duration = 2})
    
    -- [SMART FETCHER]
    -- Tries the provided URL, and if it fails, tries the root directory as a fallback
    local function Fetch(targetUrl)
        local success, content = pcall(function() return game:HttpGet(targetUrl) end)
        if success and content and not content:find("404: Not Found") and not content:find("<!DOCTYPE html>") and #content > 100 then
            return content
        end
        return nil, content -- Return error content for debugging
    end

    local content, rawError = Fetch(url)
    
    -- Fallback: Try without the "/games/" folder if it was included
    if not content and url:find("/games/") then
        local rootUrl = url:gsub("/games/", "/")
        warn("[UniversalHub] fallback: trying root URL:", rootUrl)
        content, rawError = Fetch(rootUrl)
    end
    
    if content then
        local func, err = loadstring(content)
        if func then
            task.spawn(function()
                local runSuccess, runError = pcall(func)
                if not runSuccess then
                    warn("[UniversalHub] Runtime Error:", runError)
                    SafeNotify({Title = "Runtime Error", Content = "Script crashed. Check F9 console.", Icon = "alert-triangle", Duration = 5})
                end
            end)
        else
            warn("[UniversalHub] Syntax Error:", err)
            SafeNotify({Title = "Syntax Error", Content = "Code contains errors. Check F9.", Icon = "alert-octagon", Duration = 5})
        end
    else
        warn("[UniversalHub] Connection Failed to:", url)
        warn("[UniversalHub] Error returned:", tostring(rawError))
        SafeNotify({Title = "Connection Error", Content = "Failed to reach GitHub. Check F9 console!", Icon = "wifi-off", Duration = 7})
    end
end

-- [5] GAME CONFIGURATION
-- format: [ID] = { Name = "...", Url = "..." }
local GameIds = {
    [98199457453897] = { Name = "[UPD 1] Anime Storm 2", Url = "https://raw.githubusercontent.com/LilNugOfWisdom/NebubloxUIUI/main/Scripts/anime_storm_sim2_anui.lua" },
    [133898125416947] = { Name = "[Release≡ƒöÑ] Anime Creatures≡ƒÆÑ", Url = "https://raw.githubusercontent.com/LilNugOfWisdom/NebubloxUIUI/main/Scripts/Anime_Creatures_Anui.lua" },
    [136063393518705] = { Name = "[Release] Anime Destroyers", Url = "https://raw.githubusercontent.com/LilNugOfWisdom/NebubloxUIUI/main/Scripts/anime_destroyers_anui.lua" },
    [15498808459] = { Name = "Anime Capture", Url = "https://raw.githubusercontent.com/LilNugOfWisdom/NebubloxUIUI/main/Scripts/anime_capture_anui.lua" }
}

-- [6] KEY SYSTEM INTEGRATION
local KeySystem = {}
KeySystem.__index = KeySystem

-- Configuration
local API_URL_KEY = "https://darkmatterv1.onrender.com/api/verify_key"
local SETTINGS_FILE_KEY = "nebublox_key.data"
local DISCORD_INVITE_KEY = "https://discord.gg/T2vw3QuJ9K"

function KeySystem.new()
    local self = setmetatable({}, KeySystem)
    self.Key = ""
    self.Tier = "Free"
    self.IsVerified = false
    return self
end

function KeySystem:LoadKey()
    if isfile and isfile(SETTINGS_FILE_KEY) then
        self.Key = readfile(SETTINGS_FILE_KEY)
        return true
    end
    return false
end

function KeySystem:SaveKey(key)
    if writefile then
        writefile(SETTINGS_FILE_KEY, key)
        self.Key = key
    end
end

function KeySystem:Validate(inputKey)
    local keyToCheck = inputKey or self.Key
    
    if keyToCheck then
        keyToCheck = keyToCheck:gsub("%s+", "")
    end

    if not keyToCheck or keyToCheck == "" then 
        return false, "No key provided" 
    end

    local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    
    if not httpRequest then
        return false, "Executor unsupported"
    end

    -- URL List (Localhost Priority for Dev, then Render)
    local urls = {
        "http://127.0.0.1:10000/api/verify_key",
        "https://darkmatterv1.onrender.com/api/verify_key"
    }

    local lastError = ""

    for _, url in ipairs(urls) do
        local success, response = pcall(function()
            return httpRequest({
                Url = url .. "?key=" .. keyToCheck .. "&hwid=" .. (gethwid and gethwid() or game:GetService("RbxAnalyticsService"):GetClientId()),
                Method = "GET"
            })
        end)

        if success and response.StatusCode == 200 then
            local data = HttpService:JSONDecode(response.Body)
            if data.valid then
                self.IsVerified = true
                self.Tier = data.tier
                self:SaveKey(keyToCheck)
                return true, "Success"
            else
                -- If server responds but key is invalid, don't try next server, just return invalid
                return false, data.message or "Invalid Key"
            end
        else
            lastError = "Connection Failed"
        end
    end

    return false, lastError .. " (Is Bot/Render online?)"
end

function KeySystem:ShowUI(onSuccess)
    -- 1. Auto-Login Check
    if self:LoadKey() then
        SafeNotify({Title = "Nebublox", Content = "Verifying saved key...", Icon = "loader", Duration = 2})
        
        local valid, msg = self:Validate()
        if valid then
            SafeNotify({Title = "Welcome Back", Content = "Logged in as " .. tostring(self.Tier) .. " User", Icon = "check", Duration = 5})
            if onSuccess then onSuccess() end
            return
        else
             SafeNotify({Title = "Auth Failed", Content = "Saved key expired or invalid.", Icon = "alert-triangle", Duration = 3})
        end
    end

    -- 2. Create Login Window
    local Window = ANUI:CreateWindow({
        Title = "Nebublox Auth",
        Author = "v1.0",
        Folder = "NebubloxAuth",
        Icon = "rbxassetid://121698194718505", 
        IconSize = 44,
        Theme = "Dark",
        Transparent = false,
        SideBarWidth = 0,
    })

    getgenv().Nebublox_Window = Window -- [TRACK WINDOW FOR RELOAD]
    
    local MainTab = Window:Tab({ Title = "Key System", Icon = "key", SidebarProfile = false })
    local Section = MainTab:Section({ Title = "Authentication", Icon = "lock", Opened = true })
    
    Section:Paragraph({
        Title = "Instructions",
        Content = "Join our Discord and use /verify to generate your key."
    })
    
    local KeyInput = ""
    
    Section:TextBox({
        Title = "License Key",
        Default = "",
        Placeholder = "Paste Key (BLOX-...)",
        Callback = function(text)
            KeyInput = text
        end
    })
    
    Section:Button({
        Title = "Verify Key",
        Callback = function()
            if KeyInput == "" then
                SafeNotify({Title = "Input Error", Content = "Please paste a key first!", Icon = "alert-circle", Duration = 3})
                return
            end
            
            SafeNotify({Title = "Verifying", Content = "Connecting to server...", Icon = "loader", Duration = 2})
            
            local valid, msg = self:Validate(KeyInput)
            
            if valid then
                SafeNotify({Title = "Success", Content = "Access Granted!", Icon = "check", Duration = 3})
                task.wait(0.5)
                Window:Destroy() -- Close UI
                if onSuccess then onSuccess() end
            else
                SafeNotify({Title = "Denied", Content = msg, Icon = "x", Duration = 4})
            end
        end
    })
    
    Section:Button({
        Title = "Copy Discord Link",
        Callback = function()
            setclipboard(DISCORD_INVITE_KEY)
            SafeNotify({Title = "Copied", Content = "Invite link copied to clipboard!", Icon = "link", Duration = 2})
        end
    })
end

-- [7] MAIN HUB LOGIC (Wrapped)
local function StartHub()
    local DetectedGame = GameIds[PlaceId] or GameIds[UniverseId]

    if DetectedGame then
        SafeNotify({Title = "Universal Hub", Content = "Detected: " .. DetectedGame.Name, Icon = "check", Duration = 3})
        task.wait(0.5)
        LoadScript(DetectedGame.Url)
    else
        -- MANUAL SELECTION GUI
        local Window = ANUI:CreateWindow({
            Title = "Universal Hub",
            Author = "by He Who Remains",
            Folder = "UniversalHub",
            Icon = "rbxthumb://type=Asset&id=132367447015620&w=150&h=150", 
            IconSize = 44,
            Theme = "Dark",
            Transparent = false,
            SideBarWidth = 200,
        HasOutline = true,
        })

        getgenv().Nebublox_Window = Window -- [TRACK WINDOW FOR RELOAD]
        
        -- >> TAB: ABOUT
        local MainTab = Window:Tab({ Title = "About", Icon = "info" })
        
        -- Banner Injection
        local BannerSection = MainTab:Section({ Title = "", Icon = "", Opened = true })
        BannerSection:Paragraph({ Title = "Loading Banner...", Content = "" })
        
        task.defer(function()
            task.wait(1) -- Allow UI to render
            local imgId = "rbxthumb://type=Asset&id=132367447015620&w=768&h=432"
            
            -- Optimized Finder
            local function InjectBanner()
                local targets = {LocalPlayer:FindFirstChild("PlayerGui"), CoreGui}
                for _, root in ipairs(targets) do
                    if not root then continue end
                    for _, obj in ipairs(root:GetDescendants()) do
                        if obj:IsA("TextLabel") and obj.Text == "Loading Banner..." then
                            local paragraph = obj.Parent
                            local section = paragraph and paragraph.Parent
                            if section then
                                local frame = Instance.new("ImageLabel")
                                frame.Name = "Banner"
                                frame.Size = UDim2.new(1, 0, 0, 150)
                                frame.Position = paragraph.Position
                                frame.BackgroundTransparency = 1
                                frame.Image = imgId
                                frame.ScaleType = Enum.ScaleType.Crop
                                frame.Parent = section
                                
                                pcall(function() paragraph:Destroy() end)
                                return true
                            end
                        end
                    end
                end
            end
            pcall(InjectBanner)
        end)

        local InfoSection = MainTab:Section({ Title = "Information", Icon = "shield", Opened = true })
        InfoSection:Paragraph({
            Title = "Game Not Detected",
            Content = "We couldn't auto-load a script for this game.\nPlease select a game from the list or copy the IDs below to request support."
        })
        
        -- [CHANGELOG SECTION]
        local ChangeLogSection = MainTab:Section({ Title = "Changelog (v1.1)", Icon = "file-text", Opened = false })
        ChangeLogSection:Paragraph({
            Title = "Latest Updates",
            Content = "ΓÇó Added Key System Security\nΓÇó UI Overhaul & Optimization\nΓÇó Fixed Anime Storm 2 Script\nΓÇó Added 'Save to Profile' (Auto-Login)"
        })
        
        -- >> TAB: GAMES
        local GamesTab = Window:Tab({ Title = "Games List", Icon = "gamepad-2" })
        
        local UtilitySection = GamesTab:Section({ Title = "Developer Tools", Icon = "tool", Opened = false })
        UtilitySection:Button({
            Title = "Copy Place ID (" .. tostring(PlaceId) .. ")",
            Callback = function()
                setclipboard(tostring(PlaceId))
                SafeNotify({Title = "Copied", Content = "Place ID copied to clipboard", Icon = "copy", Duration = 2})
            end
        })
        UtilitySection:Button({
            Title = "Copy Universe ID (" .. tostring(UniverseId) .. ")",
            Callback = function()
                setclipboard(tostring(UniverseId))
                SafeNotify({Title = "Copied", Content = "Universe ID copied to clipboard", Icon = "copy", Duration = 2})
            end
        })

        local GamesSection = GamesTab:Section({ Title = "Available Scripts", Icon = "list", Opened = true })
        
        -- Sort games alphabetically
        local sortedGames = {}
        for id, data in pairs(GameIds) do 
            table.insert(sortedGames, {id = id, data = data}) 
        end
        table.sort(sortedGames, function(a,b) return a.data.Name < b.data.Name end)
        
        for _, entry in ipairs(sortedGames) do
            GamesSection:Button({
                Title = entry.data.Name,
                Callback = function()
                    SafeNotify({Title = "Loading...", Content = entry.data.Name, Icon = "download", Duration = 2})
                    task.spawn(function()
                        -- [FIX] Safe Non-Blocking Destroy
                        pcall(function() Window:Destroy() end)
                    end)
                    LoadScript(entry.data.Url)
                end
            })
        end
        
        local SocialSection = MainTab:Section({ Title = "Socials", Icon = "users", Opened = true })
        SocialSection:Button({
            Title = "Join Discord Community",
            Callback = function()
                setclipboard("https://discord.gg/T2vw3QuJ9K")
                SafeNotify({Title = "Discord", Content = "Invite copied!", Icon = "check", Duration = 3})
            end
        })
    end
end

-- [8] INITIATE KEY SYSTEM
local Auth = KeySystem.new()
Auth:ShowUI(StartHub)
