local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local UI_SCALE = IS_MOBILE and 0.72 or 1.0

print(("[VexHub] Loaded. Mobile=%s Touch=%s KB=%s Gamepad=%s"):format(
    tostring(IS_MOBILE),
    tostring(UserInputService.TouchEnabled),
    tostring(UserInputService.KeyboardEnabled),
    tostring(UserInputService.GamepadEnabled)
))

local controlModule
do
    local ok, err = pcall(function()
        local playerScripts = player:WaitForChild("PlayerScripts", 10)
        if not playerScripts then
            error("PlayerScripts not found")
        end
        local playerModule = playerScripts:WaitForChild("PlayerModule", 10)
        if not playerModule then
            error("PlayerModule not found")
        end
        local mod = require(playerModule)
        controlModule = mod:GetControls()
    end)
    if not ok then
        warn("[VexHub] ControlModule init failed: " .. tostring(err))
    else
        print("[VexHub] ControlModule ready")
    end
end

local function getMoveVector()
    if controlModule then
        local ok, vec = pcall(function()
            return controlModule:GetMoveVector()
        end)
        if ok and typeof(vec) == "Vector3" then
            return vec
        end
    end
    return Vector3.zero
end

local BLACK = Color3.fromRGB(10, 10, 12)
local BLACK_2 = Color3.fromRGB(18, 18, 22)
local GREEN = Color3.fromRGB(0, 255, 120)
local GREEN_DIM = Color3.fromRGB(0, 160, 80)
local TEXT = Color3.fromRGB(230, 255, 240)
local TEXT_DARK = Color3.fromRGB(8, 18, 12)
local TAB_IDLE = Color3.fromRGB(120, 160, 140)

local ON_BASE = Color3.fromRGB(0, 200, 100)
local ON_GRAD_TOP = Color3.fromRGB(0, 225, 115)
local ON_GRAD_BOT = Color3.fromRGB(0, 150, 75)
local OFF_GRAD_TOP = Color3.fromRGB(22, 40, 30)
local OFF_GRAD_BOT = Color3.fromRGB(12, 20, 16)

local ESP_GUN = Color3.fromRGB(60, 140, 255)
local ESP_KNIFE = Color3.fromRGB(255, 60, 60)
local ESP_NONE = Color3.fromRGB(0, 255, 120)

local gui = Instance.new("ScreenGui")
gui.Name = "VexHub"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999
gui.Parent = CoreGui

local MAIN_W = math.floor(380 * UI_SCALE)
local MAIN_H = math.floor(220 * UI_SCALE)

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, MAIN_W, 0, MAIN_H)
main.Position = UDim2.new(0.5, -MAIN_W / 2, 0.5, -MAIN_H / 2)
main.BackgroundColor3 = BLACK
main.BorderSizePixel = 0
main.Active = false
main.ClipsDescendants = true
main.Visible = not IS_MOBILE
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 18)

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = GREEN
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.15
mainStroke.Parent = main

local mainGradient = Instance.new("UIGradient")
mainGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, BLACK_2),
    ColorSequenceKeypoint.new(1, BLACK)
}
mainGradient.Rotation = 90
mainGradient.Parent = main

local HEADER_H = math.floor(42 * UI_SCALE)

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, HEADER_H)
header.BackgroundColor3 = BLACK_2
header.BorderSizePixel = 0
header.Parent = main
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 18)

local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0, 18)
headerFix.Position = UDim2.new(0, 0, 1, -18)
headerFix.BackgroundColor3 = BLACK_2
headerFix.BorderSizePixel = 0
headerFix.ZIndex = 2
headerFix.Parent = header

local title = Instance.new("TextLabel")
title.Text = "VEX HUB"
title.Font = Enum.Font.GothamBold
title.TextSize = math.floor(16 * UI_SCALE)
title.TextColor3 = GREEN
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, 0, 1, 0)
title.ZIndex = 3
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.Text = "utility v2.4"
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = math.floor(11 * UI_SCALE)
subtitle.TextColor3 = Color3.fromRGB(120, 200, 150)
subtitle.BackgroundTransparency = 1
subtitle.Size = UDim2.new(1, 0, 0, 14)
subtitle.Position = UDim2.new(0, 0, 1, -16)
subtitle.ZIndex = 4
subtitle.Parent = header

