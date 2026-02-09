-- // NEBUBLOX | ANIME STORM SIMULATOR 2 (v3.0: FRESH RE-INSTALL) //
print("/// NEBUBLOX v3.0 LOADED - " .. os.date("%X") .. " ///")
-- // UI Library: ANUI //

-- // 0. SESSION & CLEANUP //
local SessionID = tick() -- Unique ID for this execution
getgenv().NebuBlox_SessionID = SessionID

-- Simple disconnect helper
local function SafeDisconnect(conn)
    if conn then pcall(function() conn:Disconnect() end) end
end

if getgenv().NebuBlox_Loaded then
    -- KILL ALL RUNNING LOOPS
    getgenv().NebuBlox_Running = false
    task.wait(0.25) -- Give loops time to break
    
    -- Disconnect all connections
    SafeDisconnect(getgenv().NebuBlox_TrialConnection)
    SafeDisconnect(getgenv().NebuBlox_BossRushConnection)
    SafeDisconnect(getgenv().NebuBlox_BossRushUIConnection)
    SafeDisconnect(getgenv().NebuBlox_RenderSteppedConnection)
    SafeDisconnect(getgenv().NebuBlox_MovementConnection)
    SafeDisconnect(getgenv().NebuBlox_NoClipConnection)
    
    -- HARD CLEANUP (New)
    pcall(function()
        if getgenv().ANUI_Window then getgenv().ANUI_Window:Destroy() end
        local core = game:GetService("CoreGui")
        local uis = {"Nebublox", "ANUI", "Orion", "Shadow", "ScreenGui"}
        for _, n in ipairs(uis) do
            local f = core:FindFirstChild(n)
            if f then f:Destroy() end
        end
        if player.PlayerGui:FindFirstChild("Nebublox") then player.PlayerGui.Nebublox:Destroy() end
    end)
    
    -- Clear global refs
    getgenv().NebuBlox_TrialConnection = nil
    getgenv().NebuBlox_BossRushConnection = nil
    getgenv().NebuBlox_BossRushUIConnection = nil
    getgenv().ANUI_Window = nil
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
    TrialAttackAll = false, -- Renamed from AttackAll
    TargetName = "",
    
    AutoTrial = false,
    AutoTrialFarm = false, -- Synced with AutoTrial usually
    
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
local SelectedEnemies = {}  -- Multi-select
local LastTargetedTime = {} 

local SavedCFrame = nil
local PerformReturn = false -- Toggle for return feature (master switch, works for Trial & Invasion)
local SelectedReturnMap = "Same Spot" -- Dropdown value
local LastTrialJoinTime = math.huge -- Initialize to infinity so we don't return immediately on load
local InInvasion = false 
local LastInvasionCheck = 0
getgenv().TrialSuccess = false -- New global for tracking success

-- // CONFIG SYSTEM & PERFORMANCE BACKEND //
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

local FolderName = "Nebublox"
local ConfigsFolder = FolderName .. "/Configs"

-- Settings Table
getgenv().NebubloxSettings = {
    AutoLoad = false,
    LastConfig = "",
    AntiAfkEnabled = false
}

-- Ensure folders exist
pcall(function()
    if not isfolder(FolderName) then makefolder(FolderName) end
    if not isfolder(ConfigsFolder) then makefolder(ConfigsFolder) end
end)

local ConfigSystem = {}

