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

local ANUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/ANHub-Script/ANUI/refs/heads/main/dist/main.lua"))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer

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
local LastTrialJoinTime = math.huge 
local InInvasion = false 
local LastInvasionCheck = 0
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
    IconSize = 64,
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
                        img.Size = UDim2.new(1, 0, 1, 0)
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
                    frame.Size = UDim2.new(1, -10, 0, 120)
                    frame.Position = paragraph.Position
                    frame.BackgroundTransparency = 1
                    frame.Image = imgId
                    frame.ScaleType = Enum.ScaleType.Fit
                    frame.Parent = section
                    paragraph:Destroy()
                    return true
                end
            end
        end
    end
    if not FindAndInjectImage(game:GetService("CoreGui")) then FindAndInjectImage(player.PlayerGui) end
end)

local AboutSection = MainTab:Section({ Title = "Welcome!", Icon = "smile", Opened = true })
AboutSection:Paragraph({
    Title = "Thank You!",
    Content = [[Thank you for using my script, I hope you enjoy!

Do you have any feedback or have ideas? 
Join our Discord server.

Drop your concepts in #dark-visions
Request a #forbidden-script]]
})

AboutSection:Button({
    Title = "Copy Discord Link",
    Callback = function()
        setclipboard("https://discord.gg/nebublox")
        ANUI:Notify({Title = "Discord", Content = "Link copied to clipboard!", Icon = "copy", Duration = 3})
    end
})

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

-- [TAB 3: TRIAL]
local TrialTab = Window:Tab({ Title = "Trial", Icon = "clock" })
local TrialSection = TrialTab:Section({ Title = "Easy Time Trial", Icon = "play", Opened = true })
TrialSection:Toggle({ Title = "Auto Join Trial", Value = false, Callback = function(s) 
    Flags.AutoTrial = s
    -- DO NOT set AutoTrialFarm - user only wants to join, not farm
    if s and (not SavedCFrame or SavedCFrame == nil) and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        SavedCFrame = player.Character.HumanoidRootPart.CFrame
        ANUI:Notify({Title = "Position Saved", Content = "Auto-saved current spot for return.", Icon = "pin", Duration = 3})
    end
end })
TrialSection:Toggle({ Title = "Return After (Trial/Invasion)", Value = false, Callback = function(s) PerformReturn = s end })

TrialSection:Button({
    Title = "Save Current Position (For Return)",
    Callback = function()
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if root then
            SavedCFrame = root.CFrame
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
            getgenv().SavedMapInternalName = currentMap
            ANUI:Notify({Title = "Position Saved", Content = "Saved for: " .. currentMap, Icon = "check", Duration = 3})
        else
            ANUI:Notify({Title = "Error", Content = "Character not found!", Icon = "alert-triangle", Duration = 3})
        end
    end
})

TrialSection:Toggle({ Title = "Auto Drop Potion (On Start)", Value = false, Callback = function(s) Flags.AutoDropPotion = s end })
TrialSection:Toggle({ Title = "Attack ALL (Trial Only)", Value = false, Callback = function(s) Flags.TrialAttackAll = s end })

-- [TAB 3: CHAMPIONS]
local ChampionsTab = Window:Tab({ Title = "Champions", Icon = "egg" })
local EggSection = ChampionsTab:Section({ Title = "Auto Hatch Champions", Icon = "egg", Opened = true })
EggSection:Toggle({ Title = "Auto Hatch One Piece", Value = false, Callback = function(s) Flags.HatchOnePiece = s end })
EggSection:Toggle({ Title = "Auto Hatch Naruto", Value = false, Callback = function(s) Flags.HatchNaruto = s end })
EggSection:Toggle({ Title = "Auto Hatch JJK", Value = false, Callback = function(s) Flags.HatchJJK = s end })
EggSection:Toggle({ Title = "Auto Hatch Demon Slayer", Value = false, Callback = function(s) Flags.HatchSlayer = s end })
EggSection:Toggle({ Title = "Auto Hatch Dragon Ball", Value = false, Callback = function(s) Flags.HatchDBZ = s end })

EggSection:Button({
    Title = "Disable Egg Animation (Experimental)",
    Callback = function()
        local Event = game:GetService("ReplicatedStorage").Remotes.Egg.EggNotification
        local success, err = pcall(function()
            for _, Connection in pairs(getconnections(Event.OnClientEvent)) do
                if hookfunction then
                     local old; old = hookfunction(Connection.Function, function(...) return end)
                else Connection:Disable() end
            end
        end)
        if success then ANUI:Notify({Title = "Animations", Content = "Attempted to disable egg UI!", Icon = "check", Duration = 3}) end
    end
})

-- [TAB 4: GAMEMODES (SWAPPED LOGIC)]
local GamemodesTab = Window:Tab({ Title = "Gamemodes", Icon = "swords" })

local BossSection = GamemodesTab:Section({ Title = "World Boss Rushes", Icon = "skull", Opened = true })
BossSection:Toggle({ Title = "Auto World Boss Rush ( Z World)", Value = false, Callback = function(s) Flags.BossRushDBZ = s end })
BossSection:Toggle({ Title = "Auto World Boss Rush ( Cursed World)", Value = false, Callback = function(s) Flags.BossRushJJK = s end })

local InvSection = GamemodesTab:Section({ Title = "Invasion", Icon = "shield", Opened = true })
InvSection:Toggle({ Title = "Auto Invasion (Slayer World)", Value = false, Callback = function(s) Flags.AutoInvasionStart = s end })
InvSection:Button({
    Title = "Force Start Invasion (Debug)",
    Callback = function()
        local InvStart = Remotes.Invasion and Remotes.Invasion:FindFirstChild("InvasionStart")
        if InvStart then
            InvStart:FireServer("StartUi", "DemonSlayerInvasion")
            ANUI:Notify({Title = "Debug", Content = "Fired StartUi -> DemonSlayerInvasion", Icon = "zap", Duration = 3})
        else
            ANUI:Notify({Title = "Error", Content = "Remote Not Found!", Icon = "alert-triangle", Duration = 3})
        end
    end
})

-- [TAB 4: GACHA]
local GachaTab = Window:Tab({ Title = "Gacha", Icon = "gift" })
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
MiscSection:Toggle({ Title = "Auto Rebirth", Value = false, Callback = function(s) Flags.AutoRebirth = s end })
MiscSection:Toggle({ Title = "Claim Timed Rewards", Value = false, Callback = function(s) Flags.AutoTimedRewards = s end })

local UpgradeSection = MiscTab:Section({ Title = "Trial Upgrades", Icon = "trending-up" })
UpgradeSection:Toggle({ Title = "Auto Upgrade Strength", Value = false, Callback = function(s) Flags.TrialUpgradeStrength = s end })
UpgradeSection:Toggle({ Title = "Auto Upgrade Gems", Value = false, Callback = function(s) Flags.TrialUpgradeGems = s end })
UpgradeSection:Toggle({ Title = "Auto Upgrade Drops", Value = false, Callback = function(s) Flags.TrialUpgradeDrops = s end })
UpgradeSection:Toggle({ Title = "Auto Upgrade Luck", Value = false, Callback = function(s) Flags.TrialUpgradeLuck = s end })
UpgradeSection:Toggle({ Title = "Auto Upgrade Walkspeed", Value = false, Callback = function(s) Flags.TrialUpgradeWalkspeed = s end })

-- [TAB 6: SETTINGS]
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })
local ConfigSection = SettingsTab:Section({ Title = "Configuration Manager", Icon = "folder", Opened = true })
ConfigSection:Input({ Title = "Config Name", Placeholder = "Enter config name...", Callback = function(text) ConfigNameInput = text end })

