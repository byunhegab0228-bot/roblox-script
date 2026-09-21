local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local PathfindingService = game:GetService("PathfindingService")

if not game:IsLoaded() then game.Loaded:Wait() end

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local espEnabled = false
local aimbotEnabled = false
local pathEnabled = false
local selectionModeEnabled = false

local playerList = {}
local targetIndex = 1
local targetPlayer = nil
local pendingTargetPlayer = nil
local pathFolder = nil
local lastPathTime = 0

-- UI 생성 함수
local function create(className, props)
	local inst = Instance.new(className)
	for k, v in pairs(props) do inst[k] = v end
	return inst
end

local playerGui = localPlayer:WaitForChild("PlayerGui")
local existing = playerGui:FindFirstChild("AdminTargetGui")
if existing then existing:Destroy() end

local screenGui = create("ScreenGui", { Name = "AdminTargetGui", ResetOnSpawn = false, Parent = playerGui })

local mainFrame = create("Frame", {
	Name = "MainFrame",
	Size = UDim2.new(0, 280, 0, 380),
	Position = UDim2.new(0.5, -140, 0.5, -190),
	BackgroundColor3 = Color3.fromRGB(20, 22, 27),
	BorderSizePixel = 0,
	Active = true,
	Parent = screenGui
})
create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = mainFrame })

-- 상단 타이틀바
local titleBar = create("Frame", {
	Size = UDim2.new(1, 0, 0, 45),
	BackgroundColor3 = Color3.fromRGB(220, 50, 50),
	BorderSizePixel = 0,
	Parent = mainFrame
})
create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = titleBar })

create("TextLabel", {
	Size = UDim2.new(0, 100, 1, 0),
	Position = UDim2.new(0, 10, 0, 0),
	BackgroundTransparency = 1,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 15,
	Font = Enum.Font.SourceSansBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "Rohack Hun",
	Parent = titleBar
})

-- 소, 중, 대 크기 조절 버튼 추가
local sizeSmallBtn = create("TextButton", {
	Size = UDim2.new(0, 20, 0, 24),
	Position = UDim2.new(1, -108, 0.5, -12),
	BackgroundColor3 = Color3.fromRGB(150, 35, 35),
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 11,
	Font = Enum.Font.SourceSansBold,
	Text = "소",
	Parent = titleBar
})
create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = sizeSmallBtn })

local sizeMidBtn = create("TextButton", {
	Size = UDim2.new(0, 20, 0, 24),
	Position = UDim2.new(1, -84, 0.5, -12),
	BackgroundColor3 = Color3.fromRGB(150, 35, 35),
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 11,
	Font = Enum.Font.SourceSansBold,
	Text = "중",
	Parent = titleBar
})
create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = sizeMidBtn })

local sizeLargeBtn = create("TextButton", {
	Size = UDim2.new(0, 20, 0, 24),
	Position = UDim2.new(1, -60, 0.5, -12),
	BackgroundColor3 = Color3.fromRGB(150, 35, 35),
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 11,
	Font = Enum.Font.SourceSansBold,
	Text = "대",
	Parent = titleBar
})
create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = sizeLargeBtn })

local closeBtn = create("TextButton", {
	Size = UDim2.new(0, 24, 0, 24),
	Position = UDim2.new(1, -30, 0.5, -12),
	BackgroundColor3 = Color3.fromRGB(180, 30, 30),
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 13,
	Font = Enum.Font.SourceSansBold,
	Text = "✕",
	Parent = titleBar
})
create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = closeBtn })

-- 크기 변경 로직
sizeSmallBtn.MouseButton1Click:Connect(function()
	mainFrame.Size = UDim2.new(0, 240, 0, 320)
end)

sizeMidBtn.MouseButton1Click:Connect(function()
	mainFrame.Size = UDim2.new(0, 280, 0, 380)
end)

sizeLargeBtn.MouseButton1Click:Connect(function()
	mainFrame.Size = UDim2.new(0, 340, 0, 460)
end)

-- 콘텐츠 프레임
local contentFrame = create("Frame", {
	Size = UDim2.new(1, 0, 1, -45),
	Position = UDim2.new(0, 0, 0, 45),
	BackgroundTransparency = 1,
	Parent = mainFrame
})

