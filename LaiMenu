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

-- Title Area
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
-- 3. Create the 2-Tab System
-- ==========================================
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, 0, 0, 30)
tabBar.Position = UDim2.new(0, 0, 0, 35)
tabBar.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
tabBar.BorderSizePixel = 0
tabBar.Parent = mainFrame

local mainTabBtn = Instance.new("TextButton")
mainTabBtn.Size = UDim2.new(0.5, 0, 1, 0)
mainTabBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
mainTabBtn.Text = "Main"
mainTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
mainTabBtn.Font = Enum.Font.GothamBold
mainTabBtn.TextSize = 14
mainTabBtn.BorderSizePixel = 0
mainTabBtn.Parent = tabBar

local emotesTabBtn = Instance.new("TextButton")
emotesTabBtn.Size = UDim2.new(0.5, 0, 1, 0)
emotesTabBtn.Position = UDim2.new(0.5, 0, 0, 0)
emotesTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
emotesTabBtn.Text = "Emotes"
emotesTabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
emotesTabBtn.Font = Enum.Font.GothamBold
emotesTabBtn.TextSize = 14
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
	btn.Size = UDim2.new(0.9, 0, 0, 35)
	btn.BackgroundColor3 = bgColor
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.Text = text
	btn.LayoutOrder = layoutOrder
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = btn
	btn.Parent = parent
	return btn
end

-- ==========================================
-- 4. Populate UI
-- ==========================================
-- Main Tab
local flyButton = createFeatureRow(mainContainer, "Toggle Fly", "Fly", 1)
local flySpeedInput = createInput(mainContainer, "Fly Speed (Default: 50)", 2)
flySpeedInput.Text = "50"

local walkButton = createFeatureRow(mainContainer, "Toggle WalkSpeed", "WalkSpeed", 3)
local walkSpeedInput = createInput(mainContainer, "Walk Speed (Default: 16)", 4)
walkSpeedInput.Text = "50"

local noclipButton = createFeatureRow(mainContainer, "Toggle Noclip", "Noclip", 5)
local espButton = createFeatureRow(mainContainer, "Toggle ESP", "ESP", 6)

menuBindBtn.MouseButton1Click:Connect(function()
	listeningForAction = "Menu"
	listeningButton = menuBindBtn
	menuBindBtn.Text = "..."
end)

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
	emotesContainer.Visible = false
	
	mainTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	emotesTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	mainTabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	emotesTabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	
	activeContainer.Visible = true
	activeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	activeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
end

mainTabBtn.MouseButton1Click:Connect(function() switchTab(mainTabBtn, mainContainer) end)
emotesTabBtn.MouseButton1Click:Connect(function() switchTab(emotesTabBtn, emotesContainer) end)

-- ==========================================
-- 5. Logic Functions
-- ==========================================
local isFlying, isCustomWalk, isNoclipping, isESP = false, false, false, false
local bodyVelocity, bodyGyro
local flyConnection, walkConnection, noclipConnection

local function ToggleFly()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChild("Humanoid")
	if not char or not hrp or not hum then return end
	
	isFlying = not isFlying
	if isFlying then
		flyButton.Text = "Toggle Fly: ON"
		flyButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		hum.PlatformStand = true
		
		bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Velocity = Vector3.new(0,0,0)
		bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		bodyVelocity.Parent = hrp
		
		bodyGyro = Instance.new("BodyGyro")
		bodyGyro.CFrame = hrp.CFrame
		bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
		bodyGyro.Parent = hrp
		
		flyConnection = RunService.RenderStepped:Connect(function()
			local moveDir = Vector3.new(0,0,0)
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camera.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camera.CFrame.RightVector end
			
			local currentFlySpeed = tonumber(flySpeedInput.Text) or 50
			bodyVelocity.Velocity = moveDir * currentFlySpeed
			bodyGyro.CFrame = camera.CFrame
		end)
	else
		flyButton.Text = "Toggle Fly: OFF"
		flyButton.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
		hum.PlatformStand = false
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
					hl.FillColor = Color3.fromRGB(255, 0, 0)
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
