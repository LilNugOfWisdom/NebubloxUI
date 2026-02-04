--[[
    ═══════════════════════════════════════════════════════════
    NEBUBLOX | ANIME CAPTURE
    Script hub for Anime Capture game
    ═══════════════════════════════════════════════════════════
]]

local GAME_NAME = "Anime Capture"
local SCRIPT_VERSION = "1.0.0"

-- Load Library
local NebubloxUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Gamr46/NebubloxUI/main/nebublox_ui.lua"))()

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

-- Game Remote Events (Anime Capture specific)
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 5) or ReplicatedStorage
local SetEnemyEvent = Remotes:FindFirstChild("SetEnemyEvent") or ReplicatedStorage:FindFirstChild("SetEnemyEvent")
local ClickEvent = Remotes:FindFirstChild("ClickEvent") or ReplicatedStorage:FindFirstChild("ClickEvent")
local CatchFollowFinish = Remotes:FindFirstChild("CatchFollowFinish") or ReplicatedStorage:FindFirstChild("CatchFollowFinish")
local PlayerAttack = Remotes:FindFirstChild("PlayerAttack") or ReplicatedStorage:FindFirstChild("PlayerAttack")
local RollOne = Remotes:FindFirstChild("RollOne") or ReplicatedStorage:FindFirstChild("RollOne")

-- Variables
local autoFarmEnabled = false
local autoCaptureEnabled = false
local autoClickEnabled = false
local selectedTarget = nil

-- ═══════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════

-- Find all capturable entities (NPCs/Anime characters)
local function getCapturableEntities()
    local entities = {}
    
    -- Check common locations for NPCs
    local searchFolders = {
        Workspace:FindFirstChild("NPCs"),
        Workspace:FindFirstChild("Enemies"),
        Workspace:FindFirstChild("Mobs"),
        Workspace:FindFirstChild("Characters"),
        Workspace:FindFirstChild("Anime"),
        Workspace
    }
    
    for _, folder in ipairs(searchFolders) do
        if folder then
            for _, obj in ipairs(folder:GetDescendants()) do
                -- Look for humanoids that aren't players
                if obj:IsA("Humanoid") and obj.Health > 0 then
                    local root = obj.Parent:FindFirstChild("HumanoidRootPart")
                    if root and not Players:GetPlayerFromCharacter(obj.Parent) then
                        table.insert(entities, {
                            Name = obj.Parent.Name,
                            Model = obj.Parent,
                            Humanoid = obj,
                            Root = root
                        })
                    end
                end
            end
        end
    end
    
    return entities
end

-- Get closest entity
local function getClosestEntity()
    local entities = getCapturableEntities()
    local closest = nil
    local closestDist = math.huge
    
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local myPos = player.Character.HumanoidRootPart.Position
        for _, entity in ipairs(entities) do
            local dist = (myPos - entity.Root.Position).Magnitude
            if dist < closestDist then
                closestDist = dist
                closest = entity
            end
        end
    end
    
    return closest, closestDist
end

-- ═══════════════════════════════════════════════════════════
-- CREATE WINDOW
-- ═══════════════════════════════════════════════════════════
local Window = NebubloxUI:CreateWindow({
    Title = "Nebublox | " .. GAME_NAME,
    Author = "by Nebublox",
    Folder = "Nebublox_AnimeCapture",
    Theme = "Void",
    Transparent = true,
    SideBarWidth = 200,
    HasOutline = true,
})

-- ═══════════════════════════════════════════════════════════
-- TABS
-- ═══════════════════════════════════════════════════════════
local CaptureTab = Window:Tab({ Title = "Capture", Icon = "target" })
local FruitsTab = Window:Tab({ Title = "Fruits", Icon = "cherry" })
local FarmTab = Window:Tab({ Title = "Farm", Icon = "coins" })
local PlayerTab = Window:Tab({ Title = "Player", Icon = "user" })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

-- ═══════════════════════════════════════════════════════════
-- CAPTURE TAB
-- ═══════════════════════════════════════════════════════════
local TargetSection = CaptureTab:Section({ Title = "Target Selection", Icon = "crosshair", Opened = true })
local CaptureSection = CaptureTab:Section({ Title = "Capture Options", Icon = "box", Opened = true })

