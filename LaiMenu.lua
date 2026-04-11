-- ============================================================
-- LAI ADMIN v6.2 | ULTIMATE STABILITY & ORIGINAL AURA (MODDED 360 FLY)
-- ============================================================

local AdonisFound, DetectedFunc, OriginalInfo = false, nil, {}
local function FindDetected()
    local LAI_PROTECT = "LAI_ADMIN_SAFE_FUNC"
    if filtergc then
        local Query = { Constants = {" - On Xbox", " - On mobile", "_"}, IgnoreExecutor = true }
        local matches = filtergc("function", Query)
        if matches and matches[1] then DetectedFunc = matches[1]; AdonisFound = true end
    elseif getgc then
        for _, v in next, getgc(true) do
            if type(v) == "function" then
                pcall(function()
                    local info = debug.info(v, "s")
                    if info and (info:find("Adonis") or info:find("Anti")) then
                        local constants = debug.getconstants(v)
                        if constants and table.find(constants, " - On Xbox") then DetectedFunc = v; AdonisFound = true end
                    end
                end)
                if AdonisFound then break end
            end
        end
    end
end

local function StealthBypass()
    local LAI_PROTECT = "LAI_ADMIN_SAFE_FUNC"
    if not AdonisFound or not DetectedFunc then return end
    local a, b, c, d, e, f = debug.info(DetectedFunc, "slanf")
    OriginalInfo = {a, b, c, d, e, f}
    
    local hook = hookfunction or (syn and syn.oth and syn.oth.hook)
    if not hook then return end
    local oldInfo
    oldInfo = hook(debug.info, newcclosure(function(...)
        local args = {...}
        if args[1] == DetectedFunc and args[2] == "slanf" then return unpack(OriginalInfo) end
        return oldInfo(...)
    end))
    hook(DetectedFunc, newcclosure(function() return task.wait(9e10) end))
    warn("[LAI ADMIN] Stealth Bypass Activated.")
end

pcall(FindDetected)
if AdonisFound then pcall(StealthBypass) end

-- ============================================================
-- CORE SERVICES & VARIABLES
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local CAS = game:GetService("ContextActionService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local mouse = player:GetMouse()

math.randomseed(math.floor(tick() * 1000) + math.floor(os.clock() * 1000))
local function randName(len)
    len = math.max(4, len or 16)
    local pool = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local bytes = {}
    for _ = 1, len do 
        local idx = math.random(1, #pool)
        bytes[#bytes+1] = pool:sub(idx, idx) 
    end
    return table.concat(bytes)
end

local Connections = {}
local function track(l, c) if Connections[l] and Connections[l].Connected then Connections[l]:Disconnect() end; Connections[l] = c; return c end
local function untrack(l) if Connections[l] then if Connections[l].Connected then Connections[l]:Disconnect() end; Connections[l] = nil end end

local keybinds = {
    Menu = Enum.KeyCode.Insert, Fly = Enum.KeyCode.C, WalkSpeed = Enum.KeyCode.V, SelfFreeze = Enum.KeyCode.B,
    JumpPower = Enum.KeyCode.Unknown, InfJump = Enum.KeyCode.Unknown, ESP = Enum.KeyCode.Unknown,
    Noclip = Enum.KeyCode.Unknown, Freeze = Enum.KeyCode.Unknown, FakeInvis = Enum.KeyCode.Unknown,
    AntiFling = Enum.KeyCode.Unknown, BypassAC = Enum.KeyCode.Unknown, FOV = Enum.KeyCode.Unknown, MaxZoom = Enum.KeyCode.Unknown,
    AntiLagback = Enum.KeyCode.Unknown, TpJump = Enum.KeyCode.Unknown, Blink = Enum.KeyCode.Unknown, NanFling = Enum.KeyCode.Unknown, 
    RemoteBlock = Enum.KeyCode.Unknown, NoStun = Enum.KeyCode.Unknown, RemoteBypass = Enum.KeyCode.Unknown, GodMode = Enum.KeyCode.Unknown,
    ThirdPerson = Enum.KeyCode.Unknown, ShiftLock = Enum.KeyCode.Unknown, InstantPrompt = Enum.KeyCode.Unknown, AutoPrompt = Enum.KeyCode.Unknown
}

local ConfigName = "LaiAdmin_Config_v6.2.json"

local T = {
    MainBG = Color3.fromRGB(28, 30, 36), ElemBG = Color3.fromRGB(42, 45, 53), ElemHover = Color3.fromRGB(55, 60, 70), 
    AccentON = Color3.fromRGB(160, 190, 240), AccentDim = Color3.fromRGB(100, 120, 150), AccentLine = Color3.fromRGB(120, 140, 175), 
    TextMain = Color3.fromRGB(235, 235, 240), TextSub = Color3.fromRGB(180, 185, 195), TextDim = Color3.fromRGB(130, 135, 145), 
    Border = Color3.fromRGB(60, 65, 75), Troll = Color3.fromRGB(230, 140, 140), Warn = Color3.fromRGB(230, 190, 130)
}

local UI = {}
local S = {
    isMenuOpen = true, curFlyMode = "Camera", flyStance = "Upright", isFlying = false, isWalk = false, isJump = false, isInfJump = false, isTpJump = false,
    isNoclip = false, isESP = false, isTracer = true, isSelfFrozen = false, isFakeInvis = false, isAntiFling = false, isBypassAC = false, 
    isFOV = false, isZoom = false, mouseTpMode = nil, isModernFling = false, isFlingActive = false, isTouchFling = false, 
    isNanFling = false, nanMode = "area", isPushing = false, isSpinning = false, isFollowing = false, nanFlingTarget = nil, 
    isSpinFlingV2 = false, isAntiLagback = false, isBlink = false,
    isNoStun = false, isRemoteBypass = false, isGodMode = false, isRemoteBlock = false, isForceThirdPerson = false, isUnlockShiftLock = false,
    isInstantPrompt = false, isAutoPrompt = false
}

-- ============================================================
-- GUI BUILDER
-- ============================================================
local gui = Instance.new("ScreenGui"); gui.Name = randName(16); gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
gui.DisplayOrder = 9999999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local targetParent = nil
pcall(function() targetParent = gethui and gethui() or cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui") end)
pcall(function() gui.Parent = targetParent end)
if not gui.Parent then pcall(function() gui.Parent = player:WaitForChild("PlayerGui") end) end

local shadow = Instance.new("Frame", gui); shadow.Size, shadow.BackgroundColor3, shadow.BackgroundTransparency, shadow.BorderSizePixel = UDim2.new(0, 292, 0, 512), Color3.new(0,0,0), 0.55, 0; Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 14); shadow.ZIndex = 1

local main = Instance.new("Frame", gui); main.Size, main.BackgroundColor3, main.BackgroundTransparency, main.BorderSizePixel = UDim2.new(0, 280, 0, 500), T.MainBG, 0.08, 0; Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12); main.Active = true; main.ZIndex = 5

local openPos, closedPos = UDim2.new(0, 20, 0.5, -250), UDim2.new(0, -320, 0.5, -250)
main.Position, shadow.Position = openPos, UDim2.new(0, 14, 0.5, -253)
local outerStroke = Instance.new("UIStroke", main); outerStroke.Color = T.Border; outerStroke.Thickness = 1
local accentBar = Instance.new("Frame", main); accentBar.Size, accentBar.Position, accentBar.BackgroundColor3, accentBar.BackgroundTransparency, accentBar.BorderSizePixel = UDim2.new(1, -24, 0, 1), UDim2.new(0, 12, 0, 0), T.AccentLine, 0.3, 0; accentBar.ZIndex = 6

local titleF = Instance.new("Frame", main); titleF.Size, titleF.BackgroundTransparency, titleF.BorderSizePixel = UDim2.new(1, 0, 0, 44), 1, 0; titleF.ZIndex = 6
local titleDot = Instance.new("Frame", titleF); titleDot.Size, titleDot.Position, titleDot.BackgroundColor3, titleDot.BorderSizePixel = UDim2.new(0, 6, 0, 6), UDim2.new(0, 14, 0.5, -3), T.AccentON, 0; Instance.new("UICorner", titleDot).CornerRadius = UDim.new(1, 0); titleDot.ZIndex = 6
local titleLbl = Instance.new("TextLabel", titleF); titleLbl.Size, titleLbl.Position, titleLbl.BackgroundTransparency, titleLbl.Text, titleLbl.TextColor3, titleLbl.Font, titleLbl.TextSize, titleLbl.TextXAlignment = UDim2.new(0, 140, 1, 0), UDim2.new(0, 26, 0, 0), 1, "LAI ADMIN", T.TextMain, Enum.Font.GothamBlack, 13, Enum.TextXAlignment.Left; titleLbl.ZIndex = 6
local titleSub = Instance.new("TextLabel", titleF); titleSub.Size, titleSub.Position, titleSub.BackgroundTransparency, titleSub.Text, titleSub.TextColor3, titleSub.Font, titleSub.TextSize, titleSub.TextXAlignment = UDim2.new(0, 100, 1, 0), UDim2.new(0, 112, 0, 0), 1, "v6.2", T.TextDim, Enum.Font.Gotham, 11, Enum.TextXAlignment.Left; titleSub.ZIndex = 6

UI.menuBindBtn = Instance.new("TextButton", titleF); UI.menuBindBtn.Size, UI.menuBindBtn.Position, UI.menuBindBtn.BackgroundColor3, UI.menuBindBtn.TextColor3, UI.menuBindBtn.Font, UI.menuBindBtn.TextSize, UI.menuBindBtn.Text, UI.menuBindBtn.BorderSizePixel = UDim2.new(0, 44, 0, 22), UDim2.new(1, -54, 0.5, -11), T.ElemBG, T.AccentON, Enum.Font.GothamBold, 10, keybinds.Menu.Name, 0; Instance.new("UICorner", UI.menuBindBtn).CornerRadius = UDim.new(0, 4); local mbStroke = Instance.new("UIStroke", UI.menuBindBtn); mbStroke.Color, mbStroke.Thickness = T.AccentDim, 1; UI.menuBindBtn.ZIndex = 6
local updateBindTexts = {}; updateBindTexts["Menu"] = function() local kb = keybinds["Menu"]; UI.menuBindBtn.Text = (kb and kb ~= Enum.KeyCode.Unknown) and kb.Name or "-" end
UI.menuBindBtn.MouseButton1Click:Connect(function() S.listenAct = "Menu"; S.listenBtn = UI.menuBindBtn; UI.menuBindBtn.Text = "..."; UI.menuBindBtn.TextColor3 = T.Warn end)
local titleSep = Instance.new("Frame", main); titleSep.Size, titleSep.Position, titleSep.BackgroundColor3, titleSep.BorderSizePixel = UDim2.new(1, -20, 0, 1), UDim2.new(0, 10, 0, 44), T.Border, 0; titleSep.ZIndex = 6

local drag, dStart, sPos = false, nil, nil
titleF.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag, dStart, sPos = true, i.Position, main.Position end end)
UserInputService.InputChanged:Connect(function(i) if drag and i.UserInputType == Enum.UserInputType.MouseMovement then local d = i.Position - dStart; main.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + d.X, sPos.Y.Scale, sPos.Y.Offset + d.Y); shadow.Position = UDim2.new(main.Position.X.Scale, main.Position.X.Offset - 6, main.Position.Y.Scale, main.Position.Y.Offset - 3) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end)

