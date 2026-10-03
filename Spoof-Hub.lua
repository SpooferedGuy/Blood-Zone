local Build = loadstring(game:HttpGet("https://raw.githubusercontent.com/SpooferedGuy/UI-Library-Spoof/main/Ui-Library.lua"))()
local UI = Build({
    Title = "Spoof Hub, by SpooferedGuy",
    ScriptName = "SpoofHub - Blood Zone",
})

local CombatTab = UI.CreateTab("Combat⚔️")
local EspTab = UI.CreateTab("Esp👁️")

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
    aimbotHead = false,
    aimbotHeadChance = 100,
    wallbang = false,
    autoshoot = false,
    espHighlight = false,
    espName = false,
    aimFov = false,
    fovSize = 40,
    wallCheck = false,
} :: {
    aimbot: boolean,
    aimbotHead: boolean,
    aimbotHeadChance: number,
    wallbang: boolean,
    autoshoot: boolean,
    espHighlight: boolean,
    espName: boolean,
    aimFov: boolean,
    fovSize: number,
    wallCheck: boolean,
}

-- ==================== AIM FOV (Camera Lock) ====================
local Cam = Workspace.CurrentCamera
local maxTransparency = 0.1

local FOVring = Drawing.new("Circle")
FOVring.Visible = false
FOVring.Thickness = 2
FOVring.Color = Color3.fromRGB(128, 0, 128)
FOVring.Filled = false
FOVring.Radius = config.fovSize
FOVring.Position = Cam.ViewportSize / 2
FOVring.Transparency = 0

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

-- Pega o jogador mais próximo dentro do FOV
local function getClosestPlayerInFOV(): (Player?, number?)
    local nearest: Player? = nil
    local last: number = math.huge
    local playerMousePos = Cam.ViewportSize / 2

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    local part = character:FindFirstChild("Head")
                    if part and part:IsA("BasePart") then
                        -- Wall check
                        if config.wallCheck and not isVisibleForFov(part) then
                            continue
                        end

                        local ePos, isVisible = Cam:WorldToViewportPoint(part.Position)
                        local distance = (Vector2.new(ePos.X, ePos.Y) - playerMousePos).Magnitude

                        if distance < last and isVisible and distance < config.fovSize then
                            last = distance
                            nearest = player
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

        local screenPos, onScreen = camera:WorldToViewportPoint(root.Position)

        if not onScreen then
            continue
        end

        local distance =
            (Vector2.new(screenPos.X, screenPos.Y) - camera.ViewportSize / 2).Magnitude

        if distance >= closestDistance then
            continue
        end

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
                    FOVring.Transparency = calculateTransparency(fovDistance)
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

CombatTab.AddSlider("FOV Size", 10, 200, 40, function(Value)
    config.fovSize = Value
    FOVring.Radius = Value
end)

CombatTab.AddToggle("FOV Wall Check", false, function(Value)
    config.wallCheck = Value
end)
-- ==========================================================