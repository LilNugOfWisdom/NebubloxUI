-- // NEBUBLOX | ZERO TO HERO (v3.41: STRICT MERGE + GROUNDED) //
-- // Game: Zero to Hero //
print("/// NEBUBLOX v3.41 LOADED - " .. os.date("%X") .. " ///")

-- // 0. SESSION & CLEANUP //
local function SafeDisconnect(conn)
    if conn then pcall(function() conn:Disconnect() end) end
end

-- Track connections globally for explicit cleanup
if not getgenv().NebuBlox_Connections then getgenv().NebuBlox_Connections = {} end

if getgenv().NebuBlox_Loaded then
    getgenv().NebuBlox_Running = false
    task.wait(0.25)
    
    for name, conn in pairs(getgenv().NebuBlox_Connections) do
        SafeDisconnect(conn)
        getgenv().NebuBlox_Connections[name] = nil
    end
    
    pcall(function()
        getgenv().ANUI_Window = nil 
        getgenv().GameTabsLoaded = false 
        local core = game:GetService("CoreGui")
        local uis = {"Nebublox", "ANUI", "Orion", "Shadow", "ScreenGui", "NebuEnemyList"}
        for _, n in ipairs(uis) do
            local f = core:FindFirstChild(n)
            if f then f:Destroy() end
        end
        if game.Players.LocalPlayer.PlayerGui:FindFirstChild("Nebublox") then 
            game.Players.LocalPlayer.PlayerGui.Nebublox:Destroy() 
        end
    end)
end

local MySessionID = tick()
getgenv().NebuBlox_Loaded = true
getgenv().NebuBlox_Running = true
getgenv().NebuBlox_SessionID = MySessionID

local function IsValidSession()
    return getgenv().NebuBlox_Running and getgenv().NebuBlox_SessionID == MySessionID
end

-- // 0.1 ROBUST LOADER //
local function LoadScript(url)
    if isfile and isfile("ANUI_source.lua") then return readfile("ANUI_source.lua") end
    local success, result = pcall(function() return game:HttpGet(url) end)
    if not success then
        local req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
        if req then
            local response = req({Url = url, Method = "GET"})
            if response.Success or response.StatusCode == 200 then return response.Body end
        end
    end
    return result
end

local ANUI = loadstring(LoadScript("https://raw.githubusercontent.com/ANHub-Script/ANUI/refs/heads/main/dist/main.lua"))()

-- // 0.2 SERVICES //
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local player = Players.LocalPlayer

-- // 0.3 FLAGS & GAME LOGIC PREP //
local Flags = {
    -- [[ MAIN ]]
    AutoFarm = false, AutoClick = false, AutoRebirth = false, AutoRankup = false,
    -- [[ COMBAT ]]
    AutoEnchant = false, AutoBreathing = false, AutoAura = false, AutoUpgrades = false,
    -- [[ LOOT ]]
    AutoDrops = false, AutoSpheres = false, AutoChests = false, AutoDaily = false, 
    AutoDungeonOres = false, AutoDungeonChests = false, AutoMissions = false,
    -- [[ PETS ]]
    AutoHatch = false, AutoGrimory = false, AutoPetGacha = false, 
    FastHatchBypass = false, SelectedEgg = "None", HatchMode = "x3",
    -- [[ GLOBAL ]]
    MuteNotifications = false, AnimSpeedLock = false, InfDash = false, 
    AntiAFK = false, TargetMob = "Nearest", NoProximityLimits = false, NoClickLimits = false, KillAura = false,
}

local Managers = {} 
local ToggleRegistry = {}

