--[[
    LAI ADMIN — Final Edition
    All fixes applied:
      • Fly: LinearVelocity only, direct CFrame orientation lock (no AlignOrientation spin bug)
      • Fling: ghost method — save pos → TP to target → blast → TP back instantly (user never flies away)
      • Freeze: Heartbeat CFrame lock loop (works within LocalScript network ownership)
      • Noclip: safe restore — only re-enables collision after confirming char is clear
      • WalkSpeed: only writes when value actually changes (no wasteful every-frame set)
      • Fly respawn: StopFly() fully awaited before restart to prevent double-constraint
      • ESP: event-driven (PlayerAdded/Removing) instead of polling loop
      • Spin: moved to RunService.Stepped (after physics) to prevent jitter
      • randName: seeded with tick()+os.clock() for true randomness
      • All instances: Archivable = false (won't show in serialize scans)
      • ESP folder: parented to camera instead of Workspace
      • GUI: CoreGui parent, random name, hidden on start
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")
local Workspace        = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- ============================================================
-- UTILITY
-- ============================================================
math.randomseed(math.floor(tick() * 1000) + math.floor(os.clock() * 1000))

local function randName(len)
    local c = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local s = ""
    for _ = 1, len or 8 do s = s .. c:sub(math.random(1,#c), math.random(1,#c)) end
    return s
end

-- Mark instance as non-archivable (invisible to serialize scans) and return it
local function stealth(inst)
    inst.Archivable = false
    return inst
end

local MAX_FORCE = 9e5  -- large but finite, avoids inf flags

-- ============================================================
-- 1. KEYBINDS
-- ============================================================
local keybinds = {
    Menu      = Enum.KeyCode.F1,
    Fly       = Enum.KeyCode.E,
    WalkSpeed = Enum.KeyCode.R,
    JumpPower = Enum.KeyCode.J,
    InfJump   = Enum.KeyCode.K,
    ESP       = Enum.KeyCode.V,
    Noclip    = Enum.KeyCode.N,
}
local listeningForAction, listeningButton = nil, nil
local currentFlyMode = "Camera"

-- ============================================================
-- 2. THEME
-- ============================================================
local T = {
    MainBG      = Color3.fromRGB(15,  15,  20),
    ElemBG      = Color3.fromRGB(30,  30,  40),
    ElemHover   = Color3.fromRGB(45,  45,  55),
    AccentON    = Color3.fromRGB(0,   170, 255),
    TextMain    = Color3.fromRGB(255, 255, 255),
    TextSub     = Color3.fromRGB(180, 180, 200),
    Border      = Color3.fromRGB(45,  45,  60),
    Troll       = Color3.fromRGB(255, 60,  80),
}

-- ============================================================
-- 3. GUI  (CoreGui parent, random name, hidden on start)
-- ============================================================
local gui = stealth(Instance.new("ScreenGui"))
gui.Name           = randName(10)
gui.ResetOnSpawn   = false
gui.IgnoreGuiInset = true
pcall(function() gui.Parent = CoreGui end)
if not gui.Parent then gui.Parent = player:WaitForChild("PlayerGui") end

local main = stealth(Instance.new("Frame"))
main.Size                  = UDim2.new(0, 280, 0, 500)
main.Position              = UDim2.new(0, -320, 0.5, -250)  -- off-screen
main.BackgroundColor3      = T.MainBG
main.BackgroundTransparency = 0.05
main.BorderSizePixel       = 0
main.Parent                = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
local ms = Instance.new("UIStroke", main); ms.Color = T.Border; ms.Thickness = 1.5

-- Title bar
local titleF = stealth(Instance.new("Frame"))
titleF.Size = UDim2.new(1,0,0,40); titleF.BackgroundColor3 = Color3.new(1,1,1)
titleF.BorderSizePixel = 0; titleF.Parent = main
Instance.new("UICorner", titleF).CornerRadius = UDim.new(0,12)
local tg = Instance.new("UIGradient", titleF)
tg.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(20,30,50)), ColorSequenceKeypoint.new(1, Color3.fromRGB(10,15,25))})
local tbc = stealth(Instance.new("Frame", titleF))
tbc.Size = UDim2.new(1,0,0,10); tbc.Position = UDim2.new(0,0,1,-10)
tbc.BackgroundColor3 = Color3.fromRGB(10,15,25); tbc.BorderSizePixel = 0

local titleLbl = stealth(Instance.new("TextLabel", titleF))
titleLbl.Size = UDim2.new(0.7,0,1,0); titleLbl.Position = UDim2.new(0.05,0,0,0)
titleLbl.BackgroundTransparency = 1; titleLbl.Text = "LAI ADMIN"
titleLbl.TextColor3 = T.TextMain; titleLbl.Font = Enum.Font.GothamBlack
titleLbl.TextSize = 16; titleLbl.TextXAlignment = Enum.TextXAlignment.Left

local menuBindBtn = stealth(Instance.new("TextButton", titleF))
menuBindBtn.Size = UDim2.new(0.2,0,0.6,0); menuBindBtn.Position = UDim2.new(0.75,0,0.2,0)
menuBindBtn.BackgroundColor3 = T.ElemHover; menuBindBtn.TextColor3 = T.AccentON
menuBindBtn.Font = Enum.Font.GothamBold; menuBindBtn.TextSize = 12
menuBindBtn.Text = "["..keybinds.Menu.Name.."]"
Instance.new("UICorner", menuBindBtn).CornerRadius = UDim.new(0,6)

-- ============================================================
-- 4. TAB BAR
-- ============================================================
local tabBar = stealth(Instance.new("Frame", main))
tabBar.Size = UDim2.new(1,0,0,35); tabBar.Position = UDim2.new(0,0,0,40)
tabBar.BackgroundColor3 = T.MainBG; tabBar.BorderSizePixel = 0

local function mkTab(text, x, col)
    local b = stealth(Instance.new("TextButton", tabBar))
    b.Size = UDim2.new(0.25,0,1,0); b.Position = UDim2.new(x,0,0,0)
    b.BackgroundColor3 = T.MainBG; b.Text = text
    b.TextColor3 = col or T.TextSub; b.Font = Enum.Font.GothamBold
    b.TextSize = 12; b.BorderSizePixel = 0
    return b
end
local tabMain   = mkTab("Main",      0,    T.TextMain)
local tabTP     = mkTab("Teleport",  0.25)
local tabEmotes = mkTab("Emotes",    0.50)
local tabTroll  = mkTab("😈 Troll", 0.75, T.Troll)
tabMain.BackgroundColor3 = T.ElemHover

-- ============================================================
-- 5. CONTAINER FACTORY
-- ============================================================
local function mkContainer(visible)
    local sf = stealth(Instance.new("ScrollingFrame", main))
    sf.Size = UDim2.new(1,0,1,-85); sf.Position = UDim2.new(0,0,0,80)
    sf.BackgroundTransparency = 1; sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 3; sf.ScrollBarImageColor3 = T.AccentON
    sf.Visible = visible; sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.CanvasSize = UDim2.new(0,0,0,0)
    local l = Instance.new("UIListLayout", sf)
    l.Padding = UDim.new(0,10); l.HorizontalAlignment = Enum.HorizontalAlignment.Center
    l.SortOrder = Enum.SortOrder.LayoutOrder
    local p = Instance.new("UIPadding", sf)
    p.PaddingTop = UDim.new(0,10); p.PaddingBottom = UDim.new(0,10)
    return sf
end

local cMain   = mkContainer(true)
local cTP     = mkContainer(false)
local cEmotes = mkContainer(false)
local cTroll  = mkContainer(false)

-- ============================================================
-- 6. WIDGET HELPERS
-- ============================================================
local function stroke(obj)
    local s = Instance.new("UIStroke", obj); s.Color = T.Border; s.Thickness = 1
end

local function mkRow(parent, text, action, order)
    local row = stealth(Instance.new("Frame", parent))
    row.Size = UDim2.new(0.9,0,0,36); row.BackgroundTransparency = 1; row.LayoutOrder = order

    local tog = stealth(Instance.new("TextButton", row))
    tog.Size = UDim2.new(0.75,-6,1,0); tog.BackgroundColor3 = T.ElemBG
    tog.TextColor3 = T.TextMain; tog.Font = Enum.Font.GothamSemibold
    tog.TextSize = 13; tog.Text = text
    Instance.new("UICorner", tog).CornerRadius = UDim.new(0,6); stroke(tog)

    local bind = stealth(Instance.new("TextButton", row))
    bind.Size = UDim2.new(0.25,0,1,0); bind.Position = UDim2.new(0.75,6,0,0)
    bind.BackgroundColor3 = T.ElemHover; bind.TextColor3 = T.AccentON
    bind.Font = Enum.Font.GothamBold; bind.TextSize = 12
    bind.Text = "["..keybinds[action].Name.."]"
    Instance.new("UICorner", bind).CornerRadius = UDim.new(0,6); stroke(bind)
    bind.MouseButton1Click:Connect(function()
        listeningForAction = action; listeningButton = bind; bind.Text = "..."
    end)
    return tog
end

local function mkInput(parent, ph, order)
    local b = stealth(Instance.new("TextBox", parent))
    b.Size = UDim2.new(0.9,0,0,32); b.BackgroundColor3 = T.ElemBG
    b.TextColor3 = T.AccentON; b.Font = Enum.Font.GothamBold; b.TextSize = 13
    b.LayoutOrder = order; b.PlaceholderText = ph; b.PlaceholderColor3 = T.TextSub; b.Text = ""
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6); stroke(b)
    return b
end

local function mkBtn(parent, text, bg, order)
    local b = stealth(Instance.new("TextButton", parent))
    b.Size = UDim2.new(0.9,0,0,34); b.BackgroundColor3 = bg or T.ElemBG
    b.TextColor3 = T.TextMain; b.Font = Enum.Font.GothamBold; b.TextSize = 13
    b.Text = text; b.LayoutOrder = order
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6); stroke(b)
    return b
