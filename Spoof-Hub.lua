local Build = loadstring(game:HttpGet("https://raw.githubusercontent.com/SpooferedGuy/UI-Library-Spoof/main/Ui-Library.lua"))()
local UI = Build({
    Title = "Spoof Hub, by SpooferedGuy",
    ScriptName = "SpoofHub - Blood Zone",
})

local CombatTab = UI.CreateTab("Combat⚔️")
local EspTab = UI.CreateTab("Esp👁️")
local PlayerTab = UI.CreateTab("Player👤")
local InstaTab = UI.CreateTab("Instant Badges🏅")
local FarmTab = UI.CreateTab("Farm⚡")



assert(typeof(hookmetamethod) == "function", "your executor doesnt support hookmetamethod")

local Workspace: Workspace? = game:GetService("Workspace")
if not Workspace then return end

local Players: Players? = game:GetService("Players")
if not Players then return end

local RunService: RunService? = game:GetService("RunService")
if not RunService then return end

local UserInputService = game:GetService("UserInputService")

local LocalPlayer: Player = Players.LocalPlayer
if not LocalPlayer then return end

local target: Instance? = nil

local config = {
    aimbot = false,
    aimbot360 = false,
    aimbotHead = false,
    aimbotHeadChance = 100,
    wallbang = false,
    autoshoot = false,
    espHighlight = false,
    espName = false,
    aimFov = false,
    aimFov = false,
    fovSize = 40,
    fovDistance = 5000,
    wallCheck = false,
} :: {
    aimbot: boolean,
    aimbot360: boolean,
    aimbotHead: boolean,
    aimbotHeadChance: number,
    wallbang: boolean,
    autoshoot: boolean,
    espHighlight: boolean,
    espName: boolean,
    aimFov: boolean,
    aimFov360: boolean,
    fovSize: number,
    fovDistance: number,
    wallCheck: boolean,
}

-- ==================== AIM FOV (Camera Lock) ====================
local Cam = Workspace.CurrentCamera
local maxTransparency = 0


local function updateFOVDrawing()
    if not FOVring then return end
    FOVring.Position = Cam.ViewportSize / 2
    FOVring.Radius = config.fovSize
    FOVring.Visible = config.aimFov
end

local function calculateTransparency(distance)
    local maxDistance = config.fovSize
    local transparency = (1 - (distance / maxDistance)) * maxTransparency
    return math.clamp(transparency, 0, 1)
end

-- Wall check para o AimFov (só mira em quem tá visível)
local function isVisibleForFov(targetPart: BasePart): boolean
    if not targetPart then return false end

    local character = LocalPlayer.Character
    if not character then return false end

    local targetCharacter = targetPart:FindFirstAncestorOfClass("Model")
    if not targetCharacter then return false end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character}
    params.IgnoreWater = true

    local origin = Cam.CFrame.Position
    local direction = targetPart.Position - origin

    local result = Workspace:Raycast(origin, direction, params)

    if not result then
        return true
    end

    return result.Instance:IsDescendantOf(targetCharacter)
end

-- Pega o jogador mais próximo dentro do Aim FOV.
-- Com Aim FOV 360° ativo, o alvo é escolhido em qualquer direção ao redor da câmera.
local function getClosestPlayerInFOV(): (Player?, number?)
    local nearest: Player? = nil
    local last: number = math.huge
    local playerMousePos = Cam.ViewportSize / 2
    local camPos = Cam.CFrame.Position

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    local part = character:FindFirstChild("Head")
                    if part and part:IsA("BasePart") then
                        if config.wallCheck and not isVisibleForFov(part) then
                            continue
                        end

                        if config.aimFov360 then
                            -- FOV 360°: não depende da posição do alvo na tela.
                            -- fovDistance funciona como raio em studs.
                            local distance3D = (part.Position - camPos).Magnitude
                            if distance3D < last and distance3D <= config.fovDistance then
                                last = distance3D
                                nearest = player
                            end
                        else
                            -- FOV normal: limita o alvo ao círculo na tela.
                            local ePos, isVisible = Cam:WorldToViewportPoint(part.Position)
                            local screenDistance =
                                (Vector2.new(ePos.X, ePos.Y) - playerMousePos).Magnitude

                            if screenDistance < last and isVisible and screenDistance < config.fovSize then
                                last = screenDistance
                                nearest = player
                            end
                        end
                    end
                end
            end
        end
    end

    return nearest, last
end

-- Trava a câmera no alvo
local function lookAt(targetPos: Vector3)
    local lookVector = (targetPos - Cam.CFrame.Position).Unit
    local newCFrame = CFrame.new(Cam.CFrame.Position, Cam.CFrame.Position + lookVector)
    Cam.CFrame = newCFrame
end
-- ==============================================================

-- ==================== ESP ====================
local ESP_FOLDER_NAME = "SpoofHub_ESP"

local function getEspFolder(): Folder
    local folder = Workspace:FindFirstChild(ESP_FOLDER_NAME)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = ESP_FOLDER_NAME
        folder.Parent = Workspace
    end
    return folder :: Folder
end

local function createHighlight(character: Model)
    local existing = character:FindFirstChild("SpoofHub_Highlight")
    if existing then
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "SpoofHub_Highlight"
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = 0.7
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = character
    highlight.Parent = character
end

local function createNameTag(character: Model)
    local head = character:FindFirstChild("Head")
    if not head or not head:IsA("BasePart") then
        return
    end

    if head:FindFirstChild("SpoofHub_NameTag") then
        return
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "SpoofHub_NameTag"
    billboard.Size = UDim2.new(0, 100, 0, 20)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = head

    local label = Instance.new("TextLabel")
    label.Name = "NameLabel"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = character.Name
    label.TextColor3 = Color3.fromRGB(255, 0, 0)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = billboard