-- [[ MANAGER SCANNER ]]
task.spawn(function()
    while task.wait(1) do
        if not IsValidSession() then break end
        pcall(function()
            for _, v in pairs(getgc(true)) do
                if type(v) == "table" then
                    if rawget(v, "Dash") and rawget(v, "Combat") and rawget(v, "Character") then Managers.Main = v end
                    if rawget(v, "PetSummon") then Managers.Hatch = v end
                    if rawget(v, "Aura") then Managers.Aura = v end
                    if rawget(v, "GetZoneLoaded") then Managers.Zone = v end
                    if rawget(v, "Market") then Managers.Market = v end
                    
                    if rawget(v, "Dash") and type(v.Dash) == "table" and v.Dash.Config and Flags.InfDash then v.Dash.Config.DashCooldown = 0; v.Dash.Config.DashSpeed = 150 end
                    if rawget(v, "Animation") and Flags.AnimSpeedLock then for _, track in pairs(v.Animation.ActionTracks or {}) do if type(track) == "table" and track.Track then track.Track:AdjustSpeed(2.5) end end end
                    if Flags.FastHatchBypass then if rawget(v, "PetSummon") then v.PetSummon.FastSpin = true end; if rawget(v, "GrimoryGacha") then v.GrimoryGacha.FastSpin = true end end
                end
            end
        end)
    end
end)

-- // 0.4 NAME SPOOFER (TEMPLATE STYLE - AUTOMATIC) //
local Creators = { ["LilNugget"] = true, ["K11ngJTB"] = true, ["James"] = true, ["LilNugOfWisdom"] = true }

local function GetDefaultSpoofName()
    return (Creators[player.Name] or Creators[player.DisplayName]) and "He Who Remains Lil'Nug" or "Nebublox 🌌"
end
getgenv().NebuBlox_SpoofName = GetDefaultSpoofName()

local function ApplyPrettyName(char)
    if not char then return end
    local head = char:WaitForChild("Head", 5)
    local hum = char:WaitForChild("Humanoid", 5)
    if not head or not hum then return end

    local spoofName = getgenv().NebuBlox_SpoofName
    local isCreator = (spoofName == "He Who Remains Lil'Nug" or Creators[player.Name] or Creators[player.DisplayName])

    -- 1. Client-Sided DisplayName
    hum.DisplayName = spoofName
    hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None 
    hum:GetPropertyChangedSignal("DisplayName"):Connect(function()
        if hum.DisplayName ~= getgenv().NebuBlox_SpoofName then hum.DisplayName = getgenv().NebuBlox_SpoofName end
    end)
    hum:GetPropertyChangedSignal("DisplayDistanceType"):Connect(function()
        if hum.DisplayDistanceType ~= Enum.HumanoidDisplayDistanceType.None then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
    end)

    -- 2. "Pretty" BillboardGui Tag
    if head:FindFirstChild("NebuTag") then head.NebuTag:Destroy() end
    local bg = Instance.new("BillboardGui", head); bg.Name = "NebuTag"; bg.Size = UDim2.new(0, 400, 0, 50); bg.StudsOffset = Vector3.new(0, 2, 0); bg.AlwaysOnTop = true
    local label = Instance.new("TextLabel", bg); label.Name = "TagLabel"; label.Size = UDim2.new(1, 0, 1, 0); label.BackgroundTransparency = 1; label.Text = spoofName; label.TextSize = 24; label.Font = Enum.Font.FredokaOne; label.TextColor3 = Color3.new(1, 1, 1); label.TextStrokeTransparency = 0 

    -- Gradient Logic (Strict Template Copy)
    local grad = Instance.new("UIGradient", label)
    if isCreator then
        grad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 255)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 215, 0)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 255))})
        task.spawn(function() while label and label.Parent do grad.Offset = Vector2.new(((tick() * 0.5) % 1) - 0.5, 0); task.wait() end end)
    else
        grad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(88, 101, 242)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(170, 0, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(88, 101, 242))})
        task.spawn(function() while label and label.Parent do grad.Rotation = (tick() * 90) % 360; task.wait() end end)
    end

    -- 3. HIDE GAME'S DEFAULT OVERHEAD
    task.spawn(function()
        while task.wait(1) do
            if not char or not IsValidSession() then break end
            local h = char:FindFirstChild("Head")
            if h then local ov = h:FindFirstChild("PlayerOverheadGui") or h:FindFirstChild("Overhead"); if ov then ov:Destroy() end end
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player and p.Character and p.Character:FindFirstChild("Head") then
                    local ov = p.Character.Head:FindFirstChild("PlayerOverheadGui") or p.Character.Head:FindFirstChild("Overhead")
                    if ov then ov:Destroy() end
                end
            end
            local clients = Workspace:FindFirstChild("Clients")
            if clients then for _, z in ipairs(clients:GetChildren()) do for _, m in ipairs(z:GetChildren()) do if m:FindFirstChild("Head") and m.Head:FindFirstChild("Overhead") then m.Head.Overhead:Destroy() end end end end
        end
    end)
