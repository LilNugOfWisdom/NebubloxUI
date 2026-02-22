--[[
    ╔═══════════════════════════════════════════════╗
    ║         NEBUBLOX UI LIBRARY v1.0              ║
    ║   A premium, flexible Roblox UI framework     ║
    ║   Deep Purple × Neon Cyan Aesthetic           ║
    ╚═══════════════════════════════════════════════╝
    
    Usage:
        local Nebublox = loadstring(...)()
        local Window = Nebublox:MakeWindow({ Title = "My Hub" })
        local Tab = Window:MakeTab({ Name = "Main", Icon = "rbxassetid://123" })
        local Section = Tab:MakeSection({ Name = "Actions" })
        Section:AddButton({ Name = "Click Me", Callback = function() print("Hi") end })
]]

-- ═══════════════════════════════════════
--  SERVICES
-- ═══════════════════════════════════════
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")
local Lighting         = game:GetService("Lighting")
local Stats            = game:GetService("Stats")
local LocalPlayer      = Players.LocalPlayer

-- Global connection tracker for clean unload
local _connections = {}

-- ═══════════════════════════════════════
--  THEME : DarkMatterV1
-- ═══════════════════════════════════════
local Theme = {
    _name         = "NebubloxUltima",
    Background    = Color3.fromRGB(8, 4, 18),
    Surface       = Color3.fromRGB(16, 10, 32),
    SurfaceLight  = Color3.fromRGB(24, 14, 48),
    Accent        = Color3.fromRGB(0, 255, 255), -- Pure Neon Cyan
    AccentDim     = Color3.fromRGB(0, 180, 200),
    Purple        = Color3.fromRGB(160, 60, 255), -- Vibrant Electric Purple
    PurpleGlow    = Color3.fromRGB(200, 100, 255),
    Text          = Color3.fromRGB(245, 245, 255),
    TextDim       = Color3.fromRGB(150, 140, 180),
    Border        = Color3.fromRGB(70, 40, 120),
    Success       = Color3.fromRGB(0, 255, 140),
    Error         = Color3.fromRGB(255, 55, 100),
    Font          = Enum.Font.GothamBold,
    FontBody      = Enum.Font.Gotham,
    Corner        = UDim.new(0, 10), -- Slightly rounder for modern look
    CornerSmall   = UDim.new(0, 7),
    CornerPill    = UDim.new(1, 0),
    Warning       = Color3.fromRGB(255, 200, 50),
}

-- ═══════════════════════════════════════
--  UTILITIES
-- ═══════════════════════════════════════

--- Safely resolves any Roblox asset input into a renderable image string.
--- Handles raw numeric IDs, rbxassetid:// strings, and decal IDs
--- by routing through rbxthumb:// to avoid 403 errors.
local function resolveImage(input)
    if not input then return "" end
    if type(input) == "number" then
        return ("rbxthumb://type=Asset&id=%d&w=420&h=420"):format(input)
    end
    local s = tostring(input)
    if s:match("^rbxthumb://") then return s end
    local id = s:match("(%d+)")
    if id then
        return ("rbxthumb://type=Asset&id=%s&w=420&h=420"):format(id)
    end
    return s -- fallback (http urls, etc.)
end

local function tween(obj, props, dur, style, dir)
    local t = TweenService:Create(obj,
        TweenInfo.new(dur or 0.25, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
        props)
    t:Play()
    return t
end

local function corner(obj, r)
    local c = Instance.new("UICorner"); c.CornerRadius = r or Theme.Corner; c.Parent = obj; return c
end

local function stroke(obj, col, thick, trans)
    local s = Instance.new("UIStroke")
    s.Color = col or Theme.Border; s.Thickness = thick or 1; s.Transparency = trans or 0.5
    s.Parent = obj; return s
end

local function pad(obj, t, b, l, r)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, t or 8); p.PaddingBottom = UDim.new(0, b or 8)
    p.PaddingLeft = UDim.new(0, l or 10); p.PaddingRight = UDim.new(0, r or 10)
    p.Parent = obj; return p
end

local function listLayout(obj, spacing)
    local l = Instance.new("UIListLayout")
    l.SortOrder = Enum.SortOrder.LayoutOrder; l.Padding = UDim.new(0, spacing or 4)
    l.Parent = obj; return l
end

local function track(conn)
    table.insert(_connections, conn); return conn
end

-- ═══════════════════════════════════════
--  BUILT-IN ICON LIBRARY
-- ═══════════════════════════════════════
local Icons = {
    home = "rbxassetid://7733960981", settings = "rbxassetid://7734053495",
    sword = "rbxassetid://7733717857", shield = "rbxassetid://7733680589",
    star = "rbxassetid://7733658504", heart = "rbxassetid://7733715400",
    user = "rbxassetid://7733756006", users = "rbxassetid://7733756006",
    search = "rbxassetid://7734042083", eye = "rbxassetid://7733685814",
    lock = "rbxassetid://7733717857", unlock = "rbxassetid://7733717857",
    check = "rbxassetid://7733658504", x = "rbxassetid://7743876156",
    plus = "rbxassetid://7743876446", minus = "rbxassetid://7743876312",
    refresh = "rbxassetid://7734042083", zap = "rbxassetid://7733658504",
    target = "rbxassetid://7733658504", flag = "rbxassetid://7733658504",
    info = "rbxassetid://7733715400", warning = "rbxassetid://7733658504",
    terminal = "rbxassetid://7734053495", code = "rbxassetid://7734053495",
    gamepad = "rbxassetid://7733960981", map = "rbxassetid://7733960981",
    package = "rbxassetid://7733960981", gift = "rbxassetid://7733960981",
}

local function resolveIcon(input)
    if not input then return "" end
    if type(input) == "string" and Icons[input:lower()] then
        return Icons[input:lower()]
    end
    return resolveImage(input)
end

-- ═══════════════════════════════════════
--  FORWARD DECLARATIONS
-- ═══════════════════════════════════════
local Section = {}; Section.__index = Section
local Tab     = {}; Tab.__index = Tab
local Window  = {}; Window.__index = Window

-- ═══════════════════════════════════════
--  SECTION : ELEMENTS
-- ═══════════════════════════════════════

function Section:NextZ()
    self._z = (self._z or 1000) - 5
    return self._z
end

function Section:AddButton(cfg)
    cfg = cfg or {}
    local name = cfg.Name or "Button"
    local cb   = cfg.Callback or function() end
    local desc = cfg.Description
    local icon = cfg.Icon

    local isUltra = (icon ~= nil)
    local height = isUltra and 56 or (desc and 46 or 32)

    local btn = Instance.new("TextButton")
    btn.Name = "Btn_"..name; btn.Size = UDim2.new(1,0,0, height)
    btn.BackgroundColor3 = isUltra and Theme.SurfaceLight or Theme.Purple
    btn.BackgroundTransparency = isUltra and 0 or 0.6
    btn.ZIndex = self:NextZ()
    btn.Text = ""; btn.BorderSizePixel = 0; btn.Parent = self.Container
    corner(btn, Theme.CornerSmall)
    if isUltra then stroke(btn, Theme.Accent, 1, 0.4) end

    if self.Window and cfg.Tooltip then self.Window.TrackTooltip(btn, cfg.Tooltip) end

    if isUltra then
        local img = Instance.new("ImageLabel"); img.Size = UDim2.new(0,28,0,28)
        img.Position = UDim2.new(0,14,0.5,0); img.AnchorPoint = Vector2.new(0,0.5)
        img.BackgroundTransparency = 1; img.Image = resolveIcon(icon)
        img.ImageColor3 = Theme.Accent; img.Parent = btn; img.ZIndex = btn.ZIndex + 1

        local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1,-60,0,20)
        lbl.Position = UDim2.new(0,54,0,10); lbl.BackgroundTransparency = 1
        lbl.Text = name; lbl.TextColor3 = Theme.Text; lbl.TextSize = 14
        lbl.Font = Theme.Font; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = btn
        lbl.ZIndex = btn.ZIndex + 1

        if desc then
            local d = Instance.new("TextLabel"); d.Size = UDim2.new(1,-60,0,16)
            d.Position = UDim2.new(0,54,0,30); d.BackgroundTransparency = 1
            d.Text = desc; d.TextColor3 = Theme.TextDim; d.TextSize = 11
            d.Font = Theme.FontBody; d.TextXAlignment = Enum.TextXAlignment.Left; d.Parent = btn
            d.ZIndex = btn.ZIndex + 1
        end
    else
        local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1,-16,0, desc and 20 or 32)
        lbl.Position = UDim2.new(0,10,0, desc and 4 or 0); lbl.BackgroundTransparency = 1
        lbl.Text = name; lbl.TextColor3 = Theme.Text; lbl.TextSize = 13
        lbl.Font = Theme.FontBody; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = btn
        lbl.ZIndex = btn.ZIndex + 1

        if desc then
            local d = Instance.new("TextLabel"); d.Size = UDim2.new(1,-16,0,16)
            d.Position = UDim2.new(0,10,0,24); d.BackgroundTransparency = 1
            d.Text = desc; d.TextColor3 = Theme.TextDim; d.TextSize = 11
            d.Font = Theme.FontBody; d.TextXAlignment = Enum.TextXAlignment.Left; d.Parent = btn
            d.ZIndex = btn.ZIndex + 1
        end
    end

    btn.MouseEnter:Connect(function() tween(btn, {BackgroundTransparency = isUltra and 0.15 or 0.3}, 0.15) end)
    btn.MouseLeave:Connect(function() tween(btn, {BackgroundTransparency = isUltra and 0 or 0.6}, 0.15) end)
    btn.MouseButton1Click:Connect(function()
        tween(btn, {BackgroundColor3 = Theme.Accent}, 0.08)
        task.delay(0.12, function() tween(btn, {BackgroundColor3 = isUltra and Theme.SurfaceLight or Theme.Purple}, 0.2) end)
        pcall(cb)
    end)
    return btn
end

function Section:AddToggle(cfg)
    cfg = cfg or {}
    local name = cfg.Name or "Toggle"
    local state = cfg.Default or false
    local cb = cfg.Callback or function() end

    local f = Instance.new("Frame"); f.Name = "Tog_"..name; f.Size = UDim2.new(1,0,0,32)
    f.BackgroundColor3 = Theme.Surface; f.BackgroundTransparency = 0.4
    f.BorderSizePixel = 0; f.Parent = self.Container; corner(f, Theme.CornerSmall)

    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1,-60,1,0)
    lbl.Position = UDim2.new(0,10,0,0); lbl.BackgroundTransparency = 1
    lbl.Text = name; lbl.TextColor3 = Theme.Text; lbl.TextSize = 13
    lbl.Font = Theme.FontBody; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f
    if self.Window and cfg.Tooltip then self.Window.TrackTooltip(lbl, cfg.Tooltip) end

    local sw = Instance.new("TextButton"); sw.Size = UDim2.new(0,40,0,20)
    sw.Position = UDim2.new(1,-50,0.5,0); sw.AnchorPoint = Vector2.new(0,0.5)
    sw.BackgroundColor3 = state and Theme.Accent or Theme.Border
    sw.Text = ""; sw.BorderSizePixel = 0; sw.Parent = f; corner(sw, Theme.CornerPill)

    local knob = Instance.new("Frame"); knob.Size = UDim2.new(0,16,0,16)
    knob.Position = state and UDim2.new(1,-18,0.5,0) or UDim2.new(0,2,0.5,0)
    knob.AnchorPoint = Vector2.new(0,0.5); knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel = 0; knob.Parent = sw; corner(knob, Theme.CornerPill)

    local function upd()
        tween(sw, {BackgroundColor3 = state and Theme.Accent or Theme.Border}, 0.2)
        tween(knob, {Position = state and UDim2.new(1,-18,0.5,0) or UDim2.new(0,2,0.5,0)}, 0.2)
    end
    sw.MouseButton1Click:Connect(function() state = not state; upd(); pcall(cb, state) end)

    local api = {}
    function api:Set(v) state = v; upd(); pcall(cb, state) end
    function api:Get() return state end
    return api
end

function Section:AddSlider(cfg)
    cfg = cfg or {}
    local name = cfg.Name or "Slider"
    local mn, mx = cfg.Min or 0, cfg.Max or 100
    local inc = cfg.Increment or 1
    local cb = cfg.Callback or function() end
    local val = math.clamp(cfg.Default or mn, mn, mx)

    local f = Instance.new("Frame"); f.Name = "Sld_"..name; f.Size = UDim2.new(1,0,0,50)
    f.BackgroundColor3 = Theme.Surface; f.BackgroundTransparency = 0.4
    f.BorderSizePixel = 0; f.Parent = self.Container; corner(f, Theme.CornerSmall)

    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1,-60,0,20)
    lbl.Position = UDim2.new(0,10,0,4); lbl.BackgroundTransparency = 1
    lbl.Text = name; lbl.TextColor3 = Theme.Text; lbl.TextSize = 13
    lbl.Font = Theme.FontBody; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f
    if self.Window and cfg.Tooltip then self.Window.TrackTooltip(lbl, cfg.Tooltip) end

    local vLbl = Instance.new("TextLabel"); vLbl.Size = UDim2.new(0,50,0,20)
    vLbl.Position = UDim2.new(1,-56,0,4); vLbl.BackgroundTransparency = 1
    vLbl.Text = tostring(val); vLbl.TextColor3 = Theme.Accent; vLbl.TextSize = 13
    vLbl.Font = Theme.Font; vLbl.TextXAlignment = Enum.TextXAlignment.Right; vLbl.Parent = f

    local track = Instance.new("Frame"); track.Name = "Track"
    track.Size = UDim2.new(1,-20,0,6); track.Position = UDim2.new(0,10,0,32)
    track.BackgroundColor3 = Theme.Border; track.BorderSizePixel = 0; track.Parent = f
    corner(track, Theme.CornerPill)

    local fill = Instance.new("Frame"); fill.Size = UDim2.new((val-mn)/(mx-mn),0,1,0)
    fill.BackgroundColor3 = Theme.Accent; fill.BorderSizePixel = 0; fill.Parent = track
    corner(fill, Theme.CornerPill)

    local sk = Instance.new("Frame"); sk.Size = UDim2.new(0,14,0,14)
    sk.Position = UDim2.new((val-mn)/(mx-mn),0,0.5,0); sk.AnchorPoint = Vector2.new(0.5,0.5)
    sk.BackgroundColor3 = Theme.Accent; sk.BorderSizePixel = 0; sk.ZIndex = 2
    sk.Parent = track; corner(sk, Theme.CornerPill); stroke(sk, Theme.Background, 2, 0)

    local sliding = false
    local function updSlider(input)
        local p = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        val = mn + (mx-mn)*p
        if inc > 0 then val = math.floor(val/inc+0.5)*inc end
        val = math.clamp(val, mn, mx)
        local n = (val-mn)/(mx-mn)
        fill.Size = UDim2.new(n,0,1,0); sk.Position = UDim2.new(n,0,0.5,0)
        vLbl.Text = tostring(val); pcall(cb, val)
    end

    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            sliding = true; updSlider(i)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            updSlider(i)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sliding = false end
    end)

    local api = {}
    function api:Set(v)
        val = math.clamp(v, mn, mx); local n = (val-mn)/(mx-mn)
        fill.Size = UDim2.new(n,0,1,0); sk.Position = UDim2.new(n,0,0.5,0)
        vLbl.Text = tostring(val); pcall(cb, val)
    end
    function api:Get() return val end
    return api
