--[[
    Nebublox UI Library - Starter Script
    A premium, high-performance UI library for Roblox Script Hubs
    Featuring Glassmorphism, smooth animations, and advanced components
    
    Created by: Nebublox
]]

-- ============================================
-- STEP 1: INSTALLATION
-- Load the Nebublox UI Library
-- ============================================
local UILib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Gamr46/NebubloxUI/main/nebublox_ui.lua"))()

-- ============================================
-- STEP 2: CREATE WINDOW
-- Main container for your script hub
-- ============================================
local Window = UILib:CreateWindow({
    Title = "Nebublox Hub",                -- Window title
    Author = "by Nebublox",                -- Author credit
    Folder = "NebubloxHub",                -- Save folder name
    Icon = "rbxassetid://0",              -- Window icon (replace with your own)
    IconSize = 44,                        -- Icon size in pixels
    Theme = "Dark",                       -- Theme: "Dark" or "Light"
    Transparent = false,                  -- Enable glass effect
    SideBarWidth = 200,                   -- Sidebar width
    HasOutline = true,                    -- Show window outline
    
    -- Optional: Key System (uncomment to enable)
    --[[
    KeySystem = {
        Title = "Key System",
        Note = "Join Discord to get key",
        SaveKey = true,
        Key = { "YOUR-KEY-HERE", "BACKUP-KEY" }, -- Simple keys
        -- OR use API (Luarmor Example):
        -- API = {
        --     { Type = "luarmor", ScriptId = "your_script_id", Discord = "https://discord.gg/..." }
        -- }
    }
    ]]
})

-- ============================================
-- STEP 3: PROFILE SETUP (Optional)
-- Create a reusable profile configuration
-- ============================================
local function MakeProfile(overrides)
    local profile = {
        Banner = "https://example.com/banner.png", -- Your banner URL
        Avatar = "rbxassetid://0",                  -- Your avatar asset
        Status = true,                              -- Online status dot
        Badges = {
            {
                Icon = "geist:logo-discord",        -- Lucide icon name
                Title = "Discord",
                Desc = "Join our server",           -- Tooltip text
                Callback = function()
                    setclipboard("discord.gg/yourserver")
                    UILib:Notify({
                        Title = "Copied!",
                        Content = "Discord invite copied to clipboard",
                        Icon = "copy",
                        Duration = 3
                    })
                end
            },
            {
                Icon = "geist:logo-github",
                Title = "GitHub",
                Desc = "View source code",
                Callback = function()
                    setclipboard("github.com/yourrepo")
                end
            }
        }
    }
    
    -- Merge overrides
    for k, v in pairs(overrides or {}) do
        profile[k] = v
    end
    
    return profile
end

-- ============================================
-- STEP 4: CREATE TABS
-- Navigation categories in the sidebar
-- ============================================

-- Main Tab (with profile)
local MainTab = Window:Tab({
    Title = "Main",
    Icon = "home",
    Profile = MakeProfile({
        Title = "Nebublox",
        Desc = "Premium User"
    }),
    SidebarProfile = true -- Show profile card in sidebar
})

-- Combat Tab
local CombatTab = Window:Tab({
    Title = "Combat",
    Icon = "swords",
    SidebarProfile = false
})

-- Player Tab
local PlayerTab = Window:Tab({
    Title = "Player",
    Icon = "user",
    SidebarProfile = false
})

-- Settings Tab
local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings",
    SidebarProfile = false
})

-- ============================================
-- STEP 5: CREATE SECTIONS
-- Collapsible containers to group elements
-- ============================================

-- Main Tab Sections
local InfoSection = MainTab:Section({
    Title = "Information",
    Icon = "info",
    Opened = true
})

-- Combat Tab Sections
local WeaponSection = CombatTab:Section({
    Title = "Weapon Settings",
    Icon = "sword",
    Opened = true
})

local AuraSection = CombatTab:Section({
    Title = "Aura Settings",
    Icon = "circle-dot",
    Opened = false
})

-- Player Tab Sections
local MovementSection = PlayerTab:Section({
    Title = "Movement",
    Icon = "footprints",
    Opened = true
})

local CharacterSection = PlayerTab:Section({
    Title = "Character",
    Icon = "user-cog",
    Opened = true
})

-- Settings Tab Sections
local ConfigSection = SettingsTab:Section({
    Title = "Configuration",
    Icon = "save",
    Opened = true
})

-- ============================================
-- STEP 6: ADD UI ELEMENTS
-- Buttons, Toggles, Sliders, Inputs, etc.
-- ============================================

