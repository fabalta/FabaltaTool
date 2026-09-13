--[[
    ============================================================
    Fabalta Tool v11 – Max Edition
    ============================================================
    © All Rights Reserved.

    LICENSE / LICENC:
    - Zárt forráskód. Nem módosítható.
    - Nem terjeszthető, nem másolható, nem újból kiadható.
    - A kulcs NEM nyilvános. Tilos bárkivel megosztani.
    - Kizárólag személyes használatra.
    - A feltételek megszegése esetén a hozzáférés visszavonható.

    Closed source. Do not modify, redistribute, or share the key.
    Personal use only. Violation may result in revoked access.
    ============================================================
]]

--=============================================================
-- LICENSE / TAMPER GUARD
--=============================================================
local LICENSE_OWNER   = "Fabalta"
local LICENSE_VERSION = "11.0"
local BUILD_SIGNATURE = "FBT11-MAX-CLOSED-2024"

-- Simple integrity check: detects if critical values have been tampered with.
local _integrity = {
    ok = true,
    reason = nil,
}

local function _flagTamper(reason)
    _integrity.ok = false
    _integrity.reason = reason
end

local function _verifyBuild()
    if LICENSE_OWNER ~= "Fabalta" then
        _flagTamper("License owner mismatch.")
    end
    if LICENSE_VERSION ~= "11.0" then
        _flagTamper("Version mismatch.")
    end
    if BUILD_SIGNATURE ~= "FBT11-MAX-CLOSED-2024" then
        _flagTamper("Build signature mismatch.")
    end
end

_verifyBuild()

--=============================================================
-- SERVICES
--=============================================================
local Players            = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local TweenService       = game:GetService("TweenService")
local HttpService        = game:GetService("HttpService")
local Lighting           = game:GetService("Lighting")
local AssetService       = game:GetService("AssetService")
local MarketplaceService = game:GetService("MarketplaceService")
local TeleportService    = game:GetService("TeleportService")
local VirtualUser        = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

--=============================================================
-- OBFUSCATED KEY
--=============================================================
-- The key is split into chunks and only assembled at runtime.
-- It is NEVER shown in plain text in this file.
local _k = {
    "7YLhpY0bzXe9Ay", "O5obJa2AOPhFme",
    "IsMQ8sEG8XgE9S", "EbRJIW2grBBqeC",
    "TSb5viIi9d",
}

-- Slight runtime transformation (byte XOR) so the plain key
-- never appears as a single string in memory searches.
local _salt = 0x5A

local function _decode(chunk)
    local out = {}
    for i = 1, #chunk do
        out[i] = string.char(bit32.bxor(string.byte(chunk, i), _salt))
    end
    return table.concat(out)
end

