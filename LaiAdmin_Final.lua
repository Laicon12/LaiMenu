local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local mouse = player:GetMouse()

math.randomseed(math.floor(tick() * 1000) + math.floor(os.clock() * 1000))
local function randName(len)
    len = math.max(4, len or 8); local bytes = {}; local pool = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    for _ = 1, len do bytes[#bytes+1] = pool:sub(math.random(1, #pool), math.random(1, #pool)) end
    return table.concat(bytes)
end

local Connections = {}
local function track(label, conn) if Connections[label] and Connections[label].Connected then Connections[label]:Disconnect() end; Connections[label] = conn; return conn end
local function untrack(label) if Connections[label] then if Connections[label].Connected then Connections[label]:Disconnect() end; Connections[label] = nil end end

local keybinds = {
    Menu = Enum.KeyCode.Insert, Fly = Enum.KeyCode.C, WalkSpeed = Enum.KeyCode.V, SelfFreeze = Enum.KeyCode.B,
    JumpPower = Enum.KeyCode.Unknown, InfJump = Enum.KeyCode.Unknown, ESP = Enum.KeyCode.Unknown,
    Noclip = Enum.KeyCode.Unknown, Freeze = Enum.KeyCode.Unknown, FakeInvis = Enum.KeyCode.Unknown,
    AntiFling = Enum.KeyCode.Unknown, BypassAC = Enum.KeyCode.Unknown
}
local listeningForAction, listeningButton = nil, nil
local currentFlyMode = "Camera"
local ConfigName = "LaiAdmin_Config.json"

local T = {
    MainBG = Color3.fromRGB(10,11,15), ElemBG = Color3.fromRGB(20,21,28), ElemHover = Color3.fromRGB(28,30,40), ElemActive = Color3.fromRGB(18,40,65),
    AccentON = Color3.fromRGB(80,180,255), AccentDim = Color3.fromRGB(40,90,140), AccentLine = Color3.fromRGB(50,130,210),
    TextMain = Color3.fromRGB(240,242,248), TextSub = Color3.fromRGB(120,128,155), TextDim = Color3.fromRGB(70,75,100),
    Border = Color3.fromRGB(30,32,45), Troll = Color3.fromRGB(255,65,85), Warn = Color3.fromRGB(255,180,50)
}

-- ============================================================
-- GUI SETUP (SMART SECURE INJECTION)
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Name = randName(16)
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local function getSecureContainer()
    -- 1. gethui() - Vùng chứa ẩn tuyệt đối của Executor xịn
    if type(gethui) == "function" then
        local s, ui = pcall(gethui)
        if s and ui then return ui end
    end
    -- 2. CoreGui với cloneref (Nhân bản CoreGui để giấu)
    if type(cloneref) == "function" then
        local s, core = pcall(function() return cloneref(game:GetService("CoreGui")) end)
        if s and core then return core end
    end
    -- 3. CoreGui gốc (Vẫn an toàn hơn PlayerGui rất nhiều)
    local s, core = pcall(function() return game:GetService("CoreGui") end)
    if s and core then return core end
    -- 4. Đường cùng mới dùng PlayerGui
    return player:WaitForChild("PlayerGui")
end

-- API Bảo vệ GUI khỏi các luồng quét của Anti-cheat
pcall(function()
    if syn and syn.protect_gui then
        syn.protect_gui(gui)
    elseif type(protectgui) == "function" then
        protectgui(gui)
    elseif type(protect_gui) == "function" then
        protect_gui(gui)
    end
end)

-- Gắn GUI vào vùng an toàn nhất
gui.Parent = getSecureContainer()

local shadow = Instance.new("Frame", gui); shadow.Size = UDim2.new(0, 292, 0, 512); shadow.BackgroundColor3 = Color3.fromRGB(0,0,0); shadow.BackgroundTransparency = 0.55; shadow.BorderSizePixel = 0; Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 14)
local main = Instance.new("Frame", gui); main.Size = UDim2.new(0, 280, 0, 500); main.BackgroundColor3 = T.MainBG; main.BackgroundTransparency = 0.08; main.BorderSizePixel = 0; Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

local isMenuOpen = true
local openPos = UDim2.new(0, 20,  0.5, -250)
local closedPos = UDim2.new(0, -320, 0.5, -250)
local openShadow = UDim2.new(0, 14,  0.5, -253)
local closedShadow = UDim2.new(0, -326, 0.5, -253)
main.Position = openPos; shadow.Position = openShadow

local outerStroke = Instance.new("UIStroke", main); outerStroke.Color = T.Border; outerStroke.Thickness = 1
local accentBar = Instance.new("Frame", main); accentBar.Size = UDim2.new(1, -24, 0, 1); accentBar.Position = UDim2.new(0, 12, 0, 0); accentBar.BackgroundColor3 = T.AccentLine; accentBar.BackgroundTransparency = 0.3; accentBar.BorderSizePixel = 0
local titleF = Instance.new("Frame", main); titleF.Size = UDim2.new(1, 0, 0, 44); titleF.BackgroundTransparency = 1; titleF.BorderSizePixel = 0
local titleDot = Instance.new("Frame", titleF); titleDot.Size = UDim2.new(0, 6, 0, 6); titleDot.Position = UDim2.new(0, 14, 0.5, -3); titleDot.BackgroundColor3 = T.AccentON; titleDot.BorderSizePixel = 0; Instance.new("UICorner", titleDot).CornerRadius = UDim.new(1, 0)
local titleLbl = Instance.new("TextLabel", titleF); titleLbl.Size = UDim2.new(0, 140, 1, 0); titleLbl.Position = UDim2.new(0, 26, 0, 0); titleLbl.BackgroundTransparency = 1; titleLbl.Text = "LAI ADMIN"; titleLbl.TextColor3 = T.TextMain; titleLbl.Font = Enum.Font.GothamBlack; titleLbl.TextSize = 13; titleLbl.TextXAlignment = Enum.TextXAlignment.Left
local titleSub = Instance.new("TextLabel", titleF); titleSub.Size = UDim2.new(0, 100, 1, 0); titleSub.Position = UDim2.new(0, 112, 0, 0); titleSub.BackgroundTransparency = 1; titleSub.Text = "v3.5"; titleSub.TextColor3 = T.TextDim; titleSub.Font = Enum.Font.Gotham; titleSub.TextSize = 11; titleSub.TextXAlignment = Enum.TextXAlignment.Left
local menuBindBtn = Instance.new("TextButton", titleF); menuBindBtn.Size = UDim2.new(0, 44, 0, 22); menuBindBtn.Position = UDim2.new(1, -54, 0.5, -11); menuBindBtn.BackgroundColor3 = T.ElemBG; menuBindBtn.TextColor3 = T.AccentON; menuBindBtn.Font = Enum.Font.GothamBold; menuBindBtn.TextSize = 10; menuBindBtn.Text = keybinds.Menu.Name; menuBindBtn.BorderSizePixel = 0; Instance.new("UICorner", menuBindBtn).CornerRadius = UDim.new(0, 4); Instance.new("UIStroke", menuBindBtn).Color = T.AccentDim
local titleSep = Instance.new("Frame", main); titleSep.Size = UDim2.new(1, -20, 0, 1); titleSep.Position = UDim2.new(0, 10, 0, 44); titleSep.BackgroundColor3 = T.Border; titleSep.BorderSizePixel = 0

local dragging, dragStart, startPos = false, nil, nil
titleF.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = input.Position; startPos = main.Position end end)
UserInputService.InputChanged:Connect(function(input) if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then local delta = input.Position - dragStart; local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y); main.Position = newPos; shadow.Position = UDim2.new(newPos.X.Scale, newPos.X.Offset - 6, newPos.Y.Scale, newPos.Y.Offset - 3) end end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

local tabBar = Instance.new("Frame", main); tabBar.Size = UDim2.new(1, 0, 0, 34); tabBar.Position = UDim2.new(0, 0, 0, 46); tabBar.BackgroundTransparency = 1
local tabLine = Instance.new("Frame", tabBar); tabLine.Size = UDim2.new(1, -20, 0, 1); tabLine.Position = UDim2.new(0, 10, 1, -1); tabLine.BackgroundColor3 = T.Border; tabLine.BorderSizePixel = 0
local tabIndicator = Instance.new("Frame", tabBar); tabIndicator.Size = UDim2.new(0.25, -10, 0, 2); tabIndicator.Position = UDim2.new(0, 5, 1, -2); tabIndicator.BackgroundColor3 = T.AccentON; tabIndicator.BorderSizePixel = 0; Instance.new("UICorner", tabIndicator).CornerRadius = UDim.new(1, 0)
local function mkTab(text, x, col) local b = Instance.new("TextButton", tabBar); b.Size = UDim2.new(0.25, 0, 1, -2); b.Position = UDim2.new(x, 0, 0, 0); b.BackgroundTransparency = 1; b.Text = text; b.TextColor3 = col or T.TextSub; b.Font = Enum.Font.GothamSemibold; b.TextSize = 11; return b end
local tabMain = mkTab("Main", 0, T.TextMain); local tabTP = mkTab("TP", 0.25); local tabEmotes = mkTab("Emotes", 0.50); local tabTroll = mkTab("Troll", 0.75, T.Troll)