end

function Section:AddDropdown(cfg)
    cfg = cfg or {}
    local name = cfg.Name or "Dropdown"
    local options = cfg.Options or {}
    local default = cfg.Default or (options[1] or "")
    local cb = cfg.Callback or function() end
    local selected = default; local open = false

    local f = Instance.new("Frame"); f.Name = "Dd_"..name; f.Size = UDim2.new(1,0,0,32)
    f.AutomaticSize = Enum.AutomaticSize.Y; f.BackgroundColor3 = Theme.Surface
    f.BackgroundTransparency = 0.4; f.BorderSizePixel = 0; f.ClipsDescendants = true
    f.ZIndex = self:NextZ()
    f.Parent = self.Container; corner(f, Theme.CornerSmall)

    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(0.5,-8,0,32)
    lbl.Position = UDim2.new(0,10,0,0); lbl.BackgroundTransparency = 1
    lbl.Text = name; lbl.TextColor3 = Theme.Text; lbl.TextSize = 13
    lbl.Font = Theme.FontBody; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f

    local valBtn = Instance.new("TextButton"); valBtn.Size = UDim2.new(0.5,-8,0,28)
    valBtn.Position = UDim2.new(0.5,0,0,2); valBtn.BackgroundColor3 = Theme.SurfaceLight
    valBtn.Text = "  "..tostring(selected).."  ▾"; valBtn.TextColor3 = Theme.Accent
    valBtn.TextSize = 12; valBtn.Font = Theme.FontBody; valBtn.BorderSizePixel = 0
    valBtn.TextXAlignment = Enum.TextXAlignment.Right; valBtn.Parent = f
    corner(valBtn, Theme.CornerSmall)

    local optContainer = Instance.new("Frame"); optContainer.Size = UDim2.new(1,-4,0,0)
    optContainer.Position = UDim2.new(0,2,0,34); optContainer.AutomaticSize = Enum.AutomaticSize.Y
    optContainer.BackgroundTransparency = 1; optContainer.BorderSizePixel = 0
    optContainer.Visible = false; optContainer.Parent = f
    listLayout(optContainer, 1)

    for _, opt in ipairs(options) do
        local ob = Instance.new("TextButton"); ob.Size = UDim2.new(1,0,0,26)
        ob.BackgroundColor3 = Theme.Background; ob.BackgroundTransparency = 0.4
        ob.Text = "   "..tostring(opt); ob.TextColor3 = Theme.TextDim; ob.TextSize = 12
        ob.Font = Theme.FontBody; ob.TextXAlignment = Enum.TextXAlignment.Left
        ob.BorderSizePixel = 0; ob.Parent = optContainer
        ob.MouseEnter:Connect(function() tween(ob, {BackgroundTransparency = 0.1, TextColor3 = Theme.Accent}, 0.1) end)
        ob.MouseLeave:Connect(function() tween(ob, {BackgroundTransparency = 0.4, TextColor3 = Theme.TextDim}, 0.1) end)
        ob.MouseButton1Click:Connect(function()
            selected = opt; valBtn.Text = "  "..tostring(opt).."  ▾"
            open = false; optContainer.Visible = false
            f.ClipsDescendants = true; pcall(cb, selected)
        end)
    end

    valBtn.MouseButton1Click:Connect(function()
        open = not open; optContainer.Visible = open; f.ClipsDescendants = not open
    end)

    local api = {}
    function api:Set(v) selected = v; valBtn.Text = "  "..tostring(v).."  ▾"; pcall(cb, v) end
    function api:Get() return selected end
    function api:Refresh(newOpts)
        for _,c in ipairs(optContainer:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        options = newOpts
        for _, opt in ipairs(options) do
            local ob = Instance.new("TextButton"); ob.Size = UDim2.new(1,0,0,26)
            ob.BackgroundColor3 = Theme.Background; ob.BackgroundTransparency = 0.4
            ob.Text = "   "..tostring(opt); ob.TextColor3 = Theme.TextDim; ob.TextSize = 12
            ob.Font = Theme.FontBody; ob.TextXAlignment = Enum.TextXAlignment.Left
            ob.BorderSizePixel = 0; ob.Parent = optContainer
            ob.MouseEnter:Connect(function() tween(ob, {BackgroundTransparency = 0.1, TextColor3 = Theme.Accent}, 0.1) end)
            ob.MouseLeave:Connect(function() tween(ob, {BackgroundTransparency = 0.4, TextColor3 = Theme.TextDim}, 0.1) end)
            ob.MouseButton1Click:Connect(function()
                selected = opt; valBtn.Text = "  "..tostring(opt).."  ▾"
                open = false; optContainer.Visible = false; f.ClipsDescendants = true; pcall(cb, selected)
            end)
        end
    end
    return api
end

function Section:AddMultiDropdown(cfg)
    cfg = cfg or {}
    local name = cfg.Name or "MultiDropdown"
    local options = cfg.Options or {}
    local defaults = cfg.Defaults or {}
    local cb = cfg.Callback or function() end
    local sel = {}; for _,v in ipairs(defaults) do sel[v] = true end
    local open = false

    local f = Instance.new("Frame"); f.Name = "MDd_"..name; f.Size = UDim2.new(1,0,0,32)
    f.AutomaticSize = Enum.AutomaticSize.Y; f.BackgroundColor3 = Theme.Surface
    f.BackgroundTransparency = 0.4; f.BorderSizePixel = 0; f.ClipsDescendants = true
    f.ZIndex = self:NextZ()
    f.Parent = self.Container; corner(f, Theme.CornerSmall)

    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(0.5,-8,0,32)
    lbl.Position = UDim2.new(0,10,0,0); lbl.BackgroundTransparency = 1
    lbl.Text = name; lbl.TextColor3 = Theme.Text; lbl.TextSize = 13
    lbl.Font = Theme.FontBody; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f
    if self.Window and cfg.Tooltip then self.Window.TrackTooltip(lbl, cfg.Tooltip) end

    local function countSel() local n=0; for _ in pairs(sel) do n=n+1 end; return n end

    local valBtn = Instance.new("TextButton"); valBtn.Size = UDim2.new(0.5,-8,0,28)
    valBtn.Position = UDim2.new(0.5,0,0,2); valBtn.BackgroundColor3 = Theme.SurfaceLight
    valBtn.Text = countSel().." selected  ▾"; valBtn.TextColor3 = Theme.Accent
    valBtn.TextSize = 12; valBtn.Font = Theme.FontBody; valBtn.BorderSizePixel = 0
    valBtn.TextXAlignment = Enum.TextXAlignment.Right; valBtn.Parent = f
    corner(valBtn, Theme.CornerSmall)

    local optC = Instance.new("Frame"); optC.Size = UDim2.new(1,-4,0,0)
    optC.Position = UDim2.new(0,2,0,34); optC.AutomaticSize = Enum.AutomaticSize.Y
    optC.BackgroundTransparency = 1; optC.BorderSizePixel = 0
    optC.Visible = false; optC.Parent = f; listLayout(optC, 1)

    local function getResult() local t = {}; for k in pairs(sel) do t[#t+1] = k end; return t end

    for _, opt in ipairs(options) do
        local ob = Instance.new("TextButton"); ob.Size = UDim2.new(1,0,0,26)
        ob.BackgroundColor3 = Theme.Background; ob.BackgroundTransparency = 0.4
        ob.Text = (sel[opt] and "  ☑ " or "  ☐ ")..tostring(opt)
        ob.TextColor3 = sel[opt] and Theme.Accent or Theme.TextDim; ob.TextSize = 12
        ob.Font = Theme.FontBody; ob.TextXAlignment = Enum.TextXAlignment.Left
        ob.BorderSizePixel = 0; ob.Parent = optC
        ob.MouseButton1Click:Connect(function()
            sel[opt] = not sel[opt] or nil
            ob.Text = (sel[opt] and "  ☑ " or "  ☐ ")..tostring(opt)
            ob.TextColor3 = sel[opt] and Theme.Accent or Theme.TextDim
            valBtn.Text = countSel().." selected  ▾"; pcall(cb, getResult())
        end)
    end

    valBtn.MouseButton1Click:Connect(function()
        open = not open; optC.Visible = open; f.ClipsDescendants = not open
    end)

    local api = {}
    function api:Get() return getResult() end
    return api
end

function Section:AddKeybind(cfg)
    cfg = cfg or {}
    local name = cfg.Name or "Keybind"
    local default = cfg.Default or Enum.KeyCode.E
    local cb = cfg.Callback or function() end
    local key = default; local listening = false

    local f = Instance.new("Frame"); f.Name = "Kb_"..name; f.Size = UDim2.new(1,0,0,32)
    f.BackgroundColor3 = Theme.Surface; f.BackgroundTransparency = 0.4
    f.BorderSizePixel = 0; f.Parent = self.Container; corner(f, Theme.CornerSmall)

    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1,-80,1,0)
    lbl.Position = UDim2.new(0,10,0,0); lbl.BackgroundTransparency = 1
    lbl.Text = name; lbl.TextColor3 = Theme.Text; lbl.TextSize = 13
    lbl.Font = Theme.FontBody; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f
    if self.Window and cfg.Tooltip then self.Window.TrackTooltip(lbl, cfg.Tooltip) end

    local kBtn = Instance.new("TextButton"); kBtn.Size = UDim2.new(0,60,0,24)
    kBtn.Position = UDim2.new(1,-68,0.5,0); kBtn.AnchorPoint = Vector2.new(0,0.5)
    kBtn.BackgroundColor3 = Theme.SurfaceLight; kBtn.Text = key.Name
    kBtn.TextColor3 = Theme.Accent; kBtn.TextSize = 12; kBtn.Font = Theme.Font
    kBtn.BorderSizePixel = 0; kBtn.Parent = f; corner(kBtn, Theme.CornerSmall)
    stroke(kBtn, Theme.Border, 1, 0.6)

    kBtn.MouseButton1Click:Connect(function()
        listening = true; kBtn.Text = "..."; kBtn.TextColor3 = Theme.PurpleGlow
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if listening and input.UserInputType == Enum.UserInputType.Keyboard then
            key = input.KeyCode; listening = false
            kBtn.Text = key.Name; kBtn.TextColor3 = Theme.Accent
        elseif not gpe and input.KeyCode == key then
            pcall(cb)
        end
    end)

    local api = {}
    function api:Set(k) key = k; kBtn.Text = key.Name end
    function api:Get() return key end
    return api
end

function Section:AddTextbox(cfg)
    cfg = cfg or {}
    local name = cfg.Name or "Textbox"
    local placeholder = cfg.Placeholder or "Type here..."
    local cb = cfg.Callback or function() end
    local clearOnFocus = cfg.ClearOnFocus

    local f = Instance.new("Frame"); f.Name = "Tb_"..name; f.Size = UDim2.new(1,0,0,32)
    f.BackgroundColor3 = Theme.Surface; f.BackgroundTransparency = 0.4
    f.BorderSizePixel = 0; f.Parent = self.Container; corner(f, Theme.CornerSmall)

    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(0.4,-8,1,0)
    lbl.Position = UDim2.new(0,10,0,0); lbl.BackgroundTransparency = 1
    lbl.Text = name; lbl.TextColor3 = Theme.Text; lbl.TextSize = 13
    lbl.Font = Theme.FontBody; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f
    if self.Window and cfg.Tooltip then self.Window.TrackTooltip(lbl, cfg.Tooltip) end

    local tb = Instance.new("TextBox"); tb.Size = UDim2.new(0.6,-12,0,24)
    tb.Position = UDim2.new(0.4,0,0.5,0); tb.AnchorPoint = Vector2.new(0,0.5)
    tb.BackgroundColor3 = Theme.SurfaceLight; tb.Text = cfg.Default or ""
    tb.PlaceholderText = placeholder; tb.PlaceholderColor3 = Theme.TextDim
    tb.TextColor3 = Theme.Accent; tb.TextSize = 12; tb.Font = Theme.FontBody
    tb.BorderSizePixel = 0; tb.ClearTextOnFocus = clearOnFocus or false
    tb.Parent = f; corner(tb, Theme.CornerSmall); stroke(tb, Theme.Border, 1, 0.6)

    tb.Focused:Connect(function() tween(tb, {BackgroundColor3 = Theme.Purple}, 0.2) end)
    tb.FocusLost:Connect(function(enter)
        tween(tb, {BackgroundColor3 = Theme.SurfaceLight}, 0.2)
        if enter then pcall(cb, tb.Text) end
    end)

    local api = {}
    function api:Set(v) tb.Text = v end
    function api:Get() return tb.Text end
    return api
end

function Section:AddImageDisplay(cfg)
    cfg = cfg or {}
    local name = cfg.Name or "Image"
    local imageId = cfg.Image or cfg.Id or 0
    local size = cfg.Size or UDim2.new(1,-16,0,160)

    local f = Instance.new("Frame"); f.Name = "Img_"..name; f.Size = UDim2.new(1,0,0,0)
    f.AutomaticSize = Enum.AutomaticSize.Y; f.BackgroundTransparency = 1
    f.BorderSizePixel = 0; f.Parent = self.Container

    if name ~= "Image" then
        local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1,0,0,20)
        lbl.BackgroundTransparency = 1; lbl.Text = name; lbl.TextColor3 = Theme.TextDim
        lbl.TextSize = 12; lbl.Font = Theme.FontBody
        lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f
        if self.Window and cfg.Tooltip then self.Window.TrackTooltip(lbl, cfg.Tooltip) end
    end

    local img = Instance.new("ImageLabel"); img.Size = size
    img.BackgroundColor3 = Theme.SurfaceLight; img.BackgroundTransparency = 0.5
    img.Image = resolveImage(imageId); img.ScaleType = Enum.ScaleType.Fit
    img.BorderSizePixel = 0; img.Parent = f; corner(img, Theme.CornerSmall)
    stroke(img, Theme.Border, 1, 0.7)
    if self.Window and cfg.Tooltip then self.Window.TrackTooltip(img, cfg.Tooltip) end

    local api = {}
    function api:SetImage(id) img.Image = resolveImage(id) end
    return api
end

function Section:AddLabel(cfg)
    cfg = cfg or {}
    local lbl = Instance.new("TextLabel"); lbl.Name = "Lbl"
    lbl.Size = UDim2.new(1,0,0,20); lbl.BackgroundTransparency = 1
    lbl.Text = cfg.Text or "Label"; lbl.TextColor3 = cfg.Color or Theme.TextDim
    lbl.TextSize = 13; lbl.Font = Theme.FontBody
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = self.Container
    if self.Window and cfg.Tooltip then self.Window.TrackTooltip(lbl, cfg.Tooltip) end
    local api = {}
    function api:Set(t) lbl.Text = t end
    return api