-- [CUSTOM CONFIG SELECTOR]
local function CreateConfigSelector(parent)
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "ConfigSelectorFrame"
    MainFrame.Size = UDim2.new(1, -10, 0, 230) -- Increased Height
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = parent
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

    local Header = Instance.new("TextLabel")
    Header.Size = UDim2.new(1, 0, 0, 30)
    Header.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    Header.Text = "📁 Saved Configs"
    Header.TextColor3 = Color3.fromRGB(255, 255, 255)
    Header.TextSize = 13
    Header.Font = Enum.Font.GothamBold
    Header.Parent = MainFrame
    Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 8)

    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Size = UDim2.new(1, -10, 1, -85) -- Adjusted for buttons
    ScrollFrame.Position = UDim2.new(0, 5, 0, 35)
    ScrollFrame.BackgroundTransparency = 1
    ScrollFrame.BorderSizePixel = 0
    ScrollFrame.ScrollBarThickness = 4
    ScrollFrame.Parent = MainFrame
    
    local ListLayout = Instance.new("UIListLayout"); ListLayout.SortOrder = Enum.SortOrder.Name; ListLayout.Padding = UDim.new(0, 4); ListLayout.Parent = ScrollFrame

    local function RefreshConfigList()
        for _, c in pairs(ScrollFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        local configs = ConfigSystem.GetConfigs()
        if #configs == 0 then
            local noConfigs = Instance.new("TextLabel")
            noConfigs.Name = "NoConfigs"; noConfigs.Size = UDim2.new(1, -10, 0, 28); noConfigs.BackgroundTransparency = 1
            noConfigs.Text = "No configs saved yet"; noConfigs.TextColor3 = Color3.fromRGB(120, 120, 120); noConfigs.TextSize = 12; noConfigs.Font = Enum.Font.Gotham; noConfigs.Parent = ScrollFrame
        else
            for _, name in ipairs(configs) do
                local btn = Instance.new("TextButton")
                btn.Name = name; btn.Size = UDim2.new(1, -10, 0, 28)
                btn.BackgroundColor3 = (ConfigNameInput == name) and Color3.fromRGB(80, 150, 80) or Color3.fromRGB(50, 50, 60)
                btn.Text = "  📄 " .. name; btn.TextColor3 = Color3.fromRGB(220, 220, 220); btn.TextSize = 12; btn.Font = Enum.Font.Gotham; btn.TextXAlignment = Enum.TextXAlignment.Left; btn.Parent = ScrollFrame
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
                btn.MouseButton1Click:Connect(function()
                    ConfigNameInput = name
                    for _, b in pairs(ScrollFrame:GetChildren()) do if b:IsA("TextButton") then b.BackgroundColor3 = (b.Name == name) and Color3.fromRGB(80, 150, 80) or Color3.fromRGB(50, 50, 60) end end
                    ANUI:Notify({Title = "Selected", Content = name, Icon = "check", Duration = 2})
                end)
            end
        end
        ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 5)
    end
    
    -- Action Buttons Area
    local ButtonFrame = Instance.new("Frame")
    ButtonFrame.Size = UDim2.new(1, -10, 0, 40)
    ButtonFrame.Position = UDim2.new(0, 5, 1, -45)
    ButtonFrame.BackgroundTransparency = 1
    ButtonFrame.Parent = MainFrame
    
    local UIGrid = Instance.new("UIGridLayout")
    UIGrid.CellSize = UDim2.new(0.23, 0, 1, 0)
    UIGrid.CellPadding = UDim2.new(0.02, 0, 0, 0)
    UIGrid.Parent = ButtonFrame
    
    local function AddBtn(text, color, callback)
        local b = Instance.new("TextButton")
        b.Text = text
        b.BackgroundColor3 = color
        b.TextColor3 = Color3.new(1,1,1)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 11
        b.Parent = ButtonFrame
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        b.MouseButton1Click:Connect(callback)
    end
    
    AddBtn("SAVE", Color3.fromRGB(60, 160, 60), function()
        if ConfigNameInput ~= "" then 
            ConfigSystem.SaveConfig(ConfigNameInput)
            RefreshConfigList()
            ANUI:Notify({Title = "Saved", Content = ConfigNameInput, Icon = "save", Duration = 2})
        else 
            ANUI:Notify({Title = "Error", Content = "Enter name!", Icon = "alert-triangle", Duration = 2}) 
        end
    end)
    
    AddBtn("LOAD", Color3.fromRGB(60, 100, 200), function()
        if ConfigNameInput ~= "" then 
            ConfigSystem.LoadConfig(ConfigNameInput)
        else 
            ANUI:Notify({Title = "Error", Content = "Select config!", Icon = "alert-triangle", Duration = 2}) 
        end
    end)
    
    AddBtn("DEL", Color3.fromRGB(200, 60, 60), function()
        if ConfigNameInput ~= "" then 
            ConfigSystem.DeleteConfig(ConfigNameInput)
            RefreshConfigList()
            ANUI:Notify({Title = "Deleted", Content = ConfigNameInput, Icon = "trash", Duration = 2})
        else 
            ANUI:Notify({Title = "Error", Content = "Select config!", Icon = "alert-triangle", Duration = 2}) 
        end
    end)
    
    AddBtn("REFRESH", Color3.fromRGB(100, 100, 100), function()
         RefreshConfigList()
         ANUI:Notify({Title = "Refreshed", Content = "Config List", Icon = "refresh", Duration = 1})
    end)

    RefreshConfigList()
    return RefreshConfigList
