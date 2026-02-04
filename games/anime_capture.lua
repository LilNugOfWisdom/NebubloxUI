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

local RollOne = Remotes:FindFirstChild("RollOne") or ReplicatedStorage:FindFirstChild("RollOne")
local RebirthEvent = Remotes:FindFirstChild("RebirthEvent") or ReplicatedStorage:FindFirstChild("RebirthEvent")
local EquipBestEvent = Remotes:FindFirstChild("EquipBestEvent") or ReplicatedStorage:FindFirstChild("EquipBestEvent") -- UPDATED
local CraftItemEvent = Remotes:FindFirstChild("CraftItemEvent") or ReplicatedStorage:FindFirstChild("CraftItemEvent") -- UPDATED
local GetAllEvent = Remotes:FindFirstChild("GetAllEvent") or ReplicatedStorage:FindFirstChild("GetAllEvent") -- Achievement Claim
local UseCatchRate = Remotes:FindFirstChild("CatchRate") and Remotes.CatchRate:FindFirstChild("UseCatchRate") or ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events.CatchRate:FindFirstChild("UseCatchRate")

-- Variables
local autoFarmEnabled = false
local autoCaptureEnabled = false
local autoClickEnabled = false
local autoRebirthEnabled = false
local autoEquipEnabled = false
local autoCraftEnabled = false
local autoClaimAchievements = false
local selectedTarget = nil
local selectedBallId = 1 -- Default Ball ID

-- ... (rest of code)

-- ═══════════════════════════════════════════════════════════
-- CAPTURE TAB
-- ═══════════════════════════════════════════════════════════

CaptureSection:Slider({
    Title = "Ball ID",
    Desc = "ID of the ball to equip/use",
    Value = { Min = 1, Max = 20, Default = 1 },
    Step = 1,
    Callback = function(val)
        selectedBallId = val
    end
})

CaptureSection:Button({
    Title = "Equip Ball",
    Desc = "Manually equip selected ball",
    Icon = "circle",
    Callback = function()
        if UseCatchRate then
            UseCatchRate:FireServer(selectedBallId)
            NebubloxUI:Notify({ Title = "Equipped!", Content = "Ball ID: " .. selectedBallId, Icon = "check", Duration = 2 })
        else
            NebubloxUI:Notify({ Title = "Error", Content = "UseCatchRate remote not found", Icon = "x", Duration = 2 })
        end
    end
})

CaptureSection:Button({
    Title = "Capture Now",
    Desc = "Equip Ball -> Capture",
    Icon = "box",
    Callback = function()
        if selectedTarget and selectedTarget.Model then
            -- 1. Equip Ball First
            if UseCatchRate then
                UseCatchRate:FireServer(selectedBallId)
            end
            wait(0.1)
            -- 2. Capture
            if CatchFollowFinish then
                CatchFollowFinish:FireServer(selectedTarget.Model, selectedBallId)
                NebubloxUI:Notify({ Title = "Captured!", Content = "Caught " .. selectedTarget.Name, Icon = "check", Duration = 2 })
            else
                NebubloxUI:Notify({ Title = "Error", Content = "CatchFollowFinish not found", Icon = "x", Duration = 2 })
            end
        else
            NebubloxUI:Notify({ Title = "No Target", Content = "Select a target first!", Icon = "alert-circle", Duration = 2 })
        end
    end
})

-- ... (rest of features)

-- BACKGROUND LOOPS UPDATE
-- ...
        -- Auto Capture loop (full sequence)
        if autoCaptureEnabled then
            local entity = getClosestEntity()
            if entity and entity.Model then
                -- Teleport close
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    player.Character.HumanoidRootPart.CFrame = entity.Root.CFrame + Vector3.new(0, 3, 0)
                end
                
                -- Fire capture sequence
                -- 0. Equip Ball
                if UseCatchRate then UseCatchRate:FireServer(selectedBallId) end
                
                -- 1. Engage
                if SetEnemyEvent then SetEnemyEvent:FireServer(entity.Model) end
                wait(0.1)
                
                -- 2. Attack
                if ClickEvent then ClickEvent:FireServer(entity.Model) end
                if PlayerAttack then PlayerAttack:FireServer(entity.Model) end
                wait(0.1)
                
                -- 3. Capture
                if CatchFollowFinish then CatchFollowFinish:FireServer(entity.Model, selectedBallId) end
            end
        end
