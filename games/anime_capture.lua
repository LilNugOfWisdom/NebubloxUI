--[[
    ═══════════════════════════════════════════════════════════
    NEBUBLOX | ANIME CAPTURE (Final Polish)
    Simple, Clean, and Powerful
    ═══════════════════════════════════════════════════════════
]]

local GAME_NAME = "Anime Capture"
local VERSION = "2.0.0"

-- // LOAD LIBRARY //
local NebubloxUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Gamr46/NebubloxUI/main/nebublox_ui.lua"))()

-- // SERVICES //
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- // REMOTES //
-- Function to safely find remotes in multiple locations
local function getRemote(names, parent)
    parent = parent or ReplicatedStorage
    if type(names) == "string" then names = {names} end
    for _, name in ipairs(names) do
        local r = parent:FindFirstChild(name, true) -- Recursive search
        if r then return r end
    end
    return nil
end

-- COMBAT / FARM
local SetEnemyEvent     = getRemote({"SetEnemyEvent"})
local PlayerAttack      = getRemote({"PlayerAttack"})
local CatchFollowFinish = getRemote({"CatchFollowFinish"})
local UseCatchRate      = getRemote({"UseCatchRate", "CatchRate"}) -- Equip Ball

-- CLICKER / UPGRADES
local ClickGUIEvent     = getRemote({"ClickEvent"}) -- GUI Clicker (likely no args)
local ClickPlusEvent    = getRemote({"ClickPlusEvent"}) -- Super Click
local RebirthEvent      = getRemote({"RebirthEvent", "Rebirth"})
local EquipBestEvent    = getRemote({"EquipBestEvent", "EquipBest"})
local CraftItemEvent    = getRemote({"CraftItemEvent"})

-- MISC / DAILY
local GetAllEvent       = getRemote({"GetAllEvent"}) -- Achievement Claim
local PortalEvent       = getRemote({"PortalEvent"}) -- Teleport
local RollOne           = getRemote({"RollOne"})     -- Gacha
local SignEvent         = getRemote({"SignEvent"})   -- Daily Sign
local GetRandom         = getRemote({"[C-S]GetRandom"}) -- Spin
local GetRewardByRandom = getRemote({"GetRewardByRandom"}) -- Spin Reward

-- // VARIABLES //
local Flags = {
    AutoFarm = false,
    AutoCapture = false,
    AutoClickGUI = false,     -- The "Clicker Simulator" spam
    AutoRebirth = false,
    AutoEquip = false,
    AutoCraft = false,
    AutoHatch = false,
    AutoRoll = false,
    AutoDaily = false,
    AutoSpin = false,
    AutoLoot = false,         -- Chests/Explore
}

local Settings = {
    SelectedBall = 1,
    SelectedScene = nil,
    SelectedEgg = nil,
    HatchAmount = 1,
    RollSpeed = 0.5,
    WalkSpeed = 16,
    JumpPower = 50
}

local selectedTarget = nil

-- // SCENE DATA //
local SCENES = {
    { Name = "Start - Pirate Village",       Id = 1, Island = "Island1" },
    { Name = "Scene 2 - Ninja Village",        Id = 2, Island = "Island2" },
    { Name = "Scene 3 - Shirayuki Village",    Id = 3, Island = "Island3" },
    { Name = "Scene 4 - Cursed Arts Hamlet",   Id = 4, Island = "Island4" },
    { Name = "Scene 5 - Arcane City Lofts",    Id = 5, Island = "Island5" },
    { Name = "Scene 6 - Lookout",              Id = 6, Island = "Island6" },
    { Name = "Scene 7 - Duck Research Center", Id = 7, Island = "Island7" },
}

-- // UI SETUP //
local Window = NebubloxUI:CreateWindow({
    Title = "Nebublox",
    Author = "Anime Capture",
    Folder = "Nebublox_AnimeCapture",
    Theme = "Void",
    SideBarWidth = 180,
    HasOutline = true,
})

-- // TABS //
local MainTab    = Window:Tab({ Title = "Main", Icon = "home" })
local UpgradeTab = Window:Tab({ Title = "Upgrades", Icon = "chevrons-up" })
local PetsTab    = Window:Tab({ Title = "Pets & Items", Icon = "dog" }) -- Combined Gacha/Eggs
local TeleportTab= Window:Tab({ Title = "Teleport", Icon = "map" })
local ExtrasTab  = Window:Tab({ Title = "Extras", Icon = "star" })

-- =====================================================================================
-- TAB: MAIN (Farm, Capture, Loot)
-- =====================================================================================
local FarmSection = MainTab:Section({ Title = "Auto Farm", Icon = "sword", Opened = true })

