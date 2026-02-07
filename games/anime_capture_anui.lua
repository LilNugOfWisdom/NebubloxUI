-- // NEBUBLOX | ANIME CAPTURE //
-- // UI Library: ANUI //

local ANUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/ANHub-Script/ANUI/refs/heads/main/dist/main.lua"))()

-- // GLOBAL CONFIG //
local ScriptTitle = "Nebublox"
local ScriptIcon = "rbxassetid://127700356483621" -- Wizard Potato Icon
-- To use your custom image:
-- 1. Upload it to Roblox Decals/Images
-- 2. Copy the Asset ID from the URL (number)
-- 3. Paste it above

-- // CLOSE OLD INSTANCE //
if _G.NebubloxCapture then
    if _G.NebubloxCapture.Window then
        pcall(function() _G.NebubloxCapture.Window:Destroy() end)
        print("Closed previous Nebublox instance.")
    end
    -- Fallback cleanup
    local core = game:GetService("CoreGui")
    local pg = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    if core:FindFirstChild(ScriptTitle) then core[ScriptTitle]:Destroy() end
    if pg:FindFirstChild(ScriptTitle) then pg[ScriptTitle]:Destroy() end
    if core:FindFirstChild("NebubloxCapture") then core.NebubloxCapture:Destroy() end
    if pg:FindFirstChild("NebubloxCapture") then pg.NebubloxCapture:Destroy() end
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- // 1. CONFIGURATION //
local Flags = {
    SmartFarm = false,
    AutoCapture = false,
    AutoEquip = false,
    AutoRebirth = false,
    AutoFreeGifts = false,
    AutoDailyRewards = false,
    AutoSpin = false,
    AutoEventCollect = false,
    AutoEventGacha = false,
    AutoCharge = false,
    AntiPopup = true,
    SelectedMobs = {},
    
    -- Gacha
    SelectedGachaId = "201",
    AutoRollSelected = false
}

-- // Helper: MakeProfile //
local function MakeProfile(config) return config end

-- // 2. WINDOW CREATION //
local Window = ANUI:CreateWindow({
    Title = ScriptTitle, 
    Author = "by He Who Remains Lil'Nug",
    Folder = "NebubloxCapture",
    Icon = ScriptIcon,
    IconSize = 44,
    Theme = "Dark", 
    Transparent = false,
    SideBarWidth = 200,
    HasOutline = true,
})

-- // 3. PROFILE SETUP //
local NugProfile = MakeProfile({
    Banner = "rbxthumb://type=Asset&id=88040798502148&w=768&h=432", 
    Avatar = "rbxthumb://type=Asset&id=121698194718505&w=420&h=420", 
    Status = true,
    Title = "He Who Remains Lil'Nug",
    Desc = "@thearchitectofthemultiverse",
    Badges = {
        {
            Icon = "geist:logo-discord", 
            Title = "Discord", 
            Desc = "Join Community", 
            Callback = function() 
                setclipboard("https://discord.gg/kgu3WXGg5m")
                ANUI:Notify({Title = "Discord", Content = "Link Copied!", Icon = "check", Duration = 3})
            end
        }
    }
})

-- // 4. TABS & SECTIONS //

-- [TAB 1: MAIN]
local MainTab = Window:Tab({ Title = "Main", Icon = "home", Profile = NugProfile, SidebarProfile = true })
local InfoSection = MainTab:Section({ Title = "Info", Icon = "info", Opened = true })

InfoSection:Paragraph({
    Title = "He Who Remains Lil'Nug",
    Content = "ID: 607677349718261783\nUser: @thearchitectofthemultiverse\nStatus: Online"
})

InfoSection:Button({
    Title = "Discord Server",
    Callback = function() setclipboard("https://discord.gg/kgu3WXGg5m") ANUI:Notify({Title = "Discord", Content = "Link Copied!", Icon = "check", Duration = 3}) end
})

