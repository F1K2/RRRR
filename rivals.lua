-- ===========================================
-- 0212 Hub Full Version (Aimbot + Silent Aim + ESP + Auto Reload + Player)
-- ===========================================

-- Auto reload après téléport (Rivals)
if syn and syn.queue_on_teleport then
    syn.queue_on_teleport([[
        loadstring(game:HttpGet("https://tonlien.com/0212hub.lua"))()
    ]])
elseif queue_on_teleport then
    queue_on_teleport([[
        loadstring(game:HttpGet("https://tonlien.com/0212hub.lua"))()
    ]])
end

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Charger Rayfield
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- Fenêtre principale
local Window = Rayfield:CreateWindow({
    Name = "0212 Hub",
    LoadingTitle = "Loading 0212 Hub..",
    LoadingSubtitle = "by @nickyterra / @dfsz",
    ToggleUIKeybind = Enum.KeyCode.RightShift,
    ConfigurationSaving = { Enabled = true, FolderName = nil, FileName = "0212 Hub" },
    Discord = { Enabled = true, Invite = "3R2xsfgDee", RememberJoins = false },
    KeySystem = false,
})

-- Tabs
local AimTab = Window:CreateTab("Aimbot")
local VisualTab = Window:CreateTab("ESP")
local PlayerTab = Window:CreateTab("Player")

-- Variables config
local config = {
    AimbotEnabled = false,
    SilentAimEnabled = false,
    ShowFOV = true,
    AimbotSmoothness = 6,
    AimbotFOV = 120,
    AimbotPrediction = true,
    AimbotTargetPart = "Head",
    ESPEnabled = false,
    ESPBox = true,
    ESPTracer = true,
    ESPHealth = true,
    ESPNames = true,
    InfiniteJump = false,
    NoClip = false
}

-- Cercle FOV
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Radius = config.AimbotFOV
FOVCircle.Filled = false
FOVCircle.Thickness = 1
FOVCircle.Color = Color3.fromRGB(255, 255, 255)

-- ===== Aimbot Core =====
local function IsAimbotKeyPressed()
    return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
end

local function GetClosestPlayer()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local closest, part, dist = nil, nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild(config.AimbotTargetPart) then
            local targetPart = p.Character[config.AimbotTargetPart]
            local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
            if onScreen then
                local mag = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                if mag < dist and mag <= config.AimbotFOV then
                    closest = p
                    part = targetPart
                    dist = mag
                end
            end
        end
    end
    return closest, part
end

local function AimAt(player, part)
    if not part then return end
    local aimPos = part.Position
    if config.AimbotPrediction and player.Character:FindFirstChild("HumanoidRootPart") then
        local vel = player.Character.HumanoidRootPart.Velocity
        aimPos = aimPos + vel * 0.05
    end
    local screenPos = Camera:WorldToViewportPoint(aimPos)
    local mousePos = UserInputService:GetMouseLocation()
    local delta = (Vector2.new(screenPos.X, screenPos.Y) - mousePos) / config.AimbotSmoothness
    mousemoverel(delta.X, delta.Y)
end

-- Render loop for Aimbot + FOV
RunService.RenderStepped:Connect(function()
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Radius = config.AimbotFOV
    FOVCircle.Visible = config.ShowFOV and (config.AimbotEnabled or config.SilentAimEnabled)
    if config.AimbotEnabled and IsAimbotKeyPressed() then
        local target, part = GetClosestPlayer()
        if target then
            AimAt(target, part)
        end
    end
end)

-- ===== Silent Aim =====
local targetSilent = nil
RunService.Heartbeat:Connect(function()
    if config.SilentAimEnabled then
        local target, part = GetClosestPlayer()
        targetSilent = part or nil
    else
        targetSilent = nil
    end
end)

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if config.SilentAimEnabled and method == "FireServer" and tostring(self) == "Hit" and targetSilent then
        args[2] = targetSilent.Position
        return oldNamecall(self, unpack(args))
    end
    return oldNamecall(self, ...)
end)

