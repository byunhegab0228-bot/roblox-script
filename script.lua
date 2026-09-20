local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- 상태 변수
local espEnabled = false
local aimbotEnabled = false
local pathEnabled = false
local isMinimized = false
local sizeState = 1 -- 1: 보통, 2: 크게, 3: 작게

local playerList = {}
local targetIndex = 1
local targetPlayer = nil

-- 저장소
local espFolder = nil
local renderConnection = nil
local pathFolder = nil
local lastPathTime = 0
local characterConnections = {}

-- UI 생성 도우미 함수
local function create(className, props)
	local inst = Instance.new(className)
	for k, v in pairs(props) do inst[k] = v end
	return inst
end

-- 1. UI 구조 생성
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

-- 상단 타이틀바 (Rohack Hun)
local titleBar = create("Frame", {
	Size = UDim2.new(1, 0, 0, 45),
	BackgroundColor3 = Color3.fromRGB(220, 50, 50),
	BorderSizePixel = 0,
	Parent = mainFrame
})
create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = titleBar })

create("TextLabel", {
	Size = UDim2.new(0, 120, 1, 0),
	Position = UDim2.new(0, 12, 0, 0),
	BackgroundTransparency = 1,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 16,
	Font = Enum.Font.SourceSansBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "Rohack Hun",
	Parent = titleBar
})

-- 크기 변경 버튼 (상단 우측 배치: [작게] ↔ [보통] ↔ [크게])
local sizeToggleBtn = create("TextButton", {
	Size = UDim2.new(0, 42, 0, 28),
	Position = UDim2.new(1, -102, 0.5, -14),
	BackgroundColor3 = Color3.fromRGB(180, 40, 40),
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 12,
	Font = Enum.Font.SourceSansBold,
	Text = "크게",
	Parent = titleBar
})
create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = sizeToggleBtn })

-- 접기/펴기 최소화 버튼 (-)
local minimizeBtn = create("TextButton", {
	Size = UDim2.new(0, 28, 0, 28),
	Position = UDim2.new(1, -56, 0.5, -14),
	BackgroundColor3 = Color3.fromRGB(180, 40, 40),
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 14,
	Font = Enum.Font.SourceSansBold,
	Text = "—",
	Parent = titleBar
})
create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = minimizeBtn })

-- 닫기 버튼 (✕)
local closeBtn = create("TextButton", {
	Size = UDim2.new(0, 28, 0, 28),
	Position = UDim2.new(1, -24, 0.5, -14),
	BackgroundColor3 = Color3.fromRGB(150, 30, 30),
	TextColor3 = Color3.fromRGB(255, 255, 255),
	Text = "✕",
	Parent = titleBar
})
create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = closeBtn })

-- 내부 콘텐츠 프레임
local contentFrame = create("Frame", {
	Size = UDim2.new(1, 0, 1, -45),
	Position = UDim2.new(0, 0, 0, 45),
	BackgroundTransparency = 1,
	Parent = mainFrame
})

-- 플레이어 선택 UI
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
	Position = UDim2.new(0, 0, 0, 0),
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
	TextSize = 14,
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

-- 토글 버튼들
local espToggleBtn = create("TextButton", {
	Size = UDim2.new(1, -20, 0, 36),
	Position = UDim2.new(0, 10, 0, 85),
	BackgroundColor3 = Color3.fromRGB(50, 52, 60),
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 14,
	Font = Enum.Font.SourceSansBold,
	Text = "ESP [H] : 꺼짐 (OFF)",
	Parent = contentFrame
})
create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = espToggleBtn })

local aimbotToggleBtn = create("TextButton", {
	Size = UDim2.new(1, -20, 0, 36),
	Position = UDim2.new(0, 10, 0, 130),
	BackgroundColor3 = Color3.fromRGB(50, 52, 60),
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 14,
	Font = Enum.Font.SourceSansBold,
	Text = "에임핵 [G] : 꺼짐 (OFF)",
	Parent = contentFrame
})
create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = aimbotToggleBtn })

local pathToggleBtn = create("TextButton", {
	Size = UDim2.new(1, -20, 0, 36),
	Position = UDim2.new(0, 10, 0, 175),
	BackgroundColor3 = Color3.fromRGB(50, 52, 60),
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 14,
	Font = Enum.Font.SourceSansBold,
	Text = "길 안내 [J] : 꺼짐 (OFF)",
	Parent = contentFrame
})
create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = pathToggleBtn })

-- 단축키 안내 텍스트
create("TextLabel", {
	Size = UDim2.new(1, -20, 0, 35),
	Position = UDim2.new(0, 10, 0, 220),
	BackgroundTransparency = 1,
	TextColor3 = Color3.fromRGB(150, 155, 165),
	TextSize = 11,
	Font = Enum.Font.SourceSansItalic,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "[F]: 패널 열기/닫기  |  [H]: ESP\n[G]: 에임핵          |  [J]: 길안내",
	Parent = contentFrame
})