-- ...

-- ... (rest of features)

-- Auto Claim Achievements (using GetAllEvent)
StatsSection:Toggle({
    Title = "Auto Claim Achievements",
    Desc = "Spam GetAllEvent to claim rewards",
    Value = false,
    Callback = function(state)
        autoClaimAchievements = state
        NebubloxUI:Notify({ Title = "Auto Claim", Content = state and "ON" or "OFF", Icon = "award", Duration = 2 })
    end
})


-- BACKGROUND LOOPS UPDATE
-- ...
        -- Auto Capture loop (full sequence)
        if autoCaptureEnabled then
            local entity = getClosestEntity()
            if entity and entity.Model then
                -- Teleport close
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    player.Character.HumanoidRootPart.CFrame = entity.Root.CFrame + Vector3.new(0, 3, 0)
                end
                
                -- Fire capture sequence
                -- 0. Equip Ball
                if UseCatchRate then UseCatchRate:FireServer(selectedBallId) end
                
                -- 1. Engage
                if SetEnemyEvent then SetEnemyEvent:FireServer(entity.Model) end
                wait(0.1)
                
                -- 2. Attack
                if ClickEvent then ClickEvent:FireServer(entity.Model) end
                if PlayerAttack then PlayerAttack:FireServer(entity.Model) end
                wait(0.1)
                
                -- 3. Capture
                if CatchFollowFinish then CatchFollowFinish:FireServer(entity.Model, selectedBallId) end
            end
        end

        -- Auto Rebirth
        if autoRebirthEnabled and RebirthEvent then
            RebirthEvent:FireServer()
        end

        -- Auto Best Equip
        if autoEquipEnabled and EquipBestEvent then
            EquipBestEvent:FireServer()
        end
        
        -- Auto Claim Achievements
        if autoClaimAchievements and GetAllEvent then
            GetAllEvent:FireServer()
        end

        -- Auto Craft Gold (loop)
        if autoCraftEnabled and CraftItemEvent then
            CraftItemEvent:FireServer("Gold") 
        end
-- ...

-- ═══════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════