local function mkContainer(visible)
    local sf = Instance.new("ScrollingFrame", main); sf.Size = UDim2.new(1, 0, 1, -82); sf.Position = UDim2.new(0, 0, 0, 82); sf.BackgroundTransparency = 1; sf.BorderSizePixel = 0; sf.ScrollBarThickness = 2; sf.ScrollBarImageColor3 = T.AccentDim; sf.Visible = visible; sf.AutomaticCanvasSize = Enum.AutomaticSize.Y; sf.CanvasSize = UDim2.new(0, 0, 0, 0)
    local l = Instance.new("UIListLayout", sf); l.Padding = UDim.new(0, 6); l.HorizontalAlignment = Enum.HorizontalAlignment.Center; l.SortOrder = Enum.SortOrder.LayoutOrder
    local p = Instance.new("UIPadding", sf); p.PaddingTop = UDim.new(0, 8); p.PaddingBottom = UDim.new(0, 12); return sf
end
local cMain = mkContainer(true); local cTP = mkContainer(false); local cEmotes = mkContainer(false); local cTroll = mkContainer(false)

local updateBindTexts = {}
local function stroke(obj, col, thick) local s = Instance.new("UIStroke", obj); s.Color = col or T.Border; s.Thickness = thick or 1 end
local function mkRow(parent, text, action, order)
    local row = Instance.new("Frame", parent); row.Size = UDim2.new(0.92,0,0,30); row.BackgroundTransparency = 1; row.LayoutOrder = order
    local tog = Instance.new("TextButton", row); tog.Size = UDim2.new(1,-50,1,0); tog.BackgroundColor3 = T.ElemBG; tog.TextColor3 = T.TextMain; tog.Font = Enum.Font.GothamSemibold; tog.TextSize = 12; tog.Text = text; tog.BorderSizePixel = 0; Instance.new("UICorner", tog).CornerRadius = UDim.new(0,6); stroke(tog)
    local bind = Instance.new("TextButton", row); bind.Size = UDim2.new(0,44,1,0); bind.Position = UDim2.new(1,-44,0,0); bind.BackgroundColor3 = T.ElemBG; bind.TextColor3 = T.AccentON; bind.Font = Enum.Font.GothamBold; bind.TextSize = 10; bind.BorderSizePixel = 0; Instance.new("UICorner", bind).CornerRadius = UDim.new(0,6); stroke(bind, T.AccentDim)
    local function updateBindText() local kb = keybinds[action]; bind.Text = (kb and kb ~= Enum.KeyCode.Unknown) and kb.Name or "-" end
    updateBindTexts[action] = updateBindText; updateBindText()
    bind.MouseButton1Click:Connect(function() listeningForAction = action; listeningButton = bind; bind.Text = "..."; bind.TextColor3 = T.Warn end); return tog
end
local function mkInput(parent, ph, order) local b = Instance.new("TextBox", parent); b.Size = UDim2.new(0.92,0,0,28); b.BackgroundColor3 = T.ElemBG; b.TextColor3 = T.AccentON; b.Font = Enum.Font.GothamBold; b.TextSize = 12; b.LayoutOrder = order; b.PlaceholderText = ph; b.PlaceholderColor3 = T.TextDim; b.Text = ""; b.BorderSizePixel = 0; Instance.new("UICorner", b).CornerRadius = UDim.new(0,6); stroke(b); return b end
local function mkBtn(parent, text, bg, order) local b = Instance.new("TextButton", parent); b.Size = UDim2.new(0.92,0,0,30); b.BackgroundColor3 = bg or T.ElemBG; b.TextColor3 = T.TextMain; b.Font = Enum.Font.GothamSemibold; b.TextSize = 12; b.Text = text; b.LayoutOrder = order; b.BorderSizePixel = 0; Instance.new("UICorner", b).CornerRadius = UDim.new(0,6); stroke(b); return b end
local function mkPresets(parent, label, vals, box, order)
    local row = Instance.new("Frame", parent); row.Size = UDim2.new(0.92,0,0,22); row.BackgroundTransparency = 1; row.LayoutOrder = order
    local lbl = Instance.new("TextLabel", row); lbl.Size = UDim2.new(0.28,0,1,0); lbl.BackgroundTransparency = 1; lbl.Text = label; lbl.TextColor3 = T.TextDim; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 10; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local w = 0.72/#vals
    for i,v in ipairs(vals) do
        local b = Instance.new("TextButton", row); b.Size = UDim2.new(w,-3,1,0); b.Position = UDim2.new(0.28+w*(i-1),2,0,0); b.BackgroundColor3 = T.ElemBG; b.TextColor3 = T.TextSub; b.Font = Enum.Font.GothamBold; b.TextSize = 10; b.Text = tostring(v); b.BorderSizePixel = 0; Instance.new("UICorner", b).CornerRadius = UDim.new(0,4); stroke(b)
        b.MouseButton1Click:Connect(function() box.Text = tostring(v); b.TextColor3 = T.AccentON; task.delay(0.3, function() b.TextColor3 = T.TextSub end) end)
    end
end
local function mkLabel(parent, text, order) local l = Instance.new("TextLabel", parent); l.Size = UDim2.new(0.92,0,0,16); l.BackgroundTransparency = 1; l.Text = text; l.TextColor3 = T.TextDim; l.Font = Enum.Font.GothamSemibold; l.TextSize = 10; l.TextXAlignment = Enum.TextXAlignment.Left; l.LayoutOrder = order; return l end

local flyBtn = mkRow(cMain, "Toggle Fly", "Fly", 1); local flyModeBtn = mkBtn(cMain, "Fly Mode: Camera", T.ElemBG, 2); local flySpeedBox = mkInput(cMain, "Fly Speed (Def: 50)", 3); flySpeedBox.Text = "50"; mkPresets(cMain, "Speed:", {50, 100, 300}, flySpeedBox, 4)
local walkBtn = mkRow(cMain, "Toggle WalkSpeed", "WalkSpeed", 5); local walkBox = mkInput(cMain, "Walk Speed (Def: 16)", 6); walkBox.Text = "16"; mkPresets(cMain, "Speed:", {16, 50, 100}, walkBox, 7)
local jumpBtn = mkRow(cMain, "Toggle JumpPower", "JumpPower", 8); local jumpBox = mkInput(cMain, "Jump Power (Def: 50)", 9); jumpBox.Text = "50"; mkPresets(cMain, "Power:", {50, 100, 250}, jumpBox, 10)
local infJumpBtn = mkRow(cMain, "Infinite Jump", "InfJump", 11); local noclipBtn = mkRow(cMain, "Toggle Noclip", "Noclip", 12); local espBtn = mkRow(cMain, "Toggle Box ESP", "ESP", 13); local selfFrzBtn = mkRow(cMain, "🧊 Freeze Self", "SelfFreeze", 14)
local fakeInvisBtn = mkRow(cMain, "👻 Toggle Fake Invis", "FakeInvis", 15); local fakeInvisBox = mkInput(cMain, "Invis Offset (Def: 7)", 16); fakeInvisBox.Text = "7"
local antiFlingBtn = mkRow(cMain, "🛡️ Toggle Anti-Fling", "AntiFling", 17)
local bypassAcBtn  = mkRow(cMain, "🪝 Bypass Walk/Jump AC", "BypassAC", 18)
local saveCfgBtn   = mkBtn(cMain, "💾 Save Config", Color3.fromRGB(40,100,60), 19)

local function mkPlayerList(parent, targetBox, layoutOrder)
    local wrap = Instance.new("Frame", parent); wrap.Size = UDim2.new(0.9,0,0,135); wrap.BackgroundTransparency = 1; wrap.LayoutOrder = layoutOrder
    local sBox = mkInput(wrap, "🔍 Search Player...", 1); sBox.Size = UDim2.new(1,0,0,22); sBox.Position = UDim2.new(0,0,0,0)
    local frame = Instance.new("Frame", wrap); frame.Size = UDim2.new(1,0,1,-26); frame.Position = UDim2.new(0,0,0,26); frame.BackgroundColor3 = T.ElemBG; frame.BorderSizePixel = 0; Instance.new("UICorner", frame).CornerRadius = UDim.new(0,6)
    local sf = Instance.new("ScrollingFrame", frame); sf.Size = UDim2.new(1,0,1,0); sf.BackgroundTransparency = 1; sf.BorderSizePixel = 0; sf.ScrollBarThickness = 3; sf.ScrollBarImageColor3 = T.AccentON; sf.AutomaticCanvasSize = Enum.AutomaticSize.Y; sf.CanvasSize = UDim2.new(0,0,0,0)
    local ll = Instance.new("UIListLayout", sf); ll.Padding = UDim.new(0,2); ll.SortOrder = Enum.SortOrder.Name
    local pp = Instance.new("UIPadding", sf); pp.PaddingTop = UDim.new(0,4); pp.PaddingBottom = UDim.new(0,4); pp.PaddingLeft = UDim.new(0,4); pp.PaddingRight = UDim.new(0,4)
    local btns = {}
    local function refresh()
        for _,b in pairs(btns) do pcall(function() b:Destroy() end) end; btns = {}
        for _,p in ipairs(Players:GetPlayers()) do
            if p ~= player then
                local b = Instance.new("TextButton", sf); b.Size = UDim2.new(1,-6,0,24); b.BackgroundColor3 = T.ElemHover; b.TextColor3 = T.TextMain; b.Font = Enum.Font.GothamSemibold; b.TextSize = 12; b.Text = p.DisplayName.." (@"..p.Name..")"; b.TextXAlignment = Enum.TextXAlignment.Left; b.BorderSizePixel = 0; Instance.new("UICorner", b).CornerRadius = UDim.new(0,4); local pad = Instance.new("UIPadding", b); pad.PaddingLeft = UDim.new(0,6)
                b.MouseButton1Click:Connect(function() targetBox.Text = p.Name; for _,ob in pairs(btns) do ob.BackgroundColor3 = T.ElemHover; ob.TextColor3 = T.TextMain end; b.BackgroundColor3 = T.AccentON; b.TextColor3 = Color3.fromRGB(20,20,25) end); btns[p.Name] = b
            end
        end
    end
    sBox:GetPropertyChangedSignal("Text"):Connect(function()
        local txt = sBox.Text:lower()
        for _,b in pairs(btns) do b.Visible = (txt == "" or string.find(b.Text:lower(), txt) ~= nil) end
    end)
    return wrap, btns, refresh
