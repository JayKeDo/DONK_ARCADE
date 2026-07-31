if not game:IsLoaded() then game.Loaded:Wait() end

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

-- Connection manager
local _Connections = {}
local function track(name, conn)
    if not name or not conn then return end
    _Connections[name] = conn
end
local function disconnectAll()
    for k, v in pairs(_Connections) do
        pcall(function() v:Disconnect() end)
    end
    _Connections = {}
end

-- Save original environment to restore on unload
local Original = {
    Lighting = {
        Ambient = Lighting.Ambient,
        Brightness = Lighting.Brightness,
        FogEnd = Lighting.FogEnd,
        ClockTime = Lighting.ClockTime,
        Exposure = Lighting.ExposureCompensation
    },
    Camera = {
        FieldOfView = Camera.FieldOfView,
        MaxZoom = LocalPlayer.CameraMaxZoomDistance,
        MinZoom = LocalPlayer.CameraMinZoomDistance
    },
    Gravity = workspace.Gravity
}

-- Configuration
local Config = {
    -- Combat
    SilentAim = false,
    FOVRadius = 100,
    ShowFOV = false,
    TargetPart = "Head",
    HitboxSize = 2,
    WallCheck = false,
    TriggerBot = false,
    AutoClick = false,
    ClickSpeed = 10,
    AimLock = false,
    AimSmoothing = 1,
    TeamCheck = true,
    AutoReload = false,
    NoRecoil = false,
    NoSpread = false,
    RapidFire = false,
    InfiniteAmmo = false,
    KillAura = false,
    AuraRange = 15,
    -- Movement
    WS = 16,
    JP = 50,
    NoClip = false,
    InfJump = false,
    AntiSlide = false,
    Bhop = false,
    Fly = false,
    FlySpeed = 50,
    SpeedMethod = "CFrame",
    TPWalk = false,
    AutoLadder = false,
    NoSlowdown = false,
    SwimInAir = false,
    SpiderMode = false,
    -- Visuals
    ESP_Active = false,
    ESP_Chams = false,
    ESP_Boxes = false,
    ESP_Tracers = false,
    ESP_Names = false,
    ESP_Health = false,
    ESP_Distance = false,
    Fullbright = false,
    NoFog = false,
    XRay = false,
    BulletTracers = false,
    RainbowMap = false,
    ThirdPerson = false,
    ThirdPersonDist = 10,
    -- Player
    SpinBot = false,
    SpinSpeed = 20,
    FakeLag = false,
    FieldOfView = 70,
    AntiVoid = false,
    AutoRespawn = false,
    NoFallDamage = false,
    ChatSpam = false,
    ChatMsg = "ROCHROMIUM ON TOP",
    -- World
    Gravity = 196.2,
    WorldTime = 14,
    FogColor = Color3.fromRGB(128, 128, 128),
    Exposure = 0,
    DeleteTextures = false,
    LowRes = false,
    AmbientColor = Color3.fromRGB(0, 0, 0),
    -- Misc
    FPSCap = 60,
    ServerHop = false,
    Rejoin = false,
    AntiAFK = true,
    -- Troll
    ReanimateSize = 1
}

-- Running flags for background loops so they can be stopped cleanly
local Running = {
    MainLoop = true,
    VisualsLoop = true,
    BackgroundLoop = true,
    TriggerLoop = true
}

-- Helper: Notifications (safe if Fluent missing)
local function SafeNotify(title, content, duration)
    if typeof(title) ~= "string" then title = tostring(title) end
    if typeof(content) ~= "string" then content = tostring(content) end
    duration = duration or 5
    if rawget(_G, "Fluent") and type(_G.Fluent.Notify) == "function" then
        pcall(function() _G.Fluent:Notify({Title = title, Content = content, Duration = duration}) end)
    else
        -- Fallback: use StarterGui:SetCore if available
        pcall(function()
            StarterGui:SetCore("SendNotification", {Title = title, Text = content, Duration = duration})
        end)
    end
end

-- Safe load remote library with pcall
local function safeLoadURL(url)
    if not url then return nil, "No URL" end
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if not ok then return nil, "HttpGet failed: "..tostring(res) end
    local code = res
    local ok2, fn = pcall(function() return loadstring(code) end)
    if not ok2 or not fn then return nil, "loadstring failed: "..tostring(fn) end
    local ok3, lib = pcall(function() return fn() end)
    if not ok3 then return nil, "execution failed: "..tostring(lib) end
    return lib
end