local SIDEBAR_W = math.floor(110 * UI_SCALE)

local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, -HEADER_H)
sidebar.Position = UDim2.new(0, 0, 0, HEADER_H)
sidebar.BackgroundColor3 = BLACK_2
sidebar.BorderSizePixel = 0
sidebar.Parent = main

local sidebarSep = Instance.new("Frame")
sidebarSep.Size = UDim2.new(0, 1, 1, 0)
sidebarSep.Position = UDim2.new(1, -1, 0, 0)
sidebarSep.BackgroundColor3 = GREEN_DIM
sidebarSep.BackgroundTransparency = 0.7
sidebarSep.BorderSizePixel = 0
sidebarSep.Parent = sidebar

local tabNames = {"Movement", "Visuals", "Misc"}
local tabData = {}

local TAB_H = math.floor(34 * UI_SCALE)
local TAB_GAP = math.floor(6 * UI_SCALE)
local TAB_PAD = math.floor(8 * UI_SCALE)

for i, name in ipairs(tabNames) do
    local tb = Instance.new("TextButton")
    tb.Size = UDim2.new(1, -TAB_PAD * 2, 0, TAB_H)
    tb.Position = UDim2.new(0, TAB_PAD, 0, TAB_PAD + (i - 1) * (TAB_H + TAB_GAP))
    tb.BackgroundColor3 = BLACK_2
    tb.BackgroundTransparency = 1
    tb.BorderSizePixel = 0
    tb.Text = ""
    tb.AutoButtonColor = false
    tb.Parent = sidebar

    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 10)

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 3, 0.55, 0)
    indicator.Position = UDim2.new(0, 0, 0.5, 0)
    indicator.AnchorPoint = Vector2.new(0, 0.5)
    indicator.BackgroundColor3 = GREEN
    indicator.BorderSizePixel = 0
    indicator.BackgroundTransparency = 1
    indicator.Parent = tb
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)

    local lbl = Instance.new("TextLabel")
    lbl.Text = name
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = math.floor(13 * UI_SCALE)
    lbl.TextColor3 = TAB_IDLE
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, -12, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = tb

    tabData[name] = {Button = tb, Label = lbl, Indicator = indicator}
end

local STATUS_H = math.floor(32 * UI_SCALE)

local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -SIDEBAR_W, 1, -HEADER_H - STATUS_H)
content.Position = UDim2.new(0, SIDEBAR_W, 0, HEADER_H)
content.BackgroundTransparency = 1
content.Parent = main

local pages = {}
for _, name in ipairs(tabNames) do
    local page = Instance.new("Frame")
    page.Name = name
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = content
    pages[name] = page
end

local function switchTab(name)
    for n, data in pairs(tabData) do
        if n == name then
            data.Label.TextColor3 = GREEN
            data.Indicator.BackgroundTransparency = 0
            data.Button.BackgroundTransparency = 0.85
        else
            data.Label.TextColor3 = TAB_IDLE
            data.Indicator.BackgroundTransparency = 1
            data.Button.BackgroundTransparency = 1
        end
    end
    for n, page in pairs(pages) do
        page.Visible = (n == name)
    end
end

for name, data in pairs(tabData) do
    data.Button.MouseButton1Click:Connect(function()
        switchTab(name)
    end)
end

