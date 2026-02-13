-- // NEBUBLOX UNIVERSAL HUB //
-- // Optimized & Branded for LilNugOfWisdom //

-- [0] COMPATIBILITY PATCH (Fixes "nil value" errors on some executors)
local getgenv = getgenv or function() return _G end

-- [1] KILL PREVIOUS INSTANCE (allows re-execution without rejoining)
if getgenv().NebubloxLoaded then 
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Nebublox",
            Text = "Reloading...",
            Duration = 2
        })
    end)
    -- Kill old session
    getgenv().NebuBlox_Running = false
    getgenv().NebuBlox_SessionID = 0
    task.wait(0.3)
    -- Destroy old UI
    pcall(function()
        local core = game:GetService("CoreGui")
        for _, name in ipairs({"Nebublox", "ANUI", "NebubloxAuth", "NebuEnemyList"}) do
            local gui = core:FindFirstChild(name)
            if gui then gui:Destroy() end
        end
        local pgui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
        if pgui then
            for _, name in ipairs({"Nebublox", "ANUI"}) do
                local gui = pgui:FindFirstChild(name)
                if gui then gui:Destroy() end
            end
        end
    end)
    getgenv().NebubloxLoaded = nil
    getgenv().ANUI_Window = nil
end

-- [2] SERVICES & VARS
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local UniverseId = game.GameId

-- [3] LIBRARY LOADER
local ANUI_URL = "https://raw.githubusercontent.com/ANHub-Script/ANUI/refs/heads/main/dist/main.lua"
local success, libraryCode = pcall(function() return game:HttpGet(ANUI_URL) end)

if not success or not libraryCode then
    warn("[Nebublox] Failed to load UI Library.")
    return
end

local ANUI = loadstring(libraryCode)()
getgenv().NebubloxLoaded = true 

-- [4] HELPER FUNCTIONS
local function SafeNotify(data)
    task.defer(function() 
        pcall(function() ANUI:Notify(data) end) 
    end)
end

local function LoadScript(url)
    SafeNotify({Title = "Nebublox Cloud", Content = "Fetching script data...", Icon = "cloud-download", Duration = 2})
    
    local function Fetch(targetUrl)
        -- [CACHE BUSTING] Append timestamp to force fresh fetch
        local freshUrl = targetUrl .. "?t=" .. tostring(os.time())
        local s, c = pcall(function() return game:HttpGet(freshUrl) end)
        if s and c and not c:find("404: Not Found") and #c > 50 then return c end
        return nil
    end

    local content = Fetch(url)
    
    if content then
        local func, err = loadstring(content)
        if func then
            task.spawn(function()
                local runSuccess, runError = pcall(func)
                if not runSuccess then
                    warn("[Nebublox] Script Error:", runError)
                    SafeNotify({Title = "Execution Failed", Content = "Check Console (F9)", Icon = "alert-triangle", Duration = 4})
                end
            end)
        else
            SafeNotify({Title = "Syntax Error", Content = "The script is broken.", Icon = "x-octagon", Duration = 4})
        end
    else
        SafeNotify({Title = "Connection Failed", Content = "Could not reach GitHub.", Icon = "wifi-off", Duration = 4})
    end
end

-- [5] GAME CONFIGURATION
-- [UPDATED] Changed gamr46 -> LilNugOfWisdom
local GameIds = {
    [98199457453897] = { Name = "Anime Storm 2", Url = "https://raw.githubusercontent.com/LilNugOfWisdom/NebubloxUI/main/Scripts/anime_storm_sim2_anui.lua" },
    [136063393518705] = { Name = "Anime Destroyers", Url = "https://raw.githubusercontent.com/LilNugOfWisdom/NebubloxUI/main/Scripts/anime_destroyers_anui.lua" },
    [133898125416947] = { Name = "Anime Creatures", Url = "https://raw.githubusercontent.com/LilNugOfWisdom/NebubloxUI/main/Scripts/Anime_Creatures_Anui.lua" },
}

-- [6] AUTO-DETECTION LOGIC
local DetectedGame = GameIds[PlaceId] or GameIds[UniverseId]