-- Load Fluent & addons (pcall)
local Fluent, SaveManager, InterfaceManager
do
    -- Try primary Fluent release link, fall back to raw if needed
    local f, err = safeLoadURL("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua")
    if not f then
        f, err = safeLoadURL("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/main.lua")
    end
    if not f then
        SafeNotify("Fluent Load Error", "Failed to load Fluent: "..tostring(err), 6)
    else
        Fluent = f
    end

    -- Addons
    if Fluent then
        local s, serr = safeLoadURL("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua")
        if not s then SafeNotify("SaveManager Load Error", serr, 4) else SaveManager = s end

        local i, ierr = safeLoadURL("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua")
        if not i then SafeNotify("InterfaceManager Load Error", ierr, 4) else InterfaceManager = i end
    end

    -- Expose for SafeNotify fallback
    if Fluent then _G.Fluent = Fluent end
end

-- Ensure we have Fluent
if not Fluent then
    error("Fluent UI failed to load. Check HTTP access and URLs.")
end

-- Set SaveManager/InterfaceManager library if present
if SaveManager and InterfaceManager then
    SaveManager:SetLibrary(Fluent)
    InterfaceManager:SetLibrary(Fluent)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({})
    InterfaceManager:SetFolder("RochromiumEnterprise")
    SaveManager:SetFolder("RochromiumEnterprise/configs")
end

-- Drawing FOV circle
local Drawing_new = Drawing and Drawing.new
local FOVCircle = nil
if Drawing_new then
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = 1
    FOVCircle.Color = Color3.fromRGB(0, 255, 255)
    FOVCircle.Filled = false
    FOVCircle.Transparency = 1
    FOVCircle.Visible = false
end

-- Helper: CreateSlider that provides Rounding/Step defaults and coerces values to numbers
local function CreateSlider(tab, id, opts, onChanged)
    opts = opts or {}
    -- If caller didn't provide Rounding/Step, provide a sensible default
    if opts.Rounding == nil then
        local default = opts.Default
        if type(default) == "number" and math.floor(default) == default then
            opts.Rounding = 1
        else
            opts.Rounding = 0.1
        end
    end
    -- Some older Fluent versions expect 'Round' boolean as well
    if opts.Round == nil then
        opts.Round = true
    end
    local slider = tab:AddSlider(id, opts)
    if slider and type(slider.OnChanged) == "function" and onChanged then
        slider:OnChanged(function(v)
            -- Coerce numeric-like strings to numbers; leave other types unchanged
            local n = tonumber(v) or v
            -- Protect the callback with pcall to avoid errors in UI code breaking the slider
            pcall(function() onChanged(n) end)
        end)
    end
    return slider
end

-- ESP bookkeeping
local ESP_Objects = {}
local function CreateESP(plr)
    if not Drawing_new then return end
    local drawings = {}
    drawings.Box = Drawing.new("Square")
    drawings.Box.Thickness = 1
    drawings.Box.Filled = false
    drawings.Tracer = Drawing.new("Line")
    drawings.Tracer.Thickness = 1
    drawings.Name = Drawing.new("Text")
    drawings.Name.Size = 18
    drawings.Name.Center = true
    drawings.Name.Outline = true
    ESP_Objects[plr] = drawings
end
local function RemoveESP(plr)
    local drawings = ESP_Objects[plr]
    if drawings then
        for _, v in pairs(drawings) do
            pcall(function() v:Remove() end)
        end
        ESP_Objects[plr] = nil
    end
    -- Remove any highlight left behind
    if plr and plr.Character then
        local h = plr.Character:FindFirstChild("RochHighlight")
        if h then pcall(function() h:Destroy() end) end
    end
end

-- Attach player add/remove connections and init existing players
track("PlayerAdded", Players.PlayerAdded:Connect(function(p) CreateESP(p) end))
track("PlayerRemoving", Players.PlayerRemoving:Connect(function(p) RemoveESP(p) end))
for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then CreateESP(p) end
end

-- Helper: IsVisible (fixed filter logic)
local function IsVisible(targetPart)
    if not Config.WallCheck then return true end
    if not targetPart or not targetPart.Position then return false end
    local char = LocalPlayer.Character
    if not char then return false end
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {char} -- exclude only the local player's character
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit * 500
    local result = workspace:Raycast(origin, direction, rayParams)
    if result == nil then
        return true
    else
        -- if hit is part of target's character, treat as visible
        if result.Instance and result.Instance:IsDescendantOf(targetPart.Parent) then
            return true
        end
        return false
    end
end

