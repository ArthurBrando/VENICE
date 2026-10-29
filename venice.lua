--==============================================================
--  VENICE HUB  •  MM2  (Sheriff / Murder / Innocent)
--  Menu: Sirius | Tema: Azul
--==============================================================

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Workspace         = game:GetService("Workspace")
local StarterGui        = game:GetService("StarterGui")

local LP  = Players.LocalPlayer
local CAM = Workspace.CurrentCamera

local Sirius = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

if not Drawing then
    warn("[Venice] Executor sem Drawing API: box / line / name / FOV desativados.")
end

--==============================================================
--  CONFIG
--==============================================================
local Config = {
    -- ESP
    ESPEnabled      = true,
    ESPInnocent     = true,
    ESPSheriff      = true,
    ESPMurder       = true,
    ESPHighlight    = true,
    ESPBox          = false,
    ESPLine         = false,
    ESPName         = false,
    ESPDistance     = true,
    MaxDistance     = 600,
    HideMurderOnNewSheriff = true,
    Notifications   = true,

    -- Player
    Speed           = 32,
    JumpPower       = 60,
    Noclip          = false,
    Fly             = false,
    FlySpeed        = 60,
    InfiniteJump    = false,
    DoubleJump      = false,

    -- FOV
    FOVEnabled      = false,
    FOVSize         = 120,
    FOVColor        = Color3.fromRGB(0, 150, 255),
    FOVRGB          = false,
    FOVRGBSpeed     = 1,

    -- Headlock
    Headlock        = false,
    HeadlockInFOV   = true,

    -- Viewmodel
    VMEnabled       = false,
    VMHide          = false,
    VMSize          = 1,
    VMMaterial      = "Metal",
    VMColor         = Color3.fromRGB(200, 200, 200),
    VMTexture       = "",

    -- Crosshair
    Crosshair       = false,
    CrosshairId     = "6031091004",
    CrosshairSize   = 24,
    CrosshairOffsetY = 0,
    CrosshairSpin   = false,
    CrosshairSpinSpeed = 90,
}

local Roles   = {}   -- [player] = "Innocent" | "Sheriff" | "Murder"
local ESPData = {}
local HideMurder = false

local COLORS = {
    Innocent = Color3.fromRGB(0, 255, 120),
    Sheriff  = Color3.fromRGB(0, 140, 255),
    Murder   = Color3.fromRGB(255, 45, 45),
}

local function roleColor(role)
    return COLORS[role] or COLORS.Innocent
end

local function getHum(plr)
    local char = (plr or LP).Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getHRP(plr)
    local char = (plr or LP).Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

--==============================================================
--  TEMA AZUL
--==============================================================
local Theme = {
    Scheme = "Dark",
    Background = Color3.fromRGB(8, 16, 30),
    Text = Color3.fromRGB(220, 235, 255),
    Accent = Color3.fromRGB(0, 132, 255),
    Title = Color3.fromRGB(235, 245, 255),
    Icon = Color3.fromRGB(0, 170, 255),
    Shadow = Color3.fromRGB(0, 0, 0),
    Glow = Color3.fromRGB(0, 120, 255),
    Main = Color3.fromRGB(12, 24, 42),
    Dropdown = Color3.fromRGB(16, 32, 55),
    DropdownText = Color3.fromRGB(210, 230, 255),
    Toggle = Color3.fromRGB(20, 40, 68),
    ToggleEnabled = Color3.fromRGB(0, 132, 255),
    Slider = Color3.fromRGB(20, 40, 68),
    SliderProgress = Color3.fromRGB(0, 132, 255),
    Button = Color3.fromRGB(16, 40, 72),
    ButtonText = Color3.fromRGB(230, 242, 255),
    Input = Color3.fromRGB(14, 28, 48),
    InputText = Color3.fromRGB(220, 235, 255),
    InputPlaceholder = Color3.fromRGB(120, 150, 190),
    SectionText = Color3.fromRGB(0, 170, 255),
}

local Window = Sirius:CreateWindow({
    Name = "Venice Hub  •  MM2",
    LoadingTitle = "Venice Hub",
    LoadingSubtitle = "MM2 Edition",
    Theme = Theme,
    ConfigurationSaving = { Enabled = true, FolderName = "VeniceHub", FileName = "MM2" },
    Discord = { Enabled = false },
    KeySystem = false,
})

