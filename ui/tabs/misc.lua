return function(tab, ctx)
    local Services       = ctx.Services
    local Flags          = ctx.Flags
    local State          = ctx.State
    local ConnMgr        = ctx.Connections
    local CharUtils      = ctx.CharUtils
    local FPSModule      = ctx.FPSModule
    local BoostModule    = ctx.BoostModule
    local Library        = ctx.Library

    -- Spectate
    local SpectBox = tab:AddLeftGroupbox("Spectate", "eye")

    SpectBox:AddDropdown("SpectatePlayer", {
        SpecialType        = "Player",
        ExcludeLocalPlayer = true,
        Text               = "Spectate Player",
        Callback           = function() end
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
            Services.Workspace.CurrentCamera.CameraSubject =
                CharUtils.getHum(nil, false) or CharUtils.getChar(nil, false)
        end
    })

    SpectBox:AddButton({
        Text = "Refresh List",
        Func = function()
            local list = {}
            for _, p in ipairs(Services.Players:GetPlayers()) do
                if p ~= Services.Players.LocalPlayer then table.insert(list, p.Name) end
            end
            table.sort(list)
            if Library.Options and Library.Options.SpectatePlayer then
                pcall(function() Library.Options.SpectatePlayer:SetValues(list) end)
            end
        end
    })

    -- Position
    local PosBox = tab:AddRightGroupbox("Position", "map-pin")

    PosBox:AddDropdown("PositionSlot", {
        Values   = { "1", "2", "3", "4", "5" },
        Default  = 1,
        Text     = "Pilih Slot",
        Callback = function(val) Flags.positionSlot = tonumber(val) or 1 end
    })

    PosBox:AddButton({ Text = "Save Pos",      Func = function()
        local hrp = CharUtils.getHRP(nil, false)
        if hrp then State.savedSlots[Flags.positionSlot or 1] = hrp.Position end
    end })

    PosBox:AddButton({ Text = "Teleport Pos",  Func = function()
        local pos = State.savedSlots[Flags.positionSlot or 1]
        if pos then CharUtils.teleportTo(CFrame.new(pos + Vector3.new(0, 5, 0))) end
    end })

    PosBox:AddButton({ Text = "Clear Slot",    Func = function()
        State.savedSlots[Flags.positionSlot or 1] = nil
    end })

    PosBox:AddButton({ Text = "Clear All Slots", Func = function()
        table.clear(State.savedSlots)
    end })

    -- Camera
    local CamBox = tab:AddRightGroupbox("Camera", "camera")

    pcall(function()
        State.freeCam = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/wakeupver/Verdict/main/modules/freecam.lua"
        ))()
    end)

    CamBox:AddToggle("FreeCam", {
        Text    = "Free Cam",
        Default = false,
        Callback = function(v)
            if State.freeCam then
                if v then State.freeCam:Enable() else State.freeCam:Disable() end
            end
        end
    })

    CamBox:AddToggle("SmoothCamera", {
        Text    = "Smooth Camera",
        Default = false,
        Callback = function(v)
            Flags.smoothCam = v
            ConnMgr.drop("smoothCam")
            ConnMgr.drop("inputHandler")
            if not v then return end

            local cam = Services.Workspace.CurrentCamera
            local lastCF = cam and cam.CFrame or CFrame.new()

            ConnMgr.set("smoothCam", Services.RunService.RenderStepped:Connect(function()
                local cur = Services.Workspace.CurrentCamera
                if not cur then return end
                lastCF = lastCF:Lerp(cur.CFrame, 0.25)
                cur.CFrame = lastCF
            end))

            ConnMgr.set("inputHandler", Services.UIS.InputChanged:Connect(function(input)
                local curCam = Services.Workspace.CurrentCamera
                if not curCam then return end
                if input.UserInputType == Enum.UserInputType.MouseMovement and Services.UIS.MouseEnabled then
                    local d = input.Delta
                    curCam.CFrame = curCam.CFrame
                        * CFrame.Angles(0, -d.X * 0.002 * Flags.sensitivity, 0)
                        * CFrame.Angles(-d.Y * 0.002 * Flags.sensitivity, 0, 0)
                elseif input.UserInputType == Enum.UserInputType.Touch and Services.UIS.TouchEnabled then
                    local d = input.Delta
                    if input.Position and input.Position.X >= (curCam.ViewportSize.X * 0.5) then
                        curCam.CFrame = curCam.CFrame
                            * CFrame.Angles(0, -d.X * 0.002 * Flags.sensitivity, 0)
                            * CFrame.Angles(-d.Y * 0.002 * Flags.sensitivity, 0, 0)
                    end
                end
            end))
        end
    })

    CamBox:AddSlider("Sensitivity", {
        Text     = "Sensitivity",
        Default  = Flags.sensitivity,
        Min      = 0.1,
        Max      = 10.0,
        Rounding = 1,
        Callback = function(val) Flags.sensitivity = val end
    })

    -- Performance
    local PerfBox = tab:AddRightGroupbox("Performance", "cpu")

    PerfBox:AddToggle("PowerSaving", {
        Text    = "Power Saving Mode",
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
        Values   = { "Lite", "Balanced", "Ultra" },
        Default  = 1,
        Text     = "BoostFPS Mode",
        Callback = function(val) Flags.boostMode = val end
    })

    PerfBox:AddButton({ Text = "Apply Boost", Func = function()
        BoostModule.restore()
        BoostModule.apply(Flags.boostMode or "Lite")
    end })

    PerfBox:AddButton({ Text = "Restore", Func = function()
        BoostModule.restore()
    end })
end