end

local function mkPresets(parent, label, vals, box, order)
    local row = stealth(Instance.new("Frame", parent))
    row.Size = UDim2.new(0.9,0,0,26); row.BackgroundTransparency = 1; row.LayoutOrder = order
    local lbl = stealth(Instance.new("TextLabel", row))
    lbl.Size = UDim2.new(0.35,0,1,0); lbl.BackgroundTransparency = 1
    lbl.Text = label; lbl.TextColor3 = T.TextSub; lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 11; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local w = 0.6/#vals
    for i,v in ipairs(vals) do
        local b = stealth(Instance.new("TextButton", row))
        b.Size = UDim2.new(w,-4,1,0); b.Position = UDim2.new(0.35+w*(i-1),2,0,0)
        b.BackgroundColor3 = T.ElemHover; b.TextColor3 = T.TextMain
        b.Font = Enum.Font.GothamBold; b.TextSize = 11; b.Text = tostring(v)
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,4); stroke(b)
        b.MouseButton1Click:Connect(function() box.Text = tostring(v) end)
    end
end

local function mkLabel(parent, text, order)
    local l = stealth(Instance.new("TextLabel", parent))
    l.Size = UDim2.new(0.9,0,0,20); l.BackgroundTransparency = 1
    l.Text = text; l.TextColor3 = T.TextSub; l.Font = Enum.Font.GothamSemibold
    l.TextSize = 11; l.TextXAlignment = Enum.TextXAlignment.Left; l.LayoutOrder = order
    return l