end

local function removeEsp(character: Model)
    local highlight = character:FindFirstChild("SpoofHub_Highlight")
    if highlight then
        highlight:Destroy()
    end

    local head = character:FindFirstChild("Head")
    if head then
        local tag = head:FindFirstChild("SpoofHub_NameTag")
        if tag then
            tag:Destroy()
        end
    end
end

local function applyEsp(character: Model)
    if config.espHighlight then
        createHighlight(character)
    else
        local h = character:FindFirstChild("SpoofHub_Highlight")
        if h then h:Destroy() end
    end

    if config.espName then
        createNameTag(character)
    else
        local head = character:FindFirstChild("Head")
        if head then
            local tag = head:FindFirstChild("SpoofHub_NameTag")
            if tag then tag:Destroy() end
        end
    end
end

local function refreshAllEsp()
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then
            continue
        end
        local character = player.Character
        if character then
            applyEsp(character)
        end
    end
end

local function onCharacterAdded(character: Model)
    character:WaitForChild("Head", 5)
    task.wait(0.1)
    applyEsp(character)
end

local function onPlayerAdded(player: Player)
    if player == LocalPlayer then return end
    player.CharacterAdded:Connect(onCharacterAdded)
    if player.Character then
        onCharacterAdded(player.Character)
    end
end

local function onPlayerRemoving(player: Player)
    if player.Character then
        removeEsp(player.Character)
    end
end

for _, player in pairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

task.spawn(function()
    while task.wait(1) do
        if config.espHighlight or config.espName then
            refreshAllEsp()
        end
    end
end)
-- ==============================================

local function isVisible(targetPart: Instance?): boolean
    if not targetPart or not targetPart:IsA("BasePart") then
        return false
    end

    local camera = Workspace.CurrentCamera
    local character = LocalPlayer.Character

    if not camera or not character then
        return false
    end

    local targetCharacter = targetPart:FindFirstAncestorOfClass("Model")
    if not targetCharacter then
        return false
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character}
    params.IgnoreWater = true

    local origin = camera.CFrame.Position
    local direction = targetPart.Position - origin

    local result = Workspace:Raycast(origin, direction, params)

    if not result then
        return true
    end

    return result.Instance:IsDescendantOf(targetCharacter)
end

local function pickAimPart(character: Model): BasePart?
    local head = character:FindFirstChild("Head")
    local torso = character:FindFirstChild("Torso")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("LowerTorso")

    if not config.aimbotHead then
        if torso and torso:IsA("BasePart") then
            return torso
        elseif head and head:IsA("BasePart") then
            return head
        end
        return nil
    end

    local roll = math.random(1, 100)
    if roll <= config.aimbotHeadChance then
        if head and head:IsA("BasePart") then
            return head
        end
    end

    if torso and torso:IsA("BasePart") then
        return torso
    elseif head and head:IsA("BasePart") then
        return head
    end

    return nil
end

local function GetClosestPlayer(): Instance?
    local closestDistance: number = math.huge
    local closest: Instance? = nil

    local camera = Workspace.CurrentCamera
    if not camera then
        return nil
    end

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myPos = (myRoot and myRoot:IsA("BasePart")) and myRoot.Position or camera.CFrame.Position

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then
            continue
        end

        local character = player.Character
        if not character then
            continue
        end

        if character:GetAttribute("Immune") == true then
            continue
        end

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then
            continue
        end

        local root = character:FindFirstChild("HumanoidRootPart")
        if not root or not root:IsA("BasePart") then
            continue
        end

        local aimPart = pickAimPart(character)
        if not aimPart then
            aimPart = root
        end

        local distance

        if config.aimbot360 then
            -- MODO 360: ignora câmera, escolhe pelo mais próximo em studs (3D)
            distance = (aimPart.Position - myPos).Magnitude
        else
            -- MODO normal: só quem está na tela
            local screenPos, onScreen = camera:WorldToViewportPoint(root.Position)

            if not onScreen then
                continue
            end

            distance =
                (Vector2.new(screenPos.X, screenPos.Y) - camera.ViewportSize / 2).Magnitude
        end

        if distance >= closestDistance then
            continue
        end

        -- Wall check (opcional). Se wallbang off, precisa estar visível.
        if not config.wallbang and not isVisible(aimPart) then
            continue
        end

        closestDistance = distance
        closest = aimPart
    end

    return closest
end

-- ================= AUTO SHOOT =================
local VirtualUser = game:GetService("VirtualUser")

local function getEquippedTool(): Tool?
    local character = LocalPlayer.Character
    if not character then
        return nil
    end
    return character:FindFirstChildOfClass("Tool")
end

local function autoShoot()
    if not config.autoshoot then
        return
    end

    if not target then
        return
    end

    local tool = getEquippedTool()
    if tool then
        pcall(function()
            tool:Activate()
        end)
    end

    pcall(function()
        VirtualUser:Button1Down(Vector2.new(0, 0))
        task.wait(0.05)
        VirtualUser:Button1Up(Vector2.new(0, 0))
    end)
end
-- ==============================================

RunService.RenderStepped:Connect(function()
    -- AIMBOT (script original)
    if config.aimbot then
        target = GetClosestPlayer()
    else
        target = nil
    end

    -- AIM FOV (sistema separado - trava a câmera)
    updateFOVDrawing()

    if config.aimFov then
        local fovTarget, fovDistance = getClosestPlayerInFOV()

        if fovTarget and fovTarget.Character then
            local head = fovTarget.Character:FindFirstChild("Head")
            if head and head:IsA("BasePart") then
                lookAt(head.Position)

                if fovDistance then
                    if config.aimFov360 then
                        -- No modo 360°, a transparência do círculo não representa distância 3D.
                        FOVring.Transparency = maxTransparency
                    else
                        FOVring.Transparency = calculateTransparency(fovDistance)
                    end
                end
            end
        else
            FOVring.Transparency = 0.1
        end
    end
end)