local tabBar = Instance.new("Frame", main); tabBar.Size, tabBar.Position, tabBar.BackgroundTransparency = UDim2.new(1, 0, 0, 34), UDim2.new(0, 0, 0, 46), 1; tabBar.ZIndex = 6
local tabLine = Instance.new("Frame", tabBar); tabLine.Size, tabLine.Position, tabLine.BackgroundColor3, tabLine.BorderSizePixel = UDim2.new(1, -20, 0, 1), UDim2.new(0, 10, 1, -1), T.Border, 0; tabLine.ZIndex = 6
local tabInd = Instance.new("Frame", tabBar); tabInd.Size, tabInd.Position, tabInd.BackgroundColor3, tabInd.BorderSizePixel = UDim2.new(0.2, -10, 0, 2), UDim2.new(0, 5, 1, -2), T.AccentON, 0; Instance.new("UICorner", tabInd).CornerRadius = UDim.new(1, 0); tabInd.ZIndex = 7
local function mkTab(txt, x, c) local b = Instance.new("TextButton", tabBar); b.Size, b.Position, b.BackgroundTransparency, b.Text, b.TextColor3, b.Font, b.TextSize = UDim2.new(0.2, 0, 1, -2), UDim2.new(x, 0, 0, 0), 1, txt, c or T.TextSub, Enum.Font.GothamSemibold, 11; b.ZIndex = 7; return b end
UI.tabMain, UI.tabTP, UI.tabMisc, UI.tabEmotes, UI.tabTroll = mkTab("Main", 0, T.TextMain), mkTab("TP", 0.2), mkTab("Misc", 0.4), mkTab("Emotes", 0.6), mkTab("Troll", 0.8, T.Troll)

local function mkCont(v) local sf = Instance.new("ScrollingFrame", main); sf.Size, sf.Position, sf.BackgroundTransparency, sf.BorderSizePixel, sf.ScrollBarThickness, sf.ScrollBarImageColor3, sf.Visible, sf.AutomaticCanvasSize, sf.CanvasSize = UDim2.new(1, 0, 1, -82), UDim2.new(0, 0, 0, 82), 1, 0, 2, T.AccentDim, v, Enum.AutomaticSize.Y, UDim2.new(0, 0, 0, 50); sf.ZIndex = 6; local l = Instance.new("UIListLayout", sf); l.Padding, l.HorizontalAlignment, l.SortOrder = UDim.new(0, 6), Enum.HorizontalAlignment.Center, Enum.SortOrder.LayoutOrder; local p = Instance.new("UIPadding", sf); p.PaddingTop, p.PaddingBottom = UDim.new(0, 8), UDim.new(0, 12); return sf end
UI.cMain, UI.cTP, UI.cMisc, UI.cEmotes, UI.cTroll = mkCont(true), mkCont(false), mkCont(false), mkCont(false), mkCont(false)

local function stroke(o, c, t) local s = Instance.new("UIStroke", o); s.Color = c or T.Border; s.Thickness = t or 1 end
local function mkRow(p, txt, act, ord) local r = Instance.new("Frame", p); r.Size, r.BackgroundTransparency, r.LayoutOrder = UDim2.new(0.92, 0, 0, 30), 1, ord; local t = Instance.new("TextButton", r); t.Size, t.BackgroundColor3, t.TextColor3, t.Font, t.TextSize, t.Text, t.BorderSizePixel = UDim2.new(1, -50, 1, 0), T.ElemBG, T.TextMain, Enum.Font.GothamSemibold, 12, txt, 0; t.ZIndex = 7; Instance.new("UICorner", t).CornerRadius = UDim.new(0, 6); stroke(t); local b = Instance.new("TextButton", r); b.Size, b.Position, b.BackgroundColor3, b.TextColor3, b.Font, b.TextSize, b.BorderSizePixel = UDim2.new(0, 44, 1, 0), UDim2.new(1, -44, 0, 0), T.ElemBG, T.AccentON, Enum.Font.GothamBold, 10, 0; b.ZIndex = 7; Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6); stroke(b, T.AccentDim); updateBindTexts[act] = function() local kb = keybinds[act]; b.Text = (kb and kb ~= Enum.KeyCode.Unknown) and kb.Name or "-" end; updateBindTexts[act](); b.MouseButton1Click:Connect(function() S.listenAct = act; S.listenBtn = b; b.Text = "..."; b.TextColor3 = T.Warn end); return t end
local function mkInp(p, ph, ord) local b = Instance.new("TextBox", p); b.Size, b.BackgroundColor3, b.TextColor3, b.Font, b.TextSize, b.LayoutOrder, b.PlaceholderText, b.PlaceholderColor3, b.Text, b.BorderSizePixel = UDim2.new(0.92, 0, 0, 28), T.ElemBG, T.AccentON, Enum.Font.GothamBold, 12, ord, ph, T.TextDim, "", 0; b.ZIndex = 7; Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6); stroke(b); return b end
local function mkBtn(p, txt, bg, ord) local b = Instance.new("TextButton", p); b.Size, b.BackgroundColor3, b.TextColor3, b.Font, b.TextSize, b.Text, b.LayoutOrder, b.BorderSizePixel = UDim2.new(0.92, 0, 0, 30), bg or T.ElemBG, T.TextMain, Enum.Font.GothamSemibold, 12, txt, ord, 0; b.ZIndex = 7; Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6); stroke(b); return b end
local function mkPre(p, lbl, vals, box, ord) local r = Instance.new("Frame", p); r.Size, r.BackgroundTransparency, r.LayoutOrder = UDim2.new(0.92, 0, 0, 22), 1, ord; local l = Instance.new("TextLabel", r); l.Size, l.BackgroundTransparency, l.Text, l.TextColor3, l.Font, l.TextSize, l.TextXAlignment = UDim2.new(0.28, 0, 1, 0), 1, lbl, T.TextDim, Enum.Font.Gotham, 10, Enum.TextXAlignment.Left; l.ZIndex = 7; local w = 0.72 / #vals; for i, v in ipairs(vals) do local b = Instance.new("TextButton", r); b.Size, b.Position, b.BackgroundColor3, b.TextColor3, b.Font, b.TextSize, b.Text, b.BorderSizePixel = UDim2.new(w, -3, 1, 0), UDim2.new(0.28 + w*(i-1), 2, 0, 0), T.ElemBG, T.TextSub, Enum.Font.GothamBold, 10, tostring(v), 0; b.ZIndex = 7; Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4); stroke(b); b.MouseButton1Click:Connect(function() box.Text = tostring(v); b.TextColor3 = T.AccentON; task.delay(0.3, function() b.TextColor3 = T.TextSub end) end) end end
local function mkLbl(p, txt, ord) local l = Instance.new("TextLabel", p); l.Size, l.BackgroundTransparency, l.Text, l.TextColor3, l.Font, l.TextSize, l.TextXAlignment, l.LayoutOrder = UDim2.new(0.92, 0, 0, 16), 1, txt, T.TextDim, Enum.Font.GothamSemibold, 10, Enum.TextXAlignment.Left, ord; l.ZIndex = 7; return l end
local function mkList(p, tBox, ord) local w = Instance.new("Frame", p); w.Size, w.BackgroundTransparency, w.LayoutOrder = UDim2.new(0.9, 0, 0, 135), 1, ord; local sBox = mkInp(w, "Search Player...", 1); sBox.Size, sBox.Position = UDim2.new(1, 0, 0, 22), UDim2.new(0, 0, 0, 0); local fr = Instance.new("Frame", w); fr.Size, fr.Position, fr.BackgroundColor3, fr.BorderSizePixel = UDim2.new(1, 0, 1, -26), UDim2.new(0, 0, 0, 26), T.ElemBG, 0; Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 6); local sf = Instance.new("ScrollingFrame", fr); sf.Size, sf.BackgroundTransparency, sf.BorderSizePixel, sf.ScrollBarThickness, sf.ScrollBarImageColor3, sf.AutomaticCanvasSize, sf.CanvasSize = UDim2.new(1, 0, 1, 0), 1, 0, 3, T.AccentON, Enum.AutomaticSize.Y, UDim2.new(0, 0, 0, 0); sf.ZIndex = 7; local ll = Instance.new("UIListLayout", sf); ll.Padding, ll.SortOrder = UDim.new(0, 2), Enum.SortOrder.Name; local pp = Instance.new("UIPadding", sf); pp.PaddingTop, pp.PaddingBottom, pp.PaddingLeft, pp.PaddingRight = UDim.new(0,4), UDim.new(0,4), UDim.new(0,4), UDim.new(0,4); local btns = {}; local function ref() for _,b in pairs(btns) do pcall(function() b:Destroy() end) end; btns = {}; for _,pl in ipairs(Players:GetPlayers()) do if pl ~= player then local b = Instance.new("TextButton", sf); b.Size, b.BackgroundColor3, b.TextColor3, b.Font, b.TextSize, b.Text, b.TextXAlignment, b.BorderSizePixel = UDim2.new(1, -6, 0, 24), T.ElemHover, T.TextMain, Enum.Font.GothamSemibold, 12, pl.DisplayName.." (@"..pl.Name..")", Enum.TextXAlignment.Left, 0; b.ZIndex = 8; Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4); local pad = Instance.new("UIPadding", b); pad.PaddingLeft = UDim.new(0, 6); b.MouseButton1Click:Connect(function() tBox.Text = pl.Name; for _,ob in pairs(btns) do ob.BackgroundColor3 = T.ElemHover; ob.TextColor3 = T.TextMain end; b.BackgroundColor3 = T.AccentON; b.TextColor3 = Color3.fromRGB(20,20,25) end); btns[pl.Name] = b end end end; sBox:GetPropertyChangedSignal("Text"):Connect(function() local txt = sBox.Text:lower(); for _,b in pairs(btns) do b.Visible = (txt == "" or string.find(b.Text:lower(), txt) ~= nil) end end); return w, btns, ref end

-- ============================================================
-- POPULATE UI ELEMENTS
-- ============================================================
UI.flyBtn = mkRow(UI.cMain, "Toggle Fly", "Fly", 1);
UI.flyModeBtn = mkBtn(UI.cMain, "Fly Mode: Camera", T.ElemBG, 2); 

-- THÊM NÚT ĐIỀU CHỈNH GÓC BAY MỚI VÀO ĐÂY
UI.flyStanceBtn = mkBtn(UI.cMain, "Fly Stance: Upright", T.ElemBG, 2.5)
UI.flyStanceBtn.MouseButton1Click:Connect(function() 
    S.flyStance = S.flyStance == "Upright" and "360" or "Upright"
    UI.flyStanceBtn.Text = "Fly Stance: " .. S.flyStance
end)

UI.flySpeedBox = mkInp(UI.cMain, "Fly Speed (Def: 50)", 3); UI.flySpeedBox.Text = "50";
mkPre(UI.cMain, "Speed:", {50, 100, 300}, UI.flySpeedBox, 4)
UI.walkBtn = mkRow(UI.cMain, "Toggle WalkSpeed", "WalkSpeed", 5);
UI.walkBox = mkInp(UI.cMain, "Walk Speed (Def: 16)", 6); UI.walkBox.Text = "16";
mkPre(UI.cMain, "Speed:", {16, 50, 100}, UI.walkBox, 7)
UI.speedModeBtn = mkBtn(UI.cMain, "Speed Mode: GodMove", T.ElemBG, 8);
UI.jumpBtn = mkRow(UI.cMain, "Toggle JumpPower", "JumpPower", 9);
UI.jumpBox = mkInp(UI.cMain, "Jump Power (Def: 50)", 10); UI.jumpBox.Text = "50";
mkPre(UI.cMain, "Power:", {50, 100, 250}, UI.jumpBox, 11)
UI.tpJumpBtn = mkRow(UI.cMain, "Toggle Teleport Jump", "TpJump", 12);
UI.tpJumpBox = mkInp(UI.cMain, "TP Jump Boost (Def: 5)", 13); UI.tpJumpBox.Text = "5";
mkPre(UI.cMain, "Boost:", {2, 5, 10}, UI.tpJumpBox, 14)
UI.infJumpBtn = mkRow(UI.cMain, "Infinite Jump", "InfJump", 15);