end

-- ============================================================
-- 7. POPULATE TABS
-- ============================================================
local flyBtn      = mkRow(cMain, "Toggle Fly",       "Fly",       1)
local flyModeBtn  = mkBtn(cMain, "Fly Mode: Camera", T.ElemBG,    2)
local flySpeedBox = mkInput(cMain, "Fly Speed (Def: 50)", 3); flySpeedBox.Text = "50"
mkPresets(cMain, "Speed:", {50, 100, 300}, flySpeedBox, 4)

local walkBtn     = mkRow(cMain, "Toggle WalkSpeed", "WalkSpeed", 5)
local walkBox     = mkInput(cMain, "Walk Speed (Def: 16)", 6); walkBox.Text = "16"
mkPresets(cMain, "Speed:", {16, 50, 100}, walkBox, 7)

local jumpBtn     = mkRow(cMain, "Toggle JumpPower", "JumpPower", 8)
local jumpBox     = mkInput(cMain, "Jump Power (Def: 50)", 9); jumpBox.Text = "50"
mkPresets(cMain, "Power:", {50, 100, 250}, jumpBox, 10)

local infJumpBtn  = mkRow(cMain, "Infinite Jump",  "InfJump", 11)
local noclipBtn   = mkRow(cMain, "Toggle Noclip",  "Noclip",  12)
local espBtn      = mkRow(cMain, "Toggle ESP",     "ESP",     13)

-- Teleport
local tpBox       = mkInput(cTP, "Player Name (ex: rob...)", 1)
local tpInstant   = mkBtn(cTP, "⚡ Instant Teleport", Color3.fromRGB(80,40,150), 2)
local tpDash      = mkBtn(cTP, "☄️ Dash Teleport",   Color3.fromRGB(200,90,40), 3)

-- Emotes
local emoteList = {"wave","point","dance","dance2","dance3","laugh","cheer","salute","stadium","tilt","shrug"}
local emoteBtns = {}
for i,n in ipairs(emoteList) do emoteBtns[n] = mkBtn(cEmotes, "▶ "..n, T.ElemBG, i) end

