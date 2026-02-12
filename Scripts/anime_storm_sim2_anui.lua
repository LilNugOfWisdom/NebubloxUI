-- // NEBUBLOX | ANIME STORM SIMULATOR 2 (v3.1: ERROR FIX) //
print("/// NEBUBLOX v3.1 LOADED - " .. os.date("%X") .. " ///")
-- // UI Library: ANUI //

-- // 0. SESSION & CLEANUP //
local SessionID = tick()
getgenv().NebuBlox_SessionID = SessionID

local function SafeDisconnect(conn)
    if conn then pcall(function() conn:Disconnect() end) end
end

if getgenv().NebuBlox_Loaded then
    getgenv().NebuBlox_Running = false
    task.wait(0.25)
    
    SafeDisconnect(getgenv().NebuBlox_TrialConnection)
    SafeDisconnect(getgenv().NebuBlox_BossRushConnection)
    SafeDisconnect(getgenv().NebuBlox_BossRushUIConnection)
    SafeDisconnect(getgenv().NebuBlox_RenderSteppedConnection)
    SafeDisconnect(getgenv().NebuBlox_MovementConnection)
    SafeDisconnect(getgenv().NebuBlox_NoClipConnection)
    
    -- [FIX] Removed 'ANUI_Window:Destroy()' to prevent Library crash (Line 13559 error)
    pcall(function()
        getgenv().ANUI_Window = nil -- Just clear the variable
        
        local core = game:GetService("CoreGui")
        local uis = {"Nebublox", "ANUI", "Orion", "Shadow", "ScreenGui", "NebuEnemyList"}
        for _, n in ipairs(uis) do
            local f = core:FindFirstChild(n)
            if f then f:Destroy() end
        end
        if player.PlayerGui:FindFirstChild("Nebublox") then player.PlayerGui.Nebublox:Destroy() end
    end)
    
    getgenv().NebuBlox_TrialConnection = nil
    getgenv().NebuBlox_BossRushConnection = nil
    getgenv().NebuBlox_BossRushUIConnection = nil
    getgenv().NebuBlox_CurrentTarget = nil
end

getgenv().NebuBlox_Loaded = true
getgenv().NebuBlox_Running = true

print("[Nebublox] New session started:", SessionID)


-- [ROBUST LOADER]
local function LoadScript(url)
    -- [DEV] Try Local File First (for testing updates)
    if isfile and isfile("ANUI_source.lua") then return readfile("ANUI_source.lua") end
    if isfile and isfile("ANUI-Library/games/ANUI_source.lua") then return readfile("ANUI-Library/games/ANUI_source.lua") end

    local success, result = pcall(function() return game:HttpGet(url) end)
    if not success then
        success, result = pcall(function() return HttpGet(url) end) -- Try global
    end
    if not success then
        -- Fallback to request
        local req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
        if req then
            local response = req({Url = url, Method = "GET"})
            if response.Success or response.StatusCode == 200 then
                return response.Body
            end
        end
    end
    return result
end

local ANUI = loadstring(LoadScript("https://raw.githubusercontent.com/ANHub-Script/ANUI/refs/heads/main/dist/main.lua"))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer

-- // 0.5 SETTINGS INIT //
if not getgenv().NebubloxSettings then
    getgenv().NebubloxSettings = {
        AutoLoad = true,
        LastConfig = "",
        AntiAfkEnabled = false
    }
end

-- // 1. CONFIGURATION //
local Flags = {
    SmartFarm = false,
    TrialAttackAll = false,
    TargetName = "",
    
    AutoTrial = false,
    AutoTrialFarm = false,
    
    BossRushDBZ = false, BossRushJJK = false,
    
    -- Invasion
    AutoInvasionStart = false,
    AutoInvasionUpgrade = false,
    
    -- Gacha
    OnePieceFruit = false, OnePieceCrew = false,
    DbzSaiyan = false,
    KiProgression = false,
    NarutoKekkeiGenkai = false, NarutoClan = false, NarutoTailedBeast = false,
    JjkDomain = false, CursedProgression = false,
    SlayerBreathing = false, SlayerArt = false,
    HakiProgression = false,
    
    AutoRebirth = false, AutoTimedRewards = false
}

-- Global State
getgenv().CurrentTarget = nil
local DeadBlacklist = {} 
local SelectedEnemies = {} 
local LastTargetedTime = {} 

local SavedCFrame = nil
local PerformReturn = false 
local SelectedReturnMap = "Same Spot"
local LastTrialJoinTime = 0 
local InInvasion = false 
local LastInvasionCheck = 0
local LastInvasionJoinTime = 0
getgenv().TrialSuccess = false
local SavedReturnMap = "Same Spot"

local function SerializeCFrame(cf)
    if not cf then return nil end
    return {cf:GetComponents()}
end
local function DeserializeCFrame(data)
    if not data then return nil end
    return CFrame.new(unpack(data))
end

-- // 3. CONFIG SYSTEM //
local FolderName = "Nebublox"
local ConfigsFolder = FolderName .. "/Configs"

pcall(function()
    if not isfolder(FolderName) then makefolder(FolderName) end
    if not isfolder(ConfigsFolder) then makefolder(ConfigsFolder) end
end)
local API_URL_BASE = "https://darkmatterv1.onrender.com"

local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

local ConfigSystem = {}

function ConfigSystem.SaveConfig(name)
    if name == "" then 
        pcall(function() ANUI:Notify({Title = "Error", Content = "Enter a config name!", Icon = "alert-triangle", Duration = 3}) end)
        return 
    end
    
    local success, err = pcall(function()
        if not writefile then error("writefile not available") end
        if not isfolder then error("isfolder not available") end
        
        if not isfolder(FolderName) then makefolder(FolderName) end
        if not isfolder(ConfigsFolder) then makefolder(ConfigsFolder) end
        
        local json = HttpService:JSONEncode(Flags)
        writefile(ConfigsFolder .. "/" .. name .. ".json", json)
    end)
    
    if success then
        pcall(function() ANUI:Notify({Title = "Config Saved!", Content = name .. ".json", Icon = "check", Duration = 3}) end)
    else
        pcall(function() ANUI:Notify({Title = "Save Failed", Content = tostring(err), Icon = "x", Duration = 5}) end)
        warn("[Nebublox] Config save failed:", err)
    end
end

function ConfigSystem.LoadConfig(name)
    local path = ConfigsFolder .. "/" .. name .. ".json"
    pcall(function()
        if isfile(path) then
            local json = readfile(path)
            local decoded = HttpService:JSONDecode(json)
            for key, value in pairs(decoded) do
                Flags[key] = value
            end
            getgenv().NebubloxSettings.LastConfig = name
            ANUI:Notify({Title = "Config", Content = "Loaded: " .. name, Icon = "folder-open", Duration = 3})
        else
            ANUI:Notify({Title = "Error", Content = "Config not found!", Icon = "alert-triangle", Duration = 3})
        end
    end)
end

function ConfigSystem.DeleteConfig(name)
    local path = ConfigsFolder .. "/" .. name .. ".json"
    pcall(function()
        if isfile(path) then
            delfile(path)
            ANUI:Notify({Title = "Config", Content = "Deleted: " .. name, Icon = "trash", Duration = 3})
        end
    end)
end

function ConfigSystem.GetConfigs()
    local names = {}
    pcall(function()
        local files = listfiles(ConfigsFolder)
        for _, file in ipairs(files) do
            local name = file:match("([^/\\]+)%.json$")
            if name then table.insert(names, name) end
        end
    end)
    return names
end

function ConfigSystem.CheckAutoload()
    pcall(function()
        if getgenv().NebubloxSettings.AutoLoad and getgenv().NebubloxSettings.LastConfig ~= "" then
            ConfigSystem.LoadConfig(getgenv().NebubloxSettings.LastConfig)
        end
    end)
end

-- Anti-AFK
local AntiAfkConnection
function ToggleAntiAFK(state)
    if state then
        AntiAfkConnection = player.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
        ANUI:Notify({Title = "Anti-AFK", Content = "Enabled", Icon = "shield", Duration = 2})
    else
        if AntiAfkConnection then
            AntiAfkConnection:Disconnect()
            AntiAfkConnection = nil
        end
        ANUI:Notify({Title = "Anti-AFK", Content = "Disabled", Icon = "shield-off", Duration = 2})
    end