mkLbl(UI.cMisc, "--- Proximity Prompts ---", 1)
UI.instantPromptBtn = mkRow(UI.cMisc, "Instant Prompts (No Hold)", "InstantPrompt", 2)
UI.autoPromptBtn = mkRow(UI.cMisc, "Auto Interact (Aura)", "AutoPrompt", 3)
mkLbl(UI.cMisc, "--- Utilities & Movement ---", 4)
UI.blinkBtn = mkRow(UI.cMisc, "Toggle Blink (Lag Switch)", "Blink", 5)
UI.noclipBtn = mkRow(UI.cMisc, "Toggle Noclip", "Noclip", 6)
UI.antiLagbackBtn = mkRow(UI.cMisc, "Anti-Lagback", "AntiLagback", 7)
UI.selfFrzBtn = mkRow(UI.cMisc, "Freeze Self", "SelfFreeze", 8)
UI.fakeInvisBtn = mkRow(UI.cMisc, "Toggle Fake Invis", "FakeInvis", 9)
UI.fakeInvisBox = mkInp(UI.cMisc, "Invis Offset (Def: 7)", 10); UI.fakeInvisBox.Text = "7"

-- [REPLICATE AURA / SPOOF AVATAR]
mkLbl(UI.cMisc, "--- Replicate Aura (Avatar) ---", 10.1)
UI.spoofBox = mkInp(UI.cMisc, "Target Username", 10.2)
UI.spoofBtn = mkBtn(UI.cMisc, "Spoof Avatar", T.ElemBG, 10.3)

mkLbl(UI.cMisc, "--- Visuals & Camera ---", 11)
UI.espBtn = mkRow(UI.cMisc, "Toggle 2D ESP", "ESP", 12)
UI.tracerBtn = mkBtn(UI.cMisc, "ESP Tracers: ON", T.ElemBG, 13)
UI.fovBox = mkInp(UI.cMisc, "Field of View (Def: 70)", 14); UI.fovBox.Text = "70"; mkPre(UI.cMisc, "FOV:", {70, 90, 120}, UI.fovBox, 15);
UI.fovBtn = mkRow(UI.cMisc, "Force FOV", "FOV", 16);
UI.zoomBtn = mkRow(UI.cMisc, "Unlock Max Zoom", "MaxZoom", 17)
UI.thirdPersonBtn = mkRow(UI.cMisc, "Unlock 3rd Person", "ThirdPerson", 18)
UI.shiftLockBtn = mkRow(UI.cMisc, "Unlock Shiftlock/Mouse", "ShiftLock", 19)
mkLbl(UI.cMisc, "--- Server & Protection ---", 20)
UI.antiFlingBtn = mkRow(UI.cMisc, "Toggle Anti-Fling", "AntiFling", 21)
UI.bypassAcBtn = mkRow(UI.cMisc, "Bypass Walk/Jump AC", "BypassAC", 22)
UI.noStunBtn = mkRow(UI.cMisc, "Strong No Stun", "NoStun", 23)
UI.godModeBtn = mkRow(UI.cMisc, "God Mode (Local)", "GodMode", 24)
UI.remoteBlockBtn = mkRow(UI.cMisc, "Block Remote Kick/Ban", "RemoteBlock", 25)
UI.remoteBypassBtn = mkRow(UI.cMisc, "Universal Remote Bypass", "RemoteBypass", 26)
UI.nukeAcBtn = mkBtn(UI.cMisc, "Nuke Anti-Cheat (Universal)", T.ElemBG, 27)
UI.saveCfgBtn = mkBtn(UI.cMisc, "Save Config", T.ElemBG, 28)
UI.safeExitBtn = mkBtn(UI.cMisc, "Safe Exit (Anti-Ban)", T.ElemBG, 29)

UI.tpBox = mkInp(UI.cTP, "Target Player Name", 1)
local _, _, tpRefresh = mkList(UI.cTP, UI.tpBox, 2)
UI.tpRefreshBtn = mkBtn(UI.cTP, "Refresh Player List", T.ElemBG, 3)
mkLbl(UI.cTP, "--- TP Player Modes ---", 4)
UI.playerTpSpeedBox = mkInp(UI.cTP, "TP Speed (Def: 150)", 5); UI.playerTpSpeedBox.Text = "150"; mkPre(UI.cTP, "Speed:", {100, 150, 300}, UI.playerTpSpeedBox, 6)
UI.tpInstant = mkBtn(UI.cTP, "Instant TP", T.ElemBG, 7)
UI.tpDash = mkBtn(UI.cTP, "Dash TP (Tween)", T.ElemBG, 8)
UI.tpStep = mkBtn(UI.cTP, "Step TP (Bypass)", T.ElemBG, 9)
mkLbl(UI.cTP, "--- Ctrl + Click TP Modes ---", 10)
UI.mouseTpBtn = mkBtn(UI.cTP, "Ctrl+Click: Tween Mode", T.ElemBG, 11)
UI.mouseTpStepBtn = mkBtn(UI.cTP, "Ctrl+Click: Step Mode", T.ElemBG, 12)
UI.mouseTpPivotBtn = mkBtn(UI.cTP, "Ctrl+Click: Pivot Mode", T.ElemBG, 13)
UI.mouseTpSpeedBox = mkInp(UI.cTP, "Click TP Speed (Def: 150)", 14); UI.mouseTpSpeedBox.Text = "150"; mkPre(UI.cTP, "Speed:", {100, 150, 300}, UI.mouseTpSpeedBox, 15)

UI.emoteBtns = {}; local emoteNames = {"wave","point","dance","dance2","dance3","laugh","cheer","salute","stadium","tilt","shrug"}
for i, n in ipairs(emoteNames) do 
    local dispName = n:sub(1,1):upper() .. n:sub(2)
    UI.emoteBtns[n] = mkBtn(UI.cEmotes, dispName, T.ElemBG, i) 
end

mkLbl(UI.cTroll, "Target Player:", 1); UI.trollBox = mkInp(UI.cTroll, "Target Player Name", 2); local _, _, refreshPlayerList = mkList(UI.cTroll, UI.trollBox, 3); UI.refreshBtn = mkBtn(UI.cTroll, "Refresh Player List", T.ElemBG, 4)
Players.PlayerAdded:Connect(function() task.wait(0.1); refreshPlayerList(); tpRefresh() end); Players.PlayerRemoving:Connect(function() task.wait(0.1); refreshPlayerList(); tpRefresh() end); refreshPlayerList(); tpRefresh()

mkLbl(UI.cTroll, "--- Freeze & Fling ---", 5); UI.freezeBtn = mkRow(UI.cTroll, "Freeze Player", "Freeze", 6); UI.unfrzBtn = mkBtn(UI.cTroll, "Unfreeze Player", T.ElemBG, 7)
UI.spinFlingV2Btn = mkBtn(UI.cTroll, "FE Spin Fling v2", T.ElemBG, 8)
UI.modernFlingBtn = mkBtn(UI.cTroll, "Modern Fling: OFF", T.ElemBG, 9); UI.flingBtn = mkBtn(UI.cTroll, "Classic Fling Player", T.ElemBG, 10); UI.touchFlingBtn = mkBtn(UI.cTroll, "Touch Fling (Toggle)", T.ElemBG, 11)
mkLbl(UI.cTroll, "--- NaN Fling ---", 12); UI.nanModeBtn = mkBtn(UI.cTroll, "Mode: Area (Nearby)", T.ElemBG, 13); UI.nanFlingBtn = mkRow(UI.cTroll, "NaN Fling (Toggle)", "NanFling", 14)
mkLbl(UI.cTroll, "--- Welder ---", 15)
local function mkPF(ord) local f = Instance.new("Frame", UI.cTroll); f.Size, f.BackgroundTransparency, f.LayoutOrder = UDim2.new(0.9, 0, 0, 30), 1, ord; f.ZIndex = 7; local l = Instance.new("UIListLayout", f); l.FillDirection, l.Padding, l.SortOrder = Enum.FillDirection.Horizontal, UDim.new(0, 4), Enum.SortOrder.LayoutOrder; return f end
local function mkPB(p, txt, ord) local b = Instance.new("TextButton", p); b.Size, b.BackgroundColor3, b.TextColor3, b.Font, b.TextSize, b.Text, b.LayoutOrder = UDim2.new(0, 60, 1, 0), T.ElemBG, T.TextMain, Enum.Font.GothamBold, 11, txt, ord; b.ZIndex = 8; Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4); return b end
local wF1 = mkPF(16); UI.weldBangBtn = mkPB(wF1,"Bang",1); UI.weldStandBtn = mkPB(wF1,"Stand",2); UI.weldAttackBtn = mkPB(wF1,"Attack",3); UI.weldHeadBtn = mkPB(wF1,"Head",4)
local wF2 = mkPF(17); UI.weldBackBtn = mkPB(wF2,"Back",1); UI.weldCarpetBtn = mkPB(wF2,"Carpet",2); UI.weldBehindBtn = mkPB(wF2,"Behind",3); UI.weldCustomBtn = mkPB(wF2,"Custom",4)
local wF3 = mkPF(18); UI.weldPushBtn = mkPB(wF3,"Push",1); UI.weldUnweldBtn = mkPB(wF3,"Unweld",2); UI.weldPushBtn.Size, UI.weldUnweldBtn.Size = UDim2.new(0, 90, 1, 0), UDim2.new(0, 90, 1, 0)
mkLbl(UI.cTroll, "--- Misc ---", 19); UI.spinBtn = mkBtn(UI.cTroll, "Spin Player (Toggle)", T.ElemBG, 20); UI.followBtn = mkBtn(UI.cTroll, "Follow Player (Sticky)", T.ElemBG, 21)

local tabs = {{btn = UI.tabMain, c = UI.cMain, x = 0}, {btn = UI.tabTP, c = UI.cTP, x = 0.2}, {btn = UI.tabMisc, c = UI.cMisc, x = 0.4}, {btn = UI.tabEmotes, c = UI.cEmotes, x = 0.6}, {btn = UI.tabTroll, c = UI.cTroll, x = 0.8}}
local function switchTab(ab, ac, ax) for _,t in ipairs(tabs) do t.c.Visible = false; t.btn.BackgroundTransparency = 1; t.btn.TextColor3 = (t.btn == UI.tabTroll) and T.Troll or T.TextDim; t.btn.Font = Enum.Font.GothamSemibold end; ac.Visible = true; ab.TextColor3 = (ab == UI.tabTroll) and T.Troll or T.TextMain; ab.Font = Enum.Font.GothamBold; tabInd.Position, tabInd.BackgroundColor3 = UDim2.new(ax, 5, 1, -2), (ab == UI.tabTroll) and T.Troll or T.AccentON end
for _,t in ipairs(tabs) do local tt = t; t.btn.MouseButton1Click:Connect(function() switchTab(tt.btn, tt.c, tt.x) end) end; switchTab(UI.tabMain, UI.cMain, 0)

-- ============================================================
-- MAIN LOGIC
-- ============================================================
local function setBtn(btn, on) 
    local tBtn = btn:IsA("TextButton") and btn or btn:FindFirstChildWhichIsA("TextButton")
    if tBtn then tBtn.BackgroundColor3, tBtn.TextColor3 = on and T.AccentON or T.ElemBG, on and Color3.fromRGB(25,25,30) or T.TextMain end 
end

-- [SERVER-SIDED SPOOF AVATAR - ORIGINAL LOGIC]
local function SpoofAvatar(targetUsername, btnObj)
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not humanoid then if btnObj then btnObj.Text = "Boii you gyat no Humanoid" end; return end

    local successId, targetId = pcall(function() return Players:GetUserIdFromNameAsync(targetUsername) end)
    if not successId then if targetId then warn(targetId) end; if btnObj then btnObj.Text = "L typo boi 🤣🤣" end; return end

    local successDesc, targetDesc = pcall(function() return Players:GetHumanoidDescriptionFromUserIdAsync(targetId) end)
    if successDesc and targetDesc then
        local current = humanoid:GetAppliedDescription()
        targetDesc.HeightScale = current.HeightScale; targetDesc.WidthScale = current.WidthScale; targetDesc.DepthScale = current.DepthScale
        targetDesc.HeadScale = current.HeadScale; targetDesc.ProportionScale = current.ProportionScale; targetDesc.BodyTypeScale = current.BodyTypeScale
        for _, item in ipairs(char:GetChildren()) do if item:IsA("Accessory") or item:IsA("Shirt") or item:IsA("Pants") then item:Destroy() end end
        local successApply = pcall(function() humanoid:ApplyDescriptionClientServer(targetDesc) end)
        if not successApply then humanoid:ApplyDescriptionResetAsync(targetDesc) end
        if btnObj then btnObj.Text = "Aura Replicated!" end
    else
        if btnObj then btnObj.Text = "insufficient aura 🤣☠️" end
    end