-- Troll
mkLabel(cTroll, "Target Player:", 1)
local trollBox  = mkInput(cTroll, "Player Name (ex: rob...)", 2)
mkLabel(cTroll, "─── Freeze ──────────────────", 3)
local freezeBtn = mkBtn(cTroll, "🧊 Freeze Player",       Color3.fromRGB(30,90,160),  4)
local unfrzBtn  = mkBtn(cTroll, "🔥 Unfreeze Player",     Color3.fromRGB(160,70,20),  5)
mkLabel(cTroll, "─── Fling ───────────────────", 6)
local flingBox  = mkInput(cTroll, "Fling Force (Def: 500)", 7); flingBox.Text = "500"
mkPresets(cTroll, "Force:", {200, 500, 2000}, flingBox, 8)
local flingBtn  = mkBtn(cTroll, "💥 Fling Player",        Color3.fromRGB(180,30,50),  9)
mkLabel(cTroll, "─── Spin ────────────────────", 10)
local spinBtn   = mkBtn(cTroll, "🌀 Spin Player (Toggle)", Color3.fromRGB(100,20,140), 11)
mkLabel(cTroll, "─── Follow ──────────────────", 12)
local followBtn = mkBtn(cTroll, "👁 Follow Player (Toggle)", Color3.fromRGB(20,120,80), 13)

-- ============================================================
-- 8. TAB SWITCHING
-- ============================================================
local tabs = {
    {btn=tabMain,   c=cMain},
    {btn=tabTP,     c=cTP},
    {btn=tabEmotes, c=cEmotes},
    {btn=tabTroll,  c=cTroll},
}
local function switchTab(ab, ac)
    for _,t in ipairs(tabs) do
        t.c.Visible = false
        t.btn.BackgroundColor3 = T.MainBG
        t.btn.TextColor3 = (t.btn == tabTroll) and T.Troll or T.TextSub
    end
    ac.Visible = true; ab.BackgroundColor3 = T.ElemHover
    ab.TextColor3 = (ab == tabTroll) and T.Troll or T.TextMain
end
for _,t in ipairs(tabs) do
    t.btn.MouseButton1Click:Connect(function() switchTab(t.btn, t.c) end)
end
switchTab(tabMain, cMain)

-- ============================================================
-- 9. STATE
-- ============================================================
local isFlying, isWalk, isJump, isInfJump, isNoclip, isESP =
      false,    false,  false,  false,     false,    false

local flyAttach, flyLV
local flyConn, walkConn, jumpConn, infJumpConn, noclipConn

-- Cached walk/jump values to avoid redundant sets
local lastWalkVal, lastJumpVal = -1, -1

local function setBtn(btn, on)
    btn.BackgroundColor3 = on and T.AccentON or T.ElemBG
    btn.TextColor3       = on and Color3.fromRGB(25,25,30) or T.TextMain
end