end

local tpBox = mkInput(cTP, "Player Name (ex: rob...)", 1)
local _, _, tpRefresh = mkPlayerList(cTP, tpBox, 2)
local tpRefreshBtn = mkBtn(cTP, "🔄 Refresh", T.ElemHover, 3); tpRefreshBtn.MouseButton1Click:Connect(tpRefresh)
local tpInstant = mkBtn(cTP, "⚡ Instant Teleport", Color3.fromRGB(80,40,150), 4)
local tpDash    = mkBtn(cTP, "☄️ Dash Teleport",   Color3.fromRGB(200,90,40), 5)
local mouseTpBtn = mkBtn(cTP, "🖱️ Ctrl+Click TP Tween (Toggle)", Color3.fromRGB(40,150,100), 6)
local mouseTpSpeedBox = mkInput(cTP, "Tween Speed (Studs/s) (Def: 150)", 7); mouseTpSpeedBox.Text = "150"; mkPresets(cTP, "Speed:", {100, 150, 300}, mouseTpSpeedBox, 8)

local emoteList = {"wave","point","dance","dance2","dance3","laugh","cheer","salute","stadium","tilt","shrug"}; local emoteBtns = {}
for i,n in ipairs(emoteList) do emoteBtns[n] = mkBtn(cEmotes, "▶ "..n, T.ElemBG, i) end

mkLabel(cTroll, "Target Player:", 1)
local trollBox = mkInput(cTroll, "Player Name (ex: rob...)", 2)
local _, _, refreshPlayerList = mkPlayerList(cTroll, trollBox, 3)
local refreshBtn = mkBtn(cTroll, "🔄 Refresh Player List", T.ElemHover, 4); refreshBtn.MouseButton1Click:Connect(refreshPlayerList)
Players.PlayerAdded:Connect(function() task.wait(0.1); refreshPlayerList(); tpRefresh() end); Players.PlayerRemoving:Connect(function() task.wait(0.1); refreshPlayerList(); tpRefresh() end); refreshPlayerList(); tpRefresh()

mkLabel(cTroll, "─── Freeze & Fling ──────────", 5)
local freezeBtn = mkRow(cTroll, "🧊 Freeze Player", "Freeze", 6); local unfrzBtn = mkBtn(cTroll, "🔥 Unfreeze Player", Color3.fromRGB(160,70,20), 7)
local modernFlingBtn = mkBtn(cTroll, "⚙️ Modern Fling: OFF", Color3.fromRGB(60,60,80), 8)
local flingBtn = mkBtn(cTroll, "💥 Fling Player", Color3.fromRGB(180,30,50), 9)
local touchFlingBtn = mkBtn(cTroll, "👆 Touch Fling (Toggle)", Color3.fromRGB(160,50,10), 10)
mkLabel(cTroll, "─── NaN Fling ───────────────", 11)
local nanModeBtn = mkBtn(cTroll, "Mode: Area (gần mình)", Color3.fromRGB(50,50,80), 12); local nanFlingBtn = mkBtn(cTroll, "☠️ NaN Fling (Toggle)", Color3.fromRGB(80,0,0), 13)
mkLabel(cTroll, "─── Welder ──────────────────", 14)

local function mkPoseFrame(order) local f = Instance.new("Frame", cTroll); f.Size = UDim2.new(0.9,0,0,30); f.BackgroundTransparency = 1; f.LayoutOrder = order; local l = Instance.new("UIListLayout", f); l.FillDirection = Enum.FillDirection.Horizontal; l.Padding = UDim.new(0,4); l.SortOrder = Enum.SortOrder.LayoutOrder; return f end
local function mkPoseBtn(parent, text, order) local b = Instance.new("TextButton", parent); b.Size = UDim2.new(0,60,1,0); b.BackgroundColor3 = Color3.fromRGB(40,40,60); b.TextColor3 = T.TextMain; b.Font = Enum.Font.GothamBold; b.TextSize = 11; b.Text = text; b.LayoutOrder = order; Instance.new("UICorner", b).CornerRadius = UDim.new(0,4); return b end

local weldPoseFrame1 = mkPoseFrame(15); local weldBangBtn = mkPoseBtn(weldPoseFrame1,"💋 Bang",1); local weldStandBtn = mkPoseBtn(weldPoseFrame1,"🧍 Stand",2); local weldAttackBtn = mkPoseBtn(weldPoseFrame1,"⚔️ Attack",3); local weldHeadBtn = mkPoseBtn(weldPoseFrame1,"👑 Head",4)
local weldPoseFrame2 = mkPoseFrame(16); local weldBackBtn = mkPoseBtn(weldPoseFrame2,"🎒 Back",1); local weldCarpetBtn = mkPoseBtn(weldPoseFrame2,"🟫 Carpet",2); local weldBehindBtn = mkPoseBtn(weldPoseFrame2,"🫷 Behind",3); local weldCustomBtn = mkPoseBtn(weldPoseFrame2,"⚙️ Custom",4)
local weldPoseFrame3 = mkPoseFrame(17); local weldPushBtn = mkPoseBtn(weldPoseFrame3,"👊 Push",1); local weldUnweldBtn = mkPoseBtn(weldPoseFrame3,"❌ Unweld",2); weldPushBtn.Size = UDim2.new(0,90,1,0); weldUnweldBtn.Size = UDim2.new(0,90,1,0); weldUnweldBtn.BackgroundColor3 = Color3.fromRGB(80,20,20)

mkLabel(cTroll, "─── Misc ────────────────────", 18)
local spinBtn = mkBtn(cTroll, "🌀 Spin Player (Toggle)", Color3.fromRGB(100,20,140), 19); local followBtn = mkBtn(cTroll, "👁 Follow Player (Toggle)", Color3.fromRGB(20,120,80), 20)

local tabs = {{btn=tabMain,c=cMain,x=0}, {btn=tabTP,c=cTP,x=0.25}, {btn=tabEmotes,c=cEmotes,x=0.50}, {btn=tabTroll,c=cTroll,x=0.75}}
local function switchTab(ab, ac, ax)
    for _,t in ipairs(tabs) do t.c.Visible = false; t.btn.BackgroundTransparency = 1; t.btn.TextColor3 = (t.btn == tabTroll) and Color3.fromRGB(180,50,65) or T.TextDim; t.btn.Font = Enum.Font.GothamSemibold end
    ac.Visible = true; ab.TextColor3 = (ab == tabTroll) and T.Troll or T.TextMain; ab.Font = Enum.Font.GothamBold; tabIndicator.Position = UDim2.new(ax, 5, 1, -2); tabIndicator.Size = UDim2.new(0.25, -10, 0, 2); tabIndicator.BackgroundColor3 = (ab == tabTroll) and T.Troll or T.AccentON
end
for _,t in ipairs(tabs) do local tt = t; t.btn.MouseButton1Click:Connect(function() switchTab(tt.btn, tt.c, tt.x) end) end; switchTab(tabMain, cMain, 0)

-- ============================================================
-- CONFIG & CORE LOGIC
-- ============================================================
local function LoadConfig()
    local ok, err = pcall(function()
        if not isfile or not isfile(ConfigName) then return end
        local raw = readfile(ConfigName)
        if not raw or raw == "" then return end
        local s, cfg = pcall(function() return HttpService:JSONDecode(raw) end)
        if s and cfg then
            if cfg.Keybinds then for k, v in pairs(cfg.Keybinds) do if keybinds[k] then pcall(function() keybinds[k] = Enum.KeyCode[v]; if updateBindTexts[k] then updateBindTexts[k]() end end) end end end
            if cfg.WalkSpeed then walkBox.Text = cfg.WalkSpeed end; if cfg.JumpPower then jumpBox.Text = cfg.JumpPower end; if cfg.FlySpeed then flySpeedBox.Text = cfg.FlySpeed end; if cfg.MouseTPSpeed then mouseTpSpeedBox.Text = cfg.MouseTPSpeed end; if cfg.FakeInvisOffset then fakeInvisBox.Text = cfg.FakeInvisOffset end
        end
    end)
end
saveCfgBtn.MouseButton1Click:Connect(function()
    local ok, err = pcall(function()
        if not writefile then error("No writefile") end
        local cfg = {Keybinds = {}, WalkSpeed = walkBox.Text, JumpPower = jumpBox.Text, FlySpeed = flySpeedBox.Text, MouseTPSpeed = mouseTpSpeedBox.Text, FakeInvisOffset = fakeInvisBox.Text}
        for k, v in pairs(keybinds) do cfg.Keybinds[k] = v.Name end
        writefile(ConfigName, HttpService:JSONEncode(cfg))
    end)
    saveCfgBtn.Text = ok and "✅ Saved!" or "❌ Not Supported"; task.delay(1.5, function() saveCfgBtn.Text = "💾 Save Config" end)
end)
LoadConfig()

