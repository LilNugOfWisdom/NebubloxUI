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
getgenv().AutoQuest = false
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
local TargetState = { CurrentTarget = nil, ScannerEnabled = true, Highlight = nil, IsAttacking = false, QuestTargetName = nil, QuestPriority = true }

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
        if not mob:IsA("Model") or mob == player.Character then continue end
        local rootPart = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("EnemyHitbox") or mob.PrimaryPart
        if not rootPart or not IsEnemyAlive(mob) then continue end
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
            local effectiveDist = dist
            if TargetState.QuestPriority and TargetState.QuestTargetName then
                if string.find(mob.Name, TargetState.QuestTargetName) or string.find(realName, TargetState.QuestTargetName) then effectiveDist = dist - 10000 end
            end
            if effectiveDist < shortestDist then shortestDist = effectiveDist; bestTarget = mob end
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
task.spawn(function() while task.wait(0.05) do if getgenv().NebuBlox_SessionID ~= SessionID then break end; if getgenv().AutoAttack then TargetState.CurrentTarget = GetSmartTarget() else TargetState.CurrentTarget = nil end end end)

-- Movement + NoClip + Platform
local platform = Instance.new("Part"); platform.Name = "NebuFarmPlatform"; platform.Size = Vector3.new(5, 1, 5); platform.Anchored = true; platform.Transparency = 1; platform.CanCollide = true; platform.Parent = workspace
getgenv().NebuBlox_Platform = platform
getgenv().NebuBlox_NoClipConnection = RunService.Stepped:Connect(function() if getgenv().AutoAttack and player.Character then for _, part in ipairs(player.Character:GetDescendants()) do if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end end end end)
getgenv().NebuBlox_MovementConnection = RunService.Stepped:Connect(function()
    if not getgenv().AutoAttack then platform.Position = Vector3.new(0, 99999, 0); return end
    local char = player.Character; local root = char and char:FindFirstChild("HumanoidRootPart"); local target = TargetState.CurrentTarget
    if root and target and target.Parent then
        local tRoot = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("EnemyHitbox") or target.PrimaryPart
        if tRoot then root.CFrame = tRoot.CFrame * CFrame.new(0, -2, 5); platform.CFrame = CFrame.new(root.Position.X, root.Position.Y - 3, root.Position.Z); root.AssemblyLinearVelocity = Vector3.zero; root.AssemblyAngularVelocity = Vector3.zero
        else platform.Position = Vector3.new(0, 99999, 0) end
    else platform.Position = Vector3.new(0, 99999, 0) end
end)

-- Attack Loop
task.spawn(function() while task.wait(0.05) do if getgenv().NebuBlox_SessionID ~= SessionID then break end; if getgenv().AutoAttack and TargetState.CurrentTarget and TargetState.CurrentTarget.Parent then pcall(function() if GameLibrary and GameLibrary.Remote then GameLibrary.Remote:Fire("ClickSystem", "Execute", TargetState.CurrentTarget.Name) end; if player.Character then local tool = player.Character:FindFirstChildWhichIsA("Tool"); if tool then tool:Activate() end end; VirtualUser:CaptureController(); VirtualUser:ClickButton1(Vector2.new(999, 999)) end) end end end)