-- Refresh & Select Target
TargetSection:Button({
    Title = "Find Nearest Entity",
    Desc = "Locate closest capturable character",
    Icon = "search",
    Callback = function()
        local entity, dist = getClosestEntity()
        if entity then
            selectedTarget = entity
            NebubloxUI:Notify({
                Title = "Target Found!",
                Content = entity.Name .. " (" .. math.floor(dist) .. " studs away)",
                Icon = "target",
                Duration = 3
            })
        else
            NebubloxUI:Notify({
                Title = "No Targets",
                Content = "No capturable entities found",
                Icon = "x",
                Duration = 3
            })
        end
    end
})

-- Teleport to target
TargetSection:Button({
    Title = "Teleport to Target",
    Desc = "Teleport to selected entity",
    Icon = "zap",
    Callback = function()
        if selectedTarget and selectedTarget.Root then
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                player.Character.HumanoidRootPart.CFrame = selectedTarget.Root.CFrame + Vector3.new(0, 5, 0)
                NebubloxUI:Notify({ Title = "Teleported!", Content = "Arrived at " .. selectedTarget.Name, Icon = "check", Duration = 2 })
            end
        else
            NebubloxUI:Notify({ Title = "No Target", Content = "Find a target first!", Icon = "alert-circle", Duration = 2 })
        end
    end
})

-- Set Enemy (fires SetEnemyEvent)
CaptureSection:Button({
    Title = "Set Enemy Target",
    Desc = "Fire SetEnemyEvent on selected target",
    Icon = "crosshair",
    Callback = function()
        if selectedTarget and selectedTarget.Model then
            if SetEnemyEvent then
                SetEnemyEvent:FireServer(selectedTarget.Model)
                NebubloxUI:Notify({ Title = "Enemy Set!", Content = "Targeting " .. selectedTarget.Name, Icon = "target", Duration = 2 })
            else
                NebubloxUI:Notify({ Title = "Error", Content = "SetEnemyEvent not found", Icon = "x", Duration = 2 })
            end
        else
            NebubloxUI:Notify({ Title = "No Target", Content = "Select a target first!", Icon = "alert-circle", Duration = 2 })
        end
    end
})

-- Click Attack (fires ClickEvent)
CaptureSection:Button({
    Title = "Click Attack",
    Desc = "Fire ClickEvent on selected target",
    Icon = "mouse-pointer",
    Callback = function()
        if selectedTarget and selectedTarget.Model then
            if ClickEvent then
                ClickEvent:FireServer(selectedTarget.Model)
                NebubloxUI:Notify({ Title = "Clicked!", Content = "Attacked " .. selectedTarget.Name, Icon = "zap", Duration = 2 })
            else
                NebubloxUI:Notify({ Title = "Error", Content = "ClickEvent not found", Icon = "x", Duration = 2 })
            end
        else
            NebubloxUI:Notify({ Title = "No Target", Content = "Select a target first!", Icon = "alert-circle", Duration = 2 })
        end
    end
})

-- Capture/Catch (fires CatchFollowFinish)
CaptureSection:Button({
    Title = "Capture Now",
    Desc = "Fire CatchFollowFinish to capture",
    Icon = "box",
    Callback = function()
        if selectedTarget and selectedTarget.Model then
            if CatchFollowFinish then
                CatchFollowFinish:FireServer(selectedTarget.Model)
                NebubloxUI:Notify({ Title = "Captured!", Content = "Caught " .. selectedTarget.Name, Icon = "check", Duration = 2 })
            else
                NebubloxUI:Notify({ Title = "Error", Content = "CatchFollowFinish not found", Icon = "x", Duration = 2 })
            end
        else
            NebubloxUI:Notify({ Title = "No Target", Content = "Select a target first!", Icon = "alert-circle", Duration = 2 })
        end
    end
})