end

-- FPS Boost
function BoostFPS()
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.Brightness = 1
        
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v.Parent:FindFirstChild("Humanoid") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
                v.CastShadow = false
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Enabled = false
            end
        end
        
        workspace.Terrain.WaterWaveSize = 0
        workspace.Terrain.WaterWaveSpeed = 0
        workspace.Terrain.WaterReflectance = 0
        workspace.Terrain.WaterTransparency = 0
    end)
    ANUI:Notify({Title = "FPS Boost", Content = "Low GFX Mode Applied!", Icon = "zap", Duration = 3})
end

local MapDisplayToInternal = {
    ["Z World"] = "Dbz",
    ["Cursed World"] = "Jjk",
    ["Shinobi World"] = "Naruto",
    ["Pirate World"] = "OnePiece",
    ["Slayer World"] = "DemonSlayer"
}
local MapInternalToDisplay = {}
for k, v in pairs(MapDisplayToInternal) do MapInternalToDisplay[v] = k end

local MapOptions = {"Cursed World", "Pirate World", "Shinobi World", "Slayer World", "Z World"} 
local function RefreshMapOptions() end

task.spawn(function()
    while task.wait(2) do
        if getgenv().NebuBlox_SessionID ~= SessionID then break end
        DeadBlacklist = {}
        local now = tick()
        for mob, time in pairs(LastTargetedTime) do
            if now - time > 0.5 then LastTargetedTime[mob] = nil end
        end
    end
end)

-- // 2. UI SETUP //
local Window = ANUI:CreateWindow({
    Title = "Nebublox", 
    Author = "He Who Remains Lil'Nug",
    Folder = "Nebublox",
    Icon = "rbxthumb://type=Asset&id=120742610207737&w=150&h=150",
    IconSize = 63,
    Theme = "Dark", 
})
getgenv().ANUI_Window = Window

-- [ICON FIX]
task.spawn(function()
    local attempts = 0
    while attempts < 20 do
        task.wait(1)
        attempts = attempts + 1
        local function FixIcon(root)
            if not root then return end
            for _, img in ipairs(root:GetDescendants()) do
                if img:IsA("ImageLabel") then
                     if (img.Name == "Icon" or img.Name == "Logo" or (img.Image and img.Image:find("120742610207737"))) then
                        img.ScaleType = Enum.ScaleType.Crop 
                        img.BackgroundTransparency = 1 
                        img.BackgroundColor3 = Color3.new(0,0,0)
                        img.Size = UDim2.new(3, 0, 3, 0)
                        local corner = img:FindFirstChildOfClass("UICorner")
                        if not corner then
                             local c = Instance.new("UICorner", img); c.CornerRadius = UDim.new(1, 0)
                        else corner.CornerRadius = UDim.new(1, 0) end
                    end
                end
            end
        end
        FixIcon(game:GetService("CoreGui"):FindFirstChild("Nebublox"))
        FixIcon(game:GetService("CoreGui"):FindFirstChild("ANUI"))
        FixIcon(player.PlayerGui:FindFirstChild("Nebublox"))
    end
end)

-- [TAB 1: ABOUT]
local TrialTab, GamemodesTab, GachaTab -- Forward declare for Key System
local MainTab = Window:Tab({ Title = "About", Icon = "info" })
local BannerSection = MainTab:Section({ Title = "", Icon = "", Opened = true })
BannerSection:Paragraph({ Title = "Loading Banner...", Content = "" })
task.spawn(function()
    task.wait(2)
    local imgId = "rbxthumb://type=Asset&id=132367447015620&w=768&h=432"
    local function FindAndInjectImage(root)
        if not root then return end
        for _, obj in ipairs(root:GetDescendants()) do
            if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Text == "Loading Banner..." then
                local paragraph = obj.Parent
                local section = paragraph and paragraph.Parent
                if section then
                    local frame = Instance.new("ImageLabel")
                    frame.Name = "Banner"
                    frame.Size = UDim2.new(1, 0, 0, 300)
                    frame.Position = paragraph.Position
                    frame.BackgroundTransparency = 1
                    frame.Image = imgId
                    frame.ScaleType = Enum.ScaleType.Crop
                    frame.Parent = section
                    paragraph:Destroy()
                    return true
                end
            end
        end
    end
    if not FindAndInjectImage(game:GetService("CoreGui")) then FindAndInjectImage(player.PlayerGui) end
end)

-- // [TAB 1: ABOUT & KEY SYSTEM] //
local AboutSection = MainTab:Section({ Title = "Authentication", Icon = "shield", Opened = true })

-- Welcome Message
-- Community Message
AboutSection:Paragraph({
    Title = "Thank You for using Nebublox! ❤️",
    Content = "We appreciate your support! \nThis script features a powerful Auto Farm (Free) and specialized modes for Premium users.\n\nJoin our Discord for keys, updates, and a great community!"
})

-- Key System Logic
local UserKeyInput = ""

-- Side-by-Side Input Group
local InputGroup = AboutSection:Group({ Title = "" }) -- Empty title for layout only

InputGroup:Input({
    Title = "Premium Key",
    Placeholder = "Enter Key...",
    Width = 200, -- Smaller width to fit button
    Callback = function(text)
        UserKeyInput = text
    end
})

InputGroup:Button({
    Title = "Verify",
    Width = 100, -- Small button next to input
    Callback = function()
        -- 1. Input Validation
        if UserKeyInput == "" then
            ANUI:Notify({Title = "Error", Content = "Please enter a key!", Icon = "alert-triangle", Duration = 3})
            return
        end
        
        -- 2. Inform User
        ANUI:Notify({Title = "Verifying...", Content = "Checking key...", Icon = "loader", Duration = 2})

        -- 3. API Request
        local success, result = pcall(function()
            local url = API_URL_BASE .. "/verify_key?key=" .. UserKeyInput .. "&hwid=" .. game:GetService("RbxAnalyticsService"):GetClientId()
            local response = game:GetService("HttpService"):GetAsync(url)
            return game:GetService("HttpService"):JSONDecode(response)
        end)

        -- 4. Handle Response
        if success then
            local data = result
            if data and data.valid then
                -- [SUCCESS]
                ANUI:Notify({Title = "Access Granted", Content = "Welcome, " .. tostring(data.username or "User"), Icon = "check", Duration = 5})
                
                -- >> UNLOCK FEATURES <<
                if TrialTab then TrialTab:Unlock() end
                if GamemodesTab then GamemodesTab:Unlock() end
                if GachaTab then GachaTab:Unlock() end
                
            else
                -- [INVALID OR EXPIRED KEY]
                ANUI:Notify({Title = "Access Denied", Content = data.message or "Invalid Key", Icon = "x", Duration = 3})
            end
        else
            -- [API ERROR]
            warn("API Error:", result)
            ANUI:Notify({Title = "Connection Error", Content = "Failed to reach server.", Icon = "wifi-off", Duration = 3})
        end
    end
})

AboutSection:Button({
    Title = "- Get Premium Key / Discord",
    Callback = function()
        setclipboard("https://discord.gg/nebublox")
        ANUI:Notify({Title = "Discord", Content = "Invite copied to clipboard!", Icon = "copy", Duration = 3})
    end
})

-- [MAP CONFIGURATION]
local MapDisplayToInternal = {
    ["Z World"] = "Dbz",
    ["Cursed World"] = "Jjk",
    ["Shinobi World"] = "Naruto",
    ["Pirate World"] = "OnePiece",
    ["Slayer World"] = "DemonSlayer"
}
local MapInternalToDisplay = {}
for k, v in pairs(MapDisplayToInternal) do MapInternalToDisplay[v] = k end
local MapOptions = {"Cursed World", "Pirate World", "Shinobi World", "Slayer World", "Z World"} 
local function RefreshMapOptions() end

-- [TAB 2: FARM (SMART FARM)]
local TeleportTab = Window:Tab({ Title = "Farm", Icon = "map-pin" })
local FarmSection = TeleportTab:Section({ Title = "Smart Farm", Icon = "zap", Opened = true })

