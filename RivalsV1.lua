-- ===========================================
-- 4444 Hub (Complete Safe Version)
-- ===========================================

-- 🔹 Auto reload après téléport
if syn and syn.queue_on_teleport then
    syn.queue_on_teleport([[
        loadstring(game:HttpGet("https://raw.githubusercontent.com/F1K2/RRRR/refs/heads/main/RivalsV1.lua"))()
    ]])
elseif queue_on_teleport then
    queue_on_teleport([[
        loadstring(game:HttpGet("https://raw.githubusercontent.com/F1K2/RRRR/refs/heads/main/RivalsV1.lua"))()
    ]])
end

-- 🔹 Exploit safe
local mousemoverel = mousemoverel or function() end
local hookmetamethod = hookmetamethod or hookfunction or function(_, f) return f end
local getnamecallmethod = getnamecallmethod or function() return "" end

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- 🔹 Fonctions sécurisées
local function GetCharacter(player)
    return player.Character or player.CharacterAdded:Wait()
end

local function GetHRP(player)
    local char = GetCharacter(player)
    return char:FindFirstChild("HumanoidRootPart")
end

-- Charger Rayfield UI
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)

if not success or not Rayfield then
    warn("[4444 Hub] Rayfield n'a pas pu être chargé. UI désactivée.")
    Rayfield = {
        CreateWindow = function() return {CreateTab=function() return {} end} end,
        Notify = function() end
    }
end

-- Fenêtre principale
local Window = Rayfield:CreateWindow({
    Name = "4444 Hub",
    LoadingTitle = "Loading 4444 Hub..",
    LoadingSubtitle = "ESP + Aimbot",
    ToggleUIKeybind = Enum.KeyCode.RightShift,
    ConfigurationSaving = { Enabled = true, FolderName = "4444Hub", FileName = "settings" },
})

-- Tabs
local AimTab = Window:CreateTab("Aimbot")
local VisualTab = Window:CreateTab("ESP")
local MiscTab = Window:CreateTab("Misc")

-- Config
local config = {
    AimbotEnabled = false,
    SilentAim = false,
    AimbotSmoothness = 6,
    AimbotFOV = 120,
    AimbotPrediction = true,
    AimbotTargetPart = "Head",
    ESPEnabled = true,
    BoxESP = true,
    Tracers = true,
    HealthBar = true,
    DistanceESP = true,
    TeamCheck = false,
    MaxDistance = 2000,
    InfiniteJump = false,
    ShowFOVCircle = true,
    FOVColor = Color3.fromRGB(255,0,0),
    ESPColor = Color3.fromRGB(255,255,255)
}

-- ===== Aimbot =====
local function IsAimbotKeyPressed()
    return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
end

local function GetClosestPlayer()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local closest, part, dist = nil, nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild(config.AimbotTargetPart) then
            local humanoid = p.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
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

-- ===== Silent Aim Hook =====
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    if config.SilentAim and method == "FindPartOnRayWithIgnoreList" then
        local target, part = GetClosestPlayer()
        if target and part then
            return part, part.Position
        end
    end
    return oldNamecall(self, ...)
end)

-- ===== FOV Circle =====
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 2
fovCircle.Filled = false

RunService.RenderStepped:Connect(function()
    fovCircle.Visible = config.AimbotEnabled and config.ShowFOVCircle
    fovCircle.Color = config.FOVColor
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    fovCircle.Radius = config.AimbotFOV

    if config.AimbotEnabled and IsAimbotKeyPressed() and not config.SilentAim then
        local target, part = GetClosestPlayer()
        if target then AimAt(target, part) end
    end
end)

-- ===== ESP =====
local ESPObjects = {}

local function CreateESP(player)
    if player == LocalPlayer then return end
    if ESPObjects[player] then return end

    ESPObjects[player] = {
        Box = Drawing.new("Square"),
        Tracer = Drawing.new("Line"),
        HealthBar = Drawing.new("Line"),
        Text = Drawing.new("Text"),
    }

    local esp = ESPObjects[player]
    esp.Box.Thickness = 1.5
    esp.Box.Filled = false
    esp.Box.Visible = false

    esp.Tracer.Thickness = 1.5
    esp.Tracer.Visible = false

    esp.HealthBar.Thickness = 3
    esp.HealthBar.Visible = false

    esp.Text.Size = 14
    esp.Text.Center = true
    esp.Text.Outline = true
    esp.Text.Visible = false
end

local function RemoveESP(player)
    if ESPObjects[player] then
        for _, obj in pairs(ESPObjects[player]) do
            if obj then obj:Remove() end
        end
        ESPObjects[player] = nil
    end
end

Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)
for _, player in pairs(Players:GetPlayers()) do
    CreateESP(player)
end