-- Player Attack (fires PlayerAttack)
CaptureSection:Button({
    Title = "Player Attack",
    Desc = "Fire PlayerAttack remote",
    Icon = "swords",
    Callback = function()
        if selectedTarget and selectedTarget.Model then
            if PlayerAttack then
                PlayerAttack:FireServer(selectedTarget.Model)
                NebubloxUI:Notify({ Title = "Attacked!", Content = "Player attacked " .. selectedTarget.Name, Icon = "swords", Duration = 2 })
            else
                NebubloxUI:Notify({ Title = "Error", Content = "PlayerAttack not found", Icon = "x", Duration = 2 })
            end
        else
            NebubloxUI:Notify({ Title = "No Target", Content = "Select a target first!", Icon = "alert-circle", Duration = 2 })
        end
    end
})

-- Auto capture toggle
CaptureSection:Toggle({
    Title = "Auto Capture",
    Desc = "Auto: SetEnemy → Click → Catch",
    Value = false,
    Callback = function(state)
        autoCaptureEnabled = state
        NebubloxUI:Notify({
            Title = state and "Auto Capture ON" or "Auto Capture OFF",
            Content = state and "Will auto-capture entities" or "Disabled",
            Icon = state and "check" or "x",
            Duration = 2
        })
    end
})

-- Auto Click toggle
CaptureSection:Toggle({
    Title = "Auto Click",
    Desc = "Continuously fire ClickEvent",
    Value = false,
    Callback = function(state)
        autoClickEnabled = state
        NebubloxUI:Notify({
            Title = state and "Auto Click ON" or "Auto Click OFF",
            Content = state and "Clicking enabled" or "Disabled",
            Icon = state and "mouse-pointer" or "x",
            Duration = 2
        })
    end
})

-- Entity list dropdown
local entityDropdown
entityDropdown = TargetSection:Dropdown({
    Title = "Select Entity",
    Values = {},
    SearchBarEnabled = true,
    Callback = function(val)
        -- Find selected entity
        local entities = getCapturableEntities()
        for _, entity in ipairs(entities) do
            if entity.Name == (val.Title or val) then
                selectedTarget = entity
                NebubloxUI:Notify({ Title = "Selected!", Content = entity.Name, Icon = "check", Duration = 2 })
                break
            end
        end
    end
})

