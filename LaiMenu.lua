local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- ==========================================
-- 1. Keybind Dictionary & Listener
-- ==========================================
local keybinds = {
	Menu = Enum.KeyCode.F1,
	Fly = Enum.KeyCode.E,
	WalkSpeed = Enum.KeyCode.R,
	JumpPower = Enum.KeyCode.J,
	InfJump = Enum.KeyCode.K,
	ESP = Enum.KeyCode.V,
	Noclip = Enum.KeyCode.N
}

local listeningForAction = nil
local listeningButton = nil
local currentEspColor = Color3.fromRGB(0, 170, 255) 
local currentFlyMode = "Camera"

-- Theme Colors
local Theme = {
	MainBG = Color3.fromRGB(15, 15, 20),
	ElementBG = Color3.fromRGB(30, 30, 40),
	ElementHover = Color3.fromRGB(45, 45, 55),
	AccentON = Color3.fromRGB(0, 170, 255), 
	AccentOFF = Color3.fromRGB(30, 30, 40),
	TextMain = Color3.fromRGB(255, 255, 255),
	TextSub = Color3.fromRGB(180, 180, 200),
	Border = Color3.fromRGB(45, 45, 60)
}

-- ==========================================
-- 2. Create the Modern GUI Elements
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LaiAdminGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 280, 0, 500) 
mainFrame.Position = UDim2.new(0, 20, 0.5, -250)
mainFrame.BackgroundColor3 = Theme.MainBG
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Theme.Border
mainStroke.Thickness = 1.5
mainStroke.Parent = mainFrame

-- Title Area
local titleFrame = Instance.new("Frame")
titleFrame.Size = UDim2.new(1, 0, 0, 40)
titleFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
titleFrame.BorderSizePixel = 0
titleFrame.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleFrame

local titleGradient = Instance.new("UIGradient")
titleGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 30, 50)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 15, 25))
})
titleGradient.Parent = titleFrame

local titleBottomCover = Instance.new("Frame")
titleBottomCover.Size = UDim2.new(1, 0, 0, 10)
titleBottomCover.Position = UDim2.new(0, 0, 1, -10)
titleBottomCover.BackgroundColor3 = Color3.fromRGB(10, 15, 25)
titleBottomCover.BorderSizePixel = 0
titleBottomCover.Parent = titleFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
titleLabel.Position = UDim2.new(0.05, 0, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "LAI ADMIN"
titleLabel.TextColor3 = Theme.TextMain
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 16
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleFrame

local menuBindBtn = Instance.new("TextButton")
menuBindBtn.Size = UDim2.new(0.2, 0, 0.6, 0)
menuBindBtn.Position = UDim2.new(0.75, 0, 0.2, 0)
menuBindBtn.BackgroundColor3 = Theme.ElementHover
menuBindBtn.TextColor3 = Theme.AccentON
menuBindBtn.Font = Enum.Font.GothamBold
menuBindBtn.TextSize = 12
menuBindBtn.Text = "[" .. keybinds.Menu.Name .. "]"
menuBindBtn.Parent = titleFrame

local menuBindCorner = Instance.new("UICorner")
menuBindCorner.CornerRadius = UDim.new(0, 6)
menuBindCorner.Parent = menuBindBtn

-- ==========================================
-- 3. Create the 3-Tab System (Trở lại kiểu Button khối)
-- ==========================================
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, 0, 0, 35)
tabBar.Position = UDim2.new(0, 0, 0, 40)
tabBar.BackgroundColor3 = Theme.MainBG
tabBar.BorderSizePixel = 0
tabBar.Parent = mainFrame

local mainTabBtn = Instance.new("TextButton")
mainTabBtn.Size = UDim2.new(0.33, 0, 1, 0)
mainTabBtn.BackgroundColor3 = Theme.ElementHover -- Active color
mainTabBtn.Text = "Main"
mainTabBtn.TextColor3 = Theme.TextMain
mainTabBtn.Font = Enum.Font.GothamBold
mainTabBtn.TextSize = 13
mainTabBtn.BorderSizePixel = 0
mainTabBtn.Parent = tabBar

