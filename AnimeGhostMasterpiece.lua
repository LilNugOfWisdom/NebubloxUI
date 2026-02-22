--[[
    ╔═══════════════════════════════════════════════╗
    ║     NEBUBLOX : ANIME GHOST  ★ MASTERPIECE     ║
    ║  Complete Port from WindUI → Nebublox Engine   ║
    ╚═══════════════════════════════════════════════╝
]]

local Configuration = {
    ApiUrl = "https://darkmatterv1.onrender.com/api/verify_key",
    SettingsFile = "nebublox_key.data",
    Discord = "https://discord.gg/nebublox",
    LanyardKey = "3b8e9dcde3778edb11fdd6c421a4bf5f",
    DiscordID = "113456789012345678" -- Change this to YOUR Discord ID
}

print("/// NEBUBLOX ANIME GHOST MASTERPIECE - " .. os.date("%X") .. " ///")

-- ═══════════════════════════════════════
--  PREVIOUS INSTANCE KILLER
-- ═══════════════════════════════════════
local SessionID = tostring(math.random(1, 1000000)) .. tostring(tick())
getgenv().NebuBlox_SessionID = SessionID
getgenv().AutoAttack = false
getgenv().AutoAscension = false
getgenv().SmoothFarm = true

pcall(function()
    for _, v in pairs(game:GetService("CoreGui"):GetChildren()) do 
        if v.Name == "WindUI" or v.Name == "Nebublox" or v.Name == "NebubloxWatermark" then v:Destroy() end 
    end
    for _, v in pairs(game:GetService("Players").LocalPlayer.PlayerGui:GetChildren()) do 
        if v.Name == "WindUI" or v.Name == "Nebublox" or v.Name == "NebubloxWatermark" then v:Destroy() end 
    end
end)

if getgenv().NebuBlox_MovementConnection then getgenv().NebuBlox_MovementConnection:Disconnect() end
if getgenv().NebuBlox_NoClipConnection then getgenv().NebuBlox_NoClipConnection:Disconnect() end
if getgenv().NebuBlox_RenderSteppedConnection then getgenv().NebuBlox_RenderSteppedConnection:Disconnect() end
if getgenv().AntiAfkConnection then getgenv().AntiAfkConnection:Disconnect(); getgenv().AntiAfkConnection = nil end
if getgenv().NebuBlox_ScannerHighlight then pcall(function() getgenv().NebuBlox_ScannerHighlight:Destroy() end) end
if getgenv().NebuBlox_Platform then pcall(function() getgenv().NebuBlox_Platform:Destroy() end) end

-- ═══════════════════════════════════════
--  SERVICES
-- ═══════════════════════════════════════
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local RequestFunc = request or http_request or (syn and syn.request) or (fluxus and fluxus.request) or nil

-- ═══════════════════════════════════════
--  UTILITY TRACKING SYSTEM
-- ═══════════════════════════════════════
local UtilityConnections = {}
local UtilityInstances = {}

local function trackConnection(connection)
    table.insert(UtilityConnections, connection)
    return connection
end

local function trackInstance(instance)
    table.insert(UtilityInstances, instance)
    return instance
end

local function unloadUtility()
    getgenv().Nebublox_Running = false
    -- Disconnect all tracked loops and events
    for _, connection in ipairs(UtilityConnections) do
        if connection.Connected then pcall(function() connection:Disconnect() end) end
    end
    -- Destroy all tracked instances
    for _, instance in ipairs(UtilityInstances) do
        if instance and instance.Parent then pcall(function() instance:Destroy() end) end
    end
    -- Legacy cleanups
    if getgenv().CurrentHighlight then pcall(function() getgenv().CurrentHighlight:Destroy() end) end
    if getgenv().NebuBlox_Platform then pcall(function() getgenv().NebuBlox_Platform:Destroy() end) end
    
    -- Window cleaning handled by NebubloxUI internally usually, but we call it here too
    if getgenv().Nebublox_MainWindow then pcall(function() getgenv().Nebublox_MainWindow:Destroy() end) end
    
    table.clear(UtilityConnections)
    table.clear(UtilityInstances)
    print("Nebublox: Utility successfully unloaded.")
end