create("TextLabel", {
	Size = UDim2.new(1, -20, 0, 20),
	Position = UDim2.new(0, 10, 0, 12),
	BackgroundTransparency = 1,
	TextColor3 = Color3.fromRGB(180, 180, 180),
	TextSize = 13,
	Font = Enum.Font.SourceSansBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "• 타겟 플레이어 선택",
	Parent = contentFrame
})

local selectorFrame = create("Frame", {
	Size = UDim2.new(1, -20, 0, 36),
	Position = UDim2.new(0, 10, 0, 34),
	BackgroundColor3 = Color3.fromRGB(35, 38, 45),
	Parent = contentFrame
})
create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = selectorFrame })

local prevBtn = create("TextButton", {
	Size = UDim2.new(0, 35, 1, 0),
	BackgroundTransparency = 1,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 16,
	Font = Enum.Font.SourceSansBold,
	Text = "<",
	Parent = selectorFrame
})

local targetDisplay = create("TextLabel", {
	Size = UDim2.new(1, -70, 1, 0),
	Position = UDim2.new(0, 35, 0, 0),
	BackgroundTransparency = 1,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 13,
	Font = Enum.Font.SourceSansBold,
	Text = "없음",
	Parent = selectorFrame
})

local nextBtn = create("TextButton", {
	Size = UDim2.new(0, 35, 1, 0),
	Position = UDim2.new(1, -35, 0, 0),
	BackgroundTransparency = 1,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 16,
	Font = Enum.Font.SourceSansBold,
	Text = ">",
	Parent = selectorFrame
})

-- 기능 버튼들
local espToggleBtn = create("TextButton", {
	Size = UDim2.new(1, -20, 0, 32),
	Position = UDim2.new(0, 10, 0, 78),
	BackgroundColor3 = Color3.fromRGB(50, 52, 60),
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 13,
	Font = Enum.Font.SourceSansBold,
	Text = "ESP [H] : 꺼짐 (OFF)",
	Parent = contentFrame
})
create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = espToggleBtn })

local selectModeBtn = create("TextButton", {
	Size = UDim2.new(1, -20, 0, 32),
	Position = UDim2.new(0, 10, 0, 115),
	BackgroundColor3 = Color3.fromRGB(50, 52, 60),
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 13,
	Font = Enum.Font.SourceSansBold,
	Text = "선택 모드 (벽 뒤 타겟 클릭) : OFF",
	Parent = contentFrame
})
create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = selectModeBtn })

local aimbotToggleBtn = create("TextButton", {
	Size = UDim2.new(1, -20, 0, 32),
	Position = UDim2.new(0, 10, 0, 152),
	BackgroundColor3 = Color3.fromRGB(50, 52, 60),
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 13,
	Font = Enum.Font.SourceSansBold,
	Text = "에임핵 [G] : 꺼짐 (OFF)",
	Parent = contentFrame
})
create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = aimbotToggleBtn })

local pathToggleBtn = create("TextButton", {
	Size = UDim2.new(1, -20, 0, 32),
	Position = UDim2.new(0, 10, 0, 189),
	BackgroundColor3 = Color3.fromRGB(50, 52, 60),
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 13,
	Font = Enum.Font.SourceSansBold,
	Text = "길 안내 [J] : 꺼짐 (OFF)",
	Parent = contentFrame
})
create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = pathToggleBtn })

create("TextLabel", {
	Size = UDim2.new(1, -20, 0, 35),
	Position = UDim2.new(0, 10, 0, 226),
	BackgroundTransparency = 1,
	TextColor3 = Color3.fromRGB(150, 155, 165),
	TextSize = 11,
	Font = Enum.Font.SourceSansItalic,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "[F]: 패널 열기/닫기  |  [H]: ESP\n[G]: 에임핵          |  [J]: 길안내",
	Parent = contentFrame
})

-- [OK?] 확정 버튼 GUI 생성
local okGuiHolder = create("ScreenGui", { Name = "OkGuiHolder", ResetOnSpawn = false, Parent = playerGui })
local okButton = create("TextButton", {
	Name = "ConfirmOkButton",
	Size = UDim2.new(0, 140, 0, 40),
	Position = UDim2.new(0.5, -70, 0.15, 0),
	BackgroundColor3 = Color3.fromRGB(40, 180, 60),
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 15,
	Font = Enum.Font.SourceSansBold,
	Text = "OK? (확정)",
	Visible = false,
	Parent = okGuiHolder
})
create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = okButton })