end

function Section:AddParagraph(cfg)
    cfg = cfg or {}
    local f = Instance.new("Frame"); f.Name = "Para"; f.Size = UDim2.new(1,0,0,0)
    f.AutomaticSize = Enum.AutomaticSize.Y; f.BackgroundColor3 = Theme.Background
    f.BackgroundTransparency = 0.5; f.BorderSizePixel = 0; f.Parent = self.Container
    corner(f, Theme.CornerSmall); pad(f, 6, 6, 8, 8)
    if self.Window and cfg.Tooltip then self.Window.TrackTooltip(f, cfg.Tooltip) end

    if cfg.Title then
        local t = Instance.new("TextLabel"); t.Size = UDim2.new(1,0,0,18)
        t.BackgroundTransparency = 1; t.Text = cfg.Title; t.TextColor3 = Theme.Accent
        t.TextSize = 13; t.Font = Theme.Font
        t.TextXAlignment = Enum.TextXAlignment.Left; t.Parent = f
    end

    local body = Instance.new("TextLabel"); body.Size = UDim2.new(1,0,0,0)
    body.AutomaticSize = Enum.AutomaticSize.Y; body.BackgroundTransparency = 1
    body.Text = cfg.Content or cfg.Text or ""; body.TextColor3 = Theme.TextDim
    body.TextSize = 12; body.Font = Theme.FontBody; body.TextWrapped = true
    body.TextXAlignment = Enum.TextXAlignment.Left; body.Parent = f
    listLayout(f, 2)

    local api = {}
    function api:Set(t) body.Text = t end
    return api
end

function Section:AddConsole(cfg)
    cfg = cfg or {}
    local name = cfg.Name or "Console"
    local maxLines = cfg.MaxLines or 100

    local f = Instance.new("Frame"); f.Name = "Console_"..name; f.Size = UDim2.new(1,0,0, cfg.Height or 120)
    f.BackgroundColor3 = Color3.fromRGB(5,2,12); f.BorderSizePixel = 0
    f.Parent = self.Container; corner(f, Theme.CornerSmall)
    stroke(f, Theme.Border, 1, 0.6)

    local scroll = Instance.new("ScrollingFrame"); scroll.Size = UDim2.new(1,-4,1,-4)
    scroll.Position = UDim2.new(0,2,0,2); scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 2
    scroll.ScrollBarImageColor3 = Theme.Accent; scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.Parent = f
    listLayout(scroll, 0)

    local lines = {}
    local api = {}
    function api:Log(text, color)
        local l = Instance.new("TextLabel"); l.Size = UDim2.new(1,0,0,14)
        l.BackgroundTransparency = 1; l.Text = "› "..tostring(text)
        l.TextColor3 = color or Theme.TextDim; l.TextSize = 11
        l.Font = Enum.Font.RobotoMono; l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = scroll; table.insert(lines, l)
        if #lines > maxLines then lines[1]:Destroy(); table.remove(lines, 1) end
        scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteCanvasSize.Y)
    end
    function api:Clear()
        for _,l in ipairs(lines) do l:Destroy() end; lines = {}
    end
    function api:Success(t) api:Log(t, Theme.Success) end
    function api:Error(t) api:Log(t, Theme.Error) end
    function api:Warn(t) api:Log(t, Color3.fromRGB(255,200,50)) end
    return api
end

function Section:AddAIAssistant(cfg)
    cfg = cfg or {}
    local name = cfg.Name or "AI Assistant"
    local height = cfg.Height or 200
    local cb = cfg.Callback or function() end
    
    local f = Instance.new("Frame"); f.Name = "Ai_"..name; f.Size = UDim2.new(1,0,0,height + 60)
    f.BackgroundColor3 = Theme.Surface; f.BackgroundTransparency = 0.4
    f.BorderSizePixel = 0; f.Parent = self.Container; corner(f, Theme.CornerSmall)
    
    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1,-16,0,24)
    lbl.Position = UDim2.new(0,10,0,4); lbl.BackgroundTransparency = 1
    lbl.Text = "✧ "..name; lbl.TextColor3 = Theme.Accent; lbl.TextSize = 13
    lbl.Font = Theme.Font; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f
    if self.Window and cfg.Tooltip then self.Window.TrackTooltip(lbl, cfg.Tooltip) end

    local chatFrame = Instance.new("Frame"); chatFrame.Size = UDim2.new(1,-16,1,-68)
    chatFrame.Position = UDim2.new(0,8,0,30); chatFrame.BackgroundColor3 = Theme.Background
    chatFrame.BackgroundTransparency = 0.2; chatFrame.BorderSizePixel = 0; chatFrame.Parent = f
    corner(chatFrame, Theme.CornerSmall); stroke(chatFrame, Theme.Border, 1, 0.5)

    local scroll = Instance.new("ScrollingFrame"); scroll.Size = UDim2.new(1,-8,1,-8)
    scroll.Position = UDim2.new(0,4,0,4); scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 2
    scroll.ScrollBarImageColor3 = Theme.Accent; scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.Parent = chatFrame
    listLayout(scroll, 4)

    local inputFrame = Instance.new("Frame"); inputFrame.Size = UDim2.new(1,-16,0,28)
    inputFrame.Position = UDim2.new(0,8,1,-34); inputFrame.BackgroundColor3 = Theme.Background
    inputFrame.BorderSizePixel = 0; inputFrame.Parent = f
    corner(inputFrame, Theme.CornerSmall); stroke(inputFrame, Theme.Border, 1, 0.5)

    local box = Instance.new("TextBox"); box.Size = UDim2.new(1,-30,1,0)
    box.Position = UDim2.new(0,8,0,0); box.BackgroundTransparency = 1
    box.Text = ""; box.PlaceholderText = "Type message..."
    box.TextColor3 = Theme.Text; box.PlaceholderColor3 = Theme.TextDim
    box.TextSize = 12; box.Font = Theme.FontBody; box.TextXAlignment = Enum.TextXAlignment.Left
    box.Parent = inputFrame

    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(0,20,0,20)
    btn.Position = UDim2.new(1,-24,0.5,0); btn.AnchorPoint = Vector2.new(0,0.5)
    btn.BackgroundColor3 = Theme.Purple; btn.Text = "➤"
    btn.TextColor3 = Theme.Text; btn.TextSize = 12; btn.Font = Theme.Font
    btn.BorderSizePixel = 0; btn.Parent = inputFrame; corner(btn, Theme.CornerSmall)
    
    local lines = {}
    local function addMsg(text, isAi)
        local l = Instance.new("TextLabel"); l.Size = UDim2.new(1,0,0,0)
        l.AutomaticSize = Enum.AutomaticSize.Y; l.BackgroundTransparency = 1
        l.Text = (isAi and "🤖 " or "👤 ") .. text; l.TextWrapped = true
        l.TextColor3 = isAi and Theme.Accent or Theme.TextDim
        l.TextSize = 12; l.Font = Theme.FontBody; l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = scroll; table.insert(lines, l)
        scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteCanvasSize.Y + 100)
    end

    btn.MouseButton1Click:Connect(function()
        if box.Text ~= "" then
            local t = box.Text; box.Text = ""
            addMsg(t, false)
            pcall(cb, t)
        end
    end)
    box.FocusLost:Connect(function(e)
        if e and box.Text ~= "" then
            local t = box.Text; box.Text = ""
            addMsg(t, false)
            pcall(cb, t)
        end
    end)

    local api = {}
    function api:Reply(t) addMsg(t, true) end
    function api:Clear()
        for _,v in ipairs(lines) do pcall(function() v:Destroy() end) end
        lines = {}; scroll.CanvasPosition = Vector2.new(0,0)
    end
    return api
end

function Section:AddVideo(cfg)
    cfg = cfg or {}
    local name = cfg.Name or "Video"
    local videoAsset = cfg.Video or "rbxassetid://9285098000" -- default fallback
    local height = cfg.Height or 200

    local f = Instance.new("Frame"); f.Name = "Vid_"..name; f.Size = UDim2.new(1,0,0,height + 30)
    f.BackgroundColor3 = Theme.Surface; f.BackgroundTransparency = 0.4
    f.BorderSizePixel = 0; f.Parent = self.Container; corner(f, Theme.CornerSmall)
    
    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1,-16,0,24)
    lbl.Position = UDim2.new(0,10,0,4); lbl.BackgroundTransparency = 1
    lbl.Text = name; lbl.TextColor3 = Theme.Text; lbl.TextSize = 13
    lbl.Font = Theme.FontBody; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f
    if self.Window and cfg.Tooltip then self.Window.TrackTooltip(lbl, cfg.Tooltip) end

    local vf = Instance.new("VideoFrame")
    vf.Size = UDim2.new(1, -12, 1, -34); vf.Position = UDim2.new(0, 6, 0, 28)
    vf.BackgroundColor3 = Color3.new(0,0,0); vf.BorderSizePixel = 0
    vf.Video = videoAsset; vf.Looped = true; vf.Playing = true
    vf.Parent = f; corner(vf, Theme.CornerSmall)

    local api = {}
    function api:Play() vf:Play() end
    function api:Pause() vf:Pause() end
    function api:SetVideo(asset) vf.Video = asset; vf:Play() end
    return api


end

function Section:AddColorPicker(cfg)
    cfg = cfg or {}
    local name = cfg.Name or "Color Picker"
    local default = cfg.Default or Color3.new(1,1,1)
    local cb = cfg.Callback or function() end
    local color = default
    local h, s, v = Color3.toHSV(color)

    local f = Instance.new("Frame"); f.Name = "Cp_"..name; f.Size = UDim2.new(1,0,0,32)
    f.BackgroundColor3 = Theme.Surface; f.BackgroundTransparency = 0.4
    f.BorderSizePixel = 0; f.Parent = self.Container; f.ClipsDescendants = true
    f.ZIndex = self:NextZ()
    corner(f, Theme.CornerSmall)

    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1,-40,0,32)
    lbl.Position = UDim2.new(0,10,0,0); lbl.BackgroundTransparency = 1
    lbl.Text = name; lbl.TextColor3 = Theme.Text; lbl.TextSize = 13
    lbl.Font = Theme.FontBody; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f
    if self.Window and cfg.Tooltip then self.Window.TrackTooltip(lbl, cfg.Tooltip) end

    local dispBtn = Instance.new("TextButton"); dispBtn.Size = UDim2.new(0,24,0,24)
    dispBtn.Position = UDim2.new(1,-34,0,4); dispBtn.BackgroundColor3 = color
    dispBtn.Text = ""; dispBtn.BorderSizePixel = 0; dispBtn.Parent = f
    corner(dispBtn, Theme.CornerSmall); stroke(dispBtn, Theme.Border)

    local pickerFrame = Instance.new("Frame"); pickerFrame.Size = UDim2.new(1,-20,0,120)
    pickerFrame.Position = UDim2.new(0,10,0,36); pickerFrame.BackgroundTransparency = 1
    pickerFrame.Parent = f; pickerFrame.Visible = false

    local satMap = Instance.new("ImageLabel"); satMap.Size = UDim2.new(1,-30,1,0)
    satMap.BackgroundColor3 = Color3.fromHSV(h, 1, 1); satMap.BorderSizePixel = 0
    satMap.Image = "rbxassetid://4155801252"; satMap.Parent = pickerFrame
    corner(satMap, Theme.CornerSmall)

    local satCursor = Instance.new("Frame"); satCursor.Size = UDim2.new(0,10,0,10)
    satCursor.AnchorPoint = Vector2.new(0.5,0.5); satCursor.Position = UDim2.new(s,0,1-v,0)
    satCursor.BackgroundColor3 = Theme.Text; satCursor.Parent = satMap
    corner(satCursor, Theme.CornerPill); stroke(satCursor, Color3.new(0,0,0))

    local hueMap = Instance.new("Frame"); hueMap.Size = UDim2.new(0,20,1,0)
    hueMap.Position = UDim2.new(1,-20,0,0); hueMap.BorderSizePixel = 0; hueMap.Parent = pickerFrame
    corner(hueMap, Theme.CornerSmall)
    local uig = Instance.new("UIGradient"); uig.Rotation = 90
    uig.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)), ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,255)),
        ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0,0,255)), ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0))
    }); uig.Parent = hueMap

    local hueCursor = Instance.new("Frame"); hueCursor.Size = UDim2.new(1,4,0,4)
    hueCursor.AnchorPoint = Vector2.new(0.5,0.5); hueCursor.Position = UDim2.new(0.5,0,h,0)
    hueCursor.BackgroundColor3 = Theme.Text; hueCursor.Parent = hueMap
    corner(hueCursor, Theme.CornerSmall); stroke(hueCursor, Color3.new(0,0,0))

    local function updColor()
        color = Color3.fromHSV(h, s, v); dispBtn.BackgroundColor3 = color
        satMap.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        satCursor.Position = UDim2.new(s,0,1-v,0); hueCursor.Position = UDim2.new(0.5,0,h,0)
        pcall(cb, color)
    end

    local open = false
    dispBtn.MouseButton1Click:Connect(function()
        open = not open; pickerFrame.Visible = open
        tween(f, {Size = open and UDim2.new(1,0,0,166) or UDim2.new(1,0,0,32)}, 0.2)
    end)

    local dragSat, dragHue = false, false
    satMap.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragSat = true end
    end)
    hueMap.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragHue = true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragSat, dragHue = false, false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
            if dragSat then
                s = math.clamp((i.Position.X - satMap.AbsolutePosition.X) / satMap.AbsoluteSize.X, 0, 1)
                v = 1 - math.clamp((i.Position.Y - satMap.AbsolutePosition.Y) / satMap.AbsoluteSize.Y, 0, 1)
                updColor()
            elseif dragHue then
                h = math.clamp((i.Position.Y - hueMap.AbsolutePosition.Y) / hueMap.AbsoluteSize.Y, 0, 1)
                updColor()
            end
        end
    end)

    local api = {}
    function api:Set(c) h,s,v = Color3.toHSV(c); updColor() end
    function api:Get() return color end
    return api
end