end

if player.Character then ApplyPrettyName(player.Character) end
getgenv().NebuBlox_Connections.CharacterAdded = player.CharacterAdded:Connect(function(char)
    if IsValidSession() then ApplyPrettyName(char) end
end)

-- // 0.5 SETTINGS INIT //
if not getgenv().NebubloxSettings then
    getgenv().NebubloxSettings = { AutoLoad = true, LastConfig = "", AntiAfkEnabled = false }
end

-- // 1. CONFIG SYSTEM (Strict Template) //
local FolderName = "Nebublox"
local ConfigsFolder = FolderName .. "/Configs"
pcall(function() if not isfolder(FolderName) then makefolder(FolderName) end; if not isfolder(ConfigsFolder) then makefolder(ConfigsFolder) end end)

local ConfigSystem = {}
function ConfigSystem.SaveConfig(name)
    if name == "" then pcall(function() ANUI:Notify({Title = "Error", Content = "Enter a config name!", Icon = "alert-triangle", Duration = 3}) end) return end
    local success, err = pcall(function() local json = HttpService:JSONEncode(Flags); writefile(ConfigsFolder .. "/" .. name .. ".json", json) end)
    if success then pcall(function() ANUI:Notify({Title = "Config Saved!", Content = name .. ".json", Icon = "check", Duration = 3}) end) else pcall(function() ANUI:Notify({Title = "Save Failed", Content = tostring(err), Icon = "x", Duration = 5}) end) end
end
function ConfigSystem.LoadConfig(name)
    local path = ConfigsFolder .. "/" .. name .. ".json"
    pcall(function()
        if isfile(path) then
            local decoded = HttpService:JSONDecode(readfile(path))
            for key, value in pairs(decoded) do Flags[key] = value; if ToggleRegistry[key] and ToggleRegistry[key].Set then pcall(function() ToggleRegistry[key]:Set(value) end) end end
            getgenv().NebubloxSettings.LastConfig = name
            ANUI:Notify({Title = "Config", Content = "Loaded: " .. name, Icon = "folder-open", Duration = 3})
        else ANUI:Notify({Title = "Error", Content = "Config not found!", Icon = "alert-triangle", Duration = 3}) end
    end)
end
function ConfigSystem.DeleteConfig(name)
    local path = ConfigsFolder .. "/" .. name .. ".json"
    pcall(function() if isfile(path) then delfile(path); ANUI:Notify({Title = "Config", Content = "Deleted: " .. name, Icon = "trash", Duration = 3}) end end)
end
function ConfigSystem.GetConfigs()
    local names = {}; pcall(function() for _, file in ipairs(listfiles(ConfigsFolder)) do local name = file:match("([^/\\]+)%.json$"); if name then table.insert(names, name) end end end); return names
end
function ConfigSystem.CheckAutoload()
    pcall(function() if getgenv().NebubloxSettings.AutoLoad and getgenv().NebubloxSettings.LastConfig ~= "" then ConfigSystem.LoadConfig(getgenv().NebubloxSettings.LastConfig) end end)
end

