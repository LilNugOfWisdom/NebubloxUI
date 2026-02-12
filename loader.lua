-- // UNIVERSAL HUB LOADER //
-- // Optimized by Gemini & Antigravity //

-- [1] PREVENT MULTIPLE EXECUTIONS
if getgenv().UniversalHubLoaded then 
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Hub Already Loaded",
            Text = "The script is already running.",
            Duration = 3
        })
    end)
    return 
end

-- [2] SERVICES & VARS
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local UniverseId = game.GameId

-- [3] LIBRARY LOADER
local ANUI_URL = "https://raw.githubusercontent.com/ANHub-Script/ANUI/refs/heads/main/dist/main.lua"
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
    
    -- Fallback: Try without the "/Scripts/" folder if it was included
    if not content and url:find("/Scripts/") then
        local rootUrl = url:gsub("/Scripts/", "/")
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
    [98199457453897] = { Name = "[UPD 1] Anime Storm 2", Url = "https://raw.githubusercontent.com/LilNugOfWisdom/NebubloxUI/main/Scripts/anime_storm_sim2_anui.lua" },
    [133898125416947] = { Name = "[Release🔥] Anime Creatures💥", Url = "https://raw.githubusercontent.com/LilNugOfWisdom/NebubloxUI/main/Scripts/Anime_Creatures_Anui.lua" },

}

-- [6] AUTO-DETECTION LOGIC
local DetectedGame = GameIds[PlaceId] or GameIds[UniverseId]

if DetectedGame then
    SafeNotify({Title = "Universal Hub", Content = "Detected: " .. DetectedGame.Name, Icon = "check", Duration = 3})
    task.wait(0.5)
    LoadScript(DetectedGame.Url)
else
    -- [7] MANUAL SELECTION GUI
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
            setclipboard("https://discord.gg/kgu3WXGg5m")
            SafeNotify({Title = "Discord", Content = "Invite copied!", Icon = "check", Duration = 3})
        end
    })
end
