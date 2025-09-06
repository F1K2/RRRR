-- ===========================================
-- 0212 Hub Ultra Safe Version (Rivals Compatible)
-- ===========================================

-- Auto reload après téléport
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

-- Rayfield
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- Fenêtre
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

-- Config
local config = {
    AimbotEnabled = false,
    SilentAimEnabled = false,
    ShowFOV = true,
    AimbotSmoothness = 6,
    AimbotFOV = 120,
    AimbotPrediction = true,
    AimbotTargetPart = "Head",
    ESPEnabled = false,
    InfiniteJump = false,
    NoClip = false
}

-- ================================
-- Aimbot Functions
-- ================================
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
    mousemoverel(delta.X, delta.Y)
end

-- RenderStepped loop for Aimbot
RunService.RenderStepped:Connect(function()
    if config.AimbotEnabled and IsAimbotKeyPressed() then
        local target, part = GetClosestPlayer()
        if target then AimAt(target, part) end
    end
end)

-- ================================
-- Silent Aim (safe hook)
-- ================================
local targetSilent = nil
RunService.Heartbeat:Connect(function()
    if config.SilentAimEnabled then
        local target, part = GetClosestPlayer()
        targetSilent = part or nil
    else
        targetSilent = nil
    end
end)

local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)
mt.__namecall = function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if config.SilentAimEnabled and method == "FireServer" and tostring(self) == "Hit" and targetSilent then
        if args[2] then args[2] = targetSilent.Position end
        return oldNamecall(self, unpack(args))
    end
    return oldNamecall(self, ...)
end
setreadonly(mt, true)

-- ================================
-- ESP Safe (Highlight + BillboardGui)
-- ================================
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
        ESPObjects[player] = highlight
    end
end

local function RemoveESP(player)
    if ESPObjects[player] and ESPObjects[player].Parent then
        ESPObjects[player]:Destroy()
        ESPObjects[player] = nil
    end
end

Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)
for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then CreateESP(p) end
end

-- Update ESP every frame
RunService.RenderStepped:Connect(function()
    for player, highlight in pairs(ESPObjects) do
        if highlight and player.Character then
            highlight.Enabled = config.ESPEnabled
            highlight.Adornee = player.Character
        end
    end
end)

-- ================================
-- Player Tab (InfiniteJump & NoClip)
-- ================================
UserInputService.JumpRequest:Connect(function()
    if config.InfiniteJump then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
end)

RunService.Stepped:Connect(function()
    if config.NoClip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

-- ================================
-- Rayfield UI
-- ================================
AimTab:CreateToggle({ Name = "Enable Aimbot", CurrentValue = config.AimbotEnabled, Callback = function(v) config.AimbotEnabled = v end })
AimTab:CreateToggle({ Name = "Silent Aim", CurrentValue = config.SilentAimEnabled, Callback = function(v) config.SilentAimEnabled = v end })
AimTab:CreateToggle({ Name = "Show ESP", CurrentValue = config.ESPEnabled, Callback = function(v) config.ESPEnabled = v end })
AimTab:CreateSlider({ Name = "Smoothness", Range = {1,20}, Increment = 1, CurrentValue = config.AimbotSmoothness, Callback = function(v) config.AimbotSmoothness=v end })
AimTab:CreateSlider({ Name = "FOV", Range = {50,600}, Increment = 10, CurrentValue = config.AimbotFOV, Callback = function(v) config.AimbotFOV=v end })
AimTab:CreateToggle({ Name = "Prediction", CurrentValue = config.AimbotPrediction, Callback = function(v) config.AimbotPrediction=v end })
AimTab:CreateDropdown({ Name = "Target Part", Options = {"Head","Torso","HumanoidRootPart"}, CurrentOption={config.AimbotTargetPart}, Callback=function(opt) config.AimbotTargetPart=opt[1] end })
AimTab:CreateLabel({ Title = "Activation : Clic droit (MouseButton2)" })

PlayerTab:CreateToggle({ Name = "Infinite Jump", CurrentValue = config.InfiniteJump, Callback = function(v) config.InfiniteJump=v end })
PlayerTab:CreateToggle({ Name = "No Clip", CurrentValue = config.NoClip, Callback = function(v) config.NoClip=v end })

Rayfield:Notify({ Title="0212 Hub", Content="Script chargé et ultra safe !", Duration=5 })