task.spawn(function()
    while task.wait() do
        if config.autoshoot and target then
            autoShoot()
        end
    end
end)

local old = nil

local hookSuccess, err = pcall(function()
    old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local args = {...}

        if tostring(self) == "GunHit"
            and getnamecallmethod() == "FireServer" then

            if config.aimbot and target and typeof(target) == "Instance" then
                local targetPart = target :: BasePart

                if args[2]
                    and args[2][1]
                    and rawget(args[2][1], "Position")
                    and rawget(args[2][1], "Instance") then

                    rawset(args[2][1], "Position", targetPart.Position)
                    rawset(args[2][1], "Instance", targetPart)
                end
            end
        end

        return old(self, unpack(args))
    end))
end)

if not hookSuccess then
    return
end

-- ==================== TOGGLES ====================
EspTab.AddToggle("ESP Highlight", false, function(Value)
    config.espHighlight = Value
    if Value then
        refreshAllEsp()
    else
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character then
                local h = player.Character:FindFirstChild("SpoofHub_Highlight")
                if h then h:Destroy() end
            end
        end
    end
end)

EspTab.AddToggle("ESP Name", false, function(Value)
    config.espName = Value
    if Value then
        refreshAllEsp()
    else
        for _, player in pairs(Players:GetPlayers()) do
            local char = player.Character
            if char then
                local head = char:FindFirstChild("Head")
                if head then
                    local tag = head:FindFirstChild("SpoofHub_NameTag")
                    if tag then tag:Destroy() end
                end
            end
        end
    end
end)

CombatTab.AddToggle("Aimbot", false, function(Value)
    config.aimbot = Value
    if not Value then
        target = nil
    end
end)

CombatTab.AddToggle("Aimbot Head", false, function(Value)
    config.aimbotHead = Value
end)

CombatTab.AddSlider("Head Chance (%)", 0, 100, 100, function(Value)
    config.aimbotHeadChance = Value
end)

CombatTab.AddToggle("Aimbot 360", false, function(Value)
    config.aimbot360 = Value
end)

CombatTab.AddToggle("Wallbang", false, function(Value)
    config.wallbang = Value
end)

CombatTab.AddToggle("Auto Shoot", false, function(Value)
    config.autoshoot = Value
end)

-- ==================== AIM FOV TOGGLES ====================
CombatTab.AddToggle("Aim FOV", false, function(Value)
    config.aimFov = Value
    FOVring.Visible = Value
end)

CombatTab.AddToggle("Aim FOV 360", false, function(Value)
    config.aimFov360 = Value
    -- Não força mais o aimFov aqui
    FOVring.Visible = config.aimFov
end)

CombatTab.AddSlider("FOV Size", 10, 200, 40, function(Value)
    config.fovSize = Value
    FOVring.Radius = Value
end)

CombatTab.AddToggle("FOV Wall Check", false, function(Value)
    config.wallCheck = Value
end)
-- ==========================================================

local Workspace = game:GetService("Workspace")

-- ================= CONFIG =================
local pumpkinESPEnabled = false
local candyESPEnabled = false
local turkeyESPEnabled = false   -- NOVO

-- Pasta dos ESPs
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "PumpkinCandyESP"
ESPFolder.Parent = Workspace

-- ================= CRIAR ESP =================
local function createESP(part, color)
    if not part:IsA("BasePart") then
        return
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP"
    billboard.Adornee = part
    billboard.Size = UDim2.fromOffset(150, 35)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 500
    billboard.Parent = ESPFolder

    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundTransparency = 1
    text.Text = part.Name
    text.TextColor3 = color
    text.TextSize = 18
    text.Font = Enum.Font.GothamBold
    text.TextStrokeColor3 = Color3.new(0, 0, 0)
    text.TextStrokeTransparency = 0
    text.Parent = billboard
end

-- ================= ATUALIZAR ESP =================
local function updateESP()
    ESPFolder:ClearAllChildren()

    for _, object in ipairs(Workspace:GetDescendants()) do
        if object:IsA("BasePart") then

            -- Pumpkin
            if pumpkinESPEnabled and object.Name == "Pumpkin" then
                createESP(object, Color3.fromRGB(255, 140, 0))
            end

            -- Candy
            if candyESPEnabled and object.Name == "Candy" then
                createESP(object, Color3.fromRGB(255, 80, 200))
            end

            -- Turkey (RGB marrom) -- NOVO
            if turkeyESPEnabled and object.Name == "Turkey" then
                createESP(object, Color3.fromRGB(139, 69, 19))
            end
        end
    end
end

-- ================= TOGGLES =================
EspTab.AddToggle("ESP Pumpkin (halloween)", false, function(Value)
    pumpkinESPEnabled = Value
    updateESP()
end)

EspTab.AddToggle("ESP Candy (halloween)", false, function(Value)
    candyESPEnabled = Value
    updateESP()
end)

-- NOVO TOGGLE
EspTab.AddToggle("ESP Turkey (christmas)", false, function(Value)
    turkeyESPEnabled = Value
    updateESP()
end)

-- ================= ATUALIZAÇÃO =================
task.spawn(function()
    while task.wait(5) do
        if pumpkinESPEnabled or candyESPEnabled or turkeyESPEnabled then
            updateESP()
        end
    end
end)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

local function getRoot()
    local character = Player.Character or Player.CharacterAdded:Wait()
    return character:FindFirstChild("HumanoidRootPart")