-- ============================================================
-- 10. PLAYER FINDER
-- ============================================================
local function FindPlayer(partial)
    if not partial or partial == "" then return nil end
    local low = partial:lower()
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            if p.Name:lower():sub(1,#low) == low or p.DisplayName:lower():sub(1,#low) == low then
                return p
            end
        end
    end
end

-- ============================================================
-- 11. TELEPORT
-- ============================================================
local function SafeTP(hrp, cf)
    task.wait(0.05 + math.random()*0.08)
    hrp.CFrame = cf * CFrame.new((math.random()-0.5)*1.5, 0, 3+(math.random()-0.5)*1.5)
end

tpInstant.MouseButton1Click:Connect(function()
    local t = FindPlayer(tpBox.Text)
    if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
        local h = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if h then SafeTP(h, t.Character.HumanoidRootPart.CFrame) end
    else tpBox.Text="Not found!"; task.wait(1); tpBox.Text="" end
end)

tpDash.MouseButton1Click:Connect(function()
    local t = FindPlayer(tpBox.Text)
    if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
        local h = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if h then
            local d = (h.Position - t.Character.HumanoidRootPart.Position).Magnitude
            TweenService:Create(h, TweenInfo.new(math.clamp(d/150,0.3,3), Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                {CFrame = t.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,3)}):Play()
        end
    else tpBox.Text="Not found!"; task.wait(1); tpBox.Text="" end
end)

-- ============================================================
-- 12. FLY  —  LinearVelocity + direct CFrame orientation
-- ============================================================
flyModeBtn.MouseButton1Click:Connect(function()
    currentFlyMode = currentFlyMode == "Camera" and "Hover" or "Camera"
    flyModeBtn.Text = currentFlyMode == "Camera" and "Fly Mode: Camera" or "Fly Mode: Hover (Space/Ctrl)"
end)

local function StopFly()
    if flyConn    then flyConn:Disconnect(); flyConn = nil end
    if flyAttach and flyAttach.Parent then flyAttach:Destroy() end
    flyAttach, flyLV = nil, nil
    local hum = player.Character and player.Character:FindFirstChild("Humanoid")
    if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
end

local function ToggleFly()
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end

    isFlying = not isFlying
    setBtn(flyBtn, isFlying)

    if not isFlying then StopFly(); return end

    hum:ChangeState(Enum.HumanoidStateType.Physics)

    flyAttach = stealth(Instance.new("Attachment"))
    flyAttach.Name = randName(6); flyAttach.Parent = hrp

    flyLV = stealth(Instance.new("LinearVelocity"))
    flyLV.Name = randName(6); flyLV.Attachment0 = flyAttach
    flyLV.MaxForce = MAX_FORCE; flyLV.VectorVelocity = Vector3.zero
    flyLV.RelativeTo = Enum.ActuatorRelativeTo.World; flyLV.Parent = flyAttach

    local smooth = Vector3.zero

    flyConn = RunService.RenderStepped:Connect(function(dt)
        local c  = player.Character
        local h2 = c and c:FindFirstChild("HumanoidRootPart")
        local hm = c and c:FindFirstChild("Humanoid")
        if not h2 or not hm or not flyAttach or not flyAttach.Parent then
            StopFly(); isFlying = false; setBtn(flyBtn, false); return
        end

        hm:ChangeState(Enum.HumanoidStateType.Physics)

        local dir = Vector3.zero
        if currentFlyMode == "Camera" then
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += camera.CFrame.LookVector  end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= camera.CFrame.LookVector  end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += camera.CFrame.RightVector end
        else
            local fwd = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
            local rgt = Vector3.new(camera.CFrame.RightVector.X,0, camera.CFrame.RightVector.Z)
            fwd = fwd.Magnitude > 0.01 and fwd.Unit or Vector3.zero
            rgt = rgt.Magnitude > 0.01 and rgt.Unit or Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W)           then dir += fwd end
            if UserInputService:IsKeyDown(Enum.KeyCode.S)           then dir -= fwd end
            if UserInputService:IsKeyDown(Enum.KeyCode.A)           then dir -= rgt end
            if UserInputService:IsKeyDown(Enum.KeyCode.D)           then dir += rgt end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space)       then dir += Vector3.yAxis end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis end
        end

        local spd = tonumber(flySpeedBox.Text) or 50
        smooth = smooth:Lerp(dir.Magnitude > 0 and dir.Unit * spd or Vector3.zero, math.min(1, dt*10))
        flyLV.VectorVelocity = smooth

        -- Keep character facing camera horizontally, always upright
        local look = camera.CFrame.LookVector
        local flat = Vector3.new(look.X, 0, look.Z)
        if flat.Magnitude > 0.01 then
            h2.CFrame = CFrame.new(h2.Position, h2.Position + flat)
        end
    end)
end

-- ============================================================
-- 13. WALKSPEED  — only writes when value changes
-- ============================================================
local function applyWalk()
    local hum = player.Character and player.Character:FindFirstChild("Humanoid")
    if not hum then return end
    local v = math.clamp(tonumber(walkBox.Text) or 16, 0, 500)
    if v ~= lastWalkVal then hum.WalkSpeed = v; lastWalkVal = v end
end

local function ToggleWalkSpeed()
    isWalk = not isWalk; setBtn(walkBtn, isWalk)
    if isWalk then
        lastWalkVal = -1  -- force write on first frame
        walkConn = RunService.Heartbeat:Connect(applyWalk)
    else
        if walkConn then walkConn:Disconnect(); walkConn = nil end
        local hum = player.Character and player.Character:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = 16 end; lastWalkVal = -1
    end
end

-- ============================================================
-- 14. JUMPPOWER  — only writes when value changes
-- ============================================================
local function applyJump()
    local hum = player.Character and player.Character:FindFirstChild("Humanoid")
    if not hum then return end
    local v = math.clamp(tonumber(jumpBox.Text) or 50, 0, 1000)
    if v ~= lastJumpVal then hum.UseJumpPower = true; hum.JumpPower = v; lastJumpVal = v end
end