function Section:AddGameScanner(cfg)
    cfg = cfg or {}
    local name = cfg.Name or "Game Scanner"
    -- Scanner element logic here (omitted for brevity but full functionality below)
    local f = Instance.new("Frame"); f.Name = "Scan_"..name; f.Size = UDim2.new(1,0,0,60)
    f.BackgroundColor3 = Theme.Surface; f.BackgroundTransparency = 0.4
    f.BorderSizePixel = 0; f.Parent = self.Container; corner(f, Theme.CornerSmall)
    
    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1,-100,0,32)
    lbl.Position = UDim2.new(0,10,0,0); lbl.BackgroundTransparency = 1
    lbl.Text = name; lbl.TextColor3 = Theme.Text; lbl.TextSize = 13
    lbl.Font = Theme.FontBody; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f
    if self.Window and cfg.Tooltip then self.Window.TrackTooltip(lbl, cfg.Tooltip) end

    local desc = Instance.new("TextLabel"); desc.Size = UDim2.new(1,-100,0,28)
    desc.Position = UDim2.new(0,10,0,30); desc.BackgroundTransparency = 1
    desc.Text = "Finds Remotes, Modules, and Assets"; desc.TextColor3 = Theme.TextDim
    desc.TextSize = 11; desc.Font = Theme.FontBody
    desc.TextXAlignment = Enum.TextXAlignment.Left; desc.Parent = f

    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(0,80,0,30)
    btn.Position = UDim2.new(1,-90,0.5,0); btn.AnchorPoint = Vector2.new(0,0.5)
    btn.BackgroundColor3 = Theme.Purple; btn.Text = "Scan Game"; btn.TextColor3 = Theme.Text
    btn.TextSize = 12; btn.Font = Theme.FontBody; btn.BorderSizePixel = 0; btn.Parent = f
    corner(btn, Theme.CornerSmall)

    btn.MouseButton1Click:Connect(function()
        tween(btn, {BackgroundColor3 = Theme.Accent}, 0.1)
        task.delay(0.1, function() tween(btn, {BackgroundColor3 = Theme.Purple}, 0.2) end)
        
        local targetDir = "NebubloxScans"
        if not isfolder(targetDir) then makefolder(targetDir) end
        local out = "-- Nebublox Game Scan: " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name .. "\n\n"
        out = out .. "-- [ REMOTE EVENTS ] --\n"
        for _,v in ipairs(game:GetDescendants()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                out = out .. v.ClassName .. ": " .. v:GetFullName() .. "\n"
            end
        end
        out = out .. "\n-- [ MODULE SCRIPTS ] --\n"
        for _,v in ipairs(game:GetDescendants()) do
            if v:IsA("ModuleScript") then
                out = out .. "Module: " .. v:GetFullName() .. "\n"
            end
        end
        out = out .. "\n-- [ IMAGES & DECALS ] --\n"
        for _,v in ipairs(game:GetDescendants()) do
            if v:IsA("ImageLabel") or v:IsA("ImageButton") or v:IsA("Decal") then
                local img = v:IsA("Decal") and v.Texture or v.Image
                if img and img ~= "" then out = out .. "Asset: " .. img .. " | Parent: " .. v:GetFullName() .. "\n" end
            end
        end
        
        local fn = targetDir .. "/Scan_" .. game.PlaceId .. "_" .. os.time() .. ".txt"
        writefile(fn, out)
        if self.Window then
            self.Window:Notify({Title="Scan Complete", Content="Saved to workspace/"..fn, Type="success", Duration=5})
        end
    end)
    return {}
end

function Section:Add3DViewport(cfg)
    cfg = cfg or {}
    local name = cfg.Name or "3D Viewport"
    local model = cfg.Model
    
    local f = Instance.new("Frame"); f.Name = "Vp_"..name; f.Size = UDim2.new(1,0,0,180)
    f.BackgroundColor3 = Theme.Surface; f.BackgroundTransparency = 0.4
    f.BorderSizePixel = 0; f.Parent = self.Container; corner(f, Theme.CornerSmall)
    
    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1,-16,0,24)
    lbl.Position = UDim2.new(0,10,0,4); lbl.BackgroundTransparency = 1
    lbl.Text = name; lbl.TextColor3 = Theme.Text; lbl.TextSize = 13
    lbl.Font = Theme.FontBody; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f
    if self.Window and cfg.Tooltip then self.Window.TrackTooltip(lbl, cfg.Tooltip) end

    local vp = Instance.new("ViewportFrame"); vp.Size = UDim2.new(1,-16,1,-36)
    vp.Position = UDim2.new(0,8,0,28); vp.BackgroundTransparency = 1
    vp.BorderSizePixel = 0; vp.Parent = f
    corner(vp, Theme.CornerSmall)
    stroke(vp, Theme.Border, 1, 0.5)

    local cam = Instance.new("Camera"); vp.CurrentCamera = cam
    local angle = 0
    local conn

    local api = {}

    function api:SetModel(m)
        vp:ClearAllChildren()
        if not m then return end
        local clone = m:Clone()
        local cf = clone:GetPivot()
        -- Normalize pivot to center
        if clone:IsA("Model") then
            local cf, size = clone:GetBoundingBox()
            for _, p in ipairs(clone:GetDescendants()) do
                if p:IsA("BasePart") then p.Anchored = true end
            end
            clone:PivotTo(CFrame.new(Vector3.zero))
            cam.CFrame = CFrame.new(Vector3.new(0, size.Y*0.5, size.Magnitude*1.2), Vector3.zero)
        elseif clone:IsA("BasePart") then
            clone.Anchored = true
            clone.CFrame = CFrame.new(Vector3.zero)
            cam.CFrame = CFrame.new(Vector3.new(0, clone.Size.Y*0.5, clone.Size.Magnitude*1.5), Vector3.zero)
        end
        clone.Parent = vp

        if conn then conn:Disconnect() end
        local spinSpeed = cfg.SpinSpeed or 0.5
        conn = RunService.RenderStepped:Connect(function(dt)
            if not vp.Parent then conn:Disconnect(); return end
            angle = angle + math.rad(spinSpeed * 60 * dt)
            clone:PivotTo(CFrame.Angles(0, angle, 0))
        end)
    end

    if model then api:SetModel(model) end
    return api
end

function Section:AddLineGraph(cfg)
    cfg = cfg or {}
    local name = cfg.Name or "Live Graph"
    local maxPoints = cfg.MaxPoints or 20
    local min = cfg.Min or 0
    local max = cfg.Max or 100
    
    local f = Instance.new("Frame"); f.Name = "Graph_"..name; f.Size = UDim2.new(1,0,0,140)
    f.BackgroundColor3 = Theme.Surface; f.BackgroundTransparency = 0.4
    f.BorderSizePixel = 0; f.Parent = self.Container; corner(f, Theme.CornerSmall)

    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1,-60,0,24)
    lbl.Position = UDim2.new(0,10,0,4); lbl.BackgroundTransparency = 1
    lbl.Text = name; lbl.TextColor3 = Theme.Text; lbl.TextSize = 13
    lbl.Font = Theme.FontBody; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f
    if self.Window and cfg.Tooltip then self.Window.TrackTooltip(lbl, cfg.Tooltip) end

    local valLbl = Instance.new("TextLabel"); valLbl.Size = UDim2.new(0,50,0,24)
    valLbl.Position = UDim2.new(1,-56,0,4); valLbl.BackgroundTransparency = 1
    valLbl.Text = "0"; valLbl.TextColor3 = Theme.Accent; valLbl.TextSize = 13
    valLbl.Font = Theme.Font; valLbl.TextXAlignment = Enum.TextXAlignment.Right; valLbl.Parent = f

    local canvas = Instance.new("Frame"); canvas.Size = UDim2.new(1,-16,1,-36)
    canvas.Position = UDim2.new(0,8,0,28); canvas.BackgroundColor3 = Theme.Background
    canvas.BackgroundTransparency = 0.2; canvas.BorderSizePixel = 0; canvas.Parent = f
    corner(canvas, Theme.CornerSmall); stroke(canvas, Theme.Border, 1, 0.5)

    local points = {}
    local lines = {}
    local lineContainer = Instance.new("Frame"); lineContainer.Size = UDim2.new(1,0,1,0)
    lineContainer.BackgroundTransparency = 1; lineContainer.Parent = canvas

    local function updateGraph()
        for _, l in ipairs(lines) do l:Destroy() end
        lines = {}
        if #points < 2 then return end

        local cw, ch = canvas.AbsoluteSize.X, canvas.AbsoluteSize.Y
        if cw == 0 then return end
        local step = cw / (maxPoints - 1)
        
        local curMax = max
        for _, v in ipairs(points) do if v > curMax then curMax = v end end

        local function getPointPos(idx, v)
            local x = (idx-1) * step
            local y = ch - (math.clamp((v - min) / (curMax - min), 0, 1) * ch)
            return Vector2.new(x, y)
        end

        for i = 1, #points-1 do
            local p1 = getPointPos(i, points[i])
            local p2 = getPointPos(i+1, points[i+1])
            
            local ln = Instance.new("Frame")
            ln.BackgroundColor3 = Theme.Accent; ln.BorderSizePixel = 0
            ln.AnchorPoint = Vector2.new(0.5, 0.5); ln.ZIndex = 5
            
            local dist = (p2 - p1).Magnitude
            ln.Size = UDim2.new(0, dist, 0, 2)
            ln.Position = UDim2.new(0, (p1.X + p2.X)/2, 0, (p1.Y + p2.Y)/2)
            ln.Rotation = math.deg(math.atan2(p2.Y - p1.Y, p2.X - p1.X))
            ln.Parent = lineContainer
            table.insert(lines, ln)

            local fill = Instance.new("Frame")
            fill.BackgroundColor3 = Theme.Accent; fill.BorderSizePixel = 0
            fill.BackgroundTransparency = 0.5; fill.AnchorPoint = Vector2.new(0, 0)
            fill.Size = UDim2.new(0, step, 0, ch - math.min(p1.Y, p2.Y))
            fill.Position = UDim2.new(0, p1.X, 0, math.min(p1.Y, p2.Y))
            fill.ZIndex = 4; fill.Parent = lineContainer
            table.insert(lines, fill)
            
            local uig = Instance.new("UIGradient")
            uig.Rotation = 90; uig.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1)
            })
            uig.Parent = fill
        end
    end

    local api = {}
    function api:AddPoint(v)
        table.insert(points, v)
        if #points > maxPoints then table.remove(points, 1) end
        valLbl.Text = tostring(math.floor(v*10)/10)
        pcall(function() updateGraph() end)
    end
    function api:Clear()
        points = {}
        updateGraph()
    end

    canvas:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if canvas.AbsoluteSize.X > 0 then updateGraph() end
    end)

    return api
end

function Section:AddRow(cfg)
    cfg = cfg or {}
    local cols = cfg.Columns or 2
    local gap = cfg.Gap or 8

    local f = Instance.new("Frame"); f.Name = "Row"
    f.Size = UDim2.new(1,0,0,0); f.AutomaticSize = Enum.AutomaticSize.Y
    f.BackgroundTransparency = 1; f.BorderSizePixel = 0
    f.Parent = self.Container
    
    local rowList = Instance.new("UIListLayout")
    rowList.FillDirection = Enum.FillDirection.Horizontal
    rowList.SortOrder = Enum.SortOrder.LayoutOrder
    rowList.Padding = UDim.new(0, gap)
    rowList.Parent = f
    
    local pseudoGroup = {}
    for i=1, cols do
        local colContainer = Instance.new("Frame")
        colContainer.Size = UDim2.new(1/cols, -(gap * (cols-1))/cols, 0, 0)
        colContainer.AutomaticSize = Enum.AutomaticSize.Y
        colContainer.BackgroundTransparency = 1
        colContainer.BorderSizePixel = 0
        colContainer.Parent = f
        listLayout(colContainer, 4)
        
        local pSec = setmetatable({}, {__index = Section})
        pSec.Container = colContainer
        pSec.Window = self.Window
        table.insert(pseudoGroup, pSec)
    end
    return pseudoGroup
end