-- 우측 하단 구석 제작자 크레딧 텍스트
create("TextLabel", {
	Size = UDim2.new(1, -20, 0, 20),
	Position = UDim2.new(0, 10, 1, -25),
	BackgroundTransparency = 1,
	TextColor3 = Color3.fromRGB(120, 125, 135),
	TextSize = 11,
	Font = Enum.Font.SourceSans,
	TextXAlignment = Enum.TextXAlignment.Right,
	Text = "배포 가능 제작:로블 핵 배포",
	Parent = contentFrame
})

-- 크기 변경 버튼 기능 (작게 ↔ 보통 ↔ 크게 순환)
local sizes = {
	{w = 280, h = 380, name = "크게"},  -- 보통 상태일 때 누르면 크게로 감
	{w = 400, h = 500, name = "작게"},  -- 크게 상태일 때 누르면 작게로 감
	{w = 240, h = 320, name = "보통"}   -- 작게 상태일 때 누르면 보통으로 감
}
local currentHeight = 380

sizeToggleBtn.MouseButton1Click:Connect(function()
	sizeState = sizeState % 3 + 1
	local info = sizes[sizeState]
	sizeToggleBtn.Text = info.name
	currentHeight = info.h
	
	if not isMinimized then
		mainFrame.Size = UDim2.new(0, info.w, 0, info.h)
	end
end)

-- 접기/펴기 기능 토글 함수
local function toggleMinimize()
	isMinimized = not isMinimized
	if isMinimized then
		contentFrame.Visible = false
		mainFrame.Size = UDim2.new(0, mainFrame.AbsoluteSize.X, 0, 45)
		minimizeBtn.Text = "+"
	else
		contentFrame.Visible = true
		mainFrame.Size = UDim2.new(0, mainFrame.AbsoluteSize.X, 0, currentHeight)
		minimizeBtn.Text = "—"
	end
end

minimizeBtn.MouseButton1Click:Connect(toggleMinimize)

-- 타이틀바 더블 클릭 접기/펴기 지원
local lastClick = 0
titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if tick() - lastClick < 0.3 then
			toggleMinimize()
		end
		lastClick = tick()
	end
end)

-- 2. 플레이어 목록 갱신 함수
local function updatePlayerList()
	playerList = {}
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= localPlayer then
			table.insert(playerList, p)
		end
	end

	if #playerList == 0 then
		targetPlayer = nil
		targetDisplay.Text = "없음 (플레이어 없음)"
	else
		if targetIndex > #playerList then targetIndex = 1 end
		if targetIndex < 1 then targetIndex = #playerList end
		targetPlayer = playerList[targetIndex]
		targetDisplay.Text = targetPlayer.DisplayName .. " (@" .. targetPlayer.Name .. ")"
	end
end

-- 3. ESP 관련 함수
local function clearESP()
	if espFolder then espFolder:Destroy() espFolder = nil end
	for _, conn in pairs(characterConnections) do
		if conn then conn:Disconnect() end
	end
	characterConnections = {}
end

local function applyESPToCharacter(char)
	if not char or not espEnabled then return end
	local existingHighlight = char:FindFirstChild("CustomESP_Highlight")
	if existingHighlight then existingHighlight:Destroy() end

	local highlight = Instance.new("Highlight")
	highlight.Name = "CustomESP_Highlight"
	highlight.Adornee = char
	highlight.FillColor = Color3.fromRGB(255, 50, 50)
	highlight.FillTransparency = 0.5
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.Parent = char
end

local function updateESPUI()
	espToggleBtn.Text = espEnabled and "ESP [H] : 켜짐 (ON)" or "ESP [H] : 꺼짐 (OFF)"
	espToggleBtn.BackgroundColor3 = espEnabled and Color3.fromRGB(220, 50, 50) or Color3.fromRGB(50, 52, 60)
end

local function updateESP()
	clearESP()
	updateESPUI()
	if not espEnabled then return end

	espFolder = Instance.new("Folder", Workspace)
	espFolder.Name = "ESPFolder"

	for _, player in pairs(Players:GetPlayers()) do
		if player ~= localPlayer then
			if player.Character then
				applyESPToCharacter(player.Character)
			end
			characterConnections[player] = player.CharacterAdded:Connect(function(newChar)
				task.wait(0.5)
				if espEnabled then
					applyESPToCharacter(newChar)
				end
			end)
		end
	end
end

-- 4. 길 안내 선 관리
local function clearPathLine()
	if pathFolder then
		pathFolder:Destroy()
		pathFolder = nil
	end
end

local function drawSegment(p1, p2)
	if not pathFolder then
		pathFolder = Instance.new("Folder", Workspace.Terrain)
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
	beam.Width0 = 0.08
	beam.Width1 = 0.08
	beam.FaceCamera = true
	beam.Parent = pathFolder

	att0.Parent = pathFolder
	att1.Parent = pathFolder
