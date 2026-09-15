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

local function getHRP()
    local char = player.Character
    if not char then return end
    return char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoidRef()
    local char = player.Character
    if not char then return end
    return char:FindFirstChildOfClass("Humanoid")
end

local THEMES = {
    {name = "Green",  base = Color3.fromRGB(0, 255, 120),   dim = Color3.fromRGB(0, 160, 80),    onBase = Color3.fromRGB(0, 200, 100),  onTop = Color3.fromRGB(0, 225, 115),  onBot = Color3.fromRGB(0, 150, 75)},
    {name = "Blue",   base = Color3.fromRGB(80, 180, 255),  dim = Color3.fromRGB(40, 110, 180),  onBase = Color3.fromRGB(40, 140, 220), onTop = Color3.fromRGB(60, 160, 240), onBot = Color3.fromRGB(30, 110, 180)},
    {name = "Red",    base = Color3.fromRGB(255, 80, 80),   dim = Color3.fromRGB(180, 40, 40),   onBase = Color3.fromRGB(200, 50, 50),  onTop = Color3.fromRGB(230, 70, 70),  onBot = Color3.fromRGB(150, 30, 30)},
    {name = "Pink",   base = Color3.fromRGB(255, 120, 200), dim = Color3.fromRGB(180, 60, 140),  onBase = Color3.fromRGB(220, 80, 170), onTop = Color3.fromRGB(240, 100, 190),onBot = Color3.fromRGB(170, 50, 130)},
    {name = "Yellow", base = Color3.fromRGB(255, 215, 60),  dim = Color3.fromRGB(180, 150, 30),  onBase = Color3.fromRGB(220, 180, 40), onTop = Color3.fromRGB(240, 200, 60), onBot = Color3.fromRGB(170, 140, 30)},
}

local currentTheme = 1

local BLACK = Color3.fromRGB(10, 10, 12)
local BLACK_2 = Color3.fromRGB(18, 18, 22)
local TEXT = Color3.fromRGB(230, 255, 240)
local TEXT_DARK = Color3.fromRGB(8, 18, 12)
local TAB_IDLE = Color3.fromRGB(120, 160, 140)
local OFF_GRAD_TOP = Color3.fromRGB(22, 40, 30)
local OFF_GRAD_BOT = Color3.fromRGB(12, 20, 16)

local ESP_GUN = Color3.fromRGB(60, 140, 255)
local ESP_KNIFE = Color3.fromRGB(255, 60, 60)
local ESP_NONE = Color3.fromRGB(0, 255, 120)
local ESP_COIN = Color3.fromRGB(255, 215, 0)

local speedBoostOn = false
local speedBoostValue = 0
local jumpBoostOn = false
local jumpBoostValue = 0

local BASE_WALKSPEED = 16
local BASE_JUMPPOWER = 50

local speedConn = nil
local speedLock = false
local jumpConn = nil
local jumpConn2 = nil
local jumpLock = false

local function computeSpeedTarget()
    return BASE_WALKSPEED + speedBoostValue
end

local function computeJumpTarget()
    return BASE_JUMPPOWER + jumpBoostValue
end

local function applySpeedNow()
    if not speedBoostOn then return end
    local hum = getHumanoidRef()
    if not hum then return end
    local target = computeSpeedTarget()
    if hum.WalkSpeed ~= target then
        speedLock = true
        hum.WalkSpeed = target
        speedLock = false
    end
end

local function applyJumpNow()
    if not jumpBoostOn then return end
    local hum = getHumanoidRef()
    if not hum then return end
    local target = computeJumpTarget()
    jumpLock = true
    if not hum.UseJumpPower then
        hum.UseJumpPower = true
    end
    if hum.JumpPower ~= target then
        hum.JumpPower = target
    end
    jumpLock = false
end

local function detachSpeedListener()
    if speedConn then
        speedConn:Disconnect()
        speedConn = nil
    end
end

local function detachJumpListener()
    if jumpConn then
        jumpConn:Disconnect()
        jumpConn = nil
    end
    if jumpConn2 then
        jumpConn2:Disconnect()
        jumpConn2 = nil
    end
end

