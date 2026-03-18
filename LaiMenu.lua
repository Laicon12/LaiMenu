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

-- FIX #4: randName — old version used sub(a,b) where a>b could return ""
-- Now uses string.char on byte values for guaranteed single-char output each iteration
-- Also ensures result is never empty by defaulting len to 8 and clamping to min 4
local function randName(len)
    len = math.max(4, len or 8)
    local bytes = {}
    local pool  = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    for _ = 1, len do
        local i = math.random(1, #pool)
        bytes[#bytes+1] = pool:sub(i, i)  -- sub(i,i) always returns exactly 1 char
    end
    local result = table.concat(bytes)
    -- Safety fallback: if result is somehow empty, return a hardcoded unique string
    return (result ~= "" and result) or ("fb"..tostring(math.random(1000,9999)))
end

-- Mark instance as non-archivable (invisible to serialize scans) and return it
local function stealth(inst)
    inst.Archivable = false
    return inst
end

local MAX_FORCE = 9e5  -- large but finite, avoids inf flags

-- ============================================================
-- FIX #6: Central connection registry
-- All RunService / event connections are stored here so that
-- Panic() and future cleanup can disconnect everything safely
-- without hunting through scattered locals.
-- ============================================================
local Connections = {}   -- key = string label, value = RBXScriptConnection

local function track(label, conn)
    -- If a connection under this label already exists, disconnect it first
    -- to prevent silent double-connections (memory leak source)
    if Connections[label] and Connections[label].Connected then
        Connections[label]:Disconnect()
    end
    Connections[label] = conn
    return conn
end

local function untrack(label)
    if Connections[label] then
        if Connections[label].Connected then Connections[label]:Disconnect() end
        Connections[label] = nil
    end
end

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

local infJumpBtn  = mkRow(cMain, "Infinite Jump",    "InfJump", 11)
local noclipBtn   = mkRow(cMain, "Toggle Noclip",    "Noclip",  12)
local espBtn      = mkRow(cMain, "Toggle ESP",       "ESP",     13)
local selfFrzBtn  = mkBtn(cMain, "🧊 Freeze Self",   T.ElemBG,  14)

-- ============================================================
-- SHARED: Player list factory — dùng cho cả TP và Troll tab
-- targetBox: TextBox sẽ được fill khi click
-- returns: { frame, btnTable, refresh() }
-- ============================================================
local function mkPlayerList(parent, targetBox, layoutOrder)
    local frame = stealth(Instance.new("Frame", parent))
    frame.Size = UDim2.new(0.9,0,0,110)
    frame.BackgroundColor3 = T.ElemBG
    frame.BorderSizePixel = 0
    frame.LayoutOrder = layoutOrder
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,6)

    local sf = stealth(Instance.new("ScrollingFrame", frame))
    sf.Size = UDim2.new(1,0,1,0)
    sf.BackgroundTransparency = 1; sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 3; sf.ScrollBarImageColor3 = T.AccentON
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.CanvasSize = UDim2.new(0,0,0,0)
    local ll = Instance.new("UIListLayout", sf)
    ll.Padding = UDim.new(0,2); ll.SortOrder = Enum.SortOrder.Name
    local pp = Instance.new("UIPadding", sf)
    pp.PaddingTop = UDim.new(0,4); pp.PaddingBottom = UDim.new(0,4)
    pp.PaddingLeft = UDim.new(0,4); pp.PaddingRight = UDim.new(0,4)

    local btns = {}

    local function refresh()
        for _,b in pairs(btns) do pcall(function() b:Destroy() end) end
        btns = {}
        for _,p in ipairs(Players:GetPlayers()) do
            if p ~= player then
                local b = stealth(Instance.new("TextButton", sf))
                b.Size = UDim2.new(1,-6,0,24)
                b.BackgroundColor3 = T.ElemHover
                b.TextColor3 = T.TextMain
                b.Font = Enum.Font.GothamSemibold
                b.TextSize = 12
                b.Text = p.DisplayName.." (@"..p.Name..")"
                b.TextXAlignment = Enum.TextXAlignment.Left
                b.BorderSizePixel = 0
                Instance.new("UICorner", b).CornerRadius = UDim.new(0,4)
                local pad = Instance.new("UIPadding", b)
                pad.PaddingLeft = UDim.new(0,6)
                b.MouseButton1Click:Connect(function()
                    targetBox.Text = p.Name
                    for _,ob in pairs(btns) do
                        ob.BackgroundColor3 = T.ElemHover
                        ob.TextColor3 = T.TextMain
                    end
                    b.BackgroundColor3 = T.AccentON
                    b.TextColor3 = Color3.fromRGB(20,20,25)
                end)
                btns[p.Name] = b
            end
        end
    end

    return frame, btns, refresh
end

-- Teleport
local tpBox = mkInput(cTP, "Player Name (ex: rob...)", 1)

-- Player list cho Teleport tab
local _, _, tpRefresh = mkPlayerList(cTP, tpBox, 2)
local tpRefreshBtn = mkBtn(cTP, "🔄 Refresh", T.ElemHover, 3)
tpRefreshBtn.MouseButton1Click:Connect(tpRefresh)

local tpInstant = mkBtn(cTP, "⚡ Instant Teleport", Color3.fromRGB(80,40,150), 4)
local tpDash    = mkBtn(cTP, "☄️ Dash Teleport",   Color3.fromRGB(200,90,40), 5)

-- Emotes
local emoteList = {"wave","point","dance","dance2","dance3","laugh","cheer","salute","stadium","tilt","shrug"}
local emoteBtns = {}
for i,n in ipairs(emoteList) do emoteBtns[n] = mkBtn(cEmotes, "▶ "..n, T.ElemBG, i) end

-- Troll
mkLabel(cTroll, "Target Player:", 1)
local trollBox = mkInput(cTroll, "Player Name (ex: rob...)", 2)

-- Player list cho Troll tab — dùng chung factory
local _, plrBtns, refreshPlayerList = mkPlayerList(cTroll, trollBox, 3)

local refreshBtn = mkBtn(cTroll, "🔄 Refresh Player List", T.ElemHover, 4)
refreshBtn.MouseButton1Click:Connect(refreshPlayerList)

-- Auto refresh cả hai list khi player join/leave
Players.PlayerAdded:Connect(function()
    task.wait(0.1); refreshPlayerList(); tpRefresh()
end)
Players.PlayerRemoving:Connect(function()
    task.wait(0.1); refreshPlayerList(); tpRefresh()
end)

-- Load lần đầu
refreshPlayerList(); tpRefresh()

mkLabel(cTroll, "─── Freeze ──────────────────", 5)
local freezeBtn    = mkBtn(cTroll, "🧊 Freeze Player",          Color3.fromRGB(30,90,160),  6)
local unfrzBtn     = mkBtn(cTroll, "🔥 Unfreeze Player",        Color3.fromRGB(160,70,20),  7)
mkLabel(cTroll, "─── Fling ───────────────────", 8)
local flingBtn     = mkBtn(cTroll, "💥 Fling Player",           Color3.fromRGB(180,30,50),  9)
mkLabel(cTroll, "─── Touch Fling ─────────────", 10)
local touchFlingBtn = mkBtn(cTroll, "👆 Touch Fling (Toggle)",  Color3.fromRGB(160,50,10),  11)
mkLabel(cTroll, "─── NaN Fling ───────────────", 12)
local nanFlingBtn   = mkBtn(cTroll, "☠️ NaN Fling (Toggle)",   Color3.fromRGB(80,0,0),     13)
mkLabel(cTroll, "─── Welder ──────────────────", 14)

-- Pose buttons row 1
local weldPoseFrame1 = stealth(Instance.new("Frame", cTroll))
weldPoseFrame1.Size = UDim2.new(0.9,0,0,30)
weldPoseFrame1.BackgroundTransparency = 1
weldPoseFrame1.LayoutOrder = 15
local weldLayout1 = Instance.new("UIListLayout", weldPoseFrame1)
weldLayout1.FillDirection = Enum.FillDirection.Horizontal
weldLayout1.Padding = UDim.new(0,4)
weldLayout1.SortOrder = Enum.SortOrder.LayoutOrder

-- Pose buttons row 2
local weldPoseFrame2 = stealth(Instance.new("Frame", cTroll))
weldPoseFrame2.Size = UDim2.new(0.9,0,0,30)
weldPoseFrame2.BackgroundTransparency = 1
weldPoseFrame2.LayoutOrder = 16
local weldLayout2 = Instance.new("UIListLayout", weldPoseFrame2)
weldLayout2.FillDirection = Enum.FillDirection.Horizontal
weldLayout2.Padding = UDim.new(0,4)
weldLayout2.SortOrder = Enum.SortOrder.LayoutOrder

local function mkPoseBtn(parent, text, order)
    local b = stealth(Instance.new("TextButton", parent))
    b.Size = UDim2.new(0,60,1,0)
    b.BackgroundColor3 = Color3.fromRGB(40,40,60)
    b.TextColor3 = T.TextMain
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.Text = text
    b.LayoutOrder = order
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,4)
    return b
