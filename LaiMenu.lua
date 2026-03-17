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
	ESP = Enum.KeyCode.V,
	Noclip = Enum.KeyCode.N
}

local listeningForAction = nil
local listeningButton = nil
local currentEspColor = Color3.fromRGB(255, 0, 0)
local currentFlyMode = "Camera"

-- ==========================================
-- 2. Create the Main GUI Elements
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LaiAdminGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 260, 0, 480) 
mainFrame.Position = UDim2.new(0, 20, 0.5, -240)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 10)
frameCorner.Parent = mainFrame

local titleFrame = Instance.new("Frame")
titleFrame.Size = UDim2.new(1, 0, 0, 35)
titleFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
titleFrame.BorderSizePixel = 0
titleFrame.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleFrame

local titleBottomCover = Instance.new("Frame")
titleBottomCover.Size = UDim2.new(1, 0, 0, 10)
titleBottomCover.Position = UDim2.new(0, 0, 1, -10)
titleBottomCover.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
titleBottomCover.BorderSizePixel = 0
titleBottomCover.Parent = titleFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Lai Admin"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 16
titleLabel.Parent = titleFrame

local menuBindBtn = Instance.new("TextButton")
menuBindBtn.Size = UDim2.new(0.25, 0, 0.7, 0)
menuBindBtn.Position = UDim2.new(0.7, 0, 0.15, 0)
menuBindBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
menuBindBtn.TextColor3 = Color3.fromRGB(255, 200, 50)
menuBindBtn.Font = Enum.Font.GothamBold
menuBindBtn.TextSize = 12
menuBindBtn.Text = "[" .. keybinds.Menu.Name .. "]"
menuBindBtn.Parent = titleFrame

local menuBindCorner = Instance.new("UICorner")
menuBindCorner.CornerRadius = UDim.new(0, 4)
menuBindCorner.Parent = menuBindBtn

-- ==========================================
-- 3. Create the 3-Tab System
-- ==========================================
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, 0, 0, 30)
tabBar.Position = UDim2.new(0, 0, 0, 35)
tabBar.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
tabBar.BorderSizePixel = 0
tabBar.Parent = mainFrame

local mainTabBtn = Instance.new("TextButton")
mainTabBtn.Size = UDim2.new(0.33, 0, 1, 0)
mainTabBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
mainTabBtn.Text = "Main"
mainTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
mainTabBtn.Font = Enum.Font.GothamBold
mainTabBtn.TextSize = 13
mainTabBtn.BorderSizePixel = 0
mainTabBtn.Parent = tabBar

local tpTabBtn = Instance.new("TextButton")
tpTabBtn.Size = UDim2.new(0.34, 0, 1, 0)
tpTabBtn.Position = UDim2.new(0.33, 0, 0, 0)
tpTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
tpTabBtn.Text = "Teleport"
tpTabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
tpTabBtn.Font = Enum.Font.GothamBold
tpTabBtn.TextSize = 13
tpTabBtn.BorderSizePixel = 0
tpTabBtn.Parent = tabBar

local emotesTabBtn = Instance.new("TextButton")
emotesTabBtn.Size = UDim2.new(0.33, 0, 1, 0)
emotesTabBtn.Position = UDim2.new(0.67, 0, 0, 0)
emotesTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
emotesTabBtn.Text = "Emotes"
emotesTabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
emotesTabBtn.Font = Enum.Font.GothamBold
emotesTabBtn.TextSize = 13
emotesTabBtn.BorderSizePixel = 0
emotesTabBtn.Parent = tabBar

local function createContainer(name, visible)
	local container = Instance.new("ScrollingFrame")
	container.Name = name
	container.Size = UDim2.new(1, 0, 1, -65)
	container.Position = UDim2.new(0, 0, 0, 65)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.ScrollBarThickness = 4
	container.Visible = visible
	container.AutomaticCanvasSize = Enum.AutomaticSize.Y
	container.CanvasSize = UDim2.new(0, 0, 0, 0)
	container.Parent = mainFrame
	
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
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