local function attachSpeedListener()
    detachSpeedListener()
    local hum = getHumanoidRef()
    if not hum then return end
    speedConn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if speedLock then return end
        if not speedBoostOn then return end
        local target = computeSpeedTarget()
        if hum.WalkSpeed ~= target then
            speedLock = true
            hum.WalkSpeed = target
            speedLock = false
        end
    end)
end

local function attachJumpListener()
    detachJumpListener()
    local hum = getHumanoidRef()
    if not hum then return end
    jumpConn = hum:GetPropertyChangedSignal("JumpPower"):Connect(function()
        if jumpLock then return end
        if not jumpBoostOn then return end
        local target = computeJumpTarget()
        if hum.JumpPower ~= target then
            jumpLock = true
            if not hum.UseJumpPower then
                hum.UseJumpPower = true
            end
            hum.JumpPower = target
            jumpLock = false
        end
    end)
    jumpConn2 = hum:GetPropertyChangedSignal("UseJumpPower"):Connect(function()
        if jumpLock then return end
        if not jumpBoostOn then return end
        if not hum.UseJumpPower then
            jumpLock = true
            hum.UseJumpPower = true
            hum.JumpPower = computeJumpTarget()
            jumpLock = false
        end
    end)
end

local function setSpeedBoost(on)
    speedBoostOn = on
    if on then
        applySpeedNow()
        attachSpeedListener()
    else
        detachSpeedListener()
        local hum = getHumanoidRef()
        if hum then
            speedLock = true
            hum.WalkSpeed = BASE_WALKSPEED
            speedLock = false
        end
    end
end

local function setJumpBoost(on)
    jumpBoostOn = on
    if on then
        applyJumpNow()
        attachJumpListener()
    else
        detachJumpListener()
        local hum = getHumanoidRef()
        if hum then
            jumpLock = true
            hum.UseJumpPower = false
            hum.JumpHeight = 7.2
            jumpLock = false
        end
    end
end

local gui = Instance.new("ScreenGui")
gui.Name = "VexHub"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999
gui.Parent = CoreGui

local MAIN_W = math.floor(380 * UI_SCALE)
local MAIN_H = math.floor(300 * UI_SCALE)

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
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, 0, 1, 0)
title.ZIndex = 3
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.Text = "utility v3.0"
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = math.floor(11 * UI_SCALE)
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
sidebarSep.BackgroundTransparency = 0.7
sidebarSep.BorderSizePixel = 0
sidebarSep.Parent = sidebar

local tabNames = {"Movement", "Visuals", "Misc", "Settings"}
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

local activeTab = nil

local function switchTab(name)
    activeTab = name
    for n, data in pairs(tabData) do
        if n == name then
            data.Label.TextColor3 = THEMES[currentTheme].base
            data.Indicator.BackgroundColor3 = THEMES[currentTheme].base
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

local PAGE_W = MAIN_W - SIDEBAR_W

local allButtons = {}
local allSliders = {}
local themeDimTexts = {}
local themeAccentTexts = {}

local function createActionButton(parent, xOffset, yOffset, width, labelOff)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, width, 0, math.floor(42 * UI_SCALE))
    btn.Position = UDim2.new(0, xOffset, 0, yOffset)
    btn.BackgroundColor3 = BLACK_2
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = parent

    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 14)

    local stroke = Instance.new("UIStroke")
    stroke.Color = THEMES[currentTheme].dim
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
    fillCircle.BackgroundColor3 = THEMES[currentTheme].base
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

    local obj = {
        Button = btn,
        Stroke = stroke,
        Gradient = gradient,
        Fill = fillCircle,
        Text = text,
        LabelOff = labelOff,
        LabelOn = labelOff:gsub("OFF", "ON"),
        Animating = false,
        IsOn = false
    }
    table.insert(allButtons, obj)
    return obj
end

local function applyState(btnTable, isOn)
    local t = THEMES[currentTheme]
    btnTable.IsOn = isOn
    if isOn then
        btnTable.Text.Text = btnTable.LabelOn
        btnTable.Text.TextColor3 = TEXT_DARK
        btnTable.Button.BackgroundColor3 = t.onBase
        btnTable.Stroke.Color = t.base
        btnTable.Stroke.Transparency = 0
        btnTable.Gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, t.onTop),
            ColorSequenceKeypoint.new(1, t.onBot)
        }
    else
        btnTable.Text.Text = btnTable.LabelOff
        btnTable.Text.TextColor3 = TEXT
        btnTable.Button.BackgroundColor3 = BLACK_2
        btnTable.Stroke.Color = t.dim
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