end

task.spawn(function()
    task.wait(2)
    local function FindSettingsSection(root)
        if not root then return nil end
        for _, obj in ipairs(root:GetDescendants()) do
            if obj:IsA("TextLabel") and obj.Text == "Configuration Manager" then
                local section = obj.Parent and obj.Parent.Parent
                if section then return section end
            end
        end
        return nil
    end
    local section = FindSettingsSection(game:GetService("CoreGui")) or FindSettingsSection(player.PlayerGui)
    if section then getgenv().RefreshConfigSelector = CreateConfigSelector(section) end
end)


ConfigSection:Toggle({ Title = "Autoload on Startup", Value = getgenv().NebubloxSettings.AutoLoad, Callback = function(s) getgenv().NebubloxSettings.AutoLoad = s end })

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
            if v:IsA("Humanoid") and v.Health > 0 then
                count = count + 1
            end
        end
    end
    return count
end

local function GetTarget()
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local whitelistActive = false
    for _ in pairs(SelectedEnemies) do whitelistActive = true; break end

    -- Sticky Logic
    local current = getgenv().CurrentTarget
    if current and current.Parent and current:FindFirstChild("Humanoid") and current.Humanoid.Health > 0 then
        if whitelistActive and not SelectedEnemies[current.Name] then
            -- Drop
        else
            if (current.HumanoidRootPart.Position - myRoot.Position).Magnitude < 300 then return current end
        end
    end

    local best = nil
    local shortest = math.huge

    local function Scan(folder)
        if not folder then return end
        for _, v in ipairs(folder:GetDescendants()) do
            if v:IsA("Humanoid") and v.Health > 0 and v.Parent and v.Parent:FindFirstChild("HumanoidRootPart") then
                local mob = v.Parent
                if whitelistActive and not SelectedEnemies[mob.Name] then continue end
                local d = (mob.HumanoidRootPart.Position - myRoot.Position).Magnitude
                if d < shortest then
                    shortest = d
                    best = mob
                end
            end
        end
    end

    -- Priority
    if Flags.BossRushDBZ or Flags.BossRushJJK then
        Scan(Workspace.Maps)
    elseif Flags.AutoInvasionStart then
        Scan(Workspace:FindFirstChild("InvasionNpc"))
        Scan(Workspace.Maps:FindFirstChild("DemonSlayerInvasion"))
    else
        Scan(Workspace:FindFirstChild("Npc"))
        Scan(Workspace:FindFirstChild("TrialRoomNpc"))
    end
    return best