-- ESP Update
RunService.RenderStepped:Connect(function()
    if not config.ESPEnabled then
        for _, esp in pairs(ESPObjects) do
            for _, obj in pairs(esp) do obj.Visible = false end
        end
        return
    end

    local myHRP = GetHRP(LocalPlayer)
    if not myHRP then return end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") and player.Character:FindFirstChild("HumanoidRootPart") then
            local esp = ESPObjects[player]
            if not esp then continue end

            local head = player.Character.Head
            local hrp = player.Character.HumanoidRootPart
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")

            local dist = (hrp.Position - myHRP.Position).Magnitude
            if dist > config.MaxDistance then
                for _, obj in pairs(esp) do obj.Visible = false end
                continue
            end

            if config.TeamCheck and player.Team == LocalPlayer.Team then
                for _, obj in pairs(esp) do obj.Visible = false end
                continue
            end

            local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0,0.5,0))
            local hrpPos, hrpOnScreen = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, humanoid.HipHeight,0))

            if headOnScreen and hrpOnScreen then
                local height = math.abs(headPos.Y - hrpPos.Y)
                local width = height / 2
                local topLeft = Vector2.new(headPos.X - width/2, headPos.Y)

                esp.Box.Visible = config.BoxESP
                esp.Box.Size = Vector2.new(width, height)
                esp.Box.Position = topLeft
                esp.Box.Color = config.ESPColor

                esp.Tracer.Visible = config.Tracers
                esp.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                esp.Tracer.To = Vector2.new(hrpPos.X, hrpPos.Y)
                esp.Tracer.Color = config.ESPColor

                if humanoid and config.HealthBar then
                    local healthPct = humanoid.Health / humanoid.MaxHealth
                    esp.HealthBar.Visible = true
                    esp.HealthBar.From = Vector2.new(topLeft.X - 5, topLeft.Y + height)
                    esp.HealthBar.To = Vector2.new(topLeft.X - 5, topLeft.Y + height * (1 - healthPct))
                    esp.HealthBar.Color = Color3.fromRGB(255*(1-healthPct),255*healthPct,0)
                else
                    esp.HealthBar.Visible = false
                end

                if config.DistanceESP then
                    esp.Text.Visible = true
                    esp.Text.Text = player.Name.." ["..math.floor(dist).."m]"
                    esp.Text.Position = Vector2.new(headPos.X, topLeft.Y - 15)
                    esp.Text.Color = config.ESPColor
                else
                    esp.Text.Visible = false
                end
            else
                for _, obj in pairs(esp) do obj.Visible = false end
            end
        end
    end
end)

-- ===== Infinite Jump =====
UserInputService.JumpRequest:Connect(function()
    if config.InfiniteJump then
        local char = GetCharacter(LocalPlayer)
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ===== UI Controls =====
-- Aimbot Tab
AimTab:CreateToggle({ Name = "Enable Aimbot", CurrentValue = config.AimbotEnabled, Callback = function(v) config.AimbotEnabled = v end })
AimTab:CreateToggle({ Name = "Silent Aim", CurrentValue = config.SilentAim, Callback = function(v) config.SilentAim = v end })
AimTab:CreateSlider({ Name = "Smoothness", Range = {1, 20}, Increment = 1, CurrentValue = config.AimbotSmoothness, Callback = function(v) config.AimbotSmoothness = v end })
AimTab:CreateSlider({ Name = "FOV", Range = {50, 600}, Increment = 10, CurrentValue = config.AimbotFOV, Callback = function(v) config.AimbotFOV = v end })
AimTab:CreateToggle({ Name = "Prediction", CurrentValue = config.AimbotPrediction, Callback = function(v) config.AimbotPrediction = v end })
AimTab:CreateDropdown({ Name = "Target Part", Options = {"Head", "Torso", "HumanoidRootPart"}, CurrentOption = {config.AimbotTargetPart}, Callback = function(opt) config.AimbotTargetPart = opt[1] end })

-- ESP Tab
VisualTab:CreateToggle({ Name = "Enable ESP", CurrentValue = config.ESPEnabled, Callback = function(v) config.ESPEnabled = v end })
VisualTab:CreateToggle({ Name = "Show FOV Circle", CurrentValue = config.ShowFOVCircle, Callback = function(v) config.ShowFOVCircle = v end })
VisualTab:CreateColorPicker({ Name = "ESP Color", Color = config.ESPColor, Callback = function(c) config.ESPColor = c end })
VisualTab:CreateColorPicker({ Name = "FOV Color", Color = config.FOVColor, Callback = function(c) config.FOVColor = c end })

-- Misc Tab
MiscTab:CreateToggle({ Name = "Infinite Jump", CurrentValue = config.InfiniteJump, Callback = function(v) config.InfiniteJump = v end })

Rayfield:Notify({ Title="4444 Hub", Content="Script injecté !", Duration=5 })
print("[4444 Hub] Script injecté et prêt")