FarmSection:Toggle({
    Title = "Auto Farm",
    Desc = "Auto targets & attacks enemies",
    Value = false,
    Callback = function(state) 
        Flags.SmartFarm = state 
        if not state then getgenv().NebuBlox_CurrentTarget = nil end
    end
})

-- [CUSTOM ENEMY SELECTOR UI]
local function CreateEmbeddedSelector(parent)
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "EnemySelectorFrame"
    MainFrame.Size = UDim2.new(1, -10, 0, 250)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = parent
    
    local UICorner = Instance.new("UICorner"); UICorner.CornerRadius = UDim.new(0, 8); UICorner.Parent = MainFrame
    
    local Header = Instance.new("TextLabel")
    Header.Size = UDim2.new(1, 0, 0, 35)
    Header.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    Header.Text = "  Multi-Target Selector"
    Header.TextColor3 = Color3.fromRGB(255, 255, 255)
    Header.TextXAlignment = Enum.TextXAlignment.Left
    Header.Font = Enum.Font.GothamBold
    Header.TextSize = 14
    Header.Parent = MainFrame
    Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 8)

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -10, 0, 20)
    StatusLabel.Position = UDim2.new(0, 5, 0, 38)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "Status: Attack All / Nearest"
    StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    StatusLabel.TextSize = 11
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.Parent = MainFrame

    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Size = UDim2.new(1, -10, 1, -65)
    ScrollFrame.Position = UDim2.new(0, 5, 0, 60)
    ScrollFrame.BackgroundTransparency = 1
    ScrollFrame.BorderSizePixel = 0
    ScrollFrame.ScrollBarThickness = 4
    ScrollFrame.Parent = MainFrame
    
    local ListLayout = Instance.new("UIListLayout")
    ListLayout.SortOrder = Enum.SortOrder.Name
    ListLayout.Padding = UDim.new(0, 4)
    ListLayout.Parent = ScrollFrame

    local function UpdateStatus()
        local count = 0
        for _ in pairs(SelectedEnemies) do count = count + 1 end
        if count == 0 then StatusLabel.Text = "Mode: Nearest Enemy (No selection)"
        else StatusLabel.Text = "Mode: Targeting " .. count .. " selected enemies" end
    end

    local function RefreshList()
        for _, c in pairs(ScrollFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        
        local seen = {}
        local names = {}
        
        local folders = {
            Workspace:FindFirstChild("Npc"),
            Workspace:FindFirstChild("TrialRoomNpc"),
            Workspace:FindFirstChild("InvasionNpc")
        }
        
        for _, folder in ipairs(folders) do
            if folder then
                for _, obj in ipairs(folder:GetDescendants()) do
                    if obj:IsA("Humanoid") and obj.Parent then
                        local mob = obj.Parent
                        local name = mob.Name
                        local bb = mob:FindFirstChild("Head") and mob.Head:FindFirstChild("NpcBillboard")
                        local disp = bb and bb:FindFirstChild("NpcName") and bb.NpcName.Text
                        if disp and disp ~= "" then name = disp end
                        
                        if name ~= "Dummy" and name ~= player.Name and not seen[name] then
                            seen[name] = true
                            table.insert(names, name)
                        end
                    end
                end
            end
        end
        
        table.sort(names)
        
        for _, name in ipairs(names) do
            local btn = Instance.new("TextButton")
            btn.Name = name
            btn.Size = UDim2.new(1, -4, 0, 25)
            btn.BackgroundColor3 = SelectedEnemies[name] and Color3.fromRGB(45, 140, 220) or Color3.fromRGB(45, 45, 50)
            btn.Text = name
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 12
            btn.Parent = ScrollFrame
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            
            btn.MouseButton1Click:Connect(function()
                if SelectedEnemies[name] then
                    SelectedEnemies[name] = nil
                    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
                else
                    SelectedEnemies[name] = true
                    btn.BackgroundColor3 = Color3.fromRGB(45, 140, 220)
                end
                UpdateStatus()
                getgenv().NebuBlox_CurrentTarget = nil 
            end)
        end
        ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
    end
    
    task.spawn(RefreshList)
    
    local RefBtn = Instance.new("TextButton")
    RefBtn.Size = UDim2.new(0, 60, 0, 20)
    RefBtn.Position = UDim2.new(1, -65, 0, 7)
    RefBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    RefBtn.Text = "Refresh"
    RefBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    RefBtn.TextSize = 10
    RefBtn.Parent = MainFrame
    Instance.new("UICorner", RefBtn).CornerRadius = UDim.new(0, 4)
    RefBtn.MouseButton1Click:Connect(RefreshList)
    
    return MainFrame
end

local TargetSection = TeleportTab:Section({ Title = "Target List", Icon = "list", Opened = true })
local Placeholder = TargetSection:Paragraph({ Title = "Loading UI...", Content = "" })
task.spawn(function()
    task.wait(0.5)
    local function FindAndInject(root)
        if not root then return end
        for _, obj in ipairs(root:GetDescendants()) do
            if obj:IsA("TextLabel") and obj.Text == "Loading UI..." then
                local paragraph = obj.Parent
                local section = paragraph and paragraph.Parent
                if section then
                    CreateEmbeddedSelector(section)
                    paragraph:Destroy()
                    return true
                end
            end
        end
    end
    if not FindAndInject(game:GetService("CoreGui")) then FindAndInject(player.PlayerGui) end
end)



-- [TAB 3: TRIAL (TIME TRIAL)]
TrialTab = Window:Tab({ Title = "Trial 👑", Icon = "clock", Locked = true })

-- Easy Trial Section (Moved)
local TrialSection = TrialTab:Section({ Title = "Easy Time Trial", Icon = "play", Opened = true })
TrialSection:Toggle({ Title = "Auto Join Trial (Smart)", Value = false, Callback = function(s) 
    Flags.AutoTrial = s; 
    Flags.AutoTrialFarm = s
    if s and (not SavedCFrame or SavedCFrame == nil) and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        SavedCFrame = player.Character.HumanoidRootPart.CFrame
        ANUI:Notify({Title = "Position Saved", Content = "Auto-saved current spot for return.", Icon = "pin", Duration = 3})
    end
end })
-- Return Toggle Renamed for Clarity
TrialSection:Toggle({ Title = "Return After (Trial/Invasion)", Value = false, Callback = function(s) PerformReturn = s end })

local MapDropdown = TrialSection:Dropdown({
    Title = "Select Return Map",
    Options = MapOptions,
    Default = "Z World", -- Default to Z World (Dbz)
    Callback = function(v) SelectedReturnMap = v end
})

TrialSection:Button({
    Title = "Refresh Map List",
    Callback = function()
        RefreshMapOptions()
        if MapDropdown and MapDropdown.Refresh then
            MapDropdown:Refresh(MapOptions) -- Attempt to refresh if supported
        else
            ANUI:Notify({Title = "Maps", Content = "Refreshed internally. Re-open UI to see changes if blocked.", Icon = "refresh", Duration = 3})
        end
    end
})

TrialSection:Button({
    Title = "Save Current Position (For Selected Map)",
    Callback = function()
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if root then
            -- We assume user is IN the map they want to save for?
            -- Or we detect map?
            -- Simple logic: Provide override.
            -- If user saves position, we store it.
            -- When returning, if Selected Map matches the map associated with this position?
            -- We don't track map association strictly.
            -- But user said "user should choose the map they saved their position in".
            -- I'll define SavedCFrame as GLOBAL value.
            SavedCFrame = root.CFrame
            -- We also try to guess the map name to be smart
            local currentMap = "Unknown"
            local maps = Workspace:FindFirstChild("Maps")
            if maps then
                local bestDist = 999999
                for _, m in ipairs(maps:GetChildren()) do
                    local spawn = m:FindFirstChild("Spawn") or m:FindFirstChild("SpawnPoint")
                    if spawn then
                        local dist = (root.Position - spawn.Position).Magnitude
                        if dist < bestDist then bestDist = dist; currentMap = m.Name end
                    end
                end
            end
            -- Store map
            getgenv().SavedMapInternalName = currentMap
            
            local disp = MapInternalToDisplay[currentMap] or currentMap
            ANUI:Notify({Title = "Position Saved", Content = "Saved for: " .. disp, Icon = "check", Duration = 3})
        else
            ANUI:Notify({Title = "Error", Content = "Character not found!", Icon = "alert-triangle", Duration = 3})
        end
    end
})

TrialSection:Toggle({ Title = "Auto Drop Potion (On Start)", Value = false, Callback = function(s) Flags.AutoDropPotion = s end })
TrialSection:Toggle({ Title = "Attack ALL (Trial Only)", Value = false, Callback = function(s) Flags.TrialAttackAll = s end })

-- Trial Upgrades Section (New)




-- [TAB 4: GAMEMODES (SWAPPED LOGIC)]
GamemodesTab = Window:Tab({ Title = "Gamemodes 👑", Icon = "swords", Locked = true })

local BossSection = GamemodesTab:Section({ Title = "World Boss Rushes", Icon = "skull", Opened = true })
BossSection:Toggle({ Title = "Auto World Boss Rush ( Z World)", Value = false, Callback = function(s) Flags.BossRushDBZ = s end })
BossSection:Toggle({ Title = "Auto World Boss Rush ( Cursed World)", Value = false, Callback = function(s) Flags.BossRushJJK = s end })

local InvSection = GamemodesTab:Section({ Title = "Invasion", Icon = "shield", Opened = true })
InvSection:Toggle({ Title = "Auto Invasion (Slayer World)", Value = false, Callback = function(s) Flags.AutoInvasionStart = s end })


-- [TAB 4: GACHA]
-- [TAB 4: GACHA]
GachaTab = Window:Tab({ Title = "Gacha 👑", Icon = "gift", Locked = true })
local OPSection = GachaTab:Section({ Title = "One Piece", Icon = "anchor" })
OPSection:Toggle({ Title = "Auto Roll Fruit", Value = false, Callback = function(s) Flags.OnePieceFruit = s end })
OPSection:Toggle({ Title = "Auto Roll Crew", Value = false, Callback = function(s) Flags.OnePieceCrew = s end })
OPSection:Toggle({ Title = "Auto Haki (Progression)", Value = false, Callback = function(s) Flags.HakiProgression = s end })

local DBZSection = GachaTab:Section({ Title = "Dragon Ball", Icon = "zap" })
DBZSection:Toggle({ Title = "Auto Roll Saiyan", Value = false, Callback = function(s) Flags.DbzSaiyan = s end })
DBZSection:Toggle({ Title = "Auto Ki Progression", Value = false, Callback = function(s) Flags.KiProgression = s end })

local NarutoSection = GachaTab:Section({ Title = "Naruto", Icon = "eye" })
NarutoSection:Toggle({ Title = "Auto Roll Kekkei Genkai", Value = false, Callback = function(s) Flags.NarutoKekkeiGenkai = s end })
NarutoSection:Toggle({ Title = "Auto Roll Clan", Value = false, Callback = function(s) Flags.NarutoClan = s end })
NarutoSection:Toggle({ Title = "Auto Roll Tailed Beast", Value = false, Callback = function(s) Flags.NarutoTailedBeast = s end })

local JJKSection = GachaTab:Section({ Title = "Jiu-Jitsu Kaisen", Icon = "flame" })
JJKSection:Toggle({ Title = "Auto Roll Domain", Value = false, Callback = function(s) Flags.JjkDomain = s end })
JJKSection:Toggle({ Title = "Auto Cursed Energy", Value = false, Callback = function(s) Flags.CursedProgression = s end })

local SlayerSection = GachaTab:Section({ Title = "Demon Slayer", Icon = "sword" })
SlayerSection:Toggle({ Title = "Auto Roll Breathing", Value = false, Callback = function(s) Flags.SlayerBreathing = s end })
SlayerSection:Toggle({ Title = "Auto Roll Art", Value = false, Callback = function(s) Flags.SlayerArt = s end })

-- [TAB 5: PROGRESSION]
local MiscTab = Window:Tab({ Title = "Progression", Icon = "chevrons-up" })
local MiscSection = MiscTab:Section({ Title = "Progression", Icon = "chevrons-up", Opened = true })
MiscSection:Toggle({ Title = "Auto Rank up", Value = false, Callback = function(s) Flags.AutoRebirth = s end })
MiscSection:Toggle({ Title = "Claim Timed Rewards", Value = false, Callback = function(s) Flags.AutoTimedRewards = s end })

local UpgradeSection = MiscTab:Section({ Title = "Trial Upgrades", Icon = "trending-up" })
UpgradeSection:Toggle({ Title = "Auto Upgrade Strength", Value = false, Callback = function(s) Flags.TrialUpgradeStrength = s end })
UpgradeSection:Toggle({ Title = "Auto Upgrade Gems", Value = false, Callback = function(s) Flags.TrialUpgradeGems = s end })
UpgradeSection:Toggle({ Title = "Auto Upgrade Drops", Value = false, Callback = function(s) Flags.TrialUpgradeDrops = s end })
UpgradeSection:Toggle({ Title = "Auto Upgrade Luck", Value = false, Callback = function(s) Flags.TrialUpgradeLuck = s end })
UpgradeSection:Toggle({ Title = "Auto Upgrade Walkspeed", Value = false, Callback = function(s) Flags.TrialUpgradeWalkspeed = s end })

-- [TAB 6: SETTINGS]
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

local SystemSection = SettingsTab:Section({ Title = "System", Icon = "power", Opened = true })
SystemSection:Button({
    Title = "Kill Script (Unload)",
    Callback = function()
        -- Break all loops
        getgenv().NebuBlox_SessionID = 0 
        getgenv().NebuBlox_Running = false
        
        -- Cleanup UI
        if getgenv().ANUI_Window then 
             pcall(function() getgenv().ANUI_Window:Destroy() end)
        end
        if Window then
             pcall(function() Window:Destroy() end)
        end
        
        -- Notify (if possible before destruction)
        pcall(function() 
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Nebublox",
                Text = "Script Unloaded / Killed.",
                Duration = 3
            })
        end)
    end
})

