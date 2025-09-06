-- ===========================================
-- 4444 Hub (ESP Safe + Aimbot + Auto-Teleport Reload)
-- ===========================================

-- 🔹 Auto reload après téléport (Rivals)
if syn and syn.queue_on_teleport then
    syn.queue_on_teleport([[
        loadstring(game:HttpGet("https://raw.githubusercontent.com/F1K2/RRRR/refs/heads/main/rivals.lua"))()
    ]])
elseif queue_on_teleport then
    queue_on_teleport([[
        loadstring(game:HttpGet("https://raw.githubusercontent.com/F1K2/RRRR/refs/heads/main/rivals.lua"))()
    ]])
end

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Charger Rayfield
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not success or not Rayfield then
    warn("Rayfield n'a pas pu être chargé. UI désactivée.")
    return
end

-- Fenêtre principale
local Window = Rayfield:CreateWindow({
    Name = "4444 Hub",
    LoadingTitle = "Loading 4444 Hub..",
    LoadingSubtitle = "ESP Safe + Aimbot",
    ToggleUIKeybind = Enum.KeyCode.RightShift,
    ConfigurationSaving = { Enabled = true, FolderName = nil, FileName = "4444 Hub" },
    Discord = { Enabled = true, Invite = "3R2xsfgDee", RememberJoins = false },
    KeySystem = false,
})

-- Tabs
local AimTab = Window:CreateTab("Aimbot")
local VisualTab = Window:CreateTab("ESP")
local PlayerTab = Window:CreateTab("Player")

-- Config
local config = {
    AimbotEnabled = false,
    AimbotSmoothness = 6,
    AimbotFOV = 120,
    AimbotPrediction = true,
    AimbotTargetPart = "Head",
    ESPEnabled = false,
    InfiniteJump = false,
    NoClip = false
}

-- ===== Aimbot (clic droit) =====
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
    if not part or not player.Character then return end
    local aimPos = part.Position
    if config.AimbotPrediction and player.Character:FindFirstChild("HumanoidRootPart") then
        aimPos = aimPos + player.Character.HumanoidRootPart.Velocity * 0.05
    end
    local screenPos = Camera:WorldToViewportPoint(aimPos)
    local mousePos = UserInputService:GetMouseLocation()
    local delta = (Vector2.new(screenPos.X, screenPos.Y) - mousePos) / config.AimbotSmoothness
    if mousemoverel then
        mousemoverel(delta.X, delta.Y)
    end
end

RunService.RenderStepped:Connect(function()
    if config.AimbotEnabled and IsAimbotKeyPressed() then
        local target, part = GetClosestPlayer()
        if target then AimAt(target, part) end
    end
end)

-- ===== ESP Safe (Highlight + BillboardGui) =====
local ESPObjects = {}

local function CreateESP(player)
    if player == LocalPlayer then return end
    if ESPObjects[player] then return end

    if player.Character then
        local highlight = Instance.new("Highlight")
        highlight.Name = "SafeESP"
        highlight.Adornee = player.Character
        highlight.FillColor = Color3.fromRGB(0,255,0)
        highlight.OutlineColor = Color3.fromRGB(255,0,0)
        highlight.FillTransparency = 0.5
        highlight.Enabled = config.ESPEnabled
        highlight.Parent = player.Character

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESPBillboard"
        billboard.Adornee = player.Character:FindFirstChild("HumanoidRootPart")
        billboard.Size = UDim2.new(0, 100, 0, 50)
        billboard.AlwaysOnTop = true
        billboard.Enabled = config.ESPEnabled
        billboard.Parent = player.Character

        local textLabel = Instance.new("TextLabel")
        textLabel.Text = player.Name
        textLabel.Size = UDim2.new(1,0,1,0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Color3.fromRGB(255,255,255)
        textLabel.TextScaled = true
        textLabel.Parent = billboard

        ESPObjects[player] = {highlight = highlight, billboard = billboard}
    end
end

local function RemoveESP(player)
    if ESPObjects[player] then
        if ESPObjects[player].highlight then ESPObjects[player].highlight:Destroy() end
        if ESPObjects[player].billboard then ESPObjects[player].billboard:Destroy() end
        ESPObjects[player] = nil
    end
end

for _, p in ipairs(Players:GetPlayers()) do
    CreateESP(p)
end
Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)

RunService.RenderStepped:Connect(function()
    for player, obj in pairs(ESPObjects) do
        if player.Character then
            obj.highlight.Enabled = config.ESPEnabled
            obj.billboard.Enabled = config.ESPEnabled
        end
    end
end)

-- ===== Infinite Jump =====
UserInputService.JumpRequest:Connect(function()
    if config.InfiniteJump then
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ===== NoClip =====
RunService.Stepped:Connect(function()
    if config.NoClip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

-- ===== UI Controls =====
AimTab:CreateToggle({ Name = "Enable Aimbot", CurrentValue = config.AimbotEnabled, Callback = function(v) config.AimbotEnabled = v end })
AimTab:CreateSlider({ Name = "Smoothness", Range = {1, 20}, Increment = 1, CurrentValue = config.AimbotSmoothness, Callback = function(v) config.AimbotSmoothness = v end })
AimTab:CreateSlider({ Name = "FOV", Range = {50, 600}, Increment = 10, CurrentValue = config.AimbotFOV, Callback = function(v) config.AimbotFOV = v end })
AimTab:CreateToggle({ Name = "Prediction", CurrentValue = config.AimbotPrediction, Callback = function(v) config.AimbotPrediction = v end })
AimTab:CreateDropdown({ Name = "Target Part", Options = {"Head","Torso","HumanoidRootPart"}, CurrentOption={config.AimbotTargetPart}, Callback=function(opt) config.AimbotTargetPart=opt[1] end })
AimTab:CreateLabel({ Title = "Activation : Clic droit (MouseButton2)" })

VisualTab:CreateToggle({ Name = "Enable ESP", CurrentValue = config.ESPEnabled, Callback = function(v) config.ESPEnabled = v end })

PlayerTab:CreateToggle({ Name = "Infinite Jump", CurrentValue = config.InfiniteJump, Callback = function(v) config.InfiniteJump=v end })
PlayerTab:CreateToggle({ Name = "NoClip", CurrentValue = config.NoClip, Callback = function(v) config.NoClip=v end })

Rayfield:Notify({ Title="4444 Hub", Content="Script injecté et ESP stable !", Duration=5 })
print("[4444 Hub] Script injecté et prêt")