local function createSlider(parent, xOffset, yOffset, width, height, minVal, maxVal, defaultVal, onChange)
    local container = Instance.new("TextButton")
    container.Size = UDim2.new(0, width, 0, height)
    container.Position = UDim2.new(0, xOffset, 0, yOffset)
    container.BackgroundTransparency = 1
    container.Text = ""
    container.AutoButtonColor = false
    container.Parent = parent

    local labelW = math.floor(30 * UI_SCALE)

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -labelW - 8, 0, 6)
    track.Position = UDim2.new(0, 4, 0.5, -3)
    track.BackgroundColor3 = BLACK_2
    track.BorderSizePixel = 0
    track.Parent = container
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = THEMES[currentTheme].base
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(0, 0, 0.5, 0)
    knob.BackgroundColor3 = THEMES[currentTheme].base
    knob.BorderSizePixel = 0
    knob.ZIndex = 3
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Text = tostring(defaultVal)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = math.floor(12 * UI_SCALE)
    valueLabel.TextColor3 = THEMES[currentTheme].base
    valueLabel.BackgroundTransparency = 1
    valueLabel.Size = UDim2.new(0, labelW, 1, 0)
    valueLabel.Position = UDim2.new(1, -labelW, 0, 0)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = container

    local value = defaultVal
    local dragging = false

    local function render()
        local ratio = (value - minVal) / (maxVal - minVal)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        knob.Position = UDim2.new(ratio, 0, 0.5, 0)
        valueLabel.Text = tostring(value)
    end

    local function setFromX(screenX)
        local trackAbsX = track.AbsolutePosition.X
        local trackSizeX = track.AbsoluteSize.X
        if trackSizeX <= 0 then return end
        local ratio = math.clamp((screenX - trackAbsX) / trackSizeX, 0, 1)
        local newVal = math.floor(ratio * (maxVal - minVal) + minVal + 0.5)
        if newVal ~= value then
            value = newVal
            render()
            if onChange then onChange(value) end
        end
    end

    container.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    render()

    local obj = {
        Fill = fill,
        Knob = knob,
        ValueLabel = valueLabel,
        GetValue = function() return value end,
        SetValue = function(v)
            value = math.clamp(math.floor(v), minVal, maxVal)
            render()
            if onChange then onChange(value) end
        end
    }
    table.insert(allSliders, obj)
    return obj
end

local PAD_X = 20
local INNER_W = PAGE_W - PAD_X * 2
local BTN_FULL_W = INNER_W
local BTN_ROW_H = math.floor(42 * UI_SCALE)
local BTN_ROW_GAP = math.floor(6 * UI_SCALE)
local BTN_STEP = BTN_ROW_H + BTN_ROW_GAP

local SPLIT_BTN_W = math.floor(INNER_W * 0.55)
local SPLIT_GAP = math.floor(10 * UI_SCALE)
local SPLIT_SLIDER_W = INNER_W - SPLIT_BTN_W - SPLIT_GAP

local yPos = PAD_X
local flyBtn = createActionButton(pages.Movement, PAD_X, yPos, BTN_FULL_W, "FLY OFF")
yPos = yPos + BTN_STEP

local noclipBtn = createActionButton(pages.Movement, PAD_X, yPos, BTN_FULL_W, "NOCLIP OFF")
yPos = yPos + BTN_STEP

local speedBoostBtn = createActionButton(pages.Movement, PAD_X, yPos, SPLIT_BTN_W, "SPEED OFF")
local speedSlider = createSlider(
    pages.Movement,
    PAD_X + SPLIT_BTN_W + SPLIT_GAP,
    yPos,
    SPLIT_SLIDER_W,
    BTN_ROW_H,
    0,
    100,
    0,
    function(val)
        speedBoostValue = val
        applySpeedNow()
    end
)
yPos = yPos + BTN_STEP