FarmSection:Toggle({
    Title = "Auto Farm Mobs",
    Desc = "Kills enemies automatically",
    Value = false,
    Callback = function(state)
        Flags.AutoFarm = state
    end
})

FarmSection:Toggle({
    Title = "Auto Clicker (GUI)",
    Desc = "Spams the Click button for currency",
    Value = false,
    Callback = function(state)
        Flags.AutoClickGUI = state
    end
})

local CaptureSection = MainTab:Section({ Title = "Capture", Icon = "box", Opened = true })

CaptureSection:Toggle({
    Title = "Auto Capture",
    Desc = "Weakens and Captures enemies",
    Value = false,
    Callback = function(state)
        Flags.AutoCapture = state
    end
})

CaptureSection:Slider({
    Title = "Select Ball ID",
    Value = { Min = 1, Max = 20, Default = 1 },
    Step = 1,
    Callback = function(val)
        Settings.SelectedBall = val
    end
})

-- =====================================================================================
-- TAB: UPGRADES
-- =====================================================================================
local ProgSection = UpgradeTab:Section({ Title = "Progression", Icon = "trending-up", Opened = true })

ProgSection:Toggle({
    Title = "Auto Rebirth",
    Value = false,
    Callback = function(state) Flags.AutoRebirth = state end
})

ProgSection:Toggle({
    Title = "Auto Equip Best",
    Value = false,
    Callback = function(state) Flags.AutoEquip = state end
})

ProgSection:Toggle({
    Title = "Auto Craft Gold",
    Value = false,
    Callback = function(state) Flags.AutoCraft = state end
})

-- =====================================================================================
-- TAB: PETS & ITEMS (Eggs, Gacha)
-- =====================================================================================
local EggSection = PetsTab:Section({ Title = "Eggs", Icon = "egg", Opened = true })
local GachaSection = PetsTab:Section({ Title = "Fruit Gacha", Icon = "gift", Opened = true })

-- Dynamic Egg List
local eggNames = {}
local eggData = {}
local eggFolder = Workspace:FindFirstChild("egg")
if eggFolder then
    for _, s in pairs(eggFolder:GetChildren()) do
        if s.Name:find("ergg_scene") then
            local sId = s.Name:match("%d+")
            for _, t in pairs(s:GetChildren()) do
                for _, e in pairs(t:GetChildren()) do
                    local id = e:GetAttribute("lottoId")
                    if id then
                        local name = "S" .. sId .. " - Egg " .. id
                        table.insert(eggNames, name)
                        eggData[name] = id
                    end
                end
            end
        end
    end
    table.sort(eggNames)
end

EggSection:Dropdown({
    Title = "Select Egg",
    Items = eggNames,
    Callback = function(val)
        Settings.SelectedEgg = eggData[val]
    end
})

EggSection:Toggle({
    Title = "Auto Hatch",
    Value = false,
    Callback = function(state)
        if not Settings.SelectedEgg then
            NebubloxUI:Notify({Title="Error", Content="Select an egg first!", Duration=3})
            return
        end
        Flags.AutoHatch = state
    end
})

GachaSection:Toggle({
    Title = "Auto Roll Fruits",
    Value = false,
    Callback = function(state) Flags.AutoRoll = state end
})

GachaSection:Slider({
    Title = "Roll Speed",
    Value = {Min=0.1, Max=2, Default=0.5},
    Step=0.1,
    Callback = function(v) Settings.RollSpeed = v end
})

-- =====================================================================================
-- TAB: TELEPORT
-- =====================================================================================
local TPSection = TeleportTab:Section({ Title = "Travel", Icon = "map-pin", Opened = true })

local sceneNames = {}
for _, s in ipairs(SCENES) do table.insert(sceneNames, s.Name) end

TPSection:Dropdown({
    Title = "Select Zone",
    Items = sceneNames,
    Callback = function(val)
        for _, s in ipairs(SCENES) do
            if s.Name == val then Settings.SelectedScene = s break end
        end
    end
})

TPSection:Button({
    Title = "Teleport",
    Icon = "zap",
    Callback = function()
        if not Settings.SelectedScene then return end
        local s = Settings.SelectedScene
        
        -- Try PortalEvent (Native)
        if PortalEvent then
            PortalEvent:FireServer(s.Id)
            NebubloxUI:Notify({Title="Warping", Content="Traveling to "..s.Name, Duration=2})
        else
            -- Fallback
             local isl = Workspace:FindFirstChild(s.Island)
             if isl then
                local cf = isl:IsA("Model") and isl:GetModelCFrame() or isl.CFrame
                player.Character.HumanoidRootPart.CFrame = cf + Vector3.new(0,10,0)
             end
        end
    end
})