local function createActionButton(parent, yOffset, labelOff)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -40, 0, math.floor(42 * UI_SCALE))
    btn.Position = UDim2.new(0, 20, 0, yOffset)
    btn.BackgroundColor3 = BLACK_2
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = parent

    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 14)

    local stroke = Instance.new("UIStroke")
    stroke.Color = GREEN_DIM
    stroke.Thickness = 1.5
    stroke.Transparency = 0.2
    stroke.Parent = btn

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, OFF_GRAD_TOP),
        ColorSequenceKeypoint.new(1, OFF_GRAD_BOT)
    }
    gradient.Rotation = 90
    gradient.Parent = btn

    local fillWrap = Instance.new("Frame")
    fillWrap.Size = UDim2.new(1, 0, 1, 0)
    fillWrap.BackgroundTransparency = 1
    fillWrap.ClipsDescendants = true
    fillWrap.ZIndex = 2
    fillWrap.Parent = btn
    Instance.new("UICorner", fillWrap).CornerRadius = UDim.new(0, 14)

    local fillCircle = Instance.new("Frame")
    fillCircle.AnchorPoint = Vector2.new(0.5, 0.5)
    fillCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
    fillCircle.Size = UDim2.new(0, 0, 0, 0)
    fillCircle.BackgroundColor3 = GREEN
    fillCircle.BorderSizePixel = 0
    fillCircle.ZIndex = 2
    fillCircle.Parent = fillWrap
    Instance.new("UICorner", fillCircle).CornerRadius = UDim.new(1, 0)

    local text = Instance.new("TextLabel")
    text.Text = labelOff
    text.Font = Enum.Font.GothamBold
    text.TextSize = math.floor(15 * UI_SCALE)
    text.TextColor3 = TEXT
    text.BackgroundTransparency = 1
    text.Size = UDim2.new(1, 0, 1, 0)
    text.ZIndex = 3
    text.Parent = btn

    return {
        Button = btn,
        Stroke = stroke,
        Gradient = gradient,
        Fill = fillCircle,
        Text = text,
        LabelOff = labelOff,
        LabelOn = labelOff:gsub("OFF", "ON"),
        Animating = false
    }
end

local function applyState(btnTable, isOn)
    if isOn then
        btnTable.Text.Text = btnTable.LabelOn
        btnTable.Text.TextColor3 = TEXT_DARK
        btnTable.Button.BackgroundColor3 = ON_BASE
        btnTable.Stroke.Color = GREEN
        btnTable.Stroke.Transparency = 0
        btnTable.Gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, ON_GRAD_TOP),
            ColorSequenceKeypoint.new(1, ON_GRAD_BOT)
        }
    else
        btnTable.Text.Text = btnTable.LabelOff
        btnTable.Text.TextColor3 = TEXT
        btnTable.Button.BackgroundColor3 = BLACK_2
        btnTable.Stroke.Color = GREEN_DIM
        btnTable.Stroke.Transparency = 0.2
        btnTable.Gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, OFF_GRAD_TOP),
            ColorSequenceKeypoint.new(1, OFF_GRAD_BOT)
        }
    end
end

local function playFill(btnTable, targetColor, isOn)
    if btnTable.Animating then return end
    btnTable.Animating = true

    btnTable.Text.TextColor3 = isOn and TEXT_DARK or TEXT

    btnTable.Fill.BackgroundColor3 = targetColor
    btnTable.Fill.Size = UDim2.new(0, 0, 0, 0)

    local tween = TweenService:Create(
        btnTable.Fill,
        TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 500, 0, 500)}
    )
    tween:Play()
    tween.Completed:Wait()

    applyState(btnTable, isOn)
    btnTable.Fill.Size = UDim2.new(0, 0, 0, 0)

    btnTable.Animating = false
end

local BTN_ROW = math.floor(54 * UI_SCALE)

local flyBtn = createActionButton(pages.Movement, math.floor(22 * UI_SCALE), "FLY OFF")
local noclipBtn = createActionButton(pages.Movement, math.floor(22 * UI_SCALE) + BTN_ROW, "NOCLIP OFF")

local espBtn = createActionButton(pages.Visuals, math.floor(22 * UI_SCALE), "ESP OFF")

local farmBtn = createActionButton(pages.Misc, math.floor(22 * UI_SCALE), "AUTO FARM OFF")