-- ═══════════════════════════════════════
--  GAME FUNCTIONS
-- ═══════════════════════════════════════
local function ClaimAchievements() pcall(function() if GameLibrary and GameLibrary.Remote then for _, achType in ipairs({"ProClicker","TheKiller","Vicious","ScrollMaster","ShinyBooster","RadiantBooster"}) do for tier = 1, 5 do GameLibrary.Remote:Fire("AchievementSystem","Claim",achType..tostring(tier)); task.wait(0.1) end end end end) end
local function ClaimChests() pcall(function() if GameLibrary and GameLibrary.Remote then GameLibrary.Remote:Fire("ChestSystem","Claim","Group Chest"); GameLibrary.Remote:Fire("ChestSystem","Claim","Premium Chest"); GameLibrary.Remote:Fire("ChestSystem","Claim","VIP Chest") end end) end
local function HatchScroll(name, amount) pcall(function() if GameLibrary and GameLibrary.Remote then GameLibrary.Remote:Fire("PetSystem","Open",name,(amount and amount > 1) and "All" or "One") end end) end
local function SpinGacha(t, b) pcall(function() if GameLibrary and GameLibrary.Remote then GameLibrary.Remote:Fire("GachaSystem","Spin",t or "Enchantments",b or "Normal",{}) end end) end
local function ClaimQuests() pcall(function() if GameLibrary and GameLibrary.Remote then GameLibrary.Remote:Fire("QuestSystem","ClaimReward","Main"); GameLibrary.Remote:Fire("QuestSystem","ClaimReward","Side") end; if GameLibrary and GameLibrary.PlayerData then local mq = GameLibrary.PlayerData.Quests and GameLibrary.PlayerData.Quests.Main; if mq and mq.Objectives then for _, obj in pairs(mq.Objectives) do if obj.Type == "DefeatEnemy" and obj.Id ~= "Any" then TargetState.QuestTargetName = obj.Id; break end end end end end) end

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
local rawCode = game:HttpGet("https://raw.githubusercontent.com/LilNugOfWisdom/NebubloxUI/main/NebubloxUI.lua")
print("[NEBUBLOX] Fetched " .. #rawCode .. " bytes")
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
    Title = "NEBUBLOX : ANIME GHOST",
    Subtitle = "by LilNugOfWisdom",
    Profile = {
        Title = player.DisplayName,
        Desc = "@"..player.Name,
        Avatar = "rbxthumb://type=AvatarHeadShot&id="..player.UserId.."&w=420&h=420",
        Status = true
    },
    Size = UDim2.new(0, 680, 0, 480),
    CyberBackground = true
})

-- Watermark HUD
Nebublox:MakeWatermark({Text = "Nebublox : Anime Ghost"})

-- ═══════════════════════════════════════
--  TAB 1: HOME
-- ═══════════════════════════════════════
local HomeTab = Window:MakeTab({Name = "🏠 Home", Icon = ""})

local InfoCard = HomeTab:MakeSection({Name = "Information"})
local InfoTabs = InfoCard:AddSubTabs({Tabs = {"About", "Changelog", "Credits"}})
local AboutTab, ChangeTab, CredTab = InfoTabs[1], InfoTabs[2], InfoTabs[3]

AboutTab:AddLabel({Text = "WELCOME TO NEBUBLOX"})
AboutTab:AddLabel({Text = "Good Afternoon, " .. player.DisplayName .. "!"})
AboutTab:AddParagraph({Title = "Status Check", Content = "Status: Connected\nJobID: " .. game.JobId .. "\nDate: " .. os.date("%x")})
AboutTab:AddButton({Name = "Copy JobID", Icon = "clipboard", Callback = function() setclipboard(game.JobId); Window:Notify({Title="Copied", Content="JobID copied to clipboard!"}) end})

ChangeTab:AddParagraph({Title = "Recent Updates", Content = "- Overhauled NebubloxUI Layout\n- Improved Engine Stability\n- Rebuilt Settings Tab"})

CredTab:AddParagraph({Title = "Developer", Content = player.DisplayName})
CredTab:AddDualButton(
    {Name = "Update Info", Icon = "info", Callback = function() Window:Notify({Title="Info", Content="Version 1.1 Active"}) end},
    {Name = "Discord", Icon = "star", Callback = function() setclipboard(Configuration.Discord); Window:Notify({Title="Discord", Content="Link Copied!", Type="success"}) end}
)

local AccountCard = HomeTab:MakeSection({Name = "Account Information"})
AccountCard:AddParagraph({Title = "User Details", Content = "User ID: " .. player.UserId .. "\nAccount Age: " .. player.AccountAge .. " days"})