-- 플레이어 목록 업데이트
local function updatePlayerList()
	playerList = {}
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= localPlayer then table.insert(playerList, p) end
	end

	if #playerList == 0 then
		targetPlayer = nil
		targetDisplay.Text = "플레이어 없음"
	else
		if targetIndex > #playerList then targetIndex = 1 end
		if targetIndex < 1 then targetIndex = #playerList end
		targetPlayer = playerList[targetIndex]
		targetDisplay.Text = targetPlayer.DisplayName .. " (@" .. targetPlayer.Name .. ")"
	end
end

-- ESP 관리
local function clearESP()
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character then
			local hl = player.Character:FindFirstChild("CustomESP_Highlight")
			if hl then hl:Destroy() end
		end
	end
end

local function applyESPToCharacter(char, isSelected)
	if not char then return end
	local hl = char:FindFirstChild("CustomESP_Highlight")
	if hl then hl:Destroy() end

	hl = Instance.new("Highlight")
	hl.Name = "CustomESP_Highlight"
	hl.Adornee = char
	hl.FillColor = isSelected and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 50, 50)
	hl.FillTransparency = 0.5
	hl.OutlineColor = Color3.fromRGB(255, 255, 255)
	hl.Parent = char
end

local function updateESP()
	if not espEnabled and not selectionModeEnabled then
		clearESP()
		return
	end
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= localPlayer and player.Character then
			applyESPToCharacter(player.Character, selectionModeEnabled)
		end
	end
end

-- 선택 모드 토글
local function setSelectionMode(state)
	selectionModeEnabled = state
	if selectionModeEnabled then
		selectModeBtn.Text = "선택 모드 중... (벽 뒤 클릭 가능)"
		selectModeBtn.BackgroundColor3 = Color3.fromRGB(220, 160, 30)
		espEnabled = true
		updateESP()
	else
		selectModeBtn.Text = "선택 모드 (벽 뒤 타겟 클릭) : OFF"
		selectModeBtn.BackgroundColor3 = Color3.fromRGB(50, 52, 60)
		okButton.Visible = false
		pendingTargetPlayer = nil
		if not espEnabled then
			clearESP()
		else
			updateESP()
		end
	end
	espToggleBtn.Text = espEnabled and "ESP [H] : 켜짐 (ON)" or "ESP [H] : 꺼짐 (OFF)"
	espToggleBtn.BackgroundColor3 = espEnabled and Color3.fromRGB(220, 50, 50) or Color3.fromRGB(50, 52, 60)
end

selectModeBtn.MouseButton1Click:Connect(function()
	setSelectionMode(not selectionModeEnabled)
end)

-- 벽 뒤 플레이어 마우스 조준 감지 레이캐스트 로직
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		if selectionModeEnabled then
			local mousePos = UserInputService:GetMouseLocation()
			local unitRay = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
			local rayOrigin = unitRay.Origin
			local rayDir = unitRay.Direction.Unit

			local closestPlayer = nil
			local shortestDistance = math.huge

			for _, p in pairs(Players:GetPlayers()) do
				if p ~= localPlayer and p.Character then
					local hrp = p.Character:FindFirstChild("HumanoidRootPart")
					if hrp then
						local playerPos = hrp.Position
						local v = playerPos - rayOrigin
						local projection = v:Dot(rayDir)
						if projection > 0 then
							local closestPoint = rayOrigin + rayDir * projection
							local distFromRay = (playerPos - closestPoint).Magnitude
							if distFromRay < 8 and projection < shortestDistance then
								shortestDistance = projection
								closestPlayer = p
							end
						end
					end
				end
			end

			if closestPlayer then
				pendingTargetPlayer = closestPlayer
				okButton.Visible = true
				okButton.Text = "OK? (" .. closestPlayer.DisplayName .. ")"
			end
		end
	end
end)

okButton.MouseButton1Click:Connect(function()
	if pendingTargetPlayer then
		targetPlayer = pendingTargetPlayer
		targetDisplay.Text = targetPlayer.DisplayName .. " (@" .. targetPlayer.Name .. ")"
		for i, p in ipairs(playerList) do
			if p == targetPlayer then
				targetIndex = i
				break
			end
		end
	end
	setSelectionMode(false)
end)