local function notify(title, content)
    if not Config.Notifications then return end
    pcall(function()
        Sirius:Notify({ Title = title, Content = content, Duration = 5 })
    end)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = title, Text = content, Duration = 5 })
    end)
end

--==============================================================
--  DETECÇÃO DE CARGO
--==============================================================
local KNIFE_NAMES = { Knife = true, ["Silver Knife"] = true }
local GUN_NAMES   = { Gun = true, Revolver = true, ["Silver Gun"] = true }

local function getToolName(plr)
    local char = plr.Character
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") then return t.Name end
        end
    end
    local bp = plr:FindFirstChildOfClass("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then return t.Name end
        end
    end
    return nil
end

local function scanRoles()
    local foundMurder, foundSheriff
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then
            local tool = getToolName(plr)
            if tool then
                if KNIFE_NAMES[tool] then
                    foundMurder = plr
                    Roles[plr] = "Murder"
                elseif GUN_NAMES[tool] and plr ~= foundMurder then
                    foundSheriff = plr
                    Roles[plr] = "Sheriff"
                else
                    Roles[plr] = Roles[plr] or "Innocent"
                end
            else
                Roles[plr] = "Innocent"
            end
        end
    end

    local oldMurder, oldSheriff = Roles.__murder, Roles.__sheriff

    -- Murder morreu / sumiu -> reseta e espera o próximo com faca
    if oldMurder and foundMurder ~= oldMurder then
        Roles.__murder = nil
        HideMurder = false
        notify("Murder morreu", "Aguardando o novo Murder aparecer com a faca...")
        for p, d in pairs(ESPData) do
            if Roles[p] == "Murder" then removeESP(p) end
        end
    end

    -- Sheriff mudou
    if foundSheriff ~= oldSheriff then
        if oldSheriff then
            notify("Sheriff morreu", "ESP do Sheriff removido. Aguardando o novo.")
        end
        Roles.__sheriff = foundSheriff
        if foundSheriff then
            notify("Sheriff encontrado", foundSheriff.Name .. " está armado.")
            if Config.HideMurderOnNewSheriff then
                HideMurder = true
            end
        end
    end

    if foundMurder and foundMurder ~= oldMurder then
        Roles.__murder = foundMurder
        HideMurder = false
        notify("Murder encontrado", foundMurder.Name .. " está com a faca.")
    elseif not foundMurder then
        Roles.__murder = nil
    end
end

--==============================================================
--  ESP
--==============================================================
local function shouldShow(plr)
    if plr == LP then return false end
    local role = Roles[plr] or "Innocent"
    if role == "Murder" then
        if HideMurder then return false end
        return Config.ESPMurder
    elseif role == "Sheriff" then
        return Config.ESPSheriff
    end
    return Config.ESPInnocent
end

local function createESP(plr)
    if ESPData[plr] then return end
    local data = {}

    local hl = Instance.new("Highlight")
    hl.Name = "VeniceESP"
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency = 0.65
    hl.OutlineTransparency = 0
    hl.Enabled = false
    data.Highlight = hl

    if Drawing then
        local box = Drawing.new("Square")
        box.Thickness = 1; box.Filled = false; box.Visible = false
        local line = Drawing.new("Line")
        line.Thickness = 1; line.Visible = false
        local txt = Drawing.new("Text")
        txt.Size = 14; txt.Center = true; txt.Outline = true; txt.Visible = false
        data.Box, data.Line, data.Name = box, line, txt
    end

    ESPData[plr] = data
end

function removeESP(plr)
    local d = ESPData[plr]
    if not d then return end
    if d.Highlight then d.Highlight:Destroy() end
    for _, obj in ipairs({ d.Box, d.Line, d.Name }) do
        if obj then pcall(function() obj:Remove() end) end
    end
    ESPData[plr] = nil
end

for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LP then createESP(plr) end
end

Players.PlayerAdded:Connect(function(plr)
    if plr ~= LP then
        Roles[plr] = "Innocent"
        createESP(plr)
    end
end)

Players.PlayerRemoving:Connect(function(plr)
    removeESP(plr)
    Roles[plr] = nil
end)

--==============================================================
--  FOV CIRCLE
--==============================================================
local FovCircle
if Drawing then
    FovCircle = Drawing.new("Circle")
    FovCircle.Thickness = 1.5
    FovCircle.NumSides = 100
    FovCircle.Filled = false
    FovCircle.Visible = false
end

local function hsvRGB(speed)
    local h = (os.clock() * speed) % 1
    return Color3.fromHSV(h, 1, 1)
end

--==============================================================
--  LOOP PRINCIPAL (ESP + FOV)
--==============================================================
RunService.RenderStepped:Connect(function()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize

    -- FOV
    if FovCircle then
        FovCircle.Position = Vector2.new(vp.X / 2, vp.Y / 2)
        FovCircle.Radius = Config.FOVSize
        FovCircle.Color = Config.FOVRGB and hsvRGB(Config.FOVRGBSpeed) or Config.FOVColor
        FovCircle.Visible = Config.FOVEnabled
    end

    -- ESP
    for plr, data in pairs(ESPData) do
        local char = plr.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local head = char and char:FindFirstChild("Head")

        local show = Config.ESPEnabled and shouldShow(plr) and hrp and hum and hum.Health > 0
        if show and Config.ESPDistance then
            if (cam.CFrame.Position - hrp.Position).Magnitude > Config.MaxDistance then
                show = false
            end
        end

        local col = roleColor(Roles[plr])

        -- Highlight
        if data.Highlight then
            if show and Config.ESPHighlight then
                if data.Highlight.Parent ~= char then data.Highlight.Parent = char end
                data.Highlight.FillColor = col
                data.Highlight.OutlineColor = col
                data.Highlight.Enabled = true
            else
                data.Highlight.Enabled = false
            end
        end

        -- Box / Line / Name
        if show and head and hrp then
            local topPos    = head.Position + Vector3.new(0, 0.55, 0)
            local bottomPos = hrp.Position - Vector3.new(0, hum.HipHeight + 0.6, 0)
            local topScr, on1    = cam:WorldToViewportPoint(topPos)
            local bottomScr, on2 = cam:WorldToViewportPoint(bottomPos)

            if on1 and on2 and topScr.Z > 0 then
                local h = math.max(bottomScr.Y - topScr.Y, 6)
                local w = h * 0.55
                local x = topScr.X - w / 2

                if data.Box and Config.ESPBox then
                    data.Box.Position = Vector2.new(x, topScr.Y)
                    data.Box.Size = Vector2.new(w, h)
                    data.Box.Color = col
                    data.Box.Visible = true
                elseif data.Box then
                    data.Box.Visible = false
                end

                if data.Line and Config.ESPLine then
                    data.Line.From = Vector2.new(vp.X / 2, vp.Y)
                    data.Line.To = Vector2.new(topScr.X, topScr.Y + h)
                    data.Line.Color = col
                    data.Line.Visible = true
                elseif data.Line then
                    data.Line.Visible = false
                end

                if data.Name and Config.ESPName then
                    local dist = math.floor((cam.CFrame.Position - hrp.Position).Magnitude)
                    data.Name.Text = string.format("%s [%s] %dm", plr.Name, Roles[plr] or "?", dist)
                    data.Name.Position = Vector2.new(topScr.X, topScr.Y - 18)
                    data.Name.Color = col
                    data.Name.Visible = true
                elseif data.Name then
                    data.Name.Visible = false
                end
            else
                if data.Box then data.Box.Visible = false end
                if data.Line then data.Line.Visible = false end
                if data.Name then data.Name.Visible = false end
            end
        else
            if data.Box then data.Box.Visible = false end
            if data.Line then data.Line.Visible = false end
            if data.Name then data.Name.Visible = false end
        end
    end
end)

--==============================================================
--  SCAN LOOP
--==============================================================
task.spawn(function()
    while true do
        pcall(scanRoles)
        task.wait(0.3)
    end
end)

--==============================================================
--  HEADLOCK
--==============================================================
local function getLockTarget()
    local myRole = Roles[LP]
    if myRole == "Sheriff" then return Roles.__murder
    elseif myRole == "Murder" then return Roles.__sheriff
    else return Roles.__murder end
end

RunService:BindToRenderStep("VeniceHeadlock", Enum.RenderPriority.Camera.Value + 1, function()
    if not Config.Headlock then return end
    local target = getLockTarget()
    if not target or not target.Character then return end
    local head = target.Character:FindFirstChild("Head")
    local hum  = target.Character:FindFirstChildOfClass("Humanoid")
    if not head or not hum or hum.Health <= 0 then return end

    local cam = Workspace.CurrentCamera
    local screen, onScreen = cam:WorldToViewportPoint(head.Position)

    if Config.HeadlockInFOV then
        local vp = cam.ViewportSize
        local center = Vector2.new(vp.X / 2, vp.Y / 2)
        if (Vector2.new(screen.X, screen.Y) - center).Magnitude > Config.FOVSize then
            return
        end
    end

    cam.CFrame = CFrame.lookAt(cam.CFrame.Position, head.Position)
end)

--==============================================================
--  PLAYER
--==============================================================
local function applySpeed()
    local hum = getHum()
    if hum then hum.WalkSpeed = Config.Speed end
end

local function applyJump()
    local hum = getHum()
    if hum then hum.JumpPower = Config.JumpPower end
end

LP.CharacterAdded:Connect(function(char)
    task.wait(1)
    applySpeed()
    applyJump()
end)

RunService.Stepped:Connect(function()
    if not Config.Noclip then return end
    local char = LP.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end)

-- Fly
local flyBV, flyBG, flyConn
local function stopFly()
    Config.Fly = false
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
    if flyConn then flyConn:Disconnect() flyConn = nil end
    local hum = getHum()
    if hum then hum.PlatformStand = false end
end

local function startFly()
    local hrp = getHRP()
    local hum = getHum()
    if not hrp or not hum then return end
    Config.Fly = true
    hum.PlatformStand = true
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = hrp
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    flyBG.P = 1000
    flyBG.Parent = hrp
    flyConn = RunService.RenderStepped:Connect(function()
        if not Config.Fly or not flyBV or not hrp.Parent then return end
        local cam = Workspace.CurrentCamera
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0, 1, 0) end
        flyBV.Velocity = dir.Magnitude > 0 and dir.Unit * Config.FlySpeed or Vector3.zero
        flyBG.CFrame = cam.CFrame
    end)