-- // 2. UTILS //
function ToggleAntiAFK(state)
    Flags.AntiAFK = state
    if state then
        getgenv().NebuBlox_Connections.AntiAFK = player.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)
        ANUI:Notify({Title = "Anti-AFK", Content = "Enabled", Icon = "shield", Duration = 2})
    else
        SafeDisconnect(getgenv().NebuBlox_Connections.AntiAFK)
        ANUI:Notify({Title = "Anti-AFK", Content = "Disabled", Icon = "shield-off", Duration = 2})
    end
end

function BoostFPS()
    pcall(function()
        Lighting.GlobalShadows = false; Lighting.FogEnd = 9e9; Lighting.Brightness = 1
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v.Parent:FindFirstChild("Humanoid") then v.Material = Enum.Material.SmoothPlastic; v.Reflectance = 0; v.CastShadow = false
            elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Enabled = false end
        end
    end)
    ANUI:Notify({Title = "FPS Boost", Content = "Low GFX Mode Applied!", Icon = "zap", Duration = 3})
end

-- // 3. UI SETUP //
local Window = ANUI:CreateWindow({
    Title = "Nebublox", Author = "He Who Remains Lil'Nug", Folder = "Nebublox",
    Icon = "rbxthumb://type=Asset&id=120742610207737&w=150&h=150", IconSize = 63, Theme = "Dark", 
})
getgenv().ANUI_Window = Window

-- [ICON FIX & THEMES - TEMPLATE EXACT]
task.spawn(function()
    local function FixIcon(root)
        if not root then return end
        for _, img in ipairs(root:GetDescendants()) do
            if img:IsA("ImageLabel") and (img.Name == "Icon" or img.Name == "Logo" or (img.Image and img.Image:find("120742610207737"))) then
                img.ScaleType = Enum.ScaleType.Crop; img.BackgroundTransparency = 1; img.BackgroundColor3 = Color3.new(0,0,0)
                img.Size = UDim2.new(3, 0, 3, 0); local corner = img:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", img); corner.CornerRadius = UDim.new(1, 0)
            end
        end
    end
    local function ApplyToFrame(frame)
        if not frame then return end
        frame.BackgroundColor3 = Color3.new(0, 0, 0); frame.BackgroundTransparency = 0
        local old = frame:FindFirstChild("WindUIGradient") or frame:FindFirstChild("NebuGradient")
        if old then old:Destroy() end
        for _, v in ipairs(frame:GetDescendants()) do if (v:IsA("TextLabel") or v:IsA("TextButton")) and v.TextColor3.R < 0.2 then v.TextColor3 = Color3.new(1,1,1) end end
    end
    local function RemoveTopBarIcon()
        for _, v in ipairs(game:GetService("Players").LocalPlayer.PlayerGui:GetDescendants()) do
            if v.Name == "TopbarPlus" or (v:IsA("ImageLabel") and v.Image:find("120742610207737")) then
                if v.Parent and v.Parent.Name == "TopbarPlus" then v.Parent:Destroy() 
                elseif v.Name == "Icon" and v.Parent and v.Parent:IsA("Frame") then local container = v.Parent.Parent; if container then container:Destroy() end end
            end
        end
        local core = game:GetService("CoreGui"); local anuiIcon = core:FindFirstChild("NebubloxIcon") or core:FindFirstChild("ANUI_Icon"); if anuiIcon then anuiIcon:Destroy() end
    end
    for i = 1, 10 do
        FixIcon(game:GetService("CoreGui"):FindFirstChild("Nebublox"))
        if Window.UIElements and Window.UIElements.Main then ApplyToFrame(Window.UIElements.Main); ApplyToFrame(Window.UIElements.Main:FindFirstChild("Main")) end
        RemoveTopBarIcon()
        task.wait(1)
    end
end)