local jumpBoostBtn = createActionButton(pages.Movement, PAD_X, yPos, SPLIT_BTN_W, "JUMP OFF")
local jumpSlider = createSlider(
    pages.Movement,
    PAD_X + SPLIT_BTN_W + SPLIT_GAP,
    yPos,
    SPLIT_SLIDER_W,
    BTN_ROW_H,
    0,
    100,
    0,
    function(val)
        jumpBoostValue = val
        applyJumpNow()
    end
)

local espPlayersBtn = createActionButton(pages.Visuals, PAD_X, PAD_X, BTN_FULL_W, "ESP PLAYERS OFF")
local espCoinsBtn = createActionButton(pages.Visuals, PAD_X, PAD_X + BTN_STEP, BTN_FULL_W, "ESP COINS OFF")

local farmBtn = createActionButton(pages.Misc, PAD_X, PAD_X, BTN_FULL_W, "AUTO FARM OFF")

local themeLabel = Instance.new("TextLabel")
themeLabel.Text = "THEME MANAGER"
themeLabel.Font = Enum.Font.GothamBold
themeLabel.TextSize = math.floor(11 * UI_SCALE)
themeLabel.BackgroundTransparency = 1
themeLabel.Size = UDim2.new(1, -PAD_X * 2, 0, 16)
themeLabel.Position = UDim2.new(0, PAD_X, 0, PAD_X - 4)
themeLabel.TextXAlignment = Enum.TextXAlignment.Left
themeLabel.Parent = pages.Settings
table.insert(themeDimTexts, themeLabel)

local themeRowY = PAD_X + 18
local themeGap = math.floor(6 * UI_SCALE)
local themeBtnW = math.floor((INNER_W - themeGap * 4) / 5)
local themeBtnH = math.floor(38 * UI_SCALE)

local themeButtons = {}

for i, theme in ipairs(THEMES) do
    local swatch = Instance.new("TextButton")
    swatch.Size = UDim2.new(0, themeBtnW, 0, themeBtnH)
    swatch.Position = UDim2.new(0, PAD_X + (i - 1) * (themeBtnW + themeGap), 0, themeRowY)
    swatch.BackgroundColor3 = BLACK_2
    swatch.BorderSizePixel = 0
    swatch.Text = ""
    swatch.AutoButtonColor = false
    swatch.Parent = pages.Settings

    Instance.new("UICorner", swatch).CornerRadius = UDim.new(0, 10)

    local swatchStroke = Instance.new("UIStroke")
    swatchStroke.Color = theme.base
    swatchStroke.Thickness = 1.5
    swatchStroke.Transparency = 0.3
    swatchStroke.Parent = swatch

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 16, 0, 16)
    circle.AnchorPoint = Vector2.new(0.5, 0.5)
    circle.Position = UDim2.new(0.5, 0, 0.5, 0)
    circle.BackgroundColor3 = theme.base
    circle.BorderSizePixel = 0
    circle.Parent = swatch
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

    themeButtons[i] = {Button = swatch, Stroke = swatchStroke, Circle = circle}

    swatch.MouseButton1Click:Connect(function()
        currentTheme = i
        if applyTheme then applyTheme() end
    end)
end

local creditsTitle = Instance.new("TextLabel")
creditsTitle.Text = "CREDITS"
creditsTitle.Font = Enum.Font.GothamBold
creditsTitle.TextSize = math.floor(11 * UI_SCALE)
creditsTitle.BackgroundTransparency = 1
creditsTitle.Size = UDim2.new(1, -PAD_X * 2, 0, 16)
creditsTitle.Position = UDim2.new(0, PAD_X, 0, themeRowY + themeBtnH + math.floor(16 * UI_SCALE))
creditsTitle.TextXAlignment = Enum.TextXAlignment.Left
creditsTitle.Parent = pages.Settings
table.insert(themeDimTexts, creditsTitle)

local creditLine1 = Instance.new("TextLabel")
creditLine1.Text = "Vex Studio"
creditLine1.Font = Enum.Font.GothamBold
creditLine1.TextSize = math.floor(14 * UI_SCALE)
creditLine1.BackgroundTransparency = 1
creditLine1.Size = UDim2.new(1, -PAD_X * 2, 0, 20)
creditLine1.Position = UDim2.new(0, PAD_X, 0, themeRowY + themeBtnH + math.floor(36 * UI_SCALE))
creditLine1.TextXAlignment = Enum.TextXAlignment.Left
creditLine1.Parent = pages.Settings
table.insert(themeAccentTexts, creditLine1)