end

-- Instant All Badges + Bugged + DemonDialog
InstaTab.AddButton("instant all badges", function()
    local root = getRoot()
    if not root then return end

    -- Teleportar todos os BadgeRegion
    for _, object in ipairs(Workspace:GetDescendants()) do
        if object:IsA("BasePart") and object.Name == "BadgeRegion" then
            object.CFrame = root.CFrame * CFrame.new(0, 0, -3)
        end
    end

    -- Ativar todos os ClickDetectors
    for _, object in ipairs(Workspace:GetDescendants()) do
        if object:IsA("ClickDetector") then
            fireclickdetector(object)
        end
    end

    -- Executar a função Bugged
    for _, object in ipairs(Workspace:GetDescendants()) do
        if object:IsA("BasePart") and object.Name == "OUT OF BOUNDS" then
            root.CFrame = object.CFrame * CFrame.new(0, 3, 0)
        end
    end

    -- Chamar DemonDialog
    ReplicatedStorage.Remotes.Requests.DemonDialog:FireServer()
end)

-- Train
InstaTab.AddButton("Train", function()
    local root = getRoot()
    if not root then return end

    for _, object in ipairs(Workspace:GetDescendants()) do
        if object:IsA("BasePart") and object.Name == "TrainOrecar" then
            root.CFrame = object.CFrame * CFrame.new(0, 3, 0)
        end
    end
end)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer

local function getRoot()
    local character = Player.Character or Player.CharacterAdded:Wait()
    return character:FindFirstChild("HumanoidRootPart")
end

local function collectLoop(objectName)
    local startTime = tick()

    while tick() - startTime < 3 do
        local root = getRoot()
        if not root then return end

        for _, object in ipairs(Workspace:GetDescendants()) do
            if tick() - startTime >= 3 then
                break
            end

            if object:IsA("BasePart") and object.Name == objectName then
                root.CFrame = object.CFrame
                task.wait()

                local prompt = object:FindFirstChildWhichIsA("ProximityPrompt", true)

                if prompt then
                    fireproximityprompt(prompt)
                end
            end
        end

        task.wait()
    end
end

InstaTab.AddButton("Pumpkin (halloween)", function()
    collectLoop("Pumpkin")
end)

InstaTab.AddButton("Candy (halloween)", function()
    collectLoop("Candy")
end)

InstaTab.AddButton("Turkey (christmas)", function()
    collectLoop("Turkey")
end)

local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local jumpBoostEnabled = false
local IMPULSE = 80

-- Input para definir a força
PlayerTab.AddInput("Jump Impulse", "80", function(Value)
    local number = tonumber(Value)

    if number then
        IMPULSE = number
    end
end)

-- Toggle para ativar/desativar
PlayerTab.AddToggle("Jump Boost", false, function(Value)
    jumpBoostEnabled = Value
end)

local function setupCharacter(character)
    local humanoid = character:WaitForChild("Humanoid")
    local rootPart = character:WaitForChild("HumanoidRootPart")

    humanoid.StateChanged:Connect(function(_, newState)
        if not jumpBoostEnabled then
            return
        end

        if newState == Enum.HumanoidStateType.Jumping then
            rootPart:ApplyImpulse(Vector3.new(
                0,
                rootPart.AssemblyMass * IMPULSE,
                0
            ))
        end
    end)
end

if Player.Character then
    setupCharacter(Player.Character)
end

Player.CharacterAdded:Connect(setupCharacter)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local SpeedConfig = {
    Enabled = false,
    Speed = 1
}

-- Slider da velocidade
PlayerTab.AddSlider("Speed input", 1, 40, 1, function(value)
    SpeedConfig.Speed = value
end)

-- Toggle
PlayerTab.AddToggle("Speed", false, function(value)
    SpeedConfig.Enabled = value
end)

local function setupCharacter(character)
    local humanoid = character:WaitForChild("Humanoid")
    local rootPart = character:WaitForChild("HumanoidRootPart")

    RunService.RenderStepped:Connect(function()
        if not SpeedConfig.Enabled then
            return
        end

        if not rootPart.Parent then
            return
        end

        local moveDirection = humanoid.MoveDirection

        if moveDirection.Magnitude > 0 then
            local currentVelocity = rootPart.AssemblyLinearVelocity

            rootPart.AssemblyLinearVelocity = Vector3.new(
                moveDirection.X * SpeedConfig.Speed,
                currentVelocity.Y,
                moveDirection.Z * SpeedConfig.Speed
            )
        end
    end)
end

if player.Character then
    setupCharacter(player.Character)
end

player.CharacterAdded:Connect(setupCharacter)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local modules = ReplicatedStorage:WaitForChild("Modules")
local localGunPath = modules:WaitForChild("Client"):WaitForChild("Game"):WaitForChild("WeaponClient"):WaitForChild("LocalWeapon"):WaitForChild("LocalGun")

local WallBangFovEnabled = false

-- Toggle
CombatTab.AddToggle("WallBang Fov", false, function(Value)
    WallBangFovEnabled = Value
end)

-- Aplica o hook uma única vez
local LG = require(localGunPath)

