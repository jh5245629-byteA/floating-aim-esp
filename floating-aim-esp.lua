-- Floating menu + head aim + colored ESP
-- FOV = 50 pixels from the center of the screen

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local FOV = 50

-- Remove the previous copy.
local previous = playerGui:FindFirstChild("FloatingAimESP")
if previous then
    previous:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "FloatingAimESP"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local connections = {}
local highlights = {}
local aimEnabled = false
local espEnabled = false
local hitboxEnabled = false
local originalHitboxes = {}
local hitboxBoxes = {}

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end

local function round(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = object
end

-- Draggable square
local square = Instance.new("TextButton")
square.Name = "Square"
square.Size = UDim2.fromOffset(54, 54)
square.Position = UDim2.fromOffset(30, 170)
square.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
square.Text = "+"
square.TextColor3 = Color3.new(1, 1, 1)
square.TextSize = 30
square.Font = Enum.Font.GothamBold
square.Parent = gui
round(square, 9)

-- Menu
local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(200, 210)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
panel.Visible = false
panel.Parent = gui
round(panel, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -45, 0, 36)
title.Position = UDim2.fromOffset(10, 5)
title.BackgroundTransparency = 1
title.Text = "AIM + ESP"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 17
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(30, 30)
close.Position = UDim2.new(1, -35, 0, 5)
close.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
close.Text = "X"
close.TextColor3 = Color3.new(1, 1, 1)
close.TextSize = 16
close.Font = Enum.Font.GothamBold
close.Parent = panel
round(close, 6)

local function positionPanel()
    local camera = workspace.CurrentCamera
    if not camera then return end

    local viewport = camera.ViewportSize
    local pos = square.AbsolutePosition
    local x = pos.X + square.AbsoluteSize.X + 8
    local y = pos.Y

    if x + panel.AbsoluteSize.X > viewport.X then
        x = pos.X - panel.AbsoluteSize.X - 8
    end

    x = math.clamp(x, 0, math.max(0, viewport.X - panel.AbsoluteSize.X))
    y = math.clamp(y, 0, math.max(0, viewport.Y - panel.AbsoluteSize.Y))
    panel.Position = UDim2.fromOffset(x, y)
end

local function makeToggle(label, y, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 42)
    button.Position = UDim2.fromOffset(10, y)
    button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 15
    button.Font = Enum.Font.GothamBold
    button.Text = label .. ": OFF"
    button.Parent = panel
    round(button, 7)

    connect(button.MouseButton1Click, function()
        local enabled = callback()
        button.Text = label .. (enabled and ": ON" or ": OFF")
        button.BackgroundColor3 = enabled
            and Color3.fromRGB(35, 140, 75)
            or Color3.fromRGB(60, 60, 60)
    end)
end

local function clearESP()
    for other, highlight in pairs(highlights) do
        highlight:Destroy()
        highlights[other] = nil
    end
end

makeToggle("Head aim", 45, function()
    aimEnabled = not aimEnabled
    return aimEnabled
end)

makeToggle("Color ESP", 95, function()
    espEnabled = not espEnabled
    if not espEnabled then
        clearESP()
    end
    return espEnabled
end)

-- Client-side size change only: server-side hit validation may reject side shots.
local function restoreHitboxes()
    for part, box in pairs(hitboxBoxes) do
        box:Destroy()
        hitboxBoxes[part] = nil
    end
    for part, original in pairs(originalHitboxes) do
        if part.Parent then
            pcall(function()
                part.Size = original.Size
                part.CanCollide = original.CanCollide
            end)
        end
        originalHitboxes[part] = nil
    end
end

makeToggle("Hitbox 50", 145, function()
    hitboxEnabled = not hitboxEnabled
    if not hitboxEnabled then restoreHitboxes() end
    return hitboxEnabled
end)

task.spawn(function()
    while gui.Parent do
        if hitboxEnabled then
            for _, other in ipairs(Players:GetPlayers()) do
                if other ~= localPlayer then
                    local character = other.Character
                    local root = character and character:FindFirstChild("HumanoidRootPart")
                    if root and root:IsA("BasePart") then
                        pcall(function()
                            if not originalHitboxes[root] then
                                originalHitboxes[root] = {
                                    Size = root.Size, CanCollide = root.CanCollide
                                }
                            end
                            root.Size = Vector3.new(50, 50, 50)
                            root.CanCollide = false
                            if not hitboxBoxes[root] then
                                local box = Instance.new("BoxHandleAdornment")
                                box.Name = "Hitbox50Visual"
                                box.Adornee = root
                                box.Size = Vector3.new(50, 50, 50)
                                box.Color3 = Color3.fromHSV((other.UserId % 100) / 100, 1, 1)
                                box.Transparency = 0.8
                                box.AlwaysOnTop = true
                                box.ZIndex = 1
                                box.Parent = gui
                                hitboxBoxes[root] = box
                            end
                        end)
                    end
                end
            end
            for part in pairs(originalHitboxes) do
                if not part.Parent then
                    originalHitboxes[part] = nil
                    if hitboxBoxes[part] then
                        hitboxBoxes[part]:Destroy()
                        hitboxBoxes[part] = nil
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)

connect(close.MouseButton1Click, function()
    panel.Visible = false
end)

-- Drag with touch or mouse. Tap without dragging to open/close.
local dragInput
local startPointer
local startPosition
local moved = false

connect(square.InputBegan, function(input)
    local kind = input.UserInputType

    if kind ~= Enum.UserInputType.Touch
        and kind ~= Enum.UserInputType.MouseButton1 then
        return
    end

    dragInput = input
    startPointer = input.Position
    startPosition = square.AbsolutePosition
    moved = false
end)

connect(UserInputService.InputChanged, function(input)
    if not dragInput then return end

    local isTouch = dragInput.UserInputType == Enum.UserInputType.Touch

    if isTouch and input ~= dragInput then return end
    if not isTouch
        and input.UserInputType ~= Enum.UserInputType.MouseMovement then
        return
    end

    local delta = input.Position - startPointer
    if delta.Magnitude > 5 then
        moved = true
    end

    if moved then
        local camera = workspace.CurrentCamera
        if not camera then return end

        local viewport = camera.ViewportSize
        local x = startPosition.X + delta.X
        local y = startPosition.Y + delta.Y

        square.Position = UDim2.fromOffset(
            math.clamp(x, 0, math.max(0, viewport.X - 54)),
            math.clamp(y, 0, math.max(0, viewport.Y - 54))
        )

        positionPanel()
    end
end)

connect(UserInputService.InputEnded, function(input)
    if input ~= dragInput then return end

    dragInput = nil

    if not moved then
        panel.Visible = not panel.Visible
        if panel.Visible then
            positionPanel()
        end
    end
end)

-- FOV circle
local circle = Instance.new("Frame")
circle.Name = "FOV"
circle.AnchorPoint = Vector2.new(0.5, 0.5)
circle.Position = UDim2.fromScale(0.5, 0.5)
circle.Size = UDim2.fromOffset(FOV * 2, FOV * 2)
circle.BackgroundTransparency = 1
circle.Visible = false
circle.Parent = gui
round(circle, FOV)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.new(1, 1, 1)
stroke.Thickness = 1.5
stroke.Parent = circle

-- Closest living player's head within the FOV.
local function findTarget(camera)
    local center = camera.ViewportSize / 2
    local closest = nil
    local closestDistance = FOV

    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= localPlayer then
            local character = other.Character
            local head = character and character:FindFirstChild("Head")
            local humanoid = character
                and character:FindFirstChildOfClass("Humanoid")

            if head and humanoid and humanoid.Health > 0 then
                local point, onScreen =
                    camera:WorldToViewportPoint(head.Position)

                if onScreen and point.Z > 0 then
                    local distance =
                        (Vector2.new(point.X, point.Y) - center).Magnitude

                    if distance < closestDistance then
                        closestDistance = distance
                        closest = head
                    end
                end
            end
        end
    end

    return closest
end

-- Run after Roblox's normal camera update.
local renderName = "FloatingAimESP_Camera"

RunService:BindToRenderStep(
    renderName,
    Enum.RenderPriority.Camera.Value + 1,
    function()
        circle.Visible = aimEnabled
        if not aimEnabled then return end

        local camera = workspace.CurrentCamera
        if not camera then return end

        local head = findTarget(camera)
        if head then
            camera.CFrame = CFrame.lookAt(
                camera.CFrame.Position,
                head.Position
            )
        end
    end
)

-- Colorful ESP, updated when players spawn or leave.
task.spawn(function()
    while gui.Parent do
        if espEnabled then
            local active = {}

            for _, other in ipairs(Players:GetPlayers()) do
                if other ~= localPlayer and other.Character then
                    local character = other.Character
                    active[other] = true

                    local highlight = highlights[other]

                    if not highlight or highlight.Adornee ~= character then
                        if highlight then
                            highlight:Destroy()
                        end

                        highlight = Instance.new("Highlight")
                        highlight.Adornee = character
                        highlight.DepthMode =
                            Enum.HighlightDepthMode.AlwaysOnTop
                        highlight.FillColor = Color3.fromHSV(
                            (other.UserId % 100) / 100,
                            1,
                            1
                        )
                        highlight.OutlineColor = Color3.new(1, 1, 1)
                        highlight.FillTransparency = 0.45
                        highlight.Parent = gui
                        highlights[other] = highlight
                    end
                end
            end

            for other, highlight in pairs(highlights) do
                if not active[other] then
                    highlight:Destroy()
                    highlights[other] = nil
                end
            end
        end

        task.wait(0.5)
    end
end)

gui.Destroying:Connect(function()
    restoreHitboxes()
    RunService:UnbindFromRenderStep(renderName)
    clearESP()

    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
end)