end

UI.spoofBtn.MouseButton1Click:Connect(function()
    local tUser = UI.spoofBox.Text; if tUser == "" then return end
    UI.spoofBtn.Text = "Fetching Aura..."
    task.spawn(function() SpoofAvatar(tUser, UI.spoofBtn); task.delay(2, function() UI.spoofBtn.Text = "Spoof Avatar" end) end)
end)

local origHoldDurations = {}
local function ToggleInstantPrompt()
    S.isInstantPrompt = not S.isInstantPrompt; setBtn(UI.instantPromptBtn, S.isInstantPrompt)
    if S.isInstantPrompt then
        track("instPrompt", ProximityPromptService.PromptShown:Connect(function(prompt) if not origHoldDurations[prompt] then origHoldDurations[prompt] = prompt.HoldDuration end; prompt.HoldDuration = 0 end))
        track("instPromptHide", ProximityPromptService.PromptHidden:Connect(function(prompt) if origHoldDurations[prompt] then prompt.HoldDuration = origHoldDurations[prompt]; origHoldDurations[prompt] = nil end end))
    else
        untrack("instPrompt"); untrack("instPromptHide")
        for p, d in pairs(origHoldDurations) do pcall(function() p.HoldDuration = d end) end; origHoldDurations = {}
    end
end

local function ToggleAutoPrompt()
    S.isAutoPrompt = not S.isAutoPrompt; setBtn(UI.autoPromptBtn, S.isAutoPrompt)
    if S.isAutoPrompt then
        track("autoPrompt", ProximityPromptService.PromptShown:Connect(function(prompt) if fireproximityprompt then task.spawn(function() task.wait(0.05); pcall(function() fireproximityprompt(prompt) end) end) else warn("Executor của bạn không hỗ trợ fireproximityprompt!"); ToggleAutoPrompt() end end))
    else untrack("autoPrompt") end
end

local oldIndex, oldNewindex, oldNamecall; local hooksSetup = { index = false, namecall = false }
local function setupIndexHooks()
    local LAI_PROTECT = "LAI_ADMIN_SAFE_FUNC"
    if hooksSetup.index or not hookmetamethod then return end
    hooksSetup.index = true
    oldIndex = hookmetamethod(game, "__index", newcclosure(function(t, k) 
        if not checkcaller() and typeof(t) == "Instance" and t:IsA("Humanoid") then 
            if S.isBypassAC then if k == "WalkSpeed" then return 16 end; if k == "JumpPower" then return 50 end; if k == "HipHeight" then return t.RigType == Enum.HumanoidRigType.R15 and 2 or 0 end end
            if S.isGodMode and k == "Health" then return t.MaxHealth end
        end; return oldIndex(t, k) 
    end)) 
    oldNewindex = hookmetamethod(game, "__newindex", newcclosure(function(t, k, v)
        if not checkcaller() and typeof(t) == "Instance" then
            if t:IsA("Humanoid") then
                if S.isBypassAC and (k == "WalkSpeed" or k == "JumpPower") then return nil end
                if S.isNoStun and (k == "WalkSpeed" or k == "JumpPower" or k == "PlatformStand" or k == "Sit") then return nil end
                if S.isGodMode and k == "Health" and type(v) == "number" and v < t.Health then return nil end
            end
            if S.isNoStun and t.Name == "HumanoidRootPart" and k == "Anchored" and v == true then return nil end
            if S.isForceThirdPerson and t == player then if k == "CameraMode" or k == "CameraMaxZoomDistance" or k == "CameraMinZoomDistance" then return nil end end
            if S.isUnlockShiftLock then if t == player and k == "DevEnableMouseLock" and v == false then return nil end; if t == UserInputService and k == "MouseBehavior" and v ~= Enum.MouseBehavior.Default then return nil end; if t == UserInputService and k == "MouseIconEnabled" and v == false then return nil end end
        end; return oldNewindex(t, k, v)
    end))
end

local function setupNamecallHook()
    local LAI_PROTECT = "LAI_ADMIN_SAFE_FUNC"
    if hooksSetup.namecall or not hookmetamethod then return end
    hooksSetup.namecall = true
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        if checkcaller() then return oldNamecall(self, ...) end
        local method = getnamecallmethod(); local args = {...}
        if (method == "Kick" or method == "kick") and (S.isRemoteBlock or S.isRemoteBypass) then return nil end 
        if method == "FireServer" or method == "InvokeServer" then
            local name = string.lower(self.Name)
            if S.isRemoteBlock then
                if string.find(name, "report") or string.find(name, "punish") or string.find(name, "ban") or string.find(name, "exploit") then return nil end
                for _, arg in pairs(args) do if type(arg) == "string" then local lowerArg = string.lower(arg); if string.find(lowerArg, "kick") or string.find(lowerArg, "banned") or string.find(lowerArg, "speedhack") or string.find(lowerArg, "noclip") or string.find(lowerArg, "exploiting") or string.find(lowerArg, "unexpected") then return nil end end end
            end
            if S.isRemoteBypass then
                local blacklistedWords = {"ban", "kick", "crash", "punish", "anticheat", "log", "report", "exploit", "suspect"}
                for _, word in ipairs(blacklistedWords) do if string.find(name, word) then return nil end end
            end
        end; return oldNamecall(self, ...)
    end))
end

local function FindPlayer(pt) if not pt or pt == "" then return nil end; local low = pt:lower(); for _,p in ipairs(Players:GetPlayers()) do if p ~= player and (p.Name:lower():find(low) or p.DisplayName:lower():find(low)) then return p end end end
local function LoadConfig() pcall(function() if not isfile or not isfile(ConfigName) then return end; local raw = readfile(ConfigName); if not raw or raw == "" then return end; local s, cfg = pcall(function() return HttpService:JSONDecode(raw) end); if s and cfg then if cfg.Keybinds then for k, v in pairs(cfg.Keybinds) do if keybinds[k] then pcall(function() keybinds[k] = Enum.KeyCode[v]; if updateBindTexts[k] then updateBindTexts[k]() end end) end end end; if cfg.WalkSpeed then UI.walkBox.Text = cfg.WalkSpeed end; if cfg.JumpPower then UI.jumpBox.Text = cfg.JumpPower end; if cfg.TpJumpBoost then UI.tpJumpBox.Text = cfg.TpJumpBoost end; if cfg.FlySpeed then UI.flySpeedBox.Text = cfg.FlySpeed end; if cfg.MouseTPSpeed then UI.mouseTpSpeedBox.Text = cfg.MouseTPSpeed end; if cfg.FakeInvisOffset then UI.fakeInvisBox.Text = cfg.FakeInvisOffset end; if cfg.FOVValue then UI.fovBox.Text = cfg.FOVValue end end end) end
UI.saveCfgBtn.MouseButton1Click:Connect(function() local ok, err = pcall(function() if not writefile then error("No writefile") end; local cfg = {Keybinds = {}, WalkSpeed = UI.walkBox.Text, JumpPower = UI.jumpBox.Text, TpJumpBoost = UI.tpJumpBox.Text, FlySpeed = UI.flySpeedBox.Text, MouseTPSpeed = UI.mouseTpSpeedBox.Text, FakeInvisOffset = UI.fakeInvisBox.Text, FOVValue = UI.fovBox.Text}; for k, v in pairs(keybinds) do cfg.Keybinds[k] = v.Name end; writefile(ConfigName, HttpService:JSONEncode(cfg)) end); UI.saveCfgBtn.Text = ok and "Saved!" or "Error"; task.delay(1.5, function() UI.saveCfgBtn.Text = "Save Config" end) end)
LoadConfig()

local gm_lc, gm_ofn, gm_lastState
local BLOCKED_STATES = {Enum.HumanoidStateType.FallingDown, Enum.HumanoidStateType.Ragdoll, Enum.HumanoidStateType.GettingUp, Enum.HumanoidStateType.PlatformStanding, Enum.HumanoidStateType.StrafingNoPhysics, Enum.HumanoidStateType.Seated, Enum.HumanoidStateType.Physics}
local ALLOWED_STATES = {Enum.HumanoidStateType.Running, Enum.HumanoidStateType.RunningNoPhysics, Enum.HumanoidStateType.Freefall, Enum.HumanoidStateType.Jumping, Enum.HumanoidStateType.Swimming, Enum.HumanoidStateType.Climbing}
local SUNK_ACTIONS = {"seatAction", "ragdollAction", "platformstandAction"}

local function gm_hookController() local ctrl; pcall(function() ctrl = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls() end); if not ctrl then return end; local ok, ac = pcall(function() return ctrl.activeController end); if not ok or not ac or ac == gm_lc then return end; gm_lc = ac; if ac.__hooked then gm_ofn = ac.__orig return end; ac.__hooked = true; ac.__orig = ac.GetMoveVector; gm_ofn = ac.__orig; ac.GetMoveVector = function(self) local ok2, v = pcall(ac.__orig, self); return ok2 and v or Vector3.zero end end
local function gm_unhookController() if not gm_lc or not gm_lc.__hooked then return end; pcall(function() gm_lc.GetMoveVector = gm_lc.__orig; gm_lc.__hooked = nil; gm_lc.__orig = nil end) end
local function gm_getMoveVec() if not gm_ofn or not gm_lc then return Vector3.zero end; local ok, v = pcall(gm_ofn, gm_lc); return ok and v or Vector3.zero end
local function gm_worldDir(mv) local cam = workspace.CurrentCamera; if not cam then return nil end; local d = cam.CFrame:VectorToWorldSpace(Vector3.new(mv.X, 0, mv.Z)); d = Vector3.new(d.X, 0, d.Z); if d.Magnitude < 0.001 then return nil end; return d.Unit end

local function ToggleWalkSpeed() S.isWalk = not S.isWalk; setBtn(UI.walkBtn, S.isWalk); untrack("walk"); untrack("godmove"); gm_unhookController(); pcall(function() player.Character.Humanoid.WalkSpeed = 16 end); for _, name in ipairs(SUNK_ACTIONS) do pcall(function() CAS:UnbindAction(name) end) end; if S.isWalk then if S.speedMode == "Classic" or S.speedMode == "Stealth" then track("walk", RunService.RenderStepped:Connect(function(dt) pcall(function() local hum = player.Character.Humanoid; local hrp = player.Character.HumanoidRootPart; local targetSpeed = tonumber(UI.walkBox.Text) or 16; if S.speedMode == "Classic" then hum.WalkSpeed = targetSpeed else hum.WalkSpeed = 16; if targetSpeed > 16 and hum.MoveDirection.Magnitude > 0 then hrp.CFrame = hrp.CFrame + (hum.MoveDirection * (targetSpeed - 16) * dt) end end end) end)) elseif S.speedMode == "GodMove" then local hum = player.Character:FindFirstChild("Humanoid"); local hrp = player.Character:FindFirstChild("HumanoidRootPart"); if not hum or not hrp then return end; for _, name in ipairs(SUNK_ACTIONS) do pcall(function() CAS:BindAction(name, function() return Enum.ContextActionResult.Sink end, false, Enum.KeyCode.Unknown) end) end; track("godmove", RunService.Heartbeat:Connect(function() pcall(function() local targetSpeed = tonumber(UI.walkBox.Text) or 16; hum.WalkSpeed = 16; for _, s in ipairs(BLOCKED_STATES) do pcall(function() hum:SetStateEnabled(s, false) end) end; for _, s in ipairs(ALLOWED_STATES) do pcall(function() hum:SetStateEnabled(s, true) end) end; gm_hookController(); local mv = gm_getMoveVec(); if mv.Magnitude <= 0 then return end; local dir = gm_worldDir(mv); if not dir then return end; local cv = hrp.AssemblyLinearVelocity; local st = hum:GetState(); local vx, vz = dir.X * targetSpeed, dir.Z * targetSpeed; if st == Enum.HumanoidStateType.Freefall or st == Enum.HumanoidStateType.Jumping or st == Enum.HumanoidStateType.Swimming or st == Enum.HumanoidStateType.Climbing then hrp.AssemblyLinearVelocity = Vector3.new(vx, cv.Y, vz); return end; if st ~= Enum.HumanoidStateType.Running and st ~= Enum.HumanoidStateType.RunningNoPhysics then if st ~= gm_lastState then gm_lastState = st; pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end) end else gm_lastState = nil end; hrp.AssemblyLinearVelocity = Vector3.new(vx, cv.Y, vz) end) end)) end end end