local creditLine2 = Instance.new("TextLabel")
creditLine2.Text = "Special Thanks to DeepSeek AI"
creditLine2.Font = Enum.Font.Gotham
creditLine2.TextSize = math.floor(11 * UI_SCALE)
creditLine2.BackgroundTransparency = 1
creditLine2.Size = UDim2.new(1, -PAD_X * 2, 0, 16)
creditLine2.Position = UDim2.new(0, PAD_X, 0, themeRowY + themeBtnH + math.floor(58 * UI_SCALE))
creditLine2.TextXAlignment = Enum.TextXAlignment.Left
creditLine2.Parent = pages.Settings
table.insert(themeDimTexts, creditLine2)

local status = Instance.new("TextLabel")
status.Text = "READY"
status.Font = Enum.Font.GothamMedium
status.TextSize = math.floor(11 * UI_SCALE)
status.BackgroundTransparency = 1
status.Size = UDim2.new(1, -30, 0, 16)
status.Position = UDim2.new(0, 15, 1, -26)
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = main

local hint = Instance.new("TextLabel")
hint.Text = IS_MOBILE and "[TAP FAB]" or "[INSERT] toggle menu"
hint.Font = Enum.Font.Gotham
hint.TextSize = math.floor(10 * UI_SCALE)
hint.BackgroundTransparency = 1
hint.Size = UDim2.new(1, -30, 0, 14)
hint.Position = UDim2.new(0, 15, 1, -12)
hint.TextXAlignment = Enum.TextXAlignment.Right
hint.Parent = main

local fab
if IS_MOBILE then
    local FAB_SIZE = 52

    fab = Instance.new("TextButton")
    fab.Name = "VexFAB"
    fab.Size = UDim2.new(0, FAB_SIZE, 0, FAB_SIZE)
    fab.Position = UDim2.new(1, -FAB_SIZE - 16, 0, 60)
    fab.BackgroundColor3 = BLACK_2
    fab.BorderSizePixel = 0
    fab.Text = "V"
    fab.Font = Enum.Font.GothamBold
    fab.TextSize = 22
    fab.AutoButtonColor = false
    fab.Parent = gui

    Instance.new("UICorner", fab).CornerRadius = UDim.new(1, 0)

    local fabStroke = Instance.new("UIStroke")
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

local function updateStatus()
    local active = {}
    if flying then table.insert(active, "FLY") end
    if noclipOn then table.insert(active, "NOCLIP") end
    if speedBoostOn then table.insert(active, "SPEED") end
    if jumpBoostOn then table.insert(active, "JUMP") end
    if espPlayersOn then table.insert(active, "ESP-P") end
    if espCoinsOn then table.insert(active, "ESP-C") end
    if farming then table.insert(active, "FARM") end
    if #active == 0 then
        status.Text = "READY"
        status.TextColor3 = THEMES[currentTheme].dim
    else
        status.Text = table.concat(active, " + ")
        status.TextColor3 = THEMES[currentTheme].base
    end
end

local function refreshButtonsVisual()
    for _, btn in ipairs(allButtons) do
        applyState(btn, btn.IsOn)
    end
end

function applyTheme()
    local t = THEMES[currentTheme]
    mainStroke.Color = t.base
    title.TextColor3 = t.base
    subtitle.TextColor3 = t.base
    sidebarSep.BackgroundColor3 = t.dim
    hint.TextColor3 = t.dim

    for _, el in ipairs(themeDimTexts) do
        el.TextColor3 = t.dim
    end
    for _, el in ipairs(themeAccentTexts) do
        el.TextColor3 = t.base
    end

    for _, data in pairs(tabData) do
        if activeTab and data.Label.Text == activeTab then
            data.Label.TextColor3 = t.base
            data.Indicator.BackgroundColor3 = t.base
        end
    end

    for _, s in ipairs(allSliders) do
        s.Fill.BackgroundColor3 = t.base
        s.Knob.BackgroundColor3 = t.base
        s.ValueLabel.TextColor3 = t.base
    end

    for i, tb in ipairs(themeButtons) do
        tb.Stroke.Transparency = (i == currentTheme) and 0 or 0.5
    end

    if fab then
        fab.TextColor3 = t.base
        for _, child in ipairs(fab:GetChildren()) do
            if child:IsA("UIStroke") then
                child.Color = t.base
            end
        end
    end

    refreshButtonsVisual()
    updateStatus()
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
local flyBV, flyBG, flyConn
local lastDebug = 0

