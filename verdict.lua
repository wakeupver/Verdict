
-- Cleanup
if _G.VerdictObsidianUI then
    local prev = _G.VerdictObsidianUI
    if type(prev.Unload) == "function" then
        pcall(function() prev:Unload() end)
    end
    _G.VerdictObsidianUI = nil
end

-- Services
local Services = {
    Players    = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UIS        = game:GetService("UserInputService"),
    Lighting   = game:GetService("Lighting"),
    Workspace  = game:GetService("Workspace"),
}

local LocalPlayer = Services.Players.LocalPlayer
local Camera = Services.Workspace.CurrentCamera
local Connections = {}

-- Flag & State
local Flags = {
    -- Aimbot
    aimbot = false,
    aimbotFOV = 120,
    aimbotSmoothness = 0.15,
    aimbotLockPart = "Head",
    aimbotTeamCheck = false,
    aimbotAliveCheck = true,
    prediction = 0.12,
    
    -- Visuals
    showFOV = false,
    fovColor = Color3.fromRGB(255, 255, 255),
    fovThickness = 2,
    
    -- Player
    noclip = false,
    noCollision = false,
    infiniteJump = false,
    
    -- Camera
    smoothCam = false,
    sensitivity = 1.0,
    clickTp = false,
    
    -- Misc
    boostMode = "Lite",
}

local State = {
    savedSlots = {},
    originalLighting = {},
    originalCap = 60,
    fovCircle = nil,
    freeCam = nil,
}

-- Helper
local function safeCall(fn, ...)
    return pcall(fn, ...)
end

local function safeDisconnect(conn)
    if conn then pcall(function() conn:Disconnect() end) end
end

local function setConnection(key, conn)
    if not key then return end
    if Connections[key] then safeDisconnect(Connections[key]) end
    Connections[key] = conn
end

local function disconnectKey(key)
    if Connections[key] then
        safeDisconnect(Connections[key])
        Connections[key] = nil
    end
end

local function clearAllConnections()
    for k, v in pairs(Connections) do
        safeDisconnect(v)
        Connections[k] = nil
    end
end

local function clamp(x, a, b)
    return math.max(a, math.min(b, x))
end

-- Character Utilities
local CharUtils = {}

function CharUtils.getChar(plr, waitFor)
    plr = plr or LocalPlayer
    if not plr then return nil end
    if plr.Character then return plr.Character end
    if waitFor and plr.CharacterAdded then return plr.CharacterAdded:Wait() end
    return nil
end

function CharUtils.getHum(plr, waitFor)
    local char = CharUtils.getChar(plr, waitFor)
    return char and char:FindFirstChildOfClass("Humanoid")
end

function CharUtils.getHRP(plr, waitFor)
    local char = CharUtils.getChar(plr, waitFor)
    return char and char:FindFirstChild("HumanoidRootPart")
end