local ConfigSection = SettingsTab:Section({ Title = "Configuration Manager", Icon = "folder", Opened = true })

ConfigSection:Input({ Title = "Config Name", Placeholder = "Enter config name...", Callback = function(text) ConfigNameInput = text end })

-- [CONFIG DROPDOWN SYSTEM]
local ConfigDropdown
local SelectedConfig = ""

local function UpdateConfigDropdown()
    local list = ConfigSystem.GetConfigs()
    if #list == 0 then list = {"None"} end
    -- Attempt to refresh dropdown if library supports it
    if ConfigDropdown and ConfigDropdown.Refresh then
        ConfigDropdown:Refresh(list, true) 
    end
end

ConfigDropdown = ConfigSection:Dropdown({
    Title = "Select Config",
    Multi = false,
    Options = ConfigSystem.GetConfigs(),
    Callback = function(val)
        if val ~= "None" then
            SelectedConfig = val
            ConfigNameInput = val -- Optional: Set name input to match selected
            ANUI:Notify({Title = "Selected", Content = val, Icon = "check", Duration = 2})
        end
    end
})

ConfigSection:Button({
    Title = "Refresh Config List",
    Callback = function() 
        UpdateConfigDropdown()
        ANUI:Notify({Title = "Configs", Content = "List Refreshed", Icon = "refresh", Duration = 2}) 
    end
})

ConfigSection:Button({
    Title = "Save Config",
    Callback = function()
        if ConfigNameInput ~= "" then
            ConfigSystem.SaveConfig(ConfigNameInput)
            UpdateConfigDropdown()
        else
            ANUI:Notify({Title = "Error", Content = "Enter a name above!", Icon = "edit", Duration = 3})
        end
    end
})

ConfigSection:Button({
    Title = "Autoload Config",
    Callback = function()
        if SelectedConfig ~= "" and SelectedConfig ~= "None" then
            getgenv().NebubloxSettings.AutoLoad = true
            getgenv().NebubloxSettings.LastConfig = SelectedConfig
            ANUI:Notify({Title = "Autoload Set", Content = "Startup config: " .. SelectedConfig, Icon = "star", Duration = 3})
        else
            ANUI:Notify({Title = "Error", Content = "Select a config first!", Icon = "alert-triangle", Duration = 3})
        end
    end
})