end

-- Row 1: Bang, Stand, Attack, Headsit
local weldBangBtn    = mkPoseBtn(weldPoseFrame1, "💋 Bang",    1)
local weldStandBtn   = mkPoseBtn(weldPoseFrame1, "🧍 Stand",   2)
local weldAttackBtn  = mkPoseBtn(weldPoseFrame1, "⚔️ Attack", 3)
local weldHeadBtn    = mkPoseBtn(weldPoseFrame1, "👑 Head",    4)

-- Row 2: Backpack, Carpet, Behind, Custom
local weldBackBtn    = mkPoseBtn(weldPoseFrame2, "🎒 Back",    1)
local weldCarpetBtn  = mkPoseBtn(weldPoseFrame2, "🟫 Carpet",  2)
local weldBehindBtn  = mkPoseBtn(weldPoseFrame2, "🫷 Behind",  3)
local weldCustomBtn  = mkPoseBtn(weldPoseFrame2, "⚙️ Custom", 4)

-- Row 3: Push, Unweld
local weldPoseFrame3 = stealth(Instance.new("Frame", cTroll))
weldPoseFrame3.Size = UDim2.new(0.9,0,0,30)
weldPoseFrame3.BackgroundTransparency = 1
weldPoseFrame3.LayoutOrder = 17
local weldLayout3 = Instance.new("UIListLayout", weldPoseFrame3)
weldLayout3.FillDirection = Enum.FillDirection.Horizontal
weldLayout3.Padding = UDim.new(0,4)
weldLayout3.SortOrder = Enum.SortOrder.LayoutOrder

local weldPushBtn    = mkPoseBtn(weldPoseFrame3, "👊 Push",    1)
local weldUnweldBtn  = mkPoseBtn(weldPoseFrame3, "❌ Unweld",  2)
weldPushBtn.Size    = UDim2.new(0,90,1,0)
weldUnweldBtn.Size  = UDim2.new(0,90,1,0)
weldUnweldBtn.BackgroundColor3 = Color3.fromRGB(80,20,20)

mkLabel(cTroll, "─── Spin ────────────────────", 17)
local spinBtn      = mkBtn(cTroll, "🌀 Spin Player (Toggle)",   Color3.fromRGB(100,20,140), 18)
mkLabel(cTroll, "─── Follow ──────────────────", 19)
local followBtn    = mkBtn(cTroll, "👁 Follow Player (Toggle)",  Color3.fromRGB(20,120,80),  20)

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

-- Cached walk/jump values removed — see WalkSpeed section for why

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
-- 12. FLY — LinearVelocity + invisible platform dưới chân
-- Technique: Part vô hình theo sát dưới chân trong khi bay.
-- Server thấy FloorMaterial != Air → không flag airtime timer.
-- ============================================================
flyModeBtn.MouseButton1Click:Connect(function()
    currentFlyMode = currentFlyMode == "Camera" and "Hover" or "Camera"
    flyModeBtn.Text = currentFlyMode == "Camera" and "Fly Mode: Camera" or "Fly Mode: Hover (Space/Ctrl)"
end)

local flyPlatform = nil

local function StopFly()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyAttach and flyAttach.Parent then flyAttach:Destroy() end
    flyAttach, flyLV = nil, nil
    if flyPlatform and flyPlatform.Parent then
        flyPlatform:Destroy(); flyPlatform = nil
    end
    local hum = player.Character and player.Character:FindFirstChild("Humanoid")
    if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end) end
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

    -- Invisible platform — CanCollide true để server detect contact
    flyPlatform = stealth(Instance.new("Part"))
    flyPlatform.Name        = randName(6)
    flyPlatform.Size        = Vector3.new(4, 0.2, 4)
    flyPlatform.Transparency = 1
    flyPlatform.CanCollide  = true   -- QUAN TRỌNG: phải true
    flyPlatform.Anchored    = true   -- anchor để không bị physics kéo
    flyPlatform.CanTouch    = false
    flyPlatform.CastShadow  = false
    flyPlatform.Massless    = true
    flyPlatform.Parent      = workspace

    flyAttach = stealth(Instance.new("Attachment"))
    flyAttach.Name = randName(6); flyAttach.Parent = hrp

    flyLV = stealth(Instance.new("LinearVelocity"))
    flyLV.Name = randName(6); flyLV.Attachment0 = flyAttach
    flyLV.MaxForce = MAX_FORCE; flyLV.VectorVelocity = Vector3.zero
    flyLV.RelativeTo = Enum.ActuatorRelativeTo.World; flyLV.Parent = flyAttach

    local smooth = Vector3.zero

    flyConn = track("fly", RunService.RenderStepped:Connect(function(dt)
        pcall(function()
            local c  = player.Character
            local h2 = c and c:FindFirstChild("HumanoidRootPart")
            local hm = c and c:FindFirstChild("Humanoid")
            if not h2 or not hm or not flyAttach or not flyAttach.Parent then
                StopFly(); isFlying = false; setBtn(flyBtn, false); return
            end

            hm:ChangeState(Enum.HumanoidStateType.Physics)

            -- Cập nhật vị trí platform ngay dưới chân
            if flyPlatform and flyPlatform.Parent then
                flyPlatform.CFrame = CFrame.new(h2.Position - Vector3.new(0, 2.8, 0))
            end

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

            local look = camera.CFrame.LookVector
            local flat = Vector3.new(look.X, 0, look.Z)
            if flat.Magnitude > 0.01 then
                h2.CFrame = CFrame.new(h2.Position, h2.Position + flat)
            end
        end)
    end))