local function createFeatureRow(parent, text, actionName, layoutOrder)
	local rowFrame = Instance.new("Frame")
	rowFrame.Size = UDim2.new(0.9, 0, 0, 35)
	rowFrame.BackgroundTransparency = 1
	rowFrame.LayoutOrder = layoutOrder
	rowFrame.Parent = parent
	
	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Size = UDim2.new(0.75, -5, 1, 0)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
	toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleBtn.Font = Enum.Font.GothamSemibold
	toggleBtn.TextSize = 13
	toggleBtn.Text = text
	toggleBtn.Parent = rowFrame
	
	local corner1 = Instance.new("UICorner")
	corner1.CornerRadius = UDim.new(0, 6)
	corner1.Parent = toggleBtn
	
	local bindBtn = Instance.new("TextButton")
	bindBtn.Size = UDim2.new(0.25, 0, 1, 0)
	bindBtn.Position = UDim2.new(0.75, 5, 0, 0)
	bindBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
	bindBtn.TextColor3 = Color3.fromRGB(255, 200, 50)
	bindBtn.Font = Enum.Font.GothamBold
	bindBtn.TextSize = 12
	bindBtn.Text = "[" .. keybinds[actionName].Name .. "]"
	bindBtn.Parent = rowFrame
	
	local corner2 = Instance.new("UICorner")
	corner2.CornerRadius = UDim.new(0, 6)
	corner2.Parent = bindBtn
	
	bindBtn.MouseButton1Click:Connect(function()
		listeningForAction = actionName
		listeningButton = bindBtn
		bindBtn.Text = "..."
	end)
	
	return toggleBtn
end

local function createInput(parent, text, layoutOrder)
	local input = Instance.new("TextBox")
	input.Size = UDim2.new(0.9, 0, 0, 30)
	input.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	input.TextColor3 = Color3.fromRGB(255, 255, 255)
	input.Font = Enum.Font.Gotham
	input.TextSize = 13
	input.LayoutOrder = layoutOrder
	input.PlaceholderText = text
	input.Text = ""
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = input
	input.Parent = parent
	return input
end

local function createSimpleButton(parent, text, bgColor, layoutOrder)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.9, 0, 0, 30)
	btn.BackgroundColor3 = bgColor or Color3.fromRGB(70, 70, 80)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamSemibold
	btn.TextSize = 13
	btn.Text = text
	btn.LayoutOrder = layoutOrder
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = btn
	btn.Parent = parent
	return btn
end

local function createPresetRow(parent, labelText, presets, targetInputBox, layoutOrder)
	local rowFrame = Instance.new("Frame")
	rowFrame.Size = UDim2.new(0.9, 0, 0, 25)
	rowFrame.BackgroundTransparency = 1
	rowFrame.LayoutOrder = layoutOrder
	rowFrame.Parent = parent
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.35, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextColor3 = Color3.fromRGB(200, 200, 200)
	label.Font = Enum.Font.GothamSemibold
	label.TextSize = 11
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = rowFrame
	
	local btnWidth = 0.6 / #presets
	for i, val in ipairs(presets) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(btnWidth, -2, 1, 0)
		btn.Position = UDim2.new(0.35 + (btnWidth * (i - 1)), 2, 0, 0)
		btn.BackgroundColor3 = Color3.fromRGB(50, 100, 150)
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 11
		btn.Text = tostring(val)
		btn.Parent = rowFrame
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = btn
		
		btn.MouseButton1Click:Connect(function()
			targetInputBox.Text = tostring(val)
		end)
	end
end

local function createColorOptions(parent, layoutOrder)
	local rowFrame = Instance.new("Frame")
	rowFrame.Size = UDim2.new(0.9, 0, 0, 25)
	rowFrame.BackgroundTransparency = 1
	rowFrame.LayoutOrder = layoutOrder
	rowFrame.Parent = parent
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.4, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "ESP Color:"
	label.TextColor3 = Color3.fromRGB(200, 200, 200)
	label.Font = Enum.Font.GothamSemibold
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = rowFrame
	
	local colors = {
		{Color3.fromRGB(255, 50, 50), UDim2.new(0.5, 0, 0, 0)}, 
		{Color3.fromRGB(50, 255, 50), UDim2.new(0.65, 0, 0, 0)}, 
		{Color3.fromRGB(50, 150, 255), UDim2.new(0.8, 0, 0, 0)}  
	}
	
	for _, data in ipairs(colors) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 25, 0, 25)
		btn.Position = data[2]
		btn.BackgroundColor3 = data[1]
		btn.Text = ""
		btn.Parent = rowFrame
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0) 
		corner.Parent = btn
		
		btn.MouseButton1Click:Connect(function()
			currentEspColor = data[1]
			for _, p in pairs(Players:GetPlayers()) do
				if p.Character and p.Character:FindFirstChild("AdminESP") then
					p.Character.AdminESP.FillColor = currentEspColor
				end
			end
		end)
	end
end