-- [TAB 2: FARMING]
local FarmTab = Window:Tab({ Title = "Farming", Icon = "swords", SidebarProfile = false })
local MainFarm = FarmTab:Section({ Title = "Smart Farm", Icon = "zap", Opened = true })

-- Moved Auto Capture Here (Above Enemy Priority)
MainFarm:Toggle({
    Title = "Auto Capture",
    Desc = "Spams Capture Interaction",
    Value = false,
    Callback = function(state) Flags.AutoCapture = state end
})

local CaptureDropdown = MainFarm:Dropdown({
    Title = "Enemy Priority",
    Multi = true,
    Required = false,
    Values = { {Title = "Refresh to load...", Icon = "loader"} },
    Callback = function(val)
        Flags.SelectedMobs = {}
        for k, v in pairs(val) do
            if v then Flags.SelectedMobs[k] = true end
        end
    end
})

MainFarm:Button({
    Title = "Refresh Enemies (Scan Maps)",
    Callback = function()
        local validEnemies = {}
        local seen = {}
        
        -- Helper
        local function AddEnemy(mob, icon)
            if mob:IsA("Model") and mob:FindFirstChild("Humanoid") and mob:FindFirstChild("HumanoidRootPart") then
                if Players:GetPlayerFromCharacter(mob) then return end
                
                -- CLEAN DISPLAY: Just the name, no subtitles
                if not seen[mob.Name] then
                   table.insert(validEnemies, {Title = mob.Name, Val = mob.Name, Icon = icon or "swords"})
                   seen[mob.Name] = true
                end
            end
        end

        -- 1. Scan Islands (workspace.common.Up)
        if workspace:FindFirstChild("common") and workspace.common:FindFirstChild("Up") then
            -- Sort islands 1-7
            for i = 1, 7 do
                 local island = workspace.common.Up:FindFirstChild(tostring(i))
                 if island then
                     local npcFolder = island:FindFirstChild("NPC")
                     if npcFolder then
                        for _, mob in ipairs(npcFolder:GetChildren()) do 
                            AddEnemy(mob, "swords")
                        end
                     end
                 end
            end
        end
        
        -- 2. Scan World Boss (workspace.enemy)
        if workspace:FindFirstChild("enemy") then
             for _, mob in ipairs(workspace.enemy:GetDescendants()) do
                AddEnemy(mob, "alert-circle")
            end
        end
        
        -- 3. GLOBAL FALLBACK
        if #validEnemies == 0 then
             for _, mob in ipairs(workspace:GetChildren()) do
                 if mob:IsA("Model") and mob:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(mob) then
                     if mob.Name ~= "StarterCharacter" then 
                         AddEnemy(mob, "help-circle")
                     end
                 end
             end
        end
        
        table.sort(validEnemies, function(a, b) return a.Title < b.Title end)
        
        -- Compatibility: Pass simple list of strings
        local stringList = {}
        for _, enemy in ipairs(validEnemies) do
            table.insert(stringList, enemy.Title)
        end
        
        if CaptureDropdown and CaptureDropdown.SetValues then 
            CaptureDropdown:SetValues(stringList)
        end
        ANUI:Notify({Title = "Farming", Content = "Found " .. #stringList .. " enemies!", Icon = "refresh-cw", Duration = 2})
    end
})

MainFarm:Toggle({
    Title = "Enable Instant Teleport Farm",
    Desc = "Teleports directly to enemies (no tween)",
    Value = false,
    Callback = function(state) Flags.SmartFarm = state end
})

-- [TAB 3: GACHA]
local GachaTab = Window:Tab({ Title = "Gacha", Icon = "gift", SidebarProfile = false })
local GachaSection = GachaTab:Section({ Title = "Auto Roll", Icon = "dices", Opened = true })

-- Gacha ID-to-Name Mapping
local GachaNames = {
    ["201"] = "Shock Fruit",
    ["202"] = "Flame Fruit",
    ["203"] = "Sharingan",
    ["204"] = "Tessen",
    ["205"] = "Nichirin Earring",
    ["206"] = "Swordsmith Mask",
    ["207"] = "Impression Ring",
    ["208"] = "Prison Realm", 
    ["209"] = "One Punch",
    ["210"] = "Monster Cell",
    ["212"] = "Machine 212", -- Unknown?
    ["213"] = "Machine 213", -- Unknown?
    ["221"] = "Scouter",
    ["222"] = "Dragon Radar",
    ["223"] = "Speed Mark",
    ["224"] = "Life Mark",
    ["601"] = "Event Star",
}

-- Auto-Detect Names from Workspace
if workspace:FindFirstChild("common") and workspace.common:FindFirstChild("OtherLotto") then
    for _, lotto in ipairs(workspace.common.OtherLotto:GetChildren()) do
        local id = lotto.Name
        if not GachaNames[id] then
            GachaNames[id] = "Machine " .. id
        end
    end
end

-- Generate Dropdown Values (Clean Names only)
local GachaList = {}
-- We want to iterate in a stable order
local OrderedIDs = {
    "201", "202", "203", "204", "205", "206", "207", 
    "208", "209", "210", "212", "213", "221", "222", "223", "224"
    -- Removed 601 (Event Star) as it has its own tab
}

for _, id in ipairs(OrderedIDs) do
    local name = GachaNames[id] or ("Machine " .. id)
    -- CLEAN NAME: "Shock Fruit" (User asked to remove numbers)
    table.insert(GachaList, {Title = name, Val = id})
end

GachaSection:Dropdown({
    Title = "Select Gacha Machine",
    Multi = false,
    Required = true,
    Values = GachaList,
    Callback = function(val) 
        local selected = val
        if type(val) == "table" then
            for k, v in pairs(val) do 
                 if type(k) == "number" then selected = v 
                 else selected = k end
            end
        end
        Flags.SelectedGachaId = selected
        print("Selected Gacha ID:", Flags.SelectedGachaId)
    end
})

GachaSection:Toggle({
    Title = "Auto Roll Selected",
    Desc = "Spams roll on selected ID",
    Value = false,
    Callback = function(state) Flags.AutoRollSelected = state end
})


-- [CHARGE PODIUMS SECTION]
local ChargeSection = GachaTab:Section({ Title = "Charge Podiums", Icon = "zap", Opened = true })

ChargeSection:Dropdown({
    Title = "Select Podium Level",
    Multi = false,
    Required = true,
    Values = {"1", "2", "3", "4", "5", "6", "7"},
    Callback = function(val)
        -- Handle single value
        local selected = val
        if type(val) == "table" then
            for k, v in pairs(val) do selected = v end
        end
        Flags.SelectedCharge = selected
    end
})

ChargeSection:Toggle({
    Title = "Auto Charge Selected",
    Desc = "Teleports & Uses Selected Podium",
    Value = false,
    Callback = function(state) Flags.AutoCharge = state end
})


local EventSection = GachaTab:Section({ Title = "Events", Icon = "star", Opened = true })

EventSection:Toggle({
    Title = "Auto Collect Star(s)",
    Desc = "Claims Online Time Rewards (1-12)",
    Value = false,
    Callback = function(state) Flags.AutoEventCollect = state end
})

EventSection:Toggle({
    Title = "Auto Roll Star(s)",
    Desc = "Rolls the Limited Event Gacha (ID 601)",
    Value = false,
    Callback = function(state) Flags.AutoEventGacha = state end
})

-- [TAB 4: AUTOMATION]
local AutoTab = Window:Tab({ Title = "Automation", Icon = "cpu", SidebarProfile = false })
local MiscSection = AutoTab:Section({ Title = "Misc", Icon = "settings", Opened = true })

MiscSection:Toggle({
    Title = "Auto Equip Best",
    Desc = "Automatically equips best pets/units",
    Value = false,
    Callback = function(state) Flags.AutoEquip = state end
})

MiscSection:Toggle({
    Title = "Auto Rebirth",
    Desc = "Automatically ranks up",
    Value = false,
    Callback = function(state) Flags.AutoRebirth = state end
})

MiscSection:Toggle({
    Title = "Auto Free Gifts",
    Desc = "Claims 1-12 Playtime Rewards",
    Value = false,
    Callback = function(state) Flags.AutoFreeGifts = state end
})

MiscSection:Toggle({
    Title = "Auto Daily Rewards",
    Desc = "Claims 1-7 Daily Rewards",
    Value = false,
    Callback = function(state) Flags.AutoDailyRewards = state end
})

MiscSection:Toggle({
    Title = "Auto Collect & Spin Wheel",
    Desc = "Claims free spins & uses them",
    Value = false,
    Callback = function(state) Flags.AutoSpin = state end
})

-- Removed Auto Charge from here (Moved to Gacha Tab)

MiscSection:Toggle({
    Title = "Hide Error Popups",
    Desc = "Hides 'Insufficient quantity' etc.",
    Value = true,
    Callback = function(state) Flags.AntiPopup = state end
})

-- [TAB 5: WORLDS]
local WorldTab = Window:Tab({ Title = "Worlds", Icon = "globe", SidebarProfile = false })
local TeleportSection = WorldTab:Section({ Title = "Teleports", Icon = "map-pin", Opened = true })

local Islands = {
    {Name = "Seaside Town",        Id = "1"},
    {Name = "Pirate Village",      Id = "2"},
    {Name = "Ninja Village",       Id = "3"},
    {Name = "Shirayuki Village",   Id = "4"},
    {Name = "Cursed Arts Hamlet",  Id = "5"},
    {Name = "Arcane City Lofts",   Id = "6"},
    {Name = "Lookout",             Id = "7"},
}

for _, island in ipairs(Islands) do
    TeleportSection:Button({
        Title = island.Name,
        Callback = function()
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root and workspace:FindFirstChild("building") and workspace.building:FindFirstChild("SceneChange") then
                -- USER REQUESTED REMOTE TELEPORT
                -- "0-7 for each world"
                local pIdx = tonumber(island.Id) - 1 -- Assuming 0-indexed (1->0, 2->1)
                
                local success, err = pcall(function() 
                    ReplicatedStorage.Events.Map.PortalEvent:FireServer(pIdx) 
                end)
                
                if success then
                    ANUI:Notify({Title = "Teleport", Content = "Warped to " .. island.Name, Icon = "map-pin", Duration = 2})
                    return -- Stop here if remote worked
                end
                
                -- Fallback to CFrame if remote fails
                local spawnName = "SpawnLocation" .. island.Id
                local spawner = workspace.building.SceneChange:FindFirstChild(spawnName)
                
                -- SAFE CFRAME LOGIC
                local cf = nil
                if spawner then
                    if spawner:IsA("BasePart") then cf = spawner.CFrame
                    elseif spawner:IsA("Model") then cf = spawner:GetPivot()
                    elseif spawner:IsA("Folder") then
                        -- Check inside Folder for Part
                        local p = spawner:FindFirstChildWhichIsA("BasePart", true)
                        if p then cf = p.CFrame end
                    end
                end
                
                if cf then
                    local char = player.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if root then root.CFrame = cf + Vector3.new(0, 5, 0) end
                    ANUI:Notify({Title = "Teleport", Content = "CFrame Warp to " .. island.Name, Icon = "map-pin", Duration = 2})
                else
                    ANUI:Notify({Title = "Teleport", Content = "Could not find location!", Icon = "alert-triangle", Duration = 2})
                end
            end
        end
    })
end

-- // 5. LOGIC //

-- Optimized Target Finder
local function GetSmartTarget()
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    
    local bestTarget = nil
    local shortestDist = 999999
    
    local function ScanFolder(folder)
        if not folder then return end
        for _, mob in ipairs(folder:GetDescendants()) do
            if mob:IsA("Model") and mob:FindFirstChild("Humanoid") and mob:FindFirstChild("HumanoidRootPart") and mob.Humanoid.Health > 0 then
                -- Filter
                local isSelected = true
                if next(Flags.SelectedMobs) ~= nil then
                    if not Flags.SelectedMobs[mob.Name] then isSelected = false end
                end

                if isSelected then
                    local dist = (mob.HumanoidRootPart.Position - myRoot.Position).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        bestTarget = mob
                    end
                end
            end
        end
    end

    if workspace:FindFirstChild("common") and workspace.common:FindFirstChild("Up") then
        for _, island in ipairs(workspace.common.Up:GetChildren()) do
             local folder = island:FindFirstChild("NPC")
             if folder then ScanFolder(folder) end
        end
    end
    
    if workspace:FindFirstChild("enemy") then ScanFolder(workspace.enemy) end
    
    return bestTarget
end

-- AGGRESSIVE CAPTURE LOOP
task.spawn(function()
    local captureEvent = nil
    pcall(function() captureEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("SetStatEvent", 5) end)
    
    RunService.RenderStepped:Connect(function()
        if Flags.AutoCapture and captureEvent then
            pcall(function() captureEvent:FireServer("AutoCatchFollow", true) end)
        end
        if Flags.SmartFarm and captureEvent then
            pcall(function() captureEvent:FireServer("AutoCatchFollow", true) end)
        end
    end)
    
    -- Secondary Ultra-Fast Loop
    task.spawn(function()
        while true do
            if Flags.AutoCapture and captureEvent then
                pcall(function() captureEvent:FireServer("AutoCatchFollow", true) end)
            end
            task.wait() -- Minimal yield
        end
    end)
end)

-- FARM LOOP
task.spawn(function()
    while task.wait(0.05) do
        if Flags.SmartFarm then
            pcall(function()
                local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if myRoot then
                    local target = GetSmartTarget()
                    if target and target:FindFirstChild("HumanoidRootPart") then
                         myRoot.CFrame = target.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                    end
                end
            end)
        end
    end
end)

-- GACHA & SPIN LOGIC
task.spawn(function()
    while task.wait(0.5) do
        if Flags.AutoSpin then
            pcall(function()
                 local TT = ReplicatedStorage.Events.Turntable
                 for i = 1, 7 do TT.ChangeData:FireServer(i, "Claimed") end
                 TT:FindFirstChild("[C-S]GetRandom"):InvokeServer()
            end)
        end

        if Flags.AutoRollSelected and Flags.SelectedGachaId then
            pcall(function()
                ReplicatedStorage.Events.NewLotto.RollOne:FireServer(true, tonumber(Flags.SelectedGachaId))
            end)
        end
        
        if Flags.AutoEventGacha then
            pcall(function()
                ReplicatedStorage.Events.NewLotto.RollOne:FireServer(true, 601)
            end)
        end
    end
end)

-- MISC LOOPS
task.spawn(function()
    while task.wait(5) do
        if Flags.AutoEquip then pcall(function() ReplicatedStorage.Events.Equip.EquipBestEvent:FireServer(1) end) end
        
        if Flags.AutoRebirth then
            pcall(function()
                local R = ReplicatedStorage.Events.Rebirth
                if R:FindFirstChild("RebirthEvent") then R.RebirthEvent:FireServer() end
                if R:FindFirstChild("AutoRebirthEvent") then R.AutoRebirthEvent:FireServer() end
            end)
        end

        if Flags.AutoFreeGifts then
            pcall(function() for i=1,12 do ReplicatedStorage.Events.Rewards.ClaimeTaskEvent:FireServer(i) end end)
        end
        
        if Flags.AutoDailyRewards then
            pcall(function() for i=1,7 do ReplicatedStorage.Events.OnceDaily.SignEvent:FireServer(i) end end)
        end
        
        if Flags.AutoEventCollect then
            pcall(function() for i=1,12 do ReplicatedStorage.Events.Activity.Mix.OnlineTime.GetEvent:FireServer(3, i) end end)
        end

        -- AUTO CHARGE LOOP UPDATED
        -- Path: workspace.common.Up[i].NPC.Model.Part
        if Flags.AutoCharge and Flags.SelectedCharge then
            pcall(function()
                local i = Flags.SelectedCharge
                if workspace:FindFirstChild("common") and workspace.common:FindFirstChild("Up") then
                    -- Target specific selected podium
                    local island = workspace.common.Up:FindFirstChild(tostring(i))
                    local npcFolder = island and island:FindFirstChild("NPC")
                    local model = npcFolder and npcFolder:FindFirstChild("Model")
                    local part = model and model:FindFirstChild("Part")
                    
                    if part then
                        -- 1. Teleport to it
                        local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                        if myRoot then
                            myRoot.CFrame = part.CFrame + Vector3.new(0, 3, 0)
                        end
                        
                        -- 2. Interact (Click/Prompt)
                        if part:FindFirstChild("ClickDetector") then
                            fireclickdetector(part.ClickDetector)
                        elseif part:FindFirstChildWhichIsA("ProximityPrompt") then
                            fireproximityprompt(part:FindFirstChildWhichIsA("ProximityPrompt"))
                        end
                        
                        -- 3. TouchInterest Check
                        firetouchinterest(myRoot, part, 0)
                        firetouchinterest(myRoot, part, 1)
                    end
                end
            end)
        end
    end
end)

-- Module Attack Hook
task.spawn(function()
    pcall(function()
        local Managers = player:WaitForChild("PlayerScripts", 10):WaitForChild("Managers")
        pcall(function() require(Managers.ClientManager):Init() end)
        pcall(function() require(Managers.ClientFollowManager):Init() end)
        pcall(function() require(Managers.ClientCircleEftManager):Init() end)
        
        RunService.RenderStepped:Connect(function(dt)
            if Flags.SmartFarm then 
                pcall(function()
                    require(Managers.ClientFollowManager):Update(dt)
                    require(Managers.ClientCircleEftManager):Update(dt)
                end)
            end
        end)
        ANUI:Notify({Title = "System", Content = "Combat Modules Hooked", Icon = "zap", Duration = 3})
    end)
end)

-- AntiPopup
task.spawn(function()
    local pg = player:WaitForChild("PlayerGui", 10)
    if pg then
        pg.DescendantAdded:Connect(function(d)
             if Flags.AntiPopup and d:IsA("TextLabel") and string.find(string.lower(d.Text), "insufficient") then
                 if d.Parent then d.Parent.Visible = false end
             end
        end)
    end
end)

ANUI:Notify({Title = "Nebublox", Content = "Anime Capture Loaded!", Icon = "check", Duration = 5})

-- Store Instance for Cleanup
_G.NebubloxCapture = { Window = Window }

-- // POST-INIT: UI CUSTOMIZATION //
task.spawn(function()
    task.wait(1) -- Wait for UI animation
    local gui = game:GetService("CoreGui"):FindFirstChild(ScriptTitle) or game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild(ScriptTitle) or game:GetService("CoreGui"):FindFirstChild("NebubloxCapture")
    
    if gui then
        -- 1. Force Square Avatar
        for _, v in ipairs(gui:GetDescendants()) do
            if v:IsA("ImageLabel") and (v.Name == "Avatar" or v.Name == "Icon") then
                -- Check if it's likely the profile avatar (usually larger)
                if v.Size.X.Offset > 30 then 
                    local corner = v:FindFirstChildOfClass("UICorner")
                    if corner then 
                        corner.CornerRadius = UDim.new(0, 0) -- Make Square
                    end
                end
            end
        end
    end
end)