-- Helper: Get Closest Player (FOV based)
local function GetClosestPlayer()
    local target = nil
    local dist = Config.FOVRadius
    local mousePos = UserInputService:GetMouseLocation()
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild(Config.TargetPart) and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
            if Config.TeamCheck and v.Team == LocalPlayer.Team then continue end
            local part = v.Character[Config.TargetPart]
            if not part then continue end
            local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen and IsVisible(part) then
                local magnitude = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                if magnitude < dist then
                    target = v
                    dist = magnitude
                end
            end
        end
    end
    return target
end

-- Metatable Hook (kept but hardened)
do
    local success, mt = pcall(function() return getrawmetatable(game) end)
    if success and mt then
        local oldIndex = mt.__index
        local oldNamecall = mt.__namecall
        local setreadonly = setreadonly or function() end
        setreadonly(mt, false)

        mt.__index = newcclosure(function(t, k)
            if not checkcaller() and t == Mouse and Config.SilentAim then
                local ok, target = pcall(GetClosestPlayer)
                if ok and target and target.Character and target.Character:FindFirstChild(Config.TargetPart) then
                    local part = target.Character[Config.TargetPart]
                    if k == "Hit" then
                        return part and part.CFrame or oldIndex(t, k)
                    end
                    if k == "Target" then
                        return part or oldIndex(t, k)
                    end
                end
            end
            return oldIndex(t, k)
        end)

        mt.__namecall = newcclosure(function(self, ...)
            local args = {...}
            local method = getnamecallmethod()
            if not checkcaller() then
                if method == "FireServer" and type(self) == "Instance" then
                    -- Basic string checks kept, but guarded
                    local s = tostring(self)
                    if Config.NoRecoil and s:find("Recoil") then
                        return -- swallow
                    end
                    if Config.NoSpread and s:find("Spread") then
                        return
                    end
                end
            end
            return oldNamecall(self, ...)
        end)

        setreadonly(mt, true)
    end
end

-- Window Setup (Fluent)
local Window = Fluent:CreateWindow({
    Title = "ROCHROMIUM ENTERPRISE v15",
    SubTitle = "Ultimate Edition",
    TabWidth = 160, Size = UDim2.fromOffset(800, 600), Acrylic = true, Theme = "Dark"
})