-- ==========================================
-- 4. Populate UI
-- ==========================================
-- Main Tab
local flyButton = createFeatureRow(mainContainer, "Toggle Fly", "Fly", 1)
local flyModeBtn = createSimpleButton(mainContainer, "Fly Mode: Camera", Color3.fromRGB(70, 70, 80), 2)
local flySpeedInput = createInput(mainContainer, "Fly Speed (Default: 50)", 3)
flySpeedInput.Text = "50"
createPresetRow(mainContainer, "Quick Speed:", {50, 100, 300}, flySpeedInput, 4)

local walkButton = createFeatureRow(mainContainer, "Toggle WalkSpeed", "WalkSpeed", 5)
local walkSpeedInput = createInput(mainContainer, "Walk Speed (Default: 16)", 6)
walkSpeedInput.Text = "16"
createPresetRow(mainContainer, "Quick Speed:", {16, 50, 100}, walkSpeedInput, 7)

local noclipButton = createFeatureRow(mainContainer, "Toggle Noclip", "Noclip", 8)
local espButton = createFeatureRow(mainContainer, "Toggle ESP", "ESP", 9)
createColorOptions(mainContainer, 10)

menuBindBtn.MouseButton1Click:Connect(function()
	listeningForAction = "Menu"
	listeningButton = menuBindBtn
	menuBindBtn.Text = "..."
end)

-- Teleport Tab
local tpInput = createInput(tpContainer, "Enter Player Name (or start of name)...", 1)
local tpInstantBtn = createSimpleButton(tpContainer, "Instant Teleport", Color3.fromRGB(150, 50, 200), 2)
local tpDashBtn = createSimpleButton(tpContainer, "Dash Teleport (Tween)", Color3.fromRGB(200, 100, 50), 3)

-- Emotes Tab
local emoteList = {"wave", "point", "dance", "dance2", "dance3", "laugh", "cheer", "salute", "stadium", "tilt", "shrug"}
local emoteButtons = {}

for i, emoteName in ipairs(emoteList) do
	local btn = createSimpleButton(emotesContainer, "Play: " .. emoteName, Color3.fromRGB(60, 90, 120), i)
	emoteButtons[emoteName] = btn
end

-- Tab Switching Logic
local function switchTab(activeBtn, activeContainer)
	mainContainer.Visible = false
	tpContainer.Visible = false
	emotesContainer.Visible = false
	
	mainTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	tpTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	emotesTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	
	mainTabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	tpTabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	emotesTabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	
	activeContainer.Visible = true
	activeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	activeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
end

mainTabBtn.MouseButton1Click:Connect(function() switchTab(mainTabBtn, mainContainer) end)
tpTabBtn.MouseButton1Click:Connect(function() switchTab(tpTabBtn, tpContainer) end)
emotesTabBtn.MouseButton1Click:Connect(function() switchTab(emotesTabBtn, emotesContainer) end)

-- ==========================================
-- 5. Logic Functions
-- ==========================================
local isFlying, isCustomWalk, isNoclipping, isESP = false, false, false, false
local bodyVelocity, bodyGyro
local flyConnection, walkConnection, noclipConnection