local function ToggleBlink() S.isBlink = not S.isBlink; if S.isBlink then pcall(function() settings():GetService("NetworkSettings").IncomingReplicationLag = 10 end); UI.blinkBtn.BackgroundColor3 = T.Warn; UI.blinkBtn.TextColor3 = Color3.fromRGB(20,20,20); else pcall(function() settings():GetService("NetworkSettings").IncomingReplicationLag = 0 end); setBtn(UI.blinkBtn, false) end end

local function applyJump() pcall(function() player.Character.Humanoid.UseJumpPower = true; player.Character.Humanoid.JumpPower = math.clamp(tonumber(UI.jumpBox.Text) or 50, 0, 1000) end) end
local function ToggleJumpPower() S.isJump = not S.isJump; setBtn(UI.jumpBtn, S.isJump); if S.isJump then applyJump(); track("jump", RunService.Heartbeat:Connect(applyJump)) else untrack("jump"); pcall(function() player.Character.Humanoid.UseJumpPower = true; player.Character.Humanoid.JumpPower = 50 end) end end
local function ToggleInfJump() S.isInfJump = not S.isInfJump; setBtn(UI.infJumpBtn, S.isInfJump); if S.isInfJump then track("infJump", UserInputService.JumpRequest:Connect(function() pcall(function() player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end) end)) else untrack("infJump") end end

local flyAttach, flyLV
UI.flyModeBtn.MouseButton1Click:Connect(function() S.curFlyMode = S.curFlyMode == "Camera" and "Hover" or "Camera"; UI.flyModeBtn.Text = "Fly Mode: " .. (S.curFlyMode == "Camera" and "Camera" or "Hover") end)
local function StopFly() untrack("fly"); if flyAttach then flyAttach:Destroy(); flyAttach = nil; flyLV = nil end; pcall(function() player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end) end

-- CẬP NHẬT: HÀM FLY CÓ HỖ TRỢ GÓC 360 ĐỘ
local function ToggleFly() 
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart"); 
    local hum = player.Character and player.Character:FindFirstChild("Humanoid");
    if not hrp or not hum then return end; 
    
    S.isFlying = not S.isFlying; 
    setBtn(UI.flyBtn, S.isFlying); 
    if not S.isFlying then StopFly(); return end; 
    
    hum:ChangeState(Enum.HumanoidStateType.Physics); 
    flyAttach = Instance.new("Attachment", hrp); 
    flyLV = Instance.new("LinearVelocity", flyAttach); 
    flyLV.Attachment0 = flyAttach; 
    flyLV.MaxForce = 9e9; 
    flyLV.VectorVelocity = Vector3.zero;
    flyLV.RelativeTo = Enum.ActuatorRelativeTo.World; 
    
    local smooth = Vector3.zero; 
    track("fly", RunService.RenderStepped:Connect(function(dt) 
        pcall(function() 
            local h2 = player.Character.HumanoidRootPart; 
            local hm2 = player.Character.Humanoid; 
            if not h2 or not hm2 or not flyAttach then StopFly(); S.isFlying = false; setBtn(UI.flyBtn, false); return end; 
            
            hm2:ChangeState(Enum.HumanoidStateType.Physics); 
            local dir = Vector3.zero; 
            
            if S.curFlyMode == "Camera" then 
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += camera.CFrame.LookVector end; 
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= camera.CFrame.LookVector end; 
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= camera.CFrame.RightVector end; 
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += camera.CFrame.RightVector end 
            else 
                local fwd = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z); 
                local rgt = Vector3.new(camera.CFrame.RightVector.X, 0, camera.CFrame.RightVector.Z); 
                fwd = fwd.Magnitude > 0.01 and fwd.Unit or Vector3.zero; 
                rgt = rgt.Magnitude > 0.01 and rgt.Unit or Vector3.zero; 
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += fwd end; 
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= fwd end;
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= rgt end; 
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += rgt end;
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end; 
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis end 
            end;
            
            local spd = tonumber(UI.flySpeedBox.Text) or 50; 
            smooth = smooth:Lerp(dir.Magnitude > 0 and dir.Unit * spd or Vector3.zero, math.min(1, dt*10));
            flyLV.VectorVelocity = smooth; 
            
            -- LOGIC BAY MỚI ÁP DỤNG Ở ĐÂY
            if S.flyStance == "360" then
                if dir.Magnitude > 0 or S.curFlyMode == "Camera" then
                    h2.CFrame = CFrame.lookAt(h2.Position, h2.Position + camera.CFrame.LookVector)
                end
            else
                local flat = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z);
                if flat.Magnitude > 0.01 then 
                    h2.CFrame = CFrame.lookAt(h2.Position, h2.Position + flat) 
                end
            end
            
        end) 
    end)) 
end

local function ToggleNoclip() S.isNoclip = not S.isNoclip; setBtn(UI.noclipBtn, S.isNoclip); if S.isNoclip then track("noclip", RunService.Stepped:Connect(function() local char = player.Character; if char then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end end end end)) else untrack("noclip"); task.spawn(function() local char = player.Character; if char then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end; local hrp = char:FindFirstChild("HumanoidRootPart"); if hrp then hrp.CanCollide = false end end end) end end
local function ToggleTpJump() S.isTpJump = not S.isTpJump; setBtn(UI.tpJumpBtn, S.isTpJump); if S.isTpJump then track("tpJump", RunService.Heartbeat:Connect(function(delta) local char = player.Character; local hum = char and char:FindFirstChildWhichIsA("Humanoid"); if hum then local root = hum.Parent:FindFirstChild("HumanoidRootPart"); if root then local state = hum:GetState(); if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall then local boost = tonumber(UI.tpJumpBox.Text) or 5; root.CFrame = root.CFrame + Vector3.new(0, boost * delta * 10, 0) end end end end)) else untrack("tpJump") end end
local function ToggleAntiLagback() S.isAntiLagback = not S.isAntiLagback; setBtn(UI.antiLagbackBtn, S.isAntiLagback); if S.isAntiLagback then local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart"); S.lastPos = hrp and hrp.Position or Vector3.zero; track("antiLagback", RunService.Heartbeat:Connect(function() pcall(function() local h = player.Character.HumanoidRootPart; local cPos = h.Position; if S.lastPos and not S.isFlying and not S.isSpinFlingV2 then local dist = (cPos - S.lastPos).Magnitude; if dist > 20 then h.CFrame = CFrame.new(S.lastPos) else S.lastPos = cPos end else S.lastPos = cPos end end) end)) else untrack("antiLagback"); S.lastPos = nil end end

UI.fovBtn.MouseButton1Click:Connect(function() S.isFOV = not S.isFOV; setBtn(UI.fovBtn, S.isFOV); if S.isFOV then track("fov", RunService.RenderStepped:Connect(function() camera.FieldOfView = tonumber(UI.fovBox.Text) or 70 end)) else untrack("fov"); camera.FieldOfView = 70 end end)
UI.zoomBtn.MouseButton1Click:Connect(function() S.isZoom = not S.isZoom; setBtn(UI.zoomBtn, S.isZoom); if S.isZoom then track("zoom", RunService.RenderStepped:Connect(function() player.CameraMaxZoomDistance = 100000 end)) else untrack("zoom"); player.CameraMaxZoomDistance = 128 end end)
UI.tracerBtn.MouseButton1Click:Connect(function() S.isTracer = not S.isTracer; UI.tracerBtn.BackgroundColor3 = S.isTracer and T.AccentON or T.ElemBG; UI.tracerBtn.Text = "ESP Tracers: " .. (S.isTracer and "ON" or "OFF") end)

local espDrawings = {}
local function clearESP(p) if espDrawings[p] then for _, drawing in pairs(espDrawings[p]) do drawing:Remove() end; espDrawings[p] = nil end end
local function ToggleESP() S.isESP = not S.isESP; setBtn(UI.espBtn, S.isESP); if S.isESP then track("espLoop", RunService.RenderStepped:Connect(function() for _, p in ipairs(Players:GetPlayers()) do if p ~= player then local char = p.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); local hum = char and char:FindFirstChild("Humanoid"); if char and hrp and hum and hum.Health > 0 then if not espDrawings[p] then espDrawings[p] = { Box = Drawing.new("Square"), Text = Drawing.new("Text"), Tracer = Drawing.new("Line"), HealthOutline = Drawing.new("Square"), HealthBar = Drawing.new("Square") }; espDrawings[p].Box.Color = Color3.new(1, 1, 1); espDrawings[p].Box.Thickness = 1.5; espDrawings[p].Box.Filled = false; espDrawings[p].Text.Color = Color3.new(1, 1, 1); espDrawings[p].Text.Size = 14; espDrawings[p].Text.Center = true; espDrawings[p].Text.Outline = true; espDrawings[p].Tracer.Color = Color3.new(1, 1, 1); espDrawings[p].Tracer.Thickness = 1.2; espDrawings[p].Tracer.Transparency = 0.5; espDrawings[p].HealthOutline.Color = Color3.new(0, 0, 0); espDrawings[p].HealthOutline.Thickness = 1; espDrawings[p].HealthOutline.Filled = true; espDrawings[p].HealthBar.Thickness = 1; espDrawings[p].HealthBar.Filled = true end; local pos, onScreen = camera:WorldToViewportPoint(hrp.Position); if onScreen then local head = char:FindFirstChild("Head"); local headPos = head and camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0)) or pos; local legPos = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0)); local height = math.abs(headPos.Y - legPos.Y); local width = height / 2; local distance = math.floor((player.Character.HumanoidRootPart.Position - hrp.Position).Magnitude); espDrawings[p].Box.Size = Vector2.new(width, height); espDrawings[p].Box.Position = Vector2.new(pos.X - width / 2, headPos.Y); espDrawings[p].Box.Visible = true; espDrawings[p].Text.Text = string.format("%s [%dm]", p.DisplayName, distance); espDrawings[p].Text.Position = Vector2.new(pos.X, headPos.Y - 18); espDrawings[p].Text.Visible = true; espDrawings[p].Tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y); espDrawings[p].Tracer.To = Vector2.new(pos.X, legPos.Y); espDrawings[p].Tracer.Visible = S.isTracer; local healthRatio = math.clamp(hum.Health / hum.MaxHealth, 0, 1); local healthBarHeight = height * healthRatio; espDrawings[p].HealthOutline.Size = Vector2.new(4, height + 2); espDrawings[p].HealthOutline.Position = Vector2.new(pos.X - width / 2 - 6, headPos.Y - 1); espDrawings[p].HealthOutline.Visible = true; espDrawings[p].HealthBar.Color = Color3.fromHSV(healthRatio * 0.3, 1, 1); espDrawings[p].HealthBar.Size = Vector2.new(2, healthBarHeight); espDrawings[p].HealthBar.Position = Vector2.new(pos.X - width / 2 - 5, headPos.Y + (height - healthBarHeight)); espDrawings[p].HealthBar.Visible = true else for _, drawing in pairs(espDrawings[p]) do drawing.Visible = false end end else clearESP(p) end end end end)); track("espRem", Players.PlayerRemoving:Connect(clearESP)) else untrack("espLoop"); untrack("espRem"); for p, _ in pairs(espDrawings) do clearESP(p) end end end