if LG and LG.__Operations then
    local ops = LG.__Operations

    if not ops._origProcessShot then
        ops._origProcessShot = ops.ProcessShot
    end

    ops.ProcessShot = function(self, origin, target, key)
        if not WallBangFovEnabled then
            return ops._origProcessShot(self, origin, target, key)
        end

        local newParams = RaycastParams.new()
        newParams.FilterType = Enum.RaycastFilterType.Include
        newParams.FilterDescendantsInstances = { workspace.Characters }
        newParams.CollisionGroup = "WeaponDetection"

        local oldParams = self.RayParams
        self.RayParams = newParams

        local result = ops._origProcessShot(self, origin, target, key)

        self.RayParams = oldParams
        return result
    end

    if not ops._origProcessProjectiles then
        ops._origProcessProjectiles = ops.ProcessProjectiles
    end

    ops.ProcessProjectiles = function(self, origin, target, key)
        if not WallBangFovEnabled then
            return ops._origProcessProjectiles(self, origin, target, key)
        end

        local newParams = RaycastParams.new()
        newParams.FilterType = Enum.RaycastFilterType.Include
        newParams.FilterDescendantsInstances = { workspace.Characters }
        newParams.CollisionGroup = "WeaponDetection"

        local oldProjParams = self.ProjectileParams

        if oldProjParams then
            local oldRaycast = oldProjParams.RaycastParams
            oldProjParams.RaycastParams = newParams

            local result = ops._origProcessProjectiles(self, origin, target, key)

            oldProjParams.RaycastParams = oldRaycast
            return result
        else
            return ops._origProcessProjectiles(self, origin, target, key)
        end
    end
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local flying = false
local speed = 35

local character
local humanoid
local root
local velocity
local attachment
local connection

--==================================================
-- CONFIGURAR PERSONAGEM
--==================================================

local function setupCharacter()
	character = player.Character or player.CharacterAdded:Wait()
	humanoid = character:WaitForChild("Humanoid")
	root = character:WaitForChild("HumanoidRootPart")
end

--==================================================
-- INICIAR FLY
--==================================================

local function startFly()
	setupCharacter()

	if velocity then velocity:Destroy() end
	if attachment then attachment:Destroy() end

	attachment = Instance.new("Attachment")
	attachment.Parent = root

	velocity = Instance.new("LinearVelocity")
	velocity.Attachment0 = attachment
	velocity.MaxForce = math.huge
	velocity.VectorVelocity = Vector3.zero
	velocity.Parent = root

	if connection then connection:Disconnect() end

	connection = RunService.RenderStepped:Connect(function()
		if not flying then return end
		if not character or not character.Parent then return end
		if not humanoid or not root then return end

		local moveDirection = humanoid.MoveDirection

		if moveDirection.Magnitude > 0 then
			local cameraLook = camera.CFrame.LookVector
			local direction = Vector3.new(cameraLook.X, cameraLook.Y, cameraLook.Z)

			if direction.Magnitude > 0 then
				direction = direction.Unit
				velocity.VectorVelocity = direction * speed
			end
		else
			velocity.VectorVelocity = Vector3.zero
		end
	end)
end

--==================================================
-- PARAR FLY
--==================================================

local function stopFly()
	if connection then
		connection:Disconnect()
		connection = nil
	end

	if velocity then
		velocity:Destroy()
		velocity = nil
	end

	if attachment then
		attachment:Destroy()
		attachment = nil
	end
end

--==================================================
-- QUANDO O PLAYER MORRER/RENASCER
--==================================================

player.CharacterAdded:Connect(function(newCharacter)
	stopFly()
	character = newCharacter
	task.wait(0.5)
	if flying then
		startFly()
	end
end)

--==================================================
-- TOGGLE
--==================================================

PlayerTab.AddToggle("Fly", false, function(Value)
	flying = Value
	if flying then
		startFly()
	else
		stopFly()
	end
end)

--==================================================
-- INSTANT RESPAWN
--==================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local instantRespawnAtivo = false
local respawnOriginal = nil

local function GetRespawnRemote()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then return nil end

    local requests = remotes:FindFirstChild("Requests")
    if not requests then return nil end

    return requests:FindFirstChild("DataChangeRequest")
end

local function LerRespawnAtual()
    local attr = LocalPlayer:GetAttribute("RespawnTime")
    if typeof(attr) == "number" then
        return attr
    end

    for _, obj in ipairs(LocalPlayer:GetDescendants()) do
        local a = obj:GetAttribute("RespawnTime")
        if typeof(a) == "number" then
            return a
        end
    end

    local candidates = {
        LocalPlayer:FindFirstChild("leaderstats"),
        LocalPlayer:FindFirstChild("PlayerGui"),
        ReplicatedStorage,
    }

    for _, container in ipairs(candidates) do
        if container then
            local val = container:FindFirstChild("RespawnTime", true)
            if val and (val:IsA("NumberValue") or val:IsA("IntValue")) then
                return val.Value
            end
        end
    end

    return Players.RespawnTime
end

local function SetRespawnTime(tempo)
    local remote = GetRespawnRemote()
    if not remote then
        return false
    end

    pcall(function()
        remote:InvokeServer("ChangeSetting", "RespawnTime", tempo)
    end)

    return true
end

PlayerTab.AddToggle("Instant Respawn", false, function(Value)
    instantRespawnAtivo = Value

    if Value then
        respawnOriginal = LerRespawnAtual()
        SetRespawnTime(0)
    else
        if respawnOriginal ~= nil then
            SetRespawnTime(respawnOriginal)
        else
            SetRespawnTime(Players.RespawnTime)
        end

        respawnOriginal = nil
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    if instantRespawnAtivo then
        task.wait(0.1)
        SetRespawnTime(0)
    end
end)

--// Credits to Remote Detector

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer   = Players.LocalPlayer
local StartRemote   = ReplicatedStorage.Remotes.Requests.StartBounty
local CancelRemote  = ReplicatedStorage.Remotes.Requests.CancelBounty

