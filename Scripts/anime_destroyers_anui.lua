-- // NEBUBLOX | ANIME DESTROYERS //
-- // UI Library: ANUI //
-- // Standardized via Starter_Template //

-- 1. Load Library

-- 1. Load Library
local function LoadScript(url)
    -- [DEV] Try Local File First (for testing updates)
    if isfile and isfile("ANUI_source.lua") then return readfile("ANUI_source.lua") end
    if isfile and isfile("ANUI-Library/games/ANUI_source.lua") then return readfile("ANUI-Library/games/ANUI_source.lua") end

    local success, result = pcall(function() return game:HttpGet(url) end)
    if not success then
        success, result = pcall(function() return HttpGet(url) end) -- Try global
    end
    if not success then
        -- Fallback to request
        local req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
        if req then
            local response = req({Url = url, Method = "GET"})
            if response.Success or response.StatusCode == 200 then
                return response.Body
            end
        end
    end
    return result
end

local ANUI = loadstring(LoadScript("https://raw.githubusercontent.com/ANHub-Script/ANUI/refs/heads/main/dist/main.lua"))()

-- 2. Configuration Flags
local Flags = {
    AutoClick = false,
}

local API_URL_BASE = "https://darkmatterv1.onrender.com"

-- Key Validator Check
local function ValidateKey(key)
    local success, result = pcall(function()
        local hwid = (gethwid and gethwid() or game:GetService("RbxAnalyticsService"):GetClientId())
        return game:HttpGet(API_URL_BASE .. "/api/verify_key?key=" .. key .. "&hwid=" .. hwid)
    end)
    if success then
        local data = game:GetService("HttpService"):JSONDecode(result)
        return data and data.valid
    end
    return false
end

-- 3. Window Setup
local Window = ANUI:CreateWindow({
    Title = "Nebublox", 
    Author = "by He Who Remains",
    Folder = "NebubloxDestroyers", 
    Icon = "rbxthumb://type=Asset&id=121698194718505&w=150&h=150", 
    IconSize = 44,
})

-- 4. Standard Tabs
local MainTab = Window:Tab({ Title = "About", Icon = "info" })
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
                    frame.Size = UDim2.new(1, 0, 0, 150)
                    frame.Position = paragraph.Position
                    frame.BackgroundTransparency = 1
                    frame.Image = imgId
                    frame.ScaleType = Enum.ScaleType.Crop
                    frame.Parent = section
                    paragraph:Destroy()
                    return true
                end
            end
        end
    end
    if not FindAndInjectImage(game:GetService("CoreGui")) then FindAndInjectImage(player.PlayerGui) end
end)

local AboutSection = MainTab:Section({ Title = "Authentication", Icon = "shield", Opened = true })
AboutSection:Paragraph({
    Title = "Thank You for using Universal Hub! ❤️",
    Content = "Join our Discord for keys and updates!"
})

local UserKeyInput = ""
local InputGroup = AboutSection:Group({ Title = "" })
InputGroup:Input({ Title = "Premium Key", Placeholder = "Enter Key...", Width = 200, Callback = function(text) UserKeyInput = text end })
InputGroup:Button({
    Title = "Verify", Width = 100, 
    Callback = function() 
        ANUI:Notify({Title = "Verifying...", Content = "Checking key...", Icon = "loader", Duration = 2})
        if ValidateKey(UserKeyInput) then 
            ANUI:Notify({Title = "Success", Content = "Welcome!", Icon = "check", Duration = 3})
        else
            ANUI:Notify({Title = "Error", Content = "Invalid Key", Icon = "x", Duration = 3})
        end
    end 
})

AboutSection:Button({
    Title = "- Join Discord Community",
    Callback = function() setclipboard("https://discord.gg/nebublox") ANUI:Notify({Title = "Discord", Content = "Invite copied!", Icon = "check", Duration = 3}) end
})