function Section:AddProfileCard(cfg)
    cfg = cfg or {}
    local title = cfg.Title or game.Players.LocalPlayer.DisplayName
    local desc = cfg.Desc or "User Status"
    local status = cfg.Status or "ready" -- ready, busy, offline
    local image = cfg.Image or game:GetService("Players"):GetUserThumbnailAsync(game.Players.LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
    local discordId = cfg.DiscordId or cfg.DiscordID

    local f = Instance.new("Frame"); f.Name = "ProfileCard"; f.Size = UDim2.new(1,0,0,64)
    f.BackgroundColor3 = Theme.Surface; f.BackgroundTransparency = 0.4
    f.BorderSizePixel = 0; f.Parent = self.Container; corner(f, Theme.Corner)
    stroke(f, Theme.Accent, 1, 0.4)

    local img = Instance.new("ImageLabel"); img.Size = UDim2.new(0,48,0,48)
    img.Position = UDim2.new(0,8,0,8); img.BackgroundTransparency = 1
    img.Image = resolveImage(image); img.Parent = f; corner(img, UDim.new(1,0))

    local tLbl = Instance.new("TextLabel"); tLbl.Size = UDim2.new(1,-90,0,20)
    tLbl.Position = UDim2.new(0,64,0,12); tLbl.BackgroundTransparency = 1
    tLbl.Text = title; tLbl.TextColor3 = Theme.Text; tLbl.TextSize = 14
    tLbl.Font = Theme.Font; tLbl.TextXAlignment = Enum.TextXAlignment.Left; tLbl.Parent = f

    local dLbl = Instance.new("TextLabel"); dLbl.Size = UDim2.new(1,-90,0,16)
    dLbl.Position = UDim2.new(0,64,0,32); dLbl.BackgroundTransparency = 1
    dLbl.Text = desc; dLbl.TextColor3 = Theme.TextDim; dLbl.TextSize = 11
    dLbl.Font = Theme.FontBody; dLbl.TextXAlignment = Enum.TextXAlignment.Left; dLbl.Parent = f

    local st = Instance.new("Frame"); st.Size = UDim2.new(0,10,0,10)
    st.Position = UDim2.new(1,-20,0,12); st.BackgroundColor3 = status == "ready" and Theme.Success or (status == "busy" and Theme.Warning or Theme.Error)
    st.BorderSizePixel = 0; st.Parent = f; corner(st, UDim.new(1,0))
    stroke(st, Theme.Background, 1.5, 0)

    local api = {}
    function api:SetTitle(t) tLbl.Text = t end
    function api:SetDesc(t) dLbl.Text = t end
    function api:SetStatus(s) 
        st.BackgroundColor3 = s == "online" and Theme.Success or (s == "idle" and Theme.Warning or (s == "dnd" and Theme.Error or Theme.TextDim)) 
    end
    function api:SetAvatar(id) img.Image = resolveImage(id) end

    if discordId then
        task.spawn(function()
            while f.Parent do
                pcall(function()
                    local res = game:HttpGet("https://api.lanyard.rest/v1/users/" .. tostring(discordId))
                    local data = HttpService:JSONDecode(res)
                    if data.success and data.data then
                        local d = data.data
                        local discordStatus = d.discord_status or "offline"
                        local username = d.discord_user.display_name or d.discord_user.username
                        local avatarUrl = "https://cdn.discordapp.com/avatars/" .. discordId .. "/" .. d.discord_user.avatar .. ".png?size=256"
                        
                        api:SetTitle(username)
                        api:SetAvatar(avatarUrl)
                        api:SetStatus(discordStatus)
                        
                        local activity = "Connected"
                        if d.activities and #d.activities > 0 then
                            for _, act in ipairs(d.activities) do
                                if act.type == 0 then activity = act.name; break end
                            end
                        end
                        api:SetDesc(activity)
                    end
                end)
                task.wait(30)
            end
        end)
    end

    return api
end

function Section:AddSubTabs(cfg)
    cfg = cfg or {}
    local tabs = cfg.Tabs or {"Tab 1", "Tab 2"}

    local f = Instance.new("Frame"); f.Name = "SubTabs"
    f.Size = UDim2.new(1,0,0,0); f.AutomaticSize = Enum.AutomaticSize.Y
    f.BackgroundTransparency = 1; f.BorderSizePixel = 0
    f.Parent = self.Container
    listLayout(f, 6)

    local btnContainer = Instance.new("Frame"); btnContainer.Size = UDim2.new(1,0,0,28)
    btnContainer.BackgroundColor3 = Theme.Background; btnContainer.BackgroundTransparency = 0.5
    btnContainer.BorderSizePixel = 0; btnContainer.Parent = f
    corner(btnContainer, Theme.CornerSmall)
    listLayout(btnContainer, 0).FillDirection = Enum.FillDirection.Horizontal

    local contentContainer = Instance.new("Frame"); contentContainer.Size = UDim2.new(1,0,0,0)
    contentContainer.AutomaticSize = Enum.AutomaticSize.Y; contentContainer.BackgroundTransparency = 1
    contentContainer.BorderSizePixel = 0; contentContainer.Parent = f

    local pseudoGroup = {}
    local btns = {}
    local frames = {}
    local activeTab = 1

    local function selectTab(idx)
        activeTab = idx
        for i, f in ipairs(frames) do
            f.Visible = (i == idx)
        end
        for i, b in ipairs(btns) do
            b.BackgroundColor3 = (i == idx) and Theme.Purple or Theme.Background
            b.BackgroundTransparency = (i == idx) and 0.4 or 1
            if b:FindFirstChild("Underline") then
                b.Underline.Visible = (i == idx)
            end
        end
    end

    local tabWidth = 1 / #tabs
    for i, tName in ipairs(tabs) do
        local btn = Instance.new("TextButton"); btn.Size = UDim2.new(tabWidth, 0, 1, 0)
        btn.Text = tName; btn.TextColor3 = Theme.Text; btn.TextSize = 13
        btn.Font = Theme.Font; btn.BorderSizePixel = 0; btn.Parent = btnContainer
        corner(btn, Theme.CornerSmall)
        
        local ul = Instance.new("Frame"); ul.Name = "Underline"
        ul.Size = UDim2.new(1,0,0,2); ul.Position = UDim2.new(0,0,1,-2)
        ul.BackgroundColor3 = Theme.Accent; ul.BorderSizePixel = 0; ul.Parent = btn

        btn.MouseButton1Click:Connect(function() selectTab(i) end)
        table.insert(btns, btn)

        local pFrame = Instance.new("Frame"); pFrame.Size = UDim2.new(1,0,0,0)
        pFrame.AutomaticSize = Enum.AutomaticSize.Y; pFrame.BackgroundTransparency = 1
        pFrame.BorderSizePixel = 0; pFrame.Parent = contentContainer
        listLayout(pFrame, 4)
        table.insert(frames, pFrame)

        local pSec = setmetatable({}, {__index = Section})
        pSec.Container = pFrame
        pSec.Window = self.Window
        table.insert(pseudoGroup, pSec)
    end
    
    selectTab(1)
    return pseudoGroup
end
-- ═══════════════════════════════════════
--  SECTION CONSTRUCTOR
-- ═══════════════════════════════════════

function Section.new(tab, cfg)
    local self = setmetatable({}, Section)
    self.Tab = tab; self.Name = cfg.Name or "Section"

    local f = Instance.new("Frame"); f.Name = "Sec_"..self.Name
    f.Size = UDim2.new(1,0,0,0); f.AutomaticSize = Enum.AutomaticSize.Y
    f.BackgroundColor3 = Theme.Surface; f.BackgroundTransparency = 0.3
    f.BorderSizePixel = 0; f.Parent = tab.Page
    corner(f, Theme.Corner); stroke(f, Theme.Border, 1, 0.7)
    self.Frame = f

    local hdr = Instance.new("TextLabel"); hdr.Size = UDim2.new(1,-16,0,26)
    hdr.Position = UDim2.new(0,8,0,4); hdr.BackgroundTransparency = 1
    hdr.Text = "⬦  "..self.Name; hdr.TextColor3 = Theme.Accent; hdr.TextSize = 14
    hdr.Font = Theme.Font; hdr.TextXAlignment = Enum.TextXAlignment.Left; hdr.Parent = f

    local line = Instance.new("Frame"); line.Size = UDim2.new(1,-16,0,1)
    line.Position = UDim2.new(0,8,0,30); line.BackgroundColor3 = Theme.Accent
    line.BackgroundTransparency = 0.7; line.BorderSizePixel = 0; line.Parent = f

    local c = Instance.new("Frame"); c.Name = "Elements"
    c.Size = UDim2.new(1,0,0,0); c.Position = UDim2.new(0,0,0,36)
    c.AutomaticSize = Enum.AutomaticSize.Y; c.BackgroundTransparency = 1
    c.BorderSizePixel = 0; c.Parent = f
    listLayout(c, 4); pad(c, 4, 8, 8, 8)
    self.Container = c
    return self
end

-- ═══════════════════════════════════════
--  TAB
-- ═══════════════════════════════════════

function Tab.new(window, cfg)
    local self = setmetatable({}, Tab)
    self.Window = window; self.Name = cfg.Name or "Tab"; self.Icon = cfg.Icon

    local btn = Instance.new("TextButton"); btn.Name = "Tab_"..self.Name
    btn.Size = UDim2.new(1,0,0,34); btn.BackgroundColor3 = Theme.Surface
    btn.BackgroundTransparency = 1; btn.Text = ""; btn.BorderSizePixel = 0
    btn.Parent = window._tabBar; corner(btn, Theme.CornerSmall)

    if self.Icon then
        local ico = Instance.new("ImageLabel"); ico.Size = UDim2.new(0,18,0,18)
        ico.Position = UDim2.new(0,8,0.5,0); ico.AnchorPoint = Vector2.new(0,0.5)
        ico.BackgroundTransparency = 1; ico.Image = resolveImage(self.Icon)
        ico.ImageColor3 = Theme.TextDim; ico.Parent = btn; self._icon = ico
    end

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, self.Icon and -60 or -36, 1, 0)
    lbl.Position = UDim2.new(0, self.Icon and 30 or 8, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = self.Name; lbl.TextColor3 = Theme.TextDim
    lbl.TextSize = 12; lbl.Font = Theme.FontBody; lbl.TextTruncate = Enum.TextTruncate.AtEnd
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = btn
    self._lbl = lbl; self._btn = btn

    local tearBtn = Instance.new("TextButton"); tearBtn.Size = UDim2.new(0,20,0,20)
    tearBtn.Position = UDim2.new(1,-24,0.5,0); tearBtn.AnchorPoint = Vector2.new(0,0.5)
    tearBtn.BackgroundTransparency = 1; tearBtn.Text = "⇱"; tearBtn.TextColor3 = Theme.TextDim
    tearBtn.TextSize = 14; tearBtn.Font = Theme.FontBody; tearBtn.Parent = btn
    if window.TrackTooltip then window.TrackTooltip(tearBtn, "Tear off tab") end

    local page = Instance.new("ScrollingFrame"); page.Name = "Page_"..self.Name
    page.Size = UDim2.new(1,0,1,0); page.BackgroundTransparency = 1
    page.BorderSizePixel = 0; page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Theme.Accent; page.CanvasSize = UDim2.new(0,0,0,0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y; page.Visible = false
    page.Parent = window._content; self.Page = page
    listLayout(page, 8); pad(page, 8, 8, 8, 8)

    self.TornOff = false
    local tearWindow

    tearBtn.MouseButton1Click:Connect(function()
        if self.TornOff then return end
        self.TornOff = true

        -- Create mini window
        tearWindow = Instance.new("Frame"); tearWindow.Name = "Tear_"..self.Name
        tearWindow.Size = UDim2.new(0, 320, 0, 400)
        tearWindow.Position = UDim2.new(0.5, 180, 0.5, 0)
        tearWindow.AnchorPoint = Vector2.new(0.5, 0.5)
        tearWindow.BackgroundColor3 = Theme.Background
        tearWindow.BorderSizePixel = 0
        tearWindow.Parent = window._sg; corner(tearWindow, UDim.new(0, 10))
        stroke(tearWindow, Theme.Accent, 1, 0.5)

        local tb = Instance.new("Frame"); tb.Size = UDim2.new(1,0,0,30)
        tb.BackgroundColor3 = Theme.Surface; tb.BorderSizePixel = 0
        tb.Parent = tearWindow; corner(tb, UDim.new(0,10))
        local tFix = Instance.new("Frame"); tFix.Size = UDim2.new(1,0,0,10)
        tFix.Position = UDim2.new(0,0,1,-10); tFix.BackgroundColor3 = Theme.Surface
        tFix.BorderSizePixel = 0; tFix.Parent = tb

        local title = Instance.new("TextLabel"); title.Size = UDim2.new(1,-40,1,0)
        title.Position = UDim2.new(0,10,0,0); title.BackgroundTransparency = 1
        title.Text = "⬡ " .. self.Name; title.TextColor3 = Theme.Accent
        title.Font = Theme.Font; title.TextSize = 14
        title.TextXAlignment = Enum.TextXAlignment.Left; title.Parent = tb

        local closeBtn = Instance.new("TextButton"); closeBtn.Size = UDim2.new(0,24,0,24)
        closeBtn.Position = UDim2.new(1,-28,0,3); closeBtn.BackgroundColor3 = Theme.Error
        closeBtn.BackgroundTransparency = 0.8; closeBtn.Text = "✕"
        closeBtn.TextColor3 = Theme.Error; closeBtn.BorderSizePixel = 0; closeBtn.Parent = tb
        corner(closeBtn, UDim.new(0,6))

        -- Dragging logic
        local dragging, dragInput, dragStart, startPos
        tb.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true; dragStart = i.Position; startPos = tearWindow.Position
                i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
            end
        end)
        tb.InputChanged:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseMovement then dragInput = i end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if i == dragInput and dragging then
                local d = i.Position - dragStart
                tearWindow.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
            end
        end)

        -- Move Page
        page.Parent = tearWindow
        page.Position = UDim2.new(0, 10, 0, 40)
        page.Size = UDim2.new(1, -20, 1, -50)
        page.Visible = true

        btn.Visible = false

        if window._activeTab == self then
            local found = false
            for _, t in ipairs(window._tabs) do
                if t ~= self and not t.TornOff then t:Select(); found = true; break end
            end
            if not found then window._activeTab = nil end
        end

        closeBtn.MouseButton1Click:Connect(function()
            self.TornOff = false
            page.Parent = window._content
            page.Position = UDim2.new(0,0,0,0)
            page.Size = UDim2.new(1,0,1,0)
            page.Visible = false
            btn.Visible = true
            tearWindow:Destroy()
            
            if not window._activeTab then self:Select() end
        end)
    end)

    btn.MouseEnter:Connect(function()
        if window._activeTab ~= self then tween(btn, {BackgroundTransparency = 0.6}, 0.15) end
    end)
    btn.MouseLeave:Connect(function()
        if window._activeTab ~= self then tween(btn, {BackgroundTransparency = 1}, 0.15) end
    end)
    btn.MouseButton1Click:Connect(function() self:Select() end)
    return self
end