end

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
        
        local hum = char:FindFirstChild("Humanoid")
        if hum and hum.WalkSpeed ~= 70 then hum.WalkSpeed = 70 end

        -- PRIORITY 1: Trial
        local tf = Workspace:FindFirstChild("TrialRoomNpc")
        local InTrial = tf and #tf:GetChildren() > 0
        
        if InTrial and Flags.AutoTrialFarm then
            local t = getgenv().NebuBlox_CurrentTarget
            if t and t.Parent and t:FindFirstChild("Humanoid") and t.Humanoid.Health > 0 and t:FindFirstChild("HumanoidRootPart") then
                root.CFrame = t.HumanoidRootPart.CFrame * CFrame.new(0,0,3)
                root.AssemblyLinearVelocity = Vector3.zero
            end
            return
        end
        
        -- PRIORITY 2: Invasion
        local invF = Workspace:FindFirstChild("InvasionNpc")
        local invBoss = Workspace.Maps:FindFirstChild("DemonSlayerInvasion")
        local InInvasion = (invF and #invF:GetChildren() > 0) or (invBoss and invBoss:FindFirstChild("NpcSpawns") and #invBoss.NpcSpawns:GetChildren() > 0)
        
        if InInvasion and Flags.AutoInvasionStart then
             local t = getgenv().NebuBlox_CurrentTarget
             if t and t.Parent and t:FindFirstChild("Humanoid") and t.Humanoid.Health > 0 and t:FindFirstChild("HumanoidRootPart") then
                 root.CFrame = t.HumanoidRootPart.CFrame * CFrame.new(0,0,3)
                 root.AssemblyLinearVelocity = Vector3.zero
             end
             return
        end

        -- PRIORITY 3: Boss Rush
        if Flags.BossRushDBZ or Flags.BossRushJJK then
             local tc = nil
             if Flags.BossRushDBZ then local s = GetBossSpawn("Dbz"); if s then tc = s.CFrame * CFrame.new(0,0,2) end
             elseif Flags.BossRushJJK then local s = GetBossSpawn("Jjk"); if s then tc = s.CFrame * CFrame.new(0,0,2) end end
             
             if tc then root.CFrame = tc; root.AssemblyLinearVelocity = Vector3.zero end
             return
        end

        -- PRIORITY 4: Smart Farm
        if Flags.SmartFarm then
            local t = getgenv().NebuBlox_CurrentTarget
            if t and t.Parent and t:FindFirstChild("Humanoid") and t.Humanoid.Health > 0 and t:FindFirstChild("HumanoidRootPart") then
                 root.CFrame = t.HumanoidRootPart.CFrame * CFrame.new(0,0,3)
                 root.AssemblyLinearVelocity = Vector3.zero
            end
        end
    end)