TargetSection:Button({
    Title = "Refresh Entity List",
    Icon = "refresh-cw",
    Callback = function()
        local entities = getCapturableEntities()
        local values = {}
        for _, entity in ipairs(entities) do
            table.insert(values, { Title = entity.Name, Icon = "user" })
        end
        if entityDropdown.SetValues then
            entityDropdown:SetValues(values)
        end
        NebubloxUI:Notify({ Title = "Refreshed!", Content = #entities .. " entities found", Icon = "check", Duration = 2 })
    end
})

-- ═══════════════════════════════════════════════════════════
-- GACHA TAB (Rolling)
-- ═══════════════════════════════════════════════════════════
local RollSection = FruitsTab:Section({ Title = "Gacha Rolling", Icon = "dice-5", Opened = true })
local SceneSection = FruitsTab:Section({ Title = "Scenes/Worlds", Icon = "map", Opened = true })

-- Scene data with gachas and teleport coordinates
local SCENES = {
    { Name = "Scene 1 - Pirate Village",       CFrame = CFrame.new(0, 50, 0), --[[ UPDATE COORDS ]] Gachas = {"Shock Fruit", "Flame Fruit"} },
    { Name = "Scene 2 - Ninja Village",        CFrame = CFrame.new(0, 50, 0), --[[ UPDATE COORDS ]] Gachas = {"Sharingan", "Tessen"} },
    { Name = "Scene 3 - Shirayuki Village",    CFrame = CFrame.new(0, 50, 0), --[[ UPDATE COORDS ]] Gachas = {"Nichirian Earring", "SwordsSmith Mask"} },
    { Name = "Scene 4 - Cursed Arts Hamlet",   CFrame = CFrame.new(0, 50, 0), --[[ UPDATE COORDS ]] Gachas = {"Impression Ring", "Prison Realm"} },
    { Name = "Scene 5 - Arcane City Lofts",    CFrame = CFrame.new(0, 50, 0), --[[ UPDATE COORDS ]] Gachas = {"One Punch", "Monster Cell"} },
    { Name = "Scene 6 - Lookout",              CFrame = CFrame.new(0, 50, 0), --[[ UPDATE COORDS ]] Gachas = {"Scouter", "Dragon Radar"} },
    { Name = "Scene 7 - Duck Research Center", CFrame = CFrame.new(0, 50, 0), --[[ UPDATE COORDS ]] Gachas = {"Speed Mark", "Life Mark"} },
}

local autoRollEnabled = false
local selectedScene = SCENES[1]

-- Roll once button (RollOne takes no arguments)
RollSection:Button({
    Title = "Roll Once",
    Desc = "Fire RollOne (random gacha)",
    Icon = "dice-5",
    Callback = function()
        if RollOne then
            RollOne:FireServer()
            NebubloxUI:Notify({ Title = "Rolling!", Content = "Rolled for a gacha!", Icon = "dice-5", Duration = 2 })
        else
            NebubloxUI:Notify({ Title = "Error", Content = "RollOne remote not found", Icon = "x", Duration = 2 })
        end
    end
})

-- Roll 10x button
RollSection:Button({
    Title = "Roll 10x",
    Desc = "Roll 10 times quickly",
    Icon = "layers",
    Callback = function()
        if RollOne then
            for i = 1, 10 do
                RollOne:FireServer()
                wait(0.1)
            end
            NebubloxUI:Notify({ Title = "Done!", Content = "Rolled 10 times!", Icon = "check", Duration = 2 })
        else
            NebubloxUI:Notify({ Title = "Error", Content = "RollOne remote not found", Icon = "x", Duration = 2 })
        end
    end
})

-- Auto roll toggle
RollSection:Toggle({
    Title = "Auto Roll",
    Desc = "Continuously roll for fruits",
    Value = false,
    Callback = function(state)
        autoRollEnabled = state
        NebubloxUI:Notify({
            Title = state and "Auto Roll ON" or "Auto Roll OFF",
            Content = state and "Rolling continuously..." or "Stopped",
            Icon = state and "repeat" or "x",
            Duration = 2
        })
    end
})

-- Auto roll speed slider
local autoRollDelay = 0.5
RollSection:Slider({
    Title = "Roll Speed (seconds)",
    Value = { Min = 0.1, Max = 2, Default = 0.5 },
    Step = 0.1,
    Callback = function(val)
        autoRollDelay = val
    end
})

-- Scene dropdown for info & selection
SceneSection:Dropdown({
    Title = "Select Scene",
    Values = (function()
        local vals = {}
        for _, scene in ipairs(SCENES) do
            table.insert(vals, { Title = scene.Name, Icon = "map-pin" })
        end
        return vals
    end)(),
    Callback = function(val)
        for _, scene in ipairs(SCENES) do
            if scene.Name == (val.Title or val) then
                selectedScene = scene
                local gachaText = #scene.Gachas > 0 and table.concat(scene.Gachas, ", ") or "Unknown"
                NebubloxUI:Notify({ Title = scene.Name, Content = "Gachas: " .. gachaText, Icon = "gift", Duration = 3 })
                break
            end
        end
    end
})

-- Teleport Button
SceneSection:Button({
    Title = "Teleport to Scene",
    Desc = "Teleport to selected location",
    Icon = "zap",
    Callback = function()
        if selectedScene and selectedScene.CFrame then
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                player.Character.HumanoidRootPart.CFrame = selectedScene.CFrame
                NebubloxUI:Notify({ Title = "Teleported!", Content = "Arrived at " .. selectedScene.Name, Icon = "check", Duration = 2 })
            end
        else
            NebubloxUI:Notify({ Title = "Error", Content = "No coordinates set for this scene!", Icon = "x", Duration = 2 })
        end
    end
})
RollSection:Slider({
    Title = "Roll Speed (seconds)",
    Value = { Min = 0.1, Max = 2, Default = 0.5 },
    Step = 0.1,
    Callback = function(val)
        autoRollDelay = val
    end
})

-- ═══════════════════════════════════════════════════════════
-- FARM TAB
-- ═══════════════════════════════════════════════════════════
local AutoSection = FarmTab:Section({ Title = "Auto Farm", Icon = "repeat", Opened = true })

AutoSection:Toggle({
    Title = "Auto Farm",
    Desc = "Automatically farm resources/XP",
    Value = false,
    Callback = function(state)
        autoFarmEnabled = state
        NebubloxUI:Notify({
            Title = state and "Auto Farm ON" or "Auto Farm OFF",
            Content = state and "Farming started" or "Farming stopped",
            Icon = state and "coins" or "x",
            Duration = 2
        })
    end
})

AutoSection:Toggle({
    Title = "Auto Teleport to Mobs",
    Desc = "Teleport to nearest mob when farming",
    Value = false,
    Callback = function(state)
        -- Add your teleport logic
    end
})

-- ═══════════════════════════════════════════════════════════
-- PLAYER TAB
-- ═══════════════════════════════════════════════════════════
local MovementSection = PlayerTab:Section({ Title = "Movement", Icon = "footprints", Opened = true })
local StatsSection = PlayerTab:Section({ Title = "Stats", Icon = "bar-chart", Opened = true })

MovementSection:Slider({
    Title = "WalkSpeed",
    Value = { Min = 16, Max = 200, Default = 16 },
    Callback = function(val)
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.WalkSpeed = val
        end
    end
})

MovementSection:Slider({
    Title = "JumpPower",
    Value = { Min = 50, Max = 500, Default = 50 },
    Callback = function(val)
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.JumpPower = val
        end
    end
})

MovementSection:Toggle({
    Title = "Infinite Jump",
    Value = false,
    Callback = function(state)
        -- Infinite jump logic would go here
    end
})

MovementSection:Toggle({
    Title = "No Clip",
    Value = false,
    Callback = function(state)
        -- No clip logic would go here
    end
})

-- ═══════════════════════════════════════════════════════════
-- SETTINGS TAB
-- ═══════════════════════════════════════════════════════════
local ConfigSection = SettingsTab:Section({ Title = "Configuration", Icon = "save", Opened = true })

ConfigSection:Button({
    Title = "Save Config",
    Icon = "save",
    Callback = function()
        NebubloxUI:Notify({ Title = "Saved!", Content = "Config saved", Icon = "check", Duration = 3 })
    end
})

ConfigSection:Button({
    Title = "Load Config",
    Icon = "folder-open",
    Callback = function()
        NebubloxUI:Notify({ Title = "Loaded!", Content = "Config loaded", Icon = "check", Duration = 3 })
    end
})

-- ═══════════════════════════════════════════════════════════
-- BACKGROUND LOOPS
-- ═══════════════════════════════════════════════════════════
spawn(function()
    while wait(0.5) do
        -- Auto capture loop (full sequence)
        if autoCaptureEnabled then
            local entity = getClosestEntity()
            if entity and entity.Model then
                -- Teleport close
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    player.Character.HumanoidRootPart.CFrame = entity.Root.CFrame + Vector3.new(0, 3, 0)
                end
                
                -- Fire capture sequence
                if SetEnemyEvent then SetEnemyEvent:FireServer(entity.Model) end
                wait(0.1)
                if ClickEvent then ClickEvent:FireServer(entity.Model) end
                wait(0.1)
                if PlayerAttack then PlayerAttack:FireServer(entity.Model) end
                wait(0.1)
                if CatchFollowFinish then CatchFollowFinish:FireServer(entity.Model) end
            end
        end
        
        -- Auto click loop
        if autoClickEnabled then
            local entity = getClosestEntity()
            if entity and entity.Model then
                if ClickEvent then ClickEvent:FireServer(entity.Model) end
                if PlayerAttack then PlayerAttack:FireServer(entity.Model) end
            end
        end
        
        -- Auto farm loop
        if autoFarmEnabled then
            local entity = getClosestEntity()
            if entity and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                -- Teleport to entity
                player.Character.HumanoidRootPart.CFrame = entity.Root.CFrame + Vector3.new(0, 3, 0)
            end
        end
    end
end)

-- Auto Roll Loop (separate for custom speed)
spawn(function()
    while true do
        if autoRollEnabled and RollOne then
            RollOne:FireServer()
        end
        wait(autoRollDelay or 0.5)
    end
end)

-- ═══════════════════════════════════════════════════════════
-- STARTUP
-- ═══════════════════════════════════════════════════════════
NebubloxUI:Notify({
    Title = "Anime Capture Loaded!",
    Content = "Script ready - enjoy!",
    Icon = "rocket",
    Duration = 5
})

print("[Nebublox] Anime Capture script loaded!")
