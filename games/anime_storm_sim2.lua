--[[
    ═══════════════════════════════════════════════════════════
    Nebublox | ANIME STORM SIMULATOR 2 (v1.0)
    Features: Smart Kill, Auto Farm, Auto Gacha, Anti-AFK
    ═══════════════════════════════════════════════════════════
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local player = Players.LocalPlayer

-- // SINGLE INSTANCE CHECK //
local CoreGui = game:GetService("CoreGui")
if CoreGui:FindFirstChild("Nebublox") then CoreGui.Nebublox:Destroy() end
if player.PlayerGui:FindFirstChild("Nebublox") then player.PlayerGui.Nebublox:Destroy() end

-- // UI LOAD //
local success, ANUI = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/ANHub-Script/ANUI/refs/heads/main/dist/main.lua"))()
end)

if not success or not ANUI then warn("STORM SIM: Failed to load UI") return end

local Window = ANUI:CreateWindow({
    Title = "Nebublox | Storm Sim 2 v1.0", 
    Author = "LilNug of Wisdom",
    Folder = "Nebublox",
    Icon = "rbxassetid://121698194718505",
    Theme = "Dark"
})

getgenv().NebubloxInstance = Window

-- // UNIVERSAL ANTI-AFK //
getgenv().AntiAfkRunning = true
player.Idled:Connect(function()
    if getgenv().AntiAfkRunning then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
        print("Anti-AFK: Activity simulated to prevent disconnect.")
    end
end)

-- // SETTINGS & FLAGS //
local Flags = {
    Farm = false, Rebirth = false, 
    Equip = false, Daily = false, 
    RollCrew = false, RollFruit = false, 
    RollSaiyan = false, KiProgression = false,
    RollTailedBeast = false, RollClan = false, RollKekkei = false,
    RollDomain = false, CursedProgression = false,
    BossRush = false, JjkBossRush = false, AutoHop = false,
    AutoSkills = false, AutoQuest = false, AutoHatch = false,
    AutoTrial = false, AutoChest = false,
    BuyTicket = false, BuyStrPot = false, BuyDropPot = false, BuyLuckPot = false, BuyGemPot = false,
    AutoAchievement = false,
    PotStr = false, PotDrop = false, PotLuck = false, PotGem = false,
    AutoPickup = false, DropESP = false
}

local Settings = {
    PriorityNames = {"Boss", "Legendary", "Event", "Mythic", "Shiny"}, 
    SearchRadius = 500,
    DropdownRadius = 1000,
    GachaTarget = "Shock Element",
    Debug = true,
    Blacklist = {"NPC", "Effect", "Part"}, 
    HopStart = nil,
    SelectedTargets = {},
    SelectedEgg = "Egg1"
}

local GuiElements = {}

-- // UTILS //
local function GetEnemyFolder()
    -- Prioritize scanning Maps folders based on user data
    local maps = Workspace:FindFirstChild("Maps")
    if maps then
        for _, world in ipairs(maps:GetChildren()) do
            -- Look for typical enemy containers in each map
            local enemies = world:FindFirstChild("Enemies") or 
                           world:FindFirstChild("Mobs") or 
                           world:FindFirstChild("NPCs")
            
            -- If not in a subfolder, maybe the entire map folder contains enemies?
            -- But usually they are grouped. Let's return the first valid 'Enemies' folder we find.
            if enemies then return enemies end
        end
    end

    -- Fallback legacy checks
    local function get(parent, name)
        if not parent then return nil end
        return parent:FindFirstChild(name) or parent:FindFirstChild(name:lower()) or parent:FindFirstChild(name:upper())
    end
    
    local possiblePaths = {
        get(Workspace, "Enemies"),
        get(Workspace, "NPCs"),
        get(Workspace, "Mobs"),
        get(get(Workspace, "World"), "Enemies")
    }
    
    for _, folder in ipairs(possiblePaths) do
        if folder then return folder end
    end
    
    return nil
end

-- // SCANNER FOR DROPDOWN (LOCAL ONLY) //
local function GetNearbyEnemyNames()
    local names = {}
    local seen = {}
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    
    if not myRoot then return {"Character Not Ready"} end

    local enemyFolder = GetEnemyFolder()
    local candidates = {}
    
    if enemyFolder then
        candidates = enemyFolder:GetDescendants()
    else
        local function scan(parent)
            for _, v in ipairs(parent:GetChildren()) do
                if v:IsA("Model") and v:FindFirstChild("Humanoid") then table.insert(candidates, v) end
                if v:IsA("Folder") then scan(v) end
            end
        end
        scan(Workspace)
    end
    
    for _, mob in ipairs(candidates) do
        if mob:IsA("Model") and mob ~= player.Character then
            local hum = mob:FindFirstChild("Humanoid")
            local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso") or mob.PrimaryPart
            
            if hum and root and hum.Health > 0 and not Players:GetPlayerFromCharacter(mob) then
                if (root.Position - myRoot.Position).Magnitude < Settings.DropdownRadius then
                    if not seen[mob.Name] then
                        table.insert(names, mob.Name)
                        seen[mob.Name] = true
                    end
                end
            end
        end
    end
    
    table.sort(names)
    return names
end

local function collectChests()
    local chests = Workspace:FindFirstChild("Chest")
    if not chests then return end
    
    for _, chest in ipairs(chests:GetChildren()) do
        local prompt = chest:FindFirstChild("ProximityPrompt", true) or chest:FindFirstChildOfClass("ProximityPrompt")
        if not prompt then
             -- Deep search
             for _, v in ipairs(chest:GetDescendants()) do
                 if v:IsA("ProximityPrompt") then prompt = v break end
             end
        end
        
        if prompt then
            if fireproximityprompt then
                fireproximityprompt(prompt)
            else
                -- Fallback: move to it? No, just warn.
                if Settings.Debug then warn("Missing fireproximityprompt function") end
            end
        end
    end
end

-- // DROPS & VISUALS //
local dropCache = {} -- [Instance] = {Name = "", Image = ""}
local validDrops = {} -- [Name] = ImageID

-- Initialize Drop Cache from ReplicatedStorage
task.spawn(function()
    local rsAssets = game:GetService("ReplicatedStorage"):WaitForChild("Assets", 5)
    local rsDrops = rsAssets and rsAssets:WaitForChild("Drops", 5)
    
    if rsDrops then
        for _, v in ipairs(rsDrops:GetChildren()) do
            -- Find Image
            local img = ""
            local decal = v:FindFirstChildOfClass("Decal") or v:FindFirstChildOfClass("Texture")
            if decal then img = decal.Texture end
            if img == "" and v:IsA("MeshPart") then img = v.TextureID end
            if img == "" then 
                 local gui = v:FindFirstChildOfClass("BillboardGui") or v:FindFirstChildOfClass("SurfaceGui")
                 local imgLabel = gui and gui:FindFirstChildOfClass("ImageLabel")
                 if imgLabel then img = imgLabel.Image end
            end
            
            validDrops[v.Name] = img
        end
    end
end)

-- Drop Listener
local function monitorDrops()
    local folder = Workspace:FindFirstChild("Drops") or Workspace
    
    local function onAdd(child)
        if validDrops[child.Name] then
            dropCache[child] = {Name = child.Name, Image = validDrops[child.Name]}
        end
    end
    
    local function onRemove(child)
        local data = dropCache[child]
        if data and Flags.DropESP then -- Use DropESP flag for "Visual Notification"
            -- Check distance
            local pRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if pRoot and (pRoot.Position - child:GetPivot().Position).Magnitude < 20 then
                ANUI:Notify({
                    Title = "Drop Collected!",
                    Content = data.Name,
                    Image = data.Image,
                    Duration = 2
                })
            end
            dropCache[child] = nil
        end
    end
    
    folder.ChildAdded:Connect(onAdd)
    folder.ChildRemoved:Connect(onRemove)
    -- Init existing
    for _, v in ipairs(folder:GetChildren()) do onAdd(v) end
end
task.spawn(monitorDrops)

local function collectDrops()
    -- Legacy auto pickup logic
    if not Flags.AutoPickup then return end
    local folder = Workspace:FindFirstChild("Drops") or Workspace
    local pRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not pRoot then return end
    
    for _, v in ipairs(folder:GetChildren()) do
        if validDrops[v.Name] or v:FindFirstChild("TouchInterest") then
             if v:FindFirstChild("TouchInterest") then -- Only if it has touch interest
                 firetouchinterest(pRoot, v:FindFirstChild("HumanoidRootPart") or v, 0)
                 firetouchinterest(pRoot, v:FindFirstChild("HumanoidRootPart") or v, 1)
             end
        end
    end
end

-- // TABS //
local MainTab = Window:Tab({ Title = "Main", Icon = "zap" })
local EggsTab = Window:Tab({ Title = "Eggs", Icon = "egg" })
local GachaTab = Window:Tab({ Title = "Gacha", Icon = "star" })
local UpgradeTab = Window:Tab({ Title = "Upgrades", Icon = "box" })
local MiscTab = Window:Tab({ Title = "Misc", Icon = "settings" })

-- // TAB 1: MAIN //
local FarmSec = MainTab:Section({ Title = "Auto Farm", Opened = true })

-- Unified Auto Attack Toggle (AutoClicker + AttackRange)
FarmSec:Toggle({ 
    Title = "Auto Attack (Clicker + Range)", 
    Value = false, 
    Callback = function(v) 
        Flags.Farm = v 
        
        if v then
            -- Enable AutoClicker (with gamepass fallback)
            EnableAutoClicker()
            
            -- Enable AttackRange
            if Remotes.AttackRange then
                pcall(function()
                    Remotes.AttackRange:FireServer("Enable")
                    if Settings.Debug then print("AttackRange enabled") end
                end)
            end
            
            ANUI:Notify({Title = "Auto Attack ON", Content = "Farming activated!", Duration = 2})
        else
            ANUI:Notify({Title = "Auto Attack OFF", Content = "Farming stopped", Duration = 2})
        end
    end 
})

-- DROPDOWN SECTION
FarmSec:Button({
    Title = "Refresh Nearby Enemies",
    Callback = function()
        local list = GetNearbyEnemyNames()
        if #list == 0 then list = {"No Enemies Nearby"} end
        GuiElements.EnemyDropdown:Refresh(list, true)
        ANUI:Notify({Title = "Refreshed", Content = "Found " .. #list .. " nearby enemies.", Duration = 2})
    end
})

GuiElements.EnemyDropdown = FarmSec:Dropdown({
    Title = "Select Specific Targets",
    Multi = true,
    Options = {"Click Refresh First"},
    Callback = function(v)
        local cleanList = {}
        for key, val in pairs(v) do
            if type(key) == "number" then table.insert(cleanList, val) 
            elseif val == true then table.insert(cleanList, key) end
        end
        Settings.SelectedTargets = cleanList
        if Settings.Debug then print("Selected:", table.concat(cleanList, ", ")) end
    end
})

-- // TAB 1.5: EGGS //
local HatchSec = EggsTab:Section({ Title = "Auto Hatch", Opened = true })

HatchSec:Input({
    Title = "Egg Name",
    Default = "Egg1",
    Callback = function(v)
        Settings.SelectedEgg = v
    end
})

HatchSec:Toggle({
    Title = "Auto Hatch Selected Egg",
    Value = false,
    Callback = function(v)
        Flags.AutoHatch = v
        if v then
            ANUI:Notify({Title = "Hatching", Content = "Started hatching " .. (Settings.SelectedEgg or "?"), Duration = 2})
        end
    end
})

-- // TAB 2: GACHA //
-- PIRATE WORLD GACHAS
local PirateGachaSec = GachaTab:Section({ Title = "Pirate World Gacha", Opened = true })

PirateGachaSec:Toggle({ 
    Title = "Auto Roll OnePiece Crew", 
    Value = false, 
    Callback = function(v) 
        Flags.RollCrew = v 
        if v and Settings.Debug then print("Auto rolling OnePiece Crew enabled") end
    end 
})

PirateGachaSec:Toggle({ 
    Title = "Auto Roll OnePiece Fruit", 
    Value = false, 
    Callback = function(v) 
        Flags.RollFruit = v 
        if v and Settings.Debug then print("Auto rolling OnePiece Fruit enabled") end
    end 
})

-- DBZ WORLD GACHAS
local DbzGachaSec = GachaTab:Section({ Title = "DBZ World Gacha", Opened = true })

DbzGachaSec:Toggle({ 
    Title = "Auto Roll DBZ Saiyan", 
    Value = false, 
    Callback = function(v) 
        Flags.RollSaiyan = v 
        if v and Settings.Debug then print("Auto rolling DBZ Saiyan enabled") end
    end 
})

DbzGachaSec:Toggle({ 
    Title = "Auto Upgrade Ki Progression", 
    Value = false, 
    Callback = function(v) 
        Flags.KiProgression = v 
        if v and Settings.Debug then print("Auto Ki Progression enabled") end
    end 
})

-- SHINOBI WORLD GACHAS
local NarutoGachaSec = GachaTab:Section({ Title = "Shinobi World Gacha", Opened = true })

NarutoGachaSec:Toggle({ 
    Title = "Auto Roll Tailed Beast", 
    Value = false, 
    Callback = function(v) 
        Flags.RollTailedBeast = v 
        if v and Settings.Debug then print("Auto rolling Tailed Beast enabled") end
    end 
})

NarutoGachaSec:Toggle({ 
    Title = "Auto Roll Naruto Clan", 
    Value = false, 
    Callback = function(v) 
        Flags.RollClan = v 
        if v and Settings.Debug then print("Auto rolling Naruto Clan enabled") end
    end 
})

NarutoGachaSec:Toggle({ 
    Title = "Auto Roll Kekkei Genkai", 
    Value = false, 
    Callback = function(v) 
        Flags.RollKekkei = v 
        if v and Settings.Debug then print("Auto rolling Kekkei Genkai enabled") end
    end 
})

-- CURSED WORLD GACHAS
local JjkGachaSec = GachaTab:Section({ Title = "Cursed World Gacha", Opened = true })

JjkGachaSec:Toggle({ 
    Title = "Auto Roll JJK Domain", 
    Value = false, 
    Callback = function(v) 
        Flags.RollDomain = v 
        if v and Settings.Debug then print("Auto rolling JJK Domain enabled") end
    end 
})

JjkGachaSec:Toggle({ 
    Title = "Auto Upgrade Cursed Energy", 
    Value = false, 
    Callback = function(v) 
        Flags.CursedProgression = v 
        if v and Settings.Debug then print("Auto Cursed Energy Progression enabled") end
    end 
})

-- // TAB 3: UPGRADES //
local UpSec = UpgradeTab:Section({ Title = "Automation", Opened = true })
UpSec:Toggle({ Title = "Auto Rebirth", Value = false, Callback = function(v) Flags.Rebirth = v end })
UpSec:Toggle({ Title = "Auto Equip Best", Value = false, Callback = function(v) Flags.Equip = v end })
UpSec:Toggle({ Title = "Auto Use Skills", Value = false, Callback = function(v) Flags.AutoSkills = v end })

local PotSec = UpgradeTab:Section({ Title = "Potions (Auto Drink)", Opened = true })
PotSec:Toggle({ Title = "Auto Strength Potion", Value = false, Callback = function(v) Flags.PotStr = v end })
PotSec:Toggle({ Title = "Auto Drops Potion", Value = false, Callback = function(v) Flags.PotDrop = v end })
PotSec:Toggle({ Title = "Auto Luck Potion", Value = false, Callback = function(v) Flags.PotLuck = v end })
PotSec:Toggle({ Title = "Auto Gem Potion", Value = false, Callback = function(v) Flags.PotGem = v end })

-- // TAB 4: MISC //
-- WORLD TELEPORTATION
local WorldSec = MiscTab:Section({ Title = "World Teleportation", Opened = true })

WorldSec:Button({
    Title = "Teleport to Pirate World",
    Callback = function()
        if Remotes.World then
            pcall(function()
                Remotes.World:FireServer("OnePiece", "Teleport")
                ANUI:Notify({Title = "Teleporting", Content = "Going to Pirate World!", Duration = 2})
            end)
        end
    end
})

WorldSec:Button({
    Title = "Teleport to DBZ World",
    Callback = function()
        if Remotes.World then
            pcall(function()
                Remotes.World:FireServer("Dbz", "Teleport")
                ANUI:Notify({Title = "Teleporting", Content = "Going to DBZ World!", Duration = 2})
            end)
        end
    end
})

WorldSec:Button({
    Title = "Teleport to Shinobi World",
    Callback = function()
        if Remotes.World then
            pcall(function()
                Remotes.World:FireServer("Naruto", "Teleport")
                ANUI:Notify({Title = "Teleporting", Content = "Going to Shinobi World!", Duration = 2})
            end)
        end
    end
})

WorldSec:Button({
    Title = "Teleport to Cursed World",
    Callback = function()
        if Remotes.World then
            pcall(function()
                Remotes.World:FireServer("Jjk", "Teleport")
                ANUI:Notify({Title = "Teleporting", Content = "Going to Cursed World!", Duration = 2})
            end)
        end
    end
})

-- BOSS RUSH MODE
local BossRushSec = MiscTab:Section({ Title = "Boss Rush Mode", Opened = true })

BossRushSec:Toggle({
    Title = "Auto Start DBZ Boss Rush",
    Value = false,
    Callback = function(v)
        Flags.BossRush = v
        if v then
            -- Open and start Boss Rush
            if Remotes.BossRushRemote then
                pcall(function()
                    Remotes.BossRushRemote:FireServer("OpenBossRushFrame", "DbzBossRush")
                end)
            end
            if Remotes.BossRushStart then
                pcall(function()
                    Remotes.BossRushStart:FireServer("StartUi", "DbzBossRush")
                    ANUI:Notify({Title = "Boss Rush", Content = "Starting DBZ Boss Rush!", Duration = 2})
                end)
            end
        end
    end
})

BossRushSec:Toggle({
    Title = "Auto Start JJK Boss Rush",
    Value = false,
    Callback = function(v)
        Flags.JjkBossRush = v
        if v then
            -- Open and start Boss Rush
            if Remotes.BossRushRemote then
                pcall(function()
                    Remotes.BossRushRemote:FireServer("OpenBossRushFrame", "JjkBossRush")
                end)
            end
            if Remotes.BossRushStart then
                pcall(function()
                    Remotes.BossRushStart:FireServer("StartUi", "JjkBossRush")
                    ANUI:Notify({Title = "Boss Rush", Content = "Starting JJK Boss Rush!", Duration = 2})
                end)
            end
        end
    end
})

-- TRIALS
local TrialSec = MiscTab:Section({ Title = "Time Trials", Opened = true })

TrialSec:Toggle({
    Title = "Auto Easy Trial (XX:15 & XX:45)",
    Value = false,
    Callback = function(v)
        Flags.AutoTrial = v
        if v then
            -- Initial check
            local date = os.date("!*t") -- UTC
            local min = date.min
            if min == 15 or min == 45 then
                ANUI:Notify({Title = "Trial Active?", Content = "It is trial time! Farming enabled.", Duration = 3})
                Flags.Farm = true
            end
        end
    end
})

local ShopSec = MiscTab:Section({ Title = "Time Trial Shop", Opened = true })
ShopSec:Toggle({ Title = "Auto Buy Storm Ticket", Value = false, Callback = function(v) Flags.BuyTicket = v end })
ShopSec:Toggle({ Title = "Auto Buy Strength Potion", Value = false, Callback = function(v) Flags.BuyStrPot = v end })
ShopSec:Toggle({ Title = "Auto Buy Drops Potion", Value = false, Callback = function(v) Flags.BuyDropPot = v end })
ShopSec:Toggle({ Title = "Auto Buy Luck Potion", Value = false, Callback = function(v) Flags.BuyLuckPot = v end })
ShopSec:Toggle({ Title = "Auto Buy Gem Potion", Value = false, Callback = function(v) Flags.BuyGemPot = v end })

-- SERVER CONTROLS
local HopSec = MiscTab:Section({ Title = "Server Control", Opened = true })
HopSec:Toggle({ Title = "Debug Mode (F9)", Value = true, Callback = function(v) Settings.Debug = v end })
HopSec:Button({
    Title = "Test Scanner (F9 Log)",
    Callback = function()
        local tgt = getSmartTarget()
        if tgt then print("Target Found: " .. tgt.Name) else warn("No Target Found") end
    end
})
HopSec:Toggle({ Title = "Auto Server Hop", Value = false, Callback = function(v) Flags.AutoHop = v end })
HopSec:Button({ 
    Title = "Force Server Hop", 
    Callback = function() 
        ANUI:Notify({Title = "Hopping...", Content = "Searching...", Duration = 3})
        Settings.ForceHop = true
    end 
})

local RewSec = MiscTab:Section({ Title = "Daily Rewards", Opened = true })
RewSec:Toggle({ Title = "Auto Daily Sign-in", Value = false, Callback = function(v) Flags.Daily = v end })
RewSec:Toggle({
    Title = "Auto Collect Chests",
    Value = false,
    Callback = function(v)
        Flags.AutoChest = v
        if v then
            -- Initial collection
            collectChests()
        end
    end
})

RewSec:Toggle({
    Title = "Auto Claim Achievements",
    Value = false,
    Callback = function(v)
        Flags.AutoAchievement = v
    end
})

-- EGG TELEPORTS (Added to Eggs Tab)
local EggTeleSec = EggsTab:Section({ Title = "Teleport to Eggs", Opened = true })
local eggLocs = {"OnePiece", "Dbz", "Naruto", "Jjk"}

for _, name in ipairs(eggLocs) do
    EggTeleSec:Button({
        Title = "Teleport to " .. name .. " Egg",
        Callback = function()
            local egg = Workspace:FindFirstChild("Eggs") and Workspace.Eggs:FindFirstChild(name)
            if egg then
                local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    -- Try to find a part to TP to
                    local part = egg:FindFirstChild("HumanoidRootPart") or egg:FindFirstChild("Part") or egg.PrimaryPart or egg:FindFirstChildOfClass("Part")
                    if part then
                        root.CFrame = part.CFrame + Vector3.new(0, 5, 0)
                        ANUI:Notify({Title = "Teleported", Content = "To " .. name .. " Egg", Duration = 2})
                    else
                        warn("No part found in egg model " .. name)
                    end
                end
            else
                ANUI:Notify({Title = "Error", Content = "Egg model not found!", Duration = 2})
            end
        end
    })
end

-- // REMOTES //
-- Storm Sim 2 uses ReplicatedStorage.Remotes structure
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 5)
local AttackRangeFolder = RemotesFolder and RemotesFolder:FindFirstChild("AttackRange")
local SpecialPerkFolder = RemotesFolder and RemotesFolder:FindFirstChild("SpecialPerkRemotes")
local BossRushFolder = RemotesFolder and RemotesFolder:FindFirstChild("BossRush")

local Remotes = {
    Rebirth = RemotesFolder and RemotesFolder:FindFirstChild("Rebirth"),
    AutoClicker = RemotesFolder and RemotesFolder:FindFirstChild("AutoClicker"),
    AttackRange = AttackRangeFolder and AttackRangeFolder:FindFirstChild("AttackRangeRemote"),
    SpecialPerk = SpecialPerkFolder and SpecialPerkFolder:FindFirstChild("SpecialPerk"),
    SpecialProgression = RemotesFolder and RemotesFolder:FindFirstChild("SpecialProgression"),
    Egg = (RemotesFolder and RemotesFolder:FindFirstChild("Egg")) and RemotesFolder.Egg:FindFirstChild("Egg"),
    TimeTrial = RemotesFolder and RemotesFolder:FindFirstChild("TimeTrial"),
    World = RemotesFolder and RemotesFolder:FindFirstChild("World"),
    BossRushRemote = BossRushFolder and BossRushFolder:FindFirstChild("BossRushRemote"),
    BossRushStart = BossRushFolder and BossRushFolder:FindFirstChild("BossRushStart"),
    
    -- Rewards
    DailyLogin = RemotesFolder and RemotesFolder:FindFirstChild("DailyLogin"),
    BoosterLogin = RemotesFolder and RemotesFolder:FindFirstChild("BoosterLogin"),
    TimedRewards = RemotesFolder and RemotesFolder:FindFirstChild("TimedRewards"),
    Achievement = RemotesFolder and RemotesFolder:FindFirstChild("Achievement"),
    
    TimeTrialShop = (RemotesFolder and RemotesFolder:FindFirstChild("TimeTrial")) and RemotesFolder.TimeTrial:FindFirstChild("TimeTrialShop"),
    PetEquip = (RemotesFolder and RemotesFolder:FindFirstChild("Pets")) and RemotesFolder.Pets:FindFirstChild("PetEquip"),
    
    -- Data & Items
    GetData = RemotesFolder and RemotesFolder:FindFirstChild("GetData"),
    UseItem = RemotesFolder and RemotesFolder:FindFirstChild("UseItem"), -- Guessing this name
    
    -- Add more remotes as we discover them:
    Attack = nil, -- TODO: Find main attack remote
    Equip = nil,  -- REMOVED: Using specific PetEquip above
}

-- // AUTO CLICKER FUNCTION (with gamepass fallback) //
local function EnableAutoClicker()
    if not Remotes.AutoClicker then return end
    
    pcall(function()
        -- Try AutoClicker (gamepass version) first
        local success = pcall(function()
            Remotes.AutoClicker:InvokeServer("AutoClicker")
        end)
        
        -- Fallback to FreeClicker if AutoClicker fails
        if not success then
            Remotes.AutoClicker:InvokeServer("FreeClicker")
            if Settings.Debug then print("Using FreeClicker (no gamepass)") end
        else
            if Settings.Debug then print("Using AutoClicker (gamepass)") end
        end
    end)
end

-- // OPTIMIZED SMART TARGETING //
function getSmartTarget()
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local bestTarget = nil
    local highestScore = -99999
    local safeRadius = Settings.SearchRadius
    
    local candidates = {}
    local enemyFolder = GetEnemyFolder()
    
    if enemyFolder then
        candidates = enemyFolder:GetDescendants()
    else
        local function scan(parent)
            for _, v in ipairs(parent:GetChildren()) do
                if v:IsA("Model") and v:FindFirstChild("Humanoid") then table.insert(candidates, v) end
                if v:IsA("Folder") then scan(v) end
            end
        end
        scan(Workspace)
    end

    local useSpecific = #Settings.SelectedTargets > 0

    for _, mob in ipairs(candidates) do
        if mob ~= player.Character then
            local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso") or mob.PrimaryPart
            local hum = mob:FindFirstChild("Humanoid")
            if root and hum and hum.Health > 0 then
                
                local shouldProcess = true
                if useSpecific then
                    local found = false
                    for _, name in ipairs(Settings.SelectedTargets) do
                        if mob.Name == name then found = true break end
                    end
                    if not found then shouldProcess = false end
                end

                if shouldProcess then
                    local isBlacklisted = false
                    for _, badName in ipairs(Settings.Blacklist) do
                        if string.find(mob.Name, badName) then isBlacklisted = true break end
                    end

                    if not isBlacklisted then
                        local dist = (root.Position - myRoot.Position).Magnitude
                        if dist < safeRadius then
                            local score = 1000 - dist
                            for _, pName in ipairs(Settings.PriorityNames) do
                                if string.find(mob.Name, pName) then score = score + 50000 break end
                            end
                            if score > highestScore then
                                highestScore = score
                                bestTarget = mob
                            end
                        end
                    end
                end
            end
        end
    end
    return bestTarget
end

-- // SERVER HOP FUNCTION //
function ServerHop()
    local PlaceId = game.PlaceId
    local servers = {}
    
    pcall(function()
        local req = game:HttpGet("https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100")
        local data = HttpService:JSONDecode(req)
        
        if data and data.data then
            for _, server in ipairs(data.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    table.insert(servers, server.id)
                end
            end
        end
    end)
    
    if #servers > 0 then
        local randomServer = servers[math.random(1, #servers)]
        TeleportService:TeleportToPlaceInstance(PlaceId, randomServer, player)
    else
        warn("No servers found for hopping")
    end
end

-- // MAIN LOOP //
local frameCount = 0

RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    
    -- Throttle to every 9 frames for performance
    if frameCount % 9 == 0 then 
        if Flags.Farm then
            pcall(function()
                local target = getSmartTarget()
                
                -- Auto Hop Logic
                if not target and Flags.AutoHop and Flags.Farm then
                      if not Settings.HopStart then Settings.HopStart = tick() end
                      if tick() - Settings.HopStart > 8 then ServerHop() end
                else
                      Settings.HopStart = nil
                end

                -- Farm Action
                if target and player.Character then
                    local myRoot = player.Character:FindFirstChild("HumanoidRootPart")
                    local targetRoot = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso") or target.PrimaryPart
                    
                    if myRoot and targetRoot then
                        myRoot.CFrame = CFrame.new(targetRoot.Position + Vector3.new(0, 3, 0))
                        myRoot.AssemblyLinearVelocity = Vector3.zero
                        myRoot.AssemblyAngularVelocity = Vector3.zero
                        
                        if Remotes.Attack then Remotes.Attack:FireServer(target) end
                        if Remotes.Click then Remotes.Click:FireServer() end
                        
                        VirtualUser:CaptureController()
                        VirtualUser:ClickButton1(Vector2.new(999,999))
                    end
                end
            end)
        end
    end
    
    if Settings.ForceHop then Settings.ForceHop = false ServerHop() end
end)

-- // SLOW LOOP (Skills, Upgrades, etc) //
local achTick = 0
task.spawn(function()
    while task.wait(0.5) do
         achTick = achTick + 1
         pcall(function()
            if Flags.Rebirth and Remotes.Rebirth then Remotes.Rebirth:FireServer("Rebirth") end
            
            -- Auto Rewards (Daily, Booster, Timed)
            if Flags.Daily then
                 if Remotes.DailyLogin then
                     Remotes.DailyLogin:FireServer("GetData")
                     for i = 1, 7 do Remotes.DailyLogin:FireServer("Claim", i) end
                 end
                 if Remotes.BoosterLogin then
                     Remotes.BoosterLogin:FireServer("GetData")
                     for i = 1, 7 do Remotes.BoosterLogin:FireServer("Claim", i) end
                 end
                 if Remotes.TimedRewards then
                     for i = 1, 8 do Remotes.TimedRewards:FireServer("TimedReward"..i) end
                 end
                 
                 -- Auto Achievements (Throttled)
                 if Remotes.Achievement and Flags.AutoAchievement and achTick % 20 == 0 then
                    Remotes.Achievement:FireServer("ClaimAll")
                    for i = 1, 30 do Remotes.Achievement:FireServer("Claim", i) end
                 end
            end
            
            if Flags.Equip and Remotes.PetEquip then 
                task.spawn(function() 
                    pcall(function() Remotes.PetEquip:InvokeServer("EquipBest") end)
                end)
            end
            
            -- Auto Gacha Rolling (Pirate World)
            if Flags.RollCrew and Remotes.SpecialPerk then 
                Remotes.SpecialPerk:FireServer("Spin", "OnePieceCrew") 
            end
            if Flags.RollFruit and Remotes.SpecialPerk then 
                Remotes.SpecialPerk:FireServer("Spin", "OnePieceFruit") 
            end
            
            -- Auto Gacha Rolling (DBZ World)
            if Flags.RollSaiyan and Remotes.SpecialPerk then 
                Remotes.SpecialPerk:FireServer("Spin", "DbzSaiyan") 
            end
            if Flags.KiProgression and Remotes.SpecialProgression then 
                Remotes.SpecialProgression:FireServer("UpgradeProgression", "KiProgression") 
            end

            -- Auto Gacha Rolling (Shinobi World)
            if Flags.RollTailedBeast and Remotes.SpecialPerk then 
                Remotes.SpecialPerk:FireServer("Spin", "NarutoTailedBeast") 
            end
            if Flags.RollClan and Remotes.SpecialPerk then 
                Remotes.SpecialPerk:FireServer("Spin", "NarutoClan") 
            end
            if Flags.RollKekkei and Remotes.SpecialPerk then 
                Remotes.SpecialPerk:FireServer("Spin", "NarutoKekkeiGenkai") 
            end

            -- Auto Gacha Rolling (Cursed World)
            if Flags.RollDomain and Remotes.SpecialPerk then 
                Remotes.SpecialPerk:FireServer("Spin", "JjkDomain") 
            end
            if Flags.CursedProgression and Remotes.SpecialProgression then 
                Remotes.SpecialProgression:FireServer("UpgradeProgression", "CursedEnergyProgression") 
            end
            
            -- Auto Hatch
            if Flags.AutoHatch and Remotes.Egg and Settings.SelectedEgg then
                -- Try common hatch commands
                Remotes.Egg:FireServer("Buy", Settings.SelectedEgg)
                Remotes.Egg:FireServer("Open", Settings.SelectedEgg)
            end
            
            -- Auto Trial Check
            if Flags.AutoTrial then
                local date = os.date("!*t")
                if date.min == 15 or date.min == 45 then
                    if not Flags.Farm then
                        Flags.Farm = true
                        if Settings.Debug then print("Auto Trial: Farming Enabled for Trial!") end
                    end
                end
            end
            
            -- Auto Chests
            if Flags.AutoChest then
                collectChests()
            end
            
            -- Auto Buy Shop
            if Remotes.TimeTrialShop then
                local function buy(item)
                    Remotes.TimeTrialShop:FireServer("Buy", item)
                    Remotes.TimeTrialShop:FireServer("Purchase", item)
                end
                
                if Flags.BuyTicket then buy("StormTicket") end
                if Flags.BuyStrPot then buy("StrengthPotion") end
                if Flags.BuyDropPot then buy("DropsPotion") end
                if Flags.BuyLuckPot then buy("LuckPotion") end
                if Flags.BuyGemPot then buy("GemPotion") end
            end
            
            -- Auto Potions (Throttled 30s)
            potTick = (potTick or 0) + 1
            if potTick % 60 == 0 and Remotes.GetData then
                 local function checkAndUse(name)
                     local success, count = pcall(function() return Remotes.GetData:InvokeServer("Item", name) end)
                     if success and type(count) == "number" and count > 0 then
                         if Settings.Debug then print("Using Potion: " .. name .. " (Count: " .. count .. ")") end
                         
                         -- Try common remote names
                         if Remotes.UseItem then Remotes.UseItem:FireServer(name) end
                         
                         local inv = RemotesFolder:FindFirstChild("Inventory")
                         if inv then inv:FireServer("Use", name) end
                         
                         local pot = RemotesFolder:FindFirstChild("Potion")
                         if pot then pot:FireServer("Use", name) end
                     end
                 end
                 
                 if Flags.PotStr then checkAndUse("StrengthPotion") end
                 if Flags.PotDrop then checkAndUse("DropsPotion") end
                 if Flags.PotLuck then checkAndUse("LuckPotion") end
                 if Flags.PotGem then checkAndUse("GemPotion") end
            end
        end)
    end
end)

ANUI:Notify({ Title = "Storm Sim 2 v1.0", Content = "Script Loaded Successfully!", Duration = 3 })