function ConfigSystem.SaveConfig(name)
    if name == "" then 
        pcall(function() ANUI:Notify({Title = "Error", Content = "Enter a config name!", Icon = "alert-triangle", Duration = 3}) end)
        return 
    end
    
    local success, err = pcall(function()
        -- Check if functions exist
        if not writefile then error("writefile not available") end
        if not isfolder then error("isfolder not available") end
        
        -- Ensure folder exists
        if not isfolder(FolderName) then makefolder(FolderName) end
        if not isfolder(ConfigsFolder) then makefolder(ConfigsFolder) end
        
        -- Encode and save
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

-- Dynamic Map Scanner
-- Mapped Names for User Friendliness
local MapDisplayToInternal = {
    ["Z World"] = "Dbz",
    ["Cursed World"] = "Jjk",
    ["Shinobi World"] = "Naruto",
    ["Pirate World"] = "OnePiece",
    ["Slayer World"] = "DemonSlayer" -- Updated to Slayer World
}
local MapInternalToDisplay = {}
for k, v in pairs(MapDisplayToInternal) do MapInternalToDisplay[v] = k end

-- Dropdown Options (Sorted alphabetically by Display Name)
local MapOptions = {"Cursed World", "Pirate World", "Shinobi World", "Slayer World", "Z World"} 
local function RefreshMapOptions()
    -- Only these 5 are supported for now as per user request (Removed TimeTrialLobby, Saved Position, Same Spot)
end
RefreshMapOptions()

-- CLEANUP BLACKLIST LOOP
task.spawn(function()
    while task.wait(2) do
        if getgenv().NebuBlox_SessionID ~= SessionID then break end
        DeadBlacklist = {}
        -- Clear old targeting history
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
    Icon = "rbxthumb://type=Asset&id=120742610207737&w=150&h=150", -- Avatar (rbxthumb for Decal support)
    IconSize = 64, -- Fills circle
    Theme = "Dark", 
})
getgenv().ANUI_Window = Window

-- [UI POLISH: Fix Icon Scaling]
task.spawn(function()
    task.wait(1)
    -- Attempt to find the Icon in the CoreGui/PlayerGui
    local function FixIcon(root)
        if not root then return end
        for _, img in ipairs(root:GetDescendants()) do
            if img:IsA("ImageLabel") and img.Image:find("120742610207737") then
                img.ScaleType = Enum.ScaleType.Crop -- Force fill
                img.BackgroundTransparency = 1 -- Remove black background
                img.BackgroundColor3 = Color3.new(0,0,0) -- Ensure no visual artifact
                -- Add circular mask if missing? ANUI usually handles it.
            end
        end
    end
    FixIcon(game:GetService("CoreGui"))
    FixIcon(player.PlayerGui)
end)

-- [TAB 1: ABOUT]
local MainTab = Window:Tab({ Title = "About", Icon = "info" })

-- Banner Section (No Header - Opens directly to visual)
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

-- About Content (One Clean Paragraph)