local function startFly()
    local hrp = getHRP()
    local hum = getHumanoidRef()
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
            hum.AutoRotate = false
        end)
    end

    flyBV = Instance.new("BodyVelocity")
    flyBV.Name = "VexHubFlyBV"
    flyBV.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    flyBV.P = 1250
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = hrp

    flyBG = Instance.new("BodyGyro")
    flyBG.Name = "VexHubFlyBG"
    flyBG.MaxTorque = Vector3.new(4e5, 4e5, 4e5)
    flyBG.P = 10000
    flyBG.D = 200
    flyBG.CFrame = hrp.CFrame
    flyBG.Parent = hrp

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
            if not flyBG or not flyBG.Parent then
                flyBG = Instance.new("BodyGyro")
                flyBG.Name = "VexHubFlyBG"
                flyBG.MaxTorque = Vector3.new(4e5, 4e5, 4e5)
                flyBG.P = 10000
                flyBG.D = 200
                flyBG.CFrame = hrp2.CFrame
                flyBG.Parent = hrp2
            end

            local cam = workspace.CurrentCamera
            if not cam then return end

            local mv = getMoveVector()
            local dir = Vector3.zero

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

            local camLook = cam.CFrame.LookVector
            flyBG.CFrame = CFrame.lookAt(hrp2.Position, hrp2.Position + camLook)
        end)
    end

    if not noclipOn then
        turnNoclip(true)
    end

    print("[VexHub Fly] ON")
end

local function stopFly()
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end

    local hum = getHumanoidRef()
    if hum then
        pcall(function()
            hum:ChangeState(Enum.HumanoidStateType.Running)
            hum.AutoRotate = true
        end)
    end

    task.defer(function()
        task.wait(0.1)
        pcall(function()
            local cam = workspace.CurrentCamera
            if cam then
                cam.CameraType = Enum.CameraType.Custom
                if hum and hum.Parent then
                    cam.CameraSubject = hum
                end
            end
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            UserInputService.MouseIconEnabled = true
        end)
    end)

    if noclipOn and not farming then
        turnNoclip(false)
    end

    print("[VexHub Fly] OFF")
end

local espPlayersOn = false
local espCoinsOn = false
local playerHighlights = {}
local coinHighlights = {}
local espLoopThread = nil

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

local function clearPlayerESP()
    for plr, hl in pairs(playerHighlights) do
        if hl then hl:Destroy() end
        playerHighlights[plr] = nil
    end
end

local function clearCoinESP()
    for coin, hl in pairs(coinHighlights) do
        if hl then hl:Destroy() end
        coinHighlights[coin] = nil
    end
end

local function collectCoins()
    local list = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "Coin_Server" then
            table.insert(list, obj)
        end
    end
    return list
end

local function updatePlayerESP()
    for plr, hl in pairs(playerHighlights) do
        if not plr.Parent or not plr.Character or not hl.Parent then
            hl:Destroy()
            playerHighlights[plr] = nil
        end
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            local char = plr.Character
            if char then
                local color = colorForToolType(getToolType(plr))
                local hl = playerHighlights[plr]
                if not hl or hl.Parent ~= char then
                    if hl then hl:Destroy() end
                    hl = Instance.new("Highlight")
                    hl.Name = "VexHubESP_Player"
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.FillTransparency = 0.55
                    hl.OutlineTransparency = 0
                    hl.Adornee = char
                    hl.Parent = char
                    playerHighlights[plr] = hl
                end
                hl.FillColor = color
                hl.OutlineColor = color
            end
        end
    end
end