local status = Instance.new("TextLabel")
status.Text = "READY"
status.Font = Enum.Font.GothamMedium
status.TextSize = math.floor(11 * UI_SCALE)
status.TextColor3 = GREEN_DIM
status.BackgroundTransparency = 1
status.Size = UDim2.new(1, -30, 0, 16)
status.Position = UDim2.new(0, 15, 1, -26)
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = main

local hint = Instance.new("TextLabel")
hint.Text = IS_MOBILE and "[TAP FAB]" or "[INSERT] toggle menu"
hint.Font = Enum.Font.Gotham
hint.TextSize = math.floor(10 * UI_SCALE)
hint.TextColor3 = Color3.fromRGB(90, 130, 105)
hint.BackgroundTransparency = 1
hint.Size = UDim2.new(1, -30, 0, 14)
hint.Position = UDim2.new(0, 15, 1, -12)
hint.TextXAlignment = Enum.TextXAlignment.Right
hint.Parent = main

if IS_MOBILE then
    local FAB_SIZE = 52

    local fab = Instance.new("TextButton")
    fab.Name = "VexFAB"
    fab.Size = UDim2.new(0, FAB_SIZE, 0, FAB_SIZE)
    fab.Position = UDim2.new(1, -FAB_SIZE - 16, 0, 60)
    fab.BackgroundColor3 = BLACK_2
    fab.BorderSizePixel = 0
    fab.Text = "V"
    fab.Font = Enum.Font.GothamBold
    fab.TextSize = 22
    fab.TextColor3 = GREEN
    fab.AutoButtonColor = false
    fab.Parent = gui

    Instance.new("UICorner", fab).CornerRadius = UDim.new(1, 0)

    local fabStroke = Instance.new("UIStroke")
    fabStroke.Color = GREEN
    fabStroke.Thickness = 1.8
    fabStroke.Transparency = 0.15
    fabStroke.Parent = fab

    local dragging, dragStart, startPos, moved
    fab.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = fab.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            if math.abs(delta.X) > 6 or math.abs(delta.Y) > 6 then moved = true end
            if moved then
                fab.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    fab.MouseButton1Click:Connect(function()
        if moved then return end
        main.Visible = not main.Visible
    end)
end

do
    local dragging, dragStart, startPos

    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function getHRP()
    local char = player.Character
    if not char then return end
    return char:FindFirstChild("HumanoidRootPart")
end
local function getHumanoid()
    local char = player.Character
    if not char then return end
    return char:FindFirstChildOfClass("Humanoid")
end

local noclipOn = false
local noclipParts = {}
local noclipCharConn = nil

local function setPartNoCollide(part)
    part.CanCollide = false
    part.CanTouch = false
    noclipParts[part] = true
end

local function applyNoclipEverywhere()
    local char = player.Character
    if not char then return end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BasePart") then
            setPartNoCollide(d)
        end
    end
end

local function restoreCollide()
    for part in pairs(noclipParts) do
        if part and part.Parent then
            part.CanCollide = true
            part.CanTouch = true
        end
    end
    noclipParts = {}
end

local function bindNoclipToChar(char)
    if noclipCharConn then noclipCharConn:Disconnect() end
    noclipCharConn = char.DescendantAdded:Connect(function(d)
        if noclipOn and d:IsA("BasePart") then
            task.defer(function() setPartNoCollide(d) end)
        end
    end)
end

local function turnNoclip(on)
    noclipOn = on
    if on then
        applyNoclipEverywhere()
        local char = player.Character
        if char then bindNoclipToChar(char) end
    else
        if noclipCharConn then noclipCharConn:Disconnect() noclipCharConn = nil end
        restoreCollide()
    end
end

local FLY_SPEED = 60

local flying = false
local flyBV, flyConn
local lastDebug = 0