-- 길 안내 유틸
local function clearPathLine()
	if pathFolder then pathFolder:Destroy() pathFolder = nil end
end

local function drawSegment(p1, p2)
	if not pathFolder then
		pathFolder = Instance.new("Folder", Workspace)
		pathFolder.Name = "PathFolder"
	end
	local att0 = Instance.new("Attachment", Workspace.Terrain)
	local att1 = Instance.new("Attachment", Workspace.Terrain)
	att0.WorldPosition = p1
	att1.WorldPosition = p2

	local beam = Instance.new("Beam")
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0))
	beam.Width0 = 0.1
	beam.Width1 = 0.1
	beam.FaceCamera = true
	beam.Parent = pathFolder

	att0.Parent = pathFolder
	att1.Parent = pathFolder
end

-- 렌더링 루프
RunService.RenderStepped:Connect(function()
	local myChar = localPlayer.Character
	local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
	local tChar = targetPlayer and targetPlayer.Character
	local tHead = tChar and tChar:FindFirstChild("Head")

	if aimbotEnabled and tHead then
		camera.CFrame = CFrame.new(camera.CFrame.Position, tHead.Position)
	end

	if pathEnabled and myHrp and tHead then
		if tick() - lastPathTime > 0.5 then
			lastPathTime = tick()
			clearPathLine()
			local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true })
			pcall(function()
				path:ComputeAsync(myHrp.Position, tHead.Position)
				if path.Status == Enum.PathStatus.Success then
					local waypoints = path:GetWaypoints()
					for i = 1, #waypoints - 1 do
						drawSegment(waypoints[i].Position + Vector3.new(0, 1, 0), waypoints[i+1].Position + Vector3.new(0, 1, 0))
					end
				end
			end)
		end
	else
		clearPathLine()
	end
end)

-- 버튼 이벤트 연결
prevBtn.MouseButton1Click:Connect(function()
	targetIndex = targetIndex - 1
	updatePlayerList()
end)

nextBtn.MouseButton1Click:Connect(function()
	targetIndex = targetIndex + 1
	updatePlayerList()
end)

espToggleBtn.MouseButton1Click:Connect(function()
	espEnabled = not espEnabled
	espToggleBtn.Text = espEnabled and "ESP [H] : 켜짐 (ON)" or "ESP [H] : 꺼짐 (OFF)"
	espToggleBtn.BackgroundColor3 = espEnabled and Color3.fromRGB(220, 50, 50) or Color3.fromRGB(50, 52, 60)
	updateESP()
end)

aimbotToggleBtn.MouseButton1Click:Connect(function()
	aimbotEnabled = not aimbotEnabled
	aimbotToggleBtn.Text = aimbotEnabled and "에임핵 [G] : 켜짐 (ON)" or "에임핵 [G] : 꺼짐 (OFF)"
	aimbotToggleBtn.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(220, 50, 50) or Color3.fromRGB(50, 52, 60)
end)

pathToggleBtn.MouseButton1Click:Connect(function()
	pathEnabled = not pathEnabled
	pathToggleBtn.Text = pathEnabled and "길 안내 [J] : 켜짐 (ON)" or "길 안내 [J] : 꺼짐 (OFF)"
	pathToggleBtn.BackgroundColor3 = pathEnabled and Color3.fromRGB(220, 50, 50) or Color3.fromRGB(50, 52, 60)
end)

closeBtn.MouseButton1Click:Connect(function()
	clearESP()
	clearPathLine()
	screenGui.Enabled = false
	okGuiHolder.Enabled = false
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.F then
		screenGui.Enabled = not screenGui.Enabled
	elseif input.KeyCode == Enum.KeyCode.G then
		aimbotToggleBtn.MouseButton1Click:Fire()
	elseif input.KeyCode == Enum.KeyCode.H then
		espToggleBtn.MouseButton1Click:Fire()
	elseif input.KeyCode == Enum.KeyCode.J then
		pathToggleBtn.MouseButton1Click:Fire()
	end
end)

Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(updatePlayerList)
updatePlayerList()

-- UI 드래그 이동 기능
local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging, dragStart, startPos = true, input.Position, mainFrame.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)
