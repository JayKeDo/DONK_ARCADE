-- ============================================================================
-- ABSOLUTE.lua - personal "Matcha-style" advanced menu (LinoriaLib)
-- Runs inside the game on your executor. External-feel ESP/aim, movement,
-- visuals and HUD.
-- ============================================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

local Library
local libErr
local loadDone = false
task.spawn(function()
	local okx, errx = pcall(function()
		Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
	end)
	if not okx then libErr = errx end
	loadDone = true
end)

-- ----------------------------------------------------------------------------
-- LAUNCHER (shown before the main menu - pick Universal or a game script)
-- ----------------------------------------------------------------------------
local GAME_SCRIPTS = {
	{
		Name = "Universal Script",
		Desc = "Full ABSOLUTE suite: aimbot, ESP, movement, visuals & HUD.",
		Type = "universal",
	},
	-- Add game scripts here. Each entry loads exactly one script:
	--   Type = "source" -> Source holds the raw Lua code.
	--   Type = "file"   -> Path is a .lua file inside the executor folder (readfile).
	--   Type = "url"    -> Url is a raw script URL fetched with game:HttpGet.
	-- {
	-- 	Name = "My Game",
	-- 	Desc = "Game-specific script",
	-- 	Type = "source",
	-- 	Source = [[ print("hello") ]],
	-- },
}

local LauncherChoice = nil
local LauncherCanceled = false
local LaunchGui = Instance.new("ScreenGui")
LaunchGui.Name = "ABSOLUTE_Launcher"
LaunchGui.ResetOnSpawn = false
LaunchGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function()
	if syn and syn.protect_gui then syn.protect_gui(LaunchGui) end
end)
pcall(function() LaunchGui.Parent = game:GetService("CoreGui") end)
if not LaunchGui.Parent then pcall(function() LaunchGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end) end

local LaunchStatus = nil
local function launchSetStatus(text, isError)
	if LaunchStatus and LaunchGui and LaunchGui.Parent then
		LaunchStatus.Text = text or ""
		LaunchStatus.TextColor3 = (isError and Color3.fromRGB(255, 90, 90)) or Color3.fromRGB(150, 150, 150)
	end
end

function loadInfiniteYield()
	launchSetStatus("Loading Infinite Yield...")
	local ok, err = pcall(function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source", true))()
	end)
	if ok then
		launchSetStatus("Infinite Yield loaded.")
	else
		launchSetStatus("Infinite Yield failed: " .. tostring(err), true)
	end
	return ok
end

local function resolveScriptSource(entry)
	if entry.Type == "source" and type(entry.Source) == "string" then
		return entry.Source
	elseif entry.Type == "file" and type(readfile) == "function" and entry.Path then
		return readfile(entry.Path)
	elseif entry.Type == "url" and entry.Url then
		return game:HttpGet(entry.Url)
	end
	return nil
end

local function runGameScript(entry)
	local src = resolveScriptSource(entry)
	if type(src) ~= "string" or #src == 0 then
		launchSetStatus("No script source found for \"" .. entry.Name .. "\".", true)
		return false
	end
	local fn, err = loadstring(src, "=ABSOLUTE:" .. entry.Name)
	if not fn then
		launchSetStatus("Compile error in \"" .. entry.Name .. "\": " .. tostring(err), true)
		return false
	end
	local ok, runErr = pcall(fn)
	if not ok then
		launchSetStatus("Script error in \"" .. entry.Name .. "\": " .. tostring(runErr), true)
		return false
	end
	return true
end

local LaunchBackdrop = Instance.new("Frame")
LaunchBackdrop.Name = "Backdrop"
LaunchBackdrop.Size = UDim2.new(1, 0, 1, 0)
LaunchBackdrop.BackgroundColor3 = Color3.new(0, 0, 0)
LaunchBackdrop.BackgroundTransparency = 0.45
LaunchBackdrop.BorderSizePixel = 0
LaunchBackdrop.Active = true
LaunchBackdrop.Parent = LaunchGui

local LaunchPanel = Instance.new("Frame")
LaunchPanel.Name = "Panel"
LaunchPanel.AnchorPoint = Vector2.new(0.5, 0.5)
LaunchPanel.Position = UDim2.fromScale(0.5, 0.5)
LaunchPanel.Size = UDim2.fromOffset(440, 540)
LaunchPanel.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
LaunchPanel.BorderColor3 = Color3.fromRGB(66, 66, 66)
LaunchPanel.BorderSizePixel = 1
LaunchPanel.Parent = LaunchBackdrop
Instance.new("UICorner", LaunchPanel).CornerRadius = UDim.new(0, 8)

local LaunchAccent = Instance.new("Frame")
LaunchAccent.Size = UDim2.new(1, 0, 0, 3)
LaunchAccent.BackgroundColor3 = Color3.fromRGB(228, 228, 228)
LaunchAccent.BorderSizePixel = 0
LaunchAccent.Parent = LaunchPanel

local LaunchTitle = Instance.new("TextLabel")
LaunchTitle.Size = UDim2.new(1, 0, 0, 30)
LaunchTitle.Position = UDim2.new(0, 16, 0, 12)
LaunchTitle.BackgroundTransparency = 1
LaunchTitle.Text = "ABSOLUTE LAUNCHER"
LaunchTitle.TextXAlignment = Enum.TextXAlignment.Left
LaunchTitle.TextColor3 = Color3.fromRGB(240, 240, 240)
LaunchTitle.TextSize = 19
LaunchTitle.Font = Enum.Font.GothamBold
LaunchTitle.Parent = LaunchPanel

local LaunchSubtitle = Instance.new("TextLabel")
LaunchSubtitle.Size = UDim2.new(1, -32, 0, 18)
LaunchSubtitle.Position = UDim2.new(0, 16, 0, 44)
LaunchSubtitle.BackgroundTransparency = 1
LaunchSubtitle.Text = "Choose a script to load"
LaunchSubtitle.TextXAlignment = Enum.TextXAlignment.Left
LaunchSubtitle.TextColor3 = Color3.fromRGB(150, 150, 150)
LaunchSubtitle.TextSize = 13
LaunchSubtitle.Font = Enum.Font.Gotham
LaunchSubtitle.Parent = LaunchPanel

local LaunchScroll = Instance.new("ScrollingFrame")
LaunchScroll.Position = UDim2.new(0, 12, 0, 68)
LaunchScroll.Size = UDim2.new(1, -24, 0, 290)
LaunchScroll.BackgroundTransparency = 1
LaunchScroll.BorderSizePixel = 0
LaunchScroll.ScrollBarThickness = 4
LaunchScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
LaunchScroll.Parent = LaunchPanel
Instance.new("UIListLayout", LaunchScroll).Padding = UDim.new(0, 8)

local function launchButton(entry)
	local Btn = Instance.new("TextButton")
	Btn.Size = UDim2.new(1, 0, 0, 58)
	Btn.BorderColor3 = Color3.fromRGB(66, 66, 66)
	Btn.BorderSizePixel = 1
	Btn.Text = ""
	Btn.Parent = LaunchScroll
	Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)

	local NameLbl = Instance.new("TextLabel")
	NameLbl.BackgroundTransparency = 1
	NameLbl.Position = UDim2.new(0, 10, 0, 7)
	NameLbl.Size = UDim2.new(1, -20, 0, 20)
	NameLbl.Text = entry.Name
	NameLbl.TextXAlignment = Enum.TextXAlignment.Left
	NameLbl.TextColor3 = Color3.fromRGB(240, 240, 240)
	NameLbl.TextSize = 15
	NameLbl.Font = Enum.Font.GothamBold
	NameLbl.Parent = Btn

	local DescLbl = Instance.new("TextLabel")
	DescLbl.BackgroundTransparency = 1
	DescLbl.Position = UDim2.new(0, 10, 0, 29)
	DescLbl.Size = UDim2.new(1, -20, 0, 20)
	DescLbl.Text = entry.Desc or ""
	DescLbl.TextXAlignment = Enum.TextXAlignment.Left
	DescLbl.TextWrapped = true
	DescLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
	DescLbl.TextSize = 12
	DescLbl.Font = Enum.Font.Gotham
	DescLbl.Parent = Btn

	local base = entry.Type == "universal" and Color3.fromRGB(58, 58, 58) or Color3.fromRGB(38, 38, 38)
	Btn.BackgroundColor3 = base
	Btn.MouseEnter:Connect(function() Btn.BackgroundColor3 = base:Lerp(Color3.fromRGB(82, 82, 82), 0.5) end)
	Btn.MouseLeave:Connect(function() Btn.BackgroundColor3 = base end)
	Btn.MouseButton1Click:Connect(function()
		LauncherChoice = entry
	end)
end

for _, entry in ipairs(GAME_SCRIPTS) do launchButton(entry) end

local LaunchCustomLabel = Instance.new("TextLabel")
LaunchCustomLabel.Position = UDim2.new(0, 12, 0, 366)
LaunchCustomLabel.Size = UDim2.new(1, -24, 0, 16)
LaunchCustomLabel.BackgroundTransparency = 1
LaunchCustomLabel.Text = "Or load raw Lua (paste below)"
LaunchCustomLabel.TextXAlignment = Enum.TextXAlignment.Left
LaunchCustomLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
LaunchCustomLabel.TextSize = 12
LaunchCustomLabel.Font = Enum.Font.GothamBold
LaunchCustomLabel.Parent = LaunchPanel

local LaunchBox = Instance.new("TextBox")
LaunchBox.Position = UDim2.new(0, 12, 0, 386)
LaunchBox.Size = UDim2.new(1, -24, 0, 54)
LaunchBox.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
LaunchBox.BorderColor3 = Color3.fromRGB(66, 66, 66)
LaunchBox.BorderSizePixel = 1
LaunchBox.Text = ""
LaunchBox.PlaceholderText = "-- paste your script here"
LaunchBox.TextXAlignment = Enum.TextXAlignment.Left
LaunchBox.TextYAlignment = Enum.TextYAlignment.Top
LaunchBox.TextColor3 = Color3.fromRGB(240, 240, 240)
LaunchBox.TextSize = 12
LaunchBox.Font = Enum.Font.Code
LaunchBox.MultiLine = true
LaunchBox.TextWrapped = true
LaunchBox.ClearTextOnFocus = false
LaunchBox.Parent = LaunchPanel
Instance.new("UICorner", LaunchBox).CornerRadius = UDim.new(0, 4)

local LaunchRunBtn = Instance.new("TextButton")
LaunchRunBtn.Position = UDim2.new(0, 12, 0, 446)
LaunchRunBtn.Size = UDim2.new(1, -24, 0, 28)
LaunchRunBtn.BackgroundColor3 = Color3.fromRGB(228, 228, 228)
LaunchRunBtn.BorderSizePixel = 0
LaunchRunBtn.Text = "Run Custom Script"
LaunchRunBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
LaunchRunBtn.TextSize = 13
LaunchRunBtn.Font = Enum.Font.GothamBold
LaunchRunBtn.Parent = LaunchPanel
Instance.new("UICorner", LaunchRunBtn).CornerRadius = UDim.new(0, 4)
LaunchRunBtn.MouseButton1Click:Connect(function()
	local text = LaunchBox.Text
	if #text < 1 then launchSetStatus("Paste a script first.", true); return end
	LauncherChoice = { Name = "Custom Script", Desc = "", Type = "source", Source = text }
end)

local LaunchIYBtn = Instance.new("TextButton")
LaunchIYBtn.Position = UDim2.new(0, 12, 0, 500)
LaunchIYBtn.Size = UDim2.new(1, -24, 0, 28)
LaunchIYBtn.BackgroundColor3 = Color3.fromRGB(228, 228, 228)
LaunchIYBtn.BorderSizePixel = 0
LaunchIYBtn.Text = "Load Infinite Yield"
LaunchIYBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
LaunchIYBtn.TextSize = 13
LaunchIYBtn.Font = Enum.Font.GothamBold
LaunchIYBtn.Parent = LaunchPanel
Instance.new("UICorner", LaunchIYBtn).CornerRadius = UDim.new(0, 4)
LaunchIYBtn.MouseButton1Click:Connect(function()
	loadInfiniteYield()
end)

LaunchStatus = Instance.new("TextLabel")
LaunchStatus.Name = "Status"
LaunchStatus.Position = UDim2.new(0, 12, 0, 480)
LaunchStatus.Size = UDim2.new(1, -24, 0, 16)
LaunchStatus.BackgroundTransparency = 1
LaunchStatus.Text = ""
LaunchStatus.TextXAlignment = Enum.TextXAlignment.Left
LaunchStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
LaunchStatus.TextSize = 11
LaunchStatus.Font = Enum.Font.Gotham
LaunchStatus.Parent = LaunchPanel

local LaunchClose = Instance.new("TextButton")
LaunchClose.Position = UDim2.new(1, -30, 0, 8)
LaunchClose.Size = UDim2.new(0, 22, 0, 22)
LaunchClose.BackgroundTransparency = 1
LaunchClose.Text = "X"
LaunchClose.TextColor3 = Color3.fromRGB(200, 200, 200)
LaunchClose.TextSize = 14
LaunchClose.Font = Enum.Font.GothamBold
LaunchClose.Parent = LaunchPanel
LaunchClose.MouseButton1Click:Connect(function()
	LauncherCanceled = true
end)

while true do
	while not LauncherChoice do
		task.wait(0.1)
		if LauncherCanceled then
			pcall(function() LaunchGui:Destroy() end)
			print("[ABSOLUTE] Launcher closed - nothing loaded.")
			return
		end
	end
	local choice = LauncherChoice
	if choice.Type == "universal" then
		break
	end
	if runGameScript(choice) then
		pcall(function() LaunchGui:Destroy() end)
		return
	end
	LauncherChoice = nil
end
pcall(function() LaunchGui:Destroy() end)

for _ = 1, 60 do
	task.wait(0.25)
	if loadDone then break end
end
if not loadDone then libErr = "game:HttpGet timed out (network blocked or hanging)" end
if not Library then
	print("[ABSOLUTE] FAILED to load LinoriaLib: " .. tostring(libErr))
	game.StarterGui:SetCore("SendNotification", { Title = "ABSOLUTE", Text = "Failed to load LinoriaLib: " .. tostring(libErr), Duration = 6 })
	return
end

-- Gray & white theme. Applied before the window is created so the whole UI
-- renders in grays/white immediately, regardless of any saved theme config.
Library.BackgroundColor = Color3.fromRGB(26, 26, 26)
Library.MainColor = Color3.fromRGB(38, 38, 38)
Library.AccentColor = Color3.fromRGB(228, 228, 228)
Library.OutlineColor = Color3.fromRGB(66, 66, 66)
Library.FontColor = Color3.fromRGB(240, 240, 240)
Library.RiskColor = Color3.fromRGB(255, 72, 72)
pcall(function() Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor) end)