UI.tpRefreshBtn.MouseButton1Click:Connect(tpRefresh)
UI.tpInstant.MouseButton1Click:Connect(function() local t = FindPlayer(UI.tpBox.Text); if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then local h = player.Character and player.Character:FindFirstChild("HumanoidRootPart"); if h then pcall(function() player.Character:PivotTo(t.Character.HumanoidRootPart.CFrame * CFrame.new((math.random()-0.5)*1.5, 2, 3+(math.random()-0.5)*1.5)) end) end else UI.tpBox.Text = "Not found!"; task.wait(1); UI.tpBox.Text = "" end end)
UI.tpDash.MouseButton1Click:Connect(function() local t = FindPlayer(UI.tpBox.Text); if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then local h = player.Character and player.Character:FindFirstChild("HumanoidRootPart"); if h then local dist = (h.Position - t.Character.HumanoidRootPart.Position).Magnitude; local speed = tonumber(UI.playerTpSpeedBox.Text) or 150; local timeToTp = math.max(0.1, dist / speed); TweenService:Create(h, TweenInfo.new(timeToTp, Enum.EasingStyle.Linear), {CFrame = t.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,3)}):Play() end else UI.tpBox.Text = "Not found!"; task.wait(1); UI.tpBox.Text = "" end end)
UI.tpStep.MouseButton1Click:Connect(function() local t = FindPlayer(UI.tpBox.Text); if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then local h = player.Character and player.Character:FindFirstChild("HumanoidRootPart"); if h then task.spawn(function() local targetCF = t.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,3); local startPos = h.Position; local dist = (startPos - targetCF.Position).Magnitude; local speed = tonumber(UI.playerTpSpeedBox.Text) or 150; local steps = math.max(1, math.floor((dist / speed) / 0.05)); for i = 1, steps do if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or not t.Character then break end; player.Character.HumanoidRootPart.CFrame = CFrame.new(startPos:Lerp(targetCF.Position, i/steps), targetCF.Position); task.wait(0.05) end end) end else UI.tpBox.Text = "Not found!"; task.wait(1); UI.tpBox.Text = "" end end)