local function startFly()
    local hrp = getHRP()
    local hum = getHumanoid()
    if not hrp then
        warn("[VexHub Fly] HRP missing")
        return
    end

    if hrp.Anchored then
        hrp.Anchored = false
        print("[VexHub Fly] HRP was anchored, unanchoring")
    end

    if hum then
        pcall(function()
            hum:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
            hum:ChangeState(Enum.HumanoidStateType.Physics)
        end)
    end

    flyBV = Instance.new("BodyVelocity")
    flyBV.Name = "VexHubFlyBV"
    flyBV.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    flyBV.P = 1250
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = hrp

    if not flyConn then
        flyConn = RunService.RenderStepped:Connect(function()
            if not flying then return end
            local hrp2 = getHRP()
            if not hrp2 then return end

            if not flyBV or not flyBV.Parent then
                flyBV = Instance.new("BodyVelocity")
                flyBV.Name = "VexHubFlyBV"
                flyBV.MaxForce = Vector3.new(1e6, 1e6, 1e6)
                flyBV.P = 1250
                flyBV.Velocity = Vector3.zero
                flyBV.Parent = hrp2
            end

            local cam = workspace.CurrentCamera
            if not cam then return end

            local mv = getMoveVector()
            local dir = Vector3.zero

            if tick() - lastDebug > 1 then
                lastDebug = tick()
                local h = getHumanoid()
                print(("[VexHub Fly] mv=(%.2f,%.2f,%.2f) | vel=%.1f | state=%s | anchored=%s"):format(
                    mv.X, mv.Y, mv.Z,
                    flyBV.Velocity.Magnitude,
                    h and tostring(h:GetState()) or "nil",
                    tostring(hrp2.Anchored)
                ))
            end

            if mv.Magnitude > 0.05 then
                local fwd = cam.CFrame.LookVector
                local right = cam.CFrame.RightVector
                right = Vector3.new(right.X, 0, right.Z)
                if right.Magnitude > 0.01 then right = right.Unit end
                dir = fwd * (-mv.Z) + right * mv.X
            end

            if dir.Magnitude > 0 then
                flyBV.Velocity = dir.Unit * FLY_SPEED
            else
                flyBV.Velocity = Vector3.zero
            end
        end)
    end

    if not noclipOn then
        turnNoclip(true)
    end

    print("[VexHub Fly] ON")
end

local function stopFly()
    if flyBV then flyBV:Destroy() flyBV = nil end

    local hum = getHumanoid()
    if hum then
        pcall(function()
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end)
    end

    if noclipOn and not farming then
        turnNoclip(false)
    end

    print("[VexHub Fly] OFF")
end

local espOn = false
local espHighlights = {}
local espLoopThread

local function getToolType(plr)
    local hasGun, hasKnife = false, false
    local function scan(container)
        if not container then return end
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") then
                if item.Name == "Gun" then hasGun = true end
                if item.Name == "Knife" then hasKnife = true end
            end
        end
    end
    scan(plr:FindFirstChild("Backpack"))
    scan(plr.Character)
    if hasGun then return "Gun" end
    if hasKnife then return "Knife" end
    return "None"
end

local function colorForToolType(t)
    if t == "Gun" then return ESP_GUN end
    if t == "Knife" then return ESP_KNIFE end
    return ESP_NONE
end

local function clearESP()
    for plr, hl in pairs(espHighlights) do
        if hl then hl:Destroy() end
        espHighlights[plr] = nil
    end
end

local function updateESP()
    for plr, hl in pairs(espHighlights) do
        if not plr.Parent or not plr.Character or not hl.Parent then
            hl:Destroy()
            espHighlights[plr] = nil
        end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            local char = plr.Character
            if char then
                local color = colorForToolType(getToolType(plr))
                local hl = espHighlights[plr]
                if not hl or hl.Parent ~= char then
                    if hl then hl:Destroy() end
                    hl = Instance.new("Highlight")
                    hl.Name = "VexHubESP"
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.FillTransparency = 0.55
                    hl.OutlineTransparency = 0
                    hl.Adornee = char
                    hl.Parent = char
                    espHighlights[plr] = hl
                end
                hl.FillColor = color
                hl.OutlineColor = color
            end
        end
    end
end

local function startESP()
    if espLoopThread then return end
    espLoopThread = task.spawn(function()
        while espOn do
            pcall(updateESP)
            task.wait(0.15)
        end
    end)