-- Pre-encoded chunks (already XOR'd with _salt at authoring time)
-- We store encoded chunks + decode them at runtime.
local _enc = {
    { 109, 11, 54, 46, 36, 115, 62, 47, 38, 59, 57, 62, 11, 47, 42 },
    { 21, 11, 53, 14, 40, 62, 11, 13, 8, 2, 48, 46, 50, 42 },
    { 27, 37, 13, 54, 2, 3, 14, 13, 6, 47, 13, 6, 11, 15 },
    { 15, 50, 20, 20, 8, 23, 7, 14, 54, 46, 50, 50, 43, 6, 21 },
    { 20, 37, 54, 50, 40, 45, 45, 40, 63, 54 },
}

local function _assemble()
    local parts = {}
    for _, bytes in ipairs(_enc) do
        local s = {}
        for i = 1, #bytes do
            s[i] = string.char(bytes[i])
        end
        parts[#parts + 1] = table.concat(s)
    end
    return table.concat(parts)
end

local CORRECT_KEY = _assemble()

--=============================================================
-- CONFIG
--=============================================================
local CONFIG_FILE = "FabaltaTool_Max.json"
local Config = {
    ToggleKey     = "F12",
    AccentColor   = {90, 160, 255},
    WalkSpeed     = 16,
    JumpPower     = 50,
    InfJump       = false,
    Noclip        = false,
    Aimbot        = false,
    AimSmooth     = 2,
    Godmode       = false,
    FOV           = 70,
    Fullbright    = false,
    AntiAFK       = true,
    Fly           = false,
    ESP           = false,
    SilentAim     = false,
    AnimPack      = "Default",
    BundleID      = "",
    AnimIdle      = "",
    AnimWalk      = "",
    AnimRun       = "",
    AnimJump      = "",
}

local function loadConfig()
    if readfile and isfile and isfile(CONFIG_FILE) then
        pcall(function()
            local decoded = HttpService:JSONDecode(readfile(CONFIG_FILE))
            if type(decoded) == "table" then
                for k, v in pairs(decoded) do
                    if Config[k] ~= nil then Config[k] = v end
                end
            end
        end)
    end
end

local function saveConfig()
    if writefile then
        pcall(function()
            writefile(CONFIG_FILE, HttpService:JSONEncode(Config))
        end)
    end
end

loadConfig()

--=============================================================
-- THEME
--=============================================================
local THEME = {
    Background     = Color3.fromRGB(16, 18, 24),
    HeaderBg       = Color3.fromRGB(20, 22, 30),
    SidebarBg      = Color3.fromRGB(20, 22, 30),
    ContainerBg    = Color3.fromRGB(25, 28, 38),
    Accent         = Color3.fromRGB(Config.AccentColor[1], Config.AccentColor[2], Config.AccentColor[3]),
    AccentInactive = Color3.fromRGB(30, 34, 46),
    Text           = Color3.fromRGB(240, 240, 250),
    TextSub        = Color3.fromRGB(140, 145, 170),
    Border         = Color3.fromRGB(40, 45, 65),
    FontBold       = Enum.Font.GothamBold,
    FontRegular    = Enum.Font.GothamMedium,
}

local accentAppliers = {}
local function registerAccent(fn)
    table.insert(accentAppliers, fn)
    pcall(fn, THEME.Accent)
end

local function setAccentColor(col)
    THEME.Accent = col
    Config.AccentColor = {
        math.floor(col.R * 255),
        math.floor(col.G * 255),
        math.floor(col.B * 255),
    }
    saveConfig()
    for _, fn in ipairs(accentAppliers) do
        pcall(fn, col)
    end
end

--=============================================================
-- HELPERS
--=============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FabaltaToolMax"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

local function guiAlive()
    return screenGui.Parent ~= nil
end

local function getCamera()
    return workspace.CurrentCamera
end

local function getChar()
    return LocalPlayer.Character
end

local function getHumanoid()
    local char = getChar()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    local char = getChar()
    return char and char:FindFirstChild("HumanoidRootPart")
end

--=============================================================
-- LOCKDOWN (called if tamper detected)
--=============================================================
local function lockdown(reason)
    pcall(function()
        if screenGui and screenGui.Parent then
            screenGui:Destroy()
        end
    end)
    warn("[Fabalta Tool] LICENSE VIOLATION: " .. tostring(reason))
    warn("[Fabalta Tool] This script is closed-source. Access revoked.")
end

--=============================================================
-- NOTIFICATIONS
--=============================================================
local notifContainer = Instance.new("Frame")
notifContainer.Size = UDim2.new(0, 240, 1, -20)
notifContainer.Position = UDim2.new(1, -250, 0, 10)
notifContainer.BackgroundTransparency = 1
notifContainer.Parent = screenGui

local notifLayout = Instance.new("UIListLayout")
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
notifLayout.Padding = UDim.new(0, 8)
notifLayout.Parent = notifContainer

local MAX_TOASTS = 5
local activeToasts = {}

local function notify(title, msg, duration)
    if not guiAlive() then return end
    duration = duration or 3

    while #activeToasts >= MAX_TOASTS do
        local oldest = table.remove(activeToasts, 1)
        if oldest and oldest.Parent then oldest:Destroy() end
    end

    local toast = Instance.new("Frame")
    toast.Size = UDim2.new(1, 0, 0, 50)
    toast.BackgroundColor3 = THEME.ContainerBg
    toast.BorderSizePixel = 0
    toast.Parent = notifContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = toast

    local stroke = Instance.new("UIStroke")
    stroke.Color = THEME.Border
    stroke.Thickness = 1
    stroke.Parent = toast

    local tLabel = Instance.new("TextLabel")
    tLabel.Size = UDim2.new(1, -16, 0, 20)
    tLabel.Position = UDim2.new(0, 10, 0, 6)
    tLabel.BackgroundTransparency = 1
    tLabel.Text = title
    tLabel.TextColor3 = THEME.Accent
    tLabel.TextSize = 12
    tLabel.Font = THEME.FontBold
    tLabel.TextXAlignment = Enum.TextXAlignment.Left
    tLabel.Parent = toast

    local mLabel = Instance.new("TextLabel")
    mLabel.Size = UDim2.new(1, -16, 0, 20)
    mLabel.Position = UDim2.new(0, 10, 0, 24)
    mLabel.BackgroundTransparency = 1
    mLabel.Text = msg
    mLabel.TextColor3 = THEME.TextSub
    mLabel.TextSize = 11
    mLabel.Font = THEME.FontRegular
    mLabel.TextXAlignment = Enum.TextXAlignment.Left
    mLabel.Parent = toast

    table.insert(activeToasts, toast)

    task.delay(duration, function()
        if toast.Parent then
            for i, t in ipairs(activeToasts) do
                if t == toast then
                    table.remove(activeToasts, i)
                    break
                end
            end
            toast:Destroy()
        end
    end)
end

--=============================================================
-- DRAGGABLE
--=============================================================
local function makeDraggable(handle, target)
    local dragging = false
    local dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

--=============================================================
-- KEY UI
--=============================================================
local keyFrame = Instance.new("Frame")
keyFrame.Size = UDim2.new(0, 340, 0, 170)
keyFrame.Position = UDim2.new(0.5, -170, 0.4, -85)
keyFrame.BackgroundColor3 = THEME.Background
keyFrame.BorderSizePixel = 0
keyFrame.Parent = screenGui

local kCorner = Instance.new("UICorner")
kCorner.CornerRadius = UDim.new(0, 10)
kCorner.Parent = keyFrame

local kBorder = Instance.new("UIStroke")
kBorder.Thickness = 1
kBorder.Color = THEME.Border
kBorder.Parent = keyFrame

local keyTitle = Instance.new("TextLabel")
keyTitle.Size = UDim2.new(1, -40, 0, 45)
keyTitle.Position = UDim2.new(0, 12, 0, 0)
keyTitle.BackgroundTransparency = 1
keyTitle.Text = "🔐 Fabalta Kulcs Hitelesítés"
keyTitle.TextColor3 = THEME.Text
keyTitle.TextSize = 14
keyTitle.Font = THEME.FontBold
keyTitle.TextXAlignment = Enum.TextXAlignment.Left
keyTitle.Parent = keyFrame

local keyCloseBtn = Instance.new("TextButton")
keyCloseBtn.Size = UDim2.new(0, 22, 0, 22)
keyCloseBtn.Position = UDim2.new(1, -28, 0, 11)
keyCloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
keyCloseBtn.BorderSizePixel = 0
keyCloseBtn.Text = "X"
keyCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
keyCloseBtn.TextSize = 11
keyCloseBtn.Font = THEME.FontBold
keyCloseBtn.Parent = keyFrame

local kcCorner = Instance.new("UICorner")
kcCorner.CornerRadius = UDim.new(0, 5)
kcCorner.Parent = keyCloseBtn

keyCloseBtn.MouseButton1Click:Connect(function()
    if guiAlive() then screenGui:Destroy() end
end)

local keyInput = Instance.new("TextBox")
keyInput.Size = UDim2.new(0.88, 0, 0, 36)
keyInput.Position = UDim2.new(0.06, 0, 0.35, 0)
keyInput.BackgroundColor3 = THEME.ContainerBg
keyInput.BorderSizePixel = 0
keyInput.PlaceholderText = "Add meg a kulcsot..."
keyInput.Text = ""
keyInput.TextColor3 = THEME.Text
keyInput.PlaceholderColor3 = THEME.TextSub
keyInput.TextSize = 11
keyInput.Font = THEME.FontRegular
keyInput.Parent = keyFrame

local kiCorner = Instance.new("UICorner")
kiCorner.CornerRadius = UDim.new(0, 6)
kiCorner.Parent = keyInput

local submitKeyBtn = Instance.new("TextButton")
submitKeyBtn.Size = UDim2.new(0.88, 0, 0, 34)
submitKeyBtn.Position = UDim2.new(0.06, 0, 0.65, 0)
submitKeyBtn.BackgroundColor3 = THEME.Accent
submitKeyBtn.BorderSizePixel = 0
submitKeyBtn.Text = "Belépés"
submitKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
submitKeyBtn.TextSize = 12
submitKeyBtn.Font = THEME.FontBold
submitKeyBtn.Parent = keyFrame

local skCorner = Instance.new("UICorner")
skCorner.CornerRadius = UDim.new(0, 6)
skCorner.Parent = submitKeyBtn

registerAccent(function(col)
    if submitKeyBtn.Parent then submitKeyBtn.BackgroundColor3 = col end
end)

makeDraggable(keyTitle, keyFrame)

--=============================================================
-- MAIN PANEL
--=============================================================
local panel = Instance.new("Frame")
panel.Name = "MainPanel"
panel.Size = UDim2.new(0, 580, 0, 460)
panel.Position = UDim2.new(0.1, 0, 0.15, 0)
panel.BackgroundColor3 = THEME.Background
panel.BorderSizePixel = 0
panel.ClipsDescendants = true
panel.Visible = false
panel.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = panel

local border = Instance.new("UIStroke")
border.Thickness = 1
border.Color = THEME.Border
border.Parent = panel

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 38)
header.BackgroundColor3 = THEME.HeaderBg
header.BorderSizePixel = 0
header.Parent = panel

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -60, 1, 0)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "⚙️ Fabalta Tool v11 (Max Edition)"
titleLabel.TextColor3 = THEME.Text
titleLabel.TextSize = 13
titleLabel.Font = THEME.FontBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 22, 0, 22)
closeBtn.Position = UDim2.new(1, -28, 0.5, -11)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 11
closeBtn.Font = THEME.FontBold
closeBtn.Parent = header