local tpTabBtn = Instance.new("TextButton")
tpTabBtn.Size = UDim2.new(0.34, 0, 1, 0)
tpTabBtn.Position = UDim2.new(0.33, 0, 0, 0)
tpTabBtn.BackgroundColor3 = Theme.MainBG
tpTabBtn.Text = "Teleport"
tpTabBtn.TextColor3 = Theme.TextSub
tpTabBtn.Font = Enum.Font.GothamBold
tpTabBtn.TextSize = 13
tpTabBtn.BorderSizePixel = 0
tpTabBtn.Parent = tabBar

local emotesTabBtn = Instance.new("TextButton")
emotesTabBtn.Size = UDim2.new(0.33, 0, 1, 0)
emotesTabBtn.Position = UDim2.new(0.67, 0, 0, 0)
emotesTabBtn.BackgroundColor3 = Theme.MainBG
emotesTabBtn.Text = "Emotes"
emotesTabBtn.TextColor3 = Theme.TextSub
emotesTabBtn.Font = Enum.Font.GothamBold
emotesTabBtn.TextSize = 13
emotesTabBtn.BorderSizePixel = 0
emotesTabBtn.Parent = tabBar

local function createContainer(name, visible)
	local container = Instance.new("ScrollingFrame")
	container.Name = name
	container.Size = UDim2.new(1, 0, 1, -85)
	container.Position = UDim2.new(0, 0, 0, 80)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.ScrollBarThickness = 3
	container.ScrollBarImageColor3 = Theme.AccentON
	container.Visible = visible
	container.AutomaticCanvasSize = Enum.AutomaticSize.Y
	container.CanvasSize = UDim2.new(0, 0, 0, 0)
	container.Parent = mainFrame
	
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = container
	
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.Parent = container
	
	return container
end

local mainContainer = createContainer("MainContainer", true)
local tpContainer = createContainer("TpContainer", false)
local emotesContainer = createContainer("EmotesContainer", false)

-- Helper Functions
local function addStroke(obj)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Border
	stroke.Thickness = 1
	stroke.Parent = obj
end

local function createFeatureRow(parent, text, actionName, layoutOrder)
	local rowFrame = Instance.new("Frame")
	rowFrame.Size = UDim2.new(0.9, 0, 0, 36)
	rowFrame.BackgroundTransparency = 1
	rowFrame.LayoutOrder = layoutOrder
	rowFrame.Parent = parent
	
	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Size = UDim2.new(0.75, -6, 1, 0)
	toggleBtn.BackgroundColor3 = Theme.ElementBG
	toggleBtn.TextColor3 = Theme.TextMain
	toggleBtn.Font = Enum.Font.GothamSemibold
	toggleBtn.TextSize = 13
	toggleBtn.Text = text
	toggleBtn.Parent = rowFrame
	Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)
	addStroke(toggleBtn)
	
	local bindBtn = Instance.new("TextButton")
	bindBtn.Size = UDim2.new(0.25, 0, 1, 0)
	bindBtn.Position = UDim2.new(0.75, 6, 0, 0)
	bindBtn.BackgroundColor3 = Theme.ElementHover
	bindBtn.TextColor3 = Theme.AccentON
	bindBtn.Font = Enum.Font.GothamBold
	bindBtn.TextSize = 12
	bindBtn.Text = "[" .. keybinds[actionName].Name .. "]"
	bindBtn.Parent = rowFrame
	Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0, 6)
	addStroke(bindBtn)
	
	bindBtn.MouseButton1Click:Connect(function()
		listeningForAction = actionName
		listeningButton = bindBtn
		bindBtn.Text = "..."
	end)
	
	return toggleBtn
end