end

-- Pulos
local jumpCount = 0

UserInputService.JumpRequest:Connect(function()
    local hrp = getHRP()
    local hum = getHum()
    if not hrp or not hum then return end

    if Config.InfiniteJump then
        task.wait()
        hrp.Velocity = Vector3.new(hrp.Velocity.X, Config.JumpPower, hrp.Velocity.Z)
    elseif Config.DoubleJump and hum.FloorMaterial == Enum.Material.Air then
        if jumpCount < 1 then
            jumpCount += 1
            hrp.Velocity = Vector3.new(hrp.Velocity.X, Config.JumpPower, hrp.Velocity.Z)
        end
    end
end)

LP.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        hum.StateChanged:Connect(function(_, new)
            if new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
                jumpCount = 0
            end
        end)
    end
end)

--==============================================================
--  CROSSHAIR
--==============================================================
local crossGui = Instance.new("ScreenGui")
crossGui.Name = "VeniceCrosshair"
crossGui.IgnoreGuiInset = true
crossGui.ResetOnSpawn = false
crossGui.Parent = game:GetService("CoreGui")

local crossLabel = Instance.new("ImageLabel")
crossLabel.BackgroundTransparency = 1
crossLabel.Size = UDim2.fromOffset(24, 24)
crossLabel.AnchorPoint = Vector2.new(0.5, 0.5)
crossLabel.Visible = false
crossLabel.Parent = crossGui