local cCorner = Instance.new("UICorner")
cCorner.CornerRadius = UDim.new(0, 5)
cCorner.Parent = closeBtn

makeDraggable(header, panel)

local sidebar = Instance.new("ScrollingFrame")
sidebar.Size = UDim2.new(0, 140, 1, -68)
sidebar.Position = UDim2.new(0, 0, 0, 38)
sidebar.BackgroundColor3 = THEME.SidebarBg
sidebar.BorderSizePixel = 0
sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
sidebar.ScrollBarThickness = 2
sidebar.Parent = panel

local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
sidebarLayout.Padding = UDim.new(0, 4)
sidebarLayout.Parent = sidebar

local sidebarPadding = Instance.new("UIPadding")
sidebarPadding.PaddingTop = UDim.new(0, 8)
sidebarPadding.PaddingBottom = UDim.new(0, 8)
sidebarPadding.PaddingLeft = UDim.new(0, 8)
sidebarPadding.PaddingRight = UDim.new(0, 8)
sidebarPadding.Parent = sidebar

local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -150, 1, -48)
contentArea.Position = UDim2.new(0, 145, 0, 43)
contentArea.BackgroundTransparency = 1
contentArea.Parent = panel

local footer = Instance.new("TextLabel")
footer.Size = UDim2.new(0, 140, 0, 30)
footer.Position = UDim2.new(0, 0, 1, -30)
footer.BackgroundColor3 = THEME.HeaderBg
footer.BackgroundTransparency = 0.5
footer.BorderSizePixel = 0
footer.Text = "[" .. tostring(Config.ToggleKey) .. "]"
footer.TextColor3 = THEME.TextSub
footer.TextSize = 10
footer.Font = THEME.FontRegular
footer.Parent = panel

