-- pynyxDlc | The Lost Front
-- For Delta Executor
-- Mobile-friendly

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

getgenv().pynyx = {
    SilentAim = false,
    ESP = false,
    TeamCheck = true,
    FOV = 150,
    TargetPart = "Head",
    Debug = false
}

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "pynyxDlc"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 360)
MainFrame.Position = UDim2.new(0, 30, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 14)
Corner.Parent = MainFrame

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(30, 30, 45)
Stroke.Thickness = 1
Stroke.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 50)
Title.BackgroundTransparency = 1
Title.Text = "pynyxDlc"
Title.TextColor3 = Color3.fromRGB(90, 169, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.Parent = MainFrame

local function CreateToggle(name, yPos, default, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -40, 0, 42)
    Btn.Position = UDim2.new(0, 20, 0, yPos)
    Btn.BackgroundColor3 = default and Color3.fromRGB(30, 100, 200) or Color3.fromRGB(28, 28, 38)
    Btn.Text = name .. ": " .. (default and "ON" or "OFF")
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Font = Enum.Font.GothamMedium
    Btn.TextSize = 14
    Btn.BorderSizePixel = 0
    Btn.Parent = MainFrame

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 10)
    c.Parent = Btn

    Btn.MouseButton1Click:Connect(function()
        local newState = not callback()
        Btn.Text = name .. ": " .. (newState and "ON" or "OFF")
        Btn.BackgroundColor3 = newState and Color3.fromRGB(30, 100, 200) or Color3.fromRGB(28, 28, 38)
    end)

    return Btn
end

CreateToggle("Silent Aim", 60, getgenv().pynyx.SilentAim, function()
    getgenv().pynyx.SilentAim = not getgenv().pynyx.SilentAim
    return getgenv().pynyx.SilentAim
end)

CreateToggle("ESP", 110, getgenv().pynyx.ESP, function()
    getgenv().pynyx.ESP = not getgenv().pynyx.ESP
    return getgenv().pynyx.ESP
end)

CreateToggle("Team Check", 160, getgenv().pynyx.TeamCheck, function()
    getgenv().pynyx.TeamCheck = not getgenv().pynyx.TeamCheck
    return getgenv().pynyx.TeamCheck
end)

CreateToggle("Debug (Console)", 210, getgenv().pynyx.Debug, function()
    getgenv().pynyx.Debug = not getgenv().pynyx.Debug
    return getgenv().pynyx.Debug
end)

local Info = Instance.new("TextLabel")
Info.Size = UDim2.new(1, -40, 0, 30)
Info.Position = UDim2.new(0, 20, 0, 260)
Info.BackgroundTransparency = 1
Info.Text = "Mobile FOV | Head"
Info.TextColor3 = Color3.fromRGB(140, 140, 160)
Info.Font = Enum.Font.Gotham
Info.TextSize = 12
Info.Parent = MainFrame

-- FOV Circle (по центру экрана, для телефона)
local FovCircle = Drawing.new("Circle")
FovCircle.Thickness = 1
FovCircle.NumSides = 60
FovCircle.Radius = getgenv().pynyx.FOV
FovCircle.Filled = false
FovCircle.Color = Color3.fromRGB(90, 169, 255)
FovCircle.Transparency = 0.6
FovCircle.Visible = false

local function GetScreenCenter()
    local vp = Camera.ViewportSize
    return Vector2.new(vp.X / 2, vp.Y / 2)
end

-- ESP
local ESP = {}

local function CreateESP(player)
    if player == LocalPlayer then return end

    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Filled = false
    box.Color = Color3.fromRGB(255, 60, 60)
    box.Transparency = 1
    box.Visible = false

    local name = Drawing.new("Text")
    name.Size = 14
    name.Center = true
    name.Outline = true
    name.Color = Color3.fromRGB(255, 255, 255)
    name.Visible = false

    ESP[player] = { Box = box, Name = name }
end

local function RemoveESP(player)
    if ESP[player] then
        ESP[player].Box:Remove()
        ESP[player].Name:Remove()
        ESP[player] = nil
    end
end

-- Utils
local function IsEnemy(player)
    if player == LocalPlayer then return false end
    if not getgenv().pynyx.TeamCheck then return true end
    if player.Team == nil or LocalPlayer.Team == nil then return true end
    return player.Team ~= LocalPlayer.Team
end

local function GetCharacter(player)
    local char = player.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return nil end
    return char
end

local function GetClosestTarget()
    local closest = nil
    local shortest = getgenv().pynyx.FOV
    local center = GetScreenCenter()

    for _, player in ipairs(Players:GetPlayers()) do
        if not IsEnemy(player) then continue end
        local char = GetCharacter(player)
        if not char then continue end

        local part = char:FindFirstChild(getgenv().pynyx.TargetPart)
        if not part then continue end

        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end

        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        if dist < shortest then
            shortest = dist
            closest = part
        end
    end

    return closest
end

-- Loops
RunService.RenderStepped:Connect(function()
    local cfg = getgenv().pynyx

    -- FOV Circle в центре
    FovCircle.Position = GetScreenCenter()
    FovCircle.Visible = cfg.SilentAim

    -- ESP
    for player, data in pairs(ESP) do
        local isEnemy = IsEnemy(player)
        local char = GetCharacter(player)

        if char and cfg.ESP and isEnemy then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    local top = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3, 0))
                    local bot = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                    local h = math.abs(top.Y - bot.Y)

                    data.Box.Size = Vector2.new(h * 0.6, h)
                    data.Box.Position = Vector2.new(pos.X - h * 0.3, pos.Y - h * 0.5)
                    data.Box.Visible = true

                    data.Name.Text = player.Name
                    data.Name.Position = Vector2.new(pos.X, pos.Y - h * 0.5 - 18)
                    data.Name.Visible = true
                else
                    data.Box.Visible = false
                    data.Name.Visible = false
                end
            end
        else
            data.Box.Visible = false
            data.Name.Visible = false
        end
    end
end)

-- Silent Aim — пробуем хукнуть все FireServer
-- DEBUG: показывает, какие RemoteEvent'ы вызываются при выстреле
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    local cfg = getgenv().pynyx

    -- Debug — лог всех FireServer
    if cfg.Debug and (method == "FireServer" or method == "InvokeServer") then
        local name = "?"
        pcall(function() name = self.Name end)
        print("[pynyxDlc] " .. method .. " -> " .. name)
        for i, v in pairs(args) do
            print("  arg[" .. i .. "] = " .. tostring(v))
        end
    end

    if cfg.SilentAim and (method == "FireServer" or method == "InvokeServer") then
        local target = GetClosestTarget()
        if target then
            for i, v in pairs(args) do
                if typeof(v) == "Vector3" then
                    args[i] = target.Position
                elseif typeof(v) == "CFrame" then
                    args[i] = CFrame.new(Camera.CFrame.Position, target.Position)
                end
            end
            return oldNamecall(self, unpack(args))
        end
    end

    return oldNamecall(self, ...)
end)

-- Player connections
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        CreateESP(player)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESP(player)
    end
end

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "pynyxDlc",
    Text = "Loaded. Debug ON — стреляй, смотри консоль.",
    Duration = 5
})
