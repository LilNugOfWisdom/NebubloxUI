# Nebublox UI Library

**Theme: DarkMatterV1** — Deep Purple × Neon Cyan

A premium, flexible Roblox UI framework built from scratch. Designed for script developers who want a massive variety of elements, automatic image/decal support, and a stunning dark aesthetic.

---

## Quick Start

```lua
local Nebublox = loadstring(game:HttpGet("YOUR_RAW_URL"))()

local Window  = Nebublox:MakeWindow({ Title = "My Hub" })
local Tab     = Window:MakeTab({ Name = "Main", Icon = "home" })
local Section = Tab:MakeSection({ Name = "Actions" })

Section:AddButton({ Name = "Click Me", Callback = function() print("Hello!") end })
```

---

## Architecture

```
Nebublox:MakeWindow()
  └─ Window:MakeTab()
       └─ Tab:MakeSection()
            └─ Section:AddButton()
            └─ Section:AddToggle()
            └─ Section:AddSlider()
            └─ Section:AddDropdown()
            └─ Section:AddMultiDropdown()
            └─ Section:AddKeybind()
            └─ Section:AddTextbox()
            └─ Section:AddImageDisplay()
            └─ Section:AddLabel()
            └─ Section:AddParagraph()
            └─ Section:AddConsole()
```

---

## Elements Reference

| Element | Key Config | Returns |
|---|---|---|
| `AddButton` | `Name, Description, Callback` | Instance |
| `AddToggle` | `Name, Default, Callback` | `api:Set(bool)`, `api:Get()` |
| `AddSlider` | `Name, Min, Max, Default, Increment, Callback` | `api:Set(n)`, `api:Get()` |
| `AddDropdown` | `Name, Options, Default, Callback` | `api:Set(v)`, `api:Get()`, `api:Refresh(opts)` |
| `AddMultiDropdown` | `Name, Options, Defaults, Callback` | `api:Get()` → table |
| `AddKeybind` | `Name, Default, Callback` | `api:Set(key)`, `api:Get()` |
| `AddTextbox` | `Name, Placeholder, Default, ClearOnFocus, Callback` | `api:Set(s)`, `api:Get()` |
| `AddImageDisplay` | `Name, Image/Id, Size` | `api:SetImage(id)` |
| `AddLabel` | `Text, Color` | `api:Set(text)` |
| `AddParagraph` | `Title, Content` | `api:Set(text)` |
| `AddConsole` | `Name, Height, MaxLines` | `api:Log(text,color)`, `:Clear()`, `:Success()`, `:Error()`, `:Warn()` |

---

## System Features

### 🔑 Key System
```lua
local key = Nebublox:KeySystem({
    Title = "My Hub",
    Keys  = { "key123", "vip456" },
    Link  = "discord.gg/myhub"
})
key.Await() -- blocks until verified
```

### 🔔 Notifications
```lua
Window:Notify({
    Title    = "Success!",
    Content  = "Auto farm enabled.",
    Type     = "success",  -- info | success | error | warning
    Duration = 4
})
```

### 💾 Config Save/Load
```lua
Nebublox:SaveConfig("my_hub", { speed = 100, autoFarm = true })
local cfg = Nebublox:LoadConfig("my_hub")
```

### 🖥️ Watermark HUD
```lua
Nebublox:MakeWatermark({ Text = "My Hub v1.0" })
-- Shows: "My Hub v1.0 | 60 FPS | 42ms | 03:15 PM"
```

### ⌨️ UI Toggle
Press `RightControl` to hide/show (configurable via `ToggleKey`).

### 🧹 Unload / Destroy
```lua
Nebublox:Destroy()  -- or Nebublox:Unload()
-- Severs ALL connections, removes ALL UI and blur
```

---

## Image & Decal Support

The library **automatically resolves** any Roblox asset format:

```lua
Section:AddImageDisplay({ Image = 12345678 })          -- raw number
Section:AddImageDisplay({ Image = "rbxassetid://123" }) -- string format
Section:AddImageDisplay({ Image = "12345678" })         -- string number
```

All inputs are routed through `rbxthumb://type=Asset&id=X&w=420&h=420` to safely handle both direct image IDs *and* decal IDs without 403 errors.

---

## Built-in Icons

Use plain English names instead of hunting for asset IDs:

```lua
Window:MakeTab({ Name = "Combat", Icon = "sword" })
Window:MakeTab({ Name = "Home",   Icon = "home" })
```

Available: `home`, `settings`, `sword`, `shield`, `star`, `heart`, `user`, `search`, `eye`, `lock`, `check`, `x`, `plus`, `minus`, `refresh`, `zap`, `target`, `flag`, `info`, `warning`, `terminal`, `code`, `gamepad`, `map`, `package`, `gift`

---

## Theme: DarkMatterV1

| Token | Color |
|---|---|
| Background | `rgb(10, 4, 22)` |
| Surface | `rgb(20, 10, 40)` |
| Accent (Cyan) | `rgb(0, 235, 255)` |
| Purple | `rgb(120, 45, 185)` |
| Text | `rgb(228, 228, 250)` |
| Border | `rgb(55, 28, 95)` |

Override any token:
```lua
Nebublox:SetTheme({ Accent = Color3.fromRGB(255, 0, 128) })
```