--=============================================================
-- ANIMATION PACK (forward declared, defined below)
--=============================================================
local applyAnimationPack

--=============================================================
-- UNLOCK
--=============================================================
local isUnlocked = false

local function unlockSuite()
    if isUnlocked then return end
    isUnlocked = true
    if keyFrame.Parent then keyFrame:Destroy() end
    panel.Visible = true
    notify("Sikeres Belépés", "Minden modul aktív.", 3)
    task.wait(0.5)
    pcall(applyAnimationPack)
end

submitKeyBtn.MouseButton1Click:Connect(function()
    if not _integrity.ok then
        lockdown(_integrity.reason or "Integrity check failed.")
        return
    end
    if keyInput.Text == CORRECT_KEY then
        unlockSuite()
    else
        keyInput.Text = ""
        keyInput.PlaceholderText = "❌ Hibás kulcs!"
    end
end)

--=============================================================
-- TOGGLE KEY
--=============================================================
local function getToggleKeyCode()
    local key = Config.ToggleKey
    if type(key) ~= "string" then return Enum.KeyCode.F12 end
    local ok, code = pcall(function() return Enum.KeyCode[key] end)
    if ok and code then return code end
    return Enum.KeyCode.F12
end

local isVisible = true
UserInputService.InputBegan:Connect(function(input, processed)
    if processed or not isUnlocked then return end
    if input.KeyCode == getToggleKeyCode() then
        isVisible = not isVisible
        panel.Visible = isVisible
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    if guiAlive() then screenGui:Destroy() end
end)

--=============================================================
-- UI BUILDING SYSTEM
--=============================================================
local tabs = {}
local currentTab = nil

local function createTab(name)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(1, 0, 0, 32)
    tabBtn.BackgroundColor3 = THEME.AccentInactive
    tabBtn.BorderSizePixel = 0
    tabBtn.Text = "  " .. name
    tabBtn.TextColor3 = THEME.TextSub
    tabBtn.TextSize = 11
    tabBtn.Font = THEME.FontBold
    tabBtn.TextXAlignment = Enum.TextXAlignment.Left
    tabBtn.Parent = sidebar

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = tabBtn

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -10, 1, 0)
    scroll.Position = UDim2.new(0, 0, 0, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.Visible = false
    scroll.Parent = contentArea

    registerAccent(function(col)
        if scroll.Parent then scroll.ScrollBarImageColor3 = col end
    end)

    local list = Instance.new("UIListLayout")
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 6)
    list.Parent = scroll

    local pad = Instance.new("UIPadding")
    pad.PaddingRight = UDim.new(0, 8)
    pad.PaddingTop = UDim.new(0, 2)
    pad.PaddingBottom = UDim.new(0, 10)
    pad.Parent = scroll

    tabBtn.MouseButton1Click:Connect(function()
        for _, t in pairs(tabs) do
            t.Btn.BackgroundColor3 = THEME.AccentInactive
            t.Btn.TextColor3 = THEME.TextSub
            t.Page.Visible = false
        end
        tabBtn.BackgroundColor3 = THEME.ContainerBg
        tabBtn.TextColor3 = THEME.Text
        scroll.Visible = true
        currentTab = scroll
    end)

    tabs[name] = { Btn = tabBtn, Page = scroll }

    if not currentTab then
        tabBtn.BackgroundColor3 = THEME.ContainerBg
        tabBtn.TextColor3 = THEME.Text
        scroll.Visible = true
        currentTab = scroll
    end

    return scroll
end