local function createInput(parent, text, layoutOrder)
	local input = Instance.new("TextBox")
	input.Size = UDim2.new(0.9, 0, 0, 32)
	input.BackgroundColor3 = Theme.ElementBG
	input.TextColor3 = Theme.AccentON
	input.Font = Enum.Font.GothamBold
	input.TextSize = 13
	input.LayoutOrder = layoutOrder
	input.PlaceholderText = text
	input.PlaceholderColor3 = Theme.TextSub
	input.Text = ""
	Instance.new("UICorner", input).CornerRadius = UDim.new(0, 6)
	addStroke(input)
	input.Parent = parent
	return input
end

local function createSimpleButton(parent, text, bgColor, layoutOrder)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.9, 0, 0, 34)
	btn.BackgroundColor3 = bgColor or Theme.ElementBG
	btn.TextColor3 = Theme.TextMain
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.Text = text
	btn.LayoutOrder = layoutOrder
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	addStroke(btn)
	btn.Parent = parent
	return btn
end

local function createPresetRow(parent, labelText, presets, targetInputBox, layoutOrder)
	local rowFrame = Instance.new("Frame")
	rowFrame.Size = UDim2.new(0.9, 0, 0, 26)
	rowFrame.BackgroundTransparency = 1
	rowFrame.LayoutOrder = layoutOrder
	rowFrame.Parent = parent
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.35, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextColor3 = Theme.TextSub
	label.Font = Enum.Font.GothamSemibold
	label.TextSize = 11
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = rowFrame
	
	local btnWidth = 0.6 / #presets
	for i, val in ipairs(presets) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(btnWidth, -4, 1, 0)
		btn.Position = UDim2.new(0.35 + (btnWidth * (i - 1)), 2, 0, 0)
		btn.BackgroundColor3 = Theme.ElementHover
		btn.TextColor3 = Theme.TextMain
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 11
		btn.Text = tostring(val)
		btn.Parent = rowFrame
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
		addStroke(btn)
		
		btn.MouseButton1Click:Connect(function()
			targetInputBox.Text = tostring(val)
		end)
	end
end

-- ==========================================
-- 4. Populate UI
-- ==========================================
-- Main Tab
local flyButton = createFeatureRow(mainContainer, "Toggle Fly", "Fly", 1)
local flyModeBtn = createSimpleButton(mainContainer, "Fly Mode: Camera", Theme.ElementBG, 2)
local flySpeedInput = createInput(mainContainer, "Fly Speed (Def: 50)", 3)
flySpeedInput.Text = "50"
createPresetRow(mainContainer, "Speed:", {50, 100, 300}, flySpeedInput, 4)

local walkButton = createFeatureRow(mainContainer, "Toggle WalkSpeed", "WalkSpeed", 5)
local walkSpeedInput = createInput(mainContainer, "Walk Speed (Def: 16)", 6)
walkSpeedInput.Text = "16"
createPresetRow(mainContainer, "Speed:", {16, 50, 100}, walkSpeedInput, 7)

local jumpButton = createFeatureRow(mainContainer, "Toggle JumpPower", "JumpPower", 8)
local jumpInput = createInput(mainContainer, "Jump Power (Def: 50)", 9)
jumpInput.Text = "50"
createPresetRow(mainContainer, "Power:", {50, 100, 250}, jumpInput, 10)

local infJumpButton = createFeatureRow(mainContainer, "Infinite Jump", "InfJump", 11)
local noclipButton = createFeatureRow(mainContainer, "Toggle Noclip", "Noclip", 12)
local espButton = createFeatureRow(mainContainer, "Toggle ESP", "ESP", 13)

-- Teleport Tab
local tpInput = createInput(tpContainer, "Player Name (ex: rob...)", 1)
local tpInstantBtn = createSimpleButton(tpContainer, "⚡ Instant Teleport", Color3.fromRGB(80, 40, 150), 2)
local tpDashBtn = createSimpleButton(tpContainer, "☄️ Dash Teleport", Color3.fromRGB(200, 90, 40), 3)