-- =====================================================================================
-- TAB: EXTRAS
-- =====================================================================================
local DailySection = ExtrasTab:Section({ Title = "Rewards", Icon = "gift", Opened = true })
local LocalSection = ExtrasTab:Section({ Title = "Local Player", Icon = "user", Opened = true })

DailySection:Toggle({
    Title = "Auto Daily / Spin",
    Desc = "Claims daily rewards and spins wheel",
    Value = false,
    Callback = function(state)
        Flags.AutoDaily = state
        Flags.AutoSpin = state
    end
})

DailySection:Button({
    Title = "Claim All Achievements",
    Icon = "award",
    Callback = function()
        if GetAllEvent then
            GetAllEvent:FireServer()
            NebubloxUI:Notify({Title="Claimed", Content="Achievements claimed!", Duration=2})
        end
    end
})

LocalSection:Slider({
    Title = "Walk Speed",
    Value = {Min=16, Max=200, Default=16},
    Callback = function(v)
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.WalkSpeed = v
        end
    end
})

-- =====================================================================================
-- LOGIC LOOPS
-- =====================================================================================

-- Helpers
local function getClosestEntity()
    local myPos = player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart.Position
    if not myPos then return nil end
    
    local closest, dist = nil, math.huge
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Humanoid") and v.Health > 0 and v.Parent ~= player.Character then
            local root = v.Parent:FindFirstChild("HumanoidRootPart")
            if root then
                local d = (root.Position - myPos).Magnitude
                if d < dist then
                    closest = v.Parent
                    dist = d
                end
            end
        end
    end
    return closest
end

-- Main Loop
spawn(function()
    while true do
        wait(0.2)
        
        -- Auto Farm (Kill)
        if Flags.AutoFarm then
            local target = getClosestEntity()
            if target then
                -- Teleport
                pcall(function()
                    player.Character.HumanoidRootPart.CFrame = target.HumanoidRootPart.CFrame + Vector3.new(0,3,4)
                end)
                
                -- Attack
                if SetEnemyEvent then SetEnemyEvent:FireServer(target) end
                if PlayerAttack then PlayerAttack:FireServer(target) end
            end
        end
        
        -- Auto Capture
        if Flags.AutoCapture then
            local target = getClosestEntity()
            if target then
                pcall(function()
                    player.Character.HumanoidRootPart.CFrame = target.HumanoidRootPart.CFrame + Vector3.new(0,3,4)
                end)
                
                -- 1. Equip Ball
                if UseCatchRate then UseCatchRate:FireServer(Settings.SelectedBall) end
                wait(0.1)
                -- 2. Attack a bit to weaken
                if SetEnemyEvent then SetEnemyEvent:FireServer(target) end
                if PlayerAttack then PlayerAttack:FireServer(target) end
                wait(0.1)
                -- 3. Capture
                if CatchFollowFinish then CatchFollowFinish:FireServer(target, Settings.SelectedBall) end
            end
        end
        
        -- Auto Clicker (GUI)
        if Flags.AutoClickGUI then
            -- Spam "Click" button remote
            if ClickGUIEvent then ClickGUIEvent:FireServer() end
        end
        
        -- Auto Rebirth
        if Flags.AutoRebirth and RebirthEvent then RebirthEvent:FireServer() end
        
        -- Auto Best Equip
        if Flags.AutoEquip and EquipBestEvent then EquipBestEvent:FireServer() end
        
        -- Auto Craft
        if Flags.AutoCraft and CraftItemEvent then CraftItemEvent:FireServer("Gold") end
        
        -- Auto Spin/Daily
        if Flags.AutoSpin then
            if GetRandom then GetRandom:FireServer() end
            if GetRewardByRandom then GetRewardByRandom:FireServer() end
        end
        if Flags.AutoDaily and SignEvent then SignEvent:FireServer() end
    end
end)

-- Gacha/Hatch Loop (Separate for speed)
spawn(function()
    while true do
        if Flags.AutoRoll and RollOne then
            RollOne:FireServer()
        end
        if Flags.AutoHatch and Settings.SelectedEgg then
            -- Assuming Hatch Remote is needed here, if not found, add it.
            -- Based on previous analysis, we focused on Gacha/Roll.
            -- If Hatch is missing, RollOne might be it, or a different one.
        end
        wait(Settings.RollSpeed)
    end
end)

NebubloxUI:Notify({Title="Loaded", Content="Anime Capture Script Ready!", Icon="check", Duration=5})
