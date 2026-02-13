-- [[ NEBUBLOX NETWORK DEBUGGER ]]
local HttpService = game:GetService("HttpService")
local Analytics = game:GetService("RbxAnalyticsService")
local StarterGui = game:GetService("StarterGui")

warn("--- [NEBUBLOX DIAGNOSTIC START] ---")

-- 1. Identify Executor
local exec = identifyexecutor and identifyexecutor() or "Unknown Executor"
print("Executor Identity:", exec)

-- 2. Test HWID Capabilities
print("Testing HWID Retrieval...")
local hwid_s, hwid_r = pcall(function() return Analytics:GetClientId() end)
print("Standard GetClientId:", hwid_s, hwid_r)

if gethwid then
    print("Custom gethwid():", gethwid())
end

-- 3. Test Server Connectivity
local target = "https://darkmatterv1.onrender.com/api/verify_key?key=DEBUG_PING&hwid=DIAGNOSTIC"
print("Attempting connection to:", target)

local start = tick()
local s, r = pcall(function()
    return game:HttpGet(target)
end)
local duration = tick() - start

if s then
    warn("✅ CONNECTION SUCCESSFUL!")
    print("Latency:", duration, "s")
    print("Response Body:", r)
    
    StarterGui:SetCore("SendNotification", {
        Title = "Debug Result",
        Text = "Success! Server is reachable.",
        Duration = 5
    })
else
    warn("❌ CONNECTION FAILED!")
    warn("Error Message:", r)
    
    StarterGui:SetCore("SendNotification", {
        Title = "Debug Result",
        Text = "Failed! See Console (F9) for error.",
        Duration = 5
    })
end

warn("--- [NEBUBLOX DIAGNOSTIC END] ---")