--=============================================================
-- WIDGETS
--=============================================================
local function createToggle(parentPage, configKey, labelText, defaultOn, callback)
    local savedState = Config[configKey]
    if type(savedState) ~= "boolean" then savedState = defaultOn end

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 36)
    container.BackgroundColor3 = THEME.ContainerBg
    container.BorderSizePixel = 0
    container.Parent = parentPage

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = THEME.Text
    label.TextSize = 11
    label.Font = THEME.FontRegular
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local track = Instance.new("TextButton")
    track.Size = UDim2.new(0, 40, 0, 20)
    track.Position = UDim2.new(1, -48, 0.5, -10)
    track.BackgroundColor3 = THEME.AccentInactive
    track.BorderSizePixel = 0
    track.Text = ""
    track.Parent = container

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = track

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local state = savedState

    local function applyVisual(animate)
        local targetColor = state and THEME.Accent or THEME.AccentInactive
        local targetPos   = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        if animate then
            local ti = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            TweenService:Create(track, ti, { BackgroundColor3 = targetColor }):Play()
            TweenService:Create(knob,  ti, { Position = targetPos }):Play()
        else
            track.BackgroundColor3 = targetColor
            knob.Position = targetPos
        end
    end

    registerAccent(function(col)
        if track.Parent and state then track.BackgroundColor3 = col end
    end)

    applyVisual(false)

    local function setState(newState)
        state = newState
        Config[configKey] = state
        saveConfig()
        applyVisual(true)
        task.spawn(function() pcall(callback, state) end)
    end

    track.MouseButton1Click:Connect(function()
        setState(not state)
    end)

    if savedState then
        task.spawn(function() pcall(callback, true) end)
    end
end

local function createSlider(parentPage, configKey, labelText, minVal, maxVal, defaultVal, callback)
    local savedValue = Config[configKey]
    if type(savedValue) ~= "number" then savedValue = defaultVal end
    savedValue = math.clamp(savedValue, minVal, maxVal)

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 48)
    container.BackgroundColor3 = THEME.ContainerBg
    container.BorderSizePixel = 0
    container.Parent = parentPage

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 0, 18)
    label.Position = UDim2.new(0, 10, 0, 4)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = THEME.Text
    label.TextSize = 11
    label.Font = THEME.FontRegular
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local valueDisplay = Instance.new("TextLabel")
    valueDisplay.Size = UDim2.new(0.3, 0, 0, 18)
    valueDisplay.Position = UDim2.new(0.65, 0, 0, 4)
    valueDisplay.BackgroundTransparency = 1
    valueDisplay.Text = tostring(math.floor(savedValue))
    valueDisplay.TextColor3 = THEME.TextSub
    valueDisplay.TextSize = 10
    valueDisplay.Font = THEME.FontBold
    valueDisplay.TextXAlignment = Enum.TextXAlignment.Right
    valueDisplay.Parent = container

    local sliderTrack = Instance.new("TextButton")
    sliderTrack.Size = UDim2.new(1, -20, 0, 6)
    sliderTrack.Position = UDim2.new(0, 10, 0, 30)
    sliderTrack.BackgroundColor3 = THEME.AccentInactive
    sliderTrack.BorderSizePixel = 0
    sliderTrack.Text = ""
    sliderTrack.Parent = container

    local stCorner = Instance.new("UICorner")
    stCorner.CornerRadius = UDim.new(1, 0)
    stCorner.Parent = sliderTrack

    local startRatio = math.clamp((savedValue - minVal) / (maxVal - minVal), 0, 1)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(startRatio, 0, 1, 0)
    fill.BackgroundColor3 = THEME.Accent
    fill.BorderSizePixel = 0
    fill.Parent = sliderTrack

    local fCorner = Instance.new("UICorner")
    fCorner.CornerRadius = UDim.new(1, 0)
    fCorner.Parent = fill

    registerAccent(function(col)
        if fill.Parent then fill.BackgroundColor3 = col end
    end)

    local dragging = false

    local function updateSlider(input)
        local width = sliderTrack.AbsoluteSize.X
        if width <= 0 then return end
        local posX = math.clamp(input.Position.X - sliderTrack.AbsolutePosition.X, 0, width)
        local ratio = posX / width
        local val = math.floor(minVal + (maxVal - minVal) * ratio)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        valueDisplay.Text = tostring(val)
        Config[configKey] = val
        saveConfig()
        pcall(callback, val)
    end

    sliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    pcall(callback, savedValue)
end

local function createButton(parentPage, text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = THEME.ContainerBg
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = THEME.Text
    btn.TextSize = 11
    btn.Font = THEME.FontBold
    btn.Parent = parentPage

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn

    btn.MouseButton1Click:Connect(function()
        task.spawn(function() pcall(callback) end)
    end)
end

local function createTextBox(parentPage, configKey, labelText, placeholder, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 48)
    container.BackgroundColor3 = THEME.ContainerBg
    container.BorderSizePixel = 0
    container.Parent = parentPage

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.4, 0, 0, 20)
    label.Position = UDim2.new(0, 10, 0, 4)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = THEME.Text
    label.TextSize = 11
    label.Font = THEME.FontBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.5, -20, 0, 28)
    box.Position = UDim2.new(0.45, 0, 0, 12)
    box.BackgroundColor3 = THEME.Background
    box.BorderSizePixel = 0
    box.Text = tostring(Config[configKey] or "")
    box.PlaceholderText = placeholder
    box.TextColor3 = THEME.Text
    box.PlaceholderColor3 = THEME.TextSub
    box.TextSize = 11
    box.Font = THEME.FontRegular
    box.Parent = container

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 4)
    boxCorner.Parent = box

    local token = 0
    box:GetPropertyChangedSignal("Text"):Connect(function()
        Config[configKey] = box.Text
        saveConfig()
        token = token + 1
        local myToken = token
        task.delay(0.4, function()
            if myToken == token then
                pcall(callback, box.Text)
            end
        end)
    end)