-- Emotes Tab
local emoteList = {"wave", "point", "dance", "dance2", "dance3", "laugh", "cheer", "salute", "stadium", "tilt", "shrug"}
local emoteButtons = {}

for i, emoteName in ipairs(emoteList) do
	local btn = createSimpleButton(emotesContainer, "▶ " .. emoteName, Theme.ElementBG, i)
	emoteButtons[emoteName] = btn
end

-- Tab Switching Logic (Cập nhật màu Nút)
local function switchTab(activeBtn, activeContainer)
	mainContainer.Visible = false
	tpContainer.Visible = false
	emotesContainer.Visible = false
	
	mainTabBtn.BackgroundColor3 = Theme.MainBG
	tpTabBtn.BackgroundColor3 = Theme.MainBG
	emotesTabBtn.BackgroundColor3 = Theme.MainBG
	mainTabBtn.TextColor3 = Theme.TextSub
	tpTabBtn.TextColor3 = Theme.TextSub
	emotesTabBtn.TextColor3 = Theme.TextSub
	
	activeContainer.Visible = true
	activeBtn.BackgroundColor3 = Theme.ElementHover
	activeBtn.TextColor3 = Theme.TextMain
end

mainTabBtn.MouseButton1Click:Connect(function() switchTab(mainTabBtn, mainContainer) end)
tpTabBtn.MouseButton1Click:Connect(function() switchTab(tpTabBtn, tpContainer) end)
emotesTabBtn.MouseButton1Click:Connect(function() switchTab(emotesTabBtn, emotesContainer) end)

-- ==========================================
-- 5. Logic Functions
-- ==========================================
local isFlying, isCustomWalk, isCustomJump, isInfJump, isNoclipping, isESP = false, false, false, false, false, false
local bodyVelocity, bodyGyro
local flyConnection, walkConnection, jumpConnection, infJumpConnection, noclipConnection

local function updateButtonState(btn, isOn)
	if isOn then
		btn.BackgroundColor3 = Theme.AccentON
		btn.TextColor3 = Color3.fromRGB(25, 25, 30) 
	else
		btn.BackgroundColor3 = Theme.ElementBG
		btn.TextColor3 = Theme.TextMain
	end
end