local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })
local SystemSection = SettingsTab:Section({ Title = "System", Icon = "power", Opened = true })
SystemSection:Button({ Title = "Kill Script", Callback = function() if Window then Window:Destroy() end end })

-- 5. Add Game Specific Tabs

-- 5. Add Game Specific Tabs
local MainTab = Window:Tab({ Title = "Main", Icon = "home" })
local FarmSection = MainTab:Section({ Title = "Farming", Icon = "zap", Opened = true })

-- [FARM SETTINGS]
FarmSection:Toggle({
    Title = "Enable Smart Farm",
    Desc = "Auto Farm Selected Mobs",
    Value = false,
    Callback = function(s) Flags.SmartFarm = s end
})

local MobDropdown
MobDropdown = FarmSection:Dropdown({
    Title = "Select Mobs",
    Multi = true,
    Options = {"Refresh List..."},
    Callback = function(val)
        -- Convert table to set for O(1) lookup
        Flags.SelectedMobs = {}
        for k, v in pairs(val) do
            if type(k) == "string" and v == true then Flags.SelectedMobs[k] = true
            elseif type(v) == "string" then Flags.SelectedMobs[v] = true end
        end
    end
})

FarmSection:Button({
    Title = "Refresh Mobs List",
    Callback = function()
        local list = {}
        local seen = {}
        -- [USER TODO]: Update this folder path to where Mobs are located!
        local mobFolder = workspace:FindFirstChild("Mobs") or workspace 
        
        for _, v in ipairs(mobFolder:GetChildren()) do
            if v:FindFirstChild("Humanoid") and not seen[v.Name] then
                table.insert(list, v.Name)
                seen[v.Name] = true
            end
        end
        table.sort(list)
        if #list == 0 then table.insert(list, "No Mobs Found (Check Folder Path)") end
        MobDropdown:Refresh(list, true)
    end
})

-- 6. Logic Engine
local RunService = game:GetService("RunService")
local player = game.Players.LocalPlayer
local VirtualInputManager = game:GetService("VirtualInputManager")

-- [SMART TARGET FINDER]
local function GetSmartTarget()
    if not Flags.SmartFarm then return nil end
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    
    local bestTarget = nil
    local shortestDist = 999999
    
    -- [USER TODO]: Update this folder path!
    local mobFolder = workspace:FindFirstChild("Mobs") or workspace 

    for _, mob in ipairs(mobFolder:GetDescendants()) do
        if mob:IsA("Model") and mob:FindFirstChild("Humanoid") and mob:FindFirstChild("HumanoidRootPart") then
             if mob.Humanoid.Health > 0 and Flags.SelectedMobs and Flags.SelectedMobs[mob.Name] then
                 local dist = (mob.HumanoidRootPart.Position - myRoot.Position).Magnitude
                 if dist < shortestDist then
                     shortestDist = dist
                     bestTarget = mob
                 end
             end
        end
    end
    return bestTarget
end

-- [MOVEMENT & ATTACK LOOP]
RunService.Heartbeat:Connect(function()
    if Flags.SmartFarm then
        local target = GetSmartTarget()
        if target and target:FindFirstChild("HumanoidRootPart") then
            -- 1. Teleport Behind
            local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if myRoot then
                myRoot.CFrame = target.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4) -- 4 studs behind
                myRoot.Velocity = Vector3.new(0,0,0) -- Stabilize
            end
            
            -- 2. Attack Logic
            pcall(function()
                -- [USER TODO]: Update this Remote!
                 local Remote = game.ReplicatedStorage:FindFirstChild("AttackRemote_PLACEHOLDER") 
                 if Remote then 
                     Remote:FireServer() 
                 else
                     -- Fallback Click
                     VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                     VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                 end
            end)
        end
    end
end)

ANUI:Notify({Title = "Nebublox", Content = "Anime Destroyers Loaded!", Icon = "check", Duration = 5})