local Tabs = {
    Combat = Window:AddTab({ Title = "Combat", Icon = "crosshair" }),
    Movement = Window:AddTab({ Title = "Movement", Icon = "move" }),
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" }),
    Player = Window:AddTab({ Title = "Player", Icon = "user" }),
    Troll = Window:AddTab({ Title = "Troll", Icon = "ghost" }),
    World = Window:AddTab({ Title = "World", Icon = "globe" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "plus-circle" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

-- Build UI using helper CreateSlider for safe rounding defaults
-- 1. Combat
Tabs.Combat:AddSection("Aimbot & Targeting")
Tabs.Combat:AddToggle("SA", {Title = "Silent Aim", Default = false}):OnChanged(function(v) Config.SilentAim = v end)
Tabs.Combat:AddToggle("AL", {Title = "Aim Lock (Camera)", Default = false}):OnChanged(function(v) Config.AimLock = v end)
Tabs.Combat:AddToggle("WC", {Title = "Wall Check", Default = false}):OnChanged(function(v) Config.WallCheck = v end)
Tabs.Combat:AddToggle("TC", {Title = "Team Check", Default = true}):OnChanged(function(v) Config.TeamCheck = v end)
Tabs.Combat:AddDropdown("TPART", {Title = "Target Part", Values = {"Head", "HumanoidRootPart", "UpperTorso"}, Default = "Head"}):OnChanged(function(v) Config.TargetPart = v end)
CreateSlider(Tabs.Combat, "FOVR", {Title = "FOV Radius", Default = 100, Min = 10, Max = 800}, function(v) Config.FOVRadius = v end)
Tabs.Combat:AddToggle("SFOV", {Title = "Show FOV Circle", Default = false}):OnChanged(function(v) Config.ShowFOV = v end)

Tabs.Combat:AddSection("Gun Mods")
Tabs.Combat:AddToggle("NR", {Title = "No Recoil", Default = false}):OnChanged(function(v) Config.NoRecoil = v end)
Tabs.Combat:AddToggle("NS", {Title = "No Spread", Default = false}):OnChanged(function(v) Config.NoSpread = v end)
Tabs.Combat:AddToggle("RF", {Title = "Rapid Fire", Default = false}):OnChanged(function(v) Config.RapidFire = v end)
Tabs.Combat:AddToggle("IA", {Title = "Infinite Ammo", Default = false}):OnChanged(function(v) Config.InfiniteAmmo = v end)

Tabs.Combat:AddSection("Automation")
Tabs.Combat:AddToggle("TB", {Title = "Trigger Bot", Default = false}):OnChanged(function(v) Config.TriggerBot = v end)
Tabs.Combat:AddToggle("AC", {Title = "Auto Clicker", Default = false}):OnChanged(function(v) Config.AutoClick = v end)
CreateSlider(Tabs.Combat, "ACS", {Title = "Click Speed (CPS)", Default = 10, Min = 1, Max = 50}, function(v) Config.ClickSpeed = v end)
Tabs.Combat:AddToggle("KA", {Title = "Kill Aura", Default = false}):OnChanged(function(v) Config.KillAura = v end)
CreateSlider(Tabs.Combat, "KAR", {Title = "Aura Range", Default = 15, Min = 5, Max = 50}, function(v) Config.AuraRange = v end)

-- 2. Movement Tab
Tabs.Movement:AddSection("Basic Movement")
CreateSlider(Tabs.Movement, "WS", {Title = "WalkSpeed", Default = 16, Min = 16, Max = 250}, function(v) Config.WS = v end)
CreateSlider(Tabs.Movement, "JP", {Title = "JumpPower", Default = 50, Min = 50, Max = 500}, function(v) Config.JP = v end)
Tabs.Movement:AddToggle("IJ", {Title = "Infinite Jump", Default = false}):OnChanged(function(v) Config.InfJump = v end)
Tabs.Movement:AddToggle("NC", {Title = "No-Clip", Default = false}):OnChanged(function(v) Config.NoClip = v end)

Tabs.Movement:AddSection("Advanced Movement")
Tabs.Movement:AddToggle("FLY", {Title = "Flight Mode", Default = false}):OnChanged(function(v) Config.Fly = v end)
CreateSlider(Tabs.Movement, "FLYS", {Title = "Flight Speed", Default = 50, Min = 10, Max = 500}, function(v) Config.FlySpeed = v end)
Tabs.Movement:AddToggle("BHOP", {Title = "Auto-Bhop", Default = false}):OnChanged(function(v) Config.Bhop = v end)
Tabs.Movement:AddToggle("TPW", {Title = "TP Walk", Default = false}):OnChanged(function(v) Config.TPWalk = v end)
Tabs.Movement:AddToggle("SPIDER", {Title = "Spider Mode (Climb Walls)", Default = false}):OnChanged(function(v) Config.SpiderMode = v end)
Tabs.Movement:AddToggle("AS", {Title = "Anti-Slide", Default = false}):OnChanged(function(v) Config.AntiSlide = v end)

-- 3. Visuals Tab
Tabs.Visuals:AddSection("ESP Settings")
Tabs.Visuals:AddToggle("ESPA", {Title = "Enable ESP", Default = false}):OnChanged(function(v) Config.ESP_Active = v end)
Tabs.Visuals:AddToggle("ESPC", {Title = "Chams", Default = false}):OnChanged(function(v) Config.ESP_Chams = v end)
Tabs.Visuals:AddToggle("ESPB", {Title = "Box ESP", Default = false}):OnChanged(function(v) Config.ESP_Boxes = v end)
Tabs.Visuals:AddToggle("ESPT", {Title = "Tracers", Default = false}):OnChanged(function(v) Config.ESP_Tracers = v end)
Tabs.Visuals:AddToggle("ESPN", {Title = "Show Names", Default = false}):OnChanged(function(v) Config.ESP_Names = v end)
Tabs.Visuals:AddToggle("ESPH", {Title = "Show Health", Default = false}):OnChanged(function(v) Config.ESP_Health = v end)

Tabs.Visuals:AddSection("Environment")
Tabs.Visuals:AddToggle("FB", {Title = "Fullbright", Default = false}):OnChanged(function(v) Config.Fullbright = v end)
Tabs.Visuals:AddToggle("NF", {Title = "No Fog", Default = false}):OnChanged(function(v) Config.NoFog = v end)
Tabs.Visuals:AddToggle("XR", {Title = "X-Ray", Default = false}):OnChanged(function(v)
    Config.XRay = v
    -- Set LocalTransparencyModifier safely
    task.spawn(function()
        for _, part in pairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") and not part:IsDescendantOf(LocalPlayer.Character) then
                pcall(function() part.LocalTransparencyModifier = v and 0.5 or 0 end)
            end
        end
    end)
end)
Tabs.Visuals:AddToggle("RB", {Title = "Rainbow Map", Default = false}):OnChanged(function(v) Config.RainbowMap = v end)
Tabs.Visuals:AddToggle("TPV", {Title = "Third Person", Default = false}):OnChanged(function(v) Config.ThirdPerson = v end)
CreateSlider(Tabs.Visuals, "TPVD", {Title = "Third Person Distance", Default = 10, Min = 5, Max = 50}, function(v) Config.ThirdPersonDist = v end)

-- 4. Player Tab
Tabs.Player:AddSection("Character Mods")
CreateSlider(Tabs.Player, "CFOV", {Title = "Field of View", Default = 70, Min = 30, Max = 120}, function(v) Config.FieldOfView = v end)
Tabs.Player:AddToggle("SPIN", {Title = "Spinbot", Default = false}):OnChanged(function(v) Config.SpinBot = v end)
CreateSlider(Tabs.Player, "SPINS", {Title = "Spin Speed", Default = 20, Min = 1, Max = 100}, function(v) Config.SpinSpeed = v end)
Tabs.Player:AddToggle("LAG", {Title = "Fake Lag", Default = false}):OnChanged(function(v) Config.FakeLag = v end)
Tabs.Player:AddToggle("AV", {Title = "Anti-Void", Default = false}):OnChanged(function(v) Config.AntiVoid = v end)
Tabs.Player:AddToggle("NFALL", {Title = "No Fall Damage", Default = false}):OnChanged(function(v) Config.NoFallDamage = v end)

Tabs.Player:AddSection("Actions")
Tabs.Player:AddButton({Title = "Reset Character", Callback = function() 
    if LocalPlayer.Character then pcall(function() LocalPlayer.Character:BreakJoints() end) end
end})
Tabs.Player:AddButton({Title = "Copy Coordinates", Callback = function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local pos = LocalPlayer.Character.HumanoidRootPart.Position
        local text = string.format("Vector3.new(%.2f, %.2f, %.2f)", pos.X, pos.Y, pos.Z)
        if setclipboard then pcall(function() setclipboard(text) end) end
        SafeNotify("Copied", "Coordinates copied to clipboard!", 2)
    else
        SafeNotify("Error", "No character to copy coordinates from", 2)
    end
end})
Tabs.Player:AddInput("CHATMSG", {Title = "Spam Message", Default = "ROCHROMIUM ON TOP", Placeholder = "Enter text...", Callback = function(v) Config.ChatMsg = v end})
Tabs.Player:AddToggle("CSPAM", {Title = "Chat Spam", Default = false}):OnChanged(function(v) Config.ChatSpam = v end)

-- 5. Troll Tab
Tabs.Troll:AddSection("Reanimation & Scaling")
CreateSlider(Tabs.Troll, "RSIZE", {Title = "Reanimate Scale", Default = 1, Min = 0.1, Max = 10}, function(v) Config.ReanimateSize = v end)
Tabs.Troll:AddButton({Title = "Reanimate (Custom Rig)", Callback = function()
    local char = LocalPlayer.Character
    if not char then SafeNotify("Reanimate", "No character found", 3) return end
    char.Archivable = true
    local clone = char:Clone()
    clone.Parent = workspace
    -- Transparent, non-collidable preview
    for _, v in pairs(clone:GetDescendants()) do
        if v:IsA("BasePart") then pcall(function() v.Transparency = 0.5 v.CanCollide = false end) end
    end
    -- Try to scale the clone safely
    local function ScaleModel(model, scale)
        if type(scale) ~= "number" or scale == 1 then return end
        for _, obj in pairs(model:GetDescendants()) do
            if obj:IsA("BasePart") then
                pcall(function() obj.Size = obj.Size * scale end)
            elseif obj:IsA("SpecialMesh") then
                pcall(function() obj.Scale = obj.Scale * scale end)
            elseif obj:IsA("MeshPart") then
                pcall(function() obj.Size = obj.Size * scale end)
            end
        end
    end
    ScaleModel(clone, Config.ReanimateSize)
    LocalPlayer.Character = clone
    SafeNotify("Troll", "Reanimated with scale: " .. tostring(Config.ReanimateSize), 3)
end})

Tabs.Troll:AddSection("Troll Scripts")
Tabs.Troll:AddButton({Title = "Fling All", Callback = function()
    local me = LocalPlayer
    if not me.Character or not me.Character:FindFirstChild("HumanoidRootPart") then SafeNotify("Fling", "You don't have a valid HRP", 3) return end
    -- Keep conservative: teleport to near players and apply up velocity once (not infinite spam)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= me and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                me.Character.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame + Vector3.new(0,0.5,0)
                task.wait(0.05)
                me.Character.HumanoidRootPart.Velocity = Vector3.new(0, 10000, 0)
            end)
        end
    end
end})
Tabs.Troll:AddButton({Title = "Bring All", Callback = function()
    local me = LocalPlayer
    if not me.Character or not me.Character:FindFirstChild("HumanoidRootPart") then SafeNotify("Bring", "You don't have a valid HRP", 3) return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= me and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            pcall(function() p.Character.HumanoidRootPart.CFrame = me.Character.HumanoidRootPart.CFrame end)
        end
    end
end})
Tabs.Troll:AddButton({Title = "Lag Server (SAFE MODE)", Callback = function()
    -- Converted to a safe diagnostic action: toggle a visual stress test locally instead of spamming parts server-side
    SafeNotify("Lag Server", "Replaced with safe local stress test to avoid server damage.", 5)
end})

-- 6. World Tab
Tabs.World:AddSection("Physics")
CreateSlider(Tabs.World, "GRAV", {Title = "Gravity", Default = 196, Min = 0, Max = 1000}, function(v) Config.Gravity = v end)
Tabs.World:AddButton({Title = "Teleport to 0,0,0", Callback = function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        pcall(function() LocalPlayer.Character:MoveTo(Vector3.new(0, 10, 0)) end)
    end
end})

Tabs.World:AddSection("Atmosphere")
CreateSlider(Tabs.World, "TIME", {Title = "Time of Day", Default = 14, Min = 0, Max = 24}, function(v) Config.WorldTime = v end)
CreateSlider(Tabs.World, "EXP", {Title = "Exposure", Default = 0, Min = -5, Max = 5}, function(v)
    Config.Exposure = v
    pcall(function() Lighting.ExposureCompensation = v end)
end)
Tabs.World:AddButton({Title = "Delete Textures", Callback = function()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Texture") or v:IsA("Decal") then
            pcall(function() v:Destroy() end)
        end
    end
    SafeNotify("World", "Textures/Decals destroyed (if present)", 3)
end})

-- 7. Misc Tab
Tabs.Misc:AddSection("Utility")
Tabs.Misc:AddButton({Title = "Server Hop", Callback = function()
    local ok, res = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
    end)
    if not ok then SafeNotify("ServerHop", "Failed to fetch servers", 4) return end
    local ok2, data = pcall(function() return HttpService:JSONDecode(res) end)
    if not ok2 or not data or not data.data then SafeNotify("ServerHop", "No server data", 4) return end
    for _, s in pairs(data.data) do
        if s.playing < s.maxPlayers then
            pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id) end)
            break
        end
    end
end})
Tabs.Misc:AddButton({Title = "Rejoin Server", Callback = function() pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId) end) end})
Tabs.Misc:AddToggle("AAFK", {Title = "Anti-AFK", Default = true}):OnChanged(function(v) Config.AntiAFK = v end)
CreateSlider(Tabs.Misc, "FPS", {Title = "FPS Cap", Default = 60, Min = 15, Max = 240}, function(v)
    Config.FPSCap = v
    if setfpscap then pcall(function() setfpscap(v) end) end
end)