-- Teleport Logic
local function FindPlayer(partialName)
	if not partialName or partialName == "" then return nil end
	local lowerName = string.lower(partialName)
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= player then
			if string.sub(string.lower(p.Name), 1, #lowerName) == lowerName or string.sub(string.lower(p.DisplayName), 1, #lowerName) == lowerName then
				return p
			end
		end
	end
	return nil
end

tpInstantBtn.MouseButton1Click:Connect(function()
	local targetPlayer = FindPlayer(tpInput.Text)
	if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
		local myChar = player.Character
		if myChar and myChar:FindFirstChild("HumanoidRootPart") then
			myChar.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
		end
	else
		tpInput.Text = "Not found!"
		task.wait(1)
		tpInput.Text = ""
	end
end)

tpDashBtn.MouseButton1Click:Connect(function()
	local targetPlayer = FindPlayer(tpInput.Text)
	if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
		local myChar = player.Character
		local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
		local targetHrp = targetPlayer.Character.HumanoidRootPart
		if myHrp then
			local distance = (myHrp.Position - targetHrp.Position).Magnitude
			local tweenTime = math.clamp(distance / 150, 0.3, 3) 
			local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
			TweenService:Create(myHrp, tweenInfo, {CFrame = targetHrp.CFrame * CFrame.new(0, 0, 3)}):Play()
		end
	else
		tpInput.Text = "Not found!"
		task.wait(1)
		tpInput.Text = ""
	end
end)

-- Fly Logic
flyModeBtn.MouseButton1Click:Connect(function()
	if currentFlyMode == "Camera" then
		currentFlyMode = "Hover"
		flyModeBtn.Text = "Fly Mode: Hover (Space/Ctrl)"
	else
		currentFlyMode = "Camera"
		flyModeBtn.Text = "Fly Mode: Camera"
	end
end)

local function ToggleFly()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChild("Humanoid")
	if not char or not hrp or not hum then return end
	
	isFlying = not isFlying
	updateButtonState(flyButton, isFlying)
	
	if isFlying then
		hum:ChangeState(Enum.HumanoidStateType.Physics)
		bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Velocity = Vector3.new(0,0,0)
		bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		bodyVelocity.Parent = hrp
		bodyGyro = Instance.new("BodyGyro")
		bodyGyro.CFrame = hrp.CFrame
		bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
		bodyGyro.Parent = hrp
		
		flyConnection = RunService.RenderStepped:Connect(function()
			hum:ChangeState(Enum.HumanoidStateType.Physics)
			local moveDir = Vector3.new(0,0,0)
			
			if currentFlyMode == "Camera" then
				if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += camera.CFrame.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= camera.CFrame.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= camera.CFrame.RightVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += camera.CFrame.RightVector end
			else
				local look = camera.CFrame.LookVector
				local right = camera.CFrame.RightVector
				local flatLook = Vector3.new(look.X, 0, look.Z).Unit
				local flatRight = Vector3.new(right.X, 0, right.Z).Unit
				if look.X == 0 and look.Z == 0 then flatLook = Vector3.new(0, 0, 1) end
				
				if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += flatLook end
				if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= flatLook end
				if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= flatRight end
				if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += flatRight end
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0, 1, 0) end
				if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir -= Vector3.new(0, 1, 0) end
			end
			
			local currentFlySpeed = tonumber(flySpeedInput.Text) or 50
			bodyVelocity.Velocity = bodyVelocity.Velocity:Lerp(moveDir * currentFlySpeed, 0.15)
			bodyGyro.CFrame = camera.CFrame
		end)
	else
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		if bodyVelocity then bodyVelocity:Destroy() end
		if bodyGyro then bodyGyro:Destroy() end
		if flyConnection then flyConnection:Disconnect() end
	end
end

local function ToggleWalkSpeed()
	isCustomWalk = not isCustomWalk
	updateButtonState(walkButton, isCustomWalk)
	
	if isCustomWalk then
		walkConnection = RunService.RenderStepped:Connect(function()
			local hum = player.Character and player.Character:FindFirstChild("Humanoid")
			if hum then hum.WalkSpeed = tonumber(walkSpeedInput.Text) or 16 end
		end)
	else
		if walkConnection then walkConnection:Disconnect() end
		local hum = player.Character and player.Character:FindFirstChild("Humanoid")
		if hum then hum.WalkSpeed = 16 end
	end
end

local function ToggleJumpPower()
	isCustomJump = not isCustomJump
	updateButtonState(jumpButton, isCustomJump)
	
	if isCustomJump then
		jumpConnection = RunService.RenderStepped:Connect(function()
			local hum = player.Character and player.Character:FindFirstChild("Humanoid")
			if hum then
				hum.UseJumpPower = true
				hum.JumpPower = tonumber(jumpInput.Text) or 50
			end
		end)
	else
		if jumpConnection then jumpConnection:Disconnect() end
		local hum = player.Character and player.Character:FindFirstChild("Humanoid")
		if hum then
			hum.UseJumpPower = true
			hum.JumpPower = 50
		end
	end
end

local function ToggleInfJump()
	isInfJump = not isInfJump
	updateButtonState(infJumpButton, isInfJump)
	
	if isInfJump then
		infJumpConnection = UserInputService.JumpRequest:Connect(function()
			local hum = player.Character and player.Character:FindFirstChild("Humanoid")
			if hum then
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end)
	else
		if infJumpConnection then infJumpConnection:Disconnect() end
	end
end

local function ToggleNoclip()
	isNoclipping = not isNoclipping
	updateButtonState(noclipButton, isNoclipping)
	
	if isNoclipping then
		noclipConnection = RunService.Stepped:Connect(function()
			if player.Character then
				for _, part in pairs(player.Character:GetDescendants()) do
					if part:IsA("BasePart") and part.CanCollide then
						part.CanCollide = false
					end
				end
			end
		end)
	else
		if noclipConnection then noclipConnection:Disconnect() end
	end