local function StopMouseTP() untrack("mTP"); S.mouseTpMode = nil; UI.mouseTpBtn.BackgroundColor3, UI.mouseTpBtn.TextColor3, UI.mouseTpBtn.Text = T.ElemBG, T.TextMain, "Ctrl+Click: Tween Mode"; UI.mouseTpStepBtn.BackgroundColor3, UI.mouseTpStepBtn.TextColor3, UI.mouseTpStepBtn.Text = T.ElemBG, T.TextMain, "Ctrl+Click: Step Mode"; UI.mouseTpPivotBtn.BackgroundColor3, UI.mouseTpPivotBtn.TextColor3, UI.mouseTpPivotBtn.Text = T.ElemBG, T.TextMain, "Ctrl+Click: Pivot Mode" end
local function StartMouseTP(mode, btn, atext) if S.mouseTpMode == mode then StopMouseTP(); return end; StopMouseTP(); S.mouseTpMode = mode; btn.BackgroundColor3, btn.TextColor3, btn.Text = T.AccentON, Color3.fromRGB(20,20,20), atext; track("mTP", UserInputService.InputBegan:Connect(function(input, gp) if gp then return end; if input.UserInputType == Enum.UserInputType.MouseButton1 and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart"); if hrp and mouse.Hit then local hp = mouse.Hit; local targetCFrame = CFrame.new(hp.X, hp.Y + 3, hp.Z, select(4, hrp.CFrame:components())); local speed = tonumber(UI.mouseTpSpeedBox.Text) or 150; if speed <= 0 then speed = 150 end; if mode == "Tween" then TweenService:Create(hrp, TweenInfo.new((hrp.Position - hp.Position).Magnitude / speed, Enum.EasingStyle.Linear), {CFrame = targetCFrame}):Play() elseif mode == "Step" then task.spawn(function() local startPos = hrp.Position; local steps = math.max(1, math.floor(((startPos - hp.Position).Magnitude / speed) / 0.05)); for i = 1, steps do if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then break end; player.Character.HumanoidRootPart.CFrame = CFrame.new(startPos:Lerp(targetCFrame.Position, i/steps), targetCFrame.Position + camera.CFrame.LookVector); task.wait(0.05) end end) elseif mode == "Pivot" then player.Character:PivotTo(targetCFrame) end end end end)) end
UI.mouseTpBtn.MouseButton1Click:Connect(function() StartMouseTP("Tween", UI.mouseTpBtn, "Active: Tween Mode") end); UI.mouseTpStepBtn.MouseButton1Click:Connect(function() StartMouseTP("Step", UI.mouseTpStepBtn, "Active: Step Mode") end); UI.mouseTpPivotBtn.MouseButton1Click:Connect(function() StartMouseTP("Pivot", UI.mouseTpPivotBtn, "Active: Pivot Mode") end)

local selfFrzCF = nil
local function ToggleSelfFreeze() 
    S.isSelfFrozen = not S.isSelfFrozen; setBtn(UI.selfFrzBtn, S.isSelfFrozen); 
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart"); 
    if S.isSelfFrozen then 
        if not hrp then S.isSelfFrozen = false; setBtn(UI.selfFrzBtn, false); return end; 
        selfFrzCF = hrp.CFrame; 
        hrp.AssemblyLinearVelocity, hrp.AssemblyAngularVelocity, hrp.Anchored = Vector3.zero, Vector3.zero, true; pcall(function() player.Character.Humanoid.WalkSpeed, player.Character.Humanoid.JumpPower = 0, 0 end); 
        UI.selfFrzBtn.Text = "Unfreeze Self"; track("sFrz", RunService.Heartbeat:Connect(function() 
            pcall(function() 
                local h2 = player.Character.HumanoidRootPart; h2.Anchored, h2.AssemblyLinearVelocity, h2.AssemblyAngularVelocity = true, Vector3.zero, Vector3.zero; 
                if (h2.Position - selfFrzCF.Position).Magnitude > 0.5 then h2.CFrame = selfFrzCF end 
            end) 
        end)) 
    else 
        untrack("sFrz"); 
        if hrp then hrp.Anchored = false end; pcall(function() player.Character.Humanoid.WalkSpeed = S.isWalk and (tonumber(UI.walkBox.Text) or 16) or 16; player.Character.Humanoid.JumpPower = S.isJump and (tonumber(UI.jumpBox.Text) or 50) or 50 end); selfFrzCF = nil; 
        UI.selfFrzBtn.Text = "Freeze Self" 
    end 
end

local function ToggleAntiFling() S.isAntiFling = not S.isAntiFling; setBtn(UI.antiFlingBtn, S.isAntiFling); if S.isAntiFling then track("aFling", RunService.Stepped:Connect(function() pcall(function() local hrp = player.Character.HumanoidRootPart; if hrp.AssemblyLinearVelocity.Magnitude > 250 or hrp.AssemblyAngularVelocity.Magnitude > 50 then hrp.AssemblyLinearVelocity, hrp.AssemblyAngularVelocity = Vector3.zero, Vector3.zero end end); for _, p in ipairs(Players:GetPlayers()) do if p ~= player and p.Character then for _, pt in ipairs(p.Character:GetDescendants()) do if pt:IsA("BasePart") and pt.CanCollide then pt.CanCollide = false end end end end end)) else untrack("aFling") end end
local fInvCF, rot90 = CFrame.new(), CFrame.Angles(math.rad(90), 0, 0)
local function ToggleFakeInvis() S.isFakeInvis = not S.isFakeInvis; setBtn(UI.fakeInvisBtn, S.isFakeInvis); local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart"); if S.isFakeInvis then if hrp then fInvCF = hrp.CFrame end; RunService:BindToRenderStep("fInvCam", Enum.RenderPriority.Camera.Value - 1, function() pcall(function() player.Character.HumanoidRootPart.CFrame = fInvCF end) end); track("fInvSim", RunService.PostSimulation:Connect(function() pcall(function() local h2 = player.Character.HumanoidRootPart; fInvCF = h2.CFrame; h2.CFrame = CFrame.new(h2.Position - Vector3.new(0, tonumber(UI.fakeInvisBox.Text) or 7, 0)) * rot90 end) end)) else RunService:UnbindFromRenderStep("fInvCam"); untrack("fInvSim"); if hrp then hrp.CFrame = fInvCF end end end

local function ToggleSpinFlingV2() local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart"); if not hrp then return end; S.isSpinFlingV2 = not S.isSpinFlingV2; if S.isSpinFlingV2 then UI.spinFlingV2Btn.BackgroundColor3, UI.spinFlingV2Btn.Text = T.Troll, "Stop Spin Fling v2"; hrp.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0, 0, 1, 1); hrp.Anchored = false; track("spinFlingV2", RunService.Heartbeat:Connect(function() pcall(function() player.Character.HumanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 122434, 0) end) end)) else untrack("spinFlingV2"); UI.spinFlingV2Btn.BackgroundColor3, UI.spinFlingV2Btn.Text = T.ElemBG, "FE Spin Fling v2"; pcall(function() player.Character.HumanoidRootPart.CustomPhysicalProperties = nil; player.Character.HumanoidRootPart.AssemblyAngularVelocity = Vector3.zero end) end end
UI.spinFlingV2Btn.MouseButton1Click:Connect(ToggleSpinFlingV2)

local frozenTarget, frozenCF = nil, nil
UI.freezeBtn.MouseButton1Click:Connect(function() local t = FindPlayer(UI.trollBox.Text); if not (t and t.Character and t.Character:FindFirstChild("HumanoidRootPart")) then return end; untrack("frz"); frozenTarget, frozenCF = t, t.Character.HumanoidRootPart.CFrame; track("frz", RunService.Heartbeat:Connect(function() pcall(function() frozenTarget.Character.HumanoidRootPart.CFrame = frozenCF end) end)); UI.freezeBtn.Text = "Frozen: " .. t.Name end)
UI.unfrzBtn.MouseButton1Click:Connect(function() untrack("frz"); frozenTarget, frozenCF = nil, nil; UI.freezeBtn.Text = "Freeze Player" end)
UI.modernFlingBtn.MouseButton1Click:Connect(function() S.isModernFling = not S.isModernFling; UI.modernFlingBtn.BackgroundColor3, UI.modernFlingBtn.Text = S.isModernFling and T.AccentON or T.ElemBG, S.isModernFling and "Modern Fling: ON" or "Modern Fling: OFF" end)

local flingOldPos, FPDH = nil, workspace.FallenPartsDestroyHeight
local function doFling(targetPlayer) local myChar = player.Character; local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid"); local myHrp = myHum and myHum.RootPart; if not myChar or not myHum or not myHrp then return end; local tChar = targetPlayer.Character; if not tChar then return end; local tHum = tChar:FindFirstChildOfClass("Humanoid"); local tHrp = tHum and tHum.RootPart; local tHead = tChar:FindFirstChild("Head"); local acc = tChar:FindFirstChildOfClass("Accessory"); local handle = acc and acc:FindFirstChild("Handle"); if myHrp.Velocity.Magnitude < 50 then flingOldPos = myHrp.CFrame end; if tHum and tHum.Sit then return end; if not tChar:FindFirstChildWhichIsA("BasePart") then return end; local mover = nil; if S.isModernFling then mover = Instance.new("Attachment", myHrp); local lv = Instance.new("LinearVelocity", mover); lv.Attachment0, lv.MaxForce, lv.VectorVelocity = mover, math.huge, Vector3.new(9e7, 9e8, 9e7); local av = Instance.new("AngularVelocity", mover); av.Attachment0, av.MaxTorque, av.AngularVelocity = mover, math.huge, Vector3.new(9e8, 9e8, 9e8) else mover = Instance.new("BodyVelocity", myHrp); mover.Velocity, mover.MaxForce = Vector3.zero, Vector3.new(9e9, 9e9, 9e9) end; local function FPos(bp, p, a) myHrp.CFrame = CFrame.new(bp.Position) * p * a; myChar:PivotTo(myHrp.CFrame); if not S.isModernFling then myHrp.Velocity, myHrp.RotVelocity = Vector3.new(9e7, 9e8, 9e7), Vector3.new(9e8, 9e8, 9e8) end end; local dl, ag = tick() + 2, 0; workspace.FallenPartsDestroyHeight = 0/0; myHum:SetStateEnabled(Enum.HumanoidStateType.Seated, false); repeat if not myHrp or not tHum then break end; local tPart = tHrp or tHead or handle; if not tPart then break end; if tPart.Velocity.Magnitude < 50 then ag = ag + 100; local cf = CFrame.Angles(math.rad(ag), 0, 0); local mv = tHum.MoveDirection * tPart.Velocity.Magnitude / 1.25; FPos(tPart, CFrame.new(0, 1.5, 0) + mv, cf); task.wait(); FPos(tPart, CFrame.new(0, -1.5, 0) + mv, cf); task.wait() else local ws = tHum.WalkSpeed; FPos(tPart, CFrame.new(0, 1.5, ws), CFrame.Angles(math.rad(90), 0, 0)); task.wait(); FPos(tPart, CFrame.new(0, -1.5, -ws), CFrame.new()); task.wait() end until tick() > dl or not S.isFlingActive; mover:Destroy(); myHum:SetStateEnabled(Enum.HumanoidStateType.Seated, true); if flingOldPos then myHrp.CFrame = flingOldPos * CFrame.new(0, 0.5, 0); myChar:PivotTo(myHrp.CFrame); myHum:ChangeState(Enum.HumanoidStateType.GettingUp); task.wait() end; workspace.FallenPartsDestroyHeight = -500 end
UI.flingBtn.MouseButton1Click:Connect(function() if S.isFlingActive then S.isFlingActive = false; UI.flingBtn.Text, UI.flingBtn.BackgroundColor3 = "Classic Fling Player", T.ElemBG; return end; local t = FindPlayer(UI.trollBox.Text); if not t then return end; S.isFlingActive = true; UI.flingBtn.Text, UI.flingBtn.BackgroundColor3 = "Stop Fling", T.Troll; task.spawn(function() while S.isFlingActive do pcall(doFling, t); task.wait(0.1) end; UI.flingBtn.Text, UI.flingBtn.BackgroundColor3 = "Classic Fling Player", T.ElemBG end) end)
UI.touchFlingBtn.MouseButton1Click:Connect(function() S.isTouchFling = not S.isTouchFling; if S.isTouchFling then UI.touchFlingBtn.BackgroundColor3, UI.touchFlingBtn.Text = T.Troll, "Touch Fling: ON"; local ml = 0.1; track("tFling", RunService.Heartbeat:Connect(function() pcall(function() local h = player.Character.HumanoidRootPart; local v = h.Velocity; h.Velocity = v * 10000 + Vector3.new(0, 10000, 0); RunService.RenderStepped:Wait(); h.Velocity = v; RunService.Stepped:Wait(); h.Velocity = v + Vector3.new(0, ml, 0); ml = -ml end) end)) else untrack("tFling"); UI.touchFlingBtn.BackgroundColor3, UI.touchFlingBtn.Text = T.ElemBG, "Touch Fling (Toggle)" end end)

local hasSHP = (typeof(sethiddenproperty) == "function")
local NAN_VEC = Vector3.new(0/0, 0/0, 0/0)
local function applyNanFling(tHrp, myHrp, myHum) myHrp.CFrame, myHrp.AssemblyLinearVelocity, myHrp.AssemblyAngularVelocity = tHrp.CFrame, NAN_VEC, NAN_VEC; pcall(function() myHum.PlatformStand = true; myHum:Move(NAN_VEC) end); if hasSHP then pcall(function() sethiddenproperty(myHrp, "PhysicsRepRootPart", tHrp) end) end end

local function ToggleNanFling() 
    S.isNanFling = not S.isNanFling; if S.isNanFling then 
        if S.nanMode == "target" then 
            local t = FindPlayer(UI.trollBox.Text); if not (t and t.Character and t.Character:FindFirstChild("HumanoidRootPart")) then UI.trollBox.Text = "Not found!"; task.wait(1); UI.trollBox.Text = ""; S.isNanFling = false; return end; S.nanFlingTarget = t 
        end; 
        
        UI.nanFlingBtn.BackgroundColor3 = T.Troll;
        UI.nanFlingBtn.TextColor3 = Color3.fromRGB(20,20,20); UI.nanFlingBtn.Text = "NaN Fling: ON" .. (hasSHP and " [SHP]" or ""); S.nanFlingConn = track("nanFling", RunService.Heartbeat:Connect(function() 
            local myChar = player.Character; local myHum, myHrp = myChar and myChar:FindFirstChildOfClass("Humanoid"), myChar and myChar:FindFirstChild("HumanoidRootPart"); 
            if not myHrp then return end; 
            if S.nanMode == "target" then 
                if not (S.nanFlingTarget and S.nanFlingTarget.Character) then ToggleNanFling(); return end; 
                local tHrp = S.nanFlingTarget.Character:FindFirstChild("HumanoidRootPart"); 
                if tHrp then applyNanFling(tHrp, myHrp, myHum) end 
            else 
                for _, p in ipairs(Players:GetPlayers()) do 
                    if p ~= player and p.Character then 
                        local tHrp = p.Character:FindFirstChild("HumanoidRootPart"); 
                        if tHrp and (myHrp.Position - tHrp.Position).Magnitude <= 15 then applyNanFling(tHrp, myHrp, myHum) end 
                    end 
                end 
            end 
        end)) 
    else 
        untrack("nanFling"); S.nanFlingConn, S.nanFlingTarget = nil, nil; 
        pcall(function() player.Character.Humanoid.PlatformStand = false end); 
        
        UI.nanFlingBtn.BackgroundColor3 = T.ElemBG;
        UI.nanFlingBtn.TextColor3 = T.TextMain; UI.nanFlingBtn.Text = "NaN Fling (Toggle)" 
    end 
end

UI.nanModeBtn.MouseButton1Click:Connect(function() S.nanMode = S.nanMode == "area" and "target" or "area"; UI.nanModeBtn.Text = S.nanMode == "area" and "Mode: Area (Nearby)" or "Mode: Target"; UI.nanModeBtn.BackgroundColor3 = S.nanMode == "area" and T.ElemBG or T.AccentON end)

local curW, wThrd, WG = nil, nil, randName(12)
pcall(function() game:GetService("PhysicsService"):RegisterCollisionGroup(WG); game:GetService("PhysicsService"):CollisionGroupSetCollidable(WG, WG, true) end)
local function stpW() if wThrd then task.cancel(wThrd); wThrd = nil end; if curW then pcall(function() curW.p:Destroy() end); for pt, pr in pairs(curW.op) do pcall(function() pt.CollisionGroup, pt.CanCollide = pr.g, pr.c end) end; pcall(function() player.Character.Humanoid.RequiresNeck = true; if curW.at then curW.at:Stop() end end); curW = nil end; workspace.FallenPartsDestroyHeight = FPDH; for _,b in ipairs({UI.weldBangBtn, UI.weldStandBtn, UI.weldAttackBtn, UI.weldHeadBtn, UI.weldBackBtn, UI.weldCarpetBtn, UI.weldBehindBtn, UI.weldCustomBtn}) do b.BackgroundColor3, b.TextColor3 = T.ElemBG, T.TextMain end end
local function strW(tR, off, aId) stpW(); local mC, mR, mH = player.Character, player.Character and player.Character:FindFirstChild("HumanoidRootPart"), player.Character and player.Character:FindFirstChild("Humanoid"); if not mR then return end; workspace.FallenPartsDestroyHeight = 0/0; local wp = Instance.new("Part", workspace.Terrain); wp.Size, wp.Transparency, wp.CollisionGroup = Vector3.new(25, 3, 25), 1, WG; local op = {}; for _,p in ipairs(mC:GetDescendants()) do if p:IsA("BasePart") then op[p] = {g = p.CollisionGroup, c = p.CanCollide}; p.CollisionGroup, p.CanCollide = WG, true end end; pcall(function() mH.RequiresNeck = false end); local at = nil; if aId ~= 0 then pcall(function() local anim = Instance.new("Animation"); anim.AnimationId = "rbxassetid://"..aId; at = mC:FindFirstChildWhichIsA("Animator", true):LoadAnimation(anim); at:Play() end) end; curW = {p = wp, op = op, at = at}; wThrd = task.spawn(function() while curW do pcall(function() wp.CFrame, mR.CFrame, wp.AssemblyLinearVelocity, mR.AssemblyLinearVelocity = tR.CFrame, tR.CFrame * off, Vector3.zero, Vector3.zero; RunService.RenderStepped:Wait(); wp.CFrame, mR.CFrame, wp.AssemblyLinearVelocity = tR.CFrame, tR.CFrame * CFrame.new(0, 4, 0), Vector3.zero end); task.wait() end end) end
local poses = {bang = {CFrame.new(0,0,-2)*CFrame.Angles(0,math.rad(180),0), 148840371}, stand = {CFrame.new(1.5,1.25,2), 313762630}, attack = {CFrame.new(0,0,-1.25)*CFrame.Angles(0,math.rad(180),0), 259438880}, head = {CFrame.new(0,3,0), 178130996}, back = {CFrame.new(0,0,1.05)*CFrame.Angles(0,math.rad(180),0), 178130996}, carpet = {CFrame.new(0,-1,0), 282574440}, behind = {CFrame.new(0,0,2), 0}}
local function doWeld(nm, btn) local t = FindPlayer(UI.trollBox.Text); if not t then return end; local tR = t.Character and t.Character:FindFirstChild("HumanoidRootPart"); if tR then strW(tR, poses[nm][1], poses[nm][2]); btn.BackgroundColor3, btn.TextColor3 = T.AccentON, Color3.fromRGB(20,20,25) end end
UI.weldBangBtn.MouseButton1Click:Connect(function() doWeld("bang", UI.weldBangBtn) end); UI.weldStandBtn.MouseButton1Click:Connect(function() doWeld("stand", UI.weldStandBtn) end); UI.weldAttackBtn.MouseButton1Click:Connect(function() doWeld("attack", UI.weldAttackBtn) end); UI.weldHeadBtn.MouseButton1Click:Connect(function() doWeld("head", UI.weldHeadBtn) end); UI.weldBackBtn.MouseButton1Click:Connect(function() doWeld("back", UI.weldBackBtn) end); UI.weldCarpetBtn.MouseButton1Click:Connect(function() doWeld("carpet", UI.weldCarpetBtn) end); UI.weldBehindBtn.MouseButton1Click:Connect(function() doWeld("behind", UI.weldBehindBtn) end); UI.weldUnweldBtn.MouseButton1Click:Connect(stpW)

UI.weldPushBtn.MouseButton1Click:Connect(function() S.isPushing = not S.isPushing; if S.isPushing then local t = FindPlayer(UI.trollBox.Text); if not t then S.isPushing = false; return end; UI.weldPushBtn.BackgroundColor3, UI.weldPushBtn.Text = T.Troll, "Pushing..."; local f = 0; track("wPush", RunService.Heartbeat:Connect(function() pcall(function() local tR = t.Character.HumanoidRootPart; f = math.min(f+2, 80); tR.AssemblyLinearVelocity = tR.CFrame.LookVector * f; if curW then player.Character.HumanoidRootPart.CFrame = tR.CFrame * CFrame.new(0,0,1.5) end end) end)) else untrack("wPush"); UI.weldPushBtn.BackgroundColor3, UI.weldPushBtn.Text = T.ElemBG, "Push" end end)
UI.weldCustomBtn.MouseButton1Click:Connect(function() local p = UI.trollBox.Text:split(" "); local t = FindPlayer(p[1]); if t then pcall(function() strW(t.Character.HumanoidRootPart, CFrame.new(tonumber(p[2]) or 0, tonumber(p[3]) or 0, tonumber(p[4]) or 1.3), 0); UI.weldCustomBtn.BackgroundColor3 = T.AccentON end) end end)

local spinTarget, followTarget = nil, nil
UI.spinBtn.MouseButton1Click:Connect(function() S.isSpinning = not S.isSpinning; if S.isSpinning then spinTarget = FindPlayer(UI.trollBox.Text); if spinTarget then UI.spinBtn.BackgroundColor3, UI.spinBtn.Text = T.Troll, "Stop Spin"; track("spin", RunService.Stepped:Connect(function() pcall(function() spinTarget.Character.HumanoidRootPart.CFrame *= CFrame.Angles(0, math.rad(18), 0) end) end)) else S.isSpinning = false end else untrack("spin"); UI.spinBtn.BackgroundColor3, UI.spinBtn.Text = T.ElemBG, "Spin Player (Toggle)" end end)

UI.followBtn.MouseButton1Click:Connect(function()
    S.isFollowing = not S.isFollowing
    setBtn(UI.followBtn, S.isFollowing)
    if S.isFollowing then
        local target = FindPlayer(UI.trollBox.Text)
        if target then
            track("fol", RunService.Heartbeat:Connect(function()
                pcall(function()
                    local char = player.Character; local hrp = char.HumanoidRootPart; local hum = char.Humanoid
                    local tHrp = target.Character.HumanoidRootPart
                    hum:ChangeState(Enum.HumanoidStateType.Physics)
                    hrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, 0.5)
                    hrp.AssemblyLinearVelocity, hrp.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
                    for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
                end)
            end))
        else S.isFollowing = false; setBtn(UI.followBtn, false) end
    else untrack("fol") end
end)

local function ToggleThirdPerson()
    setupIndexHooks(); S.isForceThirdPerson = not S.isForceThirdPerson
    setBtn(UI.thirdPersonBtn, S.isForceThirdPerson)
    if S.isForceThirdPerson then player.CameraMode = Enum.CameraMode.Classic; player.CameraMaxZoomDistance = 128 end
end

local function Panic() for l, _ in pairs(Connections) do untrack(l) end; if S.isFlying then StopFly(); setBtn(UI.flyBtn, false) end; pcall(function() local h = player.Character.Humanoid; h.WalkSpeed, h.UseJumpPower, h.JumpPower = 16, true, 50 end); setBtn(UI.walkBtn, false); setBtn(UI.jumpBtn, false); setBtn(UI.tpJumpBtn, false); if S.isNoclip then ToggleNoclip() end; if S.isESP then ToggleESP() end; if S.isFakeInvis then ToggleFakeInvis() end; if S.mouseTpMode then StopMouseTP() end; if S.isAntiFling then ToggleAntiFling() end; if S.isFOV then ToggleFOV() end; if S.isZoom then ToggleZoom() end; if S.isBlink then ToggleBlink() end; if S.isNanFling then ToggleNanFling() end; if S.isInstantPrompt then ToggleInstantPrompt() end; if S.isAutoPrompt then ToggleAutoPrompt() end; stpW(); titleLbl.Text, titleLbl.TextColor3 = "PANIC RESET", T.Troll; task.delay(1.5, function() titleLbl.Text, titleLbl.TextColor3 = "LAI ADMIN", T.TextMain end) end

track("input", UserInputService.InputBegan:Connect(function(i, gp) 
    if S.listenAct then 
        if i.UserInputType == Enum.UserInputType.Keyboard then 
            if i.KeyCode == Enum.KeyCode.Escape then keybinds[S.listenAct] = Enum.KeyCode.Unknown else keybinds[S.listenAct] = i.KeyCode end
            updateBindTexts[S.listenAct](); S.listenAct, S.listenBtn = nil, nil 
        end 
        return 
    end
    if gp then return end
    if i.KeyCode == Enum.KeyCode.RightShift then Panic(); return end
    if i.KeyCode == keybinds.Menu then S.isMenuOpen = not S.isMenuOpen; TweenService:Create(main, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = S.isMenuOpen and openPos or closedPos}):Play(); TweenService:Create(shadow, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = S.isMenuOpen and UDim2.new(0,14,0.5,-253) or UDim2.new(0,-326,0.5,-253)}):Play() end
    
    local function tr(k, f) if k ~= Enum.KeyCode.Unknown and i.KeyCode == k then f() end end
    
    tr(keybinds.Fly, ToggleFly); tr(keybinds.WalkSpeed, ToggleWalkSpeed); tr(keybinds.JumpPower, ToggleJumpPower); tr(keybinds.InfJump, ToggleInfJump); tr(keybinds.Noclip, ToggleNoclip); tr(keybinds.ESP, ToggleESP); tr(keybinds.SelfFreeze, ToggleSelfFreeze); tr(keybinds.FakeInvis, ToggleFakeInvis); tr(keybinds.AntiFling, ToggleAntiFling); tr(keybinds.BypassAC, ToggleBypassAC); tr(keybinds.FOV, ToggleFOV); tr(keybinds.MaxZoom, ToggleZoom); tr(keybinds.AntiLagback, ToggleAntiLagback); tr(keybinds.TpJump, ToggleTpJump)
    tr(keybinds.Blink, ToggleBlink); tr(keybinds.NanFling, ToggleNanFling); tr(keybinds.RemoteBlock, ToggleRemoteBlock); tr(keybinds.NoStun, ToggleNoStun); tr(keybinds.RemoteBypass, ToggleRemoteBypass); tr(keybinds.GodMode, ToggleGodMode); tr(keybinds.ThirdPerson, ToggleThirdPerson); tr(keybinds.ShiftLock, ToggleShiftLock); tr(keybinds.InstantPrompt, ToggleInstantPrompt); tr(keybinds.AutoPrompt, ToggleAutoPrompt)

    if keybinds.Freeze ~= Enum.KeyCode.Unknown and i.KeyCode == keybinds.Freeze then local t = FindPlayer(UI.trollBox.Text); if t and t.Character then untrack("frz"); frozenTarget, frozenCF = t, t.Character.HumanoidRootPart.CFrame; track("frz", RunService.Heartbeat:Connect(function() pcall(function() frozenTarget.Character.HumanoidRootPart.CFrame = frozenCF end) end)); UI.freezeBtn.Text = "Frozen: " .. t.Name end end 
end))

