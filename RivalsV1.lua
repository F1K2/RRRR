-- Auto reload après téléport
if syn and syn.queue_on_teleport then
    syn.queue_on_teleport([[
        loadstring(game:HttpGet("https://raw.githubusercontent.com/F1K2/RRRR/refs/heads/main/RivalsV1.lua"))()
    ]])
elseif queue_on_teleport then
    queue_on_teleport([[
        loadstring(game:HttpGet("https://raw.githubusercontent.com/F1K2/RRRR/refs/heads/main/RivalsV1.lua"))()
    ]])
end

local mousemoverel = mousemoverel or function() end
local safeHook = (hookmetamethod and type(hookmetamethod)=="function") and hookmetamethod or nil
local getnamecallmethod = getnamecallmethod or function() return "" end

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- Wait for LocalPlayer
local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    RunService.Heartbeat:Wait()
    LocalPlayer = Players.LocalPlayer
end

-- Wait for current camera
local Camera = Workspace.CurrentCamera
while not Camera do
    RunService.Heartbeat:Wait()
    Camera = Workspace.CurrentCamera
end

-- Utility: safe get character / HRP
local function GetCharacter(player)
    if not player then return nil end
    -- if Character exists return it, otherwise wait for it
    return player.Character or player.CharacterAdded:Wait()
end

local function GetHRP(player)
    if not player then return nil end
    local char = nil
    -- pcall so we don't error if CharacterAdded yields unexpectedly nil
    local ok, result = pcall(function() return GetCharacter(player) end)
    if ok then char = result end
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

-- Rayfield load (with fallback)
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

local Window = Rayfield:CreateWindow({
    Name = "4444 Hub",
    LoadingTitle = "Loading 4444 Hub..",
    LoadingSubtitle = "Enjoy the script!",
    ToggleUIKeybind = Enum.KeyCode.RightShift,
    ConfigurationSaving = { Enabled = true, FolderName = "4444Hub", FileName = "settings" },
})

