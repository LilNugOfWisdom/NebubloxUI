-- // NEBUBLOX | ANIME CAPTURE //
-- // UI Library: ANUI //

local ANUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/ANHub-Script/ANUI/refs/heads/main/dist/main.lua"))()

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
    Title = "Nebublox", 
    Author = "by He Who Remains Lil'Nug",
    Folder = "NebubloxCapture",
    Icon = "rbxassetid://121698194718505",
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
    Title = "Refresh Enemies",
    Callback = function()
        local validEnemies = {}
        local seen = {}
        
        -- SCANNING LOGIC UPDATED
        -- 1. Map Islands: workspace.common.Up[i].NPC
        if workspace:FindFirstChild("common") and workspace.common:FindFirstChild("Up") then
            for i = 1, 7 do
                local island = workspace.common.Up:FindFirstChild(tostring(i))
                local npcFolder = island and island:FindFirstChild("NPC")
                if npcFolder then
                    for _, mob in ipairs(npcFolder:GetDescendants()) do
                        if mob:IsA("Model") and mob:FindFirstChild("Humanoid") then
                            if not seen[mob.Name] then
                                table.insert(validEnemies, {Title = mob.Name, Icon = "swords"})
                                seen[mob.Name] = true
                            end
                        end
                    end
                end
            end
        end
        
        -- 2. World Boss: workspace.enemy.worldboss
        if workspace:FindFirstChild("enemy") and workspace.enemy:FindFirstChild("worldboss") then
             for _, mob in ipairs(workspace.enemy.worldboss:GetDescendants()) do
                if mob:IsA("Model") and mob:FindFirstChild("Humanoid") then
                    if not seen[mob.Name] then
                        table.insert(validEnemies, {Title = mob.Name, Icon = "alert-circle"}) -- Diff icon for boss
                        seen[mob.Name] = true
                    end
                end
            end
        end
        
        table.sort(validEnemies, function(a, b) return a.Title < b.Title end)
        if CaptureDropdown and CaptureDropdown.SetValues then CaptureDropdown:SetValues(validEnemies) end
        ANUI:Notify({Title = "Farming", Content = "Found " .. #validEnemies .. " enemies!", Icon = "refresh-cw", Duration = 2})
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
    ["601"] = "Event Star",
    -- Add more as known: ["202"] = "Flame Fruit", etc.
}

-- Auto-Detect Names from Workspace
if workspace:FindFirstChild("common") and workspace.common:FindFirstChild("OtherLotto") then
    for _, lotto in ipairs(workspace.common.OtherLotto:GetChildren()) do
        local id = lotto.Name
        if not GachaNames[id] then
            -- Try to find a readable name inside the model (e.g. SurfaceGui or Part Name)
            -- For now, default to "Machine [ID]"
            GachaNames[id] = "Machine " .. id
        end
    end
end

-- Generate Dropdown Values
local GachaList = {}
-- Ensure known IDs are in the list
local KnownIDs = {
    "201", "202", "203", "204", "205", "206", "207", 
    "208", "209", "210", "212", "213", "221", "222", "223", "224", "601"
}

for _, id in ipairs(KnownIDs) do
    local name = GachaNames[id] or ("Machine " .. id)
    table.insert(GachaList, {Title = name .. " (" .. id .. ")", Val = id})
end

GachaSection:Dropdown({
    Title = "Select Gacha Machine",
    Multi = false,
    Required = true,
    Values = GachaList,
    Callback = function(val) 
        -- Dropdown returns the Value property if set, or we handle table
        for k, v in pairs(val) do
            -- If using simple values:
            if type(k) == "number" then Flags.SelectedGachaId = v 
            else Flags.SelectedGachaId = k end -- ANUI sometimes returns Key=Bool
        end
        -- Fallback for single value return
        if type(val) == "string" then Flags.SelectedGachaId = val end
        
        -- Extract ID if value is "Name (ID)" format (just in case)
        if Flags.SelectedGachaId and string.find(Flags.SelectedGachaId, "%(") then
            Flags.SelectedGachaId = string.match(Flags.SelectedGachaId, "%((%d+)%)")
        end
    end
})

GachaSection:Toggle({
    Title = "Auto Roll Selected",
    Desc = "Spams roll on selected ID",
    Value = false,
    Callback = function(state) Flags.AutoRollSelected = state end
})


local EventSection = GachaTab:Section({ Title = "Events", Icon = "star", Opened = true })

EventSection:Toggle({
    Title = "Auto Collect & Spin Event Star",
    Desc = "Rolls the Limited Event Gacha (ID 601)",
    Value = false,
    Callback = function(state) Flags.AutoEventGacha = state end
})

-- [TAB 4: AUTOMATION]
local AutoTab = Window:Tab({ Title = "Automation", Icon = "cpu", SidebarProfile = false })
local MiscSection = AutoTab:Section({ Title = "Misc", Icon = "settings", Opened = true })

MiscSection:Toggle({
    Title = "Auto Capture (E)",
    Desc = "Spams Capture Interaction",
    Value = false,
    Callback = function(state) Flags.AutoCapture = state end
})

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

MiscSection:Toggle({
    Title = "Auto Collect Event Items",
    Desc = "Claims Online Time Rewards (1-12)",
    Value = false,
    Callback = function(state) Flags.AutoEventCollect = state end
})

MiscSection:Toggle({
    Title = "Hide Error Popups",
    Desc = "Hides 'Insufficient quantity' etc.",
    Value = true,
    Callback = function(state) Flags.AntiPopup = state end
})

-- [TAB 5: WORLDS]
local WorldTab = Window:Tab({ Title = "Worlds", Icon = "globe", SidebarProfile = false })
local TeleportSection = WorldTab:Section({ Title = "Teleports", Icon = "map-pin", Opened = true })

-- Using workspace.common.Up[i] (Islands) as destination + Portals as backup
local Islands = {
    {Name = "Seaside Town",        Id = "1"},
    {Name = "Pirate Village",      Id = "2"},
    {Name = "Ninja Village",       Id = "3"},
    {Name = "Shirayuki Village",   Id = "4"},
    {Name = "Cursed Arts Hamlet",  Id = "5"},
    {Name = "Arcane City Lofts",   Id = "6"},
    {Name = "Lookout",             Id = "7"},
    -- Duck Research Center not in 1-7 list, keeping generic fallback
}

for _, island in ipairs(Islands) do
    TeleportSection:Button({
        Title = island.Name,
        Callback = function()
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root and workspace:FindFirstChild("common") and workspace.common:FindFirstChild("Up") then
                local dest = workspace.common.Up:FindFirstChild(island.Id)
                local targetCFrame = nil
                
                if dest then
                    -- Safety check: Determine if it's a Model/Part or Folder
                    if dest:IsA("Model") or dest:IsA("BasePart") then
                        targetCFrame = dest:GetPivot()
                    else
                        -- It's a Folder (likely), find first part
                        local part = dest:FindFirstChildWhichIsA("BasePart", true)
                        if part then targetCFrame = part.CFrame end
                    end
                end
                
                if targetCFrame then
                    root.CFrame = targetCFrame + Vector3.new(0, 5, 0)
                    ANUI:Notify({Title = "Teleport", Content = "Warped to " .. island.Name, Icon = "map-pin", Duration = 2})
                else
                     -- Portal Fallback (0-Index based)
                     local pIdx = tonumber(island.Id) - 1
                     pcall(function() ReplicatedStorage.Events.Map.PortalEvent:FireServer(pIdx) end)
                     ANUI:Notify({Title = "Teleport", Content = "Used portal for " .. island.Name, Icon = "map-pin", Duration = 2})
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

    -- 1. Scan Islands
    if workspace:FindFirstChild("common") and workspace.common:FindFirstChild("Up") then
        for i = 1, 7 do
            local island = workspace.common.Up:FindFirstChild(tostring(i))
            if island then ScanFolder(island:FindFirstChild("NPC")) end
        end
    end
    
    -- 2. Scan World Boss
    if workspace:FindFirstChild("enemy") then ScanFolder(workspace.enemy:FindFirstChild("worldboss")) end
    
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
        -- AUTO SPIN (Collect + Spin)
        if Flags.AutoSpin then
            pcall(function()
                 local TT = ReplicatedStorage.Events.Turntable
                 -- Claim all 7 slots first
                 for i = 1, 7 do TT.ChangeData:FireServer(i, "Claimed") end
                 -- Then Spin
                 TT:FindFirstChild("[C-S]GetRandom"):InvokeServer()
            end)
        end

        -- AUTO GACHA (General)
        if Flags.AutoRollSelected and Flags.SelectedGachaId then
            pcall(function()
                ReplicatedStorage.Events.NewLotto.RollOne:FireServer({16, tonumber(Flags.SelectedGachaId), 1})
            end)
        end
        
        -- AUTO EVENT GACHA (Specific)
        if Flags.AutoEventGacha then
            pcall(function()
                ReplicatedStorage.Events.NewLotto.RollOne:FireServer({16, 601, 1})
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