ConfigSection:Button({
    Title = "Load Selected Config",
    Callback = function()
        if SelectedConfig ~= "" and SelectedConfig ~= "None" then
            ConfigSystem.LoadConfig(SelectedConfig)
        else
            ANUI:Notify({Title = "Error", Content = "Select a config first!", Icon = "alert-triangle", Duration = 3})
        end
    end
})

ConfigSection:Button({
    Title = "Delete Selected Config",
    Callback = function()
        if SelectedConfig ~= "" and SelectedConfig ~= "None" then
            ConfigSystem.DeleteConfig(SelectedConfig)
            UpdateConfigDropdown()
            SelectedConfig = ""
        else
            ANUI:Notify({Title = "Error", Content = "Select a config first!", Icon = "alert-triangle", Duration = 3})
        end
    end
})


local PerfSection = SettingsTab:Section({ Title = "System Performance", Icon = "cpu", Opened = true })
PerfSection:Toggle({ Title = "Anti-AFK / Anti-Kick", Value = getgenv().NebubloxSettings.AntiAfkEnabled, Callback = function(s) getgenv().NebubloxSettings.AntiAfkEnabled = s; ToggleAntiAFK(s) end })
PerfSection:Button({ Title = "⚡ Low GFX Mode (FPS Boost)", Callback = function() BoostFPS() end })

ConfigSystem.CheckAutoload()

-- // 3. LOGIC //
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)

-- // Helper Functions //
local function CountLiveEnemies(folder)
    local count = 0
    if folder then
        for _, v in ipairs(folder:GetDescendants()) do
            if v:IsA("Humanoid") and v.Health > 0 then count = count + 1 end
        end
    end
    return count
end

-- [SMART TARGET FINDER - V8.3 (GAMEMODE FIX)]
local function GetSmartTarget()
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    if not player.Character:IsDescendantOf(Workspace) then return nil end
    
    local bestTarget = nil
    local shortestDist = 999999
    
    local selectedCount = 0
    for _ in pairs(SelectedEnemies) do selectedCount = selectedCount + 1 end

    local function CheckMob(humanoid)
        if not humanoid or not humanoid:IsA("Humanoid") then return end
        local mob = humanoid.Parent
        if not mob or DeadBlacklist[mob] or LastTargetedTime[mob] then return end
        
        local rootPart = mob:FindFirstChild("HumanoidRootPart")
        if not rootPart or not mob:IsDescendantOf(Workspace) then return end
        if humanoid.Health <= 0 or mob.Name == player.Name then DeadBlacklist[mob] = true; return end
        
        local isValid = false
        
        -- Priority Name Check (Boss Rush / Invasion)
        if Flags.BossRushDBZ and mob.Name == "SsjRoseGoku" then isValid = true end
        if Flags.BossRushJJK and mob.Name == "AdaptiveCurse" then isValid = true end
        -- [INVASION LOGIC UPDATE]
        -- Automatically target ALL enemies in InvasionNpc if mode is active
        if Flags.AutoInvasionStart and mob:IsDescendantOf(Workspace:FindFirstChild("InvasionNpc")) then 
            isValid = true 
        end

        if not isValid then
            if Flags.SmartFarm and selectedCount > 0 then
                local head = mob:FindFirstChild("Head")
                local bb = head and head:FindFirstChild("NpcBillboard")
                local disp = bb and bb:FindFirstChild("NpcName") and bb.NpcName.Text
                if SelectedEnemies[mob.Name] or (disp and SelectedEnemies[disp]) then isValid = true end
            elseif Flags.SmartFarm then
                isValid = true
            end
            
            -- Special override for Trial Attack All
            if Flags.TrialAttackAll and mob:IsDescendantOf(Workspace:FindFirstChild("TrialRoomNpc")) then
                isValid = true
            end
        end
        
        if isValid then
            local dist = (rootPart.Position - myRoot.Position).Magnitude
            if dist < shortestDist then
                shortestDist = dist
                bestTarget = mob
            end
        end
    end

    -- 1. Scan Trials (Priority)
    if Flags.AutoTrialFarm then
        local tf = Workspace:FindFirstChild("TrialRoomNpc")
        if tf then for _, o in ipairs(tf:GetDescendants()) do CheckMob(o) end end
        if bestTarget then return bestTarget end
    end

    -- 2. Scan Boss Rush (Priority)
    if Flags.BossRushDBZ then
        local folder = Workspace:FindFirstChild("BossRushNpc") and Workspace.BossRushNpc:FindFirstChild("DbzBossRush")
        if folder then for _, o in ipairs(folder:GetDescendants()) do CheckMob(o) end end
        if bestTarget then return bestTarget end
    end
    if Flags.BossRushJJK then
        local folder = Workspace:FindFirstChild("BossRushNpc") and Workspace.BossRushNpc:FindFirstChild("JjkBossRush")
        if folder then for _, o in ipairs(folder:GetDescendants()) do CheckMob(o) end end
        if bestTarget then return bestTarget end
    end

    -- 3. Scan Invasion (Priority)
    if Flags.SmartFarm or Flags.AutoInvasionStart then 
        local invF = Workspace:FindFirstChild("InvasionNpc")
        if invF then for _, o in ipairs(invF:GetDescendants()) do CheckMob(o) end end
        if bestTarget then return bestTarget end
    end

    -- 4. Scan Generic Maps (If no higher priority target found and SmartFarm is ON)
    if Flags.SmartFarm then 
        local mf = Workspace:FindFirstChild("Npc")
        if mf then for _, o in ipairs(mf:GetDescendants()) do CheckMob(o) end end
    end
    
    return bestTarget
end

-- [PROMPT SUPPRESSION]
task.spawn(function()
    while task.wait(1) do
         if getgenv().NebuBlox_SessionID ~= SessionID then break end
         
         -- 1. Boss Rush Prompt
         if Flags.BossRushDBZ or Flags.BossRushJJK then
             local br = Remotes.BossRush and Remotes.BossRush:FindFirstChild("BossRushRemote")
             if br and br.OnClientEvent then
                 if getconnections then
                     for _, c in pairs(getconnections(br.OnClientEvent)) do c:Disable() end
                 end
             end
         end
         
         -- 2. Easy Trial Prompt "NotifyBeforeStart"
         if Flags.AutoTrial then
             local tr = Remotes.TimeTrial and Remotes.TimeTrial:FindFirstChild("TrialEffects")
             if tr and tr.OnClientEvent then
                 if getconnections then
                     for _, c in pairs(getconnections(tr.OnClientEvent)) do c:Disable() end
                 end
             end
         end
    end
end)

local function GetBossSpawn(mode)
    local maps = Workspace:FindFirstChild("Maps")
    if not maps then return nil end
    if mode == "Jjk" and maps:FindFirstChild("JjkBossRush") then return maps.JjkBossRush.NpcSpawns.Boss end
    if mode == "Dbz" and maps:FindFirstChild("dbzBossRush") then return maps.dbzBossRush.NpcSpawns.Boss end
    return nil
end

-- // LOOPS //
getgenv().NebuBlox_NoClipConnection = RunService.Stepped:Connect(function()
    if getgenv().NebuBlox_SessionID ~= SessionID then return end
    if player.Character then
        for _, v in pairs(player.Character:GetChildren()) do if v:IsA("BasePart") then v.CanCollide = false end end
    end
end)