function CharUtils.isAlive(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

function CharUtils.teleportTo(cf)
    local hrp = CharUtils.getHRP(nil, false)
    if hrp and cf then hrp.CFrame = cf end
end

function CharUtils.getVelocity(part)
    if not part then return Vector3.new(0, 0, 0) end
    local ok, vel = pcall(function()
        return part.AssemblyLinearVelocity or part.Velocity or Vector3.new(0, 0, 0)
    end)
    return (ok and vel) or Vector3.new(0, 0, 0)
end

-- Position & Resolution
local function resolveTargetPosition(char, preferredPart)
    if not char then return nil end
    
    -- Try preferred part
    if preferredPart and type(preferredPart) == "string" then
        local p = char:FindFirstChild(preferredPart)
        if p and p:IsA("BasePart") then return p.Position, p end
    end
    
    -- Priority list
    local priorities = { "Head", "UpperTorso", "Torso", "HumanoidRootPart", "LowerTorso" }
    for _, name in ipairs(priorities) do
        local p = char:FindFirstChild(name)
        if p and p:IsA("BasePart") then return p.Position, p end
    end
    
    -- Primary part
    if char.PrimaryPart and char.PrimaryPart:IsA("BasePart") then
        return char.PrimaryPart.Position, char.PrimaryPart
    end
    
    -- Bounding box fallback
    local ok, cf = pcall(function() return char:GetBoundingBox() end)
    if ok and cf then return cf.Position, nil end
    
    return nil
end

-- Aimbot Module
local AimbotModule = {}

function AimbotModule.getClosestTarget()
    local cam = Services.Workspace.CurrentCamera or Camera
    if not cam then return nil end
    
    local vpSize = cam.ViewportSize
    local screenCenter = Vector2.new(vpSize.X * 0.5, vpSize.Y * 0.5)
    local fov = Flags.aimbotFOV or 120
    local shortest = fov
    local best = nil
    
    for _, plr in ipairs(Services.Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            if not (Flags.aimbotTeamCheck and LocalPlayer and plr.Team == LocalPlayer.Team) then
                local char = plr.Character
                if char and (not Flags.aimbotAliveCheck or CharUtils.isAlive(char)) then
                    local pos, part = resolveTargetPosition(char, Flags.aimbotLockPart)
                    if pos then
                        local screenPos, onScreen = cam:WorldToViewportPoint(pos)
                        if onScreen then
                            local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                            if dist < shortest then
                                shortest = dist
                                best = { player = plr, position = pos, part = part }
                            end
                        end
                    end
                end
            end
        end
    end
    
    return best
end

function AimbotModule.predictPosition(part)
    if not part then return nil end
    local pos = part.Position
    local vel = CharUtils.getVelocity(part)
    return pos + vel * (Flags.prediction or 0.12)
end

-- Lighting Module
local LightingModule = {}

function LightingModule.save()
    State.originalLighting = {
        Brightness = Services.Lighting.Brightness,
        ClockTime = Services.Lighting.ClockTime,
        FogEnd = Services.Lighting.FogEnd,
        GlobalShadows = Services.Lighting.GlobalShadows,
        Ambient = Services.Lighting.Ambient,
    }
end

function LightingModule.restore()
    for k, v in pairs(State.originalLighting) do
        pcall(function() Services.Lighting[k] = v end)
    end
    for _, eff in ipairs(Services.Lighting:GetChildren()) do
        if eff:IsA("PostEffect") then
            pcall(function() eff.Enabled = true end)
        end
    end
end

function LightingModule.fullbright()
    LightingModule.save()
    Services.Lighting.Brightness = 2
    Services.Lighting.ClockTime = 14
    Services.Lighting.FogEnd = 1e9
    Services.Lighting.GlobalShadows = false
    Services.Lighting.Ambient = Color3.new(1, 1, 1)
end

-- FPS Cap Utillities
local FPSModule = {}

function FPSModule.isSupported()
    return typeof(setfpscap) == "function"
        or typeof(set_fps_cap) == "function"
        or (syn and typeof(syn.set_fps_cap) == "function")
end

function FPSModule.setCap(n)
    if typeof(setfpscap) == "function" then
        setfpscap(n)
    elseif typeof(set_fps_cap) == "function" then
        set_fps_cap(n)
    elseif syn and typeof(syn.set_fps_cap) == "function" then
        syn.set_fps_cap(n)
    end
end

function FPSModule.getCap()
    if typeof(getfpscap) == "function" then
        return getfpscap()
    elseif typeof(get_fps_cap) == "function" then
        return get_fps_cap()
    elseif syn and typeof(syn.get_fps_cap) == "function" then
        return syn.get_fps_cap()
    end
    return 60
end

-- Cache original cap
if FPSModule.isSupported() then
    State.originalCap = FPSModule.getCap()
end

-- Graphic Boost Module
local BoostModule = {}

local ClassLookup = {
    disableEnabled = {
        ParticleEmitter = true, Trail = true, Smoke = true,
        Fire = true, Beam = true, Highlight = true,
    },
    lights = {
        PointLight = true, SpotLight = true, SurfaceLight = true,
    },
    textures = {
        Decal = true, Texture = true,
    },
    parts = {
        BasePart = true, UnionOperation = true, MeshPart = true,
    },
}

local function optimizeLite(obj)
    local class = obj.ClassName
    if ClassLookup.disableEnabled[class] or ClassLookup.lights[class] then
        pcall(function() obj.Enabled = false end)
    end
end

local function optimizeBalanced(obj)
    optimizeLite(obj)
    local class = obj.ClassName
    if ClassLookup.textures[class] then
        pcall(function() obj.Transparency = 1 end)
    elseif ClassLookup.parts[class] then
        pcall(function()
            obj.Material = Enum.Material.Plastic
            obj.Reflectance = 0
        end)
    end
end

function BoostModule.apply(mode)
    mode = mode or "Lite"
    LightingModule.save()
    
    -- Disable post effects
    for _, eff in ipairs(Services.Lighting:GetChildren()) do
        if eff:IsA("PostEffect") then
            pcall(function() eff.Enabled = false end)
        end
    end
    
    local walker = (mode == "Lite" and optimizeLite) or optimizeBalanced
    
    -- Optimize existing objects
    for _, o in ipairs(Services.Workspace:GetDescendants()) do
        pcall(function() walker(o) end)
    end
    
    -- Watch new objects
    setConnection("boostWatcher", Services.Workspace.DescendantAdded:Connect(function(o)
        pcall(function() walker(o) end)
    end))
    
    -- Ultra mode enhancements
    if mode == "Ultra" then
        pcall(function()
            Services.Lighting.GlobalShadows = false
            Services.Lighting.Brightness = 1
            Services.Lighting.FogEnd = 1e9
            Services.Lighting.Ambient = Color3.new(1, 1, 1)
            Services.Workspace.StreamingEnabled = true
            Services.Workspace.StreamingMinRadius = 64
        end)
    end
end

function BoostModule.restore()
    disconnectKey("boostWatcher")
    LightingModule.restore()
end

-- Drawing FOV Module
local DrawingModule = {}
local DrawingLib = nil
pcall(function() DrawingLib = Drawing or drawing end)

function DrawingModule.createFOV()
    if not DrawingLib then return end
    DrawingModule.destroyFOV()
    
    pcall(function()
        State.fovCircle = DrawingLib.new("Circle")
        State.fovCircle.Visible = false
        State.fovCircle.Color = Flags.fovColor
        State.fovCircle.Thickness = Flags.fovThickness
        State.fovCircle.NumSides = 64
        State.fovCircle.Filled = false
        State.fovCircle.Radius = Flags.aimbotFOV
        State.fovCircle.Position = Vector2.new(0, 0)
    end)
end

function DrawingModule.destroyFOV()
    if State.fovCircle then
        pcall(function() State.fovCircle:Remove() end)
        State.fovCircle = nil
    end
end

function DrawingModule.updateFOV()
    if not State.fovCircle then return end
    local cam = Services.Workspace.CurrentCamera or Camera
    if not cam then return end
    
    local vp = cam.ViewportSize
    local center = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
    
    pcall(function()
        State.fovCircle.Visible = true
        State.fovCircle.Position = center
        State.fovCircle.Radius = Flags.aimbotFOV
        State.fovCircle.Color = Flags.fovColor
        State.fovCircle.Thickness = Flags.fovThickness
    end)
end

-- UI Init
local function initializeUI()
    local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
    local Library, ThemeManager, SaveManager
    
    local ok, lib = pcall(function()
        return loadstring(game:HttpGet(repo .. "Library.lua"))()
    end)
    
    if not (ok and type(lib) == "table") then
        error("Unable to load Obsidian UI library.")
    end
    
    Library = lib
    pcall(function() ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))() end)
    pcall(function() SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))() end)
    
    -- Create main window
    local Window = Library:CreateWindow({
        Title = "Verdict",
        Footer = "Optimized & Lightweight ♡",
        Icon = 95816097006870,
        NotifySide = "Right",
        ShowCustomCursor = true,
    })
    
    -- Create tabs
    local Tabs = {
        Main = Window:AddTab("Main", "user"),
        Combat = Window:AddTab("Combat", "crosshair"),
        Teleport = Window:AddTab("Teleport", "map"),
        Misc = Window:AddTab("Misc", "eye"),
        UISettings = Window:AddTab("UI Settings", "settings"),
    }
    
    -- Main Tab
    
    local PlayerBox = Tabs.Main:AddLeftGroupbox("Player", "boxes")
    
    PlayerBox:AddToggle("NoClip", {
        Text = "No Clip",
        Default = false,
        Callback = function(v)
            Flags.noclip = v
            disconnectKey("noclip")
            if v then
                setConnection("noclip", Services.RunService.Stepped:Connect(function()
                    local char = CharUtils.getChar(nil, false)
                    if not char then return end
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            pcall(function() part.CanCollide = false end)
                        end
                    end
                end))
            end
        end
    })
    
    PlayerBox:AddToggle("DisableCollision", {
        Text = "Disable Player Collision",
        Default = false,
        Callback = function(v)
            Flags.noCollision = v
            disconnectKey("noCollision")
            if v then
                setConnection("noCollision", Services.RunService.Heartbeat:Connect(function()
                    for _, plr in ipairs(Services.Players:GetPlayers()) do
                        if plr ~= LocalPlayer then
                            local char = plr.Character
                            if char then
                                for _, part in ipairs(char:GetDescendants()) do
                                    if part:IsA("BasePart") then
                                        pcall(function() part.CanCollide = false end)
                                    end
                                end
                            end
                        end
                    end
                end))
            else
                for _, plr in ipairs(Services.Players:GetPlayers()) do
                    if plr ~= LocalPlayer then
                        local char = plr.Character
                        if char then
                            for _, part in ipairs(char:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    pcall(function() part.CanCollide = true end)
                                end
                            end
                        end
                    end
                end
            end
        end
    })
    
    PlayerBox:AddToggle("InfiniteJump", {
        Text = "Infinite Jump",
        Default = false,
        Callback = function(v)
            Flags.infiniteJump = v
            disconnectKey("infiniteJump")
            if v then
                setConnection("infiniteJump", Services.UIS.JumpRequest:Connect(function()
                    local hum = CharUtils.getHum(nil, false)
                    if hum then
                        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
                    end
                end))
            end
        end
    })
    
    local VisualBox = Tabs.Main:AddRightGroupbox("Visual", "eye")
    
    VisualBox:AddToggle("Fullbright", {
        Text = "Fullbright",
        Default = false,
        Callback = function(v)
            disconnectKey("fullbright")
            if v then
                LightingModule.fullbright()
                setConnection("fullbright", Services.RunService.RenderStepped:Connect(function()
                    Services.Lighting.Brightness = 2
                    Services.Lighting.ClockTime = 14
                    Services.Lighting.FogEnd = 1e9
                    Services.Lighting.GlobalShadows = false
                    Services.Lighting.Ambient = Color3.new(1, 1, 1)
                end))
            else
                LightingModule.restore()
            end
        end
    })
    
    local UtilityBox = Tabs.Main:AddRightGroupbox("Utility", "zap")
    
    UtilityBox:AddToggle("ClickTeleport", {
        Text = "Click Teleport",
        Default = false,
        Callback = function(v)
            Flags.clickTp = v
            disconnectKey("clickTp")
            if v and LocalPlayer then
                local mouse = LocalPlayer:GetMouse()
                setConnection("clickTp", mouse.Button1Down:Connect(function()
                    if mouse.Hit then
                        CharUtils.teleportTo(CFrame.new(mouse.Hit.Position + Vector3.new(0, 5, 0)))
                    end
                end))
            end
        end
    })
    
    -- Combat Tab
    
    local AimBox = Tabs.Combat:AddLeftGroupbox("Aimbot", "crosshair")
    
    AimBox:AddToggle("Aimbot", {
        Text = "Aimbot",
        Default = false,
        Callback = function(v)
            Flags.aimbot = v
            disconnectKey("aimbot")
            if v then
                setConnection("aimbot", Services.RunService.RenderStepped:Connect(function()
                    local targetData = AimbotModule.getClosestTarget()
                    local cam = Services.Workspace.CurrentCamera or Camera
                    if targetData and cam then
                        local camPos = cam.CFrame.Position
                        local predictedPos = nil
                        
                        if targetData.part and targetData.part:IsA("BasePart") then
                            predictedPos = AimbotModule.predictPosition(targetData.part)
                        end
                        
                        if not predictedPos then
                            predictedPos = targetData.position
                        end
                        
                        if predictedPos then
                            local desiredCF = CFrame.lookAt(camPos, predictedPos, Vector3.new(0, 1, 0))
                            local smooth = clamp(tonumber(Flags.aimbotSmoothness) or 0, 0, 1)
                            local alpha = clamp(1 - smooth, 0.01, 1)
                            
                            pcall(function()
                                cam.CFrame = cam.CFrame:Lerp(desiredCF, alpha)
                            end)
                        end
                    end
                end))
            end
        end
    })
    
    AimBox:AddSlider("AimbotFOV", {
        Text = "FOV",
        Default = Flags.aimbotFOV,
        Min = 40,
        Max = 300,
        Rounding = 0,
        Callback = function(val)
            Flags.aimbotFOV = val
            if State.fovCircle then
                pcall(function() State.fovCircle.Radius = val end)
            end
        end,
    })
    
    AimBox:AddSlider("AimbotSmoothness", {
        Text = "Smoothness",
        Default = Flags.aimbotSmoothness,
        Min = 0.0,
        Max = 1.0,
        Rounding = 2,
        Callback = function(val) Flags.aimbotSmoothness = val end,
    })
    
    AimBox:AddDropdown("AimbotLockPart", {
        Values = { "Head", "Torso", "HumanoidRootPart" },
        Default = 1,
        Text = "Lock Part",
        Callback = function(val) Flags.aimbotLockPart = val end,
    })
    
    AimBox:AddToggle("AimbotTeamCheck", {
        Text = "Team Check",
        Default = false,
        Callback = function(v) Flags.aimbotTeamCheck = v end
    })
    
    AimBox:AddToggle("AimbotAliveCheck", {
        Text = "Alive Check",
        Default = true,
        Callback = function(v) Flags.aimbotAliveCheck = v end
    })
    
    AimBox:AddSlider("AimbotPrediction", {
        Text = "Prediction (s)",
        Default = Flags.prediction,
        Min = 0,
        Max = 1.0,
        Rounding = 2,
        Callback = function(val) Flags.prediction = val end,
    })
    
    AimBox:AddToggle("ShowFOV", {
        Text = "Show FOV",
        Default = false,
        Callback = function(v)
            Flags.showFOV = v
            disconnectKey("fovRender")
            if v then
                DrawingModule.createFOV()
                setConnection("fovRender", Services.RunService.RenderStepped:Connect(function()
                    if not State.fovCircle then DrawingModule.createFOV() end
                    DrawingModule.updateFOV()
                end))
            else
                DrawingModule.destroyFOV()
            end
        end
    })
    
    -- Teleport Tab
    
    local TeleBox = Tabs.Teleport:AddLeftGroupbox("Player Teleport", "map")
    
    TeleBox:AddDropdown("TeleportPlayer", {
        SpecialType = "Player",
        ExcludeLocalPlayer = true,
        Text = "Pilih Pemain",
        Callback = function() end
    })
    
    TeleBox:AddButton({
        Text = "Teleport ke Pemain",
        Func = function()
            local playerName = Library.Options and Library.Options.TeleportPlayer and Library.Options.TeleportPlayer.Value
            local target = playerName and Services.Players:FindFirstChild(playerName)
            local hrp = target and CharUtils.getHRP(target, false)
            if hrp then
                CharUtils.teleportTo(hrp.CFrame + Vector3.new(0, 3, 0))
            end
        end
    })
    
    TeleBox:AddButton({
        Text = "Refresh List",
        Func = function()
            local list = {}
            for _, p in ipairs(Services.Players:GetPlayers()) do
                if p ~= LocalPlayer then
                    table.insert(list, p.Name)
                end
            end
            table.sort(list)
            if Library.Options and Library.Options.TeleportPlayer then
                pcall(function() Library.Options.TeleportPlayer:SetValues(list) end)
            end
        end
    })
    
    -- Misc Tab
    
    local SpectBox = Tabs.Misc:AddLeftGroupbox("Spectate", "eye")
    
    SpectBox:AddDropdown("SpectatePlayer", {
        SpecialType = "Player",
        ExcludeLocalPlayer = true,
        Text = "Spectate Player",
        Callback = function() end
    })
    
    SpectBox:AddButton({
        Text = "Mulai Spectate",
        Func = function()
            local playerName = Library.Options and Library.Options.SpectatePlayer and Library.Options.SpectatePlayer.Value
            local target = playerName and Services.Players:FindFirstChild(playerName)
            if target and target.Character then
                Services.Workspace.CurrentCamera.CameraSubject = target.Character
            end
        end
    })
    
    SpectBox:AddButton({
        Text = "Berhenti Spectate",
        Func = function()
            Services.Workspace.CurrentCamera.CameraSubject = CharUtils.getHum(nil, false) or CharUtils.getChar(nil, false)
        end
    })
    
    SpectBox:AddButton({
        Text = "Refresh List",
        Func = function()
            local list = {}
            for _, p in ipairs(Services.Players:GetPlayers()) do
                if p ~= LocalPlayer then
                    table.insert(list, p.Name)
                end
            end
            table.sort(list)
            if Library.Options and Library.Options.SpectatePlayer then
                pcall(function() Library.Options.SpectatePlayer:SetValues(list) end)
            end
        end
    })
    
    local PosBox = Tabs.Misc:AddRightGroupbox("Position", "map-pin")
    
    PosBox:AddDropdown("PositionSlot", {
        Values = { "1", "2", "3", "4", "5" },
        Default = 1,
        Text = "Pilih Slot",
        Callback = function(val) Flags.positionSlot = tonumber(val) or 1 end
    })
    
    PosBox:AddButton({
        Text = "Save Pos",
        Func = function()
            local hrp = CharUtils.getHRP(nil, false)
            if hrp then
                State.savedSlots[Flags.positionSlot or 1] = hrp.Position
            end
        end
    })
    
    PosBox:AddButton({
        Text = "Teleport Pos",
        Func = function()
            local pos = State.savedSlots[Flags.positionSlot or 1]
            if pos then
                CharUtils.teleportTo(CFrame.new(pos + Vector3.new(0, 5, 0)))
            end
        end
    })
    
    PosBox:AddButton({
        Text = "Clear Slot",
        Func = function()
            State.savedSlots[Flags.positionSlot or 1] = nil
        end
    })
    
    PosBox:AddButton({
        Text = "Clear All Slots",
        Func = function()
            table.clear(State.savedSlots)
        end
    })
    
    local CamBox = Tabs.Misc:AddRightGroupbox("Camera", "camera")
    
    -- Load FreeCam if available
    pcall(function()
        State.freeCam = loadstring(game:HttpGet("https://raw.githubusercontent.com/Verdial/Verdict/refs/heads/main/fc_core.lua"))()
    end)
    
    CamBox:AddToggle("FreeCam", {
        Text = "Free Cam",
        Default = false,
        Callback = function(v)
            if State.freeCam then
                if v then State.freeCam:Enable() else State.freeCam:Disable() end
            end
        end
    })
    
    CamBox:AddToggle("SmoothCamera", {
        Text = "Smooth Camera",
        Default = false,
        Callback = function(v)
            Flags.smoothCam = v
            disconnectKey("smoothCam")
            disconnectKey("inputHandler")
            if not v then return end
            
            local cam = Services.Workspace.CurrentCamera or Camera
            local lastCF = cam and cam.CFrame or CFrame.new()
            
            setConnection("smoothCam", Services.RunService.RenderStepped:Connect(function()
                local cur = Services.Workspace.CurrentCamera or cam
                if not cur then return end
                lastCF = lastCF:Lerp(cur.CFrame, 0.25)
                cur.CFrame = lastCF
            end))
            
            setConnection("inputHandler", Services.UIS.InputChanged:Connect(function(input)
                local curCam = Services.Workspace.CurrentCamera or cam
                if not curCam then return end
                
                if input.UserInputType == Enum.UserInputType.MouseMovement and Services.UIS.MouseEnabled then
                    local d = input.Delta
                    local x = -d.X * 0.002 * Flags.sensitivity
                    local y = -d.Y * 0.002 * Flags.sensitivity
                    curCam.CFrame = curCam.CFrame * CFrame.Angles(0, x, 0) * CFrame.Angles(y, 0, 0)
                elseif input.UserInputType == Enum.UserInputType.Touch and Services.UIS.TouchEnabled then
                    local d = input.Delta
                    if input.Position and input.Position.X >= (curCam.ViewportSize.X * 0.5) then
                        local x = -d.X * 0.002 * Flags.sensitivity
                        local y = -d.Y * 0.002 * Flags.sensitivity
                        curCam.CFrame = curCam.CFrame * CFrame.Angles(0, x, 0) * CFrame.Angles(y, 0, 0)
                    end
                end
            end))
        end
    })
    
    CamBox:AddSlider("Sensitivity", {
        Text = "Sensitivity",
        Default = Flags.sensitivity,
        Min = 0.1,
        Max = 10.0,
        Rounding = 1,
        Callback = function(val) Flags.sensitivity = val end
    })
    
    local PerfBox = Tabs.Misc:AddRightGroupbox("Performance", "cpu")
    
    PerfBox:AddToggle("PowerSaving", {
        Text = "Power Saving Mode",
        Default = false,
        Callback = function(v)
            if not FPSModule.isSupported() then
                warn("⚠️ Exploit tidak support FPS cap API.")
                return
            end
            FPSModule.setCap(v and 24 or State.originalCap)
        end
    })
    
    PerfBox:AddDropdown("BoostMode", {
        Values = { "Lite", "Balanced", "Ultra" },
        Default = 1,
        Text = "BoostFPS Mode",
        Callback = function(val) Flags.boostMode = val end
    })
    
    PerfBox:AddButton({
        Text = "Apply Boost",
        Func = function()
            BoostModule.restore()
            BoostModule.apply(Flags.boostMode or "Lite")
        end
    })
    
    PerfBox:AddButton({
        Text = "Restore",
        Func = function()
            BoostModule.restore()
        end
    })
    
    -- UI Settings
    if ThemeManager and SaveManager then
        ThemeManager:SetLibrary(Library)
        SaveManager:SetLibrary(Library)
        ThemeManager:ApplyToTab(Tabs.UISettings)
        SaveManager:BuildConfigSection(Tabs.UISettings)
        SaveManager:LoadAutoloadConfig()
    end
    
    -- Cleanup on unload
    Library:OnUnload(function()
        clearAllConnections()
        Services.Workspace.CurrentCamera.CameraSubject = CharUtils.getHum(nil, false) or CharUtils.getChar(nil, false)
        if FPSModule.isSupported() then
            FPSModule.setCap(State.originalCap)
        end
        BoostModule.restore()
        DrawingModule.destroyFOV()
        _G.VerdictObsidianUI = nil
    end)
    
    _G.VerdictObsidianUI = Library
end

-- Initialize the UI
initializeUI()