local spin = 0

RunService.RenderStepped:Connect(function(dt)
    local vp = Workspace.CurrentCamera.ViewportSize
    crossLabel.Size = UDim2.fromOffset(Config.CrosshairSize, Config.CrosshairSize)
    crossLabel.Position = UDim2.fromOffset(vp.X / 2, vp.Y / 2 + Config.CrosshairOffsetY)
    crossLabel.Image = "rbxassetid://" .. Config.CrosshairId
    crossLabel.Visible = Config.Crosshair
    if Config.CrosshairSpin then
        spin = (spin + dt * Config.CrosshairSpinSpeed) % 360
        crossLabel.Rotation = spin
    end
end)

--==============================================================
--  VIEWMODEL
--==============================================================
local vmConn
local function applyViewmodel()
    local char = LP.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    local handle = tool:FindFirstChild("Handle")
    if not handle then return end

    if Config.VMHide then
        handle.Transparency = 1
    else
        handle.Transparency = 0
    end

    if Config.VMEnabled then
        handle.Size = handle.Size * 0 + Vector3.new(Config.VMSize, Config.VMSize, Config.VMSize) * 1
        handle.Color = Config.VMColor
        handle.Material = Enum.Material[Config.VMMaterial] or Enum.Material.Metal
        if Config.VMTexture ~= "" then
            local mesh = handle:FindFirstChildOfClass("SpecialMesh")
            if not mesh then
                mesh = Instance.new("SpecialMesh")
                mesh.MeshType = Enum.MeshType.FileMesh
                mesh.Parent = handle
            end
            mesh.TextureId = "rbxassetid://" .. Config.VMTexture
        end
    end