getgenv().NebuBlox_MovementConnection = RunService.RenderStepped:Connect(function()
    if getgenv().NebuBlox_SessionID ~= SessionID then return end
    pcall(function()
        local char = player.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        -- Speed
        local hum = char:FindFirstChild("Humanoid")
        if hum and hum.WalkSpeed ~= 70 then hum.WalkSpeed = 70 end

        -- PRIORITY 1: Trial
        local tf = Workspace:FindFirstChild("TrialRoomNpc")
        local InTrialArea = tf and #tf:GetChildren() > 0 
        
        if InTrialArea and Flags.AutoTrialFarm then
            local t = getgenv().NebuBlox_CurrentTarget
            if t and t.Parent and t:FindFirstChild("Humanoid") and t.Humanoid.Health > 0 and t:FindFirstChild("HumanoidRootPart") then
                root.CFrame = t.HumanoidRootPart.CFrame * CFrame.new(0,0,3)
                root.AssemblyLinearVelocity = Vector3.zero
            end
            -- STAY IN TRIAL ROOM: Even if no target, don't fall through to farming if in trial area
            return 
        end
        
        -- PRIORITY 2: Invasion
        local invF = Workspace:FindFirstChild("InvasionNpc")
        local InInvasionNow = invF and CountLiveEnemies(invF) > 0
        local InInvasionArea = InInvasionNow or (invF and #invF:GetChildren() > 0 and (tick() - LastInvasionJoinTime < 90))

        if InInvasionArea and Flags.AutoInvasionStart then
            local t = getgenv().NebuBlox_CurrentTarget
            if t and t.Parent and t:FindFirstChild("Humanoid") and t.Humanoid.Health > 0 and t:FindFirstChild("HumanoidRootPart") then
                root.CFrame = t.HumanoidRootPart.CFrame * CFrame.new(0,0,3)
                root.AssemblyLinearVelocity = Vector3.zero
            end
            return -- Priority: Don't do anything else while in Invasion
        end

        -- PRIORITY 3: Boss Rush
        if Flags.BossRushDBZ or Flags.BossRushJJK then
             -- Try to attack specific target first
             local t = getgenv().NebuBlox_CurrentTarget
             if t and t.Parent and t:FindFirstChild("Humanoid") and t.Humanoid.Health > 0 and t:FindFirstChild("HumanoidRootPart") then
                root.CFrame = t.HumanoidRootPart.CFrame * CFrame.new(0,0,3)
                root.AssemblyLinearVelocity = Vector3.zero
                return
             end
             
             -- Fallback: Stand at spawn if no target found yet
             local tc = nil
             if Flags.BossRushDBZ then local s = GetBossSpawn("Dbz"); if s then tc = s.CFrame * CFrame.new(0,0,2) end
             elseif Flags.BossRushJJK then local s = GetBossSpawn("Jjk"); if s then tc = s.CFrame * CFrame.new(0,0,2) end end
             if tc then root.CFrame = tc; root.AssemblyLinearVelocity = Vector3.zero end
             return
        end

        -- PRIORITY 4: Smart Farm (Only if not in Trial/Invasion/Boss)
        if Flags.SmartFarm then
            local t = getgenv().NebuBlox_CurrentTarget
            if t and t.Parent and t:FindFirstChild("Humanoid") and t.Humanoid.Health > 0 and t:FindFirstChild("HumanoidRootPart") then
                 root.CFrame = t.HumanoidRootPart.CFrame * CFrame.new(0,0,3)
                 root.AssemblyLinearVelocity = Vector3.zero
            end
        end
    end)
end)

-- TARGET UPDATER (THROTTLED: 0.15s)
task.spawn(function()
    while task.wait(0.15) do
        if getgenv().NebuBlox_SessionID ~= SessionID then break end
        if Flags.SmartFarm or Flags.AutoTrialFarm or Flags.AutoInvasionStart then 
             -- Enabled if ANY auto-attack mode is on
             local t = GetSmartTarget()
             if t then
                 getgenv().NebuBlox_CurrentTarget = t
                 if not LastTargetedTime[t] then LastTargetedTime[t] = tick() end
             else
                 getgenv().NebuBlox_CurrentTarget = nil
             end
        else
             getgenv().NebuBlox_CurrentTarget = nil
        end
    end
end)

task.spawn(function()
    while true do
        if getgenv().NebuBlox_SessionID ~= SessionID then break end
        local dt = task.wait(0.1)
        if Flags.SmartFarm or Flags.AutoTrialFarm or Flags.BossRushDBZ or Flags.BossRushJJK then
             pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:Button1Down(Vector2.new())
                VirtualUser:Button1Up(Vector2.new())
             end)
        end
    end
end)