-- === UI Controls ===
AimTab:CreateToggle({ Name = "Enable Aimbot", CurrentValue = config.AimbotEnabled, Callback = function(v) config.AimbotEnabled = v end })
AimTab:CreateToggle({ Name = "Silent Aim", CurrentValue = config.SilentAimEnabled, Callback = function(v) config.SilentAimEnabled = v end })
AimTab:CreateToggle({ Name = "Show FOV Circle", CurrentValue = config.ShowFOV, Callback = function(v) config.ShowFOV = v end })
AimTab:CreateSlider({ Name = "Smoothness", Range = {1, 20}, Increment = 1, CurrentValue = config.AimbotSmoothness, Callback = function(v) config.AimbotSmoothness = v end })
AimTab:CreateSlider({ Name = "FOV", Range = {50, 600}, Increment = 10, CurrentValue = config.AimbotFOV, Callback = function(v) config.AimbotFOV = v end })
AimTab:CreateToggle({ Name = "Prediction", CurrentValue = config.AimbotPrediction, Callback = function(v) config.AimbotPrediction = v end })
AimTab:CreateDropdown({ Name = "Target Part", Options = {"Head", "Torso", "HumanoidRootPart"}, CurrentOption = {config.AimbotTargetPart}, Callback = function(opt) config.AimbotTargetPart = opt[1] end })
AimTab:CreateLabel({ Title = "Activation : Clic droit (MouseButton2)" })

-- === ESP System ===
local ESPObjects = {}

local function ClearESP()
    for _, v in pairs(ESPObjects) do
        v.Box:Remove()
        v.Tracer:Remove()
        v.Health:Remove()
        v.Name:Remove()
    end
    ESPObjects = {}
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    local box = Drawing.new("Square")
    box.Color = Color3.fromRGB(0, 255, 0)
    box.Thickness = 1
    box.Filled = false

    local tracer = Drawing.new("Line")
    tracer.Color = Color3.fromRGB(255, 255, 255)

    local health = Drawing.new("Line")
    health.Color = Color3.fromRGB(0, 255, 0)

    local name = Drawing.new("Text")
    name.Color = Color3.fromRGB(255, 255, 255)
    name.Size = 14
    name.Center = true

    ESPObjects[player] = { Box = box, Tracer = tracer, Health = health, Name = name }
end

RunService.RenderStepped:Connect(function()
    if config.ESPEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                if not ESPObjects[player] then
                    CreateESP(player)
                end
                local obj = ESPObjects[player]
                local hrp = player.Character.HumanoidRootPart
                local pos, vis = Camera:WorldToViewportPoint(hrp.Position)
                if vis then
                    local size = (Camera:WorldToViewportPoint(hrp.Position + Vector3.new(2, 3, 0)).X - Camera:WorldToViewportPoint(hrp.Position - Vector3.new(2, -3, 0)).X)
                    obj.Box.Visible = config.ESPBox
                    obj.Box.Size = Vector2.new(size, size * 1.5)
                    obj.Box.Position = Vector2.new(pos.X - size/2, pos.Y - size*0.75)

                    obj.Tracer.Visible = config.ESPTracer
                    obj.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    obj.Tracer.To = Vector2.new(pos.X, pos.Y)

                    obj.Name.Visible = config.ESPNames
                    obj.Name.Position = Vector2.new(pos.X, pos.Y - size)
                    obj.Name.Text = player.Name

                    obj.Health.Visible = config.ESPHealth
                    obj.Health.From = Vector2.new(pos.X - size/2 - 5, pos.Y + size*0.75)
                    obj.Health.To = Vector2.new(pos.X - size/2 - 5, pos.Y + size*0.75 - (player.Character.Humanoid.Health / player.Character.Humanoid.MaxHealth) * size*1.5)
                else
                    obj.Box.Visible = false
                    obj.Tracer.Visible = false
                    obj.Name.Visible = false
                    obj.Health.Visible = false
                end
            end
        end
    else
        ClearESP()
    end
end)

VisualTab:CreateToggle({ Name = "Enable ESP", CurrentValue = config.ESPEnabled, Callback = function(v) config.ESPEnabled = v end })
VisualTab:CreateToggle({ Name = "Box", CurrentValue = config.ESPBox, Callback = function(v) config.ESPBox = v end })
VisualTab:CreateToggle({ Name = "Tracers", CurrentValue = config.ESPTracer, Callback = function(v) config.ESPTracer = v end })
VisualTab:CreateToggle({ Name = "Health Bar", CurrentValue = config.ESPHealth, Callback = function(v) config.ESPHealth = v end })
VisualTab:CreateToggle({ Name = "Names", CurrentValue = config.ESPNames, Callback = function(v) config.ESPNames = v end })

-- === Player Tab ===
PlayerTab:CreateToggle({ Name = "Infinite Jump", CurrentValue = false, Callback = function(v) config.InfiniteJump = v end })
UserInputService.JumpRequest:Connect(function()
    if config.InfiniteJump then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end)

PlayerTab:CreateToggle({ Name = "No Clip", CurrentValue = false, Callback = function(v) config.NoClip = v end })
RunService.Stepped:Connect(function()
    if config.NoClip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)