local AboutSection = MainTab:Section({ Title = "Nebublox", Icon = "star", Opened = true })
AboutSection:Paragraph({
    Title = "Welcome to Nebublox",
    Content = [[
// SYSTEM INFORMATION

ARCHITECTS

Core & Logic: Lil Nug of Wisdom
Visual Interface: ANUI v3.1

CURRENT PARAMETERS

Patch Date: 02/08/26 (v3.5)
Target Reality: Anime Storm Simulator 2
Origin: Roblox Community Group

TRANSMISSION
Seeking to expand the void? Access our frequency.
Share your #dark-visions and propose the next #forbidden-script.

[LINK] DISCORD: discord.gg/nebublox
]]
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
                        
                        -- Try to get display name
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
                getgenv().NebuBlox_CurrentTarget = nil -- Force retarget
            end)
        end
        ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
    end
    
    task.spawn(RefreshList)
    
    -- Refresh Button
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

-- Inject UI
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
local TrialTab = Window:Tab({ Title = "Trial", Icon = "clock" })

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
local UpgradeSection = TrialTab:Section({ Title = "Trial Upgrades", Icon = "trending-up" })
UpgradeSection:Toggle({ Title = "Auto Upgrade Strength", Value = false, Callback = function(s) Flags.TrialUpgradeStrength = s end })
UpgradeSection:Toggle({ Title = "Auto Upgrade Gems", Value = false, Callback = function(s) Flags.TrialUpgradeGems = s end })
UpgradeSection:Toggle({ Title = "Auto Upgrade Drops", Value = false, Callback = function(s) Flags.TrialUpgradeDrops = s end })
UpgradeSection:Toggle({ Title = "Auto Upgrade Luck", Value = false, Callback = function(s) Flags.TrialUpgradeLuck = s end })
UpgradeSection:Toggle({ Title = "Auto Upgrade Walkspeed", Value = false, Callback = function(s) Flags.TrialUpgradeWalkspeed = s end })

-- [TAB 3: CHAMPIONS (New)]
local ChampionsTab = Window:Tab({ Title = "Champions", Icon = "egg" })
local EggSection = ChampionsTab:Section({ Title = "Auto Hatch Champions", Icon = "egg", Opened = true })

EggSection:Toggle({ Title = "Auto Hatch One Piece", Value = false, Callback = function(s) Flags.HatchOnePiece = s end })
EggSection:Toggle({ Title = "Auto Hatch Naruto", Value = false, Callback = function(s) Flags.HatchNaruto = s end })
EggSection:Toggle({ Title = "Auto Hatch JJK", Value = false, Callback = function(s) Flags.HatchJJK = s end })
EggSection:Toggle({ Title = "Auto Hatch Demon Slayer", Value = false, Callback = function(s) Flags.HatchSlayer = s end })
EggSection:Toggle({ Title = "Auto Hatch Dragon Ball", Value = false, Callback = function(s) Flags.HatchDBZ = s end })

EggSection:Toggle({ Title = "Disable Egg Animation (Local)", Value = false, Callback = function(s) Flags.DisableEggAnim = s end })

-- [TAB 4: GAMEMODES (Consolidated)]
local GamemodesTab = Window:Tab({ Title = "Gamemodes", Icon = "swords" })

local BossSection = GamemodesTab:Section({ Title = "World Boss Rushes", Icon = "skull", Opened = true })
BossSection:Toggle({ Title = "Auto World Boss Rush ( Z World)", Value = false, Callback = function(s) Flags.BossRushDBZ = s end })
BossSection:Toggle({ Title = "Auto World Boss Rush ( Cursed World)", Value = false, Callback = function(s) Flags.BossRushJJK = s end })

local InvSection = GamemodesTab:Section({ Title = "Invasion", Icon = "shield", Opened = true })
InvSection:Toggle({ Title = "Auto Invasion (Slayer World)", Value = false, Callback = function(s) Flags.AutoInvasionStart = s end })

-- [TAB 4: GACHA (Gacha Only)]
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

-- [TAB 5: PROGRESSION (Misc)]
local MiscTab = Window:Tab({ Title = "Progression", Icon = "chevrons-up" })
local MiscSection = MiscTab:Section({ Title = "Progression", Icon = "chevrons-up", Opened = true })

MiscSection:Toggle({ Title = "Auto Rebirth", Value = false, Callback = function(s) Flags.AutoRebirth = s end })
MiscSection:Toggle({ Title = "Claim Timed Rewards", Value = false, Callback = function(s) Flags.AutoTimedRewards = s end })

-- [TAB 6: SETTINGS]
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

-- Section A: Configuration Manager
local ConfigSection = SettingsTab:Section({ Title = "Configuration Manager", Icon = "folder", Opened = true })

local ConfigNameInput = ""
-- Input removed (now inside Custom Manager)

-- [CUSTOM CONFIG MANAGER UI]
local function CreateConfigManager(parent)
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "ConfigManagerFrame"
    MainFrame.Size = UDim2.new(1, -10, 0, 260) -- Increased height for controls
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = parent
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

    -- Header
    local Header = Instance.new("TextLabel")
    Header.Size = UDim2.new(1, 0, 0, 30)
    Header.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    Header.Text = "  Configuration Manager"
    Header.TextColor3 = Color3.fromRGB(220, 220, 220)
    Header.TextSize = 14
    Header.Font = Enum.Font.GothamBold
    Header.TextXAlignment = Enum.TextXAlignment.Left
    Header.Parent = MainFrame
    Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 8)

    -- Input Box
    local InputFrame = Instance.new("Frame")
    InputFrame.Size = UDim2.new(1, -20, 0, 35)
    InputFrame.Position = UDim2.new(0, 10, 0, 40)
    InputFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    InputFrame.Parent = MainFrame
    Instance.new("UICorner", InputFrame).CornerRadius = UDim.new(0, 6)
    
    local NameInput = Instance.new("TextBox")
    NameInput.Size = UDim2.new(1, -10, 1, 0)
    NameInput.Position = UDim2.new(0, 10, 0, 0)
    NameInput.BackgroundTransparency = 1
    NameInput.Text = ""
    NameInput.PlaceholderText = "Enter config name..."
    NameInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    NameInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    NameInput.TextSize = 13
    NameInput.Font = Enum.Font.Gotham
    NameInput.TextXAlignment = Enum.TextXAlignment.Left
    NameInput.Parent = InputFrame
    
    NameInput.FocusLost:Connect(function()
        ConfigNameInput = NameInput.Text
    end)

    -- Action Buttons Row
    local function CreateBtn(text, color, pos, callback)
        local btn = Instance.new("TextButton")
        btn.Text = text
        btn.BackgroundColor3 = color
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.Size = UDim2.new(0.3, 0, 0, 30)
        btn.Position = pos
        btn.Parent = MainFrame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    -- Save (Orange)
    CreateBtn("SAVE", Color3.fromRGB(255, 100, 0), UDim2.new(0, 10, 0, 85), function()
        ConfigNameInput = NameInput.Text
        if ConfigNameInput ~= "" then
            ConfigSystem.SaveConfig(ConfigNameInput)
            if getgenv().RefreshConfigSelector then getgenv().RefreshConfigSelector() end
        else
            ANUI:Notify({Title = "Error", Content = "Enter a name!", Icon = "alert-triangle", Duration = 2})
        end
    end)

    -- Load (Blue)
    CreateBtn("LOAD", Color3.fromRGB(0, 120, 215), UDim2.new(0.35, 10, 0, 85), function()
        ConfigNameInput = NameInput.Text
        if ConfigNameInput ~= "" then
            ConfigSystem.LoadConfig(ConfigNameInput)
        else
             ANUI:Notify({Title = "Error", Content = "Select/Enter a name!", Icon = "alert-triangle", Duration = 2})
        end
    end)

    -- Delete (Red)
    CreateBtn("DELETE", Color3.fromRGB(200, 50, 50), UDim2.new(0.7, 10, 0, 85), function()
        ConfigNameInput = NameInput.Text
        if ConfigNameInput ~= "" then
            ConfigSystem.DeleteConfig(ConfigNameInput)
            if getgenv().RefreshConfigSelector then getgenv().RefreshConfigSelector() end
        end
    end)

    -- List Header
    local ListLabel = Instance.new("TextLabel")
    ListLabel.Size = UDim2.new(1, -20, 0, 20)
    ListLabel.Position = UDim2.new(0, 10, 0, 125)
    ListLabel.BackgroundTransparency = 1
    ListLabel.Text = "Saved Configurations:"
    ListLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    ListLabel.TextSize = 12
    ListLabel.Font = Enum.Font.Gotham
    ListLabel.TextXAlignment = Enum.TextXAlignment.Left
    ListLabel.Parent = MainFrame

    -- Scroll List
    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Size = UDim2.new(1, -20, 1, -155)
    ScrollFrame.Position = UDim2.new(0, 10, 0, 145)
    ScrollFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    ScrollFrame.BorderSizePixel = 0
    ScrollFrame.ScrollBarThickness = 4
    ScrollFrame.Parent = MainFrame
    Instance.new("UICorner", ScrollFrame).CornerRadius = UDim.new(0, 6)
    
    local ListLayout = Instance.new("UIListLayout")
    ListLayout.SortOrder = Enum.SortOrder.Name
    ListLayout.Padding = UDim.new(0, 2)
    ListLayout.Parent = ScrollFrame

    local function RefreshConfigList()
        for _, c in pairs(ScrollFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        
        local configs = ConfigSystem.GetConfigs()
        
        for _, name in ipairs(configs) do
            local btn = Instance.new("TextButton")
            btn.Name = name
            btn.Size = UDim2.new(1, -4, 0, 24)
            btn.BackgroundColor3 = (ConfigNameInput == name) and Color3.fromRGB(80, 150, 80) or Color3.fromRGB(45, 45, 50)
            btn.Text = "  " .. name
            btn.TextColor3 = Color3.fromRGB(220, 220, 220)
            btn.TextSize = 11
            btn.Font = Enum.Font.Gotham
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Parent = ScrollFrame
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            
            btn.MouseButton1Click:Connect(function()
                ConfigNameInput = name
                NameInput.Text = name -- Update input box
                -- Visual update
                for _, b in pairs(ScrollFrame:GetChildren()) do
                    if b:IsA("TextButton") then
                        b.BackgroundColor3 = (b.Name == name) and Color3.fromRGB(80, 150, 80) or Color3.fromRGB(45, 45, 50)
                    end
                end
            end)
        end
        ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 5)
    end
    
    RefreshConfigList()
    return RefreshConfigList