-- === BUTTONS ===
InfoSection:Button({
    Title = "Welcome!",
    Desc = "Click to view info",
    Icon = "star",
    Callback = function()
        UILib:Notify({
            Title = "Welcome!",
            Content = "Thanks for using Nebublox Hub!",
            Icon = "heart",
            Duration = 5
        })
    end
})

WeaponSection:Button({
    Title = "Kill Aura",
    Desc = "Attack nearby enemies",
    Icon = "swords",
    Callback = function()
        print("Kill Aura activated!")
    end
})

-- === TOGGLES ===
AuraSection:Toggle({
    Title = "Auto Farm",
    Value = false,
    Type = "Toggle", -- or "Checkbox"
    Callback = function(state)
        print("Auto Farm:", state)
    end
})

AuraSection:Toggle({
    Title = "Silent Aim",
    Value = false,
    Type = "Checkbox",
    Callback = function(state)
        print("Silent Aim:", state)
    end
})

-- === SLIDERS ===
MovementSection:Slider({
    Title = "WalkSpeed",
    Value = {
        Min = 16,
        Max = 200,
        Default = 16
    },
    Step = 1,
    Callback = function(val)
        local player = game.Players.LocalPlayer
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.WalkSpeed = val
        end
    end
})

MovementSection:Slider({
    Title = "JumpPower",
    Value = {
        Min = 50,
        Max = 500,
        Default = 50
    },
    Step = 5,
    Callback = function(val)
        local player = game.Players.LocalPlayer
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.JumpPower = val
        end
    end
})

-- === INPUTS ===
CharacterSection:Input({
    Title = "Target Name",
    Placeholder = "Enter username...",
    ClearTextOnFocus = true,
    Callback = function(text)
        print("Target set to:", text)
    end
})

-- === DROPDOWNS ===
WeaponSection:Dropdown({
    Title = "Select Weapon",
    Values = {
        { Title = "Sword", Icon = "sword" },
        { Title = "Bow", Icon = "crosshair" },
        { Title = "Staff", Icon = "wand" },
        { Title = "Axe", Icon = "axe" },
    },
    Value = "Sword",
    Multi = false,
    SearchBarEnabled = true,
    Callback = function(val)
        print("Selected weapon:", val.Title)
    end
})

-- Multi-select dropdown example
CharacterSection:Dropdown({
    Title = "Select Effects",
    Values = {
        { Title = "Speed Boost", Icon = "zap" },
        { Title = "Shield", Icon = "shield" },
        { Title = "Invisibility", Icon = "eye-off" },
    },
    Multi = true,
    SearchBarEnabled = false,
    Callback = function(selected)
        print("Selected effects:")
        for _, effect in pairs(selected) do
            print("  -", effect.Title)
        end
    end
})

-- === CONFIG BUTTONS ===
ConfigSection:Button({
    Title = "Save Config",
    Desc = "Save current settings",
    Icon = "save",
    Callback = function()
        -- Add your save logic here
        UILib:Notify({
            Title = "Saved!",
            Content = "Configuration saved successfully",
            Icon = "check",
            Duration = 3
        })
    end
})

ConfigSection:Button({
    Title = "Load Config",
    Desc = "Load saved settings",
    Icon = "folder-open",
    Callback = function()
        -- Add your load logic here
        UILib:Notify({
            Title = "Loaded!",
            Content = "Configuration loaded successfully",
            Icon = "check",
            Duration = 3
        })
    end
})

ConfigSection:Button({
    Title = "Reset Config",
    Desc = "Reset to default settings",
    Icon = "refresh-cw",
    Callback = function()
        -- Add your reset logic here
        UILib:Notify({
            Title = "Reset!",
            Content = "Configuration reset to defaults",
            Icon = "refresh-cw",
            Duration = 3
        })
    end
})

-- ============================================
-- STEP 7: NOTIFICATIONS
-- Show alerts or info messages
-- ============================================
UILib:Notify({
    Title = "Script Loaded!",
    Content = "Nebublox Hub initialized successfully",
    Icon = "rocket",
    Duration = 5
})

-- ============================================
-- STEP 8: VIDEO EMBEDDING (Optional)
-- Embed webm videos directly into the UI
-- ============================================
--[[
MainTab:Video({
    Video = "https://example.com/showcase.webm",
    AspectRatio = "16:9",
    Radius = 12
})
]]

print("Nebublox Hub loaded successfully!")