--// ================= CONFIG =================
local STUCK_TIME       = 10
local KILL_COOLDOWN    = 150       -- cooldown APÓS MATAR/COLETAR
local MOVE_THRESHOLD   = 3
local SWITCH_RETRY     = 0.8       -- espera entre tentativas de troca
local MAX_SWITCH_TRIES = 20        -- tentativas até desistir de achar o top
local KILL_STAT_NAMES  = {
    "Kills", "kills", "💥Kills", "💥kills", "💥 Kills", "💥 kills",
    "Kills💥", "Kill", "Koins", "BountyKills", "Eliminations"
}

--// ================= ESTADO =================
local TargetUserId     = nil
local TargetPlayer     = nil
local Billboard        = nil
local BountyAuto       = false
local LoopRunning      = false

local LastPosition     = nil
local StuckTimer       = 0
local CooldownUntil    = 0
local TargetConn       = nil
local CharConn         = nil
local Switching        = false     -- trava p/ evitar trocas simultâneas

--// ================= LEADERBOARD =================
local function getTopKillerUserId()
    local topUserId, topKills = nil, -1

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end  -- ignora você mesmo

        local containers = {}
        local ls = plr:FindFirstChild("leaderstats")
        if ls then table.insert(containers, ls) end
        for _, name in ipairs({"Leaderstats", "Stats", "PlayerStats"}) do
            local alt = plr:FindFirstChild(name)
            if alt then table.insert(containers, alt) end
        end

        for _, container in ipairs(containers) do
            for _, statName in ipairs(KILL_STAT_NAMES) do
                local stat = container:FindFirstChild(statName)
                if stat and (stat:IsA("IntValue") or stat:IsA("NumberValue") or stat:IsA("StringValue")) then
                    local val = tonumber(stat.Value) or 0
                    if val > topKills then
                        topKills = val
                        topUserId = plr.UserId
                    end
                    break
                end
            end
        end

        -- fallback por Attribute
        for _, attrName in ipairs(KILL_STAT_NAMES) do
            local v = plr:GetAttribute(attrName)
            if v and tonumber(v) then
                local val = tonumber(v)
                if val > topKills then
                    topKills = val
                    topUserId = plr.UserId
                end
            end
        end
    end

    return topUserId, topKills
end

--// ================= ESP =================
local function clearESP()
    if Billboard then Billboard:Destroy() Billboard = nil end
    if TargetConn then TargetConn:Disconnect() TargetConn = nil end
    if CharConn then CharConn:Disconnect() CharConn = nil end
    TargetPlayer = nil
end

local function createESP(player)
    clearESP()
    TargetPlayer = player
    if not player or not player.Character then return end

    local character = player.Character
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hrp then return end

    Billboard = Instance.new("BillboardGui")
    Billboard.Name = "BountyBillboard"
    Billboard.Size = UDim2.new(0, 220, 0, 50)
    Billboard.StudsOffset = Vector3.new(0, 4, 0)
    Billboard.AlwaysOnTop = true
    Billboard.LightInfluence = 0
    Billboard.MaxDistance = math.huge
    Billboard.Adornee = hrp
    Billboard.Parent = character

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "TARGET"
    lbl.TextColor3 = Color3.fromRGB(255, 0, 0)
    lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
    lbl.TextStrokeTransparency = 0
    lbl.TextScaled = true
    lbl.Font = Enum.Font.GothamBold
    lbl.Parent = Billboard

    LastPosition = hrp.Position
    StuckTimer   = 0

    if hum then
        TargetConn = hum.Died:Connect(function()
            onTargetKilled()
        end)
    end

    CharConn = player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if TargetPlayer == player and BountyAuto then
            createESP(player)
        end
    end)
end

--// ================= CANCELAR =================
local function cancelBounty()
    pcall(function() CancelRemote:InvokeServer() end)
end

--// ================= MORREU =================
function onTargetKilled()
    clearESP()
    TargetUserId = nil
    cancelBounty()
    CooldownUntil = tick() + KILL_COOLDOWN   -- cooldown REAL só aqui
end

--// ================= IDENTIFICAR =================
local function identifyTarget(userId)
    userId = tonumber(userId)
    if not userId then return end
    TargetUserId = userId

    local found = Players:GetPlayerByUserId(userId)
    if found then
        createESP(found)
    else
        local conn
        conn = Players.PlayerAdded:Connect(function(plr)
            if plr.UserId == userId then
                task.wait(1)
                if BountyAuto then createESP(plr) end
                conn:Disconnect()
            end
        end)
        task.delay(300, function() if conn then conn:Disconnect() end end)
    end
end

--// ================= PEGAR BOUNTY (com flag ignoreCooldown) =================
local function tryStartBounty(ignoreCooldown)
    if not ignoreCooldown and tick() < CooldownUntil then
        return false
    end

    local ok, result = pcall(function()
        return StartRemote:InvokeServer()
    end)
    if not ok then return false end

    local userId
    if typeof(result) == "number" or typeof(result) == "string" then
        userId = result
    elseif typeof(result) == "table" then
        userId = result.UserId or result.userId or result.TargetId or result.targetId
    end

    if userId then
        return tonumber(userId)
    end
    return false
end

--// ================= TROCAR ATÉ ACHAR O TOP =================
local function switchUntilTop()
    if Switching then return end
    Switching = true

    task.spawn(function()
        local topUserId = getTopKillerUserId()

        -- Se não temos como saber quem é o top, só pega 1 aleatório
        if not topUserId then
            clearESP()
            cancelBounty()
            task.wait(SWITCH_RETRY)
            local uid = tryStartBounty(true)
            if uid then identifyTarget(uid) end
            Switching = false
            return
        end

        -- Loop de tentativas até achar o top
        for i = 1, MAX_SWITCH_TRIES do
            if not BountyAuto then break end

            -- Já está no top? Para.
            if TargetUserId == topUserId and TargetPlayer and TargetPlayer.Character then
                createESP(TargetPlayer)
                Switching = false
                return
            end

            -- Cancela o atual
            clearESP()
            TargetUserId = nil
            cancelBounty()
            task.wait(SWITCH_RETRY)

            -- Tenta pegar de novo
            local uid = tryStartBounty(true)
            if uid then
                if uid == topUserId then
                    identifyTarget(uid)
                    Switching = false
                    return
                else
                    -- Não é o top ainda → continua tentando
                    identifyTarget(uid)
                    task.wait(SWITCH_RETRY)
                end
            else
                task.wait(SWITCH_RETRY)
            end

            -- Atualiza quem é o top (pode ter mudado)
            topUserId = getTopKillerUserId() or topUserId
        end

        Switching = false
    end)