if DetectedGame then
    SafeNotify({Title = "Nebublox", Content = "Injecting: " .. DetectedGame.Name, Icon = "zap", Duration = 3})
    task.wait(0.5)
    LoadScript(DetectedGame.Url)
else
    -- [7] MANUAL SELECTION GUI
    local Window = ANUI:CreateWindow({
        Title = "Nebublox Hub",
        Author = "Universal",
        Folder = "Nebublox",
        Icon = "rbxthumb://type=Asset&id=132367447015620&w=150&h=150", 
        IconSize = 44,
        Theme = "Dark",
        Transparent = false,
        SideBarWidth = 200,
        HasOutline = true,
    })
    
    -- >> TAB: HOME
    local MainTab = Window:Tab({ Title = "Home", Icon = "home" })
    
    -- Banner Injection
    local BannerSection = MainTab:Section({ Title = "", Icon = "", Opened = true })
    BannerSection:Paragraph({ Title = "Loading Banner...", Content = "" })
    
    task.defer(function()
        task.wait(0.8)
        local imgId = "rbxthumb://type=Asset&id=132367447015620&w=768&h=432"
        
        local function InjectBanner()
            local targets = {LocalPlayer:FindFirstChild("PlayerGui"), CoreGui}
            for _, root in ipairs(targets) do
                if not root then continue end
                for _, obj in ipairs(root:GetDescendants()) do
                    if obj:IsA("TextLabel") and obj.Text == "Loading Banner..." then
                        local p = obj.Parent
                        if p and p.Parent then
                            local f = Instance.new("ImageLabel")
                            f.Name = "NebubloxBanner"
                            f.Size = UDim2.new(1, 0, 0, 150)
                            f.Position = p.Position
                            f.BackgroundTransparency = 1
                            f.Image = imgId
                            f.ScaleType = Enum.ScaleType.Crop
                            f.Parent = p.Parent
                            pcall(function() p:Destroy() end)
                            return true
                        end
                    end
                end
            end
        end
        pcall(InjectBanner)
    end)

    local InfoSection = MainTab:Section({ Title = "Welcome", Icon = "info", Opened = true })
    
    InfoSection:Paragraph({
        Title = "About Nebublox",
        Content = "Welcome to Nebublox! We are a dedicated team of developers redefining the Roblox experience.\n\nWe build powerful, optimized, and universal scripts to help you play by your own rules. Select a game below to begin."
    })
    
    -- >> TAB: GAMES
    local GamesTab = Window:Tab({ Title = "Games", Icon = "gamepad-2" })
    
    local UtilitySection = GamesTab:Section({ Title = "Tools", Icon = "tool", Opened = false })
    UtilitySection:Button({
        Title = "Copy Game ID",
        Callback = function() 
            setclipboard(tostring(game.GameId)) 
            SafeNotify({Title = "Copied", Content = "Universe ID copied!", Icon = "check", Duration = 2})
        end
    })

    local GamesSection = GamesTab:Section({ Title = "Supported Games", Icon = "list", Opened = true })
    
    local sortedGames = {}
    for id, data in pairs(GameIds) do table.insert(sortedGames, data) end
    table.sort(sortedGames, function(a,b) return a.Name < b.Name end)
    
    for _, data in ipairs(sortedGames) do
        GamesSection:Button({
            Title = data.Name,
            Callback = function()
                SafeNotify({Title = "Nebublox", Content = "Loading " .. data.Name, Icon = "download", Duration = 2})
                task.spawn(function() pcall(function() Window:Destroy() end) end)
                LoadScript(data.Url)
            end
        })
    end
    
    local SocialSection = MainTab:Section({ Title = "Community", Icon = "users", Opened = true })
    
    -- [UPDATED] New Discord Link
    SocialSection:Button({
        Title = "Join Discord Server",
        Callback = function()
            setclipboard("https://discord.gg/T2vw3QuJ9K")
            SafeNotify({Title = "Discord", Content = "Invite link copied!", Icon = "check", Duration = 3})
        end
    })
end
