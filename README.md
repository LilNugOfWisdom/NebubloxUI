# Nebublox UI Library

<div align="center">

```
    _   __     __          __    __          
   / | / /__  / /_  __  __/ /_  / /___  _  __
  /  |/ / _ \/ __ \/ / / / __ \/ / __ \| |/_/
 / /|  /  __/ /_/ / /_/ / /_/ / / /_/ />  <  
/_/ |_/\___/_.___/\__,_/_.___/_/\____/_/|_|  
```

**A premium, high-performance UI library for Roblox Script Hubs**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Discord](https://img.shields.io/discord/YOUR_SERVER_ID?color=5865F2&label=Discord&logo=discord&logoColor=white)](https://discord.gg/nebublox)

</div>

---

## âœ¨ Features

- ðŸŽ¨ **Glassmorphism Design** - Modern, sleek UI with blur effects
- âš¡ **High Performance** - Optimized for smooth animations
- ðŸŽ¯ **Easy to Use** - Simple API for rapid development
- ðŸŒˆ **Theming Support** - Dark/Light themes with custom colors
- ðŸ“± **Responsive** - Works on all screen sizes
- ðŸ”’ **Key System** - Built-in support for Luarmor, Platoboost, Panda

## ðŸ“¦ Installation

```lua
local NebubloxUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Gamr46/NebubloxUI/main/nebublox_ui.lua"))()
```

## ðŸš€ Quick Start

```lua
-- Load the library
local NebubloxUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Gamr46/NebubloxUI/main/nebublox_ui.lua"))()

-- Create a window
local Window = NebubloxUI:CreateWindow({
    Title = "My Script Hub",
    Author = "by YourName",
    Folder = "MyHub",
    Theme = "Dark",
})

-- Create a tab
local MainTab = Window:Tab({
    Title = "Main",
    Icon = "home",
})

-- Create a section
local Section = MainTab:Section({
    Title = "Features",
    Icon = "star",
    Opened = true,
})

-- Add elements
Section:Button({
    Title = "Click Me",
    Desc = "A simple button",
    Icon = "mouse-pointer",
    Callback = function()
        print("Button clicked!")
    end
})

Section:Toggle({
    Title = "Auto Farm",
    Value = false,
    Callback = function(state)
        print("Toggle:", state)
    end
})

Section:Slider({
    Title = "WalkSpeed",
    Value = { Min = 16, Max = 200, Default = 16 },
    Callback = function(val)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = val
    end
})
```

## ðŸ“š Components

| Component | Description |
|-----------|-------------|
| **Window** | Main container with themes and key system |
| **Tab** | Navigation categories in sidebar |
| **Section** | Collapsible containers for elements |
| **Button** | Clickable actions |
| **Toggle** | Switch/Checkbox for booleans |
| **Slider** | Numeric value selector |
| **Input** | Text input fields |
| **Dropdown** | Selection menus with search |
| **ColorPicker** | Color selection |
| **Keybind** | Keyboard shortcut binding |
| **Notify** | Alert/notification system |
| **Dialog** | Modal dialogs |

## ðŸŽ¨ Themes

```lua
-- Built-in themes
Theme = "Dark"   -- Dark mode
Theme = "Light"  -- Light mode

-- Glass effect
Transparent = true
```

## ðŸ”’ Key System

```lua
local Window = NebubloxUI:CreateWindow({
    Title = "My Hub",
    KeySystem = {
        Title = "Key System",
        Note = "Get your key from our Discord",
        SaveKey = true,
        Key = { "KEY-123", "KEY-456" },
    }
})
```

## ðŸ¤ Contributing

Contributions are welcome! Feel free to submit issues and pull requests.

## ðŸ“„ License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ðŸ’¬ Support

- **Discord:** [discord.gg/nebublox](https://discord.gg/nebublox)
- **GitHub Issues:** [Create an issue](https://github.com/Gamr46/NebubloxUI/issues)

---

<div align="center">
Made with â¤ï¸ by <b>Nebublox</b>
</div>