local isFlying, isWalk, isJump, isInfJump, isNoclip, isESP = false, false, false, false, false, false
local flyAttach, flyLV; local flyConn, walkConn, jumpConn, infJumpConn, noclipConn
local function setBtn(btn, on) btn.BackgroundColor3 = on and T.AccentON or T.ElemBG; btn.TextColor3 = on and Color3.fromRGB(25,25,30) or T.TextMain end
local function FindPlayer(partial) if not partial or partial == "" then return nil end; local low = partial:lower(); for _,p in ipairs(Players:GetPlayers()) do if p ~= player then if p.Name:lower():sub(1,#low) == low or p.DisplayName:lower():sub(1,#low) == low then return p end end end end
local function SafeTP(hrp, cf) task.wait(0.05 + math.random()*0.08); hrp.CFrame = cf * CFrame.new((math.random()-0.5)*1.5, 0, 3+(math.random()-0.5)*1.5) end
tpInstant.MouseButton1Click:Connect(function() local t = FindPlayer(tpBox.Text); if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then local h = player.Character and player.Character:FindFirstChild("HumanoidRootPart"); if h then SafeTP(h, t.Character.HumanoidRootPart.CFrame) end else tpBox.Text="Not found!"; task.wait(1); tpBox.Text="" end end)
tpDash.MouseButton1Click:Connect(function() local t = FindPlayer(tpBox.Text); if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then local h = player.Character and player.Character:FindFirstChild("HumanoidRootPart"); if h then local d = (h.Position - t.Character.HumanoidRootPart.Position).Magnitude; TweenService:Create(h, TweenInfo.new(math.clamp(d/150,0.3,3), Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = t.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,3)}):Play() end else tpBox.Text="Not found!"; task.wait(1); tpBox.Text="" end end)

flyModeBtn.MouseButton1Click:Connect(function() currentFlyMode = currentFlyMode == "Camera" and "Hover" or "Camera"; flyModeBtn.Text = currentFlyMode == "Camera" and "Fly Mode: Camera" or "Fly Mode: Hover (Space/Ctrl)" end)
local function StopFly() if flyConn then flyConn:Disconnect(); flyConn = nil end; if flyAttach and flyAttach.Parent then flyAttach:Destroy() end; flyAttach, flyLV = nil, nil; local char = player.Character; if char then for _,p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CollisionGroup = "Default" end) end end end; local hum = player.Character and player.Character:FindFirstChild("Humanoid"); if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end) end end
local function ToggleFly() local char = player.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); local hum = char and char:FindFirstChild("Humanoid"); if not hrp or not hum then return end; isFlying = not isFlying; setBtn(flyBtn, isFlying); if not isFlying then StopFly(); return end; hum:ChangeState(Enum.HumanoidStateType.Physics); flyAttach = Instance.new("Attachment"); flyAttach.Name = randName(6); flyAttach.Parent = hrp; flyLV = Instance.new("LinearVelocity"); flyLV.Name = randName(6); flyLV.Attachment0 = flyAttach; flyLV.MaxForce = 9e5; flyLV.VectorVelocity = Vector3.zero; flyLV.RelativeTo = Enum.ActuatorRelativeTo.World; flyLV.Parent = flyAttach; local smooth = Vector3.zero; flyConn = track("fly", RunService.RenderStepped:Connect(function(dt) pcall(function() local c = player.Character; local h2 = c and c:FindFirstChild("HumanoidRootPart"); local hm = c and c:FindFirstChild("Humanoid"); if not h2 or not hm or not flyAttach or not flyAttach.Parent then StopFly(); isFlying = false; setBtn(flyBtn, false); return end; hm:ChangeState(Enum.HumanoidStateType.Physics); local dir = Vector3.zero; if currentFlyMode == "Camera" then if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += camera.CFrame.LookVector end; if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= camera.CFrame.LookVector end; if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= camera.CFrame.RightVector end; if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += camera.CFrame.RightVector end else local fwd = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z); local rgt = Vector3.new(camera.CFrame.RightVector.X,0, camera.CFrame.RightVector.Z); fwd = fwd.Magnitude > 0.01 and fwd.Unit or Vector3.zero; rgt = rgt.Magnitude > 0.01 and rgt.Unit or Vector3.zero; if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += fwd end; if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= fwd end; if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= rgt end; if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += rgt end; if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end; if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis end end; local spd = tonumber(flySpeedBox.Text) or 50; smooth = smooth:Lerp(dir.Magnitude > 0 and dir.Unit * spd or Vector3.zero, math.min(1, dt*10)); flyLV.VectorVelocity = smooth; local look = camera.CFrame.LookVector; local flat = Vector3.new(look.X, 0, look.Z); if flat.Magnitude > 0.01 then h2.CFrame = CFrame.new(h2.Position, h2.Position + flat) end end) end)) end
local function applyWalk() local char = player.Character; local hum = char and char:FindFirstChild("Humanoid"); if not hum then return end; local v = tonumber(walkBox.Text); if not v or v <= 0 then v = 16 end; hum.WalkSpeed = math.clamp(v, 0, 500) end
local function ToggleWalkSpeed() isWalk = not isWalk; setBtn(walkBtn, isWalk); if isWalk then if walkConn then walkConn:Disconnect(); walkConn = nil end; applyWalk(); walkConn = RunService.Heartbeat:Connect(applyWalk) else if walkConn then walkConn:Disconnect(); walkConn = nil end; local hum = player.Character and player.Character:FindFirstChild("Humanoid"); if hum then hum.WalkSpeed = 16 end end end
local function applyJump() local char = player.Character; local hum = char and char:FindFirstChild("Humanoid"); if not hum then return end; local v = tonumber(jumpBox.Text); if not v or v <= 0 then v = 50 end; hum.UseJumpPower = true; hum.JumpPower = math.clamp(v, 0, 1000) end
local function ToggleJumpPower() isJump = not isJump; setBtn(jumpBtn, isJump); if isJump then if jumpConn then jumpConn:Disconnect(); jumpConn = nil end; applyJump(); jumpConn = RunService.Heartbeat:Connect(applyJump) else if jumpConn then jumpConn:Disconnect(); jumpConn = nil end; local hum = player.Character and player.Character:FindFirstChild("Humanoid"); if hum then hum.UseJumpPower = true; hum.JumpPower = 50 end end end
local function ToggleInfJump() isInfJump = not isInfJump; setBtn(infJumpBtn, isInfJump); if isInfJump then infJumpConn = track("infJump", UserInputService.JumpRequest:Connect(function() local hum = player.Character and player.Character:FindFirstChild("Humanoid"); if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end end)) else untrack("infJump"); infJumpConn = nil end end
local noclipParts = {}
local function ToggleNoclip() isNoclip = not isNoclip; setBtn(noclipBtn, isNoclip); if isNoclip then local char = player.Character; noclipParts = {}; if char then for _,p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then noclipParts[#noclipParts+1] = p end end end; noclipConn = track("noclip", RunService.Stepped:Connect(function() for _,p in ipairs(noclipParts) do if p and p.Parent then p.CanCollide = false end end end)) else untrack("noclip"); noclipConn = nil; task.spawn(function() local char = player.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); if not hrp then for _,p in ipairs(noclipParts) do if p and p.Parent then p.CanCollide = true end end; noclipParts = {}; return end; local timeout = tick() + 2; repeat task.wait(0.05); local touching = hrp:GetTouchingParts(); local worldTouch = false; for _,tp in ipairs(touching) do if not tp:IsDescendantOf(char) then worldTouch = true; break end end; if not worldTouch then break end until tick() > timeout; task.defer(function() for _,p in ipairs(noclipParts) do if p and p.Parent then p.CanCollide = true end end; noclipParts = {} end) end) end end

local espFolder = Instance.new("Folder"); espFolder.Name = randName(8); espFolder.Parent = camera
local function addESP(p)
    if p == player then return end; local char = p.Character; if not char then return end
    for _,h in ipairs(espFolder:GetChildren()) do if h.Name == p.Name then return end end
    local hrp = char:WaitForChild("HumanoidRootPart", 2)
    if hrp then
        local box = Instance.new("BoxHandleAdornment", espFolder); box.Name = p.Name; box.Adornee = hrp; box.Size = Vector3.new(4, 5.5, 2); box.ZIndex = 0; box.AlwaysOnTop = true; box.Color3 = Color3.fromRGB(0,170,255); box.Transparency = 0.65; box.ZIndex = 1
        local bb = Instance.new("BillboardGui", espFolder); bb.Name = p.Name.."_BB"; bb.Adornee = hrp; bb.Size = UDim2.new(0, 100, 0, 30); bb.StudsOffset = Vector3.new(0, 3.5, 0); bb.AlwaysOnTop = true; bb.ResetOnSpawn = false
        local lbl = Instance.new("TextLabel", bb); lbl.Size = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency = 1; lbl.Text = p.DisplayName; lbl.TextColor3 = Color3.fromRGB(0, 200, 255); lbl.TextStrokeColor3 = Color3.new(0, 0, 0); lbl.TextStrokeTransparency = 0; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 13; lbl.TextScaled = false
    end
end
local function removeESP(p) for _,h in ipairs(espFolder:GetChildren()) do if h.Name == p.Name or h.Name == p.Name.."_BB" then h:Destroy() end end end
local espPlayerAdded, espPlayerRemoving, espCharAdded = {}, {}, {}
local function ToggleESP() isESP = not isESP; setBtn(espBtn, isESP); if isESP then for _,p in ipairs(Players:GetPlayers()) do addESP(p) end; espPlayerAdded.conn = Players.PlayerAdded:Connect(function(p) espCharAdded[p] = p.CharacterAdded:Connect(function() task.wait(0.1); addESP(p) end); addESP(p) end); espPlayerRemoving.conn = Players.PlayerRemoving:Connect(removeESP); for _,p in ipairs(Players:GetPlayers()) do if p ~= player then espCharAdded[p] = p.CharacterAdded:Connect(function() task.wait(0.1); addESP(p) end) end end else espFolder:ClearAllChildren(); if espPlayerAdded.conn then espPlayerAdded.conn:Disconnect() end; if espPlayerRemoving.conn then espPlayerRemoving.conn:Disconnect() end; for _,c in pairs(espCharAdded) do c:Disconnect() end; espCharAdded = {} end end

local isBypassAC = false; local oldIndex
local function ToggleBypassAC()
    if not hookmetamethod then bypassAcBtn.Text = "❌ Executor Not Supported"; task.wait(2); bypassAcBtn.Text = "🪝 Bypass Walk/Jump AC"; return end
    isBypassAC = not isBypassAC; setBtn(bypassAcBtn, isBypassAC)
    if isBypassAC and not oldIndex then
        oldIndex = hookmetamethod(game, "__index", function(t, k)
            if not checkcaller() and isBypassAC and t:IsA("Humanoid") then if k == "WalkSpeed" then return 16 end; if k == "JumpPower" then return 50 end end
            return oldIndex(t, k)
        end)
    end
end
bypassAcBtn.MouseButton1Click:Connect(ToggleBypassAC)

local isSelfFrozen = false; local selfFrzConn = nil; local selfFrzCF = nil
local function ToggleSelfFreeze() isSelfFrozen = not isSelfFrozen; setBtn(selfFrzBtn, isSelfFrozen); local char = player.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); local hum = char and char:FindFirstChild("Humanoid"); if isSelfFrozen then if not hrp then isSelfFrozen = false; setBtn(selfFrzBtn, false); return end; selfFrzCF = hrp.CFrame; hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero; hrp.Anchored = true; if hum then hum.WalkSpeed = 0; hum.JumpPower = 0 end; selfFrzBtn.Text = "🔥 Unfreeze Self"; selfFrzConn = track("selfFreeze", RunService.Heartbeat:Connect(function() local c = player.Character; local h2 = c and c:FindFirstChild("HumanoidRootPart"); if not h2 then return end; h2.Anchored = true; h2.AssemblyLinearVelocity = Vector3.zero; h2.AssemblyAngularVelocity = Vector3.zero; if (h2.Position - selfFrzCF.Position).Magnitude > 0.5 then h2.CFrame = selfFrzCF end end)) else untrack("selfFreeze"); selfFrzConn = nil; local hrp2 = player.Character and player.Character:FindFirstChild("HumanoidRootPart"); local hum2 = player.Character and player.Character:FindFirstChild("Humanoid"); if hrp2 then hrp2.Anchored = false end; if hum2 then hum2.WalkSpeed = isWalk and (tonumber(walkBox.Text) or 16) or 16; hum2.JumpPower = isJump and (tonumber(jumpBox.Text) or 50) or 50 end; selfFrzCF = nil; selfFrzBtn.Text = "🧊 Freeze Self" end end