end

local function isBlocked(startPos, endPos, myChar, tChar)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {myChar, tChar}

	local direction = endPos - startPos
	local result = Workspace:Raycast(startPos, direction, rayParams)

	return result ~= nil
end

-- UI 상태 업데이트 편의 함수들
local function updateAimbotUI()
	aimbotToggleBtn.Text = aimbotEnabled and "에임핵 [G] : 켜짐 (ON)" or "에임핵 [G] : 꺼짐 (OFF)"
	aimbotToggleBtn.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(220, 50, 50) or Color3.fromRGB(50, 52, 60)
end

local function updatePathUI()
	pathToggleBtn.Text = pathEnabled and "길 안내 [J] : 켜짐 (ON)" or "길 안내 [J] : 꺼짐 (OFF)"
	pathToggleBtn.BackgroundColor3 = pathEnabled and Color3.fromRGB(220, 50, 50) or Color3.fromRGB(50, 52, 60)
end

-- 5. 프레임 연산 (실시간 트래킹)
renderConnection = RunService.RenderStepped:Connect(function()
	local myChar = localPlayer.Character
	local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")

	local tChar = targetPlayer and targetPlayer.Character
	local tHead = tChar and tChar:FindFirstChild("Head")

	-- 에임핵 (머리 자동 조준)
	if aimbotEnabled and tHead then
		camera.CFrame = CFrame.new(camera.CFrame.Position, tHead.Position)
	end

	-- 길 안내 로직
	if pathEnabled and myHrp and tHead then
		local startPos = myHrp.Position
		local targetPos = tHead.Position

		local blocked = isBlocked(startPos, targetPos, myChar, tChar)

		if not blocked then
			clearPathLine()
			drawSegment(startPos, targetPos)
		else
			if tick() - lastPathTime > 0.3 then
				lastPathTime = tick()
				clearPathLine()

				local path = PathfindingService:CreatePath({
					AgentRadius = 2,
					AgentHeight = 5,
					AgentCanJump = true
				})

				pcall(function()
					path:ComputeAsync(startPos, targetPos)
					if path.Status == Enum.PathStatus.Success then
						local waypoints = path:GetWaypoints()
						for i = 1, #waypoints - 1 do
							local p1 = waypoints[i].Position + Vector3.new(0, 1, 0)
							local p2 = waypoints[i+1].Position + Vector3.new(0, 1, 0)
							drawSegment(p1, p2)
						end
						if #waypoints > 0 then
							drawSegment(waypoints[#waypoints].Position + Vector3.new(0, 1, 0), targetPos)
						end
					else
						drawSegment(startPos, targetPos)
					end
				end)
			end
		end
	else
		clearPathLine()
	end
end)

-- 6. 버튼 및 단축키 이벤트 연결
prevBtn.MouseButton1Click:Connect(function()
	targetIndex = targetIndex - 1
	updatePlayerList()
	clearPathLine()
end)

nextBtn.MouseButton1Click:Connect(function()
	targetIndex = targetIndex + 1
	updatePlayerList()
	clearPathLine()
end)

espToggleBtn.MouseButton1Click:Connect(function()
	espEnabled = not espEnabled
	updateESP()
end)

aimbotToggleBtn.MouseButton1Click:Connect(function()
	aimbotEnabled = not aimbotEnabled
	updateAimbotUI()
end)

pathToggleBtn.MouseButton1Click:Connect(function()
	pathEnabled = not pathEnabled
	updatePathUI()
end)

closeBtn.MouseButton1Click:Connect(function()
	clearESP()
	clearPathLine()
	if renderConnection then renderConnection:Disconnect() end
	screenGui.Enabled = false
end)

-- PC 단축키 기능 (F: 패널 토글, G: 에임핵, H: ESP, J: 길안내)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.F then
		screenGui.Enabled = not screenGui.Enabled
	elseif input.KeyCode == Enum.KeyCode.G then
		aimbotEnabled = not aimbotEnabled
		updateAimbotUI()
	elseif input.KeyCode == Enum.KeyCode.H then
		espEnabled = not espEnabled
		updateESP()
	elseif input.KeyCode == Enum.KeyCode.J then
		pathEnabled = not pathEnabled
		updatePathUI()
	end
end)

Players.PlayerAdded:Connect(function(player)
	updatePlayerList()
	characterConnections[player] = player.CharacterAdded:Connect(function(newChar)
		task.wait(0.5)
		if espEnabled then
			applyESPToCharacter(newChar)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	if characterConnections[player] then
		characterConnections[player]:Disconnect()
		characterConnections[player] = nil
	end
	updatePlayerList()
end)

updatePlayerList()

-- UI 드래그 처리 (패널 이동)
local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging, dragStart, startPos = true, input.Position, mainFrame.Position
		local c
		c = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				if c then c:Disconnect() end
			end
		end)
	end
end)

titleBar.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)