end

-- Inject Config Manager
task.spawn(function()
    task.wait(1.5)
    local function FindSettingsSection(root)
        if not root then return nil end
        for _, obj in ipairs(root:GetDescendants()) do
            if obj:IsA("TextLabel") and obj.Text == "Configuration Manager" then
                local paragraph = obj.Parent -- ANUI structure usually paragraph inside section?
                 -- Actually, we look for the SECTION header.
                 -- If Text == "Configuration Manager", it's likely the Section Title.
                 -- Section Title is usually inside a button/frame inside the container.
                 -- Assuming standard ANUI structure: Section -> Container -> Elements
                 
                 -- We want to inject into the Container.
                 -- The 'obj' is the Title Label.
                 -- obj.Parent is likely the Header Frame.
                 -- obj.Parent.Parent might be the Section Frame.
                 -- Section Frame should have a 'Container' child?
                 
                 local sectionFrame = obj.Parent and obj.Parent.Parent
                 if sectionFrame then
                     -- Try to find content container
                     local container = sectionFrame:FindFirstChild("Container") or sectionFrame:FindFirstChild("Content")
                     if container then return container end
                     
                     -- Fallback: Just return sectionFrame and hope
                     return sectionFrame
                 end
            end
        end
        return nil
    end
    
    local container = FindSettingsSection(game:GetService("CoreGui")) or FindSettingsSection(player.PlayerGui)
    if container then
        -- Clear existing elements if possible (Hard to do without breaking lib, so we just append)
        -- Create our Custom Manager
        getgenv().RefreshConfigSelector = CreateConfigManager(container)
    end
end)