local StatCard = HomeTab:MakeSection({Name = "Session Statistics"})
local StatLabel = StatCard:AddParagraph({Title = "Session Analytics", Content = "Tracking..."})
task.spawn(function() while task.wait(3) do if not getgenv().Nebublox_Running then break end; pcall(function() local yH, cH = GetSessionStats(); StatLabel:Set("💸 " .. yH .. "  |  💎 " .. cH .. "  |  ⏱ " .. math.floor(tick()-SessionStats.StartTime) .. "s") end) end end)

if not getgenv().NebubloxKeyValid then
    local KeySec = HomeTab:MakeSection({Name = "Authentication"})
    local KeyInputString = ""
    KeySec:AddTextbox({Name = "Galaxy Key", Placeholder = "Enter Key...", Callback = function(t) KeyInputString = t end})
    KeySec:AddButton({Name = "Verify Key", Icon = "shield", Callback = function()
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
local CombatTab = Window:MakeTab({Name = "⚔️ Combat", Icon = ""})
local CombatSec = CombatTab:MakeSection({Name = "Target System"})

getgenv().SelectedEnemy = {"All"}
getgenv().SelectedEnemyDropdown = CombatSec:AddMultiDropdown({
    Name = "Select Enemy",
    Options = {"All"},
    Default = {"All"},
    Callback = function(v) getgenv().SelectedEnemy = v end
})

CombatSec:AddButton({Name = "Refresh Enemies", Icon = "star", Callback = function()
    local mobs = {"All"}
    for id, displayName in pairs(getgenv().Nebu_EnemyData) do if displayName ~= "" and not table.find(mobs, displayName) then table.insert(mobs, displayName) end end
    pcall(function() if getgenv().SelectedEnemyDropdown and getgenv().SelectedEnemyDropdown.Refresh then getgenv().SelectedEnemyDropdown:Refresh(mobs, {"All"}) end end)
    Window:Notify({Title = "Combat", Content = "Found " .. (#mobs-1) .. " enemy types!", Type = "success"})
end})

-- Auto-refresh on load
task.spawn(function() task.wait(3); pcall(function()
    local mobs = {"All"}; for id, dn in pairs(getgenv().Nebu_EnemyData) do if dn ~= "" and not table.find(mobs, dn) then table.insert(mobs, dn) end end
    if #mobs > 1 then pcall(function() if getgenv().SelectedEnemyDropdown and getgenv().SelectedEnemyDropdown.Refresh then getgenv().SelectedEnemyDropdown:Refresh(mobs, {"All"}) end end) end
end) end)

CombatSec:AddToggle({Name = "Auto Attack", Default = false, Callback = function(s) getgenv().AutoAttack = s end})
CombatSec:AddToggle({Name = "Auto Quest", Default = false, Callback = function(s)
    getgenv().AutoQuest = s
    task.spawn(function() while getgenv().AutoQuest and task.wait(5) do if not getgenv().Nebublox_Running then break end; ClaimQuests() end end)
end})
CombatSec:AddToggle({Name = "Quest Priority", Default = true, Tooltip = "Prioritize quest targets over nearest", Callback = function(s) TargetState.QuestPriority = s end})

local TargetParagraph = CombatSec:AddParagraph({Title = "Scanner: Target Info", Content = "Waiting for engagement..."})
task.spawn(function() while task.wait(0.5) do if not getgenv().Nebublox_Running then break end; pcall(function() if TargetState.CurrentTarget and TargetState.CurrentTarget:FindFirstChild("Humanoid") then local h = TargetState.CurrentTarget.Humanoid; TargetParagraph:Set("🎯 " .. TargetState.CurrentTarget.Name .. " | HP: " .. math.floor(h.Health) .. "/" .. math.floor(h.MaxHealth)) else TargetParagraph:Set("Searching for target...") end end) end end)

-- Highlight Loop
local CurrentHighlight = Instance.new("Highlight"); CurrentHighlight.FillColor = Color3.fromRGB(255, 0, 0); CurrentHighlight.FillTransparency = 0.5; CurrentHighlight.OutlineTransparency = 1; CurrentHighlight.Name = "NebubloxHighlight"
task.spawn(function() while task.wait(0.1) do if not getgenv().Nebublox_Running then CurrentHighlight:Destroy(); break end; if TargetState.CurrentTarget and TargetState.CurrentTarget.Parent then if CurrentHighlight.Parent ~= TargetState.CurrentTarget then CurrentHighlight.Parent = TargetState.CurrentTarget; CurrentHighlight.Enabled = true end else CurrentHighlight.Parent = nil; CurrentHighlight.Enabled = false end end end)

-- ═══════════════════════════════════════
--  TAB 3: GAMEMODES
-- ═══════════════════════════════════════
local GamemodesTab = Window:MakeTab({Name = "🎮 Gamemodes", Icon = ""})

local DungSec = GamemodesTab:MakeSection({Name = "Dungeon Automation"})
DungSec:AddButton({Name = "Auto Join Crystal Cave (Hard)", Icon = "sword", Callback = function() pcall(function() if GameLibrary and GameLibrary.Remote then GameLibrary.Remote:Fire("GamemodeSystem","Create","Dungeon","CrystalCave","Hard") end end) end})
DungSec:AddTextbox({Name = "Leave at Level", Placeholder = "0 = Disabled", Callback = function(t) getgenv().DungeonLeaveLevel = tonumber(t) or 0 end})

local RaidSec = GamemodesTab:MakeSection({Name = "Raid Automation"})
RaidSec:AddToggle({Name = "Auto Start Raid", Default = false, Callback = function(s)
    getgenv().AutoStartRaid = s
    task.spawn(function() while getgenv().AutoStartRaid do if not getgenv().Nebublox_Running then break end; pcall(function()
        local gamemodeUI = player.PlayerGui:FindFirstChild("CenterGUI") and player.PlayerGui.CenterGUI:FindFirstChild("Gamemode")
        if gamemodeUI then local createBtn = gamemodeUI:FindFirstChild("Main") and gamemodeUI.Main:FindFirstChild("Create"); if createBtn and getconnections then for _, conn in ipairs(getconnections(createBtn.MouseButton1Click)) do conn:Fire() end end end
    end); task.wait(2) end end)
end})
RaidSec:AddButton({Name = "Auto Join Raid (World 1)", Icon = "sword", Callback = function() pcall(function() if GameLibrary and GameLibrary.Remote then GameLibrary.Remote:Fire("GamemodeSystem","Create","Raid",1) end end) end})
RaidSec:AddTextbox({Name = "Leave at Wave", Placeholder = "0 = Disabled", Callback = function(t) getgenv().RaidLeaveWave = tonumber(t) or 0 end})

-- ═══════════════════════════════════════
--  TAB 5: AUTOMATION
-- ═══════════════════════════════════════
local AutoTab = Window:MakeTab({Name = "🤖 Automation", Icon = ""})
local AutoSec = AutoTab:MakeSection({Name = "Core Automations"})

AutoSec:AddToggle({Name = "Auto Claim Rewards", Default = false, Callback = function(s) getgenv().AutoClaimQuests = s; task.spawn(function() while getgenv().AutoClaimQuests and task.wait(5) do if not getgenv().Nebublox_Running then break end; ClaimQuests() end end) end})
AutoSec:AddToggle({Name = "Auto Claim Achievements", Default = false, Callback = function(s) getgenv().AutoClaimAchievements = s; task.spawn(function() while getgenv().AutoClaimAchievements and task.wait(60) do if not getgenv().Nebublox_Running then break end; ClaimAchievements() end end) end})
AutoSec:AddToggle({Name = "Auto Collect Chests", Default = false, Callback = function(s) getgenv().AutoCollectChests = s; task.spawn(function() while getgenv().AutoCollectChests and task.wait(600) do if not getgenv().Nebublox_Running then break end; ClaimChests() end end) end})
AutoSec:AddToggle({Name = "Auto Ascension", Default = false, Callback = function(s) getgenv().AutoAscension = s; task.spawn(function() while getgenv().AutoAscension and task.wait(5) do if not getgenv().Nebublox_Running then break end; pcall(function() if GameLibrary and GameLibrary.Remote then GameLibrary.Remote:Fire("RebirthSystem","Ascension","Normal") end end) end end) end})
AutoSec:AddToggle({Name = "Auto Equip Best Weapon", Default = false, Callback = function(s) getgenv().AutoEquipWeapon = s; task.spawn(function() while getgenv().AutoEquipWeapon and task.wait(10) do if not getgenv().Nebublox_Running then break end; pcall(function() if GameLibrary and GameLibrary.Remote then GameLibrary.Remote:Fire("ItemSystem","EquipBest","Weapon") end end) end end) end})
AutoSec:AddToggle({Name = "Auto Equip Best Form", Default = false, Callback = function(s) getgenv().AutoEquipForm = s; task.spawn(function() while getgenv().AutoEquipForm and task.wait(10) do if not getgenv().Nebublox_Running then break end; pcall(function() if GameLibrary and GameLibrary.Remote then GameLibrary.Remote:Fire("ItemSystem","EquipBest","Form") end end) end end) end})

local GachaSec = AutoTab:MakeSection({Name = "Gacha & Scrolls"})
getgenv().SelectedScroll = "Solo Scroll"
GachaSec:AddDropdown({Name = "Select Scroll", Options = {"Titan Scroll","Supernatural Scroll","Spiritual Scroll","Solo Scroll"}, Default = "Solo Scroll", Callback = function(v) getgenv().SelectedScroll = v end})
GachaSec:AddToggle({Name = "Auto Hatch Selected", Default = false, Callback = function(s)
    getgenv().AutoHatch = s
    task.spawn(function() while getgenv().AutoHatch and task.wait(0.1) do if not getgenv().Nebublox_Running then break end; HatchScroll(getgenv().SelectedScroll, 5); local wt = (GameLibrary and GameLibrary.PlayerData and GameLibrary.PlayerData.Gamepasses and GameLibrary.PlayerData.Gamepasses.FastOpen) and 0.1 or 0.8; task.wait(wt) end end)
end})

getgenv().SelectedGachaType = "Enchantments"
GachaSec:AddDropdown({Name = "Gacha Category", Options = {"Enchantments","Hunter Ranks","Traits","Titan Serums","Passives","Soul Foundation","Avatars","Weapons"}, Default = "Enchantments", Callback = function(v) getgenv().SelectedGachaType = v end})
GachaSec:AddToggle({Name = "Auto Spin Gacha", Default = false, Callback = function(s) getgenv().AutoSpinGacha = s; task.spawn(function() while getgenv().AutoSpinGacha and task.wait(1) do if not getgenv().Nebublox_Running then break end; SpinGacha(getgenv().SelectedGachaType, "Normal") end end) end})

local SpeedSec = AutoTab:MakeSection({Name = "Movement Hacks"})
SpeedSec:AddToggle({Name = "Auto WalkSpeed", Default = false, Callback = function(s) getgenv().AutoWalkSpeed = s; if s then task.spawn(function() while getgenv().AutoWalkSpeed do if not getgenv().Nebublox_Running then break end; pcall(function() local h = player.Character and player.Character:FindFirstChild("Humanoid"); if h then h.WalkSpeed = getgenv().AutoWalkSpeedVal or 100 end end); task.wait(0.1) end end) end end})
SpeedSec:AddSlider({Name = "WalkSpeed Value", Min = 16, Max = 500, Increment = 1, Default = 100, Callback = function(v) getgenv().AutoWalkSpeedVal = v end})
SpeedSec:AddToggle({Name = "Auto JumpPower", Default = false, Callback = function(s) getgenv().AutoJumpPower = s; if s then task.spawn(function() while getgenv().AutoJumpPower do if not getgenv().Nebublox_Running then break end; pcall(function() local h = player.Character and player.Character:FindFirstChild("Humanoid"); if h then h.JumpPower = getgenv().AutoJumpPowerVal or 100 end end); task.wait(0.1) end end) end end})
SpeedSec:AddSlider({Name = "JumpPower Value", Min = 50, Max = 500, Increment = 1, Default = 100, Callback = function(v) getgenv().AutoJumpPowerVal = v end})

-- ═══════════════════════════════════════
--  TAB 6: SHOP
-- ═══════════════════════════════════════
local ShopTab = Window:MakeTab({Name = "🛒 Shop", Icon = ""})
local ShopSec = ShopTab:MakeSection({Name = "Auto-Buy"})
local ShopItems = {YenPotion2="Yen Potion II",DamagePotion2="Damage Potion II",LuckPotion2="Luck Potion II",XPPotion2="XP Potion II",DropPotion2="Drop Potion II",Crystals="Crystals"}
getgenv().AutoBuyItems = {}
for id, title in pairs(ShopItems) do
    ShopSec:AddToggle({Name = "Auto Buy " .. title, Default = false, Callback = function(s)
        getgenv().AutoBuyItems[id] = s
        if s then task.spawn(function() while getgenv().AutoBuyItems[id] and task.wait(60) do if not getgenv().Nebublox_Running then break end; pcall(function() if GameLibrary and GameLibrary.Remote then GameLibrary.Remote:Fire("ShopSystem","Buy","Dungeon Shop",id) end end) end end) end
    end})
end

-- ═══════════════════════════════════════
--  TAB 7: TELEPORTS
-- ═══════════════════════════════════════
local TPTab = Window:MakeTab({Name = "🌍 Teleports", Icon = ""})
local TPSec = TPTab:MakeSection({Name = "World Navigation"})
TPSec:AddButton({Name = "Map 1 (Spawn)", Callback = function() pcall(function() local sp = Workspace:FindFirstChild("_MAP") and Workspace._MAP:FindFirstChild("1") and Workspace._MAP["1"]:FindFirstChild("Spawn") and Workspace._MAP["1"].Spawn:FindFirstChild("hf sp"); if sp and sp:IsA("BasePart") then player.Character.HumanoidRootPart.CFrame = sp.CFrame * CFrame.new(0,3,0); Window:Notify({Title="Teleport",Content="Map 1!",Type="success"}) end end) end})
for i = 2, 4 do
    TPSec:AddButton({Name = "Map " .. i, Callback = function() pcall(function() local portal = Workspace:FindFirstChild("Lobby") and Workspace.Lobby:FindFirstChild("Portals") and Workspace.Lobby.Portals:FindFirstChild(tostring(i)); if portal and portal:FindFirstChild("Portal") then player.Character.HumanoidRootPart.CFrame = portal.Portal.CFrame * CFrame.new(0,3,0); Window:Notify({Title="Teleport",Content="Map "..i.."!",Type="success"}) end end) end})
end

-- ═══════════════════════════════════════
--  TAB 8: SETTINGS
-- ═══════════════════════════════════════
local SettingsTab = Window:MakeTab({Name = "⚙️ Settings", Icon = ""})

local UtilSec = SettingsTab:MakeSection({Name = "Utilities"})
UtilSec:AddToggle({Name = "Anti-AFK Mechanism", Default = false, Callback = function(s) if s then getgenv().AntiAfkConnection = player.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end) else if getgenv().AntiAfkConnection then getgenv().AntiAfkConnection:Disconnect() end end end})

UtilSec:AddDualButton(
    {Name = "FPS Boost (Potato)", Icon = "zap", Callback = function()
        task.spawn(function() pcall(function()
            Lighting.GlobalShadows = false; Lighting.FogEnd = 9e9; Lighting.Brightness = 1
            for _, c in ipairs(Lighting:GetChildren()) do if c:IsA("PostEffect") or c:IsA("BlurEffect") or c:IsA("SunRaysEffect") or c:IsA("ColorCorrectionEffect") or c:IsA("BloomEffect") or c:IsA("DepthOfFieldEffect") or c:IsA("Atmosphere") or c:IsA("Sky") then c:Destroy() end end
            for _, v in ipairs(Workspace:GetDescendants()) do
                if v:IsA("BasePart") then v.Material = Enum.Material.Plastic; v.Reflectance = 0; v.CastShadow = false
                elseif v:IsA("Decal") or v:IsA("Texture") then v:Destroy()
                elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Sparkles") or v:IsA("Fire") or v:IsA("Smoke") then v:Destroy()
                elseif v:IsA("MeshPart") then v.Material = Enum.Material.Plastic; v.TextureID = ""
                elseif v:IsA("Sound") then v:Stop(); v:Destroy() end
            end
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end); Window:Notify({Title="FPS Boost", Content="Potato Mode Applied!", Type="success"}) end)
    end},
    {Name = "Unload Script", Icon = "shield", Callback = function()
        getgenv().Nebublox_Running = false
        if getgenv().AntiAfkConnection then getgenv().AntiAfkConnection:Disconnect() end
        if CurrentHighlight then pcall(function() CurrentHighlight:Destroy() end) end
        if getgenv().NebuBlox_Platform then pcall(function() getgenv().NebuBlox_Platform:Destroy() end) end
        if getgenv().NebuBlox_NoClipConnection then getgenv().NebuBlox_NoClipConnection:Disconnect() end
        if getgenv().NebuBlox_MovementConnection then getgenv().NebuBlox_MovementConnection:Disconnect() end
        pcall(function() Window:Destroy() end)
    end}
)

local SetSec = SettingsTab:MakeSection({Name = "Configuration Management"})
local FolderName = "Nebublox"
local ConfigsFolder = FolderName .. "/Configs"
pcall(function() if not isfolder(FolderName) then makefolder(FolderName) end; if not isfolder(ConfigsFolder) then makefolder(ConfigsFolder) end end)

local ConfName = ""
SetSec:AddTextbox({Name = "Config Profile", Placeholder = "Enter config name...", Callback = function(t) ConfName = t end})

SetSec:AddDualButton(
    {Name = "Save Settings", Icon = "download", Callback = function() if ConfName ~= "" then pcall(function() writefile(ConfigsFolder.."/"..ConfName..".json", HttpService:JSONEncode(getgenv().NebubloxSettings or {})) end); Window:Notify({Title="Config",Content="Saved: "..ConfName,Type="success"}) end end},
    {Name = "Load Settings", Icon = "upload", Callback = function() if ConfName ~= "" then pcall(function() local p = ConfigsFolder.."/"..ConfName..".json"; if isfile(p) then for k,v in pairs(HttpService:JSONDecode(readfile(p))) do getgenv().NebubloxSettings = getgenv().NebubloxSettings or {}; getgenv().NebubloxSettings[k] = v end end end); Window:Notify({Title="Config",Content="Loaded: "..ConfName,Type="success"}) end end}
)

-- ═══════════════════════════════════════
--  FINAL INIT
-- ═══════════════════════════════════════
Window:Notify({Title = "Nebublox : Anime Ghost", Content = "Masterpiece loaded successfully! 🌌", Type = "success", Duration = 5})

-- Hide game Info GUI
pcall(function() for _, gui in ipairs(player.PlayerGui:GetDescendants()) do if gui.Name == "Info" and gui:IsA("ScreenGui") then gui.Enabled = false end; if gui.Name == "Info" and gui:IsA("Frame") then gui.Visible = false end end end)