-- [TITLE GRADIENT: TEMPLATE EXACT]
task.spawn(function()
    local attempts = 0
    while attempts < 20 do
        task.wait(1); attempts = attempts + 1
        local function ApplyGradientToTitle(root)
            if not root then return end
            for _, lbl in ipairs(root:GetDescendants()) do
                if lbl:IsA("TextLabel") then
                    if (lbl.Text == "Nebublox" or lbl.Text:find("Nebublox")) and not lbl:FindFirstChild("TitleGrad") then
                        local grad = Instance.new("UIGradient", lbl); grad.Name = "TitleGrad"
                        grad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(88, 101, 242)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(170, 0, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(88, 101, 242))})
                        task.spawn(function() while lbl and lbl.Parent do grad.Rotation = (tick() * 90) % 360; task.wait() end end)
                    elseif lbl.Text:find("He Who Remains Lil'Nug") and not lbl:FindFirstChild("AuthorGrad") then
                        Wait(0.1)
                        local grad = Instance.new("UIGradient", lbl); grad.Name = "AuthorGrad"
                        grad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 255)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 215, 0)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 255))})
                        task.spawn(function() while lbl and lbl.Parent do grad.Offset = Vector2.new(((tick() * 0.5) % 1) - 0.5, 0); task.wait() end end)
                    end
                end
            end
        end
        ApplyGradientToTitle(game:GetService("CoreGui"):FindFirstChild("Nebublox"))
        ApplyGradientToTitle(game:GetService("CoreGui"):FindFirstChild("ANUI"))
        if Window and Window.UIElements and Window.UIElements.Main then ApplyGradientToTitle(Window.UIElements.Main) end
    end
end)

-- [TAB: ABOUT (TEMPLATE COPY)]
local MainTab = Window:Tab({ Title = "About", Icon = "info" })
local BannerSection = MainTab:Section({ Title = " ", Icon = "", Opened = true })
BannerSection:Paragraph({ Title = "BANNER_PLACEHOLDER", Content = "" })

task.spawn(function()
    task.wait(1)
    local BannerImage = "rbxthumb://type=Asset&id=132367447015620&w=768&h=432"
    local function InjectBanner()
        local function ScanRoot(root)
             for _, v in ipairs(root:GetDescendants()) do
                 if v:IsA("TextLabel") and v.Text == "BANNER_PLACEHOLDER" then
                     local Container = v.Parent; if Container and Container.Name == "Content" then Container = Container.Parent end
                     if Container and Container.Parent then
                         local NewBanner = Instance.new("ImageLabel", Container.Parent); NewBanner.Name = "NebubloxBanner"
                         NewBanner.Size = UDim2.new(1, 0, 0, 150); NewBanner.BackgroundTransparency = 1; NewBanner.Image = BannerImage; NewBanner.ScaleType = Enum.ScaleType.Fit
                         local Corner = Instance.new("UICorner", NewBanner); Corner.CornerRadius = UDim.new(0, 8)
                         if Container:FindFirstChild("LayoutOrder") then NewBanner.LayoutOrder = Container.LayoutOrder end
                         Container:Destroy(); return true
                     end
                 end
             end
             return false
        end
        if not ScanRoot(game:GetService("CoreGui")) then ScanRoot(player:WaitForChild("PlayerGui")) end
    end
    for i=1,5 do if InjectBanner() then break end task.wait(1) end
end)

local AboutSection = MainTab:Section({ Title = "Authentication", Icon = "shield", Opened = true })
local LoadPremiumTabs; local UserKeyInput = ""
AboutSection:Input({ Title = "Premium Key", Placeholder = "Galaxy Key Here..", Width = 200, Callback = function(t) UserKeyInput = t end })
AboutSection:Button({ Title = "Verify key", Width = 100, Callback = function()
    local trimmedKey = UserKeyInput:gsub("^%s*(.-)%s*$", "%1")
    if trimmedKey == "" then ANUI:Notify({Title = "Error", Content = "Please enter a key first!", Icon = "x", Duration = 2}); return end
    ANUI:Notify({Title = "Verifying...", Content = "Checking Galaxy Key...", Icon = "loader", Duration = 2})
    local success, result = pcall(function() return game:HttpGet("https://darkmatterv1.onrender.com/api/verify_key?key=" .. trimmedKey .. "&hwid=" .. game:GetService("RbxAnalyticsService"):GetClientId()) end)
    if success and (result:find("valid") or result:find("success") or result:find("true")) then
        ANUI:Notify({Title = "Nebulox", Content = "Access Granted! 🌌", Icon = "check", Duration = 5})
        LoadPremiumTabs()
    else ANUI:Notify({Title = "Error", Content = "Invalid Galaxy Key", Icon = "x", Duration = 5}) end
end })
AboutSection:Button({ Title = "Join Discord", Icon = "message-square", Callback = function() setclipboard("https://discord.gg/nebublox") end })
AboutSection:Button({ Title = "https://nebublox.space", Icon = "globe", Callback = function() setclipboard("https://nebublox.space") end })