-- [REMOVED STANDARD BUTTONS]
-- [REMOVED STANDARD BUTTONS]

ConfigSection:Toggle({
    Title = "Autoload on Startup",
    Value = getgenv().NebubloxSettings.AutoLoad,
    Callback = function(s)
        getgenv().NebubloxSettings.AutoLoad = s
    end
})

-- Section B: System Performance
local PerfSection = SettingsTab:Section({ Title = "System Performance", Icon = "cpu", Opened = true })

PerfSection:Toggle({
    Title = "Anti-AFK / Anti-Kick",
    Value = getgenv().NebubloxSettings.AntiAfkEnabled,
    Callback = function(s)
        getgenv().NebubloxSettings.AntiAfkEnabled = s
        ToggleAntiAFK(s)
    end
})

PerfSection:Button({
    Title = "⚡ Low GFX Mode (FPS Boost)",
    Callback = function()
        BoostFPS()
    end
})

-- Check Autoload on Startup
ConfigSystem.CheckAutoload()

-- // 3. LOGIC //
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)

-- [SMART TARGET FINDER]
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
        -- RESTRICTED: TrialAttackAll logic handled inside scanner loops
        

    local function CheckMob(mob)
        if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob:FindFirstChild("HumanoidRootPart") then
            -- Exclude self/pets if necessary (usually they are in different folders)
            local rootPart = mob.HumanoidRootPart
            local dist = (rootPart.Position - myRoot.Position).Magnitude
            if dist < shortestDist then
                shortestDist = dist
                bestTarget = mob
            end
        end
    end

    -- PRIORITY 1: TIME TRIAL (Highest)
    local trialContainer = Workspace:FindFirstChild("TrialRoomNpc")
    local InTrial = trialContainer and #trialContainer:GetChildren() > 0
    
    if InTrial and Flags.AutoTrialFarm then
        -- STRICT: Only scan Trial Mobs
        for _, o in ipairs(trialContainer:GetDescendants()) do CheckMob(o) end
        return bestTarget 
    end

    -- PRIORITY 2: INVASION
    local invContainer = Workspace:FindFirstChild("InvasionNpc")
    local InInvasion = invContainer and #invContainer:GetChildren() > 0
    local invBossMap = Workspace.Maps:FindFirstChild("DemonSlayerInvasion")
    local InInvasionBoss = invBossMap and invBossMap:FindFirstChild("NpcSpawns")
    
    if (InInvasion or InInvasionBoss) and Flags.AutoInvasionStart then
        -- STRICT: Only scan Invasion Mobs
        if invContainer then for _, o in ipairs(invContainer:GetDescendants()) do CheckMob(o) end end
        if InInvasionBoss then for _, o in ipairs(InInvasionBoss:GetDescendants()) do CheckMob(o) end end
        return bestTarget
    end
    
    -- PRIORITY 3: BOSS RUSH
    if Flags.BossRushDBZ or Flags.BossRushJJK then
        -- Boss Rush Mobs? Usually just one boss.
        -- We will scan the specific boss rush map if it exists
        local mapName = Flags.BossRushDBZ and "dbzBossRush" or "JjkBossRush"
        local brMap = Workspace.Maps:FindFirstChild(mapName)
        if brMap then
             for _, o in ipairs(brMap:GetDescendants()) do CheckMob(o) end
        end
        return bestTarget
    end

    -- PRIORITY 4: AUTO FARM (Lowest)
    if Flags.SmartFarm then
        -- STRICT: Only scan Normal Mobs (and Invasion/Trial folders if they happen to have lingering mobs but mode is OFF? No, user said ignore if active)
        -- Normal Mobs in "Npc" folder
        local normalNpc = Workspace:FindFirstChild("Npc")
        if normalNpc then for _, o in ipairs(normalNpc:GetDescendants()) do CheckMob(o) end end
        
        -- Also scan "InvasionNpc" IF AutoInvasion is OFF (maybe user just wants to farm them without auto-start?)
        -- But strictly speaking, SmartFarm should just target closest valid mob.
        -- Use user's instruction: "Only run if Trial, Invasion, and Boss Rush are ALL inactive"
        -- If we are here, they ARE inactive (or flags are off).
        return bestTarget
    end
    
    return nil