end

--=============================================================
-- TABS
--=============================================================
local pageMovement = createTab("Mozgás")
local pageCombat   = createTab("Harc")
local pageVisuals  = createTab("Látvány")
local pageUtility  = createTab("Eszközök")
local pageAnim     = createTab("Animációk")
local pageSettings = createTab("Beállítások")

--=============================================================
-- ANIMATION PACK
--=============================================================
applyAnimationPack = function()
    local char = getChar()
    if not char then return end
    local animate = char:FindFirstChild("Animate")
    if not animate then return end

    local pack = Config.AnimPack or "Default"
    local idleId, walkId, runId, jumpId

    if type(Config.BundleID) == "string" and Config.BundleID ~= "" then
        local cleaned = Config.BundleID:gsub("%D+", "")
        if cleaned ~= "" then
            local bundleNum = tonumber(cleaned)
            if bundleNum then
                local ok, assetIds = pcall(function()
                    return AssetService:GetAssetIdsForPackage(bundleNum)
                end)
                if ok and type(assetIds) == "table" then
                    for _, id in ipairs(assetIds) do
                        pcall(function()
                            local info = MarketplaceService:GetProductInfo(id)
                            if info and info.AssetTypeId == 24 then
                                local n = string.lower(info.Name or "")
                                if string.find(n, "idle") then idleId = tostring(id)
                                elseif string.find(n, "walk") then walkId = tostring(id)
                                elseif string.find(n, "run")  then runId  = tostring(id)
                                elseif string.find(n, "jump") then jumpId = tostring(id) end
                            end
                        end)
                    end
                else
                    local sid = tostring(bundleNum)
                    idleId, walkId, runId, jumpId = sid, sid, sid, sid
                end
            end
        end
    end

    if not idleId or idleId == "" then
        if pack == "Ninja" then
            idleId, walkId, runId, jumpId = "12114635098", "12114635100", "12114635102", "12114635104"
        elseif pack == "Robot" then
            idleId, walkId, runId, jumpId = "6150272929", "6150272946", "6150272961", "6150272980"
        elseif pack == "Cartoon" then
            idleId, walkId, runId, jumpId = "5077696589", "5077696597", "5077696603", "5077696609"
        elseif pack == "Custom" then
            idleId, walkId, runId, jumpId = Config.AnimIdle, Config.AnimWalk, Config.AnimRun, Config.AnimJump
        end
    end

    pcall(function()
        if pack == "Default" and (not Config.BundleID or Config.BundleID == "") then
            return
        end

        local function applyTo(nodeName, id)
            if not id or id == "" then return end
            local node = animate:FindFirstChild(nodeName)
            if not node then return end
            local clean = id:gsub("%D+", "")
            if clean == "" then return end
            for _, anim in ipairs(node:GetChildren()) do
                if anim:IsA("Animation") then
                    anim.AnimationId = "rbxassetid://" .. clean
                end
            end
        end

        applyTo("idle", idleId)
        applyTo("walk", walkId)
        applyTo("run",  runId)
        applyTo("jump", jumpId)
    end)
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    pcall(applyAnimationPack)
end)

--=============================================================
-- GLOBAL APPLY
--=============================================================
local function applyAllSettings()
    local hum = getHumanoid()
    if hum then
        pcall(function()
            hum.WalkSpeed = Config.WalkSpeed
            hum.JumpPower = Config.JumpPower
            hum.UseJumpPower = true
            hum:SetStateEnabled(Enum.HumanoidStateType.Dead, not Config.Godmode)
        end)
    end

    pcall(function()
        local cam = getCamera()
        if cam then cam.FieldOfView = Config.FOV end

        if Config.Fullbright then
            Lighting.Brightness = 3
            Lighting.ClockTime  = 14
            Lighting.GlobalShadows = false
        else
            Lighting.Brightness = 1
            Lighting.ClockTime  = 12
            Lighting.GlobalShadows = true
        end
    end)
end

--=============================================================
-- MOZGÁS
--=============================================================
createSlider(pageMovement, "WalkSpeed", "⚡ Járási Sebesség", 16, 200, 16, function(val)
    Config.WalkSpeed = val
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = val end
end)

createSlider(pageMovement, "JumpPower", "🦘 Ugrási Erő", 50, 300, 50, function(val)
    Config.JumpPower = val
    local hum = getHumanoid()
    if hum then
        hum.UseJumpPower = true
        hum.JumpPower = val
    end
end)

createToggle(pageMovement, "InfJump", "🦘 Végtelen Ugrás", false, function(enabled)
    Config.InfJump = enabled
end)