local Window = Rayfield:CreateWindow({
   Name = "4444 Hub",
   Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "Loading 4444 Hub..",
   LoadingSubtitle = "Enjoy the script!",
   ShowText = "Rayfield", -- for mobile users to unhide rayfield, change if you'd like
   Theme = "Default", -- Check https://docs.sirius.menu/rayfield/configuration/themes

   ToggleUIKeybind = Enum.KeyCode.RightShift, -- The keybind to toggle the UI visibility (string like "K" or Enum.KeyCode)

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false, -- Prevents Rayfield from warning when the script has a version mismatch with the interface

   ConfigurationSaving = {
      Enabled = true,
      FolderName = 4444, -- Create a custom folder for your hub/game
      FileName = "4444 Hub"
   },

   Discord = {
      Enabled = true, -- Prompt the user to join your Discord server if their executor supports it
      Invite = "rPWv4TQVsV", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ ABCD would be ABCD
      RememberJoins = true -- Set this to false to make them join the discord every time they load it up
   },

   KeySystem = true, -- Set this to true to use our key system
   KeySettings = {
      Title = "4444 Hub",
      Subtitle = "Key System",
      Note = "buy your key on discord (discord.gg/rPWv4TQVsV)", -- Use this to tell the user how to get a key
      FileName = "Key", -- It is recommended to use something unique as other scripts using Rayfield may overwrite your key file
      SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
      GrabKeyFromSite = true, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
      Key = {"Hello"} -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
   }
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
    ESPColor = Color3.fromRGB(255,255,255),
    WalkSpeed = 16
	
}

-- ===== Aimbot helpers =====
local function IsAimbotKeyPressed()
    return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
end

local function GetClosestPlayer()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local closest, part, dist = nil, nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local char = p.Character
            if char and char:FindFirstChild(config.AimbotTargetPart) then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    local targetPart = char[config.AimbotTargetPart]
                    if targetPart then
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
        end
    end
    return closest, part
end

local function AimAt(player, part)
    if not part or not player or not player.Character then return end
    local aimPos = part.Position
    if config.AimbotPrediction and player.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then aimPos = aimPos + hrp.Velocity * 0.05 end
    end
    local screenPos = Camera:WorldToViewportPoint(aimPos)
    local mousePos = UserInputService:GetMouseLocation()
    local delta = (Vector2.new(screenPos.X, screenPos.Y) - mousePos) / config.AimbotSmoothness
    -- protect mousemoverel call
    if mousemoverel and type(mousemoverel) == "function" then
        pcall(function() mousemoverel(delta.X, delta.Y) end)
    end
end

-- ===== Silent Aim hook (safe pattern) =====
if safeHook then
    local oldNamecall
    oldNamecall = safeHook(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if config.SilentAim and method == "FindPartOnRayWithIgnoreList" then
            local target, part = GetClosestPlayer()
            if target and part then
                -- NOTE: returning different shape than original function can break things;
                -- attempt a minimal safe return (depends on exploit/remote/target game).
                -- Here we return the original call with the same args to avoid crashing.
                -- If you want to modify this behavior you need to adapt to the game's ray function signature.
                return oldNamecall(self, ...)
            end
        end
        return oldNamecall(self, ...)
    end)
else
    print("[4444 Hub] Silent Aim hook disabled (exploit not supported)")
end

-- ===== FOV Circle (Drawing) =====
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 2
fovCircle.Filled = false
fovCircle.Visible = false

RunService.RenderStepped:Connect(function()
    -- safe camera check
    if not Camera then
        Camera = Workspace.CurrentCamera
        if not Camera then return end
    end

    fovCircle.Visible = config.AimbotEnabled and config.ShowFOVCircle
    fovCircle.Color = config.FOVColor
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    fovCircle.Radius = config.AimbotFOV

    if config.AimbotEnabled and IsAimbotKeyPressed() and not config.SilentAim then
        local target, part = GetClosestPlayer()
        if target and part then
            AimAt(target, part)
        end
    end
end)

-- ===== ESP =====
local ESPObjects = {}

local function CreateESP(player)
    if not player or player == LocalPlayer then return end
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
    if not player then return end
    if ESPObjects[player] then
        for _, obj in pairs(ESPObjects[player]) do
            if obj then pcall(function() obj:Remove() end) end
        end
        ESPObjects[player] = nil
    end
end

Players.PlayerAdded:Connect(function(p) CreateESP(p) end)
Players.PlayerRemoving:Connect(function(p) RemoveESP(p) end)
for _, player in pairs(Players:GetPlayers()) do CreateESP(player) end

-- ESP Update
RunService.RenderStepped:Connect(function()
    if not config.ESPEnabled then
        for _, esp in pairs(ESPObjects) do
            for _, obj in pairs(esp) do
                if obj then pcall(function() obj.Visible = false end) end
            end
        end
        return
    end

    local myHRP = GetHRP(LocalPlayer)
    if not myHRP then
        -- if we don't have our HRP, hide everything and skip this frame
        for _, esp in pairs(ESPObjects) do
            for _, obj in pairs(esp) do
                if obj then pcall(function() obj.Visible = false end) end
            end
        end
        return
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then
            -- skip self
        else
            local char = player.Character
            if char and char:FindFirstChild("Head") and char:FindFirstChild("HumanoidRootPart") then
                local esp = ESPObjects[player]
                if esp then
                    local head = char.Head
                    local hrp = char.HumanoidRootPart
                    local humanoid = char:FindFirstChildOfClass("Humanoid")
                    if not humanoid then
                        -- hide if no humanoid
                        for _, obj in pairs(esp) do if obj then pcall(function() obj.Visible = false end) end end
                    else
                        local dist = (hrp.Position - myHRP.Position).Magnitude
                        if dist > config.MaxDistance then
                            for _, obj in pairs(esp) do if obj then pcall(function() obj.Visible = false end) end end
                        elseif config.TeamCheck and player.Team == LocalPlayer.Team then
                            for _, obj in pairs(esp) do if obj then pcall(function() obj.Visible = false end) end end
                        else
                            local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0,0.5,0))
                            local hrpPos, hrpOnScreen = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, humanoid.HipHeight or 0,0))
                            if headOnScreen and hrpOnScreen then
                                local height = math.abs(headPos.Y - hrpPos.Y)
                                local width = height / 2
                                local topLeft = Vector2.new(headPos.X - width/2, headPos.Y)

                                -- Box
                                esp.Box.Visible = config.BoxESP
                                esp.Box.Size = Vector2.new(width, height)
                                esp.Box.Position = topLeft
                                esp.Box.Color = config.ESPColor

                                -- Tracer
                                esp.Tracer.Visible = config.Tracers
                                esp.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                                esp.Tracer.To = Vector2.new(hrpPos.X, hrpPos.Y)
                                esp.Tracer.Color = config.ESPColor

                                -- Health Bar
                                if humanoid and config.HealthBar then
                                    local healthPct = math.clamp(humanoid.Health / (humanoid.MaxHealth ~= 0 and humanoid.MaxHealth or 1), 0, 1)
                                    esp.HealthBar.Visible = true
                                    esp.HealthBar.From = Vector2.new(topLeft.X - 5, topLeft.Y + height)
                                    esp.HealthBar.To = Vector2.new(topLeft.X - 5, topLeft.Y + height * (1 - healthPct))
                                    esp.HealthBar.Color = Color3.fromRGB(255*(1-healthPct),255*healthPct,0)
                                else
                                    esp.HealthBar.Visible = false
                                end

                                -- Distance / Name
                                if config.DistanceESP then
                                    esp.Text.Visible = true
                                    esp.Text.Text = player.Name.." ["..math.floor(dist).."m]"
                                    esp.Text.Position = Vector2.new(headPos.X, topLeft.Y - 15)
                                    esp.Text.Color = config.ESPColor
                                else
                                    esp.Text.Visible = false
                                end
                            else
                                -- off-screen: hide
                                esp.Box.Visible = false
                                esp.Tracer.Visible = false
                                esp.HealthBar.Visible = false
                                esp.Text.Visible = false
                            end
                        end
                    end
                end
            else
                -- Character not loaded: ensure any possible ESP for this player is hidden
                if ESPObjects[player] then
                    for _, obj in pairs(ESPObjects[player]) do if obj then pcall(function() obj.Visible = false end) end end
                end
            end
        end
    end