end

local function GetBossSpawn(mode)
    local maps = Workspace:FindFirstChild("Maps")
    if not maps then return nil end
    if mode == "Jjk" and maps:FindFirstChild("JjkBossRush") then return maps.JjkBossRush.NpcSpawns.Boss end
    if mode == "Dbz" and maps:FindFirstChild("dbzBossRush") then return maps.dbzBossRush.NpcSpawns.Boss end
    return nil
end

-- // 4. LOOPS //
-- // 4. LOOPS //
getgenv().NebuBlox_NoClipConnection = RunService.Stepped:Connect(function()
    if getgenv().NebuBlox_SessionID ~= SessionID then return end
    if player.Character then
        for _, v in pairs(player.Character:GetChildren()) do if v:IsA("BasePart") then v.CanCollide = false end end
    end
end)

-- MOVEMENT
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
        local InTrial = tf and #tf:GetChildren() > 0
        
        if InTrial and Flags.AutoTrialFarm then
            local t = getgenv().NebuBlox_CurrentTarget
            if t and t.Parent and t:FindFirstChild("Humanoid") and t.Humanoid.Health > 0 and t:FindFirstChild("HumanoidRootPart") then
                root.CFrame = t.HumanoidRootPart.CFrame * CFrame.new(0,0,3)
                root.AssemblyLinearVelocity = Vector3.zero
            end
            return -- STOP HERE
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
             return -- STOP HERE
        end

        -- PRIORITY 3: Boss Rush
        if Flags.BossRushDBZ or Flags.BossRushJJK then
             local tc = nil
             if Flags.BossRushDBZ then local s = GetBossSpawn("Dbz"); if s then tc = s.CFrame * CFrame.new(0,0,2) end
             elseif Flags.BossRushJJK then local s = GetBossSpawn("Jjk"); if s then tc = s.CFrame * CFrame.new(0,0,2) end end
             
             if tc then root.CFrame = tc; root.AssemblyLinearVelocity = Vector3.zero end
             return -- STOP HERE
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