end

vmConn = RunService.Heartbeat:Connect(function()
    if Config.VMEnabled or Config.VMHide then
        pcall(applyViewmodel)
    end
end)

--==============================================================
--  UI
--==============================================================
local ESPTab    = Window:CreateTab("ESP", 4483362458)
local PlayerTab = Window:CreateTab("Player", 4483362458)
local TPTab     = Window:CreateTab("Teleport", 4483362458)
local AimTab    = Window:CreateTab("Aim / FOV", 4483362458)
local VisTab    = Window:CreateTab("Visual", 4483362458)
local SetTab    = Window:CreateTab("Settings", 4483362458)

--=========================== ESP TAB ==========================
ESPTab:CreateSection("ESP PLAYERS")

local statusLabel = ESPTab:CreateLabel("Murder: —  |  Sheriff: —")
task.spawn(function()
    while true do
        local m = Roles.__murder and Roles.__murder.Name or "—"
        local s = Roles.__sheriff and Roles.__sheriff.Name or "—"
        pcall(function()
            statusLabel:Set(string.format("Murder: %s  |  Sheriff: %s", m, s))
        end)
        task.wait(1)
    end
end)

ESPTab:CreateToggle({
    Name = "ESP Ativado",
    CurrentValue = true,
    Flag = "espMaster",
    Callback = function(v) Config.ESPEnabled = v end,
})

ESPTab:CreateToggle({
    Name = "Inocentes (Verde)",
    CurrentValue = true,
    Callback = function(v) Config.ESPInnocent = v end,
})

ESPTab:CreateToggle({
    Name = "Sheriff (Azul)",
    CurrentValue = true,
    Callback = function(v) Config.ESPSheriff = v end,
})

ESPTab:CreateToggle({
    Name = "Murder (Vermelho)",
    CurrentValue = true,
    Callback = function(v) Config.ESPMurder = v end,
})

ESPTab:CreateSection("Estilo")

ESPTab:CreateToggle({
    Name = "Highlight",
    CurrentValue = true,
    Callback = function(v) Config.ESPHighlight = v end,
})

ESPTab:CreateToggle({
    Name = "ESP BOX",
    CurrentValue = false,
    Callback = function(v) Config.ESPBox = v end,
})

ESPTab:CreateToggle({
    Name = "ESP LINE",
    CurrentValue = false,
    Callback = function(v) Config.ESPLine = v end,
})

ESPTab:CreateToggle({
    Name = "ESP NAME",
    CurrentValue = false,
    Callback = function(v) Config.ESPName = v end,
})

ESPTab:CreateToggle({
    Name = "Limite de distância",
    CurrentValue = true,
    Callback = function(v) Config.ESPDistance = v end,
})

ESPTab:CreateSlider({
    Name = "Distância máxima",
    Range = { 50, 2000 },
    Increment = 50,
    Suffix = "m",
    CurrentValue = 600,
    Callback = function(v) Config.MaxDistance = v end,
})

--========================= PLAYER TAB =========================
PlayerTab:CreateSection("Movimento")

PlayerTab:CreateSlider({
    Name = "Speed",
    Range = { 16, 200 },
    Increment = 1,
    Suffix = "ws",
    CurrentValue = 32,
    Callback = function(v)
        Config.Speed = v
        applySpeed()
    end,
})

PlayerTab:CreateSlider({
    Name = "Força do pulo",
    Range = { 50, 250 },
    Increment = 1,
    CurrentValue = 60,
    Callback = function(v)
        Config.JumpPower = v
        applyJump()
    end,
})

PlayerTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(v) Config.Noclip = v end,
})

PlayerTab:CreateToggle({
    Name = "Pulo infinito",
    CurrentValue = false,
    Callback = function(v) Config.InfiniteJump = v end,
})

PlayerTab:CreateToggle({
    Name = "Pulo duplo",
    CurrentValue = false,
    Callback = function(v) Config.DoubleJump = v end,
})

PlayerTab:CreateSection("Fly")

PlayerTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Callback = function(v)
        if v then startFly() else stopFly() end
    end,
})

PlayerTab:CreateSlider({
    Name = "Velocidade do Fly",
    Range = { 10, 250 },
    Increment = 5,
    CurrentValue = 60,
    Callback = function(v) Config.FlySpeed = v end,
})

--========================== TP TAB ============================
local LobbyCF = CFrame.new(0, 25, 0)

local function tpTo(plr)
    local hrp = getHRP()
    local thrp = plr and getHRP(plr)
    if not hrp or not thrp then
        notify("Teleporte", "Alvo não encontrado.")
        return
    end
    hrp.CFrame = thrp.CFrame * CFrame.new(0, 0, 3)
    hrp.Velocity = Vector3.zero
end

TPTab:CreateSection("Partida")

TPTab:CreateButton({
    Name = "Teleportar para o Murder",
    Callback = function() tpTo(Roles.__murder) end,
})

TPTab:CreateButton({
    Name = "Teleportar para o Sheriff",
    Callback = function() tpTo(Roles.__sheriff) end,
})