player.CharacterAdded:Connect(function(char)
    task.wait(0.3); if isWalk then applyWalk() end; if isJump then applyJump() end; if isFlying then StopFly(); isFlying = false; task.wait(0.15); ToggleFly() end
    if isNoclip then task.wait(0.1); noclipParts = {}; for _,p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then noclipParts[#noclipParts+1] = p end end end
    if isFakeInvis then isFakeInvis = false; untrack("fakeInvisSim"); RunService:UnbindFromRenderStep("FakeInvis_Cam"); task.wait(0.1); ToggleFakeInvis() end
end)

flyBtn.MouseButton1Click:Connect(ToggleFly); walkBtn.MouseButton1Click:Connect(ToggleWalkSpeed); jumpBtn.MouseButton1Click:Connect(ToggleJumpPower); infJumpBtn.MouseButton1Click:Connect(ToggleInfJump); noclipBtn.MouseButton1Click:Connect(ToggleNoclip); espBtn.MouseButton1Click:Connect(ToggleESP); selfFrzBtn.MouseButton1Click:Connect(ToggleSelfFreeze)
menuBindBtn.MouseButton1Click:Connect(function() listeningForAction = "Menu"; listeningButton = menuBindBtn; menuBindBtn.Text = "..." end)
for name,btn in pairs(emoteBtns) do btn.MouseButton1Click:Connect(function() local char = player.Character; if char and char:FindFirstChild("Animate") then local pe = char.Animate:FindFirstChild("PlayEmote"); if pe and pe:IsA("BindableFunction") then pe:Invoke(name); btn.BackgroundColor3 = T.AccentON; task.delay(0.4, function() btn.BackgroundColor3 = T.ElemBG end) end end end) end

local isAntiFling = false
local function ToggleAntiFling() isAntiFling = not isAntiFling; setBtn(antiFlingBtn, isAntiFling); if isAntiFling then track("antiFling", RunService.Stepped:Connect(function() local char = player.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); if hrp then if hrp.AssemblyLinearVelocity.Magnitude > 250 or hrp.AssemblyAngularVelocity.Magnitude > 50 then hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero end end; for _, p in ipairs(Players:GetPlayers()) do if p ~= player and p.Character then for _, part in ipairs(p.Character:GetDescendants()) do if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end end end end end)) else untrack("antiFling") end end
antiFlingBtn.MouseButton1Click:Connect(ToggleAntiFling)

local isFakeInvis = false; local fakeInvisRot90 = CFrame.Angles(math.rad(90), 0, 0); local fakeInvisOldCF = CFrame.new()
local function ToggleFakeInvis() isFakeInvis = not isFakeInvis; setBtn(fakeInvisBtn, isFakeInvis); local char = player.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); if isFakeInvis then if hrp then fakeInvisOldCF = hrp.CFrame end; RunService:BindToRenderStep("FakeInvis_Cam", Enum.RenderPriority.Camera.Value - 1, function() local currHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart"); if currHrp then currHrp.CFrame = fakeInvisOldCF end end); track("fakeInvisSim", RunService.PostSimulation:Connect(function() local currHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart"); if currHrp then fakeInvisOldCF = currHrp.CFrame; local offsetVal = tonumber(fakeInvisBox.Text) or 7; currHrp.CFrame = CFrame.new(currHrp.Position - Vector3.new(0, offsetVal, 0)) * fakeInvisRot90 end end)) else RunService:UnbindFromRenderStep("FakeInvis_Cam"); untrack("fakeInvisSim"); local currHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart"); if currHrp then currHrp.CFrame = fakeInvisOldCF end end end
fakeInvisBtn.MouseButton1Click:Connect(ToggleFakeInvis)

local isMouseTween = false
local function ToggleMouseTween() isMouseTween = not isMouseTween; if isMouseTween then mouseTpBtn.BackgroundColor3 = T.AccentON; mouseTpBtn.TextColor3 = Color3.fromRGB(20,20,20); mouseTpBtn.Text = "🖱️ Mouse TP: Hold Ctrl + Click!"; track("mouseTween", UserInputService.InputBegan:Connect(function(input, gp) if gp then return end; if input.UserInputType == Enum.UserInputType.MouseButton1 then if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then local char = player.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); if hrp and mouse.Hit then local hitPos = mouse.Hit; local targetCFrame = CFrame.new(hitPos.X, hitPos.Y + 3, hitPos.Z, select(4, hrp.CFrame:components())); local speed = tonumber(mouseTpSpeedBox.Text) or 150; if speed <= 0 then speed = 150 end; local dist = (hrp.Position - hitPos.Position).Magnitude; TweenService:Create(hrp, TweenInfo.new(dist / speed, Enum.EasingStyle.Linear), {CFrame = targetCFrame}):Play() end end end end)) else untrack("mouseTween"); mouseTpBtn.BackgroundColor3 = Color3.fromRGB(40,150,100); mouseTpBtn.TextColor3 = T.TextMain; mouseTpBtn.Text = "🖱️ Ctrl+Click TP Tween (Toggle)" end end
mouseTpBtn.MouseButton1Click:Connect(ToggleMouseTween)

local freezeConn, frozenTarget, frozenCF = nil, nil, nil
freezeBtn.MouseButton1Click:Connect(function() local t = FindPlayer(trollBox.Text); if not (t and t.Character and t.Character:FindFirstChild("HumanoidRootPart")) then trollBox.Text = "Not found!"; task.wait(1); trollBox.Text = ""; return end; untrack("freeze"); freezeConn = nil; frozenTarget = t; frozenCF = t.Character.HumanoidRootPart.CFrame; freezeConn = track("freeze", RunService.Heartbeat:Connect(function() if not frozenTarget or not frozenTarget.Character then untrack("freeze"); freezeConn = nil; return end; local hrp = frozenTarget.Character:FindFirstChild("HumanoidRootPart"); if hrp then hrp.CFrame = frozenCF end end)); freezeBtn.Text = "🧊 Frozen: " .. t.Name end)
unfrzBtn.MouseButton1Click:Connect(function() untrack("freeze"); freezeConn = nil; frozenTarget = nil; frozenCF = nil; freezeBtn.Text = "🧊 Freeze Player" end)