-- // LOAD PREMIUM TABS //
LoadPremiumTabs = function()
    if getgenv().GameTabsLoaded then return end
    getgenv().GameTabsLoaded = true
    
    local FarmTab = Window:Tab({ Title = "Main", Icon = "zap" })
    local FarmSection = FarmTab:Section({ Title = "Farming", Icon = "flame", Opened = true })
    ToggleRegistry.AutoFarm = FarmSection:Toggle({ Title = "Auto Farm Mobs", Value = Flags.AutoFarm, Callback = function(s) Flags.AutoFarm = s end })
    ToggleRegistry.AutoClick = FarmSection:Toggle({ Title = "Auto Click", Value = Flags.AutoClick, Callback = function(s) Flags.AutoClick = s end })
    local MobDropdown = FarmSection:Dropdown({ Title = "Select Target Mob", Items = {"Nearest"}, Value = Flags.TargetMob, Callback = function(v) Flags.TargetMob = v end })
    FarmSection:Button({ Title = "Refresh Mobs", Callback = function()
        local list = {"Nearest"}; local ms = Workspace:FindFirstChild("Client") and Workspace.Client:FindFirstChild("Mobs")
        if ms then for _, m in ipairs(ms:GetChildren()) do if not table.find(list, m.Name) then table.insert(list, m.Name) end end end
        MobDropdown:Refresh(list)
    end })
    local ProgSection = FarmTab:Section({ Title = "Progression & Skills", Icon = "trending-up" })
    ToggleRegistry.AutoRebirth = ProgSection:Toggle({ Title = "Auto Rebirth", Value = Flags.AutoRebirth, Callback = function(s) Flags.AutoRebirth = s end })
    ToggleRegistry.AutoRankup = ProgSection:Toggle({ Title = "Auto Rankup", Value = Flags.AutoRankup, Callback = function(s) Flags.AutoRankup = s end })
    ToggleRegistry.AutoAura = ProgSection:Toggle({ Title = "Smart Aura Evolution", Value = Flags.AutoAura, Callback = function(s) Flags.AutoAura = s end })
    ToggleRegistry.AutoUpgrades = ProgSection:Toggle({ Title = "Auto Buy Upgrades", Value = Flags.AutoUpgrades, Callback = function(s) Flags.AutoUpgrades = s end })

    local GachaTab = Window:Tab({ Title = "Gacha", Icon = "sparkles" }) 
    local HatchSection = GachaTab:Section({ Title = "Hatching", Icon = "egg", Opened = true })
    HatchSection:Toggle({ Title = "Fast Spin Egg (Bypass)", Value = Flags.FastHatchBypass, Callback = function(s) Flags.FastHatchBypass = s end })
    local GachaSection = GachaTab:Section({ Title = "Other Gachas", Icon = "sparkles" })
    GachaSection:Toggle({ Title = "Auto Grimory Gacha", Value = Flags.AutoGrimory, Callback = function(s) Flags.AutoGrimory = s end })

    local LootTab = Window:Tab({ Title = "Loot", Icon = "gift" })
    local WorldLoot = LootTab:Section({ Title = "World Loot", Icon = "globe", Opened = true })
    WorldLoot:Toggle({ Title = "Auto Collect Drops", Value = Flags.AutoDrops, Callback = function(s) Flags.AutoDrops = s end })
    WorldLoot:Toggle({ Title = "Auto Chests", Value = Flags.AutoChests, Callback = function(s) Flags.AutoChests = s end })
    WorldLoot:Toggle({ Title = "Auto Dragon Spheres", Value = Flags.AutoSpheres, Callback = function(s) Flags.AutoSpheres = s end })
    local RewardLoot = LootTab:Section({ Title = "Free Rewards", Icon = "calendar" })
    RewardLoot:Toggle({ Title = "Auto Daily Reward", Value = Flags.AutoDaily, Callback = function(s) Flags.AutoDaily = s end })
    RewardLoot:Toggle({ Title = "Auto Claim Missions", Value = Flags.AutoMissions, Callback = function(s) Flags.AutoMissions = s end })
    local DungeonLoot = LootTab:Section({ Title = "Dungeons", Icon = "ghost" })
    DungeonLoot:Toggle({ Title = "Auto Dungeon Ores", Value = Flags.AutoDungeonOres, Callback = function(s) Flags.AutoDungeonOres = s end })
    DungeonLoot:Toggle({ Title = "Auto Dungeon Chests", Value = Flags.AutoDungeonChests, Callback = function(s) Flags.AutoDungeonChests = s end })


    -- [[ TAB 6: SETTINGS (TEMPLATE STYLE MERGE) ]]
    local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

    -- 1. Performance Section
    local PerfSection = SettingsTab:Section({ Title = "Performance", Icon = "mouse-pointer", Opened = true })
    PerfSection:Toggle({ Title = "Anti-AFK / Anti-Kick", Value = getgenv().NebubloxSettings.AntiAfkEnabled, Callback = function(s) getgenv().NebubloxSettings.AntiAfkEnabled = s; ToggleAntiAFK(s) end })
    PerfSection:Button({ Title = "⚡ Low GFX Mode (FPS Boost)", Callback = function() BoostFPS() end })

    -- 2. System Section (LOCKED SPOOFER - NO INPUT)
    local SystemSection = SettingsTab:Section({ Title = "System", Icon = "power" })
    SystemSection:Button({ Title = "Kill Script (Unload)", Callback = function()
        getgenv().NebuBlox_SessionID = 0; getgenv().NebuBlox_Running = false
        if getgenv().ANUI_Window then pcall(function() getgenv().ANUI_Window:Destroy() end) end
        if Window then pcall(function() Window:Destroy() end) end
    end })

    -- 3. Config Section
    local ConfigSection = SettingsTab:Section({ Title = "Manage Configurations", Icon = "folder-plus" })
    local ConfigNameInput = ""
    ConfigSection:Input({ Title = "Config Name", Placeholder = "Enter name...", Callback = function(v) ConfigNameInput = v end })
    ConfigSection:Button({ Title = "Save Config", Icon = "save", Callback = function() ConfigSystem.SaveConfig(ConfigNameInput) end })
    local ConfigDropdown = ConfigSection:Dropdown({ Title = "Saved Configs", Options = ConfigSystem.GetConfigs(), Callback = function(v) ConfigNameInput = v end })
    ConfigSection:Button({ Title = "Refresh List", Icon = "refresh", Callback = function() ConfigDropdown:Refresh(ConfigSystem.GetConfigs()) end })
    ConfigSection:Button({ Title = "Load Config", Icon = "upload", Callback = function() ConfigSystem.LoadConfig(ConfigNameInput) end })
    ConfigSection:Button({ Title = "Delete Config", Icon = "trash", Callback = function() ConfigSystem.DeleteConfig(ConfigNameInput); ConfigDropdown:Refresh(ConfigSystem.GetConfigs()) end })