TPTab:CreateButton({
    Name = "Teleportar para a partida",
    Callback = function()
        local alvo = Roles.__murder or Roles.__sheriff
        if not alvo then
            local lista = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and getHRP(p) then table.insert(lista, p) end
            end
            alvo = lista[math.random(1, math.max(#lista, 1))]
        end
        tpTo(alvo)
    end,
})

TPTab:CreateSection("Lobby")

TPTab:CreateButton({
    Name = "Teleportar para o Lobby",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end
        local lobby = Workspace:FindFirstChild("Lobby") or Workspace:FindFirstChild("SpawnLocation")
        if lobby and lobby:IsA("BasePart") then
            hrp.CFrame = lobby.CFrame * CFrame.new(0, 3, 0)
        else
            hrp.CFrame = LobbyCF
        end
        hrp.Velocity = Vector3.zero
    end,
})

TPTab:CreateInput({
    Name = "Definir posição do Lobby (X,Y,Z)",
    PlaceholderText = "0,25,0",
    RemoveTextAfterFocusLost = false,
    Callback = function(txt)
        local x, y, z = txt:match("(%-?%d+%.?%d*)%s*,%s*(%-?%d+%.?%d*)%s*,%s*(%-?%d+%.?%d*)")
        if x and y and z then
            LobbyCF = CFrame.new(tonumber(x), tonumber(y), tonumber(z))
            notify("Lobby", "Posição salva.")
        end
    end,
})

--========================= AIM / FOV TAB =======================
AimTab:CreateSection("Circle FOV")

AimTab:CreateToggle({
    Name = "Mostrar FOV",
    CurrentValue = false,
    Callback = function(v) Config.FOVEnabled = v end,
})

AimTab:CreateSlider({
    Name = "Tamanho do FOV",
    Range = { 30, 500 },
    Increment = 5,
    CurrentValue = 120,
    Callback = function(v) Config.FOVSize = v end,
})

AimTab:CreateColorPicker({
    Name = "Cor do FOV",
    Color = Color3.fromRGB(0, 150, 255),
    Callback = function(c) Config.FOVColor = c end,
})

AimTab:CreateToggle({
    Name = "Modo RGB",
    CurrentValue = false,
    Callback = function(v) Config.FOVRGB = v end,
})

AimTab:CreateSlider({
    Name = "Velocidade do RGB",
    Range = { 0.1, 5 },
    Increment = 0.1,
    CurrentValue = 1,
    Callback = function(v) Config.FOVRGBSpeed = v end,
})

AimTab:CreateSection("Headlock")

AimTab:CreateToggle({
    Name = "Headlock",
    CurrentValue = false,
    Callback = function(v) Config.Headlock = v end,
})

AimTab:CreateToggle({
    Name = "Só dentro do FOV",
    CurrentValue = true,
    Callback = function(v) Config.HeadlockInFOV = v end,
})

AimTab:CreateLabel("Sheriff trava na head do Murder. Murder trava na head do Sheriff. Inocente trava na head do Murder.")

--========================== VISUAL TAB =========================
VisTab:CreateSection("Viewmodel")

VisTab:CreateToggle({
    Name = "Aplicar alterações",
    CurrentValue = false,
    Callback = function(v) Config.VMEnabled = v end,
})

VisTab:CreateToggle({
    Name = "Esconder arma",
    CurrentValue = false,
    Callback = function(v) Config.VMHide = v end,
})

VisTab:CreateSlider({
    Name = "Tamanho",
    Range = { 0.5, 5 },
    Increment = 0.1,
    CurrentValue = 1,
    Callback = function(v) Config.VMSize = v end,
})

VisTab:CreateDropdown({
    Name = "Material",
    Options = { "Metal", "Plastic", "Neon", "ForceField", "Glass", "Wood" },
    CurrentOption = { "Metal" },
    Callback = function(opt) Config.VMMaterial = opt[1] end,
})

VisTab:CreateColorPicker({
    Name = "Cor",
    Color = Color3.fromRGB(200, 200, 200),
    Callback = function(c) Config.VMColor = c end,
})

VisTab:CreateInput({
    Name = "ID de textura",
    PlaceholderText = "123456789",
    RemoveTextAfterFocusLost = false,
    Callback = function(txt) Config.VMTexture = txt end,
})

VisTab:CreateSection("Crosshair (Overlay)")

VisTab:CreateToggle({
    Name = "Ativar crosshair",
    CurrentValue = false,
    Callback = function(v) Config.Crosshair = v end,
})

VisTab:CreateInput({
    Name = "ID da textura",
    PlaceholderText = "6031091004",
    CurrentValue = "6031091004",
    RemoveTextAfterFocusLost = false,
    Callback = function(txt) Config.CrosshairId = txt end,
})

VisTab:CreateSlider({
    Name = "Tamanho",
    Range = { 4, 128 },
    Increment = 1,
    CurrentValue = 24,
    Callback = function(v) Config.CrosshairSize = v end,
})

VisTab:CreateSlider({
    Name = "Offset vertical",
    Range = { -200, 200 },
    Increment = 1,
    CurrentValue = 0,
    Callback = function(v) Config.CrosshairOffsetY = v end,
})

VisTab:CreateToggle({
    Name = "Girar",
    CurrentValue = false,
    Callback = function(v) Config.CrosshairSpin = v end,
})

VisTab:CreateSlider({
    Name = "Velocidade do giro",
    Range = { 10, 720 },
    Increment = 10,
    CurrentValue = 90,
    Callback = function(v) Config.CrosshairSpinSpeed = v end,
})

--========================= SETTINGS TAB ========================
SetTab:CreateSection("Notificações")

SetTab:CreateToggle({
    Name = "Notificar ao achar Murder / Sheriff",
    CurrentValue = true,
    Callback = function(v) Config.Notifications = v end,
})

SetTab:CreateToggle({
    Name = "Limpar ESP do Murder quando surgir novo Sheriff",
    CurrentValue = true,
    Callback = function(v) Config.HideMurderOnNewSheriff = v end,
})

SetTab:CreateSection("Sistema")

SetTab:CreateButton({
    Name = "Forçar varredura de cargos",
    Callback = function()
        pcall(scanRoles)
        notify("Scan", "Varredura executada.")
    end,
})

SetTab:CreateButton({
    Name = "Resetar tudo",
    Callback = function()
        for p in pairs(ESPData) do removeESP(p) end
        Roles.__murder, Roles.__sheriff = nil, nil
        HideMurder = false
        stopFly()
        Config.Noclip = false
        notify("Reset", "Estado limpo.")
    end,
})

SetTab:CreateButton({
    Name = "Unload",
    Callback = function()
        for p in pairs(ESPData) do removeESP(p) end
        if FovCircle then FovCircle:Remove() end
        if crossGui then crossGui:Destroy() end
        stopFly()
        RunService:UnbindFromRenderStep("VeniceHeadlock")
        Sirius:Destroy()
    end,
})

notify("Venice Hub", "Script carregado. Abra o menu e configure.")