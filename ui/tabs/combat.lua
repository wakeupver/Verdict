return function(tab, ctx)
    local Services       = ctx.Services
    local Flags          = ctx.Flags
    local State          = ctx.State
    local ConnMgr        = ctx.Connections
    local AimbotModule   = ctx.AimbotModule
    local DrawingModule  = ctx.DrawingModule
    local clamp          = ctx.Utils.clamp

    local AimBox = tab:AddLeftGroupbox("Aimbot", "crosshair")

    AimBox:AddToggle("Aimbot", {
        Text    = "Aimbot",
        Default = false,
        Callback = function(v)
            Flags.aimbot = v
            ConnMgr.drop("aimbot")
            if not v then return end
            ConnMgr.set("aimbot", Services.RunService.RenderStepped:Connect(function()
                local targetData = AimbotModule.getClosestTarget()
                local cam = Services.Workspace.CurrentCamera
                if not (targetData and cam) then return end

                local predictedPos = (targetData.part and targetData.part:IsA("BasePart"))
                    and AimbotModule.predictPosition(targetData.part)
                    or targetData.position

                if predictedPos then
                    local desiredCF = CFrame.lookAt(cam.CFrame.Position, predictedPos, Vector3.new(0, 1, 0))
                    local alpha = clamp(1 - clamp(tonumber(Flags.aimbotSmoothness) or 0, 0, 1), 0.01, 1)
                    pcall(function() cam.CFrame = cam.CFrame:Lerp(desiredCF, alpha) end)
                end
            end))
        end
    })

    AimBox:AddSlider("AimbotFOV", {
        Text     = "FOV",
        Default  = Flags.aimbotFOV,
        Min      = 40,
        Max      = 300,
        Rounding = 0,
        Callback = function(val)
            Flags.aimbotFOV = val
            if State.fovCircle then pcall(function() State.fovCircle.Radius = val end) end
        end,
    })

    AimBox:AddSlider("AimbotSmoothness", {
        Text     = "Smoothness",
        Default  = Flags.aimbotSmoothness,
        Min      = 0.0,
        Max      = 1.0,
        Rounding = 2,
        Callback = function(val) Flags.aimbotSmoothness = val end,
    })

    AimBox:AddDropdown("AimbotLockPart", {
        Values   = { "Head", "Torso", "HumanoidRootPart" },
        Default  = 1,
        Text     = "Lock Part",
        Callback = function(val) Flags.aimbotLockPart = val end,
    })

    AimBox:AddToggle("AimbotTeamCheck", {
        Text     = "Team Check",
        Default  = false,
        Callback = function(v) Flags.aimbotTeamCheck = v end
    })

    AimBox:AddToggle("AimbotAliveCheck", {
        Text     = "Alive Check",
        Default  = true,
        Callback = function(v) Flags.aimbotAliveCheck = v end
    })

    AimBox:AddSlider("AimbotPrediction", {
        Text     = "Prediction (s)",
        Default  = Flags.prediction,
        Min      = 0,
        Max      = 1.0,
        Rounding = 2,
        Callback = function(val) Flags.prediction = val end,
    })

    AimBox:AddToggle("ShowFOV", {
        Text    = "Show FOV",
        Default = false,
        Callback = function(v)
            Flags.showFOV = v
            ConnMgr.drop("fovRender")
            if v then
                DrawingModule.createFOV()
                ConnMgr.set("fovRender", Services.RunService.RenderStepped:Connect(function()
                    if not State.fovCircle then DrawingModule.createFOV() end
                    DrawingModule.updateFOV()
                end))
            else
                DrawingModule.destroyFOV()
            end
        end
    })
end