end

ConfigSystem.CheckAutoload()
if getgenv().NebuBlox_SpoofName == "He Who Remains Lil'Nug" then LoadPremiumTabs() end
ANUI:Notify({Title = "Nebublox", Content = "Script Loaded!", Icon = "check", Duration = 3})

-- // 4. AUTOMATION LOOPS //
local function GetSmartTarget()
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local best = nil; local dist = 1000
    local mobs = Workspace:FindFirstChild("Client") and Workspace.Client:FindFirstChild("Mobs")
    if mobs then
        for _, m in ipairs(mobs:GetChildren()) do
            local h = m:FindFirstChild("Humanoid"); local r = m:FindFirstChild("HumanoidRootPart")
            if h and r and h.Health > 0 then
                if Flags.TargetMob == "Nearest" or m.Name == Flags.TargetMob then
                    local d = (r.Position - root.Position).Magnitude
                    if d < dist then dist = d; best = m end
                end
            end
        end
    end
    return best
end

-- Fast Loop
task.spawn(function()
    while task.wait(0.1) do
        if not IsValidSession() then break end
        if Flags.AutoClick then pcall(function() ReplicatedStorage.MainRemote:FireServer("Click", {}) end) end
        if Flags.AutoRebirth then pcall(function() ReplicatedStorage.MainRemote:FireServer("Rebirth", {}) end) end
        if Flags.AutoRankup then pcall(function() ReplicatedStorage.MainRemote:FireServer("Rankup", {"Rankup"}) end) end
        
        if Flags.AutoAura and _G.Data then
            local auraId = _G.Data.Aura + 1; local mod = Managers.Aura and Managers.Aura.Managers and Managers.Aura.Managers.Utility.AurasModule[auraId]
            if mod and (_G.Data.AuraEnemiesDefeated / mod.EnemiesNeed >= 1) then ReplicatedStorage.MainRemote:FireServer("Aura", {"Evolve"}) end
        end
    end
end)

