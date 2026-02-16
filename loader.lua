-- // NEBUBLOX UNIVERSAL HUB //
-- // Optimized & Branded for LilNugOfWisdom //
-- // V4.7: Fixed Infinite Yield / Crash on Reload //

local API_URL_BASE = "https://darkmatterv1.onrender.com/api"

-- [0] COMPATIBILITY & CLEANUP
local getgenv = getgenv or function() return _G end

if getgenv().NebuBlox_Loaded then
    getgenv().NebuBlox_Running = false
    -- We removed the library's :Destroy() call because it causes the "Infinite yield" error
    -- asking for a "Main" frame that might not exist yet.
    task.wait(0.1)
    
    pcall(function()
        getgenv().ANUI_Window = nil -- Unlink the window var
        
        local core = game:GetService("CoreGui")
        -- Brute force delete the UI to prevent hanging
        for _, n in ipairs({"Nebublox", "ANUI", "Orion", "Shadow", "ScreenGui", "NebuWatermark"}) do
            local f = core:FindFirstChild(n)
            if f then f:Destroy() end
        end
    end)
end

getgenv().NebuBlox_Loaded = true

-- [1] SERVICES
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local PlaceId = game.PlaceId
local UniverseId = game.GameId

-- [2] GAME CONFIGURATION
local GameIds = {
    [98199457453897] = { Name = "Anime Storm 2", Url = "https://raw.githubusercontent.com/LilNugOfWisdom/NebubloxUI/main/Scripts/anime_storm_sim2_anui.lua" },
    [136063393518705] = { Name = "Anime Destroyers", Url = "https://raw.githubusercontent.com/LilNugOfWisdom/NebubloxUI/main/Scripts/anime_destroyers_anui.lua" },
    [98808987021584] = { Name = "Zero to Hero", Url = "https://raw.githubusercontent.com/LilNugOfWisdom/NebubloxUI/main/Scripts/zero_to_hero_anui.lua" },
    [133898125416947] = { Name = "Anime Creatures", Url = "https://raw.githubusercontent.com/LilNugOfWisdom/NebubloxUI/main/Scripts/Anime_Creatures_Anui.lua" },
}

-- [3] LIBRARY LOADER
local function LoadScript(url)
    if isfile and isfile("ANUI_source.lua") then return readfile("ANUI_source.lua") end
    local success, result = pcall(function() return game:HttpGet(url) end)
    if not success then success, result = pcall(function() return HttpGet(url) end) end
    return result
end

local ANUI = loadstring(LoadScript("https://raw.githubusercontent.com/ANHub-Script/ANUI/refs/heads/main/dist/main.lua"))()

-- [4] UI SETUP
local Window = ANUI:CreateWindow({
    Title = "Nebublox", 
    Author = "He Who Remains Lil'Nug",
    Folder = "Nebublox",
    Icon = "rbxthumb://type=Asset&id=120742610207737&w=150&h=150", 
    IconSize = 63,
    Theme = "Dark", 
})
getgenv().ANUI_Window = Window

-- [5] VISUAL FIXES (Pitch Black + Gradients)
task.spawn(function()
    -- 1. Icon Fix
    local function FixIcon(root)
        if not root then return end
        for _, img in ipairs(root:GetDescendants()) do
            if img:IsA("ImageLabel") and (img.Name == "Icon" or img.Name == "Logo" or (img.Image and img.Image:find("120742610207737"))) then
                img.ScaleType = Enum.ScaleType.Crop; img.BackgroundTransparency = 1; img.BackgroundColor3 = Color3.new(0,0,0)
                img.Size = UDim2.new(3, 0, 3, 0)
                local corner = img:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", img)
                corner.CornerRadius = UDim.new(1, 0)
            end
        end
    end

    -- 2. Theme Fix
    local function ApplyToFrame(frame)
        if not frame then return end
        frame.BackgroundColor3 = Color3.new(0, 0, 0); frame.BackgroundTransparency = 0
        local old = frame:FindFirstChild("WindUIGradient") or frame:FindFirstChild("NebuGradient")
        if old then old:Destroy() end
        for _, v in ipairs(frame:GetDescendants()) do
            if (v:IsA("TextLabel") or v:IsA("TextButton")) and v.TextColor3.R < 0.2 then v.TextColor3 = Color3.new(1,1,1) end
        end
    end

    -- 3. Gradients
    local function ApplyGradientToTitle(root)
        if not root then return end
        for _, lbl in ipairs(root:GetDescendants()) do
            if lbl:IsA("TextLabel") then
                if (lbl.Text == "Nebublox" or lbl.Text:find("Nebublox")) and not lbl:FindFirstChild("TitleGrad") and lbl.Name ~= "NebubloxWelcome" then
                    local grad = Instance.new("UIGradient")
                    grad.Name = "TitleGrad"
                    grad.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(88, 101, 242)),   -- Blue
                        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(170, 0, 255)),  -- Violet
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(88, 101, 242))    -- Blue
                    })
                    grad.Rotation = 0
                    grad.Parent = lbl
                    task.spawn(function()
                        local speed = 2
                        while lbl and lbl.Parent do
                            local angle = (tick() * speed * 45) % 360
                            grad.Rotation = angle
                            task.wait() 
                        end
                    end)
                elseif lbl.Text:find("He Who Remains Lil'Nug") and not lbl:FindFirstChild("AuthorGrad") then
                    local grad = Instance.new("UIGradient")
                    grad.Name = "AuthorGrad"
                    grad.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 255)),     -- Blue
                        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 215, 0)), -- Gold
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 255))      -- Blue
                    })
                    grad.Parent = lbl
                    task.spawn(function()
                        local speed = 0.5
                        while lbl and lbl.Parent do
                            local pos = (tick() * speed) % 1
                            grad.Offset = Vector2.new(pos - 0.5, 0)
                            task.wait()
                        end
                    end)
                end
            end
        end
    end
    
    for i = 1, 10 do
        FixIcon(CoreGui:FindFirstChild("Nebublox"))
        if Window.UIElements and Window.UIElements.Main then 
            ApplyToFrame(Window.UIElements.Main)
            ApplyToFrame(Window.UIElements.Main:FindFirstChild("Main")) 
            ApplyGradientToTitle(Window.UIElements.Main)
        end
        task.wait(0.5)
    end