function Tab:Select()
    local w = self.Window
    if w._activeTab == self or self.TornOff then return end

    if w._activeTab then
        local p = w._activeTab
        -- Fade out old tab
        tween(p.Page, {ScrollBarImageTransparency = 1}, 0.2)
        for _, c in ipairs(p.Page:GetDescendants()) do
            if c:IsA("GuiObject") and c.Name ~= "UIListLayout" and c.Name ~= "UIPadding" then
                pcall(function() tween(c, {BackgroundTransparency = 1, TextTransparency = 1, ImageTransparency = 1}, 0.2) end)
            end
        end
        task.delay(0.2, function() p.Page.Visible = false end)

        tween(p._btn, {BackgroundTransparency = 1}, 0.2)
        p._lbl.TextColor3 = Theme.TextDim
        if p._icon then p._icon.ImageColor3 = Theme.TextDim end
    end

    w._activeTab = self
    
    -- Setup for animating in
    self.Page.Visible = true
    self.Page.Position = UDim2.new(0, 20, 0, 0) -- start slightly offset
    self.Page.ScrollBarImageTransparency = 1
    
    for _, c in ipairs(self.Page:GetDescendants()) do
        if c:IsA("GuiObject") and c.Name ~= "UIListLayout" and c.Name ~= "UIPadding" then
            local origBgT = c:GetAttribute("OrigBgT") or c.BackgroundTransparency
            local origTxtT = c:GetAttribute("OrigTxtT") or (c:IsA("TextLabel") or c:IsA("TextButton") or c:IsA("TextBox") and c.TextTransparency or 0)
            local origImgT = c:GetAttribute("OrigImgT") or (c:IsA("ImageLabel") or c:IsA("ImageButton") and c.ImageTransparency or 0)
            
            c:SetAttribute("OrigBgT", origBgT)
            c:SetAttribute("OrigTxtT", origTxtT)
            c:SetAttribute("OrigImgT", origImgT)
            
            c.BackgroundTransparency = 1
            if c:IsA("TextLabel") or c:IsA("TextButton") or c:IsA("TextBox") then c.TextTransparency = 1 end
            if c:IsA("ImageLabel") or c:IsA("ImageButton") then c.ImageTransparency = 1 end
            
            pcall(function() tween(c, {BackgroundTransparency = origBgT, TextTransparency = origTxtT, ImageTransparency = origImgT}, 0.3) end)
        end
    end

    tween(self.Page, {Position = UDim2.new(0, 0, 0, 0), ScrollBarImageTransparency = 0}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    tween(self._btn, {BackgroundTransparency = 0.5, BackgroundColor3 = Theme.Purple}, 0.2)
    self._lbl.TextColor3 = Theme.Text
    if self._icon then self._icon.ImageColor3 = Theme.Accent end
end

function Tab:MakeSection(cfg) return Section.new(self, cfg) end

-- ═══════════════════════════════════════
--  WINDOW
-- ═══════════════════════════════════════

function Window.new(cfg)
    cfg = cfg or {}
    local self = setmetatable({}, Window)
    self.Title = cfg.Title or "Nebublox"
    self._size = cfg.Size or UDim2.new(0, 560, 0, 380)
    self._tabs = {}; self._activeTab = nil

    local sg = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("NebubloxUI")
    if sg then sg:Destroy() end
    local water = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("NebubloxWatermark")
    if water then water:Destroy() end
    local keys = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("NebubloxKeySystem")
    if keys then keys:Destroy() end

    sg = Instance.new("ScreenGui"); sg.Name = "NebubloxUI"
    sg.ResetOnSpawn = false; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = LocalPlayer:WaitForChild("PlayerGui"); self._sg = sg

    -- Global Tooltip
    local tip = Instance.new("TextLabel"); tip.Name = "GlobalTooltip"
    tip.Size = UDim2.new(0, 200, 0, 24); tip.BackgroundColor3 = Theme.Surface
    tip.BorderSizePixel = 0; tip.ZIndex = 110; tip.Visible = false
    tip.TextColor3 = Theme.Text; tip.TextSize = 12; tip.Font = Theme.FontBody
    tip.TextWrapped = true; tip.Parent = sg
    corner(tip, Theme.CornerSmall); stroke(tip, Theme.Accent, 1, 0.4)
    local tipPad = Instance.new("UIPadding"); tipPad.PaddingLeft = UDim.new(0, 6)
    tipPad.PaddingRight = UDim.new(0, 6); tipPad.Parent = tip
    self._tooltip = tip

    -- Wrapper frame
    local wrapper = Instance.new("CanvasGroup"); wrapper.Name = "Wrapper"
    wrapper.Size = self._size; wrapper.Position = UDim2.new(0.5,0,0.5,0)
    wrapper.AnchorPoint = Vector2.new(0.5,0.5); wrapper.BackgroundTransparency = 1
    wrapper.BorderSizePixel = 0; wrapper.Parent = sg
    self._wrapper = wrapper

    -- Ambient Glow
    local glow = Instance.new("ImageLabel"); glow.Name = "AmbientGlow"
    glow.Size = UDim2.new(1, 160, 1, 160); glow.Position = UDim2.new(0.5, 0, 0.5, 0)
    glow.AnchorPoint = Vector2.new(0.5, 0.5); glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://5028857084" -- common drop shadow texture
    glow.ImageColor3 = Theme.Accent; glow.ImageTransparency = 0.4
    glow.ScaleType = Enum.ScaleType.Slice; glow.SliceCenter = Rect.new(24, 24, 276, 276)
    glow.ZIndex = 0; glow.Parent = wrapper

    -- Main frame
    local main = Instance.new("Frame"); main.Name = "Main"
    main.Size = UDim2.new(1,0,1,0); main.Position = UDim2.new(0.5,0,0.5,0)
    main.AnchorPoint = Vector2.new(0.5,0.5); main.BackgroundColor3 = Theme.Background
    main.BorderSizePixel = 0; main.ClipsDescendants = true; main.Parent = wrapper
    corner(main, UDim.new(0,12)); stroke(main, Theme.Accent, 1.5, 0.6)
    self._main = main

    -- Helper to attach tooltips
    self.TrackTooltip = function(obj, txt)
        if not txt or txt == "" then return end
        obj.MouseEnter:Connect(function()
            tip.Text = txt
            local ts = game:GetService("TextService")
            local bounds = ts:GetTextSize(txt, 12, Theme.FontBody, Vector2.new(300, 24))
            tip.Size = UDim2.new(0, bounds.X + 16, 0, 24)
            tip.Visible = true
            track(RunService.Heartbeat:Connect(function()
                if tip.Visible then
                    local mp = UserInputService:GetMouseLocation()
                    tween(tip, {Position = UDim2.new(0, mp.X + 15, 0, mp.Y - 15 - 36)}, 0.05)
                end
            end))
        end)
        obj.MouseLeave:Connect(function() tip.Visible = false end)
    end
    local bgCfg = cfg.Background or {}
    if bgCfg.Image or bgCfg.Color then
        -- Background image
        if bgCfg.Image then
            local bgImg = Instance.new("ImageLabel"); bgImg.Name = "BackgroundImage"
            bgImg.Size = UDim2.new(1,0,1,0); bgImg.BackgroundTransparency = 1
            bgImg.Image = resolveImage(bgCfg.Image)
            bgImg.ImageTransparency = bgCfg.Transparency or 0.85
            bgImg.ImageColor3 = bgCfg.Tint or Theme.Accent
            bgImg.ScaleType = Enum.ScaleType.Crop
            bgImg.ZIndex = 0; bgImg.BorderSizePixel = 0; bgImg.Parent = main
            corner(bgImg, UDim.new(0,12))
            self._bgImage = bgImg
        end

        -- Acrylic Overlay (The "Subtle Dimming" for better readability)
        local bgOverlay = Instance.new("Frame"); bgOverlay.Name = "BackgroundOverlay"
        bgOverlay.Size = UDim2.new(1,0,1,0); bgOverlay.BackgroundColor3 = Color3.new(0,0,0)
        bgOverlay.BackgroundTransparency = 0.5; bgOverlay.ZIndex = 0.5; bgOverlay.Parent = main
        corner(bgOverlay, UDim.new(0,12))

        -- Optional Real Blur Effect
        if bgCfg.Blur then
            local blurEffect = Instance.new("BlurEffect")
            blurEffect.Name = "NebubloxInternalBlur"; blurEffect.Size = 12; blurEffect.Parent = game:GetService("Lighting")
            track(blurEffect)
        end
    end

    -- Animated Galaxy Background System
    if cfg.GalaxyBackground then
        local galaxy = Instance.new("Frame"); galaxy.Name = "GalaxyLayer"
        galaxy.Size = UDim2.new(1,0,1,0); galaxy.BackgroundColor3 = Color3.fromRGB(12, 6, 24)
        galaxy.ZIndex = 0; galaxy.BorderSizePixel = 0; galaxy.Parent = main; galaxy.ClipsDescendants = true
        corner(galaxy, UDim.new(0,12))

        local gGrad = Instance.new("UIGradient"); gGrad.Parent = galaxy
        gGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(8, 2, 14)),
            ColorSequenceKeypoint.new(0.6, Color3.fromRGB(32, 12, 48)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 2, 10))
        })
        gGrad.Rotation = 45

        -- Background nebulas
        for i = 1, 3 do
            local neb = Instance.new("ImageLabel"); neb.Size = UDim2.new(1.5,0,1.5,0)
            neb.Position = UDim2.new(math.random(-20,20)/100, 0, math.random(-20,20)/100, 0)
            neb.BackgroundTransparency = 1; neb.Image = "rbxassetid://1331823772" -- smoke/cloud texture
            neb.ImageColor3 = Theme.Purple; neb.ImageTransparency = 0.85
            neb.ZIndex = 0; neb.Parent = galaxy
            
            task.spawn(function()
                while neb.Parent do
                    tween(neb, {Rotation = math.random(-15,15), ImageTransparency = 0.75}, math.random(10,20))
                    task.wait(math.random(10,20))
                    tween(neb, {Rotation = math.random(-15,15), ImageTransparency = 0.9}, math.random(10,20))
                    task.wait(math.random(10,20))
                end
            end)
        end

        -- Twinkling stars (using glowing textures instead of dots)
        for i = 1, 40 do
            local star = Instance.new("ImageLabel")
            star.Size = UDim2.new(0, math.random(6, 12), 0, math.random(6, 12))
            star.Position = UDim2.new(math.random(), 0, math.random(), 0)
            star.BackgroundTransparency = 1; star.Image = "rbxassetid://6073743871" -- soft glow texture
            star.ImageColor3 = math.random() > 0.8 and Theme.Accent or Color3.new(1,1,1)
            star.ImageTransparency = 0.6; star.ZIndex = 0; star.Parent = galaxy
            
            task.spawn(function()
                while star.Parent do
                    tween(star, {ImageTransparency = math.random(4,9)/10, Size = UDim2.new(0, math.random(4,14), 0, math.random(4,14))}, math.random(2,5))
                    task.wait(math.random(2,5))
                end
            end)
        end

        -- Shooting stars
        track(RunService.Heartbeat:Connect(function()
            if main.Parent and main.Visible and math.random() < 0.015 then
                local shooter = Instance.new("Frame")
                shooter.Size = UDim2.new(0, math.random(30, 60), 0, 1)
                local startX, startY = math.random(50, 120)/100, math.random(-20, 40)/100
                shooter.Position = UDim2.new(startX, 0, startY, 0)
                shooter.BackgroundColor3 = Theme.Accent; shooter.BackgroundTransparency = 0.2
                shooter.BorderSizePixel = 0; shooter.ZIndex = 0; shooter.Rotation = 35
                shooter.Parent = galaxy
                local gLine = Instance.new("UIGradient"); gLine.Parent = shooter
                gLine.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0)
                })

                local speed = math.random(10, 18)/10
                tween(shooter, {
                    Position = UDim2.new(startX - 0.6, 0, startY + 0.6*math.tan(math.rad(35)), 0),
                }, speed, Enum.EasingStyle.Linear)
                task.delay(speed, function() shooter:Destroy() end)
            end
        end))
        self._galaxy = galaxy
    end

    -- Open animation
    wrapper.Size = UDim2.new(0,0,0,0); wrapper.GroupTransparency = 1
    tween(wrapper, {Size = self._size, GroupTransparency = 0}, 0.5, Enum.EasingStyle.Back)

    -- Title bar
    local tb = Instance.new("Frame"); tb.Name = "TitleBar"
    tb.Size = UDim2.new(1,0,0,38); tb.BackgroundColor3 = Theme.Surface
    tb.BorderSizePixel = 0; tb.Parent = main; corner(tb, UDim.new(0,12))
    local tbFix = Instance.new("Frame"); tbFix.Size = UDim2.new(1,0,0,12)
    tbFix.Position = UDim2.new(0,0,1,-12); tbFix.BackgroundColor3 = Theme.Surface
    tbFix.BorderSizePixel = 0; tbFix.Parent = tb

    local ttl = Instance.new("TextLabel"); ttl.Size = UDim2.new(0, 200, 1, 0)
    ttl.Position = UDim2.new(0,14,0,0); ttl.BackgroundTransparency = 1
    ttl.Text = "⬡  "..self.Title; ttl.TextColor3 = Theme.Accent; ttl.TextSize = 16
    ttl.Font = Theme.Font; ttl.TextXAlignment = Enum.TextXAlignment.Left; ttl.Parent = tb

    -- NeonUI Inspired Titlebar HUD (Ping + Status)
    local statusFrame = Instance.new("Frame"); statusFrame.Size = UDim2.new(0, 140, 0, 16)
    statusFrame.Position = UDim2.new(0, 200, 0.5, 0); statusFrame.AnchorPoint = Vector2.new(0, 0.5)
    statusFrame.BackgroundTransparency = 1; statusFrame.Parent = tb

    self.StatusLabel = Instance.new("TextLabel"); self.StatusLabel.Size = UDim2.new(0, 80, 1, 0)
    self.StatusLabel.BackgroundTransparency = 1; self.StatusLabel.Position = UDim2.new(0,0,0,0)
    self.StatusLabel.Text = "● Ready"; self.StatusLabel.TextColor3 = Theme.Success
    self.StatusLabel.TextSize = 12; self.StatusLabel.Font = Theme.FontBody
    self.StatusLabel.TextXAlignment = Enum.TextXAlignment.Left; self.StatusLabel.Parent = statusFrame

    local pingLabel = Instance.new("TextLabel"); pingLabel.Size = UDim2.new(0, 60, 1, 0)
    pingLabel.BackgroundTransparency = 1; pingLabel.Position = UDim2.new(0,80,0,0)
    pingLabel.Text = "?ms"; pingLabel.TextColor3 = Theme.TextDim
    pingLabel.TextSize = 12; pingLabel.Font = Theme.FontBody
    pingLabel.TextXAlignment = Enum.TextXAlignment.Left; pingLabel.Parent = statusFrame

    track(RunService.Heartbeat:Connect(function()
        local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        pingLabel.Text = tostring(ping) .. "ms"
        if ping < 60 then
            pingLabel.TextColor3 = Theme.Success
        elseif ping < 150 then
            pingLabel.TextColor3 = Theme.Warning
        else
            pingLabel.TextColor3 = Theme.Error
        end
    end))

    -- Close / Minimize
    for i, info in ipairs({{Text="✕", Col=Theme.Error, Off=-34}, {Text="—", Col=Theme.Accent, Off=-66}}) do
        local b = Instance.new("TextButton"); b.Size = UDim2.new(0,28,0,28)
        b.Position = UDim2.new(1,info.Off,0,5); b.BackgroundColor3 = info.Col
        b.BackgroundTransparency = 0.8; b.Text = info.Text; b.TextColor3 = info.Col
        b.TextSize = 14; b.Font = Theme.Font; b.BorderSizePixel = 0; b.Parent = tb
        corner(b, UDim.new(0,6))
        b.MouseEnter:Connect(function() tween(b, {BackgroundTransparency = 0.4}, 0.15) end)
        b.MouseLeave:Connect(function() tween(b, {BackgroundTransparency = 0.8}, 0.15) end)
        if i == 1 then
            b.MouseButton1Click:Connect(function()
                tween(wrapper, {Size = UDim2.new(0,0,0,0), GroupTransparency = 1}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
                task.delay(0.45, function() sg:Destroy() end)
            end)
        else
            self._minimized = false
            b.MouseButton1Click:Connect(function()
                self._minimized = not self._minimized
                tween(wrapper, {Size = self._minimized and UDim2.new(0,self._size.X.Offset,0,38) or self._size}, 0.3)
                glow.Visible = not self._minimized
            end)
        end
    end

    -- Dragging
    local dragging, dragInput, dragStart, startPos
    tb.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = i.Position; startPos = wrapper.Position
            i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    tb.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then dragInput = i end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if i == dragInput and dragging then
            local d = i.Position - dragStart
            wrapper.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
        end
    end)

    -- Sidebar tab bar
    local tabBar = Instance.new("Frame"); tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(0,140,1,-42); tabBar.Position = UDim2.new(0,0,0,40)
    tabBar.BackgroundColor3 = Theme.Surface; tabBar.BorderSizePixel = 0
    tabBar.ClipsDescendants = true; tabBar.Parent = main; self._tabBar = tabBar

    -- Global Search bar
    local searchContainer = Instance.new("Frame"); searchContainer.Name = "SearchContainer"
    searchContainer.Size = UDim2.new(1,-12,0,28); searchContainer.Position = UDim2.new(0,6,0,6)
    searchContainer.BackgroundColor3 = Theme.Background; searchContainer.BorderSizePixel = 0
    searchContainer.Parent = tabBar; corner(searchContainer, Theme.CornerSmall)
    stroke(searchContainer, Theme.Border, 1, 0.5)

    local searchIcon = Instance.new("ImageLabel"); searchIcon.Size = UDim2.new(0,14,0,14)
    searchIcon.Position = UDim2.new(0,8,0.5,0); searchIcon.AnchorPoint = Vector2.new(0,0.5)
    searchIcon.BackgroundTransparency = 1; searchIcon.Image = resolveIcon("search")
    searchIcon.ImageColor3 = Theme.TextDim; searchIcon.Parent = searchContainer

    local searchBox = Instance.new("TextBox"); searchBox.Size = UDim2.new(1,-30,1,0)
    searchBox.Position = UDim2.new(0,26,0,0); searchBox.BackgroundTransparency = 1
    searchBox.PlaceholderText = "Search tabs..."; searchBox.PlaceholderColor3 = Theme.TextDim
    searchBox.Text = ""; searchBox.TextColor3 = Theme.Text; searchBox.TextSize = 12
    searchBox.Font = Theme.FontBody; searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.Parent = searchContainer

    local yOffset = 40
    if cfg.Profile then
        local pf = Instance.new("Frame"); pf.Name = "ProfileContainer"
        pf.Size = UDim2.new(1,-12,0,46); pf.Position = UDim2.new(0,6,0,6)
        pf.BackgroundColor3 = Theme.Background; pf.BorderSizePixel = 0
        pf.Parent = tabBar; corner(pf, Theme.CornerSmall)
        stroke(pf, Theme.Border, 1, 0.5)

        local av = Instance.new("ImageLabel"); av.Size = UDim2.new(0,32,0,32)
        av.Position = UDim2.new(0,8,0.5,0); av.AnchorPoint = Vector2.new(0,0.5)
        av.BackgroundColor3 = Theme.Surface; av.BorderSizePixel = 0
        av.Image = resolveImage(cfg.Profile.Avatar or "rbxassetid://10138402123")
        av.Parent = pf; corner(av, UDim.new(1,0))

        if cfg.Profile.Status then
            local stat = Instance.new("Frame"); stat.Size = UDim2.new(0,10,0,10)
            stat.Position = UDim2.new(1,-2,1,-2); stat.AnchorPoint = Vector2.new(1,1)
            stat.BackgroundColor3 = Theme.Success; stat.BorderSizePixel = 0
            stat.Parent = av; corner(stat, UDim.new(1,0))
            stroke(stat, Theme.Background, 2, 0)
        end

        local pt = Instance.new("TextLabel"); pt.Size = UDim2.new(1,-54,0,16)
        pt.Position = UDim2.new(0,48,0,8); pt.BackgroundTransparency = 1
        pt.Text = cfg.Profile.Title or "User"; pt.TextColor3 = Theme.Text
        pt.TextSize = 13; pt.Font = Theme.Font; pt.TextXAlignment = Enum.TextXAlignment.Left
        pt.Parent = pf

        local pd = Instance.new("TextLabel"); pd.Size = UDim2.new(1,-54,0,14)
        pd.Position = UDim2.new(0,48,0,24); pd.BackgroundTransparency = 1
        pd.Text = cfg.Profile.Desc or "Profile"; pd.TextColor3 = Theme.TextDim
        pd.TextSize = 11; pd.Font = Theme.FontBody; pd.TextXAlignment = Enum.TextXAlignment.Left
        pd.Parent = pf

        searchContainer.Position = UDim2.new(0,6,0,58)
        yOffset = 92
    end

    local bottomOffset = 6
    if cfg.BottomProfile then
        local bpf = Instance.new("Frame"); bpf.Name = "BottomProfile"
        bpf.Size = UDim2.new(1,-12,0,46); bpf.Position = UDim2.new(0,6,1,-52)
        bpf.BackgroundColor3 = Theme.Background; bpf.BorderSizePixel = 0
        bpf.Parent = tabBar; corner(bpf, Theme.CornerSmall)
        stroke(bpf, Theme.Border, 1, 0.5)

        local av = Instance.new("ImageLabel"); av.Size = UDim2.new(0,32,0,32)
        av.Position = UDim2.new(0,8,0.5,0); av.AnchorPoint = Vector2.new(0,0.5)
        av.BackgroundColor3 = Theme.Surface; av.BorderSizePixel = 0
        av.Image = resolveImage(cfg.BottomProfile.Avatar or "rbxassetid://10138402123")
        av.Parent = bpf; corner(av, UDim.new(1,0))

        if cfg.BottomProfile.Status then
            local stat = Instance.new("Frame"); stat.Size = UDim2.new(0,10,0,10)
            stat.Position = UDim2.new(1,-2,1,-2); stat.AnchorPoint = Vector2.new(1,1)
            stat.BackgroundColor3 = Theme.Success; stat.BorderSizePixel = 0
            stat.Parent = av; corner(stat, UDim.new(1,0))
            stroke(stat, Theme.Background, 2, 0)
        end

        local pt = Instance.new("TextLabel"); pt.Size = UDim2.new(1,-54,0,16)
        pt.Position = UDim2.new(0,48,0,8); pt.BackgroundTransparency = 1
        pt.Text = cfg.BottomProfile.Title or "User"; pt.TextColor3 = Theme.Text
        pt.TextSize = 13; pt.Font = Theme.Font; pt.TextXAlignment = Enum.TextXAlignment.Left
        pt.Parent = bpf

        local pd = Instance.new("TextLabel"); pd.Size = UDim2.new(1,-54,0,14)
        pd.Position = UDim2.new(0,48,0,24); pd.BackgroundTransparency = 1
        pd.Text = cfg.BottomProfile.Desc or "Profile"; pd.TextColor3 = Theme.TextDim
        pd.TextSize = 11; pd.Font = Theme.FontBody; pd.TextXAlignment = Enum.TextXAlignment.Left
        pd.Parent = bpf

        bottomOffset = 58
    end

    local tabListContainer = Instance.new("ScrollingFrame"); tabListContainer.Name = "TabList"
    tabListContainer.Size = UDim2.new(1,0,1,-(yOffset + bottomOffset)); tabListContainer.Position = UDim2.new(0,0,0,yOffset)
    tabListContainer.BackgroundTransparency = 1; tabListContainer.BorderSizePixel = 0
    tabListContainer.ScrollBarThickness = 2; tabListContainer.ScrollBarImageColor3 = Theme.Accent
    tabListContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y; tabListContainer.CanvasSize = UDim2.new(0,0,0,0)
    tabListContainer.Parent = tabBar; listLayout(tabListContainer, 2); pad(tabListContainer, 0, 0, 6, 6)
    self._tabListContainer = tabListContainer

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local q = searchBox.Text:lower()
        for _, t in ipairs(self._tabs) do
            t._btn.Visible = (q == "" or t.Title:lower():find(q) ~= nil)
        end
    end)

    local div = Instance.new("Frame"); div.Size = UDim2.new(0,1,1,-8)
    div.Position = UDim2.new(1,0,0,4); div.BackgroundColor3 = Theme.Border
    div.BackgroundTransparency = 0.5; div.BorderSizePixel = 0; div.Parent = tabBar

    -- Content area
    local content = Instance.new("Frame"); content.Name = "Content"
    content.Size = UDim2.new(1,-144,1,-42); content.Position = UDim2.new(0,142,0,40)
    content.BackgroundTransparency = 1; content.BorderSizePixel = 0
    content.ClipsDescendants = true; content.Parent = main; self._content = content

    return self