-- AUTOMATION (RESTORED ALL GACHAS & GAMEMODES)
task.spawn(function()
    print("[Nebublox] Automation Thread Started.")
    
    -- Ensure Remotes reference exists
    local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 10)
    if not Remotes then
         warn("[Nebublox] CRITICAL: 'Remotes' folder not found!")
         return
    end

    local loops = 0
    while task.wait(0.5) do
        if getgenv().NebuBlox_SessionID ~= SessionID then break end
        loops = loops + 1
        


        pcall(function()
            -- Lazy load SpecialProgression to avoid blocking
            local SpecialProgressionRemote = Remotes:FindFirstChild("SpecialProgression")
            -- State Tracking (Refined for Prioritization)
            local tf = Workspace:FindFirstChild("TrialRoomNpc")
            local InTrialNow = tf and CountLiveEnemies(tf) > 0
            -- Refined InTrialArea: Only true if there are live mobs OR if we specifically joined recently
            local InTrialArea = InTrialNow or (tf and #tf:GetChildren() > 0 and (tick() - LastTrialJoinTime < 30))
            
            -- Auto Join Trial (Easy)
            if Flags.AutoTrial and Remotes.TimeTrial then
                local TTR = Remotes.TimeTrial:FindFirstChild("TimeTrialRemote")
                if TTR then
                    if not InTrialArea then
                        if (tick() - LastTrialJoinTime > 15) then
                             TTR:FireServer("Enter")
                             LastTrialJoinTime = tick()
                             ANUI:Notify({Title = "Trial", Content = "Attempting to join Trial...", Icon = "clock", Duration = 3})
                        end
                    end
                end
            end
            
            -- Invasion (Slayer World) - Only if NOT in Trial area
            if Flags.AutoInvasionStart and not InTrialArea then 
                local InvasionFolder = Remotes:FindFirstChild("Invasion")
                local foundRemote = false
                
                -- Debug: Notify once every 30s that we are checking for invasion
                if loops % 60 == 0 then -- approx 30s
                    ANUI:Notify({Title = "Automation", Content = "Checking for Invasions...", Icon = "search", Duration = 2})
                end
                if InvasionFolder then
                    local InvRemote = InvasionFolder:FindFirstChild("InvasionRemote")
                    local InvStart = InvasionFolder:FindFirstChild("InvasionStart")
                    local InvUpdate = InvasionFolder:FindFirstChild("UpdateUi") or InvasionFolder:FindFirstChild("InvasionUpdate")
                    local InvJoin = InvasionFolder:FindFirstChild("JoinInvasion")
                    
                    -- Try multiple invasion start methods
                    pcall(function()
                        if InvStart then 
                            -- print("State: Invasion Started (Method 1)")
                            foundRemote = true
                            LastInvasionJoinTime = tick()
                            InvStart:FireServer("Start", "DemonSlayerInvasion")
                            InvStart:FireServer("StartUi", "DemonSlayerInvasion")
                            InvStart:FireServer("Enter", "DemonSlayerInvasion")
                            InvStart:FireServer("JoinInvasion", "DemonSlayerInvasion")
                            InvStart:FireServer("StartInvasion")
                        end
                        if InvRemote then
                            foundRemote = true
                            LastInvasionJoinTime = tick()
                            InvRemote:FireServer("StartInvasion", "DemonSlayerInvasion")
                            InvRemote:FireServer("JoinInvasion", "DemonSlayerInvasion")
                            InvRemote:FireServer("Start", "DemonSlayerInvasion")
                            InvRemote:FireServer("Enter")
                            InvRemote:FireServer("Begin", "DemonSlayerInvasion")
                        end
                        if InvJoin then
                            foundRemote = true
                            LastInvasionJoinTime = tick()
                            InvJoin:FireServer("DemonSlayerInvasion")
                            InvJoin:FireServer("Join", "DemonSlayerInvasion")
                        end
                        if InvUpdate then
                            InvUpdate:FireServer("JoinInvasion", "DemonSlayerInvasion")
                            InvUpdate:FireServer("StartInvasion", "DemonSlayerInvasion")
                        end
                    end)
                end
                
                -- Also try direct remote path (alternative structure)
                pcall(function()
                    local directInv = Remotes:FindFirstChild("InvasionStart") or Remotes:FindFirstChild("InvasionRemote") or Remotes:FindFirstChild("StartInvasion")
                    if directInv then
                        foundRemote = true
                        LastInvasionJoinTime = tick()
                        -- String Args
                        directInv:FireServer("StartUi", "DemonSlayerInvasion") -- [NEW]
                        directInv:FireServer("Start", "DemonSlayerInvasion")
                        directInv:FireServer("Enter", "DemonSlayerInvasion")
                        -- Table Args (USER PROVIDED)
                        pcall(function()
                            directInv:FireServer({
                                Action = "OpenUi",
                                InvasionName = "DemonSlayerInvasion",
                                CanEnter = true -- Trying true to force entry
                            })
                            directInv:FireServer({
                                Action = "JoinInvasion",
                                InvasionName = "DemonSlayerInvasion"
                            })
                        end)
                    end
                end)
                
                -- [UI HIDER / SUPPRESSOR]
                if Flags.AutoInvasionStart or Flags.BossRushDBZ or Flags.BossRushJJK then
                     pcall(function()
                         local gui = player.PlayerGui:FindFirstChild("Invasion") or player.PlayerGui:FindFirstChild("BossRush")
                         if gui and gui.Enabled then
                             gui.Enabled = false
                             -- Ensure we click 'Join' if it's there
                             local joinBtn = gui:FindFirstChild("Join") or (gui:FindFirstChild("Main") and gui.Main:FindFirstChild("Join"))
                             if joinBtn then
                                 for _, c in pairs(getconnections(joinBtn.MouseButton1Click)) do c:Fire() end
                                 for _, c in pairs(getconnections(joinBtn.MouseButton1Up)) do c:Fire() end
                             end
                         end
                     end)
                end
                
                -- [NEW] BOSS RUSH AUTOMATION
                if Flags.BossRushDBZ or Flags.BossRushJJK then
                    local BR_Folder = Remotes:FindFirstChild("BossRush")
                    if BR_Folder then
                        local BR_Start = BR_Folder:FindFirstChild("BossRushStart")
                        local BR_Remote = BR_Folder:FindFirstChild("BossRushRemote")
                        local Mode = Flags.BossRushDBZ and "DbzBossRush" or "JjkBossRush"
                        
                        -- Prevent spam joining if already in Boss Rush map
                        local maps = Workspace:FindFirstChild("Maps")
                        local inBR = maps and maps:FindFirstChild(Mode)
                        if inBR then
                            local brF = Workspace:FindFirstChild("BossRushNpc") and Workspace.BossRushNpc:FindFirstChild(Mode)
                            if brF and CountLiveEnemies(brF) == 0 then inBR = false end
                        end
                        
                        if not inBR then
                            -- Throttle join attempts (every 5 seconds)
                            if not getgenv().LastBRJoinAttempt or (tick() - getgenv().LastBRJoinAttempt > 5) then
                                getgenv().LastBRJoinAttempt = tick()
                                -- print("[Nebublox] Attempting to join Boss Rush: " .. Mode)
                                
                                pcall(function()
                                    if BR_Start then
                                        -- print("[BossRush] Found 'BossRushStart'") -- Debug
                                        -- String Args
                                        BR_Start:FireServer("StartUi", Mode)
                                        BR_Start:FireServer("Start", Mode)
                                        BR_Start:FireServer("Join", Mode)
                                        -- Table Args (New Hypothesis)
                                        BR_Start:FireServer({Action = "Start", Mode = Mode, BossRushName = Mode})
                                        BR_Start:FireServer({Action = "Join", Mode = Mode, BossRushName = Mode})
                                        BR_Start:FireServer({Action = "Enter", Mode = Mode, BossRushName = Mode})
                                    end
                                    if BR_Remote then
                                        -- String Args
                                        BR_Remote:FireServer("OpenBossRushFrame", Mode) 
                                        BR_Remote:FireServer("StartUi", Mode)
                                        BR_Remote:FireServer("Start", Mode)
                                        BR_Remote:FireServer("Join", Mode)
                                        
                                        -- Table Args (Comprehensive)
                                        local tableActions = {"Start", "Join", "Enter", "OpenUi", "OpenBossRushFrame"}
                                        for _, act in ipairs(tableActions) do
                                            BR_Remote:FireServer({Action = act, Mode = Mode, BossRushName = Mode})
                                        end
                                        
                                        BR_Remote:FireServer({BossRushName = Mode, Action = "Update"}) -- Update check
                                    end
                                end)
                            end
                        end
                    end
                end
                
                -- Try scanning all Remotes for invasion-related names
                pcall(function()
                    for _, remote in ipairs(Remotes:GetDescendants()) do
                        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                            local name = remote.Name:lower()
                            if name:find("invasion") then
                                foundRemote = true
                                pcall(function() remote:FireServer("Start", "DemonSlayerInvasion") end)
                                pcall(function() remote:FireServer("Enter", "DemonSlayerInvasion") end)
                                pcall(function() remote:FireServer("Join", "DemonSlayerInvasion") end)
                                pcall(function() remote:FireServer("DemonSlayerInvasion") end)
                            end
                        end
                    end
                end)
            end
            
            -- Boss - Only if NOT in Trial area
            if (Flags.BossRushDBZ or Flags.BossRushJJK) and not InTrialArea then
                 local BR = Remotes.BossRush
                 local mode = Flags.BossRushDBZ and "DbzBossRush" or "JjkBossRush"
                 -- Silent Mode: Disable Client Listener
                 if getconnections then 
                    if BR and BR.BossRushRemote then for _, c in pairs(getconnections(BR.BossRushRemote.OnClientEvent)) do c:Disable() end end
                 end
                 if BR and BR.BossRushStart then BR.BossRushStart:FireServer("StartUi", mode) end
            end
            
            -- Gacha & Misc
            local SP = Remotes.SpecialPerkRemotes and Remotes.SpecialPerkRemotes:FindFirstChild("SpecialPerk")
            if SP then
                local function Roll(n) SP:FireServer("Spin", n) end
                if Flags.OnePieceFruit then Roll("OnePieceFruit") end
                if Flags.OnePieceCrew then Roll("OnePieceCrew") end
                if Flags.DbzSaiyan then Roll("DbzSaiyan") end
                if Flags.NarutoKekkeiGenkai then Roll("NarutoKekkeiGenkai") end
                if Flags.NarutoClan then Roll("NarutoClan") end
                if Flags.NarutoTailedBeast then Roll("NarutoTailedBeast") end
                if Flags.JjkDomain then Roll("JjkDomain") end
                
                -- Demon World Gachas
                if Flags.SlayerBreathing then 
                    -- Silent Mode: Disable Client Listener for ALL Gacha if rolling
                    if getconnections and SP and SP.OnClientEvent then for _, c in pairs(getconnections(SP.OnClientEvent)) do c:Disable() end end
                    -- SP:FireServer("OpenFrame", "DemonSlayerBreathing") -- REMOVED
                    SP:FireServer("Spin", "DemonSlayerBreathing") 
                end
                if Flags.SlayerArt then 
                    if getconnections and SP and SP.OnClientEvent then for _, c in pairs(getconnections(SP.OnClientEvent)) do c:Disable() end end
                    SP:FireServer("Spin", "DemonSlayerArt") 
                end
            end
            
            -- Trial Upgrades
            if Remotes.TimeTrial then
                local UpRemote = Remotes.TimeTrial:FindFirstChild("TimeTrialUpgrade")
                if UpRemote then
                    -- Silent Mode: Block 'OpenUi' and 'SuccessfulUpgrade' prompts
                    if getconnections then for _, c in pairs(getconnections(UpRemote.OnClientEvent)) do c:Disable() end end
                    
                    if Flags.TrialUpgradeStrength then UpRemote:FireServer("UpgradeStat", "StrengthMultiplier") end
                    if Flags.TrialUpgradeGems then UpRemote:FireServer("UpgradeStat", "GemMultiplier") end
                    if Flags.TrialUpgradeDrops then UpRemote:FireServer("UpgradeStat", "DropsMultiplier") end
                    if Flags.TrialUpgradeLuck then UpRemote:FireServer("UpgradeStat", "LuckMultiplier") end
                    if Flags.TrialUpgradeWalkspeed then UpRemote:FireServer("UpgradeStat", "WalkspeedMultiplier") end
                end
            end
            
            if SpecialProgressionRemote then
                -- Silent Mode: Block "Not enough tokens to roll!" and other prompts
                if getconnections and SpecialProgressionRemote.OnClientEvent then 
                    pcall(function() for _, c in pairs(getconnections(SpecialProgressionRemote.OnClientEvent)) do c:Disable() end end)
                end
                if Flags.KiProgression then SpecialProgressionRemote:FireServer("UpgradeProgression", "KiProgression") end
                if Flags.CursedProgression then SpecialProgressionRemote:FireServer("UpgradeProgression", "CursedEnergyProgression") end
                if Flags.HakiProgression then SpecialProgressionRemote:FireServer("UpgradeProgression", "HakiProgression") end
            end

            if Flags.AutoRebirth and Remotes.Rebirth then 
                Remotes.Rebirth:FireServer("Rebirth") 
                -- Anti-Notification (Try to disable listener)
                if getconnections then
                    for _, c in pairs(getconnections(Remotes.Rebirth.OnClientEvent)) do c:Disable() end
                end
            end
            if Flags.AutoTimedRewards and Remotes.TimedRewards then 
                -- Silent UI: Disable 'CannotClaim' prompts
                if getconnections then for _, c in pairs(getconnections(Remotes.TimedRewards.OnClientEvent)) do c:Disable() end end
                
                -- Rewards 1-8 (User Confirmed)
                for i=1,8 do 
                    Remotes.TimedRewards:FireServer("TimedReward"..i) 
                    Remotes.TimedRewards:FireServer("Reward"..i)
                end 
            end
            
            -- [SAFETY ENFORCEMENT - PAUSE LOGIC]
            -- Instead of forcing SmartFarm=false, we just ensure GetSmartTarget ignores farming
            -- while gamemode is active. This allows SmartFarm to "resume" automatically.
            
            -- Trial/Invasion Return Logic (CLEANED)
            if PerformReturn then
                local now = tick()
                local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if not root then return end
                
                -- Check Trial State
                local tf = Workspace:FindFirstChild("TrialRoomNpc")
                -- local InTrialNow = tf and CountLiveEnemies(tf) > 0 -- Moved to top

                -- State Tracking (Moved to top)
                -- if Flags.AutoInvasionStart then ... end
                local InInvasionNow = invF and CountLiveEnemies(invF) > 0
                
                -- Track Invasion State
                if Flags.AutoInvasionStart then
                    if InInvasionNow then
                        InInvasion = true
                        LastInvasionCheck = now
                    end
                end
                
                -- TRIAL RETURN: If we joined a trial AND it's now empty
                -- Removed 300s timeout to allow long runs
                -- ADDED: TrialSuccess check
                if Flags.AutoTrial and (now - LastTrialJoinTime > 10) then
                    if not InTrialArea then
                        if getgenv().TrialSuccess then
                            -- print("[Nebublox] Trial Success Verified! Returning...")
                            -- Trial ended! Perform return
                            local internalName = MapDisplayToInternal[SelectedReturnMap] or SelectedReturnMap
                            
                            -- Check for saved position match
                            if SavedCFrame and getgenv().SavedMapInternalName then
                                local savedMap = getgenv().SavedMapInternalName:lower()
                                if internalName:lower() == savedMap then
                                    root.CFrame = SavedCFrame
                                    ANUI:Notify({Title = "Trial Complete!", Content = "Returned to saved spot in " .. SelectedReturnMap, Icon = "check", Duration = 3})
                                    LastTrialJoinTime = now + 999999
                                    getgenv().TrialSuccess = false -- Reset
                                    return
                                end
                            end
                            
                            -- Use World Remote for spawn teleport
                            local WorldRemote = Remotes:FindFirstChild("World")
                            local teleported = false
                            pcall(function()
                                if WorldRemote then
                                    -- Try multiple teleport call formats
                                    WorldRemote:FireServer("Teleport", internalName)
                                    WorldRemote:FireServer(internalName, "Teleport")
                                    WorldRemote:FireServer("TeleportToWorld", internalName)
                                    ANUI:Notify({Title = "Trial Complete!", Content = "Returned to: " .. SelectedReturnMap, Icon = "map-pin", Duration = 3})
                                    teleported = true
                                end
                            end)
                            
                            if not teleported then
                                -- Fallback: Try Maps folder teleport
                                local maps = Workspace:FindFirstChild("Maps")
                                local targetMap = maps and maps:FindFirstChild(internalName)
                                local spawn = targetMap and (targetMap:FindFirstChild("Spawn") or targetMap:FindFirstChild("SpawnPoint"))
                                if spawn then
                                    root.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
                                    ANUI:Notify({Title = "Trial Complete!", Content = "Teleported to: " .. SelectedReturnMap, Icon = "map-pin", Duration = 3})
                                end
                            end
                            
                            LastTrialJoinTime = now + 999999
                            getgenv().TrialSuccess = false -- Reset
                        else
                             -- print("[Nebublox] Trial Ended but Success NOT detected. Staying in lobby.")
                        end
                    end
                end
                
                -- INVASION RETURN: If we were in invasion AND it's now empty for 5s
                if Flags.AutoInvasionStart and InInvasion and not InInvasionNow and (now - LastInvasionCheck > 5) then
                    InInvasion = false -- Reset
                    local internalName = MapDisplayToInternal[SelectedReturnMap] or SelectedReturnMap
                    
                    local WorldRemote = Remotes:FindFirstChild("World")
                    if WorldRemote then
                        -- Try multiple teleport call formats
                        pcall(function() WorldRemote:FireServer("Teleport", internalName) end)
                        pcall(function() WorldRemote:FireServer(internalName, "Teleport") end)
                        pcall(function() WorldRemote:FireServer("TeleportToWorld", internalName) end)
                        pcall(function() WorldRemote:FireServer(internalName) end)
                        ANUI:Notify({Title = "Invasion Complete!", Content = "Returned to: " .. SelectedReturnMap, Icon = "map-pin", Duration = 3})
                    else
                        -- Fallback: Direct teleport to map spawn
                        local maps = Workspace:FindFirstChild("Maps")
                        local targetMap = maps and maps:FindFirstChild(internalName)
                        local spawn = targetMap and (targetMap:FindFirstChild("Spawn") or targetMap:FindFirstChild("SpawnPoint"))
                        if spawn then
                            root.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
                            ANUI:Notify({Title = "Invasion Complete!", Content = "Teleported to: " .. SelectedReturnMap, Icon = "map-pin", Duration = 3})
                        end
                    end
                end
            end
        end)
    end
end)