local ThemeManager, SaveManager
pcall(function() ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua"))() end)
pcall(function() SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/SaveManager.lua"))() end)
pcall(function() ThemeManager:SetLibrary(Library) end)
pcall(function() SaveManager:SetLibrary(Library) end)
pcall(function() SaveManager:SetFolder("ABSOLUTE") end)
pcall(function() ThemeManager:SetFolder("ABSOLUTE") end)

local Toggles = getgenv().Toggles
local Options = getgenv().Options

local Conns = {}
function addConn(c)
	if c then Conns[#Conns + 1] = c end
	return c
end
function notify(title, text, dur)
	pcall(function() Library:Notify(title .. (text and (" | " .. text) or ""), dur or 3) end)
end

local Loops = {}
local LoopRenderStep = {}
function loopStop(name)
	local c = Loops[name]
	if c then
		if LoopRenderStep[name] then
			pcall(function() RunService:UnbindFromRenderStep(name) end)
			LoopRenderStep[name] = nil
		else
			pcall(function() c:Disconnect() end)
		end
		Loops[name] = nil
	end
end
function loopStart(name, fn, priority)
	loopStop(name)
	if priority then
		LoopRenderStep[name] = true
		Loops[name] = true
		pcall(function() RunService:BindToRenderStep(name, priority, fn) end)
	else
		Loops[name] = RunService.RenderStepped:Connect(fn)
	end
	return Loops[name]
end
function stopAllLoops()
	for name in pairs(Loops) do loopStop(name) end
end

-- ----------------------------------------------------------------------------
-- CHARACTER HELPERS
-- ----------------------------------------------------------------------------
function getChar() return LocalPlayer.Character end
function getRoot()
	local ch = getChar()
	return ch and ch:FindFirstChild("HumanoidRootPart")
end
function getHum()
	local ch = getChar()
	return ch and ch:FindFirstChildOfClass("Humanoid")
end
function getParts()
	local ch = getChar()
	local out = {}
	if ch then
		for _, p in ipairs(ch:GetDescendants()) do
			if p:IsA("BasePart") then out[#out + 1] = p end
		end
	end
	return out
end
function getPlayerRoot(p)
	local ch = p and p.Character
	return ch and (ch:FindFirstChild("HumanoidRootPart") or ch.PrimaryPart)
end
-- Single global target dropdown used by aim, silent aim, spectate, fling,
-- bring, freeze, teleport and copy name.
function lockedTarget()
	local name = (Options and Options["Pl_Target"] and Options["Pl_Target"].Value) or ""
	if not name or name == "No players" then return nil end
	return Players:FindFirstChild(name)
end
function getMoveDir(cam)
	local dir = Vector3.new(0, 0, 0)
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
	return Vector3.new(dir.X, 0, dir.Z)
end

-- ----------------------------------------------------------------------------
-- STATE
-- ----------------------------------------------------------------------------
local S = {
	Aim = {
		Enabled = false, TargetPart = "Head", Fov = 90, Smoothness = 8,
		Prediction = 0.1, PredictMode = "Velocity", MaxDist = 400, TeamCheck = false,
		VisibleCheck = false, FovCircle = true, AutoAttack = false,
		HitboxScale = 1.5, HitboxPart = "All", HitboxLevels = 5,
		HitboxTransparency = 0, HitboxColor = Color3.fromRGB(255, 255, 255), HitboxColorOn = false,
		SilentEnabled = false, SilentFov = 60, SilentPrediction = 0.1, SilentVisible = false,
		SilentMethod = "Frame", SilentKey = "MB1",
		HoldKey = "LeftAlt", HoldActive = false,
	},
	Esp = {
		Enabled = false,
		Boxes = true, BoxMode = "2D", BoxType = "Full", BoxThickness = 1, BoxColor = Color3.fromRGB(255, 80, 80),
		Lines = false, LineMode = "2D", LineStyle = "Solid", LineThickness = 1, LineTransparency = 0, LineColor = Color3.fromRGB(255, 80, 80),
		Names = true, NameMode = "Display", NameSize = 14, NamePos = "Top", NameOffset = 0, NameColor = Color3.fromRGB(255, 255, 255),
		Health = true, HealthMode = "Bar", HealthGradient = true, HealthColor = Color3.fromRGB(80, 255, 80), HealthPos = "Top", HealthSize = 3,
		Distance = true, DistanceUnits = "Studs",
		Chams = false, ChamColor = Color3.fromRGB(0, 255, 0), ChamTransparency = 0.55, ChamThermal = false, ChamGradient = true, ChamOutline = 0.2,
		TeamColor = false, Team1Color = Color3.fromRGB(80, 200, 255), Team2Color = Color3.fromRGB(255, 80, 80),
		Skeleton = false, SkelColor = Color3.fromRGB(255, 255, 255), SkelThickness = 1, SkelTransparency = 0,
		MaxDist = 1000, Color = Color3.fromRGB(255, 80, 80),
		Preview = false,
		Rainbow = false, RainbowHue = 0, TracerOrigin = "Bottom", HealthText = "Num",
	},
	Move = {
		WalkSpeed = 16, JumpPower = 50, FlySpeed = 50, SpinSpeed = 5, HipHeight = 2,
		VoidLevel = -100, FloatY = 5, ClickTpKey = "T", ClickTpEnabled = false,
		Bhop = false, AutoJump = false,
	},
	Vis = {
		Fov = 70, FreecamSpeed = 30, ThirdDist = 10, XhSize = 12, XhGap = 4,
		XhColor = Color3.fromRGB(255, 255, 255), XhStyle = "Cross", XhRainbow = false,
		Stretch = false, StretchWidth = 1920, StretchHeight = 1080, RenderDist = false, RenderDistValue = 2000,
		Xray = false, XrayTransparency = 0.5,
		Speedo = false,
	},
	Misc = { ClickCps = 15 },
}

local UI = {}

-- ----------------------------------------------------------------------------
-- AIMBOT
-- ----------------------------------------------------------------------------
local aimFovCircle = nil

function aimTarget()
	local cam = Workspace.CurrentCamera
	if not cam then return nil end
	local myPos, fwd = cam.CFrame.Position, cam.CFrame.LookVector
	local maxAng = math.rad(S.Aim.Fov)
	-- Always re-pick the nearest player every call. No locked dropdown target:
	-- whoever is closest (and inside FOV / max distance) is the target, and it
	-- re-evaluates on every frame so the aim follows whoever is nearest.
	local best = nil
	for _, p in ipairs(Players:GetPlayers()) do
		if p == LocalPlayer then continue end
		if S.Aim.TeamCheck and p.Team == LocalPlayer.Team then continue end
		local ch = p.Character
		if not ch then continue end
		local part = ch:FindFirstChild(S.Aim.TargetPart) or ch:FindFirstChild("HumanoidRootPart")
		if not part then continue end
		local dir = part.Position - myPos
		local dist = dir.Magnitude
		if dist > S.Aim.MaxDist or dist < 0.001 then continue end
		local ang = math.acos(math.clamp(dir.Unit:Dot(fwd), -1, 1))
		if ang <= maxAng and (not best or dist < best.Dist) then
			best = { Player = p, Part = part, Dist = dist, Angle = ang }
		end
	end
	return best
end

function aimVisible(t)
	local cam = Workspace.CurrentCamera
	if not cam then return false end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { LocalPlayer.Character }
	local res = Workspace:Raycast(cam.CFrame.Position, t.Part.Position - cam.CFrame.Position, params)
	return (not res) or res.Instance:IsDescendantOf(t.Player.Character)
end

function keyMatches(input, keyName)
	if keyName == 'MB1' then return input.UserInputType == Enum.UserInputType.MouseButton1 end
	if keyName == 'MB2' then return input.UserInputType == Enum.UserInputType.MouseButton2 end
	return input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == keyName
end

addConn(UserInputService.InputBegan:Connect(function(input)
	if keyMatches(input, S.Aim.HoldKey) then S.Aim.HoldActive = true end
end))
addConn(UserInputService.InputEnded:Connect(function(input)
	if keyMatches(input, S.Aim.HoldKey) then S.Aim.HoldActive = false end
end))

function aimActive()
	local toggled = Toggles and Toggles["Aim_Enabled"] and Toggles["Aim_Enabled"].Value or false
	return toggled or S.Aim.HoldActive
end

-- --- Prediction --------------------------------------------------------------
local velCache = {}
function smoothedVelocity(part)
	local v = part.Velocity
	local c = velCache[part]
	if c then v = c:Lerp(v, 0.35) else velCache[part] = v end
	velCache[part] = v
	return v
end
function aimPredictedPos(part)
	if S.Aim.Prediction <= 0 then return part.Position end
	local vel = part.Velocity
	if S.Aim.PredictMode == "Advanced" or S.Aim.PredictMode == "Trajectory" then vel = smoothedVelocity(part) end
	local predicted = part.Position + vel * S.Aim.Prediction
	if S.Aim.PredictMode == "Trajectory" then
		local g = Workspace.Gravity
		predicted = predicted - Vector3.new(0, 0.5 * g * S.Aim.Prediction * S.Aim.Prediction, 0)
	end
	return predicted
end
function velCacheCleanup()
	for part in pairs(velCache) do
		if not part or not part.Parent then velCache[part] = nil end
	end
end

-- --- Silent aim (universal frame-flash method) -------------------------------
function keyHeld(keyName)
	if keyName == "MB1" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) end
	if keyName == "MB2" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end
	local kc = Enum.KeyCode[keyName]
	return kc ~= nil and UserInputService:IsKeyDown(kc)
end

function silentTarget()
	local cam = Workspace.CurrentCamera
	if not cam then return nil end
	local myPos, fwd = cam.CFrame.Position, cam.CFrame.LookVector
	local maxAng = math.rad(S.Aim.SilentFov)
	local lock = lockedTarget()
	if lock and lock ~= LocalPlayer then
		local ch = lock.Character
		local part = ch and (ch:FindFirstChild(S.Aim.TargetPart) or ch:FindFirstChild("HumanoidRootPart"))
		if part then
			local dir = part.Position - myPos
			local dist = dir.Magnitude
			local ang = math.acos(math.clamp(dir.Unit:Dot(fwd), -1, 1))
			if dist <= S.Aim.MaxDist and ang <= maxAng and not (S.Aim.TeamCheck and lock.Team == LocalPlayer.Team) then
				return { Player = lock, Part = part, Dist = dist, Angle = ang }
			end
		end
	end
	local best = nil
	for _, p in ipairs(Players:GetPlayers()) do
		if p == LocalPlayer then continue end
		if S.Aim.TeamCheck and p.Team == LocalPlayer.Team then continue end
		local ch = p.Character
		if not ch then continue end
		local part = ch:FindFirstChild(S.Aim.TargetPart) or ch:FindFirstChild("HumanoidRootPart")
		if not part then continue end
		local dir = part.Position - myPos
		local dist = dir.Magnitude
		if dist > S.Aim.MaxDist or dist < 0.001 then continue end
		local ang = math.acos(math.clamp(dir.Unit:Dot(fwd), -1, 1))
		if ang <= maxAng and (not best or ang < best.Angle) then
			best = { Player = p, Part = part, Dist = dist, Angle = ang }
		end
	end
	return best
end

function startSilentLoop()
	loopStart("Silent", function()
		if not S.Aim.SilentEnabled then return end
		local active = Toggles and Toggles["Aim_Silent"] and Toggles["Aim_Silent"].Value or false
		if not active then return end
		if not keyHeld(S.Aim.SilentKey) then return end
		local cam = Workspace.CurrentCamera
		if not cam then return end
		local t = silentTarget()
		if not t then return end
		if S.Aim.SilentVisible and not aimVisible(t) then return end
		local orig = cam.CFrame
		pcall(function()
			cam.CFrame = CFrame.lookAt(cam.CFrame.Position, aimPredictedPos(t.Part))
			local ch = getChar()
			local tool = ch and ch:FindFirstChildOfClass("Tool")
			if tool then tool:Activate() end
		end)
		cam.CFrame = orig
		velCacheCleanup()
	end)
end

function startAimLoop()
	-- Bind at a step AFTER the engine's camera update (Camera priority) so the
	-- cam.CFrame override sticks even in first person, where the engine normally
	-- overwrites it before the frame renders.
	loopStart("Aim", function(dt)
		local cam = Workspace.CurrentCamera
		if not cam then return end
		local active = aimActive()
		if S.Aim.FovCircle and Drawing then
			if not aimFovCircle then aimFovCircle = Drawing.new("Circle") end
			local size = cam.ViewportSize
			aimFovCircle.Position = size / 2
			aimFovCircle.Radius = (S.Aim.Fov / 90) * (size.Y / 2)
			aimFovCircle.Thickness = 1
			aimFovCircle.Color = Color3.fromRGB(255, 255, 255)
			aimFovCircle.Transparency = 0.7
			aimFovCircle.Visible = active
		elseif aimFovCircle then
			aimFovCircle.Visible = false
		end
		if not active then return end
		local t = aimTarget()
		if not t then return end
		if S.Aim.VisibleCheck and not aimVisible(t) then return end
		local pos = aimPredictedPos(t.Part)
		local look = CFrame.lookAt(cam.CFrame.Position, pos)
		if S.Aim.Smoothness <= 0 then
			cam.CFrame = look
		else
			cam.CFrame = cam.CFrame:Lerp(look, math.clamp(dt * S.Aim.Smoothness, 0, 1))
		end
		if S.Aim.AutoAttack then
			local ch = getChar()
			local tool = ch and ch:FindFirstChildOfClass("Tool")
			if tool then pcall(function() tool:Activate() end) end
		end
		velCacheCleanup()
	end, Enum.RenderPriority.Camera.Value + 1)
end

-- ----------------------------------------------------------------------------
-- ESP (external-style Drawing render)
-- ----------------------------------------------------------------------------
local espData = {}
local espConn = nil

local ESP_EDGES = {
	{ 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 1 },
	{ 5, 6 }, { 6, 7 }, { 7, 8 }, { 8, 5 },
	{ 1, 5 }, { 2, 6 }, { 3, 7 }, { 4, 8 },
}

function espRainbowColor(base, seed)
	if S.Esp.Rainbow then
		return Color3.fromHSV((S.Esp.RainbowHue + seed * 0.08) % 1, 1, 1)
	end
	return base
end
function espTeamColor(p)
	if p.Team == LocalPlayer.Team then return S.Esp.Team1Color end
	return S.Esp.Team2Color
end
function espElementColor(p)
	if S.Esp.TeamColor then return espTeamColor(p) end
	return S.Esp.BoxColor
end
function espHealthColor(frac, fallback)
	if S.Esp.HealthGradient then
		return Color3.fromRGB(math.floor(255 * (1 - frac)), math.floor(255 * frac), 0)
	end
	return fallback
end
function espDistLabel(dist)
	if S.Esp.DistanceUnits == "Meters" then
		return math.floor(dist * 0.28) .. "m"
	end
	return math.floor(dist) .. " studs"
end

local ESP_BODY = {}
for _, n in ipairs({
	"Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso",
	"LeftArm", "RightArm", "LeftHand", "RightHand",
	"LeftLowerArm", "RightLowerArm", "LeftUpperArm", "RightUpperArm",
	"LeftLeg", "RightLeg", "LeftFoot", "RightFoot",
	"LeftLowerLeg", "RightLowerLeg", "LeftUpperLeg", "RightUpperLeg",
}) do ESP_BODY[n] = true end

-- World-space AABB of a character that hugs the actual body.
-- Uses only real rig parts: whitelisted names, not under Accessory/Tool,
-- and within a sane distance of the root. Floating game effects that games
-- parent to characters can no longer push the box above the player.
-- Falls back to ALL parts when there is no root (custom rigs / vehicles /
-- games that strip the standard parts), and returns nil when the character
-- has no BaseParts at all so the caller can hide instead of drawing at origin.
function charWorldBBox(ch)
	local hrp = ch:FindFirstChild("HumanoidRootPart") or ch.PrimaryPart
	local minV = Vector3.new(math.huge, math.huge, math.huge)
	local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)
	local any = false
	local head = ch:FindFirstChild("Head")
	local useAll = not hrp
	-- Scale the "near the body" cutoff with the actual rig so giant / scaled
	-- avatars and big custom models keep every limb instead of clipping them.
	local cutoff = 12
	if hrp then
		local ref = head
		if ref and ref:IsA("BasePart") then
			cutoff = math.max(12, (ref.Position - hrp.Position).Magnitude * 1.6)
		end
	end
	for _, part in ipairs(ch:GetDescendants()) do
		if not part:IsA("BasePart") or not part.Parent then continue end
		local bodyPart = ESP_BODY[part.Name]
		if not bodyPart and not useAll then
			local anc = part.Parent
			while anc and anc ~= ch do
				if anc:IsA("Accessory") or anc:IsA("Tool") then bodyPart = false break end
				anc = anc.Parent
			end
			if bodyPart == nil then bodyPart = (part.Position - hrp.Position).Magnitude <= cutoff end
		end
		if not bodyPart and not useAll then continue end
		any = true
		local cf, s = part.CFrame, part.Size / 2
		local c = cf.Position
		local r, u, f = cf.RightVector * s.X, cf.UpVector * s.Y, cf.LookVector * s.Z
		local corners = { r + u + f, r + u - f, r - u + f, r - u - f, -r + u + f, -r + u - f, -r - u + f, -r - u - f }
		for _, o in ipairs(corners) do
			local w = c + o
			minV = Vector3.new(math.min(minV.X, w.X), math.min(minV.Y, w.Y), math.min(minV.Z, w.Z))
			maxV = Vector3.new(math.max(maxV.X, w.X), math.max(maxV.Y, w.Y), math.max(maxV.Z, w.Z))
		end
	end
	if not any then
		if not hrp then return nil, nil end
		return hrp.Position - Vector3.new(1, 3, 1), hrp.Position + Vector3.new(1, 3, 1)
	end
	-- Never let the box extend above the top of the head. Stray parts that
	-- games parent to characters (auras, floating props, big back weapons)
	-- can otherwise push the box up off the body.
	if head and head:IsA("BasePart") then
		local headTop = head.Position + head.CFrame.UpVector * (head.Size.Y * 0.5)
		if headTop.Y < maxV.Y then maxV = Vector3.new(maxV.X, headTop.Y, maxV.Z) end
	end
	return minV, maxV
end

-- Projects a world point through a camera. Uses the same hand-rolled
-- perspective math (render CFrame + FOV + viewport size) for the real screen
-- camera and for viewport-frame cameras, so results land in absolute screen
-- coordinates and can be fed to Drawing objects directly. WorldToScreenPoint
-- was dropped because it returns topbar-inset-relative coordinates, which made
-- every box/tracer/name sit ~topbar-height too high on screen.
function espProject(cam, pos, vpSize)
	-- Shared perspective math. It projects into absolute screen coordinates
	-- (origin at the top-left of the viewport) so the result can be fed to
	-- Drawing objects directly, immune to the topbar-inset confusion of
	-- WorldToScreenPoint/WorldToViewportPoint and to camera scripts that set
	-- the camera CFrame late.
	local cfr = cam.CFrame
	if not (cam.Parent and cam.Parent:IsA("ViewportFrame")) then
		local ok, r = pcall(function() return cam:GetRenderCFrame() end)
		if ok and r then cfr = r end
	end
	local rel = cfr:Inverse() * pos
	local z = -rel.Z
	if z <= 0 then return Vector3.new(-1e6, -1e6, z), false end
	local vw, vh = vpSize and vpSize.X or 1, vpSize and vpSize.Y or 1
	local halfH = math.tan(math.rad(cam.FieldOfView) / 2) * z
	local halfW = halfH * (vw / math.max(1, vh))
	local sx = (rel.X / math.max(1e-6, halfW)) * (vw / 2) + vw / 2
	local sy = (-rel.Y / math.max(1e-6, halfH)) * (vh / 2) + vh / 2
	if cam.Parent and cam.Parent:IsA("ViewportFrame") then
		return Vector3.new(sx, sy, z), true
	end
	-- Anything in front of the camera counts as visible. Strict viewport-bounds
	-- checks here dropped skeleton bones, names and labels whenever a player was
	-- near a screen edge, so we only cull points that are actually behind us.
	return Vector3.new(sx, sy, z), true
end

function projectCorners(cam, minV, maxV, vpSize)
	local ws = {
		Vector3.new(minV.X, minV.Y, minV.Z), Vector3.new(maxV.X, minV.Y, minV.Z),
		Vector3.new(maxV.X, maxV.Y, minV.Z), Vector3.new(minV.X, maxV.Y, minV.Z),
		Vector3.new(minV.X, minV.Y, maxV.Z), Vector3.new(maxV.X, minV.Y, maxV.Z),
		Vector3.new(maxV.X, maxV.Y, maxV.Z), Vector3.new(minV.X, maxV.Y, maxV.Z),
	}
	local sc, vis = {}, {}
	local minS = Vector2.new(math.huge, math.huge)
	local maxS = Vector2.new(-math.huge, -math.huge)
	local anyVis = false
	for i = 1, 8 do
		local w, o = espProject(cam, ws[i], vpSize)
		sc[i] = Vector2.new(w.X, w.Y)
		vis[i] = o and w.Z > 0
		if vis[i] then
			anyVis = true
			minS = Vector2.new(math.min(minS.X, w.X), math.min(minS.Y, w.Y))
			maxS = Vector2.new(math.max(maxS.X, w.X), math.max(maxS.Y, w.Y))
		end
	end
	if not anyVis then minS, maxS = Vector2.zero, Vector2.zero end
	return sc, vis, minS, maxS, anyVis
end

function skeletonEdges(ch)
	local edges = {}
	local root = ch:FindFirstChild("HumanoidRootPart") or ch.PrimaryPart
	if root then
		local joints = {}
		for _, j in ipairs(ch:GetDescendants()) do
			if j:IsA("Motor6D") then joints[#joints + 1] = j end
		end
		local seen, stack = { [root] = true }, { root }
		while #stack > 0 do
			local a = table.remove(stack)
			for _, j in ipairs(joints) do
				if j.Part0 == a and j.Part1 and not seen[j.Part1] then
					seen[j.Part1] = true
					edges[#edges + 1] = { a, j.Part1 }
					stack[#stack + 1] = j.Part1
				end
			end
		end
	end
	if #edges > 0 then return edges end
	local torso = ch:FindFirstChild("Torso")
	if torso then
		local head = ch:FindFirstChild("Head")
		local larm = ch:FindFirstChild("LeftArm")
		local rarm = ch:FindFirstChild("RightArm")
		local lleg = ch:FindFirstChild("LeftLeg")
		local rleg = ch:FindFirstChild("RightLeg")
		if head then edges[#edges + 1] = { torso, head } end
		if larm then edges[#edges + 1] = { torso, larm } end
		if rarm then edges[#edges + 1] = { torso, rarm } end
		if lleg then edges[#edges + 1] = { torso, lleg } end
		if rleg then edges[#edges + 1] = { torso, rleg } end
	end
	-- Last resort for fully custom rigs (no Motor6Ds, no R6 names): connect
	-- whatever distinct parts we can find into a stick figure.
	if #edges == 0 then
		local head = ch:FindFirstChild("Head")
		if not (head and head:IsA("BasePart")) then head = nil end
		local t = ch:FindFirstChild("Torso")
		if not (t and t:IsA("BasePart")) then t = nil end
		local t2 = ch:FindFirstChild("UpperTorso")
		if not (t2 and t2:IsA("BasePart")) then t2 = nil end
		local t3 = ch:FindFirstChild("LowerTorso")
		if not (t3 and t3:IsA("BasePart")) then t3 = nil end
		if root and root:IsA("BasePart") then
			local torsoP = t or t2 or t3 or root
			if head then edges[#edges + 1] = { torsoP, head } end
			if t and t2 then edges[#edges + 1] = { t, t2 } end
			if t2 and t3 then edges[#edges + 1] = { t2, t3 } end
		elseif head then
			-- No root: connect Head to a couple of the biggest remaining parts.
			local plist = {}
			for _, pt in ipairs(ch:GetDescendants()) do
				if pt:IsA("BasePart") and pt ~= head then plist[#plist + 1] = pt end
			end
			table.sort(plist, function(a, b) return (a.Size.Magnitude * a.Size.Magnitude) > (b.Size.Magnitude * b.Size.Magnitude) end)
			local ref = plist[1]
			if ref then
				edges[#edges + 1] = { head, ref }
				local ref2 = plist[2]
				if ref2 then edges[#edges + 1] = { ref, ref2 } end
			end
		end
	end
	return edges
end

-- The Drawing API has a global ~1000 object limit. Every player used to eat
-- 83 objects here, so a full server silently ran out and the last objects to
-- be created (names, distance text, skeleton) stopped showing up. We now use a
-- much smaller budget per player and create each object defensively: if the
-- budget runs out or an object type is unsupported, that one object is skipped
-- instead of taking down the whole player's ESP.
local ESP_BOX_LINES = 8
local ESP_TRACE_SEGS = 8
local ESP_SKEL_LINES = 16

local function safeDraw(type, props)
	local ok, obj = pcall(function()
		local o = Drawing.new(type)
		if props then
			for k, v in pairs(props) do
				o[k] = v
			end
		end
		return o
	end)
	if ok then return obj end
	return nil
end

function espMake(p)
	local d = { p = p, chr = p.Character, Hl = nil }
	if Drawing then
		local function mkText()
			return safeDraw("Text", {
				Center = true,
				Outline = true,
				OutlineColor = Color3.new(0, 0, 0),
				Font = 2,
				Visible = false,
			})
		end
		d.box = safeDraw("Square", { Filled = false, Visible = false, Thickness = 1, Transparency = 1 })
		d.boxL = {}
		for i = 1, ESP_BOX_LINES do
			d.boxL[i] = safeDraw("Line", { Thickness = 1, Transparency = 1, Visible = false })
		end
		d.tracer = safeDraw("Line", { Thickness = 1, Transparency = 1, Visible = false })
		d.traceSeg = {}
		for i = 1, ESP_TRACE_SEGS do
			d.traceSeg[i] = safeDraw("Line", { Thickness = 1, Transparency = 1, Visible = false })
		end
		d.hpbg = safeDraw("Square", { Filled = true, Transparency = 1, Visible = false })
		d.hp = safeDraw("Square", { Filled = true, Transparency = 1, Visible = false })
		d.name = mkText()
		d.hptext = mkText()
		d.distText = mkText()
		d.skel = {}
		for i = 1, ESP_SKEL_LINES do
			d.skel[i] = safeDraw("Line", { Thickness = 1, Transparency = 1, Visible = false })
		end
	end
	espData[p] = d
	return d
end

function espHide(d)
	if not d then return end
	for _, o in ipairs({ d.box, d.tracer, d.hpbg, d.hp, d.name, d.hptext, d.distText }) do
		if o then o.Visible = false end
	end
	for _, g in ipairs({ d.boxL, d.traceSeg, d.skel }) do
		for i = 1, #g do
			local l = g[i]
			if l then l.Visible = false end
		end
	end
end

function espDestroy(p)
	local d = espData[p]
	if not d then return end
	if d.Hl then pcall(function() d.Hl:Destroy() end) end
	for p2 in pairs(d.chamParts or {}) do
		if p2 and p2.Parent then pcall(function() p2.LocalTransparencyModifier = d.chamOrig[p2] or 0 end) end
	end
	for _, o in ipairs({ d.box, d.tracer, d.hpbg, d.hp, d.name, d.hptext, d.distText }) do
		if o then pcall(function() o:Remove() end) end
	end
	for _, g in ipairs({ d.boxL, d.traceSeg, d.skel }) do
		for i = 1, #g do
			local l = g[i]
			if l then pcall(function() l:Remove() end) end
		end
	end
	espData[p] = nil
end

function espChamsRefresh(d, ch)
	if d.Hl then pcall(function() d.Hl:Destroy() end); d.Hl = nil end
	for p in pairs(d.chamParts or {}) do
		if p and p.Parent then pcall(function() p.LocalTransparencyModifier = d.chamOrig[p] or 0 end) end
	end
	d.chamParts, d.chamOrig = {}, {}
	if not S.Esp.Chams then return end
	-- Primary: Highlight tint (works client-side even when the server
	-- won't let us modify parts).
	local h = Instance.new("Highlight")
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.Parent = ch
	d.Hl = h
	-- Fallback: emissive part transparency so the body stays visible
	-- through walls even in games that strip / remove Highlights.
	local trans = 1 - math.clamp(S.Esp.ChamTransparency, 0, 1)
	for _, part in ipairs(ch:GetDescendants()) do
		if part:IsA("BasePart") then
			d.chamParts[part] = true
			if d.chamOrig[part] == nil then d.chamOrig[part] = part.LocalTransparencyModifier end
			pcall(function() part.LocalTransparencyModifier = trans end)
		end
	end
end

function drawStyleLine(segs, from, to, color, thick, trans, style)
	local full = math.max(1, (to - from).Magnitude)
	local dir = (to - from) / full
	local function seg(i, a, b)
		local l = segs[i]
		if not l then return end
		l.Visible = true
		l.From = a
		l.To = b
		l.Color = color
		l.Thickness = thick
		l.Transparency = trans
	end
	if style == "Solid" then
		seg(1, from, to)
		return 1
	end
	-- Dash pattern scales with line length so short AND very long lines
	-- always have dashes that reach the target (never run out of segments).
	local on, off = 12, 8
	if style == "Dotted" then on, off = 4, 10 end
	local scale = (on + off) * #segs / math.max(full, 1)
	if scale > 1 then on, off = on / scale, off / scale end
	local n, d = 0, 0
	while d < full and n < #segs do
		local a = from + dir * d
		local b = from + dir * math.min(d + on, full)
		n = n + 1
		seg(n, a, b)
		d = d + on + off
	end
	return n
end

function espRenderPlayer(cam, vp, myRoot, p, offset)
	local ch = p.Character
	if not ch or not ch.Parent then
		if espData[p] then espDestroy(p) end
		return
	end
	-- No hard requirement on a Humanoid: games with custom rigs / mechs /
	-- vehicles often have none. Only bail when the character has no body.
	local minV, maxV = charWorldBBox(ch)
	if not minV then
		if espData[p] then espDestroy(p) end
		return
	end
	local hum = ch:FindFirstChildOfClass("Humanoid")
	local hrp = ch:FindFirstChild("HumanoidRootPart") or ch.PrimaryPart
	local d = espData[p] or espMake(p)
	if d.chr ~= ch then
		d.chr = ch
		espChamsRefresh(d, ch)
	end
	if S.Esp.Chams and not d.Hl then espChamsRefresh(d, ch) end
	if not S.Esp.Chams and d.Hl then espChamsRefresh(d, ch) end
	if d.Hl then
		local fill, out = S.Esp.ChamColor, S.Esp.ChamColor
		if S.Esp.ChamThermal and hum then
			local f = math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1)
			fill = Color3.fromRGB(math.floor(255 * (1 - f)), math.floor(120 * f), math.floor(255 * f))
		elseif S.Esp.ChamGradient then
			out = fill:Lerp(Color3.new(1, 1, 1), 0.4)
		end
		d.Hl.FillColor = fill
		d.Hl.OutlineColor = out
		d.Hl.FillTransparency = math.clamp(S.Esp.ChamTransparency, 0, 1)
		d.Hl.OutlineTransparency = math.clamp(S.Esp.ChamOutline, 0, 1)
		local mod = 1 - math.clamp(S.Esp.ChamTransparency, 0, 1)
		for part in pairs(d.chamParts) do
			if part and part.Parent then pcall(function() part.LocalTransparencyModifier = mod end) end
		end
	end
	local inRange = true
	if myRoot and S.Esp.MaxDist > 0 and hrp then
		inRange = (myRoot.Position - hrp.Position).Magnitude <= S.Esp.MaxDist
	end
	local sc, vis, minS, maxS, anyVis = projectCorners(cam, minV, maxV, vp)
	-- `offset` shifts viewport-relative coordinates to absolute screen
	-- coordinates so the same Drawing objects render over the mini viewport.
	local ox, oy = 0, 0
	if offset then
		ox, oy = offset.X, offset.Y
		if ox ~= 0 or oy ~= 0 then
			for i = 1, 8 do
				if sc[i] then sc[i] = Vector2.new(sc[i].X + ox, sc[i].Y + oy) end
			end
			minS = Vector2.new(minS.X + ox, minS.Y + oy)
			maxS = Vector2.new(maxS.X + ox, maxS.Y + oy)
		end
	end
	if not inRange or not anyVis then
		espHide(d)
		return
	end
	for i = 1, ESP_BOX_LINES do
		local l = d.boxL[i]
		if l then l.Visible = false end
	end
	for i = 1, ESP_TRACE_SEGS do
		local l = d.traceSeg[i]
		if l then l.Visible = false end
	end
	for i = 1, ESP_SKEL_LINES do
		local l = d.skel[i]
		if l then l.Visible = false end
	end
	local cx = (minS.X + maxS.X) / 2
	local wdt = math.max(2, maxS.X - minS.X)
	local hgt = math.max(2, maxS.Y - minS.Y)
	local topY, botY = minS.Y, maxS.Y
	-- Scale the fixed-pixel offsets (name gap, health bars) with how large the
	-- player is on screen so the labels hug the body at long range too.
	local px = math.clamp(hgt / 140, 0.55, 1.5)
	local seed = (p.UserId or 0) % 13 * 0.06
	local function rc(c)
		return espRainbowColor(c, seed)
	end
	-- Keep text labels inside the viewport so names/distance stay readable even
	-- when the player's box is clipped by a screen edge. For the preview, the
	-- on-screen rect is the frame shifted by its AbsolutePosition.
	local vpW, vpH = vp and vp.X or 640, vp and vp.Y or 480
	local labMinX, labMinY = 2, 2
	local labMaxX, labMaxY = vpW - 2, vpH - 2
	if ox ~= 0 or oy ~= 0 then
		labMinX, labMinY = ox + 2, oy + 2
		labMaxX, labMaxY = ox + vpW - 2, oy + vpH - 2
	end
	local function labelPos(x, y, size)
		return Vector2.new(
			math.clamp(x, labMinX, math.max(labMinX + 1, labMaxX)),
			math.clamp(y, labMinY, math.max(labMinY + 1, labMaxY - size - 2))
		)
	end

	-- Box
	if d.box then d.box.Visible = false end
	if S.Esp.Boxes and d.box then
		local bcol = rc(S.Esp.BoxColor)
		if S.Esp.BoxMode == "2D" then
			d.box.Visible = true
			d.box.Color = bcol
			d.box.Thickness = math.max(1, S.Esp.BoxThickness)
			d.box.Transparency = 1
			d.box.Size = Vector2.new(wdt, hgt)
			d.box.Position = Vector2.new(minS.X, topY)
			if S.Esp.BoxType == "Corner" then
				d.box.Visible = false
				local L, n = d.boxL, 0
				local len = math.clamp(wdt * 0.25, 4, 24)
				local function cs(i, a, b)
					local l = L[i]
					if not l then return end
					l.Visible = true
					l.From = a
					l.To = b
					l.Color = bcol
					l.Thickness = math.max(1, S.Esp.BoxThickness)
					l.Transparency = 1
				end
				cs(1, Vector2.new(minS.X, topY + len), Vector2.new(minS.X, topY))
				cs(2, Vector2.new(minS.X, topY), Vector2.new(minS.X + len, topY))
				cs(3, Vector2.new(maxS.X - len, topY), Vector2.new(maxS.X, topY))
				cs(4, Vector2.new(maxS.X, topY), Vector2.new(maxS.X, topY + len))
				cs(5, Vector2.new(minS.X, botY - len), Vector2.new(minS.X, botY))
				cs(6, Vector2.new(minS.X, botY), Vector2.new(minS.X + len, botY))
				cs(7, Vector2.new(maxS.X - len, botY), Vector2.new(maxS.X, botY))
				cs(8, Vector2.new(maxS.X, botY), Vector2.new(maxS.X, botY - len))
			end
		else
			local L, n = d.boxL, 0
			for _, e in ipairs(ESP_EDGES) do
				local a, b = e[1], e[2]
				if vis[a] and vis[b] then
					n = n + 1
					local l = L[n]
					if not l then continue end
					l.Visible = true
					l.From = sc[a]
					l.To = sc[b]
					l.Color = bcol
					l.Thickness = math.max(1, S.Esp.BoxThickness)
					l.Transparency = 1
				end
			end
		end
	end

	-- Tracer
	if d.tracer then d.tracer.Visible = false end
	if S.Esp.Lines then
		local origin = S.Esp.TracerOrigin or "Bottom"
		local from
		if origin == "Top" then
			from = Vector2.new(vp.X / 2 + ox, oy)
		elseif origin == "Center" then
			from = Vector2.new(vp.X / 2 + ox, vp.Y / 2 + oy)
		elseif origin == "Mouse" then
			local ml = UserInputService:GetMouseLocation()
			from = Vector2.new(ml.X - ox, ml.Y - oy)
		else
			from = Vector2.new(vp.X / 2 + ox, vp.Y + oy)
		end
		local to = Vector2.new(cx, botY)
		local thick = math.max(1, S.Esp.LineThickness)
		-- UI transparency is 0 = opaque, 1 = invisible; Drawing uses inverse.
		local trans = 1 - math.clamp(S.Esp.LineTransparency, 0, 1)
		local lcol = rc(S.Esp.LineColor)
		if S.Esp.LineStyle == "Solid" and d.tracer then
			d.tracer.Visible = true
			d.tracer.From = from
			d.tracer.To = to
			d.tracer.Color = lcol
			d.tracer.Thickness = thick
			d.tracer.Transparency = trans
		else
			drawStyleLine(d.traceSeg, from, to, lcol, thick, trans, S.Esp.LineStyle)
		end
	end

	-- Health
	if d.hpbg then d.hpbg.Visible = false end
	if d.hp then d.hp.Visible = false end
	if d.hptext then d.hptext.Visible = false end
	if S.Esp.Health and hum then
		local frac = math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1)
		local hc = espRainbowColor(espHealthColor(frac, S.Esp.HealthColor), seed)
		local showBar = (S.Esp.HealthMode == "Bar" or S.Esp.HealthMode == "Both")
		local showText = (S.Esp.HealthMode == "Text" or S.Esp.HealthMode == "Both")
		if d.hpbg then d.hpbg.Visible = showBar end
		if d.hp then d.hp.Visible = showBar end
		if d.hptext then d.hptext.Visible = showText end
		if showBar and d.hpbg and d.hp then
			local barW = (S.Esp.HealthPos == "Left" or S.Esp.HealthPos == "Right") and S.Esp.HealthSize or wdt
			local barH = (S.Esp.HealthPos == "Left" or S.Esp.HealthPos == "Right") and hgt or S.Esp.HealthSize
			local bx, by = minS.X, topY - barH * px - 3 * px
			if S.Esp.HealthPos == "Bottom" then by = botY + 3 * px end
			if S.Esp.HealthPos == "Left" then bx, by = minS.X - S.Esp.HealthSize * px - 3 * px, topY end
			if S.Esp.HealthPos == "Right" then bx, by = maxS.X + 3 * px, topY end
			d.hpbg.Color = Color3.new(0, 0, 0)
			d.hpbg.Size = Vector2.new(barW, barH)
			d.hpbg.Position = Vector2.new(bx, by)
			d.hp.Color = hc
			if S.Esp.HealthPos == "Left" or S.Esp.HealthPos == "Right" then
				d.hp.Size = Vector2.new(barW, barH * frac)
				d.hp.Position = Vector2.new(bx, by + barH * (1 - frac))
			else
				d.hp.Size = Vector2.new(barW * frac, barH)
				d.hp.Position = Vector2.new(bx, by)
			end
		end
		if showText and d.hptext then
			if S.Esp.HealthText == "Percent" then
				d.hptext.Text = math.floor(frac * 100) .. "%"
			else
				d.hptext.Text = math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
			end
			d.hptext.Color = hc
			d.hptext.Size = math.max(10, S.Esp.NameSize - 2)
			d.hptext.Position = labelPos(cx, botY + 2 * px, d.hptext.Size)
		end
	end

	-- Name / Distance
	local nameOn = S.Esp.Names and d.name ~= nil
	-- Distance needs a reference point; fall back to the camera so it works
	-- even in games where LocalPlayer has no standard character/root part.
	local distRef = myRoot
	if not distRef and cam then distRef = cam.CFrame.Position end
	local distOn = S.Esp.Distance and hrp and distRef and d.distText ~= nil
	if d.name then d.name.Visible = nameOn end
	if d.distText then d.distText.Visible = distOn end
	if nameOn then
		local nm = p.Name
		if S.Esp.NameMode == "Display" then
			local dn = p.DisplayName
			if dn and dn ~= "" then nm = dn end
		end
		d.name.Text = nm
		d.name.Size = S.Esp.NameSize
		d.name.Color = rc(S.Esp.NameColor)
		local y = topY - S.Esp.NameOffset * px - S.Esp.NameSize - 4 * px
		if S.Esp.NamePos == "Bottom" then y = botY + S.Esp.NameOffset * px + S.Esp.NameSize + 2 * px end
		d.name.Position = labelPos(cx, y, S.Esp.NameSize)
	end
	if distOn then
		local base = myRoot and myRoot.Position or cam.CFrame.Position
		local dist = (base - hrp.Position).Magnitude
		d.distText.Text = espDistLabel(dist)
		d.distText.Size = math.max(10, S.Esp.NameSize - 3)
		d.distText.Color = rc(S.Esp.NameColor)
		-- Keep distance under the health text; drop below the name when the
		-- name is drawn at the bottom so they never overlap.
		local y = botY + (d.hptext and d.hptext.Visible and 16 or 2) * px
		if nameOn and S.Esp.NamePos == "Bottom" then y = botY + S.Esp.NameSize * 2 + 4 * px end
		d.distText.Position = labelPos(cx, y, d.distText.Size)
	end

	-- Skeleton
	if S.Esp.Skeleton and d.skel then
		local edges = skeletonEdges(ch)
		local n = 0
		local scol = rc(S.Esp.SkelColor)
		for _, e in ipairs(edges) do
			n = n + 1
			if n > #d.skel then break end
			local l = d.skel[n]
			if not l then continue end
			local a, oa = espProject(cam, e[1].Position, vp)
			local b, ob = espProject(cam, e[2].Position, vp)
			if oa and ob and a.Z > 0 and b.Z > 0 then
				l.Visible = true
				l.From = Vector2.new(a.X + ox, a.Y + oy)
				l.To = Vector2.new(b.X + ox, b.Y + oy)
				l.Color = scol
				l.Thickness = math.max(1, S.Esp.SkelThickness)
				l.Transparency = 1 - math.clamp(S.Esp.SkelTransparency, 0, 1)
			end
		end
	end
end

-- Drawing objects render ABOVE every ScreenGui on executors, so the only way
-- to keep the menu readable is to pause the ESP while it is open. The ESP
-- follows the real menu state (Window.Holder.Visible) instead of a manual
-- flag, so it also stays in sync when the menu is toggled by the library's
-- own keybinds (RightShift / RightControl).
function toggleUI()
	pcall(function() Library:Toggle() end)
	if Window and Window.Holder and Window.Holder.Visible then
		for p in pairs(espData) do
			local d = espData[p]
			if d then espHide(d) end
		end
	end
end

function espUpdate()
	if not Drawing then return end
	if Window and Window.Holder and Window.Holder.Visible then
		for p in pairs(espData) do
			local d = espData[p]
			if d then espHide(d) end
		end
		return
	end
	S.Esp.RainbowHue = (S.Esp.RainbowHue + 0.003) % 1
	local cam = Workspace.CurrentCamera
	if not cam then return end
	local vp = cam.ViewportSize
	local myRoot = getRoot()
	for _, p in ipairs(Players:GetPlayers()) do
		if p == LocalPlayer then continue end
		pcall(espRenderPlayer, cam, vp, myRoot, p)
	end
	for p in pairs(espData) do
		if not p.Parent then espDestroy(p) end
	end
end

function setEspState(v)
	S.Esp.Enabled = v
	if espConn then pcall(function() espConn:Disconnect() end); espConn = nil end
	if not v then
		for p in pairs(espData) do espDestroy(p) end
		return
	end
	if not Drawing then notify("ESP", "Drawing API not available on this executor", 3); return end
	espConn = addConn(RunService.RenderStepped:Connect(function() pcall(espUpdate) end))
end

function espApply()
	for p in pairs(espData) do espDestroy(p) end
	if S.Esp.Enabled and Drawing then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and p.Character and p.Character.Parent then espMake(p) end
		end
	end
	notify("ESP", "Settings applied", 2)
end

-- ESP preview: shows your own character plus the live ESP settings in a small
-- corner viewport. It renders through its OWN camera (a ViewportFrame camera)
-- and never touches Workspace.CurrentCamera, so camera scripts that change the
-- view are left completely alone and can never freeze the camera.
local prevCam, prevGui, prevClone, prevPlayer, prevRoot = nil, nil, nil, nil, nil
local prevYaw = 0
function setEspPreviewState(v)
	S.Esp.Preview = v
	loopStop("Preview")
	if not v then
		prevYaw = 0
		if prevGui then pcall(function() prevGui:Destroy() end); prevGui = nil end
		prevCam = nil
		if prevClone then pcall(function() prevClone:Destroy() end); prevClone = nil end
		if prevPlayer and espData[prevPlayer] then espDestroy(prevPlayer) end
		prevPlayer = nil
		prevRoot = nil
		return
	end
	if prevGui then pcall(function() prevGui:Destroy() end); prevGui = nil end
	if not Drawing then notify("ESP Preview", "Drawing API unavailable", 2); return end
	local plrGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui")
	gui.Name = "ABSOLUTE_Preview"
	gui.IgnoreGuiInset = true
	gui.Parent = plrGui
	local bg = Instance.new("Frame")
	bg.Name = "BG"
	bg.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
	bg.BackgroundTransparency = 0.25
	bg.BorderSizePixel = 0
	bg.Position = UDim2.new(1, -196, 0, 12)
	bg.Size = UDim2.fromOffset(184, 148)
	bg.Parent = gui
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
	title.BorderSizePixel = 0
	title.Font = Enum.Font.GothamBold
	title.Text = "ESP PREVIEW"
	title.TextColor3 = Color3.fromRGB(228, 228, 228)
	title.TextSize = 12
	title.Size = UDim2.new(1, 0, 0, 18)
	title.Parent = bg
	local vp = Instance.new("ViewportFrame")
	vp.Name = "Viewport"
	vp.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
	vp.BorderSizePixel = 0
	vp.Position = UDim2.new(0, 0, 0, 18)
	vp.Size = UDim2.new(1, 0, 1, -18)
	vp.Parent = bg
	local cam = Instance.new("Camera")
	cam.CameraType = Enum.CameraType.Scriptable
	cam.Parent = vp
	vp.CurrentCamera = cam
	prevGui = gui
	prevCam = cam
	prevYaw = 0
	prevPlayer = { Name = LocalPlayer.Name, DisplayName = LocalPlayer.DisplayName, UserId = LocalPlayer.UserId, Parent = LocalPlayer }
	loopStart("Preview", function()
		if Window and Window.Holder and Window.Holder.Visible then return end
		local myRoot = getRoot()
		local rc = myRoot and myRoot.Parent
		if not prevGui or not prevGui.Parent or not prevCam or not rc then return end
		local vpAbs = prevGui.BG and prevGui.BG.Viewport
		if not vpAbs then return end
		local size = vpAbs.AbsoluteSize
		if size.X <= 1 or size.Y <= 1 then return end
		-- A ViewportFrame only renders objects parented to it (not the
		-- Workspace), so we keep a copy of the rig inside the frame and sync
		-- its position to the real body every frame.
		if not prevClone or prevClone.Parent ~= vpAbs or prevRoot ~= rc then
			if prevClone then pcall(function() prevClone:Destroy() end) end
			if not rc then prevClone = nil; prevRoot = nil; return end
			local ok, clone = pcall(function()
				local c = rc:Clone()
				local animate = c:FindFirstChild("Animate")
				if animate then animate:Destroy() end
				local animator = c:FindFirstChildOfClass("Animator")
				if animator then animator:Destroy() end
				return c
			end)
			if not ok or not clone then prevClone = nil; prevRoot = nil; return end
			prevClone = clone
			prevClone.Parent = vpAbs
			prevRoot = rc
			prevPlayer.Character = prevClone
			if espData[prevPlayer] then espDestroy(prevPlayer) end
		end
		local realRP = rc:FindFirstChild("HumanoidRootPart") or rc.PrimaryPart
		if realRP then pcall(function() prevClone:PivotTo(realRP.CFrame) end) end
		local rp = prevClone:FindFirstChild("HumanoidRootPart") or prevClone.PrimaryPart
		if not rp then return end
		local delta = UserInputService:GetMouseDelta()
		prevYaw = prevYaw + delta.X * 0.0025
		local eye = rp.Position + CFrame.Angles(0, prevYaw, 0) * Vector3.new(0, 3, 12)
		prevCam.CFrame = CFrame.lookAt(eye, rp.Position + Vector3.new(0, 2.5, 0))
		if Drawing then
			pcall(espRenderPlayer, prevCam, size, myRoot, prevPlayer, vpAbs.AbsolutePosition)
		end
	end)
end

-- ----------------------------------------------------------------------------
-- PLAYERS (visibility / spectate / fling)
-- ----------------------------------------------------------------------------
local hideOrig = {}
function hideCharParts(ch)
	if not ch then return end
	for _, x in ipairs(ch:GetDescendants()) do
		if x:IsA("BasePart") then
			if hideOrig[x] == nil then hideOrig[x] = x.LocalTransparencyModifier end
			x.LocalTransparencyModifier = 1
		end
	end
end

function setHidePlayersState(v)
	if v then
		loopStart("HidePlayers", function()
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= LocalPlayer then
					local ch = p.Character
					if ch and ch.Parent then hideCharParts(ch) end
				end
			end
		end)
	else
		loopStop("HidePlayers")
		for part, val in pairs(hideOrig) do
			if part and part.Parent then pcall(function() part.LocalTransparencyModifier = val end) end
		end
		hideOrig = {}
	end
end

local specCam, specSubject, specTarget = nil, nil, nil
local specYaw, specPitch = 0, 0
function specApply(v)
	if not v then
		loopStop("Spec")
		if specCam then
			pcall(function()
				-- Hand the camera back to the player. We keep the SAME camera
				-- instance the whole time, so the game's camera controller is
				-- still tracking it: forcing the type back to Custom with the
				-- original subject (or the LocalPlayer's Humanoid) makes it
				-- follow the player again. Swapping to a fresh Camera object
				-- is what left the view stuck in the old version.
				specCam.CameraType = Enum.CameraType.Custom
				if specSubject then
					specCam.CameraSubject = specSubject
				else
					local ch = getChar()
					local hum = ch and ch:FindFirstChildOfClass("Humanoid")
					if hum then specCam.CameraSubject = hum end
				end
			end)
			specCam, specSubject, specTarget = nil, nil, nil
		end
		return
	end
	local cur = Workspace.CurrentCamera
	if not cur then notify("Spectate", "Camera not ready", 2); return end
	local t = lockedTarget()
	local tr = t and getPlayerRoot(t)
	if not tr then notify("Spectate", "Target not ready", 2); return end
	specCam = cur
	specSubject = cur.CameraSubject
	specTarget = tr
	specYaw, specPitch = 0, 0
	cur.CameraType = Enum.CameraType.Scriptable
	loopStart("Spec", function()
		local tr2 = specTarget
		if not tr2 or not tr2.Parent then return end
		local hum = tr2.Parent:FindFirstChildOfClass("Humanoid")
		if hum then specCam.CameraSubject = hum end
		local delta = UserInputService:GetMouseDelta()
		specYaw = specYaw + delta.X * 0.0025
		specPitch = math.clamp(specPitch + delta.Y * 0.0025, -0.5, 1.2)
		local offset = CFrame.Angles(specPitch, specYaw, 0) * Vector3.new(0, 2, 10)
		local pos = tr2.Position + offset
		specCam.CFrame = CFrame.lookAt(pos, tr2.Position + Vector3.new(0, 1, 0))
	end)
end

local flingTool, flingHandle, flingConn = nil, nil, nil
function setFlingState(v)
	if flingConn then pcall(function() flingConn:Disconnect() end); flingConn = nil end
	if flingTool then pcall(function() flingTool:Destroy() end); flingTool = nil end
	flingHandle = nil
	local r = getRoot()
	if r then
		pcall(function()
			r.Anchored = false
			r.AssemblyLinearVelocity = Vector3.zero
			r.AssemblyAngularVelocity = Vector3.zero
		end)
	end
	if not v then return end
	local t = lockedTarget()
	local ch = getChar()
	local hum = getHum()
	if not t or not ch or not hum then notify("Fling", "Character or target missing", 2); return end
	flingTool = Instance.new("Tool")
	flingTool.Name = "AbsoluteFling"
	flingTool.RequiresHandle = false
	flingHandle = Instance.new("Part")
	flingHandle.Name = "Handle"
	flingHandle.Size = Vector3.new(1, 1, 1)
	flingHandle.Anchored = false
	flingHandle.CanCollide = true
	flingHandle.Massless = false
	flingHandle.Parent = flingTool
	flingTool.Parent = ch
	pcall(function() hum:EquipTool(flingTool) end)
	flingConn = addConn(RunService.RenderStepped:Connect(function()
		local r2 = getRoot()
		local tr = getPlayerRoot(t)
		if not r2 or not tr or not tr.Parent then return end
		pcall(function()
			-- Anchor ourselves so the overlap shove is applied to the target
			-- only, never to us. Keeping the target overlapped also keeps
			-- network ownership so the velocity writes go through.
			r2.Anchored = true
			r2.AssemblyLinearVelocity = Vector3.zero
			r2.AssemblyAngularVelocity = Vector3.zero
			r2.CFrame = tr.CFrame + Vector3.new(0, -0.5, 0)
			if flingHandle then
				flingHandle.CFrame = tr.CFrame
				flingHandle.AssemblyLinearVelocity = Vector3.new(0, 60, 0)
				flingHandle.AssemblyAngularVelocity = Vector3.new(0, 1000, 0)
			end
			local dir = tr.Position - r2.Position
			if dir.Magnitude < 1 then dir = Vector3.new(0, 1, 0) end
			dir = Vector3.new(dir.X, 0.5, dir.Z)
			if dir.Magnitude < 0.001 then dir = Vector3.new(0, 1, 0) end
			dir = dir.Unit
			tr.AssemblyLinearVelocity = dir * 500 + Vector3.new(0, 100, 0)
			tr.AssemblyAngularVelocity = Vector3.new(0, 1000, 0)
		end)
	end))
end

local flingTouchConn = nil
function setFlingTouchState(v)
	if flingTouchConn then pcall(function() flingTouchConn:Disconnect() end); flingTouchConn = nil end
	local r = getRoot()
	if r then pcall(function() r.Anchored = false end) end
	if not v then return end
	flingTouchConn = addConn(RunService.RenderStepped:Connect(function()
		local r2 = getRoot()
		if not r2 then return end
		local hit = false
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer then
				local tr = getPlayerRoot(p)
				if tr and tr.Parent then
					local dist = (tr.Position - r2.Position).Magnitude
					if dist < 7 then
						hit = true
						pcall(function()
							-- Overlap with an anchored root: the physics shove
							-- goes entirely to them, we stay put.
							r2.CFrame = tr.CFrame + Vector3.new(0, -0.5, 0)
							r2.AssemblyLinearVelocity = Vector3.zero
							r2.AssemblyAngularVelocity = Vector3.zero
							local dir = tr.Position - r2.Position
							if dir.Magnitude < 1 then dir = Vector3.new(0, 1, 0) end
							dir = Vector3.new(dir.X, 0.5, dir.Z)
							if dir.Magnitude < 0.001 then dir = Vector3.new(0, 1, 0) end
							dir = dir.Unit
							tr.AssemblyLinearVelocity = dir * 450 + Vector3.new(0, 90, 0)
							tr.AssemblyAngularVelocity = Vector3.new(0, 900, 0)
						end)
					end
				end
			end
		end
		-- Anchor while anyone is in range so only they get flung; release as
		-- soon as the area is clear so normal movement keeps working.
		pcall(function() r2.Anchored = hit end)
	end))
end

local bringOrig = {}
function setBringState(v)
	if not v then
		loopStop("Bring")
		for _, data in pairs(bringOrig) do
			pcall(function()
				if data.part and data.part.Parent then
					data.part.CFrame = data.cf
					data.part.AssemblyLinearVelocity = Vector3.zero
					data.part.AssemblyAngularVelocity = Vector3.zero
					data.part.Anchored = data.anch
				end
			end)
		end
		bringOrig = {}
		return
	end
	local t = lockedTarget()
	if not t then notify("Bring", "Target not ready", 2); return end
	loopStart("Bring", function()
		local r = getRoot()
		local tr = getPlayerRoot(t)
		if not r or not tr or not tr.Parent then return end
		local d = bringOrig[t]
		if not d or d.part ~= tr then bringOrig[t] = { part = tr, cf = tr.CFrame, anch = tr.Anchored } end
		pcall(function()
			tr.AssemblyLinearVelocity = Vector3.zero
			tr.AssemblyAngularVelocity = Vector3.zero
			tr.Anchored = true
			tr.CFrame = r.CFrame + Vector3.new(0, 3, 0)
		end)
	end)
	notify("Bring", "Bringing " .. t.Name .. ". Toggle OFF restores position.", 2)
end

local bringAllOrig = {}
function setBringAllState(v)
	if not v then
		loopStop("BringAll")
		local count = 0
		for _, data in pairs(bringAllOrig) do
			pcall(function()
				if data.part and data.part.Parent then
					data.part.CFrame = data.cf
					data.part.AssemblyLinearVelocity = Vector3.zero
					data.part.AssemblyAngularVelocity = Vector3.zero
					data.part.Anchored = data.anch
					count = count + 1
				end
			end)
		end
		bringAllOrig = {}
		notify("Bring All", "Restored " .. count .. " targets.", 2)
		return
	end
	local root = getRoot()
	if not root then notify("Bring All", "Character not ready", 2); return end
	loopStart("BringAll", function()
		local r = getRoot()
		if not r then return end
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer then
				local hrp = getPlayerRoot(p)
				if hrp and hrp.Parent then
					local d = bringAllOrig[p]
					if not d or d.part ~= hrp then bringAllOrig[p] = { part = hrp, cf = hrp.CFrame, anch = hrp.Anchored } end
					pcall(function()
						hrp.AssemblyLinearVelocity = Vector3.zero
						hrp.AssemblyAngularVelocity = Vector3.zero
						hrp.Anchored = true
						hrp.CFrame = r.CFrame * CFrame.new(math.random(-6, 6), 3, math.random(-6, 6))
					end)
				end
			end
		end
	end)
	notify("Bring All", "Bringing all players. Toggle OFF restores positions.", 2)
end

local freezeOrig = {}
function setFreezeState(v)
	if not v then
		loopStop("Freeze")
		for m, data in pairs(freezeOrig) do
			for _, e in ipairs(data) do
				if e.part and e.part.Parent then pcall(function() e.part.Anchored = e.anch end) end
			end
		end
		freezeOrig = {}
		return
	end
	local t = lockedTarget()
	if not t then notify("Freeze", "Target not ready", 2); return end
	loopStart("Freeze", function()
		local c2 = t.Character
		if not c2 or not c2.Parent then return end
		local data = freezeOrig[c2] or {}
		if #data == 0 then
			for _, part in ipairs(c2:GetDescendants()) do
				if part:IsA("BasePart") then data[#data + 1] = { part = part, anch = part.Anchored } end
			end
			freezeOrig[c2] = data
		end
		for _, e in ipairs(data) do
			if e.part and e.part.Parent then pcall(function() e.part.Anchored = true end) end
		end
	end)
end

function copyPlayerName(name)
	if not name or name == "No players" then notify("Copy", "No player selected", 2); return end
	local p = Players:FindFirstChild(name)
	if not p then return end
	local ok = pcall(function() setclipboard(p.Name) end)
	notify("Copy", (ok and "Copied " or "Player: ") .. p.Name, 2)
end

-- ----------------------------------------------------------------------------
-- MOVEMENT
-- ----------------------------------------------------------------------------
local flyBV, flyBG = nil, nil
function setFlyState(v)
	if v then
		local root, hum = getRoot(), getHum()
		if not root then notify("Fly", "Character not ready", 2); return end
		if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Flying) end) end
		if not flyBV then
			flyBV = Instance.new("BodyVelocity")
			flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
			flyBV.Parent = root
			flyBG = Instance.new("BodyGyro")
			flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
			flyBG.D = 1000
			flyBG.Parent = root
		end
		loopStart("Fly", function()
			local root2, hum2 = getRoot(), getHum()
			if not root2 then return end
			if hum2 then pcall(function() if hum2:GetState() ~= Enum.HumanoidStateType.Flying then hum2:ChangeState(Enum.HumanoidStateType.Flying) end end) end
			local cam = Workspace.CurrentCamera
			local dir = Vector3.new(0, 0, 0)
			if cam then
				dir = getMoveDir(cam)
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
				if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir + Vector3.new(0, -1, 0) end
			end
			if flyBV then flyBV.Velocity = dir.Unit * S.Move.FlySpeed end
			if flyBG and cam then flyBG.CFrame = cam.CFrame end
		end)
	else
		loopStop("Fly")
		if flyBV then pcall(function() flyBV:Destroy() end); flyBV = nil end
		if flyBG then pcall(function() flyBG:Destroy() end); flyBG = nil end
	end
end

local noclipOrig = {}
function setNoclipState(v)
	if not v then
		loopStop("Noclip")
		for part, val in pairs(noclipOrig) do
			if part and part.Parent then pcall(function() part.CanCollide = val end) end
		end
		noclipOrig = {}
		return
	end
	loopStart("Noclip", function()
		for _, part in ipairs(getParts()) do
			if part.CanCollide then
				if noclipOrig[part] == nil then noclipOrig[part] = part.CanCollide end
				pcall(function() part.CanCollide = false end)
			end
		end
	end)
end

function setSpeedState(v)
	if v then
		loopStart("Speed", function()
			local hum = getHum()
			if hum then pcall(function() hum.WalkSpeed = math.max(0, S.Move.WalkSpeed) end) end
		end)
	else
		loopStop("Speed")
	end
end

function setJumpState(v)
	if v then
		loopStart("Jump", function()
			local hum = getHum()
			if hum then pcall(function()
				hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
				hum.JumpPower = math.clamp(S.Move.JumpPower, 0, 300)
				hum.JumpHeight = S.Move.JumpPower * 0.2
			end) end
		end)
	else
		loopStop("Jump")
	end
end

local infJumpConn = nil
function setInfJumpState(v)
	if infJumpConn then pcall(function() infJumpConn:Disconnect() end); infJumpConn = nil end
	if not v then return end
	infJumpConn = addConn(UserInputService.JumpRequest:Connect(function()
		local root, hum = getRoot(), getHum()
		if root and hum and hum.Health > 0 then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
	end))
end

function setNoFallState(v)
	if v then
		loopStart("NoFall", function()
			local hum = getHum()
			if hum then pcall(function()
				hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
				if hum:GetState() == Enum.HumanoidStateType.FallingDown then hum:ChangeState(Enum.HumanoidStateType.Running) end
			end) end
		end)
	else
		loopStop("NoFall")
	end
end

local floatBV = nil
local floatStart = nil
function setFloatState(v)
	if v then
		local r = getRoot()
		if not r then notify("Float", "Character not ready", 2); return end
		floatStart = r.Position.Y
		if not floatBV then
			floatBV = Instance.new("BodyVelocity")
			floatBV.MaxForce = Vector3.new(0, 9e9, 0)
			floatBV.Parent = r
		end
		loopStart("Float", function()
			local rr = getRoot()
			if rr and floatBV then
				floatBV.Velocity = Vector3.new(0, (floatStart - rr.Position.Y) * 4, 0)
			end
		end)
	else
		loopStop("Float")
		if floatBV then pcall(function() floatBV:Destroy() end); floatBV = nil end
	end
end

function setWaterWalkState(v)
	if v then
		loopStart("WaterWalk", function()
			local root = getRoot()
			if root and root.AssemblyLinearVelocity.Y < -1 and root.Position.Y < 1 then
				pcall(function() root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z) end)
			end
		end)
	else
		loopStop("WaterWalk")
	end
end

function setSpinState(v)
	if v then
		loopStart("Spin", function(dt)
			local root = getRoot()
			if root then pcall(function()
				-- Physics-driven spin: the Humanoid resets CFrame rotation every
				-- frame, so use angular velocity instead - it can't be undone
				-- by the character controller.
				root.AssemblyAngularVelocity = Vector3.new(0, S.Move.SpinSpeed, 0)
			end) end
		end)
	else
		loopStop("Spin")
		local root = getRoot()
		if root then pcall(function() root.AssemblyAngularVelocity = Vector3.zero end) end
	end
end

function setHipHeightState(v)
	if v then
		loopStart("HipHeight", function()
			local hum = getHum()
			if hum then pcall(function() hum.HipHeight = S.Move.HipHeight end) end
		end)
	else
		loopStop("HipHeight")
	end
end

function setAntiVoidState(v)
	if v then
		loopStart("AntiVoid", function()
			local root = getRoot()
			if root and root.Position.Y < S.Move.VoidLevel then
				pcall(function() root.CFrame = root.CFrame + Vector3.new(0, 30, 0) end)
			end
		end)
	else
		loopStop("AntiVoid")
	end
end

function setBhopState(v)
	if v then
		loopStart("Bhop", function()
			if not UserInputService:IsKeyDown(Enum.KeyCode.Space) then return end
			local root, hum = getRoot(), getHum()
			if not root or not hum then return end
			local st = hum:GetState()
			if (st == Enum.HumanoidStateType.Running or st == Enum.HumanoidStateType.FallingDown) and root.AssemblyLinearVelocity.Magnitude > 8 then
				pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
			end
		end)
	else
		loopStop("Bhop")
	end
end

function setAutoJumpState(v)
	if v then
		loopStart("AutoJump", function()
			local root, hum = getRoot(), getHum()
			if not root or not hum or hum.Health <= 0 then return end
			local st = hum:GetState()
			if st == Enum.HumanoidStateType.Running and root.AssemblyLinearVelocity.Magnitude > 4 then
				pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
			end
		end)
	else
		loopStop("AutoJump")
	end
end

function doClickTp()
	local root = getRoot()
	if not root then notify("Click TP", "Character not ready", 2); return end
	local cam = Workspace.CurrentCamera
	if not cam then return end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { getChar() }
	local res = Workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 2048, params)
	local pos = (res and res.Position) or (cam.CFrame.Position + cam.CFrame.LookVector * 2048)
	root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
	root.AssemblyLinearVelocity = Vector3.zero
end

addConn(UserInputService.InputBegan:Connect(function(input)
	if not S.Move.ClickTpEnabled then return end
	local isKey = input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == S.Move.ClickTpKey
	local isMb2 = S.Move.ClickTpKey == "MB2" and input.UserInputType == Enum.UserInputType.MouseButton2
	if isKey or isMb2 then doClickTp() end
end))

local waypoints = {}
local wpDraws = {}
function wpRefresh()
	pcall(function()
		if UI.WpSelect then
			local names = {}
			for _, w in ipairs(waypoints) do names[#names + 1] = w.Name end
			if #names == 0 then names = { "None" } end
			UI.WpSelect:SetValues(names)
			UI.WpSelect:SetValue(names[1])
		end
	end)
end
function wpAdd()
	local r = getRoot()
	if not r then notify("Waypoint", "Character not ready", 2); return end
	local n = #waypoints + 1
	waypoints[#waypoints + 1] = { Name = "WP " .. n, Pos = r.Position }
	wpRefresh()
	notify("Waypoint", "Added WP " .. n, 2)
end
function wpTp()
	local r = getRoot()
	if not r then notify("Waypoint", "Character not ready", 2); return end
	local name = (Options and Options["Move_WpSelect"] and Options["Move_WpSelect"].Value) or "None"
	for _, w in ipairs(waypoints) do
		if w.Name == name then
			r.CFrame = CFrame.new(w.Pos + Vector3.new(0, 2, 0))
			r.AssemblyLinearVelocity = Vector3.zero
			notify("Waypoint", "Teleported", 2)
			return
		end
	end
	notify("Waypoint", "None selected", 2)
end
function wpClear()
	for _, d in ipairs(wpDraws) do pcall(function() d:Remove() end) end
	wpDraws = {}
	waypoints = {}
	wpRefresh()
	notify("Waypoint", "Cleared all", 2)
end

local wpMarkConn = nil
function setWpMarkersState(v)
	if wpMarkConn then pcall(function() wpMarkConn:Disconnect() end); wpMarkConn = nil end
	for _, d in ipairs(wpDraws) do pcall(function() d:Remove() end) end
	wpDraws = {}
	if not v then return end
	if not Drawing then notify("Waypoints", "Drawing API unavailable", 2); return end
	wpMarkConn = addConn(RunService.RenderStepped:Connect(function()
		local cam = Workspace.CurrentCamera
		if not cam then return end
		local r = getRoot()
		for i, w in ipairs(waypoints) do
			local d = wpDraws[i]
			if not d then
				local circ = Drawing.new("Circle")
				circ.Thickness = 1
				circ.NumSides = 24
				circ.Transparency = 1
				local lbl = Drawing.new("Text")
				lbl.Size = 13
				lbl.Center = true
				lbl.Outline = true
				lbl.OutlineColor = Color3.new(0, 0, 0)
				lbl.Font = 2
				lbl.Visible = false
				d = { circ = circ, lbl = lbl }
				wpDraws[i] = d
			end
			local sp, on = espProject(cam, w.Pos, cam.ViewportSize)
			local vis = on and sp.Z > 0
			d.circ.Visible = vis
			d.lbl.Visible = vis
			if vis then
				d.circ.Position = Vector2.new(sp.X, sp.Y)
				d.circ.Radius = 6
				d.circ.Color = Library.AccentColor
				local txt = w.Name
				if r then txt = txt .. "  [" .. math.floor((r.Position - w.Pos).Magnitude) .. "m]" end
				d.lbl.Text = txt
				d.lbl.Position = Vector2.new(sp.X, sp.Y - 16)
				d.lbl.Color = Library.AccentColor
			end
		end
	end))
end

function setDesyncState(v)
	if v then
		local root = getRoot()
		if not root then notify("Desync", "Character not ready", 2); return end
		pcall(function() root:SetNetworkOwner(nil) end)
		loopStart("Desync", function(dt)
			local r = getRoot()
			if not r then return end
			pcall(function()
				if r:GetNetworkOwner() ~= nil then r:SetNetworkOwner(nil) end
				local cam = Workspace.CurrentCamera
				if cam then
					local dir = getMoveDir(cam)
					if dir.Magnitude > 0.001 then
						r.CFrame = r.CFrame + dir.Unit * S.Move.WalkSpeed * dt * 0.6
					end
				end
			end)
		end)
	else
		loopStop("Desync")
		local r = getRoot()
		if r then pcall(function() r:SetNetworkOwner(LocalPlayer) end) end
	end
end

-- ----------------------------------------------------------------------------
-- VISUALS
-- ----------------------------------------------------------------------------
local fullbrightOrig = nil
function setFullBrightState(v)
	if v then
		if not fullbrightOrig then
			pcall(function()
				fullbrightOrig = {
					Brightness = Lighting.Brightness, Ambient = Lighting.Ambient,
					OutdoorAmbient = Lighting.OutdoorAmbient, Shadows = Lighting.GlobalShadows,
				}
			end)
		end
		loopStart("FullBright", function()
			pcall(function()
				Lighting.Brightness = 2.5
				Lighting.Ambient = Color3.new(1, 1, 1)
				Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
				Lighting.GlobalShadows = false
			end)
		end)
	else
		loopStop("FullBright")
		if fullbrightOrig then
			pcall(function()
				Lighting.Brightness = fullbrightOrig.Brightness
				Lighting.Ambient = fullbrightOrig.Ambient
				Lighting.OutdoorAmbient = fullbrightOrig.OutdoorAmbient
				Lighting.GlobalShadows = fullbrightOrig.Shadows
			end)
			fullbrightOrig = nil
		end
	end
end

local nvOrig = nil
function setNightVisionState(v)
	if v then
		if not nvOrig then
			pcall(function()
				nvOrig = { Brightness = Lighting.Brightness, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient }
			end)
		end
		loopStart("NightVision", function()
			pcall(function()
				Lighting.Brightness = 2
				Lighting.Ambient = Color3.fromRGB(120, 200, 160)
				Lighting.OutdoorAmbient = Color3.fromRGB(120, 200, 160)
			end)
		end)
	else
		loopStop("NightVision")
		if nvOrig then
			pcall(function()
				Lighting.Brightness = nvOrig.Brightness
				Lighting.Ambient = nvOrig.Ambient
				Lighting.OutdoorAmbient = nvOrig.OutdoorAmbient
			end)
			nvOrig = nil
		end
	end
end

local fogOrig = nil
function setNoFogState(v)
	if v then
		if not fogOrig then pcall(function() fogOrig = { Start = Lighting.FogStart, End = Lighting.FogEnd } end) end
		loopStart("NoFog", function() pcall(function() Lighting.FogEnd = math.huge end) end)
	else
		loopStop("NoFog")
		if fogOrig then
			pcall(function()
				Lighting.FogStart = fogOrig.Start
				Lighting.FogEnd = fogOrig.End
			end)
			fogOrig = nil
		end
	end
end

function setFovState(v)
	if v then
		loopStart("Fov", function()
			local cam = Workspace.CurrentCamera
			if cam then pcall(function() cam.FieldOfView = math.clamp(S.Vis.Fov, 1, 120) end) end
		end)
	else
		loopStop("Fov")
		local cam = Workspace.CurrentCamera
		if cam then pcall(function() cam.FieldOfView = 70 end) end
	end
end

local freecamCam = nil
local freecamConn = nil
local freecamFreeze = nil
function setFreecamState(v)
	if freecamConn then pcall(function() freecamConn:Disconnect() end); freecamConn = nil end
	if not v then
		local cam = Workspace.CurrentCamera
		if cam then
			pcall(function()
				cam.CameraType = Enum.CameraType.Custom
				if freecamCam then
					cam.CFrame = freecamCam.CFrame
					freecamCam:Destroy()
					freecamCam = nil
				end
			end)
		end
		freecamFreeze = nil
		return
	end
	local cam = Workspace.CurrentCamera
	if not cam then return end
	local root = getRoot()
	if root then freecamFreeze = { root = root, cf = root.CFrame } end
	if not freecamCam then
		freecamCam = Instance.new("Camera")
		freecamCam.CameraType = Enum.CameraType.Scriptable
		freecamCam.CFrame = cam.CFrame
		freecamCam.Parent = Workspace
	end
	freecamConn = addConn(RunService.RenderStepped:Connect(function(dt)
		-- Freeze the local character in place so the player can't move (or
		-- fall) while the freecam is active.
		if freecamFreeze then
			pcall(function()
				local fr = freecamFreeze.root
				if fr and fr.Parent then
					fr.CFrame = freecamFreeze.cf
					fr.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
					fr.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
				end
			end)
		end
		pcall(function()
			local c = freecamCam
			if not c then return end
			local dir = Vector3.new(0, 0, 0)
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + c.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - c.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - c.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + c.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir + Vector3.new(0, -1, 0) end
			if dir.Magnitude > 0 then c.CFrame = c.CFrame + dir.Unit * S.Vis.FreecamSpeed * dt end
			c.CFrame = CFrame.lookAt(c.CFrame.Position, c.CFrame.Position + c.CFrame.LookVector + UserInputService:GetMouseDelta() * 0.01)
		end)
	end))
	Workspace.CurrentCamera = freecamCam
end

local hudConn = nil
local hudGui = nil
function setHudState(v)
	if hudConn then pcall(function() hudConn:Disconnect() end); hudConn = nil end
	if hudGui then pcall(function() hudGui:Destroy() end); hudGui = nil end
	if not v then return end
	hudGui = Instance.new("ScreenGui")
	hudGui.Name = "MP_HUD"
	hudGui.ResetOnSpawn = false
	hudGui.IgnoreGuiInset = true
	hudGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.new(0, 280, 0, 20)
	lbl.Position = UDim2.new(1, -290, 1, -30)
	lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
	lbl.TextStrokeTransparency = 0.3
	lbl.TextSize = 16
	lbl.Font = Enum.Font.GothamBold
	lbl.Text = "FPS: 0  |  Ping: 0ms  |  MPH: 0"
	lbl.Parent = hudGui
	hudConn = addConn(RunService.RenderStepped:Connect(function(dt)
		local fps = math.floor(1 / math.max(0.001, dt))
		local root = getRoot()
		local mph = root and math.floor(root.AssemblyLinearVelocity.Magnitude * 0.626) or 0
		local ping = pingValue()
		lbl.Text = "FPS: " .. fps .. "  |  Ping: " .. ping .. "ms  |  MPH: " .. mph
	end))
end

function setFpsBoostState(v)
	if v then
		loopStart("FpsBoost", function()
			pcall(function()
				for _, x in ipairs(Workspace:GetDescendants()) do
					if x:IsA("ParticleEmitter") then x.Enabled = false end
					if x:IsA("Fire") or x:IsA("Smoke") or x:IsA("Sparkles") then x.Enabled = false end
				end
				Lighting.GlobalShadows = false
			end)
		end)
	else
		loopStop("FpsBoost")
	end
end

local tpCam = nil
local tpSubject = nil
local tpYaw = 0
function setThirdPersonState(v)
	if not v then
		loopStop("ThirdPerson")
		if tpCam then
			pcall(function()
				-- Same camera instance the whole time, so restoring the type
				-- and subject makes the game's camera controller follow us
				-- again (see the spectate camera for details).
				tpCam.CameraType = Enum.CameraType.Custom
				if tpSubject then
					tpCam.CameraSubject = tpSubject
				else
					local hum = getHum()
					if hum then tpCam.CameraSubject = hum end
				end
			end)
			tpCam, tpSubject = nil, nil
		end
		return
	end
	local cur = Workspace.CurrentCamera
	if not cur then notify("Third Person", "Camera not ready", 2); return end
	tpCam = cur
	tpSubject = cur.CameraSubject
	tpYaw = 0
	cur.CameraType = Enum.CameraType.Scriptable
	loopStart("ThirdPerson", function()
		local r = getRoot()
		if not r or not tpCam then return end
		local hum2 = getHum()
		if hum2 then tpCam.CameraSubject = hum2 end
		local delta = UserInputService:GetMouseDelta()
		tpYaw = tpYaw + delta.X * 0.0025
		local dist = S.Vis.ThirdDist
		local offset = CFrame.Angles(0, tpYaw, 0) * Vector3.new(0, 3, dist)
		local eye = r.Position + offset
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { getChar() }
		local res = Workspace:Raycast(r.Position + Vector3.new(0, 3, 0), eye - (r.Position + Vector3.new(0, 3, 0)), params)
		if res then eye = res.Position + (eye - (r.Position + Vector3.new(0, 3, 0))).Unit * 1 end
		tpCam.CFrame = CFrame.lookAt(eye, r.Position + Vector3.new(0, 2.5, 0))
	end)
end

local xhConn = nil
local xhDraws = {}
local xhHue = 0
function setCrosshairState(v)
	if xhConn then pcall(function() xhConn:Disconnect() end); xhConn = nil end
	for _, d in ipairs(xhDraws) do pcall(function() d:Remove() end) end
	xhDraws = {}
	if not v then return end
	if not Drawing then notify("Crosshair", "Drawing API unavailable", 2); return end
	local dot = Drawing.new("Circle")
	dot.Filled = true
	dot.Thickness = 1
	dot.NumSides = 32
	local ring = Drawing.new("Circle")
	ring.Filled = false
	ring.Thickness = 1
	ring.NumSides = 32
	local lines = {}
	for i = 1, 8 do
		local l = Drawing.new("Line")
		l.Thickness = 1
		l.Transparency = 1
		lines[i] = l
	end
	xhDraws = { dot = dot, ring = ring, lines = lines }
	xhConn = addConn(RunService.RenderStepped:Connect(function(dt)
		local cam = Workspace.CurrentCamera
		if not cam then return end
		local c = cam.ViewportSize / 2
		local size = S.Vis.XhSize
		local gap = S.Vis.XhGap
		local style = (Options and Options["Vis_XhStyle"] and Options["Vis_XhStyle"].Value) or S.Vis.XhStyle
		local color = (Options and Options["Vis_XhColor"] and Options["Vis_XhColor"].Value) or S.Vis.XhColor
		if S.Vis.XhRainbow then
			xhHue = (xhHue + (dt or 0.016) * 0.4) % 1
			color = Color3.fromHSV(xhHue, 1, 1)
		end
		local dotOn = (style == "Dot" or style == "Circle" or style == "Plus" or style == "T")
		xhDraws.dot.Position = c
		xhDraws.dot.Radius = math.max(1, size * 0.3)
		xhDraws.dot.Color = color
		xhDraws.dot.Transparency = 1
		xhDraws.dot.Visible = dotOn
		xhDraws.ring.Position = c
		xhDraws.ring.Radius = math.max(4, size)
		xhDraws.ring.Color = color
		xhDraws.ring.Transparency = 1
		xhDraws.ring.Visible = (style == "Circle")
		local half = size * 0.5
		local off = gap + half
		local L = xhDraws.lines
		local n = 0
		local function seg(ax, ay, bx, by)
			n = n + 1
			local l = L[n]
			l.From = c + Vector2.new(ax, ay)
			l.To = c + Vector2.new(bx, by)
			l.Color = color
			l.Transparency = 1
			l.Visible = true
		end
		if style == "Cross" or style == "Plus" then
			seg(-off, 0, -gap, 0)
			seg(gap, 0, off, 0)
			seg(0, -off, 0, -gap)
			seg(0, gap, 0, off)
		elseif style == "T" then
			seg(-off, 0, -gap, 0)
			seg(gap, 0, off, 0)
			seg(0, gap, 0, off)
		elseif style == "Corners" then
			local cl = size * 0.8
			seg(-cl, -cl, -cl, -half)
			seg(-cl, -cl, -half, -cl)
			seg(cl, -cl, cl, -half)
			seg(cl, -cl, half, -cl)
			seg(-cl, cl, -cl, half)
			seg(-cl, cl, -half, cl)
			seg(cl, cl, cl, half)
			seg(cl, cl, half, cl)
		end
		for i = n + 1, 8 do
			L[i].Visible = false
		end
	end))
end

-- ----------------------------------------------------------------------------
-- VISUAL FX ADDONS (stretch / render distance / overlay / xray / shaders)
-- ----------------------------------------------------------------------------
function setStretchState(v)
	S.Vis.Stretch = v
	if v then
		loopStart("Stretch", function()
			local cam = Workspace.CurrentCamera
			if cam then
				pcall(function()
					local vs = cam.ViewportSize
					if vs.X > 1 and vs.Y > 1 then
						local realAspect = vs.X / vs.Y
						local virtAspect = math.max(0.1, S.Vis.StretchWidth / math.max(1, S.Vis.StretchHeight))
						-- Emulate the chosen virtual resolution: keep the same
						-- world, but scale the vertical FOV so the horizontal
						-- extent matches the selected width/height ratio (e.g.
						-- a 4:3 "stretch" zooms in and makes targets look
						-- bigger). Roblox doesn't let scripts change the real
						-- render resolution, so this is the closest match.
						cam.FieldOfView = math.clamp((S.Vis.Fov or 70) * (virtAspect / realAspect), 1, 120)
					end
				end)
			end
		end)
	else
		loopStop("Stretch")
		local cam = Workspace.CurrentCamera
		if cam then pcall(function() cam.FieldOfView = math.clamp(S.Vis.Fov or 70, 1, 120) end) end
	end
end

local renderOrig = nil
function setRenderDistState(v)
	S.Vis.RenderDist = v
	if v then
		if not renderOrig then pcall(function() renderOrig = { Start = Lighting.FogStart, End = Lighting.FogEnd } end) end
		loopStart("RenderDist", function()
			pcall(function()
				Lighting.FogStart = math.max(1, S.Vis.RenderDistValue * 0.8)
				Lighting.FogEnd = S.Vis.RenderDistValue
			end)
		end)
	else
		loopStop("RenderDist")
		if renderOrig then
			pcall(function()
				Lighting.FogStart = renderOrig.Start
				Lighting.FogEnd = renderOrig.End
			end)
			renderOrig = nil
		end
	end
end

function pingValue()
	local ok, v = pcall(function()
		return game:GetService("Stats").Network.ServerStats.Item["Data Ping"]:GetValue()
	end)
	if ok and v then return math.floor(v) end
	return 0
end

local speedGui, speedLabel, speedConn = nil, nil, nil
function setSpeedoState(v)
	if speedConn then pcall(function() speedConn:Disconnect() end); speedConn = nil end
	if speedGui then pcall(function() speedGui:Destroy() end); speedGui = nil end
	speedLabel = nil
	if not v then return end
	speedGui = Instance.new("ScreenGui")
	speedGui.Name = "MP_SPEEDO"
	speedGui.ResetOnSpawn = false
	speedGui.IgnoreGuiInset = true
	speedGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	speedLabel = Instance.new("TextLabel")
	speedLabel.BackgroundTransparency = 1
	speedLabel.Size = UDim2.new(0, 260, 0, 24)
	speedLabel.Position = UDim2.new(0.5, -130, 0, 12)
	speedLabel.TextColor3 = Color3.new(1, 1, 1)
	speedLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	speedLabel.TextStrokeTransparency = 0.3
	speedLabel.TextSize = 18
	speedLabel.Font = Enum.Font.GothamBold
	speedLabel.Text = "0 km/h"
	speedLabel.Parent = speedGui
	speedConn = addConn(RunService.RenderStepped:Connect(function()
		local root = getRoot()
		if not root then
			speedLabel.Text = "0 km/h"
			return
		end
		local sp = root.AssemblyLinearVelocity.Magnitude
		speedLabel.Text = math.floor(sp * 0.7 * 3.6) .. " km/h  |  " .. math.floor(sp) .. " studs/s"
	end))
end

local xrayConn = nil
-- Xray: every part in the workspace (except player characters) is made
-- transparent locally so you can see players through walls. Player parts
-- stay fully visible. Uses LocalTransparencyModifier so it never touches
-- the server, and restores originals when disabled.
local xrayParts = {}
local xrayOrig = {}
local xrayDescConn, xrayRemConn = nil, nil
function xrayIsPlayerPart(part)
	local m = part:FindFirstAncestorOfClass("Model")
	return m and Players:GetPlayerFromCharacter(m) ~= nil
end
function xrayApply(part)
	if not part or not part.Parent then xrayParts[part] = nil return end
	if xrayIsPlayerPart(part) then return end
	if xrayOrig[part] == nil then xrayOrig[part] = part.LocalTransparencyModifier end
	local trans = math.clamp(S.Vis.XrayTransparency, 0, 1)
	pcall(function() part.LocalTransparencyModifier = trans end)
end
function setXrayState(v)
	if xrayConn then pcall(function() xrayConn:Disconnect() end); xrayConn = nil end
	if xrayDescConn then pcall(function() xrayDescConn:Disconnect() end); xrayDescConn = nil end
	if xrayRemConn then pcall(function() xrayRemConn:Disconnect() end); xrayRemConn = nil end
	S.Vis.Xray = v
	if not v then
		for part in pairs(xrayParts) do
			local orig = xrayOrig[part]
			if part and part.Parent then pcall(function() part.LocalTransparencyModifier = orig or 0 end) end
		end
		xrayParts, xrayOrig = {}, {}
		return
	end
	for _, part in ipairs(Workspace:GetDescendants()) do
		if part:IsA("BasePart") and not xrayIsPlayerPart(part) then
			xrayParts[part] = true
			xrayApply(part)
		end
	end
	xrayDescConn = addConn(Workspace.DescendantAdded:Connect(function(part)
		if part:IsA("BasePart") then
			xrayParts[part] = true
			xrayApply(part)
		end
	end))
	xrayRemConn = addConn(Workspace.DescendantRemoving:Connect(function(part)
		if xrayParts[part] then xrayParts[part] = nil end
	end))
	xrayConn = addConn(RunService.RenderStepped:Connect(function()
		for part in pairs(xrayParts) do xrayApply(part) end
	end))
end

-- ----------------------------------------------------------------------------
-- COMBAT / MISC
-- ----------------------------------------------------------------------------
local hitboxOrig = {}
function hitboxTargetParts(m)
	local parts = {}
	local want = S.Aim.HitboxPart
	for _, part in ipairs(m:GetDescendants()) do
		if not part:IsA("BasePart") then continue end
		local n = part.Name
		local isHead = n == "Head"
		local isTorso = n:find("Torso") ~= nil or n == "HumanoidRootPart"
		local isArm = n:find("Arm") ~= nil or n:find("Hand") ~= nil
		local isLeg = n:find("Leg") ~= nil or n:find("Foot") ~= nil
		local match = (want == "All") or (want == "Head" and isHead) or (want == "Torso" and isTorso)
			or (want == "Arms" and isArm) or (want == "Legs" and isLeg)
		if match then parts[#parts + 1] = part end
	end
	return parts
end
function hitboxReset()
	for m, data in pairs(hitboxOrig) do
		for _, e in ipairs(data) do
			local part = e.part
			if part and part.Parent then
				pcall(function()
					part.Size = e.size
					part.Color = e.color
					part.LocalTransparencyModifier = e.trans
				end)
			end
		end
	end
	hitboxOrig = {}
end
function setHitboxState(v)
	if v then
		loopStart("Hitbox", function()
			for _, p in ipairs(Players:GetPlayers()) do
				if p == LocalPlayer then continue end
				local m = p.Character
				if not m or not m.Parent then continue end
				if not hitboxOrig[m] then
					local data = {}
					for _, part in ipairs(hitboxTargetParts(m)) do
						data[#data + 1] = { part = part, size = part.Size, color = part.Color, trans = part.LocalTransparencyModifier }
					end
					if #data > 0 then hitboxOrig[m] = data end
				end
				local data = hitboxOrig[m]
				if data then
					for _, e in ipairs(data) do
						local part = e.part
						if part and part.Parent then
							pcall(function()
								local hbScale = 1 + S.Aim.HitboxLevels * 0.1
								part.Size = e.size * math.max(1, hbScale)
								if S.Aim.HitboxColorOn then part.Color = S.Aim.HitboxColor end
								part.LocalTransparencyModifier = math.clamp(S.Aim.HitboxTransparency, 0, 1)
							end)
						end
					end
				end
			end
		end)
	else
		loopStop("Hitbox")
		hitboxReset()
	end
end

local afkConn = nil
local lastAfk = 0
function setAntiAfkState(v)
	if afkConn then pcall(function() afkConn:Disconnect() end); afkConn = nil end
	if not v then return end
	lastAfk = os.clock()
	afkConn = addConn(RunService.Heartbeat:Connect(function()
		if os.clock() - lastAfk >= 60 then
			lastAfk = os.clock()
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new(1, 1))
			end)
		end
	end))
end

local clickConn = nil
function setAutoClickerState(v)
	if clickConn then pcall(function() clickConn:Disconnect() end); clickConn = nil end
	if not v then return end
	clickConn = addConn(RunService.Heartbeat:Connect(function()
		pcall(function()
			VirtualInputManager:SendMouseButtonEvent(0, 0, Enum.UserInputType.MouseButton1, true, 1)
			VirtualInputManager:SendMouseButtonEvent(0, 0, Enum.UserInputType.MouseButton1, false, 1)
		end)
	end))
end

function serverHop()
	notify("Server Hop", "Finding a new server...", 3)
	task.spawn(function()
		local ok, err = pcall(function()
			local HttpService = game:GetService("HttpService")
			local TeleportService = game:GetService("TeleportService")
			local url = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?limit=100"
			local body = HttpService:GetAsync(url)
			local data = HttpService:JSONDecode(body)
			local candidates = {}
			for _, s in ipairs(data.data or {}) do
				if s.id ~= game.JobId and (s.playing or 0) < (s.maxPlayers or 0) then
					candidates[#candidates + 1] = s.id
				end
			end
			if #candidates == 0 then error("No open servers found") end
			TeleportService:TeleportToPlaceInstance(game.PlaceId, candidates[math.random(1, #candidates)])
		end)
		if not ok then notify("Server Hop", tostring(err), 4) end
	end)
end

function rejoinServer()
	if game.JobId and game.JobId ~= "" then
		pcall(function()
			game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId)
		end)
	else
		notify("Rejoin", "Job ID unavailable", 3)
	end
end

function refreshPlayerList()
	local names = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then names[#names + 1] = p.Name end
	end
	if #names == 0 then names = { "No players" } end
	local dd = UI["Pl_Target"]
	if dd then
		pcall(function()
			dd:SetValues(names)
			local cur = Options["Pl_Target"] and Options["Pl_Target"].Value or nil
			if not table.find(names, cur) then dd:SetValue(names[1]) end
		end)
	end
end

function tpToPlayer(name)
	if not name or name == "No players" then notify("TP", "No player selected", 2); return end
	local p = Players:FindFirstChild(name)
	local r = p and getPlayerRoot(p)
	local root = getRoot()
	if not root or not r then notify("TP", "Target or character not ready", 2); return end
	root.CFrame = r.CFrame + Vector3.new(0, 3, 0)
	root.AssemblyLinearVelocity = Vector3.zero
	notify("TP", "Teleported to " .. name, 2)
end

-- ----------------------------------------------------------------------------
-- ANIMATIONS (server-sided spoofer - any marketplace animation pack)
-- ----------------------------------------------------------------------------
local AnimSlots = { "Idle", "Walk", "Run", "Jump", "Fall", "Swim", "Climb" }
local animOrig = {}
function animFindSlot(animate, slot)
	local kw = string.lower(slot)
	for _, a in ipairs(animate:GetDescendants()) do
		if a:IsA("Animation") then
			local n = string.lower(a.Name)
			local pn = a.Parent and string.lower(a.Parent.Name) or ""
			if n:find(kw) or pn:find(kw) then return a end
		end
	end
	return nil
end
function animApply()
	local slot = (Options and Options["Anim_Slot"] and Options["Anim_Slot"].Value) or "Run"
	local raw = (Options and Options["Anim_Id"] and Options["Anim_Id"].Value) or ""
	local id = tostring(raw):match("(%d+)")
	if not id or id == "" then notify("Animations", "Enter an asset ID or rbxassetid://... URL", 3); return end
	local ch = getChar()
	if not ch then notify("Animations", "Character not ready", 2); return end
	local animate = ch:FindFirstChild("Animate")
	if not animate then notify("Animations", "No Animate script (custom rig?)", 3); return end
	local a = animFindSlot(animate, slot)
	if not a then notify("Animations", "Slot not found on this rig", 3); return end
	if not animOrig[slot] then animOrig[slot] = { Obj = a, Id = a.AnimationId } end

	local hum = ch:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	local newId = "rbxassetid://" .. id
	local oldId = a.AnimationId

	-- Stop whatever track is currently using this slot so the rig doesn't keep
	-- replaying the old (cached) animation after the ID swap.
	if animator then
		for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
			if t.Animation == a then pcall(function() t:Stop() end) end
		end
	end

	if animator then
		-- Validate the new asset actually loads. A bad/unplayable ID is the usual
		-- cause of the character freezing/going static (the Animate state machine
		-- errors out mid-transition), so we roll it back instead of leaving the
		-- rig stuck.
		local ok, track = pcall(function()
			a.AnimationId = newId
			local t = animator:LoadAnimation(a)
			return t
		end)
		if not ok then
			pcall(function() a.AnimationId = oldId end)
			notify("Animations", "Animation failed to load - invalid ID?", 3)
			return
		end
		if track then pcall(function() track:Stop() end) end
	else
		a.AnimationId = newId
	end

	notify("Animations", slot .. " -> " .. id .. ". Stop & re-run the action to see it.", 4)
end
function animResetSlot(slot)
	local e = animOrig[slot]
	if e and e.Obj and e.Obj.Parent then pcall(function() e.Obj.AnimationId = e.Id end) end
	animOrig[slot] = nil
	notify("Animations", "Reset " .. slot, 2)
end
function animResetAll()
	for slot in pairs(animOrig) do animResetSlot(slot) end
	notify("Animations", "Reset all slots", 2)
end

-- ----------------------------------------------------------------------------
-- UI
-- ----------------------------------------------------------------------------
local Window = Library:CreateWindow({ Title = "ABSOLUTE | v1.0", Center = true, AutoShow = true, Size = UDim2.fromOffset(600, 680) })

local TweenService = game:GetService("TweenService")
local PageElements = {}
local RestoreSize = Window.Holder.Size
local WindowChrome = nil
do
	-- The first Frame child of the Holder is LinoriaLib's "Inner" frame, which
	-- contains the title, the tab buttons and every tab's content. Hiding it on
	-- minimize hides the whole menu body (the custom chrome bar is a separate
	-- sibling that stays visible).
	WindowChrome = Window.Holder:FindFirstChildOfClass("Frame")
end
function addPageElement(tab)
	if tab then
		local el = tab.Container or tab.Element
		if el then PageElements[#PageElements + 1] = el end
	end
end

-- ----------------------------------------------------------------------------
-- CUSTOM CHROME (Matcha-style header bar)
-- ----------------------------------------------------------------------------
local Chrome = {
	Title = "ABSOLUTE",
	Version = "v1.0",
	BarHeight = 25,
}

do
	local ChromeOuter = Window.Holder
	local AbsPill = nil
	local ResizeGrip = nil

	local ChromeBar = Library:Create("Frame", {
		BackgroundColor3 = Library.BackgroundColor,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, Chrome.BarHeight),
		ZIndex = 5,
		Parent = ChromeOuter,
	})
	Library:AddToRegistry(ChromeBar, { BackgroundColor3 = "BackgroundColor" })

	local ChromeAccent = Library:Create("Frame", {
		BackgroundColor3 = Library.AccentColor,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(0, 3, 1, 0),
		ZIndex = 6,
		Parent = ChromeBar,
	})
	Library:AddToRegistry(ChromeAccent, { BackgroundColor3 = "AccentColor" })

	local ChromeLine = Library:Create("Frame", {
		BackgroundColor3 = Library.OutlineColor,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -1),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 6,
		Parent = ChromeBar,
	})
	Library:AddToRegistry(ChromeLine, { BackgroundColor3 = "OutlineColor" })

	local ChromeTitle = Library:CreateLabel({
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(0.55, 0, 1, 0),
		Text = Chrome.Title,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		ZIndex = 6,
		Parent = ChromeBar,
	})

	local ChromeChip = Library:Create("Frame", {
		BackgroundColor3 = Library.MainColor,
		BorderColor3 = Library.OutlineColor,
		Position = UDim2.new(1, -82, 0, 4),
		Size = UDim2.new(0, 40, 0, 17),
		ZIndex = 6,
		Parent = ChromeBar,
	})
	Library:AddToRegistry(ChromeChip, { BackgroundColor3 = "MainColor", BorderColor3 = "OutlineColor" })

	local ChromeChipLabel = Library:CreateLabel({
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		Text = Chrome.Version,
		TextSize = 11,
		ZIndex = 7,
		Parent = ChromeChip,
	})

	local ChromeClose = Library:Create("TextButton", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -25, 0, 0),
		Size = UDim2.new(0, 25, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = "\u{00D7}",
		TextColor3 = Library.FontColor,
		TextSize = 16,
		TextStrokeTransparency = 0,
		ZIndex = 6,
		Parent = ChromeBar,
	})
	Library:AddToRegistry(ChromeClose, { TextColor3 = "FontColor" })

	ChromeClose.MouseEnter:Connect(function()
		ChromeClose.BackgroundTransparency = 0
		ChromeClose.BackgroundColor3 = Library.RiskColor
		ChromeClose.TextColor3 = Color3.new(1, 1, 1)
	end)
	ChromeClose.MouseLeave:Connect(function()
		ChromeClose.BackgroundTransparency = 1
		ChromeClose.TextColor3 = Library.FontColor
	end)
	ChromeClose.MouseButton1Click:Connect(function()
		toggleUI()
	end)

	local ChromeMin = Library:Create("TextButton", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -50, 0, 0),
		Size = UDim2.new(0, 25, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = "\u{2013}",
		TextColor3 = Library.FontColor,
		TextSize = 16,
		TextStrokeTransparency = 0,
		ZIndex = 6,
		Parent = ChromeBar,
	})
	Library:AddToRegistry(ChromeMin, { TextColor3 = "FontColor" })
	ChromeMin.MouseEnter:Connect(function()
		ChromeMin.BackgroundTransparency = 0
		ChromeMin.BackgroundColor3 = Library.AccentColor
		ChromeMin.TextColor3 = Color3.new(1, 1, 1)
	end)
	ChromeMin.MouseLeave:Connect(function()
		ChromeMin.BackgroundTransparency = 1
		ChromeMin.TextColor3 = Library.FontColor
	end)

	AbsPill = Library:Create("TextButton", {
		BackgroundColor3 = Library.AccentColor,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 44, 0, 4),
		Size = UDim2.new(0, 44, 0, 17),
		Font = Enum.Font.GothamBold,
		Text = "ABS",
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 12,
		TextStrokeTransparency = 0,
		Visible = false,
		ZIndex = 8,
		Parent = ChromeBar,
	})
	Library:AddToRegistry(AbsPill, { BackgroundColor3 = "AccentColor" })

	local Minimized = false
	local ElStates = {}
	local function releaseMouseForPlay()
		-- When the menu is minimized the mouse must go back to the game so the
		-- camera can rotate (first person especially). Only force it if the menu
		-- was holding it in "cursor" mode.
		pcall(function()
			if UserInputService.MouseBehavior == Enum.MouseBehavior.Default then
				UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			end
		end)
	end
	local function grabMouseForGui()
		pcall(function()
			if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
				UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			end
		end)
	end
	local function setMinimized(state)
		if Minimized == state then return end
		Minimized = state
		if state then
			RestoreSize = Window.Holder.Size
			ElStates = {}
			for i, el in ipairs(PageElements) do
				ElStates[i] = el.Visible
				el.Visible = false
			end
			if WindowChrome then WindowChrome.Visible = false end
			TweenService:Create(Window.Holder, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(150, 26) }):Play()
			ChromeChip.Visible = false
			ChromeTitle.Visible = false
			AbsPill.Visible = true
			ResizeGrip.Visible = false
			releaseMouseForPlay()
		else
			AbsPill.Visible = false
			ChromeTitle.Visible = true
			ChromeChip.Visible = true
			for i, el in ipairs(PageElements) do el.Visible = ElStates[i] or false end
			if WindowChrome then WindowChrome.Visible = true end
			TweenService:Create(Window.Holder, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = RestoreSize }):Play()
			ResizeGrip.Visible = true
			grabMouseForGui()
		end
	end
	ChromeMin.MouseButton1Click:Connect(function()
		setMinimized(not Minimized)
	end)
	AbsPill.MouseButton1Click:Connect(function()
		setMinimized(false)
	end)
	-- Let the UI toggle key restore the full menu if it was only minimized.
	getgenv().absRestoreIfMinimized = function()
		if Minimized then setMinimized(false); return true end
		return false
	end

	ResizeGrip = Library:Create("TextButton", {
		BackgroundTransparency = 1,
		BackgroundColor3 = Library.MainColor,
		BorderColor3 = Library.OutlineColor,
		Position = UDim2.new(1, -14, 1, -14),
		Size = UDim2.new(0, 14, 0, 14),
		Font = Enum.Font.GothamBold,
		Text = "\u{2198}",
		TextColor3 = Library.FontColor,
		TextSize = 10,
		ZIndex = 5,
		Parent = Window.Holder,
	})
	Library:AddToRegistry(ResizeGrip, { BackgroundColor3 = "MainColor", BorderColor3 = "OutlineColor", TextColor3 = "FontColor" })

	local resizing = false
	local startMouse, startSize = nil, nil
	ResizeGrip.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing = true
			startMouse = UserInputService:GetMouseLocation()
			startSize = Window.Holder.Size
		end
	end)
	addConn(UserInputService.InputChanged:Connect(function(inp)
		if resizing and inp.UserInputType == Enum.UserInputType.MouseMovement then
			local m = UserInputService:GetMouseLocation()
			local w = math.max(360, startSize.X.Offset + (m.X - startMouse.X))
			local h = math.max(220, startSize.Y.Offset + (m.Y - startMouse.Y))
			Window.Holder.Size = UDim2.fromOffset(w, h)
		end
	end))
	addConn(UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then resizing = false end
	end))
end

-- Keep the window on screen: clamp its position every frame so it can never be
-- dragged (partially or fully) off the viewport.
addConn(RunService.RenderStepped:Connect(function()
	local h = Window.Holder
	local cam = Workspace.CurrentCamera
	if not h or not cam or not h.Visible then return end
	local pos = h.AbsolutePosition
	local size = h.AbsoluteSize
	local vp = cam.ViewportSize
	local cx = math.clamp(pos.X, 0, math.max(0, vp.X - size.X))
	local cy = math.clamp(pos.Y, 0, math.max(0, vp.Y - size.Y))
	if cx ~= pos.X or cy ~= pos.Y then
		local p = h.Position
		h.Position = UDim2.new(p.X.Scale, p.X.Offset + (cx - pos.X), p.Y.Scale, p.Y.Offset + (cy - pos.Y))
	end
end))

local AimTab = Window:AddTab("Aim")
addPageElement(AimTab)
local AimL = AimTab:AddLeftGroupbox("Aimbot")
local AimR = AimTab:AddRightGroupbox("Combat")

local aimTog = AimL:AddToggle("Aim_Enabled", { Text = "Aimbot", Default = false, Callback = function(v) S.Aim.Enabled = v end })
AimL:AddDropdown("Aim_HoldKey", { Text = "Hold-To-Aim Key", Values = { "LeftAlt", "MB2", "X", "F", "Q", "E", "V", "C", "Z" }, Default = 1, Multi = false, Callback = function(v) S.Aim.HoldKey = v end })
startAimLoop()
AimL:AddSlider("Aim_Fov", { Text = "FOV (degrees)", Min = 5, Max = 180, Default = 90, Rounding = 0, Callback = function(v) S.Aim.Fov = v end })
AimL:AddSlider("Aim_Smooth", { Text = "Smoothness (0 = snap)", Min = 0, Max = 20, Default = 8, Rounding = 1, Callback = function(v) S.Aim.Smoothness = v end })
AimL:AddDropdown("Aim_Part", { Text = "Target Part", Values = { "Head", "HumanoidRootPart", "UpperTorso" }, Default = 1, Multi = false, Callback = function(v) S.Aim.TargetPart = v end })
AimL:AddSlider("Aim_Dist", { Text = "Max Distance", Min = 10, Max = 1000, Default = 400, Rounding = 0, Suffix = " studs", Callback = function(v) S.Aim.MaxDist = v end })
AimL:AddSlider("Aim_Predict", { Text = "Prediction", Min = 0, Max = 0.5, Default = 0.1, Rounding = 3, Suffix = "s", Callback = function(v) S.Aim.Prediction = v end })
AimL:AddDropdown("Aim_PredictMode", { Text = "Prediction Mode", Values = { "Velocity", "Advanced", "Trajectory" }, Default = 1, Multi = false, Callback = function(v) S.Aim.PredictMode = v end })
AimL:AddToggle("Aim_FovCircle", { Text = "Show FOV Circle", Default = true, Callback = function(v) S.Aim.FovCircle = v end })
AimL:AddToggle("Aim_Visible", { Text = "Visibility Check", Default = false, Callback = function(v) S.Aim.VisibleCheck = v end })
AimL:AddToggle("Aim_Team", { Text = "Ignore Team", Default = false, Callback = function(v) S.Aim.TeamCheck = v end })
AimL:AddToggle("Aim_AutoAttack", { Text = "Auto Attack While Locked", Default = false, Callback = function(v) S.Aim.AutoAttack = v end })
AimR:AddToggle("Aim_Hitbox", { Text = "Hitbox Expander", Default = false, Callback = function(v) setHitboxState(v) end })
AimR:AddDropdown("Aim_HitboxPart", { Text = "Expand Parts", Values = { "All", "Head", "Torso", "Arms", "Legs" }, Default = 1, Multi = false, Callback = function(v) S.Aim.HitboxPart = v end })
AimR:AddSlider("Aim_HitboxLevels", { Text = "Expansion Level", Min = 1, Max = 10, Default = S.Aim.HitboxLevels, Rounding = 0, Suffix = "", Callback = function(v) S.Aim.HitboxLevels = v end })
AimR:AddToggle("Aim_HitboxColorOn", { Text = "Hitbox Color", Default = false, Callback = function(v) S.Aim.HitboxColorOn = v end })
AimR:AddLabel("Hitbox Color"):AddColorPicker("Aim_HitboxColor", { Default = S.Aim.HitboxColor, Title = "Hitbox Color", Callback = function(v) S.Aim.HitboxColor = v end })
AimR:AddSlider("Aim_HitboxTransparency", { Text = "Hitbox Transparency", Min = 0, Max = 1, Default = S.Aim.HitboxTransparency, Rounding = 2, Callback = function(v) S.Aim.HitboxTransparency = v end })
AimR:AddDivider()
AimR:AddLabel("Silent Aim", true)
AimR:AddToggle("Aim_Silent", { Text = "Silent Aim", Default = false, Callback = function(v) S.Aim.SilentEnabled = v end })
AimR:AddSlider("Aim_SilentFov", { Text = "Silent FOV", Min = 5, Max = 120, Default = S.Aim.SilentFov, Rounding = 0, Callback = function(v) S.Aim.SilentFov = v end })
AimR:AddSlider("Aim_SilentPredict", { Text = "Silent Prediction", Min = 0, Max = 0.5, Default = S.Aim.SilentPrediction, Rounding = 3, Suffix = "s", Callback = function(v) S.Aim.SilentPrediction = v end })
AimR:AddToggle("Aim_SilentVisible", { Text = "Silent Visibility Check", Default = false, Callback = function(v) S.Aim.SilentVisible = v end })
AimR:AddDropdown("Aim_SilentKey", { Text = "Silent Key", Values = { "MB1", "MB2", "Q", "E", "X", "F", "V", "C", "Z" }, Default = 1, Multi = false, Callback = function(v) S.Aim.SilentKey = v end })
startSilentLoop()
AimR:AddDivider()
AimR:AddLabel("Click the Aimbot toggle for always-on, or hold the selected Hold-To-Aim key for temporary aim.", true)

local EspTab = Window:AddTab("ESP")
addPageElement(EspTab)
local EspL = EspTab:AddLeftGroupbox("Players")
local EspR = EspTab:AddRightGroupbox("Style")

EspL:AddToggle("Esp_Enabled", { Text = "Player ESP", Default = false, Callback = function(v) setEspState(v) end })
EspL:AddToggle("Esp_Boxes", { Text = "Boxes", Default = true, Callback = function(v) S.Esp.Boxes = v end })
EspL:AddToggle("Esp_Lines", { Text = "Tracers", Default = false, Callback = function(v) S.Esp.Lines = v end })
EspL:AddToggle("Esp_Names", { Text = "Names", Default = true, Callback = function(v) S.Esp.Names = v end })
EspL:AddToggle("Esp_Health", { Text = "Health Bar", Default = true, Callback = function(v) S.Esp.Health = v end })
EspL:AddToggle("Esp_Distance", { Text = "Distance", Default = true, Callback = function(v) S.Esp.Distance = v end })
EspL:AddToggle("Esp_Chams", { Text = "Chams (through walls)", Default = false, Callback = function(v) S.Esp.Chams = v end })
EspL:AddToggle("Esp_TeamColor", { Text = "Team Colors", Default = false, Callback = function(v) S.Esp.TeamColor = v end })
EspL:AddToggle("Esp_Skeleton", { Text = "Skeleton", Default = false, Callback = function(v) S.Esp.Skeleton = v end })
EspL:AddSlider("Esp_MaxDist", { Text = "Max Distance", Min = 50, Max = 3000, Default = 1000, Rounding = 0, Callback = function(v) S.Esp.MaxDist = v end })
EspL:AddDivider()
EspL:AddToggle("Esp_Preview", { Text = "Preview", Default = false, Callback = function(v) setEspPreviewState(v) end })
EspL:AddLabel("Swing a camera around yourself showing exactly what the ESP looks like on real players. Move the mouse to rotate.", true)
EspL:AddButton("Apply ESP Settings", espApply)

EspR:AddToggle("Esp_Rainbow", { Text = "Rainbow", Default = false, Callback = function(v) S.Esp.Rainbow = v end })
EspR:AddDivider()
EspR:AddLabel("Box", true)
EspR:AddDropdown("Esp_BoxMode", { Text = "Box Mode", Values = { "2D", "3D" }, Default = 1, Multi = false, Callback = function(v) S.Esp.BoxMode = v end })
EspR:AddDropdown("Esp_BoxType", { Text = "Box Type", Values = { "Full", "Corner" }, Default = 1, Multi = false, Callback = function(v) S.Esp.BoxType = v end })
EspR:AddSlider("Esp_BoxThickness", { Text = "Box Thickness", Min = 1, Max = 5, Default = 1, Rounding = 0, Callback = function(v) S.Esp.BoxThickness = v end })
EspR:AddLabel("Box Color"):AddColorPicker("Esp_BoxColor", { Default = S.Esp.BoxColor, Title = "Box Color", Callback = function(v) S.Esp.BoxColor = v end })
EspR:AddDivider()
EspR:AddLabel("Tracers", true)
EspR:AddDropdown("Esp_LineMode", { Text = "Tracer Mode", Values = { "2D" }, Default = 1, Multi = false, Callback = function(v) S.Esp.LineMode = v end })
EspR:AddDropdown("Esp_LineStyle", { Text = "Tracer Style", Values = { "Solid", "Dotted", "Dashed" }, Default = 1, Multi = false, Callback = function(v) S.Esp.LineStyle = v end })
EspR:AddDropdown("Esp_TracerOrigin", { Text = "Tracer Origin", Values = { "Bottom", "Top", "Center", "Mouse" }, Default = 1, Multi = false, Callback = function(v) S.Esp.TracerOrigin = v end })
EspR:AddSlider("Esp_LineThickness", { Text = "Tracer Thickness", Min = 1, Max = 5, Default = 1, Rounding = 0, Callback = function(v) S.Esp.LineThickness = v end })
EspR:AddSlider("Esp_LineTransparency", { Text = "Tracer Transparency", Min = 0, Max = 1, Default = 0, Rounding = 2, Callback = function(v) S.Esp.LineTransparency = v end })
EspR:AddLabel("Tracer Color"):AddColorPicker("Esp_LineColor", { Default = S.Esp.LineColor, Title = "Tracer Color", Callback = function(v) S.Esp.LineColor = v end })
EspR:AddDivider()
EspR:AddLabel("Name", true)
EspR:AddDropdown("Esp_NameMode", { Text = "Name Mode", Values = { "Display", "Username" }, Default = 1, Multi = false, Callback = function(v) S.Esp.NameMode = v end })
EspR:AddDropdown("Esp_NamePos", { Text = "Name Position", Values = { "Top", "Bottom" }, Default = 1, Multi = false, Callback = function(v) S.Esp.NamePos = v end })
EspR:AddSlider("Esp_NameSize", { Text = "Name Size", Min = 8, Max = 28, Default = 14, Rounding = 0, Callback = function(v) S.Esp.NameSize = v end })
EspR:AddSlider("Esp_NameOffset", { Text = "Name Offset", Min = -40, Max = 40, Default = 0, Rounding = 0, Callback = function(v) S.Esp.NameOffset = v end })
EspR:AddLabel("Name Color"):AddColorPicker("Esp_NameColor", { Default = S.Esp.NameColor, Title = "Name Color", Callback = function(v) S.Esp.NameColor = v end })
EspR:AddDivider()
EspR:AddLabel("Health", true)
EspR:AddDropdown("Esp_HealthMode", { Text = "Health Mode", Values = { "Bar", "Text", "Both" }, Default = 1, Multi = false, Callback = function(v) S.Esp.HealthMode = v end })
EspR:AddDropdown("Esp_HealthPos", { Text = "Health Position", Values = { "Top", "Bottom", "Left", "Right" }, Default = 1, Multi = false, Callback = function(v) S.Esp.HealthPos = v end })
EspR:AddDropdown("Esp_HealthText", { Text = "Health Text", Values = { "Num", "Percent" }, Default = 1, Multi = false, Callback = function(v) S.Esp.HealthText = v end })
EspR:AddToggle("Esp_HealthGradient", { Text = "Health Gradient", Default = true, Callback = function(v) S.Esp.HealthGradient = v end })
EspR:AddSlider("Esp_HealthSize", { Text = "Health Size", Min = 1, Max = 6, Default = 3, Rounding = 0, Callback = function(v) S.Esp.HealthSize = v end })
EspR:AddLabel("Health Color"):AddColorPicker("Esp_HealthColor", { Default = S.Esp.HealthColor, Title = "Health Color", Callback = function(v) S.Esp.HealthColor = v end })
EspR:AddDivider()
EspR:AddLabel("Distance", true)
EspR:AddDropdown("Esp_DistanceUnits", { Text = "Distance Units", Values = { "Studs", "Meters" }, Default = 1, Multi = false, Callback = function(v) S.Esp.DistanceUnits = v end })
EspR:AddDivider()
EspR:AddLabel("Chams", true)
EspR:AddToggle("Esp_ChamThermal", { Text = "Thermal Mode", Default = false, Callback = function(v) S.Esp.ChamThermal = v end })
EspR:AddToggle("Esp_ChamGradient", { Text = "Cham Gradient", Default = true, Callback = function(v) S.Esp.ChamGradient = v end })
EspR:AddSlider("Esp_ChamTransparency", { Text = "Cham Transparency", Min = 0, Max = 1, Default = 0.55, Rounding = 2, Callback = function(v) S.Esp.ChamTransparency = v end })
EspR:AddSlider("Esp_ChamOutline", { Text = "Cham Outline", Min = 0, Max = 1, Default = 0.2, Rounding = 2, Callback = function(v) S.Esp.ChamOutline = v end })
EspR:AddLabel("Cham Color"):AddColorPicker("Esp_ChamColor", { Default = S.Esp.ChamColor, Title = "Cham Color", Callback = function(v) S.Esp.ChamColor = v end })
EspR:AddDivider()
EspR:AddLabel("Team Colors", true)
EspR:AddLabel("Team 1 Color"):AddColorPicker("Esp_Team1Color", { Default = S.Esp.Team1Color, Title = "Team 1 Color", Callback = function(v) S.Esp.Team1Color = v end })
EspR:AddLabel("Team 2 Color"):AddColorPicker("Esp_Team2Color", { Default = S.Esp.Team2Color, Title = "Team 2 Color", Callback = function(v) S.Esp.Team2Color = v end })
EspR:AddDivider()
EspR:AddLabel("Skeleton", true)
EspR:AddSlider("Esp_SkelThickness", { Text = "Skeleton Thickness", Min = 1, Max = 5, Default = 1, Rounding = 0, Callback = function(v) S.Esp.SkelThickness = v end })
EspR:AddSlider("Esp_SkelTransparency", { Text = "Skeleton Transparency", Min = 0, Max = 1, Default = 0, Rounding = 2, Callback = function(v) S.Esp.SkelTransparency = v end })
EspR:AddLabel("Skeleton Color"):AddColorPicker("Esp_SkelColor", { Default = S.Esp.SkelColor, Title = "Skeleton Color", Callback = function(v) S.Esp.SkelColor = v end })
EspR:AddDivider()
EspR:AddLabel("Rendered with the Drawing API for an external look. Falls back to nothing if the executor lacks Drawing. Preview shows the style on yourself before applying.", true)

local PlTab = Window:AddTab("Players")
addPageElement(PlTab)
local PlL = PlTab:AddLeftGroupbox("Visibility")
local PlR = PlTab:AddRightGroupbox("Spectate / Fling")

PlL:AddToggle("Pl_HidePlayers", { Text = "Hide All Players", Default = false, Callback = function(v) setHidePlayersState(v) end })
PlL:AddLabel("Makes every other player invisible to you. They can still hit you.", true)
PlL:AddDivider()
PlL:AddLabel("Target", true)
UI["Pl_Target"] = PlL:AddDropdown("Pl_Target", { Text = "Target Player", Values = { "No players" }, Default = 1, Multi = false })
PlL:AddLabel("One target for everything: aim, silent aim, spectate, fling, bring, freeze, teleport and copy name.", true)
PlL:AddButton("Teleport To Player", function() tpToPlayer(Options["Pl_Target"].Value) end)
PlL:AddToggle("Pl_Bring", { Text = "Bring Target To You", Default = false, Callback = function(v) setBringState(v) end })
PlL:AddToggle("Pl_BringAll", { Text = "Bring All Players To You", Default = false, Callback = function(v) setBringAllState(v) end })
PlL:AddToggle("Pl_Freeze", { Text = "Freeze Target", Default = false, Callback = function(v) setFreezeState(v) end })
PlL:AddButton("Copy Player Name", function() copyPlayerName(Options["Pl_Target"].Value) end)
PlL:AddLabel("Bring anchors the target in front of you and re-teleports every frame; OFF restores their position.", true)

PlR:AddToggle("Pl_Spectate", { Text = "Spectate", Default = false, Callback = function(v) specApply(v) end })
PlR:AddDivider()
PlR:AddToggle("Pl_Fling", { Text = "Fling Target", Default = false, Callback = function(v) setFlingState(v) end })
PlR:AddToggle("Pl_FlingTouch", { Text = "Fling On Collision", Default = false, Callback = function(v) setFlingTouchState(v) end })
PlR:AddLabel("Fling on collision flings any player that gets within ~6 studs of you.", true)
PlR:AddLabel("Fling overlaps the target and slams velocity into them while you stay anchored, so only they get flung. Game dependent.", true)

local MoveTab = Window:AddTab("Movement")
addPageElement(MoveTab)
local MoveL = MoveTab:AddLeftGroupbox("Move")
local MoveR = MoveTab:AddRightGroupbox("Flight / Teleport")

MoveL:AddToggle("Move_Speed", { Text = "Walk Speed", Default = false, Callback = function(v) setSpeedState(v) end })
MoveL:AddSlider("Move_SpeedVal", { Text = "Speed", Min = 16, Max = 500, Default = 16, Rounding = 0, Callback = function(v) S.Move.WalkSpeed = v end })
MoveL:AddToggle("Move_Jump", { Text = "Jump Power", Default = false, Callback = function(v) setJumpState(v) end })
MoveL:AddSlider("Move_JumpVal", { Text = "Jump Power", Min = 0, Max = 300, Default = 50, Rounding = 0, Callback = function(v) S.Move.JumpPower = v end })
MoveL:AddToggle("Move_InfJump", { Text = "Infinite Jump", Default = false, Callback = function(v) setInfJumpState(v) end })
MoveL:AddToggle("Move_Bhop", { Text = "Bhop (speed boost)", Default = false, Callback = function(v) setBhopState(v) end })
MoveL:AddToggle("Move_AutoJump", { Text = "Auto Jump", Default = false, Callback = function(v) setAutoJumpState(v) end })
MoveL:AddToggle("Move_Noclip", { Text = "Noclip", Default = false, Callback = function(v) setNoclipState(v) end })
MoveL:AddToggle("Move_NoFall", { Text = "No Fall Damage", Default = false, Callback = function(v) setNoFallState(v) end })
MoveL:AddToggle("Move_Float", { Text = "Float", Default = false, Callback = function(v) setFloatState(v) end })
MoveL:AddToggle("Move_WaterWalk", { Text = "Water Walk", Default = false, Callback = function(v) setWaterWalkState(v) end })
MoveL:AddToggle("Move_Spin", { Text = "Spin", Default = false, Callback = function(v) setSpinState(v) end })
MoveL:AddSlider("Move_SpinSpeed", { Text = "Spin Speed", Min = 1, Max = 30, Default = 5, Rounding = 1, Callback = function(v) S.Move.SpinSpeed = v end })
MoveL:AddToggle("Move_HipHeight", { Text = "Hip Height", Default = false, Callback = function(v) setHipHeightState(v) end })
MoveL:AddSlider("Move_HipVal", { Text = "Hip Height", Min = 0, Max = 20, Default = 2, Rounding = 1, Callback = function(v) S.Move.HipHeight = v end })
MoveL:AddToggle("Move_AntiVoid", { Text = "Anti Void", Default = false, Callback = function(v) setAntiVoidState(v) end })
MoveL:AddSlider("Move_VoidLevel", { Text = "Void Level (Y)", Min = -500, Max = 0, Default = -100, Rounding = 0, Callback = function(v) S.Move.VoidLevel = v end })

MoveR:AddToggle("Move_Fly", { Text = "Fly", Default = false, Callback = function(v) setFlyState(v) end })
MoveR:AddSlider("Move_FlySpeed", { Text = "Fly Speed", Min = 10, Max = 300, Default = 50, Rounding = 0, Callback = function(v) S.Move.FlySpeed = v end })
MoveR:AddDivider()
MoveR:AddLabel("WASD = Move | Space = Up | Ctrl = Down", true)
MoveR:AddDivider()
MoveR:AddLabel("Click Teleport", true)
MoveR:AddToggle("Move_ClickTp", { Text = "Click TP", Default = false, Callback = function(v) S.Move.ClickTpEnabled = v end })
MoveR:AddDropdown("Move_ClickTpKey", { Text = "Key", Values = { "T", "G", "F", "MB2", "X", "V", "Z" }, Default = 1, Multi = false, Callback = function(v) S.Move.ClickTpKey = v end })
MoveR:AddDivider()
MoveR:AddLabel("Waypoints", true)
MoveR:AddToggle("Move_WpMarkers", { Text = "Waypoint Markers", Default = false, Callback = function(v) setWpMarkersState(v) end })
MoveR:AddButton("Add Waypoint", wpAdd)
MoveR:AddButton("Clear Waypoints", wpClear)
UI.WpSelect = MoveR:AddDropdown("Move_WpSelect", { Text = "Waypoint", Values = { "None" }, Default = 1, Multi = false })
MoveR:AddButton("Teleport To Waypoint", wpTp)
MoveR:AddDivider()
MoveR:AddToggle("Move_Desync", { Text = "Desync (experimental)", Default = false, Callback = function(v) setDesyncState(v) end })
MoveR:AddLabel("Server-sided desync via network owner release. Can fail or lag on some games.", true)

local VisTab = Window:AddTab("Visuals")
addPageElement(VisTab)
local VisL = VisTab:AddLeftGroupbox("Lighting")
local VisR = VisTab:AddRightGroupbox("Camera / HUD")

VisL:AddToggle("Vis_Fullbright", { Text = "Full Bright", Default = false, Callback = function(v) setFullBrightState(v) end })
VisL:AddToggle("Vis_NightVision", { Text = "Night Vision", Default = false, Callback = function(v) setNightVisionState(v) end })
VisL:AddToggle("Vis_NoFog", { Text = "No Fog", Default = false, Callback = function(v) setNoFogState(v) end })
VisL:AddToggle("Vis_FpsBoost", { Text = "FPS Boost", Default = false, Callback = function(v) setFpsBoostState(v) end })
VisL:AddDivider()
VisL:AddLabel("World FX", true)
VisL:AddToggle("Vis_Stretch", { Text = "Stretched Resolution", Default = false, Callback = function(v) setStretchState(v) end })
VisL:AddSlider("Vis_StretchWidth", { Text = "Resolution Width", Min = 800, Max = 4000, Default = 1920, Rounding = 0, Callback = function(v) S.Vis.StretchWidth = v end })
VisL:AddSlider("Vis_StretchHeight", { Text = "Resolution Height", Min = 500, Max = 2000, Default = 1080, Rounding = 0, Callback = function(v) S.Vis.StretchHeight = v end })
VisL:AddLabel("Emulates the selected resolution via FOV (Roblox can't change real render resolution).", true)
VisL:AddToggle("Vis_RenderDist", { Text = "Render Distance", Default = false, Callback = function(v) setRenderDistState(v) end })
VisL:AddSlider("Vis_RenderDistVal", { Text = "Distance", Min = 250, Max = 10000, Default = 2000, Rounding = 0, Callback = function(v) S.Vis.RenderDistValue = v end })
VisL:AddToggle("Vis_Xray", { Text = "Xray", Default = false, Callback = function(v) setXrayState(v) end })
VisL:AddSlider("Vis_XrayTrans", { Text = "Xray Transparency", Min = 0, Max = 1, Default = 0.5, Rounding = 2, Callback = function(v) S.Vis.XrayTransparency = v end })
VisL:AddLabel("Makes every part in the game transparent except for players.", true)

VisR:AddToggle("Vis_Fov", { Text = "FOV Changer", Default = false, Callback = function(v) setFovState(v) end })
VisR:AddSlider("Vis_FovVal", { Text = "Field of View", Min = 20, Max = 120, Default = 70, Rounding = 0, Callback = function(v) S.Vis.Fov = v end })
VisR:AddToggle("Vis_Freecam", { Text = "Freecam", Default = false, Callback = function(v) setFreecamState(v) end })
VisR:AddSlider("Vis_FreecamSpeed", { Text = "Freecam Speed", Min = 5, Max = 200, Default = 30, Rounding = 0, Callback = function(v) S.Vis.FreecamSpeed = v end })
VisR:AddToggle("Vis_Hud", { Text = "HUD (FPS / Ping / MPH)", Default = false, Callback = function(v) setHudState(v) end })
VisR:AddToggle("Vis_Speedo", { Text = "Speedometer", Default = false, Callback = function(v) setSpeedoState(v) end })
VisR:AddDivider()
VisR:AddLabel("Third Person", true)
VisR:AddToggle("Vis_ThirdPerson", { Text = "Third Person", Default = false, Callback = function(v) setThirdPersonState(v) end })
VisR:AddSlider("Vis_ThirdDist", { Text = "Camera Distance", Min = 3, Max = 30, Default = 10, Rounding = 1, Callback = function(v) S.Vis.ThirdDist = v end })
VisR:AddDivider()
VisR:AddLabel("Crosshair", true)
VisR:AddToggle("Vis_Crosshair", { Text = "Crosshair", Default = false, Callback = function(v) setCrosshairState(v) end })
VisR:AddDropdown("Vis_XhStyle", { Text = "Style", Values = { "Cross", "Plus", "Dot", "Circle", "T", "Corners", "None" }, Default = 1, Multi = false, Callback = function(v) S.Vis.XhStyle = v end })
VisR:AddSlider("Vis_XhSize", { Text = "Size", Min = 4, Max = 30, Default = 12, Rounding = 0, Callback = function(v) S.Vis.XhSize = v end })
VisR:AddSlider("Vis_XhGap", { Text = "Gap", Min = 0, Max = 20, Default = 4, Rounding = 0, Callback = function(v) S.Vis.XhGap = v end })
VisR:AddToggle("Vis_XhRainbow", { Text = "Rainbow", Default = false, Callback = function(v) S.Vis.XhRainbow = v end })
VisR:AddLabel("Crosshair Color"):AddColorPicker("Vis_XhColor", { Default = S.Vis.XhColor, Title = "Crosshair Color" })

local AnimTab = Window:AddTab("Animations")
addPageElement(AnimTab)
local AnimL = AnimTab:AddLeftGroupbox("Animation Spoofer")
local AnimR = AnimTab:AddRightGroupbox("Tools")

UI.Anim_Slot = AnimL:AddDropdown("Anim_Slot", { Text = "Slot", Values = AnimSlots, Default = 3, Multi = false })
AnimL:AddInput("Anim_Id", { Text = "Animation ID", Placeholder = "rbxassetid:// or numeric ID", Numeric = false, Callback = function(text) end })
AnimL:AddButton("Apply To Slot", animApply)
AnimL:AddLabel("Type any animation ID (marketplace packs, custom, etc.) and it replaces the chosen slot in your rig's Animate script. After applying, stop then re-run the action (e.g. run again) for it to show immediately.", true)
AnimR:AddButton("Reset Slot", function()
	local slot = (Options and Options["Anim_Slot"] and Options["Anim_Slot"].Value) or "Run"
	animResetSlot(slot)
end)
AnimR:AddButton("Reset All", animResetAll)
AnimR:AddLabel("Works for R6/R15 and most custom rigs. Re-join if a slot gets corrupted.", true)

local MiscTab = Window:AddTab("Misc")
addPageElement(MiscTab)
local MiscL = MiscTab:AddLeftGroupbox("Utility")
local MiscR = MiscTab:AddRightGroupbox("Cheats / Info")

MiscL:AddToggle("Misc_AntiAfk", { Text = "Anti-AFK", Default = false, Callback = function(v) setAntiAfkState(v) end })
MiscL:AddToggle("Misc_AutoClicker", { Text = "Auto Clicker", Default = false, Callback = function(v) setAutoClickerState(v) end })
MiscL:AddDivider()
MiscL:AddButton("Load Infinite Yield", function()
	local ok = loadInfiniteYield()
	notify("Infinite Yield", ok and "Loaded." or "Failed - check console.", 3)
end)
MiscL:AddDivider()
MiscL:AddButton("Reset Character", function()
	local ch = getChar()
	if ch then pcall(function() ch.Humanoid.Health = 0 end) end
end)
MiscR:AddLabel("Server anticheat can still detect movement/aim changes. This is visible only to you; it does not bypass Roblox moderation.", true)
MiscR:AddDivider()
MiscR:AddButton("Server Hop", serverHop)
MiscR:AddButton("Rejoin Server", rejoinServer)
MiscR:AddLabel("Server hop moves you to a random open public server. Rejoin returns you to this one.", true)

-- ===== Shared console (output log) =====
-- Built first so both the Executor and Console tabs can write to it.
local ConsoleFrame = Instance.new("ScrollingFrame")
ConsoleFrame.Name = "ConsoleFrame"
ConsoleFrame.Size = UDim2.new(1, -8, 0, 240)
ConsoleFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
ConsoleFrame.BorderColor3 = Color3.fromRGB(66, 66, 66)
ConsoleFrame.BorderSizePixel = 1
ConsoleFrame.ScrollBarThickness = 6
ConsoleFrame.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 90)

local ConsoleText = Instance.new("TextLabel")
ConsoleText.Name = "ConsoleText"
ConsoleText.BackgroundTransparency = 1
ConsoleText.Size = UDim2.new(1, -12, 0, 24)
ConsoleText.Position = UDim2.new(0, 6, 0, 4)
ConsoleText.TextXAlignment = Enum.TextXAlignment.Left
ConsoleText.TextYAlignment = Enum.TextYAlignment.Top
ConsoleText.Font = Enum.Font.Code
ConsoleText.TextSize = 13
ConsoleText.TextColor3 = Color3.fromRGB(255, 255, 255)
ConsoleText.TextWrapped = true
ConsoleText.RichText = true
ConsoleText.Text = ""

local execTextService = game:GetService("TextService")
local consoleBuf = ""

local function consoleEsc(s)
	return tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
end

local function consoleMeasure()
	if ConsoleText.AbsoluteSize.X < 2 then return end
	local size = execTextService:GetTextSize(ConsoleText.Text, 13, Enum.Font.Code, Vector2.new(ConsoleText.AbsoluteSize.X, math.huge))
	ConsoleText.Size = UDim2.new(1, -12, 0, size.Y + 8)
	ConsoleFrame.CanvasSize = UDim2.new(0, 0, 0, size.Y + 12)
	ConsoleFrame.CanvasPosition = Vector2.new(0, size.Y + 12)
end

-- white = print, orange = warn, red = error
local function consoleWrite(text, color)
	local line
	if color then
		line = "<font color='#" .. color .. "'>" .. consoleEsc(text) .. "</font>"
	else
		line = consoleEsc(text)
	end
	consoleBuf = consoleBuf .. line .. "\n"
	if #consoleBuf > 80000 then
		consoleBuf = consoleBuf:sub(#consoleBuf - 80000)
	end
	ConsoleText.Text = consoleBuf
	task.defer(consoleMeasure)
end

-- Mirror print/warn of executed scripts into the console. The originals are
-- chained so the executor's own output window keeps working too.
pcall(function()
	local origPrint, origWarn = print, warn
	local env = (getgenv and getgenv()) or _G
	if type(origPrint) == "function" then
		env.print = function(...)
			origPrint(...)
			consoleWrite(table.concat({ ... }, "\t"), "ffffff")
		end
	end
	if type(origWarn) == "function" then
		env.warn = function(...)
			origWarn(...)
			consoleWrite("[warn] " .. table.concat({ ... }, "\t"), "ffa500")
		end
	end
end)

-- ===== Standalone executor window (matches the LinoriaLib menu style) =====
-- A separate window opened via Misc -> "Open Executor" (or F2). Draggable,
-- minimizable and resizable, with a multi-script explorer. It uses the same
-- look as the main menu: dark panels, blue accent inset border, Code font.
local setTypeMode = nil -- filled in below; needed by the minimize logic
local ExecInput = nil -- filled in below; needed by the minimize logic
local ExecStatus = nil -- filled in below; needed by the minimize logic
local ExecGui = Instance.new("ScreenGui")
ExecGui.Name = "AbsoluteExecutor"
ExecGui.ResetOnSpawn = false
ExecGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() ExecGui.DisplayOrder = 999 end)
local execParent = (Library.ScreenGui and Library.ScreenGui.Parent) or game:GetService("CoreGui")
local okP = pcall(function() ExecGui.Parent = execParent end)
if not okP then
	pcall(function() ExecGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end)
end

-- The window: a black outer shell with the inner panel inset 1px, exactly like
-- the main menu's Outer/Inner pair (MainColor + blue accent inset border).
local ExecWin = Instance.new("Frame")
ExecWin.Name = "ExecWin"
ExecWin.Size = UDim2.fromOffset(620, 500)
ExecWin.Position = UDim2.fromOffset(60, 60)
ExecWin.BackgroundColor3 = Library.Black
ExecWin.BorderSizePixel = 0
ExecWin.Visible = false
ExecWin.Parent = ExecGui

local WinInner = Instance.new("Frame")
WinInner.Name = "WinInner"
WinInner.BackgroundColor3 = Library.MainColor
WinInner.BorderColor3 = Library.AccentColor
WinInner.BorderMode = Enum.BorderMode.Inset
WinInner.Position = UDim2.new(0, 1, 0, 1)
WinInner.Size = UDim2.new(1, -2, 1, -2)
WinInner.Parent = ExecWin

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 28)
TitleBar.BackgroundColor3 = Library.MainColor
TitleBar.BorderSizePixel = 0
TitleBar.Parent = WinInner

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -96, 1, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "ABSOLUTE Executor"
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.TextColor3 = Library.FontColor
TitleText.Font = Library.Font
TitleText.TextSize = 16
TitleText.Parent = TitleBar

local MinBtn = Instance.new("TextButton")
MinBtn.Name = "MinBtn"
MinBtn.Size = UDim2.fromOffset(22, 22)
MinBtn.Position = UDim2.new(1, -53, 0, 3)
MinBtn.BackgroundColor3 = Library.BackgroundColor
MinBtn.BorderColor3 = Library.OutlineColor
MinBtn.Text = "_"
MinBtn.TextColor3 = Library.FontColor
MinBtn.Font = Library.Font
MinBtn.TextSize = 13
MinBtn.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.fromOffset(22, 22)
CloseBtn.Position = UDim2.new(1, -27, 0, 3)
CloseBtn.BackgroundColor3 = Color3.fromRGB(70, 22, 22)
CloseBtn.BorderColor3 = Color3.fromRGB(130, 44, 44)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Library.FontColor
CloseBtn.Font = Library.Font
CloseBtn.TextSize = 13
CloseBtn.Parent = TitleBar

local dragStart = nil
pcall(function()
	TitleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragStart = input.Position - ExecWin.AbsolutePosition
		end
	end)
	TitleBar.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragStart = nil
		end
	end)
	TitleBar.InputChanged:Connect(function(input)
		if dragStart and input.UserInputType == Enum.UserInputType.MouseMovement then
			ExecWin.Position = UDim2.fromOffset(input.Position.X - dragStart.X, input.Position.Y - dragStart.Y)
		end
	end)
end)

-- Status strip under the title bar. Shows whether scripts auto-save to the
-- executor's folder (or falls back to "don't save" if writefile is missing).
local Warning = Instance.new("TextLabel")
Warning.Size = UDim2.new(1, 0, 0, 18)
Warning.Position = UDim2.new(0, 0, 0, 28)
Warning.BackgroundColor3 = Color3.fromRGB(14, 45, 14)
Warning.BorderColor3 = Color3.fromRGB(60, 220, 60)
Warning.BorderMode = Enum.BorderMode.Inset
Warning.Text = "SCRIPTS AUTO-SAVE"
Warning.TextColor3 = Color3.fromRGB(120, 220, 120)
Warning.Font = Library.Font
Warning.TextSize = 13
Warning.TextWrapped = true
Warning.Parent = WinInner

-- Script explorer: a list of scripts on the left, + creates a new one.
local ExplorerPanel = Instance.new("Frame")
ExplorerPanel.Size = UDim2.new(0, 150, 1, -76)
ExplorerPanel.Position = UDim2.new(0, 8, 0, 50)
ExplorerPanel.BackgroundColor3 = Library.BackgroundColor
ExplorerPanel.BorderColor3 = Library.OutlineColor
ExplorerPanel.Parent = WinInner

local ExplorerHeader = Instance.new("Frame")
ExplorerHeader.Size = UDim2.new(1, 0, 0, 24)
ExplorerHeader.BackgroundColor3 = Library.MainColor
ExplorerHeader.BorderSizePixel = 0
ExplorerHeader.Parent = ExplorerPanel

local ExplorerTitle = Instance.new("TextLabel")
ExplorerTitle.Size = UDim2.new(1, -54, 1, 0)
ExplorerTitle.BackgroundTransparency = 1
ExplorerTitle.Text = "Scripts"
ExplorerTitle.TextXAlignment = Enum.TextXAlignment.Left
ExplorerTitle.TextColor3 = Library.FontColor
ExplorerTitle.Font = Library.Font
ExplorerTitle.TextSize = 14
ExplorerTitle.Parent = ExplorerHeader

local MinusBtn = Instance.new("TextButton")
MinusBtn.Name = "MinusBtn"
MinusBtn.Size = UDim2.fromOffset(22, 20)
MinusBtn.Position = UDim2.new(1, -48, 0, 2)
MinusBtn.BackgroundColor3 = Library.BackgroundColor
MinusBtn.BorderColor3 = Library.OutlineColor
MinusBtn.Text = "-"
MinusBtn.TextColor3 = Library.FontColor
MinusBtn.Font = Library.Font
MinusBtn.TextSize = 13
MinusBtn.Parent = ExplorerHeader

local PlusBtn = Instance.new("TextButton")
PlusBtn.Name = "PlusBtn"
PlusBtn.Size = UDim2.fromOffset(22, 20)
PlusBtn.Position = UDim2.new(1, -24, 0, 2)
PlusBtn.BackgroundColor3 = Library.AccentColor
PlusBtn.BorderColor3 = Library.AccentColor
PlusBtn.Text = "+"
PlusBtn.TextColor3 = Library.FontColor
PlusBtn.Font = Library.Font
PlusBtn.TextSize = 15
PlusBtn.Parent = ExplorerHeader

local ScriptList = Instance.new("ScrollingFrame")
ScriptList.Size = UDim2.new(1, 0, 1, -24)
ScriptList.Position = UDim2.new(0, 0, 0, 24)
ScriptList.BackgroundTransparency = 1
ScriptList.BorderSizePixel = 0
ScriptList.ScrollBarThickness = 6
ScriptList.ScrollBarImageColor3 = Library.OutlineColor
ScriptList.CanvasSize = UDim2.new(0, 0, 0, 0)
ScriptList.Parent = ExplorerPanel
local scriptLayout = Instance.new("UIListLayout", ScriptList)
scriptLayout.Padding = UDim.new(0, 2)
scriptLayout.FillDirection = Enum.FillDirection.Vertical
scriptLayout.SortOrder = Enum.SortOrder.LayoutOrder
scriptLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	ScriptList.CanvasSize = UDim2.fromOffset(0, scriptLayout.AbsoluteContentSize.Y + 8)
end)

local RunBtn = Instance.new("TextButton")
RunBtn.Size = UDim2.fromOffset(64, 22)
RunBtn.Position = UDim2.fromOffset(166, 186)
RunBtn.BackgroundColor3 = Color3.fromRGB(20, 50, 20)
RunBtn.BorderColor3 = Color3.fromRGB(60, 110, 60)
RunBtn.Text = "Run"
RunBtn.TextColor3 = Library.FontColor
RunBtn.Font = Library.Font
RunBtn.TextSize = 13
RunBtn.Parent = WinInner
local ClearBtn = Instance.new("TextButton")
ClearBtn.Size = UDim2.fromOffset(64, 22)
ClearBtn.Position = UDim2.fromOffset(236, 186)
ClearBtn.BackgroundColor3 = Library.BackgroundColor
ClearBtn.BorderColor3 = Library.OutlineColor
ClearBtn.Text = "Clear"
ClearBtn.TextColor3 = Library.FontColor
ClearBtn.Font = Library.Font
ClearBtn.TextSize = 13
ClearBtn.Parent = WinInner
local PasteBtn = Instance.new("TextButton")
PasteBtn.Size = UDim2.fromOffset(64, 22)
PasteBtn.Position = UDim2.fromOffset(306, 186)
PasteBtn.BackgroundColor3 = Library.BackgroundColor
PasteBtn.BorderColor3 = Library.OutlineColor
PasteBtn.Text = "Paste"
PasteBtn.TextColor3 = Library.FontColor
PasteBtn.Font = Library.Font
PasteBtn.TextSize = 13
PasteBtn.Parent = WinInner
local ClearLogBtn = Instance.new("TextButton")
ClearLogBtn.Size = UDim2.fromOffset(66, 22)
ClearLogBtn.Position = UDim2.fromOffset(376, 186)
ClearLogBtn.BackgroundColor3 = Library.BackgroundColor
ClearLogBtn.BorderColor3 = Library.OutlineColor
ClearLogBtn.Text = "Clear Log"
ClearLogBtn.TextColor3 = Library.FontColor
ClearLogBtn.Font = Library.Font
ClearLogBtn.TextSize = 13
ClearLogBtn.Parent = WinInner

local ResizeGrip = Instance.new("TextButton")
ResizeGrip.Name = "ResizeGrip"
ResizeGrip.Size = UDim2.fromOffset(16, 16)
ResizeGrip.Position = UDim2.new(1, -17, 1, -17)
ResizeGrip.BackgroundTransparency = 1
ResizeGrip.Text = ""
ResizeGrip.Parent = WinInner

-- Console (built above) lives at the bottom-right of this window now.
ConsoleFrame.Size = UDim2.new(1, -170, 1, -240)
ConsoleFrame.Position = UDim2.new(0, 166, 0, 214)
ConsoleFrame.BorderColor3 = Library.OutlineColor
ConsoleFrame.Parent = WinInner
ConsoleText.Parent = ConsoleFrame

-- FPS games force the mouse to the screen center every frame, which makes
-- clicking/focusing a TextBox (and therefore typing) impossible. While the
-- executor is open we keep the cursor free; on close we hand the mouse back.
local focusGuard = nil
local function freeMouseForTyping()
	pcall(function()
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end)
end
local function execMouseFree()
	pcall(function()
		if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end
	end)
end
local function execMouseBack()
	pcall(function()
		local holder = Window and Window.Holder
		if holder and not holder.Visible then
			if UserInputService.MouseBehavior == Enum.MouseBehavior.Default then
				UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			end
		end
	end)
end

-- Minimize collapses the window to its title bar (and stops typing).
local Minimized = false
local RestoreSize = ExecWin.Size
local function setExecMinimized(v)
	if Minimized == v then return end
	Minimized = v
	Warning.Visible = not v
	ExplorerPanel.Visible = not v
	ExecInput.Visible = not v
	RunBtn.Visible = not v
	ClearBtn.Visible = not v
	PasteBtn.Visible = not v
	ClearLogBtn.Visible = not v
	ConsoleFrame.Visible = not v
	ExecStatus.Visible = not v
	ResizeGrip.Visible = not v
	if v then
		RestoreSize = ExecWin.Size
		ExecWin.Size = UDim2.fromOffset(RestoreSize.X.Offset, 30)
		pcall(function() ExecGui.Modal = false end)
		execMouseBack()
		if setTypeMode then setTypeMode(false) end
	else
		ExecWin.Size = RestoreSize
		pcall(function() ExecGui.Modal = true end)
		execMouseFree()
		if setTypeMode then setTypeMode(true) end
	end
end

-- Resize via the bottom-right grip (drag to grow/shrink).
local resizeStart = nil
pcall(function()
	ResizeGrip.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizeStart = { size = ExecWin.AbsoluteSize, pos = input.Position }
		end
	end)
	ResizeGrip.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then resizeStart = nil end
	end)
	ResizeGrip.InputChanged:Connect(function(input)
		if resizeStart and input.UserInputType == Enum.UserInputType.MouseMovement then
			local w = math.max(480, math.min(1000, resizeStart.size.X + (input.Position.X - resizeStart.pos.X)))
			local h = math.max(340, math.min(800, resizeStart.size.Y + (input.Position.Y - resizeStart.pos.Y)))
			ExecWin.Size = UDim2.fromOffset(w, h)
		end
	end)
end)

ExecInput = Instance.new("TextBox")
ExecInput.Name = "ExecInput"
ExecInput.Size = UDim2.new(1, -170, 0, 130)
ExecInput.Position = UDim2.new(0, 166, 0, 50)
ExecInput.BackgroundColor3 = Library.BackgroundColor
ExecInput.BorderColor3 = Library.OutlineColor
ExecInput.BorderSizePixel = 1
ExecInput.Font = Library.Font
ExecInput.Text = ""
ExecInput.TextColor3 = Library.FontColor
ExecInput.TextSize = 13
ExecInput.TextWrapped = true
ExecInput.TextXAlignment = Enum.TextXAlignment.Left
ExecInput.TextYAlignment = Enum.TextYAlignment.Top
ExecInput.MultiLine = true
ExecInput.ClearTextOnFocus = false
ExecInput.TextEditable = true
ExecInput.PlaceholderText = "-- paste or type your script here"
ExecInput.Parent = WinInner

ExecStatus = Instance.new("TextLabel")
ExecStatus.Name = "ExecStatus"
ExecStatus.BackgroundTransparency = 1
ExecStatus.Size = UDim2.new(1, -170, 0, 20)
ExecStatus.Position = UDim2.new(0, 166, 1, -24)
ExecStatus.Text = "Closed. Open it from Misc or press F2."
ExecStatus.TextXAlignment = Enum.TextXAlignment.Left
ExecStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
ExecStatus.TextSize = 12
ExecStatus.Font = Library.Font
ExecStatus.TextWrapped = true
ExecStatus.Parent = WinInner

local function execRun()
	saveCurrentScript()
	local src = ExecInput.Text
	if #src < 1 then
		ExecStatus.Text = "Nothing to run."
		ExecStatus.TextColor3 = Color3.fromRGB(255, 90, 90)
		return
	end
	local fn, err = loadstring(src, "=ABSOLUTE:Executor")
	if not fn then
		ExecStatus.Text = "Compile error."
		ExecStatus.TextColor3 = Color3.fromRGB(255, 90, 90)
		consoleWrite("[error] " .. tostring(err), "ff4d4d")
		return
	end
	consoleWrite("> " .. src, "8ab4ff")
	local ok, runErr = pcall(fn)
	if ok then
		ExecStatus.Text = "Ran without errors."
		ExecStatus.TextColor3 = Color3.fromRGB(120, 220, 120)
	else
		ExecStatus.Text = "Runtime error."
		ExecStatus.TextColor3 = Color3.fromRGB(255, 90, 90)
		consoleWrite("[error] " .. tostring(runErr), "ff4d4d")
	end
end

-- "Type Mode" captures the keyboard manually and writes it into the box. It
-- works even when this executor/game never gives a TextBox focus, which is why
-- clicking the box (or pressing F2) turns it on. Esc turns it off.
local TypeMode = false
local FocusBorder = Color3.fromRGB(120, 170, 255)
local NormalBorder = Color3.fromRGB(66, 66, 66)
local TypeBorder = Color3.fromRGB(255, 170, 0)
local function updateInputBorder()
	local ok, focused = pcall(function() return ExecInput:IsFocused() end)
	ExecInput.BorderColor3 = TypeMode and TypeBorder or (ok and focused and FocusBorder or NormalBorder)
end

-- Keep the cursor free while the box is focused OR Type Mode is on, so the
-- game can't lock the mouse and steal the keystrokes.
local function updateMouseGuard()
	if focusGuard then pcall(function() focusGuard:Disconnect() end); focusGuard = nil end
	local ok, focused = pcall(function() return ExecInput:IsFocused() end)
	if TypeMode or (ok and focused) then
		focusGuard = addConn(RunService.Heartbeat:Connect(freeMouseForTyping))
	end
end

local typeDigit = { Zero = 0, One = 1, Two = 2, Three = 3, Four = 4, Five = 5, Six = 6, Seven = 7, Eight = 8, Nine = 9 }
local typeKeypad = { KeypadZero = 0, KeypadOne = 1, KeypadTwo = 2, KeypadThree = 3, KeypadFour = 4, KeypadFive = 5, KeypadSix = 6, KeypadSeven = 7, KeypadEight = 8, KeypadNine = 9 }
local typeDigitShift = { ")", "!", "@", "#", "$", "%", "^", "&", "*", "(" }
local typePlain = {
	Space = " ", Comma = ",", Period = ".", Slash = "/", Semicolon = ";", Quote = "'",
	LeftBracket = "[", Backslash = "\\", RightBracket = "]",
	Minus = "-", Equals = "=", Backquote = "`",
}
local typeShifted = {
	Comma = "<", Period = ">", Slash = "?", Semicolon = ":", Quote = '"',
	LeftBracket = "{", Backslash = "|", RightBracket = "}",
	Minus = "_", Equals = "+", Backquote = "~",
}
local function typeCharForKey(key, shift)
	local n = key.Name
	if #n == 1 and n:match("%a") then
		return shift and n or n:lower()
	end
	local d = typeDigit[n]
	if d ~= nil then
		return shift and typeDigitShift[d + 1] or tostring(d)
	end
	local kd = typeKeypad[n]
	if kd ~= nil then
		return tostring(kd)
	end
	if shift and typeShifted[n] then return typeShifted[n] end
	return typePlain[n]
end

local typeModeConn = nil
setTypeMode = function(v)
	TypeMode = v
	pcall(function() ExecInput.TextEditable = not v end)
	if v then pcall(function() ExecInput:ReleaseFocus() end) end
	if typeModeConn then pcall(function() typeModeConn:Disconnect() end); typeModeConn = nil end
	if not v then
		ExecStatus.Text = "Typing OFF - open it from Misc or press F2."
		ExecStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
		updateMouseGuard()
		updateInputBorder()
		return
	end
	ExecStatus.Text = "Typing ON - every key goes into the box. Esc/F2 closes."
	ExecStatus.TextColor3 = Color3.fromRGB(255, 200, 90)
	updateMouseGuard()
	updateInputBorder()
	typeModeConn = addConn(UserInputService.InputBegan:Connect(function(input, gp)
		if not TypeMode or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		local key = input.KeyCode
		local ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
		local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
		if key == Enum.KeyCode.Backspace then
			ExecInput.Text = ExecInput.Text:sub(1, -2)
		elseif key == Enum.KeyCode.Return then
			if ctrl then execRun() else ExecInput.Text = ExecInput.Text .. "\n" end
		elseif key == Enum.KeyCode.V and ctrl then
			if getclipboard then pcall(function() ExecInput.Text = ExecInput.Text .. tostring(getclipboard()) end) end
		else
			local ch = typeCharForKey(key, shift)
			if ch then ExecInput.Text = ExecInput.Text .. ch end
		end
	end))
end

-- Native focus vs. capture: if the box CAN be focused the game types into it
-- normally; otherwise keys are captured. The Focused/FocusLost pair switches
-- between the two automatically so there is never double input.
ExecInput.Focused:Connect(function()
	if ExecWin.Visible then setTypeMode(false) end
	updateMouseGuard()
	updateInputBorder()
end)
ExecInput.FocusLost:Connect(function(enterPressed)
	if ExecWin.Visible and not Minimized then
		setTypeMode(true)
	else
		pcall(function()
			if UserInputService.MouseBehavior == Enum.MouseBehavior.Default then
				UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			end
		end)
	end
	updateMouseGuard()
	updateInputBorder()
	-- Fallback for executors/clients where MultiLine is ignored: plain Enter runs.
	if enterPressed then
		task.defer(execRun)
	end
end)

-- F2 opens/closes the executor; Esc closes it while it is open.
local openExecutor = nil
local closeExecutor = nil
addConn(UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
	if input.KeyCode == Enum.KeyCode.F2 then
		if ExecWin.Visible then closeExecutor() else openExecutor() end
	elseif input.KeyCode == Enum.KeyCode.Escape and ExecWin.Visible then
		closeExecutor()
	end
end))

-- Ctrl+Enter runs while the input is focused (Enter alone is a newline).
pcall(function()
	ExecInput.InputBegan:Connect(function(input, gp)
		if gp and input.KeyCode == Enum.KeyCode.Return and
			(UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
			execRun()
		end
	end)
end)

-- Script explorer state: a list of scripts; clicking one loads it into the
-- editor, + adds a new one, - deletes the selected one.
local Scripts = {}
local CurrentScript = 0
local scriptCounter = 0
local scriptButtons = {}
local refreshScriptList = nil
local saveCurrentScript = nil
local selectScript = nil
local newScript = nil
local deleteScript = nil

-- Auto-save: every script is written to the executor's folder as <Name>.lua so
-- it survives a reload of ABSOLUTE. Falls back to memory-only when the executor
-- lacks writefile/readfile; the status strip shows which mode is active.
local SAVE_DIR = "ABSOLUTE/Scripts"
local fsSupported = nil -- nil = unknown, true = file I/O ok, false = no file I/O
local function checkFS()
	if fsSupported == true then return true end
	if fsSupported == false then return false end
	local has = false
	pcall(function() has = (writefile ~= nil and readfile ~= nil) end)
	if has then
		pcall(function()
			if makefolder and (not isfolder or not isfolder(SAVE_DIR)) then makefolder(SAVE_DIR) end
		end)
		fsSupported = true
	else
		fsSupported = false
	end
	if Warning then
		if fsSupported then
			Warning.Text = "SCRIPTS AUTO-SAVE"
			Warning.BackgroundColor3 = Color3.fromRGB(14, 45, 14)
			Warning.BorderColor3 = Color3.fromRGB(60, 220, 60)
			Warning.TextColor3 = Color3.fromRGB(120, 220, 120)
		else
			Warning.Text = "SCRIPTS DONT SAVE - no file support"
			Warning.BackgroundColor3 = Color3.fromRGB(45, 14, 14)
			Warning.BorderColor3 = Color3.fromRGB(255, 50, 50)
			Warning.TextColor3 = Library.RiskColor
		end
	end
	return fsSupported
end
local function sanitizeName(name)
	local safe = tostring(name):gsub("[^%w _%-%.]+", "_"):gsub("^%.+", ""):sub(1, 60)
	if #safe < 1 then safe = "Script" end
	return safe
end
local function scriptPath(name)
	return SAVE_DIR .. "/" .. sanitizeName(name) .. ".lua"
end
local function saveScriptToDisk(s)
	if not s or not checkFS() then return end
	local path = scriptPath(s.Name)
	if #s.Text < 1 then
		pcall(function() if delfile then delfile(path) end end)
		return
	end
	pcall(function() writefile(path, s.Text) end)
end
local function loadScriptsFromDisk()
	if not checkFS() then return end
	local files
	pcall(function() if listfiles then files = listfiles(SAVE_DIR) end end)
	if not files then return end
	Scripts = {}
	for _, path in ipairs(files) do
		if type(path) == "string" and path:lower():sub(-4) == ".lua" then
			local fname = path:match("([^/\\]+)$") or path
			local ok, text = pcall(readfile, path)
			if ok and type(text) == "string" then
				Scripts[#Scripts + 1] = { Name = fname:sub(1, -5), Text = text }
			end
		end
	end
	local maxN = 0
	for _, s in ipairs(Scripts) do
		local n = tonumber(tostring(s.Name):match("Untitled%s*(%d+)"))
		if n and n > maxN then maxN = n end
	end
	scriptCounter = maxN
	if #Scripts > 0 then
		CurrentScript = 1
		ExecInput.Text = Scripts[1].Text or ""
		refreshScriptList()
		ExecStatus.Text = "Loaded " .. #Scripts .. " saved script" .. (#Scripts == 1 and "" or "s") .. "."
		ExecStatus.TextColor3 = Color3.fromRGB(120, 220, 120)
	end
end

refreshScriptList = function()
	for _, b in ipairs(scriptButtons) do pcall(function() b:Destroy() end) end
	scriptButtons = {}
	for i, s in ipairs(Scripts) do
		local row = Instance.new("TextButton")
		row.Name = "ScriptRow"
		row.Size = UDim2.new(1, -6, 0, 20)
		row.BackgroundColor3 = (i == CurrentScript) and Library.AccentColor or Color3.fromRGB(32, 32, 32)
		row.BorderSizePixel = 0
		row.Text = "  " .. s.Name
		row.TextColor3 = Library.FontColor
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.Font = Library.Font
		row.TextSize = 13
		row.TextTruncate = Enum.TextTruncate.AtEnd
		row.Parent = ScriptList
		pcall(function()
			row.Activated:Connect(function()
				selectScript(i)
			end)
		end)
		scriptButtons[#scriptButtons + 1] = row
	end
	pcall(function() ScriptList.CanvasSize = UDim2.fromOffset(0, scriptLayout.AbsoluteContentSize.Y + 8) end)
end
saveCurrentScript = function()
	if CurrentScript > 0 and Scripts[CurrentScript] then
		Scripts[CurrentScript].Text = ExecInput.Text
		saveScriptToDisk(Scripts[CurrentScript])
	end
end
selectScript = function(i)
	if i == CurrentScript then return end
	saveCurrentScript()
	CurrentScript = i
	ExecInput.Text = Scripts[i].Text or ""
	refreshScriptList()
end
newScript = function()
	saveCurrentScript()
	scriptCounter = scriptCounter + 1
	local name = "Untitled " .. scriptCounter
	Scripts[#Scripts + 1] = { Name = name, Text = "" }
	CurrentScript = #Scripts
	ExecInput.Text = ""
	refreshScriptList()
	ExecStatus.Text = "Created " .. name
	ExecStatus.TextColor3 = Library.FontColor
end
deleteScript = function()
	if CurrentScript <= 0 then return end
	saveCurrentScript()
	local removed = Scripts[CurrentScript]
	if removed then
		local path = scriptPath(removed.Name)
		pcall(function() if delfile then delfile(path) end end)
	end
	table.remove(Scripts, CurrentScript)
	ExecInput.Text = ""
	if #Scripts == 0 then
		CurrentScript = 0
	else
		CurrentScript = math.min(CurrentScript, #Scripts)
		ExecInput.Text = Scripts[CurrentScript].Text or ""
	end
	refreshScriptList()
	ExecStatus.Text = "Script deleted (file removed too)"
	ExecStatus.TextColor3 = Library.RiskColor
end
loadScriptsFromDisk()

pcall(function() MinBtn.MouseButton1Click:Connect(function() setExecMinimized(not Minimized) end) end)
pcall(function() PlusBtn.MouseButton1Click:Connect(newScript) end)
pcall(function() MinusBtn.MouseButton1Click:Connect(deleteScript) end)
pcall(function() RunBtn.MouseButton1Click:Connect(execRun) end)
pcall(function()
	ClearBtn.MouseButton1Click:Connect(function()
		ExecInput.Text = ""
	end)
end)
pcall(function()
	PasteBtn.MouseButton1Click:Connect(function()
		if getclipboard then pcall(function() ExecInput.Text = ExecInput.Text .. tostring(getclipboard()) end) end
	end)
end)
pcall(function()
	ClearLogBtn.MouseButton1Click:Connect(function()
		consoleBuf = ""
		ConsoleText.Text = ""
		ConsoleFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
		ConsoleFrame.CanvasPosition = Vector2.zero
	end)
end)
pcall(function() CloseBtn.MouseButton1Click:Connect(closeExecutor) end)

openExecutor = function()
	if ExecWin.Visible then
		if Minimized then setExecMinimized(false) end
		return
	end
	if #Scripts == 0 then newScript() end
	ExecWin.Visible = true
	ExecGui.Enabled = true
	pcall(function() ExecGui.Modal = true end)
	execMouseFree()
	setTypeMode(true)
end
closeExecutor = function()
	if not ExecWin.Visible then return end
	saveCurrentScript()
	ExecWin.Visible = false
	if Minimized then
		Minimized = false
		ExecWin.Size = RestoreSize
	end
	pcall(function() ExecGui.Modal = false end)
	setTypeMode(false)
	execMouseBack()
end

MiscL:AddDivider()
MiscL:AddButton("Open Executor", openExecutor)

local UiTab = Window:AddTab("Settings")
addPageElement(UiTab)

local UiL = UiTab:AddLeftGroupbox("Theme")
local UiR = UiTab:AddRightGroupbox("Config")

UiL:AddButton("Toggle UI", toggleUI)
UiL:AddLabel("Right Shift toggles the UI.", true)
-- LinoriaLib already toggles RightShift itself when the game doesn't consume
-- the press; only fall back to our own toggle when the game swallowed it.
addConn(UserInputService.InputBegan:Connect(function(input, gp)
	if input.KeyCode == Enum.KeyCode.RightShift and gp then
		local rest = getgenv().absRestoreIfMinimized
		if type(rest) == "function" and rest() then return end
		pcall(function() Library:Toggle() end)
	end
end))
pcall(function() ThemeManager:ApplyToTab(UiTab) end)
pcall(function() SaveManager:BuildConfigSection(UiTab) end)

-- Resize behavior: clip anything that would spill outside the window, and let
-- each tab's Left/Right column fill the window height (they default to a fixed
-- 509px, which leaves dead space when enlarged and overflows when shrunk).
Window.Holder.ClipsDescendants = true
for _, desc in ipairs(Window.Holder:GetDescendants()) do
	if desc.Name == "TabFrame" then
		for _, side in ipairs(desc:GetChildren()) do
			if side:IsA("ScrollingFrame") then
				side.Size = UDim2.new(0.5, -10, 1, -16)
			end
		end
	end
end

-- Tab bar: make the tab buttons scrollable when the window is too small to
-- fit them, and support switching between horizontal (top) and vertical
-- (left) layouts.
local TabFrame0 = nil
for _, desc in ipairs(Window.Holder:GetDescendants()) do
	if desc.Name == "TabFrame" then TabFrame0 = desc; break end
end
local tabContainer = TabFrame0 and TabFrame0.Parent
local mainSectionInner = tabContainer and tabContainer.Parent
local tabArea = nil
local tabLayout = nil
if mainSectionInner then
	for _, child in ipairs(mainSectionInner:GetChildren()) do
		if child:IsA("Frame") then
			local lay = child:FindFirstChildOfClass("UIListLayout")
			if lay and lay.FillDirection == Enum.FillDirection.Horizontal then
				tabArea = child
				tabLayout = lay
				break
			end
		end
	end
end

local TabVertical = false
local tabScroll = nil

local function updateTabCanvas()
	if not tabScroll or not tabLayout then return end
	local s = tabLayout.AbsoluteContentSize
	if TabVertical then
		tabScroll.CanvasSize = UDim2.fromOffset(0, s.Y)
	else
		tabScroll.CanvasSize = UDim2.fromOffset(s.X, 0)
	end
end

local function applyTabOrientation()
	if not tabArea or not tabLayout or not tabContainer or not tabScroll then return end
	if TabVertical then
		tabArea.Position = UDim2.new(0, 8, 0, 8)
		tabArea.Size = UDim2.new(0, 122, 1, -16)
		tabLayout.FillDirection = Enum.FillDirection.Vertical
		tabScroll.ScrollingDirection = Enum.ScrollingDirection.Y
		for _, b in ipairs(tabScroll:GetChildren()) do
			if b:IsA("Frame") then
				b.Size = UDim2.new(1, 0, 0, 26)
			end
		end
		tabContainer.Position = UDim2.new(0, 138, 0, 8)
		tabContainer.Size = UDim2.new(1, -146, 1, -16)
	else
		tabArea.Position = UDim2.new(0, 8, 0, 8)
		tabArea.Size = UDim2.new(1, -16, 0, 21)
		tabLayout.FillDirection = Enum.FillDirection.Horizontal
		tabScroll.ScrollingDirection = Enum.ScrollingDirection.X
		for _, b in ipairs(tabScroll:GetChildren()) do
			if b:IsA("Frame") then
				local label = b:FindFirstChildOfClass("TextLabel")
				local w = label and math.ceil(label.TextBounds.X) + 12 or 40
				b.Size = UDim2.new(0, w, 1, 0)
			end
		end
		tabContainer.Position = UDim2.new(0, 8, 0, 30)
		tabContainer.Size = UDim2.new(1, -16, 1, -38)
	end
	task.defer(updateTabCanvas)
end

if tabArea and tabLayout then
	tabScroll = Instance.new("ScrollingFrame")
	tabScroll.Name = "TabScroll"
	tabScroll.BackgroundTransparency = 1
	tabScroll.BorderSizePixel = 0
	tabScroll.Size = UDim2.new(1, 0, 1, 0)
	tabScroll.ScrollingDirection = Enum.ScrollingDirection.X
	tabScroll.ScrollBarThickness = 3
	tabScroll.ScrollBarImageColor3 = Color3.fromRGB(110, 110, 110)
	tabScroll.Parent = tabArea

	tabLayout.Parent = tabScroll
	for _, b in ipairs(tabArea:GetChildren()) do
		if b ~= tabScroll and b:IsA("Frame") then
			b.Parent = tabScroll
		end
	end
	tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateTabCanvas)
	updateTabCanvas()
end

UiR:AddToggle("Ui_TabVertical", { Text = "Vertical Tabs", Default = false, Callback = function(v)
	TabVertical = v
	pcall(applyTabOrientation)
end })

refreshPlayerList()
addConn(Players.PlayerAdded:Connect(refreshPlayerList))
addConn(Players.PlayerRemoving:Connect(refreshPlayerList))
task.spawn(function()
	while true do
		task.wait(10)
		pcall(refreshPlayerList)
	end
end)

Library:OnUnload(function()
	setEspState(false)
	setEspPreviewState(false)
	loopStop("Aim")
	loopStop("Silent")
	if aimFovCircle then pcall(function() aimFovCircle:Remove() end); aimFovCircle = nil end
	setHitboxState(false)
	setFlyState(false)
	setNoclipState(false)
	setFreecamState(false)
	setFpsBoostState(false)
	setHudState(false)
	setSpeedoState(false)
	setInfJumpState(false)
	setHidePlayersState(false)
	specApply(false)
	setFlingState(false)
	setFlingTouchState(false)
	setBringState(false)
	setBringAllState(false)
	setWpMarkersState(false)
	setDesyncState(false)
	setThirdPersonState(false)
	setCrosshairState(false)
	setFullBrightState(false)
	setNightVisionState(false)
	setNoFogState(false)
	setFovState(false)
	setStretchState(false)
	setRenderDistState(false)
	setXrayState(false)
	stopAllLoops()
	if ExecGui then pcall(function() ExecGui:Destroy() end); ExecGui = nil end
	for _, c in ipairs(Conns) do pcall(function() c:Disconnect() end) end
	Conns = {}
	notify("ABSOLUTE", "Unloaded.", 2)
end)

notify("ABSOLUTE", "Loaded. Right Shift = menu, F2 = executor.", 3)