local function updateCoinESP()
    local coins = collectCoins()
    local seen = {}

    for _, coin in ipairs(coins) do
        if coin and coin.Parent then
            seen[coin] = true
            local hl = coinHighlights[coin]
            if not hl or not hl.Parent then
                if hl then hl:Destroy() end
                hl = Instance.new("Highlight")
                hl.Name = "VexHubESP_Coin"
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.FillTransparency = 0.4
                hl.OutlineTransparency = 0
                hl.FillColor = ESP_COIN
                hl.OutlineColor = ESP_COIN
                hl.Adornee = coin
                hl.Parent = coin
                coinHighlights[coin] = hl
            end
        end
    end

    for coin, hl in pairs(coinHighlights) do
        if not seen[coin] or not coin.Parent then
            hl:Destroy()
            coinHighlights[coin] = nil
        end
    end
end

local function updateESP()
    if espPlayersOn then
        updatePlayerESP()
    else
        clearPlayerESP()
    end

    if espCoinsOn then
        updateCoinESP()
    else
        clearCoinESP()
    end
end

local function startESP()
    if espLoopThread then return end
    espLoopThread = task.spawn(function()
        while espPlayersOn or espCoinsOn do
            pcall(updateESP)
            task.wait(0.15)
        end
        clearPlayerESP()
        clearCoinESP()
        espLoopThread = nil
    end)
end

local function stopESPIfNeeded()
    if not espPlayersOn and not espCoinsOn then
        clearPlayerESP()
        clearCoinESP()
    end
end

Players.PlayerRemoving:Connect(function(plr)
    if playerHighlights[plr] then
        playerHighlights[plr]:Destroy()
        playerHighlights[plr] = nil
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
hookHover(speedBoostBtn, function() return speedBoostOn end)
hookHover(jumpBoostBtn, function() return jumpBoostOn end)
hookHover(espPlayersBtn, function() return espPlayersOn end)
hookHover(espCoinsBtn, function() return espCoinsOn end)
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
        playFill(flyBtn, THEMES[currentTheme].onBase, true)
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
        playFill(noclipBtn, THEMES[currentTheme].onBase, true)
    end
    updateStatus()
end)

speedBoostBtn.Button.MouseButton1Click:Connect(function()
    if speedBoostBtn.Animating then return end
    if speedBoostOn then
        setSpeedBoost(false)
        playFill(speedBoostBtn, BLACK_2, false)
    else
        setSpeedBoost(true)
        playFill(speedBoostBtn, THEMES[currentTheme].onBase, true)
    end
    updateStatus()
end)

jumpBoostBtn.Button.MouseButton1Click:Connect(function()
    if jumpBoostBtn.Animating then return end
    if jumpBoostOn then
        setJumpBoost(false)
        playFill(jumpBoostBtn, BLACK_2, false)
    else
        setJumpBoost(true)
        playFill(jumpBoostBtn, THEMES[currentTheme].onBase, true)
    end
    updateStatus()
end)

espPlayersBtn.Button.MouseButton1Click:Connect(function()
    if espPlayersBtn.Animating then return end
    if espPlayersOn then
        espPlayersOn = false
        playFill(espPlayersBtn, BLACK_2, false)
        stopESPIfNeeded()
    else
        espPlayersOn = true
        startESP()
        playFill(espPlayersBtn, THEMES[currentTheme].onBase, true)
    end
    updateStatus()
end)

espCoinsBtn.Button.MouseButton1Click:Connect(function()
    if espCoinsBtn.Animating then return end
    if espCoinsOn then
        espCoinsOn = false
        playFill(espCoinsBtn, BLACK_2, false)
        stopESPIfNeeded()
    else
        espCoinsOn = true
        startESP()
        playFill(espCoinsBtn, THEMES[currentTheme].onBase, true)
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
        playFill(farmBtn, THEMES[currentTheme].onBase, true)
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
        if flyBG then flyBG:Destroy() flyBG = nil end
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
    if speedBoostOn then
        applySpeedNow()
        attachSpeedListener()
    end
    if jumpBoostOn then
        applyJumpNow()
        attachJumpListener()
    end
end)

applyState(flyBtn, false)
applyState(noclipBtn, false)
applyState(speedBoostBtn, false)
applyState(jumpBoostBtn, false)
applyState(espPlayersBtn, false)
applyState(espCoinsBtn, false)
applyState(farmBtn, false)
switchTab("Movement")
applyTheme()