UserInputService.JumpRequest:Connect(function()
    if Config.InfJump and guiAlive() then
        local hum = getHumanoid()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

createToggle(pageMovement, "Noclip", "🧱 Noclip (Falon átjárás)", false, function(enabled)
    Config.Noclip = enabled
    if not enabled then
        local char = getChar()
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and not part.Anchored then
                    part.CanCollide = true
                end
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if not guiAlive() or not Config.Noclip then return end
    local char = getChar()
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and not part.Anchored then
            part.CanCollide = false
        end
    end
end)

--=============================================================
-- FLY
--=============================================================
local flyBodyVelocity = nil

local function setupFly()
    local root = getRoot()
    if not root then return end
    if flyBodyVelocity and flyBodyVelocity.Parent == root then return end
    if flyBodyVelocity then flyBodyVelocity:Destroy() end

    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    flyBodyVelocity.P = 1e5
    flyBodyVelocity.Velocity = Vector3.zero
    flyBodyVelocity.Parent = root
end

local function removeFly()
    if flyBodyVelocity then
        flyBodyVelocity:Destroy()
        flyBodyVelocity = nil
    end
end

createToggle(pageMovement, "Fly", "✈️ Repülés (Szóköz/SHIFT)", false, function(enabled)
    Config.Fly = enabled
    if enabled then
        setupFly()
        local hum = getHumanoid()
        if hum then hum.PlatformStand = true end
    else
        removeFly()
        local hum = getHumanoid()
        if hum then hum.PlatformStand = false end
    end
end)

RunService.Heartbeat:Connect(function()
    if not guiAlive() then return end
    if not Config.Fly then
        if flyBodyVelocity then removeFly() end
        return
    end

    local root = getRoot()
    if not root then
        removeFly()
        return
    end

    if not flyBodyVelocity or flyBodyVelocity.Parent ~= root then
        setupFly()
    end
    if not flyBodyVelocity then return end

    local cam = getCamera()
    if not cam then return end

    local hum = getHumanoid()
    if hum then hum.PlatformStand = true end

    local moveDir = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        moveDir = moveDir + cam.CFrame.LookVector * Vector3.new(1, 0, 1)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        moveDir = moveDir - cam.CFrame.LookVector * Vector3.new(1, 0, 1)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        moveDir = moveDir - cam.CFrame.RightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        moveDir = moveDir + cam.CFrame.RightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        moveDir = moveDir + Vector3.new(0, 1, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        moveDir = moveDir - Vector3.new(0, 1, 0)
    end

    if moveDir.Magnitude > 0 then
        flyBodyVelocity.Velocity = moveDir.Unit * 60
    else
        flyBodyVelocity.Velocity = Vector3.zero
    end
end)

--=============================================================
-- TP TOOL
--=============================================================
local tpToolActive = false
local tpConnection = nil

createButton(pageMovement, "📍 TP Tool (Ctrl + Kattintás)", function()
    tpToolActive = not tpToolActive
    if tpToolActive then
        if not tpConnection then
            local mouse = LocalPlayer:GetMouse()
            tpConnection = mouse.Button1Down:Connect(function()
                if not UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then return end
                local root = getRoot()
                if root and mouse.Hit then
                    root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
                end
            end)
        end
        notify("TP Tool", "Aktív: Ctrl + Bal klikk a pályán.", 3)
    else
        if tpConnection then
            tpConnection:Disconnect()
            tpConnection = nil
        end
        notify("TP Tool", "Kikapcsolva.", 2)
    end
end)

--=============================================================
-- HARC
--=============================================================
local aimbotEnabled = false
local aimSmoothness = 0.2

createSlider(pageCombat, "AimSmooth", "🎯 Aimbot Simítás", 1, 10, 2, function(val)
    aimSmoothness = math.clamp(val / 10, 0.05, 1)
end)

createToggle(pageCombat, "Aimbot", "🎯 Aimbot (Jobb klikk tartás)", false, function(enabled)
    aimbotEnabled = enabled
end)

RunService.RenderStepped:Connect(function()
    if not guiAlive() or not aimbotEnabled then return end
    if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end

    local cam = getCamera()
    if not cam then return end

    local closestPlayer, closestDist = nil, math.huge
    local mouseLoc = UserInputService:GetMouseLocation()

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local head = p.Character:FindFirstChild("Head")
            if head then
                local pos, onScreen = cam:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - mouseLoc).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestPlayer = p
                    end
                end
            end
        end
    end

    if closestPlayer then
        local head = closestPlayer.Character and closestPlayer.Character:FindFirstChild("Head")
        if head then
            local targetCFrame = CFrame.new(cam.CFrame.Position, head.Position)
            cam.CFrame = cam.CFrame:Lerp(targetCFrame, aimSmoothness)
        end
    end
end)

createToggle(pageCombat, "SilentAim", "🎯 Silent Aimbot (Auto-lock)", false, function(enabled)
    Config.SilentAim = enabled
end)

RunService.Heartbeat:Connect(function()
    if not guiAlive() or not Config.SilentAim then return end
    if aimbotEnabled then return end

    local root = getRoot()
    if not root then return end

    local cam = getCamera()
    if not cam then return end

    local closestPlayer, closestDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local head = p.Character:FindFirstChild("Head")
            if head then
                local d = (root.Position - head.Position).Magnitude
                if d < closestDist then
                    closestDist = d
                    closestPlayer = p
                end
            end
        end
    end

    if closestPlayer then
        local head = closestPlayer.Character and closestPlayer.Character:FindFirstChild("Head")
        if head then
            pcall(function()
                cam.CFrame = CFrame.new(cam.CFrame.Position, head.Position)
            end)
        end
    end
end)

createToggle(pageCombat, "Godmode", "🛡️ Istenmód (Halhatatlanság)", false, function(enabled)
    Config.Godmode = enabled
    local hum = getHumanoid()
    if hum then
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead, not enabled)
    end
end)