local function ToggleShiftLock()
    setupIndexHooks()
    S.isUnlockShiftLock = not S.isUnlockShiftLock
    setBtn(UI.shiftLockBtn, S.isUnlockShiftLock)
    
    if S.isUnlockShiftLock then 
        pcall(function() player.DevEnableMouseLock = true end)
        track("mouseUnlock", RunService.RenderStepped:Connect(function()
            pcall(function() 
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default 
                UserInputService.MouseIconEnabled = true
            end)
        end))
    else
        untrack("mouseUnlock")
    end
end

UI.flyBtn.MouseButton1Click:Connect(ToggleFly); UI.walkBtn.MouseButton1Click:Connect(ToggleWalkSpeed); UI.blinkBtn.MouseButton1Click:Connect(ToggleBlink); UI.jumpBtn.MouseButton1Click:Connect(ToggleJumpPower); UI.infJumpBtn.MouseButton1Click:Connect(ToggleInfJump); UI.noclipBtn.MouseButton1Click:Connect(ToggleNoclip); UI.selfFrzBtn.MouseButton1Click:Connect(ToggleSelfFreeze); UI.fakeInvisBtn.MouseButton1Click:Connect(ToggleFakeInvis); UI.antiFlingBtn.MouseButton1Click:Connect(ToggleAntiFling); UI.bypassAcBtn.MouseButton1Click:Connect(function() setupIndexHooks(); S.isBypassAC = not S.isBypassAC; setBtn(UI.bypassAcBtn, S.isBypassAC) end); UI.espBtn.MouseButton1Click:Connect(ToggleESP); UI.tpJumpBtn.MouseButton1Click:Connect(ToggleTpJump); UI.antiLagbackBtn.MouseButton1Click:Connect(ToggleAntiLagback); UI.nanFlingBtn.MouseButton1Click:Connect(ToggleNanFling)
UI.noStunBtn.MouseButton1Click:Connect(function() setupIndexHooks(); S.isNoStun = not S.isNoStun; setBtn(UI.noStunBtn, S.isNoStun) end); UI.remoteBypassBtn.MouseButton1Click:Connect(function() setupNamecallHook(); S.isRemoteBypass = not S.isRemoteBypass; setBtn(UI.remoteBypassBtn, S.isRemoteBypass) end); UI.godModeBtn.MouseButton1Click:Connect(function() setupIndexHooks(); S.isGodMode = not S.isGodMode; setBtn(UI.godModeBtn, S.isGodMode) end); UI.remoteBlockBtn.MouseButton1Click:Connect(function() setupNamecallHook(); S.isRemoteBlock = not S.isRemoteBlock; setBtn(UI.remoteBlockBtn, S.isRemoteBlock) end)
UI.thirdPersonBtn.MouseButton1Click:Connect(ToggleThirdPerson)
UI.shiftLockBtn.MouseButton1Click:Connect(ToggleShiftLock)
UI.instantPromptBtn.MouseButton1Click:Connect(ToggleInstantPrompt)
UI.autoPromptBtn.MouseButton1Click:Connect(ToggleAutoPrompt)

-- [NUKE AC]
UI.nukeAcBtn.MouseButton1Click:Connect(function()
    local count = 0
    local susWords = {"kick", "ban", "exploit", "crash", "anticheat"}
    for _, v in pairs(getgc(true)) do
        if type(v) == "function" and islclosure(v) then
            local s, consts = pcall(debug.getconstants, v)
            if s and consts and not table.find(consts, "LAI_ADMIN_SAFE_FUNC") then
                local level = 0
                for _, c in pairs(consts) do if type(c) == "string" then for _, w in ipairs(susWords) do if c:lower():find(w) then level = level + 1 end end end end
                if level >= 2 then hookfunction(v, newcclosure(function() return end)); count = count + 1 end
            end
        end
    end
    UI.nukeAcBtn.Text = "Nuked: " .. count .. " funcs"; UI.nukeAcBtn.BackgroundColor3 = T.AccentON; UI.nukeAcBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
    task.delay(3, function() UI.nukeAcBtn.Text = "Nuke Anti-Cheat (Universal)"; UI.nukeAcBtn.BackgroundColor3 = T.ElemBG; UI.nukeAcBtn.TextColor3 = T.TextMain end)
end)

player.CharacterAdded:Connect(function(char) task.wait(0.3); if S.isWalk then untrack("walk"); pcall(function() player.Character.Humanoid.WalkSpeed = 16 end); ToggleWalkSpeed() end; if S.isJump then applyJump() end; if S.isFlying then StopFly(); S.isFlying = false; task.wait(0.15); ToggleFly() end; if S.isNoclip then task.wait(0.1); nocParts = {}; for _,p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then nocParts[#nocParts+1] = p end end end; if S.isFakeInvis then S.isFakeInvis = false; untrack("fInvSim"); RunService:UnbindFromRenderStep("fInvCam"); task.wait(0.1); ToggleFakeInvis() end end)
UI.safeExitBtn.MouseButton1Click:Connect(function() pcall(function() UI.safeExitBtn.Text = "Disconnecting safely..."; local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart"); if hrp then hrp.Anchored = true end; if S.isESP then ToggleESP() end; task.wait(1.5); game:Shutdown() end) end)

S.speedMode = "GodMove"; UI.speedModeBtn.Text = "Speed Mode: GodMove (Physics)"
UI.speedModeBtn.MouseButton1Click:Connect(function()
    if S.speedMode == "Stealth" then S.speedMode = "Classic"; UI.speedModeBtn.Text = "Speed Mode: Classic (Risk)";
    elseif S.speedMode == "Classic" then S.speedMode = "GodMove"; UI.speedModeBtn.Text = "Speed Mode: GodMove (Physics)"; 
    else S.speedMode = "Stealth"; UI.speedModeBtn.Text = "Speed Mode: Stealth (Safe)"; end
    if S.isWalk then ToggleWalkSpeed() ToggleWalkSpeed() end
end)

task.wait(0.5)
pcall(function() ToggleAntiFling() end)
warn("[LAI ADMIN v6.2] 360 Fly Mod Applied! Enjoy!")