-- Find all capturable entities (NPCs/Anime characters)
-- Find all capturable entities (NPCs/Anime characters)
local function getCapturableEntities()
    local entities = {}
    
    -- Scan entire workspace for Humanoids
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Humanoid") and obj.Health > 0 then
            local model = obj.Parent
            local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("HumanoidRootPart")
            
            -- Check if it's a player
            local isPlayer = Players:GetPlayerFromCharacter(model)
            
            if root and not isPlayer then
                -- Exclude our own character
                if model ~= player.Character then
                    table.insert(entities, {
                        Name = model.Name,
                        Model = model,
                        Humanoid = obj,
                        Root = root
                    })
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
-- Scene data with gachas and Workspace names
local SCENES = {
    { Name = "Scene 1 - Pirate Village",       Island = "Island1", Gachas = {"Shock Fruit", "Flame Fruit"} },
    { Name = "Scene 2 - Ninja Village",        Island = "Island2", Gachas = {"Sharingan", "Tessen"} },
    { Name = "Scene 3 - Shirayuki Village",    Island = "Island3", Gachas = {"Nichirian Earring", "SwordsSmith Mask"} },
    { Name = "Scene 4 - Cursed Arts Hamlet",   Island = "Island4", Gachas = {"Impression Ring", "Prison Realm"} },
    { Name = "Scene 5 - Arcane City Lofts",    Island = "Island5", Gachas = {"One Punch", "Monster Cell"} },
    { Name = "Scene 6 - Lookout",              Island = "Island6", Gachas = {"Scouter", "Dragon Radar"} },
    { Name = "Scene 7 - Duck Research Center", Island = "Island7", Gachas = {"Speed Mark", "Life Mark"} },
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
-- Teleport Button
SceneSection:Button({
    Title = "Teleport to Scene",
    Desc = "Teleport to selected location",
    Icon = "zap",
    Callback = function()
        if selectedScene and selectedScene.Island then
            -- Find the island in Workspace
            local island = Workspace:FindFirstChild(selectedScene.Island)
            
            if island then
                -- Try to find a good teleport spot (Spawn, Part, or just above center)
                local targetCFrame = island:IsA("Model") and (island.PrimaryPart and island.PrimaryPart.CFrame or island:GetModelCFrame()) or island.CFrame
                
                if island:IsA("Folder") then
                     -- If it's a folder, look for a "Spawn" or "Base" part
                    local spawnPart = island:FindFirstChild("Spawn") or island:FindFirstChild("Base") or island:FindFirstChild("Floor")
                    if spawnPart then
                        targetCFrame = spawnPart.CFrame
                    else
                         NebubloxUI:Notify({ Title = "Error", Content = "Could not find part in " .. selectedScene.Island, Icon = "x", Duration = 2 })
                         return
                    end
                end

                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    player.Character.HumanoidRootPart.CFrame = targetCFrame + Vector3.new(0, 10, 0)
                    NebubloxUI:Notify({ Title = "Teleported!", Content = "Arrived at " .. selectedScene.Name, Icon = "check", Duration = 2 })
                end
            else
                NebubloxUI:Notify({ Title = "Error", Content = selectedScene.Island .. " not found in Workspace", Icon = "x", Duration = 2 })
            end
        else
            NebubloxUI:Notify({ Title = "Error", Content = "No island set for this scene!", Icon = "x", Duration = 2 })
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
-- ═══════════════════════════════════════════════════════════
-- PLAYER TAB
-- ═══════════════════════════════════════════════════════════
local StatsSection = PlayerTab:Section({ Title = "Progression", Icon = "trending-up", Opened = true })
local CraftSection = PlayerTab:Section({ Title = "Crafting", Icon = "hammer", Opened = true })
local MovementSection = PlayerTab:Section({ Title = "Movement", Icon = "footprints", Opened = true })

-- Auto Rebirth
StatsSection:Toggle({
    Title = "Auto Rebirth",
    Desc = "Automatically rebirth when ready",
    Value = false,
    Callback = function(state)
        autoRebirthEnabled = state
        NebubloxUI:Notify({ Title = "Auto Rebirth", Content = state and "ON" or "OFF", Icon = "refresh-cw", Duration = 2 })
    end
})

-- Auto Best Equip
StatsSection:Toggle({
    Title = "Auto Best Equip",
    Desc = "Always equip best items",
    Value = false,
    Callback = function(state)
        autoEquipEnabled = state
        NebubloxUI:Notify({ Title = "Auto Equip", Content = state and "ON" or "OFF", Icon = "shield", Duration = 2 })
    end
})

-- Craft Gold
CraftSection:Toggle({
    Title = "Auto Craft Gold",
    Desc = "Automatically craft Gold items",
    Value = false,
    Callback = function(state)
        autoCraftEnabled = state
        NebubloxUI:Notify({ Title = "Auto Craft", Content = state and "Crafting Gold..." or "Stopped", Icon = "hammer", Duration = 2 })
    end
})

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

        -- Auto Rebirth
        if autoRebirthEnabled and RebirthEvent then
            RebirthEvent:FireServer()
        end

        -- Auto Best Equip
        if autoEquipEnabled and EquipBest then
            EquipBest:FireServer()
        end

        -- Auto Craft Gold (loop)
        if autoCraftEnabled and CraftAll then
            CraftAll:FireServer("Gold") -- Assuming "Gold" is the argument, or adjust if needed
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