end)

task.spawn(function()
    while task.wait(0.15) do
        if getgenv().NebuBlox_SessionID ~= SessionID then break end
        if Flags.SmartFarm or Flags.AutoTrialFarm or Flags.AutoInvasionStart or Flags.BossRushDBZ or Flags.BossRushJJK then 
             local t = GetTarget()
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

task.spawn(function()
    while task.wait(0.5) do
        if getgenv().NebuBlox_SessionID ~= SessionID then 
            if HatchOverlay then HatchOverlay:Destroy() end
            break 
        end
        local targetEgg = nil
        local eggName = ""
        if Flags.HatchOnePiece then targetEgg = Workspace.Eggs.OnePiece.OnePiece.EggModel.Egg; eggName = "One Piece" end
        if Flags.HatchNaruto then targetEgg = Workspace.Eggs.Naruto.Naruto.EggModel:FindFirstChild("Egeg") or Workspace.Eggs.Naruto.Naruto.EggModel:FindFirstChild("Egg"); eggName = "Naruto" end
        if Flags.HatchJJK then targetEgg = Workspace.Eggs.Jjk.Jjk.EggModel.Egg; eggName = "JJK" end
        if Flags.HatchSlayer then targetEgg = Workspace.Eggs.DemonSlayer.DemonSlayer.EggModel.Egg; eggName = "Demon Slayer" end
        if Flags.HatchDBZ then targetEgg = Workspace.Eggs.Dbz.Dbz.EggModel.Egg; eggName = "Dragon Ball" end
        
        if targetEgg then
            UpdateHatchUI("Hatching: " .. eggName)
            pcall(function()
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    player.Character.HumanoidRootPart.CFrame = targetEgg.CFrame * CFrame.new(0,0,3)
                end
                local EggRemote = Remotes.Egg and Remotes.Egg:FindFirstChild("Egg")
                if EggRemote then EggRemote:FireServer("AutoHatch") end
            end)
        else
            UpdateHatchUI(nil)
        end
    end
end)

-- AUTOMATION & SWAPPED GAMEMODE LOGIC
task.spawn(function()
    local SpecialProgressionRemote = Remotes:WaitForChild("SpecialProgression", 5)
    
    while task.wait(0.5) do
        if getgenv().NebuBlox_SessionID ~= SessionID then break end
        pcall(function()
            -- Auto Join Trial (Easy)
            local tf = Workspace:FindFirstChild("TrialRoomNpc")
            local InTrial = tf and #tf:GetChildren() > 0
            
            if Flags.AutoTrial and Remotes.TimeTrial then
                local TTR = Remotes.TimeTrial:FindFirstChild("TimeTrialRemote")
                if TTR then
                    if not InTrial then
                        if (tick() - LastTrialJoinTime > 15) then
                             TTR:FireServer("Enter")
                             LastTrialJoinTime = tick()
                        end
                    end
                end
            end
            
            -- INVASION MANAGER
            if Flags.AutoInvasionStart then 
                local invMap = Workspace.Maps:FindFirstChild("DemonSlayerInvasion")
                local invMobs = Workspace:FindFirstChild("InvasionNpc")
                local activeMobs = CountLiveEnemies(invMobs) + CountLiveEnemies(invMap)
                
                if activeMobs == 0 then
                    local InvStart = Remotes.Invasion and Remotes.Invasion:FindFirstChild("InvasionStart")
                    if InvStart then 
                        InvStart:FireServer("StartUi", "DemonSlayerInvasion")
                    end
                end
            end
            
            -- BOSS RUSH LOGIC
            if (Flags.BossRushDBZ or Flags.BossRushJJK) then
                 local mode = Flags.BossRushDBZ and "DbzBossRush" or "JjkBossRush"
                 local map = Workspace.Maps:FindFirstChild(mode)
                 local enemies = CountLiveEnemies(map)
                 
                 if enemies == 0 then
                     local br = Remotes.BossRush
                     if br and br:FindFirstChild("BossRushStart") then
                         br.BossRushStart:FireServer("StartUi", mode)
                         if br:FindFirstChild(mode) then 
                             br[mode]:FireServer("Enter") 
                         end
                     end
                 end
            end

            
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
                
                if Flags.SlayerBreathing then 
                    if getconnections and SP and SP.OnClientEvent then for _, c in pairs(getconnections(SP.OnClientEvent)) do c:Disable() end end
                    SP:FireServer("Spin", "DemonSlayerBreathing") 
                end
                if Flags.SlayerArt then 
                    if getconnections and SP and SP.OnClientEvent then for _, c in pairs(getconnections(SP.OnClientEvent)) do c:Disable() end end
                    SP:FireServer("Spin", "DemonSlayerArt") 
                end
            end
            
            if Remotes.TimeTrial then
                local UpRemote = Remotes.TimeTrial:FindFirstChild("TimeTrialUpgrade")
                if UpRemote then
                    if getconnections then for _, c in pairs(getconnections(UpRemote.OnClientEvent)) do c:Disable() end end
                    
                    if Flags.TrialUpgradeStrength then UpRemote:FireServer("UpgradeStat", "StrengthMultiplier") end
                    if Flags.TrialUpgradeGems then UpRemote:FireServer("UpgradeStat", "GemMultiplier") end
                    if Flags.TrialUpgradeDrops then UpRemote:FireServer("UpgradeStat", "DropsMultiplier") end
                    if Flags.TrialUpgradeLuck then UpRemote:FireServer("UpgradeStat", "LuckMultiplier") end
                    if Flags.TrialUpgradeWalkspeed then UpRemote:FireServer("UpgradeStat", "WalkspeedMultiplier") end
                end
            end
            
            if SpecialProgressionRemote then
                if getconnections and SpecialProgressionRemote.OnClientEvent then 
                    pcall(function() for _, c in pairs(getconnections(SpecialProgressionRemote.OnClientEvent)) do c:Disable() end end)
                end
                if Flags.KiProgression then SpecialProgressionRemote:FireServer("UpgradeProgression", "KiProgression") end
                if Flags.CursedProgression then SpecialProgressionRemote:FireServer("UpgradeProgression", "CursedEnergyProgression") end
                if Flags.HakiProgression then SpecialProgressionRemote:FireServer("UpgradeProgression", "HakiProgression") end
            end

            if Flags.AutoRebirth and Remotes.Rebirth then 
                Remotes.Rebirth:FireServer("Rebirth") 
                if getconnections then for _, c in pairs(getconnections(Remotes.Rebirth.OnClientEvent)) do c:Disable() end end
            end
            if Flags.AutoTimedRewards and Remotes.TimedRewards then 
                if getconnections then for _, c in pairs(getconnections(Remotes.TimedRewards.OnClientEvent)) do c:Disable() end end
                for i=1,8 do 
                    Remotes.TimedRewards:FireServer("TimedReward"..i) 
                    Remotes.TimedRewards:FireServer("Reward"..i)
                end 
            end
            
            if PerformReturn then
                local now = tick()
                local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                
                if root then
                    local tf = Workspace:FindFirstChild("TrialRoomNpc")
                    local InTrialNow = tf and #tf:GetChildren() > 0
                    local invF = Workspace:FindFirstChild("InvasionNpc")
                    local InInvasionNow = invF and #invF:GetChildren() > 0
                    
                    if Flags.AutoInvasionStart then
                        if InInvasionNow then InInvasion = true; LastInvasionCheck = now end
                    end
                    
                    if Flags.AutoTrial and (now - LastTrialJoinTime > 10) then
                        if not InTrialNow then
                            if getgenv().TrialSuccess then
                                local internalName = MapDisplayToInternal[SelectedReturnMap] or SelectedReturnMap
                                local returnedToSave = false
                                if SavedCFrame and getgenv().SavedMapInternalName then
                                    local savedMap = getgenv().SavedMapInternalName:lower()
                                    if internalName:lower() == savedMap then
                                        root.CFrame = SavedCFrame
                                        ANUI:Notify({Title = "Trial Complete!", Content = "Returned to saved spot in " .. SelectedReturnMap, Icon = "check", Duration = 3})
                                        returnedToSave = true
                                    end
                                end
                                
                                if not returnedToSave then
                                    local WorldRemote = Remotes:FindFirstChild("World")
                                    local teleported = false
                                    pcall(function()
                                        if WorldRemote then
                                            WorldRemote:FireServer("Teleport", internalName)
                                            WorldRemote:FireServer(internalName, "Teleport")
                                            WorldRemote:FireServer("TeleportToWorld", internalName)
                                            ANUI:Notify({Title = "Trial Complete!", Content = "Returned to: " .. SelectedReturnMap, Icon = "map-pin", Duration = 3})
                                            teleported = true
                                        end
                                    end)
                                    if not teleported then
                                        local maps = Workspace:FindFirstChild("Maps")
                                        local targetMap = maps and maps:FindFirstChild(internalName)
                                        local spawn = targetMap and (targetMap:FindFirstChild("Spawn") or targetMap:FindFirstChild("SpawnPoint"))
                                        if spawn then
                                            root.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
                                            ANUI:Notify({Title = "Trial Complete!", Content = "Teleported to: " .. SelectedReturnMap, Icon = "map-pin", Duration = 3})
                                        end
                                    end
                                end
                                LastTrialJoinTime = now + 999999
                                getgenv().TrialSuccess = false
                            end
                        end
                    end
                    
                    if Flags.AutoInvasionStart and InInvasion and not InInvasionNow and (now - LastInvasionCheck > 5) then
                        InInvasion = false
                        pcall(function()
                            if firesignal then
                                local WorldRemote = Remotes:FindFirstChild("World")
                                if WorldRemote then firesignal(WorldRemote.OnClientEvent, "StartWorldEffects", "DemonSlayer"); ANUI:Notify({Title = "Invasion Done", Content = "Signaled World Return (Client)", Icon = "map", Duration = 3}) end
                                local GamemodeUi = Remotes:FindFirstChild("GamemodeUi")
                                if GamemodeUi then firesignal(GamemodeUi.OnClientEvent, "CloseGamemodeUi") end
                            else
                                 local WorldRemote = Remotes:FindFirstChild("World")
                                 if WorldRemote then WorldRemote:FireServer("Teleport", "DemonSlayer") end
                                 ANUI:Notify({Title = "Invasion Done", Content = "Fallback: Standard Teleport", Icon = "alert-triangle", Duration = 3})
                            end
                        end)
                    end
                end
            end
        end)
    end
end)

task.spawn(function()
    pcall(function()
        if not getgenv().NebuBlox_TrialConnection then
            local TimeTrial = Remotes:WaitForChild("TimeTrial", 5)
            if not TimeTrial then return end
            
            getgenv().NebuBlox_TrialConnection = TimeTrial.TrialEffects.OnClientEvent:Connect(function(action, trialType)
                 if action == "NotifyBeforeStart" then
                     getgenv().TrialSuccess = false
                 elseif action == "Success" or action == "TrialComplete" or action == "Victory" or action == "Rewards" then
                     getgenv().TrialSuccess = true
                 end

                 if Flags.AutoTrial and action == "NotifyBeforeStart" and trialType == "EasyTrial" then
                     if PerformReturn and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                         SavedCFrame = player.Character.HumanoidRootPart.CFrame
                         LastTrialJoinTime = tick()
                     end
                     ANUI:Notify({Title = "Trial", Content = "Joining Easy Trial...", Icon = "clock", Duration = 3})
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
                                if gui.Buttons and gui.Buttons.Confirm then
                                    for _, c in pairs(getconnections(gui.Buttons.Confirm.MouseButton1Up)) do c:Fire() end
                                end
                                task.delay(1, function() gui.Enabled = true end)
                             end
                         end)
                     end)
                 end
            end)
        end
    end)
end)

ANUI:Notify({Title = "Nebublox", Content = "Loaded v3.0 (Gamemode Logic Patched)", Icon = "check", Duration = 5})