-- ═══════════════════════════════════════
--  GAME FRAMEWORK LOADER
-- ═══════════════════════════════════════
local GameLibrary = nil
pcall(function() GameLibrary = require(ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Library")) end)

getgenv().Nebu_EnemyData = {}
pcall(function()
    local edModule = ReplicatedStorage:FindFirstChild("Framework") and ReplicatedStorage.Framework:FindFirstChild("Modules") and ReplicatedStorage.Framework.Modules:FindFirstChild("Data") and ReplicatedStorage.Framework.Modules.Data:FindFirstChild("EnemyData")
    if edModule then
        for id, info in pairs(require(edModule)) do
            getgenv().Nebu_EnemyData[id] = info.Name or id
        end
    end
end)

-- ═══════════════════════════════════════
--  TARGETING SYSTEM CORE (FULL PORT)
-- ═══════════════════════════════════════
getgenv().Nebu_TargetSettings = { ScanRange = 1000, AttackDist = 5, TickRate = 0.1 }
local TargetState = { CurrentTarget = nil, IsAttacking = false }

local function IsEnemyAlive(mob)
    if mob:GetAttribute("Dead") or mob:GetAttribute("Shield") then return false end
    local billboard = mob:FindFirstChild("EnemyBillboard")
    if billboard and billboard:FindFirstChild("Amount") and billboard.Amount:IsA("TextLabel") then
        local hpMatch = string.match(billboard.Amount.Text, "^%s*([%d%.]+[kKmMbBtTqQ]?)") or string.match(billboard.Amount.Text, "(%d+)")
        if hpMatch and tostring(hpMatch) ~= "0" then return true end
        return false
    end
    local hum = mob:FindFirstChild("Humanoid")
    if hum and hum:IsA("Humanoid") and hum.Health > 0 then return true end
    return false
end

local function GetRealEnemyName(model)
    local ed = getgenv().Nebu_EnemyData
    if ed and ed[model.Name] then return ed[model.Name] end
    local billboard = model:FindFirstChild("EnemyBillboard")
    if billboard and billboard:FindFirstChild("Title") and billboard.Title:IsA("TextLabel") then
        local rawName = billboard.Title.Text:gsub("<[^>]+>", "")
        if rawName ~= "" then return rawName end
    end
    local hum = model:FindFirstChild("Humanoid")
    if hum and hum:IsA("Humanoid") and hum.DisplayName ~= "" then return hum.DisplayName:gsub("%s*%[.*%]", "") end
    return model.Name
end

local function ScanFolder(folder, myRoot, bestTarget, shortestDist)
    for _, mob in ipairs(folder:GetChildren()) do
        if mob:IsA("Model") and mob ~= player.Character then
            local rootPart = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("EnemyHitbox") or mob.PrimaryPart
            if rootPart and IsEnemyAlive(mob) then
                local realName = GetRealEnemyName(mob)
                local isSelected = false
                local selection = getgenv().SelectedEnemy
                if not selection or (typeof(selection) == "string" and selection == "All") then isSelected = true
                elseif typeof(selection) == "table" then
                    if #selection == 0 or table.find(selection, "All") then isSelected = true
                    else for _, sel in ipairs(selection) do if string.find(realName, sel) or string.find(mob.Name, sel) then isSelected = true; break end end end
                elseif typeof(selection) == "string" then isSelected = string.find(realName, selection) or string.find(mob.Name, selection) end
                if isSelected then
                    local dist = (rootPart.Position - myRoot.Position).Magnitude
                    if dist < shortestDist then shortestDist = dist; bestTarget = mob end
                end
            end
        end
    end
    return bestTarget, shortestDist
end

local function GetSmartTarget()
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local bestTarget, shortestDist = nil, getgenv().Nebu_TargetSettings.ScanRange
    local enemiesFolder = Workspace:FindFirstChild("_ENEMIES")
    if enemiesFolder then
        bestTarget, shortestDist = ScanFolder(enemiesFolder, myRoot, bestTarget, shortestDist)
        for _, sub in ipairs(enemiesFolder:GetChildren()) do
            if sub:IsA("Folder") or sub:IsA("Model") then bestTarget, shortestDist = ScanFolder(sub, myRoot, bestTarget, shortestDist) end
        end
    end
    for _, fname in ipairs({"Mobs", "Enemies"}) do
        local f = Workspace:FindFirstChild(fname)
        if f then bestTarget, shortestDist = ScanFolder(f, myRoot, bestTarget, shortestDist) end
    end
    return bestTarget
end

-- Background Scanner
task.spawn(function()
    while task.wait(0.05) do
        if getgenv().NebuBlox_SessionID ~= SessionID then break end
        if getgenv().AutoAttack then 
            TargetState.CurrentTarget = GetSmartTarget() 
        else 
            TargetState.CurrentTarget = nil 
        end
    end
end)

-- Movement + NoClip + Platform
local platform = Instance.new("Part"); platform.Name = "NebuFarmPlatform"; platform.Size = Vector3.new(5, 1, 5); platform.Anchored = true; platform.Transparency = 1; platform.CanCollide = true; platform.Parent = workspace
getgenv().NebuBlox_Platform = platform
getgenv().NebuBlox_NoClipConnection = trackConnection(RunService.Stepped:Connect(function() if getgenv().AutoAttack and player.Character then for _, part in ipairs(player.Character:GetDescendants()) do if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end end end end))
getgenv().NebuBlox_MovementConnection = trackConnection(RunService.Stepped:Connect(function()
    if not getgenv().AutoAttack then platform.Position = Vector3.new(0, 99999, 0); return end
    local char = player.Character; local root = char and char:FindFirstChild("HumanoidRootPart"); local target = TargetState.CurrentTarget
    if root and target and target.Parent then
        local tRoot = target:FindFirstChild("EnemyHitbox") or target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
        if tRoot then root.CFrame = tRoot.CFrame * CFrame.new(0, -2, 5); platform.CFrame = CFrame.new(root.Position.X, root.Position.Y - 3, root.Position.Z); root.AssemblyLinearVelocity = Vector3.zero; root.AssemblyAngularVelocity = Vector3.zero
        else platform.Position = Vector3.new(0, 99999, 0) end
    else platform.Position = Vector3.new(0, 99999, 0) end
end))

-- Attack Loop
task.spawn(function()
    while task.wait(0.05) do
        if getgenv().NebuBlox_SessionID ~= SessionID then break end
        if getgenv().AutoAttack and TargetState.CurrentTarget and TargetState.CurrentTarget.Parent then
            pcall(function()
                if GameLibrary and GameLibrary.Remote then
                    GameLibrary.Remote:Fire("ClickSystem", "Execute", TargetState.CurrentTarget.Name)
                end
                if player.Character then
                    local tool = player.Character:FindFirstChildWhichIsA("Tool")
                    if tool then tool:Activate() end
                end
                VirtualUser:CaptureController()
                VirtualUser:ClickButton1(Vector2.new(999, 999))
            end)
        end
    end
end)

-- ═══════════════════════════════════════
--  GAME FUNCTIONS
-- ═══════════════════════════════════════
local function ClaimAchievements() pcall(function() if GameLibrary and GameLibrary.Remote then for _, achType in ipairs({"ProClicker","TheKiller","Vicious","ScrollMaster","ShinyBooster","RadiantBooster"}) do for tier = 1, 5 do GameLibrary.Remote:Fire("AchievementSystem","Claim",achType..tostring(tier)); task.wait(0.1) end end end end) end
local function ClaimChests() pcall(function() if GameLibrary and GameLibrary.Remote then GameLibrary.Remote:Fire("ChestSystem","Claim","Group Chest"); GameLibrary.Remote:Fire("ChestSystem","Claim","Premium Chest"); GameLibrary.Remote:Fire("ChestSystem","Claim","VIP Chest") end end) end
local function HatchScroll(name, amount) pcall(function() if GameLibrary and GameLibrary.Remote then GameLibrary.Remote:Fire("PetSystem","Open",name,(amount and amount > 1) and "All" or "One") end end) end
local function SpinGacha(t, b) pcall(function() if GameLibrary and GameLibrary.Remote then GameLibrary.Remote:Fire("GachaSystem","Spin",t or "Enchantments",b or "Normal",{}) end end) end
local function ClaimQuests() pcall(function() if GameLibrary and GameLibrary.Remote then GameLibrary.Remote:Fire("QuestSystem","ClaimReward","Main"); GameLibrary.Remote:Fire("QuestSystem","ClaimReward","Side") end end) end

local function get_hwid() local hwid = "Unknown"; pcall(function() hwid = gethwid() or game:GetService("RbxAnalyticsService"):GetClientId() end); return hwid end
local function ValidateKey(key)
    if not key or key:match("^%s*$") then return false, "Empty Key" end
    key = key:gsub("%s+", "")
    local my_hwid = get_hwid()
    local requestUrl = string.format("%s?key=%s&hwid=%s&roblox_id=%s&game=%s", Configuration.ApiUrl, HttpService:UrlEncode(key), HttpService:UrlEncode(my_hwid), HttpService:UrlEncode(tostring(player.UserId)), HttpService:UrlEncode(tostring(game.PlaceId)))
    if RequestFunc then
        local s, r = pcall(function() return RequestFunc({Url=requestUrl,Method="GET",Headers={["User-Agent"]="DarkMatter/1.0",["Content-Type"]="application/json"}}) end)
        if s and r and r.StatusCode == 200 then local js, d = pcall(function() return HttpService:JSONDecode(r.Body or r.Content) end); if js and d then return d.valid, d end end
    end
    return false, "Validation Failed"
end

local function GetLanyardStatus()
    local id = Configuration.DiscordID or "113456789012345678"
    local url = "https://api.lanyard.rest/v1/users/" .. id
    if RequestFunc then
        local s, r = pcall(function() return RequestFunc({Url=url, Method="GET"}) end)
        if s and r and r.StatusCode == 200 then
            local js, d = pcall(function() return HttpService:JSONDecode(r.Body or r.Content) end)
            if js and d and d.success then
                local data = d.data
                local status = data.discord_status or "offline"
                local activity = ""
                if data.activities and #data.activities > 0 then
                    for _, act in ipairs(data.activities) do
                        if act.type == 0 then -- Playing
                            activity = "Playing " .. act.name
                            break
                        elseif act.type == 2 then -- Listening
                            activity = "Listening to " .. act.details
                            break
                        elseif act.type == 4 then -- Custom Status
                            activity = act.state or ""
                            break
                        end
                    end
                end
                
                local statusMap = {online = "🟢 Online", idle = "🟡 Idle", dnd = "🔴 DND", offline = "⚫ Offline"}
                return (statusMap[status] or "⚫ Offline") .. (activity ~= "" and (" | " .. activity) or "")
            end
        end
    end
    return "⚫ Offline"
end

-- Session Stats
local SessionStats = {StartTime = tick()}
local StartingYen, StartingCrystals = 0, 0
task.spawn(function() repeat task.wait(1) until GameLibrary and GameLibrary.PlayerData; local d = GameLibrary.PlayerData; StartingYen = d.Currency and d.Currency.Yen or 0; StartingCrystals = d.Currency and d.Currency.Crystals or 0 end)
local function GetSessionStats()
    if not GameLibrary or not GameLibrary.PlayerData then return "0/hr", "0/hr" end
    local d = GameLibrary.PlayerData; local elapsed = (tick() - SessionStats.StartTime) / 3600; if elapsed < 0.001 then elapsed = 0.001 end
    local yR = math.floor(((d.Currency and d.Currency.Yen or 0) - StartingYen) / elapsed)
    local cR = math.floor(((d.Currency and d.Currency.Crystals or 0) - StartingCrystals) / elapsed)
    local function fmt(n) if n >= 1e9 then return string.format("%.2fB",n/1e9) elseif n >= 1e6 then return string.format("%.2fM",n/1e6) elseif n >= 1e3 then return string.format("%.1fK",n/1e3) end; return tostring(n) end
    return fmt(yR).."/hr", fmt(cR).."/hr"
end

-- ═══════════════════════════════════════
--  LOAD NEBUBLOX UI LIBRARY
-- ═══════════════════════════════════════
local rawCode = game:HttpGet("https://raw.githubusercontent.com/LilNugOfWisdom/NebubloxUI/main/NebubloxUI.lua?cache=" .. math.random(1, 999999))
print("[NEBUBLOX] Fetched " .. #rawCode .. " bytes (Fresh)")
local loader, loadErr = loadstring(rawCode)
if not loader then
    warn("NEBUBLOX LOADSTRING SYNTAX ERROR: " .. tostring(loadErr))
    warn("First 200 chars: " .. rawCode:sub(1, 200))
    return
end
local success, Nebublox = pcall(loader)
if not success then warn("NEBUBLOX RUNTIME ERROR: " .. tostring(Nebublox)); return end
Nebublox:IgniteKillSwitch()
getgenv().Nebublox_Running = true

-- ═══════════════════════════════════════
--  CREATE WINDOW
-- ═══════════════════════════════════════
local Window = Nebublox:MakeWindow({
    Title = "NEBUBLOX",
    Subtitle = "ANIME GHOST",
    Profile = {
        Title = player.DisplayName,
        Desc = "Ready  ●  " .. math.random(30, 80) .. "ms",
        Avatar = "rbxthumb://type=AvatarHeadShot&id="..player.UserId.."&w=420&h=420",
        Status = true,
        DiscordId = Configuration.DiscordID,
        LanyardKey = Configuration.LanyardKey
    },
    Size = UDim2.new(0, 680, 0, 480),
    CyberBackground = true
})
getgenv().Nebublox_MainWindow = Window

-- Watermark HUD
Nebublox:MakeWatermark({Text = "Nebublox : Anime Ghost"})

-- ═══════════════════════════════════════
--  TAB 1: HOME
-- ═══════════════════════════════════════
local HomeTab = Window:MakeTab({Name = "🏠", Icon = ""})

local InfoCard = HomeTab:MakeSection({Name = "Information"})
local InfoTabs = InfoCard:AddSubTabs({Tabs = {"About", "Changelog", "Credits"}})
local AboutTab, ChangeTab, CredTab = InfoTabs[1], InfoTabs[2], InfoTabs[3]

AboutTab:AddLabel({Text = "WELCOME TO NEBUBLOX"})
AboutTab:AddLabel({Text = "Good Afternoon, " .. player.DisplayName .. "!"})
local statusRow = AboutTab:AddRow({Columns = 2})
statusRow[1]:AddParagraph({Title = "Status Check", Content = "Status: Connected\nJobID: " .. game.JobId .. "\nDate: " .. os.date("%x")})
statusRow[2]:AddButton({Name = "Copy JobID", Icon = "star", Callback = function() setclipboard(game.JobId); Window:Notify({Title="Copied", Content="JobID copied to clipboard!"}) end})

ChangeTab:AddParagraph({Title = "Recent Updates", Content = "- Overhauled NebubloxUI Layout\n- Improved Engine Stability\n- Rebuilt Settings Tab"})

local DevPara = CredTab:AddParagraph({Title = "LilNugget", Content = "Nebublox Founder\nFetching status..."})
CredTab:AddDualButton(
    {Name = "Update Info", Icon = "info", Color = Color3.fromRGB(0, 255, 255), Callback = function() Window:Notify({Title="Info", Content="Version 1.1 Active"}) end},
    {Name = "Discord", Icon = "star", Color = Color3.fromRGB(138, 43, 226), Callback = function() setclipboard(Configuration.Discord); Window:Notify({Title="Discord", Content="Link Copied!", Type="success"}) end}
)

-- Start Lanyard Loop
task.spawn(function()
    while task.wait(30) do
        if not getgenv().Nebublox_Running then break end
        pcall(function()
            local status = GetLanyardStatus()
            DevPara:Set("Nebublox Founder\nStatus: " .. status)
        end)
    end
end)
-- Initial fetch
task.spawn(function() pcall(function() DevPara:Set("Nebublox Founder\nStatus: " .. GetLanyardStatus()) end) end)

local statsRow = HomeTab:AddRow({Columns = 2})
local AccountCard = statsRow[1]:MakeSection({Name = "Account Information"})
AccountCard:AddParagraph({Title = "User Details", Content = "User ID: " .. player.UserId .. "\nAccount Age: " .. player.AccountAge .. " days"})

local StatCard = statsRow[2]:MakeSection({Name = "Session Statistics"})
local StatLabel = StatCard:AddParagraph({Title = "Session Analytics", Content = "Tracking..."})
task.spawn(function() 
    while task.wait(3) do 
        if not getgenv().Nebublox_Running then break end
        pcall(function() 
            local yH, cH = GetSessionStats() 
            StatLabel:Set("💸 " .. yH .. "  |  💎 " .. cH .. "  |  ⏱ " .. math.floor(tick()-SessionStats.StartTime) .. "s") 
        end) 
    end 
end)

if not getgenv().NebubloxKeyValid then
    local KeySec = HomeTab:MakeSection({Name = "Authentication"})
    local KeyInputString = ""
    local authRow = KeySec:AddRow({Columns = 2})
    
    local entryRow = authRow[1]:AddRow({Columns = 2})
    entryRow[1]:AddLabel({Text = "🌌 Galaxy Key"})
    entryRow[2]:AddTextbox({Name = "", Placeholder = "Enter Key...", Callback = function(t) KeyInputString = t end})
    
    authRow[2]:AddButton({Name = "Verify 🌌", Color = Color3.fromRGB(0, 255, 255), Callback = function()
        local trimmedKey = KeyInputString:gsub("^%s*(.-)%s*$", "%1")
        if trimmedKey == "" then Window:Notify({Title = "Error", Content = "Enter a key!", Type = "error"}); return end
        Window:Notify({Title = "Verifying...", Content = "Checking server...", Type = "info"})
        local isValid, data = ValidateKey(trimmedKey)
        if isValid then
            Window:Notify({Title = "Success", Content = "Access Granted! 🌌", Type = "success"}); getgenv().NebubloxKeyValid = true
            if writefile then writefile(Configuration.SettingsFile, trimmedKey) end
        else
            Window:Notify({Title = "Failed", Content = (type(data) == "table" and data.message) or "Invalid Key", Type = "error"})
        end
    end})
end

-- ═══════════════════════════════════════
--  TAB 2: COMBAT
-- ═══════════════════════════════════════
local CombatTab = Window:MakeTab({Name = "⚔️", Icon = ""})
local CombatSec = CombatTab:MakeSection({Name = "Target System"})

local combRow = CombatSec:AddRow({Columns = 2})
getgenv().SelectedEnemy = {"All"}
getgenv().SelectedEnemyDropdown = combRow[1]:AddMultiDropdown({
    Name = "Select Enemy",
    Options = {"All"},
    Default = {"All"},
    Callback = function(v) getgenv().SelectedEnemy = v end
})

combRow[2]:AddButton({Name = "Refresh 🔄", Color = Color3.fromRGB(0, 255, 255), Callback = function()
    local mobs = {"All"}
    pcall(function()
        local enemiesFolder = Workspace:FindFirstChild("_ENEMIES") and Workspace._ENEMIES:FindFirstChild("Client")
        if enemiesFolder then
            for _, mob in ipairs(enemiesFolder:GetChildren()) do
                if mob:IsA("Model") and not table.find(mobs, mob.Name) then
                    table.insert(mobs, mob.Name)
                end
            end
        end
    end)
    pcall(function() if getgenv().SelectedEnemyDropdown and getgenv().SelectedEnemyDropdown.Refresh then getgenv().SelectedEnemyDropdown:Refresh(mobs, {"All"}) end end)
    Window:Notify({Title = "Combat", Content = "Found " .. (#mobs-1) .. " enemy types!", Type = "success"})
end})

-- Auto-refresh on load
task.spawn(function() task.wait(3); pcall(function()
    local mobs = {"All"}
    local enemiesFolder = Workspace:FindFirstChild("_ENEMIES") and Workspace._ENEMIES:FindFirstChild("Client")
    if enemiesFolder then
        for _, mob in ipairs(enemiesFolder:GetChildren()) do
            if mob:IsA("Model") and not table.find(mobs, mob.Name) then
                table.insert(mobs, mob.Name)
            end
        end
    end
    if #mobs > 1 then pcall(function() if getgenv().SelectedEnemyDropdown and getgenv().SelectedEnemyDropdown.Refresh then getgenv().SelectedEnemyDropdown:Refresh(mobs, {"All"}) end end) end
end) end)

CombatSec:AddToggle({Name = "Auto Attack", Default = false, Callback = function(s) getgenv().AutoAttack = s end})

-- ═══════════════════════════════════════
--  TAB 3: GAMEMODES
-- ═══════════════════════════════════════
local GamemodesTab = Window:MakeTab({Name = "🎮", Icon = ""})

local DungSec = GamemodesTab:MakeSection({Name = "Auto Dungeon"})
getgenv().SelectedDungeon = "Dungeon"
local dungRow = DungSec:AddRow({Columns = 2})
local DungDrop = dungRow[1]:AddDropdown({Name = "Selected", Options = {"Dungeon"}, Default = "Dungeon", Callback = function(v) getgenv().SelectedDungeon = v end})

dungRow[2]:AddButton({Name = "Refresh 🔄", Color = Color3.fromRGB(0, 255, 255), Callback = function()
    local dList = {"Dungeon"}
    pcall(function()
        local portalFolder = Workspace:FindFirstChild("Lobby") and Workspace.Lobby:FindFirstChild("Portals")
        if portalFolder then
            for _, v in ipairs(portalFolder:GetChildren()) do
                if v:FindFirstChild("Dungeon") and not table.find(dList, v.Name) then table.insert(dList, v.Name) end
            end
        end
    end)
    if DungDrop and DungDrop.Refresh then DungDrop:Refresh(dList, dList[1]) end
end})

DungSec:AddButton({Name = "Join Dungeon ⚔️", Icon = "sword", Callback = function() pcall(function() if GameLibrary and GameLibrary.Remote then GameLibrary.Remote:Fire("GamemodeSystem","Create","Dungeon",getgenv().SelectedDungeon,"Hard",false) end end) end})
DungSec:AddTextbox({Name = "Leave at Level", Placeholder = "0 = Disabled", Callback = function(t) getgenv().DungeonLeaveLevel = tonumber(t) or 0 end})

local RaidSec = GamemodesTab:MakeSection({Name = "Auto Raid"})
getgenv().SelectedRaid = "TitanTown"
getgenv().SelectedRaidDiff = "Easy"

local raidRow1 = RaidSec:AddRow({Columns = 2})
local RaidDrop = raidRow1[1]:AddDropdown({Name = "Selected", Options = {"TitanTown"}, Default = "TitanTown", Callback = function(v) getgenv().SelectedRaid = v end})

raidRow1[2]:AddButton({Name = "Refresh 🔄", Color = Color3.fromRGB(0, 255, 255), Callback = function()
    local rList = {"TitanTown"}
    pcall(function()
        local portalFolder = Workspace:FindFirstChild("Lobby") and Workspace.Lobby:FindFirstChild("Portals")
        if portalFolder then
            for _, v in ipairs(portalFolder:GetChildren()) do
                if v:FindFirstChild("Raid") and not table.find(rList, v.Name) then table.insert(rList, v.Name) end
            end
        end
    end)
    if RaidDrop and RaidDrop.Refresh then RaidDrop:Refresh(rList, rList[1]) end
end})

local raidRow2 = RaidSec:AddRow({Columns = 2})
raidRow2[1]:AddDropdown({Name = "Difficulty", Options = {"Easy", "Normal", "Hard"}, Default = "Easy", Callback = function(v) getgenv().SelectedRaidDiff = v end})
raidRow2[2]:AddToggle({Name = "Auto Start", Default = false, Callback = function(s)
    getgenv().AutoStartRaid = s
    task.spawn(function() while getgenv().AutoStartRaid do if not getgenv().Nebublox_Running then break end; pcall(function()
        local Event = game:GetService("ReplicatedStorage"):FindFirstChild("ffrostflame_bridgenet2@1.0.0")
        if Event then Event = Event.dataRemoteEvent end
        if Event then Event:FireServer({{"GamemodeSystem", "Start", "Raid", 8221438525, n = 4}, "\x02"}) end
    end); task.wait(2) end end)
end})
RaidSec:AddButton({Name = "Create Raid", Icon = "sword", Callback = function()
    pcall(function()
        local Event = game:GetService("ReplicatedStorage"):FindFirstChild("ffrostflame_bridgenet2@1.0.0")
        if Event then Event = Event.dataRemoteEvent end
        if Event then Event:FireServer({{"GamemodeSystem", "Create", "Raid", getgenv().SelectedRaid, getgenv().SelectedRaidDiff, false, n = 6}, "\x02"}) end
    end)
end})
RaidSec:AddTextbox({Name = "Leave at Wave", Placeholder = "0 = Disabled", Callback = function(t) getgenv().RaidLeaveWave = tonumber(t) or 0 end})

-- ═══════════════════════════════════════
--  TAB 5: AUTOMATION
-- ═══════════════════════════════════════
local AutoTab = Window:MakeTab({Name = "🤖", Icon = ""})
local AutoSec = AutoTab:MakeSection({Name = "Core Automations"})

AutoSec:AddToggle({Name = "Auto Claim Rewards", Default = false, Callback = function(s) getgenv().AutoClaimQuests = s; task.spawn(function() while getgenv().AutoClaimQuests and task.wait(5) do if not getgenv().Nebublox_Running then break end; ClaimQuests() end end) end})
AutoSec:AddToggle({Name = "Auto Claim Achievements", Default = false, Callback = function(s) getgenv().AutoClaimAchievements = s; task.spawn(function() while getgenv().AutoClaimAchievements and task.wait(60) do if not getgenv().Nebublox_Running then break end; ClaimAchievements() end end) end})
AutoSec:AddToggle({Name = "Auto Collect Chests", Default = false, Callback = function(s) getgenv().AutoCollectChests = s; task.spawn(function() while getgenv().AutoCollectChests and task.wait(600) do if not getgenv().Nebublox_Running then break end; ClaimChests() end end) end})
AutoSec:AddToggle({Name = "Auto Ascension", Default = false, Callback = function(s) getgenv().AutoAscension = s; task.spawn(function() while getgenv().AutoAscension and task.wait(5) do if not getgenv().Nebublox_Running then break end; pcall(function() if GameLibrary and GameLibrary.Remote then GameLibrary.Remote:Fire("RebirthSystem","Ascension","Normal") end end) end end) end})
AutoSec:AddToggle({Name = "Auto Equip Best Weapon", Default = false, Callback = function(s) getgenv().AutoEquipWeapon = s; task.spawn(function() while getgenv().AutoEquipWeapon and task.wait(10) do if not getgenv().Nebublox_Running then break end; pcall(function() if GameLibrary and GameLibrary.Remote then GameLibrary.Remote:Fire("ItemSystem","EquipBest","Weapon") end end) end end) end})
AutoSec:AddToggle({Name = "Auto Equip Best Form", Default = false, Callback = function(s) getgenv().AutoEquipForm = s; task.spawn(function() while getgenv().AutoEquipForm and task.wait(10) do if not getgenv().Nebublox_Running then break end; pcall(function() if GameLibrary and GameLibrary.Remote then GameLibrary.Remote:Fire("ItemSystem","EquipBest","Form") end end) end end) end})

local GachaSec = AutoTab:MakeSection({Name = "Gacha & Scrolls"})
local gRow1 = GachaSec:AddRow({Columns = 2})
local ScrollDrop = gRow1[1]:AddDropdown({Name = "Selected Scroll", Options = {"Titan Scroll","Supernatural Scroll","Spiritual Scroll","Solo Scroll"}, Default = "Solo Scroll", Callback = function(v) getgenv().SelectedScroll = v end})

gRow1[2]:AddButton({Name = "Refresh 🔄", Color = Color3.fromRGB(138, 43, 226), Callback = function()
    local sList = {"Solo Scroll"}
    pcall(function()
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("Model") and v.Name:match("Scroll") and not table.find(sList, v.Name) then
                table.insert(sList, v.Name)
            end
        end
    end)
    if ScrollDrop and ScrollDrop.Refresh then ScrollDrop:Refresh(sList, sList[1]) end
end})

local gRow2 = GachaSec:AddRow({Columns = 2})
local GachaDrop = gRow2[1]:AddDropdown({Name = "Selected Gacha", Options = {"Enchantments","Hunter Ranks","Traits","Titan Serums","Passives","Soul Foundation","Avatars","Weapons"}, Default = "Enchantments", Callback = function(v) getgenv().SelectedGachaType = v end})

gRow2[2]:AddButton({Name = "Refresh 🔄", Color = Color3.fromRGB(0, 255, 255), Callback = function()
    local gList = {"Enchantments"}
    pcall(function()
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("Model") and (v.Name:match("Gacha") or v.Name:match("Roll") or v.Name:match("Spin")) and not table.find(gList, v.Name) then
                table.insert(gList, v.Name)
            end
        end
    end)
    if GachaDrop and GachaDrop.Refresh then GachaDrop:Refresh(gList, gList[1]) end
end})

local gRow3 = GachaSec:AddRow({Columns = 2})
gRow3[1]:AddToggle({Name = "Auto Hatch", Default = false, Callback = function(s)
    getgenv().AutoHatch = s
    task.spawn(function() while getgenv().AutoHatch and task.wait(0.1) do if not getgenv().Nebublox_Running then break end; HatchScroll(getgenv().SelectedScroll, 5); local wt = (GameLibrary and GameLibrary.PlayerData and GameLibrary.PlayerData.Gamepasses and GameLibrary.PlayerData.Gamepasses.FastOpen) and 0.1 or 0.8; task.wait(wt) end end)
end})
gRow3[2]:AddToggle({Name = "Auto Spin", Default = false, Callback = function(s) getgenv().AutoSpinGacha = s; task.spawn(function() while getgenv().AutoSpinGacha and task.wait(1) do if not getgenv().Nebublox_Running then break end; SpinGacha(getgenv().SelectedGachaType, "Normal") end end) end})

local SpeedSec = AutoTab:MakeSection({Name = "Movement Hacks"})
local MovRow1 = SpeedSec:AddRow({Columns = 3})
MovRow1[1]:AddToggle({Name = "Walkspeed", Default = false, Callback = function(s) getgenv().AutoWalkSpeed = s end})
MovRow1[2]:AddToggle({Name = "JumpPower", Default = false, Callback = function(s) getgenv().AutoJumpPower = s end})
MovRow1[3]:AddToggle({Name = "Noclip", Default = false, Callback = function(s) getgenv().Noclip = s end})

local MovRow2 = SpeedSec:AddRow({Columns = 2})
MovRow2[1]:AddSlider({Name = "Speed Value", Min = 16, Max = 500, Increment = 1, Default = 100, Callback = function(v) getgenv().AutoWalkSpeedVal = v end})
MovRow2[2]:AddSlider({Name = "Jump Value", Min = 50, Max = 500, Increment = 1, Default = 100, Callback = function(v) getgenv().AutoJumpPowerVal = v end})

-- Robust Movement Loop
task.spawn(function()
    while task.wait() do
        if not getgenv().Nebublox_Running then break end
        pcall(function()
            local char = player.Character
            local hum = char and char:FindFirstChild("Humanoid")
            if hum then
                if getgenv().AutoWalkSpeed then hum.WalkSpeed = getgenv().AutoWalkSpeedVal or 100 end
                if getgenv().AutoJumpPower then 
                    hum.UseJumpPower = true
                    hum.JumpPower = getgenv().AutoJumpPowerVal or 100 
                end
            end
            
            if getgenv().Noclip and char then
                for _, v in ipairs(char:GetDescendants()) do
                    if v:IsA("BasePart") and v.CanCollide then
                        v.CanCollide = false
                    end
                end
            end
        end)
    end
end)

-- Tab Removed (Shop)

-- ═══════════════════════════════════════
--  TAB 7: TELEPORTS
-- ═══════════════════════════════════════
-- Tab Removed (Merged with Tab 3)

-- ═══════════════════════════════════════
--  TAB 8: SETTINGS
-- ═══════════════════════════════════════
local SettingsTab = Window:MakeTab({Name = "⚙️", Icon = ""})

local UtilSec = SettingsTab:MakeSection({Name = "Utilities"})
local utilRow = UtilSec:AddRow({Columns = 3})

utilRow[1]:AddToggle({Name = "Anti-AFK", Default = false, Callback = function(s)
    if s then
        getgenv().AntiAfkConnection = trackConnection(player.Idled:Connect(function()
            -- Simulates a right-click at the center of the screen
            VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(0.5)
            VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            print("Anti-AFK: Prevented idle disconnect.")
        end))
    else
        if getgenv().AntiAfkConnection then
            getgenv().AntiAfkConnection:Disconnect()
            getgenv().AntiAfkConnection = nil
        end
    end
end})

utilRow[2]:AddButton({Name = "FPS Boost", Icon = "zap", Callback = function()
    task.spawn(function() pcall(function()
        local terrain = Workspace:WaitForChild("Terrain")
        -- Optimize Terrain & Lighting
        terrain.WaterWaveSize = 0
        terrain.WaterWaveSpeed = 0
        terrain.WaterReflectance = 0
        terrain.WaterTransparency = 0
        
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.Brightness = 0 -- Performance Optimizer suggested 0
        
        for _, c in ipairs(Lighting:GetChildren()) do 
            if c:IsA("PostEffect") or c:IsA("BlurEffect") or c:IsA("SunRaysEffect") or c:IsA("ColorCorrectionEffect") or c:IsA("BloomEffect") or c:IsA("DepthOfFieldEffect") or c:IsA("Atmosphere") or c:IsA("Sky") then 
                c:Destroy() 
            end 
        end
        
        -- Strip Textures and Materials
        for _, descendant in ipairs(Workspace:GetDescendants()) do
            if descendant:IsA("BasePart") then
                descendant.Material = Enum.Material.Plastic
                descendant.Reflectance = 0
                descendant.CastShadow = false
            elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
                descendant.Transparency = 1
            elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") or descendant:IsA("Sparkles") or descendant:IsA("Fire") or descendant:IsA("Smoke") then
                descendant.Lifetime = NumberRange.new(0)
            elseif descendant:IsA("MeshPart") then
                descendant.Material = Enum.Material.Plastic
                descendant.TextureID = ""
            elseif descendant:IsA("PostEffect") then
                descendant.Enabled = false
            elseif descendant:IsA("Sound") then
                descendant:Stop(); descendant:Destroy()
            end
        end
        
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        RunService:Set3dRenderingEnabled(false)
        print("FPS Boost applied.")
    end); Window:Notify({Title="Settings", Content="FPS Boost Enabled!", Type="info"}) end)
end})

utilRow[3]:AddButton({Name = "Destroy Script", Icon = "shield", Callback = function()
    unloadUtility()
end})

local utilRow2 = UtilSec:AddRow({Columns = 1})
utilRow2[1]:AddButton({Name = "Unlock FPS 🚀", Icon = "zap", Callback = function()
    if setfpscap then
        setfpscap(999)
        Window:Notify({Title="FPS", Content="FPS Cap removed!", Type="success"})
        print("FPS Cap removed.")
    else
        Window:Notify({Title="Error", Content="Executor does not support setfpscap", Type="error"})
        warn("Your executor does not support the setfpscap function.")
    end
end})

local SetSec = SettingsTab:MakeSection({Name = "Configuration Management"})
local FolderName = "Nebublox"
local ConfigsFolder = FolderName .. "/Configs"
pcall(function() if not isfolder(FolderName) then makefolder(FolderName) end; if not isfolder(ConfigsFolder) then makefolder(ConfigsFolder) end end)

local ConfName = ""
local function GetConfigs() local files = {"None"}; pcall(function() for _, f in ipairs(listfiles(ConfigsFolder)) do if f:match("%.json$") then table.insert(files, f:match("([^/\\]+)%.json$")) end end end); return files end

local confRow1 = SetSec:AddRow({Columns = 2})
local ConfDrop = confRow1[1]:AddDropdown({Name = "Saved Profiles", Options = GetConfigs(), Default = "None", Callback = function(v) if v ~= "None" then ConfName = v end end})
confRow1[2]:AddButton({Name = "Refresh 🔄", Color = Color3.fromRGB(0, 255, 255), Callback = function()
    local files = GetConfigs()
    if ConfDrop and ConfDrop.Refresh then ConfDrop:Refresh(files, files[1]) end
end})

SetSec:AddTextbox({Name = "Profile Name", Placeholder = "Enter config name...", Callback = function(t) ConfName = t end})

local confRow2 = SetSec:AddRow({Columns = 3})
confRow2[1]:AddButton({Name = "Save", Color = Color3.fromRGB(0, 255, 140), Callback = function() if ConfName ~= "" and ConfName ~= "None" then pcall(function() writefile(ConfigsFolder.."/"..ConfName..".json", HttpService:JSONEncode(getgenv().NebubloxSettings or {})) end); Window:Notify({Title="Config",Content="Saved: "..ConfName,Type="success"}) end end})
confRow2[2]:AddButton({Name = "Load", Color = Color3.fromRGB(180, 100, 255), Callback = function() if ConfName ~= "" and ConfName ~= "None" then pcall(function() local p = ConfigsFolder.."/"..ConfName..".json"; if isfile(p) then for k,v in pairs(HttpService:JSONDecode(readfile(p))) do getgenv().NebubloxSettings = getgenv().NebubloxSettings or {}; getgenv().NebubloxSettings[k] = v end end end); Window:Notify({Title="Config",Content="Loaded: "..ConfName,Type="success"}) end end})
confRow2[3]:AddButton({Name = "Delete", Color = Color3.fromRGB(255, 50, 90), Callback = function() if ConfName ~= "" and ConfName ~= "None" then pcall(function() delfile(ConfigsFolder.."/"..ConfName..".json") end); Window:Notify({Title="Config",Content="Deleted: "..ConfName,Type="error"}) end end})

-- ═══════════════════════════════════════
--  FINAL INIT
-- ═══════════════════════════════════════
Window:Notify({Title = "Nebublox : Anime Ghost", Content = "Masterpiece loaded successfully! 🌌", Type = "success", Duration = 5})

-- Hide game Info GUI
pcall(function() for _, gui in ipairs(player.PlayerGui:GetDescendants()) do if gui.Name == "Info" and gui:IsA("ScreenGui") then gui.Enabled = false end; if gui.Name == "Info" and gui:IsA("Frame") then gui.Visible = false end end end)