end)
-- =========================
-- ===== MISC FEATURES =====
-- =========================

-- ===== Infinite Jump =====
UserInputService.JumpRequest:Connect(function()
    if config.InfiniteJump then
        local char = GetCharacter(LocalPlayer)
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end) end
        end
    end
end)

-- ===== WalkSpeed =====
RunService.Stepped:Connect(function()
    if config.WalkSpeed and config.WalkSpeed > 0 then
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.WalkSpeed ~= config.WalkSpeed then
                humanoid.WalkSpeed = config.WalkSpeed
            end
        end
    end
end)

-- ===== Fly =====
config.FlyEnabled = false
config.FlySpeed = 5

local flyConn

local function StopFly()
    if flyConn then
        flyConn:Disconnect()
        flyConn = nil
    end
    local hrp = GetHRP(LocalPlayer)
    if hrp then
        hrp.Velocity = Vector3.new(0,0,0)
    end
end

local function StartFly()
    StopFly() -- éviter doublons
    local hrp = GetHRP(LocalPlayer)
    if not hrp then return end

    flyConn = RunService.RenderStepped:Connect(function()
        if config.FlyEnabled and hrp and hrp.Parent then
            local cam = Workspace.CurrentCamera
            local move = Vector3.new()

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                move = move + (cam.CFrame.LookVector)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                move = move - (cam.CFrame.LookVector)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                move = move - (cam.CFrame.RightVector)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                move = move + (cam.CFrame.RightVector)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                move = move + Vector3.new(0,1,0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                move = move + Vector3.new(0,-1,0)
            end

            if move.Magnitude > 0 then
                hrp.Velocity = move.Unit * config.FlySpeed * 10
            else
                hrp.Velocity = Vector3.new(0,0,0)
            end
        end
    end)
end

local function ToggleFly(state)
    config.FlyEnabled = state
    if state then
        StartFly()
    else
        StopFly()
    end
end

-- 🔁 Réactiver automatiquement après respawn
LocalPlayer.CharacterAdded:Connect(function()
    if config.FlyEnabled then
        task.wait(1) -- petit délai pour laisser charger HRP
        StartFly()
    end
end)

-- ===== UI Controls =====
-- Aimbot Tab
AimTab:CreateToggle({ Name = "Enable Aimbot", CurrentValue = config.AimbotEnabled, Callback = function(v) config.AimbotEnabled = v end })
AimTab:CreateToggle({ Name = "Silent Aim (don't work for the moment !)", CurrentValue = config.SilentAim, Callback = function(v) config.SilentAim = v end })
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
MiscTab:CreateSlider({ Name = "WalkSpeed", Range = {16, 200}, Increment = 1, CurrentValue = config.WalkSpeed, Callback = function(v) config.WalkSpeed = v end })
MiscTab:CreateToggle({ Name = "Fly", CurrentValue = config.FlyEnabled, Callback = function(v) ToggleFly(v) end })
MiscTab:CreateSlider({ Name = "Fly Speed", Range = {1, 50}, Increment = 1, CurrentValue = config.FlySpeed, Callback = function(v) config.FlySpeed = v end })

Rayfield:Notify({ Title="4444 Hub", Content="Script injecté !", Duration=5 })
print("[4444 Hub] Script injecté !")