end

local function ToggleESP()
	isESP = not isESP
	updateButtonState(espButton, isESP)
	
	if not isESP then
		for _, p in pairs(Players:GetPlayers()) do
			if p.Character and p.Character:FindFirstChild("AdminESP") then
				p.Character.AdminESP:Destroy()
			end
		end
	end
end

task.spawn(function()
	while task.wait(1) do
		if isESP then
			for _, p in pairs(Players:GetPlayers()) do
				if p ~= player and p.Character and not p.Character:FindFirstChild("AdminESP") then
					local hl = Instance.new("Highlight")
					hl.Name = "AdminESP"
					hl.FillColor = currentEspColor
					hl.OutlineColor = Color3.fromRGB(255, 255, 255)
					hl.FillTransparency = 0.5
					hl.Parent = p.Character
				end
			end
		end
	end
end)

flyButton.MouseButton1Click:Connect(ToggleFly)
walkButton.MouseButton1Click:Connect(ToggleWalkSpeed)
jumpButton.MouseButton1Click:Connect(ToggleJumpPower)
infJumpButton.MouseButton1Click:Connect(ToggleInfJump)
noclipButton.MouseButton1Click:Connect(ToggleNoclip)
espButton.MouseButton1Click:Connect(ToggleESP)

menuBindBtn.MouseButton1Click:Connect(function()
	listeningForAction = "Menu"
	listeningButton = menuBindBtn
	menuBindBtn.Text = "..."
end)

for emoteName, btn in pairs(emoteButtons) do
	btn.MouseButton1Click:Connect(function()
		local char = player.Character
		if char and char:FindFirstChild("Animate") then
			local playEmote = char.Animate:FindFirstChild("PlayEmote")
			if playEmote and playEmote:IsA("BindableFunction") then
				playEmote:Invoke(emoteName)
			end
		end
	end)
end

-- ==========================================
-- 6. Dynamic Keybind Input System (CÓ ESCAPE ĐỂ HỦY)
-- ==========================================
local isMenuOpen = true
local openPosition = UDim2.new(0, 20, 0.5, -250)
local closedPosition = UDim2.new(0, -320, 0.5, -250)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- Đang chờ nhập Keybind mới
	if listeningForAction then
		if input.UserInputType == Enum.UserInputType.Keyboard then
			
			-- NẾU NHẤN ESCAPE -> HỦY THAO TÁC, TRẢ LẠI CHỮ CŨ
			if input.KeyCode == Enum.KeyCode.Escape then
				listeningButton.Text = "[" .. keybinds[listeningForAction].Name .. "]"
				listeningForAction = nil
				listeningButton = nil
				return
			end
			
			-- NẾU NHẤN PHÍM BÌNH THƯỜNG -> GÁN PHÍM
			if input.KeyCode ~= Enum.KeyCode.Unknown then
				keybinds[listeningForAction] = input.KeyCode
				listeningButton.Text = "[" .. input.KeyCode.Name .. "]"
				listeningForAction = nil
				listeningButton = nil
			end
		end
		return 
	end
	
	if gameProcessed then return end 
	
	if input.KeyCode == keybinds.Menu then
		isMenuOpen = not isMenuOpen
		local targetPos = isMenuOpen and openPosition or closedPosition
		TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = targetPos}):Play()
	elseif input.KeyCode == keybinds.Fly then ToggleFly()
	elseif input.KeyCode == keybinds.WalkSpeed then ToggleWalkSpeed()
	elseif input.KeyCode == keybinds.JumpPower then ToggleJumpPower()
	elseif input.KeyCode == keybinds.InfJump then ToggleInfJump()
	elseif input.KeyCode == keybinds.Noclip then ToggleNoclip()
	elseif input.KeyCode == keybinds.ESP then ToggleESP()
	end
end)