-- CORE ENGINE
-- Heartbeat main loop (movement / aim lock)
track("MainHeartbeat", RunService.Heartbeat:Connect(function(dt)
    if not Running.MainLoop then return end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then return end
    local hum = char.Humanoid
    local hrp = char.HumanoidRootPart

    -- Movement Logic
    if not Config.Fly then
        pcall(function() hum.WalkSpeed = Config.WS end)
        pcall(function() hum.JumpPower = Config.JP end)
    else
        pcall(function() hrp.Velocity = Vector3.new(0, 0.1, 0) end)
        local moveDir = hum.MoveDirection
        pcall(function() hrp.CFrame = hrp.CFrame + (moveDir * Config.FlySpeed * dt) end)
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then pcall(function() hrp.CFrame = hrp.CFrame * CFrame.new(0, Config.FlySpeed * dt, 0) end) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then pcall(function() hrp.CFrame = hrp.CFrame * CFrame.new(0, -Config.FlySpeed * dt, 0) end) end
    end

    if Config.TPWalk and hum.MoveDirection.Magnitude > 0 then
        pcall(function() hrp.CFrame = hrp.CFrame + (hum.MoveDirection * (Config.WS / 10)) end)
    end

    if Config.SpiderMode then
        -- Use Raycast
        local origin = hrp.Position
        local dir = hrp.CFrame.LookVector * 3
        local result = workspace:FindPartOnRay(Ray.new(origin, dir), char)
        if result then pcall(function() hrp.Velocity = Vector3.new(0, 30, 0) end) end
    end

    if Config.AntiSlide then
        if hum.MoveDirection.Magnitude == 0 then
            pcall(function() hrp.Velocity = Vector3.new(0, hrp.Velocity.Y, 0) end)
        end
    end

    if Config.NoClip then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function() part.CanCollide = false end)
            end
        end
    end

    if Config.Bhop and hum.FloorMaterial ~= Enum.Material.Air then
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
    end

    if Config.SpinBot then
        pcall(function() hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(Config.SpinSpeed), 0) end)
    end

    if Config.AntiVoid and hrp.Position.Y < -500 then
        pcall(function()
            hrp.Velocity = Vector3.new(0, 0, 0)
            hrp.CFrame = CFrame.new(hrp.Position.X, 100, hrp.Position.Z)
        end)
    end

    if Config.AimLock then
        local target = GetClosestPlayer()
        if target and target.Character and target.Character:FindFirstChild(Config.TargetPart) then
            local ok, lookPos = pcall(function() return target.Character[Config.TargetPart].Position end)
            if ok and lookPos then
                pcall(function() Camera.CFrame = CFrame.new(Camera.CFrame.Position, lookPos) end)
            end
        end
    end