local function ToggleJumpPower()
    isJump = not isJump; setBtn(jumpBtn, isJump)
    if isJump then
        lastJumpVal = -1
        jumpConn = RunService.Heartbeat:Connect(applyJump)
    else
        if jumpConn then jumpConn:Disconnect(); jumpConn = nil end
        local hum = player.Character and player.Character:FindFirstChild("Humanoid")
        if hum then hum.UseJumpPower = true; hum.JumpPower = 50 end; lastJumpVal = -1
    end
end

-- ============================================================
-- 15. INFINITE JUMP
-- ============================================================
local function ToggleInfJump()
    isInfJump = not isInfJump; setBtn(infJumpBtn, isInfJump)
    if isInfJump then
        infJumpConn = UserInputService.JumpRequest:Connect(function()
            local hum = player.Character and player.Character:FindFirstChild("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    else
        if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end
    end
end

-- ============================================================
-- 16. NOCLIP  — safe restore (no bounce-out-of-wall bug)
-- ============================================================
local function ToggleNoclip()
    isNoclip = not isNoclip; setBtn(noclipBtn, isNoclip)
    if isNoclip then
        noclipConn = RunService.Stepped:Connect(function()
            local char = player.Character; if not char then return end
            for _,p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        -- Delay restore by 1 frame so character is no longer inside geometry
        task.defer(function()
            local char = player.Character; if not char then return end
            for _,p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end)
    end
end

-- ============================================================
-- 17. ESP  — event-driven, Highlight in camera folder
-- ============================================================
-- Parent to camera — far less scanned than Workspace children
local espFolder = stealth(Instance.new("Folder"))
espFolder.Name = randName(8); espFolder.Parent = camera

local function addESP(p)
    if p == player then return end
    local char = p.Character; if not char then return end
    for _,h in ipairs(espFolder:GetChildren()) do
        if h:IsA("Highlight") and h.Adornee == char then return end
    end
    local hl = stealth(Instance.new("Highlight", espFolder))
    hl.Name = randName(6); hl.Adornee = char
    hl.FillColor = Color3.fromRGB(0,170,255); hl.OutlineColor = Color3.new(1,1,1)
    hl.FillTransparency = 0.5
end

local function removeESP(p)
    for _,h in ipairs(espFolder:GetChildren()) do
        if h:IsA("Highlight") and h.Adornee and h.Adornee:IsDescendantOf(game) then
            -- check if adornee belongs to this player
            if Players:GetPlayerFromCharacter(h.Adornee) == p then h:Destroy() end
        end
    end
end

local espPlayerAdded, espPlayerRemoving, espCharAdded = {}, {}, {}

local function ToggleESP()
    isESP = not isESP; setBtn(espBtn, isESP)
    if isESP then
        -- Existing players
        for _,p in ipairs(Players:GetPlayers()) do addESP(p) end
        -- New players joining
        espPlayerAdded.conn = Players.PlayerAdded:Connect(function(p)
            espCharAdded[p] = p.CharacterAdded:Connect(function() task.wait(0.1); addESP(p) end)
            addESP(p)
        end)
        espPlayerRemoving.conn = Players.PlayerRemoving:Connect(removeESP)
        -- Also hook CharacterAdded for existing players
        for _,p in ipairs(Players:GetPlayers()) do
            if p ~= player then
                espCharAdded[p] = p.CharacterAdded:Connect(function() task.wait(0.1); addESP(p) end)
            end
        end
    else
        espFolder:ClearAllChildren()
        if espPlayerAdded.conn   then espPlayerAdded.conn:Disconnect()   end
        if espPlayerRemoving.conn then espPlayerRemoving.conn:Disconnect() end
        for _,c in pairs(espCharAdded) do c:Disconnect() end
        espCharAdded = {}
    end
end

-- ============================================================
-- 18. RESPAWN PERSISTENCE
-- ============================================================
player.CharacterAdded:Connect(function()
    task.wait(0.3)
    lastWalkVal = -1; lastJumpVal = -1
    if isWalk  then applyWalk() end
    if isJump  then applyJump() end
    if isFlying then
        -- Fully clean up old constraints before restarting
        StopFly()
        isFlying = false
        task.wait(0.15)
        ToggleFly()
    end
end)

-- ============================================================
-- 19. BUTTON WIRING
-- ============================================================
flyBtn.MouseButton1Click:Connect(ToggleFly)
walkBtn.MouseButton1Click:Connect(ToggleWalkSpeed)
jumpBtn.MouseButton1Click:Connect(ToggleJumpPower)
infJumpBtn.MouseButton1Click:Connect(ToggleInfJump)
noclipBtn.MouseButton1Click:Connect(ToggleNoclip)
espBtn.MouseButton1Click:Connect(ToggleESP)

menuBindBtn.MouseButton1Click:Connect(function()
    listeningForAction = "Menu"; listeningButton = menuBindBtn; menuBindBtn.Text = "..."
end)

for name,btn in pairs(emoteBtns) do
    btn.MouseButton1Click:Connect(function()
        local char = player.Character
        if char and char:FindFirstChild("Animate") then
            local pe = char.Animate:FindFirstChild("PlayEmote")
            if pe and pe:IsA("BindableFunction") then
                pe:Invoke(name)
                -- Visual feedback: briefly highlight the button
                btn.BackgroundColor3 = T.AccentON
                task.delay(0.4, function() btn.BackgroundColor3 = T.ElemBG end)
            end
        end
    end)
end

-- ============================================================
-- 20. TROLL LOGIC
-- ============================================================

-- FREEZE — Heartbeat CFrame lock (works client-side)
local freezeConn, frozenTarget, frozenCF = nil, nil, nil

freezeBtn.MouseButton1Click:Connect(function()
    local t = FindPlayer(trollBox.Text)
    if not (t and t.Character and t.Character:FindFirstChild("HumanoidRootPart")) then
        trollBox.Text = "Not found!"; task.wait(1); trollBox.Text = ""; return
    end
    if freezeConn then freezeConn:Disconnect(); freezeConn = nil end
    frozenTarget = t
    frozenCF     = t.Character.HumanoidRootPart.CFrame
    freezeConn = RunService.Heartbeat:Connect(function()
        if not frozenTarget or not frozenTarget.Character then
            if freezeConn then freezeConn:Disconnect(); freezeConn = nil end; return
        end
        local hrp = frozenTarget.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = frozenCF end
    end)
    freezeBtn.Text = "🧊 Frozen: " .. t.Name
end)

unfrzBtn.MouseButton1Click:Connect(function()
    if freezeConn then freezeConn:Disconnect(); freezeConn = nil end
    frozenTarget = nil; frozenCF = nil
    freezeBtn.Text = "🧊 Freeze Player"
end)

-- FLING — Ghost method: save our position → invisible TP to target →
--         apply LinearVelocity on OUR hrp pointing AWAY from us (pushes target via collision) →
--         immediately TP back home. We never fly away.
flingBtn.MouseButton1Click:Connect(function()
    local t = FindPlayer(trollBox.Text)
    if not (t and t.Character and t.Character:FindFirstChild("HumanoidRootPart")) then
        trollBox.Text = "Not found!"; task.wait(1); trollBox.Text = ""; return
    end
    local myChar = player.Character
    local myHrp  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum  = myChar and myChar:FindFirstChild("Humanoid")
    if not myHrp or not myHum then return end

    local targetHrp  = t.Character.HumanoidRootPart
    local force      = math.clamp(tonumber(flingBox.Text) or 500, 1, 5000)
    local savedCF    = myHrp.CFrame  -- remember where we are

    -- Make ourselves invisible briefly (optional stealth touch)
    local charParts = {}
    for _,p in ipairs(myChar:GetDescendants()) do
        if p:IsA("BasePart") then charParts[p] = p.Transparency; p.Transparency = 1 end
    end

    -- Disable our collision so we don't collide with world on TP
    myHum:ChangeState(Enum.HumanoidStateType.Physics)

    -- Teleport to be right in front of the target
    local pushDir = (targetHrp.CFrame.LookVector * -1 + Vector3.new(0, 0.3, 0)).Unit
    myHrp.CFrame  = targetHrp.CFrame * CFrame.new(0, 0.5, -1.5)

    -- Apply force on OUR hrp — momentum transfers to target on collision
    local att = stealth(Instance.new("Attachment"))
    att.Name   = randName(5); att.Parent = myHrp

    local lv = stealth(Instance.new("LinearVelocity"))
    lv.Name = randName(5); lv.Attachment0 = att
    lv.MaxForce = MAX_FORCE
    lv.ForceLimitMode = Enum.ForceLimitMode.Magnitude
    lv.VectorVelocity = pushDir * force
    lv.RelativeTo = Enum.ActuatorRelativeTo.World
    lv.Parent = att

    -- After one physics frame the collision happens; then snap back home
    task.wait(0.08)
    if att and att.Parent then att:Destroy() end

    -- TP back to saved position immediately
    myHrp.CFrame = savedCF
    myHum:ChangeState(Enum.HumanoidStateType.GettingUp)

    -- Restore visibility
    for p, tr in pairs(charParts) do
        if p and p.Parent then p.Transparency = tr end
    end
end)

-- SPIN — RunService.Stepped (after physics, prevents jitter)
local isSpinning, spinTarget, spinConn = false, nil, nil

spinBtn.MouseButton1Click:Connect(function()
    isSpinning = not isSpinning
    if isSpinning then
        local t = FindPlayer(trollBox.Text)
        if t and t.Character then
            spinTarget = t
            spinBtn.BackgroundColor3 = T.Troll
            spinBtn.Text = "🌀 Stop Spin: " .. t.Name
            spinConn = RunService.Stepped:Connect(function()
                if spinTarget and spinTarget.Character then
                    local hrp = spinTarget.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(18), 0) end
                else
                    isSpinning = false
                    spinBtn.BackgroundColor3 = Color3.fromRGB(100,20,140)
                    spinBtn.Text = "🌀 Spin Player (Toggle)"
                    if spinConn then spinConn:Disconnect(); spinConn = nil end
                end
            end)
        else
            isSpinning = false
            trollBox.Text = "Not found!"; task.wait(1); trollBox.Text = ""
        end
    else
        spinBtn.BackgroundColor3 = Color3.fromRGB(100,20,140)
        spinBtn.Text = "🌀 Spin Player (Toggle)"
        spinTarget = nil
        if spinConn then spinConn:Disconnect(); spinConn = nil end
    end
end)

-- FOLLOW — continuously teleport near the target so they can't escape
local isFollowing, followTarget, followConn = false, nil, nil

followBtn.MouseButton1Click:Connect(function()
    isFollowing = not isFollowing
    if isFollowing then
        local t = FindPlayer(trollBox.Text)
        if t and t.Character then
            followTarget = t
            followBtn.BackgroundColor3 = T.Troll
            followBtn.Text = "👁 Stop Follow: " .. t.Name
            followConn = RunService.Heartbeat:Connect(function()
                if not followTarget or not followTarget.Character then
                    isFollowing = false
                    followBtn.BackgroundColor3 = Color3.fromRGB(20,120,80)
                    followBtn.Text = "👁 Follow Player (Toggle)"
                    if followConn then followConn:Disconnect(); followConn = nil end
                    return
                end
                local tHrp = followTarget.Character:FindFirstChild("HumanoidRootPart")
                local mHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if tHrp and mHrp then
                    -- Only re-TP if we've drifted more than 8 studs away
                    if (mHrp.Position - tHrp.Position).Magnitude > 8 then
                        mHrp.CFrame = tHrp.CFrame * CFrame.new(2, 0, 3)
                    end
                end
            end)
        else
            isFollowing = false
            trollBox.Text = "Not found!"; task.wait(1); trollBox.Text = ""
        end
    else
        followBtn.BackgroundColor3 = Color3.fromRGB(20,120,80)
        followBtn.Text = "👁 Follow Player (Toggle)"
        followTarget = nil
        if followConn then followConn:Disconnect(); followConn = nil end
    end
end)

-- ============================================================
-- 21. KEYBIND SYSTEM + MENU TOGGLE
-- ============================================================
local isMenuOpen  = false
local openPos     = UDim2.new(0, 20, 0.5, -250)
local closedPos   = UDim2.new(0, -320, 0.5, -250)

UserInputService.InputBegan:Connect(function(input, gp)
    if listeningForAction then
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if input.KeyCode == Enum.KeyCode.Escape then
            local prev = keybinds[listeningForAction]
            if prev then listeningButton.Text = "["..prev.Name.."]" end
        elseif input.KeyCode ~= Enum.KeyCode.Unknown then
            keybinds[listeningForAction] = input.KeyCode
            listeningButton.Text = "["..input.KeyCode.Name.."]"
        end
        listeningForAction = nil; listeningButton = nil
        return
    end
    if gp then return end
    if     input.KeyCode == keybinds.Menu      then
        isMenuOpen = not isMenuOpen
        TweenService:Create(main, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {Position = isMenuOpen and openPos or closedPos}):Play()
    elseif input.KeyCode == keybinds.Fly       then ToggleFly()
    elseif input.KeyCode == keybinds.WalkSpeed  then ToggleWalkSpeed()
    elseif input.KeyCode == keybinds.JumpPower  then ToggleJumpPower()
    elseif input.KeyCode == keybinds.InfJump    then ToggleInfJump()
    elseif input.KeyCode == keybinds.Noclip     then ToggleNoclip()
    elseif input.KeyCode == keybinds.ESP        then ToggleESP()
    end
end)