-- TÌM NGƯỜI CHƠI THÔNG MINH
local function FindPlayer(partialName)
	if not partialName or partialName == "" then return nil end
	local lowerName = string.lower(partialName)
	
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= player then
			-- Tìm theo Username hoặc DisplayName
			if string.sub(string.lower(p.Name), 1, #lowerName) == lowerName or 
			   string.sub(string.lower(p.DisplayName), 1, #lowerName) == lowerName then
				return p
			end
		end
	end
	return nil
end

-- DỊCH CHUYỂN TỨC THỜI
tpInstantBtn.MouseButton1Click:Connect(function()
	local targetPlayer = FindPlayer(tpInput.Text)
	if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
		local myChar = player.Character
		if myChar and myChar:FindFirstChild("HumanoidRootPart") then
			-- Dịch chuyển ra ngay phía sau người đó 3 studs
			myChar.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
		end
	else
		tpInput.Text = "Player not found!"
		task.wait(1)
		tpInput.Text = ""
	end
end)

-- DỊCH CHUYỂN LƯỚT NHANH (DASH)
tpDashBtn.MouseButton1Click:Connect(function()
	local targetPlayer = FindPlayer(tpInput.Text)
	if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
		local myChar = player.Character
		local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
		local targetHrp = targetPlayer.Character.HumanoidRootPart
		
		if myHrp then
			-- Tính toán khoảng cách để đặt tốc độ lướt cho hợp lý
			local distance = (myHrp.Position - targetHrp.Position).Magnitude
			local tweenTime = math.clamp(distance / 150, 0.3, 3) -- Tốc độ bay khoảng 150 studs/giây
			
			local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
			local tween = TweenService:Create(myHrp, tweenInfo, {CFrame = targetHrp.CFrame * CFrame.new(0, 0, 3)})
			tween:Play()
		end
	else
		tpInput.Text = "Player not found!"
		task.wait(1)
		tpInput.Text = ""
	end
end)

-- Các chức năng cũ (Fly, Walk, ESP)
flyModeBtn.MouseButton1Click:Connect(function()
	if currentFlyMode == "Camera" then
		currentFlyMode = "Hover"
		flyModeBtn.Text = "Fly Mode: Hover (Space/Ctrl)"
		flyModeBtn.BackgroundColor3 = Color3.fromRGB(80, 100, 70)
	else
		currentFlyMode = "Camera"
		flyModeBtn.Text = "Fly Mode: Camera"
		flyModeBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
	end
end)

local function ToggleFly()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChild("Humanoid")
	if not char or not hrp or not hum then return end
	
	isFlying = not isFlying
	if isFlying then
		flyButton.Text = "Toggle Fly: ON"
		flyButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		
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
			local targetVelocity = moveDir * currentFlySpeed
			bodyVelocity.Velocity = bodyVelocity.Velocity:Lerp(targetVelocity, 0.15)
			bodyGyro.CFrame = camera.CFrame
		end)
	else
		flyButton.Text = "Toggle Fly: OFF"
		flyButton.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
		
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		
		if bodyVelocity then bodyVelocity:Destroy() end
		if bodyGyro then bodyGyro:Destroy() end
		if flyConnection then flyConnection:Disconnect() end
	end
end

local function ToggleWalkSpeed()
	isCustomWalk = not isCustomWalk
	if isCustomWalk then
		walkButton.Text = "Toggle WalkSpeed: ON"
		walkButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		walkConnection = RunService.RenderStepped:Connect(function()
			local char = player.Character
			local hum = char and char:FindFirstChild("Humanoid")
			if hum then hum.WalkSpeed = tonumber(walkSpeedInput.Text) or 16 end
		end)
	else
		walkButton.Text = "Toggle WalkSpeed: OFF"
		walkButton.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
		if walkConnection then walkConnection:Disconnect() end
		local char = player.Character
		local hum = char and char:FindFirstChild("Humanoid")
		if hum then hum.WalkSpeed = 16 end
	end
end

local function ToggleNoclip()
	isNoclipping = not isNoclipping
	if isNoclipping then
		noclipButton.Text = "Toggle Noclip: ON"
		noclipButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		noclipConnection = RunService.Stepped:Connect(function()
			local char = player.Character
			if char then
				for _, part in pairs(char:GetDescendants()) do
					if part:IsA("BasePart") and part.CanCollide then
						part.CanCollide = false
					end
				end
			end
		end)
	else
		noclipButton.Text = "Toggle Noclip: OFF"
		noclipButton.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
		if noclipConnection then noclipConnection:Disconnect() end
	end
end

local function ToggleESP()
	isESP = not isESP
	if isESP then
		espButton.Text = "Toggle ESP: ON"
		espButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	else
		espButton.Text = "Toggle ESP: OFF"
		espButton.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
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
noclipButton.MouseButton1Click:Connect(ToggleNoclip)
espButton.MouseButton1Click:Connect(ToggleESP)

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
-- 6. Dynamic Keybind Input System
-- ==========================================
local isMenuOpen = true
local openPosition = UDim2.new(0, 20, 0.5, -240)
local closedPosition = UDim2.new(0, -300, 0.5, -240)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if listeningForAction then
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
			keybinds[listeningForAction] = input.KeyCode
			listeningButton.Text = "[" .. input.KeyCode.Name .. "]"
			listeningForAction = nil
			listeningButton = nil
		end
		return 
	end
	
	if gameProcessed then return end 
	
	if input.KeyCode == keybinds.Menu then
		isMenuOpen = not isMenuOpen
		local targetPos = isMenuOpen and openPosition or closedPosition
		local tween = TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = targetPos})
		tween:Play()
	elseif input.KeyCode == keybinds.Fly then
		ToggleFly()
	elseif input.KeyCode == keybinds.WalkSpeed then
		ToggleWalkSpeed()
	elseif input.KeyCode == keybinds.Noclip then
		ToggleNoclip()
	elseif input.KeyCode == keybinds.ESP then
		ToggleESP()
	end
end)