end

local function stopESP()
    espOn = false
    espLoopThread = nil
    clearESP()
end

Players.PlayerRemoving:Connect(function(plr)
    if espHighlights[plr] then
        espHighlights[plr]:Destroy()
        espHighlights[plr] = nil
    end
end)

local farming = false
local farmCoins = {}
local farmScanTr = nil
local farmMoveConn = nil
local farmBP = nil
local farmJuking = false
local lastJuke = 0

local FARM_Y_OFFSET = -3
local FARM_ARRIVE = 6
local FARM_RESCAN = 0.25
local FARM_P = 60000
local FARM_D = 4000
local JUKE_DOWN = 12
local JUKE_UP = 6
local JUKE_HOLD = 0.05
local JUKE_COOLDOWN = 0.3

local function refreshCoins()
    local list, seen = {}, {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "CoinContainer" then
            for _, child in ipairs(obj:GetChildren()) do
                if child:IsA("BasePart") and child.Name == "Coin_Server" and not seen[child] then
                    seen[child] = true
                    table.insert(list, child)
                elseif child:IsA("Model") and child.Name == "Coin_Server" then
                    local prim = child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart")
                    if prim and not seen[prim] then
                        seen[prim] = true
                        table.insert(list, prim)
                    end
                end
            end
        end
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "Coin_Server" and not seen[obj] then
            seen[obj] = true
            table.insert(list, obj)
        end
    end
    farmCoins = list
end

local function findNearestCoin(hrp)
    refreshCoins()
    local nearest, nearestDist = nil, math.huge
    for _, coin in ipairs(farmCoins) do
        if coin and coin.Parent then
            local d = (coin.Position - hrp.Position).Magnitude
            if d < nearestDist then
                nearestDist = d
                nearest = coin
            end
        end
    end
    return nearest, nearestDist
end

local function makeFarmBP(hrp)
    local bp = Instance.new("BodyPosition")
    bp.Name = "VexHubFarmBP"
    bp.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bp.P = FARM_P
    bp.D = FARM_D
    bp.Position = hrp.Position
    bp.Parent = hrp
    return bp
end

local function doJuke(hrp, coin)
    farmJuking = true
    lastJuke = tick()
    local bpWas = farmBP
    if bpWas then bpWas.Enabled = false end
    local savedRot = hrp.CFrame - hrp.CFrame.Position
    hrp.CFrame = CFrame.new(coin.Position - Vector3.new(0, JUKE_DOWN, 0)) * savedRot
    task.wait(JUKE_HOLD)
    hrp.CFrame = CFrame.new(coin.Position + Vector3.new(0, JUKE_UP, 0)) * savedRot
    task.wait(JUKE_HOLD)
    if bpWas and bpWas.Parent then
        bpWas.Enabled = true
        bpWas.Position = hrp.Position
    end
    farmJuking = false
end

local function startFarm()
    farming = true
    refreshCoins()
    print(("[VexHub Farm] START. Coin_Server: %d"):format(#farmCoins))

    local hrp = getHRP()
    if hrp then farmBP = makeFarmBP(hrp) end

    if not noclipOn then
        turnNoclip(true)
    end

    if not farmScanTr then
        farmScanTr = task.spawn(function()
            while farming do
                task.wait(FARM_RESCAN)
                pcall(refreshCoins)
            end
            farmScanTr = nil
        end)
    end

    if not farmMoveConn then
        farmMoveConn = RunService.Heartbeat:Connect(function()
            if not farming or farmJuking then return end
            local hrp2 = getHRP()
            if not hrp2 then return end
            if not farmBP or farmBP.Parent ~= hrp2 then
                if farmBP then farmBP:Destroy() end
                farmBP = makeFarmBP(hrp2)
            end
            local coin, dist = findNearestCoin(hrp2)
            if not coin then
                farmBP.Position = hrp2.Position
                return
            end
            farmBP.Position = coin.Position + Vector3.new(0, FARM_Y_OFFSET, 0)
            if dist < FARM_ARRIVE and (tick() - lastJuke) > JUKE_COOLDOWN then
                task.spawn(doJuke, hrp2, coin)
            end
        end)
    end
end

local function stopFarm()
    farming = false
    if farmMoveConn then farmMoveConn:Disconnect() farmMoveConn = nil end
    if farmBP then farmBP:Destroy() farmBP = nil end
    farmScanTr = nil
    farmCoins = {}
    farmJuking = false
    if noclipOn and not flying then
        turnNoclip(false)
    end
    print("[VexHub Farm] STOP")
end

local function updateStatus()
    local active = {}
    if flying then table.insert(active, "FLY") end
    if noclipOn then table.insert(active, "NOCLIP") end
    if espOn then table.insert(active, "ESP") end
    if farming then table.insert(active, "FARM") end
    if #active == 0 then
        status.Text = "READY"
        status.TextColor3 = GREEN_DIM
    else
        status.Text = table.concat(active, " + ")
        status.TextColor3 = GREEN
    end
end

local function hookHover(btnTable, isOnGetter)
    local tween
    btnTable.Button.MouseEnter:Connect(function()
        if isOnGetter() then return end
        if tween then tween:Cancel() end
        tween = TweenService:Create(btnTable.Stroke, TweenInfo.new(0.15), {Transparency = 0})
        tween:Play()
    end)
    btnTable.Button.MouseLeave:Connect(function()
        if isOnGetter() then return end
        if tween then tween:Cancel() end
        tween = TweenService:Create(btnTable.Stroke, TweenInfo.new(0.15), {Transparency = 0.2})
        tween:Play()
    end)
end

hookHover(flyBtn, function() return flying end)
hookHover(noclipBtn, function() return noclipOn end)
hookHover(espBtn, function() return espOn end)
hookHover(farmBtn, function() return farming end)

flyBtn.Button.MouseButton1Click:Connect(function()
    if flyBtn.Animating then return end
    if flying then
        flying = false
        stopFly()
        playFill(flyBtn, BLACK_2, false)
    else
        flying = true
        startFly()
        playFill(flyBtn, ON_BASE, true)
    end
    updateStatus()
end)

noclipBtn.Button.MouseButton1Click:Connect(function()
    if noclipBtn.Animating then return end
    if noclipOn then
        noclipOn = false
        if not flying and not farming then
            turnNoclip(false)
        end
        playFill(noclipBtn, BLACK_2, false)
    else
        noclipOn = true
        turnNoclip(true)
        playFill(noclipBtn, ON_BASE, true)
    end
    updateStatus()
end)

espBtn.Button.MouseButton1Click:Connect(function()
    if espBtn.Animating then return end
    if espOn then
        espOn = false
        stopESP()
        playFill(espBtn, BLACK_2, false)
    else
        espOn = true
        startESP()
        playFill(espBtn, ON_BASE, true)
    end
    updateStatus()
end)

farmBtn.Button.MouseButton1Click:Connect(function()
    if farmBtn.Animating then return end
    if farming then
        stopFarm()
        playFill(farmBtn, BLACK_2, false)
    else
        startFarm()
        playFill(farmBtn, ON_BASE, true)
    end
    updateStatus()
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        main.Visible = not main.Visible
    end
end)

player.CharacterAdded:Connect(function(char)
    noclipParts = {}
    task.wait(0.3)
    if flying then
        if flyBV then flyBV:Destroy() flyBV = nil end
        startFly()
    end
    if farming then
        if farmBP then farmBP:Destroy() farmBP = nil end
        local hrp = getHRP()
        if hrp then farmBP = makeFarmBP(hrp) end
    end
    if noclipOn or flying or farming then
        applyNoclipEverywhere()
        bindNoclipToChar(char)
    end
end)

applyState(flyBtn, false)
applyState(noclipBtn, false)
applyState(espBtn, false)
applyState(farmBtn, false)
switchTab("Movement")
updateStatus()