-- ATTACK (THROTTLED: 10 CPS)
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

-- AUTO HATCH LOOP
task.spawn(function()
    while task.wait(0.5) do
        if getgenv().NebuBlox_SessionID ~= SessionID then break end
        
        local targetEgg = nil
        if Flags.HatchOnePiece then targetEgg = Workspace.Eggs.OnePiece.OnePiece.EggModel.Egg end
        if Flags.HatchNaruto then targetEgg = Workspace.Eggs.Naruto.Naruto.EggModel:FindFirstChild("Egeg") or Workspace.Eggs.Naruto.Naruto.EggModel:FindFirstChild("Egg") end
        if Flags.HatchJJK then targetEgg = Workspace.Eggs.Jjk.Jjk.EggModel.Egg end
        if Flags.HatchSlayer then targetEgg = Workspace.Eggs.DemonSlayer.DemonSlayer.EggModel.Egg end
        if Flags.HatchDBZ then targetEgg = Workspace.Eggs.Dbz.Dbz.EggModel.Egg end
        
        if targetEgg then
            -- Teleport close to egg
            pcall(function()
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    player.Character.HumanoidRootPart.CFrame = targetEgg.CFrame * CFrame.new(0,0,3)
                end
                
                -- Fire Hatch Remote
                local EggRemote = Remotes.Egg and Remotes.Egg:FindFirstChild("Egg")
                if EggRemote then
                    EggRemote:FireServer("AutoHatch")
                end
            end)
        end
    end
end)