end)

-- [6] TABS & CONTENT

-- >> TAB: HOME
local HomeTab = Window:Tab({ Title = "Home", Icon = "home" })

-- Banner Section
local BannerSection = HomeTab:Section({ Title = " ", Icon = "", Opened = true })


-- 1. Placeholder Text (Will be replaced by Image)
BannerSection:Paragraph({ Title = "BANNER_PLACEHOLDER", Content = "" })

-- 2. Placeholder for Welcome Text (Will include Rich Text)
BannerSection:Paragraph({ Title = "WELCOME_PLACEHOLDER", Content = "" })

-- Banner Injector Logic (Single execution)
task.spawn(function()
    task.wait(0.5)
    local BannerImage = "rbxthumb://type=Asset&id=132367447015620&w=768&h=432"
    local function InjectBanner()
        local function ScanRoot(root)
             local foundAny = false
             for _, v in ipairs(root:GetDescendants()) do
                 if v:IsA("TextLabel") then
                     if v.Text == "BANNER_PLACEHOLDER" then
                         local Container = v.Parent 
                         if Container and Container.Parent then 
                             -- HIDE BUBBLE for Banner Container
                             if Container:IsA("Frame") then Container.BackgroundTransparency = 1; Container.BorderSizePixel = 0 end
                             if Container.Parent:IsA("Frame") then Container.Parent.BackgroundTransparency = 1; Container.Parent.BorderSizePixel = 0 end
                             
                             local NewBanner = Instance.new("ImageLabel")
                             NewBanner.Name = "NebubloxBanner"
                             NewBanner.Parent = Container.Parent 
                             NewBanner.Size = UDim2.new(1, 0, 0, 150)
                             NewBanner.BackgroundTransparency = 1
                             NewBanner.Image = BannerImage
                             NewBanner.ScaleType = Enum.ScaleType.Fit
                             
                             if Container:FindFirstChild("LayoutOrder") then 
                                 NewBanner.LayoutOrder = Container.LayoutOrder 
                             end
                             
                             Container:Destroy()
                             foundAny = true
                         end
                     
                     elseif v.Text == "WELCOME_PLACEHOLDER" then
                         local Container = v.Parent
                         if Container and Container.Parent then
                             -- HIDE BUBBLE for Text Container
                             if Container:IsA("Frame") then Container.BackgroundTransparency = 1; Container.BorderSizePixel = 0 end
                             if Container.Parent:IsA("Frame") then Container.Parent.BackgroundTransparency = 1; Container.Parent.BorderSizePixel = 0 end

                             local NewText = Instance.new("TextLabel")
                             NewText.Name = "NebubloxWelcome"
                             NewText.Parent = Container.Parent
                             NewText.Size = UDim2.new(1, 0, 0, 30) -- Height for text
                             NewText.BackgroundTransparency = 1
                             NewText.Text = '<font color="#ffffff">Welcome and thank you for choosing </font><font color="#a855f7">Nebublox</font><font color="#ffffff"> 🌠</font>'
                             NewText.RichText = true
                             NewText.Font = Enum.Font.GothamBold
                             NewText.TextSize = 16
                             NewText.TextColor3 = Color3.new(1,1,1)
                             NewText.TextXAlignment = Enum.TextXAlignment.Center
                             
                             if Container:FindFirstChild("LayoutOrder") then
                                 NewText.LayoutOrder = Container.LayoutOrder
                             end
                             
                             Container:Destroy()
                             foundAny = true
                         end
                     end
                 end
             end
             return foundAny
        end
        if not ScanRoot(CoreGui) then ScanRoot(player:WaitForChild("PlayerGui")) end
    end
    -- Retry a few times but ensure we only inject once
    for i=1,10 do 
        if InjectBanner() then break end 
        task.wait(0.5) 
    end
end)

-- GAMES SECTION
local ListSection = HomeTab:Section({ Title = "Supported Games", Icon = "list", Opened = true })

local sortedGames = {}
for id, data in pairs(GameIds) do table.insert(sortedGames, data) end
table.sort(sortedGames, function(a,b) return a.Name < b.Name end)

for _, data in ipairs(sortedGames) do
    ListSection:Button({
        Title = data.Name,
        Icon = "play",
        Callback = function()
            ANUI:Notify({Title = "Nebublox", Content = "Loading " .. data.Name, Icon = "download", Duration = 2})
            task.wait(0.5)
            if Window then 
                -- Manual destroy to prevent infinite yield
                pcall(function() 
                    local core = game:GetService("CoreGui")
                    local gui = core:FindFirstChild("Nebublox")
                    if gui then gui:Destroy() end
                end)
            end
            loadstring(game:HttpGet(data.Url))()
        end
    })
end

-- SOCIALS SECTION
local SocialSection = HomeTab:Section({ Title = "Community", Icon = "users", Opened = true })
SocialSection:Button({ Title = "Join Discord", Icon = "message-square", Callback = function() setclipboard("https://discord.gg/nebublox") end })
SocialSection:Button({ Title = "https://nebublox.space", Icon = "globe", Callback = function() setclipboard("https://nebublox.space") end })

ANUI:Notify({Title = "Nebublox", Content = "Universal Hub Loaded", Icon = "check", Duration = 3})