end

--// ================= LOOP =================
local function startLoop()
    if LoopRunning then return end
    LoopRunning = true

    task.spawn(function()
        while BountyAuto do
            -- Cooldown pós-kill ativo? espera
            if tick() < CooldownUntil then
                task.wait(1)
                continue
            end

            local topUserId = getTopKillerUserId()

            -- Sem alvo? tenta pegar
            if not TargetPlayer or not TargetPlayer.Character then
                switchUntilTop()
                task.wait(1)
                continue
            end

            -- Alvo atual não é o top → troca até achar
            if topUserId and TargetUserId and TargetUserId ~= topUserId then
                switchUntilTop()
                task.wait(1)
                continue
            end

            -- Alvo é o top (ou não temos ranking) → monitora stuck
            local hrp = TargetPlayer.Character:FindFirstChild("HumanoidRootPart")
            local hum = TargetPlayer.Character:FindFirstChildOfClass("Humanoid")

            if hrp and hum and hum.Health > 0 then
                if LastPosition then
                    local moved = (hrp.Position - LastPosition).Magnitude
                    if moved < MOVE_THRESHOLD then
                        StuckTimer = StuckTimer + 1
                    else
                        StuckTimer = 0
                    end
                end
                LastPosition = hrp.Position

                if StuckTimer >= STUCK_TIME then
                    StuckTimer = 0
                    switchUntilTop()
                end
            end

            task.wait(1)
        end
        LoopRunning = false
    end)
end

--// ================= EXECUÇÃO INICIAL =================
if BountyAuto then switchUntilTop() end

--// ================= TOGGLE =================
FarmTab.AddToggle("Auto Bounty", false, function(Value)
    BountyAuto = Value
    if Value then
        startLoop()
        switchUntilTop()
    else
        clearESP()
        TargetUserId = nil
        cancelBounty()
    end
end)

-- ==================== KILL ESP TARGET (isolado) ====================
local KillEspTargetEnabled = false
local EspTargetKillLoop = nil

-- Encontra o Player que está com o billboard "TARGET" (BountyBillboard)
local function getEspTargetPlayer()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        local character = player.Character
        if not character then continue end

        -- Procura o billboard do Auto Bounty
        local billboard = character:FindFirstChild("BountyBillboard")
        if billboard and billboard:IsA("BillboardGui") then
            return player
        end
    end
    return nil
end

-- Pega a cabeça do alvo
local function getEspTargetHead(player)
    if not player or not player.Character then return nil end

    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return nil end

    local head = player.Character:FindFirstChild("Head")
    if head and head:IsA("BasePart") then
        return head
    end
    return nil
end

-- Mira a câmera na cabeça do alvo
local function lookAtPosition(pos)
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local lookVector = (pos - cam.CFrame.Position).Unit
    cam.CFrame = CFrame.new(cam.CFrame.Position, cam.CFrame.Position + lookVector)
end

-- Atira (mesma lógica do autoshoot original)
local function shootOnce()
    local character = LocalPlayer.Character
    if not character then return end

    local tool = character:FindFirstChildOfClass("Tool")
    if tool then
        pcall(function() tool:Activate() end)
    end

    pcall(function()
        VirtualUser:Button1Down(Vector2.new(0, 0))
        task.wait(0.05)
        VirtualUser:Button1Up(Vector2.new(0, 0))
    end)
end

-- Hook temporário no GunHit só enquanto o toggle está ligado
local EspKillHookOld = nil
local EspKillHookActive = false
local EspKillCurrentHead = nil

local function installEspKillHook()
    if EspKillHookActive then return end

    EspKillHookActive = true
    EspKillHookOld = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local args = {...}

        if tostring(self) == "GunHit"
            and getnamecallmethod() == "FireServer"
            and KillEspTargetEnabled
            and EspKillCurrentHead then

            if args[2] and args[2][1]
                and rawget(args[2][1], "Position")
                and rawget(args[2][1], "Instance") then

                rawset(args[2][1], "Position", EspKillCurrentHead.Position)
                rawset(args[2][1], "Instance", EspKillCurrentHead)
            end
        end

        return EspKillHookOld(self, unpack(args))
    end))
end

-- Loop principal
local function startEspKillLoop()
    if EspTargetKillLoop then return end

    EspTargetKillLoop = task.spawn(function()
        while KillEspTargetEnabled do
            local targetPlayer = getEspTargetPlayer()
            local head = getEspTargetHead(targetPlayer)

            if head then
                EspKillCurrentHead = head

                -- Trava câmera na cabeça (aimbot 360° = não depende da tela)
                lookAtPosition(head.Position)

                -- Dispara
                shootOnce()
            else
                EspKillCurrentHead = nil
            end

            task.wait(0.05)
        end

        EspKillCurrentHead = nil
        EspTargetKillLoop = nil
    end)
end

-- ==================== TOGGLE ====================
FarmTab.AddToggle("Kill bounty Target", false, function(Value)
    KillEspTargetEnabled = Value

    if Value then
        installEspKillHook()
        startEspKillLoop()
    else
        EspKillCurrentHead = nil
        -- Hook fica instalado, mas desativado pela flag KillEspTargetEnabled
    end
end)