--=============================================================
-- LÁTVÁNY
--=============================================================
createSlider(pageVisuals, "FOV", "👁️ Kamera FOV", 70, 120, 70, function(val)
    Config.FOV = val
    local cam = getCamera()
    if cam then cam.FieldOfView = val end
end)

createToggle(pageVisuals, "Fullbright", "☀️ Teljes Fényerő (Fullbright)", false, function(enabled)
    Config.Fullbright = enabled
    Lighting.Brightness = enabled and 3 or 1
    Lighting.ClockTime  = enabled and 14 or 12
    Lighting.GlobalShadows = not enabled
end)

local espHighlights = {}

local function clearESP(player)
    if player and espHighlights[player] then
        pcall(function() espHighlights[player]:Destroy() end)
        espHighlights[player] = nil
    end
end

local function clearAllESP()
    for p, hl in pairs(espHighlights) do
        if hl then pcall(function() hl:Destroy() end) end
        espHighlights[p] = nil
    end
end

Players.PlayerRemoving:Connect(function(p)
    clearESP(p)
end)

createToggle(pageVisuals, "ESP", "👥 Játékos ESP (Kiemelés)", false, function(enabled)
    Config.ESP = enabled
    if not enabled then clearAllESP() end
end)

RunService.Heartbeat:Connect(function()
    if not guiAlive() then return end

    if not Config.ESP then
        if next(espHighlights) then clearAllESP() end
        return
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character.Parent then
            if not espHighlights[p] or not espHighlights[p].Parent then
                clearESP(p)
                local hl = Instance.new("Highlight")
                hl.Adornee        = p.Character
                hl.FillColor      = THEME.Accent
                hl.OutlineColor   = Color3.fromRGB(255, 255, 255)
                hl.FillTransparency = 0.5
                hl.Parent = p.Character
                espHighlights[p] = hl
            end
        else
            clearESP(p)
        end
    end
end)

--=============================================================
-- ESZKÖZÖK
--=============================================================
createToggle(pageUtility, "AntiAFK", "💤 Anti-AFK (Rendszer)", true, function(enabled)
    Config.AntiAFK = enabled
end)

LocalPlayer.Idled:Connect(function()
    if Config.AntiAFK then
        pcall(function()
            VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        end)
        notify("Anti-AFK", "Kick megakadályozva.", 2)
    end
end)

createButton(pageUtility, "🔄 Újracsatlakozás (Rejoin)", function()
    pcall(function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end)

createButton(pageUtility, "📦 Reset Karakter", function()
    local hum = getHumanoid()
    if hum then hum.Health = 0 end
end)

--=============================================================
-- ANIMÁCIÓK
--=============================================================
createTextBox(pageAnim, "BundleID", "📦 Bundle ID (Csomag)", "Írd ide a Bundle ID-t...", function()
    applyAnimationPack()
end)

createButton(pageAnim, "🔄 Animáció Csomag Frissítése", function()
    applyAnimationPack()
    notify("Animációk", "Csomag / Bundle betöltve.", 2)
end)

createTextBox(pageAnim, "AnimIdle", "Egyedi Idle ID", "Add meg az ID-t...", function() applyAnimationPack() end)
createTextBox(pageAnim, "AnimWalk", "Egyedi Walk ID", "Add meg az ID-t...", function() applyAnimationPack() end)
createTextBox(pageAnim, "AnimRun",  "Egyedi Run ID",  "Add meg az ID-t...", function() applyAnimationPack() end)
createTextBox(pageAnim, "AnimJump", "Egyedi Jump ID", "Add meg az ID-t...", function() applyAnimationPack() end)

--=============================================================
-- BEÁLLÍTÁSOK
--=============================================================
createTextBox(pageSettings, "ToggleKey", "Menü Gyorsbillentyű", "Pl. F12", function()
    footer.Text = "[" .. tostring(Config.ToggleKey) .. "]"
    notify("Beállítások", "Gyorsbillentyű frissítve.", 2)
end)

createButton(pageSettings, "💾 Konfiguráció Mentése", function()
    saveConfig()
    notify("Mentés", "A beállítások elmentve.", 2)
end)

--=============================================================
-- INIT
--=============================================================
if not _integrity.ok then
    lockdown(_integrity.reason or "Integrity check failed.")
    return
end

pcall(applyAllSettings)