end

function Window:MakeTab(cfg)
    local t = Tab.new(self, cfg); table.insert(self._tabs, t)
    -- Attach tab button to the new ScrollingFrame container instead of raw tabBar
    t._btn.Parent = self._tabListContainer
    if #self._tabs == 1 then t:Select() end
    return t
end

function Window:Destroy()
    -- Sever ALL tracked connections to prevent memory leaks
    for i, conn in ipairs(_connections) do
        pcall(function() conn:Disconnect() end)
        _connections[i] = nil
    end
    -- Remove blur
    local blur = Lighting:FindFirstChild("NebubloxBlur")
    if blur then blur:Destroy() end
    -- Animate out and destroy
    local wrap = self._wrapper or self._main
    tween(wrap, {Size = UDim2.new(0,0,0,0), GroupTransparency = 1}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    task.delay(0.45, function()
        self._sg:Destroy()
        -- Also remove watermark if it exists
        local wm = LocalPlayer.PlayerGui:FindFirstChild("NebubloxWatermark")
        if wm then wm:Destroy() end
    end)
end

--- Notification system: slides in from bottom-right
function Window:Notify(cfg)
    cfg = cfg or {}
    local title = cfg.Title or "Nebublox"
    local content = cfg.Content or cfg.Text or ""
    local duration = cfg.Duration or 4
    local nType = cfg.Type or "info" -- info, success, error, warning

    local accentCol = ({info=Theme.Accent, success=Theme.Success, error=Theme.Error, warning=Theme.Warning})[nType] or Theme.Accent

    -- Notification container (reuse or create)
    local container = self._sg:FindFirstChild("NotifyContainer")
    if not container then
        container = Instance.new("Frame"); container.Name = "NotifyContainer"
        container.Size = UDim2.new(0,260,1,0); container.Position = UDim2.new(1,-270,0,0)
        container.BackgroundTransparency = 1; container.BorderSizePixel = 0
        container.Parent = self._sg
        local lay = Instance.new("UIListLayout"); lay.SortOrder = Enum.SortOrder.LayoutOrder
        lay.VerticalAlignment = Enum.VerticalAlignment.Bottom
        lay.Padding = UDim.new(0,6); lay.Parent = container
        pad(container, 0, 10, 0, 0)
    end

    local nf = Instance.new("Frame"); nf.Size = UDim2.new(1,0,0,0)
    nf.BackgroundColor3 = Theme.Surface; nf.BorderSizePixel = 0
    nf.ClipsDescendants = true; nf.Parent = container
    corner(nf, Theme.CornerSmall); stroke(nf, accentCol, 1, 0.4)

    local bar = Instance.new("Frame"); bar.Size = UDim2.new(0,3,1,-8)
    bar.Position = UDim2.new(0,4,0,4); bar.BackgroundColor3 = accentCol
    bar.BorderSizePixel = 0; bar.Parent = nf; corner(bar, Theme.CornerPill)

    local tLbl = Instance.new("TextLabel"); tLbl.Size = UDim2.new(1,-20,0,18)
    tLbl.Position = UDim2.new(0,14,0,6); tLbl.BackgroundTransparency = 1
    tLbl.Text = title; tLbl.TextColor3 = accentCol; tLbl.TextSize = 13
    tLbl.Font = Theme.Font; tLbl.TextXAlignment = Enum.TextXAlignment.Left; tLbl.Parent = nf

    local cLbl = Instance.new("TextLabel"); cLbl.Size = UDim2.new(1,-20,0,0)
    cLbl.Position = UDim2.new(0,14,0,24); cLbl.AutomaticSize = Enum.AutomaticSize.Y
    cLbl.BackgroundTransparency = 1; cLbl.Text = content; cLbl.TextColor3 = Theme.TextDim
    cLbl.TextSize = 12; cLbl.Font = Theme.FontBody; cLbl.TextWrapped = true
    cLbl.TextXAlignment = Enum.TextXAlignment.Left; cLbl.Parent = nf

    -- Animate in
    tween(nf, {Size = UDim2.new(1,0,0,60)}, 0.3, Enum.EasingStyle.Back)
    -- Auto-dismiss
    task.delay(duration, function()
        tween(nf, {Size = UDim2.new(1,0,0,0), BackgroundTransparency = 1}, 0.3)
        task.delay(0.35, function() nf:Destroy() end)
    end)
end

--- Interactive Dialog System
function Window:ShowDialog(cfg)
    cfg = cfg or {}
    local title = cfg.Title or "Dialog"
    local content = cfg.Content or "Are you sure?"
    local buttons = cfg.Buttons or {{Title = "OK", Callback = function() end}}
    
    local dim = Instance.new("Frame"); dim.Size = UDim2.new(1,0,1,0)
    dim.BackgroundColor3 = Color3.new(0,0,0); dim.BackgroundTransparency = 1
    dim.BorderSizePixel = 0; dim.Active = true; dim.ZIndex = 100
    dim.Parent = self._wrapper or self._main
    
    local dBox = Instance.new("Frame"); dBox.Size = UDim2.new(0,0,0,0)
    dBox.Position = UDim2.new(0.5,0,0.5,0); dBox.AnchorPoint = Vector2.new(0.5,0.5)
    dBox.BackgroundColor3 = Theme.Background; dBox.BorderSizePixel = 0; dBox.ClipsDescendants = true
    dBox.ZIndex = 101; dBox.Parent = dim; corner(dBox, Theme.CornerSmall)
    stroke(dBox, Theme.Border, 1, 0.6)
    
    local tLbl = Instance.new("TextLabel"); tLbl.Size = UDim2.new(1,-20,0,30)
    tLbl.Position = UDim2.new(0,10,0,10); tLbl.BackgroundTransparency = 1
    tLbl.Text = title; tLbl.TextColor3 = Theme.Accent; tLbl.TextSize = 16
    tLbl.Font = Enum.Font.GothamBold; tLbl.TextXAlignment = Enum.TextXAlignment.Center
    tLbl.ZIndex = 102; tLbl.Parent = dBox
    
    local cLbl = Instance.new("TextLabel"); cLbl.Size = UDim2.new(1,-40,0,40)
    cLbl.Position = UDim2.new(0,20,0,40); cLbl.BackgroundTransparency = 1
    cLbl.Text = content; cLbl.TextColor3 = Theme.TextDim; cLbl.TextSize = 13
    cLbl.Font = Theme.FontBody; cLbl.TextWrapped = true; cLbl.TextXAlignment = Enum.TextXAlignment.Center
    cLbl.ZIndex = 102; cLbl.Parent = dBox
    
    local btnContainer = Instance.new("Frame"); btnContainer.Size = UDim2.new(1,-40,0,32)
    btnContainer.Position = UDim2.new(0,20,1,-42); btnContainer.BackgroundTransparency = 1
    btnContainer.ZIndex = 102; btnContainer.Parent = dBox
    
    local function closeDialog()
        tween(dBox, {Size=UDim2.new(0,0,0,0)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        tween(dim, {BackgroundTransparency=1}, 0.3)
        task.delay(0.35, function() dim:Destroy() end)
    end
    
    local btnWidth = 1 / #buttons
    for i, bCfg in ipairs(buttons) do
        local btn = Instance.new("TextButton"); btn.Size = UDim2.new(btnWidth, -6, 1, 0)
        btn.Position = UDim2.new((i-1)*btnWidth, 3, 0, 0)
        btn.BackgroundColor3 = Theme.SurfaceLight; btn.Text = bCfg.Title
        btn.TextColor3 = Theme.Text; btn.TextSize = 13; btn.Font = Theme.Font
        btn.ZIndex = 103; btn.BorderSizePixel = 0; btn.Parent = btnContainer
        corner(btn, Theme.CornerSmall); stroke(btn, Theme.Border, 1, 0.4)
        
        btn.MouseButton1Click:Connect(function()
            closeDialog()
            if bCfg.Callback then pcall(bCfg.Callback) end
        end)
    end
    
    tween(dim, {BackgroundTransparency = 0.5}, 0.3)
    tween(dBox, {Size = UDim2.new(0,300,0,140)}, 0.4, Enum.EasingStyle.Back)
end

-- ═══════════════════════════════════════
--  PUBLIC API
-- ═══════════════════════════════════════
local Nebublox = {}
Nebublox.__index = Nebublox
Nebublox.Theme = Theme
Nebublox.Icons = Icons
Nebublox.ResolveImage = resolveImage
Nebublox.ResolveIcon = resolveIcon
Nebublox._windows = {}
Nebublox._statistics = {
    Runtime = 0,
    ToggleClicks = 0,
    SliderChanges = 0,
    ButtonPresses = 0
}

local startTime = tick()
track(RunService.Heartbeat:Connect(function()
    Nebublox._statistics.Runtime = tick() - startTime
end))

function Nebublox:MakeWindow(cfg)
    local w = Window.new(cfg)
    table.insert(self._windows, w)

    -- UI Toggle Keybind (RightControl by default) + Quick Tab Switching
    local toggleKey = cfg.ToggleKey or Enum.KeyCode.RightControl
    track(UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == toggleKey then
            w._main.Visible = not w._main.Visible
            -- Also toggle blur
            local blur = Lighting:FindFirstChild("NebubloxBlur")
            if blur then blur.Enabled = w._main.Visible end
        elseif not gpe and w._main.Visible and input.KeyCode.Value >= 49 and input.KeyCode.Value <= 57 then
            -- Pressing 1-9 to quick-swap tabs
            local num = input.KeyCode.Value - 48
            if w._tabs[num] then w._tabs[num]:Select() end
        end
    end))

    -- Acrylic blur effect
    if cfg.AcrylicBlur ~= false then
        local blur = Lighting:FindFirstChild("NebubloxBlur")
        if not blur then
            blur = Instance.new("BlurEffect"); blur.Name = "NebubloxBlur"
            blur.Size = 8; blur.Parent = Lighting
        end
    end

    return w
end

function Nebublox:SetTheme(overrides)
    for k,v in pairs(overrides) do Theme[k] = v end
end

--- Full cleanup: severs every connection, destroys all GUI, removes blur
function Nebublox:Destroy()
    for _, w in ipairs(self._windows) do
        pcall(function() w:Destroy() end)
    end
    self._windows = {}
    for _, c in ipairs(_connections) do
        pcall(function() if c.Disconnect then c:Disconnect() elseif c.disconnect then c:disconnect() end end)
    end
    _connections = {}
end
Nebublox.Unload = Nebublox.Destroy -- alias

--- Config save/load using executor workspace
function Nebublox:SaveConfig(name, data)
    local success, encoded = pcall(HttpService.JSONEncode, HttpService, data)
    if success then
        local fileName = (name or "nebublox_config").. ".json"
        if writefile then
            writefile(fileName, encoded)
        end
    end
end

function Nebublox:LoadConfig(name)
    local fileName = (name or "nebublox_config").. ".json"
    if isfile and isfile(fileName) then
        local raw = readfile(fileName)
        local success, data = pcall(HttpService.JSONDecode, HttpService, raw)
        if success then return data end
    end
    return nil
end

--- IgniteKillSwitch: Aggressively destroys all known script UIs and clears trackers
--- Targets: Nebublox, WindUI, ANUI, Boreal, Rayfield, Solaris, etc.
function Nebublox:IgniteKillSwitch()
    local targetNames = {"WindUI", "ANUI", "Nebublox", "Boreal", "Linoria", "Rayfield", "Solaris", "Nebula"}
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        for _, gui in ipairs(pg:GetChildren()) do
            if gui:IsA("ScreenGui") then
                local found = false
                for _, name in ipairs(targetNames) do
                    if gui.Name:find(name) then found = true; break end
                end
                if found then pcall(function() gui:Destroy() end) end
            end
        end
    end
    
    if getgenv then
        local genv = getgenv()
        if genv.Nebublox and genv.Nebublox.Destroy then pcall(function() genv.Nebublox:Destroy() end) end
        if genv.WindUI and genv.WindUI.Unload then pcall(function() genv.WindUI:Unload() end) end
        if genv._connections then
            for _, c in ipairs(genv._connections) do
                pcall(function() if c.Disconnect then c:Disconnect() elseif c.disconnect then c:disconnect() end end)
            end
            genv._connections = {}
        end
    end
    task.wait(0.1) -- allow cleanup to settle
end

--- Watermark HUD: tiny persistent display with FPS, ping, time
function Nebublox:MakeWatermark(cfg)
    cfg = cfg or {}
    local text = cfg.Text or "Nebublox"

    local sg = Instance.new("ScreenGui"); sg.Name = "NebubloxWatermark"
    sg.ResetOnSpawn = false; sg.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local wf = Instance.new("Frame"); wf.Size = UDim2.new(0,300,0,24)
    wf.Position = UDim2.new(0.5,0,0,6); wf.AnchorPoint = Vector2.new(0.5,0)
    wf.BackgroundColor3 = Theme.Background; wf.BackgroundTransparency = 0.3
    wf.BorderSizePixel = 0; wf.Parent = sg
    corner(wf, Theme.CornerSmall); stroke(wf, Theme.Accent, 1, 0.7)

    local wLbl = Instance.new("TextLabel"); wLbl.Size = UDim2.new(1,-12,1,0)
    wLbl.Position = UDim2.new(0,6,0,0); wLbl.BackgroundTransparency = 1
    wLbl.TextColor3 = Theme.Accent; wLbl.TextSize = 11; wLbl.Font = Theme.Font
    wLbl.TextXAlignment = Enum.TextXAlignment.Center; wLbl.Parent = wf

    track(RunService.Heartbeat:Connect(function()
        local fps = math.floor(1 / RunService.Heartbeat:Wait())
        local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        local t = os.date("%I:%M %p")
        wLbl.Text = ("%s  |  %d FPS  |  %dms  |  %s"):format(text, fps, ping, t)
    end))

    return sg
end

--- Key System: blocks UI until valid key is entered
function Nebublox:KeySystem(cfg)
    cfg = cfg or {}
    local validKeys = cfg.Keys or {}
    local title = cfg.Title or "Nebublox Key System"
    local subtitle = cfg.Subtitle or "Enter your key to continue"
    local link = cfg.Link or ""
    local cb = cfg.Callback or function() end

    local sg = Instance.new("ScreenGui"); sg.Name = "NebubloxKeySystem"
    sg.ResetOnSpawn = false; sg.Parent = LocalPlayer:WaitForChild("PlayerGui")

    -- Dimmed background
    local dim = Instance.new("Frame"); dim.Size = UDim2.new(1,0,1,0)
    dim.BackgroundColor3 = Color3.new(0,0,0); dim.BackgroundTransparency = 0.4
    dim.BorderSizePixel = 0; dim.Parent = sg

    local modal = Instance.new("Frame"); modal.Size = UDim2.new(0,340,0,200)
    modal.Position = UDim2.new(0.5,0,0.5,0); modal.AnchorPoint = Vector2.new(0.5,0.5)
    modal.BackgroundColor3 = Theme.Background; modal.BorderSizePixel = 0; modal.Parent = sg
    corner(modal, UDim.new(0,14)); stroke(modal, Theme.Accent, 2, 0.3)

    -- Open anim
    modal.Size = UDim2.new(0,0,0,0); modal.BackgroundTransparency = 1
    tween(modal, {Size = UDim2.new(0,340,0,200), BackgroundTransparency = 0}, 0.5, Enum.EasingStyle.Back)

    local tLbl = Instance.new("TextLabel"); tLbl.Size = UDim2.new(1,-20,0,30)
    tLbl.Position = UDim2.new(0,10,0,16); tLbl.BackgroundTransparency = 1
    tLbl.Text = title; tLbl.TextColor3 = Theme.Accent; tLbl.TextSize = 18
    tLbl.Font = Theme.Font; tLbl.TextXAlignment = Enum.TextXAlignment.Center; tLbl.Parent = modal

    local sLbl = Instance.new("TextLabel"); sLbl.Size = UDim2.new(1,-20,0,20)
    sLbl.Position = UDim2.new(0,10,0,48); sLbl.BackgroundTransparency = 1
    sLbl.Text = subtitle; sLbl.TextColor3 = Theme.TextDim; sLbl.TextSize = 12
    sLbl.Font = Theme.FontBody; sLbl.TextXAlignment = Enum.TextXAlignment.Center; sLbl.Parent = modal

    local keyBox = Instance.new("TextBox"); keyBox.Size = UDim2.new(1,-40,0,32)
    keyBox.Position = UDim2.new(0,20,0,80); keyBox.BackgroundColor3 = Theme.Surface
    keyBox.PlaceholderText = "Paste your key here..."; keyBox.PlaceholderColor3 = Theme.TextDim
    keyBox.Text = ""; keyBox.TextColor3 = Theme.Text; keyBox.TextSize = 13
    keyBox.Font = Theme.FontBody; keyBox.BorderSizePixel = 0; keyBox.Parent = modal
    corner(keyBox, Theme.CornerSmall); stroke(keyBox, Theme.Border, 1, 0.5)

    local verBtn = Instance.new("TextButton"); verBtn.Size = UDim2.new(1,-40,0,32)
    verBtn.Position = UDim2.new(0,20,0,122); verBtn.BackgroundColor3 = Theme.Purple
    verBtn.Text = "Verify Key"; verBtn.TextColor3 = Theme.Text; verBtn.TextSize = 14
    verBtn.Font = Theme.Font; verBtn.BorderSizePixel = 0; verBtn.Parent = modal
    corner(verBtn, Theme.CornerSmall)
    verBtn.MouseEnter:Connect(function() tween(verBtn, {BackgroundColor3 = Theme.PurpleGlow}, 0.15) end)
    verBtn.MouseLeave:Connect(function() tween(verBtn, {BackgroundColor3 = Theme.Purple}, 0.15) end)

    local statusLbl = Instance.new("TextLabel"); statusLbl.Size = UDim2.new(1,-20,0,18)
    statusLbl.Position = UDim2.new(0,10,0,160); statusLbl.BackgroundTransparency = 1
    statusLbl.Text = link ~= "" and ("Get key: "..link) or ""
    statusLbl.TextColor3 = Theme.AccentDim; statusLbl.TextSize = 11
    statusLbl.Font = Theme.FontBody; statusLbl.Parent = modal

    local verified = false
    verBtn.MouseButton1Click:Connect(function()
        local input = keyBox.Text:gsub("%s+", "")
        for _, k in ipairs(validKeys) do
            if input == k then verified = true; break end
        end
        if verified then
            statusLbl.Text = "✓ Key verified!"; statusLbl.TextColor3 = Theme.Success
            tween(modal, {Size = UDim2.new(0,0,0,0), BackgroundTransparency = 1}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
            tween(dim, {BackgroundTransparency = 1}, 0.3)
            task.delay(0.45, function() sg:Destroy(); pcall(cb, true) end)
        else
            statusLbl.Text = "✗ Invalid key!"; statusLbl.TextColor3 = Theme.Error
            tween(modal, {Position = UDim2.new(0.5,8,0.5,0)}, 0.05)
            task.delay(0.05, function() tween(modal, {Position = UDim2.new(0.5,-8,0.5,0)}, 0.05) end)
            task.delay(0.1, function() tween(modal, {Position = UDim2.new(0.5,0,0.5,0)}, 0.05) end)
        end
    end)

    -- Return a promise-like: blocks via polling
    return {
        IsVerified = function() return verified end,
        Await = function()
            repeat task.wait(0.1) until verified or not sg.Parent
            return verified
        end
    }
end

--- Core Floating Keybinds HUD
function Nebublox:MakeKeybindsList(cfg)
    cfg = cfg or {}
    local sg = Instance.new("ScreenGui"); sg.Name = "NebubloxKeybinds"
    sg.ResetOnSpawn = false; sg.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    local main = Instance.new("Frame"); main.Size = UDim2.new(0, 180, 0, 30)
    main.Position = UDim2.new(0, 20, 0.5, 0); main.BackgroundColor3 = Theme.Background
    main.BackgroundTransparency = 0.4; main.BorderSizePixel = 0; main.Parent = sg
    main.Active = true -- allow drag start
    corner(main, Theme.CornerSmall); stroke(main, Theme.Accent, 1, 0.6)
    
    local title = Instance.new("TextLabel"); title.Size = UDim2.new(1,0,0,30)
    title.BackgroundTransparency = 1; title.Text = cfg.Title or "Keybinds"
    title.TextColor3 = Theme.Accent; title.TextSize = 13; title.Font = Theme.Font
    title.Parent = main
    
    local list = Instance.new("Frame"); list.Size = UDim2.new(1,0,0,0)
    list.Position = UDim2.new(0,0,0,30); list.BackgroundTransparency = 1
    list.Parent = main; listLayout(list, 2); pad(list, 4,6,6,6)
    
    -- basic dragging
    local dragging, dragInput, dragStart, startPos
    main.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = i.Position; startPos = main.Position
            i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    main.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement then dragInput = i end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if i == dragInput and dragging then
            local d = i.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
        end
    end)
    
    local api = {}
    local binds = {}
    function api:Add(name, keyString)
        if binds[name] then self:Update(name, keyString); return end
        local f = Instance.new("Frame"); f.Size = UDim2.new(1,0,0,16)
        f.BackgroundTransparency = 1; f.Parent = list
        local ln = Instance.new("TextLabel"); ln.Size = UDim2.new(1,-40,1,0)
        ln.BackgroundTransparency = 1; ln.Text = name; ln.TextColor3 = Theme.Text
        ln.TextSize = 12; ln.Font = Theme.FontBody; ln.TextXAlignment = Enum.TextXAlignment.Left
        ln.Parent = f
        local v = Instance.new("TextLabel"); v.Size = UDim2.new(0,40,1,0)
        v.Position = UDim2.new(1,-40,0,0); v.BackgroundTransparency = 1
        v.Text = "["..keyString.."]"; v.TextColor3 = Theme.Accent
        v.TextSize = 12; v.Font = Theme.FontBody; v.TextXAlignment = Enum.TextXAlignment.Right
        v.Parent = f
        binds[name] = {Frame = f, ValLabel = v}
        main.Size = UDim2.new(0, 180, 0, 30 + list.UIListLayout.AbsoluteContentSize.Y + 12)
    end
    function api:Update(name, keyString)
        if binds[name] then binds[name].ValLabel.Text = "["..keyString.."]" end
    end
    function api:Remove(name)
        if binds[name] then binds[name].Frame:Destroy(); binds[name] = nil end
        main.Size = UDim2.new(0, 180, 0, 30 + list.UIListLayout.AbsoluteContentSize.Y + 12)
    end
    function api:Destroy()
        sg:Destroy()
    end
    return api
end

local _rgbConn = nil
function Nebublox:SetRGBMode(enabled)
    if _rgbConn then _rgbConn:Disconnect(); _rgbConn = nil end
    if enabled then
        local hue = 0
        _rgbConn = RunService.RenderStepped:Connect(function(dt)
            hue = (hue + dt * 0.1) % 1
            Theme.Accent = Color3.fromHSV(hue, 1, 1)
        end)
    else
        Theme.Accent = Color3.fromRGB(0, 235, 255) -- Reset back to default cyan
    end
end

return Nebublox