-- AUTO TRIAL JOIN
task.spawn(function()
    pcall(function()
        if not getgenv().NebuBlox_TrialConnection then
            local TimeTrial = Remotes:WaitForChild("TimeTrial", 5)
            if not TimeTrial then return end
            
            getgenv().NebuBlox_TrialConnection = TimeTrial.TrialEffects.OnClientEvent:Connect(function(action, trialType)
                 -- print("[Trial Debug] Event Action:", action) -- Debug print
                 
                 if action == "NotifyBeforeStart" then
                     getgenv().TrialSuccess = false
                 elseif action == "Success" or action == "TrialComplete" or action == "Victory" or action == "Rewards" then
                     getgenv().TrialSuccess = true
                     -- print("[Nebublox] Trial Success Flag SET!")
                 end

                 if Flags.AutoTrial and action == "NotifyBeforeStart" and trialType == "EasyTrial" then
                     if PerformReturn and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                         SavedCFrame = player.Character.HumanoidRootPart.CFrame
                         LastTrialJoinTime = tick()
                     end
                     ANUI:Notify({Title = "Trial", Content = "Joining Easy Trial...", Icon = "clock", Duration = 3})
                     
                     -- Auto Potion
                     if Flags.AutoDropPotion then
                         local PotionRemote = Remotes:FindFirstChild("Potion")
                         if PotionRemote then PotionRemote:FireServer("DropsPotion") end
                     end
                     
                     task.wait(2)
                     TimeTrial.UpdateUi:FireServer("JoinTrial", "EasyTrial")
                     task.delay(0.5, function()
                         pcall(function()
                             local gui = player.PlayerGui.GamemodeWarning
                             if gui then
                                 gui.Enabled = false 
                                 for _, c in pairs(getconnections(gui.Buttons.Confirm.MouseButton1Up)) do c:Fire() end
                                 task.delay(1, function() gui.Enabled = true end)
                             end
                         end)
                     end)
                 end
            end)
        end
    end)
end)

ANUI:Notify({Title = "Nebublox", Content = "Loaded v3.2 (Optimized Logic)", Icon = "check", Duration = 5})