local isModernFling = false
modernFlingBtn.MouseButton1Click:Connect(function() isModernFling = not isModernFling; modernFlingBtn.BackgroundColor3 = isModernFling and Color3.fromRGB(80,100,200) or Color3.fromRGB(60,60,80); modernFlingBtn.Text = isModernFling and "⚙️ Modern Fling: ON" or "⚙️ Modern Fling: OFF" end)

local isFlingActive = false; local flingOldPos = nil; local FPDH = workspace.FallenPartsDestroyHeight
local function doFling(targetPlayer)
    local myChar = player.Character; local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid"); local myHrp = myHum and myHum.RootPart; if not myChar or not myHum or not myHrp then return end
    local tChar = targetPlayer.Character; if not tChar then return end; local tHum = tChar:FindFirstChildOfClass("Humanoid"); local tHrp = tHum and tHum.RootPart; local tHead = tChar:FindFirstChild("Head"); local acc = tChar:FindFirstChildOfClass("Accessory"); local handle = acc and acc:FindFirstChild("Handle")
    if myHrp.Velocity.Magnitude < 50 then flingOldPos = myHrp.CFrame end; if tHum and tHum.Sit then return end; if not tChar:FindFirstChildWhichIsA("BasePart") then return end
    if tHead then workspace.CurrentCamera.CameraSubject = tHead elseif tHum then workspace.CurrentCamera.CameraSubject = tHum end

    local mover = nil; if isModernFling then mover = Instance.new("Attachment", myHrp); local lv = Instance.new("LinearVelocity", mover); lv.Attachment0 = mover; lv.MaxForce = math.huge; lv.VectorVelocity = Vector3.new(9e7, 9e7 * 10, 9e7); local av = Instance.new("AngularVelocity", mover); av.Attachment0 = mover; av.MaxTorque = math.huge; av.AngularVelocity = Vector3.new(9e8, 9e8, 9e8) else mover = Instance.new("BodyVelocity", myHrp); mover.Velocity = Vector3.zero; mover.MaxForce = Vector3.new(9e9, 9e9, 9e9) end
    local function FPos(bp, pos, ang) myHrp.CFrame = CFrame.new(bp.Position) * pos * ang; pcall(function() myChar:PivotTo(CFrame.new(bp.Position) * pos * ang) end); if not isModernFling then myHrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7); myHrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8) end end
    local function SFBasePart(bp)
        local deadline = tick() + 2; local angle = 0; repeat if not myHrp or not tHum then break end; if bp.Velocity.Magnitude < 50 then angle = angle + 100; local cf = CFrame.Angles(math.rad(angle), 0, 0); local mv = tHum.MoveDirection * bp.Velocity.Magnitude / 1.25; FPos(bp, CFrame.new(0,  1.5, 0) + mv, cf); task.wait(); FPos(bp, CFrame.new(0, -1.5, 0) + mv, cf); task.wait(); FPos(bp, CFrame.new(0,  1.5, 0) + mv, cf); task.wait(); FPos(bp, CFrame.new(0, -1.5, 0) + mv, cf); task.wait(); FPos(bp, CFrame.new(0,  1.5, 0) + tHum.MoveDirection, cf); task.wait(); FPos(bp, CFrame.new(0, -1.5, 0) + tHum.MoveDirection, cf); task.wait() else local ws = tHum.WalkSpeed; FPos(bp, CFrame.new(0,  1.5,  ws), CFrame.Angles(math.rad(90),0,0)); task.wait(); FPos(bp, CFrame.new(0, -1.5, -ws), CFrame.new()); task.wait(); FPos(bp, CFrame.new(0,  1.5,  ws), CFrame.Angles(math.rad(90),0,0)); task.wait(); FPos(bp, CFrame.new(0, -1.5,  0),  CFrame.Angles(math.rad(90),0,0)); task.wait(); FPos(bp, CFrame.new(0, -1.5,  0),  CFrame.new()); task.wait(); FPos(bp, CFrame.new(0, -1.5,  0),  CFrame.Angles(math.rad(90),0,0)); task.wait(); FPos(bp, CFrame.new(0, -1.5,  0),  CFrame.new()); task.wait() end until tick() > deadline or not isFlingActive
    end
    workspace.FallenPartsDestroyHeight = 0/0; myHum:SetStateEnabled(Enum.HumanoidStateType.Seated, false); if tHrp then SFBasePart(tHrp) elseif tHead then SFBasePart(tHead) elseif handle then SFBasePart(handle) end; mover:Destroy(); myHum:SetStateEnabled(Enum.HumanoidStateType.Seated, true); workspace.CurrentCamera.CameraSubject = myHum
    if flingOldPos then local tries = 0; repeat tries = tries + 1; myHrp.CFrame = flingOldPos * CFrame.new(0, 0.5, 0); pcall(function() myChar:PivotTo(flingOldPos * CFrame.new(0, 0.5, 0)) end); myHum:ChangeState(Enum.HumanoidStateType.GettingUp); for _,p in ipairs(myChar:GetChildren()) do if p:IsA("BasePart") then p.Velocity = Vector3.zero; p.RotVelocity = Vector3.zero end end; task.wait() until (myHrp.Position - flingOldPos.Position).Magnitude < 25 or tries > 60; workspace.FallenPartsDestroyHeight = FPDH end
end
flingBtn.MouseButton1Click:Connect(function() if isFlingActive then isFlingActive = false; flingBtn.Text = "💥 Fling Player"; flingBtn.BackgroundColor3 = Color3.fromRGB(180,30,50); return end; local t = FindPlayer(trollBox.Text); if not (t and t.Character and t.Character:FindFirstChild("HumanoidRootPart")) then trollBox.Text = "Not found!"; task.wait(1); trollBox.Text = ""; return end; isFlingActive = true; flingBtn.Text = "⏹ Stop Fling"; flingBtn.BackgroundColor3 = Color3.fromRGB(80,80,80); task.spawn(function() while isFlingActive do pcall(doFling, t); task.wait(0.1) end; flingBtn.Text = "💥 Fling Player"; flingBtn.BackgroundColor3 = Color3.fromRGB(180,30,50) end) end)

local isTouchFling = false; local touchFlingConn = nil
local function startTouchFling() local movel = 0.1; touchFlingConn = track("touchFling", RunService.Heartbeat:Connect(function() local c = player.Character; local hrp = c and c:FindFirstChild("HumanoidRootPart"); if not hrp then return end; local vel = hrp.Velocity; hrp.Velocity = vel * 10000 + Vector3.new(0, 10000, 0); RunService.RenderStepped:Wait(); hrp.Velocity = vel; RunService.Stepped:Wait(); hrp.Velocity = vel + Vector3.new(0, movel, 0); movel = -movel end)) end
touchFlingBtn.MouseButton1Click:Connect(function() isTouchFling = not isTouchFling; if isTouchFling then touchFlingBtn.BackgroundColor3 = T.Troll; touchFlingBtn.TextColor3 = Color3.fromRGB(20,20,20); touchFlingBtn.Text = "👆 Touch Fling: ON"; startTouchFling() else untrack("touchFling"); touchFlingConn = nil; touchFlingBtn.BackgroundColor3 = Color3.fromRGB(160,50,10); touchFlingBtn.TextColor3 = T.TextMain; touchFlingBtn.Text = "👆 Touch Fling (Toggle)" end end)