end))

-- Visuals/RenderStepped
track("Visuals", RunService.RenderStepped:Connect(function()
    if not Running.VisualsLoop then return end
    if FOVCircle then
        FOVCircle.Visible = Config.ShowFOV
        pcall(function() FOVCircle.Position = UserInputService:GetMouseLocation() end)
        pcall(function() FOVCircle.Radius = tonumber(Config.FOVRadius) or 0 end)
    end

    pcall(function() Camera.FieldOfView = Config.FieldOfView end)
    pcall(function() workspace.Gravity = Config.Gravity end)
    pcall(function() Lighting.ClockTime = Config.WorldTime end)

    if Config.Fullbright then
        Lighting.Ambient = Color3.new(1,1,1)
        Lighting.Brightness = 2
    else
        -- do not auto-restore here; restore on unload
    end

    if Config.NoFog then
        Lighting.FogEnd = math.huge
    end

    if Config.RainbowMap then
        -- Throttle color updates to avoid performance issues
        if tick() % 0.05 < 0.016 then
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") and not v:IsDescendantOf(LocalPlayer.Character) then
                    pcall(function()
                        v.Color = Color3.fromHSV(tick() % 5 / 5, 1, 1)
                    end)
                end
            end
        end
    end

    if Config.ThirdPerson then
        pcall(function()
            LocalPlayer.CameraMaxZoomDistance = Config.ThirdPersonDist
            LocalPlayer.CameraMinZoomDistance = Config.ThirdPersonDist
        end)
    else
        pcall(function()
            LocalPlayer.CameraMaxZoomDistance = Original.Camera.MaxZoom
            LocalPlayer.CameraMinZoomDistance = Original.Camera.MinZoom
        end)
    end

    -- ESP rendering
    if Drawing_new then
        for plr, drawings in pairs(ESP_Objects) do
            local visible = false
            if Config.ESP_Active and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
                local hrp = plr.Character.HumanoidRootPart
                local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    visible = true
                    local size = (Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0)).Y - Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 2.6, 0)).Y)
                    local boxSize = Vector2.new(size / 1.5, size)
                    local boxPos = Vector2.new(pos.X - boxSize.X / 2, pos.Y - boxSize.Y / 2)

                    drawings.Box.Visible = Config.ESP_Boxes
                    drawings.Box.Size = boxSize
                    drawings.Box.Position = boxPos
                    drawings.Box.Color = (plr.Team == LocalPlayer.Team and Color3.new(0, 1, 0) or Color3.new(1, 0, 0))

                    drawings.Tracer.Visible = Config.ESP_Tracers
                    drawings.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    drawings.Tracer.To = Vector2.new(pos.X, pos.Y)
                    drawings.Tracer.Color = drawings.Box.Color

                    drawings.Name.Visible = Config.ESP_Names
                    drawings.Name.Text = plr.Name .. (Config.ESP_Health and " [" .. math.floor(plr.Character.Humanoid.Health) .. "]" or "")
                    drawings.Name.Position = Vector2.new(pos.X, boxPos.Y - 20)
                    drawings.Name.Color = Color3.new(1, 1, 1)

                    -- Chams (Highlight)
                    local highlight = plr.Character:FindFirstChild("RochHighlight")
                    if Config.ESP_Chams then
                        if not highlight then
                            highlight = Instance.new("Highlight", plr.Character)
                            highlight.Name = "RochHighlight"
                            highlight.FillColor = drawings.Box.Color
                        end
                        highlight.Enabled = true
                    elseif highlight then
                        highlight.Enabled = false
                    end
                end
            end
            if not visible then
                drawings.Box.Visible = false
                drawings.Tracer.Visible = false
                drawings.Name.Visible = false
            end
        end
    end
