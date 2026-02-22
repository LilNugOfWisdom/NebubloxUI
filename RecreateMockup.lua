local success, Nebublox = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/LilNugOfWisdom/NebubloxUI/main/NebubloxUI.lua"))()
end)

if not success then
    warn("Nebublox Ultimate Load Error: " .. tostring(Nebublox))
    return
end

Nebublox:IgniteKillSwitch()

-- ═══════════════════════════════════════
--  ULTIMATE MOCKUP RECONSTRUCTION
-- ═══════════════════════════════════════
local Window = Nebublox:MakeWindow({
    Title = "NEBUBLOX ULTIMATE v1.3.0",
    Size = UDim2.new(0, 680, 0, 480),
    Background = {
        Image = "rbxassetid://1331823772", -- Premium Nebula Asset
        Transparency = 0.8,
        Tint = Color3.fromRGB(0, 255, 255), -- Matching cyan glow
        Blur = true
    },
    GalaxyBackground = true,
    Profile = {
        Title = "Nebublox",
        Desc = "Ultimate Edition",
        Image = "rbxassetid://15266858296" -- High-end avatar circle
    }
})

-- Sidebar Navigation
local HomeTab = Window:AddTab({Name = "Home", Icon = "rbxassetid://11419713314"})
local FeatureTab = Window:AddTab({Name = "Game Features", Icon = "rbxassetid://11419717444"})
local ExploitTab = Window:AddTab({Name = "Exploits", Icon = "rbxassetid://11419715317"})
local ConfigTab = Window:AddTab({Name = "Configuration", Icon = "rbxassetid://11419719547"})

-- ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
--  HOME TAB: Premium Dashboard
-- ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
local MainRow = HomeTab:AddRow({Columns = 2})
local LeftCol = MainRow[1]
local RightCol = MainRow[2]

LeftCol:AddProfileCard({
    Title = "Welcome, " .. game.Players.LocalPlayer.Name,
    Desc = "Status: Premium User",
    Image = "rbxthumb://type=AvatarHeadShot&id="..game.Players.LocalPlayer.UserId.."&w=150&h=150",
    Status = "ready"
})

LeftCol:AddButton({
    Name = "Execute Main Script",
    Subtitle = "Launch all active features",
    Icon = "rbxassetid://11422155630",
    Callback = function() end
})

-- 3D Viewport in Right Column
RightCol:Add3DViewport({
    Name = "Character Preview",
    Model = game.Players.LocalPlayer.Character
})

-- ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
--  FEATURE TAB: Grid Layout
-- ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
local Grid = FeatureTab:AddRow({Columns = 2})
local Act = Grid[1]
local Stats = Grid[2]

Act:AddToggle({Name = "Auto Farm", Default = false, Callback = function() end})
Act:AddToggle({Name = "Killaura", Default = false, Callback = function() end})

local graph = Stats:AddLineGraph({Name = "Server Performance", MaxPoints = 30})
task.spawn(function()
    while task.wait(1) do
        graph:AddPoint(math.random(40, 60))
    end
end)

Window:SelectTab(HomeTab)
Window:Notify({
    Title = "Nebublox Reconstructed",
    Content = "The aesthetic overhaul is complete. Welcome home.",
    Type = "success"
})