local isNanFling = false; local nanFlingConn = nil; local nanFlingTarget = nil; local hasSHP = (typeof(sethiddenproperty) == "function"); local nanMode = "area"
local function setNanMode(m) nanMode = m; if m == "area" then nanModeBtn.Text = "Mode: Area (gần mình)"; nanModeBtn.BackgroundColor3 = Color3.fromRGB(50,50,80) else nanModeBtn.Text = "Mode: Target (".. (trollBox.Text ~= "" and trollBox.Text or "chọn player") ..")"; nanModeBtn.BackgroundColor3 = Color3.fromRGB(80,50,50) end end; nanModeBtn.MouseButton1Click:Connect(function() if nanMode == "area" then setNanMode("target") else setNanMode("area") end end)
local NAN_VEC = Vector3.new(0/0, 0/0, 0/0); local function applyNanFling(targetHrp, myHrp, myHum) myHrp.CFrame = targetHrp.CFrame; myHrp.AssemblyLinearVelocity = NAN_VEC; myHrp.AssemblyAngularVelocity = NAN_VEC; pcall(function() myHum.PlatformStand = true end); pcall(function() myHum:Move(NAN_VEC) end); if hasSHP then pcall(function() sethiddenproperty(myHrp, "PhysicsRepRootPart", targetHrp) end) end end
nanFlingBtn.MouseButton1Click:Connect(function() isNanFling = not isNanFling; if isNanFling then if nanMode == "target" then local t = FindPlayer(trollBox.Text); if not (t and t.Character and t.Character:FindFirstChild("HumanoidRootPart")) then trollBox.Text = "Not found!"; task.wait(1); trollBox.Text = ""; isNanFling = false; return end; nanFlingTarget = t end; nanFlingBtn.BackgroundColor3 = T.Troll; nanFlingBtn.TextColor3 = Color3.fromRGB(20,20,20); nanFlingBtn.Text = "☠️ NaN Fling: ON" .. (hasSHP and " [SHP]" or ""); nanFlingConn = track("nanFling", RunService.Heartbeat:Connect(function() local myChar = player.Character; local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid"); local myHrp = myHum and myHum.RootPart; if not myChar or not myHrp then return end; if nanMode == "target" then if not (nanFlingTarget and nanFlingTarget.Character) then isNanFling = false; untrack("nanFling"); nanFlingConn = nil; nanFlingBtn.BackgroundColor3 = Color3.fromRGB(80,0,0); nanFlingBtn.TextColor3 = T.TextMain; nanFlingBtn.Text = "☠️ NaN Fling (Toggle)"; pcall(function() myHum.PlatformStand = false end); return end; local tHrp = nanFlingTarget.Character:FindFirstChild("HumanoidRootPart"); if tHrp then applyNanFling(tHrp, myHrp, myHum) end else for _, p in ipairs(Players:GetPlayers()) do if p ~= player and p.Character then local tHrp = p.Character:FindFirstChild("HumanoidRootPart"); if tHrp then local dist = (myHrp.Position - tHrp.Position).Magnitude; if dist <= 15 then applyNanFling(tHrp, myHrp, myHum) end end end end end end)) else untrack("nanFling"); nanFlingConn = nil; nanFlingTarget = nil; local myHum = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); pcall(function() if myHum then myHum.PlatformStand = false end end); nanFlingBtn.BackgroundColor3 = Color3.fromRGB(80,0,0); nanFlingBtn.TextColor3 = T.TextMain; nanFlingBtn.Text = "☠️ NaN Fling (Toggle)" end end)

local currentWeld = nil; local weldThread = nil; local WELD_FPDH = workspace.FallenPartsDestroyHeight; local WELD_GROUP = randName(12)
pcall(function() local PS = game:GetService("PhysicsService"); PS:RegisterCollisionGroup(WELD_GROUP); PS:CollisionGroupSetCollidable(WELD_GROUP, WELD_GROUP, true) end); local function isR15(char) return char and char:FindFirstChild("UpperTorso") ~= nil end
local function stopWeld() if weldThread then task.cancel(weldThread); weldThread = nil end; if currentWeld then pcall(function() if currentWeld.part and currentWeld.part.Parent then currentWeld.part:Destroy() end end); local myChar = player.Character; if myChar and currentWeld.oldCharProps then for part, props in pairs(currentWeld.oldCharProps) do pcall(function() if part and part.Parent then part.CollisionGroup = props.group; part.CanCollide = props.collide end end) end end; local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid"); if myHum then pcall(function() myHum.RequiresNeck = true end) end; if currentWeld.animTrack then pcall(function() currentWeld.animTrack:Stop() end) end; currentWeld = nil end; workspace.FallenPartsDestroyHeight = WELD_FPDH; for _,b in ipairs({weldBangBtn,weldStandBtn,weldAttackBtn,weldHeadBtn,weldBackBtn,weldCarpetBtn, weldBehindBtn}) do b.BackgroundColor3 = Color3.fromRGB(40,40,60); b.TextColor3 = T.TextMain end end
local function startWeld(targetPart, offset, animId) stopWeld(); local myChar = player.Character; local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid"); local myRoot = myHum and myHum.RootPart; if not myChar or not myRoot then return end; workspace.FallenPartsDestroyHeight = 0/0; local weldPart = Instance.new("Part"); weldPart.Name = randName(6); weldPart.Size = Vector3.new(25, 3, 25); weldPart.Anchored = false; weldPart.CanCollide = true; weldPart.Transparency = 1; weldPart.CastShadow = false; weldPart.CollisionGroup = WELD_GROUP; weldPart.Parent = workspace.Terrain; local oldCharProps = {}; for _,p in ipairs(myChar:GetDescendants()) do if p:IsA("BasePart") then oldCharProps[p] = {group = p.CollisionGroup, collide = p.CanCollide}; p.CollisionGroup = WELD_GROUP; p.CanCollide = true end end; pcall(function() myHum.RequiresNeck = false end); local animTrack = nil; if animId and animId ~= 0 then pcall(function() local animator = myChar:FindFirstChildWhichIsA("Animator", true); if animator then local anim = Instance.new("Animation"); anim.AnimationId = "rbxassetid://" .. tostring(animId); animTrack = animator:LoadAnimation(anim); animTrack:Play() end end) end; currentWeld = {part = weldPart, oldCharProps = oldCharProps, animTrack = animTrack}; weldThread = task.spawn(function() while currentWeld do if not targetPart or not targetPart.Parent then stopWeld(); break end; local tCF = targetPart.CFrame; weldPart.CFrame = tCF; myRoot.CFrame = tCF * offset; weldPart.AssemblyLinearVelocity = Vector3.zero; weldPart.AssemblyAngularVelocity = Vector3.zero; myRoot.AssemblyLinearVelocity = Vector3.zero; myRoot.AssemblyAngularVelocity = Vector3.zero; RunService.RenderStepped:Wait(); weldPart.CFrame = tCF; myRoot.CFrame = tCF * CFrame.new(0, 4, 0); weldPart.AssemblyLinearVelocity = Vector3.zero; weldPart.AssemblyAngularVelocity = Vector3.zero; task.wait() end end) end
local function weldToPose(poseName, activeBtn) local t = FindPlayer(trollBox.Text); if not (t and t.Character) then trollBox.Text = "Not found!"; task.wait(1); trollBox.Text = ""; return end; local char = t.Character; local myChar = player.Character; local tHum = char:FindFirstChildOfClass("Humanoid"); local tRoot = (tHum and tHum.RootPart) or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart"); if not tRoot then return end; local offset, animId; if poseName == "bang" then offset = CFrame.new(0, 0, -2) * CFrame.Angles(0, math.rad(180), 0); animId = 148840371 elseif poseName == "behind" then offset = CFrame.new(0, 0, 2); animId = 0 elseif poseName == "stand" then if isR15(myChar) then offset = CFrame.new(1.8, 1.8, 2); animId = 96658788627102 else offset = CFrame.new(1.5, 1.25, 2); animId = 313762630 end elseif poseName == "attack" then local r180 = CFrame.Angles(0, math.rad(180), 0); if isR15(myChar) then offset = CFrame.new(0, 0.5, -2.55) * r180; animId = 117183737438245 else offset = CFrame.new(0, 0, -1.25) * r180; animId = 259438880 end elseif poseName == "headsit" then offset = CFrame.new(0, 3, 0); animId = 178130996 elseif poseName == "backpack" then offset = CFrame.new(0, 0, 1.05) * CFrame.Angles(0, math.rad(180), 0); animId = 178130996 elseif poseName == "carpet" then offset = CFrame.new(0, -1, 0); animId = 282574440 end; startWeld(tRoot, offset, animId); for _,b in ipairs({weldBangBtn,weldStandBtn,weldAttackBtn,weldHeadBtn,weldBackBtn,weldCarpetBtn, weldBehindBtn}) do b.BackgroundColor3 = Color3.fromRGB(40,40,60); b.TextColor3 = T.TextMain end; activeBtn.BackgroundColor3 = T.AccentON; activeBtn.TextColor3 = Color3.fromRGB(20,20,25) end
weldBangBtn.MouseButton1Click:Connect(function() weldToPose("bang", weldBangBtn) end); weldStandBtn.MouseButton1Click:Connect(function() weldToPose("stand", weldStandBtn) end); weldAttackBtn.MouseButton1Click:Connect(function() weldToPose("attack", weldAttackBtn) end); weldHeadBtn.MouseButton1Click:Connect(function() weldToPose("headsit", weldHeadBtn) end); weldBackBtn.MouseButton1Click:Connect(function() weldToPose("backpack",weldBackBtn) end); weldCarpetBtn.MouseButton1Click:Connect(function() weldToPose("carpet", weldCarpetBtn) end); weldBehindBtn.MouseButton1Click:Connect(function() weldToPose("behind", weldBehindBtn) end); weldUnweldBtn.MouseButton1Click:Connect(stopWeld)
local isPushing = false; local pushConn2 = nil
weldPushBtn.MouseButton1Click:Connect(function() isPushing = not isPushing; if isPushing then local t = FindPlayer(trollBox.Text); if not (t and t.Character and t.Character:FindFirstChild("HumanoidRootPart")) then trollBox.Text = "Not found!"; task.wait(1); trollBox.Text = ""; isPushing = false; return end; weldPushBtn.BackgroundColor3 = T.Troll; weldPushBtn.TextColor3 = Color3.fromRGB(20,20,25); weldPushBtn.Text = "👊 Pushing..."; local tHrp = t.Character.HumanoidRootPart; local pushForce = 0; pushConn2 = track("weldPush", RunService.Heartbeat:Connect(function() if not t.Character or not tHrp.Parent then isPushing = false; untrack("weldPush"); pushConn2 = nil; weldPushBtn.BackgroundColor3 = Color3.fromRGB(40,40,60); weldPushBtn.TextColor3 = T.TextMain; weldPushBtn.Text = "👊 Push"; return end; pushForce = math.min(pushForce + 2, 80); local pushDir = tHrp.CFrame.LookVector; tHrp.AssemblyLinearVelocity = pushDir * pushForce; local myHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart"); if myHrp and currentWeld then myHrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, 1.5) end end)) else untrack("weldPush"); pushConn2 = nil; isPushing = false; weldPushBtn.BackgroundColor3 = Color3.fromRGB(40,40,60); weldPushBtn.TextColor3 = T.TextMain; weldPushBtn.Text = "👊 Push" end end)
weldCustomBtn.MouseButton1Click:Connect(function() local parts = trollBox.Text:split(" "); local x = tonumber(parts[2]) or 0; local y = tonumber(parts[3]) or 0; local z = tonumber(parts[4]) or 1.3; local t2 = FindPlayer(parts[1]); if not (t2 and t2.Character) then trollBox.Text = "Format: name x y z"; task.wait(1.5); trollBox.Text = ""; return end; local tRoot2 = t2.Character:FindFirstChild("HumanoidRootPart"); if tRoot2 then startWeld(tRoot2, CFrame.new(x, y, z), 0); weldCustomBtn.BackgroundColor3 = T.AccentON end end)

local isSpinning, spinTarget = false, nil
spinBtn.MouseButton1Click:Connect(function() isSpinning = not isSpinning; if isSpinning then local t = FindPlayer(trollBox.Text); if t and t.Character then spinTarget = t; spinBtn.BackgroundColor3 = T.Troll; spinBtn.Text = "🌀 Stop Spin: " .. t.Name; track("spin", RunService.Stepped:Connect(function() if spinTarget and spinTarget.Character then local hrp = spinTarget.Character:FindFirstChild("HumanoidRootPart"); if hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(18), 0) end else isSpinning = false; spinBtn.BackgroundColor3 = Color3.fromRGB(100,20,140); spinBtn.Text = "🌀 Spin Player (Toggle)"; untrack("spin") end end)) else isSpinning = false; trollBox.Text = "Not found!"; task.wait(1); trollBox.Text = "" end else spinBtn.BackgroundColor3 = Color3.fromRGB(100,20,140); spinBtn.Text = "🌀 Spin Player (Toggle)"; spinTarget = nil; untrack("spin") end end)
local isFollowing, followTarget = false, nil
followBtn.MouseButton1Click:Connect(function() isFollowing = not isFollowing; if isFollowing then local t = FindPlayer(trollBox.Text); if t and t.Character then followTarget = t; followBtn.BackgroundColor3 = T.Troll; followBtn.Text = "👁 Stop Follow: " .. t.Name; track("follow", RunService.Heartbeat:Connect(function() if not followTarget or not followTarget.Character then isFollowing = false; followBtn.BackgroundColor3 = Color3.fromRGB(20,120,80); followBtn.Text = "👁 Follow Player (Toggle)"; untrack("follow"); return end; local tHrp = followTarget.Character:FindFirstChild("HumanoidRootPart"); local mHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart"); if tHrp and mHrp then if (mHrp.Position - tHrp.Position).Magnitude > 8 then mHrp.CFrame = tHrp.CFrame * CFrame.new(2, 0, 3) end end end)) else isFollowing = false; trollBox.Text = "Not found!"; task.wait(1); trollBox.Text = "" end else followBtn.BackgroundColor3 = Color3.fromRGB(20,120,80); followBtn.Text = "👁 Follow Player (Toggle)"; followTarget = nil; untrack("follow") end end)

local function Panic()
    for label,_ in pairs(Connections) do untrack(label) end
    if isFlying then isFlying = false; StopFly(); setBtn(flyBtn, false) end
    if isWalk then isWalk = false; setBtn(walkBtn, false); local hum = player.Character and player.Character:FindFirstChild("Humanoid"); if hum then hum.WalkSpeed = 16 end end
    if isJump then isJump = false; setBtn(jumpBtn, false); local hum = player.Character and player.Character:FindFirstChild("Humanoid"); if hum then hum.UseJumpPower = true; hum.JumpPower = 50 end end
    if isInfJump then isInfJump = false; setBtn(infJumpBtn, false) end
    if isNoclip then isNoclip = false; setBtn(noclipBtn, false); for _,p in ipairs(noclipParts) do if p and p.Parent then p.CanCollide = true end end; noclipParts = {} end
    if isESP then isESP = false; setBtn(espBtn, false); pcall(function() espFolder:ClearAllChildren() end) end
    if isSelfFrozen then isSelfFrozen = false; untrack("selfFreeze"); selfFrzConn = nil; local hrp2 = player.Character and player.Character:FindFirstChild("HumanoidRootPart"); local hum2 = player.Character and player.Character:FindFirstChild("Humanoid"); if hrp2 then hrp2.Anchored = false end; if hum2 then hum2.WalkSpeed = 16; hum2.JumpPower = 50 end; selfFrzCF = nil; selfFrzBtn.Text = "🧊 Freeze Self"; setBtn(selfFrzBtn, false) end
    
    if isFakeInvis then ToggleFakeInvis() end
    if isMouseTween then ToggleMouseTween() end
    if isAntiFling then ToggleAntiFling() end
    if isBypassAC then ToggleBypassAC() end
    
    freezeConn = nil; frozenTarget = nil; frozenCF = nil; freezeBtn.Text = "🧊 Freeze Player"
    isSpinning = false; spinTarget = nil; spinBtn.BackgroundColor3 = Color3.fromRGB(100,20,140); spinBtn.Text = "🌀 Spin Player (Toggle)"
    isFollowing = false; followTarget = nil; followBtn.BackgroundColor3 = Color3.fromRGB(20,120,80); followBtn.Text = "👁 Follow Player (Toggle)"
    if isTouchFling then isTouchFling = false; untrack("touchFling"); touchFlingConn = nil; touchFlingBtn.BackgroundColor3 = Color3.fromRGB(160,50,10); touchFlingBtn.TextColor3 = T.TextMain; touchFlingBtn.Text = "👆 Touch Fling (Toggle)" end
    if isNanFling then isNanFling = false; untrack("nanFling"); nanFlingConn = nil; nanFlingTarget = nil; local myHum = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); pcall(function() if myHum then myHum.PlatformStand = false end end); nanFlingBtn.BackgroundColor3 = Color3.fromRGB(80,0,0); nanFlingBtn.TextColor3 = T.TextMain; nanFlingBtn.Text = "☠️ NaN Fling (Toggle)" end
    pcall(stopWeld)
    if isPushing then isPushing = false; untrack("weldPush"); weldPushBtn.BackgroundColor3 = Color3.fromRGB(40,40,60); weldPushBtn.TextColor3 = T.TextMain; weldPushBtn.Text = "👊 Push" end
    pcall(function() local orig = titleLbl.TextColor3; titleLbl.Text = "⚠ PANIC — RESET"; titleLbl.TextColor3 = T.Troll; task.delay(1.5, function() titleLbl.Text = "LAI ADMIN"; titleLbl.TextColor3 = orig end) end)
end

track("input", UserInputService.InputBegan:Connect(function(input, gp)
    if listeningForAction then
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if input.KeyCode == Enum.KeyCode.Escape then keybinds[listeningForAction] = Enum.KeyCode.Unknown; listeningButton.Text = "[-]" elseif input.KeyCode ~= Enum.KeyCode.Unknown then keybinds[listeningForAction] = input.KeyCode; listeningButton.Text = "["..input.KeyCode.Name.."]" end
        if updateBindTexts[listeningForAction] then updateBindTexts[listeningForAction]() end
        listeningForAction = nil; listeningButton = nil; return
    end
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then Panic(); return end
    
    if input.KeyCode == keybinds.Menu then
        isMenuOpen = not isMenuOpen
        local pos  = isMenuOpen and openPos or closedPos; local spos = isMenuOpen and openShadow or closedShadow
        local ti = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        TweenService:Create(main, ti, {Position = pos}):Play(); TweenService:Create(shadow, ti, {Position = spos}):Play()
    end

    local function tryBind(key, fn) if key ~= Enum.KeyCode.Unknown and input.KeyCode == key then fn() end end
    tryBind(keybinds.Fly, ToggleFly); tryBind(keybinds.WalkSpeed, ToggleWalkSpeed); tryBind(keybinds.JumpPower, ToggleJumpPower)
    tryBind(keybinds.InfJump, ToggleInfJump); tryBind(keybinds.Noclip, ToggleNoclip); tryBind(keybinds.ESP, ToggleESP)
    tryBind(keybinds.SelfFreeze, ToggleSelfFreeze); tryBind(keybinds.FakeInvis, ToggleFakeInvis)
    tryBind(keybinds.AntiFling, ToggleAntiFling); tryBind(keybinds.BypassAC, ToggleBypassAC)

    if keybinds.Freeze ~= Enum.KeyCode.Unknown and input.KeyCode == keybinds.Freeze then
        local t = FindPlayer(trollBox.Text)
        if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
            if freezeConn then untrack("freeze"); freezeConn = nil; frozenTarget = nil; frozenCF = nil; freezeBtn.Text = "🧊 Freeze Player" else frozenTarget = t; frozenCF = t.Character.HumanoidRootPart.CFrame; freezeConn = track("freeze", RunService.Heartbeat:Connect(function() if not frozenTarget or not frozenTarget.Character then untrack("freeze"); freezeConn = nil; return end; local hrp = frozenTarget.Character:FindFirstChild("HumanoidRootPart"); if hrp then hrp.CFrame = frozenCF end end)); freezeBtn.Text = "🧊 Frozen: " .. t.Name end
        end
    end
end))

print("[LAI ADMIN] GUI Đã chui vào vùng bảo mật an toàn thành công!")