end

-- ============================================================
-- 13. WALKSPEED — simplified, direct write every Heartbeat
-- Throttle bị xoá vì có thể gây delay apply trên frame đầu tiên
-- ============================================================
local function applyWalk()
    local char = player.Character
    local hum  = char and char:FindFirstChild("Humanoid")
    if not hum then return end
    local v = tonumber(walkBox.Text)
    if not v or v <= 0 then v = 16 end
    v = math.clamp(v, 0, 500)
    -- Không dùng pcall ở đây để lỗi nổi ra ngoài nếu có
    hum.WalkSpeed = v
end

local function ToggleWalkSpeed()
    isWalk = not isWalk
    setBtn(walkBtn, isWalk)
    if isWalk then
        -- Disconnect cái cũ nếu còn tồn tại
        if walkConn then walkConn:Disconnect(); walkConn = nil end
        -- Apply ngay lập tức, không chờ frame đầu
        applyWalk()
        -- Sau đó giữ bằng Heartbeat
        walkConn = RunService.Heartbeat:Connect(applyWalk)
    else
        if walkConn then walkConn:Disconnect(); walkConn = nil end
        -- Restore về mặc định
        local hum = player.Character and player.Character:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end

-- ============================================================
-- 14. JUMPPOWER — tương tự, simplified
-- ============================================================
local function applyJump()
    local char = player.Character
    local hum  = char and char:FindFirstChild("Humanoid")
    if not hum then return end
    local v = tonumber(jumpBox.Text)
    if not v or v <= 0 then v = 50 end
    v = math.clamp(v, 0, 1000)
    hum.UseJumpPower = true
    hum.JumpPower    = v
end

local function ToggleJumpPower()
    isJump = not isJump
    setBtn(jumpBtn, isJump)
    if isJump then
        if jumpConn then jumpConn:Disconnect(); jumpConn = nil end
        applyJump()
        jumpConn = RunService.Heartbeat:Connect(applyJump)
    else
        if jumpConn then jumpConn:Disconnect(); jumpConn = nil end
        local hum = player.Character and player.Character:FindFirstChild("Humanoid")
        if hum then hum.UseJumpPower = true; hum.JumpPower = 50 end
    end
end