-- AUTOMATION (RESTORED ALL GACHAS)
task.spawn(function()
    local SpecialProgressionRemote = Remotes:WaitForChild("SpecialProgression", 5)
    
    while task.wait(0.5) do
        if getgenv().NebuBlox_SessionID ~= SessionID then break end
        pcall(function()
            -- Auto Join Trial (Easy) (Priority Check)
            -- We check if we are already IN a Trial
            local tf = Workspace:FindFirstChild("TrialRoomNpc")
            local InTrial = tf and #tf:GetChildren() > 0
            
            if Flags.AutoTrial and Remotes.TimeTrial then
                local TTR = Remotes.TimeTrial:FindFirstChild("TimeTrialRemote")
                if TTR then
                    if not InTrial then
                        -- Check timer to avoid spam
                        if (tick() - LastTrialJoinTime > 15) then
                             -- Logic to Join
                             TTR:FireServer("Enter")
                             LastTrialJoinTime = tick() -- Reset timer
                        end
                    end
                end
            end
            
            -- Invasion (Slayer World) - Only if NOT In Trial
            if Flags.AutoInvasionStart and not InTrial then 
                local InvStart = Remotes.Invasion and Remotes.Invasion:FindFirstChild("InvasionStart")
                if InvStart then
                    -- 1. Fire Start Remote
                    InvStart:FireServer("StartUi", "DemonSlayerInvasion")
                    
                    -- 2. Teleport to Invasion Boss Spawn (Immediately)
                    local map = Workspace.Maps:FindFirstChild("DemonSlayerInvasion")
                    local bossSpawn = map and map:FindFirstChild("NpcSpawns") and map.NpcSpawns:FindFirstChild("Boss")
                    
                    if bossSpawn and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        -- Only TP if not already there (distance check 200 studs)
                        if (player.Character.HumanoidRootPart.Position - bossSpawn.Position).Magnitude > 200 then
                            player.Character.HumanoidRootPart.CFrame = bossSpawn.CFrame
                            print("[Nebublox] Teleported to Invasion Boss Spawn")
                        end
                    end
                end
            end
            
            -- Boss - Only if NOT In Trial AND NOT In Invasion
            if (Flags.BossRushDBZ or Flags.BossRushJJK) and not InTrial and not InInvasion then
                 local BR = Remotes.BossRush
                 local mode = Flags.BossRushDBZ and "DbzBossRush" or "JjkBossRush"
                 if BR and BR:FindFirstChild(mode) then
                      BR[mode]:FireServer("Enter")
                 end
                 -- Silent Mode: Disable Client Listener
                 if getconnections then for _, c in pairs(getconnections(BR.BossRushRemote.OnClientEvent)) do c:Disable() end end
                 -- BR.BossRushRemote:FireServer("OpenBossRushFrame", mode) -- REMOVED
                 BR.BossRushStart:FireServer("StartUi", mode)
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
            
            -- Trial/Invasion Return Logic (CLEANED)
            if PerformReturn then
                local now = tick()
                local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if not root then return end
                
                -- Check Trial State
                local tf = Workspace:FindFirstChild("TrialRoomNpc")
                local InTrialNow = tf and #tf:GetChildren() > 0
                
                -- Check Invasion State
                local invF = Workspace:FindFirstChild("InvasionNpc")
                local InInvasionNow = invF and #invF:GetChildren() > 0
                
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
                    if not InTrialNow then
                        if getgenv().TrialSuccess then
                            print("[Nebublox] Trial Success Verified! Returning...")
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
                    
                    -- User Requested: Use firesignal to simulate client events
                    pcall(function()
                        if firesignal then
                            local WorldRemote = Remotes:FindFirstChild("World")
                            if WorldRemote then
                                firesignal(WorldRemote.OnClientEvent, "StartWorldEffects", "DemonSlayer")
                                ANUI:Notify({Title = "Invasion Done", Content = "Signaled World Return (Client)", Icon = "map", Duration = 3})
                            end
                            
                            local GamemodeUi = Remotes:FindFirstChild("GamemodeUi")
                            if GamemodeUi then
                                firesignal(GamemodeUi.OnClientEvent, "CloseGamemodeUi")
                            end
                        else
                             -- Fallback if executor lacks firesignal
                             local WorldRemote = Remotes:FindFirstChild("World")
                             if WorldRemote then WorldRemote:FireServer("Teleport", "DemonSlayer") end
                             ANUI:Notify({Title = "Invasion Done", Content = "Fallback: Standard Teleport", Icon = "alert-triangle", Duration = 3})
                        end
                    end)
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
                 print("[Trial Debug] Event Action:", action) -- Debug print
                 
                 if action == "NotifyBeforeStart" then
                     getgenv().TrialSuccess = false
                 elseif action == "Success" or action == "TrialComplete" or action == "Victory" or action == "Rewards" then
                     getgenv().TrialSuccess = true
                     print("[Nebublox] Trial Success Flag SET!")
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

ANUI:Notify({Title = "Nebublox", Content = "Loaded v3.5 (Critical Syntax Fix)", Icon = "check", Duration = 5})