-- Slow Loop (Hatch/Crates)
task.spawn(function()
    while task.wait(1.5) do
        if not IsValidSession() then break end
        -- if Flags.AutoHatch then ... end -- REMOVED
        if Flags.AutoGrimory then ReplicatedStorage.MainRemote:FireServer("GrimoryGacha", {"Spin", true}) end
        
        if Flags.AutoUpgrades and _G.Data and _G.Data.Upgrades then
            local mod = Managers.Main and Managers.Main.Managers and Managers.Main.Managers.Utility.UpgradesModule
            if mod then for n, t in pairs(mod) do if _G.Data.Gems >= (t[(_G.Data.Upgrades[n] or 0) + 1] or {Cost=9e9}).Cost then ReplicatedStorage.MainRemote:FireServer("Upgrade", {"Upgrade", n}) end end end
        end
        if Flags.AutoAura and _G.Data then
            local auraId = _G.Data.Aura + 1; local mod = Managers.Aura and Managers.Aura.Managers and Managers.Aura.Managers.Utility.AurasModule[auraId]
            if mod and (_G.Data.AuraEnemiesDefeated / mod.EnemiesNeed >= 1) then ReplicatedStorage.MainRemote:FireServer("Aura", {"Evolve"}) end
        end
    end
end)

-- [[ HEARTBEAT (GROUNDED FIX) ]]
getgenv().NebuBlox_Connections.Heartbeat = RunService.Heartbeat:Connect(function()
    if not IsValidSession() or not Flags.AutoFarm then return end
    local char = player.Character; local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local target = GetSmartTarget()
    if target and target:FindFirstChild("HumanoidRootPart") then
        local tRoot = target.HumanoidRootPart
        local look = tRoot.CFrame.LookVector * Vector3.new(1, 0, 1)
        if look.Magnitude < 0.1 then look = Vector3.new(0, 0, 1) end
        
        -- Place 3 studs BEHIND target, keeping target's Y level
        local behind = tRoot.Position + (look.Unit * 3)
        root.CFrame = CFrame.lookAt(Vector3.new(behind.X, tRoot.Position.Y, behind.Z), tRoot.Position)
        
        -- Zero velocity to prevent floating/flinging
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        
        ReplicatedStorage.MainRemote:FireServer("Click", {})
    end
end)

print("/// NEBUBLOX: EXECUTION COMPLETE ///")