-- ==================== SKIP TARGET (FarmTab) ====================
FarmTab.AddButton("Skip Target", function()
    -- Verifica se o Auto Bounty está ativo
    if not BountyAuto then
        warn("[SpoofHub] Ative o 'Auto Bounty' primeiro para poder pular alvo!")
        return
    end

    -- Limpa ESP atual
    if clearESP then
        clearESP()
    end

    -- Reseta o TargetUserId
    TargetUserId = nil

    -- Cancela o bounty atual
    if cancelBounty then
        cancelBounty()
    end

    -- Espera um pouco antes de pegar o próximo (evita spam no servidor)
    task.wait(0.5)

    -- Pega um novo alvo
    if switchUntilTop then
        switchUntilTop()
    end
end)

-- ==================== TARGET PLAYER (FarmTab) ====================
local TargetPlayerName = nil
local TargetPlayerKill = false
local OriginalConfig = nil

-- Input para definir o nome do jogador alvo
FarmTab.AddInput("Target Player Name", "", function(Value)
    if Value and Value ~= "" then
        TargetPlayerName = Value
    else
        TargetPlayerName = nil
    end
end)

-- Função para encontrar o jogador pelo nome
local function findTargetPlayerByName(name)
    if not name or name == "" then return nil end
    
    name = name:lower()
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            -- Verifica nome exato ou DisplayName
            if player.Name:lower() == name 
            or player.DisplayName:lower() == name 
            or player.Name:lower():find(name, 1, true) then
                return player
            end
        end
    end
    
    return nil
end

-- Função para forçar mira no alvo específico
local function getTargetPlayerAimPart()
    if not TargetPlayerName then return nil end
    
    local player = findTargetPlayerByName(TargetPlayerName)
    if not player then return nil end
    
    local character = player.Character
    if not character then return nil end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return nil end
    
    local head = character:FindFirstChild("Head")
    if head and head:IsA("BasePart") then
        return head  -- Sempre mira na cabeça
    end
    
    return nil
end

-- Salva configs originais
local function saveOriginalConfig()
    OriginalConfig = {
        aimbot = config.aimbot,
        aimbot360 = config.aimbot360,
        aimbotHead = config.aimbotHead,
        aimbotHeadChance = config.aimbotHeadChance,
        wallbang = config.wallbang,
        autoshoot = config.autoshoot,
    }
end

-- Restaura configs originais
local function restoreOriginalConfig()
    if OriginalConfig then
        config.aimbot = OriginalConfig.aimbot
        config.aimbot360 = OriginalConfig.aimbot360
        config.aimbotHead = OriginalConfig.aimbotHead
        config.aimbotHeadChance = OriginalConfig.aimbotHeadChance
        config.wallbang = OriginalConfig.wallbang
        config.autoshoot = OriginalConfig.autoshoot
        OriginalConfig = nil
    end
end

-- Toggle principal
FarmTab.AddToggle("Kill Target Player", false, function(Value)
    TargetPlayerKill = Value
    
    if Value then
        if not TargetPlayerName or TargetPlayerName == "" then
            -- Se não tem nome definido, avisa e desativa
            warn("[SpoofHub] Defina um nome de jogador no input 'Target Player Name' primeiro!")
            return
        end
        
        -- Salva configurações originais
        saveOriginalConfig()
        
        -- Força configurações específicas
        config.aimbot = true
        config.aimbot360 = true
        config.aimbotHead = true
        config.aimbotHeadChance = 100  -- 100% headshot
        config.wallbang = true
        config.autoshoot = true
        
    else
        -- Restaura configurações originais
        restoreOriginalConfig()
        target = nil
    end
end)

-- Hook no GetClosestPlayer para forçar o alvo específico quando o toggle estiver ativo
local OriginalGetClosestPlayer = GetClosestPlayer

GetClosestPlayer = function(): Instance?
    if TargetPlayerKill and TargetPlayerName then
        local forcedPart = getTargetPlayerAimPart()
        if forcedPart then
            return forcedPart
        end
        -- Se o alvo não estiver disponível, retorna nil (não mira em mais ninguém)
        return nil
    end
    
    -- Comportamento original
    return OriginalGetClosestPlayer()
end

-- ==================== AUTO EQUIP WEAPON (Mobile Safe) ====================
local autoEquipEnabled = false

-- Verifica se o player está com alguma Tool equipada
local function hasToolEquipped(): boolean
    local character = LocalPlayer.Character
    if not character then return false end
    return character:FindFirstChildOfClass("Tool") ~= nil
end

-- Equipa a primeira Tool disponível (Character ou Backpack)
local function equipFirstTool()
    local character = LocalPlayer.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    -- 1) Se já tiver Tool no Backpack, equipa
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack then
        local tool = backpack:FindFirstChildOfClass("Tool")
        if tool then
            humanoid:EquipTool(tool)
            return
        end
    end

    -- 2) Fallback: procura Tools em qualquer lugar do player
    for _, obj in ipairs(LocalPlayer:GetDescendants()) do
        if obj:IsA("Tool") and obj.Parent ~= character then
            humanoid:EquipTool(obj)
            return
        end
    end
end

-- Loop de auto equip
task.spawn(function()
    while task.wait(0.5) do
        if autoEquipEnabled and not hasToolEquipped() then
            equipFirstTool()
        end
    end
end)

-- Toggle
FarmTab.AddToggle("Auto Equip Weapon", false, function(Value)
    autoEquipEnabled = Value
    if Value then
        if not hasToolEquipped() then
            equipFirstTool()
        end
    end
end)