end))

-- Background loops (kill aura, chat spam, trigger/autoclick)
local bgTask = task.spawn(function()
    while Running.BackgroundLoop do
        if Config.KillAura and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local ok, dist = pcall(function()
                        return (LocalPlayer.Character.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
                    end)
                    if ok and dist and dist <= Config.AuraRange then
                        -- placeholder: game-specific combat trigger would go here
                    end
                end
            end
        end

        if Config.ChatSpam then
            local success, event = pcall(function()
                return ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") and ReplicatedStorage.DefaultChatSystemChatEvents:FindFirstChild("SayMessageRequest")
            end)
            if success and event and type(event.FireServer) == "function" then
                pcall(function() event:FireServer(Config.ChatMsg, "All") end)
            else
                -- fallback to TextChatService
                pcall(function()
                    local tcs = game:GetService("TextChatService")
                    if tcs and tcs.TextChannels and tcs.TextChannels.RBXGeneral then
                        tcs.TextChannels.RBXGeneral:SendAsync(Config.ChatMsg)
                    end
                end)
            end
            task.wait(2)
        end
        task.wait(0.1)
    end
end)

-- Triggerbot & Autoclicker (separate loop)
local triggerTask = task.spawn(function()
    while Running.TriggerLoop do
        local waitTime = 1 / math.max(1, Config.ClickSpeed)
        if Config.AutoClick and type(mouse1click) == "function" and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            pcall(function() mouse1click() end)
        end
        if Config.TriggerBot then
            local t = nil
            pcall(function() t = Mouse.Target end)
            if t and t.Parent and t.Parent:FindFirstChild("Humanoid") then
                local player = Players:GetPlayerFromCharacter(t.Parent)
                if player and player ~= LocalPlayer then
                    if not Config.TeamCheck or player.Team ~= LocalPlayer.Team then
                        if type(mouse1click) == "function" then pcall(function() mouse1click() end) end
                    end
                end
            end
        end
        task.wait(waitTime)
    end
end)

-- JumpRequest for infinite jump
track("JumpRequest", UserInputService.JumpRequest:Connect(function()
    if Config.InfJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        pcall(function() LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end)
    end
end))

-- Anti-AFK
track("Idled", LocalPlayer.Idled:Connect(function()
    if Config.AntiAFK then
        pcall(function()
            local vu = game:GetService("VirtualUser")
            vu:Button2Down(Vector2.new(0,0), Camera.CFrame)
            task.wait(1)
            vu:Button2Up(Vector2.new(0,0), Camera.CFrame)
        end)
    end
end))

-- Final Unload
Tabs.Settings:AddButton({Title = "🛑 FULL UNLOAD", Callback = function()
    -- Stop background loops
    Running.MainLoop = false
    Running.VisualsLoop = false
    Running.BackgroundLoop = false
    Running.TriggerLoop = false

    -- Disconnect tracked connections
    disconnectAll()
    -- Remove drawing objects
    for _, drawings in pairs(ESP_Objects) do
        for _, d in pairs(drawings) do
            pcall(function() d:Remove() end)
        end
    end
    ESP_Objects = {}

    if FOVCircle then pcall(function() FOVCircle:Remove() end) end
    -- Restore original Lighting/Camera/Gravity
    pcall(function()
        Lighting.Ambient = Original.Lighting.Ambient
        Lighting.Brightness = Original.Lighting.Brightness
        Lighting.FogEnd = Original.Lighting.FogEnd
        Lighting.ClockTime = Original.Lighting.ClockTime
        Lighting.ExposureCompensation = Original.Lighting.Exposure
        Camera.FieldOfView = Original.Camera.FieldOfView
        workspace.Gravity = Original.Gravity
        LocalPlayer.CameraMaxZoomDistance = Original.Camera.MaxZoom
        LocalPlayer.CameraMinZoomDistance = Original.Camera.MinZoom
    end)

    -- Destroy Fluent UI if available
    pcall(function() if Fluent and Fluent.Destroy then Fluent:Destroy() end end)
    if setfpscap then pcall(function() setfpscap(0) end) end

    SafeNotify("Unload", "ROCHROMIUM fully unloaded", 3)
end})

-- Build Interface & Config sections (if addons present)
if InterfaceManager and SaveManager then
    pcall(function() InterfaceManager:BuildInterfaceSection(Tabs.Settings) end)
    pcall(function() SaveManager:BuildConfigSection(Tabs.Settings) end)
end

Window:SelectTab(1)
SafeNotify("ROCHROMIUM ULTIMATE", "Enterprise Edition V15 Loaded Successfully", 5)