-- ============================================================
-- 15. INFINITE JUMP
-- ============================================================
local function ToggleInfJump()
    isInfJump = not isInfJump; setBtn(infJumpBtn, isInfJump)
    if isInfJump then
        infJumpConn = track("infJump", UserInputService.JumpRequest:Connect(function()
            local hum = player.Character and player.Character:FindFirstChild("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end))
    else
        untrack("infJump"); infJumpConn = nil
    end
end

-- ============================================================
-- 16. NOCLIP
-- FIX #2: Safe restore — only re-enables collision once the HRP
--         is confirmed not overlapping any world BasePart.
-- FIX #3: Cache character BaseParts once on enable instead of
--         calling GetDescendants() every Stepped frame (perf fix).
-- ============================================================
local noclipParts = {}  -- cached list, rebuilt on toggle

local function ToggleNoclip()
    isNoclip = not isNoclip; setBtn(noclipBtn, isNoclip)
    if isNoclip then
        -- FIX #3: build part cache once, refresh on CharacterAdded
        local char = player.Character
        noclipParts = {}
        if char then
            for _,p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then noclipParts[#noclipParts+1] = p end
            end
        end
        -- FIX #6: track() label "noclip"
        noclipConn = track("noclip", RunService.Stepped:Connect(function()
            -- FIX #3: iterate cached list — no GetDescendants each frame
            for _,p in ipairs(noclipParts) do
                if p and p.Parent then p.CanCollide = false end
            end
        end))
    else
        untrack("noclip"); noclipConn = nil

        -- FIX #2: Wait until HRP is no longer touching any BasePart before restoring
        -- Use task.spawn so we don't block the toggle call
        task.spawn(function()
            local char = player.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then
                -- No HRP — just restore immediately
                for _,p in ipairs(noclipParts) do
                    if p and p.Parent then p.CanCollide = true end
                end
                noclipParts = {}; return
            end

            -- Poll until HRP has no touching parts (max 2 seconds to avoid infinite wait)
            local timeout = tick() + 2
            repeat
                task.wait(0.05)
                local touching = hrp:GetTouchingParts()
                -- Filter out character own parts
                local worldTouch = false
                for _,tp in ipairs(touching) do
                    if not tp:IsDescendantOf(char) then worldTouch = true; break end
                end
                if not worldTouch then break end
            until tick() > timeout

            -- Now safe to restore — defer one extra frame for physics to settle
            task.defer(function()
                for _,p in ipairs(noclipParts) do
                    if p and p.Parent then p.CanCollide = true end
                end
                noclipParts = {}
            end)
        end)
    end
end

-- FIX #3: Rebuild noclip part cache when character respawns while noclip is on
player.CharacterAdded:Connect(function(char)
    if isNoclip then
        task.wait(0.1)
        noclipParts = {}
        for _,p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then noclipParts[#noclipParts+1] = p end
        end
    end
end)

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

    -- Highlight
    local hl = stealth(Instance.new("Highlight", espFolder))
    hl.Name = randName(6); hl.Adornee = char
    hl.FillColor = Color3.fromRGB(0,170,255); hl.OutlineColor = Color3.new(1,1,1)
    hl.FillTransparency = 0.5

    -- BillboardGui hiện tên trên đầu
    local head = char:FindFirstChild("Head")
    if head then
        local bb = stealth(Instance.new("BillboardGui"))
        bb.Name        = randName(6)
        bb.Adornee     = head
        bb.Size        = UDim2.new(0, 100, 0, 30)
        bb.StudsOffset = Vector3.new(0, 2.5, 0)  -- cao hơn đầu một chút
        bb.AlwaysOnTop = true                     -- hiện qua tường
        bb.ResetOnSpawn = false
        bb.Parent      = espFolder

        local lbl = Instance.new("TextLabel", bb)
        lbl.Size               = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text               = p.DisplayName  -- tên hiển thị
        lbl.TextColor3         = Color3.fromRGB(0, 200, 255)
        lbl.TextStrokeColor3   = Color3.new(0, 0, 0)
        lbl.TextStrokeTransparency = 0          -- viền đen cho dễ đọc
        lbl.Font               = Enum.Font.GothamBold
        lbl.TextSize           = 14
        lbl.TextScaled         = false
    end
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

-- ============================================================
-- SELF FREEZE — Anchor HRP của mình tại chỗ
-- Dùng để đứng yên hoàn toàn, không bị knockback hay đẩy
-- Kết hợp tốt với Welder hoặc khi muốn giữ vị trí cố định
-- ============================================================
local isSelfFrozen = false
local selfFrzConn  = nil
local selfFrzCF    = nil

local function ToggleSelfFreeze()
    isSelfFrozen = not isSelfFrozen
    setBtn(selfFrzBtn, isSelfFrozen)

    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChild("Humanoid")

    if isSelfFrozen then
        if not hrp then isSelfFrozen = false; setBtn(selfFrzBtn, false); return end

        selfFrzCF = hrp.CFrame  -- lưu vị trí hiện tại

        -- Zero velocity ngay lập tức
        hrp.AssemblyLinearVelocity  = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero

        -- Anchor HRP
        hrp.Anchored = true

        -- Disable humanoid movement
        if hum then
            hum.WalkSpeed = 0
            hum.JumpPower = 0
        end

        selfFrzBtn.Text = "🔥 Unfreeze Self"

        -- Heartbeat giữ frozen — một số game có thể unanchor từ server
        selfFrzConn = track("selfFreeze", RunService.Heartbeat:Connect(function()
            local c  = player.Character
            local h2 = c and c:FindFirstChild("HumanoidRootPart")
            if not h2 then return end
            h2.Anchored = true
            h2.AssemblyLinearVelocity  = Vector3.zero
            h2.AssemblyAngularVelocity = Vector3.zero
            -- Snap về vị trí frozen nếu bị move
            if (h2.Position - selfFrzCF.Position).Magnitude > 0.5 then
                h2.CFrame = selfFrzCF
            end
        end))
    else
        -- Unfreeze
        untrack("selfFreeze"); selfFrzConn = nil

        local hrp2 = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local hum2 = player.Character and player.Character:FindFirstChild("Humanoid")

        if hrp2 then hrp2.Anchored = false end
        if hum2 then
            -- Restore speed — dùng giá trị từ walkBox/jumpBox nếu đang bật
            hum2.WalkSpeed = isWalk and (tonumber(walkBox.Text) or 16) or 16
            hum2.JumpPower = isJump and (tonumber(jumpBox.Text) or 50) or 50
        end

        selfFrzCF = nil
        selfFrzBtn.Text = "🧊 Freeze Self"
    end
end

selfFrzBtn.MouseButton1Click:Connect(ToggleSelfFreeze)

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

-- FREEZE — Heartbeat CFrame lock
local freezeConn, frozenTarget, frozenCF = nil, nil, nil

freezeBtn.MouseButton1Click:Connect(function()
    -- FIX #5: nil-check target fully before proceeding
    local t = FindPlayer(trollBox.Text)
    if not (t and t.Character and t.Character:FindFirstChild("HumanoidRootPart")) then
        trollBox.Text = "Not found!"; task.wait(1); trollBox.Text = ""; return
    end
    untrack("freeze"); freezeConn = nil
    frozenTarget = t
    frozenCF     = t.Character.HumanoidRootPart.CFrame
    -- FIX #6: track()
    freezeConn = track("freeze", RunService.Heartbeat:Connect(function()
        if not frozenTarget or not frozenTarget.Character then
            untrack("freeze"); freezeConn = nil; return
        end
        local hrp = frozenTarget.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = frozenCF end
    end))
    freezeBtn.Text = "🧊 Frozen: " .. t.Name
end)

unfrzBtn.MouseButton1Click:Connect(function()
    untrack("freeze"); freezeConn = nil
    frozenTarget = nil; frozenCF = nil
    freezeBtn.Text = "🧊 Freeze Player"
end)

-- ============================================================
-- FLING — Velocity method (proven, reliable)
-- Dựa trên kỹ thuật zqyDSUWX: set Velocity + RotVelocity trực tiếp,
-- oscillate CFrame quanh target → momentum transfer → target bay.
-- Bấm lần 2 để dừng. Mình về OldPos sau khi xong.
-- ============================================================
local isFlingActive = false
local flingOldPos   = nil
local FPDH          = workspace.FallenPartsDestroyHeight

local function doFling(targetPlayer)
    local myChar = player.Character
    local myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
    local myHrp  = myHum and myHum.RootPart
    if not myChar or not myHum or not myHrp then return end

    local tChar  = targetPlayer.Character
    if not tChar then return end
    local tHum   = tChar:FindFirstChildOfClass("Humanoid")
    local tHrp   = tHum and tHum.RootPart
    local tHead  = tChar:FindFirstChild("Head")
    local acc    = tChar:FindFirstChildOfClass("Accessory")
    local handle = acc and acc:FindFirstChild("Handle")

    if myHrp.Velocity.Magnitude < 50 then
        flingOldPos = myHrp.CFrame
    end
    if tHum and tHum.Sit then return end
    if not tChar:FindFirstChildWhichIsA("BasePart") then return end

    if tHead then
        workspace.CurrentCamera.CameraSubject = tHead
    elseif tHum then
        workspace.CurrentCamera.CameraSubject = tHum
    end

    local function FPos(bp, pos, ang)
        myHrp.CFrame = CFrame.new(bp.Position) * pos * ang
        pcall(function() myChar:PivotTo(CFrame.new(bp.Position) * pos * ang) end)
        myHrp.Velocity    = Vector3.new(9e7, 9e7 * 10, 9e7)
        myHrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
    end

    local function SFBasePart(bp)
        local deadline = tick() + 2
        local angle    = 0
        repeat
            if not myHrp or not tHum then break end
            if bp.Velocity.Magnitude < 50 then
                angle = angle + 100
                local cf = CFrame.Angles(math.rad(angle), 0, 0)
                local mv = tHum.MoveDirection * bp.Velocity.Magnitude / 1.25
                FPos(bp, CFrame.new(0,  1.5, 0) + mv, cf); task.wait()
                FPos(bp, CFrame.new(0, -1.5, 0) + mv, cf); task.wait()
                FPos(bp, CFrame.new(0,  1.5, 0) + mv, cf); task.wait()
                FPos(bp, CFrame.new(0, -1.5, 0) + mv, cf); task.wait()
                FPos(bp, CFrame.new(0,  1.5, 0) + tHum.MoveDirection, cf); task.wait()
                FPos(bp, CFrame.new(0, -1.5, 0) + tHum.MoveDirection, cf); task.wait()
            else
                local ws = tHum.WalkSpeed
                FPos(bp, CFrame.new(0,  1.5,  ws), CFrame.Angles(math.rad(90),0,0)); task.wait()
                FPos(bp, CFrame.new(0, -1.5, -ws), CFrame.new());                    task.wait()
                FPos(bp, CFrame.new(0,  1.5,  ws), CFrame.Angles(math.rad(90),0,0)); task.wait()
                FPos(bp, CFrame.new(0, -1.5,  0),  CFrame.Angles(math.rad(90),0,0)); task.wait()
                FPos(bp, CFrame.new(0, -1.5,  0),  CFrame.new());                    task.wait()
                FPos(bp, CFrame.new(0, -1.5,  0),  CFrame.Angles(math.rad(90),0,0)); task.wait()
                FPos(bp, CFrame.new(0, -1.5,  0),  CFrame.new());                    task.wait()
            end
        until tick() > deadline or not isFlingActive
    end

    workspace.FallenPartsDestroyHeight = 0/0

    local bv = Instance.new("BodyVelocity")
    bv.Velocity  = Vector3.zero
    bv.MaxForce  = Vector3.new(9e9, 9e9, 9e9)
    bv.Parent    = myHrp

    myHum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

    if     tHrp   then SFBasePart(tHrp)
    elseif tHead  then SFBasePart(tHead)
    elseif handle then SFBasePart(handle) end

    bv:Destroy()
    myHum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    workspace.CurrentCamera.CameraSubject = myHum

    -- Restore vị trí cũ
    if flingOldPos then
        local tries = 0
        repeat
            tries = tries + 1
            myHrp.CFrame = flingOldPos * CFrame.new(0, 0.5, 0)
            pcall(function() myChar:PivotTo(flingOldPos * CFrame.new(0, 0.5, 0)) end)
            myHum:ChangeState(Enum.HumanoidStateType.GettingUp)
            for _,p in ipairs(myChar:GetChildren()) do
                if p:IsA("BasePart") then
                    p.Velocity = Vector3.zero; p.RotVelocity = Vector3.zero
                end
            end
            task.wait()
        until (myHrp.Position - flingOldPos.Position).Magnitude < 25 or tries > 60
        workspace.FallenPartsDestroyHeight = FPDH
    end
end

flingBtn.MouseButton1Click:Connect(function()
    -- Toggle: bấm lần 2 dừng
    if isFlingActive then
        isFlingActive = false
        flingBtn.Text = "💥 Fling Player"
        flingBtn.BackgroundColor3 = Color3.fromRGB(180,30,50)
        return
    end

    local t = FindPlayer(trollBox.Text)
    if not (t and t.Character and t.Character:FindFirstChild("HumanoidRootPart")) then
        trollBox.Text = "Not found!"; task.wait(1); trollBox.Text = ""; return
    end

    isFlingActive = true
    flingBtn.Text = "⏹ Stop Fling"
    flingBtn.BackgroundColor3 = Color3.fromRGB(80,80,80)

    task.spawn(function()
        while isFlingActive do
            pcall(doFling, t)
            task.wait(0.1)
        end
        flingBtn.Text = "💥 Fling Player"
        flingBtn.BackgroundColor3 = Color3.fromRGB(180,30,50)
    end)
end)

-- ============================================================
-- TOUCH FLING — Velocity multiplier method
-- Không cần chọn target — ai đứng gần đều bị fling.
-- Nhân velocity 10000x trong đúng 1 render frame → momentum
-- transfer sang người đứng cạnh → họ bay.
-- Mình không bị bay vì velocity reset ngay frame sau.
-- ============================================================
local isTouchFling = false
local touchFlingConn = nil

local function startTouchFling()
    local movel = 0.1
    touchFlingConn = track("touchFling", RunService.Heartbeat:Connect(function()
        local c   = player.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local vel = hrp.Velocity

        -- Frame 1: nhân velocity lên 10000x + upward kick
        hrp.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
        RunService.RenderStepped:Wait()

        -- Frame 2: reset về velocity cũ — mình không bay
        hrp.Velocity = vel
        RunService.Stepped:Wait()

        -- Frame 3: oscillate nhỏ để tạo liên tục micro-collision
        hrp.Velocity = vel + Vector3.new(0, movel, 0)
        movel = -movel  -- đổi chiều mỗi cycle
    end))
end

touchFlingBtn.MouseButton1Click:Connect(function()
    isTouchFling = not isTouchFling
    if isTouchFling then
        touchFlingBtn.BackgroundColor3 = T.Troll
        touchFlingBtn.TextColor3       = Color3.fromRGB(20,20,20)
        touchFlingBtn.Text = "👆 Touch Fling: ON"
        startTouchFling()
    else
        untrack("touchFling"); touchFlingConn = nil
        touchFlingBtn.BackgroundColor3 = Color3.fromRGB(160,50,10)
        touchFlingBtn.TextColor3       = T.TextMain
        touchFlingBtn.Text = "👆 Touch Fling (Toggle)"
    end
end)

-- ============================================================
-- ============================================================
-- NaN FLING — Not a Number velocity exploit
-- Set AssemblyLinearVelocity = NaN → physics engine không
-- tính được → propagate NaN sang target đang contact → void.
-- NaN bypass mọi velocity threshold vì NaN > mọi số.
-- sethiddenproperty (executor paid) = force physics assembly
-- share với target → NaN transfer trực tiếp, không cần contact.
-- Script tự detect executor có support hay không.
-- ============================================================
local isNanFling   = false
local nanFlingConn = nil
local nanFlingTarget = nil  -- nil = affect ai cũng được (area mode)

-- Detect sethiddenproperty — paid executor feature
local hasSHP = (typeof(sethiddenproperty) == "function")

-- Mode toggle: Area (ai đứng gần) hoặc Target (người cụ thể)
local nanMode    = "area"   -- "area" hoặc "target"
local nanModeBtn = mkBtn(cTroll, "Mode: Area (gần mình)", Color3.fromRGB(50,50,80), 13)
-- Chèn vào ngay sau nanFlingBtn — không cần layout order vì mkBtn tự set

nanModeBtn.LayoutOrder = 13
nanFlingBtn.LayoutOrder = 13  -- cùng section

-- Thực ra dùng label order riêng cho gọn:
nanModeBtn.LayoutOrder = 14
nanFlingBtn.LayoutOrder = 13

local function setNanMode(m)
    nanMode = m
    if m == "area" then
        nanModeBtn.Text = "Mode: Area (gần mình)"
        nanModeBtn.BackgroundColor3 = Color3.fromRGB(50,50,80)
    else
        nanModeBtn.Text = "Mode: Target (".. (trollBox.Text ~= "" and trollBox.Text or "chọn player") ..")"
        nanModeBtn.BackgroundColor3 = Color3.fromRGB(80,50,50)
    end
end

nanModeBtn.MouseButton1Click:Connect(function()
    if nanMode == "area" then
        setNanMode("target")
    else
        setNanMode("area")
    end
end)

local NAN_VEC = Vector3.new(0/0, 0/0, 0/0)

local function applyNanFling(targetHrp, myHrp, myHum)
    -- TP vào target
    myHrp.CFrame = targetHrp.CFrame

    -- Set NaN velocity — propagate ke target qua contact
    myHrp.AssemblyLinearVelocity  = NAN_VEC
    myHrp.AssemblyAngularVelocity = NAN_VEC

    -- PlatformStand để mình không bị physics kéo lúc NaN
    pcall(function() myHum.PlatformStand = true end)

    -- Move NaN — thêm một vector NaN vào movement
    pcall(function() myHum:Move(NAN_VEC) end)

    -- sethiddenproperty nếu executor support
    -- Buộc physics engine coi mình và target là cùng assembly
    -- → NaN transfer trực tiếp, không cần frame collision
    if hasSHP then
        pcall(function()
            sethiddenproperty(myHrp, "PhysicsRepRootPart", targetHrp)
        end)
    end
end

nanFlingBtn.MouseButton1Click:Connect(function()
    isNanFling = not isNanFling

    if isNanFling then
        -- Target mode: lấy player từ trollBox
        if nanMode == "target" then
            local t = FindPlayer(trollBox.Text)
            if not (t and t.Character and t.Character:FindFirstChild("HumanoidRootPart")) then
                trollBox.Text = "Not found!"; task.wait(1); trollBox.Text = ""
                isNanFling = false; return
            end
            nanFlingTarget = t
        end

        nanFlingBtn.BackgroundColor3 = T.Troll
        nanFlingBtn.TextColor3       = Color3.fromRGB(20,20,20)
        nanFlingBtn.Text = "☠️ NaN Fling: ON" .. (hasSHP and " [SHP]" or "")

        nanFlingConn = track("nanFling", RunService.Heartbeat:Connect(function()
            local myChar = player.Character
            local myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
            local myHrp  = myHum and myHum.RootPart
            if not myChar or not myHrp then return end

            if nanMode == "target" then
                -- Target mode: chỉ fling 1 người
                if not (nanFlingTarget and nanFlingTarget.Character) then
                    -- Target đã rời game, tự dừng
                    isNanFling = false
                    untrack("nanFling"); nanFlingConn = nil
                    nanFlingBtn.BackgroundColor3 = Color3.fromRGB(80,0,0)
                    nanFlingBtn.TextColor3       = T.TextMain
                    nanFlingBtn.Text = "☠️ NaN Fling (Toggle)"
                    pcall(function() myHum.PlatformStand = false end)
                    return
                end
                local tHrp = nanFlingTarget.Character:FindFirstChild("HumanoidRootPart")
                if tHrp then
                    applyNanFling(tHrp, myHrp, myHum)
                end
            else
                -- Area mode: fling tất cả player trong range 15 studs
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= player and p.Character then
                        local tHrp = p.Character:FindFirstChild("HumanoidRootPart")
                        if tHrp then
                            local dist = (myHrp.Position - tHrp.Position).Magnitude
                            if dist <= 15 then
                                applyNanFling(tHrp, myHrp, myHum)
                            end
                        end
                    end
                end
            end
        end))
    else
        -- Tắt
        untrack("nanFling"); nanFlingConn = nil
        nanFlingTarget = nil
        -- Restore PlatformStand
        local myHum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        pcall(function() if myHum then myHum.PlatformStand = false end end)
        nanFlingBtn.BackgroundColor3 = Color3.fromRGB(80,0,0)
        nanFlingBtn.TextColor3       = T.TextMain
        nanFlingBtn.Text = "☠️ NaN Fling (Toggle)"
    end
end)

-- ============================================================
-- ============================================================
-- WELDER — Weld mình vào target với các pose preset
-- Cơ chế: tạo Part lớn làm "anchor", mỗi frame set CFrame
-- của Part = target position, Root = Part + offset.
-- Kết quả: mình di chuyển theo target với pose cố định.
-- ============================================================
local currentWeld    = nil  -- weld object đang active
local weldThread     = nil  -- task thread của weld loop
local WELD_FPDH      = workspace.FallenPartsDestroyHeight

-- Collision group riêng để weld part không block mình
local WELD_GROUP = (function()
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local s = ""
    for _ = 1, 12 do s = s .. charset:sub(math.random(1,#charset),math.random(1,#charset)) end
    return s
end)()
pcall(function()
    local PS = game:GetService("PhysicsService")
    PS:RegisterCollisionGroup(WELD_GROUP)
    PS:CollisionGroupSetCollidable(WELD_GROUP, WELD_GROUP, true)
end)

-- Detect R15 vs R6
local function isR15(char)
    return char and char:FindFirstChild("UpperTorso") ~= nil
end

-- Preset poses: {offset CFrame, animId}
local WELD_POSES = {
    bang    = {CFrame.new(0, 0, 1.3),                                          148840371},
    stand   = {nil, nil},  -- set per rig below
    attack  = {nil, nil},
    headsit = {CFrame.new(0, 3, 0),                                            178130996},
    backpack= {CFrame.new(0, 0, 1.05) * CFrame.Angles(0, math.rad(180), 0),   178130996},
    carpet  = {CFrame.new(0, -1, 0),                                           282574440},
}

local function stopWeld()
    if weldThread then task.cancel(weldThread); weldThread = nil end
    if currentWeld then
        -- Restore weld part properties
        pcall(function()
            if currentWeld.part and currentWeld.part.Parent then
                currentWeld.part:Destroy()
            end
        end)
        -- Restore character collision
        local myChar = player.Character
        if myChar and currentWeld.oldCharProps then
            for part, props in pairs(currentWeld.oldCharProps) do
                pcall(function()
                    if part and part.Parent then
                        part.CollisionGroup = props.group
                        part.CanCollide     = props.collide
                    end
                end)
            end
        end
        -- Restore humanoid
        local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        if myHum then
            pcall(function() myHum.RequiresNeck = true end)
        end
        -- Stop anim
        if currentWeld.animTrack then
            pcall(function() currentWeld.animTrack:Stop() end)
        end
        currentWeld = nil
    end
    workspace.FallenPartsDestroyHeight = WELD_FPDH
    -- Update all pose buttons back to default
    for _,b in ipairs({weldBangBtn,weldStandBtn,weldAttackBtn,weldHeadBtn,weldBackBtn,weldCarpetBtn}) do
        b.BackgroundColor3 = Color3.fromRGB(40,40,60)
        b.TextColor3 = T.TextMain
    end
end

local function startWeld(targetPart, offset, animId)
    stopWeld()  -- cleanup any existing weld first

    local myChar = player.Character
    local myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
    local myRoot = myHum and myHum.RootPart
    if not myChar or not myRoot then return end

    workspace.FallenPartsDestroyHeight = 0/0

    -- Weld anchor part
    local weldPart = stealth(Instance.new("Part"))
    weldPart.Name        = randName(6)
    weldPart.Size        = Vector3.new(25, 3, 25)
    weldPart.Anchored    = false
    weldPart.CanCollide  = true
    weldPart.Transparency = 1
    weldPart.CastShadow  = false
    weldPart.CollisionGroup = WELD_GROUP
    weldPart.Parent      = workspace.Terrain

    -- Set character to same collision group
    local oldCharProps = {}
    for _,p in ipairs(myChar:GetDescendants()) do
        if p:IsA("BasePart") then
            oldCharProps[p] = {group = p.CollisionGroup, collide = p.CanCollide}
            p.CollisionGroup = WELD_GROUP
            p.CanCollide = true
        end
    end

    -- Disable neck requirement (prevent death from weird angles)
    pcall(function() myHum.RequiresNeck = false end)

    -- Play animation if provided
    local animTrack = nil
    if animId and animId ~= 0 then
        pcall(function()
            local animator = myChar:FindFirstChildWhichIsA("Animator", true)
            if animator then
                local anim = Instance.new("Animation")
                anim.AnimationId = "rbxassetid://" .. tostring(animId)
                animTrack = animator:LoadAnimation(anim)
                animTrack:Play()
            end
        end)
    end

    -- Store weld state
    currentWeld = {
        part         = weldPart,
        oldCharProps = oldCharProps,
        animTrack    = animTrack,
    }

    local startCF = CFrame.new(myRoot.Position)

    weldThread = task.spawn(function()
        while currentWeld do
            if not targetPart or not targetPart.Parent then
                stopWeld(); break
            end
            local tCF = targetPart.CFrame

            -- Frame A: anchor part at target, root at offset
            weldPart.CFrame = tCF
            myRoot.CFrame   = tCF * offset
            weldPart.AssemblyLinearVelocity  = Vector3.zero
            weldPart.AssemblyAngularVelocity = Vector3.zero
            myRoot.AssemblyLinearVelocity    = Vector3.zero
            myRoot.AssemblyAngularVelocity   = Vector3.zero

            RunService.RenderStepped:Wait()

            -- Frame B: slight vertical shift to maintain contact
            weldPart.CFrame = tCF
            myRoot.CFrame   = tCF * CFrame.new(0, 4, 0)
            weldPart.AssemblyLinearVelocity  = Vector3.zero
            weldPart.AssemblyAngularVelocity = Vector3.zero

            task.wait()
        end
    end)
end

local function weldToPose(poseName, activeBtn)
    local t = FindPlayer(trollBox.Text)
    if not (t and t.Character) then
        trollBox.Text = "Not found!"; task.wait(1); trollBox.Text = ""; return
    end

    local char  = t.Character
    local myChar = player.Character
    local tHum  = char:FindFirstChildOfClass("Humanoid")
    local tRoot = (tHum and tHum.RootPart)
        or char:FindFirstChild("UpperTorso")
        or char:FindFirstChild("Torso")
        or char:FindFirstChild("HumanoidRootPart")
    if not tRoot then return end

    local offset, animId

    if poseName == "bang" then
        -- Đứng thẳng vuông góc ngay trước mặt target
        -- Z âm = phía trước mặt target (LookVector)
        -- Xoay 180° để mình nhìn vào mặt target
        offset = CFrame.new(0, 0, -2) * CFrame.Angles(0, math.rad(180), 0)
        animId = 148840371
    elseif poseName == "behind" then
        -- Đứng sau lưng target, cùng hướng nhìn
        offset = CFrame.new(0, 0, 2)
        animId = 0
    elseif poseName == "stand" then
        if isR15(myChar) then
            offset = CFrame.new(1.8, 1.8, 2); animId = 96658788627102
        else
            offset = CFrame.new(1.5, 1.25, 2); animId = 313762630
        end
    elseif poseName == "attack" then
        local r180 = CFrame.Angles(0, math.rad(180), 0)
        if isR15(myChar) then
            offset = CFrame.new(0, 0.5, -2.55) * r180; animId = 117183737438245
        else
            offset = CFrame.new(0, 0, -1.25) * r180; animId = 259438880
        end
    elseif poseName == "headsit" then
        offset = CFrame.new(0, 3, 0); animId = 178130996
    elseif poseName == "backpack" then
        offset = CFrame.new(0, 0, 1.05) * CFrame.Angles(0, math.rad(180), 0); animId = 178130996
    elseif poseName == "carpet" then
        offset = CFrame.new(0, -1, 0); animId = 282574440
    end

    startWeld(tRoot, offset, animId)

    -- Highlight active button
    for _,b in ipairs({weldBangBtn,weldStandBtn,weldAttackBtn,weldHeadBtn,weldBackBtn,weldCarpetBtn}) do
        b.BackgroundColor3 = Color3.fromRGB(40,40,60)
        b.TextColor3 = T.TextMain
    end
    activeBtn.BackgroundColor3 = T.AccentON
    activeBtn.TextColor3 = Color3.fromRGB(20,20,25)
end

weldBangBtn.MouseButton1Click:Connect(function()   weldToPose("bang",    weldBangBtn)   end)
weldStandBtn.MouseButton1Click:Connect(function()  weldToPose("stand",   weldStandBtn)  end)
weldAttackBtn.MouseButton1Click:Connect(function() weldToPose("attack",  weldAttackBtn) end)
weldHeadBtn.MouseButton1Click:Connect(function()   weldToPose("headsit", weldHeadBtn)   end)
weldBackBtn.MouseButton1Click:Connect(function()   weldToPose("backpack",weldBackBtn)   end)
weldCarpetBtn.MouseButton1Click:Connect(function() weldToPose("carpet",  weldCarpetBtn) end)
weldBehindBtn.MouseButton1Click:Connect(function() weldToPose("behind",  weldBehindBtn) end)
weldUnweldBtn.MouseButton1Click:Connect(stopWeld)

-- PUSH — đẩy target liên tục ra phía trước
-- Dùng khi đang weld ở pose behind hoặc bang
-- Tăng dần velocity theo hướng target đang nhìn
local isPushing   = false
local pushConn2   = nil

weldPushBtn.MouseButton1Click:Connect(function()
    isPushing = not isPushing

    if isPushing then
        local t = FindPlayer(trollBox.Text)
        if not (t and t.Character and t.Character:FindFirstChild("HumanoidRootPart")) then
            trollBox.Text = "Not found!"; task.wait(1); trollBox.Text = ""
            isPushing = false; return
        end

        weldPushBtn.BackgroundColor3 = T.Troll
        weldPushBtn.TextColor3       = Color3.fromRGB(20,20,25)
        weldPushBtn.Text = "👊 Pushing..."

        local tHrp = t.Character.HumanoidRootPart
        local pushForce = 0

        pushConn2 = track("weldPush", RunService.Heartbeat:Connect(function()
            if not t.Character or not tHrp.Parent then
                isPushing = false
                untrack("weldPush"); pushConn2 = nil
                weldPushBtn.BackgroundColor3 = Color3.fromRGB(40,40,60)
                weldPushBtn.TextColor3 = T.TextMain
                weldPushBtn.Text = "👊 Push"
                return
            end

            -- Tăng lực đẩy theo thời gian (build up)
            pushForce = math.min(pushForce + 2, 80)

            -- Đẩy theo hướng target đang nhìn
            local pushDir = tHrp.CFrame.LookVector
            tHrp.AssemblyLinearVelocity = pushDir * pushForce

            -- Mình đứng sau lưng nếu đang weld
            local myHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if myHrp and currentWeld then
                myHrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, 1.5)
            end
        end))
    else
        untrack("weldPush"); pushConn2 = nil
        isPushing = false
        pushForce = 0
        weldPushBtn.BackgroundColor3 = Color3.fromRGB(40,40,60)
        weldPushBtn.TextColor3 = T.TextMain
        weldPushBtn.Text = "👊 Push"
    end
end)

-- Custom offset input via trollBox (x y z format)
weldCustomBtn.MouseButton1Click:Connect(function()
    local parts = trollBox.Text:split(" ")
    local x = tonumber(parts[2]) or 0
    local y = tonumber(parts[3]) or 0
    local z = tonumber(parts[4]) or 1.3
    local t2 = FindPlayer(parts[1])
    if not (t2 and t2.Character) then
        trollBox.Text = "Format: name x y z"; task.wait(1.5); trollBox.Text = ""; return
    end
    local tRoot2 = t2.Character:FindFirstChild("HumanoidRootPart")
    if tRoot2 then
        startWeld(tRoot2, CFrame.new(x, y, z), 0)
        weldCustomBtn.BackgroundColor3 = T.AccentON
    end
end)

-- ============================================================
-- SPIN — RunService.Stepped, FIX #6: track()
local isSpinning, spinTarget = false, nil

spinBtn.MouseButton1Click:Connect(function()
    isSpinning = not isSpinning
    if isSpinning then
        local t = FindPlayer(trollBox.Text)
        if t and t.Character then
            spinTarget = t
            spinBtn.BackgroundColor3 = T.Troll
            spinBtn.Text = "🌀 Stop Spin: " .. t.Name
            track("spin", RunService.Stepped:Connect(function()
                -- FIX #5: nil check inside loop
                if spinTarget and spinTarget.Character then
                    local hrp = spinTarget.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(18), 0) end
                else
                    isSpinning = false
                    spinBtn.BackgroundColor3 = Color3.fromRGB(100,20,140)
                    spinBtn.Text = "🌀 Spin Player (Toggle)"
                    untrack("spin")
                end
            end))
        else
            isSpinning = false
            trollBox.Text = "Not found!"; task.wait(1); trollBox.Text = ""
        end
    else
        spinBtn.BackgroundColor3 = Color3.fromRGB(100,20,140)
        spinBtn.Text = "🌀 Spin Player (Toggle)"
        spinTarget = nil; untrack("spin")
    end
end)

-- FOLLOW — FIX #6: track()
local isFollowing, followTarget = false, nil

followBtn.MouseButton1Click:Connect(function()
    isFollowing = not isFollowing
    if isFollowing then
        local t = FindPlayer(trollBox.Text)
        if t and t.Character then
            followTarget = t
            followBtn.BackgroundColor3 = T.Troll
            followBtn.Text = "👁 Stop Follow: " .. t.Name
            track("follow", RunService.Heartbeat:Connect(function()
                -- FIX #5: nil check
                if not followTarget or not followTarget.Character then
                    isFollowing = false
                    followBtn.BackgroundColor3 = Color3.fromRGB(20,120,80)
                    followBtn.Text = "👁 Follow Player (Toggle)"
                    untrack("follow"); return
                end
                local tHrp = followTarget.Character:FindFirstChild("HumanoidRootPart")
                local mHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if tHrp and mHrp then
                    if (mHrp.Position - tHrp.Position).Magnitude > 8 then
                        mHrp.CFrame = tHrp.CFrame * CFrame.new(2, 0, 3)
                    end
                end
            end))
        else
            isFollowing = false
            trollBox.Text = "Not found!"; task.wait(1); trollBox.Text = ""
        end
    else
        followBtn.BackgroundColor3 = Color3.fromRGB(20,120,80)
        followBtn.Text = "👁 Follow Player (Toggle)"
        followTarget = nil; untrack("follow")
    end
end)

-- ============================================================
-- FIX #7: PANIC SYSTEM
-- Stops ALL active features instantly.
-- Bound to RightShift by default — rebindable.
-- Call Panic() from anywhere to safely reset everything.
-- ============================================================
local function Panic()
    -- Disconnect every tracked connection
    for label,_ in pairs(Connections) do untrack(label) end

    -- Reset fly
    if isFlying then
        isFlying = false
        StopFly()
        setBtn(flyBtn, false)
    end

    -- Reset walk/jump
    if isWalk then
        isWalk = false; setBtn(walkBtn, false)
        local hum = player.Character and player.Character:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
    if isJump then
        isJump = false; setBtn(jumpBtn, false)
        local hum = player.Character and player.Character:FindFirstChild("Humanoid")
        if hum then hum.UseJumpPower = true; hum.JumpPower = 50 end
    end

    -- Reset inf jump
    if isInfJump then isInfJump = false; setBtn(infJumpBtn, false) end

    -- Reset noclip (restore collision immediately — in panic we skip intersection check)
    if isNoclip then
        isNoclip = false; setBtn(noclipBtn, false)
        for _,p in ipairs(noclipParts) do
            if p and p.Parent then p.CanCollide = true end
        end
        noclipParts = {}
    end

    -- Reset ESP
    if isESP then
        isESP = false; setBtn(espBtn, false)
        pcall(function() espFolder:ClearAllChildren() end)
    end

    -- Reset self freeze
    if isSelfFrozen then
        isSelfFrozen = false
        untrack("selfFreeze"); selfFrzConn = nil
        local hrp2 = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local hum2 = player.Character and player.Character:FindFirstChild("Humanoid")
        if hrp2 then hrp2.Anchored = false end
        if hum2 then hum2.WalkSpeed = 16; hum2.JumpPower = 50 end
        selfFrzCF = nil
        selfFrzBtn.Text = "🧊 Freeze Self"
        setBtn(selfFrzBtn, false)
    end

    -- Reset troll states
    freezeConn  = nil; frozenTarget = nil; frozenCF = nil
    freezeBtn.Text = "🧊 Freeze Player"
    isSpinning = false; spinTarget = nil
    spinBtn.BackgroundColor3 = Color3.fromRGB(100,20,140)
    spinBtn.Text = "🌀 Spin Player (Toggle)"
    isFollowing = false; followTarget = nil
    followBtn.BackgroundColor3 = Color3.fromRGB(20,120,80)
    followBtn.Text = "👁 Follow Player (Toggle)"
    -- Touch fling
    if isTouchFling then
        isTouchFling = false
        untrack("touchFling"); touchFlingConn = nil
        touchFlingBtn.BackgroundColor3 = Color3.fromRGB(160,50,10)
        touchFlingBtn.TextColor3       = T.TextMain
        touchFlingBtn.Text = "👆 Touch Fling (Toggle)"
    end
    -- NaN fling
    if isNanFling then
        isNanFling = false
        untrack("nanFling"); nanFlingConn = nil
        nanFlingTarget = nil
        local myHum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        pcall(function() if myHum then myHum.PlatformStand = false end end)
        nanFlingBtn.BackgroundColor3 = Color3.fromRGB(80,0,0)
        nanFlingBtn.TextColor3       = T.TextMain
        nanFlingBtn.Text = "☠️ NaN Fling (Toggle)"
    end
    -- Welder
    pcall(stopWeld)
    -- Push
    if isPushing then
        isPushing = false
        untrack("weldPush")
        weldPushBtn.BackgroundColor3 = Color3.fromRGB(40,40,60)
        weldPushBtn.TextColor3 = T.TextMain
        weldPushBtn.Text = "👊 Push"
    end

    -- Flash title red briefly as visual confirmation
    pcall(function()
        local orig = titleLbl.TextColor3
        titleLbl.Text = "⚠ PANIC — RESET"
        titleLbl.TextColor3 = T.Troll
        task.delay(1.5, function()
            titleLbl.Text = "LAI ADMIN"
            titleLbl.TextColor3 = orig
        end)
    end)
end

-- ============================================================
-- 21. KEYBIND SYSTEM + MENU TOGGLE
-- ============================================================
local isMenuOpen  = false
local openPos     = UDim2.new(0, 20, 0.5, -250)
local closedPos   = UDim2.new(0, -320, 0.5, -250)

-- FIX #6: track the input connection so Panic can disconnect it too
track("input", UserInputService.InputBegan:Connect(function(input, gp)
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

    -- FIX #7: RightShift = Panic (emergency stop all features)
    if input.KeyCode == Enum.KeyCode.RightShift then
        Panic(); return
    end

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
end))
